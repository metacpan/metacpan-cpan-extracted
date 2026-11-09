use v5.36;

package DBIx::Squirrel::db;

use Carp       qw(croak);
use DBI        qw();
use List::Util qw(all max);
use Ref::Util  qw(is_arrayref is_coderef is_hashref is_ref);

use DBIx::Squirrel::Errors       qw(at_caller croakf failed in_method);
use DBIx::Squirrel::Placeholders qw(
    expand_lists key_of study_sql values_for values_taken
);
use DBIx::Squirrel::Pipes qw();
use DBIx::Squirrel::Util  qw(
    canonical iterator_going shift_attrs split_attrs split_stages unwrap_values
);

use namespace::clean;

our @ISA = ('DBI::db', 'DBIx::Squirrel::Pipes');

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# DBD::Pg's options that change which placeholders it reads.
my @PG_OPTIONS = qw(pg_placeholder_dollaronly pg_placeholder_nocolons);

# Prepare a statement, with placeholders in any style, and return its
# handle.
sub prepare ($self, $statement, $attrs = undef, @args) {
    return _prepare($self, $statement, $attrs, @args)
        || croak failed($self, 'prepare');
}

# Prepare a statement, as prepare does, and return its handle, or
# nothing, as the DBI's prepare does, if it can't be prepared. A
# statement with list placeholders can't be prepared without its values.
sub _prepare ($self, $statement, $attrs, @args) {
    my($normalised, $state, $dbi_attrs) = _study($self, $statement, $attrs);
    _no_lists($state);
    return _prepare_studied($self, $normalised, $state, $dbi_attrs, @args);
}

# Prepare a statement, as _prepare does, given the bind values it's to be
# executed with, so that a statement with list placeholders is prepared
# with a "?" for each value in each list.
sub _prepare_for ($self, $statement, $attrs, @values) {
    my($normalised, $state, $dbi_attrs) = _study($self, $statement, $attrs);
    return _prepare_studied(
        $self, _for_values($self, $normalised, $state, $dbi_attrs, @values),
        $dbi_attrs,
    );
}

# Return a statement handle for a statement with list placeholders, to be
# executed with the bind values given: the handle given, if each list has
# as many values as it was prepared for, or a new one, prepared for them,
# croaking if it can't be prepared. Without values, the handle executes
# with those bound already. An iterator calls it from its reset.
sub _prepare_again ($self, $sth, @values) {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my $state = $sth->{private_ekorn};
    return $sth
        unless @values;
    my($normalised, $expanded)
        = _for_values($self, undef, $state, $state->{DBIAttrs}, @values);
    my($was, $now) = ($state->{Lengths}, $expanded->{Lengths});
    return $sth
        if all { $was->{$_} == $now->{$_} } keys %$now;
    return _prepare_studied($self, $normalised, $expanded, $state->{DBIAttrs})
        || croak failed($self, 'prepare');
}

# Return a statement studied already, and what its handle is to keep
# about it, as they are, unless it has list placeholders: then, given the
# bind values it's to be executed with, return it with a "?" for each
# value in each list, as expand_lists does, and what its handle is to keep
# about that, starting afresh from what was studied.
sub _for_values ($self, $normalised, $state, $dbi_attrs, @values) {
    return $normalised, $state
        unless $state->{Lists};
    @values = unwrap_values(
        $self->{Driver}{Name},
        sub { values_taken($state->{Binds}) },
        $state->{Lists}, @values,
    );
    my($expanded, $binds, $lengths)
        = expand_lists($state, {values_for($state->{Binds}, @values)});
    my %kept = map { ($_ => $state->{$_}) }
        qw(Placeholders OriginalStatement Options Lists Pieces);
    return $expanded, {
        %kept,
        Binds    => $binds,
        Lengths  => $lengths,
        DBIAttrs => $dbi_attrs,
    };
}

# Croak if a statement has list placeholders, which take their values
# before it's prepared.
sub _no_lists ($state) {
    my $lists = $state->{Lists};
    croakf 'Expected bind values with a statement taking a list (%s)',
        join ', ', sort values %$lists
        if $lists;
    return;
}

