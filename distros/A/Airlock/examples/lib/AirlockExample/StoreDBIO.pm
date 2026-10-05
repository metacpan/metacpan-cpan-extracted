package AirlockExample::StoreDBIO;

# The four Airlock store subs on a DBIO schema.
#
#   my $schema  = AirlockExample::Schema->connect( $dsn, $user, $password );
#   my $store   = AirlockExample::StoreDBIO->new( schema => $schema );
#   my $airlock = Airlock->new( store => $store->as_subs, ... );

use Moo;
use Carp qw( croak );
use namespace::autoclean;

has schema => ( is => 'ro', required => 1 );

has source => ( is => 'ro', default => 'Airlock' );

sub _rs { $_[0]->schema->resultset( $_[0]->source ) }

sub insert {
  my ( $self, $row ) = @_;
  $self->_rs->create( { %$row } );
  return 1;
}

sub find {
  my ( $self, $field, $value ) = @_;
  croak __PACKAGE__.'->find by '.$field.' is not supported' unless $field eq 'hash' || $field eq 'user_code';
  return unless defined $value;
  my $row = $self->_rs->search( { $field => $value } )->single or return;
  return { $row->get_columns };
}

# One UPDATE ... WHERE hash = ? AND state = ?. A resultset update returns the
# number of rows it changed, as '0E0' when there were none.
sub update {
  my ( $self, $hash, $from_state, $changes ) = @_;
  # a reference to a number means "add it", done by the database in one statement
  my %set = map {
    my $value = $changes->{$_};
    $_ => ref $value eq 'SCALAR' ? \[ $_.' + ?', $$value ] : $value
  } keys %$changes;
  return $self->_rs->search( { hash => $hash, state => $from_state } )->update( \%set ) > 0 ? 1 : 0;
}

sub purge {
  my ( $self, $before ) = @_;
  return $self->_rs->search( { expires => { '<' => $before } } )->delete + 0;
}

sub as_subs {
  my ( $self ) = @_;
  return {
    insert => sub { $self->insert(@_) },
    find   => sub { $self->find(@_) },
    update => sub { $self->update(@_) },
    purge  => sub { $self->purge(@_) }
  };
}

1;
