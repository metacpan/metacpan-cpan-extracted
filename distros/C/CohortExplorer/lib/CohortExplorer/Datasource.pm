package CohortExplorer::Datasource;
use strict;
use warnings;

our $VERSION = 0.14;

use Carp;
use Config::General;
use CLI::Framework::Exceptions qw ( :all);
use DBI;
use Exception::Class::TryCatch;
use SQL::Abstract::More;
use Tie::Autotie 'Tie::IxHash';

#-------
sub initialize {
 my ( $class, $opts, $conf_file ) = @_;
 my $conf = Config::General->new(
                                  -ConfigFile            => $conf_file,
                                  -LowerCaseNames        => 1,
                                  -MergeDuplicateBlocks  => 1,
                                  -MergeDuplicateOptions => 1,
                                  -ExtendedAccess        => 1,
                                  -StrictObjects         => 0,
                                  -StrictVars            => 0
   )->obj('datasource')->obj( $opts->{datasource} )
   or croak "Failed to get datasource '$opts->{datasource}' configuration";

 if ( keys %{ $conf->{ConfigHash} } == 0 ) {
  croak "Invalid datasource '$opts->{datasource}'";
 }
 for (qw/namespace dsn username password/) {
  if ( !$conf->$_ ) {
   croak "'$_' missing from '$opts->{datasource}' configuration";
  }
 }
 my $pkg;

 # Untaint and load the datasource package
 if ( $conf->namespace =~ /^(.+)$/g ) {
  $pkg = $1;
  eval "require $pkg";
 }

 # Add name to config
 $conf->name( $conf->name || $opts->{datasource} );
 my $dbh =
   DBI->connect( $conf->dsn, $conf->username, $conf->password,
                 { PrintError => 0, RaiseError => 1 } )
   or croak $DBI::errstr;
 my $dialect = CohortExplorer::Dialect->new($dbh);
 my $sqla = SQL::Abstract::More->new( max_members_IN => 100 );
 my %param = (
               _dbh             => $dbh,
               _dialect         => $dialect,
               _sqla            => $sqla,
               _conf            => $conf,
               _entity_count    => undef,
               _visit_info      => undef,
               _table_info      => undef,
               _variable_info   => undef,
               _visit_variables => undef,
 );

 # Instantiate datasource
 my $obj = $pkg->new( \%param ) or croak "Failed to instantiate datasource package '$pkg' via new(): $!";
 $obj->_process($opts);
 return $obj;
}

sub _process {
 my ( $ds, $opts ) = @_;
 my $class = ref $ds;
 if ( $opts->{verbose} ) {
  print STDERR "Authenticating $opts->{username}\@$opts->{datasource} ...\n";
 }
 my $authres = $ds->authenticate(%$opts);

 # Successful authentication returns a defined response
 if ( !$authres ) {
  throw_app_init_exception( error =>
"Either the username/password combination is incorrect or you do not seem to have the correct permission to query the datasource"
  );
 }
 if ( $opts->{verbose} ) {
  print STDERR
    "Initializing application for $opts->{username}\@$opts->{datasource} ...\n";
 }

 # Response is passed to additional_param as it may contain
 # some data which the subclass hooks may use in entity, table
 # or variable specific hooks
 my $param = $ds->additional_params( $authres, %$opts );
 if ( ref $param ne 'HASH' ) {
  throw_app_hook_exception( error =>
    "Return from method 'additional_param' in class '$class' is not hash-worthy"
  );
 }
 
 for ( keys %$param ) {
  if ( $param->{$_} ) {
   $ds->{_conf}->$_( $param->{$_} );
  }
 }
 
 if ( !$ds->{_conf}->type || $ds->{_conf}->type !~ /^(standard|longitudinal)$/ )
 {
  throw_app_hook_exception( error =>
"Datasource type (i.e. standard/longitudinal) is not specified for datasource '$opts->{datasource}'"
  );
 }

 # Validate subclass hooks
 for my $p (qw/entity table variable/) {
  my $method = $p . '_structure';
  my $struct = $ds->$method;
  for (qw/-columns -from -where/) {
   if ( !$struct->{$_} ) {
    throw_app_hook_exception(
                error => "'$_' missing in method '$method' in class '$class'" );
   }
  }
 
  if ( scalar @{ $struct->{-columns} } % 2 != 0 ) {
   throw_app_hook_exception( error =>
        "'-columns' in method '$method' in class '$class' is not hash-worthy" );
  }
  $method = 'set_' . $p . '_info';
  $ds->$method($struct);
 }
 
 if ( $ds->conf->type eq 'longitudinal' ) {
  # Set visit variables if the datasource is longitudinal
  # and contains data on at least 2 visits
  if ( $ds->{_visit_info} && keys %{ $ds->{_visit_info} } >= 2 ) {
   for my $var ( keys %{ $ds->{_variable_info} } ) {
    for my $v ( keys %{ $ds->{_visit_info} } ) {

     # Add suffix (vAny, vLast, visit names) to variables
     # belonging to dynamic table
     if (
          grep ( $_ eq $ds->{_variable_info}{$var}{table},
                 @{ $ds->{_visit_info}{$v}{tables} } )
       )
     {
      push @{ $ds->{_visit_variables} }, "$ds->{_visit_info}{$v}{name}.$var";
      push @{ $ds->{_visit_variables} }, ( "vAny.$var", "vLast.$var" );
     }
    }
   }
   
   if ( $opts->{verbose} ) {
    print STDERR
   "Order of visits : " . join ( ' >= ', reverse keys %{ $ds->{_visit_info} } ) . " ...\n";
   }
  }
  
  else {
   $ds->{_conf}->type('standard');
   if ( $opts->{verbose} ) {
    print STDERR
      "No follow-up visits are found, datasource is set to standard ...\n";
   }
  }
 }

}

