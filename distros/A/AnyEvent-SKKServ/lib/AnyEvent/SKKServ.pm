package AnyEvent::SKKServ;
use strict;
use warnings;
use 5.008005;
our $VERSION = '0.01';

use AnyEvent::Handle;
use AnyEvent::Socket ();

use constant {
    CLIENT_END       => '0',
    CLIENT_REQUEST   => '1',
    CLIENT_VERSION   => '2',
    CLIENT_HOST      => '3',

    SERVER_ERROR     => '0',
    SERVER_FOUND     => '1',
    SERVER_NOT_FOUND => '4',
    SERVER_FULL      => '9',
};

sub new {
    my ($class, %args) = @_;
    return bless {
        host => undef,
        port => 55100,

        on_error => sub {
            $_[0]->push_write(SERVER_ERROR . "\n");
        },
        on_end => sub {
            undef $_[0];
        },
        on_version => sub {
            $_[0]->push_write("$VERSION:anyevent_skkserv ");
        },
        on_host => sub {
            # unimplemented
            $_[0]->push_write("hostname:addr:...: ");
        },
        on_request => sub {},
        %args,
    }, $class;
}

sub run {
    my $self = shift;
    AnyEvent::Socket::tcp_server $self->{host}, $self->{port}, sub {
        my ($fh, $host, $port) = @_ or die "connection failed: $!";
        my $hdl; $hdl = AnyEvent::Handle->new(
            fh => $fh,
            on_eof => sub {
                $_[0]->destroy;
            },
            on_error => sub {
                $_[0]->destroy;
            },
        );
        $hdl->on_read(sub {
            $hdl->push_read(chunk => 1, sub {
                my ($hdl, $command) = @_;
                if ($command eq CLIENT_END) {
                    $self->{on_end}->(@_);
                } elsif ($command eq CLIENT_REQUEST) {
                    $hdl->push_read(regex => qr/\x20/, sub {
                        chop $_[1];
                        $self->{on_request}->(@_);
                    });
                } elsif ($command eq CLIENT_VERSION) {
                    $self->{on_version}->(@_);
                } elsif ($command eq CLIENT_HOST) {
                    $self->{on_host}->(@_);
                } else {
                    $self->{on_error}->(@_);
                }
            });
        });
    };
}

1;
__END__

=encoding utf8

=head1 NAME

AnyEvent::SKKServ - Lightweight skkserv implementation for AnyEvent

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::SKKServ;

  my $cv = AE::cv();

  my $skkserv = AnyEvent::SKKServ->new(
      on_request => sub {
          my ($handle, $request) = @_;

          ...
      },
  );
  $skkserv->run;

  $cv->recv;

=head1 DESCRIPTION

AnyEvent::SKKServ is yet another skkserv implementation. And too simple, so it doesn't support jisyo (dictionary) file.

Let's make your own skkserv! (e.g. Google CGI API for Japanese Input, Social IME's API, ...)

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 METHODS

=head2 new

=over 4

=item host : Str

Takes an optional host address.

=item port => 55100 : Num

Takes an optional port number. (Defaults to 55100)

=item on_error => $cb->($handle) : CodeRef

Takes a callback for when you receive an illegal data.

=item on_end => $cb->($handle) : CodeRef

=item on_request => $cb->($handle, $request) : CodeRef

=item on_version => $cb->($handle) : CodeRef

=item on_host => $cb->($handle) : CodeRef

Takes callbacks corresponding to reply from the client (see L</PROTOCOL>).

=back

=head2 run

Run skkserv.

=head1 PROTOCOL

=head2 Client Request Form

=over 4

=item "0"

end of connection

=item "1eee "

eee is keyword in EUC code with ' ' at the end

=item "2"

skkserv version number

=item "3"

hostname and its IP addresses

=back

=head2 Server Reply Form for "1eee"

=over

=item "0"

Error

=item "1eee"

eee is the associated line separated by '/'

=item "4"

Not Found

=back

=head2 Server Reply Form for "2"

=over 4

=item "A.B "

A for major version number, B for minor version number followed by a space

=back

=head2 Server Reply Form for "3"

=over 4

=item "string:addr1:...: "

string for hostname, addr1 for an IP address followed by a space

=back

=head1 AUTHOR

Takumi Akiyama E<lt>akiym@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
