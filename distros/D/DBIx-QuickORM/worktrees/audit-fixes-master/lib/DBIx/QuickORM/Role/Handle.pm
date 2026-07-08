package DBIx::QuickORM::Role::Handle;
use strict;
use warnings;

our $VERSION = '0.000028';

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::Handle - Role defining the query/handle interface.

=head1 DESCRIPTION

Defines the common interface for handle objects used to build and run
queries against a source. Consumers implement the bulk of the interface;
this role supplies a small set of convenience aliases.

=head1 SYNOPSIS

    package My::Handle;
    use Role::Tiny::With;
    with 'DBIx::QuickORM::Role::Handle';

    sub one { ... }
    # ...and the other required methods

=head1 REQUIRED METHODS

Consumers must provide the full handle interface, including C<handle>,
C<clone>, the C<is_*> mode predicates, the C<by_id>/C<by_ids> lookups, the
C<all>/C<one>/C<count>/C<first>/C<iterate>/C<iterator> result methods, the
C<delete>/C<insert>/C<update>/C<vivify>/C<upsert> write methods, the
accessors (C<connection>, C<dialect>, C<source>, C<sql_builder>, C<sync>,
C<aside>, C<async>, C<forked>, C<data_only>, C<fields>, C<limit>, C<omit>,
C<order_by>, C<row>, C<where>), and the join methods (C<cross_join>,
C<full_join>, C<inner_join>, C<left_join>, C<right_join>).

=cut

requires qw{
    handle
    clone

    is_aside
    is_async
    is_forked
    is_sync

    by_id
    by_ids

    all
    one
    count
    first
    iterate
    iterator

    delete
    insert
    update
    vivify
    upsert

    connection
    dialect
    source
    sql_builder
    sync
    aside
    async
    forked
    data_only
    fields
    limit
    omit
    order_by
    row
    where

    cross_join
    full_join
    inner_join
    left_join
    right_join
};

=pod

=head1 PUBLIC METHODS

=over 4

=item $row = $handle->any(@args)

Alias for C<first>.

=back

=cut

sub any { shift->first(@_) }

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
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
