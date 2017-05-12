package Class::DBI::Frozen::301;

BEGIN {
  my @cdbi_packages = qw(Column ColumnGrouper Iterator Relationship Query
                        Relationship::HasA Relationship::MightHave
                        Relationship::HasMany);

  my @cdbi_modules = qw(Column ColumnGrouper Iterator Relationship Query
                        Relationship/HasA Relationship/MightHave
                        Relationship/HasMany);
  
  $INC{'Class/DBI.pm'} = 'Set by Class::DBI::Frozen::301';
  $INC{"Class/DBI/${_}.pm"} = 'Set by Class::DBI::Frozen::301'
    for @cdbi_modules;

  eval "use Class::DBI::Frozen::301::$_;" for @cdbi_packages;
}

package Class::DBI::__::Base;

require 5.00502;

use Class::Trigger 0.07;
use base qw(Class::Accessor Class::Data::Inheritable Ima::DBI);

package Class::DBI;

use strict;

use base "Class::DBI::__::Base";

use vars qw($VERSION);
$VERSION = '3.0.1';

use Class::DBI::ColumnGrouper;
use Class::DBI::Query;
use Carp ();
use List::Util;
use UNIVERSAL::moniker;

use vars qw($Weaken_Is_Available);

BEGIN {
	$Weaken_Is_Available = 1;
	eval {
		require Scalar::Util;
		import Scalar::Util qw(weaken);
	};
	if ($@) {
		$Weaken_Is_Available = 0;
	}
}

use overload
	'""'     => sub { shift->stringify_self },
	bool     => sub { not shift->_undefined_primary },
	fallback => 1;

sub stringify_self {
	my $self = shift;
	return (ref $self || $self) unless $self;    # empty PK
	my @cols = $self->columns('Stringify');
	@cols = $self->primary_columns unless @cols;
	return join "/", $self->get(@cols);
}

sub _undefined_primary {
	my $self = shift;
	return grep !defined, $self->_attrs($self->primary_columns);
}

{
	my %deprecated = (
		croak            => "_croak",               # 0.89
		carp             => "_carp",                # 0.89
		min              => "minimum_value_of",     # 0.89
		max              => "maximum_value_of",     # 0.89
		normalize_one    => "_normalize_one",       # 0.89
		_primary         => "primary_column",       # 0.90
		primary          => "primary_column",       # 0.89
		primary_key      => "primary_column",       # 0.90
		essential        => "_essential",           # 0.89
		column_type      => "has_a",                # 0.90
		associated_class => "has_a",                # 0.90
		is_column        => "find_column",          # 0.90
		has_column       => "find_column",          # 0.94
		add_hook         => "add_trigger",          # 0.90
		run_sql          => "retrieve_from_sql",    # 0.90
		rollback         => "discard_changes",      # 0.91
		commit           => "update",               # 0.91
		autocommit       => "autoupdate",           # 0.91
		new              => 'create',               # 0.93
		_commit_vals     => '_update_vals',         # 0.91
		_commit_line     => '_update_line',         # 0.91
		make_filter      => 'add_constructor',      # 0.93
	);

	no strict 'refs';
	while (my ($old, $new) = each %deprecated) {
		*$old = sub {
			my @caller = caller;
			warn
				"Use of '$old' is deprecated at $caller[1] line $caller[2]. Use '$new' instead\n";
			goto &$new;
		};
	}
}

sub normalize      { shift->_carp("normalize is deprecated") }         # 0.94
sub normalize_hash { shift->_carp("normalize_hash is deprecated") }    # 0.94

#----------------------------------------------------------------------
# Our Class Data
#----------------------------------------------------------------------
__PACKAGE__->mk_classdata('__AutoCommit');
__PACKAGE__->mk_classdata('__hasa_list');
__PACKAGE__->mk_classdata('_table');
__PACKAGE__->mk_classdata('_table_alias');
__PACKAGE__->mk_classdata('sequence');
__PACKAGE__->mk_classdata('__grouper');
__PACKAGE__->mk_classdata('__data_type');
__PACKAGE__->mk_classdata('__driver');
__PACKAGE__->__data_type({});

__PACKAGE__->mk_classdata('iterator_class');
__PACKAGE__->iterator_class('Class::DBI::Iterator');
__PACKAGE__->__grouper(Class::DBI::ColumnGrouper->new());

__PACKAGE__->mk_classdata('purge_object_index_every');
__PACKAGE__->purge_object_index_every(1000);

__PACKAGE__->add_relationship_type(
	has_a      => "Class::DBI::Relationship::HasA",
	has_many   => "Class::DBI::Relationship::HasMany",
	might_have => "Class::DBI::Relationship::MightHave",
);
__PACKAGE__->mk_classdata('__meta_info');
__PACKAGE__->__meta_info({});

#----------------------------------------------------------------------
# SQL we'll need
#----------------------------------------------------------------------
__PACKAGE__->set_sql(MakeNewObj => <<'');
INSERT INTO __TABLE__ (%s)
VALUES (%s)

__PACKAGE__->set_sql(update => <<"");
UPDATE __TABLE__
SET    %s
WHERE  __IDENTIFIER__

__PACKAGE__->set_sql(Nextval => <<'');
SELECT NEXTVAL ('%s')

__PACKAGE__->set_sql(SearchSQL => <<'');
SELECT %s
FROM   %s
WHERE  %s

__PACKAGE__->set_sql(RetrieveAll => <<'');
SELECT __ESSENTIAL__
FROM   __TABLE__

__PACKAGE__->set_sql(Retrieve => <<'');
SELECT __ESSENTIAL__
FROM   __TABLE__
WHERE  %s

__PACKAGE__->set_sql(Flesh => <<'');
SELECT %s
FROM   __TABLE__
WHERE  __IDENTIFIER__

__PACKAGE__->set_sql(single => <<'');
SELECT %s
FROM   __TABLE__

