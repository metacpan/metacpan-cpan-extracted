package DBIx::SQLEngine::Criteria::Not;

@ISA = 'DBIx::SQLEngine::Criteria';
use strict;
use Carp;

sub new {
  my $package = shift;
  ( @_ < 2 ) or croak("The Not criteria only accepts one argument");
  bless [ shift ], $package;
}

sub sql_where {
  my $self = shift;
  my ($clause, @params) = $self->[0]->sql_where;
  
  return unless defined $clause and length $clause;
  
  return ( " NOT ( " . $clause . " ) ", @params )
}

1;

__END__

#########################################################################

=head1 NAME

DBIx::SQLEngine::Criteria::Not - Negating A Single Criteria

=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria::Not->new( $crit );


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria::Not logicaly inverts a single given
criteria by wrapping it in a NOT criteria.

(Contributed by Christian Glahn at Innsbruck University.)


=head1 REFERENCE

=head2 Constructor

=over 4

=item new ( @criteria ) : $notcriteria

Constructor.

=back


=head1 SEE ALSO

See L<DBIx::SQLEngine::Criteria> and L<DBIx::SQLEngine::Criteria::Comparison>
for more information on using these objects.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
