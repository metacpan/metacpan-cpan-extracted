=head1 NAME

DBIx::SQLEngine::Driver::Trait::NoPlaceholders - For drivers without placeholders

=head1 SYNOPSIS

  # Classes can import this behavior if they don't have joins using "on"
  use DBIx::SQLEngine::Driver::Trait::NoPlaceholders ':all';
  
  # Queries which would typically use placeholders need special treatment
  $hash_ary = $sqldb->fetch_select( 
    table => 'students', where => { 'status'=>'minor' },
  );


=head1 DESCRIPTION

This package supports drivers or database servers which do support the use of "?"-style placeholders in queries. 

This is a problem for Linux users of DBD::Sybase connecting to MS SQL Servers on Windows.

This package attempts to substitute the placeholders into the query before executing it.

=head2 About Driver Traits

You do not need to use this package directly; it is used internally by those driver subclasses which need it. 

For more information about Driver Traits, see L<DBIx::SQLEngine::Driver/"About Driver Traits">.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Trait::NoPlaceholders;

use Exporter;
sub import { goto &Exporter::import } 
@EXPORT_OK = qw( 
  prepare_execute
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

use strict;
use Carp;

########################################################################

=head1 REFERENCE

=cut

########################################################################

=head2 Database Capability Information

=over 4

=item dbms_placeholders_unsupported()

  $sqldb->dbms_placeholders_unsupported() : 1

Capability Limitation: This driver does not support "?"-style placehoders. 

=back

=cut

sub dbms_placeholders_unsupported { 1 }

########################################################################

=head2 Statement Handle Lifecycle 

=over 4

=item prepare_execute()

  $sqldb->prepare_execute ($sql, @params) : $sth

Prepare, bind, and execute a SQL statement to create a DBI statement handle.

Uses the DBI prepare_cached() and execute() methods. 

Instead of using bind_params, attempts to subtitute them into the statement using the DBI quote() method.

To Do: This could benefit from a much wider range of tests to confirm that the substitution is being applied as expected.

To Do: Examine the optional type information that can be passed with parameters. This is currently ignored, but could be used to differentiate between string types that needed to be quoted and those numeric types that don't.

=back

=cut

# $sth = $self->prepare_execute($sql);
# $sth = $self->prepare_execute($sql, @params);
sub prepare_execute {
  my ($self, $sql, @params) = @_;
  
  my @values;
  for my $param_no ( 0 .. $#params ) {
    my $param_v = $params[$param_no];
    my @param_v = ( ref($param_v) eq 'ARRAY' ) ? @$param_v : $param_v;
    $values[ $param_no+1 ] = $param_v[0];
  }
  
  $sql =~ s{\?}{ scalar(@values) or croak "not enough parameters";
		 $self->quote( shift @values ) }geo;
  ! scalar(@values) or croak "too many parameters";
  
  my $sth = $self->prepare_cached($sql);
  $self->{_last_sth_execute} = $sth->execute();
  
  return $sth;
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;

