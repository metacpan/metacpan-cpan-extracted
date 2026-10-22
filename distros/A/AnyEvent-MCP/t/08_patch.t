use common::sense;
use Test::More;
use AnyEvent ();
use AnyEvent::MCP ();
use File::Temp qw(tempdir);

my $log = "Hmm...  Looks like a unified diff to me...\n"
   . "The text leading up to this was:\n--------------------------\n|--- a/input\n|+++ b/input\n"
   . "--------------------------\npatching file output (read from input)\n"
   . "Hunk #1 succeeded at 2 (offset -1 line).\n"
   . "Hunk #2 succeeded at 8 with fuzz 2 (offset 3 lines).\ndone\n";
my $parsed = AnyEvent::MCP::parse_patch_output $log;
is_deeply $parsed, {
   hunks => [
      { hunk => 1, success => 1, line => 2, fuzz => 0, offset => -1 },
      { hunk => 2, success => 1, line => 8, fuzz => 2, offset => 3 },
   ],
   unparsed => [],
}, "parse verbose framing, signed offsets and fuzz";

$parsed = AnyEvent::MCP::parse_patch_output (
   "Hunk #1 FAILED at 4.\nHunk #2 ignored at 7.\nunexpected diagnostic\n"
);
ok !$parsed->{hunks}[0]{success} && !$parsed->{hunks}[1]{success}, "parse failed and ignored hunks";
is_deeply $parsed->{unparsed}, ["unexpected diagnostic"], "retain unknown diagnostics";

for my $offset (-2, 0, 2) {
   my $hunks = AnyEvent::MCP::check_patch_output (
      0, "Hunk #1 succeeded at 10 (offset $offset lines).\n", [2]
   );
   is $hunks->[0]{offset}, $offset, "accept offset inside limit";
}

for my $case (
   [256, "Hunk #1 succeeded at 1.\n", [0], qr/wait status 256/],
   [9, "", [0], qr/wait status 9/],
   [0, "Hunk #1 succeeded at 1.\nunexpected\n", [0], qr/unrecognized output/],
   [0, "", [0], qr/expected 1 hunks, got 0/],
   [0, "", [], qr/expected 0 hunks, got 0/],
   [0, "Hunk #1 succeeded at 1.\n", [0, 0], qr/expected 2 hunks, got 1/],
   [0, "Hunk #2 succeeded at 1.\n", [0], qr/unexpected hunk number/],
   [0, "Hunk #1 succeeded at 1.\nHunk #1 succeeded at 2.\n", [0, 0], qr/unexpected hunk number/],
   [0, "Hunk #1 FAILED at 1.\n", [0], qr/hunk 1 failed/],
   [0, "Hunk #1 succeeded at 1 with fuzz 1.\n", [0], qr/used fuzz/],
   [0, "Hunk #1 succeeded at 1 (offset 3 lines).\n", [2], qr/exceeds 2/],
   [0, "Hunk #1 succeeded at 1 (offset -3 lines).\n", [2], qr/exceeds 2/],
) {
   eval { AnyEvent::MCP::check_patch_output @$case[0, 1, 2] };
   like $@, $case->[3], "reject incomplete or unacceptable application";
}

my $dir = tempdir CLEANUP => 1;
my $input = "$dir/input";
my $source = "zero\none\ntwo\nthree\n";
open my $fh, ">", $input or die $!;
print $fh $source;
close $fh or die $!;

sub contents {
   open my $fh, "<", $_[0] or die "$_[0]: $!";
   binmode $fh;
   local $/;
   <$fh>
}

my $output = "$dir/output";
my $diff = "--- a/input\n+++ b/input\n@@ -3 @@\n one\n-two\n+TWO\n three\n";
my $bad = "$dir/bad";
SKIP: {
   skip "extended GNU patch tests (PERL_ANYEVENT_MCP_TESTS=1)", 14
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
   my ($patch) = grep -f && -x _, map "$_/patch", split /:/, $ENV{PATH};
   skip "GNU patch is unavailable", 14 unless $patch;
   open my $version, "-|", $patch, "--version" or die "$patch: $!";
   my $gnu = do { local $/; <$version> } =~ /GNU patch/;
   skip "GNU patch is unavailable", 14 unless close $version && $gnu;

   my $hunks = AnyEvent::MCP::apply_udiff ($input, $output, $diff)->recv;
   is contents ($output), "zero\none\nTWO\nthree\n", "real patch output";
   is contents ($input), $source, "input unchanged";
   is $hunks->[0]{offset}, -1, "real verbose offset validated";

   eval { AnyEvent::MCP::apply_udiff ($input, $output, $diff) };
   like $@, qr/\Q$output\E:/, "existing output refused";
   is contents ($output), "zero\none\nTWO\nthree\n", "existing output preserved";

   eval { AnyEvent::MCP::apply_udiff ($input, $bad, "@@ -3 @@\n-one\n+ONE\n")->recv };
   like $@, qr/offset -1 exceeds 0/, "real excessive relocation rejected";
   ok !-e $bad, "excessive-offset output removed";

   eval { AnyEvent::MCP::apply_udiff ($input, $bad, $diff . "@@ -4 @@\n-absent\n+bad\n")->recv };
   like $@, qr/patch failed/, "real partial application rejected";
   ok !-e $bad, "partial output removed";
   is contents ($input), $source, "input unchanged after failures";

   eval { AnyEvent::MCP::apply_udiff ("$dir/missing", $bad, $diff)->recv };
   like $@, qr/patch failed/, "missing input rejected";
   ok !-e $bad, "output removed after command failure";

   open my $binary, ">", "$dir/binary" or die $!;
   binmode $binary;
   print {$binary} "a\0\xff\n";
   close $binary or die $!;
   AnyEvent::MCP::apply_udiff ("$dir/binary", "$dir/binary-output",
      "@@ -1 @@\n-a\0\xff\n+b\0\xfe\n")->recv;
   is contents ("$dir/binary-output"), "b\0\xfe\n", "byte diff preserves NUL and non-UTF-8 bytes";
   is contents ("$dir/binary"), "a\0\xff\n", "binary patch leaves input unchanged";

}

eval { AnyEvent::MCP::apply_udiff ($input, $bad, "invalid") };
like $@, qr/no hunks/, "invalid diff rejected before starting";
ok !-e $bad, "invalid diff creates no output";

done_testing;
