package DBIx::QuickORM::ORM;
use strict;
use warnings;

our $VERSION = '0.000002';

use Carp qw/confess croak/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/alias/;

require DBIx::QuickORM::GlobalLookup;
require DBIx::QuickORM::Schema;
require DBIx::QuickORM::Source;
require DBIx::QuickORM::Transaction;
require DBIx::QuickORM::Cache::Naive;

use DBIx::QuickORM::Util::HashBase qw{
    <name
    <db
    +connection
    +transactions
    <cache
    <schema
    +con_schema  <con_sources
    +temp_schema <temp_sources
    <autofill
    <accessor_name_cb
    <locator
    <created
    <broken_row_behavior
    <row_class
};

use Role::Tiny::With qw/with/;

# Aliases must come before 'with'
alias start_txn => 'start_transaction';
alias txn_do => 'transaction_do';
alias transactions => 'txns';

with 'DBIx::QuickORM::Role::SelectLike';
with 'DBIx::QuickORM::Role::HasORM';
with 'DBIx::QuickORM::Role::HasTransactions';

sub orm { $_[0] }

sub temp_table_supported { $_[0]->connection->temp_table_supported }
sub temp_view_supported  { $_[0]->connection->temp_view_supported }

sub init {
    my $self = shift;

    delete $self->{+NAME} unless defined $self->{+NAME};

    my $db = $self->{+DB} or croak "'db' is a required attribute";

    $self->{+AUTOFILL}     //= 1;
    $self->{+TEMP_SOURCES} //= {};
    $self->{+CON_SOURCES}  //= {};
    $self->{+CACHE}        //= DBIx::QuickORM::Cache::Naive->new();

    $self->{+BROKEN_ROW_BEHAVIOR} //= 'die';

    croak "You must either provide the 'schema' attribute or enable 'autofill'"
        unless $self->{+SCHEMA} || $self->{+AUTOFILL};

    $self->{+LOCATOR} = DBIx::QuickORM::GlobalLookup->register($self);

    $self->{+TRANSACTIONS} = [];
}

sub clone {
    my $self = shift;
    my (%params) = @_;

    my $type = blessed($self);

    for my $field (NAME(), DB(), SCHEMA(), AUTOFILL(), ACCESSOR_NAME_CB()) {
        $params{$field} //= $self->{$field};
    }

    return $type->new(%params);
}

sub con_schema {
    my $self = shift;

    return $self->{+CON_SCHEMA} if $self->{+CON_SCHEMA};

    $self->{+CON_SCHEMA} = DBIx::QuickORM::Schema->new(name => $self->{+NAME});

    if (my $schema = $self->{+SCHEMA}) {
        $self->{+CON_SCHEMA} = $self->{+CON_SCHEMA}->merge($schema);
    }

    if (my $af = $self->{+AUTOFILL}) {
        my %params;
        $params{name_cb} = $af if ref($af) eq 'CODE';
        $self->{+CON_SCHEMA} = $self->{+CON_SCHEMA}->merge($self->connection->generate_schema, %params);
    }

    $self->{+CON_SCHEMA}->compile;

    return $self->{+CON_SCHEMA};
}

sub temp_schema {
    my $self = shift;
    return $self->{+TEMP_SCHEMA} //= DBIx::QuickORM::Schema->new();
}

sub reconnect {
    my $self = shift;
    delete $self->{+CONNECTION};

    $self->{+CON_SOURCES}  = {};
    $self->{+TEMP_SOURCES} = {};

    delete $self->{+TEMP_SCHEMA};

    return $self->connection;
}

sub connection {
    my $self = shift;

    my $con = $self->{+CONNECTION};

    return $self->{+CONNECTION} = $self->{+DB}->connect
        unless $con;

    return $self->reconnect
        unless $$ == $con->pid;

    return $con;
}

sub _table {
    my $self = shift;
    my ($name) = @_;

    my ($schema, $table);

    for my $meth (qw/ temp_schema con_schema /) {
        $schema = $self->$meth()              or next;
        $table  = $schema->maybe_table($name) or next;
        return ($schema, $table);
    }

    return;
}

