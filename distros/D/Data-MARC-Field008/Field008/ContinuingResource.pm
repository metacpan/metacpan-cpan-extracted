package Data::MARC::Field008::ContinuingResource;

use strict;
use warnings;

use Data::MARC::Field008::Utils qw(check_conference_publication
	check_continuing_resource_entry_convention
	check_continuing_resource_form_of_original_item
	check_continuing_resource_frequency
	check_continuing_resource_nature_of_content
	check_continuing_resource_nature_of_entire_work
	check_continuing_resource_original_alphabet_or_script
	check_continuing_resource_regularity
	check_continuing_resource_type
	check_government_publication check_item_form);
use Error::Pure qw(err);
use Error::Pure::Utils qw(clean err_get);
use Mo qw(build is);
use Mo::utils 0.22 qw(check_length_fix check_required);

our $STRICT = 1;

our $VERSION = 0.03;

has conference_publication => (
	is => 'ro',
);

has entry_convention => (
	is => 'ro',
);

has form_of_item => (
	is => 'ro',
);

has form_of_original_item => (
	is => 'ro',
);

has frequency => (
	is => 'ro',
);

has government_publication => (
	is => 'ro',
);

has nature_of_content => (
	is => 'ro',
);

has nature_of_entire_work => (
	is => 'ro',
);

has original_alphabet_or_script_of_title => (
	is => 'ro',
);

has raw => (
	is => 'ro',
);

has regularity => (
	is => 'ro',
);

