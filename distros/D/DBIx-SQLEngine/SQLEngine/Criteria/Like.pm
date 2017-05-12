package DBIx::SQLEngine::Criteria::Like;

use DBIx::SQLEngine::Criteria::Comparison;
@ISA = 'DBIx::SQLEngine::Criteria::Comparison';
use strict;
use Carp;

__PACKAGE__->sql_comparator('like');

1;

__END__

########################################################################

=head1 NAME

DBIx::SQLEngine::Criteria::Like - Criteria for SQL92 Like Wildcards

=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria::Like->new( $expr, $value );


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria::Like objects check that an expression
matches a given SQL wildcard pattern. ANSI SQL 92 provides for "%"
wildcards, and some vendors support additional patterns.

=over 4

=item sql_comparator()

Returns "like".

=back

=head1 SEE ALSO

See L<DBIx::SQLEngine::Criteria> and L<DBIx::SQLEngine::Criteria::Comparison>
for more information on using these objects.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
