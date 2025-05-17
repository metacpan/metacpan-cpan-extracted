package Crop::Object;
use base qw/ Crop /;

=begin nd
Class: Crop::Object
	ORM.
	
	Collects class attributes including attributes of all the parent classes (multiple inheritance).
	Generates getters/setters conforming to the class declaration.

	Derived class could set up the <Extern> objects.

	Attributes:
	
	STATE - flags REMOVED, NOSYNC, DWHLINK, MODIFIED; see <Crop::Object::Constants>.
	
=cut

use strict;
use v5.14;
use experimental qw/ switch /;

use Crop::Error;
use Crop::Util;
use Crop::Object::Collection;
use Crop::Object::Constants;
use Crop::Object::Attrs;
use Crop::Object::Warehouse;

use Crop::Debug;

=begin nd
Constant: READ
	Name of the read method.

Constant: WRITE
	Name of the write method.
=cut
use constant {
	READ     => 'read',
	WRITE    => 'write',
};

=begin nd
Variable: our $AUTOLOAD
	Name of the method call.
=cut
our $AUTOLOAD;

=begin nd
Variable: my %Attr_cache
	Remember Attributes() for childs.
=cut
my %Attr_cache;

=begin nd
Variable: my %Done
	Yet processed methods; there is no need to process it again.
=cut
my %Done;

=begin nd
Variable: my $WH
	Warehouse stores objects.
=cut
my $WH = Crop::Object::Warehouse->new;

=begin nd
Constructor: new ($nosync, @attrs)
	Init exemplar.

	Determines <Crop::Object::Constants::DONT_SYNC> flag.
	
	Setup value: from either argument or default.
	
	Establish initial STATE.
	
Parameters:
	$nosync - either exemplar will be syncronized to a warehouse; optional
	@attrs  - hash of attribute=>value packed to an array

Returns:
	$self
=cut
sub new {
	my $either = shift;
	my $class = ref $either || $either;
	
	my $nosync;
	$nosync = shift if @_ and defined $_[0] and $_[0] eq DONT_SYNC;

	my @in;
	while (my ($i, $val) = each @_) {
		# only a key could be dereferenced; value can be an object of the same class, i.e. in linked list
		push @in, !($i % 2) && ref $val && ref $val eq $class ? %$val : $val;
	}
	my $in = expose_hashes \@in;

	my $self = bless {}, $class;

	for ($self->Attributes->List) {
		my $name = $_->name;
		$self->{$name} = exists $in->{$name} ? $in->{$name} : $_->default;
	}
	$self->{STATE}  = OBJINIT;
	$self->{STATE} |= NOSYNC if $nosync;

	$self;
}

=begin nd
Method: __Access_r ($attr)
	Read-access for attribute.

Parameters:
	$attr - <Crop::Object::Attr> object

Returns:
	Method reference.
=cut
sub __Access_r {
	my ($self, $attr) = @_;

	sub {
		my $self = shift;

		my $attr_name = $attr->name;
		return warn "OBJECT|ERR: Write access for $attr_name denied by rules" if @_;

		return $self->{$attr->name};
	};
}

=begin nd
Method: __Access_rw ($attr)
	Read-write-access for attibute.

Parameters:
	$attr - <Crop::Object::Attr> object

Returns:
	Method reference.
=cut
sub __Access_rw {
	my ($self, $attr) = @_;

	sub {
		my $self = shift;

		if (@_) {
			$self->{$attr->name} = shift;
			$self->{STATE} |= MODIFIED if $self->{STATE} & DWHLINK and $attr->of_type(STORED);

			return $self;
		}

		$self->{$attr->name};
	};
}

=begin nd
Method: __Access_no ($attr)
	Access to an attribute without any accessor.

	An error 'OBJECT|ALERT' will be arised.

Parameters:
	$attr - <Crop::Object::Attr> object

Returns:
	Method reference.
=cut
sub __Access_no {
	my (undef, $attr) = @_;

	sub {
		return warn @_ > 1 ?
			  'OBJECT|ALERT: Write access for ' . $attr->name . ' denied by rules'
			: 'OBJECT|ALERT: Read  access for ' . $attr->name . ' denied by rules';
	};
}

