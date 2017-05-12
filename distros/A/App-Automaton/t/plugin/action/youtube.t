use strict;
use warnings;
use Test::More;

require_ok( 'App::Automaton::Plugin::Action::YouTube');

my $conf = {
    type => 'YouTube',
    target => '.'
};

my $y = App::Automaton::Plugin::Action::YouTube->new();
ok($y, 'new');

SKIP: {
	skip "Skipping actual download tests", 1 unless $ENV{'AUTOMATAN_TEST_DOWNLOADS'};
	
	my $queue = [
		'https://www.youtube.com/watch?v=jTAPsVXLu1I',
		'https://www.youtube.com/watch?v=GD3y7ylpqO8',
		'https://www.youtube.com/watch?v=4XWHOAeuteI'
	];
	ok($y->go($conf, $queue), 'Go');
}

done_testing();
