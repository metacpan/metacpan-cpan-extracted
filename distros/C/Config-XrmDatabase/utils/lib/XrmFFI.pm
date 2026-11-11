package XrmFFI;

# Minimal FFI binding to libX11's resource manager (Xrm), used by
# utils/fake to generate reference results from the real X11
# implementation.
#
# Requires libX11 (e.g. Debian/Ubuntu libx11-dev) and FFI::Platypus.

use v5.10;
use strict;
use warnings;

use FFI::Platypus 2.00;

{
    # typedef struct { unsigned int size; XPointer addr; } XrmValue;
    package XrmFFI::XrmValue;
    use FFI::Platypus::Record;
    record_layout_1(
        uint   => 'size',
        opaque => 'addr',
    );
}

my $ffi = FFI::Platypus->new( api => 2, lib => [ find_libX11() ] );
$ffi->type( 'record(XrmFFI::XrmValue)*' => 'XrmValue' );

$ffi->attach( XrmInitialize        => []                     => 'void' );
$ffi->attach( XrmGetStringDatabase => ['string']             => 'opaque' );
$ffi->attach( XrmPutFileDatabase   => [ 'opaque', 'string' ] => 'void' );
$ffi->attach( XrmDestroyDatabase   => ['opaque']             => 'void' );
$ffi->attach( XrmGetResource => [ 'opaque', 'string', 'string', 'opaque*', 'XrmValue' ] => 'int' );

XrmInitialize();

sub find_libX11 {
    require FFI::CheckLib;
    my @lib = FFI::CheckLib::find_lib( lib => 'X11', symbol => 'XrmGetResource' );
    die "unable to find libX11\n" unless @lib;
    return @lib;
}

# $db = XrmFFI->GetStringDatabase( $string );
sub GetStringDatabase {
    my ( $class, $string ) = @_;
    my $db = XrmGetStringDatabase( $string );
    die "XrmGetStringDatabase failed\n" unless defined $db;
    return bless \$db, $class;
}

# $db->PutFileDatabase( $filename );
sub PutFileDatabase {
    my ( $self, $file ) = @_;
    XrmPutFileDatabase( $$self, $file );
}

# ( $status, $type, $value ) = $db->GetResource( $name, $class );
# On failure, $status is false and $type and $value are undef.
sub GetResource {
    my ( $self, $name, $class ) = @_;

    my $type;
    my $xvalue = XrmFFI::XrmValue->new;

    my $status = XrmGetResource( $$self, $name, $class, \$type, $xvalue );
    return ( 0, undef, undef ) unless $status;

    # the value is NUL terminated, and size includes the NUL
    my $value = $ffi->cast( 'opaque', 'string', $xvalue->addr );
    $type = $ffi->cast( 'opaque', 'string', $type );

    return ( $status, $type, $value );
}

sub DESTROY {
    my $self = shift;
    XrmDestroyDatabase( $$self ) if defined $$self;
}

1;