__PACKAGE__->set_sql(DeleteMe => <<"");
DELETE
FROM   __TABLE__
WHERE  __IDENTIFIER__


# Override transform_sql from Ima::DBI to provide some extra
# transformations
sub transform_sql {
	my ($self, $sql, @args) = @_;

	my %cmap;
	my $expand_table = sub {
		my ($class, $alias) = split /=/, shift, 2;
		my $table = $class ? $class->table : $self->table;
		$cmap{ $alias || $table } = $class || ref $self || $self;
		($alias ||= "") &&= " AS $alias";
		return $table . $alias;
	};

	my $expand_join = sub {
		my $joins  = shift;
		my @table  = split /\s+/, $joins;
		my %tojoin = map { $table[$_] => $table[ $_ + 1 ] } 0 .. $#table - 1;
		my @sql;
		while (my ($t1, $t2) = each %tojoin) {
			my ($c1, $c2) = map $cmap{$_}
				|| $self->_croak("Don't understand table '$_' in JOIN"), ($t1, $t2);

			my $join_col = sub {
				my ($c1, $c2) = @_;
				my $meta = $c1->meta_info('has_a');
				my ($col) = grep $meta->{$_}->foreign_class eq $c2, keys %$meta;
				$col;
			};

			my $col = $join_col->($c1 => $c2) || do {
				($c1, $c2) = ($c2, $c1);
				($t1, $t2) = ($t2, $t1);
				$join_col->($c1 => $c2);
			};

			$self->_croak("Don't know how to join $c1 to $c2") unless $col;
			push @sql, sprintf " %s.%s = %s.%s ", $t1, $col, $t2,
				$c2->primary_column;
		}
		return join " AND ", @sql;
	};

	$sql =~ s/__TABLE\(?(.*?)\)?__/$expand_table->($1)/eg;
	$sql =~ s/__JOIN\((.*?)\)__/$expand_join->($1)/eg;
	$sql =~ s/__ESSENTIAL__/join ", ", $self->_essential/eg;
	$sql =~
		s/__ESSENTIAL\((.*?)\)__/join ", ", map "$1.$_", $self->_essential/eg;
	if ($sql =~ /__IDENTIFIER__/) {
		my $key_sql = join " AND ", map "$_=?", $self->primary_columns;
		$sql =~ s/__IDENTIFIER__/$key_sql/g;
	}
	return $self->SUPER::transform_sql($sql => @args);
}

#----------------------------------------------------------------------
# EXCEPTIONS
#----------------------------------------------------------------------

sub _carp {
	my ($self, $msg) = @_;
	Carp::carp($msg || $self);
	return;
}

sub _croak {
	my ($self, $msg) = @_;
	Carp::croak($msg || $self);
}

#----------------------------------------------------------------------
# SET UP
#----------------------------------------------------------------------

sub connection {
	my $class = shift;
	$class->set_db(Main => @_);
}

{
	my %Per_DB_Attr_Defaults = (
		pg     => { AutoCommit => 0 },
		oracle => { AutoCommit => 0 },
	);

	sub _default_attributes {
		my $class = shift;
		return (
			$class->SUPER::_default_attributes,
			FetchHashKeyName   => 'NAME_lc',
			ShowErrorStatement => 1,
			AutoCommit         => 1,
			ChopBlanks         => 1,
			%{ $Per_DB_Attr_Defaults{ lc $class->__driver } || {} },
		);
	}
}

sub set_db {
	my ($class, $db_name, $data_source, $user, $password, $attr) = @_;

	# 'dbi:Pg:dbname=foo' we want 'Pg'. I think this is enough.
	my ($driver) = $data_source =~ /^dbi:(\w+)/i;
	$class->__driver($driver);
	$class->SUPER::set_db('Main', $data_source, $user, $password, $attr);
}

sub table {
	my ($proto, $table, $alias) = @_;
	my $class = ref $proto || $proto;
	$class->_table($table)      if $table;
	$class->table_alias($alias) if $alias;
	return $class->_table || $class->_table($class->table_alias);
}

sub table_alias {
	my ($proto, $alias) = @_;
	my $class = ref $proto || $proto;
	$class->_table_alias($alias) if $alias;
	return $class->_table_alias || $class->_table_alias($class->moniker);
}

sub columns {
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $group = shift || "All";
	return $class->_set_columns($group => @_) if @_;
	return $class->all_columns    if $group eq "All";
	return $class->primary_column if $group eq "Primary";
	return $class->_essential     if $group eq "Essential";
	return $class->__grouper->group_cols($group);
}

sub _set_columns {
	my ($class, $group, @columns) = @_;

	# Careful to take copy
	$class->__grouper(Class::DBI::ColumnGrouper->clone($class->__grouper)
			->add_group($group => @columns));
	$class->_mk_column_accessors(@columns);
	return @columns;
}

sub all_columns { shift->__grouper->all_columns }

sub id {
	my $self  = shift;
	my $class = ref($self)
		or return $self->_croak("Can't call id() as a class method");

	# we don't use get() here because all objects should have
	# exisitng values for PK columns, or else loop endlessly
	my @pk_values = $self->_attrs($self->primary_columns);
	return @pk_values if wantarray;
	$self->_croak(
		"id called in scalar context for class with multiple primary key columns")
		if @pk_values > 1;
	return $pk_values[0];
}

sub primary_column {
	my $self            = shift;
	my @primary_columns = $self->__grouper->primary;
	return @primary_columns if wantarray;
	$self->_carp(
		ref($self)
			. " has multiple primary columns, but fetching in scalar context")
		if @primary_columns > 1;
	return $primary_columns[0];
}
*primary_columns = \&primary_column;

sub _essential { shift->__grouper->essential }

sub find_column {
	my ($class, $want) = @_;
	return $class->__grouper->find_column($want);
}

