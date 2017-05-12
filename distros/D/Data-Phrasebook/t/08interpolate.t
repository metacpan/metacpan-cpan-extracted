#!/usr/bin/perl -w
use strict;
use vars qw( $class $subclass );

use Test::More tests => 4;

# ------------------------------------------------------------------------

BEGIN {
    $class = 'Data::Phrasebook';
    use_ok $class;
}

my $file = 't/08phrases.txt';

# ------------------------------------------------------------------------

{
    my $obj = $class->new;
    isa_ok( $obj => "${class}::Plain", 'Class new' );
    $obj->file( $file );
    is( $obj->file() => $file , 'Set/get file works');

    my $str = $obj->fetch( 'baz', {foo => '${bar}', bar => '${foo}'} );
    is($str, 'foo is ${bar} and bar is ${foo}');
}
