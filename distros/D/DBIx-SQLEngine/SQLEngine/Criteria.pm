package DBIx::SQLEngine::Criteria;
use strict;

########################################################################

use Class::MakeMethods (
  'Standard::Universal:abstract' => 'new',
  'Template::ClassName:subclass_name --require' => 'type',
);

sub type_new {
  (shift)->type( shift )->new( @_ );
}

########################################################################

sub auto {
  my $package = shift;
  local $_ = shift;
  if ( ! $_ ) {
    ();
  } elsif ( ! ref( $_ ) and length( $_ ) ) {
    $package->type_new('LiteralSQL', $_ );
  } elsif ( UNIVERSAL::can($_, 'sql_where') ) {
    $_;
  } elsif ( ref($_) eq 'ARRAY' ) {
    $package->type_new('LiteralSQL', @$_ );
  } elsif ( ref($_) eq 'HASH' ) {
    $package->type_new('HashGroup', %$_ );
  } else {
    confess("Unsupported criteria spec '$_'");
  }
}

sub auto_and {
  my $package = shift;
  $package->type_new('And', map { $package->auto( $_ ) } @_ )
}

sub auto_where {
  my $package = shift;
  $package->auto_and( @_ )->sql_where;
}

########################################################################

package DBIx::SQLEngine::Criteria::StringEquality;
require DBIx::SQLEngine::Criteria::Equality;
       @DBIx::SQLEngine::Criteria::StringEquality::ISA = 
       'DBIx::SQLEngine::Criteria::Equality';
sub sql_comparator { DBIx::SQLEngine::Criteria::Equality->sql_comparator }

########################################################################

package DBIx::SQLEngine::Criteria::NumericLesser;
require DBIx::SQLEngine::Criteria::Lesser;
       @DBIx::SQLEngine::Criteria::NumericLesser::ISA = 
       'DBIx::SQLEngine::Criteria::Lesser';
sub sql_comparator { DBIx::SQLEngine::Criteria::Lesser->sql_comparator }

########################################################################

1;

__END__

########################################################################


=head1 NAME

DBIx::SQLEngine::Criteria - Struct for database criteria info

=head1 SYNOPSIS

  my $crit = DBIx::SQLEngine::Criteria->type_new( $type, ... );
  
  print $crit->sql_where();


=head1 DESCRIPTION

DBIx::SQLEngine::Criteria objects hold information about particular query criteria.


=head1 REFERENCE

=head2 Constructor

Multiple subclasses based on type.

=over 4

=item new 

Abstract. Implemented in each subclass

=item type_new

  DBIx::SQLEngine::Criteria->type_new( $type, @args ) : $criteria

Looks up type, then calls new.

=item type 

Multiple subclasses based on type. (See L<Class::MakeMethods::Template::ClassName/subclass_name>.)

=back

=head2 Generic Argument Parsing

=over 4

=item auto

  DBIx::SQLEngine::Criteria->auto( $sql_string ) : $criteria
  DBIx::SQLEngine::Criteria->auto( [ $sql_string, @params ] ) : $criteria
  DBIx::SQLEngine::Criteria->auto( { fieldname => matchvalue, ... } ) : $criteria
  DBIx::SQLEngine::Criteria->auto( $criteria_object ) : $criteria_object

Convert any one of several standard criteria representations into a DBIx::SQLEngine::Criteria object.

=item auto_and 

  DBIx::SQLEngine::Criteria->auto( @any_of_the_above ) : $criteria

Create a single criteria requiring the satisfaction of each of the separate criteria passed in. Supports the same argument forms as auto.

=item auto_where

  DBIx::SQLEngine::Criteria->auto_where( @any_of_the_above ) : $sql, @params

Create a single criteria requiring the satisfaction of each of the separate criteria passed in, and returns its sql_where results. Supports the same argument forms as auto.

=back


=head1 INCLUDED SUBCLASSES

The following criteria subclasses are included in this distribution:


=head2 Logical Groupings

=over 4

=item And

Requires all of its subclauses to be true.

=item Or

Requires at least one of its subclauses to be true.

=item Not

Requires its one subclause to be false.

=back


=head2 Comparison

=over 4

=item Equality

Requires an exact match with its comparison value. 

=item Greater

Requires a value higher than its comparison value.

=item Lesser

Requires a value lower than its comparison value.

=item Like

Requires a value that matches its comparison value, including any SQL wildcards.

=item StringComparison

Functions as an Equality unless a wildcard is used, in which case it's a Like.

=back


=head2 Programmer Convenience

=over 4

=item HashGroup

Easy way to create a group of StringComparison criteria.

=item LiteralSQL

Encapsulates a snippet of literal SQL, optionally with placeholder parameters.

=back


=head2 Backwards Compatibility

=over 4

=item StringEquality

Empty subclass to support an old name for Equality Criteria.

=item NumericLesser

Empty subclass to support an old name for Lesser Criteria.

=back


=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut
