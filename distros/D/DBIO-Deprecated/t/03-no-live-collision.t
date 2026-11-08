use strict;
use warnings;
use Test::More;

use Cwd ();
use File::Find ();
use File::Spec ();

# THE CLAIM THIS TEST MAKES (house rule 11 -- stated up front, so that a
# future fix has to say whether it keeps this claim or replaces it):
#
#   "No tombstone name shipped here exists as a REAL package in lib/ of any
#    other dist of the family."
#
# A tombstone takes the PAUSE index entry for an orphaned name. If another
# dist ships a real module under the same name, the two dists fight over the
# entry and installing this one overwrites the real module with a stub that
# dies on load -- exactly what happened with DBIO::Test::Future, which core
# re-introduced after this dist had tombstoned it (karr k7). t/02 cannot see
# that: it only compares versions, not who else ships the name.
#
# "Real package" means a `package X;` statement at column 0 outside POD and
# before __END__/__DATA__. Indented lines and POD SYNOPSIS examples do not
# count -- core's DBIO::Storage::PoolBase carries
# `  package DBIO::PostgreSQL::Async::Pool;` inside a SYNOPSIS, and that name
# IS a tombstone here; it must not fail this test.
#
# The test needs the family checked out side by side (../*/lib). It SKIPS --
# deliberately, so the dist builds standalone -- when run anywhere else:
# from a built tree (dzil test, a tarball), where ../ is not the family, the
# cwd is no git checkout. Siblings must be git checkouts too, so stale
# build directories next to a build are never mistaken for family members.
#
# A sibling that is itself a copy of THIS dist is not "another dist" and is
# left out: a second clone under a different directory name, or the other
# git worktrees when this one lives in .claude/worktrees/<name>. Each of
# them carries every tombstone as a column-0 `package X;` by design, so
# counting them would report all tombstones as live collisions. Such a copy
# is recognised by what makes it this dist -- its main module,
# lib/DBIO/Deprecated.pm -- not by its directory name.

my $cwd = Cwd::getcwd();

plan skip_all => 'not run from a git checkout of the dist (built tree or '
  . 'tarball): ../ is not the family checkout directory'
  unless -e File::Spec->catfile($cwd, '.git');

my $MAIN_MODULE = 'lib/DBIO/Deprecated.pm';

my $parent = Cwd::abs_path(File::Spec->catdir($cwd, File::Spec->updir));
my $self   = Cwd::abs_path($cwd);

my @siblings = grep {
  my $abs = Cwd::abs_path($_);
  defined $abs && $abs ne $self && -d "$_/lib" && -e "$_/.git"
    && !-e "$_/$MAIN_MODULE"
} glob("$parent/*");

plan skip_all => "no sibling checkouts of other DBIO dists under $parent -- "
  . 'nothing to compare against'
  unless @siblings;

# Tombstone names come from lib/ itself (like t/02), not from a hand-kept list.
my %tombstone;
File::Find::find(
  {
    no_chdir => 1,
    wanted   => sub {
      return unless /\.pm\z/;
      return if $File::Find::name eq $MAIN_MODULE;
      (my $mod = $File::Find::name) =~ s{^lib/}{};
      $mod =~ s{\.pm\z}{};
      $mod =~ s{/}{::}g;
      $tombstone{$mod} = 1;
    },
  },
  'lib',
);

BAIL_OUT('found no tombstone modules under lib/ -- test is inoperative')
  unless %tombstone;

my %collision;   # name => [ "file:line", ... ]
my $scanned = 0;

for my $sib (@siblings) {
  File::Find::find(
    {
      no_chdir => 1,
      wanted   => sub {
        return unless /\.pm\z/ && -f;
        my $file = $File::Find::name;
        open my $fh, '<', $file or return;
        $scanned++;
        my $in_pod = 0;
        while (my $line = <$fh>) {
          if ($line =~ /^=(\w+)/) { $in_pod = $1 ne 'cut'; next }
          next if $in_pod;
          last if $line =~ /^__(?:END|DATA)__\b/;
          if ($line =~ /^package\s+([A-Za-z_][\w:]*)/ && $tombstone{$1}) {
            my $name = $1;
            (my $rel = $file) =~ s{^\Q$parent\E/}{../};
            push @{ $collision{$name} }, "$rel:$.";
          }
        }
      },
    },
    "$sib/lib",
  );
}

BAIL_OUT('sibling checkouts found but no .pm scanned -- test is inoperative')
  unless $scanned;

for my $mod (sort keys %tombstone) {
  ok(!$collision{$mod}, "$mod is not a real package in any sibling dist")
    or diag("tombstone name is shipped as a real module by:\n  "
      . join("\n  ", @{ $collision{$mod} })
      . "\nInstalling DBIO-Deprecated would overwrite it with a stub that dies"
      . " on load. Remove the tombstone (the name is live again), do not"
      . ' rename the real module.');
}

done_testing();
