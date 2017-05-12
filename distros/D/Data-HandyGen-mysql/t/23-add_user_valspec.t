#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;


main();
exit(0);


#   _add_user_valspec

sub main {
    
    my $hd = Data::HandyGen::mysql->new();

    test_this_table($hd);
    test_another_table($hd);
    test_invalid($hd);

    done_testing();
}



sub test_this_table {
    my ($hd) = @_;

    $hd->_add_user_valspec('test1', { 'col1' => [ 1, 2, 3 ] });
    is_deeply($hd->_valspec()->{test1}{col1}{random}, [ 1, 2, 3 ]);

    $hd->_add_user_valspec('test1', { 'col2' => 5 });
    is_deeply($hd->_valspec()->{test1}{col1}{random}, [ 1, 2, 3 ]);
    is_deeply($hd->_valspec()->{test1}{col2}{fixval}, 5);
   
    $hd->_add_user_valspec('test1', { 'col1' => 0 } );
    ok( !defined( $hd->_valspec()->{test1}{col1}{random} ) );
    is( $hd->_valspec()->{test1}{col1}{fixval}, 0 ); 
    is_deeply($hd->_valspec()->{test1}{col2}{fixval}, 5);

    $hd->_add_user_valspec('test1', { 'col2' => [ 0, 1, 2 ] });
    ok( !defined( $hd->_valspec()->{test1}{col1}{random} ) );
    is( $hd->_valspec()->{test1}{col1}{fixval}, 0 ); 
    is_deeply($hd->_valspec()->{test1}{col2}{random}, [ 0, 1, 2 ]);
    ok( !defined( $hd->_valspec()->{test1}{col2}{fixval} ) );
}


sub test_another_table {
    my ($hd) = @_;

    $hd->_add_user_valspec('test2', { 'test3.col3' => [ 1, 2, 3 ] });
    ok( !defined( $hd->_valspec()->{test2} ) );
    is_deeply( $hd->_valspec()->{test3}{col3}{random}, [ 1, 2, 3 ]);

    $hd->_add_user_valspec('test2', { 'test3.col3' => 0 } );
    ok( !defined( $hd->_valspec()->{test2} ) );
    ok( !defined( $hd->_valspec()->{test3}{col3}{random} ) );
    is( $hd->_valspec()->{test3}{col3}{fixval}, 0 );
}


sub test_invalid {
    my ($hd) = @_;

    dies_ok { $hd->_add_user_valspec() };
    dies_ok { $hd->_add_user_valspec('table4') };
    dies_ok { $hd->_add_user_valspec('table4', 'col1' => 5) };
    dies_ok { $hd->_add_user_valspec('table4', { 'table5.col1.col2' => 5 } ) };
    dies_ok { $hd->_add_user_valspec('table4', { '.table5' => 5 } ) };
    dies_ok { $hd->_add_user_valspec('table4', { 'table5.' => 5 } ) };
}


