# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

use Mojo::Base -strict, -signatures;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use CavilCliTest;
use Mojo::File qw(path tempdir);
use Mojolicious::Lite;

app->log->level('error');

get '/api/v1/whoami' => {json => {id => 1, user => 'tester', roles => ['admin'], write_access => \1}};
post '/api/v1/packages/upload' => {json => {saved => {id => 7, name => 'proj', state => 'new'}, duplicate => \0}};
get '/api/v1/report/7' => [format => ['json']] => {
  json => {
    package         => {id       => 7, name => 'proj', state => 'new', unresolved_matches => 0},
    report          => {licenses => {MIT => {name => 'MIT', risk => 2, spdx => 'MIT'}}},
    risk            => 2,
    acceptable_risk => 4
  }
};

# The document is generated on demand: 408 first, ready second, so the client must poll.
my $pending = 1;
get '/api/v1/documents/7/spdx' => sub ($c) {
  return $c->render(text => 'being generated', status => 408) if $pending-- > 0;
  $c->render(json => {'@context' => 'https://spdx.org/rdf/3.0.1/spdx-context.jsonld'});
};

my $proj = tempdir;
$proj->child('file.c')->spew("int x;\n");
my $dest = tempdir;
my $sbom = $dest->child('out.spdx.json')->to_string;
my $test = CavilCliTest->new(app);

subtest '--sbom downloads the SPDX document, polling while it builds' => sub {
  my $result = $test->run('--name', 'proj', '--sbom', $sbom, $proj->to_string);
  is $result->{exit}, 0, 'a clean check still exits clean';
  ok -f $sbom, 'the SBOM was written';
  like path($sbom)->slurp, qr/spdx\.org/,        'and holds the SPDX content';
  like $result->{stdout},  qr/SBOM:.*out\.spdx/, 'the output names the file';
};

done_testing;