sub _find_columns {
	my $class = shift;
	my $cg    = $class->__grouper;
	return map $cg->find_column($_), @_;
}

sub has_real_column {    # is really in the database
	my ($class, $want) = @_;
	return ($class->find_column($want) || return)->in_database;
}

sub data_type {
	my $class    = shift;
	my %datatype = @_;
	while (my ($col, $type) = each %datatype) {
		$class->_add_data_type($col, $type);
	}
}

sub _add_data_type {
	my ($class, $col, $type) = @_;
	my $datatype = $class->__data_type;
	$datatype->{$col} = $type;
	$class->__data_type($datatype);
}

# Make a set of accessors for each of a list of columns. We construct
# the method name by calling accessor_name() and mutator_name() with the
# normalized column name.

# mutator_name will be the same as accessor_name unless you override it.

# If both the accessor and mutator are to have the same method name,
# (which will always be true unless you override mutator_name), a read-write
# method is constructed for it. If they differ we create both a read-only
# accessor and a write-only mutator.

sub _mk_column_accessors {
	my $class = shift;
	foreach my $obj ($class->_find_columns(@_)) {
		my %method = (
			ro => $obj->accessor($class->accessor_name($obj->name)),
			wo => $obj->mutator($class->mutator_name($obj->name)),
		);
		my $both = ($method{ro} eq $method{wo});
		foreach my $type (keys %method) {
			my $name     = $method{$type};
			my $acc_type = $both ? "make_accessor" : "make_${type}_accessor";
			my $accessor = $class->$acc_type($obj->name_lc);
			$class->_make_method($_, $accessor) for ($name, "_${name}_accessor");
		}
	}
}

sub _make_method {
	my ($class, $name, $method) = @_;
	return if defined &{"$class\::$name"};
	$class->_carp("Column '$name' in $class clashes with built-in method")
		if Class::DBI->can($name)
		and not($name eq "id" and join(" ", $class->primary_columns) eq "id");
	no strict 'refs';
	*{"$class\::$name"} = $method;
	$class->_make_method(lc $name => $method);
}

sub accessor_name {
	my ($class, $column) = @_;
	return $column;
}

sub mutator_name {
	my ($class, $column) = @_;
	return $class->accessor_name($column);
}

sub autoupdate {
	my $proto = shift;
	ref $proto ? $proto->_obj_autoupdate(@_) : $proto->_class_autoupdate(@_);
}

sub _obj_autoupdate {
	my ($self, $set) = @_;
	my $class = ref $self;
	$self->{__AutoCommit} = $set if defined $set;
	defined $self->{__AutoCommit}
		? $self->{__AutoCommit}
		: $class->_class_autoupdate;
}

sub _class_autoupdate {
	my ($class, $set) = @_;
	$class->__AutoCommit($set) if defined $set;
	return $class->__AutoCommit;
}

sub make_read_only {
	my $proto = shift;
	$proto->add_trigger("before_$_" => sub { _croak "$proto is read only" })
		foreach qw/create delete update/;
	return $proto;
}

sub find_or_create {
	my $class    = shift;
	my $hash     = ref $_[0] eq "HASH" ? shift: {@_};
	my ($exists) = $class->search($hash);
	return defined($exists) ? $exists : $class->create($hash);
}

sub create {
	my $class = shift;
	return $class->_croak("create needs a hashref") unless ref $_[0] eq 'HASH';
	my $info = { %{ +shift } };    # make sure we take a copy

	my $data;
	while (my ($k, $v) = each %$info) {
		my $col = $class->find_column($k)
			|| (List::Util::first { $_->mutator  eq $k } $class->columns)
			|| (List::Util::first { $_->accessor eq $k } $class->columns)
			|| $class->_croak("$k is not a column of $class");
		$data->{$col} = $v;
	}

	$class->normalize_column_values($data);
	$class->validate_column_values($data);
	return $class->_create($data);
}

sub _attrs {
	my ($self, @atts) = @_;
	return @{$self}{@atts};
}
*_attr = \&_attrs;

sub _attribute_store {
	my $self   = shift;
	my $vals   = @_ == 1 ? shift: {@_};
	my (@cols) = keys %$vals;
	@{$self}{@cols} = @{$vals}{@cols};
}

# If you override this method, you must use the same mechanism to log changes
# for future updates, as other parts of Class::DBI depend on it.
sub _attribute_set {
	my $self = shift;
	my $vals = @_ == 1 ? shift: {@_};

	# We increment instead of setting to 1 because it might be useful to
	# someone to know how many times a value has changed between updates.
	for my $col (keys %$vals) { $self->{__Changed}{$col}++; }
	$self->_attribute_store($vals);
}

sub _attribute_delete {
	my ($self, @attributes) = @_;
	delete @{$self}{@attributes};
}

sub _attribute_exists {
	my ($self, $attribute) = @_;
	exists $self->{$attribute};
}

# keep an index of live objects using weak refs
my %Live_Objects;
my $Init_Count = 0;

sub _init {
	my $class = shift;
	my $data = shift || {};
	my $obj;
	my $obj_key = "";

	my @primary_columns = $class->primary_columns;
	if (@primary_columns == grep defined, @{$data}{@primary_columns}) {

		# create single unique key for this object
		$obj_key = join "|", $class, map { $_ . '=' . $data->{$_} }
			sort @primary_columns;
	}

	unless (defined($obj = $Live_Objects{$obj_key})) {

		# not in the object_index, or we don't have all keys yet
		$obj = bless {}, $class;
		$obj->_attribute_store(%$data);

		# don't store it unless all keys are present
		if ($obj_key && $Weaken_Is_Available) {
			weaken($Live_Objects{$obj_key} = $obj);

			# time to clean up your room?
			$class->purge_dead_from_object_index
				if ++$Init_Count % $class->purge_object_index_every == 0;
		}
	}

	return $obj;
}

