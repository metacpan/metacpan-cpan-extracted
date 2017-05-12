use Test::More ;
plan tests=>2;


my $dir   = $ENV{PWD} =~ m#\/t$#  ? '../' : '';
my $file1 = "${dir}lib/Class/DBI/Loader/Kinship.pm" ;
my $file2 = "${dir}lib/Class/DBI/Loader/k_Pg.pm" ;

my $found = eval 'use Test::Pod ; 1' ;

SKIP: {
	skip  'no Test::Pod', 2  unless $found ;
	pod_file_ok( $file1,  'Kinship.pm Pod ok') ;
	pod_file_ok( $file2 , 'k_Pg.pm    Pod ok') ;
} ;
