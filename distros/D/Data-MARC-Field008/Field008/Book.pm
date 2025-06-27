package Data::MARC::Field008::Book;

use strict;
use warnings;

use Data::MARC::Field008::Utils qw(check_book_biography check_book_festschrift
	check_book_illustration check_book_literary_form check_book_nature_of_content
	check_conference_publication check_government_publication check_index
	check_item_form check_target_audience);
use Error::Pure qw(err);
use Error::Pure::Utils qw(clean err_get);
use Mo qw(build is);
use Mo::utils 0.22 qw(check_length_fix check_required);

our $STRICT = 1;

our $VERSION = 0.03;

has biography => (
	is => 'ro',
);

has conference_publication => (
	is => 'ro',
);

has festschrift => (
	is => 'ro',
);

has form_of_item => (
	is => 'ro',
);

has government_publication => (
	is => 'ro',
);

has illustrations => (
	is => 'ro',
);

has index => (
	is => 'ro',
);

has literary_form => (
	is => 'ro',
);

has nature_of_content => (
	is => 'ro',
);

has raw => (
	is => 'ro',
);

has target_audience => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'raw'
	check_length_fix($self, 'raw', 17);

	# Check 'biography'.
	eval { check_book_biography($self, 'biography'); };

	# Check 'conference_publication'.
	eval { check_conference_publication($self, 'conference_publication'); };

	# Check 'festschrift'.
	eval { check_book_festschrift($self, 'festschrift'); };

	# Check 'form_of_item'.
	eval { check_item_form($self, 'form_of_item'); };

	# Check 'government_publication'.
	eval { check_government_publication($self, 'government_publication'); };

	# Check 'illustrations'.
	eval { check_book_illustration($self, 'illustrations'); };

	# Check 'index'.
	eval { check_index($self, 'index'); };

	# Check 'literary_form'.
	eval { check_book_literary_form($self, 'literary_form'); };

	# Check 'nature_of_content'.
	eval { check_book_nature_of_content($self, 'nature_of_content'); };

	# Check 'target_audience'.
	eval { check_target_audience($self, 'target_audience'); };

	if ($STRICT) {
		my @errors = err_get();
		if (@errors) {
			err "Couldn't create data object of book.",
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

Data::MARC::Field008::Book - Data object for MARC field 008 book material.

=head1 SYNOPSIS

 use Data::MARC::Field008::Book;

 my $obj = Data::MARC::Field008::Book->new(%params);
 my $biography = $obj->biography;
 my $conference_publication = $obj->conference_publication;
 my $festschrift = $obj->festschrift;
 my $form_of_item = $obj->form_of_item;
 my $government_publication = $obj->government_publication;
 my $illustrations = $obj->illustrations;
 my $index = $obj->index;
 my $literary_form = $obj->literary_form;
 my $nature_of_content = $obj->nature_of_content;
 my $raw = $obj->raw;
 my $target_audience = $obj->target_audience;

=head1 METHODS

=head2 C<new>

 my $obj = Data::MARC::Field008::Book->new(%params);

Constructor.

=over 8

=item * C<biography>

Biography. The length of the item is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd' or '|'.

It's required.

Default value is undef.

=item * C<conference_publication>

Conference publication. The length of the item is 1 character.
Possible characters are '0', '1' or '|'.

It's required.

Default value is undef.

=item * C<festschrift>

Festschrift. The length of the item is 1 character.
Possible characters are '0', '1' or '|'.

It's required.

Default value is undef.

=item * C<form_of_item>

Form of item. The length of the item is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'f', 'o', 'q', 'r', 's' or '|'.

It's required.

Default value is undef.

=item * C<government_publication>

Government publication. The length of the string is 1 character.
Possible characters are ' ', 'a', 'c', 'f', 'i', 'l', 'm', 'o', 's', 'u', 'z' or '|'.

It's required.

Default value is undef.

=item * C<illustrations>

Illustrations. The length of the string is 4 characters.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
'k', 'l', 'm', 'o', 'p' or '|'.

It's required.

Default value is undef.

=item * C<index>

Index. The length of the string is 1 character.
Possible characters are '0', '1' or '|'.

It's required.

Default value is undef.

=item * C<literary_form>

Literary form. The length of the string is 1 character.
Possible characters are '0', '1', 'd', 'e', 'f', 'h', 'i', 'j', 'm', 'p', 's',
'u' or '|'.

It's required.

Default value is undef.

=item * C<nature_of_content>

Nature of contents. The length of the string is 4 characters.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'j', 'k',
'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'y', 'z', '2', '5',
'6' or '|'.

It's required.

Default value is undef.

=item * C<raw>

Raw string of material. The length of the string is 17 characters.

It's optional.

Default value is undef.

=item * C<target_audience>

Target audience. The length of the item is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'j' or '|'.

It's required.

Default value is undef.

=back

Returns instance of object.

=head2 C<biography>

 my $biography = $obj->biography;

Get biography.

Returns string.

=head2 C<conference_publication>

 my $conference_publication = $obj->conference_publication;

Get conference publication.

Returns string.

=head2 C<festschrift>

 my $festschrift = $obj->festschrift;

Get festschrift.

Returns string.

=head2 C<form_of_item>

 my $form_of_item = $obj->form_of_item;

Get form of item.

Returns string.

=head2 C<government_publication>

 my $government_publication = $obj->government_publication;

Get government publication.

Returns string.

=head2 C<illustrations>

 my $illustrations = $obj->illustrations;

Get illustrations.

Returns string.

=head2 C<index>

 my $index = $obj->index;

Get index.

Returns string.

=head2 C<literary_form>

 my $literary_form = $obj->literary_form;

Get literary form.

Returns string.

=head2 C<nature_of_content>

 my $nature_of_content = $obj->nature_of_content;

Get nature of content.

Returns string.

=head2 C<raw>

 my $raw = $obj->raw;

Get raw string of the block.

Returns string.

=head2 C<target_audience>

 my $target_audience = $obj->target_audience;

Get target audience.

Returns string.

=head1 ERRORS

 new():
         Couldn't create data object of book.
                 Raw string: %s
         Parameter 'raw' has length different than '17'.
                 Value: %s
         From Data::MARC::Field008::Utils::check_book_biography():
                 Parameter 'biography' has bad value.
                         Value: %s
                 Parameter 'biography' is required.
                 Parameter 'biography' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'biography' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_book_festschrift():
                 Parameter 'festschrift' has bad value.
                         Value: %s
                 Parameter 'festschrift' is required.
                 Parameter 'festschrift' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'festschrift' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_book_illustration():
                 Parameter 'illustrations' contains bad book illustration character.
                         Value: %s
                 Parameter 'illustrations' has value with pipe character.
                         Value: %s
                 Parameter 'illustrations' is required.
                 Parameter 'illustrations' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 4
                 Parameter 'illustrations' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_book_literary_form():
                 Parameter 'literary_form' has bad value.
                         Value: %s
                 Parameter 'literary_form' is required.
                 Parameter 'literary_form' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'literary_form' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_book_nature_of_content():
                 Parameter 'nature_of_content' has bad value.
                         Value: %s
                 Parameter 'nature_of_content' has value with pipe character.
                         Value: %s
                 Parameter 'nature_of_content' is required.
                 Parameter 'nature_of_content' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 4
                 Parameter 'nature_of_content' must be a scalar value.
                         Reference: %s
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
         From Data::MARC::Field008::Utils::check_target_audience():
                 Parameter 'target_audience' has bad value.
                         Value: %s
                 Parameter 'target_audience' is required.
                 Parameter 'target_audience' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'target_audience' must be a scalar value.
                         Reference: %s

=head1 EXAMPLE

=for comment filename=create_and_dump_marc_field_008_book.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::MARC::Field008::Book;

 # cnb000000096
 my $obj = Data::MARC::Field008::Book->new(
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
 );

 # Print out.
 p $obj;

 # Output:
 # Data::MARC::Field008::Book  {
 #     parents: Mo::Object
 #     public methods (15):
 #         BUILD
 #         Data::MARC::Field008::Utils:
 #             check_book_biography, check_book_festschrift, check_book_illustration, check_book_literary_form, check_book_nature_of_content, check_conference_publication, check_government_publication, check_index, check_item_form, check_target_audience
 #         Error::Pure:
 #             err
 #         Error::Pure::Utils:
 #             err_get
 #         Mo::utils:
 #             check_length_fix, check_required
 #     private methods (0)
 #     internals: {
 #         biography                " ",
 #         conference_publication   0,
 #         festschrift              "|",
 #         form_of_item             " ",
 #         government_publication   "u",
 #         illustrations            "a   ",
 #         index                    0,
 #         literary_form            "|",
 #         nature_of_content        "    ",
 #         raw                      "a         u0|0 | ",
 #         target_audience          " "
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
