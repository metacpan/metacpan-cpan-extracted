use Test::More;
use Data::Dumper;

require_ok( 'App::Automaton::Plugin::Action::TedTalks');


my $conf = {
    type => TedTalks,
    target => '.'
};

my $y = App::Automaton::Plugin::Action::TedTalks->new();
ok($y, 'new');


is(
	App::Automaton::Plugin::Action::TedTalks::_get_name('http://www.ted.com/talks/paola_antonelli_why_i_brought_pacman_to_moma'),
	'paola_antonelli_why_i_brought_pacman_to_moma.mp4',
	'_get_name'
);

SKIP: {
	skip "Skipping actual download tests", 2 unless $ENV{'AUTOMATAN_TEST_DOWNLOADS'};

	my $l = App::Automaton::Plugin::Action::TedTalks::_get_link('http://www.ted.com/talks/paola_antonelli_why_i_brought_pacman_to_moma');
	is($l, 'http://download.ted.com/talks/PaolaAntonelli_2013S-480p.mp4', '_get_link' );

	my $queue = [
		'https://www.youtube.com/watch?v=4XWHOAeuteI',
		'http://www.ted.com/talks/paola_antonelli_why_i_brought_pacman_to_moma',
		'http://ow.ly/FiTXV',
	];

	ok($y->go($conf, $queue), 'Go');
}

done_testing();

1;
