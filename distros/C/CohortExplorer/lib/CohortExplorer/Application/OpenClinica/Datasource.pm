package CohortExplorer::Application::OpenClinica::Datasource;

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
 # Default OpenCLinica url is http://localhost:8080
 my $ua = LWP::UserAgent->new( timeout => 10, cookie_jar => $cookie, ssl_opts => { verify_hostname => 0 } );
(my $url = $self->url || 'http://localhost:8080/OpenClinica' ) =~ s/\/$//;
 my $res = $ua->post(
                      $url . '/j_spring_security_check',
                      [
                        j_username => $opts{username},
                        j_password => $opts{password}
                      ]
 );
 if ( $cookie->as_string =~ /(JSESSIONID=[^;]+);/i ) {
  if ( $res->header('Location') =~ /$1$/i ) {
       my $dialect = $self->dialect;
       $self->dbh->selectrow_hashref(  'SELECT s.study_id, '
                                      . $dialect->aggregate( "DISTINCT sur.role_name" ) . ' AS role_name, '
                                      . $dialect->aggregate( "DISTINCT crf.oc_oid" ) . ' AS tables '
                                      . " FROM study AS s INNER JOIN study_user_role AS sur ON s.study_id = sur.study_id inner join crf on crf.source_study_id = s.study_id where s.oc_oid = ? AND sur.user_name = ? AND crf.status_id = 1 AND s.status_id = 1 group by s.study_id", undef, @{opts}{qw/datasource username/} );
  }
  else {
   return;
  }
 }
 else {
  die "Failed to connect to OpenClinica server using '$url' ("
  . $res->status_line . ")\n";
 }
}

sub additional_params {
 my ( $self, $res, %opts ) = @_;

      my %param = %$res;
      my $dynamic_tables = $self->dbh->selectcol_arrayref('SELECT crf.oc_oid FROM crf INNER JOIN event_definition_crf AS edcrf ON crf.crf_id = edcrf.crf_id WHERE edcrf.study_id = ? AND crf.status_id = 1 AND edcrf.status_id = 1 GROUP BY crf.oc_oid HAVING COUNT( crf.oc_oid ) > 1', undef, $param{study_id});

      if ( $dynamic_tables ) {
           my %dynamic_tables = map { $_ => 1 } @$dynamic_tables;
           @param{ qw/type static_tables/ } = ( 'longitudinal', [ grep { !$dynamic_tables{$_} } split ( ',', $param{tables} ) ] );
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
                         entity_id => 'ss.label',
                         variable  => 'i.oc_oid',
                         value     => 'id.value',
                         table     => 'crf.oc_oid'
           ],
           -from => [
                       -join => qw/item|i <=>{item_id=item_id} item_data|id <=>{event_crf_id=event_crf_id} event_crf|ecrf <=>{study_event_id=study_event_id} study_event|se <=>{ecrf.crf_version_id=crf_version_id} crf_version|crfv <=>{crf_id=crf_id} crf|crf <=>{se.study_event_definition_id=study_event_definition_id} study_event_definition|sed <=>{ecrf.study_subject_id=study_subject_id} study_subject|ss/
           ],
           -where => {
               'sed.study_id'   => $self->study_id,
               'sed.status_id'  => 1,
               'ecrf.date_validate_completed' => { '!=', undef },
               'se.status_id' => { -not_in, [ 5, 6, 7, 9 ] }
           }
 );

 if ( $self->type eq 'longitudinal' ) {
      push @{ $struct{-columns} }, visit => "CONCAT( sed.oc_oid, '_', se.sample_ordinal )";
 }

   return \%struct;
}

sub table_structure {
 my ($self) = @_;
 my $dialect = $self->dialect;

  return {
   -columns => [ 
        table          => 'crf.oc_oid',
        variable_count => 'COUNT(DISTINCT ifmd.item_id )',
        label          => $dialect->aggregate( 'DISTINCT crf.name' ),
        description    => $dialect->aggregate( 'DISTINCT crf.description' ),
        version        => $dialect->aggregate( 'DISTINCT crfv.name' ),
        events         => $dialect->aggregate( "DISTINCT CONCAT( sed.name, '(repeat = ', sed.repeating, ', required = ', edcrf.required_crf, ')'  )", ', ' )
    ],
   -from    => [
    -join =>
      qw/crf|crf <=>{crf_id=crf_id} crf_version|crfv <=>{crf_version_id=crf_version_id} item_form_metadata|ifmd <=>{crf.crf_id=crf_id} event_definition_crf|edcrf <=>{study_event_definition_id=study_event_definition_id} study_event_definition|sed/
   ],
   -group_by => 'crf.oc_oid',
   -where => {
               'crf.status_id'   => 1,
               'crfv.status_id'  => 1,
               'sed.status_id'   => 1,
               'edcrf.status_id' => 1,
               'sed.study_id'    => $self->study_id
   }
  };
 }