sub purge_dead_from_object_index {
	delete @Live_Objects{ grep !defined $Live_Objects{$_}, keys %Live_Objects };
}

sub remove_from_object_index {
	my $self            = shift;
	my @primary_columns = $self->primary_columns;
	my %data;
	@data{@primary_columns} = $self->get(@primary_columns);
	my $obj_key = join "|", ref $self, map $_ . '=' . $data{$_},
		sort @primary_columns;
	delete $Live_Objects{$obj_key};
}

sub clear_object_index {
	%Live_Objects = ();
}

sub _prepopulate_id {
	my $self            = shift;
	my @primary_columns = $self->primary_columns;
	return $self->_croak(
		sprintf "Can't create %s object with null primary key columns (%s)",
		ref $self, $self->_undefined_primary)
		if @primary_columns > 1;
	$self->_attribute_store($primary_columns[0] => $self->_next_in_sequence)
		if $self->sequence;
}

sub _create {
	my ($proto, $data) = @_;
	my $class = ref $proto || $proto;

	my $self = $class->_init($data);
	$self->call_trigger('before_create');
	$self->call_trigger('deflate_for_create');

	$self->_prepopulate_id if $self->_undefined_primary;

	# Reinstate data
	my ($real, $temp) = ({}, {});
	foreach my $col (grep $self->_attribute_exists($_), $self->all_columns) {
		($class->has_real_column($col) ? $real : $temp)->{$col} =
			$self->_attrs($col);
	}
	$self->_insert_row($real);

	my @primary_columns = $class->primary_columns;
	$self->_attribute_store(
		$primary_columns[0] => $real->{ $primary_columns[0] })
		if @primary_columns == 1;

	delete $self->{__Changed};

	my %primary_columns;
	@primary_columns{@primary_columns} = ();
	my @discard_columns = grep !exists $primary_columns{$_}, keys %$real;
	$self->call_trigger('create', discard_columns => \@discard_columns);   # XXX

	# Empty everything back out again!
	$self->_attribute_delete(@discard_columns);
	$self->call_trigger('after_create');
	return $self;
}

sub _next_in_sequence {
	my $self = shift;
	return $self->sql_Nextval($self->sequence)->select_val;
}

sub _auto_increment_value {
	my $self = shift;
	my $dbh  = $self->db_Main;

	# the DBI will provide a standard attribute soon, meanwhile...
	my $id = $dbh->{mysql_insertid}    # mysql
		|| eval { $dbh->func('last_insert_rowid') };    # SQLite
	$self->_croak("Can't get last insert id") unless defined $id;
	return $id;
}

sub _insert_row {
	my $self = shift;
	my $data = shift;
	eval {
		my @columns = keys %$data;
		my $sth     = $self->sql_MakeNewObj(
			join(', ', @columns),
			join(', ', map $self->_column_placeholder($_), @columns),
		);
		$self->_bind_param($sth, \@columns);
		$sth->execute(values %$data);
		my @primary_columns = $self->primary_columns;
		$data->{ $primary_columns[0] } = $self->_auto_increment_value
			if @primary_columns == 1
			&& !defined $data->{ $primary_columns[0] };
	};
	if ($@) {
		my $class = ref $self;
		return $self->_croak(
			"Can't insert new $class: $@",
			err    => $@,
			method => 'create'
		);
	}
	return 1;
}

sub _bind_param {
	my ($class, $sth, $keys) = @_;
	my $datatype = $class->__data_type or return;
	for my $i (0 .. $#$keys) {
		if (my $type = $datatype->{ $keys->[$i] }) {
			$sth->bind_param($i + 1, undef, $type);
		}
	}
}

sub retrieve {
	my $class           = shift;
	my @primary_columns = $class->primary_columns
		or return $class->_croak(
		"Can't retrieve unless primary columns are defined");
	my %key_value;
	if (@_ == 1 && @primary_columns == 1) {
		my $id = shift;
		return unless defined $id;
		return $class->_croak("Can't retrieve a reference") if ref($id);
		$key_value{ $primary_columns[0] } = $id;
	} else {
		%key_value = @_;
		$class->_croak(
			"$class->retrieve(@_) parameters don't include values for all primary key columns (@primary_columns)"
			)
			if keys %key_value < @primary_columns;
	}
	my @rows = $class->search(%key_value);
	$class->_carp("$class->retrieve(@_) selected " . @rows . " rows")
		if @rows > 1;
	return $rows[0];
}

# Get the data, as a hash, but setting certain values to whatever
# we pass. Used by copy() and move().
# This can take either a primary key, or a hashref of all the columns
# to change.
sub _data_hash {
	my $self    = shift;
	my @columns = $self->all_columns;
	my %data;
	@data{@columns} = $self->get(@columns);
	my @primary_columns = $self->primary_columns;
	delete @data{@primary_columns};
	if (@_) {
		my $arg = shift;
		unless (ref $arg) {
			$self->_croak("Need hash-ref to edit copied column values")
				unless @primary_columns == 1;
			$arg = { $primary_columns[0] => $arg };
		}
		@data{ keys %$arg } = values %$arg;
	}
	return \%data;
}

sub copy {
	my $self = shift;
	return $self->create($self->_data_hash(@_));
}

#----------------------------------------------------------------------
# CONSTRUCT
#----------------------------------------------------------------------

sub construct {
	my ($proto, $data) = @_;
	my $class = ref $proto || $proto;
	my $self = $class->_init($data);
	$self->call_trigger('select');
	return $self;
}

sub move {
	my ($class, $old_obj, @data) = @_;
	$class->_carp("move() is deprecated. If you really need it, "
			. "you should tell me quickly so I can abandon my plan to remove it.");
	return $old_obj->_croak("Can't move to an unrelated class")
		unless $class->isa(ref $old_obj)
		or $old_obj->isa($class);
	return $class->create($old_obj->_data_hash(@data));
}

