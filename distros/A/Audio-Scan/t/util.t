use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 7;

use Audio::Scan;

# Test for is_supported
{
	is( Audio::Scan->is_supported( _f('v1.mp3') ), 1, 'is_supported on mp3 file ok' );
	is( Audio::Scan->is_supported( _f('foo.dat') ), 0, 'is_supported on non-audio file ok' );
}

# Test for get_types
{
    my $types = Audio::Scan->get_types;

    is( $types->[0], 'mp4', 'get_types 1 ok' );
    is( $types->[1], 'aac', 'get_types 2 ok' );
}

# Test for extensions_for
{
    my $exts = Audio::Scan->extensions_for('mp4');
    is( $exts->[0], 'mp4', 'extensions_for 1 ok' );
    is( $exts->[1], 'm4a', 'extensions_for 2 ok' );
}

# Test for type_for
{
    is( Audio::Scan->type_for('wma'), 'asf', 'type_for ok' );
}

sub _f {
    return catfile( $FindBin::Bin, 'mp3', shift );
}
