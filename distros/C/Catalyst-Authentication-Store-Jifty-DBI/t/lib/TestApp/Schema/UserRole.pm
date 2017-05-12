package TestApp::Schema::UserRole;

use strict;
use warnings;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
  column user => references TestApp::Schema::User;
  column role => references TestApp::Schema::Role;
};

1;
