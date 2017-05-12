#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;


main();
exit(0);


sub main {

    my $hd = Data::HandyGen::mysql->new();

    #  invalid number of args 
    dies_ok { $hd->add_inserted_id() };
    dies_ok { $hd->add_inserted_id('table1') };
    
    #  valid
    lives_ok { $hd->add_inserted_id('table1', 10) };
    is_deeply( $hd->inserted()->{table1}, [ 10 ] );

    lives_ok { $hd->add_inserted_id('table1', 11) };
    is_deeply( $hd->inserted()->{table1}, [ 10, 11 ] );

    lives_ok { $hd->add_inserted_id('table2', 'a') };
    is_deeply( $hd->inserted()->{table1}, [ 10, 11 ] );
    is_deeply( $hd->inserted()->{table2}, [ 'a' ] );

    lives_ok { $hd->add_inserted_id('table3', 0) } 'No problem even if the value is 0';
    is_deeply( $hd->inserted()->{table3}, [ 0 ] );

    lives_ok { $hd->add_inserted_id('table4', '') } 'No problem even if the value is an empty string';
    is_deeply( $hd->inserted()->{table4}, [ '' ] );
}


