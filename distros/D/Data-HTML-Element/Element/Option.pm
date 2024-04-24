package Data::HTML::Element::Option;

use strict;
use warnings;

use Data::HTML::Element::Utils qw(check_data check_data_type);
use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo qw(build is);
use Mo::utils qw(check_array check_bool check_number);
use Mo::utils::CSS qw(check_css_class);

our $VERSION = 0.15;

has css_class => (
	is => 'ro',
);

has data => (
	default => [],
	is => 'ro',
);

has data_type => (
	is => 'ro',
);

has disabled => (
	is => 'ro',
);

has id => (
	is => 'ro',
);

has label => (
	is => 'ro',
);

has selected => (
	is => 'ro',
);

has value => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check CSS class.
	check_css_class($self, 'css_class');

	# Check data type.
	check_data_type($self);

	# Check data based on type.
	check_data($self);

	# Check disabled.
	if (! defined $self->{'disabled'}) {
		$self->{'disabled'} = 0;
	}
	check_bool($self, 'disabled');

	# Check selected.
	if (! defined $self->{'selected'}) {
		$self->{'selected'} = 0;
	}
	check_bool($self, 'selected');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::HTML::Element::Option - Data object for HTML option element.

=head1 SYNOPSIS

 use Data::HTML::Element::Option;

 my $obj = Data::HTML::Element::Option->new(%params);
 my $css_class = $obj->css_class;
 my $data = $obj->data;
 my $data_type = $obj->data_type;
 my $disabled = $obj->disabled;
 my $id = $obj->id;
 my $label = $obj->label;
 my $selected = $obj->selected;
 my $value = $obj->value;

=head1 METHODS

=head2 C<new>

 my $obj = Data::HTML::Element::Option->new(%params);

Constructor.

=over 8

=item * C<css_class>

Option CSS class.

Default value is undef.

=item * C<data>

Data content. It's reference to array.

Data type of data is described in 'data_type' parameter.

Default value is [].

=item * C<data_type>

Data type for content.

Possible value are: cb plain tags

The 'cb' content is code reference.
The 'plain' content are string(s).
The 'tags' content is structure described in L<Tags>.

Default value is 'plain'.

=item * C<disabled>

Disabled flag.

Default value is 0.

=item * C<id>

Option identifier.

Default value is undef.

=item * C<label>

Option label.

Default value is undef.

=item * C<selected>

Selected flag.

Default value is 0.

=item * C<value>

Option value.

Default value is undef.

=back

Returns instance of object.

=head2 C<css_class>

 my $css_class = $obj->css_class;

Get CSS class for option.

Returns string.

=head2 C<data>

 my $data = $obj->data;

Get data inside option element.

Returns reference to array.

=head2 C<data_type>

 my $data_type = $obj->data_type;

Get option data type.

Returns string.

=head2 C<disabled>

 my $disabled = $obj->disabled;

Get option disabled flag.

Returns bool value (1/0).

=head2 C<id>

 my $id = $obj->id;

Get option identifier.

Returns string.

=head2 C<label>

 my $label = $obj->label;

Get option label.

Returns string.

=head2 C<selected>

 my $selected = $obj->selected;

Get selected flag.

Returns bool value (1/0).

=head2 C<value>

 my $value = $obj->value;

Get option value.

Returns string.

=head1 ERRORS

 new():
         Parameter 'css_class' has bad CSS class name.
                 Value: %s
         Parameter 'css_class' has bad CSS class name (number on begin).
                 Value: %s
         Parameter 'data' must be a array.
                 Value: %s
                 Reference: %s
         Parameter 'data' in 'plain' mode must contain reference to array with scalars.
         Parameter 'data' in 'tags' mode must contain reference to array with references to array with Tags structure.
         Parameter 'data_type' has bad value.
         Parameter 'disabled' must be a bool (0/1).
                 Value: %s
         Parameter 'selected' must be a bool (0/1).
                 Value: %s

=head1 EXAMPLE

=for comment filename=option.pl

 use strict;
 use warnings;

 use Data::HTML::Element::Option;

 my $obj = Data::HTML::Element::Option->new(
        'css_class' => 'opt',
        'id' => 7,
        'label' => 'Audi',
        'selected' => 1,
        'value' => 'audi',
 );

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'CSS class: '.$obj->css_class."\n";
 print 'Label: '.$obj->label."\n";
 print 'Value: '.$obj->value."\n";
 print 'Selected: '.$obj->selected."\n";

 # Output:
 # Id: 7
 # CSS class: opt
 # Label: Audi
 # Value: audi
 # Selected: 1

=head1 DEPENDENCIES

L<Data::HTML::Element::Utils>,
L<Error::Pure>,
L<List::Util>,
L<Mo>,
L<Mo::utils>,
L<Mo::utils::CSS>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HTML-Element>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.15

=cut
