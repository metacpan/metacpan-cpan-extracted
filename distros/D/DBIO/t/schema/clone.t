use strict;
use warnings;
use Test::More;

use DBIO::Test;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

{
  my $clone = $schema->clone;
  cmp_ok ($clone->storage, 'eq', $schema->storage, 'Storage copied into new schema (not a new instance)');
}

{
  is $schema->custom_attr, undef;
  my $clone = $schema->clone(custom_attr => 'moo');
  is $clone->custom_attr, 'moo', 'cloning can change existing attrs';
}

{
  my $clone = $schema->clone({ custom_attr => 'moo' });
  is $clone->custom_attr, 'moo', 'cloning can change existing attrs';
}


done_testing;
