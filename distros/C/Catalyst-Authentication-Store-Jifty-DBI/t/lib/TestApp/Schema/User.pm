package TestApp::Schema::User;

use strict;
use warnings;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
  column username     => datatype is 'text';
  column password     => datatype is 'text';
  column email        => datatype is 'text';
  column status       => datatype is 'text';
  column role_text    => datatype is 'text';
  column session_data => datatype is 'text';

  column roles =>
    references TestApp::Schema::UserRoleCollection by 'user';
};

1;