sub delete {
	my $self = shift;
	return $self->_search_delete(@_) if not ref $self;
	$self->call_trigger('before_delete');

	eval { $self->sql_DeleteMe->execute($self->id) };
	if ($@) {
		return $self->_croak("Can't delete $self: $@", err => $@);
	}
	$self->call_trigger('after_delete');
	undef %$self;
	bless $self, 'Class::DBI::Object::Has::Been::Deleted';
	return 1;
}

sub _search_delete {
	my ($class, @args) = @_;
	$class->_carp(
		"Delete as class method is deprecated. Use search and delete_all instead."
	);
	my $it = $class->search_like(@args);
	while (my $obj = $it->next) { $obj->delete }
	return 1;
}

# Return the placeholder to be used in UPDATE and INSERT queries.
# Overriding this is deprecated in favour of
#   __PACKAGE__->find_column('entered')->placeholder('IF(1, CURDATE(), ?));

sub _column_placeholder {
	my ($self, $column) = @_;
	return $self->find_column($column)->placeholder;
}

sub update {
	my $self  = shift;
	my $class = ref($self)
		or return $self->_croak("Can't call update as a class method");

	$self->call_trigger('before_update');
	return 1 unless my @changed_cols = $self->is_changed;
	$self->call_trigger('deflate_for_update');
	my @primary_columns = $self->primary_columns;
	my $sth             = $self->sql_update($self->_update_line);
	$class->_bind_param($sth, \@changed_cols);
	my $rows = eval { $sth->execute($self->_update_vals, $self->id); };
	return $self->_croak("Can't update $self: $@", err => $@) if $@;

	# enable this once new fixed DBD::SQLite is released:
	if (0 and $rows != 1) {    # should always only update one row
		$self->_croak("Can't update $self: row not found") if $rows == 0;
		$self->_croak("Can't update $self: updated more than one row");
	}

	$self->call_trigger('after_update', discard_columns => \@changed_cols);

	# delete columns that changed (in case adding to DB modifies them again)
	$self->_attribute_delete(@changed_cols);
	delete $self->{__Changed};
	return 1;
}

sub _update_line {
	my $self = shift;
	join(', ', map "$_ = " . $self->_column_placeholder($_), $self->is_changed);
}

sub _update_vals {
	my $self = shift;
	$self->_attrs($self->is_changed);
}

sub DESTROY {
	my ($self) = shift;
	if (my @changed = $self->is_changed) {
		my $class = ref $self;
		$self->_carp("$class $self destroyed without saving changes to "
				. join(', ', @changed));
	}
}

sub discard_changes {
	my $self = shift;
	return $self->_croak("Can't discard_changes while autoupdate is on")
		if $self->autoupdate;
	$self->_attribute_delete($self->is_changed);
	delete $self->{__Changed};
	return 1;
}

# We override the get() method from Class::Accessor to fetch the data for
# the column (and associated) columns from the database, using the _flesh()
# method. We also allow get to be called with a list of keys, instead of
# just one.

sub get {
	my $self = shift;
	return $self->_croak("Can't fetch data as class method") unless ref $self;

	my @cols = $self->_find_columns(@_);
	return $self->_croak("Can't get() nothing!") unless @cols;

	if (my @fetch_cols = grep !$self->_attribute_exists($_), @cols) {
		$self->_flesh($self->__grouper->groups_for(@fetch_cols));
	}

	return $self->_attrs(@cols);
}

sub _flesh {
	my ($self, @groups) = @_;
	my @real = grep $_ ne "TEMP", @groups;
	if (my @want = grep !$self->_attribute_exists($_),
		$self->__grouper->columns_in(@real)) {
		my %row;
		@row{@want} = $self->sql_Flesh(join ", ", @want)->select_row($self->id);
		$self->_attribute_store(\%row);
		$self->call_trigger('select');
	}
	return 1;
}

# We also override set() from Class::Accessor so we can keep track of
# changes, and either write to the database now (if autoupdate is on),
# or when update() is called.
sub set {
	my $self          = shift;
	my $column_values = {@_};

	$self->normalize_column_values($column_values);
	$self->validate_column_values($column_values);

	while (my ($column, $value) = each %$column_values) {
		my $col = $self->find_column($column) or die "No such column: $column\n";
		$self->_attribute_set($col => $value);

		# $self->SUPER::set($column, $value);

		eval { $self->call_trigger("after_set_$column") };    # eg inflate
		if ($@) {
			$self->_attribute_delete($column);
			return $self->_croak("after_set_$column trigger error: $@", err => $@);
		}
	}

	$self->update if $self->autoupdate;
	return 1;
}

sub is_changed {
	my $self = shift;
	grep $self->has_real_column($_), keys %{ $self->{__Changed} };
}

sub any_changed { keys %{ shift->{__Changed} } }

# By default do nothing. Subclasses should override if required.
#
# Given a hash ref of column names and proposed new values,
# edit the values in the hash if required.
# For create $self is the class name (not an object ref).
sub normalize_column_values {
	my ($self, $column_values) = @_;
}

# Given a hash ref of column names and proposed new values
# validate that the whole set of new values in the hash
# is valid for the object in relation to its current values
# For create $self is the class name (not an object ref).
sub validate_column_values {
	my ($self, $column_values) = @_;
	my @errors;
	foreach my $column (keys %$column_values) {
		eval {
			$self->call_trigger("before_set_$column", $column_values->{$column},
				$column_values);
		};
		push @errors, $column => $@ if $@;
	}
	return unless @errors;
	$self->_croak(
		"validate_column_values error: " . join(" ", @errors),
		method => 'validate_column_values',
		data   => {@errors}
	);
}

