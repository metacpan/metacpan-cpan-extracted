#!perl

use Test::More tests => 4;

package My::Schema::User;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/+DBICx::TxnInsert Core/);
__PACKAGE__->table('user');
__PACKAGE__->add_columns(qw/id name/);
__PACKAGE__->set_primary_key('id');

package My::Storage;
use base 'DBIx::Class::Storage::DBI';

sub last_insert_id {
  my ($self,$source,$col) = @_;
  return $self->dbh_do(sub { $_[1]->last_insert_id(undef,undef,undef,undef); });
}

package My::Schema;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw/User/);

package main;

my $schema = My::Schema->clone;
$schema->storage(My::Storage->new($schema));
$schema->storage->connect_info( ['DBI:Mock:', '', ''] );
my $dbh  = $schema->storage->dbh;
my $user_rs = $schema->resultset('User');

my $row = $user_rs->create( { name => 'user1' } );

my $hist = $dbh->{mock_all_history};
is( scalar(@$hist),        3,            '3 query' );
is( $hist->[0]->statement, 'BEGIN WORK', '1 - begin' );
like( $hist->[1]->statement, qr/INSERT INTO/, '2 - insert' );
is( $hist->[2]->statement, 'COMMIT', '3 - commit' );

