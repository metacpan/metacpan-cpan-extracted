#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

#use utf8;

our $VERSION = '0.06';

use Test::More;
use Test::More::UTF8;
use FindBin;
use Test::TempDir::Tiny;
use Mojo::Log;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Android::ElectricSheep::Automator::ScreenLayout;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

my ($params, $sl, $tostring, $xmlfilename);

# must succeed
$params = {
  'data' => {
	'w' => 100,
	'h' => 150,
	'top-area' => [10,20,30,40,50,60],
	'app-icons-area' => [1,2,3,4,5,6],
	'dock-divider-area' => [11,12,13,14,15,16],
	'hotseat-area' => [21,22,23,24,25,26],
	'home-buttons-area' => [1000, 2000, 3000, 4000, 5000, 6000],
  }
};
$sl = Android::ElectricSheep::Automator::ScreenLayout->new($params);
ok(defined($sl), 'Android::ElectricSheep::Automator::ScreenLayout->new()'." : called and got defined result.") or BAIL_OUT;

for my $k (sort keys %{$params->{'data'}}){
	my $v = $params->{'data'}->{$k};
	is_deeply($sl->get($k), $v, 'Android::ElectricSheep::Automator::ScreenLayout->new()'." : key '$k' was set to value '".(ref($v)eq''?$v:('['.join(',',@$v).']'))."' OK.") or BAIL_OUT("no it was set to this value instead '".(ref($sl->get($k))eq''?$sl->get($k):('['.join(',',@{$sl->get($k)}).']'))."'.");
}

$tostring = $sl->toString();
ok(defined $tostring, 'toString()'." : called and got good result.") or BAIL_OUT;

diag "Results:\n".$tostring;

diag "Results with operator overloaded:\n".$sl;

#######

# must fail
$params = {
  'data' => {
	'w' => [1,1,1,1], # wrong type, this is not a scalar!
	'h' => 150,
	'top-area' => [10,20,30,40,50,60],
	'app-icons-area' => [1,2,3,4,5,6],
	'dock-divider-area' => [11,12,13,14,15,16],
	'hotseat-area' => [21,22,23,24,25,26],
	'home-buttons-area' => [1000, 2000, 3000, 4000, 5000, 6000],
  }
};
$sl = Android::ElectricSheep::Automator::ScreenLayout->new($params);
ok(!defined($sl), 'Android::ElectricSheep::Automator::ScreenLayout->new()'." : called and got defined result.") or BAIL_OUT;

# from XML
$xmlfilename = File::Spec->catfile($curdir, 't-data', 'example-screen-layout.xml');
ok(-f $xmlfilename, "A Screen layout dumped to XML file '${xmlfilename}' exists.") or BAIL_OUT;
$params = {
	'xml-filename' => $xmlfilename
};
$sl = Android::ElectricSheep::Automator::ScreenLayout->new($params);
ok(defined($sl), 'Android::ElectricSheep::Automator::ScreenLayout->new()'." : called and got defined result.") or BAIL_OUT;

$tostring = $sl->toString();
ok(defined $tostring, 'toString()'." : called and got good result.") or BAIL_OUT;

diag "Results:\n".$tostring;

diag "Results with operator overloaded:\n".$sl;


# END
done_testing();
