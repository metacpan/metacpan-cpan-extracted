use Test::More tests => 7;
use strict;

use lib 't/';

BEGIN {
	use_ok('CGI::Application');
};

use TestAppAttributeParsing;
use CGI;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my @runmodes = qw|
  single_quotes_space
  double_quotes_space
  single_quotes_tab
  double_quotes_tab
  single_quotes_tab_space
  double_quotes_tab_space
|;

foreach my $runmode ( @runmodes )
{
  local $ENV{PATH_INFO} = '/' . $runmode;
  my $app = TestAppAttributeParsing->new();
  my $output = $app->run();
  my $expected_output = 'Runmode: ' . $runmode;

  like($output, qr/$expected_output/);
}
