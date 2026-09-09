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

# A mock Cavil: authenticate, accept an upload, then serve a report. The report's risk and how many times it is
# still "being indexed" are set per subtest, so one mock covers the clean, pending and gate cases.
my ($upload, $pending, $risk, $accept);
get '/api/v1/whoami' => {json => {id => 1, user => 'tester', roles => ['admin'], write_access => \1}};
post '/api/v1/packages/upload' => sub ($c) {
  $upload = {
    name      => $c->param('name'),
    priority  => $c->param('priority'),
    checksum  => $c->param('checksum'),
    ephemeral => $c->param('ephemeral'),
    tarball   => ($c->req->upload('tarball') ? 1 : 0)
  };
  $c->render(json => {saved => {id => 42, name => $c->param('name'), state => 'new'}, duplicate => \0});
};
get '/api/v1/report/42' => [format => ['json']] => sub ($c) {
  return $c->render(json => {stage => 'indexing'}, status => 408) if $pending-- > 0;
  $c->render(
    json => {
      package => {id => 42, name => 'proj', state => 'new', unresolved_matches => 0},
      report  => {
        licenses => {
          MIT            => {name => 'MIT',          risk => 2,     spdx => 'MIT'},
          'GPL-3.0-only' => {name => 'GPL-3.0-only', risk => $risk, spdx => 'GPL-3.0-only'}
        }
      },
      risk            => $risk,
      acceptable_risk => $accept
    }
  );
};

my $proj = tempdir;
$proj->child('main.c')->spew("int main() { return 0; }\n");
my $test = CavilCliTest->new(app);

subtest 'a clean project uploads, is reviewed, and passes the gate' => sub {
  ($pending, $risk, $accept) = (0, 2, 4);
  my $result = $test->run('--name', 'proj', $proj->to_string);
  is $result->{exit}, 0, 'a project below the threshold exits clean';
  like $result->{stdout}, qr/proj - risk 2 \(permissive\) within threshold 5/, 'headline states the verdict';
  like $result->{stdout}, qr/MIT/,                                             'lists the licenses found';
  like $result->{stdout}, qr{/reviews/details/42},                             'links the web report';
  is $upload->{tarball}, 1, 'a tarball was uploaded';
  like $upload->{checksum}, qr/^[a-f0-9]{32}$/, 'with its MD5 checksum';
  is $upload->{name},      'proj', 'under the requested name';
  is $upload->{ephemeral}, 1,      'and asks for a one-off, side-effect-free review';
};

subtest 'polls until the review finishes' => sub {
  ($pending, $risk, $accept) = (1, 2, 4);
  my $result = $test->run('--name', 'proj', $proj->to_string);
  is $result->{exit}, 0, 'a 408-then-200 report is waited out';
};

subtest 'risk at or above the threshold fails the gate' => sub {
  ($pending, $risk, $accept) = (0, 6, 4);
  my $result = $test->run('--name', 'proj', $proj->to_string);
  is $result->{exit}, 1, 'risk 6 with threshold 5 fails';
  like $result->{stdout}, qr/risk 6 \(restrictive obligations\).*threshold 5/, 'headline shows the gate was crossed';
};

subtest '--fail-on-risk overrides the instance default' => sub {
  ($pending, $risk, $accept) = (0, 3, 4);
  my $result = $test->run('--name', 'proj', '--fail-on-risk', '3', $proj->to_string);
  is $result->{exit}, 1, 'risk 3 fails when the gate is lowered to 3';
};

done_testing;
