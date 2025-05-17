package Crop::Object::Warehouse::Pg;
use base qw/ Crop::Object::Warehouse /;

=begin nd
Class: Crop::Object::Warehouse::Pg
	General Postgres driver.

	Attribute 'dbi' keeps a connection to db.
=cut

use v5.14;
use warnings;
no warnings 'experimental::smartmatch';

use Crop::Error;
use Crop::Util;
use Crop::Object::Warehouse::Agent::DBI;
use Crop::Object::Constants;
use Crop::Object::Warehouse::Lang::SQL::Query::Select;
use Crop::Object::Warehouse::Lang::SQL::Query::Insert;
use Crop::Object::Warehouse::Lang::SQL::Query::Delete;
use Crop::Object::Warehouse::Lang::SQL::Query::Update;

use Crop::Debug;

=begin nd
Constant: KEYWORDS
	Key words for build query to a database.
=cut
use constant { KEYWORDS => [qw/ EXT LIMIT LOCK OFFSET ORDER SLICEN SORT /] };

=begin nd
Constructor: new ($conn)
	Establish connection to a specified database.
	
Parameters:
	$conn - credentials for database connection (login, pass, etc.)
	
Returns:
	$self - if OK
	undef - if connection to database fails
=cut
sub new {
	my ($class, @conn) = @_;
	
	my $self = bless {
		dbi => undef,
	}, $class;

	$self->{dbi} = Crop::Object::Warehouse::Agent::DBI->new(@conn);
	
	$self;
}

=begin nd
Method: all ($object, @filter)
	Get all exemplars that match the @filter clause.

Parameters:
	$object - class name of objects
	@filter - complex clause contains WHERE, ORDER BY, and EXT tokens
	
Returns:
	collection of objects - if ok
	undef                 - otherwise
	
=cut
sub all {
	my ($self, $object, @filter) = @_;
	my $in = {@filter};
	my $class = ref $self || $self;
	
	for my $field (keys %{$in}) {
		next if $field ~~ KEYWORDS;

		for (split ' OR ', $field) {
		    return warn "OBJECT|ALERT: Unknown attribute: $object.$_" unless $object->Attributes->have(STORED, $_);
		}
	}

	if (exists $in->{SORT}) {
		$in->{ORDER} = delete $in->{SORT};
		$in->{ORDER} = [$in->{ORDER}] unless ref $in->{ORDER};
	}
	
	my %clause = %$in;
	my $ext    = delete $clause{EXT};
	my $sort   = delete $clause{ORDER};
	my $limit  = delete $clause{LIMIT};
	my $offset = delete $clause{OFFSET};
	
# 	my %key;
	
	my $q = Crop::Object::Warehouse::Lang::SQL::Query::Select->new(
		start_class => $object,
		clause      => \%clause,
		order       => $sort,
		limit       => $limit,
		ext         => $ext,
		offset      => $offset,
	)->build;
	my $rows = $self->{dbi}->fetch_all($q);

	# While the SELECT uses the LEFT JOIN only, following chunk of code don't work
# 	if (not @$rows and not $q->parsed->child->Is_empty) {
# 		return warn 'DBASE: Complex inner clauses is not implemented' if $q->parsed->child->Size > 1;
# 		
# 		my $n_clauses;
# 		$q->foreach_prepared($q->parsed, sub {
# 			my $node = shift;
# 		
# 			++$n_clauses if $node->clause;
# 		});
# 		
# 		my $inner_clauses = $q->parsed->clause ? $n_clauses - 1 : $n_clauses;
# 
# 		if ($inner_clauses) {
# 			my @root_sort = grep not /[.]/, @$sort;
# 			
# 			my $root_q = Crop::Object::Warehouse::Lang::SQL::Query::Select->new(
# 				start_class => $object,
# 				clause      => \%clause,
# 				@root_sort ? (order => \@root_sort) : (),
# 				limit       => $limit,
# 			)->build;
# 			$rows = $self->{dbi}->fetch_all($root_q);
# 			
# 			if (@$rows) {
# 				for ($q->parsed->child->List) {
# 					$q->foreach_prepared($_, sub {
# 						my $node = shift;
# 						
# 						$node->row_action('PARENTINIT');
# 					});
# 				}
# 			}
# 		}
# 	}
	
	for (@$rows) {
		my %data;
		while (my ($field, $val) = each %$_) {
			my ($table, $attr) = split '\$', $field;
			$data{$table}{$attr} = $val;
		}
		
		$q->foreach_prepared ($q->parsed, sub {
			my $node = shift;
			
			$node->parse_row(\%data);
		});
	}

	return $q->parsed->object;
}

