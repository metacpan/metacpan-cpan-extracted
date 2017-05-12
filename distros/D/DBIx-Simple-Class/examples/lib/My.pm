package    #hide
  My;      #our schema
use parent qw(DBIx::Simple::Class);
use 5.10.1;
use strict;
use warnings;
use utf8;

#put common to all subclasses functionality here

{

  package    #hide
    My::Collision;
  use base qw(My);

  use constant TABLE   => 'collision';
  use constant COLUMNS => [qw(id data)];
  use constant WHERE   => {};
  use constant ALIASES => {data => 'column_data'};

  #CHECKS are on columns
  use constant CHECKS => {
    id   => {allow   => qr/^\d+$/x},
    data => {default => '',}           #that's ok
  };
}

{

  package                              #hide
    My::SiteUser;
  use base qw(My::User);
  my $_CHECKS = My::User->CHECKS;
  $_CHECKS->{group_id}{default} = 3;
  sub CHECKS {$_CHECKS}
  sub WHERE { {disabled => 0, group_id => $_CHECKS->{group_id}{default}} }

  #merge with parent $SQL
  __PACKAGE__->SQL(GUEST_USER => 'SELECT * FROM users WHERE login_name = \'guest\'');
}

1;
