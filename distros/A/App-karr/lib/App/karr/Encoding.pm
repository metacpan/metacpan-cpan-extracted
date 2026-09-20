# ABSTRACT: The character/octet boundary for karr

package App::karr::Encoding;
our $VERSION = '0.601';
use strict;
use warnings;
use Exporter qw( import );
use Encode qw( encode decode FB_CROAK LEAVE_SRC );
use IO::Handle;
use YAML::XS ();
use JSON::MaybeXS ();


our @EXPORT_OK = qw(
  BOARD_ENCODING_VERSION
  decode_argv
  enable_std_utf8
  to_octets
  from_octets
  to_octets_for_env
  from_octets_from_env
  yaml_dump
  yaml_load
  json_encode
  json_decode
  repair_mojibake
);


use constant BOARD_ENCODING_VERSION => 2;


sub to_octets {
  my ($chars) = @_;
  return $chars unless defined $chars;
  return encode( 'UTF-8', $chars );
}


sub from_octets {
  my ($octets) = @_;
  return $octets unless defined $octets;
  my $chars = eval { decode( 'UTF-8', $octets, FB_CROAK | LEAVE_SRC ) };
  return defined $chars ? $chars : $octets;
}


sub to_octets_for_env {
  my ($chars) = @_;
  return to_octets($chars);
}


sub from_octets_from_env {
  my ($octets) = @_;
  return from_octets($octets);
}


sub decode_argv {
  $_ = from_octets($_) for @ARGV;
  return;
}


sub enable_std_utf8 {
  binmode STDOUT, ':encoding(UTF-8)';
  binmode STDERR, ':encoding(UTF-8)';
  # After the binmode, and on both handles: see above (#249). The layer takes
  # STDERR's unbuffered default away, and flushing only STDERR would invert the
  # commands that print their outcome before they warn.
  STDOUT->autoflush(1);
  STDERR->autoflush(1);
  return;
}


sub yaml_dump {
  my (@data) = @_;
  return from_octets( YAML::XS::Dump(@data) );
}


sub yaml_load {
  my ($chars) = @_;
  return YAML::XS::Load( to_octets($chars) );
}

# One codec for the process. utf8 => 0 is the whole point: the caller gets a
# character string back and the output layer encodes it once, at the edge.
my $JSON;

sub _json {
  return $JSON //= JSON::MaybeXS->new(
    utf8            => 0,
    canonical       => 1,
    convert_blessed => 1,
  );
}


sub json_encode {
  my ($data) = @_;
  return _json()->encode($data);
}


sub json_decode {
  my ($chars) = @_;
  return _json()->decode($chars);
}


