#!perl -T

use Test::More tests => 6;
use Config::Param;
use Storable qw(dclone);

use strict;

# Testing the basic get() API, including automatic parsing of a present config file for this test.

my %default =
(
	 parm1=>'a string'
	,parm2=>10
	,parmA=>[1, 2, 'free', 'beer']
	,parmH=>{'key'=>3, 'donkey'=>'animal'}
	,parmX=>'Y'
	,const=>'unchanged'
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
@ARGV = @args;
my @p;
my %config = ();
$config{verbose} = 0;
my $builtins = Config::Param::builtins(\%config);

#$Config::Param::verbose = 1;

# first plain comparison without config file
$config{nofile} = 1; # yeah, looks funny
$p[0] = Config::Param::get(dclone(\%config),dclone(\@pardef),[]);
for my $b (keys %{$builtins}){ delete $p[0]->{$b}; }

# cmd line changes
my %afterfact = %{dclone(\%default)};
$afterfact{parm2} -= 3;
$afterfact{parm1} .= '!';
$afterfact{parmH}{more} = "of it";
$afterfact{parmX} = 'Z';

is_deeply($p[0], \%default, "result of get() call 0 (no config file)");

delete $config{nofile};

# Always provide copies to separate things!

@ARGV = @args;
$p[0] = Config::Param::get(@{dclone(\@pardef)});
@ARGV = @args;
$p[1] = Config::Param::get(dclone(\@pardef));
@ARGV = @args;
$p[2] = Config::Param::get(dclone(\%config),dclone(\@pardef));
$p[3] = Config::Param::get(dclone(\%config),dclone(\@pardef),dclone(\@args));

# alternate parameter specification via array / hash refs
@pardef =
(
	 ['parm1', $default{parm1}, 'a', 'help text for scalar 1']
	,['parm2', $default{parm2}, 'b', 'help text for scalar 2']
	,['parmA', $default{parmA}, 'A' ] # allowed to omit an entry
	,{long=>'parmH', value=>$default{parmH}, short=>'H', help=>'help text for hash H'}
	,['const', $default{const}, '' , 'a constant thing']
	,['parmX', $default{parmX}, '',  'help text for last one (scalar)']
);
$p[4] = Config::Param::get(dclone(\%config),dclone(\@pardef),dclone(\@args));


# the config file changes values a bit
%afterfact = %{dclone(\%default)};
$afterfact{parm2} = 42;
$afterfact{parm1} = 'some line without end';
push(@{$afterfact{parmA}}, '"addendum', 'addendum maximo');
$afterfact{parmH}{twinkie} = "text with\nmultiple lines that\nbreak\n";

#then the command line args
$afterfact{parm2} -= 3;
$afterfact{parm1} .= '!';
$afterfact{parmH}{more} = "of it";
$afterfact{parmX} = 'Z';

my $i;
for my $p (@p)
{
	++$i;
	# ignore builtins
	for my $b (keys %{$builtins}){ delete $p->{$b}; }
	# now the values should be identical
	is_deeply($p, \%afterfact, "result of get() call $i");
}
