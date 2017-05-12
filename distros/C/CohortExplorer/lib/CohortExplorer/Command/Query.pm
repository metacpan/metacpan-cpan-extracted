package CohortExplorer::Command::Query;

use strict;
use warnings;

our $VERSION = 0.14;
our ( $COMMAND_HISTORY_FILE, $COMMAND_HISTORY_CONFIG, $COMMAND_HISTORY );
our @EXPORT_OK = qw($COMMAND_HISTORY);

my $arg_max = 500;

#-------
BEGIN {
 use base qw(CLI::Framework::Command Exporter);
 use CLI::Framework::Exceptions qw( :all );
 use CohortExplorer::Datasource;
 use Exception::Class::TryCatch;
 use FileHandle;
 use File::HomeDir;
 use File::Spec;
 use Config::General;

 # Untaint and set command history file
 $COMMAND_HISTORY_FILE = $1
 if File::Spec->catfile( File::HomeDir->my_home, ".CohortExplorer_History" ) =~ /^(.+)$/;
 
 my $fh = FileHandle->new(">> $COMMAND_HISTORY_FILE");

 # Throw exception if command history file does not exist or
 # is not readable and writable
 if ( !$fh ) {
  throw_cmd_run_exception( error =>
"'$COMMAND_HISTORY_FILE' must exist with RW enabled (i.e. chmod 766) for CohortExplorer"
  );
 }
 $fh->close;

 # Read command history file
 eval {
  $COMMAND_HISTORY_CONFIG =
    Config::General->new(
                          -ConfigFile            => $COMMAND_HISTORY_FILE,
                          -MergeDuplicateOptions => "false",
                          -StoreDelimiter        => "=",
                          -SaveSorted            => 1
    );
 };
 if ( catch my $e ) {
  throw_cmd_run_exception( error => $e );
 }
 $COMMAND_HISTORY = { $COMMAND_HISTORY_CONFIG->getall };
}

sub option_spec {
 (
   [],
   [ 'cond|c=s%'      => 'impose conditions' ],
   [ 'out|o=s'        => 'provide output directory' ],
   [ 'save-command|s' => 'save command' ],
   [ 'stats|S'        => 'show summary statistics' ],
   [ 'export|e=s@'    => 'export tables by name' ],
   [ 'export-all|a'   => 'export all tables' ],
   []
 );
}

