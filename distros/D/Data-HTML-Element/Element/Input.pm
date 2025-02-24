package Data::HTML::Element::Input;

use strict;
use warnings;

use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo qw(build is);
use Mo::utils 0.26 qw(check_bool check_number);
use Mo::utils::CSS 0.02 qw(check_css_class);
use Readonly;
use Scalar::Util qw(looks_like_number);

Readonly::Array our @TYPES => qw(button checkbox color date datetime-local
	email file hidden image month number password radio range reset search
	submit tel text time url week);
Readonly::Array our @STEP_TYPES => qw(date datetime-local month number range time week);

our $VERSION = 0.17;

has autofocus => (
	is => 'ro',
);

has checked => (
	is => 'ro',
);

has css_class => (
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

has max => (
	is => 'ro',
);

has min => (
	is => 'ro',
);

has name => (
	is => 'ro',
);

has onclick => (
	is => 'ro',
);

has placeholder => (
	is => 'ro',
);

has readonly => (
	is => 'ro',
);

has required => (
	is => 'ro',
);

has size => (
	is => 'ro',
);

has step => (
	is => 'ro',
);

has value => (
	is => 'ro',
);

has type => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check autofocus.
	if (! defined $self->{'autofocus'}) {
		$self->{'autofocus'} = 0;
	}
	check_bool($self, 'autofocus');

	# Check checked.
	if (! defined $self->{'checked'}) {
		$self->{'checked'} = 0;
	}
	check_bool($self, 'checked');

	# Check CSS class.
	check_css_class($self, 'css_class');

	# Check disabled.
	if (! defined $self->{'disabled'}) {
		$self->{'disabled'} = 0;
	}
	check_bool($self, 'disabled');

	# Check max.
	check_number($self, 'max');

	# Check min.
	check_number($self, 'min');

	# Check readonly.
	if (! defined $self->{'readonly'}) {
		$self->{'readonly'} = 0;
	}
	check_bool($self, 'readonly');

	# Check required.
	if (! defined $self->{'required'}) {
		$self->{'required'} = 0;
	}
	check_bool($self, 'required');

	# Check size.
	check_number($self, 'size');

	# Check step.
	if (defined $self->{'step'}) {
		# Value 'any' is valid in step.
		if ($self->{'step'} ne 'any') {
			if (! looks_like_number($self->{'step'})) {
				err "Parameter 'step' must be a number or 'any' string.",
					'Value', $self->{'step'},
				;
			}
		}
	}

	# Check type.
	if (! defined $self->{'type'}) {
		$self->{'type'} = 'text';
	}
	if (none { $self->{'type'} eq $_ } @TYPES) {
		err "Parameter 'type' has bad value.";
	}

	# Check step and type.
	if (defined $self->{'step'}) {
		if (none { $self->type eq $_ } @STEP_TYPES) {
			err "Parameter 'step' is not valid for defined type.",
				'Type', $self->type,
			;
		}
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::HTML::Element::Input - Data object for HTML input element.

=head1 SYNOPSIS

 use Data::HTML::Element::Input;

 my $obj = Data::HTML::Element::Input->new(%params);
 my $autofocus = $obj->autofocus;
 my $checked = $obj->checked;
 my $css_class = $obj->css_class;
 my $disabled = $obj->disabled;
 my $id = $obj->id;
 my $label = $obj->label;
 my $max = $obj->max;
 my $min = $obj->min;
 my $name = $obj->name;
 my $onclick = $obj->onclick;
 my $placeholder = $obj->placeholder;
 my $readonly = $obj->readonly;
 my $required = $obj->required;
 my $size = $obj->size;
 my $step = $obj->step;
 my $value = $obj->value;
 my $type = $obj->type;

=head1 METHODS

=head2 C<new>

 my $obj = Data::HTML::Element::Input->new(%params);

Constructor.

=over 8

=item * C<autofocus>

Autofocus flag.

Default value is 0.

=item * C<checked>

Checked flag.

Default value is 0.

=item * C<css_class>

Input CSS class.

Default value is undef.

=item * C<disabled>

Disabled flag.

Default value is 0.

=item * C<id>

Input identifier.

Default value is undef.

=item * C<label>

Input label.

Default value is undef.

=item * C<max>

Input maximum value.

Default value is undef.

=item * C<min>

Input minimum value.

Default value is undef.

=item * C<name>

Input name.

Default value is undef.

=item * C<onclick>

OnClick code.

Default value is undef.

=item * C<placeholder>

Input placeholder.

Default value is undef.

=item * C<readonly>

Readonly flag.

Default value is 0.

=item * C<required>

Required flag.

Default value is 0.

=item * C<size>

Input width in characters.

Default value is undef.

=item * C<step>

Input step.

Value is number or 'any' string.

Default value is undef.

=item * C<value>

Input value.

Default value is undef.

=item * C<type>

Input type.

Possible value are:

=over

=item * button

=item * checkbox

=item * color

=item * date

=item * datetime-local

=item * email

=item * file

=item * hidden

=item * image

=item * month

=item * number

=item * password

=item * radio

=item * range

=item * reset

=item * search

=item * submit

=item * tel

=item * text

=item * time

=item * url

=item * week

=back

=back

Returns instance of object.

=head2 C<autofocus>

 my $autofocus = $obj->autofocus;

Get input autofocus flag.

Returns bool value (1/0).

=head2 C<checked>

 my $checked = $obj->checked;

Get input checked flag.

Returns bool value (1/0).

=head2 C<css_class>

 my $css_class = $obj->css_class;

Get CSS class for input.

Returns string.

=head2 C<disabled>

 my $disabled = $obj->disabled;

Get input disabled flag.

Returns bool value (1/0).

=head2 C<id>

 my $id = $obj->id;

Get input identifier.

Returns string.

=head2 C<label>

 my $label = $obj->label;

Get input label.

Returns string.

=head2 C<max>

 my $max = $obj->max;

Get input max value.

Returns number.

=head2 C<min>

 my $min = $obj->min;

Get input min value.

Returns number.

=head2 C<name>

 my $name = $obj->name;

Get input name value.

Returns string.

=head2 C<onclick>

 my $onclick = $obj->onclick;

Get OnClick code.

Returns string.

=head2 C<placeholder>

 my $placeholder = $obj->placeholder;

Get input placeholder.

Returns string.

=head2 C<readonly>

 my $readonly = $obj->readonly;

Get input readonly flag.

Returns bool value (1/0).

=head2 C<required>

 my $required = $obj->required;

Get input required flag.

Returns bool value (1/0).

=head2 C<size>

 my $size = $obj->size;

Get input size.

Returns number.

=head2 C<step>

 my $step = $obj->step;

Get input step.

Returns number of 'any' string.

=head2 C<value>

 my $value = $obj->value;

Get input value.

Returns string.

=head2 C<type>

 my $type = $obj->type;

Get input type.

Returns string.

=head1 ERRORS

 new():
         Parameter 'autofocus' must be a bool (0/1).
                 Value: %s
         Parameter 'checked' must be a bool (0/1).
                 Value: %s
         Parameter 'css_class' has bad CSS class name.
                 Value: %s
         Parameter 'css_class' has bad CSS class name (number on begin).
                 Value: %s
         Parameter 'disabled' must be a bool (0/1).
                 Value: %s
         Parameter 'max' must be a number.
                 Value: %s
         Parameter 'min' must be a number.
                 Value: %s
         Parameter 'readonly' must be a bool (0/1).
                 Value: %s
         Parameter 'required' must be a bool (0/1).
                 Value: %s
         Parameter 'size' must be a number.
                 Value: %s
         Parameter 'step' is not valid for defined type.
                 Type: %s
         Parameter 'step' must be a number or 'any' string.
                 Value: %s
         Parameter 'type' has bad value.

=head1 EXAMPLE

=for comment filename=input_text.pl

 use strict;
 use warnings;

 use Data::HTML::Element::Input;

 my $obj = Data::HTML::Element::Input->new(
        'autofocus' => 1,
        'css_class' => 'input',
        'id' => 'address',
        'label' => 'Customer address',
        'placeholder' => 'Place address',
        'type' => 'text',
 );

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Type: '.$obj->type."\n";
 print 'CSS class: '.$obj->css_class."\n";
 print 'Label: '.$obj->label."\n";
 print 'Autofocus: '.$obj->autofocus."\n";
 print 'Placeholder: '.$obj->placeholder."\n";

 # Output:
 # Id: address
 # Type: text
 # CSS class: input
 # Label: Customer address
 # Autofocus: 1
 # Placeholder: Place address

=head1 DEPENDENCIES

L<Error::Pure>,
L<List::Util>,
L<Mo>,
L<Mo::utils>,
L<Mo::utils::CSS>,
L<Readonly>,
L<Scalar::Util>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HTML-Element>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.17

=cut
