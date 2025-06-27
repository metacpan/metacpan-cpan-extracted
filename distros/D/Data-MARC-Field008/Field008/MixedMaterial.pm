package Data::MARC::Field008::MixedMaterial;

use strict;
use warnings;

use Data::MARC::Field008::Utils qw(check_item_form);
use Error::Pure qw(err);
use Error::Pure::Utils qw(clean err_get);
use Mo qw(build is);
use Mo::utils 0.22 qw(check_length_fix check_required check_strings);

our $STRICT = 1;

our $VERSION = 0.03;

has form_of_item => (
	is => 'ro',
);

has raw => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'raw'
	check_length_fix($self, 'raw', 17);

	# Check 'form_of_item'.
	eval { check_item_form($self, 'form_of_item'); };

	if ($STRICT) {
		my @errors = err_get();
		if (@errors) {
			err "Couldn't create data object of mixed material.",
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

Data::MARC::Field008::MixedMaterial - Data object for MARC field 008 mixed material.

=head1 SYNOPSIS

 use Data::MARC::Field008::MixedMaterial;

 my $obj = Data::MARC::Field008::MixedMaterial->new(%params);
 my $form_of_item = $obj->form_of_item;
 my $raw = $obj->form_of_item;

=head1 METHODS

=head2 C<new>

 my $obj = Data::MARC::Field008::MixedMaterial->new(%params);

Constructor.

=over 8

=item * C<form_of_item>

Form of item. The length of the item is 1 character.
Possible characters are ' ', 'a', 'b', 'c', 'd', 'f', 'o', 'q', 'r', 's' or '|'.

It's required.

Default value is undef.

=item * C<raw>

Raw string of material. The length of the string is 17 characters.

It's optional.

Default value is undef.

=back

Returns instance of object.

=head2 C<form_of_item>

 my $form_of_item = $obj->form_of_item;

Get form of item.

Returns string

=head2 C<raw>

 my $raw = $obj->form_of_item;

Get raw string of the block.

Returns string.

=head1 ERRORS

 new():
         Couldn't create data object of mixed material.
                 Raw string: %s
         Parameter 'raw' has length different than '17'.
                 Value: %s
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

=for comment filename=create_and_dump_marc_field_008_mixed_material.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::MARC::Field008::MixedMaterial;

 my $obj = Data::MARC::Field008::MixedMaterial->new(
         'form_of_item' => 'o',
         #         89012345678901234
         'raw' => '     o           ',
 );

 # Print out.
 p $obj;

 # Output:
 # Data::MARC::Field008::MixedMaterial  {
 #     parents: Mo::Object
 #     public methods (7):
 #         BUILD
 #         Data::MARC::Field008::Utils:
 #             check_item_form
 #         Error::Pure:
 #             err
 #         Error::Pure::Utils:
 #             err_get
 #         Mo::utils:
 #             check_length_fix, check_required, check_strings
 #     private methods (0)
 #     internals: {
 #         form_of_item   "o",
 #         raw            "     o           "
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
