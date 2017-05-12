package App::Termcast;
BEGIN {
  $App::Termcast::AUTHORITY = 'cpan:DOY';
}
$App::Termcast::VERSION = '0.13';
use Moose;
# ABSTRACT: broadcast your terminal sessions for remote viewing

with 'MooseX::Getopt::Dashes';

use IO::Select;
use IO::Socket::INET;
use JSON;
use Scalar::Util 'weaken';
use Term::Filter::Callback;
use Term::ReadKey;
use Try::Tiny;



has host => (
    is      => 'rw',
    isa     => 'Str',
    default => 'noway.ratry.ru',
    documentation => 'Hostname of the termcast server to connect to',
);


has port => (
    is      => 'rw',
    isa     => 'Int',
    default => 31337,
    documentation => 'Port to connect to on the termcast server',
);


has user => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { $ENV{USER} },
    documentation => 'Username for the termcast server',
);


has password => (
    is      => 'rw',
    isa     => 'Str',
    default => 'asdf', # really unimportant
    documentation => "Password for the termcast server\n"
                   . "                              (mostly unimportant)",
);


has bell_on_watcher => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    documentation => "Send a terminal bell when a watcher connects\n"
                   . "                              or disconnects",
);


has timeout => (
    is      => 'rw',
    isa     => 'Int',
    default => 5,
    documentation => "Timeout length for the connection to the termcast server",
);


