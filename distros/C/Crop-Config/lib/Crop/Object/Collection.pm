package Crop::Object::Collection;
use base qw/ Crop /;

=begin nd
Class: Crop::Object::Collection
	Container contains objects of the same class.

	All items of a Collection have the same state flags, so you need to use special methods
	<Set_State ($flags )> and <Remove_State ($flags)> to change it.

	Common use of a Collection is <Crop::Object::All (@filter)>
	
	This module do not inherits <Crop::Object>.
	
	Attributes:

	elements - items
	class    - class name of items; has getter <Class>
	simple   - an array contains id for <Crop:::Object::Simple> descendents
	state    - has the same semantics as an object <Crop::Object>; inits by <Crop::Object::Constants::OBJINIT>
=cut

use v5.14;
use warnings;

use Scalar::Util qw/ blessed /;

use Crop::Error;
use Crop::Util qw/ expose_hashes load_class /;
use Crop::Object::Constants;

use Crop::Debug;

=begin nd
Constructor: new ($bless, $obj)
	Create a new collection of class $bless based on $obj data.

Parameters:
	$bless - items class name
	$obj   - hashes that contain source data for each item-object; optional

Returns:
	Collection - on success; empty Collection if $obj missed
	undef      - error
=cut
sub new {
	my ($class, $bless, $obj) = @_;
	$obj = [] unless defined $obj;
	
	load_class($bless) or return warn "OBJECT|CRIT: Collection cannot load class $bless";

	my $is_simple = $bless->isa('Crop::Object::Simple');

	my (@id, @element);
	for (@$obj) {
		my $item = ref eq $bless ? $_ : $bless->new($_);

		push @element, $item;
		push @id, $_->{id} if $is_simple;
	}

	my $self = bless {
		class    => $bless,
		elements => \@element,
		state    => OBJINIT,
	}, $class;

	$self->{simple} = [] if $is_simple;
	$self->{simple} = \@id if @id;

	$self;
}

=begin nd
Method: Class ( )
	Get the class name of a Collection.
	
Returns:
	string - class name
=cut
sub Class { shift->{class} }

=begin nd
Method: Cleanup ( )
	Remove all the items from Collection.
	
	Still alive items in the warehouse.
Returns:
	$self
=cut
sub Cleanup {
	my $self = shift;
	
	$self->{elements} = [];
	$self->{simple}   = [] if exists $self->{simple};
	
	$self;
}

=begin nd
Method: Find (@filter)
	Find all the elements of Collection that satisfy the @filter.
	
	Despite lookup uses string searching, number attributes are processed fine,
	when the 'eq' operator correctly compares digit.

Parameters:
	@filter - items in key position are names of class attributes and values are values for lookup;
	          will be exposed

Returns:
	Arrayref of items where indexes are in ascending order - if items was found
	Empty arrayref                                         - if no items found
=cut
sub Find {
	my ($self, @filter) = @_;
	my $filter = expose_hashes \@filter;

	my @found;
	ITEM:
	while (my ($i, $item) = each @{$self->{elements}}) {
		exists
					$item->{$_}
				and
					defined $item->{$_}
				and
					$item->{$_} eq $filter->{$_}
			or next ITEM for keys %$filter;
		
		push @found, $i;
	}

	\@found;
}

=begin nd
Method: First (@filter)
	Get a first element of a Collection that satisfy @filter.
	
	If no @filter specified, this method will return an item with index 0.
	No checks for range will performed in this case.

Parameters:
	@filter - hash were keys are names of class attributes and values are values for lookup
	
	Example:
	> my $obj = $collection->Fist(id => 25, color => 'red', {smoke = 'yes'});

	Hashrefs in key positions will be exposed for @filter.

Returns:
	an object - if found
	undef     - otherwise
=cut
sub First {
	my ($self, @filter) = @_;
	
	return $self->{elements}[0] unless @filter;

	my $i = shift @{$self->Find(@filter)};

	# $i can has legal non-true value, either 0 or empty string
	defined $i or return undef;

	$self->{elements}[$i];
}

=begin nd
Method: Get ($ix)
	Get element by index.

Parameters:
	$ix - index

Returns:
	item  - if ok
	undef - out of range
=cut
sub Get {
	my ($self, $ix) = @_;

	$self->{elements}[$ix];
}

