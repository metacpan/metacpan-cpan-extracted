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

use Data::Roundtrip qw/:all/;
use Data::Random::Structure::UTF8;

use Test::More;
use Test2::Plugin::UTF8;
use YAML;
use Data::Dumper;

$Data::Dumper::Useperl = 1;
$Data::Dumper::Useqq='utf8';

my $perl = [
	{
		"\"aaa'bbb" => "aaa",
		"bbb" => 1,
	}
];
my $yamlstr = eval { Dump($perl) };
# $yamlstr CURRENTLY (YAML 1.30) is not defined
ok(! $@, "eval'ing YAML::Dump() : eval did not fail.")
  or BAIL_OUT(Dumper($perl)."above data structure failed for YAML::Dump(): $@");
ok(defined($yamlstr), "YAML::Dump() : called and got defined result.")
  or BAIL_OUT(Dumper($perl)."above data structure failed for YAML::Dump(): $@");

my $pd = eval { Load($yamlstr) };
# just print this if this is the case and exit the tests, it means YAML
# has not been fixed yet
if( $@ || ! defined($pd) ){
	diag("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\nit seems YAML (v.".$YAML::VERSION.") has not been fixed yet,\n$@\n# bailing out.\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
	done_testing;
	exit(0);
}
ok(! $@, "eval'ing YAML::Load() : eval did not fail.")
  or BAIL_OUT(Dumper($perl)."above data structure failed for YAML::Load(): $@");
ok(defined($pd), "YAML::Load() : called and got defined result.")
  or BAIL_OUT(Dumper($perl)."and YAML string:\n$yamlstr\nabove data structure failed for YAML::Load(): $@");

done_testing;

1;
__END__
