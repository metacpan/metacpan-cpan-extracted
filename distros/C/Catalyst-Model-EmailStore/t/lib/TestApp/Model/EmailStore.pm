package TestApp::Model::EmailStore;

use base 'Catalyst::Model::EmailStore';

__PACKAGE__->config(
  dsn           => 'dbi:XXX:XXX',
  user          => '',
  password      => '',
  options       => {},
  cdbi_plugins  => [],
  upgrade_relationships => 1
);


1;
