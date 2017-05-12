#!perl -w

use strict;

use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin;
use Common;

use Data::Util qw(:all);

signeture 'Data::Util' => \&get_stash;

my $pkg = 'Data::Util';

cmpthese timethese -1 => {
	get_stash => sub{
		my $stash = get_stash($pkg);
	},
	direct => sub{
		my $stash = do{ no strict 'refs'; \%{$pkg . '::'}; };
	},
};
