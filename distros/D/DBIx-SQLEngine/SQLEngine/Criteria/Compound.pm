package DBIx::SQLEngine::Criteria::Compound;

@ISA = 'DBIx::SQLEngine::Criteria';

use strict;
use Carp;

########################################################################

sub new {
  my $package = shift;
  bless [ @_ ], $package;
}

########################################################################

sub subs {
  my $crit = shift;
  @$crit
}

sub push_subs {
  my $crit = shift;
  push @{ $crit->subs }, @_
}

sub unshift_subs {
  my $crit = shift;
  unshift @{ $crit->subs }, @_
}

########################################################################

use Class::MakeMethods (
  'Template::Class:string' => 'sql_join',
);

sub sql_where {
  my $self = shift;
  my (@clauses, @params);
  foreach my $sub ( $self->subs ) {
    my ($sql, @v_params) = $sub->sql_where( @_ );
    next if ( ! length $sql );
    push @clauses, $sql;
    push @params, @v_params;
  }
  return unless scalar @clauses;
  return ($clauses[0], @params) if ( scalar @clauses == 1 );
  my $joiner = $self->sql_join or Carp::confess "Class does not have a joiner";
  return ( '( ' . join( " $joiner ", @clauses ) . ' )', @params );
}

########################################################################

sub expr {
  my $self = shift;
  my %exprs;
  foreach my $sub ( $self->subs ) {
    if ( $sub->expr =~ /ARRAY/ ) {
      map {
        $exprs{ $_ } = 1;
      } @{$sub->expr};

    } else {
      $exprs{ $sub->expr } = 1;
    }
  }
  my @exprs = keys %exprs;
  return \@exprs;
}

1;

########################################################################

=head1 NAME

DBIx::SQLEngine::Criteria::Compound - Superclass for And and Or

=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria::CompoundSubclass->new( $crit, ... );


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria::Compound objects are built around an array of other criteria.


=head1 REFERENCE

=head2 Constructor

=over 4

=item new ( @criteria ) : $compound

Constructor.

=back

=cut

=head2 Content Access

=over 4

=item subs()

  $criteria->subs() : @criteria

Returns all of the contained criteria.

=item push_subs()

  $criteria->push_subs ( @criteria ) 

=item unshift_subs()

  $criteria->unshift_subs ( @criteria ) 

=back


=head2 SQL Where Generation

=over 4

=item sql_where()

  $criteria->sql_where() : $sql, @params

Generates SQL criteria expression. 

=back


=head1 SEE ALSO

See L<DBIx::SQLEngine::Criteria> and L<DBIx::SQLEngine::Criteria::Comparison>
for more information on using these objects.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
