#!perl 

use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
    use_ok 'Catmandu::Importer::MediaMosa';
}

require_ok 'Catmandu::Importer::MediaMosa';

my $base_url = $ENV{MM_URL} || "";
my $user     = $ENV{MM_USER} || "";
my $password = $ENV{MM_PWD} || "";

SKIP: {
    skip "No MediaMosa server environment settings found (MM_URL,"
	 . "MM_USER,MM_PWD).", 
	2 if (! $base_url || ! $user || ! $password);

    my $mm = Catmandu::Importer::MediaMosa->new(base_url => $base_url , user => $user , password => $password);

    ok($mm);

    my $count = $mm->take(20)->count();
    ok($count > 0);
    
    my $first = $mm->first;
   
    print Dumper($first);
    
}

done_testing 4;