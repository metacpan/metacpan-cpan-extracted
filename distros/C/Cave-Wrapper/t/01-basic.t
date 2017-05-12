
use strict;
use warnings;

use Test::More tests => 2;
use Test::Fatal;
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

use Cave::Wrapper;

my @commands;

note "Tempdir in $tmpdir";

is(
  exception {
    my $cave = Cave::Wrapper->new();

    @commands = $cave->print_commands(qw(--all));

  },
  undef,
  'Call Succeeds'
);

is_deeply( [ grep { $_ =~ /^print-commands$/ } @commands ], ['print-commands'], 'print-commands shows print-commands' );

for my $command (@commands) {
  note $command;
}