sub repair_mojibake {
  my ($data) = @_;

  my $ref = ref $data;
  return { map { $_ => repair_mojibake( $data->{$_} ) } keys %$data }
    if $ref eq 'HASH';
  return [ map { repair_mojibake($_) } @$data ]
    if $ref eq 'ARRAY';
  return $data if $ref;
  return $data unless defined $data;

  return $data unless $data =~ /[^\x00-\x7F]/;   # ASCII: nothing to repair
  return $data if     $data =~ /[^\x00-\xFF]/;   # real characters: already right

  # LEAVE_SRC on both calls, and it is not cosmetic: with a CHECK argument and
  # without it, Encode consumes the source string in place. Omitting it here
  # emptied $data, so every string that reached the decode and failed it -- all
  # ordinary Latin-1 text -- came back as "" instead of unchanged.
  my $octets = eval { encode( 'ISO-8859-1', $data, FB_CROAK | LEAVE_SRC ) };
  return $data unless defined $octets;
  my $decoded = eval { decode( 'UTF-8', $octets, FB_CROAK | LEAVE_SRC ) };
  return defined $decoded ? $decoded : $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Encoding - The character/octet boundary for karr

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    use App::karr::Encoding qw( decode_argv enable_std_utf8 yaml_dump );

    enable_std_utf8();
    decode_argv();

    print yaml_dump( { title => "Fix \x{fc}nicode \x{2014} \x{e4}rger" } );

=head1 DESCRIPTION

karr holds one rule: B<everything inside the program is a Perl character
string, and bytes exist only at the outer edges>. This module is the only place
that crosses that line, so every edge crosses it the same way.

The edges, and who guards them:

=over 4

=item * B<C<@ARGV>> -- L</decode_argv>, called from F<bin/karr> and
F<bin/karr-foundation>.

=item * B<C<STDOUT>/C<STDERR>> -- L</enable_std_utf8>, likewise called from the
two scripts. An in-process caller that captures output (a test, say) has to put
the same layer on its capture handle, because reopening C<STDOUT> drops the
layer the script installed. The same is true of a caller that loads
L<App::karr::Foundation> directly instead of running F<bin/karr-foundation> --
see L<App::karr::Foundation/DESCRIPTION> for what that means in practice.

=item * B<Git refs> -- L<App::karr::Git/write_ref> and
L<App::karr::Git/read_ref> call L</to_octets> and L</from_octets>. Blobs hold
UTF-8 octets; everything above C<read_ref> sees characters.

=item * B<Files> -- L<Path::Tiny>'s C<slurp_utf8>/C<spew_utf8>, which are
already character-level. Nothing extra is needed, and nothing extra may be
added: an C<Encode::encode> in front of a C<spew_utf8> is a double encode.

=item * B<YAML> -- L</yaml_dump> and L</yaml_load>. C<YAML::XS::Dump> emits
octets and C<YAML::XS::Load> expects them, which is the opposite of the rule
above, so those two functions are never called directly. (C<DumpFile> and
C<LoadFile> B<are> character-level and are used unwrapped.)

=item * B<JSON> -- L</json_encode> and L</json_decode>. The C<encode_json> and
C<decode_json> functions are octet-level for the same reason and are likewise
not used directly.

=item * B<C<%ENV>> -- L</to_octets_for_env> and L</from_octets_from_env>.
Perl's C<%ENV> is a byte boundary: assigning a character string warns
C<Wide character in setenv>, and C<$ENV{NAME}> reads back whatever bytes
were stored. The crossing is named here so neither side is handled ad hoc
at the call site.

=back

=head2 Legacy boards

karr up to and including 0.402 mixed the two levels, and every board written by
those versions has UTF-8 octets encoded a second time in its task frontmatter,
its config, and its activity log. Task bodies are unaffected: they never passed
through C<Dump>. L</repair_mojibake> undoes exactly that second encoding, and
L<App::karr::Git/board_encoding_version> decides when to apply it -- see
L<App::karr::Cmd::Repair> for the migration.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Git>, L<App::karr::Task>,
L<App::karr::Cmd::Repair>

=head2 BOARD_ENCODING_VERSION

The encoding contract version this code writes, stored per board in
C<refs/karr/meta/encoding>. A board without that ref predates the contract and
is read through L</repair_mojibake>.

=head2 to_octets

  my $bytes = to_octets($characters);

Encodes a character string to UTF-8 octets. C<undef> passes through. This is
the character-to-octet edge: the only place karr calls C<Encode::encode>
directly, so nothing outside this module ever needs to.

=head2 from_octets

  my $characters = from_octets($bytes);

Decodes UTF-8 octets to a character string -- the octet-to-character edge,
and the only place karr calls C<Encode::decode> directly. A payload that is
not valid UTF-8 is returned B<unchanged> rather than being lossily
substituted: karr ref blobs
and command-line arguments are UTF-8 by contract, and passing a non-conforming
payload through keeps the byte-in/byte-out behaviour karr had before this
boundary existed, instead of quietly replacing bytes with U+FFFD.

=head2 to_octets_for_env

  my $bytes = to_octets_for_env($characters);

The character-to-octet edge for C<%ENV>. C<undef> passes through. Assigning a
character string to C<$ENV{NAME}> makes Perl emit C<Wide character in setenv>
and emit bytes whose encoding depends on the IO layers in scope; encoding
explicitly here makes the warning impossible to emit and the bytes the child
process receives well-defined. Equivalent to L</to_octets>; the dedicated
name marks the call site as an ENV crossing, the way L</decode_argv> marks
argv.

=head2 from_octets_from_env

  my $characters = from_octets_from_env($bytes);

The octet-to-character edge for C<%ENV>. C<%ENV> stores bytes; reading a
non-ASCII value back through C<$ENV{NAME}> gives octets, not characters.
A payload that is not valid UTF-8 is returned unchanged, for the same
reason L</from_octets> does. Equivalent to L</from_octets>; the dedicated
name marks the call site as an ENV crossing.

=head2 decode_argv

  decode_argv();

Decodes C<@ARGV> in place from UTF-8. Arguments that are not valid UTF-8 are
left as they arrived.

=head2 enable_std_utf8

  enable_std_utf8();

Puts a C<:encoding(UTF-8)> layer on C<STDOUT> and C<STDERR> so command bodies
can C<print> character strings, and turns autoflush on for both.

The autoflush is not a convenience -- it pays back what the layer costs. A bare
C<STDERR> is unbuffered, so a warning printed before a result also arrives in
a combined stream before it; the C<:encoding(UTF-8)> layer buffers, and that
stops being true. Both handles then flushed at exit, C<STDOUT> first, so a
combined stream carried every warning karr wrote B<after> every result it
wrote: C<< karr delete 1 --yes 2>&1 >> reported C<Deleted task 1> above the
warning that the deletion orphaned a dependent (#249).

Both handles carry the autoflush, not just the one the layer broke.
Autoflushing C<STDERR> alone would only turn the inversion around: L<karr
move|App::karr::Cmd::Move> prints its outcome first and warns after, so its
combined output would then read warning-before-outcome. With both handles
flushed at every C<print>, a combined stream shows what the code printed, in
the order it printed it -- which is what a terminal shows anyway, C<STDOUT>
being line buffered and C<STDERR> unbuffered there. That is why this was never
visible interactively and hit only whoever reads both streams as one: a
C<< 2>&1 >> pipeline, or an agent harness capturing combined output.

The price is a C<write> per C<print> instead of one per full buffer, which for
a command that prints a board is a few hundred small writes. The one caller
that prints steadily is L<App::karr::Foundation>, whose runner tees agent
output; there it is a gain rather than a cost -- an operator's
C<< karr-foundation ... > run.log >> now fills as the run happens instead of in
4k jumps, the per-board C<fork> can no longer inherit a half-full buffer and
write it twice (the hand-written flushes around that C<fork> stay, now as
cheap no-ops), and parallel boards interleave at whole prints rather than at
buffer boundaries that can split a line.

C<STDIN> is deliberately left alone, and the rule is that every reader of it
decodes what it read itself. L<App::karr::Cmd::Restore>,
L<App::karr::Cmd::SetRefs> and L<App::karr::Foundation> slurp a whole payload,
each setting C<binmode STDIN, ':raw'> first and passing the octets through
L</from_octets> exactly once. A layer installed here would buy those three
nothing -- C<:raw> pops it straight back off -- and would silently decode twice
for a reader that ever forgot that C<binmode>. The fourth reader,
L<App::karr::Cmd::Delete>, is the odd one out: it reads one line of typed
answer to its confirmation. That line stays octets, which is without
consequence only because nothing keeps it -- it is matched against C</^y/i>
and dropped, never stored, echoed or written to a ref. A reader that starts
using an answer as text has to decode it like the other three, rather than
expect a layer here.

=head2 yaml_dump

  my $characters = yaml_dump($data);

C<YAML::XS::Dump> at the character level, and the only place karr calls it
directly: C<Dump> itself emits octets, which is why the result is passed
through L</from_octets> before any caller sees it.

=head2 yaml_load

  my $data = yaml_load($characters);

C<YAML::XS::Load> at the character level, and the only place karr calls it
directly: C<Load> expects octets, which is why the character string is
turned to them with L</to_octets> first.

=head2 json_encode

  my $characters = json_encode($data);

C<encode_json> at the character level, and the only place karr calls it
directly, with C<canonical> key ordering so the C<--json> payload an agent
parses is byte-stable across runs.

=head2 json_decode

  my $data = json_decode($characters);

C<decode_json> at the character level, and the only place karr calls it
directly.

=head2 repair_mojibake

  my $fixed = repair_mojibake($data);

Undoes one round of UTF-8 double encoding, walking hashes and arrays and
returning a fresh structure. Blessed references and hash keys are passed
through untouched.

A string is only rewritten when it cannot be anything but double-encoded:

=over 4

=item * pure ASCII is never touched, so an ASCII board is bit-identical
afterwards and the repair is safe to run over a whole board;

=item * a string containing a codepoint above U+00FF cannot be a byte string
misread as characters, so it is already correct and is left alone;

=item * what remains must additionally form valid UTF-8 when read back as
bytes. Ordinary Latin-1 text almost never does -- C<"\x{fc}ber"> is C<fc 62>,
which is not valid UTF-8 -- whereas C<"\x{c3}\x{bc}ber"> is C<c3 bc 65 72>,
which decodes to C<"\x{fc}ber">.

=back

The residual ambiguity is a string whose non-ASCII characters happen to spell
valid UTF-8, such as a literal C<"\x{c3}\x{a9}">. That is why the repair is
bounded to boards that predate C<refs/karr/meta/encoding> instead of running
forever.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
