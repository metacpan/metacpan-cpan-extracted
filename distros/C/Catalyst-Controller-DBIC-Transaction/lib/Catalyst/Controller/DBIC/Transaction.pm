{   package Catalyst::Controller::DBIC::Transaction;

    use strict;
    use warnings;
    use base 'Catalyst::Controller';

    our $VERSION = '0.4';

    __PACKAGE__->mk_accessors qw(_dbic_transaction_schemas);

    sub _parse_DBICTransaction_attr {
        my ($self, $c, $name, $value) = @_;

        $self->_dbic_transaction_schemas({}) unless
          $self->_dbic_transaction_schemas();

        $self->_dbic_transaction_schemas->{$name} = $value;

        ( ActionClass => 'Catalyst::Action::DBIC::Transaction' );
    }

};
1;

=head1 NAME

Catalyst::Controller::DBIC::Transaction - Encloses actions into transactions

=head1 SYNOPSIS

  use base qw(Catalyst::Controller::DBIC::Transaction);
  sub foo :DBICTransaction('DB') {
     do $something or die $!;
  }

=head1 DESCRIPTION

THIS MODULE SHOULD BE CONSIDERED DEPRECATED. What is currently
understood as a better practice is to enclose the code requiring a
transaction into a proper model class. The point is that business
logic should not be in the controller.

This module enables the use of automatic transaction support into
Catalyst Actions, it will associate a given action with the
appropriate action class and save the DBIC::Schema model class name
for later use.

The action will be executed inside a txn_do, and a die inside that
method will cause the transaction to be rolled back, as documented in
DBIx::Class::Schema.

This method will not, on the other hand, handle that exception, since
txn_do will rethrow it. This means that this handling is not much
intrusive in the action processing flow.

=head1 AUTHORS

Daniel Ruoso <daniel@ruoso.com>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Controller::DBIC::Transaction> to
C<bug-catalyst-controller-dbic-transaction@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
