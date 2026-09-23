#!/usr/bin/perl
##############################################################################
#
#  Data::Tools test suite -- Data::Tools::CSV
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
use strict;
use lib 'lib', '../lib';
use Test::More;
use Data::Tools::CSV;

ok( defined $Data::Tools::CSV::VERSION, 'Data::Tools::CSV loaded' );

##############################################################################
# parse_csv_line()
##############################################################################

is_deeply( parse_csv_line( 'a,b,c' ), [ qw( a b c ) ], 'parse_csv_line() plain fields' );
is_deeply( parse_csv_line( 'a,,c' ),  [ 'a', undef, 'c' ], 'parse_csv_line() empty field' );
is_deeply( parse_csv_line( 'a;b;c', ';' ), [ qw( a b c ) ], 'parse_csv_line() custom delimiter' );

is_deeply( parse_csv_line( '"quoted"' ), [ 'quoted' ], 'parse_csv_line() strips surrounding quotes' );
is_deeply( parse_csv_line( '"has, comma",x' ), [ 'has, comma', 'x' ],
           'parse_csv_line() keeps delimiter inside quotes' );
is_deeply( parse_csv_line( '"say ""hi"""' ), [ 'say "hi"' ],
           'parse_csv_line() unescapes doubled quotes' );

is_deeply( parse_csv_line( '  a , b  ' ), [ '  a ', ' b  ' ], 'parse_csv_line() keeps spaces by default' );
is_deeply( parse_csv_line( '  a , b  ', ',', 1 ), [ 'a', 'b' ], 'parse_csv_line() strips spaces when asked' );
is_deeply( parse_csv_line( '  "a b"  ', ',', 1 ), [ 'a b' ],
           'parse_csv_line() strips spaces around quoted field' );

##############################################################################
# parse_csv()
##############################################################################

my $CSV = <<'END';
NAME,QTY,NOTE
"apple",12,"has, comma"
kiwi,3,""" quoted """
END

is_deeply( parse_csv( $CSV ),
           [
             [ 'NAME',  'QTY', 'NOTE'       ],
             [ 'apple', '12',  'has, comma' ],
             [ 'kiwi',  '3',   '" quoted "' ],
           ],
           'parse_csv() array of arrays' );

is_deeply( parse_csv( "a,b\n\n\nc,d\n" ), [ [ 'a', 'b' ], [ 'c', 'd' ] ],
           'parse_csv() skips empty lines' );

is_deeply( parse_csv( "a,b\r\nc,d\r\n" ), [ [ 'a', 'b' ], [ 'c', 'd' ] ],
           'parse_csv() handles CRLF line endings' );

is_deeply( parse_csv( "a;b\nc;d\n", ';' ), [ [ 'a', 'b' ], [ 'c', 'd' ] ],
           'parse_csv() custom delimiter' );

is_deeply( parse_csv( " a , b \n", ',', 1 ), [ [ 'a', 'b' ] ],
           'parse_csv() passes strip flag down' );

##############################################################################
# parse_csv_to_hash_array()
##############################################################################

is_deeply( parse_csv_to_hash_array( $CSV ),
           [
             { NAME => 'apple', QTY => '12', NOTE => 'has, comma' },
             { NAME => 'kiwi',  QTY => '3',  NOTE => '" quoted "' },
           ],
           'parse_csv_to_hash_array() uses first row as keys' );

is_deeply( parse_csv_to_hash_array( "NAME,QTY\n" ), [],
           'parse_csv_to_hash_array() header only gives empty result' );

is_deeply( parse_csv_to_hash_array( " N , Q \n 1 , 2 \n", ',', 1 ),
           [ { N => '1', Q => '2' } ],
           'parse_csv_to_hash_array() passes strip flag down' );

##############################################################################

done_testing();
