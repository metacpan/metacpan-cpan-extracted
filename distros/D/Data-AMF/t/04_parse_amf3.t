use Test::Base;

plan tests => 1 * blocks;

use FindBin;
use File::Spec;

use Data::AMF;
use Data::AMF::Type::Boolean;
use Data::AMF::Type::Null;

my $amf = Data::AMF->new( version => 3 );

sub load {
    my $file = File::Spec->catfile( $FindBin::Bin, $_[0] );
    open my $fh, "<$file";
    my $data = do { local $/; <$fh> };
    close $fh;

    $data;
}

sub parse {
    my ($obj) = $amf->deserialize($_[0]);

    return $obj;
}

filters {
    input    => [qw/load parse/],
    expected => 'eval',
};

run_compare;

__DATA__

=== number
--- input: data/amf3/number
--- expected
123.45

=== boolean true
--- input: data/amf3/true
--- expected
Data::AMF::Type::Boolean->new(1)

=== boolean false
--- input: data/amf3/false
--- expected
Data::AMF::Type::Boolean->new(0)

=== string
--- input: data/amf3/string
--- expected
"foo"

=== object
--- input: data/amf3/object
--- expected
{ foo => "bar" }

=== object2
--- input: data/amf3/object2
--- expected
{
	array => [ "foo", "bar" ],
	hash => { foo => "bar" }
}

=== null object
--- input: data/amf3/null_object
--- expected
{}

=== array
--- input: data/amf3/array
--- expected
[ "foo", "bar" ]

=== null
--- input: data/amf3/null
--- expected
Data::AMF::Type::Null->new()

=== undefined
--- input: data/amf3/undefined
--- expected
undef

=== date
--- input: data/amf3/date
--- expected
DateTime->new(
	year   => 2009,
	month  => 10,
	day    => 22,
	hour   => 03,
	minute => 34,
	second => 56
)

=== byte_array
--- input: data/amf3/byte_array
--- expected
Data::AMF::Type::ByteArray->new([10, 11, 1, 7, 102, 111, 111, 6, 7, 98, 97, 114, 1])
