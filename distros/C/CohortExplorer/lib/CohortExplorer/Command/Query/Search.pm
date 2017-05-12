package CohortExplorer::Command::Query::Search;

use strict;
use warnings;

our $VERSION = 0.14;

use base qw(CohortExplorer::Command::Query);
use CLI::Framework::Exceptions qw( :all );

#-------
# Command is available to both standard and longitudinal datasources
sub usage_text {
 q\
     search [--out|o=<directory>] [--export|e=<table>] [--export-all|a] [--save-command|s] [--stats|S] [--cond|c=<cond>] 
            [variable] : search entities with/without conditions on variables
              
              
     NOTES
         The variables entity_id and visit (if applicable) must not be provided as arguments as they are already part of
         the query-set. However, the user can impose conditions on both variables.

         Other variables in arguments/cond (option) must be referenced as <table>.<variable>.

         The conditions can be imposed using the operators such as =, !=, >, <, >=, <=, between, not_between, like, 
         not_like, ilike, in, not_in, regexp and not_regexp. 

         The keyword undef can be used to search for null values.

         The directory specified in 'out' option must have RWX enabled (i.e. chmod 777) for CohortExplorer.


     EXAMPLES
         search --out=/home/user/exports --stats --save-command --cond=DS.Status='=, CTL, MCI' GDS.Score
                 
         search --out=/home/user/exports --stats --save-command --cond=CER.Score='<=, 30' GDS.Score

         search --out=/home/user/exports --export-all --cond=SD.Sex='=, Male' CER.Score DIS.Status

         search -o/home/user/exports -eDS -eSD -c entity_id='like, DCR%' DIS.Status

         search -o/home/user/exports -Ssa -c visit='in, 1, 3, 5' DIS.Status 

         search -o/home/user/exports -c CER.Score='between, 25, 30' DIS.Status
 \;
}

sub get_valid_variables {
 my ($self) = @_;
 my $ds     = $self->cache->get('cache')->{datasource};
 my @vars   = keys %{ $ds->variable_info };
 return $ds->type eq 'standard'
   ? [ qw/entity_id/, @vars ]
   : [ qw/entity_id visit/, @vars ];
}

