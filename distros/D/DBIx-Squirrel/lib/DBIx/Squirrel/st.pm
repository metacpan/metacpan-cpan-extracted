use v5.36;

package DBIx::Squirrel::st;

use DBI        qw();
use List::Util qw(max pairs);
use Ref::Util  qw(
    is_arrayref is_coderef is_plain_arrayref is_plain_hashref
    is_ref);

use DBIx::Squirrel::Errors       qw(at_caller croakf);
use DBIx::Squirrel::Iterator     qw();
use DBIx::Squirrel::Placeholders qw(
    is_numbered key_of place_values values_taken
);
use DBIx::Squirrel::Results qw();
use Ekorn::Pipeline::Pipes  qw();
use DBIx::Squirrel::Util    qw(unwrap_values);

use namespace::clean;

our $VERSION = 'v4.1.1';

our @ISA = ('DBI::st', 'Ekorn::Pipeline::Pipes');

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# Bind values to the statement's placeholders, without executing it, and
# return the handle, or nothing if the DBI couldn't bind one. Numbered
# placeholders take values in order, the first to every use of 1, and so
# on; named ones take a hash reference or a list of names and values. An
# array reference stands for the values in it.
sub bind ($self, @args) {
    return _bind($self, _binds($self), _unwrap($self, @args));
}

# Bind values, as bind does, given as a list, and the statement's map of
# placeholders to positions, if it has one. Each value is bound to its
# positions directly, with the DBI's bind_param.
sub _bind ($self, $binds, @args) {
    my @placed;
    if ($binds) {
        my $given = DBIx::Squirrel::Placeholders::_values_for($binds, \@args);    ## no critic (Subroutines::ProtectPrivateSubs)
        my $state = $self->{private_ekorn};
        @placed = @{ DBIx::Squirrel::Placeholders::_place_values($state, $given) };    ## no critic (Subroutines::ProtectPrivateSubs)
    }
    else {
        @placed = map { ($_ => $args[$_ - 1]) } 1 .. @args;
    }
    return at_caller {
        for my $pair (pairs @placed) {
            $self->SUPER::bind_param(@$pair) or return;
        }
        $self->{private_ekorn}{AllBound} = 1 if $binds;
        $self;
    };
}

# Bind a value to a placeholder, as the DBI's bind_param does, given its
# number or its name, with or without the sigil, and bind it to every use
# of that placeholder in the statement; for a list placeholder, bind each
# value in the list to a position of its own. Return what the DBI returns.
sub bind_param ($self, $param, $value, @attrs) {
    my $binds = _binds($self)
        or return at_caller { $self->SUPER::bind_param($param, $value, @attrs) };
    my $key = key_of($param);
    unless ($binds->{$key}) {

        # A position, for a statement with named placeholders.
        if ($param =~ m( \A \d+ \z )xa && !is_numbered($binds)) {
            my $rv = at_caller { $self->SUPER::bind_param($param, $value, @attrs) };
            $self->{private_ekorn}{Bound}{$param} = 1 if $rv;
            return $rv;
        }
        croakf 'Expected a placeholder of the statement (%s)', $param;
    }
    my @placed = pairs place_values($self->{private_ekorn}, $key => $value);
    my $rv;
    for my $pair (@placed) {
        $rv = at_caller { $self->SUPER::bind_param(@$pair, @attrs) }
            or return $rv;
    }
    $self->{private_ekorn}{Bound}{$_->[0]} = 1 for @placed;
    return $rv;
}

# Execute the statement, as the DBI's execute does, with any values given
# bound as bind binds them. Values for numbered or named placeholders go
# to the DBI's execute in the order of their positions, which binds them
# as bind_param would, in one call. With the ekorn_finish_active
# attribute, a statement still active from an earlier execute is finished
# first. While execute_for_fetch runs, values come by position already, a
# value for each use of each placeholder, and go to the DBI as they are.
sub execute ($self, @args) {
    my $state = $self->{private_ekorn};
    $self->finish
        if $state && $state->{Options}{ekorn_finish_active} && $self->{Active};
    # Only values in an array reference given alone need unwrapping, and
    # most aren't: the call, copying them in and out, is left out for
    # them (roadmap 2026-0028).
    @args = _unwrap($self, @args) if @args == 1 && is_plain_arrayref($args[0]);
    my $binds = $state && $state->{Binds};
    if ($binds && !$state->{InOrder}) {
        _check_bound($self) unless @args;
        @args = _in_order($state, \@args) if @args;
        $state->{AllBound} = 1;
    }
    return at_caller { $self->SUPER::execute(@args) };
}

