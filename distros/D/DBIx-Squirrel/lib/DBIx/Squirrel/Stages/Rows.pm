use v5.36;

package DBIx::Squirrel::Stages::Rows;

use experimental qw(builtin);

use builtin   qw(refaddr);
use Exporter  qw(import);
use Ref::Util qw(is_plain_arrayref is_plain_hashref);

use DBIx::Squirrel::Context qw();
use DBIx::Squirrel::Errors  qw(croakf);
use DBIx::Squirrel::Gather  qw(gather);

use namespace::clean -except => 'import';

our @EXPORT = qw(pluck as_hash);    ## no critic (Modules::ProhibitAutomaticExportation)

our @EXPORT_OK   = @EXPORT;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# The column pluck has when it's given none: a reference no caller can
# give, so pluck() is told from pluck(undef), which croaks, while the
# signature still croaks for more than one.
my $ONLY = \'the only column';


# Return a stage giving one column of each row, by its name, in any
# case, or its position, from 0, whether the row is an array, a hash or
# a row object; or, given none, each row's only column.
sub pluck ($column = $ONLY) {
    return _pluck_only()
        if ref $column && refaddr($column) == refaddr($ONLY);
    croakf 'Expected a column, by name or position'
        unless defined $column && length $column;
    my $by_position = $column =~ m( \A \d+ \z )xa;
    return gather {
        my $key;    # the array index or hash key, found once a run

        # Without a signature, as it's called for each row: one costs
        # about 19 ns a call.
        return sub {
            return $_[0]->get_column($column)
                if $_[0] isa 'DBIx::Squirrel::Result';
            if (is_plain_arrayref($_[0])) {
                $key //= $by_position ? $column : _position_of($column);
                croakf 'Expected a column of the row (%s)', $column
                    if $key >= @{ $_[0] };
                return $_[0][$key];
            }
            if (is_plain_hashref($_[0])) {
                $key //= _key_of($_[0], $column, $by_position);
                return $_[0]{$key};
            }
            croakf 'Expected a row: an array, a hash or a row object';
        };
    };
}

# Return a stage giving each row's only column, counted from the row, so
# it needs no statement; a row of more columns croaks.
sub _pluck_only () {
    # Without a signature, as it's called for each row, as for pluck. A
    # row object is an array too.
    return sub {
        if (is_plain_arrayref($_[0]) || $_[0] isa 'DBIx::Squirrel::Result') {
            croakf 'Expected one column to pluck, not %d', scalar @{ $_[0] }
                unless @{ $_[0] } == 1;
            return $_[0][0];
        }
        if (is_plain_hashref($_[0])) {
            croakf 'Expected one column to pluck, not %d', scalar keys %{ $_[0] }
                unless keys %{ $_[0] } == 1;
            return (values %{ $_[0] })[0];
        }
        croakf 'Expected a row: an array, a hash or a row object';
    };
}


# Return a stage making each row a hash, keyed by the column names as
# fetchrow_hashref keys them: arrays and row objects are made into one,
# and hashes are passed on as they are. Given column names, the hash has
# only those columns, each found in any case: a hash is made anew.
sub as_hash (@columns) {
    croakf 'Expected a column name' if grep { !defined || !length } @columns;
    return gather {
        my($names, $at, $keys);    # found once a run: names, positions, keys

        # Without a signature, as for pluck.
        return sub {
            if (is_plain_hashref($_[0])) {
                return $_[0] unless @columns;
                $keys //= [map { _key_of($_[0], $_, 0) } @columns];
                my %hash;
                @hash{@$keys} = @{ $_[0] }{@$keys};
                return \%hash;
            }
            croakf 'Expected a row: an array, a hash or a row object'
                unless is_plain_arrayref($_[0])
                || $_[0] isa 'DBIx::Squirrel::Result';
            $names //= [_column_names()];
            my %hash;
            if (@columns) {
                $at //= [map { _last_position_in($names, $_) } @columns];
                @hash{@$names[@$at]} = @{ $_[0] }[@$at];
            }
            else {
                @hash{@$names} = @{ $_[0] };
            }
            return \%hash;
        };
    };
}

# Return the names of the columns of the statement whose rows the
# stages are running on.
sub _column_names () {
    my $run = DBIx::Squirrel::Context::statement_context()
        or croakf 'Expected a statement to read, for the column names';
    return @{ $run->{columns} };
}

# Return the position of a column, by its name: as it's written, or else
# in any case.
sub _position_of ($column) {
    my @names = _column_names();
    my($n)    = grep { $names[$_] eq $column } 0 .. $#names;
    ($n) = grep { lc $names[$_] eq lc $column } 0 .. $#names
        unless defined $n;
    croakf 'Expected a column of the row (%s)', $column unless defined $n;
    return $n;
}