# We override set_sql() from Ima::DBI so it has a default database connection.
sub set_sql {
	my ($class, $name, $sql, $db, @others) = @_;
	$db ||= 'Main';
	$class->SUPER::set_sql($name, $sql, $db, @others);
	$class->_generate_search_sql($name) if $sql =~ /select/i;
	return 1;
}

sub _generate_search_sql {
	my ($class, $name) = @_;
	my $method = "search_$name";
	defined &{"$class\::$method"}
		and return $class->_carp("$method() already exists");
	my $sql_method = "sql_$name";
	no strict 'refs';
	*{"$class\::$method"} = sub {
		my ($class, @args) = @_;
		return $class->sth_to_objects($name, \@args);
	};
}

sub dbi_commit   { my $proto = shift; $proto->SUPER::commit(@_); }
sub dbi_rollback { my $proto = shift; $proto->SUPER::rollback(@_); }

#----------------------------------------------------------------------
# Constraints / Triggers
#----------------------------------------------------------------------

sub constrain_column {
	my $class = shift;
	my $col   = $class->find_column(+shift)
		or return $class->_croak("constraint_column needs a valid column");
	my $how = shift
		or return $class->_croak("constrain_column needs a constraint");
	if (ref $how eq "ARRAY") {
		my %hash = map { $_ => 1 } @$how;
		$class->add_constraint(list => $col => sub { exists $hash{ +shift } });
	} elsif (ref $how eq "Regexp") {
		$class->add_constraint(regexp => $col => sub { shift =~ $how });
	} else {
		my $try_method = sprintf '_constrain_by_%s', $how->moniker;
		if (my $dispatch = $class->can($try_method)) {
			$class->$dispatch($col => ($how, @_));
		} else {
			$class->_croak("Don't know how to constrain $col with $how");
		}
	}
}

sub add_constraint {
	my $class = shift;
	$class->_invalid_object_method('add_constraint()') if ref $class;
	my $name = shift or return $class->_croak("Constraint needs a name");
	my $column = $class->find_column(+shift)
		or return $class->_croak("Constraint $name needs a valid column");
	my $code = shift
		or return $class->_croak("Constraint $name needs a code reference");
	return $class->_croak("Constraint $name '$code' is not a code reference")
		unless ref($code) eq "CODE";

	$column->is_constrained(1);
	$class->add_trigger(
		"before_set_$column" => sub {
			my ($self, $value, $column_values) = @_;
			$code->($value, $self, $column, $column_values)
				or return $self->_croak(
				"$class $column fails '$name' constraint with '$value'");
		}
	);
}

sub add_trigger {
	my ($self, $name, @args) = @_;
	return $self->_croak("on_setting trigger no longer exists")
		if $name eq "on_setting";
	$self->_carp(
		"$name trigger deprecated: use before_$name or after_$name instead")
		if ($name eq "create" or $name eq "delete");
	$self->SUPER::add_trigger($name => @args);
}

#----------------------------------------------------------------------
# Inflation
#----------------------------------------------------------------------

sub add_relationship_type {
	my ($self, %rels) = @_;
	while (my ($name, $class) = each %rels) {
		$self->_require_class($class);
		no strict 'refs';
		*{"$self\::$name"} = sub {
			my $proto = shift;
			$class->set_up($name => $proto => @_);
		};
	}
}

sub _extend_meta {
	my ($class, $type, $subtype, $val) = @_;
	my %hash = %{ $class->__meta_info || {} };
	$hash{$type}->{$subtype} = $val;
	$class->__meta_info(\%hash);
}

sub meta_info {
	my ($class, $type, $subtype) = @_;
	my $meta = $class->__meta_info;
	return $meta          unless $type;
	return $meta->{$type} unless $subtype;
	return $meta->{$type}->{$subtype};
}

sub _simple_bless {
	my ($class, $pri) = @_;
	return $class->_init({ $class->primary_column => $pri });
}

sub _deflated_column {
	my ($self, $col, $val) = @_;
	$val ||= $self->_attrs($col) if ref $self;
	return $val unless ref $val;
	my $meta = $self->meta_info(has_a => $col) or return $val;
	my ($a_class, %meths) = ($meta->foreign_class, %{ $meta->args });
	if (my $deflate = $meths{'deflate'}) {
		$val = $val->$deflate(ref $deflate eq 'CODE' ? $self : ());
		return $val unless ref $val;
	}
	return $self->_croak("Can't deflate $col: $val is not a $a_class")
		unless UNIVERSAL::isa($val, $a_class);
	return $val->id if UNIVERSAL::isa($val => 'Class::DBI');
	return "$val";
}

#----------------------------------------------------------------------
# SEARCH
#----------------------------------------------------------------------

sub retrieve_all { shift->sth_to_objects('RetrieveAll') }

sub retrieve_from_sql {
	my ($class, $sql, @vals) = @_;
	$sql =~ s/^\s*(WHERE)\s*//i;
	return $class->sth_to_objects($class->sql_Retrieve($sql), \@vals);
}

sub search_like { shift->_do_search(LIKE => @_) }
sub search      { shift->_do_search("="  => @_) }

sub _do_search {
	my ($proto, $search_type, @args) = @_;
	my $class = ref $proto || $proto;

	@args = %{ $args[0] } if ref $args[0] eq "HASH";
	my (@cols, @vals);
	my $search_opts = @args % 2 ? pop @args : {};
	while (my ($col, $val) = splice @args, 0, 2) {
		my $column = $class->find_column($col)
			|| (List::Util::first { $_->accessor eq $col } $class->columns)
			|| $class->_croak("$col is not a column of $class");
		push @cols, $column;
		push @vals, $class->_deflated_column($column, $val);
	}

	my $frag = join " AND ",
		map defined($vals[$_]) ? "$cols[$_] $search_type ?" : "$cols[$_] IS NULL",
		0 .. $#cols;
	$frag .= " ORDER BY $search_opts->{order_by}"
		if $search_opts->{order_by};
	return $class->sth_to_objects($class->sql_Retrieve($frag),
		[ grep defined, @vals ]);

}

