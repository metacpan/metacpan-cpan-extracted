#!perl -T

use Test::More tests => 6;
use Config::Param::FileWorker;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use File::Spec;

use strict;

# Testing the basic get() API, including automatic parsing of a present config file for this test.

my $dir = tempdir(CLEANUP => 1);
my $file = 'test.conf'; #File::Spec->catfile($dir, 'test.conf');

my %default =
(
	 parm1=>'a string'
	,parm2=>10
	,parmA=>[1, 2, 'free', 'beer']
	,parmH=>{key=>3, donkey=>'animal'}
	,parmX=>'Y'
	,const=>'unchanged'
);

my %modified =
(
	 parm1=>'a string!'
	,parm2=>7
	,parmA=>[1, 2, 'free', 'beer']
	,parmH=>{key=>3, donkey=>'animal', more=>'of it'}
	,parmX=>'Z'
	,const=>'changed anyway'
);

my @pardef =
(
	 'parm1', $default{parm1}, 'a', 'help text for scalar 1'
	,'parm2', $default{parm2}, 'b', 'help text for scalar 2'
	,'parmA', $default{parmA}, 'A', 'help text for array A'
	,'parmH', $default{parmH}, 'H', 'help text for hash H'
	,'const', $default{const}, '' , 'a constant thing'
	,'parmX', $default{parmX}, '',  'help text for last one (scalar)'
);

my @args = ('-b-=3', '--parm1.=!', '--parmH.=more=of it', '--parmX=Z');
my %config = ();

my $fw = Config::Param::FileWorker->new(\%config, dclone(\@pardef));

my $par = dclone($fw->param());
for( keys %{$fw->{pars}->builtins()} ){ delete $par->{$_}; }

is_deeply($par, \%default, 'defaults kept');

$default{const} = 'changed anyway';
$fw->param()->{const} = $default{const};
$fw->store_defaults();

$fw->init_with_args(\@args);

$par = dclone($fw->param());
for( keys %{$fw->{pars}->builtins()} ){ delete $par->{$_}; }
is_deeply($par, \%modified, 'arg parsing');

$fw->load_defaults();

$par = dclone($fw->param());
for( keys %{$fw->{pars}->builtins()} ){ delete $par->{$_}; }
is_deeply($par, \%default, 'back to modified default');

$fw->store_file($file);
my $oldpar = dclone($fw->param());

$fw->param()->{const} = 'changed again';

$fw->load_file($file);
my $newpar = dclone($fw->param());

is_deeply($newpar, $oldpar, 'preserved via config file');

# Let's also check that a param object can construct itself fully from the config file.
my $pw = Config::Param::->new();

ok($pw->parse_file($file,1), 'parse file with plain object');

my $oldsetup = [$fw->{pars}->current_setup()];
my $newsetup = [$pw->current_setup()];

is_deeply($newsetup->[1], $oldsetup->[1], 'set up of file worker and plain object');

