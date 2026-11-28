package DBIx::QuickORM::WhereBuilder::SQLAbstract;
use strict;
use warnings;

our $VERSION = '0.000031';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::WhereBuilder';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::WhereBuilder::SQLAbstract - Any where, through SQL::Abstract.

=head1 DESCRIPTION

Takes every C<where> and renders it as
L<DBIx::QuickORM::SQLBuilder::SQLAbstract> documents: L<SQL::Abstract>'s
syntax, with value markers anywhere. It is the last where builder in the
default chain.

=head1 SYNOPSIS

    my $orm = DBIx::QuickORM->new(..., where_builders => ['DBIx::QuickORM::WhereBuilder::SQLAbstract']);

=head1 PUBLIC METHODS

=over 4

=item $bool = DBIx::QuickORM::WhereBuilder::SQLAbstract->can_build_where($where)

Always true.

=item ($sql, \@binds) = DBIx::QuickORM::WhereBuilder::SQLAbstract->build_where($where, $source, $dialect)

As L<DBIx::QuickORM::Role::WhereBuilder> describes.

=back

=cut

# One shared SQL builder: its convert_where turns value markers into SQL::Abstract's forms, and it keeps an
# SQL::Abstract per quote character. Loaded at first use, since that builder loads this class.
my $SQL_BUILDER;

sub can_build_where { 1 }

sub build_where {
    my $class = shift;
    my ($where, $source, $dialect) = @_;

    my $builder = $SQL_BUILDER //= do { require DBIx::QuickORM::SQLBuilder::SQLAbstract; DBIx::QuickORM::SQLBuilder::SQLAbstract->new };
    my ($sql, @binds) = $builder->sqla($dialect)->where($builder->convert_where($where));
    $sql =~ s/^ WHERE //;
    return ($sql, \@binds);
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
