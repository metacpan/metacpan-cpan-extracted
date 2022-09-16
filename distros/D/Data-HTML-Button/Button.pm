package Data::HTML::Button;

use strict;
use warnings;

use Error::Pure qw(err);
use List::Util qw(none);
use Mo qw(build default is);
use Mo::utils qw(check_bool check_required);
use Readonly;

Readonly::Array our @DATA_TYPES => qw(plain tags);
Readonly::Array our @ENCTYPES => (
	'application/x-www-form-urlencoded',
	'multipart/form-data',
	'text/plain',
);
Readonly::Array our @FORM_METHODS => qw(get post);
Readonly::Array our @TYPES => qw(button reset submit);

our $VERSION = 0.02;

has autofocus => (
	ro => 1,
);

has css_class => (
	ro => 1,
);

has data => (
	default => [],
	ro => 1,
);

has data_type => (
	ro => 1,
);

has disabled => (
	ro => 1,
);

has form => (
	ro => 1,
);

has form_enctype => (
	ro => 1,
);

has form_method => (
	ro => 1,
);

has id => (
	ro => 1,
);

has label => (
	ro => 1,
);

has name => (
	ro => 1,
);

has type => (
	ro => 1,
);

has value => (
	ro => 1,
);

sub BUILD {
	my $self = shift;

	# Check autofocus.
	if (! defined $self->{'autofocus'}) {
		$self->{'autofocus'} = 0;
	}
	check_bool($self, 'autofocus');

	# Check data type.
	if (! defined $self->{'data_type'}) {
		$self->{'data_type'} = 'plain';
	}
	if (none { $self->{'data_type'} eq $_ } @DATA_TYPES) {
		err "Parameter 'data_type' has bad value.";
	}

	# Check disabled.
	if (! defined $self->{'disabled'}) {
		$self->{'disabled'} = 0;
	}
	check_bool($self, 'disabled');

	# Check form_enctype.
	if (defined $self->{'form_enctype'}) {
		if (none { $self->{'form_enctype'} eq $_ } @ENCTYPES) {
			err "Parameter 'form_enctype' has bad value.",
				'Value', $self->{'form_enctype'},
			;
		}
	}

	# Check form_method.
	if (! defined $self->{'form_method'}) {
		$self->{'form_method'} = 'get';
	}
	if (none { $self->{'form_method'} eq $_ } @FORM_METHODS) {
		err "Parameter 'form_method' has bad value.";
	}

	# Check type.
	if (! defined $self->{'type'}) {
		$self->{'type'} = 'button';
	}
	if (none { $self->{'type'} eq $_ } @TYPES) {
		err "Parameter 'type' has bad value.";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::HTML::Button - Data object for HTML button element.

=head1 SYNOPSIS

 use Data::HTML::Button;

 my $obj = Data::HTML::Button->new(%params);
 my $autofocus = $obj->autofocus;
 my $css_class = $obj->css_class;
 my $data = $obj->data;
 my $data_type = $obj->data_type;
 my $disabled = $obj->disabled;
 my $form = $obj->form;
 my $form_enctype = $obj->form_enctype;
 my $form_method = $obj->form_method;
 my $id = $obj->id;
 my $label = $obj->label;
 my $name = $obj->name;
 my $type = $obj->type;
 my $value = $obj->value;

=head1 METHODS

=head2 C<new>

 my $obj = Data::HTML::Button->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<autofocus>

Button autofocus flag.

Default value is 0.

=item * C<css_class>

Button CSS class.

Default value is undef.

=item * C<data>

Button data content. It's reference to array.
Data type of data is described in 'data_type' parameter.

Default value is [].

=item * C<data_type>

Button data type for content.

Possible value are: plain tags

Default value is 'plain'.

=item * C<disabled>

Button autofocus flag.

Default value is 0.

=item * C<form>

Button form id.

Default value is undef.

=item * C<form_enctype>

Button form encoding.
It's valuable for 'submit' type.

Possible values are: application/x-www-form-urlencoded multipart/form-data text/plain

Default value is undef.

=item * C<form_method>

Button form method.
It's valuable for 'submit' type.

Possible values are: get post

Default value is 'get'.

=item * C<id>

Button identifier.

Default value is undef.

=item * C<label>

Button label.

Default value is undef.

=item * C<name>

Button name.

Default value is undef.

=item * C<type>

Button element type.

Possible types: button reset submit

Default value is 'button'.

=item * C<value>

Button value.

Default value is undef.

=back

=head2 C<autofocus>

 my $autofocus = $obj->autofocus;

Get button autofocus flag.

Returns bool value (1/0).

=head2 C<css_class>

 my $css_class = $obj->css_class;

Get CSS class for button.

Returns string.

=head2 C<data>

 my $data = $obj->data;

Get data inside button element.

Returns reference to array.

=head2 C<data_type>

 my $data_type = $obj->data_type;

Get button data type.

Returns string.

=head2 C<disabled>

 my $disabled = $obj->disabled;

Get button disabled flag.

Returns bool value (1/0).

=head2 C<form>

 my $form = $obj->form;

Get button form id.

Returns string.

=head2 C<form_enctype>

 my $form_enctype = $obj->form_enctype;

Get button form enctype.

Returns string.

=head2 C<form_method>

 my $form_method = $obj->form_method;

Get button form method.

Returns string.

=head2 C<id>

 my $id = $obj->id;

Get button identifier.

Returns string.

=head2 C<label>

 my $label = $obj->label;

Get button label.

Returns string.

=head2 C<name>

 my $name = $obj->name;

Get button name.

Returns string.

=head2 C<type>

 my $type = $obj->type;

Get button type.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get button value.

Returns string.

=head1 ERRORS

 new():
         Parameter 'autofocus' must be a bool (0/1).
                Value: %s
         Parameter 'data_type' has bad value.
         Parameter 'disabled' must be a bool (0/1).
                Value: %s
         Parameter 'form_enctype' has bad value.
                 Value: %s
         Parameter 'form_method' has bad value.
         Parameter 'type' has bad value.

=head1 EXAMPLE1

=for comment filename=button_default.pl

 use strict;
 use warnings;

 use Data::HTML::Button;

 my $obj = Data::HTML::Button->new;

 # Print out.
 print 'Data type: '.$obj->data_type."\n";
 print 'Form method: '.$obj->form_method."\n";
 print 'Type: '.$obj->type."\n";

 # Output:
 # Data type: plain
 # Form method: get
 # Type: button

=head1 EXAMPLE2

=for comment filename=button_tags.pl

 use strict;
 use warnings;

 use Data::HTML::Button;
 use Tags::Output::Raw;

 my $obj = Data::HTML::Button->new(
         # Tags(3pm) structure.
         'data' => [
                 ['b', 'span'],
                 ['d', 'Button'],
                 ['e', 'span'],
         ],
         'data_type' => 'tags',
 );

 my $tags = Tags::Output::Raw->new;

 # Serialize data to output.
 $tags->put(@{$obj->data});
 my $data = $tags->flush(1);

 # Print out.
 print 'Data (serialized): '.$data."\n";
 print 'Data type: '.$obj->data_type."\n";
 print 'Form method: '.$obj->form_method."\n";
 print 'Type: '.$obj->type."\n";

 # Output:
 # Data (serialized): <span>Button</span>
 # Data type: tags
 # Form method: get
 # Type: button

=head1 EXAMPLE3

=for comment filename=button_plain.pl

 use strict;
 use warnings;

 use Data::HTML::Button;

 my $obj = Data::HTML::Button->new(
         # Plain content.
         'data' => [
                 'Button',
         ],
         'data_type' => 'plain',
 );

 # Serialize data to output.
 my $data = join ' ', @{$obj->data};

 # Print out.
 print 'Data: '.$data."\n";
 print 'Data type: '.$obj->data_type."\n";
 print 'Form method: '.$obj->form_method."\n";
 print 'Type: '.$obj->type."\n";

 # Output:
 # Data: Button
 # Data type: plain
 # Form method: get
 # Type: button

=head1 DEPENDENCIES

L<Error::Pure>,
L<List::Util>,
L<Mo>,
L<Mo::utils>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HTML-Button>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
