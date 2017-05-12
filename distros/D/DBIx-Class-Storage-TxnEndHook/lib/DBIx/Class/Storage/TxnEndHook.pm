package DBIx::Class::Storage::TxnEndHook;
use 5.008005;
use strict;
use warnings;

use Try::Tiny;
use base 'DBIx::Class::Storage';

__PACKAGE__->mk_group_accessors(simple => qw/_hooks/);

our $VERSION = "0.01";

sub new {
    my $self = shift->next::method(@_);
    $self->_hooks([]);
    $self;
}

sub add_txn_end_hook {
    my ($self, $hook) = @_;

    unless ( $self->transaction_depth > 0 ) {
        $self->throw_exception('only can call add_txn_end_hook in transaction');
    }

    push @{ $self->_hooks }, $hook;
}

sub txn_commit {
    my $self = shift;
    my $is_last_txn = $self->transaction_depth == 1;
    my @ret = $self->next::method(@_);

    if ( $is_last_txn && @{ $self->_hooks } ) {
        try {
            while ( my $hook = shift @{ $self->_hooks } ) {
                $hook->();
            }
        }
        catch {
            $self->_hooks([]);
            warn $_;
        };
    }

    @ret;
}

sub txn_rollback {
    my $self = shift;
    my @ret = $self->next::method(@_);
    $self->_hooks([]);
    @ret;
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Class::Storage::TxnEndHook - transaction hook provider for DBIx::Class

=head1 SYNOPSIS

    package MyApp::Schema;
    use parent 'DBIx::Schema';
    __PACKAGE__->ensure_class_loaded('DBIx::Class::Storage::TxnEndHook');
    __PACKAGE__->ensure_class_loaded('DBIx::Class::Storage::DBI');
    __PACKAGE__->inject_base('DBIx::Class::Storage::DBI', 'DBIx::Class::Storage::TxnEndHook');

    package main

    my $schema = MyApp::Schema->connect(...)
    $schema->storage->txn_begin;
    $schema->storage->add_txn_end_hook(sub { ... });
    $schema->storage->txn_commit;

=head1 DESCRIPTION

DBIx::Class::Storage::TxnEndHook is transaction hook provider for DBIx::Class.
This module is porting from L<DBIx::TransactionManager::EndHook>.

=head1 METHODS

=over 4

=item $schema->storage->add_txn_end_hook(sub{ ... })

Add transaction hook. You can add multiple subroutine and transaction is not started, cant call
this method. These subroutines are executed after all transactions are commited. If any
transaction is failed, these subroutines are cleard.

If died in subroutine, I<warn> deid message and clear remain all subroutines. It is different from
L<DBIx::Class::Storage::TxnEndHook>. In L<DBIx::TransactionManager::EndHook>, when died in
subroutine, other subroutines are canceld and I<died>.

Why ? It's caused by L<DBIx::Class::Storage::TxnScopeGuard>. Guard object marked inactivated
after C<< $self->{storage}->txn_commit >> in C<DBIx::Class::Storage::TxnScopeGuard::commit>.
So if died in here, can't mark guard as inactivated.

=back

=head1 SEE ALSO

L<DBIx::Class>

L<DBIx::Class::Storage>

L<DBIx::TransactionManager::EndHook>

=head1 LICENSE

Copyright (C) soh335.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

soh335 E<lt>sugarbabe335@gmail.comE<gt>

=cut
