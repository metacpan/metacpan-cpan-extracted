use Test::More;
use Beagle::Model::Entry;

my $entry = Beagle::Model::Entry->new();
isa_ok( $entry, 'Beagle::Model::Entry' );

for my $attr (
    qw/root path original_path id author draft created updated
    format body timezone/
  )
{
    can_ok( $entry, $attr );
}

for my $method (
    qw/new_from_string serialize serialize_meta serialize_body
    parse_field serialize_field type summary parse_body
    format_date created_string created_year created_month
    created_day updated_string updated_year updated_month
    updated_day body_html/
  )
{
    can_ok( $entry, $method );
}

done_testing();