=begin nd
Method: __Access_w ($attr)
	Write-accessor for an attibute.

Parameters:
	$attr - <Crop::Object::Attr> object

Returns:
	Method reference.
=cut
sub __Access_w {
	my ($self, $attr) = @_;

	sub {
		my $self = shift;

		return warn 'OBJECT|ERR: Read access for \'' . $attr->name . '\' denied by rules' unless @_;

		$self->{$attr->name} = shift;
		$self->{STATE} |= MODIFIED if $self->{STATE} & DWHLINK and $attr->of_type(STORED);

		$self;
	};
}

=begin nd
Method: All (@filter)
	Get a <Crop::Object::Collection> of objects from warehouse.
	
	(start code)
	Class->All;  # Get the Collection of all the exemplars
	Class->All(attr1=>val1, attr_2=>val2);  # Get the exemplars restricted by their attribute values
	Class->All(attr1=>val, SORT=>'attr2');   # With the 'order by' clause
	
	With 'extended' exemplars
	Class->All(attr1=>val, EXT=>[ext1, ext2 => [ext3]]);
	Class->All(attr1=>val,
		SORT=> 'ext3.attr1',  # works fine while 'ext3.attr1' matches real tablename.attrname
		EXT=>[ext1, ext2 => [ext3]]
	);
	
	# extended with filter in inner objects
	Class->All(EXT=>[doc => {visible => 1} => ['file'], qw/ picture units /]);
	(end code)
	
	The following features are not yet implemented!
	
	In addition to filter, an argument could be a SLICEN or SORT expression
	(start code)
	My::Class->All(SLICEN => [20, 30]);
	# produces:
	SELECT * from class_table OFFSET 30 LIMIT 20 ORDER BY id;
	-- by default SLICEN does sort by primary keys
	
	My::Class->All(SLICEN => [20, 30], SORT => ['ctime DESC']);
	My::Class->All(SLICEN => [20, 30], SORT => 'ctime DESC'); -- is equivalent
	SELECT * from class_table OFFSET 30 LIMIT 20 ORDER BY ctime DESC; -- explicit sort
	
	My::Class->All(SORT => ['ctime DESC']);
	SELECT * from class_table ORDER BY ctime; -- sort without slice
	(end code)

Parameters:
	@filter - attr=>val pairs, {attr=>val} hashref, SORT=>[expression, ...],
	SORT=>'expression', SLICEN=>[limit, offset], LIMIT=>limit,
	EXT=>[obj, ...]

Returns:
	Collection of exemplars
=cut
sub All {
	my ($either, @filter) = @_;
	my $class = ref $either || $either;
	
	my $in = expose_hashes \@filter;
	exists $in->{$_} and not ref $in->{$_} and $in->{$_} = [$in->{$_}] for qw/ EXT SORT /;

	$WH->all($class, %$in)->Set_state(DWHLINK);
}

=begin nd
Method: Attributes ($mode)
	Get the class attributes corresponding to the $mode.
	
	If no $mode has specified, all the attibutes will return.
	
	Fetch all the attributes including (multi) inherited ones.
	
Parameters:
	$mode - fetch attibutes with according to $mode; optional; (ANY,CACHED,STORED,KEY)

Returns:
	arrayref                         - if $mode is defined
	Attributes <Crop::Object::Attrs> - otherwise
=cut
sub Attributes {
	my ($either, $mode) = @_;
	my $class = ref $either || $either;

	return $class->_attrs($mode) if $mode;
	
	return Crop::Object::Attrs->new(class => $class) if $class eq __PACKAGE__;
	return $Attr_cache{$class} if exists $Attr_cache{$class};
	
	my ($isa, $class_attr);
	{
		no strict;

		$isa        = \@{$class . '::ISA'};
		$class_attr = \%{$class . '::Attributes'};
	}

	my %source;
	for my $parent_class (@$isa) {
		next unless $parent_class->can('Attributes');
	
		my $parent_attr = $parent_class->Attributes;
		%source = (%source, %{$parent_attr->source});
	}
	%source = (%source, %$class_attr);

	my $Attributes  = Crop::Object::Attrs->new(source => \%source, class => $class);
	
	$Attr_cache{$class} = $Attributes;
}

