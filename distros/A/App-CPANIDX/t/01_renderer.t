use strict;
use warnings;
use Test::More tests => 13;
use App::CPANIDX::Renderer;

my $data = [
  {
    'email' => 'chris@bingosnet.co.uk',
    'cpan_id' => 'BINGOS',
    'fullname' => 'Chris Williams'
  }
];

my %types = (
  'yaml', 'application/x-yaml; charset=utf-8',
  'json', 'application/json; charset=utf-8',
  'xml',  'application/xml; charset=utf-8',
  'html', 'text/html',
);

my @enc = App::CPANIDX::Renderer->renderers();
my @types = sort keys %types;

is_deeply( \@enc, \@types, 'We got the right renderers back' );

foreach my $enc ( qw(yaml json xml html) ) {
  my $ren = App::CPANIDX::Renderer->new( $data, $enc );
  isa_ok( $ren, 'App::CPANIDX::Renderer' );
  my ($type,$content) = $ren->render('auth');
  is( $type, $types{ $enc }, "$enc type is okay" );
  ok( $content, "There is $type content" );
}
