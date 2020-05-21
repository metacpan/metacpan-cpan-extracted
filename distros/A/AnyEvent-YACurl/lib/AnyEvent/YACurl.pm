package AnyEvent::YACurl;

use 5.010000;
use strict;
use warnings;

use AnyEvent;

our $VERSION = '0.15';

require XSLoader;
XSLoader::load('AnyEvent::YACurl', '0.15');

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

AnyEvent::YACurl - Yet Another curl binding for AnyEvent

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::YACurl ':constants';

    my $client = AnyEvent::YACurl->new({});
    my $condvar = AnyEvent->condvar;
    my $return_data = '';
    $client->request($condvar, {
        CURLOPT_URL => "https://www.perl.org",
        CURLOPT_VERBOSE => 1,
        CURLOPT_WRITEFUNCTION => sub {
            my ($chunk) = @_;
            $return_data .= $chunk;
        },
        CURLOPT_HTTPHEADER => [
            "My-Super-Awesome-Header: forty-two",
        ],
    });

    my ($response, $error) = $condvar->recv;
    my $response_code = $response->getinfo(CURLINFO_RESPONSE_CODE);
    print "Have response code $response_code. Body was $return_data";

=head1 DESCRIPTION

This module provides bindings to curl, integrated into AnyEvent.

=head1 METHODS

=head2 AnyEvent::YACurl

=over

=item C<new>

Returns a new C<AnyEvent::YACurl> object. This is essentially a binding over curl's
L<"multi" interface|https://curl.haxx.se/libcurl/c/libcurl-multi.html>.

Its first and only argument is a required hashref containing options to control behavior, such as
C<CURLMOPT_MAX_TOTAL_CONNECTIONS>. Refer to the actual
L<curl documentation|https://curl.haxx.se/libcurl/c/curl_multi_setopt.html> to find out about
other options to pass.

=item C<request>

Performs a request using the client instantiated via C<new>. Takes a callback and a hashref of
curl options (C<CURLOPT_*>). At a minimum C<CURLOPT_URL> must be provided, but it's recommended
to pass a few more arguments than that. Refer to the actual
L<curl documentation|https://curl.haxx.se/libcurl/c/curl_easy_setopt.html> to find out about
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

=head2 AnyEvent::YACurl::Response

=over

=item C<getinfo>

Queries the curl API for information about the response. Refer to the
L<curl documentation|https://curl.haxx.se/libcurl/c/curl_easy_getinfo.html> for possible
C<CURLINFO_*> options.

=back

=head1 CURL OPTIONS

curl "multi" options may be passed to C<< AnyEvent::YACurl->new({ ... }) >>, and a list of all
options can be found in the
L<curl multi documentation|https://curl.haxx.se/libcurl/c/curl_multi_setopt.html>. Most, but not
all, options can be passed.

curl "easy" (request) options may be passed to C<< $client->request({ ... }) >>, and a list of all
options can be found in the
L<curl easy documentation|https://curl.haxx.se/libcurl/c/curl_easy_setopt.html>. Most, but not all,
options can be passed.

Some translation between Perl and curl value types has to be done. Many curl options take a number
or string, and these will be converted from simple Perl scalars. When a curl option takes a
C<curl_slist> structure, a Perl array reference will be converted appropriately, like in the
C<CURLOPT_HTTPHEADER> example listed earlier.

Special care has to be taken with curl options that take a function, such as
C<CURLOPT_WRITEFUNCTION>. Their Perl signatures are documented below.

=over

=item CURLOPT_WRITEFUNCTION

(See L<curl documentation|https://curl.haxx.se/libcurl/c/CURLOPT_WRITEFUNCTION.html>)

Set callback for writing received data. This will be called with one argument, C<data>, containing
the received data.

    CURLOPT_WRITEFUNCTION => sub {
        my $data= shift;
        print STDERR $data;
    },

=item CURLOPT_HEADERFUNCTION

(See L<curl documentation|https://curl.haxx.se/libcurl/c/CURLOPT_HEADERFUNCTION.html>)

Callback that receives header data. This will be called with one argument, C<data>, containing
the received data.

=item CURLOPT_READFUNCTION

(See L<curl documentation|https://curl.haxx.se/libcurl/c/CURLOPT_READFUNCTION.html>)

Read callback for data uploads. This will be called with one argument, C<length>, indicating
the maximum size of data to be read. The callback should either return a scalar with the data, an
empty string to indicate the end of the transfer, or C<undef> to abort the transfer.

    CURLOPT_READFUNCTION => sub {
        my $length= shift;
        return substr($my_data, 0, $length, '');
    },

=item CURLOPT_DEBUGFUNCTION

(See L<curl documentation|https://curl.haxx.se/libcurl/c/CURLOPT_DEBUGFUNCTION.html>)

Debug callback. Called with two arguments, C<type> and C<data>.

    CURLOPT_DEBUGFUNCTION => sub {
        my ($type, $data)= @_;
	if ($type == CURLINFO_TEXT) {
            print STDERR "curl: $data\n";
	}
    },

=item CURLOPT_TRAILERFUNCTION

(See L<curl documentation|https://curl.haxx.se/libcurl/c/CURLOPT_TRAILERFUNCTION.html>)

Set callback for sending trailing headers. Called without any arguments, expected output is a
reference to an array of scalars representing headers to be sent out. C<undef> may be returned to
abort the request.

    CURLOPT_TRAILERFUNCTION => sub {
        return [
            "My-super-awesome-trailer: trailer-stuff",
	];
    }

=back

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
