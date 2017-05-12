package DBIx::Class::Schema::TxnEndHook;

use 5.008005;
use strict;
use warnings;

sub add_txn_end_hook {
    my $self = shift;

    $self->storage or $self->throw_exception
    ('add_txn_end_hook called on $schema without storage');

    $self->storage->add_txn_end_hook(@_);
}

1;

=encoding utf-8

=head1 NAME

DBIx::Class::Schema::TxnEndHook - provide add_txn_end_hook method to your schema class

=head1 SYNOPSIS

    package MyApp::Schema;
    use parent 'DBIx::Schema';
    __PACKAGE__->ensure_class_loaded('DBIx::Class::Storage::TxnEndHook');
    __PACKAGE__->ensure_class_loaded('DBIx::Class::Storage::DBI');
    __PACKAGE__->inject_base('DBIx::Class::Storage::DBI', 'DBIx::Class::Storage::TxnEndHook');
    __PACKAGE__->load_components('Schema::TxnEndHook');

    package main

    my $schema = MyApp::Schema->connect(...)
    $schema->txn_begin;
    $schema->add_txn_end_hook(sub { ... });
    $schema->txn_commit;

=head1 DESCRIPTION

DBIx::Class::Schema::TxnEndHook provide C<add_txn_end_hook> method to your schema class.

=head1 METHODS

=over 4

=item $schema->add_txn_end_hook(sub{ ... })

It is short cut for C<< $schema->storage->add_txn_end_hook(sub{ ... }) >>.

=back
