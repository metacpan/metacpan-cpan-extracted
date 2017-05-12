use Test::More tests => 12;
use Test::CGI::Untaint;

use strict;
use warnings;

#use YAML;
#use Data::Dumper;

use CGI::Untaint::set;

#                  in   out    handler
# is_extractable("Red","red","validcolor");

#
# unextractable( $in, $handler );


#            out            in
my %sets = ( 'red,blue'     => [ qw( red blue ) ],
             'red,blue,green'     => [ qw( red blue green ) ],
             '9,10'         => [ qw( 9 10 ) ],
             '0,0,0'        => [ qw( 0 0 0 ) ],
             'red,0,blue'   => [ qw( red 0 blue ) ],
             'red'          => 'red',
             '0'            => '0',
             'red,redred'   => [ qw( red redred ) ],
             
             # can pre-process into set format
             'red,blue,green' => 'red,blue,green',
             
             # MySQL ignores repeated values
             'red,red'   => [ qw( red red ) ],
             
             );
             
#            out            in
my %bads = ( 'red'          => [ ( '', 'red' ) ],
             ''             => [ ( '' ) ],
             ','            => [ ( '', '' ) ],
             
             
             );
             
             
             
             

is_extractable( $sets{ $_ }, $_, 'set' ) for keys %sets;

unextractable( $_, 'set' )               for values %bads;
