package DBIx::QuickORM::WhereBuilder::RawSQL;
use strict;
use warnings;

our $VERSION = '0.000031';

use Scalar::Util qw/blessed/;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::WhereBuilder';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::WhereBuilder::RawSQL - A where that is SQL already.

=head1 DESCRIPTION

Takes a C<where> that is a plain string, used as SQL with no binds, or a
single C<sql()> marker (L<DBIx::QuickORM::Value>), used with its binds. It
declines everything else.

=head1 SYNOPSIS

    use DBIx::QuickORM::Value qw/sql/;

    my @rows = $orm->handle('users')->where(sql('id > ?', 10))->all;

=head1 PUBLIC METHODS

=over 4

=item $bool = DBIx::QuickORM::WhereBuilder::RawSQL->can_build_where($where)

=item ($sql, \@binds) = DBIx::QuickORM::WhereBuilder::RawSQL->build_where($where, $source, $dialect)

As L<DBIx::QuickORM::Role::WhereBuilder> describes. The SQL is wrapped in
parentheses. An empty string is no condition.

=back

=cut

sub can_build_where {
    my $class = shift;
    my ($where) = @_;
    return 1 if defined($where) && !ref($where);
    return blessed($where) && $where->isa('DBIx::QuickORM::Value') && $where->kind eq 'sql' ? 1 : 0;
}

sub build_where {
    my $class = shift;
    my ($where) = @_;
    my ($sql, @binds) = ref($where) ? ($where->value, map { [undef, $_] } @{$where->binds}) : ($where);
    return length($sql) ? ("( $sql )", \@binds) : ('', []);
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
