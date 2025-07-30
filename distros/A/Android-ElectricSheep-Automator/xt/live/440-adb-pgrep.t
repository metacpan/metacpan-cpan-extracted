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

my ($name, $res);

# this should return many pids and their command name
$name = 'com.google';
$res = $mother->pgrep({'name' => $name});
ok(defined($res), 'Android::ElectricSheep::Automator->pgrep()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'ARRAY', 'Android::ElectricSheep::Automator->pgrep()'." : called and got good result which is an ARRAY.") or BAIL_OUT("no it is '".ref($res)."'");
ok(scalar(@$res) > 1, 'Android::ElectricSheep::Automator->pgrep()'." : called and got good result which is an ARRAY with more than 1 items.") or BAIL_OUT(perl2dump($res)."no it is above.");
for my $ares (@$res){
  for my $k ('pid', 'command'){
	ok(exists($ares->{$k}), 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
	ok(defined($ares->{$k}), 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
	ok($ares->{$k} !~ /^\s*$/, 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
  }
}

# this should return many pids but their command name will be ''
$name = 'com.google';
$res = $mother->pgrep({'name' => $name}, 'dont-show-command-name' => 1);
ok(defined($res), 'Android::ElectricSheep::Automator->pgrep()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'ARRAY', 'Android::ElectricSheep::Automator->pgrep()'." : called and got good result which is an ARRAY.") or BAIL_OUT("no it is '".ref($res)."'");
ok(scalar(@$res) > 1, 'Android::ElectricSheep::Automator->pgrep()'." : called and got good result which is an ARRAY with more than 1 items.") or BAIL_OUT(perl2dump($res)."no it is above.");
for my $ares (@$res){
  for my $k ('pid'){
	ok(exists($ares->{$k}), 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
	ok(defined($ares->{$k}), 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
	ok($ares->{$k} !~ /^\s*$/, 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
  }
  for my $k ('command'){ # this must exist but must be empty string
	ok(exists($ares->{$k}), 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
	ok(defined($ares->{$k}), 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
	#ok($ares->{$k} !~ /^\s*$/, 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
  }
}

# this is an exact match, it should return 1 pid
$name = '^com.google.android.calendar$';
$res = $mother->pgrep({'name' => $name});
ok(defined($res), 'Android::ElectricSheep::Automator->pgrep()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'ARRAY', 'Android::ElectricSheep::Automator->pgrep()'." : called and got good result which is an ARRAY.") or BAIL_OUT("no it is '".ref($res)."'");
is(scalar(@$res), 1, 'Android::ElectricSheep::Automator->pgrep()'." : called and got good result which is an ARRAY with exactly 1 item because an exact name was specified.") or BAIL_OUT(perl2dump($res)."no it is above.");
for my $ares (@$res){
  for my $k ('pid', 'command'){
	ok(exists($ares->{$k}), 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
	ok(defined($ares->{$k}), 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
	ok($ares->{$k} !~ /^\s*$/, 'Android::ElectricSheep::Automator->pgrep()'." : result is an ARRAY of hashes and this one contains key '$k'.") or BAIL_OUT(perl2dump($ares)."no it contains above.");
  }
}

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
 
sleep(1);

