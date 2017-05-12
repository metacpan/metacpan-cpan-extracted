
package Acme::Chef::Recipe;

use strict;
use warnings;

use Carp;

use Acme::Chef::Ingredient;
use Acme::Chef::Container;

=head1 NAME

Acme::Chef::Recipe - Internal module used by Acme::Chef

=head1 SYNOPSIS

  use Acme::Chef;

=head1 DESCRIPTION

Please see L<Acme::Chef>;

=head2 METHODS

This is list of methods in this package.

=over 2

=cut

use vars qw/$VERSION %Grammars @GrammarOrder %Commands/;
$VERSION = '1.01';

@GrammarOrder = qw(
  take_from add_dry put fold add remove combine divide
  liquify_contents liquify stir_time stir_ingredient
  mix clean pour refrigerate set_aside serve_with
  until_verbed verb
);

{ # scope of grammar definition

   my $ord         = qr/([1-9]\d*)(?:st|nd|rd|th)/;
   my $ord_noncap  = qr/[1-9]\d*(?:st|nd|rd|th)/;
   my $ingr_noncap = qr/[\-\w][\- \w]*/;
   my $ingr        = qr/($ingr_noncap)/;
   my $verb        = qr/([\-\w]+)/;

   %Grammars = (

     put => sub {
        my $recipe = shift;
        local $_ = shift;
        my $regex;
        if (/ into (?:the )?(?:$ord )?mixing bowl$/) {
           $regex = qr/^Put (?:the )?$ingr into (?:the )?(?:$ord )?mixing bowl$/;
        } else {
           $regex = qr/^Put (?:the )?$ingr$/;
        }
        /$regex/ or return();
        $recipe->require_bowl($2||1);
        $recipe->require_ingredient($1, 'put');
        return 'put', $1, ($2||1);
     },

     take_from => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Take $ingr from refrigerator$/ or return();
        $recipe->require_ingredient($1);
        return 'take_from', $1;
     },

     fold => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Fold (?:the )?$ingr into (?:the )?(?:$ord )?mixing bowl$/ or return();
        $recipe->require_bowl($2||1);
        $recipe->require_ingredient($1, 'fold');
        return 'fold', $1, ($2||1);
     },

     add => sub {
        my $recipe = shift;
        local $_ = shift;
        my $regex;
        if (/ to (?:the )?(?:$ord )?mixing bowl$/) {
           $regex = qr/^Add (?:the )?$ingr to (?:the )?(?:$ord )?mixing bowl$/;
        } else {
           $regex = qr/^Add (?:the )?$ingr()$/;
        }
        /$regex/ or return();
        $recipe->require_bowl($2||1);
        $recipe->require_ingredient($1, 'add');
        return 'add', $1, ($2||1);
     },

     remove => sub {
        my $recipe = shift;
        local $_ = shift;
        my $regex;
        if (/ from (?:the )?(?:$ord )?mixing bowl$/) {
           $regex = qr/^Remove (?:the )?$ingr from (?:the )?(?:$ord )?mixing bowl$/;
        } else {
           $regex = qr/^Remove (?:the )?$ingr()$/;
        }
        /$regex/ or return();
        $recipe->require_bowl($2||1);
        $recipe->require_ingredient($1, 'remove');
        return 'remove', $1, ($2||1);
     },

     combine => sub {
        my $recipe = shift;
        local $_ = shift;
        my $regex;
        if (/ into (?:the )?(?:$ord )?mixing bowl$/) {
           $regex = qr/^Combine (?:the )?$ingr into (?:the )?(?:$ord )?mixing bowl$/;
        } else {
           $regex = qr/^Combine (?:the )?$ingr()$/;
        }
        /$regex/ or return();
        $recipe->require_bowl($2||1);
        $recipe->require_ingredient($1, 'combine');
        return 'combine', $1, ($2||1);
     },

     divide => sub {
        my $recipe = shift;
        local $_ = shift;
        my $regex;
        if (/ into (?:the )?(?:$ord )?mixing bowl$/) {
           $regex = qr/^Divide (?:the )?$ingr into (?:the )?(?:$ord )?mixing bowl$/;
        } else {
           $regex = qr/^Divide(?: the)?$ingr()$/;
        }
        /$regex/ or return();
        $recipe->require_bowl($2||1);
        $recipe->require_ingredient($1, 'divide');
        return 'divide', $1, ($2||1);
     },

     add_dry => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Add (?:the )?dry ingredients(?: to (?:the )?(?:$ord )?mixing bowl)?$/ or return();
        $recipe->require_bowl($1||1);
        return 'add_dry', ($1||1);
     },

     liquify_contents => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Liqu(?:i|e)fy (?:the )?contents of (?:the )?(?:$ord )?mixing bowl$/ or return();
        $recipe->require_bowl($1||1);
        return 'liquify_contents', ($1||1);
     },

     liquify => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Liqu(?:i|e)fy (?:the )?$ingr$/ or return();
        $recipe->require_ingredient($1, 'liquify');
        return 'liquify', $1;
     },

     stir_time => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Stir (?:(?:the )?(?:$ord )?mixing bowl )?for (\d+) minutes?$/ or return();
        $recipe->require_bowl($1||1);
        return 'stir_time', $2, ($1||1);
     },

     stir_ingredient => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Stir $ingr into (?:the )?(?:$ord )?mixing bowl$/ or return();
        $recipe->require_bowl($2||1);
        $recipe->require_ingredient($1, 'stir_ingredient');
        return 'stir_ingredient', $1, ($2||1);
     },

     mix => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Mix (?:the (?:$ord )?mixing bowl )well$/ or return();
        $recipe->require_bowl($1||1);
        return 'mix', ($1||1);
     },

     clean => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Clean (?:the )?(?:$ord )?mixing bowl$/ or return();
        $recipe->require_bowl($1||1);
        return 'clean', ($1||1);
     },

     pour => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Pour contents of (?:the )?((?:[1-9]\d*(?:st|nd|rd|th) )?)mixing bowl into (?:the )?((?:[1-9]\d*(?:st|nd|rd|th) )?)baking dish$/ or return();
        my $m = $1 || 1;
        my $b = $2 || 1;
        $m =~ s/\D//g;
        $b =~ s/\D//g;
        $recipe->require_bowl($m);
        $recipe->require_dish($b);
        return 'pour', $m, $b;
     },

     refrigerate => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Refrigerate(?: for (\d+) hours?)?$/ or return();
        return 'refrigerate', (defined $1 ? $1 : 0);
     },

     set_aside => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Set aside$/ or return();
        return 'set_aside';
     },

     serve_with => sub {
        my $recipe = shift;
        local $_ = shift;
        /^Serve with $ingr$/ or return();
        # $ingr is a recipe name here
        return 'serve_with', lc($1);
     },

     verb => sub {
        my $recipe = shift;
        local $_ = shift;
        /^$verb (?:the )?$ingr$/ or return();
        $recipe->require_ingredient($2, 'verb');
        return 'verb', lc($1), $2;
     },

     until_verbed => sub {
        my $recipe = shift;
        local $_ = shift;
        /^$verb ((?:(?:the )?$ingr_noncap )?)until ${verb}ed$/ or return();
        my $ing = (defined $2 ? $2 : '');
        my $verbed = $3;
        $verbed .= 'e' if not exists $recipe->{loops}{$verbed};
        $ing =~ s/^the //;
        $ing =~ s/ $//;
        $recipe->require_ingredient($ing, 'until_verbed') if $ing ne '';
        return 'until_verbed', $verbed, $ing;
     },

   );

}