=begin nd
Method: Hash ($key, $ix, $attr)
	Get hash of items grouped to arrayrefs by $key.

	Special case is where no $key is specified and Colllection is a child of <Crop::Object::Simple>. Than,
	'id' key will be used implicitly and method will return a hash with values in form of hashref instead
	of arrayref.
	If an 'id' key speicfied, method works as always.
	
	> $collection->Hash('attr');  # result = {a1=>[], a2=>[]}
	> $collection->Hash();        # result = {a1=>{}, a2=>{}}
	
	The result of first call with the same key is stored in $self->{hash}{$key}. Next call will use this cache.
	
	The $ix optional argument causes the resulting values to be a single object fetched from arrayref at $ix position.
	
	If the call contains both, $ix and $attr, so result will be {one => $val} where $val is a value of attribute ($attr).
	Use of $attr without $ix defined, is not yet implemented.

Parameters:
	$key  - attribute name; values of the $key produce keys of resulting hash; if missed, 'id' assumed
	$ix   - optional; position (starting from 0) of the target object in arrayref to be returned
	$attr - attribute name that value go to be the value of resultin hash.

Returns:
	hash of arrays, where keys are values of $key specified and values are arrays of items
	> Hash(attr1)
	{
		one => [{attr1=>'one', attr2=>val00,...}, {attr1=>'one', attr2=>val01, ...}, ...],
		two => [{attr1=>'two', attr2=>val10,...}, {attr1=>'two', attr2=>val11, ...}, ...],
		...,
	}
	hash of hash, where keys are the values of $key specified and values are hash of item at index $ix
	> Hash(attr1, 0)
	{
		one => {attr1=>'one', attr2=>val00,...},
		two => {attr1=>'two', attr2=>val10,...},
	}
	hash of value, where keys are the values of $key specified and values are value of $attr at index $ix (0)
	> Hash(attr1, 0, attr2)
	{
		one => val00,
		two => val10,
	}
	hash of value, where keys are the values of $key specified and values are value of $attr at index $ix (1)
	> Hash(attr1, 1, attr2)
	{
		one => val01,
		two => val11,
	}
=cut
sub Hash {
	my ($self, $key, $ix, $attr) = @_;

	my $is_flat;  # would the values retrned directly without arrayref?
	unless ($key) {
		return warn "OBJECT|ALERT: Can't build 'hash-of-exemplar' for Collection of non-simple class: $self->{class}" unless exists $self->{simple};
		$key = 'id';
		$is_flat = 1;
	}

	return $self->{hash}{$key} if exists $self->{hash}{$key};

	my %hash;
	if ($is_flat) {
		%hash = map +($_->{id} => $_), @{$self->{elements}};
	} else {
		for (@{$self->{elements}}) {
			next unless defined $_->{$key};
			push @{$hash{$_->{$key}}}, $_;
		}
	}

	if (defined $ix) {
		while (my ($k, $v) = each %hash) {
			$hash{$k} = defined $attr ?
				  $v->[$ix]->{$attr}
				: $v->[$ix];
		}
	}

	$self->{hash}{$key} = \%hash unless defined $ix;  # cache turn off
	
	\%hash;
}

=begin nd
Method: Is_empty
	Is a Collection empty?

Returns:
	true  - Collection is empty
	false - Collection has at least one element
=cut
sub Is_empty { not @{+shift->{elements}} }

=begin nd
Method: Last ( )
	Get the last item of a Collection.
	
Returns:
	An item - if the Collection is not empty
	undef   - otherwise
=cut
sub Last {
	my $self = shift;
	
	@{$self->{elements}} ? $self->{elements}[-1] : undef;
}

=begin nd
Method: List ($id_marker)
	Get items list.

Parameters:
	$id_marker - 'id' string specifies that only ids requested for <Crop::Object::Simple> descendent; optional

Returns:
	items arrayref - in scalar context
	items array    - in list context (for convenient)

	If $id_marker is 'id', the method returns ids only.

Example:
> my $collection = My::Module->All(arg1=>val)->List;
> for ($collection->List) {...}
=cut
sub List {
	my ($self, $id) = @_;

	return wantarray ? @{$self->{simple}} : $self->{simple} if $self->{class}->isa('Crop::Object::Simple') and $id and $id eq 'id';

	wantarray ? @{$self->{elements}} : $self->{elements};
}

=begin nd
Method: Map (@map)
	Compose the array of unblessed hashes based on the original items.
	
	If @map is empty, will return the elements as-is.
	