# Execute the statement once for each row of values the fetch gives, as
# the DBI's execute_for_fetch does, and return what it returns. A
# statement whose placeholders are mapped takes each row as the values for
# its placeholders, in order: by number, or for names, as each first
# appears; or, for named ones, as a hash by name. Each row's values go to
# the DBI by position, a value for each use, so a driver gets them as it
# would for "?" (roadmap 2026-0037).
sub execute_for_fetch ($self, $fetch, @status) {
    _binds($self)
        or return at_caller { $self->SUPER::execute_for_fetch($fetch, @status) };
    my $state = $self->{private_ekorn};
    _no_lists_for_rows($state);
    my $keys     = _row_keys($state);
    my $in_order = sub {
        my $row = $fetch->() or return;
        $state->{AllBound} = 1;
        return [_row_in_order($state, $keys, $row)];
    };
    local $state->{InOrder} = 1;
    return at_caller { $self->SUPER::execute_for_fetch($in_order, @status) };
}

# Execute the statement once for each row of values, as the DBI's
# execute_array does, and return what it returns: the rows come from the
# arrays given, a value for each placeholder in the order
# execute_for_fetch takes them, or from those bound with
# bind_param_array, or from ArrayTupleFetch. A statement whose
# placeholders are mapped is counted by its placeholders, not their uses,
# as the DBI's NUM_OF_PARAMS counts them (roadmap 2026-0037). The DBI's
# own checks keep its messages, raised as it raises them.
sub execute_array ($self, $attrs, @arrays) {
    _binds($self)
        or return at_caller { $self->SUPER::execute_array($attrs, @arrays) };
    my $state = $self->{private_ekorn};
    _no_lists_for_rows($state);
    my $keys   = _row_keys($state);
    my $needed = @$keys;
    my $status = $attrs && $attrs->{ArrayTupleStatus};
    return _dbi_error(
        $self,
        execute_array => 'ArrayTupleStatus attribute must be an arrayref',
    ) if $status && !is_plain_arrayref($status);
    my $fetch;
    if (my $source = $attrs && $attrs->{ArrayTupleFetch}) {
        return _dbi_error(
            $self,
            execute_array => "Can't use both ArrayTupleFetch and explicit bind values",
        ) if @arrays;
        $fetch = _fetch_from($self, $source, $needed)
            or return;
    }
    else {
        if (@arrays) {
            return _dbi_error(
                $self,
                execute_array => @arrays . " bind values supplied but $needed expected",
            ) unless @arrays == $needed;
            $state->{ParamArrays} = {};
            for my $i (keys @arrays) {
                $self->bind_param_array($keys->[$i], $arrays[$i])
                    or return;
            }
        }
        my $given = $state->{ParamArrays} // {};
        my $count = keys %$given;
        return _dbi_error(
            $self,
            execute_array => "$count bind values supplied but $needed expected",
        ) unless $count == $needed;
        my $rows
            = max(1, map { scalar @$_ } grep { is_plain_arrayref($_) } values %$given);
        my $row = 0;
        $fetch = sub {
            return if $row >= $rows;
            my @values
                = map { is_plain_arrayref($_) ? $_->[$row] : $_ } @$given{@$keys};
            $row++;
            return \@values;
        };
    }
    return $self->execute_for_fetch($fetch, $status ? $status : ());
}

# Bind an array of values, one for each row execute_array executes, to a
# placeholder, as the DBI's bind_param_array does, and return what it
# returns. A statement whose placeholders are mapped takes the
# placeholder's number or name, with or without its sigil, where the
# DBI's takes only a number; attributes given are bound to every use of
# it, as bind_param binds them. Its arrays are kept with the statement's
# map, not in the DBI's ParamArrays, which only the driver's side of the
# handle can set (roadmap 2026-0037).
sub bind_param_array ($self, $param, $values, @attrs) {
    my $binds = _binds($self)
        or return
        at_caller { $self->SUPER::bind_param_array($param, $values, @attrs) };
    my $state = $self->{private_ekorn};
    _no_lists_for_rows($state);
    return _dbi_error(
        $self, bind_param_array =>
            "Value for parameter $param must be a scalar or an arrayref, not a "
            . ref $values,
    ) if is_ref($values) && !is_plain_arrayref($values);
    my $key = key_of($param);
    croakf 'Expected a placeholder of the statement (%s)', $param
        unless $binds->{$key};
    $state->{ParamArrays}{$key} = $values;
    return $self->bind_param($key, undef, @attrs)
        if @attrs && $attrs[0];
    return 1;
}