%Commands = (
   put => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [2] - 1]
        ->
           put( $recipe -> {ingredients} -> {$data -> [1]} );
      return 1;
   },
   
   take_from => sub {
      my $recipe = shift;
      my $data   = shift;
      local $/   = "\n";
      my $value;
      while (1) {
         $value  = <STDIN>;
         last if $value =~ /^\s*\.?\d+/;
      }
      $recipe -> {ingredients} -> {$data -> [1]}
              -> value($value+0);
   },

   fold => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [2] - 1]
        ->
           fold( $recipe -> {ingredients} -> {$data -> [1]} );
      return 1;
   },

   add => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [2] - 1]
        ->
           add( $recipe -> {ingredients} -> {$data -> [1]} );
      return 1;
   },

   remove => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [2] - 1]
        ->
           remove( $recipe -> {ingredients} -> {$data -> [1]} );
      return 1;
   },

   combine => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [2] - 1]
        ->
           combine( $recipe -> {ingredients} -> {$data -> [1]} );
      return 1;
   },

   divide => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [2] - 1]
        ->
           divide( $recipe -> {ingredients} -> {$data -> [1]} );
      return 1;
   },

   add_dry => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [1] - 1]
        ->
           put_sum(
                    grep { $_->type() eq 'dry' }
                         values %{ $recipe -> {ingredients} }
                  );
      return 1;
   },

   liquify => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {ingredients} -> {$data -> [1]} -> liquify();
      return 1;
   },

   liquify_contents => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [1] - 1] -> liquify_contents();
      return 1;
   },

   stir_time => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [2] - 1]
        ->
           stir_time( $data -> [1] );
      return 1;
   },

   stir_ingredient => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [2] - 1]
        ->
           stir_ingredient( $recipe -> {ingredients} -> {$data -> [1]} );
      return 1;
   },

   mix => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [1] - 1] -> mix();
      return 1;
   },

   clean => sub {
      my $recipe = shift;
      my $data   = shift;
      $recipe -> {bowls} -> [$data -> [1] - 1] -> clean();
      return 1;
   },

   pour => sub {
      my $recipe = shift;
      my $data   = shift;
      my @stuff  = $recipe -> {bowls} -> [$data -> [1] - 1] -> pour();

      $recipe -> {dishes} -> [$data -> [2] - 1] -> put( $_ ) foreach @stuff;

      return 1;
   },

   refrigerate => sub {
      my $recipe = shift;
      my $data   = shift;
      my $serves = $recipe->{serves};
      my $hours  = $data->[1];
      $serves  ||= 0;
      $hours   ||= 0;
      $recipe->{serves} = $hours if $serves < $hours;
      return 'halt';
   },

   set_aside => sub {
      my $recipe = shift;
      my $data   = shift;

      return 'break';
   },

   serve_with => sub {
      my $recipe = shift;
      my $data   = shift;

      my $rec_recipe = $data->[1];

      return "recurse.$rec_recipe" ;
   },

   verb => sub {
      my $recipe = shift;
      my $data   = shift;

      my $verb = $data->[1];
      my $ingr = $data->[2];
      return "loop.$verb.$ingr";
   },

   until_verbed => sub {
      my $recipe = shift;
      my $data   = shift;

      my $verb = $data->[1];

      if ( exists $recipe->{ingredients}->{$data->[2]} ) {
         my $ingr = $recipe->{ingredients}->{$data->[2]};
         $ingr->value( $ingr->value() - 1 );
      }

      return "endloop.$verb";
   },

);

