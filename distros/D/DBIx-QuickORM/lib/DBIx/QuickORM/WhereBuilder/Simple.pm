package DBIx::QuickORM::WhereBuilder::Simple;
use strict;
use warnings;

our $VERSION = '0.000031';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::WhereBuilder';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::WhereBuilder::Simple - Fast equality conditions.

=head1 DESCRIPTION

Takes a C<where> that is a hashref of field names to plain values: each
field equals its value, and an undef value means C<IS NULL>. The SQL and
binds are exactly what L<DBIx::QuickORM::WhereBuilder::SQLAbstract> gives for
the same hashref, built without L<SQL::Abstract>.

It declines anything else: a value that is a reference (including value
markers and operator hashes), and a key that is not a word or C<table.word>
(including C<-and> and C<-or>).

=head1 SYNOPSIS

    my @rows = $orm->handle('users')
        ->where({
            name  => 'Bob',
            email => undef,
        })
        ->all;

=head1 PUBLIC METHODS

=over 4

=item $bool = DBIx::QuickORM::WhereBuilder::Simple->can_build_where($where)

=item ($sql, \@binds) = DBIx::QuickORM::WhereBuilder::Simple->build_where($where, $source, $dialect)

As L<DBIx::QuickORM::Role::WhereBuilder> describes. Fields are sorted and
quoted through the dialect.

=back

=cut

sub can_build_where {
    my $class = shift;
    my ($where) = @_;
    return 0 unless ref($where) eq 'HASH';

    for my $key (keys %$where) {
        return 0 if ref($where->{$key}) || $key !~ m/^\w+(?:\.\w+)?\z/;
    }

    return 1;
}

sub build_where {
    my $class = shift;
    my ($where, $source, $dialect) = @_;

    my (@sql, @binds);
    for my $key (sort keys %$where) {
        my $name  = join '.' => map { $dialect->quote_identifier($_) } split m/\./, $key;
        my $value = $where->{$key};
        if (defined $value) {
            push @sql   => "$name = ?";
            push @binds => [$key => $value];
        }
        else {
            push @sql => "$name IS NULL";
        }
    }

    return ('', []) unless @sql;

    # The parentheses SQL::Abstract writes, so both give the same statement.
    return (@sql == 1 ? "( $sql[0] )" : '( ( ' . join(' AND ' => @sql) . ' ) )', \@binds);
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
