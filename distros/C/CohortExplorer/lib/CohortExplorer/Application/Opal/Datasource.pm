package CohortExplorer::Application::Opal::Datasource;

use strict;
use warnings;

our $VERSION = 0.14;

use base qw(CohortExplorer::Datasource);
use JSON qw( decode_json );

#-------
sub authenticate {
 my ( $self, %opts ) = @_;
 my $ds_name = $self->name;
 require LWP::UserAgent;
 require MIME::Base64;

 # Authenticate using Opal url
 # Default Opal url is http://localhost:8080
 my $ua = LWP::UserAgent->new( timeout => 10, ssl_opts => { verify_hostname => 0 } );
(my $url = $self->url || 'http://localhost:8080' ) =~ s/\/$//;
 my $req = HTTP::Request->new( GET => $url . "/ws/datasource/$ds_name" );
 $req->header(
             Authorization => "X-Opal-Auth "
               . MIME::Base64::encode( join ':', @opts{qw/username password/} ),
             Accept => "application/json"
 );
 my $res  = $ua->request($req);
 my $code = $res->code;
 if ( $code == 200 ) {
  my $json = decode_json( $res->decoded_content );
  if ( $json->{type} ne 'mongodb' ) {

   # Successful authentication returns tables and views accessible to the user
   my %view = map { $_ => 1 } @{ $json->{view} || [] };
   my @tables = @{ $json->{table} || [] };

   # Get all base tables ( i.e. exclude views )
   my @base_tables =
     defined $json->{view} ? grep { not $view{$_} } @tables : @tables;
   if ( @base_tables == 0 ) {
    die "No tables but views found in $ds_name\n";
   }
   return \@base_tables;
  }
  else {
   die "Storage type for $ds_name is not MySQL but MongoDB\n";
  }
 }
 elsif ( $code == 401 ) {
  return;
 }
 else {
  die "Failed to connect to Opal server using '$url' (error $code)\n";
 }
}

sub additional_params {
 my ( $self, $res, %opts ) = @_;
 my $ds_name = $self->name;

 # By default,
 # datasource type is standard (i.e. cross-sectional)
 # entity_type is participant
 # id_visit_separator is '_' (valid to longitudinal datasources only)
 my %param = (
               type        => $self->type        || 'standard',
               entity_type => $self->entity_type || 'Participant',
               allowed_tables => $res,
               username       => $opts{username}
 );

 if ( $param{type} eq 'longitudinal' ) {
     $param{id_visit_separator} = $self->id_visit_separator || '_';

  # Get static tables (if any) from datasource-config.properties and check them against @allowed_tables
  my @static_tables = ();
  my %table = map { $_ => 1 } @{ $param{allowed_tables} };
  $param{static_tables} = $self->static_tables || undef;
  if ( $param{static_tables} ) {
   for ( split /,\s*/, $param{static_tables} ) {
    push @static_tables, $_ if ( $table{$_} );
   }
  }
  $param{static_tables} = \@static_tables;
 }
 else {

  # id_visit_separator and visit_max is undefined for standard datasources
  @param{qw/id_visit_separator visit_max static_tables/} =
    ( undef, undef, $param{allowed_tables} );
 }

 # Get list of allowed variables from each table
 my $ua = LWP::UserAgent->new( timeout => 10, ssl_opts => { verify_hostname => 0 } );
(my $url = $self->url || 'http://localhost:8080' ) =~ s/\/$//;
 for my $t ( @{ $param{allowed_tables} } ) {
  my $entity_req =
    HTTP::Request->new(
                    GET => $url . "/ws/datasource/$ds_name/table/$t/entities" );
  $entity_req->header(
             Authorization => "X-Opal-Auth "
               . MIME::Base64::encode( join ':', @opts{qw/username password/} ),
             Accept => "application/json"
  );
  my $entity_res = $ua->request($entity_req);

  # Get the first identifier
  if ( $entity_res->code == 200 ) {
   my $decoded_json = decode_json( $entity_res->decoded_content );
   my $var_req =
     HTTP::Request->new(   GET => $url
                         . "/ws/datasource/$ds_name/table/$t/valueSet/"
                         . ( $decoded_json->[0]->{identifier} || '' ) );
   $var_req->header(
             Authorization => "X-Opal-Auth "
               . MIME::Base64::encode( join ':', @opts{qw/username password/} ),
             Accept => "application/json"
   );
   my $var_res = $ua->request($var_req);

   # Get all variables with accessible values
   if ( $var_res->code == 200 ) {
    $decoded_json = decode_json( $var_res->decoded_content );
    push @{ $param{allowed_variables} },
      map { "$t.$_" } @{ $decoded_json->{variables} };
   }
   else {
    die "Failed to fetch variable list via $url (error "
      . $var_res->code . ")\n";
   }
  }
  else {
   die "Failed to fetch variable list via $url (error "
     . $entity_res->code . ")\n";
  }
 }
 return \%param;
}

