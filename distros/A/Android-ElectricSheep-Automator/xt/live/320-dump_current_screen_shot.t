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
use Android::ElectricSheep::Automator::AppProperties;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', '..', 't', 't-config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $mother = Android::ElectricSheep::Automator->new({
	'configfile' => $configfile,
	#'verbosity' => $VERBOSITY,
	# we have a device connected and ready to control
	'device-is-connected' => 1,
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;

my $res = $mother->dump_current_screen_shot();
ok(defined($res), 'Android::ElectricSheep::Automator->dump_current_screen_shot()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'Image::PNG', 'Android::ElectricSheep::Automator->dump_current_screen_shot()'." : called and got good result which is of class 'Image::PNG'.") or BAIL_OUT("no it is '".ref($res)."'");

# now save it to a file
my $outfile = File::Spec->catfile($tmpdir, 'screenshot.png');
$res = $mother->dump_current_screen_shot({
	'filename' => $outfile
});
ok(defined($res), 'Android::ElectricSheep::Automator->dump_current_screen_shot()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'Image::PNG', 'Android::ElectricSheep::Automator->dump_current_screen_shot()'." : called and got good result which is a Image::PNG object.") or BAIL_OUT("no it is '".ref($res)."'");
ok(-f $outfile, 'Android::ElectricSheep::Automator->dump_current_screen_shot()'." : called and result saved to output file '$outfile'.") or BAIL_OUT;

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
 
sleep(1);

