package Crop::Object::Attr;
use base qw/ Crop /;

=begin nd
Class: Crop::Object::Attr
	Certain attribute of an Object.
	
	This module not inherit <Crop::Object>, so automatic generation of getters/setters missed.
	
	<my %Attibutes> are default values each item has.
=cut

use v5.14;
use warnings;
no warnings 'experimental::smartmatch';

use Clone qw/ clone /;

use Crop::Debug;
use Crop::Error;
use Crop::Object::Constants;
use Crop::Object::Key;

=begin nd
Constants: Groupping attribute types by store semantics.

Constant: ATTR_STORED
	Attribute has to be stored in warehouse.

Constant: ATTR_CACHED
	Attribute is not storable in warehouse.

Constant: ATTR_KEY
	Attribute is a Key in a warehouse terms.
=cut
use constant {
	ATTR_STORED => [qw/ store key /],
	ATTR_CACHED => [qw/ cache     /],
	ATTR_KEY    => [qw/ key       /],
};

=begin nd
Constant: DEFAULT_TYPE
	Any attribute has type; this is default
=cut
use constant {
	DEFAULT_TYPE => 'store',
};

=begin nd
Variable: my %Attributes
	Attributes:

	default	- default value of the object
	extern  - declaration of relation to other object
	key     - <Crop::Object::Key> object if attribute is a key
	mode   	- access mode (read, write, read/write)
	name	- attribute name
	stable 	- each class defines their own semantics of this attribute
	source 	- raw source of declaration
	type   	- defines either attribute is storable in warehouse ('store', 'cache', 'key')
=cut
my %Attributes = (
	default => undef,
	extern  => undef,
	key     => undef,
	mode    => undef,
	name	=> {mode => 'read'},
	stable  => undef,
	source  => undef,
	type    => DEFAULT_TYPE,
);

=begin nd
Variable: my @Required
	All madatory constructor arguments.

Variable: my @Passthrough
	All optional constructor arguments.
=cut
my @Required = qw/ name source /;
my @Passthrough = qw/ default mode stable type /;

=begin nd
Constructor: new (%in)
	Set the name and parse the declaration.

	Check mandatory arguments, return erros if missed.

Parameters:
	%in - hash of attributes and their values

Returns:
	$self - if all right
	undef - otherwise
=cut
sub new {
	my ($class, %in) = @_;

	my $self = bless {%Attributes}, $class;
	
	# set mandatory attributes
	exists $in{$_} ? $self->{$_} = $in{$_} : return warn "Attr haven't required field: $_" for @Required;

	# set optional attributes from %in{source}
	exists $in{source}->{$_} and $self->{$_} = $in{source}->{$_} for @Passthrough;

	# define either type is 'key'
	if (exists $in{source}->{key}) {
		$self->{type} = 'key';
		$self->{key} = Crop::Object::Key->new(type => $in{source}->{key});
	}

	if (exists $in{source}->{extern}) {
		debug __PACKAGE__ . '::new()_EXTERN=', $in{source}->{extern};
		return warn 'Crop::Object::Attr->new NOT IMPLEMENTED';
# 		$self->{extern} = Crop::Object::Attr::Extern->new(
# 			attr => $self,
# 			source => $in{source}->{extern},
# 		);
	}

	$self;
}

=begin nd
Method: accessible ($mode)
	Check either attribute has the accessor.

Returns:
	true  - if attr has accessible
	false - oterwise
=cut
sub accessible {
	my ($self, $mode) = @_;

	defined $self->{mode} and $self->{mode} =~ $mode;
}

=begin nd
Method: default ( )
	Get the declared default value.

Returns:
	Copy of default value. This is what you need.
=cut
sub default {
	my $self = shift;

	ref $self->{default} ? clone $self->{default} : $self->{default};
}

=begin nd
Method: has ($key, $val)
	Is attribute has $key with corresponding $val?
	
	Method of a class.
	
Parameters:
	$key - name of the key
	$val - value of the $key
	
Returns:
	true  - if has
	false - if not
=cut
sub has {
	my ($class, $key, $val) = @_;
	
	exists $class->{source} and exists $class->{source}{$key} and $class->{source}{$key} eq $val;
}

=begin nd
Method: has_default ( )
	Is attribute has default value?

Returns:
	true  - if it has
	false - otherwise
=cut
sub has_default { defined shift->{default} }

=begin nd
Method: is_stable ( )
	Is attribute stable?

	Each class defines semantics of this flag separately.

Returns:
	true  - if stable
	false - if not stable
=cut
sub is_stable { shift->{stable} }

=begin nd
Method: key ( )
	Getter.
}
=cut
sub key { shift->{key} }

=begin nd
Method: name ( )
	Get the attribute name.

Returns:
	name as string
=cut
sub name { shift->{name} }

=begin nd
Method: of_type ($type)
	Is attribute type equal to the $type specified?
	
	$type has not mapping to the 'type' attribute, but abstract discipline specified by <Crop::Object::Constants>:
	
	- STORED
	- CACHED
	- ANY
	
Parameters:
	$type - type to check; STORED, CACHED, ANY, specified by <Crop::Object::Constants>
	
Returns:
	true  - if correspondes
	false - otherwise
=cut
sub of_type {
	my ($self, $type) = @_;
	
	given ($type) {
		when (STORED) { $self->{type} ~~ ATTR_STORED }
		when (CACHED) { $self->{type} ~~ ATTR_CACHED }
		when (KEY)    { $self->{type} ~~ ATTR_KEY    }
		when (ANY)    { defined $self->{type} }
		
		default { warn "OBJECT|ALERT: Unknown Attribute discipline '$type'" }
	}
}

=begin nd
Method: Set_state ( )
	Do nothing.
	
	Attr is not a <Crop::Object> subclass, so has to redefine this method.
=cut
sub Set_state { }

1;
