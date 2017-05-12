use Test::More qw(no_plan);
BEGIN { eval 'use Test::Pod' };

my $dir  = $ENV{PWD} =~ m#\/t$#  ? '../' : '';
my @modules = <${dir}lib/Authen/Tcpdmatch/*.pm>;

SKIP: {
	skip  'no Test::Pod', scalar @modules  unless $INC{'Test/Pod.pm'} ;
	pod_file_ok $_ , "pod $_ ok" for @modules;
} ;