sub set_entity_info {
 my ( $self, $struct ) = @_;
 my $class = ref $self;
 my %map   = @{ $struct->{-columns} };

 # Check all mandatory columns are present
 for my $c (
             $self->{_conf}->type eq 'standard'
             ? qw/entity_id table variable value/
             : qw/entity_id table variable value visit/
   )
 {
  if ( !defined $map{$c} ) {
   throw_app_hook_exception( error =>
     "Column '$c' in method 'entity_structure' in class '$class' is not defined"
   );
  }
 }
 
 ##----- SQL TO FETCH ENTITY_COUNT & VISITS -----##
 my $dialect = $self->{_dialect};
 my @columns = ( "COUNT( DISTINCT $map{entity_id} )" ); 
 if ( $self->{_conf}->type eq 'longitudinal' ) {
      my $order_by = $struct->{-order_by} || "CONCAT( $map{table}, '\@\@', $map{visit} )";
      push @columns, $dialect->aggregate( "DISTINCT CONCAT( $map{table}, '\@\@', $map{visit} ) ORDER BY $order_by" , '===' );
 }

 $struct->{-columns} = \@columns;

 my ( $stmt, @bind, $entity_count, $visit );
 
 delete $struct->{-order_by};

 eval { ( $stmt, @bind ) = $self->{_sqla}->select(%$struct); };
 if ( catch my $e ) {
      throw_app_hook_exception( error => $e );
 }

 eval {
  ( $entity_count, $visit ) =
    $self->{_dbh}->selectrow_array( $stmt, undef, @bind );
 };
 if ( catch my $e ) {
  throw_app_hook_exception( error => $e );
 }
 
 if ( $entity_count == 0 ) {
      throw_app_init_exception(
       error => 'No entities are found in datasource ' . $self->{_conf}->name );
 }

 # Add entity_count
 $self->{_entity_count} = $entity_count;

 # Preserve order of visits
 tie %{ $self->{_visit_info} }, 'Tie::IxHash';
 if ($visit) {
  my @static_tables = $self->{_conf}->array('static_tables');
  for my $tv ( split '===', $visit ) {
   my ( $t, $v, $n ) = ( $tv =~ /^(.+)\@\@((.+))$/ );
   if ( !grep ( $_ eq $t, @static_tables ) ) {

    # Associated name with non word characters replaced by underscore
    $n =~ s/[\W]/_/g;
    $self->{_visit_info}{"$v"}{name} = 'v' . ucfirst lc $n,

      # Associated table(s)
      push @{ $self->{_visit_info}{"$v"}{tables} }, $t;
   }
  }
 }
}