# Return the position of a column among the names, by its name: as it's
# written, or else in any case. Of two columns of that name, the last,
# as fetchrow_hashref keeps the last of them in its hash.
sub _last_position_in ($names, $column) {
    my($n) = reverse grep { $names->[$_] eq $column } 0 .. $#$names;
    ($n) = reverse grep { lc $names->[$_] eq lc $column } 0 .. $#$names
        unless defined $n;
    croakf 'Expected a column of the row (%s)', $column unless defined $n;
    return $n;
}

# Return the key of a column in a hash row, by its name: as it's written,
# or else in any case; or by its position.
sub _key_of ($row, $column, $by_position) {
    my $key;
    if ($by_position) {
        $key = (_column_names())[$column];
    }
    elsif (exists $row->{$column}) {
        $key = $column;
    }
    else {
        ($key) = grep { lc $_ eq lc $column } sort keys %$row;
    }
    croakf 'Expected a column of the row (%s)', $column unless defined $key;
    return $key;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stages::Rows - stages reshaping rows: pluck and as_hash

=head1 SYNOPSIS

    use DBIx::Squirrel::Stages::Rows;    # pluck and as_hash

    # Each artist's name
    my @names = $dbh->iterate('SELECT id, name FROM artist', pluck('name'))->all;

    # Each row as a hash, as fetchrow_hashref gives it
    my @rows = $dbh->iterate('SELECT id, name FROM artist', as_hash)->all;

=head1 DESCRIPTION

Stages that reshape rows, whatever shape they were fetched in: as
arrays, as hashes (with the C<ekorn_slice> attribute), or as row
objects (from C<results>). Each finds what it needs from the
statement's column names, once on each run, in the context a statement
gives the run: in an iterator's own stages, or in a chain made with
C<|>, or a pipeline of yours, reading one. So a stage can be given to
statements whose columns differ.

B<The columns are the statement's, not the row's.> After a stage that
reshapes rows, C<pluck> by a name for an array row, or by a position,
picks the wrong field, and says nothing. Use L</as_hash> first, and
C<pluck> by name then reads each hash's own keys.

=head1 FUNCTIONS

Both are exported by default, and with C<:all>.

=head2 pluck

    pluck($name)
    pluck($position)
    pluck

Gives one column of each row, by its name, in any case, or by its
position, from 0, as a row object's C<get_column> does. A name for an
array row, or a position for a hash row, is found from the column
names. So it needs to be in a run reading a statement. A column the
row hasn't got croaks.

Given no column, it gives each row's only column, so a one-column
query gives plain values:

    my @names = $dbh->iterate('SELECT name FROM artist', pluck)->all;

The columns are counted from each row: an array of one element, a hash
of one key, or a row object of one column. So it needs no statement,
and a row of more columns croaks, rather than giving the first, which
would go wrong silently when a query gains a column. C<pluck(0)> gives
the first. C<pluck(undef)> and C<pluck('')> still croak, as an unset
variable is more likely a mistake.

=head2 as_hash

    as_hash
    as_hash(@names)

Makes each row a hash, keyed by the column names as
C<fetchrow_hashref> would key them, following C<FetchHashKeyName>. So
it gives what plain DBI does. An array row, or a row object, is made
into a new hash. A hash row is passed on unchanged. As with
C<fetchrow_hashref>, of two columns with the same name, the hash has
one, the last. It needs to be in a run reading a statement, for the
column names.

Given column names, the hash has only those columns, each found in any
case, and keyed as it would be without them, so it's a part of the
hash C<as_hash> gives. A hash row is made into a new hash of those
keys. A name the row hasn't got croaks, as an empty or undefined one
does. Positions aren't taken: a number is a column's name.

    my @rows = $dbh->iterate('SELECT * FROM artist', as_hash('name'))->all;

=head1 DIAGNOSTICS

=over

=item Expected a column, by name or position

C<pluck> was given an undefined column, or an empty name.

=item Expected a column name

C<as_hash> was given an undefined or empty column name.

=item Expected a column of the row (%s)

A row hasn't got the column C<pluck>, or C<as_hash>, was given.

=item Expected one column to pluck, not %d

C<pluck>, given no column, had a row of more than one column, or of
none. Name the column, or select only one.

=item Expected a statement to read, for the column names

C<as_hash>, or C<pluck> with a name for an array row or a position for
a hash row, ran where no statement was being read, such as in a
pipeline called with values. So the column names aren't known.

=item Expected a row: an array, a hash or a row object

A stage was given a value that isn't a row.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Iterator>,
L<DBIx::Squirrel::Result>, L<DBIx::Squirrel::Context>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
