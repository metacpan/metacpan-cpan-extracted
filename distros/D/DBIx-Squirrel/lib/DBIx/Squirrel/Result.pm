use v5.36;

package DBIx::Squirrel::Result;

use Digest::SHA qw(sha1_hex);

use DBIx::Squirrel::Errors qw(croakf);
use DBIx::Squirrel::Util   qw(install_sub is_name);

use namespace::clean;

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# Each row class made, with the position of each of its columns' names.
my %position_of;

# Return a column's value, by its name, in any case, or its position,
# from 0.
sub get_column ($self, $column) {
    my $n
        = $column =~ m( \A \d+ \z )xa
        ? $column
        : $position_of{ref $self}{lc $column};
    croakf 'Expected a column of the row (%s)', $column
        if !defined $n || $n >= @$self;
    return $self->[$n];
}

# For DBIx::Squirrel::Results: return the row class, a subclass of the
# invocant, for rows with the columns named, making it the first time,
# with an accessor for each column.
sub class_for ($base, $names) {
    my $class = sprintf '%s::Row_%s', $base,
        substr(sha1_hex(join "\0", @$names), 0, 16);
    return $class if $position_of{$class};
    my %position;
    for my $n (reverse 0 .. $#$names) {
        $position{$names->[$n]} = $n;
    }
    {
        no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
        @{ "${class}::ISA" } = ($base);
    }
    for my $name (keys %position) {
        next if !is_name($name) || $base->can($name);
        my $n = $position{$name};
        install_sub("${class}::$name", sub ($row) { $row->[$n] });
    }
    $position_of{$class} = \%position;
    return $class;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Result - the base class of the rows a result set hands out

=head1 SYNOPSIS

    my $results = $dbh->results('SELECT id, Name FROM artist');
    while (my($artist) = $results->next) {
        say $artist->id, ' ', $artist->name;
    }

=head1 DESCRIPTION

A L<DBIx::Squirrel::Results> hands out each row as an array, blessed
into a class with a method for each column. Each method is named as
its column is, in lower case. The class is a subclass of this one. Or
it's a subclass of the class given as the C<ekorn_result_class>
attribute, which must itself be a subclass of this one. That class can
give rows methods of their own:

    package My::Artist {
        our @ISA = 'DBIx::Squirrel::Result';
        sub shout ($self) { return uc $self->name }
    }

    my $results = $dbh->results($sql, {ekorn_result_class => 'My::Artist'});

There's one class for each base class and list of column names. It's
made the first time a result set fetches rows with those columns, and
kept, so a row can be kept after its result set has gone.

A column gets no method if its name can't be a method's, such as
C<count(*)>. Nor does it if the base class already has a method of that
name, such as C<can>, C<isa> or C<get_column>, or one of its own. When
two columns have one name, as in C<SELECT a.id, b.id>, the method is
the first's. L</get_column> reaches every column.

To give such a column a method, give it another name in the statement,
with C<AS>:

    my $row = $dbh->results(
        'SELECT COUNT(*) AS total, class AS kind, b.id AS b_id FROM ...'
    )->single;
    say $row->total, ' ', $row->kind, ' ', $row->b_id;

=head1 METHODS

=head2 get_column

    $value = $row->get_column($name);
    $value = $row->get_column($position);

Returns a column's value, by its name, in any case, or by its
position, from 0, as the row is an array.

=head2 class_for

For L<DBIx::Squirrel::Results>, which makes the row classes. It's not
for use elsewhere.

=head1 DIAGNOSTICS

=over

=item Expected a column of the row (%s)

L</get_column> was given a name or a position the row doesn't have.

=back

=head1 SEE ALSO

L<DBIx::Squirrel::Results>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
