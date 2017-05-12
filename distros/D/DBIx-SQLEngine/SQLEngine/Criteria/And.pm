package DBIx::SQLEngine::Criteria::And;
use DBIx::SQLEngine::Criteria::Compound;
@ISA = 'DBIx::SQLEngine::Criteria::Compound';
use strict;

__PACKAGE__->sql_join('and');

1;

__END__

########################################################################

=head1 NAME

DBIx::SQLEngine::Criteria::And - Criteria for Compound "All"

=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria::And->new( $crit, ... );


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria::And objects are built around an array of other criteria, all of which must be satisified in order for the And criterion to be met.


=head1 SEE ALSO

See L<DBIx::SQLEngine::Criteria> and L<DBIx::SQLEngine::Criteria::Comparison>
for more information on using these objects.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
