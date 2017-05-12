package MyApp::Role::Verification::TransactionalActions::DBIC;

use namespace::autoclean;
use Moose::Role;

with 'MyApp::Role::Verification::TransactionalActions';

has schema => (
    is      => 'ro',
    lazy    => 1,
    default => sub { return shift->result_source->schema }
);

sub _wrap_in_transaction {
    my ( $self, $code ) = @_;
    return sub {
        my @args = @_;
        $self->schema->txn_do( sub { $code->(@args) } );
    };
}

1;

