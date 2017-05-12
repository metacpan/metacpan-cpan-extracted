package CohortExplorer::Application::REDCap::Datasource;

use strict;
use warnings;

our $VERSION = 0.14;

use base qw(CohortExplorer::Datasource);

#-------
sub authenticate {
 my ( $self, %opts ) = @_;
 require HTTP::Cookies;
 require LWP::UserAgent;
 my $cookie = HTTP::Cookies->new();

 # Authenticate using REDCap url
 # Default REDCap url is http://localhost:80
 my $ua = LWP::UserAgent->new( timeout => 10, cookie_jar => $cookie, ssl_opts => { verify_hostname => 0 } );
(my $url = $self->url || 'http://localhost:80/redcap' ) =~ s/\/$//;
 my $res = $ua->post(
                      $url . '/index.php',
                      [
                        username => $opts{username},
                        password => $opts{password}
                      ]
 );
 my $code = $res->code;
 if ( $res->is_success ) {
  if ( $cookie->as_string =~ /(?:PHPSESSID|authchallenge)=[^;]+;/ ) {
   return
     $self->dbh->selectrow_hashref(
"SELECT rp.project_id, rur.data_export_tool, rur.group_id FROM redcap_user_rights AS rur INNER JOIN redcap_projects AS rp ON rur.project_id = rp.project_id WHERE rp.project_name = ? AND rur.data_export_tool != 0 AND rur.username = ? AND ( rp.project_id NOT IN ( SELECT project_id FROM redcap_external_links_exclude_projects ) AND ( rur.expiration <= CURDATE() OR rur.expiration IS NULL ) )", undef, $self->name, $opts{username} );
  }
  else {
   return;
  }
 }
 else {
  die "Failed to connect to REDCap server using '$url' ("
    . $res->status_line . ")\n";
 }
}

