package DBIx::PgLink::TypeMapper;

use Moose::Role;
use MooseX::Method;
use DBIx::PgLink::Local;
use DBIx::PgLink::Logger;
use DBI qw/:sql_types/;


#requires 'conn_name'; #only attribute accessor :-(
#requires 'adapter';


has 'data_type_map' => ( 
  is      => 'rw',
  isa     => 'HashRef[TypeMap]',
  lazy    => 1,
  default => \&load_data_type_map,
);


has 'sql_type_name_to_code' => (is=>'ro', isa=>'HashRef', lazy=>1,
  default => sub {
    my %map;
    for my $symbol (@{ $DBI::EXPORT_TAGS{sql_types} }) {
      no strict 'refs';
      my $code = &{"DBI::$symbol"}();
      (my $short = $symbol) =~ s/^SQL_//;
      $map{$symbol} = $code;  # 'SQL_INTEGER' -> 4
      $map{$short}  = $code;  # 'INTEGER' -> 4
      $map{$code}   = $code;  # '4' -> 4
    }
    return \%map;
  }
);


sub resolve_converter_method {
  my $self = shift;
  return undef unless $_[0];
  # TODO: mark convert subs (Attribute::Handlers) and check here for security
  my $coderef = $self->adapter->can($_[0])
  or trace_msg('WARNING', "Conversion method '$_[0]' not exists in Adapter class of $self->{conn_name} connection");
  return $coderef;
}


sub load_data_type_map {
  my $self = shift;
  # 1. standard types for default connection
  # 2. vendor types for default connection
  # 3. standard types for current connection
  # 4. vendor types for current connection
  my $sth = pg_dbh->prepare(<<'END_OF_SQL',
SELECT *
FROM dbix_pglink.data_type_map
WHERE (conn_name = '' or conn_name = $1)
ORDER BY conn_name, adapter_class
END_OF_SQL
    { boolean=>[qw/insertable updatable/] }
  );
  my %r = ();
  $sth->execute($self->conn_name);
  while (my $t = $sth->fetchrow_hashref) {
    next unless $self->adapter->isa($t->{adapter_class});
    # replace standard type name to code
    $t->{standard_type} = do {
      no strict 'refs';
      &{"DBI::$t->{standard_type}"}();
    };
    my $rt = uc $t->{remote_type};
    # specfic type replace general type of same name
    if ($rt =~ /^SQL_(.*)/) { # DBI constant
      $r{$rt} = $t; # standard type name with prefix
      $r{$1} = $t; # standard type name
      no strict 'refs';
      $r{ &{"DBI::$rt"}() } = $t; # standard type code
    } else {
      $r{$rt} = $t; # vendor type
    }
  }

  for my $t (keys %r) {
    $r{$t}->{conv_to_local_coderef} = $self->resolve_converter_method( $r{$t}->{conv_to_local} );
    $r{$t}->{conv_to_remote_coderef} = $self->resolve_converter_method( $r{$t}->{conv_to_remote} );
  }

  return \%r;
}


# input: vendor type name or standard type name or standard type code
sub data_type_to_local {
  my ($self, $type) = @_;
  return undef unless $type;
  return $self->data_type_map->{$type}
         # check each name second time as UPPERCASE
         || $self->data_type_map->{uc $type};
}


method expanded_data_type_to_local => named(
  native_type_name => {isa=>'Str'}, # base type or custom type or domain
  base_type_name   => {isa=>'Str'}, # always base type
  TYPE_NAME        => {isa=>'Any'}, # SQL Standard type name (can be undef)
  DATA_TYPE        => {isa=>'Any'}, # SQL Standard type code (or type name sometimes, can be undef)
) => sub {
  my ($self, $p) = @_;

  my $t;

  $t = $self->data_type_to_local($p->{native_type_name})
    and return $t;

  # shortcut for PostgreSQL
  # (base type, but after lookup by native_type_name)
  if ($self->adapter->isa('DBIx::PgLink::Adapter::Pg')) {
    return {
      local_type     => $p->{base_type_name},
      remote_type    => $p->{native_type_name},
      conv_to_local  => $p->{conv_to_local},
      conv_to_remote => $p->{conv_to_remote},
    };
  }

  $t = $self->data_type_to_local($p->{base_type_name})
    and return $t;

  $t = $self->data_type_to_local($p->{TYPE_NAME})
    and return $t;

  $t = $self->data_type_to_local($p->{DATA_TYPE})
    and return $t;

  # unknown type
  return {
    local_type  => 'TEXT',
    remote_type => $p->{native_type_name} || $p->{base_type_name} || $p->{TYPE_NAME},
  };
};

1;
