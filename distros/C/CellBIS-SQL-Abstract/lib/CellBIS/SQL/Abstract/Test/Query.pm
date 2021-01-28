package    # hide from PAUSE
  CellBIS::SQL::Abstract::Test::Query;

use Mojo::Base -base;

has 'users';
has 'roles';

sub new {
  my $self = shift->SUPER::new();

  $self->{users} = __PACKAGE__ . '::_users';
  $self->{roles} = __PACKAGE__ . '::_roles';

}

package CellBIS::SQL::Abstract::Test::Query::_users;
$CellBIS::SQL::Abstract::Test::Query::_users::VERSION = '1.3';
use Mojo::Base -base;

# Table fields
has table_name  => 'users';
has id          => 'id_users';
has id_roles    => 'roles_id';
has firstname   => 'firstname';
has lastname    => 'lastname';
has fullname    => 'fullname';
has username    => 'username';
has password    => 'password';
has create_date => 'date_create';
has update_date => 'date_update';
has status      => 'status';

sub create {
  my $self = shift;

  return (
    $self->table_name,
    [
      $self->id_roles,    $self->firstname,   $self->lastname,
      $self->fullname,    $self->username,    $self->password,
      $self->create_date, $self->update_date, $self->status,
    ],
    {
      1,          'Achmad Yusri', 'Afandi',  'Achmad Yusri Afandi',
      'yusrideb', 's3cr3tm3',     ['now()'], ['now()']
    }
  );
}

package CellBIS::SQL::Abstract::Test::Query::_roles;
$CellBIS::SQL::Abstract::Test::Query::_roles::VERSION = '1.3';
use Mojo::Base -base;

# Table fields
has table_name => 'roles';
has id         => 'id_roles';
has name       => 'name';
has config     => 'config';

1;