=begin nd
Method: _attrs($mode)
	Get all the object attributes declaration according to the $mode.
	
Parameters:
	@mode - mode such a 'CACHED', 'STORED'; See <Crop::Object::Constants>
	
Returns:
	array of <Crop::Object::Attr>
=cut
sub _attrs {
	my ($class, $mode) = @_;
	
	[
		grep $_->of_type($mode), $class->Attributes->List
	];
}

=begin nd
Method: AUTOLOAD ($AUTOLOAD)
	Generate accessors for class attributes.

	Class declaration specifies a mode - {mode => 'read'}, 'write', or 'read/write'.

	Call of inappropriate accessor arise an error.

	An accessor will be build only once. Next call will get it from the cache.

Parameters:
	$AUTOLOAD - method name; See Perl-package 'UNIVERAL'
=cut
sub AUTOLOAD {
	my $self = shift;

	my $method = $self->_get_method_name($AUTOLOAD);
# 	debug "ACCESS_ATTR='$method'";

	return warn "OBJECT|ERR: Can't AUTOLOAD method $method oF class $self without the exemplar." unless ref $self;
	return if $method eq 'DESTROY';
	return warn "OBJECT|ERR: Method AUTOLOAD: $AUTOLOAD in loop" if $Done{$AUTOLOAD};

	return sub { undef } if $method eq 'Table';

	my $Attributes = $self->Attributes;

	my $accessor;
	my $attr = $Attributes->have($method);

	if ($attr) {
		$accessor =
			  $attr->accessible(READ) && $attr->accessible(WRITE) ? '__Access_rw'
			: $attr->accessible(READ)                             ? '__Access_r'
			: $attr->accessible(WRITE)                            ? '__Access_w'
			:                                                       '__Access_no'
		;
	} else {
		return warn "OBJECT|ERR: Either Object hasn't attribute or method $AUTOLOAD";
	}

	{
		no strict 'refs';
		*{$AUTOLOAD} = $self->$accessor($attr);
	}

	$Done{$AUTOLOAD}++;
	$self->$method(@_);
}

=begin nd
Method: _Create ( )
	Create a new object.
	
	Put an object to the Warehouse.
	
	A subclass could redefine this method with specific behavior.
	
Returns:
	$self - if ok
	undef - otherwise
=cut
sub _Create {
	my $self = shift;

	$WH->create($self);
}

=begin nd
Method: DESTROY ( )
	Sync an exemplar with warehouse.
	
	Do not perform save of object when:
	
	- no table specified for the class
	- exemplar was removed from warehouse
	- exemplar has a special 'Dont sync' flag
	- exemplar was not modified
=cut
sub DESTROY {
	my $self = shift;

	return unless $self->Table;
	return if $self->{STATE} & REMOVED;
	return if $self->{STATE} & NOSYNC;
	return if $self->{STATE} & DWHLINK and not $self->{STATE} & MODIFIED;

	$self->Save;
}

=begin nd
Method Erase ( )
	Cleanup all non-stable attributes of an object.
=cut
sub Erase {
	my $self = shift;

	for ($self->Attributes->List) {
		next if $_->is_stable;

		if ($_->has_default) {
			$self->{$_->name} = $_->default;
		} else {
			undef $self->{$_->name};
		}
	}
}

=begin nd
Method: Genkey ( )
	Generate Primary key.
	
	This method must be redefined by subclass, it is pure virtual.
	
	Produces error.
	
Returns:
	undef
=cut
sub Genkey {
	my $self = shift;
	my $class = ref $self;

	return warn "OBJECT|ALERT: Genkey method must be redefined by subclass '$class'";
}

=begin nd
Method: Get (@filter)
	Get an exemplar from warehouse.
	
	(start code)
	Class->All(EXT=>[doc => {visible => 1} => ['file'], qw/ picture units /]);
	(end code)
	
	See <All(@filter)>.
Parameters:
	@filter - clause, exemplar must satisfy to
	
