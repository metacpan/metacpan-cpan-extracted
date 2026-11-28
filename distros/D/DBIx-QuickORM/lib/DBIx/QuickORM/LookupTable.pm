package DBIx::QuickORM::LookupTable;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak confess/;
use Hash::Util::FieldHash qw/fieldhash/;
use Scalar::Util qw/refaddr weaken/;

use Object::HashBase qw{
    <db_map
    <connection
    <retain
    <stack
    +marks
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::LookupTable - The canon row hash for each table and primary key.

=head1 DESCRIPTION

The lookup table maps each table and primary key to the I<canon> row hash:
the ORM's canonical copy of that row. A hash is canon when it is the same
reference as the entry the levels give for its key. Rows arrive through
C<ingest()> (reads) and C<store()> (writes), and leave through C<forget()>.

The table is a stack of levels: the outside level, plus one per open
transaction or savepoint. Writes go to the top level. Reads inside a
transaction look from the top level down to the root transaction level, never
the outside level, and stop at the first level that knows the key.
L<DBIx::QuickORM/Transactions> describes what users see.

=over 4

=item *

A root transaction pushes an empty level, so nothing from before it is canon
inside it. The outside level stays as a cache.

=item *

A savepoint pushes an empty level, so the parent's entries stay canon in it.

=item *

C<clear()> or C<forget()> inside a transaction also marks the key, the
table, or everything as cleared in its level, hiding the levels below.

=item *

A savepoint commit merges its entries and marks into its parent. A savepoint
rollback discards it, so the parent's entries are canon again.

=item *

A root commit clears what its marks name from the outside level, then merges
its entries into it, replacing those for the same keys. A root rollback
discards it.

=item *

Inside a transaction, a key that a C<store()>, a C<forget()>, or a replacing
C<ingest()> touches leaves the outside level at once. C<forget()> with no table
empties the outside level.

=item *

An C<ingest()> of a key the transaction lacks reuses the outside hash when it
agrees on every field both hold. New fields are added to it in place, and it
stays outside too, so an object holding it from before the transaction is
canon again.

=back

Fields C<ingest()> adds in place to a hash a savepoint's parent holds stay
visible to the parent after a savepoint rollback.

Outside a transaction, entries are held weakly unless C<retain> is set.
Inside one they are strong. A root commit weakens the entries it merges,
again unless C<retain> is set. A freed weak entry reads as a miss and is
deleted when met.

A primary key argument (C<$pk> below) is a hashref holding the key fields, so
row data works. Callers convert other key forms before calling, as the ORM's
key arguments do.

An untyped key field is keyed by its value as it is. A typed one is keyed by
its type's C<canonical_key_value>, so its database text, its inflated value,
and other forms of the same value all find one entry. The map's C<pk_types>
says which fields are typed.

It croaks on a table with no primary key, a missing or undef key field, and a
reference in an untyped key field.

=head2 Row state

Beside the levels, the lookup table keeps a little state for row hashes,
keyed by the hash itself (a fieldhash), never stored in it:

=over 4

=item *

C<deleted>: set by a row C<delete>, a C<delete_row>, and a refresh or find
that finds nothing in the database. A miss from the cache alone marks
nothing. A handle's bulk delete marks nothing, unless given C<mark_deleted>.

=item *

C<vivified>: the hash was built by the ORM's C<vivify>, never read from the
database, or its insert was rolled back.

=back

Each is present only when it applies. Row state follows the transaction:

=over 4

=item *

A hash marked deleted inside a transaction is unmarked when that level rolls
back, and so is every copy made of it with C<copy_row_state>.

=item *

A hash inserted inside a transaction (C<mark_inserted>) is marked vivified
when that level rolls back. A hash inserted and then deleted in it ends up
vivified too, and so does the new hash of a row inserted and then updated or
refreshed in it (C<carry_inserted>).

=back

A savepoint commit carries both lists to its parent. A root commit drops
them.

=head1 SYNOPSIS

    my $lookup = DBIx::QuickORM::LookupTable->new(
        db_map => $map,
        retain => 0,
    );

    my $canon = $lookup->ingest(
        users => {
            id   => 1,
            name => 'bob',
        },
    );
    $lookup->is_canon(users => $canon);    # true

    $lookup->begin_root;
    $lookup->push_level;
    $lookup->store(users => $new_data);
    $lookup->rollback_level;               # savepoint rollback
    $lookup->commit_level;                 # root commit

=head1 ATTRIBUTES

=over 4

=item $map = $lookup->db_map

Required: the L<DBIx::QuickORM::Map> that gives each table's primary key.

=item $conn = $lookup->connection

The L<DBIx::QuickORM::Connection> passed to C<canonical_key_value>, held
weakly. Types whose key form depends on the connection need it: the DateTime
type reads the dialect and C<time_zone> from it. A connection passes itself
when it builds its lookup table.

=item $bool = $lookup->retain

When true, entries outside a transaction are held strongly until cleared.

=item $levels = $lookup->stack

The levels, each C<< {table => {key => $row_hash}} >>. The first is the
outside level, the last is the top. Each transaction level's clear marks,
and the row hashes it marked deleted or inserted, are kept beside it,
privately.

=back

=cut

# Inside-out row state, keyed by row hash: {deleted => 1 or the hash a copy follows, vivified => 1}, each only when it applies.
fieldhash my %STATE;

sub init {
    my $self = shift;
    croak "'db_map' is required" unless $self->{+DB_MAP};
    weaken($self->{+CONNECTION}) if $self->{+CONNECTION};
    $self->{+STACK} = [{}];
    $self->{+MARKS} = [undef];
}

=head1 PUBLIC METHODS

=over 4

=item $bool = $lookup->in_txn

True while a root transaction is open.

=back

=cut

sub in_txn { @{$_[0]->{+STACK}} > 1 ? 1 : 0 }

=over 4

=item $lookup->begin_root

Starts a root transaction: pushes an empty level above the outside level.
Croaks when a transaction is already open.

=back

=cut

sub begin_root {
    my $self = shift;
    croak "A transaction is already open" if $self->in_txn;
    push @{$self->{+STACK}} => {};
    push @{$self->{+MARKS}} => undef;
}

=over 4

=item $lookup->push_level

Starts a savepoint: pushes an empty level, so its cost does not depend on the
rows held. Croaks when no transaction is open.

=back

=cut

sub push_level {
    my $self = shift;
    croak "No transaction is open" unless $self->in_txn;
    push @{$self->{+STACK}} => {};
    push @{$self->{+MARKS}} => undef;
}

=over 4

=item $lookup->commit_level

Commits the innermost savepoint, or the root transaction when no savepoint is
open. Croaks when no transaction is open.

A savepoint commit merges its entries and marks into its parent, at a cost
that grows with the keys it touched. A root commit clears what its marks name
from the outside level, then merges its entries into it, weakened unless
C<retain>.

=back

=cut

sub commit_level {
    my $self  = shift;
    my $stack = $self->{+STACK};
    croak "No transaction is open" unless $self->in_txn;
    my $child = pop @$stack;
    my $mark  = pop @{$self->{+MARKS}};
    return $self->_merge($child, $mark) if @$stack > 1;

    my $outside = $stack->[0];
    $self->_apply_marks($outside, $mark) if $mark;
    for my $table (keys %$child) {
        my $rows = $outside->{$table} //= {};
        for my $key (keys %{$child->{$table}}) {
            $rows->{$key} = $child->{$table}->{$key};
            weaken($rows->{$key}) unless $self->{+RETAIN};
        }
    }
    return;
}

=over 4

=item $lookup->rollback_level

Rolls back the innermost savepoint, or the root transaction when no savepoint
is open: discards the top level, unmarks the hashes it marked deleted, then
marks the hashes it inserted vivified. Croaks when no transaction is open.

=back

=cut

sub rollback_level {
    my $self = shift;
    croak "No transaction is open" unless $self->in_txn;
    pop @{$self->{+STACK}};
    my $mark = pop @{$self->{+MARKS}} or return;
    for my $data (@{$mark->{deleted} // []}) {
        delete $STATE{$data}->{deleted};
        delete $STATE{$data} unless %{$STATE{$data}};
    }
    $STATE{$_}->{vivified} = 1 for values %{$mark->{inserted} // {}};
    return;
}

=over 4

=item $bool = $lookup->is_canon($table, \%row_data)

True when the hash is the entry for its primary key. False when it is not, or
no entry exists.

=back

=cut

sub is_canon {
    my $self = shift;
    my ($table, $data) = @_;
    my $canon = $self->lookup($table, $data) or return 0;
    return $canon == $data ? 1 : 0;
}

=over 4

=item $row_data = $lookup->lookup($table, $pk)

The canon hash for C<$pk>, or undef.

=back

=cut

sub lookup {
    my $self = shift;
    my ($table, $pk) = @_;
    return $self->_find($table, $self->_key($table, $pk));
}

=over 4

=item $row_data = $lookup->ingest($table, \%row_data)

Takes in a row read from the database and returns the canon hash.

When an entry exists and agrees on every field both hashes hold (NULL and
missing differ), new fields are added to it and it is returned. Otherwise the
given hash becomes the entry and is returned.

Inside a transaction, a key no transaction level holds is compared the same
way with the outside level's entry, which is reused in the top level when it
agrees.

=back

=cut

sub ingest {
    my $self = shift;
    my ($table, $data) = @_;
    my $key = $self->_key($table, $data);

    my $canon = $self->_find($table, $key);
    my $reuse = !$canon && @{$self->{+STACK}} > 1 && ($canon = $self->_get(0, $table, $key));
    return $self->_store($table, $data, $key) unless $canon;

    my @new;
    for my $field (keys %$data) {
        if (exists $canon->{$field}) {
            next unless $self->differ($canon->{$field}, $data->{$field});
            return $self->_store($table, $data, $key);
        }
        push @new => $field;
    }

    $canon->{$_} = $data->{$_} for @new;
    $self->{+STACK}->[-1]->{$table}->{$key} = $canon if $reuse;
    return $canon;
}

=over 4

=item $bool = DBIx::QuickORM::LookupTable->differ($old, $new)

True when two raw field values differ: they compare unequal as strings, or
one is NULL (undef) and the other is not. NULL equals only NULL.

C<ingest> uses it to tell whether a row read from the database changed, and a
row uses it to decide which inflated values to keep when its row data is
replaced. It may be called on the class or on an instance.

=back

=cut

sub differ {
    shift;
    my ($x, $y) = @_;
    return 0 if !defined($x) && !defined($y);
    return 1 if !defined($x) || !defined($y);
    return $x eq $y ? 0 : 1;
}

=over 4

=item $row_data = $lookup->store($table, \%row_data)

Makes the hash the entry for its primary key, replacing any other, and returns
it. This is the write path.

Inside a transaction the key is removed from the outside level. To re-key
after a primary key change, C<forget> the old key first.

=back

=cut

sub store {
    my $self = shift;
    my ($table, $data) = @_;
    return $self->_store($table, $data, $self->_key($table, $data));
}

=over 4

=item $lookup->clear

=item $lookup->clear($table)

=item $lookup->clear($table, $pk)

Clears everything, one table, or one row from the top level only. Inside a
transaction it also marks them as cleared there, so the levels below no longer
show them. A savepoint rollback brings them back. A root commit clears them
from the outside level, and a root rollback leaves the outside level as it
was.

=back

=cut

sub clear {
    my $self = shift;
    my ($table, $pk) = @_;
    my $stack = $self->{+STACK};
    my $top   = $stack->[-1];

    # Inside a transaction a mark hides the same from the levels below, and a root commit applies it outside.
    my $mark = @$stack > 1 ? ($self->{+MARKS}->[-1] //= {}) : undef;
    if (!defined $table) {
        $stack->[-1] = {};
        $mark->{all} = 1 if $mark;
    }
    elsif (@_ < 2) {
        delete $top->{$table};
        $mark->{tables}->{$table} = 1 if $mark;
    }
    else {
        my $key = $self->_key($table, $pk);
        delete $top->{$table}->{$key};
        $mark->{keys}->{$table}->{$key} = 1 if $mark;
    }
    return;
}

=over 4

=item $lookup->forget

=item $lookup->forget($table)

=item $lookup->forget($table, $pk)

What C<clear> does, and inside a transaction the same from the outside level.
A root commit then merges what the transaction holds at that point (rows
read or written again after the forget). A root rollback brings back nothing.

This is how C<clear_cache>, a delete, a primary key change, a row found gone,
or a bulk update or delete drops entries.

=back

=cut

sub forget {
    my $self = shift;
    my ($table, @pk) = @_;
    $self->clear(@_);
    $self->_touch($table, @pk ? $self->_key($table, $pk[0]) : ());
    return;
}

=over 4

=item $state = DBIx::QuickORM::LookupTable->row_state(\%row_data)

C<'deleted'>, C<'vivified'>, or undef for a hash with neither mark (see
L</Row state>). It may be called on the class or on an instance.

=back

=cut

sub row_state {
    my $state = $STATE{$_[1]} or return undef;
    my $del   = $state->{deleted};
    return $_[0]->row_state($del) if ref $del;    # a copy follows the hash it was copied from
    return $del ? 'deleted' : $state->{vivified} ? 'vivified' : undef;
}

=over 4

=item DBIx::QuickORM::LookupTable->mark_vivified(\%row_data)

Marks a hash vivified (built by C<vivify>). No rollback undoes it.

=back

=cut

sub mark_vivified { $STATE{$_[1]}->{vivified} = 1; return }

=over 4

=item DBIx::QuickORM::LookupTable->copy_row_state(\%from, \%to)

Gives a copy of a row hash the original's state. A deleted copy follows the
hash first marked deleted, so a rollback that unmarks that hash unmarks the
copy too. It may be called on the class or on an instance.

=back

=cut

sub copy_row_state {
    my (undef, $from, $to) = @_;
    my $state = $STATE{$from} or return;
    $STATE{$to}->{vivified} = 1                                                  if $state->{vivified};
    $STATE{$to}->{deleted}  = ref($state->{deleted}) ? $state->{deleted} : $from if $state->{deleted};
    return;
}

=over 4

=item $lookup->mark_deleted(@row_data)

Marks each hash deleted, unless it already reads as deleted. Inside a
transaction the top level records the hashes it newly marked, so rolling that
level back unmarks them.

A copy that follows a hash a rollback unmarked is marked in its own right.

=back

=cut

sub mark_deleted {
    my $self  = shift;
    my $level = $self->in_txn ? ($self->{+MARKS}->[-1] //= {}) : undef;
    for my $data (@_) {
        next if ($self->row_state($data) // '') eq 'deleted';
        $STATE{$data}->{deleted} = 1;    # also replaces a copy's stale follow of an unmarked hash
        push @{$level->{deleted}} => $data if $level;
    }
    return;
}

=over 4

=item $lookup->mark_inserted(@row_data)

Records each hash as inserted in the top level, so rolling that level back
marks it vivified. Does nothing outside a transaction.

=back

=cut

sub mark_inserted {
    my $self = shift;
    return unless $self->in_txn;
    my $set = ($self->{+MARKS}->[-1] //= {})->{inserted} //= {};
    $set->{refaddr($_)} = $_ for @_;
    return;
}

=over 4

=item $lookup->carry_inserted(\%old, \%new)

For a write or refresh that gave a row new row data: when an open level
recorded the old hash as inserted, it records the new one too, so a rollback
of that level marks both vivified. Does nothing outside a transaction.

=back

=cut

sub carry_inserted {
    my $self = shift;
    my ($old, $new) = @_;
    return unless $self->in_txn && $new && $old != $new;
    my $id = refaddr($old);
    for my $mark (@{$self->{+MARKS}}) {
        my $set = $mark && $mark->{inserted} or next;
        $set->{refaddr($new)} = $new if $set->{$id};
    }
    return;
}

=over 4

=item $lookup->gone($table, \%key, \%row_data)

Forgets a row the database no longer has and marks its entry, and the row
data when given, deleted.

Inside a transaction the outside level's entry is marked too, and a rollback
unmarks it.

=back

=cut

sub gone {
    my $self = shift;
    my ($table, $key, $data) = @_;
    my $canon = $self->lookup($table, $key);

    # A lookup inside a transaction never reads the outside level, so its held hash is fetched directly before forget drops it.
    my $outside = $self->in_txn ? $self->_get(0, $table, $self->_key($table, $key)) : undef;

    $self->forget($table, $key);
    $self->mark_deleted(grep { $_ } $data, $canon, $outside);
}

=over 4

=item $lookup->clear_txn_levels

Empties every level above the outside level, keeping the number of levels.

For a transaction whose outcome is unknown, after which no row held from
inside it can be trusted. The outside level is kept: keys the transaction
touched are already gone from it.

=back

=cut

sub clear_txn_levels {
    my $self  = shift;
    my $stack = $self->{+STACK};
    $_ = {}    for @$stack[1 .. $#$stack];
    $_ = undef for @{$self->{+MARKS}}[1 .. $#$stack];
    return;
}

=head1 PRIVATE METHODS

=over 4

=item $key = $lookup->_key($table, \%pk)

The key string for the key fields in the hash, typed fields through their
type's C<canonical_key_value>. Croaks as the DESCRIPTION says.

=back

=cut

sub _key {
    my $self = shift;
    my ($table, $pk) = @_;

    my $map    = $self->{+DB_MAP};
    my $t      = $map->table($table) || $map->pk($table);    # pk() croaks for a table not in the map
    my $fields = $t->{pk};
    confess "The table '$table' has no primary key" unless $fields && @$fields;
    my $types = $t->{pk_types};

    # The common case: one untyped key field, keyed by its value.
    if (@$fields == 1 && !$types) {
        my $v = $pk->{$fields->[0]} // confess "The primary key field '$fields->[0]' of the table '$table' is missing or undefined";
        confess "The primary key field '$fields->[0]' of the table '$table' has no type, so its value cannot be a reference" if ref $v;
        return "$v";
    }

    my @vals = map { $pk->{$_} // confess "The primary key field '$_' of the table '$table' is missing or undefined" } @$fields;
    for my $i (0 .. $#vals) {
        my $type = $types && $types->[$i];
        if    ($type)         { $vals[$i] = $type->canonical_key_value($vals[$i], $map->field($table, $fields->[$i]), $self->{+CONNECTION}) }
        elsif (ref $vals[$i]) { confess "The primary key field '$fields->[$i]' of the table '$table' has no type, so its value cannot be a reference" }
    }

    return "$vals[0]" if @vals == 1;
    return join '' => map { length($_) . ':' . $_ } @vals;
}

=over 4

=item $row_data = $lookup->_store($table, \%row_data, $key)

C<store> with the key string already built, so C<ingest> builds it once.

=back

=cut

sub _store {
    my $self = shift;
    my ($table, $data, $key) = @_;
    my $stack = $self->{+STACK};
    $stack->[-1]->{$table}->{$key} = $data;

    if (@$stack > 1) {
        my $outside = $stack->[0]->{$table};
        delete $outside->{$key} if $outside;
    }
    elsif (!$self->{+RETAIN}) {
        weaken($stack->[-1]->{$table}->{$key});
    }

    return $data;
}

=over 4

=item $row_data = $lookup->_find($table, $key)

The canon hash for the key string, or undef. Outside a transaction it is the
outside level's entry. Inside one, the levels are read from the top down to
the root transaction level, never the outside level. The first level that
holds the key, or marks it, its table, or everything as cleared, decides.

=back

=cut

sub _find {
    my $self = shift;
    my ($table, $key) = @_;
    my $stack = $self->{+STACK};
    return $self->_get(0, $table, $key) unless @$stack > 1;

    my $marks = $self->{+MARKS};
    for (my $i = $#$stack; $i > 0; $i--) {
        my $rows = $stack->[$i]->{$table};
        return $rows->{$key} if $rows && exists $rows->{$key};
        my $mark = $marks->[$i] or next;
        my $keys = $mark->{keys} && $mark->{keys}->{$table};
        return undef if $mark->{all} || ($mark->{tables} && $mark->{tables}->{$table}) || ($keys && $keys->{$key});
    }
    return undef;
}

=over 4

=item $lookup->_merge(\%child, \%mark)

A savepoint commit: applies the popped level's marks to its parent with
C<_apply_marks>, carrying them and its deleted and inserted hashes into the
parent's marks, then copies the popped level's entries into the parent.

=back

=cut

sub _merge {
    my $self = shift;
    my ($child, $mark) = @_;
    my $parent = $self->{+STACK}->[-1];

    if ($mark) {
        my $into = $self->{+MARKS}->[-1] //= {};
        $self->_apply_marks($parent, $mark, $into);
        push @{$into->{deleted}} => @{$mark->{deleted}} if $mark->{deleted};
        $into->{inserted}->{refaddr($_)} = $_ for values %{$mark->{inserted} // {}};
    }

    for my $table (keys %$child) {
        my $rows = $parent->{$table} //= {};
        $rows->{$_} = $child->{$table}->{$_} for keys %{$child->{$table}};
    }
    return;
}

=pod

=over 4

=item $lookup->_apply_marks(\%level, \%mark)

=item $lookup->_apply_marks(\%level, \%mark, \%into)

Clears what the marks name (everything, tables, keys) from the level, and
adds them to the C<\%into> marks when given.

=back

=cut

sub _apply_marks {
    my $self = shift;
    my ($level, $mark, $into) = @_;

    if ($mark->{all}) {
        %$level = ();
        $into->{all} = 1 if $into;
    }
    for my $table (keys %{$mark->{tables} // {}}) {
        delete $level->{$table};
        $into->{tables}->{$table} = 1 if $into;
    }
    my $keys = $mark->{keys} // {};
    for my $table (keys %$keys) {
        for my $key (keys %{$keys->{$table}}) {
            delete $level->{$table}->{$key}     if $level->{$table};
            $into->{keys}->{$table}->{$key} = 1 if $into;
        }
    }
    return;
}

=over 4

=item $row_data = $lookup->_get($index, $table, $key)

The entry for the key string in the level at C<$index> of the stack, or undef.
A freed weak entry is deleted.

=back

=cut

sub _get {
    my $self = shift;
    my ($index, $table, $key) = @_;
    my $rows = $self->{+STACK}->[$index]->{$table} or return undef;
    return undef unless exists $rows->{$key};
    return $rows->{$key} // delete $rows->{$key};
}

=over 4

=item $lookup->_touch

=item $lookup->_touch($table)

=item $lookup->_touch($table, $key)

Inside a transaction, removes everything, the table, or the key string from
the outside level.

=back

=cut

sub _touch {
    my $self = shift;
    my ($table, @key) = @_;
    my $stack = $self->{+STACK};
    return unless @$stack > 1;
    if (!defined $table) { $stack->[0] = {}; return }
    my $rows = $stack->[0]->{$table} or return;
    if   (@key) { delete $rows->{$key[0]} }
    else        { delete $stack->[0]->{$table} }
    return;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
