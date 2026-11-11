use v5.36;

package DBIx::Squirrel::Stages::Rows;

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

# Return a stage giving one column of each row, by its name, in any
# case, or its position, from 0, whether the row is an array, a hash or
# a row object.
sub pluck ($column) {
    croakf 'Expected a column, by name or position'
        unless defined $column && length $column;
    my $by_position = $column =~ m( \A \d+ \z )xa;
    return gather {
        my $key;    # the array index or hash key, found once a run
        return sub ($row) {
            return $row->get_column($column)
                if $row isa 'DBIx::Squirrel::Result';
            if (is_plain_arrayref($row)) {
                $key //= $by_position ? $column : _position_of($column);
                croakf 'Expected a column of the row (%s)', $column
                    if $key >= @$row;
                return $row->[$key];
            }
            if (is_plain_hashref($row)) {
                $key //= _key_of($row, $column, $by_position);
                return $row->{$key};
            }
            croakf 'Expected a row: an array, a hash or a row object';
        };
    };
}

# Return a stage making each row a hash, keyed by the column names as
# fetchrow_hashref keys them: arrays and row objects are made into one,
# and hashes are passed on as they are.
sub as_hash : prototype() () {
    return gather {
        my $names;    # the column names, found once a run
        return sub ($row) {
            return $row if is_plain_hashref($row);
            croakf 'Expected a row: an array, a hash or a row object'
                unless is_plain_arrayref($row)
                || $row isa 'DBIx::Squirrel::Result';
            $names //= [_column_names()];
            my %hash;
            @hash{@$names} = @$row;
            return \%hash;
        };
    };
}

# Return the names of the columns of the statement whose rows the
# stages are running on.
sub _column_names () {
    my $iterator = DBIx::Squirrel::Context::iterator
        or croakf 'Expected an iterator, for the column names';
    return $iterator->column_names;
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
statement's column names, once on each run, through
L<DBIx::Squirrel::Context/iterator> and
L<DBIx::Squirrel::Iterator/column_names>. So a stage can be given to
statements whose columns differ.

=head1 FUNCTIONS

Both are exported by default, and with C<:all>.

=head2 pluck

    pluck($name)
    pluck($position)

Gives one column of each row, by its name, in any case, or by its
position, from 0, as a row object's C<get_column> does. A name for an
array row, or a position for a hash row, is found from the column
names. So it needs the stages to be run by an iterator. A column the
row hasn't got croaks.

=head2 as_hash

    as_hash

Makes each row a hash, keyed by the column names as
C<fetchrow_hashref> would key them, following C<FetchHashKeyName>. So
it gives what plain DBI does. An array row, or a row object, is made
into a new hash. A hash row is passed on unchanged. As with
C<fetchrow_hashref>, of two columns with the same name, the hash has
one. It needs the stages to be run by an iterator, for the column
names.

=head1 DIAGNOSTICS

=over

=item Expected a column, by name or position

C<pluck> was given no column, or an empty name.

=item Expected a column of the row (%s)

A row hasn't got the column C<pluck> was given.

=item Expected an iterator, for the column names

C<as_hash>, or C<pluck> with a name for an array row or a position for
a hash row, ran in a pipeline no iterator was running, such as one
called with values. So the column names aren't known.

=item Expected a row: an array, a hash or a row object

A stage was given a value that isn't a row.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Iterator>, L<DBIx::Squirrel::Result>,
L<DBIx::Squirrel::Context>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
