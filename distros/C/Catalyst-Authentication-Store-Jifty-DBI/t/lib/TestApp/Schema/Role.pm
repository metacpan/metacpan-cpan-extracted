package TestApp::Schema::Role;

use strict;
use warnings;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
  column role => datatype is 'text';

  column users =>
    references TestApp::Schema::UserRoleCollection by 'role';
};

1;
