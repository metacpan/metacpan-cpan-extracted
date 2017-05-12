#!perl
use strict;
use warnings;
use Test::More;
use Cogit;
use Test::utf8;

my $git = Cogit->new(directory => "test-encoding");

for ([$git->master, "utf-8"], [$git->master->parent, "iso-8859-1"],) {
   my ($commit, $encoding) = @{$_};
   is($commit->encoding, $encoding);
   for my $role (qw(author committer)) {
      is_flagged_utf8($commit->$role->name);
      is_sane_utf8($commit->$role->name);
      is($commit->author->name, "T\x{e9}st User");
   }
   is_flagged_utf8($commit->comment);
   is_sane_utf8($commit->comment);
   is($commit->comment, "Touch\x{e9}");
}

done_testing;
