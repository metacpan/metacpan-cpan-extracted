package Data::MARC::Field008::Map;

use strict;
use warnings;

use Data::MARC::Field008::Utils qw(check_government_publication check_index
	check_item_form check_map_cartographic_material_type check_map_projection
	check_map_relief check_map_special_format);
use Error::Pure qw(err);
use Error::Pure::Utils qw(clean err_get);
use Mo qw(build is);
use Mo::utils 0.22 qw(check_length_fix);

our $STRICT = 1;

our $VERSION = 0.03;

has form_of_item => (
	is => 'ro',
);

has government_publication => (
	is => 'ro',
);

has index => (
	is => 'ro',
);

has projection => (
	is => 'ro',
);

has raw => (
	is => 'ro',
);

has relief => (
	is => 'ro',
);

has special_format_characteristics => (
	is => 'ro',
);

has type_of_cartographic_material => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'raw'
	check_length_fix($self, 'raw', 17);

	# Check 'form_of_item'.
	eval { check_item_form($self, 'form_of_item'); };

	# Check 'government_publication'.
	eval { check_government_publication($self, 'government_publication'); };

	# Check 'index'.
	eval { check_index($self, 'index'); };

	# Check 'projection'.
	eval { check_map_projection($self, 'projection'); };

	# Check 'relief'.
	eval { check_map_relief($self, 'relief'); };

	# Check 'special_format_characteristics'.
	eval { check_map_special_format($self, 'special_format_characteristics'); };

	# Check 'type_of_cartographic_material'.
	eval { check_map_cartographic_material_type($self, 'type_of_cartographic_material'); };

	if ($STRICT) {
		my @errors = err_get();
		if (@errors) {
			err "Couldn't create data object of map.",
				defined $self->raw ? ('Raw string', $self->raw) : (),
			;
		}
	} else {
		clean();
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::MARC::Field008::Map - Data object for MARC field 008 map material.

=head1 SYNOPSIS

 use Data::MARC::Field008::Map;

 my $obj = Data::MARC::Field008::Map->new(%params);
 my $form_of_item = $obj->form_of_item;
 my $government_publication = $obj->government_publication;
 my $index = $obj->index;
 my $projection = $obj->projection;
 my $raw = $obj->raw;
 my $relief = $obj->relief;
 my $special_format_characteristics = $obj->special_format_characteristics;
 my $type_of_cartographic_material = $obj->type_of_cartographic_material;

=head1 METHODS

=head2 C<new>

 my $obj = Data::MARC::Field008::Map->new(%params);

Constructor.

=over 8

=item * C<form_of_item>

Form of item. The length of the string is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'f', 'o', 'q', 's', 'u', 'z' or '|'.

It's required.

Default value is undef.

=item * C<government_publication>

Government publication. The length of the string is 1 character.
Possible characters are ' ', 'a', 'c', 'f', 'i', 'l', 'm', 'o', 's', 'u', 'z' or '|'.

It's required.

Default value is undef.

=item * C<index>

Index. The length of the string is 1 character.
Possible characters are '0', '1' or '|'.

It's required.

Default value is undef.

=item * C<projection>

Projection. The length of the string is 2 characters.
Possible strings are '  ', 'aa', 'ab', 'ac', 'ad', 'ae', 'af', 'ag', 'am', 'an',
'ap', 'au', 'az', 'ba', 'bb', 'bc', 'bd', 'be', 'be', 'bf', 'bg', 'bh', 'bi',
'bj', 'bk', 'bl', 'bo', 'br', 'bs', 'bu', 'bz', 'ca', 'cb', 'cc', 'ce', 'cp',
'cu', 'cz', 'da', 'db', 'dc', 'dd', 'de', 'df', 'dg', 'dh', 'dl', 'zz' or '||'.

It's required.

Default value is undef.

=item * C<raw>

Raw string of material. The length of the string is 17 characters.

It's optional.

Default value is undef.

=item * C<relief>

Map relief. The length of the string is 4 characters.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'j', 'k', 'm' or 'z' in each character.
Or '||||' in all 4 characters.

It's required.

Default value is undef.

=item * C<special_format_characteristics>

Special format characteristics. The length of the string is 2 characters.
Possible characters are ' ', 'e', 'j', 'k', 'l', 'n', 'o', 'p', 'r' or 'z'.
Or '||' in all 2 characters.

It's required.

Default value is undef.

=item * C<type_of_cartographic_material>

Type of cartographic material. The length of the string is 1 character.
Possible characters are 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'u', 'z' or '|'.

It's required.

Default value is undef.

=back

Returns instance of object.

=head2 C<form_of_item>

 my $form_of_item = $obj->form_of_item;

Get form of item.

Returns string.

=head2 C<government_publication>

 my $government_publication = $obj->government_publication;

Get governent publication.

Returns string.

=head2 C<index>

 my $index = $obj->index;

Get index.

Returns string.

=head2 C<projection>

 my $projection = $obj->projection;

Get projection.

Returns string.

=head2 C<raw>

 my $raw = $obj->raw;

Get raw string of the block.

Returns string.

=head2 C<relief>

 my $relief = $obj->relief;

Get relief.

Returns string.

=head2 C<special_format_characteristics>

my $special_format_characteristics = $obj->special_format_characteristics;

Get special format characteristics.

Returns string.

=head2 C<type_of_cartographic_material>

 my $type_of_cartographic_material = $obj->type_of_cartographic_material;

Get type of cartographic material.

Returns string.

=head1 ERRORS

 new():
         Couldn't create data object of map.
                 Raw string: %s
         Parameter 'raw' has length different than '17'.
                 Value: %s
         From Data::MARC::Field008::Utils::check_government_publication():
                 Parameter 'government_publication' has bad value.
                         Value: %s
                 Parameter 'government_publication' is required.
                 Parameter 'government_publication' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'government_publication' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_index():
                 Parameter 'index' has bad value.
                         Value: %s
                 Parameter 'index' is required.
                 Parameter 'index' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'index' must be a scalar value.
                         Reference: %s
	 From Data::MARC::Field008::Utils::check_item_form():
                 Parameter 'form_of_item' has bad value.
                         Value: %s
                 Parameter 'form_of_item' is required.
                 Parameter 'form_of_item' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'form_of_item' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_map_cartographic_material_type():
                 Parameter 'type_of_cartographic_material' has bad value.
                         Value: %s
                 Parameter 'type_of_cartographic_material' is required.
                 Parameter 'type_of_cartographic_material' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'type_of_cartographic_material' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_map_projection():
                 Parameter 'projection' has bad value.
                         Value: %s
                 Parameter 'projection' is required.
                 Parameter 'projection' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 2
                 Parameter 'projection' must be a scalar value.
                         Reference: %s
	 From Data::MARC::Field008::Utils::check_map_relief():
                 Parameter 'relief' contains bad relief character.
                         Value: %s
                 Parameter 'relief' has value with pipe character.
                         Value: %s
                 Parameter 'relief' is required.
                 Parameter 'relief' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 4
                 Parameter 'relief' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_map_special_format():
                 Parameter 'special_format_characteristics' contains bad special format characteristics character.
                         Value: %s
                 Parameter 'special_format_characteristics' has value with pipe character.
                         Value: %s
                 Parameter 'special_format_characteristics' is required.
                 Parameter 'special_format_characteristics' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 2
                 Parameter 'special_format_characteristics' must be a scalar value.
                         Reference: %s

=head1 EXAMPLE

=for comment filename=create_and_dump_marc_field_008_map_material.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::MARC::Field008::Map;

 # cnb000001006
 my $obj = Data::MARC::Field008::Map->new(
         'form_of_item' => ' ',
         'government_publication' => ' ',
         'index' => '1',
         'projection' => '  ',
         #         89012345678901234
         'raw' => 'z      e     1   ',
         'relief' => 'z   ',
         'special_format_characteristics' => '  ',
         'type_of_cartographic_material' => 'e',
 );

 # Print out.
 p $obj;

 # Output:
 # Data::MARC::Field008::Map  {
 #     parents: Mo::Object
 #     public methods (11):
 #         BUILD
 #         Data::MARC::Field008::Utils:
 #             check_government_publication, check_index, check_item_form, check_map_cartographic_material_type, check_map_projection, check_map_relief, check_map_special_format
 #         Error::Pure:
 #             err
 #         Error::Pure::Utils:
 #             err_get
 #         Mo::utils:
 #             check_length_fix
 #     private methods (0)
 #     internals: {
 #         form_of_item                     " ",
 #         government_publication           " ",
 #         index                            1,
 #         projection                       "  ",
 #         raw                              "z      e     1   ",
 #         relief                           "z   ",
 #         special_format_characteristics   "  ",
 #         type_of_cartographic_material    "e"
 #     }
 # }

=head1 DEPENDENCIES

L<Data::MARC::Field008::Utils>,
L<Error::Pure>
L<Error::Pure::Utils>
L<Mo>,
L<Mo::utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-MARC-Field008>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
