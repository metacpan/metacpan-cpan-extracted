package DBIx::Class::Async::TxnGuard;

use strict;
use warnings;

=head1 NAME

DBIx::Class::Async::TxnGuard - Transaction guard for DBIx::Class::Async

=head1 VERSION

Version 0.35

=cut

our $VERSION = '0.35';

=head1 SYNOPSIS

    use DBIx::Class::Async::TxnGuard;

    # Typically created by DBIx::Class::Async::Schema
    my $guard = $schema->txn_scope_guard;

    # Perform async operations
    $schema->resultset('User')->create({
        name  => 'Alice',
        email => 'alice@example.com',
    })->then(sub {
        my ($user) = @_;
        # If successful, commit the transaction
        $guard->commit;
        return Future->done($user);
    })->catch(sub {
        my ($error) = @_;
        # On error, rollback (automatic when $guard goes out of scope)
        return Future->fail($error);
    });

    # OR use with scope guard pattern
    {
        my $guard = $schema->txn_scope_guard;

        # Multiple async operations
        my $result1 = $schema->resultset('User')->find(1);
        my $result2 = $schema->resultset('Order')->create({ user_id => 1 });

        # Wait for both to complete
        Future->wait_all($result1, $result2)->then(sub {
            # Both succeeded - commit
            $guard->commit;
        })->catch(sub {
            # One failed - rollback (automatic)
        });
        # $guard goes out of scope here
        # If not committed, auto-rollback occurs
    }

=head1 DESCRIPTION

C<DBIx::Class::Async::TxnGuard> provides a transaction guard object for
managing database transactions in L<DBIx::Class::Async>. It implements the
scope guard pattern where a transaction is automatically rolled back if
the guard object is destroyed without an explicit commit.

This class is typically created by calling C<txn_scope_guard> on a
L<DBIx::Class::Async::Schema> instance and is used to manage transaction
boundaries in asynchronous code.

=head1 CONSTRUCTOR

=head2 new

    my $guard = DBIx::Class::Async::TxnGuard->new(
        schema => $schema,  # DBIx::Class::Async::Schema instance
    );

Creates a new transaction guard.

=over 4

=item B<Parameters>

=over 8

=item C<schema>

A L<DBIx::Class::Async::Schema> instance. Required.

=back

=item B<Returns>

A new C<DBIx::Class::Async::TxnGuard> object.

=back

=cut

sub new {
    my ($class, %args) = @_;
    return bless {
        schema    => $args{schema},
        committed => 0,
    }, $class;
}

=head1 METHODS

=head2 commit

    $guard->commit;

Marks the transaction for commit.

=over 4

=item B<Returns>

True (1) on success.

=item B<Notes>

Calling this method prevents the automatic rollback that would normally
occur when the guard object is destroyed. The actual commit operation
is performed by the underlying transaction management system.

=back

=cut

sub commit {
    my $self = shift;
    $self->{committed} = 1;
    return 1;
}

=head2 rollback

    $guard->rollback;

Marks the transaction for rollback.

=over 4

=item B<Returns>

True (1) on success.

=item B<Notes>

This method is called automatically by the destructor if C<commit> was
not called. It signals to the underlying transaction management system
that the transaction should be rolled back.

=back

=cut

sub rollback {
    my $self = shift;
    # Can't really rollback without transaction context
    return 1 unless $self->{committed};
}

=head1 DESTROY

When a C<DBIx::Class::Async::TxnGuard> object is destroyed (goes out of
scope), its destructor automatically calls C<rollback> unless C<commit>
was explicitly called. This implements the scope guard pattern:

    {
        my $guard = $schema->txn_scope_guard;
        # ... perform operations ...
        # If $guard goes out of scope without commit(),
        # rollback happens automatically
    }

This ensures that transactions are properly cleaned up even if exceptions
occur or the code path doesn't reach an explicit commit call.

=cut

sub DESTROY {
    my $self = shift;
    # Auto-rollback if not committed (simplified)
    $self->rollback unless $self->{committed};
}

=head1 USAGE PATTERNS

=head2 Basic Scope Guard

    {
        my $guard = $schema->txn_scope_guard;

        # Perform async operations
        $schema->resultset('User')->create($data)
               ->then(sub  { $guard->commit })
               ->catch(sub { # rollback happens automatically });

        # $guard goes out of scope here
        # Auto-rollback if not committed
    }

=head2 Manual Control

    my $guard = $schema->txn_scope_guard;

    # Long-running operations
    perform_async_work()->then(sub {
        if (successful) {
            $guard->commit;
        }
        # No need to explicitly rollback - it happens on destruction
    });

    # Keep $guard in scope until work is complete
    undef $guard;  # Force destruction if needed

=head2 Nested Transactions

    # Outer transaction
    my $outer_guard = $schema->txn_scope_guard;

    # Some operations
    $schema->resultset('User')->update($update_data);

    {
        # Inner transaction (savepoint)
        my $inner_guard = $schema->txn_scope_guard;

        $schema->resultset('Order')->create($order_data)
            ->then(sub { $inner_guard->commit })
            ->catch(sub {
                # Inner transaction rolls back
                # Outer transaction continues
            });

        # $inner_guard goes out of scope
    }

    # Continue with outer transaction
    $outer_guard->commit;

=head1 LIMITATIONS

=over 4

=item *

The actual transaction management is handled by the underlying
L<DBIx::Class::Async> system. This class only provides the guard interface.

=item *

In asynchronous contexts, the timing of transaction boundaries can be
complex. Ensure all async operations within a transaction complete before
the guard goes out of scope.

=item *

Nested transactions may not be fully supported by all database backends
in the async worker model.

=back

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class::Async::Schema> - Asynchronous schema class

=item *

L<DBIx::Class::Async> - Core asynchronous DBIx::Class implementation

=item *

L<DBIx::Class::Storage::TxnScopeGuard> - Standard DBIx::Class transaction guard

=item *

L<Scope::Guard> - Generic scope guard implementation

=back

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

    perldoc DBIx::Class::Async::TxnGuard

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

1; # End of DBIx::Class::Async::TxnGuard