# Return an iterator over the statement's results, executed with the bind
# values given, and run through the stages given after them; or, if the
# last stage is a sink, the sink's result.
sub iterate ($self, @args) {
    return DBIx::Squirrel::Iterator->new($self, @args)->_or_sink;    ## no critic (Subroutines::ProtectPrivateSubs)
}

# Return a result set over the statement's results: an iterator handing
# out rows as objects; or, if the last stage is a sink, the sink's result.
sub results ($self, @args) {
    return DBIx::Squirrel::Results->new($self, @args)->_or_sink;    ## no critic (Subroutines::ProtectPrivateSubs)
}

# Return the values given, or those in an array reference given alone,
# as unwrap_values does. Values not given in an array reference alone,
# as most aren't, are returned at once, without reading the driver's name
# through the handles' attributes.
sub _unwrap ($self, @args) {
    return @args
        unless @args == 1 && is_plain_arrayref($args[0]);
    my $state = $self->{private_ekorn};
    return unwrap_values(
        $self->{Database}{Driver}{Name},
        sub { _values_taken($self) },
        $state && $state->{Lists}, @args,
    );
}

# Return how many values the statement takes in order: one for each
# placeholder the DBI sees, or each number, or none if they're named.
sub _values_taken ($self) {
    my $binds = _binds($self)
        or return $self->{NUM_OF_PARAMS};
    return values_taken($binds);
}

# Return the statement's map of each placeholder's number or name to its
# positions, or nothing if the statement went to the DBI as written.
sub _binds ($self) {
    my $state = $self->{private_ekorn};
    return $state && $state->{Binds};
}

# Croak unless a value has been bound to every use of each of the
# placeholders of a statement with numbered or named ones: given to
# execute or bind, which bind them all, or to bind_param. Unbound, the
# driver would read them as NULL, or fail.
sub _check_bound ($self) {
    my $state = $self->{private_ekorn};
    return if $state->{AllBound};
    my $binds   = $state->{Binds};
    my $bound   = $state->{Bound} // {};
    my @missing = sort grep {
        grep { !$bound->{$_} }
            @{ $binds->{$_} }
    } keys %$binds;
    croakf 'Expected a value for each placeholder (none for %s)',
        join(', ', @missing)
        if @missing;
    return;
}

# Return the values for a statement's placeholders, as values_for finds
# them, in the order of their positions, each as often as it's used, and
# each value in a list at a position of its own, given what the statement
# handle keeps about the statement.
#
# A statement without list placeholders keeps their order, so its values
# are put in it with a slice (roadmap 2026-0028).
sub _in_order ($state, $args) {
    my $given = DBIx::Squirrel::Placeholders::_values_for($state->{Binds}, $args); ## no critic (Subroutines::ProtectPrivateSubs)
    if (my $order = $state->{Order}) {
        return @$given{@$order};
    }
    # A list's values go to positions of their own, each pair a position
    # and its value, put in order without a hash of them.
    my $placed = DBIx::Squirrel::Placeholders::_place_values($state, $given);    ## no critic (Subroutines::ProtectPrivateSubs)
    my @in_order;
    for (my $i = 0; $i < @$placed; $i += 2) {
        $in_order[$placed->[$i] - 1] = $placed->[$i + 1];
    }
    return @in_order;
}

# Return the numbers or names a row of values gives a statement values
# for, in the order it gives them: each number to the highest, as execute
# takes them, or the names in the order each first appears (roadmap
# 2026-0037, D1). A statement's handle keeps them.
sub _row_keys ($state) {
    return $state->{RowKeys}
        if $state->{RowKeys};
    my $binds = $state->{Binds};
    return $state->{RowKeys}
        = is_numbered($binds)
        ? [1 .. values_taken($binds)]
        : [sort { $binds->{$a}[0] <=> $binds->{$b}[0] } keys %$binds];
}

