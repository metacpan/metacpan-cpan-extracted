use Test::More tests => 230;

use strict;
use warnings;

use Data::Plist::BinaryWriter;
use Data::Plist::BinaryReader;

my $in;
my $out;

# Empty dict
round_trip( {}, 42 );

# Dict containing stuff
round_trip( { 'kitteh' => 'Angleton', 'MoL' => 42, 'array' => ['Cthulhu'] },
    93 );

# Empty array
round_trip( [], 42 );

# Array containing stuff
round_trip( ['Cthulhu'], 52 );

# Negative integer
round_trip( -1, 50 );

# Small integer
round_trip( 42, 43 );

# Large integer
round_trip( 777, 44 );

# Even larger integer
round_trip( 141414, 46 );

# Ginormous integer
round_trip( 4294967296, 50 );

# Short string
round_trip( "kitteh", 48 );

# Long string (where long means "more than 15 characters")
round_trip( "The kyokeach is cute", 64 );

# Ustring
files("t/data/ustring.binary.plist");

# Real number
round_trip( 3.14159, 50 );

# Negative real
round_trip( -1.985, 50 );

# Date
round_trip( DateTime->new( year => 2008, month => 7, day => 23 ), 50 );

# Caching
round_trip( { 'kitteh' => 'Angleton', 'Laundry' => 'Angleton' }, 73 );

# refsize = 2
round_trip( [ 1 .. 300 ], 1891 );

# UIDs
preserialized_trip( [ UID => 1 ], 43 );

# Miscs
preserialized_trip( [ false => 0 ],  42 );
preserialized_trip( [ true  => 1 ],  42 );
preserialized_trip( [ fill  => 15 ], 44 );
preserialized_trip( [ null  => 0 ],  42 );

# Data
preserialized_trip( [ data => "\x00" ], 43 );

# OffsetSize == 3
preserialized_trip( [ array => [ [ data => "\x00" x 65536 ] ] ], 65590 );

# Fails thanks to unknown data type
my $fail = Data::Plist::BinaryWriter->new( serialize => 0 );
my $ret = eval { $fail->write( [ random => 0 ] ) };
ok( not($ret), "Binary plist didn't write." );
like( $@, qr/can't/i, "Threw an error." );

# Large files
files("t/data/bigfile-01.binary.plist");
files("t/data/bigfile-02.binary.plist");

sub files {
    my $write      = Data::Plist::BinaryWriter->new( serialize => 0 );
    my $read       = Data::Plist::BinaryReader->new;
    my ($filename) = @_;
    my $str        = do { local @ARGV = $filename; local $/; <> };
    my $output;
    ok( $str, "Read binary data in by hand" );
    $output = eval { $read->open_string($str) };
    ok( $output, "Opening from a string worked" );
    isa_ok( $output, "Data::Plist" );
    $output = $output->raw_data;
    ok( $output, "Has data inside" );
    my $orig = $write->write($output);
    ok( $orig, "Created data structure" );
    like( $orig, qr/^bplist00/, "Bplist begins with correct header" );
    is( "$@", '', "No errors thrown." );
}

sub round_trip {
    my $write = Data::Plist::BinaryWriter->new;
    $in = trip( $write, @_ );
    is_deeply( $in->data, $_[0], "Read back " . $_[0] );
}

sub preserialized_trip {
    my $write = Data::Plist::BinaryWriter->new( serialize => 0 );
    $in = trip( $write, @_ );
    is_deeply( $in->raw_data, $_[0], "Read back " . $_[0] );
}

sub trip {
    my $read = Data::Plist::BinaryReader->new;
    my ( $write, $input, $expected_size ) = @_;
    ok( $write, "Created a binary writer" );
    isa_ok( $write, "Data::Plist::BinaryWriter" );
    $out = eval { $write->write($input) };
    ok( $out, "Created data structure" );
    like( $out, qr/^bplist00/, "Bplist begins with correct header" );
    is( "$@", '', "No errors thrown." );
    is( length($out), $expected_size,
        "Bplist is " . $expected_size . " bytes long." );
    $in = eval { $read->open_string($out) };
    ok( $in, "Read back bplist" );
    isa_ok( $in, "Data::Plist" );
    return $in;
}
