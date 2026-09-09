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

get '/api/v1/whoami' => {json => {id => 1, user => 'tester', roles => ['admin'], write_access => \1}};
post '/api/v1/packages/upload' => sub ($c) { $c->render(json => {error => 'boom'}, status => 500) };

my $dir = tempdir;
$dir->child('file.txt')->spew("some content\n");

my $test = CavilCliTest->new(app);

subtest 'a server error during upload exits with the server code and explains itself' => sub {
  my $result = $test->run($dir->to_string);
  is $result->{exit}, 3, 'server error exit code';
  like $result->{stderr}, qr/response from Cavil/, 'the error names Cavil';
};

done_testing;