sub create_query_params {
 my ( $self, $opts, @args ) = @_;
 my ( $ds, $csv ) = @{ $self->cache->get('cache') }{qw/datasource csv/};
 my $dialect = $ds->dialect;
 my $struct  = $ds->entity_structure;
 my %map     = @{ $struct->{-columns} };
 my $aliase_in_having = $dialect->aliase_in_having || undef;

 my ( @vars, %param );

 # Extract all variables from args/cond (option) except
 # entity_id and visit as they are dealt separately
 for my $v ( @args, keys %{ $opts->{cond} } ) {
  if ( !grep ( $_ eq $v, ( 'entity_id', 'visit', @vars ) ) ) {
   push @vars, $v;
  }
 }

 for (@vars) {
  ##---- BUILD 'WHERE' FOR TABLES AND VARIABLES ----##
  my ( $t, $v ) = @{ $ds->variable_info->{$_} }{qw/table variable/};
  my $table_type = $ds->table_info->{$t}{__type__};
  
  push @{ $param{$table_type}{-where}{ $map{table} }{-in} },    $t;
  push @{ $param{$table_type}{-where}{ $map{variable} }{-in} }, $v;
  
  my $col_sql = 'CAST( NULLIF( '
    . $dialect->aggregate(
        (
         (
           $table_type eq 'static' ? 'DISTINCT' : ''
         )
         . " CASE WHEN CONCAT($map{table}, '.', $map{variable} )  = '$_' THEN TRIM( $map{value} ) ELSE NULL END "
        )
    )
    . ", '' ) AS "
    . $ds->variable_info->{$_}{__type__} . ' )';

  push @{ $param{$table_type}{-columns} }, $_ => $col_sql;
  
  # Take into account the dialect's support for the use of aliases in 'having' clause
  # Postgresql does not allow the use of column names but mysql does making the query more 
  # readable and easy to understand/debug 
  my $alias = $aliase_in_having ? "`$_`" : $col_sql;
  
  ##---- BUILD 'HAVING' FOR CONDITIONS ON VARIABLES ----##
  if (    $opts->{cond}
       && $opts->{cond}{$_}
       && $csv->parse( $opts->{cond}{$_} ) )
  {
   my ( $opr, @conds ) = grep ( s/^\s*|\s*$//g, $csv->fields );
   $param{$table_type}{-having}{$alias} = { ( $dialect->$opr || $opr ) =>  \@conds };
  }
 }
 
 ##---- ADD IDENTIFIER, VISIT AND GROUP BY COLUMNS ----##
 for ( keys %param ) {
  if ( $_ eq 'static' ) {
   $param{$_}{-group_by} = 'entity_id';
  }
  else {
   $param{$_}{-group_by} = [qw/entity_id visit/];
   unshift @{ $param{$_}{-columns} }, visit => $map{visit};
   my $alias = $aliase_in_having ? 'visit' : $map{visit};
   # Set condition on visit
   if (    $opts->{cond}
        && $opts->{cond}{visit}
        && $csv->parse( $opts->{cond}{visit} ) )
   {
    my ( $opr, @conds ) = grep ( s/^\s*|\s*$//g, $csv->fields );
    $param{$_}{-having}{$alias} = { ( $dialect->$opr || $opr ) =>  \@conds };
   }
  }
  
  ###--- PARAMETERS COMMON TO BOTH STATIC AND DYNAMIC TABLE TYPES ---###
  unshift @{ $param{$_}{-columns} }, entity_id => $map{entity_id};
  
  if ( $opts->{cond} && $opts->{cond}{entity_id} ) {
   # Set condition on entity_id
   my $alias = $aliase_in_having ? 'entity_id' : $map{entity_id};
   my ( $opr, @conds ) = split /\s*,\s*/, $opts->{cond}{entity_id};
   $param{$_}{-having}{$alias} = { ( $dialect->$opr || $opr ) =>  \@conds };
  }
  
  $param{$_}{-from} = $struct->{-from};
  $param{$_}{-where} =
    $struct->{-where}
    ? { %{ $param{$_}{-where} }, %{ $struct->{-where} } }
    : $param{$_}{-where};

  # Make sure condition clause in 'tables' has no duplicate placeholders
  $param{$_}{-where}{ $map{table} }{-in} = [
    keys %{ { map { $_ => 1 } @{ $param{$_}{-where}{ $map{table} }{-in} } } } ];
 }
   
   return \%param;
}

sub process_result {
 my ( $self, $opts, $rs, $dir, @args ) = @_;
 my $csv = $self->cache->get('cache')->{csv};
 my %rs_entity;

 # Write result set
 my $file = File::Spec->catfile( $dir, 'QueryOutput.csv' );
 my $fh = FileHandle->new("> $file") 
   or throw_cmd_run_exception( error => "Failed to open file: $!" );

 # Returns a ref to hash with key as entity_id and value either:
 # list of visit numbers if the result-set contains visit column
 # (i.e. dynamic tables- Longitudinal datasources) or,
 # empty list (i.e. static tables)
 for ( 0 .. $#$rs ) {
  if ( $_ > 0 ) {
   if ( $rs->[0][1] eq 'visit' ) {
    push @{ $rs_entity{ $rs->[$_][0] } }, $rs->[$_][1];
   }
   else {
    push @{ $rs_entity{ $rs->[$_][0] } }, ();
   }
  }
  $csv->print( $fh, $rs->[$_] )
    or throw_cmd_run_exception( error => $csv->error_diag );
 }
 
 $fh->close;
 return \%rs_entity;
}

sub process_table {
 my ( $self, $table, $ts, $dir, $rs_entity ) = @_;
 my ( $ds, $csv ) = @{ $self->cache->get('cache') }{qw/datasource csv/};
 my $table_info = $ds->table_info;
 my $var_info   = $ds->variable_info;
 my ( @vars, %data );
 
 for ( keys %$var_info ) {
  if ( $var_info->{$_}{table} eq $table ) {
       push @vars, $var_info->{$_}{variable};
  }
 }
 
 for (@$ts) {
  if ( $table_info->{$table}{__type__} eq 'static' ) {
         $data{ $_->[0] }{ $_->[1] } = $_->[2];
  }
  else {
         $data{ $_->[0] }{ $_->[3] }{ $_->[1] } = $_->[2];
  }
 }

 # Add visit column to the header if the table is dynamic
 my $file = File::Spec->catfile( $dir, 'data.csv' );
 my $untaint = $1 if ( $file =~ /^(.+)$/ );
 my $fh = FileHandle->new("> $untaint")
   or throw_cmd_run_exception( error => "Failed to open file: $!" );
   
 my @cols =
   $table_info->{$table}{__type__} eq 'static'
   ? ( qw/entity_id/, @vars )
   : ( qw/entity_id visit/, @vars );
 
 $csv->print( $fh, \@cols )
   or throw_cmd_run_exception( error => $csv->error_diag );
 
 my @sorted_entity =
   DBI::looks_like_number( ( keys %$rs_entity )[-1] )
   ? sort { $a <=> $b } keys %$rs_entity
   : sort { $a cmp $b } keys %$rs_entity;

 # Write data for entities present in the result set
 for my $entity (@sorted_entity) {
  if ( $table_info->{$table}{__type__} eq 'static' ) {
   my @vals = ( $entity, map { $data{$entity}{$_} } @vars );
   $csv->print( $fh, \@vals )
     or throw_cmd_run_exception( error => $csv->error_diag );
  }
  else {
   for my $visit (
                     @{ $rs_entity->{$entity} }
                   ? @{ $rs_entity->{$entity} }
                   : keys %{ $data{$entity} }
     )
   {
    my @vals = ( $entity, $visit, map { $data{$entity}{$visit}{$_} } @vars );
    $csv->print( $fh, \@vals )
      or throw_cmd_run_exception( error => $csv->error_diag );
   }
  }
 }
 
 $fh->close;
}

sub create_dataset {
 my ( $self, $rs ) = @_;

 # If the result set contains visit column group data
 # by visit (i.e. dynamic tables/longitudinal datasources)
 my $index = $rs->[0][1] eq 'visit' ? 1 : 0;
 my %data;
 
 for my $r ( 1 .. $#$rs ) {
  my $key = $index == 0 ? 1 : $rs->[$r][$index];
  for ( $index + 1 .. $#{ $rs->[0] } ) {
   push @{ $data{$key}{ $rs->[0][$_] } }, $rs->[$r][$_] || ();
  }
 }

 return ( \%data, $index, splice @{ $rs->[0] }, 1 );
}

#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Command::Query::Search - CohortExplorer class to search entities

=head1 SYNOPSIS

B<search [OPTIONS] [VARIABLE]>

B<s [OPTIONS] [VARIABLE]>

=head1 DESCRIPTION

The search command enables the user to search entities using the variables of interest. The user can also impose conditions on the variables. Moreover, the command also enables the user to view summary statistics and export data in csv format. The command is available to both standard/cross-sectional and longitudinal datasources.

This class is inherited from L<CohortExplorer::Command::Query> and overrides the following methods:

=head2 usage_text()

This method returns the usage information for the command.

=head2 get_valid_variables()

This method returns a ref to the list of variables for validating arguments and condition option(s).

=head2 create_query_params( $opts, @args )

This method returns a hash ref with keys, C<static>, C<dynamic> or both depending on the datasource type and variables supplied as arguments and conditions. The value of each key is a hash containing SQL parameters such as C<-columns>, C<-from>, C<-where>, C<-group_by> and C<-having>.

=head2 process_result( $opts, $rs, $dir, @args ) 
        
This method returns a hash ref with keys as C<entity_id> and values can be a list of visit numbers provided the result-set contains visit column (dynamic tables), or empty list (static tables).

=head2 process_table( $table, $ts, $dir, $rs_entity ) 
        
This method writes the table set (C<$ts>) into a csv file. The data includes C<entity_id> of all entities present in the result set followed by values of all variables. In case of dynamic tables the csv also contains C<visit> column.

=head2 create_dataset( $rs )
        
This method returns a hash ref with C<visit> as keys and variable-value hash as its value provided the query set contains at least one dynamic variable. For all other cases it simply returns a hash ref with variable name-value pairs.
  
=head1 OPTIONS

=over

=item B<-o> I<DIR>, B<--out>=I<DIR>

Provide directory to export data

=item B<-e> I<TABLE>, B<--export>=I<TABLE>

Export table by name

=item B<-a>, B<--export-all>

Export all tables

=item B<-s>, B<--save--command>

Save command

=item B<-S>, B<--stats>

Show summary statistics

=item B<-c> I<COND>, B<--cond>=I<COND>
            
Impose conditions using the operators: C<=>, C<!=>, C<E<gt>>, C<E<lt>>, C<E<gt>=>, C<E<lt>=>, C<between>, C<not_between>, C<like>, C<not_like>, C<ilike>, C<in>, C<not_in>, C<regexp> and C<not_regexp>.

=back

=head1 NOTES

The variables C<entity_id> and C<visit> (if applicable) must not be provided as arguments as they are already part of the query-set.  However, the user can impose conditions on both variables.

The directory specified in C<out> option must have RWX enabled for CohortExplorer.

=head1 EXAMPLES

 search --out=/home/user/exports --stats --save-command --cond=DS.Status='=, CTL, MCI' GDS.Score
                 
 search --out=/home/user/exports --stats --save-command --cond=CER.Score='<=, 30' GDS.Score

 search --out=/home/user/exports --export-all --cond=SD.Sex='=, Male' CER.Score DIS.Status

 search -o/home/user/exports -eDS -eSD -c entity_id='like, DCR%' DIS.Status

 search -o/home/user/exports -Ssa -c visit='in, 1, 3, 5' DIS.Status 

 search -o/home/user/exports -c CER.Score='between, 25, 30' DIS.Status

=head1 DIAGNOSTICS

This class throws C<throw_cmd_run_exception> exception imported from L<CLI::Framework::Exceptions> if L<Text::CSV_XS> fails to construct a csv string from the list containing variable values.

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