(start code)
$collection->Map(
	qw/ a1, a2, a3 /,  # as is
	{outVar => a4},    # a4 goes to outVar
	{calcVar => sub {          # calculate on each item of a Collection
		my $item = shift;
		$item + 2;
	}},
);
(end code)

Parameters:
	@map - rules of tranformation for each resulting item
	
	       Single string means no tranformation required, an attribute transpasses to the result as is.

	       Hashref means the value of an item presents tranformation rule. The string with dot performs
	       an access to the nested object(s). And subref will be executed with the entire item as a single argument.

Returns:
	arrayref of unblessed hashes - in a scalar context
	array of unblessed hashed    - in list context
=cut
sub Map {
	my ($self, @map) = @_;
	
	return $self->{elements} unless @map;

	my %output;
	for (@map) {
		if (ref eq 'HASH') {
			my $cur = \%output;
		
			while (my ($dst, $src) = each %$_) {
				my @dst = split /\./, $dst;
				while (my ($i, $name) = each @dst) {
					if ($i < @dst - 1) {                      # not last
						$cur = $cur->{$name}{inner} = {};
					} else {                                  # last
						$cur->{$name}{src} = $src;
					}
				}
			}
		} else {
			$output{$_}{src} = $_;
		}
	}
	
	my $res = $self->_map_out(\%output);

	wantarray ? @$res : $res;
}

=begin nd
Method: _map_out ($output)
	Transform collection based on specified rules.

	For recursive use.
	
Parameters:
	$output - hashref of rules
	
Returns:
	arrayref of unblessed objects
=cut
sub _map_out {
	my ($self, $output) = @_;
	
	my @result;
	for my $item (@{$self->{elements}}) {
		push @result, { map {
			if (exists $output->{$_} and exists $output->{$_}{inner}) {
				$_ => $item->{$_}->_map_out($output->{$_}{inner});
			} else {
				my $src = $output->{$_}{src};
				
				if (ref $src and ref $src eq 'CODE') {
					$_ => $src->($item);
				} elsif ($src =~ /\./) {
					my @chain = split '\.', $src;
					my $cur = $item;
					while (my $accessor = shift @chain) {
						$cur = $cur->{$accessor};
					}
				
					$_ => $cur;
				} elsif (not defined $item->{$src}) {
					$_ => undef;
				} elsif (ref $item->{$src} and $item->{$src}->isa('Crop::Object::Collection')) {
						$_ => scalar $item->{$src}->List;
				} else {
					$_ => $item->{$src};
				}
			}

		} keys %$output};
	}
	
	\@result;
}

=begin nd
Method: Push ($src)
	Insert new item(s) to the end of a Collection.

	Items get the same flags as the Collection has.

Parameters:
	$src - item or arrayref of items; item is a hashref

Returns:
	$self
=cut
sub Push {
	my ($self, $src) = @_;
	my @add = ref $src eq 'ARRAY' ? @$src : $src;

	for (@add) {
		my $item;
		if (blessed $_ and $_->isa($self->{class})) {
			$item = $_;
		} else {
			$item = $self->{class}->new($_);
		}
		
		$item->Set_state($self->{state});

		push @{$self->{elements}}, $item;
		push @{$self->{simple}}, $item->{id} if exists $self->{simple};
	}

	$self;
}

=begin nd
Method: Save ( )
	Save all the elements to the warehouse.

	Actual version stores elements in 'one-by-one' fashion.

Returns:
	$self
=cut
sub Save {
	my $self = shift;
	
	return warn 'OBJECT|CRIT: Collection::Save() is only implemented for pure(0) state' if $self->{state};
	
	my $id;
	for (@{$self->{elements}}) {
		$_->Save;
		if ($self->{simple}) {
			push @$id, $_->id;
		}
	}
	$self->{simple} = $id if $id;
	
	$self->{state} |= DWHLINK;
	
	$self;
}

=begin nd
Method: Set_state ($flags)
	Set up flags for Collection and all their itmes.

Parameters:
	$flags - See <Crop::Object::Constants>

Returns:
	$self
=cut
sub Set_state {
	my ($self, $flags) = @_;

	$self->{state} |= $flags;

	$_->Set_state($flags) for @{$self->{elements}};

	$self;
}

=begin nd
Method: Size ( )
	Get items number.

Returns:
	integer
=cut
sub Size { int @{+shift->{elements}} }

1;