sub validate {
 my ( $self, $opts, @args ) = @_;
 my ( $ds, $csv, $verbose ) = @{ $self->cache->get('cache') }{qw/datasource csv verbose/};
 
 print STDERR "\nValidating command options/arguments ...\n\n" if $verbose;
 
 ##----- VALIDATE ARG LENGTH, EXPORT AND OUT OPTIONS -----##
 if ( !$opts->{out} || !-d $opts->{out} || !-w $opts->{out} ) {
  throw_cmd_validation_exception( error =>
"Option 'out' is required. The directory specified in 'out' option must exist with RWX enabled (i.e. chmod 777) for CohortExplorer"
  );
 }

 
 if ( $opts->{export} && $opts->{export_all} ) {
  throw_cmd_validation_exception( error =>
      'Mutually exclusive options (export and export-all) specified together' );
 }
 if ( @args == 0 || @args > $arg_max ) {
  throw_cmd_validation_exception(
                      error => "At least 1-$arg_max variable(s) are required" );
 }
 
 # Match table names supplied in the export option to
 # datasource tables and throw exception if they don't match
 if ( $opts->{export} ) {
  my @invalid_tables = grep { !$ds->table_info->{$_} } @{ $opts->export };
  if (@invalid_tables) {
   throw_cmd_validation_exception( error => 'Invalid table(s) ' . join ( ', ', @invalid_tables ) . ' in export' );
  }
 }

 # Set export to all tables
 if ( $opts->{export_all} ) {
  $opts->{export} = [ keys %{$ds->table_info} ];
 }

 # --- VALIDATE CONDITION OPTION AND ARGS ---
 # Get valid variables for validation
 my @vars = @{ $self->get_valid_variables };
 
 for my $v (@args) {
  # Throw exception if entity_id/visit are supplied as an argument
  if ( $v =~ /^(?:entity_id|visit)$/ ) {
   throw_cmd_validation_exception( error =>
"'entity_id' and 'visit' (if applicable) need not be supplied as arguments as they are already part of the query set"
   );
  }

  # Throw exception if some invalid variable is supplied as an argument
  if ( !grep( $_ eq $v, @vars ) ) {
   throw_cmd_validation_exception(
                                error => "Invalid variable '$v' in arguments" );
  }
 }

 # Condition can be imposed on all variables including
 # entity_id and visit (if applicable)
 for my $v ( keys %{ $opts->{cond} } ) {

  # Throw exception if some invalid variable is supplied as argument
  if ( !grep( $_ eq $v, @vars ) ) {
   throw_cmd_validation_exception(
                         error => "Invalid variable '$v' in condition option" );
  }

  # Regexp to validate condition option
  if ( $opts->{cond}{$v} =~
/^\s*(=|\!=|>|<|>=|<=|between|not_between|like|not_like|ilike|in|not_in|regexp|not_regexp)\s*,\s*([^\`]+)\s*$/
    )
  {
   my ( $opr, $val ) = ( $1, $2 );
   $opts->{cond}{$v} =~ s/$opr,\s+/$opr,/;

   # Validating SQL conditions
   if ( $opr && $val && $csv->parse($val) ) {
    my @val = grep ( s/^\s*|\s*$//g, $csv->fields );

    # Operators between and not_between require array but for others it is optional
    if ( $opr =~ /(?:between)/ && scalar @val != 2 ) {
     throw_cmd_validation_exception( error =>
         "Expecting min and max for '$opr' in '$v' (i.e. between, min, max )" );
    }
   }
   else {
    throw_cmd_validation_exception(
            error => "Invalid condition '$opts->{cond}{$v}' on variable '$v'" );
   }
  }
  else {
   throw_cmd_validation_exception(
            error => "Invalid condition '$opts->{cond}{$v}' on variable '$v'" );
  }
 }
}

sub run {

 # Overall running of the command
 my ( $self, $opts, @args ) = @_;
 my $rs = $self->process( $opts, @args );
 if ( $opts->{save_command} ) {
      $self->save_command( $opts, @args );
 }

 # If result-set is not empty
 if (@$rs) {
  my $dir;
  if ( $opts->{out} =~ /^(.+)$/ ) {
   $dir = File::Spec->catdir( $1, 'CohortExplorer-' . time . $$ );
  }

  # Create dir to export data
  eval { mkdir $dir };
  if ( catch my $e ) {
   warn $e . "\n";
   $dir = $1;
  }
  else {
   eval { chmod 0777, $dir };
   if ( catch my $e ) {
    warn $e . "\n";
    $dir = $1;
   }
  }
  $self->export( $opts, $rs, $dir, @args );
  
  return {
           headingText => 'summary statistics',
           rows        => $self->summary_stats( $opts, $rs, $dir )
    }
    if $opts->{stats};
 }
 return;
}

sub process {
 my ( $self, $opts, @args ) = @_;
 my ( $ds, $verbose ) = @{ $self->cache->get('cache') }{qw/datasource verbose/};
 
 ##----- PREPARE QUERY PARAMETERS FROM CONDITION OPTION AND ARGS -----##
 # Query parameters can be static, dynamic or both
 # Static type is applicable to 'standard' datasource but it may also apply to
 # 'longitudinal' datasource provided the datasource contains tables which are
 # independent of visits (i.e. static tables).
 # Dynamic type only applies to longitudinal datasources
 my $param = $self->create_query_params( $opts, @args );
 my $aliase_in_having = 1 if $ds->dialect->name eq 'mysql';
 my $dbh = $ds->dbh;
 my ( $stmt, $vars, $sth, @rows );
 
 # Construct sql query for static/dynamic or both types (if applicable)
 for my $p ( keys %$param ) {
  tie my %c, 'Tie::IxHash', @{ $param->{$p}{-columns} };
  $param->{$p}{-columns} = [
   map {
        $c{$_} . ' AS '
      . $dbh->quote_identifier($_)
     } keys %c
  ];
  eval {
   ( $param->{$p}{stmt}, @{ $param->{$p}{bind} } ) =
     $ds->sqla->select( %{ $param->{$p} } );
  };
  if ( catch my $e ) {
   throw_cmd_run_exception( error => $e );
  }

  # Filter literals from @bind. 'Visit' is not treated as a variable, only to
  # avoid clash between the column and table name, what if some table is named as visit? (I saw one!!)
  # Get all indices in @bind containing literals (i.e. variable/column names or undef)
  my @bind = @{ $param->{$p}{bind} };
  my @placeholders;
  for ( 0 .. $#bind ) {
   if ( ( $c{ $bind[$_] } && $bind[$_] ne 'visit' ) || $bind[$_] eq 'undef' ) {
         push @placeholders, $_;
   }
  }

  # Remove variable names from placeholders as they need to be hard coded
  if (@placeholders) {
   for ( 0 .. $#placeholders ) {
    my @chunks = split /\?/, $param->{$p}{stmt};
    my $val = $bind[ $placeholders[$_] ];
    my $literal = $aliase_in_having ? "`$val`" : ( $c{$val} || $val );
    
    $chunks[ $placeholders[$_] - $_ ] .= $literal;
    $param->{$p}{stmt} = join '?', @chunks;
    $param->{$p}{stmt} =~ s/([\w\)\"\`\'])\?/$1/g;
    delete( $param->{$p}{bind}->[ $placeholders[$_] ] );
   }

   # Update @bind
   @{ $param->{$p}{bind} } = grep( defined($_), @{ $param->{$p}{bind} } );
  }

  # undef needs to be hard coded as 'is null' or 'is not null'
  # depending upon the operator (i.e. = or !=)
  $param->{$p}{stmt} =~ s/\s+=\s+undef\s+/ IS NULL /g;
  $param->{$p}{stmt} =~ s/\s+!=\s+undef\s+/ IS NOT NULL /g;
  $vars->{$p} = [ map { $dbh->quote_identifier($_) } grep ( $_ ne 'entity_id', keys %c ) ];
 }

 # Either static or dynamic parameter
 if ( keys %$param == 1 ) {
  $stmt = $param->{ ( keys %$param )[0] }{stmt};
 }
 else {
  # Give priority to visit dependent tables (i.e. dynamic tables) therefore do left join
  # Inner join is done only when conditions are imposed on variables from static tables
  $stmt =
      'SELECT dynamic.entity_id, '
    . join( ', ', map { @{ $vars->{$_} } } keys %$param )
    . ' FROM '
    . join(
            (
              (
                (
                  !$param->{static}{-having}{entity_id}
                    && keys %{ $param->{static}{-having} } == 1
                )
                  || keys %{ $param->{static}{-having} } > 1
              ) ? ' INNER JOIN ' : ' LEFT OUTER JOIN '
            ),
            map { "( " . $param->{$_}{stmt} . " ) AS $_" } keys %$param
    ) . ' ON dynamic.entity_id = static.entity_id';
 }
 
 my @bind = map { @{ $param->{$_}{bind} } } keys %$param;
 
 print STDERR "Running the query with "
   . scalar @bind
   . " bind variables ...\n\n"
   if $verbose;
 
 require Time::HiRes;
 my $timeStart = Time::HiRes::time();
 
 eval {
  $sth = $dbh->prepare_cached($stmt);
  $sth->execute(@bind);
 };
 
 if ( catch my $e ) {
  throw_cmd_run_exception( error => $e );
 }
 
 my $timeEnd = Time::HiRes::time();
 
 ( my $command = lc ref $self ) =~ s/^.+:://;
 
 printf( "Found %d rows in %.2f sec matching the %s query criteria ...\n\n",
         ( $sth->rows || 0 ),
         ( $timeEnd - $timeStart ), $command )
 if $verbose;
 
 if ( $sth->rows ) {
  my @cols = @{ $sth->{NAME} };
  @rows = @{ $sth->fetchall_arrayref( [] ) };

  # Sort results by entity_id (entity_id can be number or text)
  @rows =
    DBI::looks_like_number( $rows[0]->[0] )
    ? sort { $a->[0] <=> $b->[0] } @rows
    : sort { $a->[0] cmp $b->[0] } @rows;
  unshift @rows, \@cols;
 }
 $sth->finish;
 return \@rows;
}

sub save_command {
 my ( $self, $opts, @args ) = @_;
 my ( $ds, $ds_name, $verbose ) = @{ $self->cache->get('cache') }{qw/datasource datasource_name verbose/};
 my $count = scalar keys %{ $COMMAND_HISTORY->{datasource}{$ds_name} };
 ( my $command = lc ref $self ) =~ s/^.+:://;
 print STDERR "Saving command ...\n\n" if $verbose;
 require POSIX;

 # Remove the save-command option
 delete $opts->{save_command};

 # Construct the command run by the user and store it in $COMMAND_HISTORY
 for my $opt ( keys %$opts ) {
  if ( ref $opts->{$opt} eq 'ARRAY' ) {
   $command .= " --$opt=" . join( " --$opt=", @{ $opts->{$opt} } );
  }
  elsif ( ref $opts->{$opt} eq 'HASH' ) {
   $command .= join( ' ',
                     map { "--$opt=$_='$opts->{$opt}{$_}' " }
                       keys %{ $opts->{$opt} } );
  }
  else {
   ( $_ = $opt ) =~ s/_/-/g;
   $command .= " --$_=$opts->{$opt} ";
   $command =~ s/($_)=1/$1/ if $opts->{export_all} || $opts->{stats};
  }
 }
 $command .= ' ' . join( ' ', @args );
 $command =~ s/\-\-export=[^\s]+\s*/ /g if $opts->{export_all};
 $command =~ s/\s+/ /g;
 for ( keys %{ $COMMAND_HISTORY->{datasource} } ) {
  if ( $_ eq $ds_name ) {
   $COMMAND_HISTORY->{datasource}{$_}{ ++$count } = {
                        datetime => POSIX::strftime( '%d/%m/%Y %T', localtime ),
                        command  => $command
   };
  }
 }
}

sub export {
 my ( $self, $opts, $rs, $dir, @args ) = @_;
 my ( $ds, $verbose ) = @{ $self->cache->get('cache') }{qw/datasource verbose/};
 
 ##---- WRITE QUERY PARAMETERS FILE -----##
 my $file = File::Spec->catfile( $dir, 'QueryParameters' );
 my $fh = FileHandle->new("> $file") or throw_cmd_run_exception( error => "Failed to open file: $!" );
 
 print $fh "Query Parameters" . "\n\n";
 print $fh "Arguments supplied: " . join( ', ', @args ) . "\n\n";
 print $fh "Conditions imposed: " . scalar( keys %{ $opts->{cond} } ) . "\n\n";
 my @vars = keys %{ $opts->{cond} };

 # Write all imposed conditions
 for ( 0 .. $#vars ) {
  $opts->{cond}{ $vars[$_] } =~ /^\s*([^,]+),\s*(.+)\s*$/;
  print $fh ( $_ + 1 ) . ") $vars[$_]: '$1' => $2" . "\n";
 }

 # Write all tables to be exported
 print $fh "\n"
   . "Tables exported: "
   . ( $opts->{export} ? join ', ', @{ $opts->{export} } : 'None' ) . "\n";
 $fh->close;
 
 print STDERR "Exporting query results in $dir ...\n\n" if $verbose;

 # Process result set and get entities in the result set
 my $rs_entity = $self->process_result( $opts, $rs, $dir, @args );
 if ( $opts->{export} ) {
  my ( $stmt, @bind, $sth );
  my $struct = $ds->entity_structure;
  my %map    = @{ $struct->{-columns} };

  # Construct sql query with a placeholder for table name
  # Columns follow the order: entity_id, variable, value and visit (if applicable)
  eval {
   ( $stmt, @bind ) =
     $ds->sqla->select(
            -columns =>
              [ map { $map{$_} || 'NULL' } qw/entity_id variable value visit/ ],
            -from  => $struct->{-from},
            -where => { %{ $struct->{-where} }, $map{table} => { '=' => '?' } }
     );
  };
  if ( catch my $e ) {
   throw_cmd_run_exception( error => $e );
  }

  $sth = $ds->dbh->prepare_cached($stmt);

  # The user might have supplied multiple conditions in the where clause
  # of entity_structure() method so split the $stmt by '?' and get the index of
  # 'table' placeholder
  my @chunks = split /\?/, $stmt;
  my ($placeholder) = grep ( $chunks[$_] =~ /\s+$map{table}\s+=\s+/, 0 .. $#chunks );
  for my $table ( @{ $opts->{export} } ) {

   # Ensure the user has access to at least one variable in the table to be exported
   if ( grep ( /^$table\..+$/, keys %{ $ds->variable_info } ) ) {
    $bind[$placeholder] = $table;
    eval { $sth->execute(@bind); };
    if ( catch my $e ) {
     throw_cmd_run_exception( error => $e );
    }
    
    my $rows = $sth->fetchall_arrayref( [] );
    $sth->finish;
    
    if (@$rows) {
     print STDERR "Exporting $table ...\n\n" if $verbose;
     my $subdir = File::Spec->catdir( $dir, $table );

     # Create dir to export data
     eval { mkdir $subdir };
     if ( catch my $e ) {
      warn $e . "\n";
      $dir = $1;
     }

     # Write metadata
     $self->export_metadata( $table, $subdir );

     # Process table set
     $self->process_table( $table, $rows, $subdir, $rs_entity );
    }
    else {
     print STDERR "Omitting $table (no entities) ...\n\n"
       if $verbose;
    }
   }
   else {
    print STDERR "Omitting $table (no variables) ...\n\n"
      if $verbose;
   }
  }
 }
}

sub summary_stats {
 my ( $self, $opts, $rs, $dir ) = @_;
 my ( $ds, $csv, $verbose ) = @{ $self->cache->get('cache') }{qw/datasource csv verbose/};
 print STDERR "Preparing dataset for summary statistics ...\n\n"
 if $verbose;

 # Create data for calculating summary statistics from the result set
 my ( $data, $key_index, @cols ) = $self->create_dataset($rs);
 my $var_info = $ds->variable_info;

 # Open a file for writing descriotive statistics
 my $file = File::Spec->catfile( $dir, "SummaryStatistics.csv" );
 my $fh = FileHandle->new("> $file") or throw_cmd_run_exception( error => "Failed to open file: $!" );
 $csv->print( $fh, \@cols ) or throw_cmd_run_exception( error => $csv->error_diag );
 push my @stats, [@cols];

 # Sort keys (i.e. visit/entity_id) according to their type (text/number)
 my @keys =
   DBI::looks_like_number( ( keys %$data )[-1] )
   ? sort { $a <=> $b } keys %$data
   : sort keys %$data;
 
 @cols = $key_index == 0 ? @cols : splice @cols, 1;
 
 print STDERR "calculating summary statistics for "
   . ( $#cols + 1 )
   . ' query variable(s): '
   . join( ', ', @cols )
   . " ... \n\n"
   if $verbose;

  # Key can be entity_id, visit or none depending on the command (i.e. search/compare) run.
  # For longitudinal datasources the search command calculates statistics with respect to visit,
  # hence the key is visit. Standard datasources are not visit based so no key is used.
  # Compare command uses entity_id as the key when calculating statistics for longitudinal datasources.
  
  require Statistics::Descriptive;
  
  for my $key (@keys) {
  push my @rows, ( $key_index == 0 ? () : $key );
  for my $c (@cols) {
   my $sdf = Statistics::Descriptive::Full->new;

   # Calculate statistics for categorical variables with type 'text' and boolean variables only
   if (    $var_info->{$c}
           && $var_info->{$c}{category} )
   {
    my $N = @{ $data->{$key}{$c} } || 1;
    tie my %category, 'Tie::IxHash',
      map { /^([^,]+),\s*(.+)$/, $1 => $2 } split /\s*\n\s*/,
      $var_info->{$c}{category};

    # Order of categories should remain the same
    tie my %count, 'Tie::IxHash', map { $_ => 0 } keys %category;

    # Get break-down by each category
    for ( @{ $data->{$key}{$c} } ) {
     $count{$_}++;
    }
    push @rows,
      sprintf( "N: %1s\n", scalar @{ $data->{$key}{$c} } ) . join "\n", map {
     sprintf( ( $category{$_} || $_ ) . "\: %d (%1.2f%s",
              $count{$_}, $count{$_} * 100 / $N, '%)' )
      } keys %count;
   }

   # Calculate statistics for integer/decimal variables
   elsif (
        $var_info->{$c}
        && ( $var_info->{$c}{type} =~
             /(signed|decimal|int|float|numeric|real|double)/i )
        && scalar @{ $data->{$key}{$c} } > 0
     )
   {

    # Remove single/double quotes (if any) from the numeric array
    $sdf->add_data( map { s/[\'\"]+//; $_ } @{ $data->{$key}{$c} } );
    eval {
     push @rows,
       sprintf(
             "N: %3s\nMean: %.2f\nMedian: %.2f\nSD: %.2f\nMax: %.2f\nMin: %.2f",
             $sdf->count, $sdf->mean, $sdf->median, $sdf->standard_deviation,
             $sdf->max, $sdf->min );
    };
    if ( catch my $e ) {
     throw_cmd_run_exception($e);
    }
   }

   # For all other variable types (e.g. date, datetime) get no. of observations alone
   else {
    push @rows, sprintf( "N: %3s\n", scalar @{ $data->{$key}{$c} } );
   }
  }
  $csv->print( $fh, \@rows )
    or throw_cmd_run_exception( error => $csv->error_diag );
  push @stats, [@rows];
 }
 $fh->close;
 return \@stats;
}

sub export_metadata {
 my ( $self, $table, $dir ) = @_;
 my ( $ds, $csv ) = @{ $self->cache->get('cache') }{qw/datasource csv/};
 my $var_info = $ds->variable_info;

 # First two columns are always variable and table names
 my @cols = qw/variable table/;
 for ( keys %{ { @{ $ds->variable_structure->{-columns} } } } ) {
  if ( $_ ne 'variable' && $_ ne 'table' ) {
   push @cols, $_;
  }
 }
 my $file = File::Spec->catfile( $dir, 'variables.csv' );
 my $untaint = $1 if ( $file =~ /^(.+)$/ );
 
 my $fh = FileHandle->new("> $untaint") or throw_cmd_run_exception( error => "Failed to open file: $!" );
 $csv->print( $fh, \@cols ) or throw_cmd_run_exception( error => $csv->error_diag );
 
 for my $v ( keys %$var_info ) {
  if ( $var_info->{$v}{table} eq $table ) {
   my @vals = map { $var_info->{$v}{$_} || '' } @cols;
   $csv->print( $fh, \@vals ) or throw_cmd_run_exception( error => $csv->error_diag );
  }
 }
 $fh->close;
}

#------------- SUBCLASSES HOOKS -------------#
sub usage_text          { }

sub get_valid_variables { }

sub create_query_params { }

sub process_result      { }

sub process_table       { }

sub create_dataset      { }

END {

 # Write saved commands to command history file
 eval {
  $COMMAND_HISTORY_CONFIG->save_file( $COMMAND_HISTORY_FILE, $COMMAND_HISTORY );
 };
 if ( catch my $e ) {
  throw_cmd_run_exception( error => $e );
 }
}
 
#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Command::Query - CohortExplorer base class to search and compare command classes

=head1 DESCRIPTION

This class serves as the base class to search and compare command classes. The class is inherited from L<CLI::Framework::Command> and overrides the following methods:

=head2 option_spec()

Returns application option specifications as expected by L<Getopt::Long::Descriptive>

       ( 
         [ 'cond|c=s%'      => 'impose conditions'                            ],
         [ 'out|o=s'        => 'provide output directory'                     ],
         [ 'save-command|s' => 'save command'                                 ],
         [ 'stats|S'        => 'show summary statistics'                      ],
         [ 'export|e=s@'    => 'export tables by name'                        ],
         [ 'export-all|a'   => 'export all tables'                            ] 
       )

=head2 validate( $opts, @args )

This method validates the command options and arguments and throws exceptions when validation fails.

=head2 run( $opts, @args )

This method is responsible for the overall functioning of the command. The method calls option specific methods for option specific processing.


=head1 OPTION SPECIFIC PROCESSING

=head2 process( $opts, @args )

The method attempts to construct the SQL query from the hash ref returned by L<create_query_params|/create_query_params( $opts, @args )>. Upon successful execution of the SQL query the method returns the result set (C<$rs>) which is a ref to array of arrays where each array corresponds to data on one entity or entity-visit combination (if applicable).

=head2 save_command( $opts, @args)

This method is only called if the user has specified the save command option (C<--save-command>). The method first constructs the command from command options and arguments (C<$opts> and C<@args>) and adds the command to C<$COMMAND_HISTORY> hash along with the datetime information. C<$COMMAND_HISTORY> contains all commands previously saved by the user. 

=head2 export( $opts, $rs, $dir, @args )

This method creates a export directory in the directory specified by C<--out> option and calls L<process_result|/process_result( $opts, $rs, $dir, @args )> method in the subclass. Further processing by the method depends on the presence of C<--export> option(s). If the user has specified C<--export> option, the method first constructs the SQL query from the hash ref returned by L<entity_structure|CohortExplorer::Datasource/entity_structure()> with a placeholder for table name. The method executes the same SQL query with a different bind value (table name) depending on the number of tables to be exported. The output obtained from successful execution of SQL is passed to L<process_table|/process_table( $table, $td, $dir, $rs_entity )> for further processing.

=head2 summary_stats( $opts, $rs, $dir )

This method is only called if the user has specified summary statistics option (C<--stats>). The method attempts to calculate statistics from the data frame returned by L<create_dataset|/create_dataset( $rs )>.


=head1 SUBCLASS HOOKS

=head2 usage_text()

This method should return the usage information for the command.

=head2 get_valid_variables()

This method should return a ref to the list of variables for validating arguments and condition option(s).

=head2 create_query_params( $opts, @args )

This method should return a hash ref with keys, C<static>, C<dynamic>, or both depending on the datasource type and variables supplied as arguments and conditions. As standard datasource only contains static tables so the hash ref must contain only one key, C<static> where as a longitudinal datasource may contain both keys, C<static> and C<dynamic> provided the datasource has static tables. The value of each key comprises of SQL parameters such as C<-from>, C<-where>, C<-group_by> and C<-order_by>. The parameters to this method are as follows:

C<$opts> an options hash with the user-provided command options as keys and their values as hash values.

C<@args> arguments to the command.

=head2 process_result( $opts, $rs, $dir, @args )

This method should process the result set obtained after running the SQL query and write the results into a csv file. If the variables provided as arguments and conditions belong to static tables, the method should return a ref to list of entities present in the result set otherwise return a hash ref with C<entity_id> as keys and their visit numbers as values.

In this method, 

C<$opts> an options hash with the user-provided options as keys and their values as hash values.

C<$rs> is the result set obtained upon executing the SQL query. 

C<$dir> is the export directory.

C<@args> arguments to the command.

=head2 export_metadata( $table, $dir )

This method writes table metadata (i.e. variable dictionary) in the export directory.

In this method,

C<$table> is the name of the table to be exported.

C<$dir> is the export directory.

=head2 process_table( $table, $ts, $dir, $rs_entity )

This method should process the table data obtained from running the export SQL query. The method should write the table data for all entities present in the result set into a csv file.

The parameters to the method are:

C<$table> is the name of the table to be exported.

C<$ts> is the table set obtained from executing the table export SQL query.

C<$dir> is the export directory.

C<$rs_entity> is a ref to a list/hash containing entities present in the result set.

=head2 create_dataset( $rs )

This method should create a data frame for calculating statistics. The method should return a hash ref where key is the parameter, the statistics are calculated with respect to and value is the variable name-value pairs.

=head1 DIAGNOSTICS

CohortExplorer::Command::Query throws following exceptions imported from L<CLI::Framework::Exceptions>:

=over

=item 1

C<throw_cmd_run_exception>: This exception is thrown if one of the following conditions are met:

=over

=item *

The command history file fails to load. For the save command option to work it is expected that the file C<$HOME/.CohortExplorer_History> exists with RWX enabled for CohortExplorer.

=item *

C<select> method in L<SQL::Abstract::More> fails to construct the SQL from the supplied hash ref.

=item *

C<execute> method in L<DBI> fails to execute the SQL query.

=item *

The full methods in package L<Statistics::Descriptive> fail to calculate statistics.

=back

=item 2

C<throw_cmd_validation_exception>: This exception is thrown whenever the command options/arguments fail to validate.

=back

=head1 DEPENDENCIES

L<CLI::Framework::Command>

L<CLI::Framework::Exceptions>

L<Config::General>

L<DBI>

L<Exception::Class::TryCatch>

L<FileHandle>

L<File::HomeDir>

L<File::Spec>

L<SQL::Abstract::More>

L<Statistics::Descriptive>

L<Text::CSV_XS>

L<Tie::IxHash>

=head1 SEE ALSO

L<CohortExplorer>

L<CohortExplorer::Datasource>

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

the "Artistic Licence".

=back

=head1 AUTHOR

Abhishek Dixit

=cut
