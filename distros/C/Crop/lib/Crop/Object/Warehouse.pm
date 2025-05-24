package Crop::Object::Warehouse;
use base qw/ Crop /;
# use base qw/ Crop::Object /;

=begin nd
Class: Crop::Object::Warehouse
	Warehouse stores objects.
	
	WH routes requests to appropriate database and returns response to a caller by
	composing the workers responses.
	
	Each table has appropriate the worker entry in the main config file.

	TODO: AUTOLOAD for all the remaining methods; then get understanding of the use of this class.
=cut

use v5.14;
use strict;

use Crop::Util qw/ load_class /;
use Crop::Error;

use Crop::Debug;

=begin nd
Variable: our $AUTOLOAD
	Name of the method call.
=cut
our $AUTOLOAD;

=begin nd
Variable: my $WH
	Class Singleton.
=cut
my $WH;

=begin nd
Constructor: new ( )
	Load workers for all the tables.

	Singleton.
	
	Defines role for warehouse.

Returns:
	$self - if ok
	undef - otherwise
=cut
sub new {
	my $class = shift;
	
	return warn "WAREHOUSE|ALERT: Constructor new() must be redefined by subclass $class" unless $class eq __PACKAGE__;
	
	return $WH if defined $WH;
	
	my $mode = $class->C->{install}{mode};
	my $role = $mode eq 'test' ? 'admin' : 'user';
	
	my %driver;
	while (my ($db, $conf) = each %{$class->C->{warehouse}{db}}) {
		my $driver_name = __PACKAGE__ . "::$conf->{driver}";
		load_class $driver_name or return warn "WAREHOUSE|ALERT: Can not access DB driver $driver_name";
		
		$driver{$db} = $driver_name->new(
			host  => $conf->{server}{host},
			port  => $conf->{server}{port},
			name  => $conf->{name},
			login => $conf->{role}{$role}{login},
			pass  => $conf->{role}{$role}{pass},
		);
	}

	my %worker;
	while (my ($table, $db) = each %{$class->C->{warehouse}{relation}}) {
		$worker{$table} = $driver{$db};
	}
	
	my $self = $WH = bless {
		worker => \%worker,
	}, $class;
}

=begin nd
Method: AUTOLOAD ($either, $obj, @data)
	Mostly, all the methods do the same work.

Param:
	$either - $self or class name of descendant of this package
	$obj    - class name of object in the warehouse
	@data   - remaining arguments
=cut
sub AUTOLOAD {
	my ($self, $obj, @data) = @_;
	my $class = ref $self;
	my ($method) = $AUTOLOAD =~ /(\w+)\z/;
# 	debug 'CROPOBJECTWAREHOUSE_AUTOLOAD_METHOD=', $method;

# 	debug 'CROPOBJECTWAREHOUSE_AUTOLOAD_PACKAGE=', __PACKAGE__;
# 	debug 'CROPOBJECTWAREHOUSE_AUTOLOAD_CLASS=', $class;
	return warn "WAREHOUSE|ALERT: method '$method' must be redefined by subclass $class" unless $class eq __PACKAGE__;

	my $table = $obj->Table;
	my $worker = $self->_worker($obj) or return warn "WAREHOUSE|ALERT: No worker exist for table '$table'";
	$worker->$method($obj, @data);
}

=begin nd
Method: all ($obj, @filter)
	Get collection of objects corresponding to the @filter.
	
Param:
	$obj    - class name of objects
	@filter - clause
=cut
sub all {
	my ($self, $obj, @filter) = @_;
	my $class = ref $self;

	return warn "WAREHOUSE|ALERT: method all() must be redefined by subclass $class" unless $class eq __PACKAGE__;

	my $table = $obj->Table;
	my $worker = $self->_worker($obj) or return warn "WAREHOUSE|ALERT: No worker exist for table '$table'";
	$worker->all($obj, @filter);
}

=begin nd
Method: create ($obj)
	Create object of general type.
	
	Call appropriate Warehouse method.
	