=item new

Acme::Chef::Recipe constructor. Arguments are interpreted as key/value pairs
and used as object attributes.

=cut


sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my $self = {};

   if (ref $proto) {
      %$self = %$proto;

      $self->{bowls}  = [ map { $_->new() } @{$self -> {bowls }} ];
      $self->{dishes} = [ map { $_->new() } @{$self -> {dishes}} ];
      $self->{loops}  = { map { ( $_, $self->{loops}{$_} ) }
                              keys %{$self->{loops}} };

      if ( $self->{compiled} ) {
         $self->{ingredients} = { map {
             (
              $_,
              $self -> {ingredients} -> {$_} -> new()
             )
           } keys %{ $self->{ingredients} }
         };
      }
   }

   my %args  = @_;

   %$self = (
     compiled     => 0,
     name         => '',
     comments     => '',
     ingredients  => '',
     cooking_time => '',
     temperature  => '',
     method       => '',
     serves       => '',
     output       => '',
     loops        => {},
     bowls        => [],
     dishes       => [],
     %$self,
     %args,
   );

   bless $self => $class;
   return $self;
}


=item execute

Executes the recipe (program). First argument should be a reference to a
hash of sous-recipes.

=cut


sub execute {
   my $self    = shift;

   my $recipes = shift;

   $self->compile() unless $self->{compiled};

   my @loop_stack;

   my $max_pos = $#{$self->{method}};
   my $exec_pos = 0;
   while (1) {

      my $next_method = $self->{method}->[$exec_pos];
#      print ' ' x scalar(@loop_stack), join(',', @$next_method),"\n";

      my $return = $Commands{$next_method->[0]}->($self, $next_method);

      last if $return eq 'halt';

      if ( $return =~ /^recurse\.([\-\w][\-\w ]*)/ ) {
         exists $recipes->{$1}
           or croak "Invalid recipe '$1' specified for recursion.";

         my $clone       = $self->new();
         my $sous_recipe = $recipes->{$1}->new(
           bowls  => $clone->{bowls},
           dishes => $clone->{dishes},
         );

         my $sous_done   = $sous_recipe->execute( $recipes );

         $self->output( $sous_done->output() );

         $self -> {bowls} -> [0]
           -> put( $sous_done -> first_bowl() -> new() -> pour() );

      } elsif ( $return =~ /^loop\.([^\.]+)\.([^\.]+)/ ) {
         my $verb = $1;
         my $ingr = $2;

         push @loop_stack, $verb;

         if ( not $self -> {ingredients} -> {$ingr} -> value() ) {
            pop @loop_stack;
            $exec_pos = $self -> {loops} -> {$verb} -> {end};
         }

      } elsif ( $return =~ /^endloop\.([^\.]+)/ ) {
         my $verb = $1;

         $exec_pos = $self -> {loops} -> {$verb} -> {start} - 1;

      } elsif ( $return =~ /^break/ ) {
         my $verb = pop @loop_stack;
         $exec_pos = $self -> {loops} -> {$verb} -> {end};
      }

      $exec_pos++;
      last if $exec_pos > $max_pos;
   }

   if ( $self->{serves} ) {
      foreach my $serve ( 0..($self->{serves}-1) ) {
         last if $serve > $#{$self->{dishes}};
         my $string = $self->{dishes}->[$serve]->print();
         $self->{output} .= $string;
      }
   }

   return $self;
}