=begin nd
Method: create ($object)
	Insert an object to the database.

Parameters:
	$obj - object data to insert
=cut
sub create {
	my ($self, $object) = @_;

	my %attr;
	for (@{$object->Attributes(STORED)}) {
		next unless defined $object->{$_->name};
		$attr{$_->name} = $object->{$_->name};
	}

	my $table = $object->Table;
	my $q = Crop::Object::Warehouse::Lang::SQL::Query::Insert->new(
		table     => $table,
		attr      => \%attr,
	);
	$self->{dbi}->exec($q) or return warn 'DBASE: Create object in Warehouse fails';
}


=begin nd
Method: create_auto_id ($object)
	Insert a new $object in the database, generate 'id'.

Parameters:
	$object - exemplar to create

Returns:
	id    - if ok
	undef - fail
=cut
sub create_auto_id {
	my ($self, $object) = @_;

	my %attr;
	for (@{$object->Attributes(STORED)}) {
		next unless defined $object->{$_->name};
		$attr{$_->name} = $object->{$_->name};
	}
	my $table = $object->Table;
	my $q = Crop::Object::Warehouse::Lang::SQL::Query::Insert->new(
		table     => $table,
		attr      => \%attr,
		returning => 'id',
	);

	$self->{dbi}->fetch($q)->{id};
}

=begin nd
Method: global_delete ($obj_class, $clause)
	Delete rows on etire class.
	
Parameters:
	$obj_class - class to update
	$clause    - {a1 => {'EQ' => 25}}; or {a1=>25} default EQ
=cut
sub global_delete {
	my ($self, $obj_class, $clause) = @_;
	
	my $table = $obj_class->Table or return warn 'OBJECT: Table required for global Delete';

	my $q = Crop::Object::Warehouse::Lang::SQL::Query::Delete->new(
		table   => $table,
		clause  => $clause,
	);

	$self->{dbi}->exec($q) or return warn 'DBASE: Can not global Delete';
}

=begin nd
Method: global_safe_update ($obj_class, $val, $clause)
	Update rows on entire class with care to table restrictions.

Param:
	$obj_class - class to update
	$val       - hashref $attr=>val where 'val' is an expression with direct references to table fields 'a1 = a2+1'
	$clause    - rule to select exemplars of $obj_class to update {a1 =>{'EQ'=>25}, a2=>7, ...}

	Returns:
	true  - ok
	false - error
=cut
sub global_safe_update {
# 	debug 'CROPOBJECTWAREHOUSEPG_GLOBALSAFEUPDATE_ARGV=', \@_;
# 	...;
# 	my ($self, $obj_class) = splice @_, 0, 2;

	my ($self, $obj_class, $val, $clause) = @_;
# 	debug 'CROPOBJECTWAREHOUSEPG_GLOBALSAFEUPDATE_VAL=', $val;

	# invert the value sign
	my %negative;
	while (my ($attr, $v) = each %$val) {
		$negative{$attr} = "($attr + $v) * -1";
	}
# 	debug 'CROPOBJECTWAREHOUSEPG_GLOBALSAFEUPDATE_NEGATIVE=', \%negative;
# 	...;
	$self->global_update($obj_class, \%negative, $clause);
# 	...;

	# restore the value sign for all the changed attributes
	my (%restore_val, %restore_clause);
	for (keys %negative) {
		$restore_val{$_}    = "$_ * -1";
		$restore_clause{$_} = {LT => 0};
	}
	$self->global_update(
		$obj_class,
		\%restore_val,
		\%restore_clause,
	);
}

=begin nd
Method: global_update ($obj_class, $values, $clause)
	Update rows on entire class.
	
Parameters:
	$obj_class - class to update
	$value     - hash $attr=>val where 'val' is an expression with direct references to table fields 'a1 = a2+1'
	$clause    - {a1 =>{EQ=>25}, a2=>7, ...};

