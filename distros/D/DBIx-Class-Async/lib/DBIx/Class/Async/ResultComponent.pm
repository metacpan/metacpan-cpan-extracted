package DBIx::Class::Async::ResultComponent;

=head1 NAME

DBIx::Class::Async::ResultComponent - Non-blocking row-level CRUD for DBIx::Class::Async

=head1 VERSION

Version 0.43

=cut

use strict;
use warnings;
use parent 'DBIx::Class';

=head1 SYNOPSIS

    # In your Result Class
    __PACKAGE__->load_components(qw/Async::ResultComponent Core/);

    # In your application
    $row->delete->then(sub {
        say "Deleted successfully";
    })->get;

    $row->update({ status => 'active' })->then(sub {
        my $updated_row = shift;
        say "Update complete";
    })->get;

=head1 DESCRIPTION

C<DBIx::Class::Async::ResultComponent> is a mixin designed to override the
standard synchronous C<delete> and C<update> methods provided by L<DBIx::Class::Row>.

In a standard event-loop environment (like L<IO::Async> or L<Mojolicious>),
traditional DBIC row operations block the entire process while waiting for
database I/O. This component intercepts those calls and reroutes them
through the asynchronous bridge, returning L<Future> objects instead.

=head1 ARCHITECTURAL NOTES

=head2 Why use a Component?

By loading this into the Result class, we ensure that every instance of a row
becomes "async-aware". Without this, a developer might successfully use
async ResultSets for fetching data, but inadvertently block the loop the
moment they call C<$row-E<gt>update>.

=head2 Thread Safety and Identity

The component specifically builds a fresh identity hashref for every call.
This ensures that even in complex race conditions, the background worker
receives a precise C<WHERE> clause targeting only the specific primary key
of the object in question.

=head2 Persistence and Caching

Because the C<delete> or C<update> happens in a background worker, the
in-memory state of B<other> objects in the main process may become stale.
Always ensure you synchronise state by re-fetching or clearing the L<DBIx::Class>
schema cache if subsequent logic relies on database-level consistency.

=cut

=head1 METHODS

=head2 delete

    my $future = $row->delete;

Overrides the default delete behavior. It performs the following steps:
1. Extracts the primary key(s) using C<get_column> to ensure current identity.
2. Locates the C<async_db> bridge via the schema.
3. Dispatches the delete task to the background worker pool.
4. Returns a L<Future> that resolves with the number of rows affected.

If the C<async_db> bridge is not found, it falls back to a standard ResultSet-based delete.

sub delete {
    my ($self) = @_;

    my $source_name = $self->result_source->source_name;
    my $async_db    = $self->result_source->schema->{async_db};

    my %ident;
    foreach my $col ($self->result_source->primary_columns) {
        $ident{$col} = $self->get_column($col);
    }

    if ($async_db) {
        return $async_db->delete($source_name, \%ident);
    }

    return $self->result_source->resultset->search(\%ident)->delete;
}

=head2 update

    my $future = $row->update({ column => $value });

Overrides the default update behavior.
1. Inflates the provided columns into the object memory.
2. Identifies "dirty" (changed) columns.
3. If no columns are changed, returns a C<Future->done($self)> immediately.
4. Reroutes the update through the asynchronous ResultSet to the worker pool.

Returns a L<Future> that resolves to the updated row object.

=cut

sub update {
    my ($self, $upd) = @_;

    $self->set_inflated_columns($upd) if $upd;

    my $ident = $self->ident_condition;
    $ident = { $self->ident_condition } unless ref $ident eq 'HASH';

    my %dirty = $self->get_dirty_columns;
    return Future->done($self) unless keys %dirty;

    return $self->result_source->resultset->search($ident)->update(\%dirty);
}

=head1 SEE ALSO

L<DBIx::Class::Async>, L<Future>, L<IO::Async>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/DBIx-Class-Async>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/DBIx-Class-Async/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Async::ResultComponent

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/DBIx-Class-Async/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Async>

=item * Search MetaCPAN

L<https://metacpan.org/dist/DBIx-Class-Async/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of DBIx::Class::Async::ResultComponent
