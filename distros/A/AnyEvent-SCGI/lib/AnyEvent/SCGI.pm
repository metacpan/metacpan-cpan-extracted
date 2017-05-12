package AnyEvent::SCGI;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

use base 'Exporter';
our @EXPORT = qw(scgi_server);

=head1 NAME

AnyEvent::SCGI - Event based SCGI server

=cut

our $VERSION = '1.1';

=head1 SYNOPSIS

A simple Hello World SCGI server running on port 22222:

    use AnyEvent::SCGI;
    use HTTP::Headers;

    my $s = scgi_server '127.0.0.1', 22222, sub {
        my $handle = shift;
        my $env = shift;
        my $content_ref = shift; # undef if none
        my $fatal_error = shift;
        my $error_string = shift;

        my $headers = HTTP::Headers->new(
            'Status' => '200 OK',
            'Content-Type' => 'text/plain',
            'Connection' => 'close',
        );

        $handle->push_write($headers->as_string . "\r\nHello World!\r\n");
        $handle->push_shutdown;
    }
    AnyEvent->condvar->recv;

=head1 DESCRIPTION

Sets up a SCGI server on the specified port. Can be used with or without
C<Coro>.  You are responsible for any daemonization and startup code.

The usual C<AnyEvent> callback caveats apply; make sure you don't block or
re-enter the event loop in a way that's not supported.  This module has been
tested for use with C<Coro>, but if you don't want to use that, it's
recommended that you return from the callback as quickly as possible.

=head2 Using Coro

If you're using Coro, here's the supported calling pattern:

    use Coro;
    use Coro::AnyEvent;
    use AnyEvent;
    use AnyEvent::SCGI;

    my $s = scgi_server $server_name, $port, sub {
        my $handle = shift;
        my $env = shift;
        my $content = shift;

        # handle errors if any

        async { 
            my $stuff = expensive($content);
            $handle->push_write(
                $headers->as_string .
                "\r\nHello World!\r\n$stuff"
            );
            $handle->push_shutdown;
        };
        # return before running async block
    };
    AE::cv->recv;

=head1 FUNCTIONS

=head2 scgi_server $host, $port, $handler_cb

This function creates a TCP socket on the given host and port by calling
C<tcp_server()> from C<AnyEvent::Socket>.

Calls C<$handler_cb> when a valid SCGI request has been received.  The
callback will block other clients until it returns.

=head3 $handler_cb->($handle,\%env,\$content,$fatal,$error)

The first parameter is the C<AnyEvent::Handle> If the request has a payload, a
reference to it is passed in as the C<$content> parameter.

On error, C<\%env> and C<\$content> are undef and the usual C<$fatal> and
C<$error> parameters are passed in as subsequent arguments.  On "EOF" from the
client, fatal is "0" and error is 'EOF'.

=cut

sub scgi_server($$$) {
    my $host = shift;
    my $port = shift;
    my $cb = shift;
    return tcp_server $host, $port, sub { handle_scgi(@_,$cb) };
}

sub handle_scgi {
    my $fh = shift;
    my $host = shift;
    my $port = shift;
    my $cb = shift;

    my $handle; $handle = AnyEvent::Handle->new(
        fh => $fh,
        on_error => sub {
            shift;
            my $fatal = shift;
            my $error = shift;
            $cb->($handle, undef, undef, $fatal, $error);
        },
        on_eof => sub {
            shift;
            $cb->($handle, undef, undef, 0, 'EOF');
        },
    );

    $handle->push_read (netstring => sub {
        shift;
        my $env = shift;
        my %env = split /\0/, $env;

        if ($env{CONTENT_LENGTH} == 0) {
            $cb->($handle, \%env);
        }
        else {
            $handle->push_read(chunk => $env{CONTENT_LENGTH}, sub {
                $cb->($handle, \%env, \$_[1]);
            });
        }
    });

    return;
}

=head1 AUTHORS

Jeremy Stashewsky <stash@cpan.org>

Kevin Jones <kevinj@cpan.org>


=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-scgi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-SCGI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::SCGI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-SCGI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-SCGI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyEvent-SCGI>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-SCGI>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jeremy Stashewsky
Copyright 2009 Kevin Jones

Copyright 2009 Socialtext Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of AnyEvent::SCGI
