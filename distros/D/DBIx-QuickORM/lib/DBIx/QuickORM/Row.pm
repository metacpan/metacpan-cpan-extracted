package DBIx::QuickORM::Row;
use strict;
use warnings;

our $VERSION = '0.000002';

use Carp qw/croak confess carp longmess/;
use Scalar::Util qw/weaken blessed refaddr readonly reftype/;
use Hash::Util qw/hashref_locked/;

use DBIx::QuickORM::Util qw/parse_hash_arg mask unmask masked equ/;

BEGIN {
    require DBIx::QuickORM::Transaction;
    *FINALIZED = \&DBIx::QuickORM::Transaction::FINALIZED;
    *PARENT    = \&DBIx::QuickORM::Transaction::PARENT;
}

use DBIx::QuickORM::Util::HashBase qw{
    +stored +dirty +inflated
    +transaction

    <uncached +tainted +invalid

    +when_broken

    +source
    +table
    +table_name
    <fetched_relations

    debug_uncache
};

sub init {
    my $self = shift;

    my $source = delete $self->{+SOURCE} or croak "'source' is a required attribute";
    croak "'source' must be an instance of 'DBIx::QuickORM::Source'" unless $source->isa('DBIx::QuickORM::Source');

    $source = mask($source, weaken => 1) if blessed($source) && !masked($source);
    $self->{+SOURCE} = $source;

    $self->set_when_broken($self->{+WHEN_BROKEN} // $self->orm->broken_row_behavior)
        unless $self->{+WHEN_BROKEN} && ref($self->{+WHEN_BROKEN}) eq 'HASH';

    my $fdb = $self->{+STORED};
    my $dty = $self->{+DIRTY};

    croak "Cannot have references in the stored data" if $fdb && grep { ref($_) } values %$fdb;
    croak "Cannot have references in the dirty data"  if $dty && grep { ref($_) } values %$dty;

    return $self;
}

sub real_source  { unmask($_[0]->source) }
sub insert       { $_[0]->source->insert_row($_[0]) }
sub connection   { $_[0]->source->connection }
sub db           { $_[0]->source->connection->db }
sub orm          { $_[0]->source->orm }
sub table        { $_[0]->{+TABLE} // $_[0]->source->table }
sub table_name   { $_[0]->{+TABLE_NAME} //= $_[0]->table->name }
sub column_def   { $_[0]->table->column($_[1]) }
sub relation_def { $_[0]->table->relation($_[1]) }
sub column_type  { $_[0]->{+SOURCE}->connection->column_type($_[0]->{+SOURCE}->table_name, $_[1]) }
sub has_relation { $_[0]->relation_def($_[1]) ? 1 : 0 }

sub is_broken       { $_[0]->broken                            ? 1 : 0 }
sub is_stored       { $_[0]->verify_row; $_[0]->{+STORED}     ? 1 : 0 }
sub has_transaction { $_[0]->verify_row; $_[0]->{+TRANSACTION} ? 1 : 0 }

sub stored   { shift->verify_row->_verify_column(0, @_)->_stored(@_) }
sub dirty    { shift->verify_row->_verify_column(0, @_)->_dirty(@_) }
sub inflated { shift->verify_row->_verify_column(0, @_)->_inflated(@_) }

sub stored_column   { shift->verify_row->_verify_column(1, @_)->_stored(@_) }
sub dirty_column    { shift->verify_row->_verify_column(1, @_)->_dirty(@_) }
sub inflated_column { shift->verify_row->_verify_column(1, @_)->_inflated(@_) }
sub raw_column      { shift->verify_row->_verify_column(1, @_)->_raw(@_) }

sub column { shift->verify_row->_verify_column(1, @_)->_column(@_) }

sub _stored { my $s = $_[0]->{+STORED}; $s ? ($_[1] ? $s->{$_[1]} : {%$s}) : undef }

sub _raw { $_[0]->_dirty($_[1]) // $_[0]->_stored($_[1]) // undef }
sub _reverse_raw { $_[0]->_stored($_[1]) // $_[0]->_dirty($_[1]) // undef }

sub tainted { return unless $_[0]->{+TAINTED}; keys %{$_[0]->{+TAINTED}} }

sub invalid { @{$_[0]->{+INVALID} // []} }
sub set_invalid { push @{$_[0]->{+INVALID} //= []} => $_[1] }

sub has_column {
    my $self = shift;
    my ($name) = @_;

    return 1 if $self->{+STORED} && exists($self->{+STORED}->{$name});
    return 1 if $self->{+DIRTY}   && exists($self->{+DIRTY}->{$name});

    return $self->column_def($name) ? 1 : 0;
}

sub is_dirty {
    my $self = shift;
    $self->verify_row;

    my $dirty = $self->{+DIRTY};
    my $stored = $self->{+STORED};

    # Make sure no inflated objects have been modified
    if (my $inf = $self->{+INFLATED}) {
        my $table = $self->table;

        for my $col (keys %$inf) {
            next if $dirty && exists $dirty->{$col}; # We already know the column is dirty
            next unless $stored; # Nothing to verify

            my $val = $inf->{$col};
            next if readonly($val);

            my $ref = reftype($val) or next;    # If it is not a reference it has probably not mutated
            next if blessed($val) && $val->can('qorm_immutible') && $val->qorm_immutible;

            if    ($ref eq 'HASH')   { next if hashref_locked($val) || readonly(%$val) }
            elsif ($ref eq 'ARRAY')  { next if readonly(@$val) }
            elsif ($ref eq 'SCALAR') { next if readonly($$val) }
            elsif ($ref eq 'CODE')   { next if readonly(&$val) }

            # *sigh* fine, check for mutation

            my $def  = $self->column_def($col) or die "Inflated column '$col' has no definition";
            my $conf = $def->conflate          or die "Inflated column '$col' has no conflator";
            my $raw = $conf->qorm_deflate(column => $def, value => $val, type => $self->column_type($col));

            my $type = $table->columns->{$col}->compare_type($self->column_type($col));

            # deflated value matches what is in the db
            next if equ($raw, $stored->{$col}, $type);

            $dirty //= $self->{+DIRTY} //= {};
            $dirty->{$col} = $raw;
        }
    }

    return 1 if $self->{+DIRTY};
    return 0;
}

sub _dirty {
    my $self = shift;
    my ($col) = @_;

    return unless $self->is_dirty;

    return { %{$self->{+DIRTY}} } unless @_;

    return $self->{+DIRTY}->{$col};
}

sub _inflated {
    my $self = shift;
    my ($col) = @_;

    return {%{$self->{+INFLATED}}} unless $col;

    return $self->{+INFLATED}->{$col} if $self->{+INFLATED} && exists $self->{+INFLATED}->{$col};

    my $def  = $self->column_def($col) or return undef;
    my $conf = $def->conflate          or return undef;

    my $raw = $self->_raw($col);
    my $inf = $conf->qorm_inflate(column => $def, value => $raw, type => $self->column_type($col));

    $self->{+INFLATED} //= {};
    return $self->{+INFLATED}->{$col} = $inf;
}

sub stored_primary_key {
    my $self = shift;

    return unless $self->{+STORED};

    my $pk_fields = $self->{+SOURCE}->table->primary_key;
    return { map {($_ => $self->{+STORED}->{$_})} @$pk_fields };
}

sub dirty_primary_key {
    my $self = shift;

    my $dirty = $self->{+DIRTY} // {};

    my $pk_fields = $self->{+SOURCE}->table->primary_key;
    return { map {($_ => $dirty->{$_} // $self->{+STORED}->{$_})} @$pk_fields };
}

sub source {
    my $self = shift;

    if ($self->{+UNCACHED}) {
        my $msg = "This row has been 'uncached' and can no longer interact with the database. You need to fetch a new copy of the row from the database";

        if (my $debug = $self->{+DEBUG_UNCACHE}) {
            confess "$msg.\nStack trace taken during uncache operation:\n====\n$debug\n====\n";
        }

        croak $msg;
    }

    $self->verify_row;

    my $source = $self->{+SOURCE} or croak "The row has no source!";
    return $source if blessed($source) && $source->isa('DBIx::QuickORM::Source');

    confess($source->{error}) if ref($source) eq 'HASH' && $source->{error};

    require Data::Dumper;
    confess "Something is wrong with the source: " . Data::Dumper::Dumper($source);
}

sub _column {
    my $self = shift;
    my ($col, $val, $inf) = @_;

    if (@_ > 1) {
        my $def = $self->column_def($col);

        unless ($inf) {
            if (my $conf = $def->conflate) {
                $inf = $conf->qorm_inflate(column => $def, value => $val, type => $self->column_type($col));
            }
        }

        $self->set_column($col, $val, $inf);
    }

    return $self->_inflated($col) // $self->_raw($col) // undef;
}

sub _verify_column {
    my $self = shift;
    return $self unless $_[0] or @_ > 1;

    # We already checked required above
    my ($required, $col) = @_;

    my $def = defined($col);

    croak "A column name is required" unless $def;

    return $self if $self->has_column($col);

    croak "This row has no column named '$col'";
}

sub transaction_ok {
    my $self = shift;

    my $out = 1;

    my $txn = $self->{+TRANSACTION} or return $out;

    while ($txn) {
        if (defined $txn->{+FINALIZED}) { # Undefined means txn is still open
            $out &&= $txn->{+FINALIZED}; # Rollback or similar if this is false
            last unless $out;
        }

        $txn = $txn->{+PARENT};
    }

    # Next time we only start looking at the higher txn, and if this is undef
    # then no relevent txn is open.
    $self->{+TRANSACTION} = $txn;

    return $out;
}

sub when_broken {
    my $self = shift;

    $self->set_when_broken($self->orm->broken_row_behavior) unless $self->{+WHEN_BROKEN};
    my $set = $self->{+WHEN_BROKEN};

    return $set->{custom} if $set->{custom};
    return 'die'          if $set->{die};

    return 'warn'         if $set->{warn};
    return 'reload'       if $set->{reload};
    return 'ignore'       if $set->{ignore};

    return 'die';
}

my %VALID_BROKEN_ACTIONS = (
    die    => 'die',
    warn   => 'warn',
    reload => 'reload',
    ignore => 'ignore',
);

sub set_when_broken {
    my $self = shift;
    my ($action) = @_;

    return $self->{+WHEN_BROKEN} = {custom  => $action} if ref($action) eq 'CODE';
    return $self->{+WHEN_BROKEN} = {$action => $action} if $VALID_BROKEN_ACTIONS{$action};

    croak "'$action' is not a valid 'when_broken' action";
}

sub broken {
    my $self = shift;

    my $set = $self->{+WHEN_BROKEN} // $self->when_broken;
    return () if $set->{ignore};

    my @out;

    push @out => "This row was removed from the cache and is no longer managed by DBIx::QuickORM"
        if $self->{+UNCACHED};

    if (my $invalid = $self->{+INVALID}) {
        push @out => "This row instance was marked invalid (use reload() to fix this): $_" for @$invalid;
    }

    if (my $tainted = $self->{+TAINTED}) {
        push @out => "The following fields were modified locally, but the database row has changed since they were altered (use discard() or reload() to fix this): " . join(', ' => sort keys %$tainted);
    }

    push @out => "This row needs to be reload after a failed or aborted transaction, please call refresh() or reload() to fix it"
        unless $self->transaction_ok;

    return @out;
}

sub verify_row {
    my $self = shift;

    my $set = $self->{+WHEN_BROKEN} //= {die => 'die'};

    unless ($set->{ignore}) {
        my @broken = $self->broken;
        return $self unless @broken;

        carp(join "\n" => @broken)  if $set->{warn};
        croak(join "\n" => @broken) if $set->{die};
        $set->{custom}->($self)     if $set->{custom};
        $self->reload               if $set->{reload};
    }

    # Do not clear 'uncached'

    # Unless something above died, we want to clear the state that indicates things are broken
    delete @{$self}{INVALID(), TAINTED()};

    # Clear any transactions that have closed without commit
    delete $self->{+TRANSACTION} if $self->{+TRANSACTION} && defined($self->{+TRANSACTION}->{+FINALIZED}) && !$self->{+TRANSACTION}->{+FINALIZED};

    return $self;
}

sub uncache {
    my $self = shift;

    return if $self->{+UNCACHED};

    $self->{+DEBUG_UNCACHE} = longmess() if $self->{+DEBUG_UNCACHE};

    # Usually an issue during global deconstruction
    my $source = $self->{+SOURCE}                  or return $self->{+UNCACHED} = 1;
    my $orm    = $source->orm                      or return $self->{+UNCACHED} = 1;
    my $cache  = $orm->cache                       or return $self->{+UNCACHED} = 1;
    my $table  = $self->{+TABLE} // $source->table or return $self->{+UNCACHED} = 1;

    $self->{+TABLE_NAME} //= $table->name;

    $cache->uncache_source_row($source, $self);

    delete $self->{+SOURCE};
    delete $self->{+FETCHED_RELATIONS};

    if (my $fdb = delete $self->{+STORED}) {
        my $dirty = $self->{+DIRTY} //= {};
        %$dirty = (%$fdb, %$dirty);
    }

    $self->{+UNCACHED} = 1;

    return $self;
}

sub _update_fetched_relations {
    my $self = shift;
    my ($relations) = @_;

    $self->{+FETCHED_RELATIONS} = { %{$self->{+FETCHED_RELATIONS} // {}}, %$relations };
}

sub relation {
    my $self = shift;
    my ($name, %params) = @_;

    $self->verify_row;

    my $rel = $self->table->relation($name) or croak "'$name' is not a relation on this rows table (" . $self->table_name . ")";
    croak "Relation '$name' can return multiple items, use \$row->relations('$name') instead" unless $rel->gets_one;
    croak "order_by is not supported in relation()" if $params{order_by};

    return $self->{+FETCHED_RELATIONS}->{$name} if $self->{+FETCHED_RELATIONS}->{$name};

    my $source = $self->orm->source($rel->table);

    my $on = $rel->on;
    my %query = map {("me.$on->{$_}" => $self->_raw($_))} keys %$on;

    my $row = $source->find(%query) or return undef;

    return $self->{+FETCHED_RELATIONS}->{$name} = $row;
}

sub relations {
    my $self = shift;
    my ($name, %params) = @_;

    $self->verify_row;

    my $rel = $self->table->relation($name) or croak "'$name' is not a relation on this rows table (" . $self->table_name . ")";
    croak "Relation '$name' returns a single row, use \$row->relation('$name') instead" unless $rel->gets_many;

    my $source = $self->orm->source($rel->table);

    my $on = $rel->on;
    my %query = map {("me.$on->{$_}" => $self->_raw($_))} keys %$on;

    return $source->select(
        where => \%query,
        map { $params{$_} ? ($_ => $params{$_}) : () } qw/order_by limit prefetch/,
    );
}

sub set_column {
    my $self = shift;
    my ($name, $raw, $inf) = @_;

    $self->verify_row;

    my $dirty = $self->{+DIRTY} //= {};
    $dirty->{$name} = $raw;

    my $inf_hash = $self->{+INFLATED};

    if ($inf) {
        $inf_hash //= {};
        $inf_hash->{$name} = $inf;
        $self->{+INFLATED} //= $inf_hash;
    }
    elsif ($inf_hash) {
        delete $inf_hash->{$name};
        delete $self->{+INFLATED} unless keys %$inf_hash;
    }

    return $self;
}

sub unset_column {
    my $self = shift;
    my ($name) = @_;

    $self->verify_row;

    my $dirty = $self->{+DIRTY} //= {};
    $dirty->{$name} = undef;

    if (my $inf = $self->{+INFLATED}) {
        delete $inf->{$name};
        delete $self->{+INFLATED} unless keys %$inf;
    }

    return $self;
}

# Pull new data from the db, also reset transacton
sub refresh {
    my $self = shift;
    my ($new_data, $txn, %params) = @_;

    delete $self->{+TRANSACTION};

    my $table = $self->table;

    unless ($new_data) {
        my $source = $self->source;
        $new_data //= $source->fetch($self->stored_primary_key);
        $txn = $source->orm->transaction;
    }

    $self->{+STORED} = delete $self->{+DIRTY} // {}
        if $params{insert};

    my $inf  = $self->{+INFLATED};
    my $drt  = $self->{+DIRTY} // {};
    my $data = $self->{+STORED} //= {};

    for my $col (keys %$new_data) {
        my $type = $table->columns->{$col}->compare_type($self->column_type($col));
        next if equ($data->{$col}, $new_data->{$col}, $type);
        $data->{$col} = $new_data->{$col};

        if (exists $drt->{$col}) {
            $self->{+TAINTED}->{$col} = 1;
        }
        else {
            delete $inf->{$col} if $inf;
        }
    }

    $self->{+TRANSACTION} = $txn->for_row() if $txn;

    return $self;
}

# Remove 'dirty' data and taint
sub discard {
    my $self = shift;
    my ($col) = @_;

    if ($col) {
        if (my $dirty = $self->{+DIRTY}) {
            delete $dirty->{$col};
            delete $self->{+DIRTY} unless keys %$dirty;
        }

        if (my $taint = $self->{+TAINTED}) {
            delete $taint->{$col};
            delete $self->{+TAINTED} unless keys %$taint;
        }

        if (my $inf = $self->{+INFLATED}) {
            delete $inf->{$col};
            delete $self->{+INFLATED} unless keys %$inf;
        }
    }
    else {
        my $dirty = delete $self->{+DIRTY};
        delete $self->{+TAINTED};

        return $self unless $dirty;
        my $inf = $self->{+INFLATED} or return $self;

        delete $inf->{$_} for keys %$dirty;
        delete $self->{+INFLATED} unless keys %$inf;
    }

    return $self;
}

# discard+refresh+clear invalid
sub reload {
    my $self = shift;

    $self->discard;
    $self->refresh;

    delete $self->{+INVALID};

    return $self;
}

sub save {
    my $self = shift;

    $self->verify_row;

    return $self->update if $self->{+STORED};
    return $self->insert;
}

sub update {
    my $self = shift;
    my $row_data = $self->parse_hash_arg(@_);

    $self->verify_row;

    croak "Object is not yet in the database, use insert or save" unless $self->{+STORED};

    my $source = $self->real_source;
    my $orm = $source->orm;
    my $cache = $orm->cache;

    $row_data = $source->deflate_row_data(%{$self->{+DIRTY} // {}}, %$row_data);

    my $stored_primary_key = $self->stored_primary_key;
    my $dirty_primary_key  = $self->dirty_primary_key;

    my $table  = $source->table;
    my $tname  = $self->table_name;
    my @cols   = $table->column_names;
    my $con    = $source->connection;
    my $ret    = $con->db->update_returning_supported;

    my ($stmt, @bind) = $con->sqla->update($tname, $row_data, $stored_primary_key, $ret ? {returning => \@cols} : ());

    my $dbh = $con->dbh;
    my $sth = $dbh->prepare($stmt);
    $sth->execute(@bind);

    my $new_data;
    if ($ret) {
        $new_data = $sth->fetchrow_hashref;
    }
    else {
        # An update could theoretically update the primary key values, so get
        # new ones
        my ($stmt, $bind) = $source->build_select_sql($tname, \@cols, $dirty_primary_key);
        my $sth = $dbh->prepare($stmt);
        $sth->execute(@$bind);
        $new_data = $sth->fetchrow_hashref;
    }

    delete $self->{+TAINTED};
    delete $self->{+DIRTY};
    %{$self->{+STORED} //= {}} = (%{$self->{+STORED} //= {}}, %$new_data );

    my $old_cache_key = $cache->cache_key($source, $stored_primary_key);
    my $new_cache_key = $cache->cache_key($source, $dirty_primary_key);

    $old_cache_key = $old_cache_key ? join(';' => @$old_cache_key) : "";
    $new_cache_key = $new_cache_key ? join(':' => @$new_cache_key) : "";

    if ($old_cache_key ne $new_cache_key) {
        $cache->remove_source_item($source, $stored_primary_key);
        $cache->add_source_row($source, $self);
    }

    return $self;
}

sub delete {
    my $self = shift;

    $self->verify_row;

    croak "Object is not yet in the database, use insert or save" unless $self->{+STORED};

    my $primary_key = $self->stored_primary_key;

    my $source = $self->real_source;
    my $table  = $source->table;
    my $tname  = $table->name;
    my @cols   = $table->column_names;
    my $con    = $source->connection;

    my ($stmt, @bind) = $con->sqla->delete($tname, $primary_key);

    my $dbh = $con->dbh;
    my $sth = $dbh->prepare($stmt);
    $sth->execute(@bind);

    $self->uncache;

    # This is fine because it may not be in cache, but it is also not in the database
    delete $self->{+UNCACHED};

    return $self;
}

1;
