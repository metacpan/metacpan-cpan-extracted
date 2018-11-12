#!perl -T
package App::fftrim;
use 5.006;
use strict;
use warnings;
use Test::More;
use App::fftrim;
our %length;
my @sources = qw(00000.MTS 00001.MTS 00002.MTS);
my @lengths = (2400, 3600, 4000);

my @s = @sources;
while (@s){ $length{pop @s} = pop @lengths }

my @test_data = (
	'12' => 12,
	'1:12' => 72,
	'1+12' => 2412,
	'1+2+12' => 6012,
	'1+2+1:12' => 6072,
	'2-12' => 2412,
	'3-12' => 6012,
	'3-1:12' => 6072,
);
my %test_data = @test_data;

while ( my ($k, $v) = splice @test_data,0,2 )
{
	is( int( abs ( seconds(decode_cutpoint($k,\@sources)) - $v ) - 0.01), 0, "decode pos $k");

}
done_testing();
