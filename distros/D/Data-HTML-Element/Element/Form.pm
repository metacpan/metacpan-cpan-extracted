package Data::HTML::Element::Form;

use strict;
use warnings;

use Data::HTML::Element::Utils qw(check_data check_data_type);
use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo qw(build is);
use Mo::utils::CSS qw(check_css_class);
use Readonly;

Readonly::Array our @METHODS => qw(get post);
Readonly::Array our @ENCTYPES => (
	'application/x-www-form-urlencoded',
	'multipart/form-data',
	'text/plain',
);

our $VERSION = 0.10;

has action => (
	is => 'ro',
);

has css_class => (
	is => 'ro',
);

has data => (
	default => [],
	ro => 1,
);

has data_type => (
	ro => 1,
);

has enctype => (
	is => 'ro',
);

has id => (
	is => 'ro',
);

has label => (
	is => 'ro',
);

has method => (
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

	# Check enctype.
	if (defined $self->{'enctype'}) {
		if (none { $self->{'enctype'} eq $_ } @ENCTYPES) {
			err "Parameter 'enctype' has bad value.",
				'Value', $self->{'enctype'},
			;
		}
	}

	# Check method.
	if (! defined $self->{'method'}) {
		$self->{'method'} = 'get';
	}
	if (none { $self->{'method'} eq $_ } @METHODS) {
		err "Parameter 'method' has bad value.",
			'Value', $self->{'method'};
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::HTML::Element::Form - Data object for HTML form element.

=head1 SYNOPSIS

 use Data::HTML::Element::Form;

 my $obj = Data::HTML::Element::Form->new(%params);
 my $action = $obj->action;
 my $css_class = $obj->css_class;
 my $data = $obj->data;
 my $data_type = $obj->data_type;
 my $enctype = $obj->enctype;
 my $id = $obj->id;
 my $label = $obj->label;
 my $method = $obj->method;

=head1 METHODS

=head2 C<new>

 my $obj = Data::HTML::Element::Form->new(%params);

Constructor.

=over 8

=item * C<action>

Form action.

Default value is undef.

=item * C<css_class>

Form CSS class.

Default value is undef.

=item * C<data>

Data content. It's reference to array.

Data type of data is described in 'data_type' parameter.

Default value is [].

=item * C<data_type>

Data type for content.

Possible value are: plain tags

The 'plain' content are string(s).
The 'tags' content is structure described in L<Tags>.

Default value is 'plain'.

=item * C<enctype>

Form enctype, attribute which specifies how the form-data should be encoded when
submitting it to the server.

Possible values are:

=over

=item * (undefined - same as application/x-www-form-urlencoded)

=item * application/x-www-form-urlencoded

=item * multipart/form-data

=item * text/plain

=back

Default value is undef.

=item * C<id>

Form identifier.

Default value is undef.

=item * C<label>

Form label.

Default value is undef.

=item * C<method>

Form method.

Default value is 'get'.

Possible methods are: get and post

=back

Returns instance of object.

=head2 C<action>

 my $action = $obj->action;

Get form action.

Returns string.

=head2 C<css_class>

 my $css_class = $obj->css_class;

Get CSS class for form.

Returns string.

=head2 C<data>

 my $data = $obj->data;

Get data inside button element.

Returns reference to array.

=head2 C<data_type>

 my $data_type = $obj->data_type;

Get button data type.

Returns string.

=head2 C<enctype>

 my $enctype = $obj->enctype;

Get enctype, attribute which specifies how the form-data should be encoded when
submitting it to the server.

Returns string.

=head2 C<id>

 my $id = $obj->id;

Get form identifier.

Returns string.

=head2 C<label>

 my $label = $obj->label;

Get form label.

Returns string.

=head2 C<method>

 my $method = $obj->method;

Get form method.

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
         Parameter 'enctype' has bad value.
                 Value: %s
         Parameter 'method' has bad value.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=form_default.pl

 use strict;
 use warnings;

 use Data::HTML::Element::Form;

 my $obj = Data::HTML::Element::Form->new;

 # Print out.
 print 'Method: '.$obj->method."\n";

 # Output:
 # Method: get

=head1 EXAMPLE2

=for comment filename=form.pl

 use strict;
 use warnings;

 use Data::HTML::Element::Form;

 my $obj = Data::HTML::Element::Form->new(
        'action' => '/action.pl',
        'css_class' => 'form',
        'enctype' => 'multipart/form-data',
        'id' => 'form-id',
        'label' => 'Form label',
        'method' => 'post',
 );

 # Print out.
 print 'Action: '.$obj->action."\n";
 print 'CSS class: '.$obj->css_class."\n";
 print 'Enctype: '.$obj->enctype."\n";
 print 'Id: '.$obj->id."\n";
 print 'Label: '.$obj->label."\n";
 print 'Method: '.$obj->method."\n";

 # Output:
 # Action: /action.pl
 # CSS class: form
 # Enctype: multipart/form-data
 # Id: form-id
 # Label: Form label
 # Method: post

=head1 DEPENDENCIES

L<Error::Pure>,
L<List::Util>,
L<Mo>,
L<Mo::utils::CSS>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HTML-Element>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.10

=cut
