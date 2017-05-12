package TestApp::DB;

use strict;

use base 'Rose::DB';

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db
(
  driver => 'sqlite',
  dsn    => 'dbi:SQLite:t/auth.db',
);

1;
