package DBIx::SQLEngine::Criteria::Equality;

use DBIx::SQLEngine::Criteria::Comparison;
@ISA = 'DBIx::SQLEngine::Criteria::Comparison';
use strict;
use Carp;

__PACKAGE__->sql_comparator('=');

1;

__END__

########################################################################

=head1 NAME

DBIx::SQLEngine::Criteria::Equality - Criteria for Basic Equality 

=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria::Equality->new( $expr, $value );


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria::Equality objects are check that an expression exactly matches a given reference value.

=over 4

=item sql_comparator()

Returns "=".

=back


=head1 SEE ALSO

See L<DBIx::SQLEngine::Criteria> and L<DBIx::SQLEngine::Criteria::Comparison>
for more information on using these objects.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
