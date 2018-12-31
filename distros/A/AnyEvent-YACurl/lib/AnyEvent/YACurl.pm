package AnyEvent::YACurl;

use 5.010000;
use strict;
use warnings;

use AnyEvent;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('AnyEvent::YACurl', $VERSION);

require constant;
my %constants= %{_get_known_constants()};
constant->import(\%constants);

use Exporter 'import';
our @EXPORT_OK = keys %constants;
our %EXPORT_TAGS = (constants => [keys %constants]);

my %TIMER;
my %WATCH;

_ae_set_helpers(
    sub { # watchset
        my ($client, $socket, $what)= @_;
        if ($what == 1) { # POLL_IN
            $WATCH{$socket}= AE::io($socket, 0, sub {
                _ae_event($client, $socket, 0);
            });

        } elsif ($what == 2) { # POLL_OUT
            $WATCH{$socket}= AE::io($socket, 1, sub {
                _ae_event($client, $socket, 1);
            });

        } elsif ($what == 3) { # POLL_INOUT
            $WATCH{$socket}= [
                AE::io($socket, 0, sub {
                    _ae_event($client, $socket, 0);
                }),
                AE::io($socket, 1, sub {
                    _ae_event($client, $socket, 1);
                }),
            ];

        } elsif ($what == 0 || $what == 4) { # NONE / REMOVE
            delete $WATCH{$socket};

        } else {
            warn "Don't understand what==$what";
        }
    },
    sub { # timerset
        my ($client, $time_ms)= @_;

        if ($time_ms == -1) {
            delete $TIMER{$$client};
            return;
        }

        AE::now_update;
        $TIMER{$$client}= AE::timer(($time_ms / 1000), 0, sub {
            delete $TIMER{$$client};
            _ae_timer_fired($client);
        });
    }
);

1;

=head1 NAME

AnyEvent::YACurl - Yet Another cURL binding for AnyEvent

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::YACurl ':constants';

    my $client = AnyEvent::YACurl->new;
    my $condvar = AnyEvent->condvar;
    my $return_data = '';
    $client->request($condvar, {
        CURLOPT_URL => "https://www.perl.org",
        CURLOPT_VERBOSE => 1,
        CURLOPT_WRITEFUNCTION => sub {
            my ($chunk) = @_;
            $return_data .= $chunk;
        }
    });

    my ($response, $error) = $condvar->recv;
    my $response_code = $response->getinfo(CURLINFO_RESPONSE_CODE);
    print "Have response code $response_code. Body was $return_data";

=head1 DESCRIPTION

This module provides bindings to cURL, integrated into AnyEvent.

=head2 AnyEvent::YACurl methods

=over

=item C<new>

Returns a new C<AnyEvent::YACurl> object. This is essentially a binding over cURL's
L<"multi" interface|https://curl.haxx.se/libcurl/c/libcurl-multi.html>.

=item C<request>

Performs a request using the client instantiated via C<new>. Takes a callback and a hashref of
cURL options (C<CURLOPT_*>). At a minimum C<CURLOPT_URL> must be provided, but it's recommended
to pass a few more arguments than that. Refer to the actual
L<cURL documentation|https://curl.haxx.se/libcurl/c/curl_easy_setopt.html> to find out about
other options to pass.

C<request> does not return anything, but will invoke the coderef passed via C<callback> once the
request is completed or had an error. The callback is invoked with two arguments, C<response> and
C<error>, but only one of the two will be defined.

The C<response> argument to the callback is a C<AnyEvent::YACurl::Response> object, documented
later in this pod, unless there was an error. If that was the case, the C<error> argument to the
callback will contain a human readable description of what went wrong.

    use Promises qw/deferred/;

    my $deferred = deferred;
    $client->request(
        sub {
            my ($response, $error) = @_;
            if ($error) {
                $deferred->reject($error);
            } else {
                $deferred->resolve($response->getinfo(CURLINFO_RESPONSE_CODE));
            }
        },
        {
            CURLOPT_URL => "https://www.perl.org",
            ...
        }
    );

=back

=head2 AnyEvent::YACurl::Response methods

=over

=item C<getinfo>

Queries the cURL API for information about the response. Refer to the
L<cURL documentation|https://curl.haxx.se/libcurl/c/curl_easy_getinfo.html> for possible
C<CURLINFO_*> options.

=back

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
