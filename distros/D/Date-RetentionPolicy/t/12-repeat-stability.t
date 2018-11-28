#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok( 'Date::RetentionPolicy' ) or BAIL_OUT;
my $epoch_2018= 1514764800;
my $srand_value= defined $ENV{TEST_SRAND}? $ENV{TEST_SRAND} : time;
srand($srand_value);

my @dates= epoch_series_with_jitter('2018-01-01', '2017-10-01', hours => 6);

my @tests= (
	{
		name   => '4x daily for 2w, 1x daily for 2mo, 1x weekly for 1y',
		retain => [
			{ interval => { hours => 6 }, history => { days   =>  7 } },
			{ interval => { days  => 1 }, history => { months =>  1 } },
			{ interval => { days  => 7 }, history => { months =>  3 } },
		],
		reach  => .75,
	},
);
for my $t (@tests) {
	subtest $t->{name} => sub {
		my $rp= new_ok( 'Date::RetentionPolicy', [
			retain => $t->{retain},
			reference_date => $epoch_2018,
			reach_factor => $t->{reach},
			auto_sync => 1
		] );
		
		my @expected= @dates;
		$rp->prune(\@expected);
		
		# Now try again with various offsets to reference_date
		for (0..7*48) {
			my @again= @expected;
			$rp->reference_date($epoch_2018 - $_ * 30*60);
			my $pruned= $rp->prune(\@again);
			is_deeply( \@again, \@expected, 'with ref offset '.(-$_ * 30*60) )
				or diag "seed=$srand_value",
					$rp->visualize(\@expected),
					"pruned:\n",
					explain([ map ''.DateTime->from_epoch(epoch => $_), @$pruned ]);
		}
	};
}

sub epoch_series_with_jitter {
	my ($from, $until, @interval)= @_;
	my @ret;
	my $d0= DateTime::Format::Flexible->parse_datetime($from);
	my $ofs= $d0->epoch - $d0->clone->subtract(@interval)->epoch;
	$d0= $d0->epoch;
	my $dn= DateTime::Format::Flexible->parse_datetime($until)->epoch;
	while ($d0 >= $dn) {
		$d0 -= $ofs;
		push @ret, $d0 + int(rand($ofs/2));
	}
	@ret;
}

done_testing;
