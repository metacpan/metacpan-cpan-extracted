package CohortExplorer::Command::Query::Compare;

use strict;
use warnings;

our $VERSION = 0.14;

use base qw(CohortExplorer::Command::Query);
use CLI::Framework::Exceptions qw( :all );

#-------
# Command is only available to longitudinal datasources
sub usage_text {
 q\
     compare [--out|o=<directory>] [--export|e=<table>] [--export-all|a] [--save-command|s] [--stats|S] [--cond|c=<cond>]
             [variable] : compare entities across visits with/without conditions on variables


     NOTES
       The variables entity_id and visit (if applicable) must not be provided as arguments as they are already part of the
       query-set. However, the user can impose conditions on both variables.

       Other variables in arguments/cond (option) must be referenced as <table>.<variable> or <visit>.<table>.<variable>
       where visit can be vAny, vLast, v1, v2, v3 ... vMax. Here vMax is the maximum visit number for which data is
       available.

       Conditions can be imposed using the operators: =, !=, >, <, >=, <=, between, not_between, like, not_like, ilike, in,
       not_in, regexp and not_regexp. The keyword undef can be used to specify null.

       When condition is imposed on variable with no prefix such as vAny, vLast, v1, v2 and v3 the command assumes the
       condition applies to all visits of the variable.

       The directory specified in 'out' option must have RWX enabled (i.e. chmod 777) for CohortExplorer.


     EXAMPLES
       compare --out=/home/user/exports --stats --save-command --cond=v1.CER.Score='>, 20' v1.SC.Date

       compare --out=/home/user/exports --export=CER --cond=SD.Sex='=, Male' v1.CER.Score v3.DIS.Status
 
       compare --out=/home/user/exports --export=CER --cond=v2.CER.Score'!=, undef' vLast.DIS.Status

       compare -o/home/user/exports -Ssa -c vLast.CER.Score='in, 25, 30, 40' DIS.Status 

       compare -o/home/user/exports -eCER -eSD -c vLast.CER.Score='between, 25, 30' DIS.Status

    \;
}

sub get_valid_variables {
 my ($self) = @_;
 my $ds = $self->cache->get('cache')->{datasource};
 return [ 'entity_id', keys %{ $ds->variable_info },
          @{ $ds->visit_variables } ];
}

