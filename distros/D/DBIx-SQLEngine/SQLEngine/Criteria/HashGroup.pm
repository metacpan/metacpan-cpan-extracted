package DBIx::SQLEngine::Criteria::HashGroup;
use DBIx::SQLEngine::Criteria;
@ISA = 'DBIx::SQLEngine::Criteria';
use strict;

use DBIx::SQLEngine::Criteria::And;
use DBIx::SQLEngine::Criteria::Or;
use DBIx::SQLEngine::Criteria::StringComparison;
# 2004-02-24 Switched to StringComparison based on suggestion from Michael Kroll
# use DBIx::SQLEngine::Criteria::StringEquality;

use Class::MakeMethods (
  'Composite::Hash:new' => [ 'new', {modifier => 'with_values'} ],
);

sub normalized {
  my $hashref = shift;
  
  DBIx::SQLEngine::Criteria::And->new(
    map {
      my ($key, $value) = ($_, $hashref->{$_});
      ( ref( $value ) eq 'ARRAY' ) 
	? DBIx::SQLEngine::Criteria::Or->new( 
	    map {
              DBIx::SQLEngine::Criteria::StringComparison->new( $key, $_ ) 
	    } @$value
	  )
	: DBIx::SQLEngine::Criteria::StringComparison->new($key, $value)
    } sort keys %$hashref 
  )
}

sub sql_where {
  (shift)->normalized->sql_where( @_ ) 
}

1;

__END__

########################################################################

=head1 NAME

DBIx::SQLEngine::Criteria::HashGroup - A group of string criteria

=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria::HashGroup->new( 
    customer => 'Acme Inc.', status => [ 'open', 'pending' ]
  );


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria::HashGroup objects provide a convenient way to bundle several criteria together in a Perl hash structure. 

Each key-value pair is converted to a StringComparison Criteria, except if the value is an array reference, which produces an Or group of StringComparisons that will match any one of the provided values.

=head2 Evaluation

=over 4

=item sql_where () $sql_where_expression

  $criteria->sql_where() : $sql, @params

Generates SQL criteria expression. 

=item normalized()

Called by sql_where to convert the hash structure into simpler criteria objects.

=back


=head1 SEE ALSO

See L<DBIx::SQLEngine::Criteria> and L<DBIx::SQLEngine::Criteria::Comparison>
for more information on using these objects.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
