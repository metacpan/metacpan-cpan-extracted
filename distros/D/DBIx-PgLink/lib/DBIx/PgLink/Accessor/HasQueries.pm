package DBIx::PgLink::Accessor::HasQueries;

# role for Accessor object

use Moose::Role;
use MooseX::Method;
use DBIx::PgLink::Types;
use DBIx::PgLink::Accessor::Query;


has '_queries' => (
  is      => 'ro',
  isa     => 'HashRef[DBIx::PgLink::Accessor::Query]',
  default => sub { {} },
);


method load_query => positional (
  { isa => 'Action', required => 1 },
) => sub {
  my ($self, $action) = @_;
  unless (exists $self->_queries->{$action}) {
    $self->_queries->{$action} = DBIx::PgLink::Accessor::Query->load(
      parent => $self,
      action => $action,
    );
  }
  return $self->_queries->{$action};
};


method create_query => positional (
  { isa => 'HashRef', required => 1 },
) => sub {
  my ($self, $hashref) = @_;
  # create object from hash
  my $q = DBIx::PgLink::Accessor::Query->new(
    %{$hashref},
    parent => $self,
  );
  $self->_queries->{$q->action} = $q;
};


after 'save_metadata' => sub {
  my $self = shift;
  $_->save for values %{$self->_queries};
};


1;
