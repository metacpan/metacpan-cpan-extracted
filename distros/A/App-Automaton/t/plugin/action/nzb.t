use Test::More;
use Data::Dumper;

require_ok( 'App::Automaton::Plugin::Action::NZB');


my $conf = {
    type => NZB,
    target => '.'
};

my $y = App::Automaton::Plugin::Action::NZB->new();
ok($y, 'new');

# get_name test
my $name_input = 'https://abc!@#$%def^&*()ghi    jkl-_';
my $name_expect = 'abc_____def_____ghi____jkl-_.nzb';
my $name = App::Automaton::Plugin::Action::NZB::_get_name($name_input);
is($name, $name_expect, '_get_name');

SKIP: {
	skip "Skipping actual download tests", 1 unless $ENV{'AUTOMATAN_TEST_DOWNLOADS'};
	
	my $queue = [
		'http://www.nzbsearch.net/nzb_get.aspx?mid=N8NTC',
		'https://www.nzb-rss.com/nzb/32039-James.Mays.Man.Lab.S03E01.HDTV.x264-FTP.nzb'
	];
	ok($y->go($conf, $queue), 'Go');
}

done_testing();

1;
