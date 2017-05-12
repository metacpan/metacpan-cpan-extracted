
use strict;
use warnings;

use Test::More tests => 1;
use Test::TempDir::Tiny qw( tempdir );
use Path::Tiny;
my $tmpdir;
BEGIN {
  $tmpdir = tempdir("homedir");
  my $world      = path($tmpdir)->child('world')->absolute;
  my $name_cache = path($tmpdir)->child('name-cache')->absolute;
  my $repo       = path($tmpdir)->child('repo')->absolute;
  my $profiles   = $repo->child('profiles')->absolute;
  my $paludis    = path($tmpdir)->child('.paludis')->absolute;

  $world->spew_raw('');
  $name_cache->mkpath;
  $profiles->mkpath;
  $repo->mkpath;
  $repo->child('profiles')->mkpath;
  $repo->child( 'profiles', 'repo_name' )->spew_raw('fake');
  $paludis->mkpath;
  $paludis->child('repositories')->mkpath;
  $paludis->child( 'repositories', 'gentoo.conf' )->spew_raw(<<"EOF");
location = \${ROOT}$repo
profiles = \${ROOT}$profiles
format = e
names_cache = $name_cache
EOF
  $paludis->child('general.conf')->spew_raw(<<"EOF");
world="$world"
EOF
  $ENV{HOME} = $tmpdir;
}

{
  open my $fh, '-|', 'cave', '--help'
    or BAIL_OUT('Cannot call cave --help, you probably lack the program required to use this module');
  my @lines = <$fh>;
  close $fh;
}
{
  open my $fh, '-|', 'cave', '--version'
    or BAIL_OUT('Cannot call cave --version, you probably lack the program required to use this module');
  my @lines = <$fh>;
  close $fh;
  diag(@lines);
}
{
  open my $fh, '-|', 'cave', 'print-commands', '--all'
    or BAIL_OUT('Cannot call cave print-commands --all, you probably lack a new enough copy of paluids');
  my @lines = <$fh>;
  close $fh;
}

pass("All cave calls execute successfully");