sub set_table_info {
 my ( $self, $struct ) = @_;
 my $class   = ref $self;
 my %map     = @{ $struct->{-columns} };
 my $ds_name = $self->{_conf}->name;
 my $dbh     = $self->{_dbh};
 if ( !defined $map{table} ) {
  throw_app_hook_exception( error =>
   "Column 'table' in method 'table_structure' in class '$class' is not defined"
  );
 }
 ##----- SQL TO FETCH TABLE DATA -----##
 my ( $stmt, @bind, $tables );

 # Format column name-SQL pairs along the lines of columns in
 # SQL::Abstract::More (add names as aliases really)
 $struct->{-columns} = [ map { $map{$_} . ' AS ' . $dbh->quote_identifier($_) } keys %map ];
 
 eval { ( $stmt, @bind ) = $self->{_sqla}->select(%$struct); };
 if ( catch my $e ) {
  throw_app_hook_exception( error => $e );
 }


 eval { $tables = $dbh->selectall_arrayref( $stmt, { Slice => {} }, @bind ); };
 if ( catch my $e ) {
  throw_app_hook_exception( error => $e );
 }
 
 if ( @$tables == 0 ) {
  throw_app_init_exception(
           error => "No accessible tables are found in datasource '$ds_name'" );
 }
 
 my @static_tables = $self->{_conf}->array('static_tables');

 # Preserve order of tables
 tie %{ $self->{_table_info} }, 'Tie::IxHash';
 for my $t (@$tables) {
  for my $c ( keys %map ) {
   $self->{_table_info}{ $t->{table} }{$c} = $t->{$c};
  }

  # Set table type based on datasource type
  $self->{_table_info}{ $t->{table} }{__type__} =
    $self->{_conf}->type eq 'standard'
    || grep ( $_ eq $t->{table}, @static_tables )
    ? 'static'
    : 'dynamic';
 }

}

sub set_variable_info {
 my ( $self, $struct ) = @_;
 my $class   = ref $self;
 my $ds_name = $self->{_conf}->name;
 my %map     = @{ $struct->{-columns} };
 my $datatype = $self->datatype_map;
 my $dbh     = $self->{_dbh};

 # Throw exception if column 'table' or 'variable' is not defined
 if ( !defined $map{table} || !defined $map{variable} ) {
  throw_app_hook_exception( error =>
      "No mapping found for column 'table' or 'variable' in method 'variable_structure' in class '$class'"
  );
 }

 if ( ref $datatype ne 'HASH' ) {
      throw_app_init_exception( error =>
       "Return by method 'datatype_map' in class '$class' is not hash-worthy" );
 }

 ##----- SQL TO FETCH TABLE DATA -----##
 my ( $stmt, @bind, $vars );

 # Format column name-SQL pairs along the lines of columns in
 # SQL::Abstract::More
 $struct->{-columns} = [ map { $map{$_} . ' AS ' . $dbh->quote_identifier($_) } keys %map ];
 
 eval { ( $stmt, @bind ) = $self->{_sqla}->select(%$struct); };
 if ( catch my $e ) {
      throw_app_hook_exception( error => $e );
 }

 eval { $vars = $dbh->selectall_arrayref( $stmt, { Slice => {} }, @bind ); };
 if ( catch my $e ) {
  throw_app_hook_exception( error => $e );
 }
 
 if ( @$vars == 0 ) {
  throw_app_init_exception(
        error => "No accessible variables are found in datasource '$ds_name'" );
 }

 # Get the variable data type to sql data type mapping
 my %datatype_map = map { uc $_ => ( $datatype->{$_} || $self->dialect->sql_text ) } keys %$datatype;
 
 # Preserve order of variables
 tie %{ $self->{_variable_info} }, 'Tie::IxHash';
 for my $v (@$vars) {
  if ( !$v->{table} || !$v->{variable} ) {
   throw_app_init_exception(
           error => "Undefined table/variable found in datasource '$ds_name'" );
  }

  # 'table-variable' combination is key
  my $k = $v->{table} . '.' . $v->{variable};
  for my $c ( keys %map ) {
   $self->{_variable_info}{$k}{$c} = $v->{$c};
  }

  $self->{_variable_info}{$k}{category} = $v->{'category'} || undef;
  $self->{_variable_info}{$k}{__type__} = $datatype_map{ uc $v->{type} } || $self->dialect->sql_text;
 }
}

