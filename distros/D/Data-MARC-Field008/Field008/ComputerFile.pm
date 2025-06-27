package Data::MARC::Field008::ComputerFile;

use strict;
use warnings;

use Data::MARC::Field008::Utils qw(check_computer_file_item_form
	check_computer_file_type check_government_publication
	check_target_audience);
use Error::Pure qw(err);
use Error::Pure::Utils qw(clean err_get);
use Mo qw(build is);
use Mo::utils 0.22 qw(check_length_fix check_required);

our $STRICT = 1;

our $VERSION = 0.03;

has form_of_item => (
	is => 'ro',
);

has government_publication => (
	is => 'ro',
);

has raw => (
	is => 'ro',
);

has target_audience => (
	is => 'ro',
);

has type_of_computer_file => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'raw'
	check_length_fix($self, 'raw', 17);

	# Check 'form_of_item'.
	eval { check_computer_file_item_form($self, 'form_of_item'); };

	# Check 'government_publication'.
	eval { check_government_publication($self, 'government_publication'); };

	# Check 'target_audience'.
	eval { check_target_audience($self, 'target_audience'); };

	# Check 'type_of_computer_file'.
	eval { check_computer_file_type($self, 'type_of_computer_file'); };

	if ($STRICT) {
		my @errors = err_get();
		if (@errors) {
			err "Couldn't create data object of computer file.",
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

Data::MARC::Field008::ComputerFile - Data object for MARC field 008 computer file material.

=head1 SYNOPSIS

 use Data::MARC::Field008::ComputerFile;

 my $obj = Data::MARC::Field008::ComputerFile->new(%params);
 my $form_of_item = $obj->form_of_item;
 my $government_publication = $obj->government_publication;
 my $raw = $obj->raw;
 my $target_audience = $obj->target_audience;
 my $type_of_computer_file = $obj->type_of_computer_file;

=head1 METHODS

=head2 C<new>

 my $obj = Data::MARC::Field008::ComputerFile->new(%params);

Constructor.

=over 8

=item * C<form_of_item>

Form of item. The length of the item is 1 character.
Possible characters are ' ', 'o', 'q' or '|'.

It's required.

Default value is undef.

=item * C<government_publication>

Government publication. The length of the string is 1 character.
Possible characters are ' ', 'a', 'c', 'f', 'i', 'l', 'm', 'o', 's', 'u', 'z' or '|'.

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

=item * C<type_of_computer_file>

Type of computer file. The length of the item is 1 character.
Possible characters are 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'm',
'u', 'z' or '|'.

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

Get government publication.

Returns string.

=head2 C<raw>

 my $raw = $obj->form_of_item;

Get raw string of the block.

Returns string.

=head2 C<target_audience>

 my $target_audience = $obj->target_audience;

Get target audience.

Returns string.

=head2 C<type_of_computer_file>

 my $type_of_computer_file = $obj->type_of_computer_file;

Get type of computer file.

Returns string.

=head1 ERRORS

 new():
         Couldn't create data object of computer file.
                 Raw string: %s
         Parameter 'raw' has length different than '17'.
                 Value: %s
         From Data::MARC::Field008::Utils::check_computer_file_item_form():
                 Parameter 'form_of_item' has bad value.
                         Value: %s
                 Parameter 'form_of_item' is required.
                 Parameter 'form_of_item' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'form_of_item' must be a scalar value.
                         Reference: %s
         From Data::MARC::Field008::Utils::check_computer_file_type():
                 Parameter 'type_of_computer_file' has bad value.
                         Value: %s
                 Parameter 'type_of_computer_file' is required.
                 Parameter 'type_of_computer_file' length is bad.
                         Length: %s
                         Value: %s
                         Expected length: 1
                 Parameter 'type_of_computer_file' must be a scalar value.
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

=for comment filename=create_and_dump_marc_field_008_computer_file_material.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::MARC::Field008::ComputerFile;

 # cnb000208289
 my $obj = Data::MARC::Field008::ComputerFile->new(
         'form_of_item' => ' ',
         'government_publication' => ' ',
         #         89012345678901234
         'raw' => '        m        ',
         'target_audience' => ' ',
         'type_of_computer_file' => 'm',
 );

 # Print out.
 p $obj;

 # Output:
 # Data::MARC::Field008::ComputerFile  {
 #     parents: Mo::Object
 #     public methods (9):
 #         BUILD
 #         Data::MARC::Field008::Utils:
 #             check_computer_file_item_form, check_computer_file_type, check_government_publication, check_target_audience
 #         Error::Pure:
 #             err
 #         Error::Pure::Utils:
 #             err_get
 #         Mo::utils:
 #             check_length_fix, check_required
 #     private methods (0)
 #     internals: {
 #         form_of_item             " ",
 #         government_publication   " ",
 #         raw                      "        m        ",
 #         target_audience          " ",
 #         type_of_computer_file    "m"
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
