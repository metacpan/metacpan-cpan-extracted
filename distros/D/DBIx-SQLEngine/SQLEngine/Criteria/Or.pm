package DBIx::SQLEngine::Criteria::Or;
use DBIx::SQLEngine::Criteria::Compound;
@ISA = 'DBIx::SQLEngine::Criteria::Compound';
use strict;

__PACKAGE__->sql_join('or');

1;

__END__

########################################################################

=head1 NAME

DBIx::SQLEngine::Criteria::Or - Criteria for Compound "Any"

=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria::Or->new( $crit, ... );


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria::Or objects are built around an array of other criteria, any of which may be satisified in order for the Or criterion to be met.


=head1 SEE ALSO

See L<DBIx::SQLEngine::Criteria> and L<DBIx::SQLEngine::Criteria::Comparison>
for more information on using these objects.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