sub new {
 return bless $_[1], $_[0];
}

sub DESTROY {
 my ($ds) = @_;
 $ds->dbh->disconnect if $ds->{dbh};
}

sub AUTOLOAD {
 my ($ds) = @_;
 my $class = ref $ds;
 our $AUTOLOAD;
 ( my $p = $AUTOLOAD ) =~ s/.*:://;
 my @params = qw/dbh dialect sqla conf entity_count visit_info table_info variable_info visit_variables/;
 if ( $ds->{"_$p"} && grep ( $_ eq $p, @params ) ) {
  return $ds->{"_$p"};
 }
 else {
  if ( $ds->{_conf}->is_hash($p) ) {
   return { $ds->{_conf}->hash($p) };
  }
  elsif ( $ds->{_conf}->is_array($p) ) {
   return [ $ds->{_conf}->array($p) ];
  }
  else {
   return $ds->{_conf}->$p;
  }
 }
}

#--------- SUBCLASSES HOOKS --------#
sub authenticate       { 1 }

sub additional_params  { }

sub entity_structure   { }

sub table_structure    { }

sub variable_structure { }

sub datatype_map       { }

###############################
#
#   DIALECT
#
###############################
package CohortExplorer::Dialect;
use strict;
use warnings;
use Carp;

sub new {
 my ( $class, $dbh ) = @_;
 my %param = ( _name => $dbh->{Driver}{Name} );

 if ( $param{_name} =~ /^Pg(PP)?$/ ) {
      @param{ qw/_name _regexp _not_regexp _sql_text/ } = ( 'postgresql', '~', '!~',  'VARCHAR(65000)' );
 }
 elsif ( $param{_name} eq 'mysql' ) {
   $dbh->do('SET SESSION group_concat_max_len = 65000');
   @param{ qw/_aliase_in_having _like _ilike _sql_text/ } = ( 1, 'like binary', 'like', 'CHAR(65000)' );
 }
 else {
  croak "Dialect '$param{_name}' is not supported";
 }
   
  $param{_aggregate} = sub {
                         my ( $str, $sep ) = @_;
                         $sep ||= ',';
                         if ( $param{_name} eq 'postgresql' ) {
                              $sep = $sep eq '\n' ? "E'\\n'" : "'$sep'";
                              return "ARRAY_TO_STRING( ARRAY_AGG( $str ) , $sep )";
                         }
                         else {
                                return "GROUP_CONCAT( $str SEPARATOR '$sep' )";
                         }
                       };

   $param{_substring} = sub {
                         my ( $str, $sep, $pos ) = @_;
                         croak "Position can either be 1 or -1" if $pos != 1 && $pos != -1;
                         if ( $param{_name} eq 'postgresql' ) {
                              return $pos == 1
                                     ? "SUBSTRING( $str FROM '^[^$sep]*')"
                                     : "SUBSTRING( $str FROM '[^$sep]*\$')";
                         }
                         else { 
                                return "SUBSTRING_INDEX( $str, '$sep', $pos )"
                         }
                       };

                         return bless \%param, $class;
}

sub AUTOLOAD {
 my ($dialect, @args) = @_;

 our $AUTOLOAD;
 ( my $p = $AUTOLOAD ) =~ s/.*:://;

  if ( ref $dialect->{"_$p"} eq 'CODE' ) {
           return $dialect->{"_$p"}->(@args);
  }
  else {
           return $dialect->{"_$p"} || undef;
  }
 
}

#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Datasource - CohortExplorer datasource superclass

