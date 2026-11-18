package API::Docker::Error::HTTP;
# ABSTRACT: Error status returned by the Docker Engine on the status line
our $VERSION = '0.006';
use Moo;
# namespace::clean has to come BEFORE "use overload" here, not after it as
# everywhere else in this distribution -- same reason as in
# API::Docker::Error::Stream. It sweeps the symbols `overload` installs --
# the `("" ` slot among them -- so with the two lines in the house order the
# class ends up not overloaded at all and stringifies as
# API::Docker::Error::HTTP=HASH(0x...). Nothing dies when that happens: every
# caller that only inspects $@ as a string silently starts seeing a reference
# address instead of the reason, and this is the exception every resource
# method in the distribution can raise. Measured, not assumed:
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


has status => (
  is       => 'ro',
  required => 1,
);


has reason => (
  is      => 'ro',
  default => sub { '' },
);


has body => (
  is      => 'ro',
  default => sub { '' },
);


has data => (
  is => 'ro',
);


sub as_string { $_[0]->message . $_[0]->location }



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Error::HTTP - Error status returned by the Docker Engine on the status line

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    eval { $docker->containers->kill($id) };
    if (my $err = $@) {
        # Behaves exactly like the string it replaces ...
        warn "kill failed: $err";

        # ... and carries the status code, so 404 and 409 are told apart
        # without matching on prose the engine is free to change.
        if (ref $err && $err->isa('API::Docker::Error::HTTP')) {
            return    if $err->status == 404;   # already gone
            sleep 1   if $err->status == 409;   # wrong state, retry
        }
    }

=head1 DESCRIPTION

L<API::Docker::Role::HTTP> croaks with an object of this class whenever the
engine answers a request with a status of 400 or above.

The reason it exists is that the croak B<text> is not an interface. What the
engine puts in the error body is engine-specific prose: a kill against a
stopped container answers 409 with C<can only kill running containers. E<lt>idE<gt> is
in state stopped: container state improper> on rootless Podman 5.4.2, while
Docker's own example for the same case is C<Container E<lt>idE<gt> is not running> --
a different body shape and entirely different wording. A caller that has to
tell "no such container" from "wrong state" apart had no choice but to match
that prose. L</status> is the same distinction as a number the engine
documents.

=head2 It is still the string it replaces

Everything this class replaces was a plain C<croak> of a string, and callers
rely on that. It overloads stringification (with C<< fallback => 1 >>, so
comparison, concatenation, C<sprintf> and matching all work through it) and
produces byte for byte what C<croak> died with before: the same
C<Docker API error (STATUS): REASON> text, followed by Carp's own
C< at FILE line N.> location suffix, naming the same frame. Code written
against the old behaviour keeps working unchanged:

    eval { $docker->containers->inspect($id) };
    if ($@) {
        (my $reason = $@) =~ s/\s+at\s+\S+\s+line\s+\d+\.?//g;   # still works
        die "no good: $@";                                        # still works
        warn $@ if $@ =~ /404/;                                   # still works
    }

Note that a substitution B<on> C<$@> replaces the object in that scalar with a
plain string, as it would with any overloaded object, so take a copy first if
L</status> is still wanted afterwards.

The boolean overload is explicit rather than derived from the string, so an
engine message of C<0> cannot make a live exception test false.

=head2 What it does not replace

Catching this class is B<not> a reliable way to catch a failed operation, and
the POD of the streaming methods still says to inspect C<$@> as a string.
Two exception classes reach a caller and which one it is depends on the
engine: a failure the daemon decides before it commits to a status arrives
here, while one it decides after arrives as an L<API::Docker::Error::Stream>
inside a stream that was already answered with HTTP 200. C<< ->status >> is
the extra for a caller that has already established it is holding one of
these, not the new recommended way to detect failure.

The C<response> out-parameter of L<API::Docker::Role::HTTP/get> is untouched
by this class and is not superseded by it: it is the only way to the status of
a request that did B<not> fail -- a C<304 Not Modified> from starting an
already-running container, or the C<X-Docker-Container-Path-Stat> header a
successful C<HEAD> carries its whole payload in.

=head2 message

The reason on its own, without the location suffix: the same
C<Docker API error (STATUS): REASON> text the transport croaked before this
class existed, where C<REASON> is the engine's C<message> field, its
C<errorDetail.message>, its flat C<error> key or the raw body, in that order
of preference.

=head2 location

Carp's location suffix (C< at FILE line N.\n>), captured at the point the
error was raised so it names the same frame a plain C<croak> would have named.
Kept apart from L</message> so a caller can have the reason without it.

=head2 status

The HTTP status code: C<404>, C<409>, C<500>. This is the whole point of the
class -- the one part of an engine error that is documented per endpoint and
identical across engines.

It arrives off the status line as a string of digits, exactly as
C<< $res{status} >> from L<API::Docker::Role::HTTP>'s C<response> option does,
so compare it numerically (C<< $err->status == 404 >>) rather than relying on
a type.

=head2 reason

The status line's reason phrase as the engine sent it (C<Not Found>,
C<Conflict>). Informational: it comes off the wire, not from a table, so it is
no more of a stable interface than the error body's prose. Branch on
L</status>.

=head2 body

The response body verbatim, before any decoding -- the bytes the engine sent.
Empty string when it sent none.

=head2 data

The decoded body, or C<undef> when there was nothing to decode or decoding
failed. Usually the HashRef the engine's C<{"message":...}> shape decodes to,
which is where an engine-specific extra such as Podman's C<cause> key can be
read; an array-shaped body decodes to an ArrayRef, so check the C<ref> before
subscripting it.

=head2 as_string

    my $text = $err->as_string;   # same as "$err"

The message and the location suffix, concatenated. This is what the
stringification overload returns.

=head1 SEE ALSO

=over

=item * L<API::Docker::Role::HTTP> - Raises this error; see its C<response>
option for the status of a request that did not fail

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
