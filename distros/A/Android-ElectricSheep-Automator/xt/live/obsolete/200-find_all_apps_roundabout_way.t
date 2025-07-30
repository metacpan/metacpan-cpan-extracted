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

# we need to go to home screen because other tests may have messed up the screens
is($mother->home_screen(), 0, 'home_screen()'." : called and got good results.") or BAIL_OUT;

sleep(1);

my $res = $mother->find_all_apps_roundabout_way();
ok(defined($res), 'Android::ElectricSheep::Automator->find_all_apps_roundabout_way()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator->find_all_apps_roundabout_way()'." : called and got good result which is a HASH.") or BAIL_OUT("no it is '".ref($res)."'");
# this may not always work so don't check this.
#ok(scalar(keys %$res)>0, 'Android::ElectricSheep::Automator->find_all_apps_roundabout_way()'." : called and got good result which is a HASH and has some items in it.") or BAIL_OUT;

diag perl2dump($res);

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();

sleep(1);

