#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

# NOTE: this does checks assuming no device is connected,
# so there is no testing enquire()
# this will be done in livetest

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
use MY::TestPlugin_Apps;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

my ($params, $sl, $tostring, $xmlfilename);

my $configfile = File::Spec->catfile($curdir, 't-config', 'plugins', 'mytestplugin_apps.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

$params = {
	'configfile' => $configfile
};
$sl = MY::TestPlugin_Apps->new($params);
ok(defined($sl), 'MY::TestPlugin_Apps->new()'." : called and got defined result.") or BAIL_OUT;

my $ret = $sl->test_call({'a'=>1, 'b'=>2});
is($ret, 0, 'MY::TestPlugin_Apps->test_call()'." : called and got defined result.") or BAIL_OUT;

# END
done_testing();
