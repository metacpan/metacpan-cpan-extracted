package Data::HTML::Element::Textarea;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_bool check_number);
use Mo::utils::CSS qw(check_css_class);

our $VERSION = 0.09;

has autofocus => (
	is => 'ro',
);

has cols => (
	is => 'ro',
);

has css_class => (
	is => 'ro',
);

has disabled => (
	is => 'ro',
);

has form => (
	is => 'ro',
);

has id => (
	is => 'ro',
);

has label => (
	is => 'ro',
);

has name => (
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

has rows => (
	is => 'ro',
);

has value => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check autofocus.
	if (! defined $self->{'autofocus'}) {
		$self->{'autofocus'} = 0;
	}
	check_bool($self, 'autofocus');

	# Check css_class.
	check_css_class($self, 'css_class');

	# Check cols.
	check_number($self, 'cols');

	# Check disabled.
	if (! defined $self->{'disabled'}) {
		$self->{'disabled'} = 0;
	}
	check_bool($self, 'disabled');

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

	# Check rows.
	check_number($self, 'rows');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::HTML::Element::Textarea - Data object for HTML textarea element.

=head1 SYNOPSIS

 use Data::HTML::Element::Textarea;

 my $obj = Data::HTML::Element::Textarea->new(%params);
 my $autofocus = $obj->autofocus;
 my $cols = $obj->cols;
 my $css_class = $obj->css_class;
 my $disabled = $obj->disabled;
 my $form = $obj->form;
 my $id = $obj->id;
 my $label = $obj->label;
 my $name = $obj->name;
 my $placeholder = $obj->placeholder;
 my $readonly = $obj->readonly;
 my $required = $obj->required;
 my $rows = $obj->rows;
 my $value = $obj->value;

=head1 METHODS

=head2 C<new>

 my $obj = Data::HTML::Element::Textarea->new(%params);

Constructor.

=over 8

=item * C<autofocus>

Textarea autofocus flag.

Default value is 0.

=item * C<cols>

Textarea columns number.

Default value is undef.

=item * C<css_class>

Textarea CSS class.

Default value is undef.

=item * C<disabled>

Textarea disabled flag.

Default value is 0.

=item * C<form>

Textarea form id.

Default value is undef.

=item * C<id>

Form identifier.

Default value is undef.

=item * C<label>

Form label.

Default value is undef.

=item * C<name>

Form name.

Default value is undef.

=item * C<placeholder>

Form placeholder.

Default value is undef.

=item * C<readonly>

Textarea readonly flag.

Default value is 0.

=item * C<required>

Textarea required flag.

Default value is 0.

=item * C<rows>

Textarea rows number.

Default value is undef.

=item * C<value>

Textarea value.

Default value is undef.

=back

Returns instance of object.

=head2 C<autofocus>

 my $autofocus = $obj->autofocus;

Get autofocus boolean flag for textarea.

Returns 0/1.

=head2 C<cols>

 my $cols = $obj->cols;

Get textarea column number.

Returns number.

=head2 C<css_class>

 my $css_class = $obj->css_class;

Get CSS class for textarea.

Returns string.

=head2 C<disabled>

 my $disabled = $obj->disabled;

Get disabled boolean flag for textarea.

Returns 0/1.

=head2 C<form>

 my $form = $obj->form;

Get form id for textarea.

Returns string.

=head2 C<id>

 my $id = $obj->id;

Get textarea identifier.

Returns string.

=head2 C<label>

 my $label = $obj->label;

Get textarea label.

Returns string.

=head2 C<name>

 my $name = $obj->name;

Get textarea name.

Returns string.

=head2 C<placeholder>

 my $placeholder = $obj->placeholder;

Get textarea placeholder.

Returns string.

=head2 C<readonly>

 my $readonly = $obj->readonly;

Get readonly boolean flag for textarea.

Returns 0/1.

=head2 C<required>

 my $required = $obj->required;

Get required boolean flag for textarea.

Returns 0/1.

=head2 C<rows>

 my $rows = $obj->rows;

Get textarea rows number.

Returns number.

=head2 C<value>

 my $value = $obj->value;

Get textarea value.

Returns string.

=head1 ERRORS

 new():
         Parameter 'autofocus' must be a bool (0/1).
                 Value: %s
         Parameter 'cols' must be a number.
                 Value: %s
         Parameter 'disabled' must be a bool (0/1).
                 Value: %s
         Parameter 'readonly' must be a bool (0/1).
                 Value: %s
         Parameter 'required' must be a bool (0/1).
                 Value: %s
         Parameter 'rows' must be a number.
                 Value: %s

=head1 EXAMPLE

=for comment filename=textarea.pl

 use strict;
 use warnings;

 use Data::HTML::Element::Textarea;

 my $obj = Data::HTML::Element::Textarea->new(
        'autofocus' => 1,
        'css_class' => 'textarea',
        'id' => 'textarea-id',
        'label' => 'Textarea label',
        'value' => 'Textarea value',
 );

 # Print out.
 print 'Autofocus: '.$obj->autofocus."\n";
 print 'CSS class: '.$obj->css_class."\n";
 print 'Disabled: '.$obj->disabled."\n";
 print 'Id: '.$obj->id."\n";
 print 'Label: '.$obj->label."\n";
 print 'Readonly: '.$obj->readonly."\n";
 print 'Required: '.$obj->required."\n";
 print 'Value: '.$obj->value."\n";

 # Output:
 # Autofocus: 1
 # CSS class: textarea
 # Disabled: 0
 # Id: textarea-id
 # Label: Textarea label
 # Readonly: 0
 # Required: 0
 # Value: Textarea value

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::CSS>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HTML-Textarea>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.09

=cut