sub table {
    my $self = shift;
    my ($name) = @_;

    my ($schema, $table) = $self->_table($name);

    return $table;
}

sub aggregate        { my ($self, $source, @args) = @_; $self->source($source)->aggregate(@args) }
sub all              { my ($self, $source, @args) = @_; $self->source($source)->all(@args) }
sub any              { my ($self, $source, @args) = @_; $self->source($source)->any(@args) }
sub aside            { my ($self, $source, @args) = @_; $self->source($source)->aside(@args) }
sub async            { my ($self, $source, @args) = @_; $self->source($source)->async(@args) }
sub count            { my ($self, $source, @args) = @_; $self->source($source)->count(@args) }
sub find             { my ($self, $source, @args) = @_; $self->source($source)->find(@args) }
sub find_or_insert   { my ($self, $source, @args) = @_; $self->source($source)->find_or_insert(@args) }
sub first            { my ($self, $source, @args) = @_; $self->source($source)->first(@args) }
sub forked           { my ($self, $source, @args) = @_; $self->source($source)->forked(@args) }
sub insert           { my ($self, $source, @args) = @_; $self->source($source)->insert(@args) }
sub insert_row       { my ($self, $source, @args) = @_; $self->source($source)->insert_row(@args) }
sub last             { my ($self, $source, @args) = @_; $self->source($source)->last(@args) }
sub relations        { my ($self, $source, @args) = @_; $self->source($source)->relations(@args) }
sub select           { my ($self, $source, @args) = @_; $self->source($source)->select(@args) }
sub update           { my ($self, $source, @args) = @_; $self->source($source)->update(@args) }
sub update_or_insert { my ($self, $source, @args) = @_; $self->source($source)->update_or_insert(@args) }

sub shotgun { die "FIXME" }

sub source {
    my $self = shift;
    my ($name) = @_;

    croak "source() requires a table/view name" unless $name;

    return $self->{+TEMP_SOURCES}->{$name} if $self->{+TEMP_SOURCES}->{$name};
    return $self->{+CON_SOURCES}->{$name}  if $self->{+CON_SOURCES}->{$name};

    my ($schema, $table) = $self->_table($name);

    croak "'$name' is not defined in the schema as a table/view, or temporary table/view"
        unless $schema && $table;

    return $self->{+CON_SOURCES}->{$name} = DBIx::QuickORM::Source->new(
        connection => $self->connection,
        schema     => $schema,
        table      => $table,
        orm        => $self,
    );
}

sub load_schema_sql { shift->connection->load_schema_sql(@_) }

sub create_temp_table { shift->_create_temp(table => @_) }
sub create_temp_view  { shift->_create_temp(view  => @_) }

sub _create_temp {
    my $self = shift;
    my ($type, $name, %params) = @_;

    my $supported = "temp_${type}_supported";
    my $create    = "create_temp_${type}";

    my $from   = $params{from}   or croak "Must provide a 'from' source to build the $type";
    my $select = $params{select} or croak "Must provide a 'select' to build the $type";

    my $con    = $self->connection;
    my $schema = $self->temp_schema;

    croak "The current database '" . ref($self->{+DB}) . "' does not support temporary ${type}s"
        unless $con->$supported;

    croak "There is already a temporary table or view named '$name'"
        if $schema->maybe_table($name) || $self->{+TEMP_SOURCES}->{$name};

    $from = $self->source($from) unless blessed($from) && $from->isa('DBIx::QuickORM::Source');

    my ($sql, $bind) = $from->sql_for_select(@$select);

    $con->$create($name, $sql, $bind);

    my $table;
    if ($table = $params{table}) {
        if (ref($table) eq 'CODE') {
            require DBIx::QuickORM;
            $table = DBIx::QuickORM::rogue_table($name => $table);
        }

        $table = $table->merge($con->generate_table_schema($name)) if $params{autofill};
    }
    elsif ($params{autofill}) {
        $table = $con->generate_table_schema($name);
    }
    else {
        croak "Must specify either a 'table' specification, or set the `autofill => 1` parameter";
    }

    # Might get cloned and modified
    $table = $schema->add_table($name => $table);

    return $self->{+TEMP_SOURCES}->{$name} = DBIx::QuickORM::Source->new(
        connection => $con,
        schema     => $schema,
        table      => $table,
    );
}

