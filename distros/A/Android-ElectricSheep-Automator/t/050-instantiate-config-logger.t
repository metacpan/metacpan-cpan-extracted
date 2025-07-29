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
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, 't-config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $LOGFILE = File::Spec->catfile($tmpdir, 'adb.log');
my $log = Mojo::Log->new(path => $LOGFILE);
my $mother = Android::ElectricSheep::Automator->new({
	'configfile' => $configfile,
#	'verbosity' => $VERBOSITY,
	'logger' => $log
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;
$mother->log->info("testing!");
ok(-f $LOGFILE, 'Android::ElectricSheep::Automator->new()'." : output log file exists ($LOGFILE).") or BAIL_OUT;
ok(! -z $LOGFILE, 'Android::ElectricSheep::Automator->new()'." : output log file exists ($LOGFILE) and it is not empty.") or BAIL_OUT;

$LOGFILE = File::Spec->catfile($tmpdir, 'adb2.log');
$mother = Android::ElectricSheep::Automator->new({
	'configfile' => $configfile,
#	'verbosity' => $VERBOSITY,
	'logfile' => $LOGFILE
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;
$mother->log->info("testing!");
ok(-f $LOGFILE, 'Android::ElectricSheep::Automator->new()'." : output log file exists ($LOGFILE).") or BAIL_OUT;
ok(! -z $LOGFILE, 'Android::ElectricSheep::Automator->new()'." : output log file exists ($LOGFILE) and it is not empty.") or BAIL_OUT;

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