sub entity_structure {
 my ($self) = @_;
 my %struct = (
  -columns => [
                variable => 'var.name',
                value    => 'vsv.value',
                table    => 'vt.name'
  ],
  -from => [
   -join =>
     qw/variable_entity|ve id=variable_entity_id value_set|vs <=>{value_table_id=id} value_table|vt <=>{vs.id=value_set_id} value_set_value|vsv <=>{vsv.variable_id=id} variable|var <=>{vt.datasource_id=id} datasource|ds/
  ],
  -where => {
              've.type' => $self->entity_type,
              'ds.name' => $self->name
  }
 );

# For longitudinal datasources split identifier into entity_id and visit using id_split_separator
 if ( $self->type eq 'longitudinal' ) {
  my $id_visit_sep = $self->id_visit_separator;
  push @{ $struct{-columns} },
    entity_id => "SUBSTRING_INDEX( ve.identifier, '$id_visit_sep', 1)";
  my $visit = "CAST( SUBSTRING_INDEX( ve.identifier, '$id_visit_sep', IF( ve.identifier RLIKE '$id_visit_sep\[0-9\]+\$', -1, NULL ) ) AS UNSIGNED )";

  # Check for the presence of id_visit_sep
  push @{ $struct{-columns} }, visit => $visit;
  $struct{-order_by} = $visit;
 }
 else {
  push @{ $struct{-columns} }, entity_id => 've.identifier';
 }
 return \%struct;
}

sub table_structure {
 my ($self) = @_;
 return {
  -columns => [
   table          => 'GROUP_CONCAT( DISTINCT vt.name)',
   variable_count => 'COUNT( DISTINCT var.id)',
   entity_type    => 'GROUP_CONCAT( DISTINCT vt.entity_type )',
   description => "GROUP_CONCAT( DISTINCT IF ( varatt.name = 'description', varatt.value, NULL ) )"
  ],
  -from => [
   -join =>
     qw/value_table|vt <=>{vt.datasource_id=id} datasource|ds <=>{vt.id=value_table_id} variable|var =>{var.id=variable_id} variable_attributes|varatt/
  ],
  -where => {
              'vt.entity_type' => $self->entity_type,
              'vt.name'        => { -in => $self->allowed_tables },
              'ds.name'        => $self->name
  },
  -group_by => 'vt.id',
  -order_by => [qw/vt.name var.id var.variable_index/]
 };
}

sub variable_structure {
 my ($self) = @_;
 return {
  -columns => [
   variable => 'GROUP_CONCAT( DISTINCT var.name )',
   table    => 'GROUP_CONCAT( DISTINCT vt.name )',
   type     => 'GROUP_CONCAT( DISTINCT var.value_type )',
   unit => "GROUP_CONCAT( DISTINCT IF( varatt.name = 'unitLabel' AND varatt.name IS NOT NULL, varatt.value, IF( var.unit IS NOT NULL, var.unit, '' )) SEPARATOR '')",
   category => "GROUP_CONCAT( DISTINCT IF( var.value_type = 'boolean', 'true, True\\nfalse, False', CONCAT( cat.name, ', ', catatt.value ) ) SEPARATOR '\\n')",
   validation => "GROUP_CONCAT( DISTINCT IF( varatt.name = 'validation', REPLACE( SUBSTRING_INDEX( varatt.value,',', 2), 'Number.', '' ), NULL ) SEPARATOR '')",
   label => "GROUP_CONCAT( DISTINCT IF( varatt.name = 'label', varatt.value, '' ) SEPARATOR ' ')",
  ],
  -from => [
   -join =>
     qw/value_table|vt <=>{vt.datasource_id=id} datasource|ds <=>{vt.id=value_table_id} variable|var =>{var.id=variable_id} variable_attributes|varatt =>{var.id=variable_id} category|cat =>{id=category_id} category_attributes|catatt/
  ],
  -where => {
              'vt.entity_type' => $self->entity_type,
              'ds.name'        => $self->name,
              "CONCAT( vt.name, '.', var.name )" =>
                { -in => $self->allowed_variables || [] },
  },
  -group_by => 'var.id',
  -order_by => [qw/vt.name var.id var.variable_index/]
 };
}

sub datatype_map {
 return {
          'integer'  => 'signed',
          'decimal'  => 'decimal',
          'date'     => 'date',
          'datetime' => 'datetime'
 };
}

#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Application::Opal::Datasource - CohortExplorer class to initialize datasource stored in L<Opal (OBiBa)|http://obiba.org/node/63> SQL framework

=head1 SYNOPSIS

The class is inherited from L<CohortExplorer::Datasource> and overrides the following methods:

=head2 authenticate( $opts )

This method authenticates the user using the Opal URL specified in C</etc/CohortExplorer/datasource-config.properties>. By default, the Opal URL is assumed to be C<http://localhost:8080>. The successful authentication returns reference to the list of base tables (i.e. tables excluding views) accessible to the user. In order to use CohortExplorer with Opal the user must have the permission to view at least one variable from at least one base table. 

=head2 additional_params( $opts, $response )

This method returns a hash ref containing all configuration specific parameters. The method also fetches a list of all variables from base tables (i.e. C<$response>) whose values are accessible to the user via Opal REST API. By default,

  datasource type = standard (i.e. cross-sectional)
  entity_type = Participant
  id_visit_separator (valid to longitudinal datasources) = _ 

=head2 entity_structure()

This method returns a hash ref defining the entity structure. The datasources in Opal are strictly standard but they can be easily made longitudinal by joining C<entity_id> and C<visit> on C<id_visit_separator> (default C<_>). For example, PART001_1, implies the first visit of the participant PART001 and PART001_2 implies the second visit. C<id_visit_separator> can also be a string (e.g. PARTIOP1, PARTIOP2).

=head2 table_structure()

This method returns a hash ref defining the table structure. The hash ref includes table attributes such as C<variable_count>, C<label>, C<entity_type> and C<description>.

=head2 variable_structure()

This method returns a hash ref defining the variable structure. The variable attributes include C<unit>, C<type>, C<category>, C<validation> and C<label>.

=head2 datatype_map()

This method returns variable type to SQL type mapping.

=head1 DEPENDENCIES

L<JSON>

L<LWP::UserAgent>

L<MIME::Base64>    

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
