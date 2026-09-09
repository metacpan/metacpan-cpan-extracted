# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

use Mojo::Base -strict, -signatures;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use CavilCliTest;
use Mojo::File qw(tempdir);
use Mojolicious::Lite;

app->log->level('error');

my ($uploaded, $reject);
get '/api/v1/whoami' => {json => {id => 1, user => 'tester', roles => ['admin'], write_access => \1}};
post '/api/v1/packages/upload' => sub ($c) {
  $uploaded++;
  return $c->render(json => {error => 'too large'}, status => 413) if $reject;
  $c->render(json => {saved => {id => 1, name => 'proj', state => 'new'}, duplicate => \0});
};

my $proj = tempdir;
$proj->child('file.c')->spew("int x;\n");
my $test = CavilCliTest->new(app);

subtest 'refuses to upload an archive over the size limit, before uploading' => sub {
  ($uploaded, $reject) = (0, 0);
  my $r = $test->run_with_env({CAVIL_URL => $test->url, CAVIL_API_KEY => 'test-token', CAVIL_MAX_UPLOAD_MB => 0},
    'check', '--name', 'proj', $proj->to_string);
  is $r->{exit}, 2, 'a too-large archive is a usage error';
  like $r->{stderr}, qr/over the 0 MiB upload limit/,  'names the limit';
  like $r->{stderr}, qr/\.cavilignore|--exclude-path/, 'and how to trim it';
  is $uploaded, 0, 'and never attempts the upload';
};

subtest 'a server size rejection (413) is a clear message, not a raw status' => sub {
  ($uploaded, $reject) = (0, 1);
  my $r = $test->run('--name', 'proj', $proj->to_string);
  isnt $r->{exit}, 0, 'a rejected upload is non-zero';
  like $r->{stderr}, qr/too large for this Cavil instance/, 'explains the archive was too large';
  is $uploaded, 1, 'the upload was attempted (the tiny archive passed the client gate)';
};

done_testing;