=head1 SYNOPSIS

    # The code below shows methods your datasource class overrides

    package CohortExplorer::Application::My::Datasource;
    use base qw( CohortExplorer::Datasource );

    sub authenticate {

        my ($self, $opts) = @_;

          # authentication code...

          # Successful authentication returns a scalar response (e.g. project_id)
          return $response

    }

    sub additional_params {

         my ($self, $opts, $response) = @_;

         my %params;

         # Get database handle (i.e. $self->dbh) and run some SQL queries to get additional parameters
         # to be used in entity/variable/table structure hooks

         return \%params;
    }

    sub entity_structure {

         my ($self) = @_;

         my %struct = (
                      -columns =>  {
                                     entity_id => 'd.record',
                                     variable => 'd.field_name',
                                     value => 'd.value',
                                     table => 'm.form_name'
                       },
                       -from =>  [ -join => qw/data|d <=>{project_id=project_id} metadata|m/ ],
                       -where =>  {
                                       'd.project_id' => $self->project_id
                        }
          );

          return \%struct;
     }


    sub table_structure {

         my ($self) = @_;

         return {

                  -columns => {
                                 table => 'GROUP_CONCAT( DISTINCT form_name )',
                                 variable_count => 'COUNT( field_name )',
                                 label => 'element_label'
                  },
                 -from  => 'metadata'',
                 -where => {
                             project_id => $self->project_id
                  },
                 -order_by => 'field_order',
                 -group_by => 'form_name'
        };
     }

     sub variable_structure {

         my ($self) = @_;

         return {
                 -columns => {
                               variable => 'field_name',
                               table => 'form_name',
                               label => 'element_label',
                               type => "IF( element_validation_type IS NULL, 'text', element_validation_type)",
                               category => "IF( element_enum like '%, %', REPLACE( element_enum, '\\\\n', '\n'), '')"
                 },
                -from => 'metadata',
                -where => {
                             project_id => $self->project_id
                 },
                -order_by => 'field_order'
        };
     }

     sub datatype_map {

       return {
                  int         => 'signed',
                 float        => 'decimal',
                 date_dmy     => 'date',
                 date_mdy     => 'date',
                 date_ymd     => 'date',
                 datetime_dmy => 'datetime'
       };
    }

=head1 DESCRIPTION

CohortExplorer::Datasource is the base class for all datasources. When connecting CohortExplorer to EAV repositories other than L<Opal (OBiBa)|http://obiba.org/node/63/> and L<REDCap|http://project-redcap.org/> the user is expected to create a class which inherits from CohortExplorer::Datasource. The datasources stored in Opal and REDCap can be queried using the in-built L<Opal|CohortExplorer::Application::Opal::Datasource> and L<REDCap|CohortExplorer::Application::REDCap::Datasource> API (see L<here|http://www.youtube.com/watch?v=Tba9An9cWDY>).


=head1 OBJECT CONSTRUCTION

=head2 initialize( $opts, $config_file )

CohortExplorer::Datasource is an abstract factory; C<initialize()> is the factory method that constructs and returns an object of the datasource supplied as an application option. This class reads the datasource configuration from the config file C<datasource-config.properties> to instantiate the datasource object. A sample config file is shown below:

        <datasource Medication_Participant>
         namespace=CohortExplorer::Application::Opal::Datasource
         url=http://opal_home
         entity_type=Participant
         dsn=DBI:mysql:database=opal;host=hostname;port=3306
         username=database_username
         password=database_password
       </datasource>

       <datasource Medication_Instrument>
         namespace=CohortExplorer::Application::Opal::Datasource
         url=http://opal_home
         entity_type=Instrument
         dsn=DBI:mysql:database=opal;host=hostname;port=3306
         username=database_username
         password=database_password
         name=datasourceA
       </datasource>

       <datasource Drug_A>
         namespace=CohortExplorer::Application::REDCap::Datasource
         url=http://redcap_home
         dsn=DBI:mysql:database=opal;host=myhost;port=3306
         arm_name=Drug A
         username=database_username
         password=database_password
         name=Drug
       </datasource>

       <datasource Drug_B>
         namespace=CohortExplorer::Application::REDCap::Datasource
         url=http://redcap_home
         dsn=DBI:mysql:database=opal;host=myhost;port=3306
         arm_name=Drug B
         username=database_username
         password=database_password
         name=Drug
       </datasource>

