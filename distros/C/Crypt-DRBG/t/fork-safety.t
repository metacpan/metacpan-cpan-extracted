#!perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Crypt::DRBG::Hash;
use Crypt::DRBG::HMAC;
use Test::More;

my $state = 0;
my @tests = (
	{
		params => {seed => sub { $$ }, fork_safe => 1},
		desc => 'reseeds when fork safe',
	},
	{
		params => {auto => 1},
		desc => 'fork safe by default'
	},
	{
		params => {seed => sub { die if ++$state > 2; $$ }, fork_safe => 1},
		desc => 'does not keep reseeding',
	},
);
foreach my $test (@tests) {
	subtest $test->{desc} => sub {
		my %kids;
		my $obj = Crypt::DRBG::HMAC->new(%{$test->{params}});
		foreach my $kid (1..2) {
			pipe my $rfh, my $wfh;
			my $pid = fork;
			die 'No fork?' unless defined $pid;
			if ($pid > 0) {
				close($wfh);
				my @data = $rfh->getlines;
				chomp @data;
				$kids{$kid} = {
					data => join('', @data),
					pid => $pid,
				};
				waitpid($pid, 0);
			}
			else {
				close($rfh);
				for (1..2) {
					$wfh->print(unpack('H*', $obj->generate(10)), "\n");
				}
				exit;
			}
		}
		my $mine = $obj->generate(10) . $obj->generate(10);
		$mine = unpack('H*', $mine);
		isnt($mine, $kids{1}->{data}, "Data for kid 1 isn't mine");
		isnt($mine, $kids{2}->{data}, "Data for kid 2 isn't mine");
		isnt($kids{1}->{data}, $kids{2}->{data}, "kids are different");
	}
}

done_testing();
