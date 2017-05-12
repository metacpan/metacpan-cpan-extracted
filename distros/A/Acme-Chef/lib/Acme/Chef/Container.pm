
package Acme::Chef::Container;

use strict;
use warnings;

use Carp;

use Acme::Chef::Ingredient;

use vars qw/$VERSION/;
$VERSION = '1.00';

=head1 NAME

Acme::Chef::Container - Internal module used by Acme::Chef

=head1 SYNOPSIS

  use Acme::Chef;

=head1 DESCRIPTION

Please see L<Acme::Chef>;

=head2 METHODS

This is a list of methods in this package.

=over 2

=cut

=item new

This is the Acme::Chef::Container constructor. Creates a new
Acme::Chef::Container object. All arguments are treated as key/value pairs for
object attributes.

=cut

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my $self = {};

   if (ref $proto) {
      %$self = %$proto;
      $self->{contents} = [ map { $_->new() } @{$self -> {contents}} ];
   }

   %$self = (
     contents => [],
     %$self,
     @_,
   );

   return bless $self => $class;
}


=item put

This method implements the 'put' command. Please refer to L<Acme::Chef> for
details.

=cut

sub put {
   my $self = shift;

   my @ingredients = @_;

   push @{$self->{contents}}, $_->new() for @ingredients;

   return $self;
}

=item fold

This method implements the 'fold' command. Please refer to L<Acme::Chef> for
details.

=cut

sub fold {
   my $self = shift;

   my $ingredient = shift;

   croak "Invalid operation on empty container: fold."
     unless @{$self->{contents}};

   my $new_val = pop @{ $self->{contents} };

   $ingredient->value( $new_val->value() );

   return $ingredient;
}

=item add

This method implements the 'add' command. Please refer to L<Acme::Chef> for
details.

=cut

sub add {
   my $self = shift;

   my $ingredient = shift;

   croak "Invalid operation on empty container: add."
     unless @{$self->{contents}};

   $self->{contents}->[-1]->value(
     $self->{contents}->[-1]->value() +
     $ingredient->value()
   );

   return $ingredient;
}

=item remove

This method implements the 'remove' command. Please refer to L<Acme::Chef> for
details.

=cut


sub remove {
   my $self = shift;

   my $ingredient = shift;

   croak "Invalid operation on empty container: remove."
     unless @{$self->{contents}};

   $self->{contents}->[-1]->value(
     $self->{contents}->[-1]->value() -
     $ingredient->value()
   );

   return $ingredient;
}


=item combine

This method implements the 'combine' command. Please refer to L<Acme::Chef> for
details.

=cut

sub combine {
   my $self = shift;

   my $ingredient = shift;

   croak "Invalid operation on empty container: combine."
     unless @{$self->{contents}};

   $self->{contents}->[-1]->value(
     $self->{contents}->[-1]->value() *
     $ingredient->value()
   );

   return $ingredient;
}


=item divide

This method implements the 'divide' command. Please refer to L<Acme::Chef> for
details.

=cut

sub divide {
   my $self = shift;

   my $ingredient = shift;

   croak "Invalid operation on empty container: divide."
     unless @{$self->{contents}};

   $self->{contents}->[-1]->value(
     $self->{contents}->[-1]->value() /
     $ingredient->value()
   );

   return $ingredient;
}

=item put_sum

This method takes a number of Acme::Chef::Ingredient objects as arguments and
creates and 'puts' the sum of the ingredients.

Please refer to L<Acme::Chef> for details.

=cut

sub put_sum {
   my $self = shift;

   my @ingredients = @_;

   my $sum = 0;
   $sum += $_->value() for @ingredients;

   my $ingredient = Acme::Chef::Ingredient->new(
     name    => '',
     value   => $sum,
     measure => '',
     type    => 'dry',
   );

   $self->put($ingredient);

   return $ingredient;
}

=item liquify_contents

This method implements the 'liquify' command for all ingredients.
Please refer to L<Acme::Chef> for details.

=cut

sub liquify_contents {
   my $self = shift;

   foreach my $ingredient (@{$self->{contents}}) {
      $ingredient->liquify();
   }

   return $self;
}

=item stir_time

This method implements the 'stir' command.
First argument should be the depth ("time") to stir.
Please refer to L<Acme::Chef> for details.

=cut

sub stir_time {
   my $self = shift;

   my $depth = shift;

   return $self unless scalar @{$self->{contents}};

   $depth = $#{$self->{contents}} if $depth > $#{$self->{contents}};

   my $top = pop @{ $self->{contents} };
   splice @{$self->{contents}}, (@{$self->{contents}}-$depth), 0, $top;

   return $self;
}


=item stir_ingredient

This method implements the 'stir_ingredient' command. Please refer to
L<Acme::Chef> for details.

=cut


sub stir_ingredient {
   my $self = shift;

   my $ingredient = shift;

   $self->stir_time($ingredient->value());

   return $self;
}

=item mix

This method implements the 'mix' command. Please refer to L<Acme::Chef> for
details.

Shuffles the container's contents.

=cut

sub mix {
   my $self = shift;

   _fisher_yates_shuffle( $self->{contents} );

   return $self;
}

=item clean

This method implements the 'clean' command. Please refer to L<Acme::Chef> for
details.

Empties the container.

=cut

sub clean {
   my $self = shift;

   @{$self->{contents}} = ();

   return $self;
}


=item pour

This method implements the 'pour' command. Please refer to L<Acme::Chef> for
details.

Returns the contained ingredients.

=cut

sub pour {
   my $self = shift;

   return @{ $self->{contents} };
}


=item print

Returns stringification of the object.

=cut

sub print {
   my $self = shift;

   my $string = '';

   foreach my $ingr ( reverse @{$self->{contents}} ) {
      if ($ingr->type() eq 'liquid') {
         $string .= chr( $ingr->value() );
      } else {
         $string .= ' '.$ingr->value();
      }
   }

   return $string;
}


# From the Perl FAQ: (NOT a method)
# fisher_yates_shuffle( \@array ) :
# generate a random permutation of @array in place
sub _fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        @$array[$i,$j] = @$array[$j,$i];
    }
}

__END__

=back

=head1 AUTHOR

Steffen Mueller.

Chef designed by David Morgan-Mar.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2008 Steffen Mueller. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

Author can be reached at chef-module at steffen-mueller dot net

=cut



