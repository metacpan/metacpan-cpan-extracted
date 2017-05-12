package # hide from PAUSE
    DBICTest::Schema;

use base qw/DBIx::Class::Schema/;

no warnings qw/qw/;

__PACKAGE__->load_classes();

sub sqlt_deploy_hook {
  my ($self, $sqlt_schema) = @_;

}

1;
