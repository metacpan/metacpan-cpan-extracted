#!perl 

use Test::More tests => 6;

use lib qw{ lib local/lib/perl5 };

BEGIN {
	use_ok( 'Config::Simple::Extended' );
}

my $cfg = Config::Simple::Extended->new();

my @methods = ( 'inherit','parse_url_for_config_path' );
foreach my $method (@methods) {
  can_ok($cfg,$method);
}

$0 = 'supporters.cgi';
my $result;
my %test_cases = _get_test_cases();
foreach my $test (keys %test_cases){
  my $url = "$test/$0"; # '/11_parse_url_for_cfg_path.t';
  $result = $cfg->parse_url_for_config_path($url);
  is($result,$test_cases{$test},"Successfully derived configuration path from url: $test.");
}

diag( "Testing Config::Simple::Extended $Config::Simple::Extended::VERSION, Perl $], $^X" );

sub _get_test_cases {
  my %test_cases = (
        'http://supporters.runcynthiarun.org/nanGGA' => 'conf.d/supporters.runcynthiarun.org.nanGGA',
        'http://supporters.runcynthiarun.org' => 'conf.d/supporters.runcynthiarun.org',
        'http://supporters.votecobb.org' => 'conf.d/supporters.votecobb.org',
       );

  return %test_cases;
}
