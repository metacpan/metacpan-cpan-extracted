use Test::Base;

plan tests => 1 * blocks;

use Data::AMF;
use Data::AMF::Type::Boolean;
use Data::AMF::Type::ByteArray;
use Data::AMF::Type::Null;
use DateTime;

my $amf = Data::AMF->new( version => 3 );

sub serialize {
    $amf->serialize($_[0]);
}

sub deserialize {
    my ($data) = $amf->deserialize($_[0]);
    return { data => $data };
}

filters {
    input => [qw/eval serialize deserialize/],
};

run_compare input => 'input';

__DATA__

=== number
--- input
123.45

=== boolean true
--- input
Data::AMF::Type::Boolean->new(1)

=== boolean false
--- input
Data::AMF::Type::Boolean->new(0)

=== string
--- input
"foo"

=== object
--- input
{ foo => "bar" }

=== null object
--- input
{}

=== complex object
--- input
{
	array => [
		"foo",
		"bar",
		'',
		{
			id => 1,
			name => 'hoge',
		},
		{
			id => 2,
			name => '',
			age => 21,
		},
		{
			id => 3,
			name => 'hoge',
		},
	],
	hash => { foo => "bar" }
}

=== null
--- input
Data::AMF::Type::Null->new()

=== undefined
--- input
undef

=== date
--- input
DateTime->now;

=== byte_array
--- input
Data::AMF::Type::ByteArray->new([1, 2, 3, 4, 5])