=item first_bowl

Returns the first bowl of the recipe.

=cut

sub first_bowl {
   my $self = shift;
   return $self->{bowls}->[0];
}

=item require_ingredient

First argument must be an ingredient object. Second may be a string indicating
the location of the requirement. Throws a fatal error if the ingredient is not
present.

=cut

sub require_ingredient {
   my $self = shift;
   my $ingredient = shift;
   my $sub = shift;

   (defined $ingredient and exists $self->{ingredients}{$ingredient})
     or croak "Unknown ingredient '".(defined$ingredient?$ingredient:'<undefined>').
              "' required for recipe '$self->{name}'".
              (defined $sub?" in '$sub'":'').".";

   return $self;
}

=item output

Mutator for the Recipe output.

=cut

sub output {
   my $self = shift;

   $self->{output} .= shift if @_;

   return $self->{output};
}

=item require_bowl

First argument must be a number of bowls. Additional bowls are added to the
recipe if it currently has less than this number of bowls.

=cut

sub require_bowl {
   my $self = shift;
   my $no   = shift;

   return if @{$self->{bowls}} >= $no;

   while (@{$self->{bowls}} < $no) {
      push @{$self->{bowls}}, Acme::Chef::Container->new();
   }

   return $self;
}


=item require_dish

First argument must be a number of dishes. Additional dishes are added to the
recipe if it currently has less than this number of dishes.

=cut

sub require_dish {
   my $self = shift;
   my $no   = shift;

   return if @{$self->{dishes}} >= $no;

   while (@{$self->{dishes}} < $no) {
      push @{$self->{dishes}}, Acme::Chef::Container->new();
   }

   return $self;
}

=item recipe_name

Mutator for the recipe name.

=cut

sub recipe_name {
   my $self = shift;

   $self->{name} = shift if @_;

   return $self->{name};
}


=item compile

Tries to compile the recipe. Returns 0 on error or if the recipe was
already compiled. Returns the compiled recipe if the compilation succeeded.

=cut

sub compile {
   my $self = shift;

   return 0 if $self->{compiled};

   my @ingredients = split /\n/, $self->{ingredients};

   shift @ingredients; # remove header line

   @ingredients or croak "Failed compiling recipe. No ingredients specified.";

   my %ingredients;
   my $ingredient_no = 0;

   foreach (@ingredients) {
      $ingredient_no++;

      my $value;
      if (s/^[ ]*(\d+)[ ]//) {
         $value = $1;
      } else {
         $value = undef;
      }

      my $measure_type = '';
      foreach my $type ( keys %Acme::Chef::Ingredient::MeasureTypes ) {
         if ( s/^\Q$type\E[ ]// ) {
            $measure_type = $type;
            last;
         }
      }

      my $measure = '';
      foreach my $meas ( keys %Acme::Chef::Ingredient::Measures ) {
         next if $meas eq '';

         if ( s/^\Q$meas\E[ ]// ) {
            $measure = $meas;
            last;
         }
      }

      /[ ]*([\-\w][\- \w]*)[ ]*$/
        or croak "Invalid ingredient specification (ingredient no. $ingredient_no, name).";

      my $ingredient_name = $1;

      my $ingredient = Acme::Chef::Ingredient->new(
        name         => $ingredient_name,
        value        => $value,
        measure      => $measure,
        measure_type => $measure_type,
      );

      $ingredients{$ingredient_name} = $ingredient;
   }

   $self->{ingredients} = \%ingredients;

   $self->{method} =~ s/\s+/ /g;

   my @steps = split /\s*\.\s*/, $self->{method};

   shift @steps; # remove "Method."

   my $step_no = 0;
   foreach my $step (@steps) {
      $step_no++;

      foreach my $grammar (@GrammarOrder) {
         my @res = $Grammars{$grammar}->($self, $step);
         @res or next;

         if ( $res[0] eq 'verb' ) {
            my $verb = $res[1];
            my $ingr = $res[2];

            $self->{loops}->{$verb} = {start => ($step_no-1), test => $ingr};
         } elsif ( $res[0] eq 'until_verbed' ) {
            my $verb = $res[1];
            exists $self->{loops}->{$verb}
              or croak "Loop end without loop start '$verb'.";

            $self->{loops}->{$verb}->{end} = $step_no - 1;
         }

         $step = [@res];
         last;
      }

      croak "Invalid method step (step no. $step_no): '$step'."
        if not ref $step eq 'ARRAY';
   }

   if ( grep { not exists $self->{loops}{$_}{end} } keys %{$self->{loops}} ) {
      croak "Not all loop starting points have matching ends.";
   }

   $self->{method} = \@steps;

   $self->{compiled} = 1;

   return $self;
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


