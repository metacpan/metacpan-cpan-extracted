#!perl 

use v5.10;
use strict;
use warnings;
use Test::More;
use Catmandu::MediaMosa;
use Data::Dumper;

my $base_url = $ENV{MM_URL} || "";
my $user     = $ENV{MM_USER} || "";
my $password = $ENV{MM_PWD} || "";

SKIP: {
    skip "No MediaMosa server environment settings found (MM_URL,"
	 . "MM_USER,MM_PWD).", 
	5 if (! $base_url || ! $user || ! $password);
	
    my $mm;
    ok($mm = Catmandu::MediaMosa->new( base_url => $base_url , user => $user , password => $password ));

    my $vpcore = $mm->asset_list({ offset => 0,limit => 10});

    ok($vpcore);
    ok($vpcore->header->item_count_total > 0);
    ok($vpcore->header->item_count > 0);

    my $count = $vpcore->items->count;

    is($count,10);
   
    
};

done_testing 5;