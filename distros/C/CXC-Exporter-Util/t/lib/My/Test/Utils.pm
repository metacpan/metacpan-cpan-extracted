package My::Test::Utils;

use strict;
use warnings;

use feature 'state';
use experimental 'signatures';

use Import::Into;

use Exporter 'import';

our @EXPORT_OK = ( 'export_from' );

sub export_from ( $src, @args ) {
    state $package = 'Package000';
    ++$package;
    $src->import::into( $package, @args );
    $package;
}

1;
