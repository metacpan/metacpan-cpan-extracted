=encoding utf-8

=head1 NAME

Business::cXML::Object - Generic cXML object

=head1 SYNOPSIS

	package Business::cXML::YourPackage;
	use base qw(Business::cXML::Object);

	use constant NODENAME => 'XMLNodeName';

	use constant PROPERTIES => (
		first_name => '',
		last_name  => undef,
		emails     => [],
		phone      => undef,
	);
	# new(), first_name(), last_name() and emails() get/set methods will be provided automatically

	# Optionally: an e-mail is actually a Something::Email object
	# Even more optional: a phone is actually a Something::Number with "Phone" argument
	use constant OBJ_PROPERTIES => (
		emails => 'Something::Email',
		phone  => [ 'Something::Number', 'Phone' ],
	);

=head1 DESCRIPTION

Base class for cXML objects which represent useful data (pretty much every
module except L<Business::cXML> and L<Business::cXML::Transmission>).

Declarations in I<C<PROPERTIES>> represent property names to create in new
instances along with their default value.  A default value of C<undef> is
acceptable: every possible property must be explicitly declared.  A default
value of C<[]> indicates that the property is a list instead of a single
value.  C<can()> will behave as expected, recognizing your methods and
automatic property methods.

Declare those properties which should be objects (or lists of objects) of a
specific class in optional I<C<OBJ_PROPERTIES>> (in addition to
I<C<PROPERTIES>>) to specify which class (see example in L</SYNOPSIS>).  If
the class is actually an arrayref, the first element will be considered the
class name and all other elements will be passed as arguments to the class'
C<new()> after the value hashref argument.

I<C<NODENAME>> will be used in cases where C<_nodeName> cannot be
inferred from context.

=cut

use 5.014;
use strict;

package Business::cXML::Object;

use Carp;
use Clone qw(clone);

use constant PROPERTIES       => ();
use constant OBJ_PROPERTIES   => ();
use constant NODENAME => 'GenericNode';

=head1 COMMON METHODS

The following methods are automatically available in all objects which inherit
from this one.

=over

=item C<B<new>( [I<$nodename>], [I<$node>], [I<$properties>] )>

In some cases, specifying I<$nodename> is necessary, such as when creating a
new multi-name object like L<Business::cXML::Amount> without a source
I<$node>.  This sets property C<_nodeName>.  Alternatively, I<C<$properties>>
can also contain a C<_nodeName>, which is writeable during object creation.

L<XML::LibXML::Element> I<C<$node>> is passed to L</from_node()>.

Hashref I<C<$properties>> is passed to L</set()>.

=cut

sub new {
	my $class = shift;

	# Create instance
	my $self = {
		_nodeName => undef,
	};
	bless $self, $class;  # $self->isa() true for 'Business::cXML::Object' and your own class, magically

	# Populate with declared default values
	$self->{_nodeName} = clone($self->NODENAME);  # First in case PROPERTIES overrides it
	my %fields = $self->PROPERTIES;
	$self->{$_} = clone($fields{$_}) foreach keys %fields;

	# Process arguments
	foreach (@_) {
		if (ref($_) eq 'HASH') {
			$self->set(%{ $_ });
		} elsif (ref($_)) {
			$self->{_nodeName} = $_->nodeName;
			$self->from_node($_);
		} else {
			$self->{_nodeName} = $_;
		};
	};

	return $self;
}

=item C<B<set>( I<%properties> )>

Batch sets all known read-write properties, safely ignoring any unknown keys.

=cut

sub set {
	my ($self, %props) = @_;
	$self->_getset($_, $props{$_}) foreach keys %props;
}

=item C<B<copy>( I<$object> )>

Copy data from another cXML object into our own, only considering known
properties.  It is thus theoretically safe to copy from an object of a
different class.  Deep structures (hashes, arrays, other objects) are cloned
into new copies.

=cut

sub copy {
	my ($self, $other) = @_;
	my %fields = $self->PROPERTIES;
	foreach (keys %fields) {
		$self->{$_} = clone($other->{$_}) if exists $other->{$_};
	};
}

=back

The following methods are required to be provided by classes which inherit
from this one.

=over

=item C<B<from_node>( I<$node> )>

Overwrite our internal data from what is found by traversing I<C<$node>>, a
L<XML::LibXML::Element>.

=item C<B<to_node>( I<$doc> )>

Returns an L<XML::LibXML::Element> constructed from our internal data.
I<C<$doc>> can be any existing L<XML::LibXML::Element> so that this method can
return a new detached element within the same existing document.

=item C<B<can>( I<$methodname> )>

L<UNIVERSAL::can()> is properly overloaded according to L</PROPERTIES> so it
can still safely be used.

=cut

sub can {
	my ($self, $method) = @_;
	my $universal = UNIVERSAL::can($self, $method);
	unless (defined $universal) {
		my %fields = $self->PROPERTIES;
		$universal = \&AUTOLOAD if exists $self->{$method};
	};
	return $universal;
}

=back

=head1 PROPERTY METHODS

Each property declared in I<C<PROPERTIES>> of classes which inherit from this
one, can be read from and written to by invoking a method of the same name.

Calling with no arguments (perhaps not even parenthesis) returns the current
value.

Calling with an argument overwrites the property and returns the new value.
For arrayref properties (documented with a C<[]> suffix), setting a new value
actually pushes a new one into the list.  For properties which are objects of
a specific class, passing a hashref argument automatically creates a new
object of that class with that hashref.

B<Example:>

	my $addr = new Business::cXML::Contact;

	$addr->name('John Smith');
	print $addr->name;  # Prints: John Smith

	$addr->emails('john1@');
	$addr->emails('john2@');
	print join(' ', @{ $addr->emails });  # Prints: john1@ john2@

The following properties are automatically available in all objects which
inherit from this one:

=over

=item C<B<_nodeName>>

Read-only name of the current cXML node.

=back

=cut

sub _nodeName { shift->{_nodeName} }

sub _getset {
	my ($self, $name, $val) = @_;

	return unless exists $self->{$name};
	my %obj_fields = $self->OBJ_PROPERTIES;

	if (exists($obj_fields{$name}) && ref($val) eq 'HASH') {
		my @args;
		my $class;
		if (ref($obj_fields{$name}) eq 'ARRAY') {
			@args = @{ $obj_fields{$name} };
			$class = shift(@args);
		} else {
			$class = $obj_fields{$name};
		};

		unshift(@args, $val);
		my $file = $class;
		$file =~ s|::|/|g;
		require "$file.pm";
		$val = $class->new(@args);
	};

	if (@_ > 2) {
		if (ref($self->{$name}) eq 'ARRAY') {
			push @{ $self->{$name} }, $val;
		} else {
			$self->{$name} = $val;
		};
	};

	return $self->{$name};
}

sub AUTOLOAD {
	my $self = shift;  # We need a clean @_ to be passed to _getset() later

	our $AUTOLOAD;
	my $field = $AUTOLOAD;
	$field =~ s/.*:://;
	croak "Unknown method $field" unless ref $self;

	if (exists $self->{$field}) {
		return $self->_getset($field, @_);
	} else {
		croak qq'Can\'t locate object method "$field" via package "@{[ ref $self ]}"';
	};
}
sub DESTROY { }  # Having AUTOLOAD requires us also having an explicit DESTROY.

=head1 AUTHOR

Stéphane Lavergne L<https://github.com/vphantom>

=head1 ACKNOWLEDGEMENTS

Graph X Design Inc. L<https://www.gxd.ca/> sponsored this project.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2017-2018 Stéphane Lavergne L<https://github.com/vphantom>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=cut

1;