# Prepare a statement studied already, as _prepare does.
sub _prepare_studied ($self, $normalised, $state, $dbi_attrs, @args) {
    my $sth = at_caller { $self->SUPER::prepare($normalised, $dbi_attrs, @args) }
        or return;
    $sth->{private_ekorn} = $state;
    return $sth;
}

# Prepare a statement, with placeholders in any style, using the DBI's
# cache of statement handles, and return its handle.
#
# The DBI caches a handle by its statement and attributes, and different
# statements can be rewritten the same, as "SELECT :a, :b" and
# "SELECT :b, :a" both are, so the original statement goes in a private
# attribute, to keep their handles apart, with DBIx::Squirrel's own
# attributes, which the DBI doesn't see, as a string.
#
# A cached handle an iterator is part way through is never handed out, or
# finished, as the DBI would finish an active one: that would cut the
# iterator's results short. A new handle is made, and cached in its place,
# unless $if_active is 2, which asks for the handle as it is. Otherwise,
# $if_active means what it does to the DBI.
sub prepare_cached ($self, $statement, $attrs = undef, $if_active = undef) {
    my($normalised, $state, $dbi_attrs, $ekorn) = _study($self, $statement, $attrs);
    _no_lists($state);
    $dbi_attrs = {
        %{ $dbi_attrs // {} },
        private_ekorn_statement => $state->{OriginalStatement},
        (%$ekorn ? (private_ekorn_options => canonical($ekorn)) : ()),
    };
    my $cached = sub (@if_active) {
        in_method $self, 'prepare_cached', sub {
            at_caller {
                $self->SUPER::prepare_cached($normalised, $dbi_attrs, @if_active)
            } or croak failed($self, 'prepare_cached');
        };
    };

    # Look at the cached handle, without finishing it.
    my $sth   = $cached->(2);
    my $as_is = defined $if_active && $if_active == 2;
    if (!$as_is && iterator_going($sth)) {
        _uncache($self, $sth);
        $sth = $cached->();
    }

    # One that's active, with no iterator, is the DBI's to deal with.
    $sth = $cached->(defined $if_active ? $if_active : ())
        if !$as_is && $sth->{Active};

    # A cached handle keeps what it had, such as the iterator using it,
    # updated in place: a copy would make the weak reference to the
    # iterator strong, and the two would never be freed.
    my $kept = $sth->{private_ekorn};
    if ($kept) {
        @$kept{keys %$state} = values %$state;
    }
    else {
        $sth->{private_ekorn} = $state;
    }
    return $sth;
}

# Prepare a statement by calling the method named, prepare or
# prepare_cached, which a subclass may have of its own, with $if_active
# for prepare_cached; or, if the statement takes a list, for the bind
# values given, as _prepare_for does, and not cached, croaking as the
# method does if it can't be prepared. iterate, results and
# DBIx::Squirrel::Sugar's functions prepare their statements with it.
sub _prepare_as ($self, $method, $statement, $attrs, $if_active, @values) {
    my(undef, $state) = _study($self, $statement, $attrs);
    return $self->$method($statement, $attrs, defined $if_active ? $if_active : ())
        unless $state->{Lists};
    return _prepare_for($self, $statement, $attrs, @values)
        || croak failed($self, $method);
}

# Take a statement handle out of the DBI's cache, so the next
# prepare_cached of its statement makes a new one.
sub _uncache ($self, $sth) {
    my $cache = $self->{CachedKids} or return;
    delete @$cache{grep { $cache->{$_} == $sth } keys %$cache};
    return;
}

# Run a statement, and return what the DBI's do returns. Unlike the DBI's,
# the attributes may be left out. A statement DBIx::Squirrel doesn't
# rewrite goes to the driver's own do, as with plain DBI, so the driver's
# row counts and options, such as DBD::SQLite's multiple statements,
# apply; any other is prepared and executed, returning undef, as the DBI
# does, if it can't be prepared.
sub do ($self, $statement, @args) {
    my $attrs = shift_attrs(\@args);
    my($normalised, $state, $dbi_attrs) = _study($self, $statement, $attrs);
    if ($state->{Binds}) {
        return in_method $self, 'do', sub {
            my $sth = _prepare_studied(
                $self, _for_values($self, $normalised, $state, $dbi_attrs, @args),
                $dbi_attrs,
            ) or return;
            return $sth->execute(@args);
        };
    }
    @args = unwrap_values(
        $self->{Driver}{Name},
        sub { _values_taken($state->{Placeholders}) },
        undef, @args,
    );
    return at_caller { $self->SUPER::do($normalised, $dbi_attrs, @args) };
}

# Return how many values a statement the DBI binds as written takes: one
# for each "?", or the highest number of those DBD::Pg reads as "$1".
sub _values_taken ($placeholders) {
    my @placeholders = values %$placeholders;
    return scalar @placeholders
        unless @placeholders && $placeholders[0] =~ m( \A \$ )x;
    return max map { s( \A \$ )()xr } @placeholders;
}

# Prepare a statement, and return an iterator over its results, executed
# with the bind values given, and run through the stages given after
# them. As with do, the attributes may be left out.
sub iterate ($self, $statement, @args) {
    return _prepare_to_iterate($self, $statement, \@args)->iterate(@args);
}

# Prepare a statement, and return a result set over its results, as
# iterate does.
sub results ($self, $statement, @args) {
    return _prepare_to_iterate($self, $statement, \@args)->results(@args);
}

# Prepare a statement for iterate or results, as _prepare_as does with
# prepare, for the bind values in their arguments, taking the attributes
# off the front of them, unless a stage is there.
sub _prepare_to_iterate ($self, $statement, $args) {
    my $attrs  = @$args && is_coderef($args->[0]) ? undef : shift_attrs($args);
    my @values = @$args;
    split_stages(\@values);
    return _prepare_as($self, 'prepare', $statement, $attrs, undef, @values);
}

# The DBI's select methods, each preparing the statement and binding its
# values as DBIx::Squirrel does. Drivers built on the DBI's own C code,
# such as DBD::SQLite, DBD::mysql and DBD::Pg, bind and execute in C, not
# through DBIx::Squirrel's methods, so each is given a statement handle
# with its values already bound.
sub selectrow_array ($self, $statement, @args) {
    return _select($self, 'selectrow_array', $statement, [], @args);
}


sub selectrow_arrayref ($self, $statement, @args) {
    return _select($self, 'selectrow_arrayref', $statement, [], @args);
}


sub selectrow_hashref ($self, $statement, @args) {
    return _select($self, 'selectrow_hashref', $statement, [], @args);
}


sub selectall_arrayref ($self, $statement, @args) {
    return _select($self, 'selectall_arrayref', $statement, [], @args);
}


sub selectall_hashref ($self, $statement, $key_field, @args) {
    return _select($self, 'selectall_hashref', $statement, [$key_field], @args);
}


sub selectcol_arrayref ($self, $statement, @args) {
    return _select($self, 'selectcol_arrayref', $statement, [], @args);
}

# Call one of the DBI's select methods with a statement handle, prepared,
# unless it was given one, and with any values bound. Return what the
# DBI's method returns. The attributes may be left out, as with do.
#
# A statement that can't be prepared returns what the DBI's method does,
# without RaiseError: undef from those returning a reference to one row
# or all of them, and nothing from the others.
sub _select ($self, $method, $statement, $before, @args) {
    state %UNDEF = map { ($_ => 1) } qw(
        selectrow_arrayref selectrow_hashref selectall_arrayref
    );
    my $attrs = shift_attrs(\@args);
    return in_method $self, $method, sub {
        my $sth
            = $statement isa 'DBI::st'
            ? $statement
            : _prepare_for($self, $statement, $attrs, @args);
        return $UNDEF{$method} ? undef : ()
            unless $sth;
        # Values for ? placeholders go to the DBI, which checks them as
        # plain DBI does; those for numbered or named ones are bound, or,
        # without any, must have been.
        my @values = DBIx::Squirrel::st::_unwrap($sth, @args);    ## no critic (Subroutines::ProtectPrivateSubs)
        if ($sth->{private_ekorn}{Binds}) {
            DBIx::Squirrel::st::_check_bound($sth) unless @values;    ## no critic (Subroutines::ProtectPrivateSubs)
            $sth->bind(@values) or return          if @values;
            @values = ();
        }
        my $super = "SUPER::$method";
        at_caller { $self->$super($sth, @$before, $attrs, @values) };
    };
}

# Return a statement with its placeholders rewritten as "?", for the DBI
# to prepare, what its statement handle keeps about it, the attributes to
# prepare it with, without DBIx::Squirrel's own, and DBIx::Squirrel's own,
# those given, apart from the handle's defaults. Study it with the
# driver's name, DBD::Pg's placeholder options from the handle, the
# handle's own defaults, from connect, and the attributes given, each
# overriding the last.
#
# A statement given as a string, without attributes, as most are, is
# studied once for each handle, which keeps what was found in its
# private_ekorn_studied attribute, keyed by the statement and, with DBD::Pg, its placeholder options, as they can be
# changed on the handle. Each statement handle has a copy of its own of
# what the statement handle keeps, as an iterator adds to it. The handle
# keeps no more than $STUDIED statements, starting again when it has
# that many, so statements made as the program runs can't fill memory.
sub _study ($self, $statement, $attrs) {
    state $STUDIED = 1000;
    return _study_afresh($self, $statement, $attrs)
        if ($attrs && %$attrs)
        || !defined $statement
        || is_ref($statement);
    my $cache = $self->{private_ekorn_studied} //= {
        Pg         => $self->{Driver}{Name} eq 'Pg',
        Statements => {},
    };
    my $key
        = $cache->{Pg}
        ? join("\0", $statement, map { $self->{$_} // '' } @PG_OPTIONS)
        : $statement;
    my $studied = $cache->{Statements};
    my $found   = $studied->{$key};
    unless ($found) {
        my($normalised, $kept) = _study_afresh($self, $statement, undef);
        %$studied = () if keys %$studied >= $STUDIED;
        $found    = $studied->{$key} = [$normalised, $kept];
    }
    return $found->[0], {%{ $found->[1] }}, undef, {};
}

# Study a statement, as _study does, without keeping what was found.
sub _study_afresh ($self, $statement, $attrs) {
    my $driver  = $self->{Driver}{Name};
    my $state   = $self->{private_ekorn};
    my %options = (
        ekorn_dialect => $driver,
        ($driver eq 'Pg' ? map { ($_ => $self->{$_}) } @PG_OPTIONS : ()),
        %{ $state && $state->{Options} // {} },
        %{ $attrs // {} },
    );
    my $slice = $options{ekorn_slice};
    croakf 'Expected ekorn_slice to be a reference to an ARRAY or HASH'
        if defined $slice && !is_arrayref($slice) && !is_hashref($slice);
    my($placeholders, $normalised, $original, $lists, $pieces)
        = study_sql(_statement_text($statement), \%options)
        or croakf 'Expected a statement';
    my %state = (
        Placeholders      => $placeholders,
        OriginalStatement => $original,
        Options           => \%options,
        Binds             => scalar _binds($placeholders, $normalised, $original),
    );
    @state{qw(Lists Pieces)} = (_lists($placeholders, $lists), $pieces)
        if $lists;
    return $normalised, \%state, split_attrs($attrs);
}

# Return a map of each number or name a statement's placeholders use to
# the positions using it, from 1, or nothing if the statement goes to the
# DBI as written: with "?" placeholders or none, or with placeholders left
# for DBD::Pg to read. With list placeholders, "?" placeholders are
# numbered by their positions.
sub _binds ($placeholders, $normalised, $original) {
    return if $normalised eq $original;
    my %binds;
    for my $position (sort { $a <=> $b } keys %$placeholders) {
        my $placeholder = $placeholders->{$position};
        my $key         = key_of($placeholder, $position);
        croakf 'Expected placeholders numbered from 1 (%s)', $placeholder
            if $key =~ m( \A \d+ \z )xa && $key == 0;
        push @{ $binds{$key} }, $position;
    }
    return \%binds;
}

# Return a map of the number or name of each list placeholder to the
# placeholder as written, with "...", for its messages, and a "?" with
# its position too, as "...? at 2", given the statement's map of its
# placeholders and of the positions taking a list. Croak if a placeholder
# takes a list in one place and not another.
sub _lists ($placeholders, $lists) {
    my(%listed, %plain);
    for my $position (keys %$placeholders) {
        my $placeholder = $placeholders->{$position};
        my $key         = key_of($placeholder, $position);
        if ($lists->{$position}) {
            $listed{$key} = $placeholder eq '?' ? "...? at $key" : "...$placeholder";
        }
        else {
            $plain{$key} = $placeholder;
        }
    }
    my @both = sort map { $plain{$_} } grep { exists $plain{$_} } keys %listed;
    croakf 'Expected a placeholder to take a list everywhere or nowhere (%s)',
        join ', ', @both
        if @both;
    return \%listed;
}

# Return the text of a statement given as a string, as lines in an array
# reference, as a code reference returning either, or as a statement
# handle.
sub _statement_text ($statement) {
    $statement = $statement->() if is_coderef($statement);
    return join ' ', @$statement if is_arrayref($statement);
    if ($statement isa 'DBI::st') {
        my $state = $statement->{private_ekorn};
        return $state ? $state->{OriginalStatement} : $statement->{Statement};
    }
    croakf 'Expected a statement' if is_ref($statement);
    return $statement;
}

1;
__END__

=encoding utf8

=for stopwords PostgreSQL PostgreSQL's

=head1 NAME

DBIx::Squirrel::db - DBIx::Squirrel's database handle class

=head1 DESCRIPTION

A database handle from L<DBIx::Squirrel/connect> is blessed into this
class, a subclass of the DBI's C<DBI::db>, so it does everything a DBI
database handle does. It also inherits L<DBIx::Squirrel/pipe> and
L<DBIx::Squirrel/tap> from L<DBIx::Squirrel::Pipes>.

=head1 METHODS

=head2 prepare

    $sth = $dbh->prepare($statement);
    $sth = $dbh->prepare($statement, \%attr);

Prepares a statement, as the DBI's C<prepare> does, and returns a
L<DBIx::Squirrel::st>. L</do> and the DBI's select methods, such as
C<selectrow_array>, prepare a statement this way too.

The statement can use placeholders in any of these styles, which are
rewritten as C<?> before the DBI sees them:

    SELECT * FROM artist WHERE id = ?
    SELECT * FROM artist WHERE id = ?1
    SELECT * FROM artist WHERE id = :1
    SELECT * FROM artist WHERE id = $1
    SELECT * FROM artist WHERE id = :id

A statement uses one style of placeholder throughout; C<prepare> croaks
if it finds more than one. The same placeholder can appear more than
once.

A numbered placeholder is bound once, wherever it appears, and a named
one by name, as L<DBIx::Squirrel::st/bind> describes. Numbers start
from 1.

A placeholder with C<...> before it takes a list, which is written as a
C<?> for each of its values, separated by commas:

    SELECT * FROM artist WHERE id IN (...?)
    SELECT * FROM artist WHERE id IN (...$1)
    SELECT * FROM artist WHERE id IN (...:ids)

Its value is a reference to an array of at least one plain value. As
the number of values decides the statement the DBI prepares, a statement
taking a list is prepared with its values, by L</do>, L</iterate>,
L</results> or a select method, never by C<prepare> or C<prepare_cached>
alone, which croak. A placeholder takes a list everywhere it's used, or
nowhere. L<DBIx::Squirrel::st/Lists> says more.

Placeholders are looked for only in the SQL itself. Anything that looks
like one inside a quoted string or identifier (C<'10:30'>, C<"a:b">,
C<`c?`>), a comment (C<-- :x>, C</* $1 */>) or a PostgreSQL
dollar-quoted body (C<$$ ... $$>, C<$tag$ ... $tag$>) is left as it is,
and so is a cast, such as C<x::int>, or an identifier containing C<$>,
such as C<v$session>.

Strings are read by the rules of the database handle's driver. With
DBD::mysql and DBD::MariaDB, a backslash escapes a character in a string
(C<'it\'s'>), C<"..."> is a string, and C<#> starts a comment. With other
drivers, a backslash is an ordinary character in a string (C<'C:\'>),
except in PostgreSQL's C<E'...'> strings. MySQL's
C<NO_BACKSLASH_ESCAPES> mode isn't noticed.

A database reached through another driver, such as DBD::ODBC or
DBD::Proxy, is read by its own rules if it says what it is, as
L<DBIx::Squirrel/connect> describes, and by the standard rules if it
doesn't. To read a statement as another dialect, name that dialect's
driver in the C<ekorn_dialect> attribute:

    $dbh->prepare($statement, {ekorn_dialect => 'mysql'});

Attributes starting C<ekorn_> are DBIx::Squirrel's own, and aren't
passed on to the DBI. Passed to L<DBIx::Squirrel/connect>, they're the
defaults for every statement the handle prepares; passed to C<prepare>,
they override those for one statement.

To use a C<?>, C<:> or C<$> that isn't a placeholder, such as one of
PostgreSQL's C<?>, C<?|> and C<?&> operators, put a backslash before it,
as L<DBD::Pg> allows. The backslash and the character after it are
passed on as they are, and DBD::Pg removes the backslash:

    $dbh->prepare(q{SELECT * FROM doc WHERE data \? 'key' AND id = :id});

DBD::Pg's own placeholder options are followed too, whether set on the
database handle or passed to C<prepare>. With C<pg_placeholder_dollaronly>,
only C<$1>-style placeholders are recognised, and the statement is passed
on as written, for DBD::Pg to read, so none can take a list. With
C<pg_placeholder_nocolons>, the C<:1> and C<:name> styles aren't
placeholders, so array slices such as C<data[:2]> are left alone.

The statement can be a string, an array reference of lines, which are
joined with spaces, a code reference returning either, or a statement
handle, whose statement is prepared again. Blank space around the
statement is removed; comments are passed on to the database.

Unlike the DBI's C<prepare>, it B<always croaks> if the statement can't
be prepared, whatever C<RaiseError> is set to, with the message the DBI
raises under C<RaiseError>, such as
C<DBD::SQLite::db prepare failed: near "SELEC": syntax error>.

=head2 prepare_cached

    $sth = $dbh->prepare_cached($statement);
    $sth = $dbh->prepare_cached($statement, \%attr);
    $sth = $dbh->prepare_cached($statement, \%attr, $if_active);

As L</prepare>, using the DBI's cache of statement handles. Its errors
name C<prepare_cached>, as the DBI's do. Like C<prepare>, it croaks
given a statement taking a list.

A cached handle that an iterator is part way through isn't handed out,
or finished, as the DBI would finish an active one, which would cut the
iterator's results short. A new handle is made instead, and cached in its
place, unless C<$if_active> is 2, which asks for the cached handle as it
is. Otherwise, C<$if_active> means what it does to the DBI.

=head2 do

    $rv = $dbh->do($statement);
    $rv = $dbh->do($statement, \%attr, @bind_values);
    $rv = $dbh->do($statement, undef, @bind_values);
    $rv = $dbh->do($statement, @bind_values);

Runs a statement, and returns what the DBI's C<do> returns: the number
of rows affected, C<0E0> for none, or C<undef> on an error without
C<RaiseError>. Unlike the DBI's, the attributes may be left out: the
first argument after the statement is taken as the attributes only if
it's a hash reference or C<undef>. An error names C<do>, as the DBI's
does: C<DBD::SQLite::db do failed: ...>.

A statement with C<?> placeholders, or none, goes to the driver's own
C<do>, as with plain DBI, so the driver's row counts and options apply,
such as running several statements with DBD::SQLite's
C<sqlite_allow_multiple_statements>. A statement with numbered or named
placeholders is prepared, as L</prepare> does, and executed, with the
values bound as L<DBIx::Squirrel::st/bind> binds them; some drivers,
such as DBD::SQLite, then count the rows of an C<UPDATE ... RETURNING>
only as they're fetched, giving C<0E0>. So is a statement taking a list,
prepared for the values given.

Like the DBI's, C<do> returns no rows, even from a C<SELECT> or a
C<RETURNING> clause. Use L</prepare> and C<execute>, or the select
methods, for those.

=head2 iterate

    $it = $dbh->iterate($statement, \%attr, @bind_values, @stages);
    $it = $dbh->iterate($statement, @bind_values, @stages);

Prepares a statement, as L</prepare> does, and returns a
L<DBIx::Squirrel::Iterator>, an iterator over its results, as
L<DBIx::Squirrel::st/iterate> does. As with L</do>, the attributes may
be left out. A statement taking a list is prepared for the values
given.

=head2 results

    $results = $dbh->results($statement, \%attr, @bind_values, @stages);
    $results = $dbh->results($statement, @bind_values, @stages);

As L</iterate>, returning a L<DBIx::Squirrel::Results>, whose rows are
objects with a method for each column.

=head2 The select methods

    @row_ary  = $dbh->selectrow_array($statement, \%attr, @bind_values);
    @row_ary  = $dbh->selectrow_array($statement, @bind_values);
    $ary_ref  = $dbh->selectrow_arrayref($statement, \%attr, @bind_values);
    $hash_ref = $dbh->selectrow_hashref($statement, \%attr, @bind_values);
    $ary_ref  = $dbh->selectall_arrayref($statement, \%attr, @bind_values);
    $hash_ref = $dbh->selectall_hashref($statement, $key_field, \%attr,
                                        @bind_values);
    $ary_ref  = $dbh->selectcol_arrayref($statement, \%attr, @bind_values);

=over

=item selectrow_array

=item selectrow_arrayref

=item selectrow_hashref

=item selectall_arrayref

=item selectall_hashref

=item selectcol_arrayref

=back

Each works as the DBI's, preparing the statement as L</prepare> does, unless it's
already a statement handle, and binding the values as
L<DBIx::Squirrel::st/bind> binds them. A statement taking a list is
prepared for the values given. The DBI's C<selectall_array>
goes through C<selectall_arrayref>, so it does too. As with L</do>, the
attributes may be left out: the first argument after the statement, or
after C<selectall_hashref>'s key field, is taken as the attributes only
if it's a hash reference or C<undef>. Unlike L</prepare>,
they don't croak if the statement can't be prepared: without
C<RaiseError>, each returns what the DBI's returns, as C<do> does.

=head1 DIAGNOSTICS

=over

=item Expected one placeholder style, not several (%s)

The statement used more than one style of placeholder, such as C<?> and
C<:name>. The styles found are listed, each as an example: C<?>, C<?1>,
C<:1>, C<$1>, C<:name> or C<$name>.

=item Expected placeholders numbered from 1 (%s)

The statement had a numbered placeholder such as C<$0>.

=item Expected a statement

The statement was blank, or was a reference other than those L</prepare>
takes.

=item Expected bind values with a statement taking a list (%s)

A statement with a list placeholder, such as C<...:ids>, was given to
L</prepare> or L</prepare_cached>, which have no values to prepare it
for. Each list placeholder is named, a C<?> with its position, as in
C<...? at 2>.

=item Expected a placeholder to take a list everywhere or nowhere (%s)

A placeholder was used with C<...> in one place and without it in
another, as in C<SELECT :a WHERE x IN (...:a)>.

=item Expected no list placeholder with pg_placeholder_dollaronly (%s)

With DBD::Pg's C<pg_placeholder_dollaronly>, the statement goes to
DBD::Pg as written, so a C<$1> placeholder can't take a list.

=item Expected a reference to a HASH or ARRAY

The first argument after the statement in L</do>, L</iterate>,
L</results> or a select method was a reference, but not to a hash or an
array.

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
