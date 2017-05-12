package DBIx::SQLEngine::Criteria::StringComparison;

use DBIx::SQLEngine::Criteria::Comparison;
@ISA = 'DBIx::SQLEngine::Criteria::Comparison';
use strict;
use Carp;

sub sql_comparator {
  ( ( (shift)->compv || '' ) =~ /%/ ) ? 'like' : '=' 
}

1;

__END__

########################################################################

=head1 NAME

DBIx::SQLEngine::Criteria::StringComparison - Equality or Wildcard Criteria

=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria::StringComparison->new( $expr, $value );


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria::StringComparison objects behave as either Equality or Like objects, depending on whether the value they're matching against contains a SQL wildcard "%" character.

=over 4

=item sql_comparator()

Returns "like" or "=".

=back

=head1 SEE ALSO

See L<DBIx::SQLEngine::Criteria> and L<DBIx::SQLEngine::Criteria::Comparison>
for more information on using these objects.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
