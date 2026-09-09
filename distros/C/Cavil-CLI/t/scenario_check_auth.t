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

# The token authenticates, but the key is not allowed to submit (needs infra + write on the server).
get '/api/v1/whoami' => {json => {id => 1, user => 'reader', roles => ['user'], write_access => \0}};
post '/api/v1/packages/upload' =>
  sub ($c) { $c->render(json => {error => 'It appears you have insufficient permissions'}, status => 403) };

my $proj = tempdir;
$proj->child('file.c')->spew("int x;\n");
my $test = CavilCliTest->new(app);

subtest 'a key without submit access fails with a clear message' => sub {
  my $result = $test->run('--name', 'proj', $proj->to_string);
  isnt $result->{exit}, 0, 'a rejected submission is non-zero';
  like $result->{stderr}, qr/may not submit/, 'explains the key cannot submit';
};

done_testing;
