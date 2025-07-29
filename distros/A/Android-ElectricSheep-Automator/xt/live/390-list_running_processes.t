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

# returns a hash of 'raw' and 'XML::LibXML'
my $res = $mother->list_running_processes();
ok(defined($res), 'Android::ElectricSheep::Automator->list_running_processes()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator->list_running_processes()'." : called and got good result which is a HASHref.") or BAIL_OUT("no it is '".ref($res)."'");
for ('raw', 'json', 'perl'){
	ok(exists($res->{$_}), 'Android::ElectricSheep::Automator->list_running_processes()'." : result contains key '$_'.") or BAIL_OUT("--BEGIN result:\n${res}\n--END result.\nno it is as above.");
	ok(defined($res->{$_}), 'Android::ElectricSheep::Automator->list_running_processes()'." : result contains key '$_' which is defined.") or BAIL_OUT("--BEGIN result:\n${res}\n--END result.\nno it is as above.");
}
ok($res->{'raw'}=~/\bPID\b/, 'Android::ElectricSheep::Automator->list_running_processes()'." : called and got good result which has word 'PID' in it.") or BAIL_OUT("--BEGIN result:\n".perl2dump(${res})."--END result.\nno it is as above.");
is(ref($res->{'perl'}), 'HASH', 'Android::ElectricSheep::Automator->list_running_processes()'." : called and got good result which contains key 'perl' which is a HASHref.") or BAIL_OUT("--BEGIN result:\n".perl2dump(${res})."--END result.\nno it is as above.");

# now save it to a file
my $outfile = File::Spec->catfile($tmpdir, 'ui.xml');
my @extrafields = ('TTY', 'TIME');
$res = $mother->list_running_processes({
	'filename' => $outfile,
	'extra-fields' => \@extrafields
});
ok(defined($res), 'Android::ElectricSheep::Automator->list_running_processes()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator->list_running_processes()'." : called and got good result which is a HASHref.") or BAIL_OUT("no it is '".ref($res)."'");
for ('raw', 'json', 'perl'){
	ok(exists($res->{$_}), 'Android::ElectricSheep::Automator->list_running_processes()'." : result contains key '$_'.") or BAIL_OUT("--BEGIN result:\n${res}\n--END result.\nno it is as above.");
	ok(defined($res->{$_}), 'Android::ElectricSheep::Automator->list_running_processes()'." : result contains key '$_' which is defined.") or BAIL_OUT("--BEGIN result:\n${res}\n--END result.\nno it is as above.");
}
ok($res->{'raw'}=~/\bPID\b/, 'Android::ElectricSheep::Automator->list_running_processes()'." : called and got good result which has word 'PID' in it.") or BAIL_OUT("--BEGIN result:\n".perl2dump(${res})."--END result.\nno it is as above.");
is(ref($res->{'perl'}), 'HASH', 'Android::ElectricSheep::Automator->list_running_processes()'." : called and got good result which contains key 'perl' which is a HASHref.") or BAIL_OUT("--BEGIN result:\n".perl2dump(${res})."--END result.\nno it is as above.");
# check that extra fields are present
for my $ef (@extrafields){
	for my $k (sort keys %{ $res->{'perl'} }){
		ok(exists($res->{'perl'}->{$k}->{$ef}), 'Android::ElectricSheep::Automator->list_running_processes()'." : result contains extra field '$k'.") or BAIL_OUT(perl2dump($res->{'perl'}->{$k})."no, see above data missing this key.");
	}
}
ok(-f $outfile, 'Android::ElectricSheep::Automator->list_running_processes()'." : called and result saved to output file '$outfile'.") or BAIL_OUT;

diag $res->{'raw'};

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
 
sleep(1);

