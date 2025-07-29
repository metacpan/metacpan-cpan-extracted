#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

#use utf8;

our $VERSION = '0.05';

use Test::More;
use Test::More::UTF8;
use FindBin;
use Test::TempDir::Tiny;
use Mojo::Log;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Android::ElectricSheep::Automator;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

# if for debug you change this make sure that it has path in it e.g. ./xyz
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
#ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', '..', 't', 't-config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $mother = Android::ElectricSheep::Automator->new({
	'configfile' => $configfile,
	#'verbosity' => $VERBOSITY,
	# we have a device connected and ready to control
	'device-is-connected' => 1,
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;

my ($params, $res);

# left
$params = {
	'direction' => 'left'
};
$res = $mother->swipe($params);
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->swipe()'." : called and got good result.") or BAIL_OUT;
sleep(1);
$params = {
	'direction' => 'right'
};
$res = $mother->swipe($params);
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->swipe()'." : called and got good result.") or BAIL_OUT;

sleep(1);
$res = $mother->home_screen();
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->home_screen()'." : called and got good result.") or BAIL_OUT;
sleep(1);

# right
$params = {
	'direction' => 'right'
};
$res = $mother->swipe($params);
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->swipe()'." : called and got good result.") or BAIL_OUT;
sleep(1);
$params = {
	'direction' => 'left'
};
$res = $mother->swipe($params);
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->swipe()'." : called and got good result.") or BAIL_OUT;

sleep(1);
$res = $mother->home_screen();
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->home_screen()'." : called and got good result.") or BAIL_OUT;
sleep(1);

# up
$params = {
	'direction' => 'up'
};
$res = $mother->swipe($params);
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->swipe()'." : called and got good result.") or BAIL_OUT;
sleep(1);
$params = {
	'direction' => 'down'
};
$res = $mother->swipe($params);
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->swipe()'." : called and got good result.") or BAIL_OUT;

sleep(1);
$res = $mother->home_screen();
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->home_screen()'." : called and got good result.") or BAIL_OUT;
sleep(1);

# down
$params = {
	'direction' => 'down'
};
$res = $mother->swipe($params);
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->swipe()'." : called and got good result.") or BAIL_OUT;
sleep(1);
$params = {
	'direction' => 'up'
};
$res = $mother->swipe($params);
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->swipe()'." : called and got good result.") or BAIL_OUT;

sleep(1);
$res = $mother->home_screen();
ok(defined($res) && ($res==0), 'Android::ElectricSheep::Automator->home_screen()'." : called and got good result.") or BAIL_OUT;
sleep(1);

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
 
sleep(1);

