# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

use Mojo::Base -strict, -signatures;

use Test::More;
use Cavil::CLI::Archive;
use Cavil::CLI::Util qw(have_tool md5_file);
use Mojo::File       qw(path tempdir);

sub members ($file) { return split /\n/, `tar tzf @{[quotemeta $file]}` }

my $tree = tempdir;
$tree->child('src')->make_path->child('main.c')->spew("int main() { return 0; }\n");
$tree->child('node_modules', 'dep')->make_path->child('index.js')->spew("module.exports = 1;\n");
$tree->child('.gitignore')->spew("node_modules/\n");    # a real directory pattern, trailing slash and all
$tree->child('secret.env')->spew("TOKEN=xyz\n");
$tree->child('.cavilignore')->spew("*secret.env\n");
system('git', '-C', $tree->to_string, 'init', '-q');

my $outdir = tempdir;
my $out    = $outdir->child('archive.tar.gz')->to_string;

subtest 'packages vendored deps, drops .git and .cavilignore entries' => sub {
  my $md5 = Cavil::CLI::Archive->new(dir => $tree->to_string)->build($out);
  is $md5, md5_file($out), 'the returned checksum is the archive content hash';

  my @members = members($out);
  ok((grep {m!node_modules/dep/index\.js!} @members), 'installed node_modules is included');
  ok((grep {m!src/main\.c!} @members),                'source is included');
  ok(!(grep {m!/\.git/!} @members),                   '.git is excluded');
  ok(!(grep {m!secret\.env!} @members),               '.cavilignore entry is excluded');
};

subtest '--respect-gitignore also drops gitignored paths' => sub {
  Cavil::CLI::Archive->new(dir => $tree->to_string, respect_gitignore => 1)->build($out);
  my @members = members($out);
  ok(!(grep {m!node_modules!} @members), 'node_modules dropped when honouring .gitignore');
  ok((grep {m!src/main\.c!} @members),   'source is still included');
};

subtest 'identical content produces an identical archive, so Cavil can dedup a re-check' => sub {
  my $first = Cavil::CLI::Archive->new(dir => $tree->to_string)->build($out);

  # A second checkout has newer file mtimes; the archive must still hash the same.
  utime time, time, $_->to_string for $tree->child('src', 'main.c'), $tree->child('secret.env');
  my $again = Cavil::CLI::Archive->new(dir => $tree->to_string)->build("$out.2");
  is $again, $first, 'a rebuild of the same content has the same checksum';

  $tree->child('src', 'main.c')->spew("int main() { return 1; }\n");
  my $changed = Cavil::CLI::Archive->new(dir => $tree->to_string)->build("$out.3");
  isnt $changed, $first, 'changed content changes it';
};

subtest 'a missing directory is a clear error' => sub {
  eval { Cavil::CLI::Archive->new(dir => $tree->child('nope')->to_string)->build($out) };
  like $@, qr/Not a directory/, 'refuses a directory that does not exist';
};

subtest 'a missing external tool is a clear error, not a cryptic exit code' => sub {
  ok have_tool('tar'),                     'tar is found on a normal PATH';
  ok !have_tool('cavil-cli-no-such-tool'), 'a nonexistent command is not found';

  local $ENV{PATH} = '/cavil-cli-nonexistent';
  eval { Cavil::CLI::Archive->new(dir => $tree->to_string)->build($out) };
  like $@, qr/needs the 'tar' command/, 'names the missing tool instead of failing obscurely';
};

done_testing;
