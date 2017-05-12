=head1 NAME

DBIx::SQLEngine::Criteria::Comparison - Superclass for comparisons

=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria::ComparisonSubclass->new( $key, $value );


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria::Comparison objects provide a structured representation of certain simple kinds of SQL criteria clauses, those of the form C<column_or_expression comparison_operator comparison_value>.

Each Criteria::Comparison object is implemented in the form of blessed arrayref, with two items in the array. The first is the column name (or SQL expression) to be compared against, and the second is the comparison value. The type of comparison operator to use is indicated by which subclass of Criteria::Comparison the object is blessed into. 

The comparison value is assumed by default to be a literal string or numeric value, and uses parameter substitution to avoid having to deal with quoting. If you actually want to compare against another column or expression, pass a reference to the column name or expression string. For example, to select records where C<first_name = last_name>, you could use:

  DBIx::SQLEngine::Criteria::Equality->('first_name', \'last_name');

=cut

package DBIx::SQLEngine::Criteria::Comparison;
@ISA = 'DBIx::SQLEngine::Criteria';
use strict;

########################################################################

=head1 REFERENCE

=head2 Constructor

=over 4

=item new ( $key, $value ) : $Comparison

Constructor.

=back

=cut

sub new {
  my $package = shift;
  bless [ @_ ], $package;
}


########################################################################

=head2 Content Access

=over 4

=item expr () : $fieldname

=item expr ( $fieldname )

Accessor.

=item compv () : $comparsion_value

=item compv ( $comparsion_value )

Accessor.

=back

=cut

use Class::MakeMethods (
  'Standard::Array:scalar' => 'expr',
  'Standard::Array:scalar' => 'compv',
);

########################################################################

=head2 Evaluation

=over 4

=item sql_comparator () : $operator

Returns operator associated with this criteria, such as "=" or "like".

=item sql_where () : $sql_where_expression

Generates SQL criteria expression. 

Automatically converts "= NULL" to "IS NULL".

=back

=cut

use Class::MakeMethods (
  'Template::Class:string' => 'sql_comparator',
);

sub sql_where {
  my $self = shift;
  my $expr = $self->expr;
  ( length $expr ) or Carp::confess("Expression is missing or empty");
  my $compv = $self->compv;
  # 2002-11-02 Patch from Michael Kroell, University of Innsbruck
  #( defined $compv ) or Carp::confess("Comparison value is missing or empty");
  my $cmp = $self->sql_comparator;
  ( length $cmp ) or Carp::confess("sql_comparator is missing or empty");
  
  # 2002-11-02 Based on patch from Michael Kroll, University of Innsbruck
  if ( ! defined($compv) ) {
    if ( $cmp eq '=' ) { $cmp = 'IS' }
    join(' ', $expr, $cmp, 'NULL' );
  } elsif ( ! ref($compv) ) {
    join(' ', $expr, $cmp, '?' ), $compv;
  } elsif ( ref($compv) eq 'SCALAR' ) {
    join(' ', $expr, $cmp, $$compv );
  } else {
    Carp::confess("Can't use '$compv' as a comparison value");
  }
}

########################################################################


=head1 SEE ALSO

See L<DBIx::SQLEngine::Criteria> and L<DBIx::SQLEngine::Criteria::Comparison>
for more information on using these objects.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