#----------------------------------------------------------------------
# CONSTRUCTORS
#----------------------------------------------------------------------

sub add_constructor {
	my ($class, $method, $fragment) = @_;
	return $class->_croak("constructors needs a name") unless $method;
	no strict 'refs';
	my $meth = "$class\::$method";
	return $class->_carp("$method already exists in $class")
		if *$meth{CODE};
	*$meth = sub {
		my $self = shift;
		$self->sth_to_objects($self->sql_Retrieve($fragment), \@_);
	};
}

sub sth_to_objects {
	my ($class, $sth, $args) = @_;
	$class->_croak("sth_to_objects needs a statement handle") unless $sth;
	unless (UNIVERSAL::isa($sth => "DBI::st")) {
		my $meth = "sql_$sth";
		$sth = $class->$meth();
	}
	my (%data, @rows);
	eval {
		$sth->execute(@$args) unless $sth->{Active};
		$sth->bind_columns(\(@data{ @{ $sth->{NAME_lc} } }));
		push @rows, {%data} while $sth->fetch;
	};
	return $class->_croak("$class can't $sth->{Statement}: $@", err => $@)
		if $@;
	return $class->_ids_to_objects(\@rows);
}
*_sth_to_objects = \&sth_to_objects;

sub _my_iterator {
	my $self  = shift;
	my $class = $self->iterator_class;
	$self->_require_class($class);
	return $class;
}

sub _ids_to_objects {
	my ($class, $data) = @_;
	return $#$data + 1 unless defined wantarray;
	return map $class->construct($_), @$data if wantarray;
	return $class->_my_iterator->new($class => $data);
}

#----------------------------------------------------------------------
# SINGLE VALUE SELECTS
#----------------------------------------------------------------------

sub _single_row_select {
	my ($self, $sth, @args) = @_;
	Carp::confess("_single_row_select is deprecated in favour of select_row");
	return $sth->select_row(@args);
}

sub _single_value_select {
	my ($self, $sth, @args) = @_;
	$self->_carp("_single_value_select is deprecated in favour of select_val");
	return $sth->select_val(@args);
}

sub count_all { shift->sql_single("COUNT(*)")->select_val }

sub maximum_value_of {
	my ($class, $col) = @_;
	$class->sql_single("MAX($col)")->select_val;
}

sub minimum_value_of {
	my ($class, $col) = @_;
	$class->sql_single("MIN($col)")->select_val;
}

sub _unique_entries {
	my ($class, %tmp) = shift;
	return grep !$tmp{$_}++, @_;
}

sub _invalid_object_method {
	my ($self, $method) = @_;
	$self->_carp(
		"$method should be called as a class method not an object method");
}

#----------------------------------------------------------------------
# misc stuff
#----------------------------------------------------------------------

sub _extend_class_data {
	my ($class, $struct, $key, $value) = @_;
	my %hash = %{ $class->$struct() || {} };
	$hash{$key} = $value;
	$class->$struct(\%hash);
}

my %required_classes; # { required_class => class_that_last_required_it, ... }

sub _require_class {
	my ($self, $load_class) = @_;
	$required_classes{$load_class} ||= my $for_class = ref($self) || $self;

	# return quickly if class already exists
	no strict 'refs';
	return if exists ${"$load_class\::"}{ISA};
	(my $load_module = $load_class) =~ s!::!/!g;
	return if eval { require "$load_module.pm" };

	# Only ignore "Can't locate" errors for the specific module we're loading
	return if $@ =~ /^Can't locate \Q$load_module\E\.pm /;

	# Other fatal errors (syntax etc) must be reported (as per base.pm).
	chomp $@;

	# This error message prefix is especially handy when dealing with
	# classes that are being loaded by other classes recursively.
	# The final message shows the path, e.g.:
	# Foo can't load Bar: Bar can't load Baz: syntax error at line ...
	$self->_croak("$for_class can't load $load_class: $@");
}

sub _check_classes {    # may automatically call from CHECK block in future
	while (my ($load_class, $by_class) = each %required_classes) {
		next if $load_class->isa("Class::DBI");
		$by_class->_croak(
			"Class $load_class used by $by_class has not been loaded");
	}
}

#----------------------------------------------------------------------
# Deprecations
#----------------------------------------------------------------------

__PACKAGE__->mk_classdata('__hasa_rels');
__PACKAGE__->__hasa_rels({});

sub ordered_search {
	shift->_croak(
		"Ordered search no longer exists. Pass order_by to search instead.");
}

sub hasa {
	my ($class, $f_class, $f_col) = @_;
	$class->_carp(
		"hasa() is deprecated in favour of has_a(). Using it instead.");
	$class->has_a($f_col => $f_class);
}

sub hasa_list {
	my $class = shift;
	$class->_carp("hasa_list() is deprecated in favour of has_many()");
	$class->has_many(@_[ 2, 0, 1 ], { nohasa => 1 });
}

1;

__END__

=head1 NAME

	Class::DBI::Frozen::301 - Class::DBI, frozen at 3.0.1

=head1 SYNOPSIS

  use Class::DBI::Frozen::301;

  ... Class::DBI-using app as normal ...

With the rapid changes in Class::DBI and the author's refusal to participate
in the community or effectively liaise with developers of dependent apps
to ensure that plugin authors are warned of changes in order to avoid
breakage, a substantial number of users have frozen their production systems
at 0.96 or 3.0.1. This is designed to make that easier, and to allow other
users of the same system to use whatever Class::DBI version they prefer.

The rest of this POD is identical to the original from 3.0.1; the section
titled 'RELEASE PHILOSOPHY' should make the reason for this package
abundantly clear.

=head1 CURRENT AUTHOR

Tony Bowden 

