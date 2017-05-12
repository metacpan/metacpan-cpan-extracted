use strict;
use warnings;
use Test::More 'no_plan';
use CPANPLUS::Configure;
use CPANPLUS::Backend;

{
  require CPANPLUS::Internals::Source::MetaCPAN::HTTP;
  unless( my $req =
    CPANPLUS::Internals::Source::MetaCPAN::HTTP->new()->request(
      'http://api.metacpan.org/release'
    ) ) {
    ok('Pointless processing with Intawebs');
    exit 0;
  }
}

my $conf = CPANPLUS::Configure->new();
$conf->set_conf( enable_custom_sources => 0 );
$conf->set_conf( no_update => '1' );
$conf->set_conf( source_engine => 'CPANPLUS::Internals::Source::MetaCPAN' );
my $cb = CPANPLUS::Backend->new($conf);
my $mod = $cb->parse_module( module => 'LWP' );
isa_ok( $mod, 'CPANPLUS::Module' );
isa_ok( $mod->author, 'CPANPLUS::Module::Author' );
