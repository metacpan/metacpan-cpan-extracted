package CGI::Parse::PSGI::Streaming;
use strict;
use warnings;
our $VERSION = '1.0.1'; # VERSION
use HTTP::Response;
use CGI::Parse::PSGI::Streaming::Handle;
use SelectSaver;

# ABSTRACT: creates a filehandle that parses CGI output and writes to a PSGI responder


sub parse_cgi_output_streaming_fh {
    my ($responder) = @_;

    # ugly-ish way to get a ref to a new filehandle
    my $output = \do {local *HANDLE};

    # state for the callback closure
    my $headers; # string, accumulated headers
    my $response; # HTTP::Response object with parsed headers
    my $writer; # the writer object returned by the responder

    ## no critic(ProhibitTies)
    tie *{$output},'CGI::Parse::PSGI::Streaming::Handle', sub {
        # this callback is invoked with whatever bytes were printed to
        # the filehandle; it will be called with no argument (or an
        # undef) when the filehandle is closed
        my ($data) = @_;

        # reset the default filehandle to the real STDOUT, just in
        # case: it's nice to make sure all the callbacks are invoked
        # with the state they expect
        my $saver = SelectSaver->new("::STDOUT");

        # if we're still parsing the headers
        if (!$response) {
            if (defined $data) {
                $headers .= $data;
            }
            else { # closed file before the end of headers
                $headers = "HTTP/1.1 500 Internal Server Error\x0d\x0a";
            }

            # still more headers to come, return to the CGI
            return unless $headers =~ /\x0d?\x0a\x0d?\x0a/;

            # since we may have received the last bytes of the headers
            # together with the first bytes of the body, we want to
            # make sure that $headers contains only the headers, and
            # $data contains only the body (or '')
            ($headers,$data) =
                ($headers =~ m{\A(.+?)\x0d?\x0a\x0d?\x0a(.*)\z}sm);

            # HTTP::Response wants things formatted like... an HTTP
            # response. CGI output is slightly different. Let's cheat.
            unless ( $headers =~ /^HTTP/ ) {
                $headers = "HTTP/1.1 200 OK\x0d\x0a" . $headers;
            }

            $response = HTTP::Response->parse($headers);

            # RFC 3875 6.2.3
            if ($response->header('Location') && !$response->header('Status')) {
                $response->header('Status', 302);
            }
        }

        # this is not a "elsif"! we may have the start of the body
        # with the same 'print' as the end of the headers, and we want
        # to stream out that body already
        if ($response) { # we have parsed the headers
            if ( $response->code == 500 && !defined($data) ) {
                # filehandle closed after a raw 500, synthesise a body
                $responder->([
                    500,
                    [ 'Content-Type' => 'text/html' ],
                    [ $response->error_as_HTML ]
                ]);
                return;
            }
            # we haven't sent the headers to the PSGI backend yet
            if (!$writer) {
                my $status = $response->header('Status') || 200;
                $status =~ s/\s+.*$//; # remove ' OK' in '200 OK'
                # PSGI doesn't allow having Status header in the response
                $response->remove_header('Status');

                # we send the status and headers, we get a writer
                # object back
                $writer = $responder->([
                    $status,
                    +[
                        map {
                            my $k = $_;
                            map { ( $k => _cleanup_newline($_) ) }
                                $response->headers->header($_);
                        } $response->headers->header_field_names
                    ],
                ]);
            }

            # ok, now we have a writer object (either just built, or
            # built during a previous call). Let's send it whatever
            # body we have
            if (defined $data) {
                $writer->write($data) if length($data);
            }
            else {
                $writer->close;
            }
        }
    };

    return $output;
}

sub _cleanup_newline {
    local $_ = shift;
    s/\r?\n//g;
    return $_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CGI::Parse::PSGI::Streaming - creates a filehandle that parses CGI output and writes to a PSGI responder

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

  use CGI::PSGI;
  use CGI::Parse::PSGI::Streaming;

  sub {
    my ($env) = @_;

    my $q = CGI::PSGI->new($env);

    return sub {
      my ($psgi_responder) = @_;

      my $tied_stdout =
        CGI::Parse::PSGI::Streaming::parse_cgi_output_streaming_fh(
          $psgi_responder,
        );

      select $tied_stdout;
      old_sub_that_expects_a_cgi_object_and_prints($q);
      close $tied_stdout;
    };
   };

=head1 DESCRIPTION

You should probably not do what the L</synopsis> says, and just use
L<< C<CGI::Emulate::PSGI::Streaming> >> directly.

=head1 FUNCTIONS

=head2 C<parse_cgi_output_streaming_fh>

  my $tied_stdout =
    CGI::Parse::PSGI::Streaming::parse_cgi_output_streaming_fh(
      $psgi_responder,
    );

This function, given a PSGI responder object, builds a L<tied
filehandle|perltie/Tying FileHandles> that your old CGI code can print
to.

The tied handle will parse CGI headers, and pass them on to the
responder in the format that it expects them. The handle will then
feed whatever is printed to it, on to the writer object that the
responder returned. See L<the "Delayed Response and Streaming Body"
section of the PSGI spec|PSGI/Delayed Response and Streaming Body> for
details.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Broadbean.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
