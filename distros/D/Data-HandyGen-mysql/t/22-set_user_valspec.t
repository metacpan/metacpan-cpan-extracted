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


#   _set_user_valspec

sub main {
    
    my $hd = Data::HandyGen::mysql->new();

    test($hd);

    done_testing();
}


sub test {
    my ($hd) = @_;

    $hd->_add_user_valspec('table1', { 'col1' => [ 1, 2, 3 ] });
    $hd->_add_user_valspec('table2', { 'col2' => 5 });
    $hd->_set_user_valspec('table3', { 'col3' => 0 });
    ok( !defined( $hd->_valspec()->{table1} ) );
    ok( !defined( $hd->_valspec()->{table2} ) );
    is( $hd->_valspec()->{table3}{col3}{fixval}, 0 );

    $hd->_set_user_valspec('table4', { 'col4' => [ 1, 2, 3 ] });
    ok( !defined( $hd->_valspec()->{table3} ) );
    is_deeply( $hd->_valspec()->{table4}{col4}{random}, [1, 2, 3] );

    $hd->_set_user_valspec('table4', { 'col5' => 3 });
    ok( !defined( $hd->_valspec()->{table4}{col4} ) );
    is_deeply( $hd->_valspec()->{table4}{col5}{fixval}, 3 );

}


