package TestSchema;
 
use strict;
use warnings;
 
our $VERSION = 0.001;
use parent 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(); 

sub deploy_or_connect {
  my $self = shift;
  my $schema = $self->connect(@_);
  $schema->deploy();
  return $schema;
}

sub connection {
  my $self = shift;
  return $self->next::method('dbi:SQLite::memory:');
}
 
1;