sub create_query_params {
 my ( $self, $opts, @args ) = @_;
 my ( $ds, $csv ) = @{ $self->cache->get('cache') }{qw/datasource csv/};
 my $visit_info       = $ds->visit_info;
 my $dialect          = $ds->dialect;
 my $struct           = $ds->entity_structure;
 my %map              = @{ $struct->{-columns} };
 my $aliase_in_having = $dialect->aliase_in_having || undef;
 my $visit = $dialect->aggregate( "DISTINCT $map{visit} " 
                                 . ( $struct->{-order_by} ? " ORDER BY $struct->{-order_by} " : '' ), '@@' );
 
 my ( @vars, %param );
 # Extract all variables from args/cond (option) except
 # entity_id and visit as they are dealt separately
 my $visit_regex = join( '|', map { $visit_info->{$_}{name} } keys %$visit_info );
 
 for my $v ( @args, keys %{ $opts->{cond} } ) {
  $v =~ s/^(?:vLast|vAny|$visit_regex)\.//;
  if ( !grep ( $_ eq $v, ( 'entity_id', 'visit', @vars ) ) ) {
   push @vars, $v;
  }
 }
 
 for my $var (@vars) {
  ##---- BUILD 'WHERE' FOR TABLES AND VARIABLES ----##
  my ( $t, $v ) = @{ $ds->variable_info->{$var} }{qw/table variable/};
  my $table_type = $ds->table_info->{$t}{__type__};
  
  push @{ $param{$table_type}{-where}{ $map{table} }{-in} },    $t;
  push @{ $param{$table_type}{-where}{ $map{variable} }{-in} }, $v;
  
  my $col_sql = 'CAST( NULLIF( '
    . $dialect->aggregate(
       (
        ( $table_type eq 'static' ? 'DISTINCT' : '' )
        . " CASE WHEN CONCAT( $map{table}, '.', $map{variable} ) " 
        . (
              $table_type eq 'static' ? " = '$var' " : " = '$var' AND $map{visit} = ? " )
          . " THEN TRIM( $map{value} ) ELSE NULL END "
       )
    )
    . ", '' ) AS "
    . $ds->variable_info->{$var}{__type__} . ' )';
  
  if ( $table_type eq 'static' ) {
   push @{ $param{$table_type}{-columns} }, $var => $col_sql;
  }
  
  else {
   # Each column corresponds to one visit variable
   for my $i ( keys %$visit_info ) {
    ( my $vv = $col_sql ) =~ s/\?/'$i'/;
    push @{ $param{$table_type}{-columns} },
      "$visit_info->{$i}{name}.$var" => $vv;
   }
  }
  
  ##---- BUILD 'HAVING' FOR CONDITIONS ON VARIABLES AND VISIT VARIABLES ----##
  if ( $table_type eq 'static' ) {
   if (    $opts->{cond}
        && $opts->{cond}{$var}
        && $csv->parse( $opts->{cond}{$var} ) )
   {

    # Set condition on static variable (i.e. variable from static table)
    my ( $opr, @conds ) = grep ( s/^\s*|\s*$//g, $csv->fields );
    my $alias = $aliase_in_having ? "`$var`" : $col_sql;
    $param{$table_type}{-having}{$alias} =
      {  ( $dialect->$opr || $opr ) => \@conds };
   }
  }
  
  else {

   # Build conditions for visit variables e.g. v1.var, vLast.var, vAny.var etc.
   # Values inside array references are joined as 'OR' and hashes as 'AND'
   my @visit_vars =
     grep( /^((vAny|vLast|$visit_regex)\.$var|$var)$/, keys %{ $opts->{cond} } );
  
   tie my %vv_col, 'Tie::IxHash', @{ $param{$table_type}{-columns} };
   
   for my $vv (@visit_vars) {
    my (@conds, $opr);
       if ( $csv->parse( $opts->{cond}{$vv} ) ) {
          ( $opr, @conds ) =  grep ( s/^\s*|\s*$//g, $csv->fields );
            $opr = $dialect->$opr || $opr;
       }
    # Last visits (i.e. vLast) for entities are not known in advance so practically any
    # visit can be the last visit for any entity
    if ( $vv =~ /^vLast\.$var$/ ) {
     if ( defined $param{$table_type}{-having}{-or} ) {
      # Get all visit representations of the variable from %vv_col
      my @c = grep { $_ =~ /\.$var$/ } keys %vv_col;
    
      for ( 0 .. $#{ $param{$table_type}{-having}{-or} } ) {
       my $alias = $aliase_in_having ? "`$c[$_]`" : $vv_col{ $c[$_] };
       ${ $param{$table_type}{-having}{-or} }[$_]->{$alias} =
         { $opr => \@conds };
      }
     }
    
     else {
      my $lv = $aliase_in_having ? '`vLast`' : $dialect->substring( $visit, '@@', -1 );
      my @lvc;
      
      for ( keys %$visit_info ) {
       my $vc = "$visit_info->{$_}{name}.$var";
       push @lvc,
         {
           $lv => { -ident => "'$_'" },
           (
             $aliase_in_having
             ? "`$vc`"
             : $vv_col{"$vc"}
             ) => { $opr => \@conds }
         };
      }
      $param{$table_type}{-having}{-or} = \@lvc;
     }
    }

    # vAny includes all visit variables joined as 'OR'
    elsif ( $vv =~ /^vAny\.$var$/ ) {
     my @avc;
     
     for ( keys %$visit_info ) {
      my $vc = "$visit_info->{$_}{name}.$var";
      my $alias = $aliase_in_having ? "`$vc`" : $vv_col{"$vc"};
      push @avc, $alias => { $opr => \@conds };
     }
     
     if ( defined $param{$table_type}{-having}{-and} ) {
      push @{ $param{$table_type}{-having}{-and} }, \@avc;
     }
     else {
      $param{$table_type}{-having}{-and} = [ { -or => \@avc } ];
     }
    }

    # Individual visits (v1.var, v2.var, v3.var etc.)
    elsif ( $vv =~ /^(?:$visit_regex)\.$var$/ ) {
     my ( $vv_opr, @vv_conds ) = grep ( s/^\s*|\s*$//g, $csv->fields )
       if $csv->parse( $opts->{cond}{$vv} );
     
     my $alias = $aliase_in_having ? "`$vv`" : $vv_col{$vv};
     
     if ( $param{$table_type}{-having}{$alias} ) {
      $param{$table_type}{-having}{$alias} = [
                   -and => { $opr => \@conds },
                   [
                    -or => { ( $dialect->$vv_opr || $vv_opr ) => \@vv_conds },
                    { '=', undef }
                   ]
      ];
     }
     else {
      $param{$table_type}{-having}{$alias} =
        { $opr => \@conds };
     }
    }

    # When condition is imposed on a variable (with no prefix v1, v2, vLast, vAny)
    # assume condition applies to all visits of the variable (i.e. 'AND' case)
    else {
     for ( keys %$visit_info ) {
      my $vc = "$visit_info->{$_}{name}.$var";
      my $alias = $aliase_in_having ? "`$vc`" : $vv_col{"$vc"};
      $param{$table_type}{-having}{$alias} =
        [ { $opr => \@conds }, { '=', undef } ];
     }
    }
   }
  }
 }
 
 ##---- ADD IDENTIFIER, VISIT AND GROUP BY COLUMNS ----##
 for ( keys %param ) {
  if ( $_ eq 'dynamic' ) {
   unshift @{ $param{$_}{-columns} },
     (
       'vFirst' => $dialect->substring( $visit, '@@',  1 ),
       'vLast'  => $dialect->substring( $visit, '@@', -1 ),
       'visit'  => $visit
     );
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
 
  $param{$_}{-group_by} = 'entity_id';

  # Make sure condition on 'tables' has no duplicate placeholders
  $param{$_}{-where}{ $map{table} }{-in} = [
    keys %{ { map { $_ => 1 } @{ $param{$_}{-where}{ $map{table} }{-in} } } } ];
 }
 return \%param;
}

sub process_result {
 my ( $self, $opts, $rs, $dir, @args ) = @_;
 my ( $ds, $csv ) = @{ $self->cache->get('cache') }{qw/datasource csv/};
 my $visit_info = $ds->visit_info;
 my $var_info   = $ds->variable_info;
 my $table_info = $ds->table_info;

 # Header of the csv must pay attention to args and variables on which the condition is imposed
 # Extract visit specific variables from the result-set based on the variables provided as args/cond (option).
 # Say, variables in args/cond variables are v1.var and vLast.var but as the result-set contains all visits of
 # the variable 'var' so discard v2.var and v3.var and select v1.var and the equivalent vLast.var
 my $index = $rs->[0][3] && $rs->[0][3] eq 'visit' ? 3 : 0;
 my @cols = $index == 0 ? qw/entity_id/ : qw/entity_id vFirst vLast visit/;
 my @args_cond_vars = grep ( $_ ne 'entity_id', @args, keys %{ $opts->{cond} } );
 
 for my $var ( @args_cond_vars ) {
     if ( ( $var_info->{$var} && $table_info->{$var_info->{$var}{table}}{__type__} eq 'dynamic' ) || $var =~ /^vAny\./ ) {
         my $v = $var =~ /^vAny\.(.+)$/ ? $1 : $var;
         # Avoid repeating visit variables
         # variable 'var' without prefix or with prefix 'vAny' corresponds 
         # to all visits of 'var'
         for my $visit ( keys %$visit_info ) {
               if ( !grep ( $_ eq "$visit_info->{$visit}{name}.$v", @cols ) ) {
                    push @cols, "$visit_info->{$visit}{name}.$v";
               }
         }
     }
     # Static and visit specific variables (e.g. v1.Var, v2.Var, vLast.Var )
     else {
         if ( !grep ( $_ eq $var, @cols ) ) {
              push @cols, $var;
         }    
     }
 }
 
 my @rs_entity;
 my $file = File::Spec->catfile( $dir, 'QueryOutput.csv' );
 my $fh = FileHandle->new("> $file")
   or throw_cmd_run_exception( error => "Failed to open file: $!" );
 
 $csv->print( $fh, \@cols )
   or throw_cmd_run_exception( error => $csv->error_diag );
 
 for my $r ( 1 .. $#$rs ) {
  push @rs_entity, $rs->[$r][0];
  my @vals;
  for my $c (@cols) {
   if ( $c eq 'visit' ) {
    ( my $val = $rs->[$r][$index] ) =~ s/\@\@/, /g;
    push @vals, $val;
   }
   elsif ( $c eq 'vFirst' ) {
    push @vals, $rs->[$r][1];
   }
   elsif ( $c eq 'vLast' ) {
    push @vals, $rs->[$r][2];
   }
   elsif ( $c =~ /^vLast\.(.+)$/ ) {
    my ($pos) = grep ( $rs->[0][$_] eq "$visit_info->{$vals[2]}{name}.$1",
                       0 .. $#{ $rs->[0] } );
    push @vals, $rs->[$r][$pos];
   }
   else {
    my ($pos) = grep ( $rs->[0][$_] eq $c, 0 .. $#{ $rs->[0] } );
    push @vals, $rs->[$r][$pos];
   }
  }
  $csv->print( $fh, \@vals )
    or throw_cmd_run_exception( error => $csv->error_diag );
 }
 $fh->close;
 return \@rs_entity;
}

sub process_table {
 my ( $self, $table, $ts, $dir, $rs_entity ) = @_;
 my ( $ds, $csv ) = @{ $self->cache->get('cache') }{qw/datasource csv/};
 my $table_info = $ds->table_info;
 my $var_info   = $ds->variable_info;
 my $visit_info = $ds->visit_info;
 my ( @vars, %data );
 if ( $table_info->{$table}{__type__} eq 'static' ) {
  for ( keys %$var_info ) {
   if ( $var_info->{$_}{table} eq $table ) {
    push @vars, $var_info->{$_}{variable};
   }
  }
 }
 else {

  # All visits applicable to the table
  for my $v ( keys %$visit_info ) {
   if ( grep ( $_ eq $table, @{ $visit_info->{$v}{tables} } ) ) {
    for ( keys %$var_info ) {
     if ( $var_info->{$_}{table} eq $table ) {
      push @vars, "$visit_info->{$v}{name}.$var_info->{$_}{variable}";
     }
    }
   }
  }
 }
 
 for (@$ts) {
  # For static tables in longitudinal datasources table data comprise of
  # entity_id and values of all table variables and in dynamic tables
  # (longitudinal datasources only) it contains an additional column visit
  if ( $table_info->{$table}{__type__} eq 'static' ) {
         $data{ $_->[0] }{ $_->[1] } = $_->[2];
  }
  else {
         $data{ $_->[0] }{"$visit_info->{$_->[3]}{name}.$_->[1]"} = $_->[2];
  }
 }

 # Write table data
 my $file = File::Spec->catfile( $dir, 'data.csv' );
 my $untaint = $1 if $file =~ /^(.+)$/;
 my $fh = FileHandle->new("> $untaint")
   or throw_cmd_run_exception( error => "Failed to open file: $!" );
   
 my @cols = ( qw/entity_id/, @vars );
 $csv->print( $fh, \@cols )
   or throw_cmd_run_exception( error => $csv->error_diag );

 # Write data for entities present in the result set
 for my $entity (@$rs_entity) {
  my @vals = ( $entity, map { $data{$entity}{$_} } @vars );
  $csv->print( $fh, \@vals )
    or throw_cmd_run_exception( error => $csv->error_diag );
 } 
 $fh->close;
}

sub create_dataset {
 my ( $self, $rs ) = @_;
 my $visit_info = $self->cache->get('cache')->{datasource}->visit_info;
 my $index = $rs->[0][3] && $rs->[0][3] eq 'visit' ? 3 : 0;
 my ( @vars, %data );

 # Remove visit suffix vAny, vLast, v1, v2 etc. from variables
 # in the result-set (i.e. args/cond (option))
 my $regex = 'vLast|' . join( '|', map { $visit_info->{$_}{name} } keys %$visit_info );
 
 for my $v ( @{ $rs->[0] }[ $index + 1 .. $#{ $rs->[0] } ] ) {
  $v =~ s/^(?:$regex)\.//;
  if ( !grep ( $_ eq $v, @vars ) ) {
   push @vars, $v;
  }
 }

 # Create dataset for calculating summary statistics
 for my $r ( 1 .. $#$rs ) {
  for my $v (@vars) {
   my @ds;
   for my $i ( $index + 1 .. $#{ $rs->[0] } ) {
      push @ds,  $rs->[0][$i] =~ /$v$/ ? $rs->[$r][$i] || () : ()
   }
   $data{ $rs->[$r][0] }{$v} = \@ds;
   
   $data{ $rs->[$r][0] }{'visit'} = [ split '@@', $rs->[$r][$index] ]
     if $index == 3;
  }
  
 }
 return ( \%data, 1, ( $index == 0 ? qw/entity_id/ : qw/entity_id visit/ ),
          @vars );
}

#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Command::Query::Compare - CohortExplorer class to compare entities across visits

=head1 SYNOPSIS

B<compare [OPTIONS] [VARIABLE]>

B<c [OPTIONS] [VARIABLE]>

=head1 DESCRIPTION

The compare command enables the user to compare entities across visits. The user can also impose conditions on variables. Moreover, the command also enables the user to view summary statistics and export data in csv format. The command is only available to longitudinal datasources with data on at least 2 visits.

This class is inherited from L<CohortExplorer::Command::Query> and overrides the following methods:

=head2 usage_text()

This method returns the usage information for the command.

=head2 get_valid_variables()

This method returns a ref to the list containing all variables (including visit variables) for validating arguments and condition option(s).

=head2 create_query_params( $opts, @args )

This method returns a hash ref with keys, C<static>, C<dynamic> or both depending on the variables supplied as arguments and conditions. The value of each key is a hash containing SQL parameters such as C<-columns>, C<-from>, C<-where>, C<-group_by> and C<-having>.

=head2 process_result( $opts, $rs, $dir, @args )
     
This method writes result set into a csv file and returns a ref to the list containing entity_ids.
        
=head2 process_table( $table, $ts, $dir, $rs_entity )
        
This method writes the table data into a csv file. The data includes C<entity_id> of all entities present in the result set followed by values of all visit variables.

=head2 create_dataset( $rs )

This method returns a hash ref with C<entity_id> as keys and variable name-value pairs as values. The statistics in this command are calculated with respect to C<entity_id> and the number of observations for each variable is the number of times (or visits) each variable was recorded for each entity during the course of the study.
 
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
            
Impose conditions using the operators: C<=>, C<!=>, C<E<gt>>, C<E<lt>>, C<E<gt>=>, C<E<lt>=>, C<between>, C<not_between>, C<like>, C<not_like>, C<ilike>, C<in>, C<not_in>, C<regexp> 
and C<not_regexp>.

The keyword C<undef> can be used to specify null.

=back

=head1 NOTES

The variables C<entity_id> and C<visit> (if applicable) must not be provided as arguments as they are already part of the query-set.
However, the user can impose conditions on both variables. Other variables in arguments and conditions must be referenced as C<table.variable> or C<visit.table.variable> where visit = C<vAny>, C<vLast>, C<v1>, C<v2>, C<v3> ... C<vMax>. Here vMax is the maximum visit number for which data is available. When a condition is imposed on a variable with no prefix such as C<vAny>, C<vLast>, C<v1>, C<v2> and C<v3> the command assumes the condition applies to all visits of the variable.

The directory specified in C<out> option must have RWX enabled for CohortExplorer.

=head1 EXAMPLES

 compare --out=/home/user/exports --stats --save-command --cond=v1.CER.Score='>, 20' v1.SC.Date

 compare --out=/home/user/exports --export=CER --cond=SD.Sex='=, Male' v1.CER.Score v3.DIS.Status
 
 compare --out=/home/user/exports --export=CER --cond=v2.CER.Score'!=, undef' vLast.DIS.Status

 compare -o/home/user/exports -Ssa -c vLast.CER.Score='in, 25, 30, 40' DIS.Status 

 compare -o/home/user/exports -eCER -eSD -c vLast.CER.Score='between, 25, 30' DIS.Status

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
