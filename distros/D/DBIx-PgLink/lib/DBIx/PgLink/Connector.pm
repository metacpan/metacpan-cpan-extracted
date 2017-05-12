package DBIx::PgLink::Connector;

use Carp;
use Moose;
use MooseX::Method;
use DBIx::PgLink::Logger qw/trace_msg trace_level/;
use DBIx::PgLink::Local;
use DBIx::PgLink::Types;
use Scalar::Util qw/weaken/;
use Data::Dumper;

extends 'Moose::Object';

our $VERSION = '0.01';

has 'conn_name' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has 'adapter' => (
  is  => 'rw',
  isa => 'DBIx::PgLink::Adapter',
);

has 'credentials' => (
  is  => 'rw',
  isa => 'HashRef',
);

with 'DBIx::PgLink::RoleInstaller';

# functions spread out to fixed roles
with 'DBIx::PgLink::TypeMapper';
with 'DBIx::PgLink::Accessor';
with 'DBIx::PgLink::RemoteAction';


sub BUILD {
  my $self = shift;
  my $self_attr = shift;

  # load main connection record
  my $conn = $self->load_connection;

  # include additional paths
  $self->use_libs( $conn->{use_libs} );

  # apply Connector roles to myself
  $self->load_roles('Connector', $self);

  # check adapter class
  my $adapter_class = $self->require_class($conn->{adapter_class}, "DBIx::PgLink::Adapter");

  # load remote credentials
  $self->credentials( $self->load_credentials($conn->{logon_mode}) )
    or croak "Access to the " . $self->conn_name . " is denied because no login-mapping exists";

  # load attributes
  my $attr_href = $self->load_attributes;

  # pass weak reference to self
  $attr_href->{connector} = $self;
  weaken $attr_href->{connector};

  # create adapter
  trace_msg('INFO', "Creating adapter '$adapter_class' for connection " . $self->conn_name) 
    if trace_level>=2;
  $self->adapter( $adapter_class->new($attr_href) );

  # remove applied attributes from hash
  # the rest belongs to DBI or Adapter role
  $self->apply_attributes_to_adapter($attr_href, 1);

  # apply adapter roles
  $self->load_roles('Adapter', $self->adapter);

  # set role attributes
  # the rest belongs to DBI (and DBI->connect ignore unknown attributes)
  $self->apply_attributes_to_adapter($attr_href);


  return if $self_attr->{no_connect}; # for debugging and connection uninstall

  # connect to remote database
  $self->adapter->connect(
    $conn->{data_source}, 
    $self->credentials->{remote_user}, 
    $self->credentials->{remote_password}, 
    $attr_href
  );
  trace_msg('NOTICE', "Connection " . $self->conn_name . " established to data source $conn->{data_source}" 
    . " as '" . $self->credentials->{remote_user} . "'"
  ) if trace_level>=1;

  return;
}


sub load_connection {
  my $self = shift;
  my $conn = pg_dbh->selectrow_hashref(<<'END_OF_SQL',
SELECT *
FROM dbix_pglink.connections
WHERE conn_name = $1
END_OF_SQL
    {  
      Slice=>{},
      array=>[qw/use_libs/],
    }, 
    $self->conn_name,
  );
  confess "Connection named '" . $self->conn_name . "' not found" unless $conn;
  return $conn;
}


sub use_libs {
  my $self = shift;
  my $libs = shift or return;

  for my $lib (@{$libs}) {
    eval q/use lib $lib/; # change global @INC, not scoped
  }
}


sub load_roles {
  my $self = shift;
  my $role_kind = shift;
  my $object = shift;

  unless ($object->does('DBIx::PgLink::RoleInstaller')) {
    trace_msg('WARNING', "Object $object cannot install roles");
    return;
  }

  my $roles_aref = pg_dbh->selectall_arrayref(<<'END_OF_SQL', {Slice=>{}}, $self->conn_name, $role_kind);
SELECT role_name 
FROM dbix_pglink.roles
WHERE conn_name = $1
  and role_kind = $2
  and (local_user = '' or local_user = session_user)
ORDER BY role_seq, local_user
END_OF_SQL
  my %seen;
  my @role_names = grep { ! $seen{$_}++ } map { $_->{role_name} } @{$roles_aref};
  $object->install_roles(@role_names);
}


sub require_class {
  my $self = shift;
  my $class_name = shift;
  my $class_prefix = shift;

  $class_name = $class_prefix . "::" . $class_name unless $class_name =~ /::/;
  eval "require $class_name";
  confess "Cannot use class '$class_name' for connection " . $self->conn_name, $@ if $@;

  return $class_name;
}