Each block holds a unique datasource configuration. In addition to reserve parameters C<namespace>, C<name>, C<dsn>, C<username>, C<password> and C<static_tables> it is up to the user to decide what other parameters they want to include in the configuration file. If the block name is an alias the user can specify the actual name of the datasource using C<name> parameter. If C<name> parameter is not found the block name is assumed to be the actual name of the datasource. In the example above, both C<Medication_Participant> and C<Medication_Instrument> connect to the same datasource (C<Medication>) but with different configurations. C<Medication_Participant> is configured to query the participant data where as, C<Medication_Instrument> can be used to query the instrument data. Similarly C<Drug A> and C<Drug B> are configured to query different arms of REDCap datasource C<Drug>. Once the class has instantiated the datasource object, the user can access the parameters by simply calling the accessors which have the same name as the parameters. For example, the datasource name can be retrived by C<$self-E<gt>name> and entity_type by C<$self-E<gt>entity_type>.

The namespace is the full package name of the in-built API the application will use to consult the parent EAV schema. The parameters present in the configuration file can be used by the subclass hooks to provide user or project specific functionality.

=head2 new()

    $object = $ds_pkg->new();

Basic constructor.

=head1 PROCESSING

After instantiating the datasource object, the class first calls L<authenticate|/authenticate( $opts )> to perform the user authentication. If the authentication is successful (i.e. returns a defined C<$response>), it sets some additional parameters, if any ( via L<additional_params|/additional_params( $opts, $response )>). The subsequent steps include calling methods; L<entity_structure|/entity_structure()>, L<table_structure|/table_structure()>, L<variable_structure|/variable_structure()>, L<datatype_map|/datatype_map()> and validating the return by each method. Upon successful validation the class attempts to set entity, table and variable specific parameters by invoking the methods below:

=head2 set_entity_info( $struct )

This method attempts to retrieve the entity parameters such as C<entity_count> and C<visit_info> (if applicable) from the database. The method accepts the input from L<entity_structure|/entity_structure()> method.

=head2 set_table_info( $struct )

This method attempts to retrieve data on table and table attributes from the database. The method accepts the input from L<table_structure|/table_structure()> method.

=head2 set_variable_info( $struct )

This method attempts to retrieve data on variable and variable attributes from the database. The method accepts the input from L<variable_structure|/variable_structure()> method.

=head1 SUBCLASS HOOKS

The subclasses override the following hooks:

=head2 authenticate( $opts )

This method should return a scalar response upon successful authentication otherwise return C<undef>. The method is called with one parameter, C<$opts> which is a hash with application options as keys and their user-provided values as hash values. B<Note> the methods below are only called if the authentication is successful.

=head2 additional_params( $opts, $response )

This method should return a hash ref containing parameter name-value pairs. Not all parameter values are known in advance so they can not be specified in the datasource configuration file. Sometimes the value of some parameter first needs to be retrieved from the database (e.g. variables and records a given user has access to). This hook can be used specifically for this purpose. The user can use the database handle (C<$self-E<gt>dbh>) and run some SQL queries to retrieve parameter name-value pairs which can then be added to the datasource object. The parameters used in calling this method are:

C<$opts> a hash with application options as keys and their user-provided values as hash values.

C<$response> a scalar received upon successful authentication. The user may want to use the scalar response to fetch other parameters (if any).

=head2 entity_structure()

The method should return a hash ref defining the entity structure in the database. The hash ref must have the following keys:

=over

=item B<-columns>

C<entity_id>

C<variable>

C<value>

C<table>

C<visit> (valid to longitudinal datasources)

=item B<-from>

table specifications (see L<SQL::Abstract::More|SQL::Abstract::More/Table_specifications>)

=item B<-where>

where clauses (see L<SQL::Abstract|SQL::Abstract/WHERE_CLAUSES>)

=item B<-order_by>

column used to order the visits (valid to longitudinal datasources)

=back

=head2 table_structure()

The method should return a hash ref defining the table structure in the database. C<table> in this context implies questionnaires or forms. For example,

      {
          -columns => [
                        table => 'GROUP_CONCAT( DISTINCT form_name )',
                        variable_count => 'COUNT( field_name )',
                        label => 'element_label'
          ],
         -from  => 'metadata',
         -where => {
                     project_id => $self->project_id
         },
        -order_by => 'field_order',
        -group_by => 'form_name'

      }

