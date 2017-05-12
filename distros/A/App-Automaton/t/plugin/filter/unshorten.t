use Test::More;
use Data::Dumper;

use strict;
use warnings;

require_ok( 'App::Automaton::Plugin::Filter::Unshorten');


my $conf = {
    type => 'Unshorten',
};

my @queue = qw(
	https://tr.im/429e1
	http://ow.ly/Gc7RI
	http://bit.ly/1sHi667
	http://bit.do/VGZZ
	http://goo.gl/IGBHwm
	http://t.ted.com/Pa5p9zX]
	http://youtu.be/KVFkWWvMIpM
	https://www.youtube.com/watch?v=KVFkWWvMIpM
);

my @expect = qw(
	https://www.youtube.com/watch?v=KVFkWWvMIpM
	https://www.youtube.com/watch?v=KVFkWWvMIpM
	https://www.youtube.com/watch?v=KVFkWWvMIpM
	https://www.youtube.com/watch?v=KVFkWWvMIpM
	https://www.youtube.com/watch?v=KVFkWWvMIpM
	http://www.ted.com/talks/catherine_crump_the_small_and_surprisingly_dangerous_detail_the_police_track_about_you]
	https://www.youtube.com/watch?v=KVFkWWvMIpM&feature=youtu.be
	https://www.youtube.com/watch?v=KVFkWWvMIpM
);

my $u = App::Automaton::Plugin::Filter::Unshorten->new();
ok($u, 'new');

SKIP: {
	skip "Skipping actual download tests", 2 unless $ENV{'AUTOMATAN_TEST_DOWNLOADS'};

	ok($u->go($conf, \@queue), 'Go');
	is_deeply( \@queue, \@expect, 'unshorten');
}

done_testing();
