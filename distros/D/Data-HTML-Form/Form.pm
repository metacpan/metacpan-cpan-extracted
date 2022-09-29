package Data::HTML::Form;

use strict;
use warnings;

use Error::Pure qw(err);
use List::Util qw(none);
use Mo qw(build is);
use Readonly;

Readonly::Array our @METHODS => qw(get post);
Readonly::Array our @ENCTYPES => (
	'application/x-www-form-urlencoded',
	'multipart/form-data',
	'text/plain',
);

our $VERSION = 0.04;

has action => (
	is => 'ro',
);

has css_class => (
	is => 'ro',
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

Data::HTML::Form - Data object for HTML form.

=head1 SYNOPSIS

 use Data::HTML::Form;

 my $obj = Data::HTML::Form->new(%params);
 my $action = $obj->action;
 my $css_class = $obj->css_class;
 my $enctype = $obj->enctype;
 my $id = $obj->id;
 my $label = $obj->label;
 my $method = $obj->method;

=head1 METHODS

=head2 C<new>

 my $obj = Data::HTML::Form->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<action>

Form action.

Default value is undef.

=item * C<css_class>

Form CSS class.

Default value is undef.

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

=head2 C<action>

 my $action = $obj->action;

Get form action.

Returns string.

=head2 C<css_class>

 my $css_class = $obj->css_class;

Get CSS class for form.

Returns string.

=head2 C<enctype>

 my $enctype = $obj->enctype;

Get enctype, attribute which specifies how the form-data should be encoded when
submitting it to the server.

Returns string.

=head2 C<id>

Get form identifier.

Returns string.

=head2 C<label>

Get form label.

Returns string.

=head2 C<method>

Get form method.

Returns string.

=head1 ERRORS

 new():
         Parameter 'enctype' has bad value.
                 Value: %s
         Parameter 'method' has bad value.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=form_default.pl

 use strict;
 use warnings;

 use Data::HTML::Form;

 my $obj = Data::HTML::Form->new;

 # Print out.
 print 'Method: '.$obj->method."\n";

 # Output:
 # Method: get

=head1 EXAMPLE2

=for comment filename=form.pl

 use strict;
 use warnings;

 use Data::HTML::Form;

 my $obj = Data::HTML::Form->new(
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
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HTML-Form>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
