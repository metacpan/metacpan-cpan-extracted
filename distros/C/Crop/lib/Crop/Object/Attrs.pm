package Crop::Object::Attrs;

=begin nd
Class: Crop::Object::Attrs
	Container for <Crop::Object::Attr> of class attributes declaration.
	
	OOP-class, but do not inherits to the <Crop::Object>.
	
	Attributes:
	
	attr   - Collection of <Crop::Object::Attr>
	class  - class of declaration
	extern - hash of Crop::Object::Extern::* describes link to an external object
	source - raw source of attributes declaration
=cut

use v5.14;
use warnings;
no warnings 'experimental::smartmatch';

use Crop::Debug;
use Crop::Error;
use Crop::Object::Attr;
use Crop::Object::Collection;
use Crop::Object::Constants;
use Crop::Object::Extern;

=begin nd
Constructor: new (%attr)
	Construct Collection of attributes <Crop::Object::Attr>.
	
	$attr{class} is required.
	
Parameters:
	%attr - see 'Attributes' in class description

Returns:
	$self - if all right
	undef - otherwise
=cut
sub new {
	my ($class, %in) = @_;
	
	exists $in{class} or return warn "Attrs constructor requires the 'class' argument.";
	
	my $self = bless {
		attr   => Crop::Object::Collection->new('Crop::Object::Attr'),
		class  => $in{class},
		extern => {},
		source => {},
		%in,
	}, $class;

	while (my ($name, $desc) = each %{$self->{source}}) {
		next if $name eq 'EXT';
		my $attr = Crop::Object::Attr->new(name => $name, source => $desc);
		$self->{attr}->Push($attr);
	}

	$self;
}

=begin nd
Method: extern ($name)
	Get the extern declaration for $name attribute

Parameters:
	$name - attribute name
	
Returns:
	The particular object Crop::Object::Extern::*
=cut
sub extern {
	my ($self, $name) = @_;
	my $class = ref $self;
	
	exists $self->{extern}{$name} and return $self->{extern}{$name};
	
	exists $self->{source}{EXT}        or return warn "NODECL|CRIT: EXT not is in class declaration";
	exists $self->{source}{EXT}{$name} or return warn "OBJECT|CRIT: Not EXT declaration presence for name $name";
	
	my $ext = Crop::Object::Extern->new($self->{source}{EXT}{$name}) or return warn "OBJECT|CRIT: extern declaration is not valid for $name";
	my $rc = $self->{extern}{$name} = $ext;
	
	$rc;
}

=begin nd
Method: first ($key, $val)
	Get the first <Crop::Object::Attr> that has key named $key and corresponging $val as value
	
Parameters:
	$key - name of the key
	$val - value for $key
	
Returns:
	attribute object - if found
	undef            - otherwise
=cut
sub first {
	my ($self, $key, $val) = @_;
	
	for ($self->{attr}->List) {
		return $_ if $_->has($key, $val);
	}
	
	return;
}

=begin nd
Method: have ($discipline, $name)
	Get attribute by name.

Parameters:
	$discipline - predefined constant (see <Crop::Object::Constants>)
	$name - attribute name

Returns:
	<Crop::Object::Attr> object - if found
	undef                       - if not found
=cut
sub have {
	my $self       = shift;
	my $name       = pop;
	my $discipline = shift || ANY;

	my $attribute = $self->{attr}->First(name => $name) or return;
	
	$attribute->of_type($discipline) ? $attribute : undef;
}

=begin nd
Method: List ( )
	Get the attributes (<Crop::Object::Attr>) list.

	Will call <Crop::Object::Collection::List> so calling context matters. The initial
	capital letter 'L' in the method name reminds it.

Returns:
	items arrayref - in scalar context
	items array    - in list context
	
	See <Crop::Object::Collection::List>.
=cut
sub List { shift->{attr}->List }

=begin nd
Method: source ( )
	Get declaration source.

Returns:
	Hashref of raw source of attributes declaration in form of the class declaration.
=cut
sub source { shift->{source} }

1;