the user should make sure the SQL query constructed from hash ref is able to produce the output like the one below:

       +-------------------+-----------------+------------------+
       | table             | variable_count  | label            |
       +-------------------+-----------------+------------------+
       | demographics      |              26 | Demographics     |
       | baseline_data     |              19 | Baseline Data    |
       | month_1_data      |              20 | Month 1 Data     |
       | month_2_data      |              20 | Month 2 Data     |
       | month_3_data      |              28 | Month 3 Data     |
       | completion_data   |               6 | Completion Data  |
       +-------------------+-----------------+------------------+

B<Note> C<-columns> hash must contain C<table> definition. It is up to the user to decide what table attributes they think are suitable for the description of tables.

=head2 variable_structure()

This method should return a hash ref defining the variable structure in the database. For example,

         {
             -columns => [
                            variable => 'field_name',
                            table => 'form_name',
                            label => 'element_label',
                            category => "IF( element_enum like '%, %', REPLACE( element_enum, '\\\\n', '\n'), '')",
                            type => "IF( element_validation_type IS NULL, 'text', element_validation_type)"
             ],
            -from => 'metadata',
            -where => {
                        project_id => $self->project_id
             },
             -order_by => 'field_order'
         }

the user should make sure the SQL query constructed from the hash ref is able to produce the output like the one below:

       +---------------------------+---------------+-------------------------+---------------+----------+
       | variable                  | table         |label                    | category      | type     |
       +---------------------------+---------------+-------------------------+---------------------------
       | kt_v_b                    | baseline_data | Kt/V                    |               | float    |
       | plasma1_b                 | baseline_data | Collected Plasma 1?     | 0, No         | text     |
       |                           |               |                         | 1, Yes        |          |
       | date_visit_1              | month_1_data  | Date of Month 1 visit   |               | date_ymd |
       | alb_1                     | month_1_data  | Serum Albumin (g/dL)    |               | float    |
       | prealb_1                  | month_1_data  | Serum Prealbumin (mg/dL)|               | float    |
       | creat_1                   | month_1_data  | Creatinine (mg/dL)      |               | float    |
       +---------------------------+---------------+-----------+-------------------------------+--------+

B<Note> C<-columns> hash must define C<variable> and C<table> columns. Again it is up to the user to decide what variable attributes they think define the variables in the datasource. The categories within C<category> column must be separated by newline.

=head2 datatype_map()

This method should return a hash ref with value types as keys and equivalent SQL types (i.e. castable) as hash values. For example,

      {
          'int'        => 'signed',
          'float'      => 'decimal',
          'number_1dp' => 'decimal(10,1)',
          'datetime'   => 'datetime'
      }

=head1 DIAGNOSTICS

=over

=item *

L<Config::General> fails to parse the datasource configuration file.

=item *

Failed to instantiate datasource package '<datasource pkg>' via new().

=item *

Return by methods C<additional_params>, C<entity_structure>, C<table_structure>, C<variable_structure> and C<datatype_map> is either not hash-worthy or contains missing columns.

=item *

C<select> method in L<SQL::Abstract::More> fails to construct the SQL query from the supplied hash ref.

=item *

C<execute> method in L<DBI> fails to execute the SQL query.

=back

=head1 DEPENDENCIES

L<Carp>

L<CLI::Framework::Exceptions>

L<Config::General>

L<DBI>

L<Exception::Class::TryCatch>

L<SQL::Abstract::More>

L<Tie::IxHash>

=head1 SEE ALSO

L<CohortExplorer>

L<CohortExplorer::Application::Opal::Datasource>

L<CohortExplorer::Application::REDCap::Datasource>

L<CohortExplorer::Command::Describe>

L<CohortExplorer::Command::Find>

L<CohortExplorer::Command::History>

L<CohortExplorer::Command::Query::Search>

L<CohortExplorer::Command::Query::Compare>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013-2014 Abhishek Dixit (adixit@cpan.org). All rights reserved.

This program is free software: you can redistribute it and/or modify it under the terms of either:

=over

=item *
the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version, or

=item *
the " Artistic Licence ".

=back

=head1 AUTHOR

Abhishek Dixit