sub load_credentials {
  my $self = shift;
  my $logon_mode = shift;

  my $cred_sth = pg_dbh->prepare_cached(<<'END_OF_SQL', {no_cursor=>1});
SELECT local_user, remote_user, remote_password
FROM dbix_pglink.users
WHERE conn_name = $1
  and local_user = $2
END_OF_SQL

  my $local_user = pg_dbh->pg_session_user; # session_user because here we in 'security definer' PL/Perl function 
  $cred_sth->execute( $self->conn_name, $local_user );
  my $cred = $cred_sth->fetchrow_hashref;

  # mapping exists
  if ($cred) { 
    trace_msg('NOTICE', "Remote credentials: local user '$local_user' mapped to remote user '$cred->{remote_user}'") 
      if trace_level >= 2;
    return $cred if defined $cred;
  }
  trace_msg('NOTICE', "Remote credentials: no remote user mapping found for local user '$local_user'") 
    if trace_level >= 2;

  return if $logon_mode eq 'deny'; # connection refused

  if ($logon_mode eq 'empty') { 
    # connect with empty user/password
    return { 
      local_user      => '',
      remote_user     => '', 
      remote_password => '',
    };
  } elsif ($logon_mode eq 'current') { 
    # connect as current user without password
    trace_msg('NOTICE', "Remote credentials: with local user name '$local_user' without password") 
      if trace_level >= 2;
    return { 
      local_user      => $local_user,
      remote_user     => $local_user,
      remote_password => '',
    };
  } elsif ($logon_mode eq 'default') { 
    # connect as default user
    my $rc = $cred_sth->execute($self->conn_name, ''); # has empty string as 'local_user'
    my $cred = $cred_sth->fetchrow_hashref;
    if ($cred) {
      trace_msg('NOTICE', "Remote credentials: as default user '$cred->{remote_user}' with default password") 
        if trace_level >= 2;
      return $cred;
    }
  }

  return; # connection refused
}


sub load_attributes {
  my $self = shift;

  # user value override global value
  my $attr_aref = pg_dbh->selectall_arrayref(<<'END_OF_SQL', {Slice=>{}}, $self->conn_name);
SELECT attr_name, attr_value
FROM dbix_pglink.attributes
WHERE conn_name = $1
  AND (local_user = '' or local_user = session_user)
ORDER BY local_user
END_OF_SQL
  my %attr = map { $_->{attr_name} => $_->{attr_value} } @{$attr_aref};
  return \%attr;
}


sub apply_attributes_to_adapter {
  my $self = shift;
  my $attr = shift;
  my $skip = shift;
  while (my ($a, $v) = each %{$attr}) {
    # NOTE: run-time role damages $self->meta->has_attribute
    next unless $self->adapter->can($a); # requires attr accessor
    unless ($skip) {
      $self->adapter->$a($v);
    }
    delete $attr->{$a}; # remove applied attribute from hash
    trace_msg('INFO', "Applied attibute $a = $v") 
      if trace_level >= 3;
  }
}


1;


__END__

=pod

=head1 NAME

DBIx::PgLink::Connector - glue between Adapter, Accessors and PL/Perl

=head1 SYNOPSIS

See L<DBIx::PgLink>

=head1 ATTRIBUTES

=over

=item conn_name

Connection name (I<dbix_pglink.connections.conn_name>).

=item adapter

Instance of L<DBIx::PgLink::Adapter> class.

=back

=head1 METHODS

=over

=item C<new>

Create new instance of Adapter class, load settings from PostgreSQL tables in I<dbix_pglink> schema,
and immediately connect to datasource.

=item C<build_accessors>

  $connector->build_accessors(
    local_schema        => $local_schema,
    remote_catalog      => $remote_catalog,
    remote_schema       => $remote_schema,
    remote_object       => $remote_object,
    remote_object_type  => \@types,
  );

Enumerates database objects of remote database, 
and build local accessors in specified C<local_schema>.

Can accept like-pattern of remote catalog, schema and object names.

Local schema created automatically if not exists. 
Building methods must be reenterable and must drop old object before creating new one.

Implemented with C<DBIx::PgLink::Accessor> role.

=item C<remote_query>

I<In PL/Perl function>
  $connector->remote_query($query);
  $connector->remote_query($query, $param_values);
  $connector->remote_query($query, $param_values, $param_types);

Execute set-returning SQL $query in remote database and returns dataset as result of PL/Perl PostgreSQL function.
Query can by parametrized and $param_values binded.
Parameter values and types is function input parameters of TEXT[] type.
Parameter type can be specified as 'SQL_FLOAT' or 'FLOAT' or integer type code. See L<DBI/"DBI Constants">.

Implemented with C<DBIx::PgLink::RemoteAction> role.

=item C<remote_exec>

I<In PL/Perl function>
  $connector->remote_exec($query);
  $connector->remote_exec($query, $param_values);
  $connector->remote_exec($query, $param_values, $param_types);

The same as C<remote_query> but returns only number of proceeded rows.
Ignore any resultset returned.

Implemented with C<DBIx::PgLink::RemoteAction> role.

=back

=head1 SEE ALSO

L<DBI>,
L<DBIx::PgLink>
L<DBIx::PgLink::Adapter>
L<DBIx::PgLink::Accessor::Tables>

=head1 AUTHOR

Alexey Sharafutdinov E<lt>alexey.s.v.br@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