=head1 AUTHOR EMERITUS

Michael G Schwern 

=head1 THANKS TO

Tim Bunce, Tatsuhiko Miyagawa, Perrin Hawkins, Alexander Karelas, Barry
Hoggard, Bart Lateur, Boris Mouzykantskii, Brad Bowman, Brian Parker,
Casey West, Charles Bailey, Christopher L. Everett Damian Conway, Dan
Thill, Dave Cash, David Jack Olrik, Dominic Mitchell, Drew Taylor,
Drew Wilson, Jay Strauss, Jesse Sheidlower, Jonathan Swartz, Marty
Pauley, Michael Styer, Mike Lambert, Paul Makepeace, Phil Crow, Richard
Piacentini, Simon Cozens, Simon Wilcox, Thomas Klausner, Tom Renfro,
Uri Gutman, William McKee, the Class::DBI mailing list, the POOP group,
and all the others who've helped, but that I've forgetten to mention.

=head1 RELEASE PHILOSOPHY

Class::DBI now uses a three-level versioning system. This release, for
example, is version 3.0.1

The general approach to releases will be that users who like a degree of
stability can hold off on upgrades until the major sub-version increases
(e.g. 3.1.0). Those who like living more on the cutting edge can keep up
to date with minor sub-version releases. 

In general the minor-version releases will be for bug fixes and
refactorings, whereas new functionality will be held-off until major
sub-version releases.

Of course, these aren't hard and fast rules, and we'll need to see how
this all goes.

=head2 Getting changes accepted

There is an active Class::DBI community, however I am not part of it.
I am not on the mailing list, and I don't follow the wiki. I also do
not follow Perl Monks or CPAN reviews or annoCPAN or whatever the tool
du jour happens to be. 

If you find a problem with Class::DBI, by all means discuss it in any of
these places, but don't expect anything to happen unless you actually
tell me about it.

The preferred method for doing this is via the CPAN RT interface, which
you can access at http://rt.cpan.org/ or by emailing
  bugs-Class-DBI@rt.cpan.org

If you email me personally about Class::DBI issues, then I will
probably bounce them on to there, unless you specifically ask me not to.
Otherwise I can't keep track of what all needs fixed. (This of course
means that if you ask me not to send your mail to RT, there's a much
higher chance that nothing will every happen about your problem).

=head2 Bug Reports

If you're reporting a bug then it has a much higher chance of getting
fixed quicker if you can include a failing test case. This should be
a completely stand-alone test that could be added to the Class::DBI
distribution. That is, it should use Test::Simple or Test::More, fail
with the current code, but pass when I fix the problem. If it needs to
have a working database to show the problem, then this should preferably
use SQLite, and come with all the code to set this up. The nice people
on the mailing list will probably help you out if you need assistance
putting this together.

You don't need to include code for actually fixing the problem, but of
course it's often nice if you can. I may choose to fix it in a different
way, however, so it's often better to ask first whether I'd like a
patch, particularly before spending a lot of time hacking.

=head2 Patches

If you are sending patches, then please send either the entire code
that is being changed or the output of 'diff -Bub'.  Please also note
what version the patch is against. I tend to apply all patches manually,
so I'm more interested in being able to see what you're doing than in
being able to apply the patch cleanly. Code formatting isn't an issue,
as I automagically run perltidy against the source after any changes,
so please format for clarity.

Patches have a much better chance of being applied if they are small.
People often think that it's better for me to get one patch with a bunch
of fixes. It's not. I'd much rather get 100 small patches that can be
applied one by one. A change that I can make and release in five minutes
is always better than one that needs a couple of hours to ponder and work
through. 

I often reject patches that I don't like. Please don't take it personally.
I also like time to think about the wider implications of changes. Often
a I<lot> of time. Feel free to remind me about things that I may have
forgotten about, but as long as they're on rt.cpan.org I will get around
to them eventually.

=head2 Feature Requests

Wish-list requests are fine, although you should probably discuss them
on the mailing list (or equivalent) with others first. There's quite
often a plugin somewhere that already does what you want.

In general I am much more open to discussion on how best to provide the
flexibility for you to make your Cool New Feature(tm) a plugin rather
than adding it to Class::DBI itself.

For the most part the core of Class::DBI already has most of the
functionality that I believe it will ever need (and some more besides,
that will probably be split off at some point). Most other things are much
better off as plugins, with a separate life on CPAN or elsewhere (and with
me nowhere near the critical path). Most of the ongoing work on Class::DBI
is about making life easier for people to write extensions - whether
they're local to your own codebase or released for wider consumption.

=head1 SUPPORT

Support for Class::DBI is mostly via the mailing list.

To join the list, or read the archives, visit
  http://lists.digitalcraftsmen.net/mailman/listinfo/classdbi

There is also a Class::DBI wiki at 
  http://www.class-dbi.com/

The wiki contains much information that should probably be in these docs
but isn't yet. (See above if you want to help to rectify this.)

As mentioned above, I don't follow the list or the wiki, so if you want
to contact me individually, then you'll have to track me down personally.

There are lots of 3rd party subclasses and plugins available.
For a list of the ones on CPAN see:
  http://search.cpan.org/search?query=Class%3A%3ADBI&mode=module

An article on Class::DBI was published on Perl.com a while ago. It's
slightly out of date , but it's a good introduction:
  http://www.perl.com/pub/a/2002/11/27/classdbi.html

The wiki has numerous references to other articles, presentations etc.

http://poop.sourceforge.net/ provides a document comparing a variety
of different approaches to database persistence, such as Class::DBI,
Alazabo, Tangram, SPOPS etc.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Class::DBI is built on top of L<Ima::DBI>, L<DBIx::ContextualFetch>,
L<Class::Accessor> and L<Class::Data::Inheritable>. The innards and
much of the interface are easier to understand if you have an idea of
how they all work as well.

=cut