has type_of_continuing_resource => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'raw'.
	check_length_fix($self, 'raw', 17);

	# Check 'conference_publication'.
	eval { check_conference_publication($self, 'conference_publication'); };

	# Check 'entry_convention'.
	eval {check_continuing_resource_entry_convention($self, 'entry_convention'); };

	# Check 'form_of_item'.
	eval { check_item_form($self, 'form_of_item'); };

	# Check 'form_of_original_item'.
	eval { check_continuing_resource_form_of_original_item($self, 'form_of_original_item'); };

	# Check 'frequency'.
	eval { check_continuing_resource_frequency($self, 'frequency'); };

	# Check 'government_publication'.
	eval { check_government_publication($self, 'government_publication'); };

	# Check 'nature_of_content'.
	eval { check_continuing_resource_nature_of_content($self, 'nature_of_content'); };

	# Check 'nature_of_entire_work'.
	eval { check_continuing_resource_nature_of_entire_work($self, 'nature_of_entire_work'); };

	# Check 'original_alphabet_or_script_of_title'.
	eval { check_continuing_resource_original_alphabet_or_script($self, 'original_alphabet_or_script_of_title'); };

	# Check 'regularity'.
	eval { check_continuing_resource_regularity($self, 'regularity'); };

	# Check 'type_of_continuing_resource'.
	eval { check_continuing_resource_type($self, 'type_of_continuing_resource'); };

	if ($STRICT) {
		my @errors = err_get();
		if (@errors) {
			err "Couldn't create data object of continuing resource.",
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

Data::MARC::Field008::ContinuingResource - Data object for MARC field 008 continuing resource material.

=head1 SYNOPSIS

 use Data::MARC::Field008::ContinuingResource;

 my $obj = Data::MARC::Field008::ContinuingResource->new(%params);
 my $conference_publication = $obj->conference_publication;
 my $entry_convention = $obj->entry_convention;
 my $form_of_item = $obj->form_of_item;
 my $form_of_original_item = $obj->form_of_original_item;
 my $frequency = $obj->frequency;
 my $government_publication = $obj->government_publication;
 my $nature_of_content = $obj->nature_of_content;
 my $nature_of_entire_work = $obj->nature_of_entire_work;
 my $original_alphabet_or_script_of_title = $obj->original_alphabet_or_script_of_title;
 my $raw = $obj->raw;
 my $regularity = $obj->regularity;
 my $type_of_continuing_resource = $obj->type_of_continuing_resource;

=head1 METHODS

=head2 C<new>

 my $obj = Data::MARC::Field008::ContinuingResource->new(%params);

Constructor.

=over 8

=item * C<conference_publication>

Conference publication. The length of the item is 1 character.
Possible characters are '0', '1' or '|'.

It's required.

Default value is undef.

=item * C<entry_convention>

Entry convention. The length of the string is 1 character.
Possible characters are '0', '1', '2' or '|'.

It's required.

Default value is undef.

=item * C<form_of_item>

Form of item. The length of the item is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'f', 'o', 'q', 'r', 's' or '|'.

It's required.

Default value is undef.

=item * C<form_of_original_item>

Form of original item. The length of the string is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'o', 'q', 's' or '|'.

It's required.

Default value is undef.

=item * C<frequency>

Frequency. The length of the string is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
'k', 'm', 'q', 's', 't', 'u', 'w', 'z' or '|'.

It's required.

Default value is undef.

=item * C<government_publication>

Government publication. The length of the string is 1 character.
Possible characters are ' ', 'a', 'c', 'f', 'i', 'l', 'm', 'o', 's', 'u', 'z' or '|'.

It's required.

Default value is undef.

=item * C<nature_of_content>

Nature of contents. The length of the string is 3 characters.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'k',
'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'y', 'z', '5', '6'
or '|||'.

It's required.

Default value is undef.

=item * C<nature_of_entire_work>

Nature of entire work. The length of the string is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'k',
'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'y', 'z', '5', '6'
or '|'.

It's required.

Default value is undef.

=item * C<original_alphabet_or_script_of_title>

Original alphabet or script of title. The length of the string is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
'k', 'l', 'u', 'z', '|'.

It's required.

Default value is undef.

=item * C<raw>

Raw string of material. The length of the string is 17 characters.

It's optional.

Default value is undef.

=item * C<regularity>

Regularity. The length of the string is 1 character.
Possible characters are 'n', 'r', 'u', 'x' or '|'.

It's required.

Default value is undef.

=item * C<type_of_continuing_resource>

Type of continuing resource. The length of the string is 1 character.
Possible characters are ' ', 'd', 'g', 'h', 'j', 'l', 'm', 'n', 'p', 'r', 's',
't', 'w' or '|'.

It's required.

Default value is undef.

=back

Returns instance of object.

=head2 C<conference_publication>

 my $conference_publication = $obj->conference_publication;

Get converence publication.

Returns string.

=head2 C<entry_convention>

 my $entry_convention = $obj->entry_convention;

Get entry convention.

Returns string.

=head2 C<form_of_item>

 my $form_of_item = $obj->form_of_item;

Get form of item.

Returns string.

=head2 C<form_of_original_item>

 my $form_of_original_item = $obj->form_of_original_item;

Get form of original item.

Returns string.

=head2 C<frequency>

 my $frequency = $obj->frequency;

Get frequency.

Returns string.

=head2 C<government_publication>

 my $government_publication = $obj->government_publication;

Get government publication.

Returns string.

=head2 C<nature_of_content>

 my $nature_of_content = $obj->nature_of_content;

Get nature of content.

Returns string.

=head2 C<nature_of_entire_work>

 my $nature_of_entire_work = $obj->nature_of_entire_work;

Get nature of entire work.

Returns string.

=head2 C<original_alphabet_or_script_of_title>

 my $original_alphabet_or_script_of_title = $obj->original_alphabet_or_script_of_title;

Get original alphabet or script of title.

Returns string.

=head2 C<raw>

 my $raw = $obj->form_of_item;

Get raw string of the block.

Returns string.

=head2 C<regularity>

 my $regularity = $obj->regularity;

Get regularity.

Returns string.

=head2 C<type_of_continuing_resource>

 my $type_of_continuing_resource = $obj->type_of_continuing_resource;

Get type of continuing resource.

Returns string.

=head1 ERRORS

 new():
         Couldn't create data object of continuing resource.
                 Raw string: %s
         Parameter 'raw' has length different than '17'.
                 Value: %s
         From Data::MARC::Field008::Utils::check_conference_publication():
                 Parameter 'conference_publication' has bad value.
                         Value: %s
                 Parameter 'conference_publication' is required.
                 Parameter 'conference_publication' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'conference_publication' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_continuing_resource_entry_convention():
                 Parameter 'entry_convention' has bad value.
                         Value: %s
                 Parameter 'entry_convention' is required.
                 Parameter 'entry_convention' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'entry_convention' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_continuing_resource_form_of_original_item():
                 Parameter 'form_of_original_item' has bad value.
                         Value: %s
                 Parameter 'form_of_original_item' is required.
                 Parameter 'form_of_original_item' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'form_of_original_item' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_continuing_resource_frequency():
                 Parameter 'frequency' has bad value.
                         Value: %s
                 Parameter 'frequency' is required.
                 Parameter 'frequency' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'frequency' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_continuing_resource_nature_of_content():
                 Parameter 'nature_of_content' has bad value.
                         Value: %s
                 Parameter 'nature_of_content' has value with pipe character.
                         Value: %s
                 Parameter 'nature_of_content' is required.
                 Parameter 'nature_of_content' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'nature_of_content' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_continuing_resource_nature_of_entire_work():
                 Parameter 'nature_of_entire_work' has bad value.
                         Value: %s
                 Parameter 'nature_of_entire_work' is required.
                 Parameter 'nature_of_entire_work' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'nature_of_entire_work' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_continuing_resource_original_alphabet_or_script():
                 Parameter 'original_alphabet_or_script_of_title' has bad value.
                         Value: %s
                 Parameter 'original_alphabet_or_script_of_title' is required.
                 Parameter 'original_alphabet_or_script_of_title' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'original_alphabet_or_script_of_title' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_continuing_resource_regularity():
                 Parameter 'regularity' has bad value.
                         Value: %s
                 Parameter 'regularity' is required.
                 Parameter 'regularity' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'regularity' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_continuing_resource_type():
                 Parameter 'type_of_continuing_resource' has bad value.
                         Value: %s
                 Parameter 'type_of_continuing_resource' is required.
                 Parameter 'type_of_continuing_resource' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'type_of_continuing_resource' must be a scalar value.
                         Reference: %s
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

=head1 EXAMPLE

=for comment filename=create_and_dump_marc_field_008_continuing_resource_material.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::MARC::Field008::ContinuingResource;

 # cnb000002514
 my $obj = Data::MARC::Field008::ContinuingResource->new(
         'conference_publication' => '0',
         'entry_convention' => '|',
         'form_of_item' => ' ',
         'form_of_original_item' => ' ',
         'frequency' => 'z',
         'government_publication' => 'u',
         'nature_of_content' => '   ',
         'nature_of_entire_work' => ' ',
         'original_alphabet_or_script_of_title' => ' ',
         #         89012345678901234
         'raw' => 'zr        u0    |',
         'regularity' => 'r',
         'type_of_continuing_resource' => ' ',
 );

 # Print out.
 p $obj;

 # Output:
 # Data::MARC::Field008::ContinuingResource  {
 #     parents: Mo::Object
 #     public methods (16):
 #         BUILD
 #         Data::MARC::Field008::Utils:
 #             check_conference_publication, check_continuing_resource_entry_convention, check_continuing_resource_form_of_original_item, check_continuing_resource_frequency, check_continuing_resource_nature_of_content, check_continuing_resource_nature_of_entire_work, check_continuing_resource_original_alphabet_or_script, check_continuing_resource_regularity, check_continuing_resource_type, check_government_publication, check_item_form
 #         Error::Pure:
 #             err
 #         Error::Pure::Utils:
 #             err_get
 #         Mo::utils:
 #             check_length_fix, check_required
 #     private methods (0)
 #     internals: {
 #         conference_publication                 0,
 #         entry_convention                       "|",
 #         form_of_item                           " ",
 #         form_of_original_item                  " ",
 #         frequency                              "z",
 #         government_publication                 "u",
 #         nature_of_content                      "   ",
 #         nature_of_entire_work                  " ",
 #         original_alphabet_or_script_of_title   " ",
 #         raw                                    "zr        u0    |",
 #         regularity                             "r",
 #         type_of_continuing_resource            " "
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