# Return a row's values for a statement's placeholders in the order of
# their positions, a value for each use, as _in_order does, given what the
# statement handle keeps about it, the numbers or names its rows give
# values for, and the row: an array of values in that order, or, for a
# named statement, a hash of them by name.
sub _row_in_order ($state, $keys, $row) {
    my $numbered = is_numbered($state->{Binds});
    return _in_order($state, [$row])
        if !$numbered && is_plain_hashref($row);
    croakf 'Expected a row of values: an array, or a hash for named placeholders'
        unless is_arrayref($row);
    return _in_order($state, $row)
        if $numbered;
    croakf 'Expected %d bind values, not %d', scalar @$keys, scalar @$row
        unless @$row == @$keys;
    my %values;
    @values{@$keys} = @$row;
    return @values{@{ $state->{Order} }};
}

# Return a fetch of rows, for execute_array, from what ArrayTupleFetch
# holds: a code reference, as it is, or an active statement handle, read
# a row at a time, with as many columns as the statement has
# placeholders. Otherwise, set the DBI's error, as it does, and return
# nothing.
sub _fetch_from ($self, $source, $needed) {
    return $source
        if is_coderef($source);
    return _dbi_error(
        $self,
        execute_array =>
            "ArrayTupleFetch '$source' is not a code ref or statement handle",
    ) unless $source isa 'DBI::st';
    return _dbi_error(
        $self,
        execute_array =>
            'ArrayTupleFetch sth is not Active, need to execute() it first',
    ) unless $source->{Active};
    my $fields = $source->{NUM_OF_FIELDS};    # an active statement has them
    return _dbi_error(
        $self,
        execute_array =>
            "$fields columns from ArrayTupleFetch sth but $needed expected",
    ) if $fields != $needed;
    return sub { $source->fetchrow_arrayref };
}

# Croak if a statement has list placeholders: its handle is prepared for
# lists of the lengths it was given, so rows of values can't share it
# (roadmap 2026-0037, D4).
sub _no_lists_for_rows ($state) {
    my $lists = $state->{Lists};
    croakf 'Expected no list placeholder in a statement for rows of values (%s)',
        join ', ', sort values %$lists
        if $lists;
    return;
}

# Set the DBI's error on a statement handle, with one of the DBI's own
# messages, as its execute_array and bind_param_array set them, so it's
# raised, printed or handled as the handle's attributes say, named for
# the method given, as the DBI names it; return what set_err returns. An
# error left from an earlier call is cleared first, as the DBI clears it
# at the start of each of its methods, or set_err would add to it.
sub _dbi_error ($self, $method, $message) {
    $self->set_err(undef, undef);
    return at_caller { $self->set_err($DBI::stderr, $message, undef, $method) };
}

1;
__END__

=encoding utf8

=for stopwords PostgreSQL

=head1 NAME

DBIx::Squirrel::st - DBIx::Squirrel's statement handle class

=head1 DESCRIPTION

A statement handle prepared on a DBIx::Squirrel database handle is
blessed into this class. It's a subclass of the DBI's C<DBI::st>, so
it does everything a DBI statement handle does. It also inherits
L<DBIx::Squirrel/pipe> and L<DBIx::Squirrel/tap> from
L<Ekorn::Pipeline::Pipes>.

=head2 Lists

A placeholder with C<...> before it, such as C<...?>, C<...$1> or
C<...:ids>, takes a list. See L<DBIx::Squirrel::db/prepare>. The list
is the value for its placeholder: a reference to an array of plain
values, given as any other value is:

    $dbh->selectall_arrayref('SELECT * FROM artist WHERE id IN (...:ids)',
        ids => [1, 2, 3]);
    $dbh->selectall_arrayref('SELECT * FROM artist WHERE name = ? OR id IN (...?)',
        'Abba', [1, 2, 3]);

Given to a statement whose one value is a list, a single array
reference is the list, not the values in it. So C<[1, 2, 3]> is a list
of three values. C<[[1, 2, 3]]> croaks, as a list holds plain values.

The statement is prepared for the values it's given, so its handle is
for lists of those lengths. Executed or bound again, each list must
have as many values, or it croaks. An iterator's
L<DBIx::Squirrel::Iterator/reset> prepares the statement again, on a
new handle, when a list has a different number. L</bind_param> binds
each value in a list to a position of its own.

=head1 METHODS

=head2 bind

    $sth = $sth->bind(@bind_values);
    $sth = $sth->bind(\@bind_values);
    $sth = $sth->bind(%values);
    $sth = $sth->bind(\%values);

Binds values to the statement's placeholders, as L</execute> does,
without executing it. Returns the statement handle, or nothing if the
DBI couldn't bind a value. How values are matched to placeholders
depends on the statement's style of placeholder:

