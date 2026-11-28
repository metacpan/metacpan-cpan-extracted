package DBIx::QuickORM::Source::Query;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;

use Object::HashBase qw{
    <sql
    <binds
};

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Source';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Source::Query - A query as a source.

=head1 DESCRIPTION

An SQL query and its binds, as L<DBIx::QuickORM::Role::Source> describes. The
SQL is used as written and its binds are sent without types. Its rows belong
to no table: they bypass the lookup table, and the ORM's default row class
wraps them unless the handle sets another.

A handle that adds nothing to the query runs it as it is. One that adds a
C<where>, an order, a limit or offset, or fields selects from it as a
subquery. Some databases need a subquery's column names to be distinct, and an
C<ORDER BY> inside one may be lost.

=head1 SYNOPSIS

    my $h = $orm->handle(\['SELECT id, name FROM users WHERE age > ?', 40]);

=head1 ATTRIBUTES

=over 4

=item $sql = $source->sql

Required, and not blank.

=item \@binds = $source->binds

Empty unless given. Must be an arrayref.

=back

=cut

sub init {
    my $self = shift;

    my $sql = $self->{+SQL};
    croak "A query source needs its SQL as a string" unless defined($sql) && !ref($sql) && $sql =~ m/\S/;
    croak "'binds' must be an arrayref"              unless ref($self->{+BINDS} //= []) eq 'ARRAY';
}

=head1 PUBLIC METHODS

=over 4

=item undef = $source->table

=item undef = $source->pk

Undef: a query source has no table, so no primary key.

=item $fields = $source->select_fields($given)

What the handle gives, or undef (every column).

=item {} = $source->field_records

Empty: the query's columns have no field records.

=back

=cut

sub table         { undef }
sub pk            { undef }
sub select_fields { $_[1] }
sub field_records { +{} }

=pod

=over 4

=item ($sql, \@binds) = $source->from_sql($dialect)

The query in parentheses with the alias C<qorm_query>.

=back

=cut

sub from_sql {
    my $self = shift;
    my ($sql, $binds) = $self->query_sql;
    return ("($sql) qorm_query", $binds);
}

=pod

=over 4

=item ($sql, \@binds) = $source->query_sql

The query itself.

=back

=cut

sub query_sql {
    my $self = shift;
    return ($self->{+SQL}, [map { [undef, $_] } @{$self->{+BINDS}}]);
}

=pod

=over 4

=item (\@rows, \&build) = $source->results($orm, \@raw, $ingest, @class)

The rows as fetched (nothing to ingest), built with the handle's C<row_class>
when given, otherwise the ORM's.

=back

=cut

sub results {
    my $self = shift;
    my ($orm, $raw, $ingest, @class) = @_;
    return ($raw, $orm->_row_builder(undef, @class));
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
