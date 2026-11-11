use v5.36;

package DBIx::Squirrel::st;

use DBI        qw();
use List::Util qw(pairs);
use Ref::Util  qw(is_arrayref);

use DBIx::Squirrel::Errors       qw(at_caller croakf);
use DBIx::Squirrel::Iterator     qw();
use DBIx::Squirrel::Placeholders qw(
    is_numbered key_of place_values values_for values_taken
);
use DBIx::Squirrel::Results qw();
use DBIx::Squirrel::Pipes   qw();
use DBIx::Squirrel::Util    qw(unwrap_values);

use namespace::clean;

our @ISA = ('DBI::st', 'DBIx::Squirrel::Pipes');

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
    my @placed
        = $binds
        ? place_values($self->{private_ekorn}, values_for($binds, @args))
        : map { ($_ => $args[$_ - 1]) } 1 .. @args;
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
# first.
sub execute ($self, @args) {
    my $state = $self->{private_ekorn};
    $self->finish
        if $state && $state->{Options}{ekorn_finish_active} && $self->{Active};
    @args = _unwrap($self, @args);
    my $binds = $state && $state->{Binds};
    if ($binds) {
        _check_bound($self) unless @args;
        @args = _in_order($state, @args) if @args;
        $state->{AllBound} = 1;
    }
    return at_caller { $self->SUPER::execute(@args) };
}

# Return an iterator over the statement's results, executed with the bind
# values given, and run through the stages given after them.
sub iterate ($self, @args) {
    return DBIx::Squirrel::Iterator->new($self, @args);
}

# Return a result set over the statement's results: an iterator handing
# out rows as objects.
sub results ($self, @args) {
    return DBIx::Squirrel::Results->new($self, @args);
}

# Return the values given, or those in an array reference given alone,
# as unwrap_values does. Values not given in an array reference alone,
# as most aren't, are returned at once, without reading the driver's name
# through the handles' attributes.
sub _unwrap ($self, @args) {
    return @args
        unless @args == 1 && is_arrayref($args[0]);
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
sub _in_order ($state, @args) {
    my %placed = place_values($state, values_for($state->{Binds}, @args));
    return @placed{1 .. keys %placed};
}

1;
__END__

=encoding utf8

=for stopwords PostgreSQL

=head1 NAME

DBIx::Squirrel::st - DBIx::Squirrel's statement handle class

=head1 DESCRIPTION

A statement handle prepared on a DBIx::Squirrel database handle is
blessed into this class. It's a subclass of the DBI's C<DBI::st>, so it
does everything a DBI statement handle does. It also inherits
L<DBIx::Squirrel/pipe> and L<DBIx::Squirrel/tap> from
L<DBIx::Squirrel::Pipes>.

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
C<< $sth->bind([1, 2]) >> is C<< $sth->bind(1, 2) >>. There are two
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
in the statement. A statement with named placeholders can also be bound
by position, as with the DBI.

The value for a list placeholder is its list. Each value in it is bound
to a position of its own, with the same C<\%attr> or C<$bind_type>.

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

=head2 iterate

    $it = $sth->iterate(@bind_values, @stages);

Returns a L<DBIx::Squirrel::Iterator> over the statement's results.
The statement is executed with C<@bind_values>, in any form
L</execute> takes, when the first result is asked for. Each row is run
through C<@stages>, the code references or pipelines at the end of the
arguments.

=head2 results

    $results = $sth->results(@bind_values, @stages);

As L</iterate>, returning a L<DBIx::Squirrel::Results>, whose rows are
objects with a method for each column.

=head1 DIAGNOSTICS

=over

=item Expected %d bind values, not %d

A statement with numbered placeholders was given more or fewer values
than its highest number.

=item Expected names and values in pairs

A statement with named placeholders was given an odd number of values.

=item Expected a placeholder of the statement (%s)

A value was given for a placeholder the statement doesn't have.

=item Expected a value for each placeholder (none for %s)

A statement with named placeholders wasn't given a value for each name,
or a statement with numbered or named placeholders was executed without
values when some had none bound.

=item Expected a reference to an ARRAY for a list (%s)

The value given for a list placeholder, named with its C<...>, wasn't a
list. It was a plain value, C<undef>, or a reference to something
other than an array.

=item Expected at least one value in a list (%s)

The list given for a list placeholder was empty. C<IN ()> isn't SQL,
so the caller must deal with an empty list.

=item Expected plain values in a list (%s)

A list held a reference, such as an array reference inside the one
given, as in C<[[1, 2]]> to a statement whose one value is a list.

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

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
