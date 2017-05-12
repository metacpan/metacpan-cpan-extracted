package DBIx::SQLEngine::Criteria::LiteralSQL;

@ISA = 'DBIx::SQLEngine::Criteria';
use strict;

########################################################################

sub new {
  my $package = shift;
  bless [ @_ ], $package;
}

########################################################################

sub sql_where {
  my $self = shift;
  @$self;
}

########################################################################

1;

########################################################################

########################################################################

=head1 NAME

DBIx::SQLEngine::Criteria::LiteralSQL - Criteria with SQL snippets


=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria::LiteralSQL->new( "name = 'Dave'" );


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria::LiteralSQL objects are built around an
array of a SQL string, followed by values to be bound the the '?'
placeholders in the string, if any.

=cut


=head1 REFERENCE

=head2 Constructor

=over 4

=item new

  DBIx::SQLEngine::Criteria::LiteralSQL->new( $sql ) : $comparison

  DBIx::SQLEngine::Criteria::LiteralSQL->new( $sql, @params ) : $comparison

Constructor.

=back

=head2 SQL Where Generation

=over 4

=item sql_where()

  $criteria->sql_where() : $sql, @params

Returns the SQL fragment and parameters stored by the constructor.

=back

=cut


=head1 SEE ALSO

See L<DBIx::SQLEngine::Criteria> and L<DBIx::SQLEngine::Criteria::Comparison>
for more information on using these objects.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
