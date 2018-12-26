#!perl

use strict;
use Test::More tests => 2;
use Data::Dumper;
use FindBin;
use File::Basename;

my $dir;
BEGIN {
    $dir = dirname( __FILE__ );
}

use lib $dir;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new( $FindBin::Bin . '/test9.yml' );

my $error;
eval { $validator->check('field1','check'), 1; } or $error = $@;

like $error, qr/Can't check with/
