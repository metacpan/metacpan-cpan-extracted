#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs;
#----------------------------------------------------------------------
use strict;
use warnings;

use Carp::Clan       qw[^(DBIx::DataModel::|SQL::Abstract)];

sub new {
  my $class = shift;

  return bless {@_}, $class;
}

sub get_result {
  my $self  = shift;
  my $class = ref $self || $self;
  croak "$class should implement a get_result() method";
}

1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs - Parent class for result kinds

=head1 DESCRIPTION

This is the mother class for all subclasses implementing
kinds of results to the C<select()> call, as requested
by the C<-result_as> argument.
See L<DBIx::DataModel::Doc::Reference/select()>.

=head1 METHODS

Subclasses should implement

=over

=item C<new()>

The constructor

=item C<get_result()>

  $result = $subclass->new(...)->get_result($statement);

The method receives a reference to a
L<DBIx::DataModel::Statement>; calls like
C<< $statement->header >> and C<< $statement->next >>
may be used to build the expected result.

=back