=over

=item C<?>

Values are bound in order, as with the DBI.

=item C<?1>, C<:1> and C<$1>

The first value is bound to every use of placeholder 1, the second to
every use of 2, and so on, wherever they are in the statement. There
must be as many values as the highest number. In
C<SELECT $2 + $1, $1>, C<(10, 20)> gives C<SELECT 20 + 10, 10>.

=item C<:name> and C<$name>

Values are given by name, as pairs or in a hash reference, and each is
bound to every use of its name. The names can be given with or without
the sigil. There must be a value for each name, and no other:

    $sth->bind(id => 1, name => 'AC/DC');
    $sth->bind({':id' => 1, ':name' => 'AC/DC'});

=back

A single array reference stands for the values in it, so
C<< $sth->bind([1, 2]) >> is C<< $sth->bind(1, 2) >>. An object is a
value, as it is to the DBI, whatever it's made of. There are two
exceptions, each for a statement taking one value:

=over

=item * If its value is a list, as described in L</Lists>, the array
reference is the list.

=item * L<DBD::Pg> binds an array reference as a PostgreSQL array. So,
with DBD::Pg, an array reference given to a statement taking one value,
such as C<SELECT * FROM artist WHERE id = ANY(?)>, is that value, as it
would be with the DBI. Through another driver, such as DBD::ODBC, it's
unwrapped as usual, as the driver can't bind arrays.

=back

=head2 bind_param

    $rv = $sth->bind_param($placeholder, $value);
    $rv = $sth->bind_param($placeholder, $value, \%attr);
    $rv = $sth->bind_param($placeholder, $value, $bind_type);

Binds a value, as the DBI's C<bind_param> does, and returns what it
returns. A numbered placeholder is given by number, and a named one by
name, with or without its sigil. The value is bound to every use of it
in the statement. A statement with named placeholders can also be
bound by position, as with the DBI.

The value for a list placeholder is its list. Each value in it is
bound to a position of its own, with the same C<\%attr> or
C<$bind_type>.

=head2 bind_param_array

    $rv = $sth->bind_param_array($placeholder, \@values);
    $rv = $sth->bind_param_array($placeholder, $value);
    $rv = $sth->bind_param_array($placeholder, \@values, \%attr);

Binds an array of values to a placeholder, a value for each row
L</execute_array> executes, or a plain value for every row, as the
DBI's C<bind_param_array> does, and returns what it returns. The
placeholder is named as for L</bind_param>: by number or name, with or
without its sigil, where the DBI's takes only a number. Attributes
given are bound to every use of it.

For any style but C<?>, the arrays are kept with the statement, not in
the DBI's C<ParamArrays>, which only the driver's side of the handle
can set.

=head2 execute

    $rv = $sth->execute;
    $rv = $sth->execute(@bind_values);
    $rv = $sth->execute(\@bind_values);
    $rv = $sth->execute(%values);
    $rv = $sth->execute(\%values);

Executes the statement, as the DBI's C<execute> does, and returns what
it returns. Values given are bound first, as L</bind> binds them.

A statement with numbered or named placeholders, executed without
values, croaks unless each placeholder already has a value bound. The
value can come from L</bind>, L</bind_param> or an earlier C<execute>,
as the DBI keeps them. The DBI would leave the placeholder unbound,
which most drivers read as C<NULL>.

The DBI doesn't finish a statement still active from an earlier
C<execute> before executing it again. Nor does C<execute>, unless the
C<ekorn_finish_active> attribute is true. Pass it to
L<DBIx::Squirrel/connect> to set it for every statement of a database
handle, or to L<DBIx::Squirrel::db/prepare> for one statement.

=head2 execute_array

    $tuples = $sth->execute_array(\%attr, @arrays);
    ($tuples, $rows) = $sth->execute_array(\%attr, @arrays);
    $tuples = $sth->execute_array(\%attr);

Executes the statement once for each row of values, as the DBI's
C<execute_array> does, and returns what it returns: in a list, the
rows executed and the rows changed. The rows come from C<@arrays>, an
array for each placeholder; from those bound with
L</bind_param_array>; or from C<ArrayTupleFetch> in C<%attr>, a code
reference returning a row at a time, or an active statement handle to
read them from. Each row's status goes in C<ArrayTupleStatus>, as with
the DBI.