Parameters:
	$obj - object to create
	
Returns:
	object - if ok
	undef  - error
=cut
sub create {
	my ($self, $obj) = @_;
	my $class = ref $self;
	
	return warn "WAREHOUSE|ALERT: method create() must be redefined by subclass $class" unless $class eq __PACKAGE__;

	my $worker = $self->_worker($obj) or return warn 'WH|ALERT: Can not create object: table \'' . $obj->Table . '\' do not has worker';
	
	$self->_worker($obj)->create($obj);
	
	$obj;
}

=begin nd
Method: create_auto_id ($obj)
	Create an object of <Crop::Object::Simple> type in the warehouse.
	
Parameters:
	$obj - hash with data
	
Returns:
	id    - if ok
	undef - fail
=cut
sub create_auto_id {
	my ($self, $obj) = @_;
	my $class = ref $self;
	
	return warn "WAREHOUSE|ALERT: method create_auto_id() must be redefined by subclass $class" unless $class eq __PACKAGE__;

	my $worker = $self->_worker($obj) or return warn 'WH|ALERT: Can not create object: table \'' . $obj->Table . '\' do not has worker';
	
	my $id = $self->_worker($obj)->create_auto_id($obj);
}

=begin nd
Method: get_id ($obj)
	Get id for object.
	
Parameters:
	$obj - object that needs id
	
Returns:
	$obj
=cut
sub get_id {
	my ($self, $obj) = @_;
	
	$self->_worker($obj)->get_id($obj);
	
	$obj;
}

=begin nd
Method: global_delete ($obj_class, $clause)
	Delete entire class.
	
	Performs delete immediately.
	
Parameters:
	$obj_class - class to update
	$clause    - defines exemplars to update
	
Returns:
	true  - if ok
	false - otherwise
=cut
sub global_delete {
	my ($either, $obj_class, $clause) = @_;
	my $class = ref $either || $either;
	
	return warn "WAREHOUSE|ALERT: method global_delete() must be redefined by subclass $class" unless $class eq __PACKAGE__;
	
	$either->_worker($obj_class)->global_delete($obj_class, $clause);
}

=begin nd
Method: global_update ($obj_class, \%values, \%clause)
	Update entire class.
	
	Performs update immediately.
	
Parameters:
	$obj_class - class to update
	$values    - hash of new values for each attribute
	$clause    - defines exemplars to update
	
Returns:
	true  - if ok
	false - otherwise
=cut
sub global_update {
	my ($either, $obj_class, $values, $clause) = @_;
	my $class = ref $either || $either;
	
	return warn "WAREHOUSE|ALERT: method global_update() must be redefined by subclass $class" unless $class eq __PACKAGE__;
	
	$either->_worker($obj_class)->global_update($obj_class, $values, $clause);

	1;
}

=begin nd
Method: Refresh ($obj)
	Update exemplar in a warehouse.

Parameters:
	$obj - exemplar to update
	
Returns:
	$obj
=cut
sub refresh {
	my ($self, $obj) = @_;
	my $class = ref $self;
	
	return warn "WAREHOUSE|ALERT: method refresh() must be redefined by subclass $class" unless $class eq __PACKAGE__;
	
	$self->_worker($obj)->refresh($obj);
	
	$obj;
}

=begin nd
Method: remove ($obj)
	Delete exemplar from warehouse.
	
Parameters:
	$obj - exemplar to delete
	
Returns:
	true  - if ok
	undef - an error
=cut
sub remove {
	my ($self, $obj) = @_;
	my $class = ref $self;
	
	return warn "WAREHOUSE|ALERT: method remove() must be redefined by subclass $class" unless $class eq __PACKAGE__;
	
	$self->_worker($obj)->remove($obj);
	
	1;
}

=begin nd
Method: _worker ($table)
	Get a worker for the specified $table.
	
Parameters:
	$table - table name
	
Returns:
	driver name as a string
=cut
sub _worker {
	my ($self, $obj) = @_;
	
	$self->{worker}{$obj->Table};
}

1;