sub additional_params {
 my ( $self, $res, %opts ) = @_;

 my %param = %$res;
 
 # Get static tables and dynamic_event_ids (i.e. comma separated event_ids of all repeating forms)
 my $rows = $self->dbh->selectall_arrayref( "SELECT arm_name, GROUP_CONCAT( DISTINCT IF( form_count = 1, form, NULL ) ) AS static_tables FROM ( SELECT GROUP_CONCAT( DISTINCT ref.form_name ) AS form, COUNT( ref.event_id ) AS form_count, arm_name FROM redcap_events_forms AS ref INNER JOIN redcap_events_metadata AS rem ON ref.event_id = rem.event_id INNER JOIN redcap_events_arms AS rea ON rea.arm_id = rem.arm_id WHERE rea.project_id = ? GROUP BY ref.form_name, rea.arm_id ORDER BY ref.event_id) AS t GROUP BY arm_name", undef, $param{project_id} );
 
 die "Datasource has multiple arms, please provide a single arm (i.e. arm_name) to query\n" if @$rows > 1 && !$self->arm_name;
   
 if ( @$rows ) {
      my $arm_index;
      if ( @$rows > 1 ) {
           ($arm_index) = grep ( $self->arm_name eq $rows->[$_][0], 0..$#$rows );
           die "Arm name must be either " . join ( ' or ', map { "'$_->[0]'" } @$rows ) if !defined $arm_index;        
      }
           @param{ qw/type arm_name static_tables/ } =  ( 'longitudinal', 
                                                           $rows->[$arm_index || 0 ][0], 
                                                           [ split ',', ( $rows->[$arm_index || 0][1] || '') ] 
                                                        );
 }
 else {
        $param{type} = 'standard';
 }
  
 return \%param;
}

sub entity_structure {
 my ($self) = @_;
 my %struct = (
  -columns => [
                entity_id => 'rd.record',
                variable  => 'rd.field_name',
                value     => 'rd.value',
                table     => 'form_name'
  ],
  -from => [
   -join => (
    $self->type eq 'standard'
    ? qw/redcap_data|rd <=>{project_id=project_id} redcap_metadata|rm/
    : qw/redcap_data|rd <=>{event_id=event_id} redcap_events_forms|ref <=>{event_id=event_id} redcap_events_metadata|rem <=>{arm_id=arm_id} redcap_events_arms|rea/
   )
  ],
  -where => {
      'rd.project_id' => $self->project_id,
      'rd.record'     => ( $self->group_id ? { -in => \[ 'SELECT record FROM redcap_data WHERE project_id = ? AND field_name = ? AND 
       value = ?', $self->project_id, '__GROUP_ID__', $self->group_id ] } : { 'like', '%' } )
   }
 );

 # Add visit column if the datasource is longitudinal
 # Visit number is determined using the init_event_id
 if ( $self->type eq 'longitudinal' ) {
      push @{ $struct{-columns} }, visit => 'rem.descrip';
      $struct{-order_by} = 'rem.day_offset';
      $struct{-where}{'rea.arm_name'} = $self->arm_name;
 }
      return \%struct;
}

sub table_structure {
 my ($self) = @_;
 my @cols = (
  arm            => 'GROUP_CONCAT( DISTINCT rea.arm_name )',
  table          => 'GROUP_CONCAT( DISTINCT rm.form_name )',
  label          => 'GROUP_CONCAT( DISTINCT rm.form_menu_description )',
  variable_count => 'COUNT( DISTINCT rm.field_name )',
  event_count    => 'COUNT( DISTINCT rem.day_offset )',
  event_description => "GROUP_CONCAT( DISTINCT CONCAT( rem.descrip, '(', rem.day_offset, ')' ) ORDER BY rem.day_offset SEPARATOR '\n ')"
 );
 
 # If data_export_tool is != 1 remove variables tagged as identifiers

 if ( $self->type eq 'longitudinal' ) {
  return {
   -columns => \@cols,
   -from    => [
    -join =>
      qw/redcap_metadata|rm <=>{form_name=form_name} redcap_events_forms|ref <=>{event_id=event_id} redcap_events_metadata|rem <=>{arm_id=arm_id} redcap_events_arms|rea/
   ],
   -order_by => [ qw/rm.form_name rem.day_offset/ ],
   -group_by => 'rm.form_name',
   -having => { 'variable_count' => { '>', 0 } },
   -where  => {
       'rm.project_id'  => $self->project_id,
       'rea.arm_name'   => $self->arm_name,
       'rea.project_id' => { -ident => 'rm.project_id' },
       'rm.field_phi'  => ( $self->data_export_tool == 2 
                             ? { '=', undef }
                             : [ { '=', undef }, { '!=', undef } ]
                           )
   }
 };
}

 else {
  return {
           -columns  => [ splice( @cols, 2, 6 ) ],
           -from     => 'redcap_metadata AS rm',
           -order_by => 'rm.field_order',
           -group_by => 'rm.form_name',
           -having => { 'variable_count' => { '>', 0 } },
           -where  => {
           'rm.project_id'  => $self->project_id,
           'rm.field_phi'  => ( $self->data_export_tool == 2 
                                 ? { '=', undef }
                                 : [ { '=', undef }, { '!=', undef } ]
                               )
            }
  };
 }
}

sub variable_structure {
 my ($self) = @_;

 return {
  -columns => [
   variable => 'field_name',
   table    => 'form_name',
   type => "IF( element_validation_type IS NULL, 'text', element_validation_type )",
   unit => 'field_units',
   category => "IF( element_enum like '%, %', REPLACE( element_enum, '\\\\n', '\n'), '' )",
   label => 'element_label'
  ],
  -from     => 'redcap_metadata',
  -order_by => 'field_order',
  -where  => {
    'project_id'  => $self->project_id,
    'field_phi'   => ( $self->data_export_tool == 2
                          ? { '=', undef }
                          : [ { '=', undef }, { '!=', undef } ]
                      ),
    'form_name'   => { -in => [ keys %{$self->table_info} ] }
   }
 };
}


sub datatype_map {
 return {
          'int'                  => 'signed',
          'float'                => 'decimal',
          'date_dmy'             => 'date',
          'date_mdy'             => 'date',
          'date_ymd'             => 'date',
          'datetime_dmy'         => 'datetime',
          'datetime_mdy'         => 'datetime',
          'datetime_ymd'         => 'datetime',
          'datetime_seconds_dmy' => 'datetime',
          'datetime_seconds_mdy' => 'datetime',
          'datetime_seconds_ymd' => 'datetime',
          'number'               => 'decimal',
          'number_1dp'           => 'decimal(10,1)',
          'number_2dp'           => 'decimal(10,2)',
          'number_3dp'           => 'decimal(10,3)',
          'number_4dp'           => 'decimal(10,4)',
          'time'                 => 'time',
          'time_mm_sec'          => 'time'
 };
}

#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Application::REDCap::Datasource - CohortExplorer class to initialize datasource stored under L<REDCap|http://project-redcap.org/> framework

=head1 SYNOPSIS

The class is inherited from L<CohortExplorer::Datasource> and overrides the following methods:

=head2 authenticate( $opts )

This method authenticates the user by performing POST request against the REDCap database. The successful POST is followed by SQL query to retrieve C<project_id>, C<data_export_tool> and C<group_id>. In order to use CohortExplorer with REDCap the user must have the permission to export data (C<data_export_tool != 0>).

=head2 additional_params( $opts, $response )

The method runs a SQL query to determine the datasource type (i.e. standard/cross-sectional or longitudinal), static_tables and arm name (if applicable).

=head2 entity_structure()

This method returns a hash ref defining the entity structure. The method uses C<redcap_events_metadata.descrip> column to define C<visit> column. The ordering of visits is defined using the column C<redcap_events_metadata.day_offset>. The hash ref also contains the condition for the inclusion and exclusion of records (group level permissions).

=head2 table_structure() 

This method returns a hash ref defining the table structure. C<-columns> key within the table structure depends on the datasource type. For standard datasources C<-columns> key includes table attributes such as C<table>, C<label> and C<variable_count> where as for longitudinal datasources it comprises of C<table>, C<arm>, C<variable_count>, C<label>, C<event_count> and C<event_description>.

=head2 variable_structure()

This method returns a hash ref defining the variable structure. The hash ref uses C<data_export_tool> parameter set in C<additional_params> to specify condition for the inclusion and exclusion of variables tagged as identifiers. The variable attributes include attributes such as C<table>, C<unit>, C<type>, C<category> and C<label>.

=head2 datatype_map()

This method returns variable type to SQL type mapping.

=head1 DEPENDENCIES

L<HTTP::Cookies>

L<LWP::UserAgent>

=head1 SEE ALSO

L<CohortExplorer>

L<CohortExplorer::Datasource>

L<CohortExplorer::Command::Describe>

L<CohortExplorer::Command::Find>

L<CohortExplorer::Command::History>

L<CohortExplorer::Command::Query::Search>

L<CohortExplorer::Command::Query::Compare>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Abhishek Dixit (adixit@cpan.org). All rights reserved.

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
