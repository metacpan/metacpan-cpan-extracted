package Test::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_namespaces();

sub deploy_or_connect {
   my $self = shift;

   my $schema = $self->connect(@_);
   $schema->deploy();
   return $schema;
}

1;
