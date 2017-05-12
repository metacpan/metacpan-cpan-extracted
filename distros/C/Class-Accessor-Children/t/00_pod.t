use strict;
use Test::More;

my $FILES = [qw(
	lib/Class/Accessor/Children.pm
	lib/Class/Accessor/Children/Fast.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;
