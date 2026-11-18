package API::Docker::Error::Truncated;
# ABSTRACT: The daemon closed before the response it announced was complete
our $VERSION = '0.006';
use Moo;
# namespace::clean has to come BEFORE "use overload" here, not after it as
# everywhere else in this distribution -- same reason as in
# API::Docker::Error::Stream, API::Docker::Error::HTTP and
# API::Docker::Error::Timeout. It sweeps the symbols `overload` installs --
# the `("" ` slot among them -- so with the two lines in the house order the
# class ends up not overloaded at all and stringifies as
# API::Docker::Error::Truncated=HASH(0x...). Nothing dies when that happens:
# every caller that only inspects $@ as a string silently starts seeing a
# reference address instead of the reason. Measured, not assumed:
# overload::Overloaded($err) is false with the lines swapped.
use namespace::clean;
use overload
  '""'     => sub { $_[0]->as_string },
  'bool'   => sub { 1 },
  fallback => 1;


has message => (
  is       => 'ro',
  required => 1,
);


has location => (
  is      => 'ro',
  default => sub { '' },
);


has endpoint => (
  is      => 'ro',
  default => sub { '' },
);


has phase => (
  is       => 'ro',
  required => 1,
);


has expected => (
  is => 'ro',
);


has received => (
  is => 'ro',
);


has partial => (
  is      => 'ro',
  default => sub { '' },
);


has summary => (
  is => 'ro',
);


sub as_string { $_[0]->message . $_[0]->location }



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Error::Truncated - The daemon closed before the response it announced was complete

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    # A tar the daemon stopped sending halfway is not a tar.
    my $tar = eval { $docker->images->get_tar('busybox') };
    if (my $err = $@) {
        die $err unless ref $err
            && $err->isa('API::Docker::Error::Truncated');
        warn 'got ' . length($err->partial) . ' of '
            . $err->expected . ' bytes; retrying';
        $tar = $docker->images->get_tar('busybox');
    }

=head1 DESCRIPTION

L<API::Docker::Role::HTTP> croaks with an object of this class when the daemon
closed the connection in the middle of a response -- a status line with no
terminator, a header block with no blank line to close it, a body shorter than
its C<Content-Length>, a chunk shorter than its own header, a chunk header cut
in half, or a chunked body with no terminating zero chunk. It is raised in one
more place that is not a closed connection but has the same consequence: a
chunk size line that arrived in full and is not a hexadecimal number, which
would otherwise be misread as a zero chunk and end the body early (see
L</phase>).

It is a structural check, not a heuristic, and it asks one of two questions
depending on how the piece is delimited. Where the response announced a length
it compares what arrived against it. Where the framing is by terminator
instead -- the head, and the chunk headers -- it asks whether the terminator
came before the stream ended, which needs nothing to compare and is just as
decidable. Neither is a guess about content: a header block that never closed
is not a short one, it is an unfinished one.

A body delimited by nothing but the close -- C<attach>,
C<< logs(follow => 1) >>, C</exec/{id}/start>, the whole
C<application/vnd.docker.raw-stream> family -- announces no end and has no
terminator either, so there an EOF B<is> the end and this is never raised.
Its B<head> is framed like any other, and is checked like any other.

=head2 Why it is fatal

For the same reason L<API::Docker::Error::Timeout> is, and the two are the
same defect reached by different routes: a short body satisfies every return
shape this role promises and is indistinguishable from a complete one.
C<ndjson> promises an ArrayRef of events and gets a shorter one; C<raw>
promises the response bytes and gets fewer of them; the default promises the
decoded body and gets whatever the truncated bytes happened to parse as. A
half tarball that looks whole is the worst of them, and it is the case this
exists for.

Nothing is lost by raising it: L</partial> carries the bytes a buffered read
had collected and L</summary> the count a streamed one had delivered, so a
caller who wants what arrived can have it. What it cannot do any more is
mistake it for everything.

=head2 What it is not

Not a timeout. Nothing waited and nothing expired -- the daemon answered, and
then the stream ended early. L<API::Docker::Error::Timeout> is raised when the
daemon goes B<quiet> for longer than a C<read_timeout>, which is a bound the
caller asked for; this needs no option and is on for every request.

Not a status. Where a status line arrived intact it said 200 and the response
after it did not follow; where L</phase> is C<'status-line'> there was no
usable status to begin with. An engine that reports a failure the normal way
raises L<API::Docker::Error::HTTP>, and one that reports it inside an HTTP 200
stream raises L<API::Docker::Error::Stream>. This is the third thing: no
report at all, because the connection went away mid-sentence.

Nor is it the daemon answering nothing whatsoever. A connection that closed
before a single byte of the status line is still the plain
C<No response from Docker daemon> croak it has always been -- there is no
half-sent response to describe, and that string predates every error class
here.

A response with a status of 400 or above raises this rather than
L<API::Docker::Error::HTTP> when B<its> body is the one cut short, which is
the same rule the timeout follows: the transport cannot tell a caller what the
engine said when it did not finish saying it. Read L</partial> for the part of
the error body that did arrive.

=head2 It is still the string it replaces

Like the other three error classes here, this one overloads stringification
(with C<< fallback => 1 >>, so comparison, concatenation, C<sprintf> and
matching all work through it) and produces what a plain C<croak> would have
died with: the reason, followed by Carp's own C< at FILE line N.> location
suffix, naming the same frame.

