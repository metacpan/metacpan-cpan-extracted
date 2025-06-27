package Data::MARC::Field008;

use strict;
use warnings;

use Data::MARC::Field008::Utils qw(check_cataloging_source check_date
	check_modified_record check_type_of_date);
use Error::Pure qw(err);
use Error::Pure::Utils qw(err_get);
use Mo qw(build is);
use Mo::utils 0.22 qw(check_isa check_length_fix check_number check_required check_strings);
use Readonly;

Readonly::Array our @MATERIAL_TYPES => qw(book computer_file continuing_resource
	map mixed_material music visual_material);

our $VERSION = 0.03;

has cataloging_source => (
	is => 'ro',
);

has date_entered_on_file => (
	is => 'ro',
);

has date1 => (
	is => 'ro',
);

has date2 => (
	is => 'ro',
);

has language => (
	is => 'ro',
);

has material => (
	is => 'ro',
);

has material_type => (
	is => 'ro',
);

has modified_record => (
	is => 'ro',
);

has place_of_publication => (
	is => 'ro',
);

has raw => (
	is => 'ro',
);

has type_of_date => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'cataloging_source'.
	check_cataloging_source($self, 'cataloging_source');

	# Check 'date_entered_on_file'.
	check_required($self, 'date_entered_on_file');
	check_length_fix($self, 'date_entered_on_file', 6);
	if (defined $self->{'date_entered_on_file'} && $self->{'date_entered_on_file'} ne '      ') {
		check_number($self, 'date_entered_on_file');
	}

	# Check 'date1'.
	check_date($self, 'date1');

	# Check 'date2'.
	check_date($self, 'date2');

	# Check 'language'.
	check_required($self, 'language');
	check_length_fix($self, 'language', 3);

	# Check 'material_type'.
	check_required($self, 'material_type');
	check_strings($self, 'material_type', \@MATERIAL_TYPES);

	# Check 'material'.
	if ($self->material_type eq 'book') {
		check_isa($self, 'material', 'Data::MARC::Field008::Book');
	} elsif ($self->material_type eq 'computer_file') {
		check_isa($self, 'material', 'Data::MARC::Field008::ComputerFile');
	} elsif ($self->material_type eq 'continuing_resource') {
		check_isa($self, 'material', 'Data::MARC::Field008::ContinuingResource');
	} elsif ($self->material_type eq 'map') {
		check_isa($self, 'material', 'Data::MARC::Field008::Map');
	} elsif ($self->material_type eq 'mixed_material') {
		check_isa($self, 'material', 'Data::MARC::Field008::MixedMaterial');
	} elsif ($self->material_type eq 'music') {
		check_isa($self, 'material', 'Data::MARC::Field008::Music');
	} elsif ($self->material_type eq 'visual_material') {
		check_isa($self, 'material', 'Data::MARC::Field008::VisualMaterial');
	}

	# Check 'modified_record'
	check_modified_record($self, 'modified_record');

	# Check place_of_publication.
	check_required($self, 'place_of_publication');
	check_length_fix($self, 'place_of_publication', 3);

	# Check 'raw'
	check_length_fix($self, 'raw', 40);

	# Check 'type_of_date'.
	check_type_of_date($self, 'type_of_date');

	# Explicit error in case of not strict mode.
	my @errors = err_get();
	if (@errors) {
		err "Field 008 isn't valid.",
			defined $self->{'raw'} ? ('Raw string', $self->{'raw'}) : (),
		;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::MARC::Field008 - Data object for MARC field 008.

=head1 SYNOPSIS

 use Data::MARC::Field008;

 my $obj = Data::MARC::Field008->new(%params);
 my $cataloging_source = $obj->cataloging_source;
 my $date_entered_on_file = $obj->date_entered_on_file;
 my $date1 = $obj->date1;
 my $date2 = $obj->date2;
 my $language = $obj->language;
 my $material = $obj->material;
 my $material_type = $obj->material_type;
 my $modified_record = $obj->modified_record;
 my $place_of_publication = $obj->place_of_publication;
 my $raw = $obj->raw;
 my $type_of_date = $obj->type_of_date;

=head1 METHODS

=head2 C<new>

 my $obj = Data::MARC::Field008->new(%params);

Constructor.

=over 8

=item * C<cataloging_source>

Cataloging source character. The length of the string is 1 character.
Possible characters are ' ', 'c', 'd', 'u' or '|'.

It's required.

Default value is undef.

=item * C<date_entered_on_file>

Date entered on file.

It's required.

Default values is undef.

=item * C<date1>

Date 1.

It's required.

Default value is undef.

=item * C<date2>

Date 2.

It's required.

Default value is undef.

=item * C<language>

Language. The length of the string is 3 characters.
Possible values are '   ', 'zxx', 'mul', 'sgn', 'und', '|||' or three character
language code.

It's required.

Default value is undef.

=item * C<material>

Material data object.

Possible objects are:

=over

=item * L<Data::MARC::Field008::Book>

=item * L<Data::MARC::Field008::ComputerFile>

=item * L<Data::MARC::Field008::ContinuingResource>

=item * L<Data::MARC::Field008::Map>

=item * L<Data::MARC::Field008::MixedMaterial>

=item * L<Data::MARC::Field008::Music>

=item * L<Data::MARC::Field008::VisualMaterial>

=back

It's required.

Default value is undef.

=item * C<material_type>

Material type.

Possible values are:

=over

=item * book

=item * computer_file

=item * continuing_resource

=item * map

=item * mixed_material

=item * music

=item * visual_material

=back

It's required.

Default value is undef.

=item * C<modified_record>

Modified record. The length of the string is 1 character.
Possible characters are ' ', 'd', 'o', 'r', 's', 'x' or '|'.

It's required.

Default value is undef.

=item * C<place_of_publication>

Place of publication, production, or execution. The length of the string are 3
characters.
Possible values are 'xx ', 'vp ', or two/three alphabetic codes.

It's required.

Default value is undef.

=item * C<raw>

Raw string of field 008. The length of the string is 40 characters.

It's optional.

Default value is undef.

=item * C<type_of_date>

The type of date or the publication status. The length of the string is 1
character.
Possible characters are 'b', 'c', 'd', 'e', 'i', 'k', 'm', 'n', 'p', 'q', 'r',
's', 't', 'u' or '|'.

It's required.

Default value is undef.

=back

Returns instance of object.

=head2 C<cataloging_source>

 my $cataloging_source = $obj->cataloging_source;

Get cataloging source flag.

Returns character.

=head2 C<date_entered_on_file>

 my $date_entered_on_file = $obj->date_entered_on_file;

Get date entered on file.

Returns string.

=head2 C<date1>

 my $date1 = $obj->date1;

Get date #1 string.

Returns string.

=head2 C<date2>

 my $date2 = $obj->date2;

Get date #2 string.

Returns string.

=head2 C<language>

 my $language = $obj->language;

Get language.

Returns string.

=head2 C<material>

 my $material = $obj->material;

Get material object.

Returns Material object.

=head2 C<material_type>

 my $material_type = $obj->material_type;

Get material type.

Returns string.

=head2 C<modified_record>

 my $modified_record = $obj->modified_record;

Get modified record.

Returns string.

=head2 C<place_of_publication>

 my $place_of_publication = $obj->place_of_publication;

Get place of publication.

Returns string.

=head2 C<raw>

 my $raw = $obj->raw;

Get raw string of field 008.

Returns string.

=head2 C<type_of_date>

 my $type_of_date = $obj->type_of_date;

Get type of date.

Returns string.

=head1 ERRORS

 new():
         Field 008 isn't valid.
                 Raw string: %s
         From Mo::utils::check_isa():
                 Parameter 'material' must be a 'Data::MARC::Field008::Book' object.
                         Value: %s
                         Reference: %s
                 Parameter 'material' must be a 'Data::MARC::Field008::ComputerFile' object.
                         Value: %s
                         Reference: %s
                 Parameter 'material' must be a 'Data::MARC::Field008::ContinuingResource' object.
                         Value: %s
                         Reference: %s
                 Parameter 'material' must be a 'Data::MARC::Field008::Map' object.
                         Value: %s
                         Reference: %s
                 Parameter 'material' must be a 'Data::MARC::Field008::MixedMaterial' object.
                         Value: %s
                         Reference: %s
                 Parameter 'material' must be a 'Data::MARC::Field008::Music' object.
                         Value: %s
                         Reference: %s
                 Parameter 'material' must be a 'Data::MARC::Field008::VisualMaterial' object.
                         Value: %s
                         Reference: %s
         From Mo::utils::check_length_fix():
                 Parameter 'date_entered_on_file' has length different than '6'.
                         Value: %s
                 Parameter 'language' has length different than '3'.
                         Value: %s
                 Parameter 'place_of_publication' has length different than '3'.
                         Value: %s
                 Parameter 'raw' has length different than '40'.
                         Value: %s
         From Mo::utils::check_number():
                 Parameter 'date_entered_on_file' must be a number.
                         Value: %s
         From Mo::utils::check_required():
                 Parameter 'date_entered_on_file' is required.
                 Parameter 'language' is required.
                 Parameter 'material_type' is required.
                 Parameter 'place_of_publication' is required.
         From Mo::utils::check_strings():
                 Parameter 'material_type' must be one of defined strings.
                         String: %s
                         Possible strings: %s
                 Parameter 'material_type' must have right string definition.
                 Parameter 'material_type' must have strings definition.
         From Data::MARC::Field008::Utils::check_cataloging_source():
                 Parameter 'cataloging_source' has bad value.
                         Value: %s
                 Parameter 'cataloging_source' is required.
                 Parameter 'cataloging_source' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'cataloging_source' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_date():
                 Parameter 'date1' has bad value.
                         Value: %s
                 Parameter 'date2' has bad value.
                         Value: %s
                 Parameter 'date1' has value with pipe character.
                         Value: %s
                 Parameter 'date2' has value with pipe character.
                         Value: %s
                 Parameter 'date1' has value with space character.
                         Value: %s
                 Parameter 'date2' has value with space character.
                         Value: %s
                 Parameter 'date1' is required.
                 Parameter 'date2' is required.
                 Parameter 'date1' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'date2' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'date1' must be a scalar value.
                         Reference: %s
                 Parameter 'date2' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_modified_record():
                 Parameter 'modified_record' has bad value.
                         Value: %s
                 Parameter 'modified_record' is required.
                 Parameter 'modified_record' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'modified_record' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_type_of_date():
                 Parameter 'type_of_date' has bad value.
                         Value: %s
                 Parameter 'type_of_date' is required.
                 Parameter 'type_of_date' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'type_of_date' must be a scalar value.
                         Reference: %s

=head1 EXAMPLE

=for comment filename=create_and_dump_marc_field_008.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::MARC::Field008;
 use Data::MARC::Field008::Book;

 # cnb000000096
 my $obj = Data::MARC::Field008->new(
         'cataloging_source' => ' ',
         'date_entered_on_file' => '830304',
         'date1' => '1982',
         'date2' => '    ',
         'language' => 'cze',
         'material' => Data::MARC::Field008::Book->new(
                 'biography' => ' ',
                 'conference_publication' => '0',
                 'festschrift' => '|',
                 'form_of_item' => ' ',
                 'government_publication' => 'u',
                 'illustrations' => 'a   ',
                 'index' => '0',
                 'literary_form' => '|',
                 'nature_of_content' => '    ',
                 #         89012345678901234
                 'raw' => 'a         u0|0 | ',
                 'target_audience' => ' ',
         ),
         'material_type' => 'book',
         'modified_record' => ' ',
         'place_of_publication' => 'xr ',
         #         0123456789012345678901234567890123456789
         'raw' => '830304s1982    xr a         u0|0 | cze  ',
         'type_of_date' => 's',
 );

 # Print out.
 p $obj;

 # Output:
 # Data::MARC::Field008  {
 #     parents: Mo::Object
 #     public methods (14):
 #         BUILD
 #         Data::MARC::Field008::Utils:
 #             check_cataloging_source, check_date, check_modified_record, check_type_of_date
 #         Error::Pure:
 #             err
 #         Error::Pure::Utils:
 #             err_get
 #         Mo::utils:
 #             check_isa, check_length_fix, check_number, check_regexp, check_required, check_strings
 #         Readonly:
 #             Readonly
 #     private methods (0)
 #     internals: {
 #         cataloging_source      " ",
 #         date_entered_on_file   830304,
 #         date1                  1982,
 #         date2                  "    ",
 #         language               "cze",
 #         material               Data::MARC::Field008::Book,
 #         material_type          "book",
 #         modified_record        " ",
 #         place_of_publication   "xr ",
 #         raw                    "830304s1982    xr a         u0|0 | cze  " (dualvar: 830304),
 #         type_of_date           "s"
 #     }
 # }

=head1 DEPENDENCIES

L<Data::MARC::Field008::Utils>,
L<Error::Pure>
L<Error::Pure::Utils>
L<Mo>,
L<Mo::utils>,
L<Readonly>.

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
