use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;

use Colouring::In::XS;

my $dir = Colouring::In::XS->include_dir;
ok(-d $dir, 'include_dir names a directory');
ok(-f "$dir/colouring.h", 'holding colouring.h');

my $tree = tempdir(CLEANUP => 1);
mkdir "$tree/include";
{
	local $INC{'Colouring/In/XS.pm'} = "$tree/lib/Colouring/In/XS.pm";
	is(Colouring::In::XS->include_dir, "$tree/include", 'a source tree answers its include directory');
}

my $bare = tempdir(CLEANUP => 1);
{
	local $INC{'Colouring/In/XS.pm'} = "$bare/Colouring/In/XS.pm";
	is(Colouring::In::XS->include_dir, "$bare/Colouring/In/XS/include", 'with neither present, the installed place');
}

done_testing;