sub drop_temp_source {
    my $self = shift;
    my ($name) = @_;

    my $source = $self->source($name) or croak "No such source '$name'";
    my $table  = $source->table;
    croak "'$name' is not temporary" unless $table->is_temp;
    $source->drop;

    delete $self->{TEMP_SOURCES}->{$name};

    return;
}

sub drop_temp_table {
    my $self = shift;
    my ($name) = @_;

    my $source = $self->source($name) or croak "No such table '$name'";
    croak "'$name' is a view, not a table" if $source->table->is_view;

    return $self->drop_temp_source($name);
}

sub drop_temp_view {
    my $self = shift;
    my ($name) = @_;

    my $source = $self->source($name) or croak "No such view '$name'";
    croak "'$name' is a view, not a table" if $source->table->is_view;

    return $self->drop_temp_source($name);
}

sub with_temp_view  { shift->_with_temp(view  => @_) }
sub with_temp_table { shift->_with_temp(table => @_) }

sub _with_temp {
    my $self = shift;
    my ($type, $name, $select, $code) = @_;

    my $create = "create_temp_$type";
    my $drop   = "drop_temp_$type";

    my $source = $self->$create($name, @$select);

    my $out;
    my $ok  = eval { $out = $code->($source); 1 };
    my $err = $@;

    $self->$drop($name);

    return $out if $ok;
    die $err;
}

sub generate_and_load_schema {
    my $self = shift;
    my $sql = $self->generate_schema_sql();
    return $self->load_schema_sql($sql);
}

sub generate_schema_sql {
    my $self = shift;
    my $con = $self->connection or die "WTF?";
    $self->{+DB}->generate_schema_sql(schema => $self->{+SCHEMA}, connection => $con, dbh => $con->dbh);
}

sub txn_do {
    my $self = shift;
    my $cb = pop;
    my $name = shift;

    my $want = wantarray;
    my @caller = caller;

    croak "txn_do takes a coderef as its final argument" unless $cb && ref($cb) eq 'CODE';

    my $txn = $self->start_txn(name => $name, caller => \@caller);

    my $out;
    my $ok = eval { $out = $cb->($txn); 1 };
    my $err = $@;

    if ($ok) {
        local $@;
        $ok &&= eval { $txn->commit; 1 };
        $err = $@;

        if ($ok) {
            return (1, $out) if $want;

            if (defined $want) {
                return $out || 1;
            }

            return;
        }
    }

    unless ($ok) {
        local $@;
        eval { $txn->rollback; 1 } or warn $@;
    }

    $txn = undef;

    return (0, $err) if $want;

    if (defined $want) {
        warn $err;
        return 0;
    }

    die $err;
}

sub start_txn {
    my $self = shift;
    my %params = @_;

    $params{caller} //= [caller];

    my $con = $self->{+CONNECTION};
    return -1 if $con->in_external_transaction;

    my $txns = $self->transactions;

    my $sp;
    if (my $depth = @$txns) {
        $sp = "SAVEPOINT" . $depth;
        $con->create_savepoint($sp);
    }
    else {
        $sp = undef;
        $con->start_txn;
    }

    my $parent = @$txns ? $txns->[-1] : undef;
    my $txn    = DBIx::QuickORM::Transaction->new(
        %params,
        connection => $con,
        savepoint  => $sp,
        parent     => $parent,
    );

    $parent->set_child($txn) if $parent;

    push @$txns => $txn;
    weaken($txns->[-1]);

    $self->{+CACHE}->new_transaction($txn);

    return $txn;
}

sub transactions {
    my $txns = $_[0]->{+TRANSACTIONS};

    # Transactions are weak refs in the array, so they may go undef on us.
    pop @$txns while @$txns && !$txns->[-1];

    return $txns;
}

1;