A row's values come in the order of the statement's placeholders: by
number, or, for names, in the order each first appears. So
C<:id, :name, :id> takes two values a row, and the DBI's counts are of
the placeholders, not their uses. The DBI's errors keep its messages,
raised, printed or handled as the handle's attributes say.

    my $sth = $dbh->prepare('INSERT INTO gig (artist, city) VALUES (:artist, :city)');
    $sth->execute_array({}, ['Abba', 'Blur'], ['Brighton', 'Colchester']);

=head2 execute_for_fetch

    $tuples = $sth->execute_for_fetch($fetch);
    $tuples = $sth->execute_for_fetch($fetch, \@status);
    ($tuples, $rows) = $sth->execute_for_fetch($fetch, \@status);

Executes the statement once for each row C<$fetch> returns, until it
returns nothing, as the DBI's C<execute_for_fetch> does, and returns
what it returns. A row is an array of values, in the order
L</execute_array> takes them, or, for named placeholders, a hash of
them by name, with or without the sigil:

    my @rows = ({artist => 'Cream', city => 'Windsor'});
    $sth->execute_for_fetch(sub { shift @rows });

Each row's values go to the DBI by position, a value for each use of
each placeholder, so a driver with its own C<execute_for_fetch> gets
them as it would for C<?>.

A statement with a list placeholder, described in L</Lists>, can't
take rows, as its handle is prepared for lists of one length:
C<execute_array>, C<execute_for_fetch> and C<bind_param_array> croak
for it.

=head2 iterate

    $it = $sth->iterate(@bind_values, @stages);

Returns a L<DBIx::Squirrel::Iterator> over the statement's results.
The statement is executed with C<@bind_values>, in any form
L</execute> takes, when the first result is asked for. Each row is run
through C<@stages>, the code references or pipelines at the end of the
arguments.

If the last stage is one of L<Ekorn::Pipeline::Sinks>' sinks, it reads
the results to the end and returns the sink's result instead. A sink
of one value, such as C<count_items> or C<keep_single>, gives it. A
sink of many, such as C<keep_all>, gives a list, or, where one value
is asked for, an array reference.

    use Ekorn::Pipeline::Sinks qw(count_items keep_all);

    my @rows = $sth->iterate(1990, keep_all);
    my $n    = $sth->iterate(1990, count_items);

=head2 results

    $results = $sth->results(@bind_values, @stages);

As L</iterate>, returning a L<DBIx::Squirrel::Results>, whose rows are
objects with a method for each column, or, if the last stage is a
sink, the sink's result.

=head1 DIAGNOSTICS

=over

=item Expected %d bind values, not %d

A statement with numbered placeholders was given more or fewer values
than its highest number; or a row given to L</execute_for_fetch>, for
numbered or named placeholders, had more or fewer values than the
statement has placeholders.

=item Expected names and values in pairs

A statement with named placeholders was given an odd number of values.

=item Expected a placeholder of the statement (%s)

A value was given for a placeholder the statement doesn't have.

=item Expected a value for each placeholder (none for %s)

A statement with named placeholders wasn't given a value for each
name, or a statement with numbered or named placeholders was executed
without values when some had none bound.

=item Expected one value for each placeholder (two for %s)

A statement with named placeholders was given a value for a name twice,
written with and without its sigil, as C<:id> and C<id>.

=item Expected a reference to an ARRAY for a list (%s)

The value given for a list placeholder, named with its C<...>, wasn't
a list. It was a plain value, C<undef>, or a reference to something
other than an array.

=item Expected at least one value in a list (%s)

The list given for a list placeholder was empty. C<IN ()> isn't SQL,
so the caller must deal with an empty list.

=item Expected plain values in a list (%s)

A list held an unblessed reference, such as an array reference inside
the one given, as in C<[[1, 2]]> to a statement whose one value is a
list.

=item Expected a row of values: an array, or a hash for named placeholders

A row given to L</execute_for_fetch>, or by C<ArrayTupleFetch> to
L</execute_array>, was neither an array, nor, for named placeholders, a
hash. The rows before it have been executed.

=item Expected no list placeholder in a statement for rows of values (%s)

L</execute_array>, L</execute_for_fetch> or L</bind_param_array> was
called on a statement with a list placeholder. Its handle is prepared
for lists of one length, so rows of values can't share it.

=item Expected %d values in a list, as prepared, not %d (%s)

A statement handle prepared for a list of one length was executed or
bound with a list of another. To prepare it again, execute the
statement through L<DBIx::Squirrel::db>'s methods, or reset its
iterator.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBI>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
