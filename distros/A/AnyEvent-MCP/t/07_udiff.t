use common::sense;
use Test::More;
use AnyEvent::MCP ();

for my $case (
   [
      "@@ -10,99 +123,99 @@ section\n keep\n-old\n+new\n",
      "@@ -10,2 +10,2 @@ section\n-keep\n+keep\n-old\n+new\n",
      [1],
   ],
   [
      "@@ -3 @@\n same\n same\n-old\n+new\n",
      "@@ -3,3 +3,3 @@\n-same\n+same\n same\n-old\n+new\n",
      [1],
   ],
   ["@@ -0 @@\n+a\n+b\n", "@@ -0,0 +1,2 @@\n+a\n+b\n", [0]],
   ["@@ -1 @@\n-a\n", "@@ -1,1 +0,0 @@\n-a\n", [0]],
   [
      "--- a/file\n+++ b/file\n@@ -1 @@\n-a\n+b\n+c\n@@ -10 @@\n-z\n",
      "--- a/file\n+++ b/file\n@@ -1,1 +1,2 @@\n-a\n+b\n+c\n@@ -10,1 +10,0 @@\n-z\n",
      [0, 0],
   ],
   [
      "@@ -1 @@\n-old\n\\ No newline at end of file\n+new\n\\ No newline at end of file\n\n",
      "@@ -1,1 +1,1 @@\n-old\n\\ No newline at end of file\n+new\n\\ No newline at end of file\n",
      [0],
   ],
) {
   my ($input, $expected, $offsets) = @$case;
   my ($diff, $max_offset) = AnyEvent::MCP::normalize_udiff $input;

   is $diff, $expected, "normalized diff";
   is_deeply $max_offset, $offsets, "whole-hunk relocation limits";
   is $input, $case->[0], "input not modified";
}

for my $case (
   ["no patch\n", qr/no hunks/],
   ["@@ -bad @@\n-old\n+new\n", qr/bad hunk header/],
   ["@@ -1 @@\ninvalid\n", qr/bad hunk line/],
   ["@@ -1 @@\n", qr/empty hunk/],
   ["@@ -2 @@\n+new\n", qr/needs old-side context/],
) {
   eval { AnyEvent::MCP::normalize_udiff $case->[0] };
   like $@, $case->[1], "invalid diff rejected";
}

done_testing;
