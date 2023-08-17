use strict;
use warnings;
use Test::More;

plan skip_all => 'TEST_DOCSISISOUS=1' unless $ENV{TEST_DOCSISISOUS};

require Mojo::File;
require Test::Mojo;

$ENV{DOCSIS_STORAGE} = Mojo::File::path(qw(t storage))->to_abs->to_string;
do(Mojo::File::path(qw(script docsisious))->to_abs) or die $@;
my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->element_exists('form[action="/"][method="POST"]')
  ->element_exists('form button[name="save"][value="1"]')
  ->element_exists('form button[name="download"][value="1"]')
  ->element_exists('form input[name="filename"]')
  ->element_exists('form input[name="shared_secret"]')
  ->element_exists('form textarea[name="config"]');

$t->post_ok('/', form => {})->status_is(400);

my $config = <<'HERE';
NetworkAccess: 1
GlobalPrivacyEnable: 1
MaxCPE: 1
HERE

$t->post_ok('/', form => {save => 1})->status_is(400);
$t->post_ok('/', form => {save => 1, config => $config})->status_is(302)
  ->header_like(Location => qr{^/edit/\w+$});

my $id = $t->tx->res->headers->location;
$id =~ s!.*/!!;
$t->get_ok("/edit/$id")->status_is(200)
  ->text_like('form textarea[name="config"]', qr{NetworkAccess: 1});
$t->post_ok('/', form => {config => $config, id => $id, save => 1})->status_is(302)
  ->header_is(Location => "/edit/$id");
$t->post_ok('/', form => {config => $config, id => $id, download => 1})->status_is(200)
  ->header_is('Content-Disposition', "attachment; filename=$id.bin");

my $binary = $t->tx->res->body;
eval { DOCSIS::ConfigFile::decode_docsis($binary) };
ok !$@, 'decode_docsis body' or diag $@;

$t->post_ok('/', form => {config => $config, id => $id, save => 1, filename => 'test.bin'})
  ->status_is(302);
$t->post_ok('/', form => {config => $config, id => $id, download => 1, filename => 'foo.bin'})
  ->status_is(200)->header_is('Content-Disposition', "attachment; filename=foo.bin");

$t->post_ok('/', form => {binary => {content => $binary, filename => 'x.bin'}})->status_is(200)
  ->element_exists('form input[name="filename"][value="x.bin"]')
  ->text_like('form textarea[name="config"]', qr{NetworkAccess: 1});

done_testing;
