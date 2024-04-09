#!perl -T

use 5.008;

use strict;
use warnings;

our $VERSION='0.21';

######################################################
# this test fails because of YAML v1.30
# see:
#    https://github.com/ingydotnet/yaml-pm/issues/224
######################################################

use Test::More;
use Test2::Plugin::UTF8;
use YAML::PP;

my $perl = [
	{
		"\"aaa'bbb" => "aaa",
		"bbb" => 1,
	}
];

my $ypp = YAML::PP->new;
ok(defined($ypp), 'YAML::PP->new()'." : called and got defined result");

my $yamlstr = $ypp->dump_string($perl);
ok(defined($yamlstr), 'dump_string()'." : called and got defined result");
ok($yamlstr =~ /^\-\-\-/, 'dump_string()'." : called and looks like a yaml string");

my $newperl = $ypp->load_string($yamlstr);
ok(defined($newperl), 'load_string()'." : called and got good result");

is_deeply($perl, $newperl, 'load_string()'." : result is exactly the same as the data structure we started with");

done_testing;

1;
__END__
