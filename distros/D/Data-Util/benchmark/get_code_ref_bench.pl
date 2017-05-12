#!perl -w

use strict;

use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin;
use Common;

use Data::Util qw(:all);

signeture 'Data::Util' => \&get_code_ref;

my $pkg  = 'Data::Util';
my $name = 'get_code_ref';

cmpthese timethese -1 => {
	get_code_ref => sub{
		my $code = get_code_ref($pkg, $name);
	},
	direct => sub{
		my $code = do{ no strict 'refs'; *{$pkg . '::' . $name}{CODE}; };
	},
};
