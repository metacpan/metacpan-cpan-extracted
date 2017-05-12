#!perl -T

use Test::More tests => 2;
use Config::Param;
use Storable qw(dclone);

# Testing object functionality which hasn't been tested implicitly yet.

my %default =
(
	 parm1=>'a string'
	,parm2=>10
	,parmA=>[1, 2, 'free', 'beer']
	,parmH=>{'key'=>3, 'donkey'=>'animal'}
	,parmX=>'Y'
	,const=>'unchanged'
);

# sorted by name!
my @pardef =
(
	 'const', $default{const}, '' , 'a constant thing'
	,'parm1', $default{parm1}, 'a', 'help text for scalar 1'
	,'parm2', $default{parm2}, 'b', 'help text for scalar 2'
	,'parmA', $default{parmA}, 'A', 'help text for array A'
	,'parmH', $default{parmH}, 'H', 'help text for hash H'
	,'parmX', $default{parmX}, '',  'help text for last one (scalar)'
);


my @p;
my %config = (verbose=>0, program=>'uninteresting');

my $param = Config::Param->new(dclone(\%config), dclone(\@pardef)); 
my ($parconf, $pardef) = $param->current_setup();

delete $parconf->{confdir};
is_deeply($parconf, \%config, 'config match');
is_deeply($pardef, \@pardef, 'pardef match');

