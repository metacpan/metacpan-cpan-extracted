package My::Test::Schema;
our $VERSION = '0.002';

use strict;
use warnings;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;

{
  my $_last_schema;

  sub last_schema {
    return $_last_schema;
  }

  sub sqlt_deploy_hook {
    my $self = shift;
    my ($schema) = @_;

    $_last_schema = $schema;

    $self->next::method(@_) if $self->next::can;
  }
}

1;
