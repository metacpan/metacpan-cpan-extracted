package DBIx::PgLink::RoleInstaller;

# role to install run-time roles

use Carp;
use Moose::Role;
use DBIx::PgLink::Logger;


has 'role_prefix' => (
  is  => 'rw',
  isa => 'Str',
  default => sub { 
    my $self = shift;
    return (grep {$_ !~ /^Moose::/} $self->meta->class_precedence_list)[0]
     . '::Roles::';
  }
);


sub install_roles {
  my ($self, @role_names) = @_;

  for my $role_name (@role_names) {
    confess "Invalid role name '$role_name'" 
      unless $role_name =~ /^(\w+)(::\w+)*$/; # secure eval
    $role_name = $self->role_prefix . $role_name
      unless $role_name =~ /::/;
    trace_msg('INFO', "install role $role_name") 
      if trace_level >= 3;
    eval "require $role_name";
    confess "$self: install_role '$role_name' failed in require: $@" if $@;
    $role_name->meta->apply($self);
  }

  $self->init_roles;
}


sub init_roles { 1 }


1;
