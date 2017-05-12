package App::Pocosi::ReadLine;
BEGIN {
  $App::Pocosi::ReadLine::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $App::Pocosi::ReadLine::VERSION = '0.03';
}

use strict;
use warnings FATAL => 'all';
use Carp;
use Data::Dump 'dump';
use IO::WrapOutput;
use POE;
use POE::Component::Server::IRC::Plugin qw(PCSI_EAT_NONE);
use POE::Wheel::ReadLine;
use POE::Wheel::ReadWrite;
use Symbol qw(gensym);

sub new {
    my ($package) = shift;
    croak "$package requires an even number of arguments" if @_ & 1;
    my $self = bless { @_ }, $package;
    return $self;
}

sub PCSI_register {
    my ($self, $ircd, %args) = @_;
    $self->{ircd} = $ircd;

    POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                got_user_input
                got_output
                restore_stdio
            )],
        ],
    );
    return 1;
}

sub PCSI_unregister {
    my ($self, $ircd, %args) = @_;
    $poe_kernel->call($self->{session_id}, 'restore_stdio');
    return 1;
}

sub _start {
    my ($kernel, $session, $self) = @_[KERNEL, SESSION, OBJECT];

    $self->{session_id} = $session->ID();
    $self->{console} = POE::Wheel::ReadLine->new(
        InputEvent => 'got_user_input',
        PutMode    => 'immediate',
        AppName    => 'pocosi',
    );

    my ($stdout, $stderr) = wrap_output();

    $self->{stderr_reader} = POE::Wheel::ReadWrite->new(
        Handle     => $stderr,
        InputEvent => 'got_output',
    );
    $self->{stdout_reader} = POE::Wheel::ReadWrite->new(
        Handle     => $stdout,
        InputEvent => 'got_output',
    );

    $self->{console}->get();
    return;
}

sub got_output {
    my ($self, $line) = @_[OBJECT, ARG0];
    $self->{console}->put($line);
    return;
}

sub got_user_input {
    my ($self, $line, $ex) = @_[OBJECT, ARG0, ARG1];

    if (defined $ex && $ex eq 'interrupt') {
        $self->{Pocosi}->shutdown('Exiting due to user interruption');
        return;
    }

    if (defined $line && length $line) {
        $self->{console}->add_history($line);

        if (my ($feature) = $line =~ /^(verbose|trace)\s*$/) {
            if ($self->{Pocosi}->$feature()) {
                $self->{Pocosi}->$feature(0);
                print "Disabled '$feature'\n";
            }
            else {
                $self->{Pocosi}->$feature(1);
                print "Enabled '$feature'\n";
            }
        }
        elsif (my ($cmd, $args) = $line =~ m{^/([a-z_]+)\s*(.+)?}) {
            my @args = defined $args ? eval $args : ();
            $self->{ircd}->yield($cmd, @args);
        }
        elsif (my ($method, $params) = $line =~ m{^\.([a-z_]+)\s*(.+)?}) {
            my @params = defined $params ? eval $params : ();

            local ($@, $!);
            eval {
                print dump($self->{ircd}->$method(@params)), "\n";
            };
            if (my $err = $@) {
                chomp $err;
                my $our_file = __FILE__;
                $err =~ s{ at \Q$our_file\E line [0-9]+\.$}{};
                warn $err, "\n";
            }
        }
        else {
            $self->_print_help();
        }
    }

    $self->{console}->get();
    return;
}

sub _print_help {
    my ($self) = @_;

    print <<'EOF';
Type ".foo 'bar', 'baz'" to call the method "foo" with the arguments 'bar'
and 'baz' on the IRCd component. You must quote your arguments since they
will be eval'd, and don't forget to use commas between arguments.

Type "/foo 'bar', 'baz'" to call the POE::Component::Server::IRC command foo
with the arguments 'bar' and 'baz'. This is equivalent to: .yield 'foo',
'bar', 'baz'

Type "verbose" and "trace" to flip those features on/off.
EOF

    return;
}

sub restore_stdio {
    my ($self) = $_[OBJECT];

    unwrap_output();
    delete $self->{console};
    delete $self->{stderr_reader};
    delete $self->{stdout_reader};
    return;
}

1;

=encoding utf8

=head1 NAME

App::Pocosi::ReadLine - A PoCo-Server-IRC plugin which provides a ReadLine UI

=head1 DESCRIPTION

This plugin is used internally by L<App::Pocosi|App::Pocosi>. No need for
you to use it.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut
