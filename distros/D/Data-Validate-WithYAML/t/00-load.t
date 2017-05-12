#!perl 

use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}


diag( "Testing Data::Validate::WithYAML $Data::Validate::WithYAML::VERSION, Perl $], $^X" );
