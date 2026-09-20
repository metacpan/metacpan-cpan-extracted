use strict;
use warnings;
use Test::More;
use FindBin;
use Path::Tiny qw( path );
use Encode qw( decode FB_CROAK );

# Ticket #211: the shipped skill doc (then share/claude-skill.md, since #285
# share/kanban-issues-karr-cli/SKILL.md plus references/*.md) -- what
# `karr skill install` hands to users -- carried two double-encoded UTF-8
# sequences: an em dash
# (\xc3\xa2\xc2\x80\xc2\x94 instead of \xe2\x80\x94) and an arrow
# (\xc3\xa2\xc2\x86\xc2\x92 instead of \xe2\x86\x92). That is exactly the
# defect `karr repair` fixes on boards (a UTF-8 character re-encoded a second
# time as if it were Latin-1), just landed in a shipped doc file instead of a
# ref blob. Both sites are fixed now, but nothing under t/ would notice a
# recurrence, so this test scans every file `karr skill install`/
# `karr init --claude-skill` can hand out for the general double-encoding
# shape -- not only the two literal sequences that happened to land here --
# plus the UTF-8-validity and stray-C1-control-character symptoms the same
# class of bug tends to leave behind.
#
# Scope: App::karr::Role::SkillFile::_skill_files (lib/App/karr/Role/SkillFile.pm)
# walks share/kanban-issues-karr-cli/ for every *.md `karr skill`/`karr init`
# ship, and this test walks all of share/ -- recursively, which is what
# reaches the references/ subdirectory -- instead of naming any file, so a
# reference doc dropped in later is covered without anyone having to remember
# to update this test.
#
# .claude/skills/kanban-issues-karr-cli/ (the copy this repo's own agents are
# briefed with) is not scanned here: t/62-skill-doc-sync.t already requires
# each file's body to be byte-identical to its twin under share/, so a
# mojibake regression in either copy becomes a body mismatch that test
# already catches -- confirmed still passing as of this test being written.
# This test only has to own the encoding shape itself.

# Every double-encoded UTF-8 run in $bytes, as a list of the raw byte
# sequences that matched (not decoded -- the point is to see the bytes that
# went wrong). \xc3[\x80-\xbf] is a UTF-8 lead byte re-encoded as if it were a
# single Latin-1 character; (?:\xc2[\x80-\xbf])+ is one or more UTF-8
# continuation bytes re-encoded the same way. Together they catch any
# double-encoded character, not just the em dash and arrow ticket #211 found.
sub find_double_encoded {
  my ($bytes) = @_;
  my @hits = $bytes =~ /(\xc3[\x80-\xbf](?:\xc2[\x80-\xbf])+)/g;
  return @hits;
}

# ---------------------------------------------------------------------------
# Prove the scanner can fail before trusting a green run of it below.
# ---------------------------------------------------------------------------

subtest 'the scanner catches the ticket #211 sequences and leaves plain UTF-8 alone' => sub {
  # The exact bytes ticket #211 found: an em dash and an arrow, each a UTF-8
  # character re-encoded a second time as if it were Latin-1.
  my $mojibake = "before \xc3\xa2\xc2\x80\xc2\x94 middle \xc3\xa2\xc2\x86\xc2\x92 after";
  my @hits = find_double_encoded($mojibake);
  is( scalar @hits, 2, 'both planted double-encoded sequences are caught' );
  is( $hits[0], "\xc3\xa2\xc2\x80\xc2\x94", '...the em dash bytes, exactly' );
  is( $hits[1], "\xc3\xa2\xc2\x86\xc2\x92", '...the arrow bytes, exactly' );

  # The correctly single-encoded UTF-8 versions of the same two characters
  # must NOT trip the scanner -- otherwise this test would fail on the very
  # fix it is meant to protect.
  my $clean = "before \xe2\x80\x94 middle \xe2\x86\x92 after";
  is( scalar( find_double_encoded($clean) ), 0,
    'correctly single-encoded UTF-8 is not flagged' );
};

# ---------------------------------------------------------------------------
# Every file karr actually ships as a skill doc.
# ---------------------------------------------------------------------------

my $repo_root = path($FindBin::Bin)->parent;
my $share_dir = $repo_root->child('share');

plan skip_all => "$share_dir not found -- skipping outside a full source checkout"
  unless $share_dir->exists;

my @shipped;
$share_dir->visit(
  sub { my ($p) = @_; push @shipped, $p if $p->is_file },
  { recurse => 1 },
);
@shipped = sort @shipped;

cmp_ok scalar(@shipped), '>=', 1, 'found shipped doc(s) under share/'
  or BAIL_OUT('nothing under share/ to scan -- run this from the distribution root');

# The walk has to reach below share/ itself: since #285 the skill is a
# directory and its references/*.md sit two levels down. A walk that stopped
# at the top would scan nothing and pass, which is the silent skip this guards.
cmp_ok scalar( grep { $_->relative($share_dir)->stringify =~ m{/.+/} } @shipped ), '>=', 1,
  'the walk recursed at least two levels below share/ (references/*.md)';

for my $file (@shipped) {
  subtest "$file" => sub {
    my $bytes = $file->slurp_raw;

    # Guard against a vacuous pass: if the file lost its non-ASCII content
    # entirely, the checks below would all trivially succeed while proving
    # nothing about double-encoding.
    like $bytes, qr/[^\x00-\x7f]/,
      'the file carries non-ASCII bytes worth checking';

    # decode() with a CHECK argument modifies its OCTETS argument in place --
    # it consumes decoded characters off the front of the buffer it was
    # handed, so on full success it leaves the original variable empty. Feed
    # it a copy, never $bytes itself, or the double-encoding scan below would
    # silently run against an emptied string and pass no matter what.
    my $bytes_for_decode = $bytes;
    my $decoded = eval { decode( 'UTF-8', $bytes_for_decode, FB_CROAK ) };
    my $decode_error = $@;
    ok( defined $decoded, 'the file is valid UTF-8' )
      or diag("UTF-8 decode failed: $decode_error");

    my @hits = find_double_encoded($bytes);
    is( scalar @hits, 0, 'no double-encoded UTF-8 sequences (ticket #211)' )
      or diag( 'found: ' . join( ', ', map { unpack 'H*', $_ } @hits ) );

    SKIP: {
      skip 'cannot check for C1 controls in bytes that are not valid UTF-8', 1
        unless defined $decoded;
      my @c1 = $decoded =~ /([\x{80}-\x{9f}])/g;
      is( scalar @c1, 0, 'no stray C1 control characters (U+0080-U+009F)' )
        or diag( 'found: ' . join( ', ', map { sprintf 'U+%04X', ord $_ } @c1 ) );
    }
  };
}

done_testing;