sub variable_structure {
 my ($self) = @_;

 # Table containing category information for categorical variables
 my $category_table = '( SELECT response_set_id, ' . $self->dialect->aggregate( "CONCAT( TRIM(values), ',', TRIM(text) )", '\n' ) . " AS category FROM ( SELECT rs.response_set_id, REGEXP_SPLIT_TO_TABLE(rs.options_text, ',') AS text, REGEXP_SPLIT_TO_TABLE( rs.options_values, ',') AS values FROM response_set AS rs INNER JOIN response_type AS rt ON rs.response_type_id = rt.response_type_id WHERE rt.name IN ('radio', 'single-select', 'multi-select') GROUP BY rs.response_set_id, rs.options_text, rs.options_values ) AS res WHERE text != '' and values != '' GROUP BY res.response_set_id ) AS cat";

 return {
    -columns => [
     variable      => 'i.oc_oid',
     table         => 'crf.oc_oid',
     type          => 'idt.code',
     default_value => 'ifmd.default_value',
     description   => 'i.description',
     unit          => 'i.units',
     category      => 'cat.category',
     label         => 'CONCAT( ifmd.question_number_label, ifmd.left_item_text )'
    ],
    -from => [
              -join => (
                 'item|i', '<=>{item_data_type_id=item_data_type_id}',
                 'item_data_type|idt',     '<=>{i.item_id=item_id}',
                 'item_group_metadata|igmd', '<=>{i.item_id=item_id}',
                 'item_form_metadata|ifmd', '<=>{crf_version_id=crf_version_id}',
                 'crf_version|crfv',       '<=>{crf_id=crf_id}',
                 'crf|crf', '=>{ifmd.response_set_id=cat.response_set_id}',
                 $category_table
              )
    ],
    -order_by => [ qw/crf.oc_oid i.item_id/ ],
    -where    => {
                  'crf.source_study_id' => $self->study_id,
                  'crf.status_id'       => 1,
                  'crfv.status_id'      => 1,
                  'i.status_id'         => 1,
                  ( $self->role_name =~ /^(?:director|admin)$/ ? ( -bool => 'i.phi_status' ) : ( -not_bool => 'i.phi_status' ) )
      }
   
  };
}

sub datatype_map {
   return {
            'INT'     => 'integer',
            'REAL'    => 'decimal',
            'DATE'    => 'date',
   };
}

#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Application::OpenClinica::Datasource - CohortExplorer class to initialize datasource stored under L<OpenClinica|https://www.openclinica.com/> framework

=head1 SYNOPSIS

The class is inherited from L<CohortExplorer::Datasource> and overrides the following methods:

=head2 authenticate( $opts )

This method authenticates the user by performing POST request against the OpenClinica database. The successful POST is followed by SQL query to retrieve user's role and crfs within the study/datasource.

=head2 additional_params( $opts, $response )

The method runs a SQL query to determine the datasource type (i.e. standard/cross-sectional or longitudinal). For longitudinal datasources the method attempts to set C<static_tables> (i.e. non repeating CRFs).

=head2 entity_structure()

This method returns a hash ref defining the entity structure. The method uses a combination of C<study_event_definition.oc_oid> and C<study_event.sample_ordinal> columns to define C<visit> column for the longitudinal datasources.

=head2 table_structure() 

This method returns a hash ref defining the table structure. C<-columns> key within the table structure includes table attributes such as C<table>, C<variable_count>, C<version>, C<description> and C<events>.

=head2 variable_structure()

This method returns a hash ref defining the variable structure. The variable attributes include columns such as C<variable>, C<table>, C<unit>, C<type>, C<category>, C<default_value>, C<description>, C<unit> and C<label>.

=head2 datatype_map()

This method returns variable type to SQL type mapping.

=head1 BUGS

At present the application only supports querying of OpenClinica instances that are implemented in PostgreSQL. In future, the application will be available with support for Oracle databases.


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
