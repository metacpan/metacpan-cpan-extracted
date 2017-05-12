=head1 NAME

DBIx::SQLEngine::Driver::Trait::NoComplexJoins - For databases without complex joins

=head1 SYNOPSIS

  # Classes can import this behavior if they don't have joins using "on"
  use DBIx::SQLEngine::Driver::Trait::NoComplexJoins ':all';
  
  # Implements a workaround for missing "inner join on ..." capability
  $rows = $sqldb->fetch_select_rows( tables => [
    'foo', inner_join=>[ 'foo.id = bar.id' ], 'bar'
  ] );
  
  # Attempts to use an "outer join" produce an exception
  $rows = $sqldb->fetch_select_rows( tables => [
    'foo', outer_join=>[ 'foo.id = bar.id' ], 'bar'
  ] );

=head1 DESCRIPTION

This package supports SQL database servers which do natively provide a SQL
select with inner and outer joins. 

This package causes inner joins to be replaced with cross joins and a where clause. Outer joins, including left and right joins, are not supported and will cause an exception.

=head2 About Driver Traits

You do not need to use this package directly; it is used internally by those driver subclasses which need it. 

For more information about Driver Traits, see L<DBIx::SQLEngine::Driver/"About Driver Traits">.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Trait::NoComplexJoins;

use Exporter;
sub import { goto &Exporter::import } 
@EXPORT_OK = qw( 
  sql_join
  dbms_join_on_unsupported dbms_outer_join_unsupported
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

=item dbms_join_on_unsupported

  $sqldb->dbms_join_on_unsupported() : 1

Capability Limitation: This driver does not support the "join ... on ..." syntax.

=item dbms_outer_join_unsupported

  $sqldb->dbms_outer_join_unsupported() : 1

Capability Limitation: This driver does not support any type of outer joins.

=back

=cut

sub dbms_join_on_unsupported { 1 }
sub dbms_outer_join_unsupported { 1 }

########################################################################

=head2 Select to Retrieve Data

=over 4

=item sql_join()

  $sqldb->sql_join( $table1, $table2, ... ) : $sql, @params
  $sqldb->sql_join( $table1, \%criteria, $table2 ) : $sql, @params
  $sqldb->sql_join( $table1, $join_type=>\%criteria, $table2 ) : $sql, @params

Processes one or more table names to create the "from" clause of a select statement. Table names may appear in succession for normal "cross joins", or you may specify a join criteria between them.

Inner joins are replaced with normal "comma" cross joins and a where clause. Use of a left, right or full outer join causes an exception to be thrown.

Note that using join criteria will cause the return from this method to be a bit different than that of the superclass; instead of just being a "from" expression with table names, the returned SQL statement will also include a "where" expression. Conveniently, the sql_where method allows post-processing of a statement that already includes a where clause, so this value can still be combined with additional criteria supplied as a separate "where" argument to one of the select methods.

=back

=cut

sub sql_join {
  my ($self, @exprs) = @_;
  my $sql = '';
  my @params;
  my @where_sql;
  my @where_params;
  while ( scalar @exprs ) {
    my $expr = shift @exprs;

    my ( $table, $join, $criteria );
    if ( ! ref $expr and $expr =~ /^[\w\s]+join$/i and ref($exprs[0]) ) {
      $join = $expr;
      $criteria = shift @exprs;
      $table = shift @exprs;

    } elsif ( ref($expr) eq 'HASH' ) {
      $join = 'inner join';
      $criteria = $expr;
      $table = shift @exprs;

    } else {
      $join = ',';
      $criteria = undef;
      $table = $expr;
    }

    ( $table ) or croak("No table name provided to join to");
    ( $join ) or croak("No join type provided for link to $table");

    ( $join !~ /outer|right|left/i ) 
	or confess("This database does not support outer joins");
    
    my ( $expr_sql, @expr_params );
    if ( ! ref $table ) {
      $expr_sql = $table 
    } elsif ( ref($table) eq 'ARRAY' ) {
      my ( $sub_sql, @sub_params ) = $self->sql_join( @$table );
      # No need for parentheses because everything's going to be cross joined.
      $expr_sql = $sub_sql;
      push @expr_params, @sub_params
    } elsif ( ref($table) eq 'HASH' ) {
      my %seen_tables;
      my @tables = grep { ! $seen_tables{$_} ++ } map { ( /^([^\.]+)\./ )[0] } %$table;
      if ( @tables == 2 ) {
	my ( $sub_sql, @sub_params ) = $self->sql_join( 
	  $tables[0], 
	  inner_join => { map { $_ => \($table->{$_}) } keys %$table },
	  $tables[1], 
	);
	$expr_sql = $sub_sql;
	push @expr_params, @sub_params
      } else {
	confess("sql_join on hash with more than two tables not yet supported")
      }
    } elsif ( UNIVERSAL::can($table, 'name') ) {
      $expr_sql = $table->name
    } else {
      Carp::confess("Unsupported expression in sql_join: '$table'");
    }
    
    if ( $expr_sql =~ s/ where (.*)$// ) {
      push @where_sql, $1;
      push @where_params, @expr_params;
    }
    $sql .= ", $expr_sql";
    push @params, @expr_params;
    
    if ( $criteria ) {
      my ($crit_sql, @crit_params) = 
			DBIx::SQLEngine::Criteria->auto_where( $criteria );
      if ( $crit_sql ) {
	push @where_sql, $crit_sql if ( $crit_sql );
	push @where_params, @crit_params;
      }
    }

  }
  $sql =~ s/^, // or carp("Suspect table join: '$sql'");
  if ( scalar @where_sql ) {
    $sql .= " where " . ( ( scalar(@where_sql) == 1 ) ? $where_sql[0] 
				  : join( 'and', map "( $_ )", @where_sql ) );
    push @params, @where_params;
  }
  ( $sql, @params );
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;

