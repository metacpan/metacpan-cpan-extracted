#!perl -T

use Test::More tests => 9;

# Here we're testing 80 01 updates which send song info.  these also need to call a function (the event system).  Updates on ch# 22.
our $called = 0;


BEGIN {
	my %UPDATES = (
		'16050110506574657220496c796963682054636802104672616e63657363612064612052696d06094f72636865737472618605244f3336318803386671'
# Item type: 1 Info: Peter Ilyich Tch
# Item type: 2 Info: Francesca da Rim
# Item type: 6 Info: Orchestra
# Item type: 134 Info: $O361
			=> {
		'artist' => 'Peter Ilyich Tch',
		'title' => 'Francesca da Rim',
		'composer' => 'Orchestra',
		'pid' => '$O361'
		},
		'16040104494e5853020c446f6e2774204368616e67658605244f4a495588023673'
# Item type: 1 Info: INXS
# Item type: 2 Info: Don't Change
# Item type: 134 Info: $OJIU
			=> {
		'artist' => 'INXS',
		'title' => "Don't Change",
		'composer' => undef,
		'pid' => '$OJIU'
		}
	);



	require Audio::Radio::Sirius;

	my $tuner = new Audio::Radio::Sirius;
	$tuner->set_callback('channel_update', \&my_callback);

	foreach $item (keys %UPDATES) {
		my $artist = $UPDATES{$item}{'artist'};
		my $title = $UPDATES{$item}{'title'};
		my $composer = $UPDATES{$item}{'composer'};
		my $pid = $UPDATES{$item}{'pid'};

		$tuner->_channel_item_update(pack ('H*', $item) );

		is ($tuner->{'channels'}{22}{'artist'}, $artist);
		is ($tuner->{'channels'}{22}{'title'}, $title);
		is ($tuner->{'channels'}{22}{'composer'}, $composer);
		is ($tuner->{'channels'}{22}{'pid'}, $pid);
	}

	is ($main::called, 2, 'Ensure callback function hit twice');

sub my_callback {
	my ($channel) = @_;
	if (defined($channel)) { $main::called++; }
}
		
}