has establishment_message => (
    traits     => ['NoGetopt'],
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_establishment_message {
    my $self = shift;
    return sprintf("hello %s %s\n", $self->user, $self->password);
}

sub _termsize {
    return try { GetTerminalSize() } catch { (undef, undef) };
}


sub termsize_message {
    my $self = shift;

    my ($cols, $lines) = $self->_termsize;

    return '' unless $cols && $lines;

    return $self->_form_metadata_string(
        geometry => [ $cols, $lines ],
    );
}

has socket => (
    traits     => ['NoGetopt'],
    is         => 'rw',
    isa        => 'IO::Socket::INET',
    lazy_build => 1,
    init_arg   => undef,
);

sub _form_metadata_string {
    my $self = shift;
    my %data = @_;

    my $json = JSON::encode_json(\%data);

    return "\e]499;$json\x07";
}

sub _build_socket {
    my $self = shift;

    my $socket;
    {
        $socket = IO::Socket::INET->new(PeerAddr => $self->host,
                                        PeerPort => $self->port);
        if (!$socket) {
            Carp::carp "Couldn't connect to " . $self->host . ": $!";
            ReadMode(0, $self->input)
                if $self->_has_term && $self->_term->_raw_mode;
            sleep 5;
            ReadMode(5, $self->input)
                if $self->_has_term && $self->_term->_raw_mode;
            redo;
        }
    }

    syswrite $socket, $self->establishment_message . $self->termsize_message;

    # ensure the server accepted our connection info
    {
        my $select = IO::Select->new($socket);
        my ($r, undef, $e) = IO::Select->select(
            $select, undef, $select,
        );

        for my $fh (@$e) {
            if ($fh == $socket) {
                ReadMode(0, $self->input)
                    if $self->_has_term && $self->_term->_raw_mode;
                Carp::croak("Invalid password");
            }
        }
        for my $fh (@$r) {
            if ($fh == $socket) {
                my $buf;
                $socket->recv($buf, 4096);
                if (!defined $buf || length $buf == 0) {
                    ReadMode(0, $self->input)
                        if $self->_has_term && $self->_term->_raw_mode;
                    Carp::croak("Invalid password");
                }
                elsif ($buf ne ('hello, ' . $self->user . "\n")) {
                    ReadMode(0, $self->input)
                        if $self->_has_term && $self->_term->_raw_mode;
                    Carp::carp("Unknown login response from server: $buf");
                    ReadMode(5, $self->input)
                        if $self->_has_term && $self->_term->_raw_mode;
                }
            }
        }
    }

    ReadMode(5, $self->input)
        if $self->_has_term && $self->_term->_raw_mode;
    return $socket;
}

before clear_socket => sub {
    my $self = shift;
    Carp::carp("Lost connection to server ($!), reconnecting...");
    $self->socket->close;
    ReadMode(0, $self->input)
        if $self->_has_term && $self->_term->_raw_mode;
};

sub _new_socket {
    my $self = shift;
    $self->_term->remove_input_handle($self->socket);
    $self->clear_socket;
    $self->_term->add_input_handle($self->socket);
}

has _needs_termsize_update => (
    traits  => ['NoGetopt'],
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has _term => (
    is        => 'ro',
    does      => 'Term::Filter',
    lazy      => 1,
    predicate => '_has_term',
    default   => sub {
        my $_self = shift;
        weaken(my $self = $_self);
        # XXX using ::Callback for now because we need to be able to
        # instantiate App::Termcast objects without initializing the terminal
        # (in case of just calling write_to_termcast). This should
        # eventually be deprecated in favor of moving the termcast interaction
        # code out to an App::Termcast::Writer module or something, and
        # this module should be a simple wrapper that combines that module
        # with Term::Filter.
        Term::Filter::Callback->new(
            callbacks => {
                setup => sub {
                    my ($term) = @_;
                    $term->add_input_handle($self->socket);
                },
                winch => sub {
                    # for the sake of sending a clear to the client anyway
                    syswrite $self->output, "\e[H\e[2J";
                    $self->_needs_termsize_update(1);
                },
                read_error => sub {
                    my ($term, $fh) = @_;
                    if ($fh == $self->socket) {
                        $self->_new_socket;
                    }
                },
                read => sub {
                    my ($term, $fh) = @_;
                    if ($fh == $self->socket) {
                        my $got = $term->_read_from_handle(
                            $self->socket, "socket"
                        );
                        $self->_new_socket unless defined $got;

                        if ($self->bell_on_watcher) {
                            # something better to do here?
                            syswrite $self->output, "\a";
                        }
                    }
                },
                munge_output => sub {
                    my ($term, $buf) = @_;
                    $self->write_to_termcast($buf);
                    $buf;
                },
            },
        );
    },
    handles => [ 'run', 'input', 'output' ],
);


sub write_to_termcast {
    my $self = shift;
    my ($buf) = @_;

    my $socket = $self->socket;
    my $select = IO::Select->new($socket);

    my (undef, $w, $e) = IO::Select->select(
        undef, $select, $select, $self->timeout,
    );

    my $err;

    for my $fh (@$e) {
        if ($fh == $socket) {
            $err = 1;
        }
    }

    if (!$err) {
        for my $fh (@$w) {
            if ($fh == $socket) {
                if ($self->_needs_termsize_update) {
                    $buf = $self->termsize_message . $buf;
                    $self->_needs_termsize_update(0);
                }

                return $self->socket->syswrite($buf);
            }
        }
    }

    $self->clear_socket;
    return $self->write_to_termcast(@_);
}


__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Termcast - broadcast your terminal sessions for remote viewing

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  my $tc = App::Termcast->new(user => 'foo');
  $tc->run('bash');

=head1 DESCRIPTION

App::Termcast is a client for the L<http://termcast.org/> service, which allows
broadcasting of a terminal session for remote viewing.

=head1 ATTRIBUTES

=head2 host

Server to connect to (defaults to noway.ratry.ru, the host for the termcast.org
service).

=head2 port

Port to use on the termcast server (defaults to 31337).

=head2 user

Username to use (defaults to the local username).

=head2 password

Password for the given user. The password is set the first time that username
connects, and must be the same every subsequent time. It is sent in plaintext
as part of the connection process, so don't use an important password here.
Defaults to 'asdf' since really, a password isn't all that important unless
you're worried about being impersonated.

=head2 bell_on_watcher

Whether or not to send a bell to the terminal when a watcher connects or
disconnects. Defaults to false.

=head2 timeout

How long in seconds to use for the timeout to the termcast server. Defaults to
5.

=head1 METHODS

=head2 establishment_message

Returns the string sent to the termcast server when connecting (typically
containing the username and password)

=head2 termsize_message

Returns the string sent to the termcast server whenever the terminal size
changes.

=head2 write_to_termcast $BUF

Sends C<$BUF> to the termcast server.

=head2 run @ARGV

Runs the given command in the local terminal as though via C<system>, but
streams all output from that command to the termcast server. The command may be
an interactive program (in fact, this is the most useful case).

=head1 TODO

Use L<MooseX::SimpleConfig> to make configuration easier.

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/doy/app-termcast/issues>.

=head1 SEE ALSO

L<http://termcast.org/>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc App::Termcast

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/App-Termcast>

=item * Github

L<https://github.com/doy/app-termcast>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Termcast>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Termcast>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