Returns:
	an exemplar - if ok
	false       - if an error has acquired
=cut
sub Get {
	my $either = shift;
	my $class = ref $either || $either;
	
	my $collection = $either->All(@_);

	return unless $collection->Size;
	return warn "OBJECT: Multiple exemplars for Get() method found for $class class" if $collection->Size > 1;

	my $self = $collection->First;

	$self->{STATE} |= DWHLINK;
	
	$self;
}

=begin nd
Method: _get_method_name ($full_name)
	Get method name stripping package name.

Parameters:
	$full_name - method name with the package name as a prefix

Returns:
	String, method name only.
=cut
sub _get_method_name {
	my ($self, $full_name) = @_;
	$full_name =~ /.*::(\w+)/;

	$1;
}

=begin nd
Method: Global ($action, %values, $clause)
	Perform changes on an entire class.
	
	Performs action immediately.
	
Param:
	$action - 'UPDATE', 'SAFE_UPDATE', and 'DELETE':
		- UPDATE      update with no paying attantion to the warehouse constraints
		- SAFE_UPDATE update with care to wh constrains
		- DELETE      delete exemplars

	%values - hash packed on the list where each pair consists attr=>value; for UPDATE only
	$clause - hashref defines elements of class that will change; {attr1=>{gt=>25},...}
	
Returns:
	true  - if ok
	false - otherwise
=cut
sub Global {
	my ($either, $action) = splice @_, 0, 2;
	my $class = ref $either || $either;
	
	my $clause;
	$clause = pop if @_ % 2;

	my @val = @_;
	
	given ($action) {
		when ('UPDATE') {
			my %values = @_ or return;
			
			$WH->global_update($class, \%values, $clause);
		}
		when ('SAFE_UPDATE') {
			my $val = @val == 1 ? shift @val : {@val};
			debug 'CROPOBJECT_GLOBAL_CLASS=', $class;
			debug 'CROPOBJECT_GLOBAL_VAL=', $val;
			debug 'CROPOBJECT_GLOBAL_CLAUSE=', $clause;

			$WH->global_safe_update($class, $val, $clause)
		}
		when ('DELETE') { $WH->global_delete($class, $clause) }
		
		default { return warn "OBJECT|CRIT: No such action '$action' for global operation" }
	}
}

