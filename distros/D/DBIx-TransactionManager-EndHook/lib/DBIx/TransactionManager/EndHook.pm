package DBIx::TransactionManager::EndHook;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.02';
use DBIx::TransactionManager;

use Try::Tiny;
use Carp;

sub DBIx::TransactionManager::add_end_hook {
    my ($self, $sub) = @_;

    unless ( $self->in_transaction ) {
        croak "only can call add_end_hook in transaction";
    }

    my $arr = $self->{_end_hooks} ||= [];
    push @$arr, $sub;
}

my $orig_txn_commit = \&DBIx::TransactionManager::txn_commit;
my $orig_txn_rollback = \&DBIx::TransactionManager::txn_rollback;

{
    no warnings 'redefine';
    *DBIx::TransactionManager::txn_commit = *txn_commit;
    *DBIx::TransactionManager::txn_rollback = *txn_rollback;
}

sub txn_commit {
    my $self = shift;
    my $is_last_txn = @{ $self->active_transactions } == 1;

    my $ret = $orig_txn_commit->($self);

    if ( $is_last_txn && defined $self->{_end_hooks} ) {
        try {
            while ( my $end_hook = shift @{ $self->{_end_hooks} } ) {
                $end_hook->();
            }
        }
        catch {
            $self->{_end_hooks} = [];
            croak $_;
        };
    }

    $ret;
}

sub txn_rollback {
    my $self = shift;
    my $ret = $orig_txn_rollback->($self);
    $self->{_end_hooks} = [];
    $ret;
}

1;
__END__

=head1 NAME

DBIx::TransactionManager::EndHook - hook of DBIx::TransactionManager commit

=head1 VERSION

This document describes DBIx::TransactionManager::EndHook version 0.02.

=head1 SYNOPSIS

    use DBIx::TransactionManager;
    use DBIx::TransactionManager::EndHook;

    my $txn = $tm->txn_scope;

    $dbh->do('...');
    $tm->add_end_hook(sub {
        # do something
    });

    $txn->commit;

=head1 DESCRIPTION

DBIx::TransactionManager::EndHook propide hook point that all transactions handled by
DBIx::TransactionManager are excuted successfully.

=head1 METHODS

=head2 $tm->add_end_hook(sub{});

Add hook subroutine to DBIx::TransactionManager. If call it without transactions, it throw
Exception.
And these hooks are executed only all transactions are executed successfully. If some
transactions are failed, these aren't executed.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<DBIx::TransactionManager>

=head1 AUTHOR

Soh Kitahara E<lt>sugarbabe335@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Soh Kitahara. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