Returns:
	true  - ok
	false - error
=cut
sub global_update {
	my ($self, $obj_class, $value, $clause) = @_;
# 	debug 'CROPOBJECTWAREHOUSEPG_GLOBALUPDATE_ARGV=', \@_;
	
	my $table = $obj_class->Table or return warn 'OBJECT: Table required for global Update';
	
	my %val_ref;
	for (keys %$value) {
# 		debug 'CROPOBJECTWAREHOUSEPG_GLOBALSAFEUPDATE_VALKEY=', $_;
		$val_ref{$_} = \$value->{$_};
	}
# 	my %val_ref = map ($_ => \$value->{$_}), keys %$value;
# 	debug 'CROPOBJECTWAREHOUSEPG_GLOBALUPDATE_VALREF=', \%val_ref;
# 	...;

	my $q = Crop::Object::Warehouse::Lang::SQL::Query::Update->new(
		table   => $table,
		new_val => \%val_ref,
		clause  => $clause,
	);
# 	debug 'CROPOBJECTWAREHOUSEPG_GLOBALUPDATE_UPDATEQ=', $q;
# 	...;

	$self->{dbi}->exec($q);
# 	my ($sql, $val) = $q->print_sql;
# 	$self->{dbi}->exec($sql, @$val);
}

=begin nd
Method: get_id ($obj)
	Get id for object.
	
Parameters:
	$obj - object that needs ID
	
Returns:
	$obj with ID defined
=cut
sub get_id {
	my ($self, $obj) = @_;
	
	my $sequence = $obj->Table . '_id_seq';
	my $q = Crop::Object::Warehouse::Lang::SQL::Query::Select->new(expression => "nextval('$sequence')");
	
	my $id = $self->{dbi}->fetch($q)->{nextval};
	
	$obj->{id} = $id;

	$obj;
}

=begin nd
Method: max ($class, $attr)
	Get the maximum value of the attribute

Param:
	$class
	$attr
=cut
sub max {
	my ($self, $obj, $attr) = @_;

	my $table = $obj->Table;
	my $rc = "max_$attr";
	my $q = Crop::Object::Warehouse::Lang::SQL::Query::Select->new(
		expression => "max($attr) AS $rc FROM $table",
	);

	my $max = $self->{dbi}->fetch($q)->{$rc};
	$max //= 0;
# 	debug 'CROPOBJECTWAREHOUSEPG_MAX_MAX=', $max;

	$max;
}

=begin nd
Method: refresh ($obj)
	Update an object in the database.
	
Parameters:
	$obj - exemplar to update
	
Returns:
	$obj  - if OK
	undef - otherwise
=cut
sub refresh {
	my ($self, $obj) = @_;
	
	my $table = $obj->Table or return warn 'OBJECT: Refresh exemplar requires a Table';
	
	my (%clause, %set);
	for (@{$obj->Attributes(STORED)}) {
		my $attr = $_->name;
		if ($_->of_type(KEY)) {
			$clause{$attr} = $obj->{$attr};
		} else {
			$set{$attr} = $obj->{$attr};
		}
	}

	my $q = Crop::Object::Warehouse::Lang::SQL::Query::Update->new(
		table   => $table,
		new_val => \%set,
		clause  => \%clause,
	);
# 	debug 'CROPOBJECTWAREHOUSEPG_Q=', $q;
	$self->{dbi}->exec($q);
	
	$obj;
}

=begin nd
Method: remove ($obj)
	Remove an $obj from database.
	
Parameters:
	$obj - exemplar to remove

Returns:
	undef
=cut
sub remove {
	my ($self, $obj) = @_;
	
	my $table = $obj->Table or return warn 'OBJECT: Remove exemplar requires a Table';
	
	my %keys = map {
		($_->name => $obj->{$_->name});
	} @{$obj->Attributes(KEY)};
	return warn 'OBJECT: Remove requires the primary key defined' unless keys %keys;
	
	my $q = Crop::Object::Warehouse::Lang::SQL::Query::Delete->new(
		table  => $obj->Table,
		clause => \%keys,
	);
	$self->{dbi}->exec($q);
	
	undef;
}

1;