Unlike the other three it replaces no string, because there was nothing here
to replace -- a truncated response used to be returned rather than raised.
That makes it the one exception in this distribution that existing code cannot
have been catching, which is why it is a documented behaviour change and not a
bug fix in passing.

The boolean overload is explicit rather than derived from the string, so it
cannot be made false by its own message.

=head2 message

The reason on its own, without the location suffix: the request it belongs to,
where in the response framing the stream ended, and how much had arrived.

The request is named without its query string, for the same reason the
C<< >= 400 >> croak names it that way -- C</build> carries its C<buildargs>
there, which can hold credentials and have no business in an exception.

=head2 location

Carp's location suffix (C< at FILE line N.\n>), captured at the point the
error was raised so it names the same frame a plain C<croak> would have named.
Kept apart from L</message> so a caller can have the reason without it.

=head2 endpoint

The request that was cut short, as C<"GET /v1.47/images/get"> -- method and
path, no query string. The empty string for a reader driven directly with no
request context, which is how the transport's own tests drive them.

=head2 phase

Which piece of the response framing the stream ended inside. One of:

=over

=item * C<'status-line'> - the stream ended inside the status line, before the
CRLF that terminates it. A status line with nothing after it parses perfectly
well -- C<'HTTP/1.1 200 OK'> yields 200 and C<OK> -- so the missing terminator
is the only thing that says the daemon never finished writing it. Also a line
that arrived in full but is not an HTTP status line at all -- a proxy's
plain-text banner, an HTML error page -- which is no cut response, but is
refused here for the reason the non-hexadecimal chunk size below is: its second
word would otherwise be split out and read as the status

=item * C<'header-block'> - the stream ended inside a header line, or where
one belongs with the blank line that ends the field section never sent. The
second covers a head with no fields at all: RFC 9112 section 2.1 requires the
empty line whether there are twenty fields or none

=item * C<'content-length'> - fewer bytes arrived than the C<Content-Length>
header announced, or the header arrived in full but its value is not a number.
The second is no cut response either: left as it stood it would read as C<0>
and a response that had a body would come back empty, the same body-shaped lie
a truncation is

=item * C<'chunk-header'> - the stream ended inside a chunk size line, or at a
chunk boundary with no terminating zero chunk after it, or a chunk size line
that arrived in full but is not a hexadecimal number. The last is not a cut
response: the line is complete and terminated, but C<hex> would read its
garbage as C<0> -- the terminating zero chunk -- so the body would silently
come back empty. It is caught here because the outcome is the same body-shaped
lie a truncation is, not because the connection went away

=item * C<'chunk-data'> - the stream ended inside a chunk, short of the size
that chunk's own header announced

=item * C<'chunk-terminator'> - a chunk's data arrived in full and the CRLF
that ends it did not

=back

Informational rather than something to branch on: every value means the same
thing to a caller, which is that the response is incomplete. It is here
because "which of the four" is the first question when a real engine starts
raising this, and reading it off the object beats parsing L</message>.

=head2 expected

The byte count the framing announced for the piece that was cut short: the
C<Content-Length> for C<'content-length'>, the chunk's own size for
C<'chunk-data'>. C<undef> for the four phases with no announcement to fall
short of, which are the ones framed by a terminator instead.

=head2 received

How many of L</expected> arrived. C<undef> whenever L</expected> is.

Note that this counts the piece, not the response: on a chunked body it is the
bytes of the unfinished chunk, while L</partial> holds every chunk before it
as well.

=head2 partial

The response body bytes that had arrived when the stream ended, for a request
whose body was being buffered -- the empty string when none had.

These are B<not> a body: nothing was decoded, no chunk framing was verified
beyond what was needed to find the truncation, and the content stops
mid-value. They are here so a caller who wants them can have them rather than
because the transport thinks they are usable.

Always the empty string for a streamed request, which keeps no body by design.
Nothing is lost there either: every byte that arrived went through the same
decoding as every other byte, so the units it completed reached the callback
and are counted in L</summary> before this is raised.

Also always the empty string when L</phase> is C<'status-line'> or
C<'header-block'>: the response was cut before its body began, so there are no
body bytes to hand over. The bytes of the head itself are deliberately not put
here -- they are not a body, and L</message> already says how far into which
piece the stream got.

=head2 summary

For a request streaming through C<on_event>, C<on_frame> or C<on_chunk>: the
same C<< { delivered => N, stopped => 0 } >> HashRef the call would have
returned, describing what reached the callback before the stream was cut off.
C<undef> for a buffered request.

C<stopped> is always 0 here. A stream the caller ended with C<< $stop->() >>
leaves the rest of the response unread on purpose and is never truncation --
the check is skipped entirely once the callback has said stop.

=head2 as_string

    my $text = $err->as_string;   # same as "$err"

The message and the location suffix, concatenated. This is what the
stringification overload returns.

=head1 SEE ALSO

=over

=item * L<API::Docker::Role::HTTP> - Raises this error; see
L<API::Docker::Role::HTTP/"Failure in the middle of a response">

=item * L<API::Docker::Error::Timeout> - Raised instead when the daemon went
quiet for longer than a C<read_timeout>, rather than closing

=item * L<API::Docker::Error::HTTP> - Raised instead when the daemon answered,
completely, with a status of 400 or above

=item * L<API::Docker::Error::Stream> - Raised instead for a failure reported
inside a stream the daemon already answered with HTTP 200

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