=begin nd
Method: Increase (@val, @clause)
	Safely update all the exemplars in a class.

	Use it where warehouse constrains broke consistency correctness of intermediate operations.

	Action is performed immediately.

	>lkey => +2, rkey => +2, {lkey => {GE => $self->{rkey}},
Param:
	@val    - attr1=>val1,attr2=>val2 ... pairs to be step-by-step updated
	@clause - select clauses, each packed in a hashref

Returns:
	true  - ok
	false - error
=cut
sub Increase {
	my $either = shift;
	my $class = ref $either || $either;

	$WH->increase($class, @_);
}

=begin nd
Method: _Is_key_defined ( )
	If an exemplar has a key attibutes fully defined.
	
	This method can be redefined by multi-ancestors, so the 'generate-cache-call' pattern is ommited.

Returns:
	true  - is defined
	false - otherwise
=cut
sub _Is_key_defined {
	my $self = shift;
	my $class = ref $self;

	my $keys = $self->Attributes(KEY);
	return warn "OBJECT|CRIT: No keys found for class $class" unless @$keys;
	
	defined $self->{$_->name} or return for @$keys;
	
	1;
}

=begin nd
Method: Max ($attr)
	Get maximum of $attr value in all the class.

	Method of class either method of exemplar.
Param:
	$attr - attribute name

Returns:
	Maximum value of $attr across all the class exemplars.
=cut
sub Max {
	my ($either, $attr) = @_;
	my $class = ref $either || $either;
# 	debug 'CROPOBJECT_MAX_ATTR=', $attr;

	$WH->max($class, $attr);
}

=begin nd
Method: Modified ($modify)
	Set or unset the 'MODIFIED' flag.

Parameters:
	$state - if defined and if is FALSE than unset flag; optional

Returns:
	$self
=cut
sub Modified {
	my ($self, $modify) = @_;
	$modify //= 1;

	 $modify ? $self->Set_state(MODIFIED) : $self->Remove_state(MODIFIED);

	$self;
}

=begin nd
Method: Nosync ( )
	Mark an object as unsynced.
=cut
sub Nosync {
	my $self = shift;
	
	$self->Set_state(NOSYNC);
}

=begin
Method: _Prepare_key ( )
	Try to prepare the key for insert.

	Pure virtual.
	
	Arise an error.

Returns:
	false
=cut
sub _Prepare_key {
	my $self = shift;
	my $class = ref $self;

	return warn "OBJECT: _Prepare_key method must be redefined by subclass $class";
}

=begin nd
Method: Remove ( )
	Delete exemplar from the warehouse immediately.
	
Returns:
	undef
=cut
sub Remove {
	my $self = shift;
	my $class = ref $self;

	return warn "OBJECT|ERR: Can't remove object with no Table specified in class $class" unless $self->Table;
	
	$WH->remove($self);
	$self->{STATE} |= REMOVED;

	undef $self;
}

=begin nd
Method: Remove_State ($flags)
	Remove $flags from STATE.

Parameters:
	$flags - the 'OR'ed flags to remove

Returns:
	$self
=cut
sub Remove_State {
	my ($self, $flags) = @_;

	$self->{STATE} &= ~$flags;

	$self;
}

=begin nd
Method: Save ( )
	Save current exemplar state to the warehouse.
	
	In case of multi-ancestors the preparation walks through all the extra parents first.

Returns:
	$self - if saved successfully
	undef - otherwise
=cut
sub Save {
	my $self = shift;
	my $class = ref $self;
	
	return warn "OBJECT|ERR: Can't Save object with no TABLE specified for class $class" unless defined $self->Table;
	
	if ($self->{STATE} & DWHLINK) {  # object is in the Warehouse
		return $self unless $self->{STATE} & MODIFIED;  # object corresponds to the state in the Warehouse
		$WH->refresh($self);
	} else {                         # object is missing in the Warehouse
		my $isa;
		{
			no strict 'refs';
			$isa = \@{$class . '::ISA'};
		}
		my @isa_original = @$isa;
		
		my $err;
		if (my $extra_parent = @isa_original - 1) {
			while ($extra_parent--) {
				my $parent = pop @$isa;
				unshift @$isa, $parent;
				
				$self->_Is_key_defined or $self->_Prepare_key or ++$err, last;  # once @ISA has been modified, return not allowed
			}
			@$isa = @isa_original;
			
			return warn "OBJECT|ERR: Can't Generate Primary key either required attributes for class $class" if $err;
		}

		$self->_Is_key_defined or $self->_Prepare_key or return warn "OBJECT|ERR: Can't Generate Primary key either required attributes for class $class";
		$self->_Create;
	}
	$self->{STATE} |= DWHLINK;
	$self->{STATE} &= ~MODIFIED;

	$self;
}

=begin nd
Method: Set_state ($flags)
	Set up STATE-$flags.

Parameters:
	$flags - binary mask to be ORed

Returns:
	$self
=cut
sub Set_state {
	my ($self, $flags) = @_;

	$self->{STATE} |= $flags;

	$self;
}

=begin nd
Method: Table ( )
	Return false for Objects that should not be saved to Warehouse.

Returns:
	false
=cut
sub Table {  }

=begin nd
Method: TO_JSON ($data)
	Prepare blessed objects for JSON output.

	All the objects are a blessed hashrefs, so will return UNblessed original hashref.

	Removes the 'STATE' container from result.

	This metod is called automatically by JSON module for each object.

Parameters:
	$data - blessed hashref

Returns:
	unblessed hashref
=cut
sub TO_JSON {
	my $data = shift;

	my $json =  {%$data};
	delete $json->{STATE};

	$json;
}

=begin nd
Method: WH ( )
	Get WareHouse object.
	
	User do not should use this method directly at top-level code.
	
Returns:
	Warehouse object <Crop::Object::Warehouse>
=cut
sub WH { $WH }

1;
