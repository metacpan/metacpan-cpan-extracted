# Please read the pod documentation in this file for
# details on how to reach the author and copyright issues.

package Acme::Chef;

use 5.006;
use strict;
use warnings;

use Carp;

use vars qw/$VERSION/;
$VERSION = '1.03';

use Acme::Chef::Recipe;
use Acme::Chef::Container;
use Acme::Chef::Ingredient;

=head1 NAME

Acme::Chef - An interpreter for the Chef programming language

=head1 SYNOPSIS

  # Using the script that comes with the distribution.
  chef.pl file.chef
  
  # Using the module
  use Acme::Chef;
  
  my $compiled = Acme::Chef->compile($code_string);  
  print $compiled->execute();
  
  my $string = $compiled->dump(); # requires Data::Dumper
  # Save it to disk, send it over the web, whatever.
  my $reconstructed_object = eval $string;
  
  # or:
  $string = $compiled->dump('autorun'); # requires Data::Dumper
  # Save it to disk, send it over the web, whatever.
  my $output_of_chef_program = eval $string;

=head1 DESCRIPTION

Chef is an esoteric programming language in which programs look like
recipes. I needn't mention that using it in
production environment, heck, using it for anything but entertainment
ought to result in bugs and chaos in reverse order.

All methods provided by Acme::Chef are adequately described in the
synopsis. If you don't think so, you need to read the source code.

There has been an update to the Chef specification. I have implemented
the changes and marked them in the following documentation with
"I<new specification>".

With that out of the way, I would like to present a pod-formatted
copy of the Chef specification from David Morgan-Mar's homepage
(L<http://www.dangermouse.net/esoteric/chef.html>).

=head2 METHODS

This is a list of methods in this package.

=over 2

=item compile

Takes Chef source code as first argument and compiles a Chef program from it.
This method doesn't run the code, but returns a program object.

=cut

sub compile {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my $code = shift;
   defined $code or croak "compile takes one argument: a code string.";

   my $self = {};

   bless $self => $class;

   my @paragraphs = $self->_get_paragraphs( $code );
   my @recipes    = $self->_paragraphsToRecipes(\@paragraphs);

   $_->compile() foreach @recipes;

   $self->{start_recipe} = $recipes[0]->recipe_name();

   $self->{recipes} = {
                        map { ($_->recipe_name(), $_) } @recipes
                      };

   return $self;
}


=item execute
 
Takes no arguments. Runs the program and returns its output.

=cut

sub execute {
   my $self = shift;

   my $start_recipe = $self->{recipes}->{ $self->{start_recipe} }->new();

   $start_recipe->execute($self->{recipes});

   return $start_recipe->output();   
}


=item dump
 
Takes one optional argument. If it equals 'autorun',
dump returns a string that, when evaluated, executes
the program and returns the output.

If the argument does not equal 'autorun', a different
string is returned that reconstructs the Acme::Chef
object.

=cut

sub dump {
   my $self = shift;
   my $type = shift;
   $type = '' if not defined $type;

   local $@ = undef;
   require Data::Dumper;

   my $dumper = Data::Dumper->new([$self], ['self']);
   $dumper->Indent(0);
   $dumper->Purity(1);

   my $dump = $dumper->Dump();

   if ($type =~ /^autorun$/) {
      $dump = 'do{my ' . $dump . ' bless $self => "' . (__PACKAGE__) . '"; $self->execute();} ';
   } else {
      $dump = 'do{my ' . $dump . ' bless $self => "' . (__PACKAGE__) . '";} ';
   }

   return $dump;
}


# private function _get_paragraphs

sub _get_paragraphs {
   my $self = shift;

   my $string = shift;

   $string =~ s/^\s+//;
   $string =~ s/\s+$//;

   return split /\n{2,}/, $string;
}


# private function _paragraphsToRecipes
# 
# Constructs recipes from an array ref of paragraphs.

sub _paragraphsToRecipes {
   my $self = shift;

   my $paragraphs = shift;
   $paragraphs = shift if not defined $paragraphs or not ref $paragraphs;

   while (chomp @$paragraphs) {}

   my @recipes;

   my $paragraph_no = 0;
   while (@$paragraphs) {
      my $recipe_name = shift @$paragraphs;
      $paragraph_no++;
      $recipe_name =~ /^[ ]*([\-\w][\- \w]*)\.[ ]*$/
        or croak "Invalid recipe name specifier in paragraph no. $paragraph_no.";
      $recipe_name = lc($1);

      last unless @$paragraphs;
      my $comments = shift @$paragraphs;
      $paragraph_no++;
      my $ingredients;
      if ( $comments =~ /^[ ]*Ingredients\.[ ]*\n/ ) {
         $ingredients = $comments;
         $comments = '';
      } else {
         last unless @$paragraphs;
         $ingredients = shift @$paragraphs;
         $paragraph_no++;
      }

      last unless @$paragraphs;
      my $cooking_time = shift @$paragraphs;
      $paragraph_no++;
      my $temperature;

      if ($cooking_time =~ /^[ ]*Cooking time:[ ]*(\d+)(?: hours?| minutes?)\.[ ]*$/) {
         $cooking_time = $1;
         last unless @$paragraphs;
         $temperature = shift @$paragraphs;
         $paragraph_no++;
      } else {
         $temperature = $cooking_time;
         $cooking_time = '';
      }

      my $method;
      if ($temperature =~ /^[ ]*Pre-heat oven to (\d+) degrees Celsius(?: gas mark (\d+))?\.[ ]*$/) {
         $temperature = $1;
         $temperature .= ",$2" if defined $2;
         last unless @$paragraphs;
         $method = shift @$paragraphs;
         $paragraph_no++;
      } else {
         $method = $temperature;
         $temperature = '';
      }

      $method =~ /^[ ]*Method\.[ ]*\n/
        or croak "Invalid method specifier in paragraph no. $paragraph_no.";
      
      my $serves = '';
      if (@$paragraphs) {
         $serves = shift @$paragraphs;
         if ($serves =~ /^[ ]*Serves (\d+)\.[ ]*$/) {
            $serves = $1;
            $paragraph_no++;
         } else {
            unshift @$paragraphs, $serves;
            $serves = '';
         }
      }

      push @recipes, Acme::Chef::Recipe->new(
        name         => $recipe_name,
        comments     => $comments,
        ingredients  => $ingredients,
        cooking_time => $cooking_time,
        temperature  => $temperature,
        method       => $method,
        serves       => $serves,
      );
      
   }
   
   return @recipes;
}


1;
__END__

=back

=head1 DESIGN PRINCIPLES

=over 2

=item *

Program recipes should not only generate valid output, but be easy to
prepare and delicious.

=item *

Recipes may appeal to cooks with different budgets.

=item *

Recipes will be metric, but may use traditional cooking measures such as
cups and tablespoons. 

=back

=head1 LANGUAGE CONCEPTS

=head2 Ingredients

All recipes have ingredients! The ingredients hold individual data values.
All ingredients are numerical, though they can be interpreted as Unicode
for I/O purposes. Liquid ingredients will be output as Unicode characters,
while dry or unspecified ingredients will be output as numbers.

=head2 Mixing Bowls and Baking Dishes

Chef has access to an unlimited supply of mixing bowls and baking dishes.
These can contain ingredient values. The ingredients in a mixing bowl or
baking dish are ordered, like a stack of pancakes. New ingredients are
placed on top, and if values are removed they are removed from the top.
Note that if the value of an ingredient changes, the value in the mixing
bowl or baking dish does not. The values in the mixing bowls and baking
dishes also retain their dry or liquid designations.

Multiple mixing bowls and baking dishes are referred to by an ordinal
identifier - "the 2nd mixing bowl". If no identifier is used, the recipe
only has one of the relevant utensil. Ordinal identifiers must be digits
followed by "st", "nd", "rd" or "th", not words. 

=head1 SYNTAX ELEMENTS

The following items appear in a Chef recipe. Some are optional. Items
must appear in the order shown below, with a blank line (two newlines)
between each item.

=head2 Recipe Title

The recipe title describes in a few words what the program does. For
example: "Hello World Souffle", or "Fibonacci Numbers with Caramel Sauce".
The recipe title is always the first line of a Chef recipe, and is
followed by a full stop.

  recipe-title.

=head2 Comments

Comments are placed in a free-form paragraph after the recipe title.
Comments are optional.

=head2 Ingredient List

The next item in a Chef recipe is the ingredient list. This lists the
ingredients to be used by the program. The syntax is

  Ingredients.
  [initial-value] [[measure-type] measure] ingredient-name
  [further ingredients]

Ingredients are listed one per line. The intial-value is a number.
I<New specification: The initial-value is now optional. Attempting to
use an ingredient without a defined value is a run-time error.>
The optional measure can be any of the following:

=over 2

=item *

C<g> | C<kg> | C<pinch[es]> : These always indicate dry measures.

=item *

C<ml> | C<l> | C<dash[es]> : These always indicate liquid measures.

=item *

C<cup[s]> | C<teaspoon[s]> | C<tablespoon[s]> : These indicate measures
which may be either dry or liquid.

=back

The optional measure-type may be any of the following:

=over 2

=item *

C<heaped> | C<level> : These indicate that the measure is dry.

=back

The ingredient-name may be anything reasonable, and may include space
characters. The ingredient list is optional. If present, it declares
ingredients with the given initial values and measures.

=head2 Cooking Time

  Cooking time: time (hour[s] | minute[s]).

The cooking time statement is optional. The time is a number.

=head2 Oven Temperature

  Pre-heat oven to temperature degrees Celcius [(gas mark mark)].

Some recipes require baking. If so, there will be an oven
temperature statement. This is optional. The temperature and mark are
numbers.

=head2 Method

  Method.
  method statements

The method contains the actual recipe instructions. These are written
in sentences. Line breaks are ignored in the method of a recipe. Valid
method instructions are:

=over 2

=item *

C<Take ingredient from refrigerator.>

I<New specification!> This reads lines from STDIN until a
numerical value is found. This numerical value is put into the
ingredient overwriting any previous value.

=item *

C<Put ingredient into [nth] mixing bowl.>

This puts the ingredient into the nth mixing bowl.

=item *

C<Fold ingredient into [nth] mixing bowl.>

This removes the top value from the nth mixing bowl and places it in
the ingredient.

=item *

C<Add ingredient [to [nth] mixing bowl].>

This adds the value of ingredient to the value of the ingredient on top
of the nth mixing bowl and stores the result in the nth mixing bowl.

=item *

C<Remove ingredient [from [nth] mixing bowl].>

This subtracts the value of ingredient from the value of the ingredient
on top of the nth mixing bowl and stores the result in the nth mixing bowl.

=item *

C<Combine ingredient [into [nth] mixing bowl].>

This multiplies the value of ingredient by the value of the ingredient on
top of the nth mixing bowl and stores the result in the nth mixing bowl.

=item *

C<Divide ingredient [into [nth] mixing bowl].>

This divides the value of ingredient into the value of the ingredient on
top of the nth mixing bowl and stores the result in the nth mixing bowl.

=item *

C<Add dry ingredients [to [nth] mixing bowl].>

This adds the values of all the dry ingredients together and places the
result into the nth mixing bowl.

=item *

C<Liquify ingredient.>
I<New specification!> C<Liquefy ingredient.>

This turns the ingredient into a liquid, i.e. a Unicode character for
output purposes.

=item *

C<Liquify contents of the [nth] mixing bowl.>
I<New specification!> C<Liquefy contents of the [nth] mixing bowl.>

This turns all the ingredients in the nth mixing bowl into a liquid, i.e.
a Unicode characters for output purposes.

=item *

C<Stir [the [nth] mixing bowl] for number minutes.>

This "rolls" the top number ingredients in the nth mixing bowl, such that
the top ingredient goes down that number of ingredients and all
ingredients above it rise one place. If there are not that many ingredients
in the bowl, the top ingredient goes to tbe bottom of the bowl and all the
others rise one place.

=item *

C<Stir ingredient into the [nth] mixing bowl.>

This rolls the number of ingredients in the nth mixing bowl equal to the
value of ingredient, such that the top ingredient goes down that number of
ingredients and all ingredients above it rise one place. If there are not
that many ingredients in the bowl, the top ingredient goes to tbe bottom
of the bowl and all the others rise one place.

=item *

C<Mix [the [nth] mixing bowl] well.>

This randomises the order of the ingredients in the nth mixing bowl.

=item *

C<Clean [nth] mixing bowl.>

This removes all the ingredients from the nth mixing bowl.

=item *

C<Pour contents of the [nth] mixing bowl into the [pth] baking dish.>

This copies all the ingredients from the nth mixing bowl to the pth baking 
ish, retaining the order and putting them on top of anything already in
the baking dish.

=item *

C<Verb the ingredient.>

This marks the beginning of a loop. It must appear as a matched pair with
the following statement. The loop executes as follows: The value of
ingredient is checked. If it is non-zero, the body of the loop executes
until it reaches the "until" statement. The value of ingredient is
rechecked. If it is non-zero, the loop executes again. If at any check
the value of ingredient is zero, the loop exits and execution continues
at the statement after the "until". Loops may be nested.

=item *

C<Verb [the ingredient] until verbed.>

This marks the end of a loop. It must appear as a matched pair with the
above statement. verbed must match the Verb in the matching loop start
statement. The Verb in this statement may be arbitrary and is ignored.
If the ingredient appears in this statement, its value is decremented
by 1 when this statement executes. The ingredient does not have to
match the ingredient in the matching loop start statement.

=item *

C<Set aside.>

This causes execution of the innermost loop in which it occurs to end
immediately and execution to continue at the statement after the "until".

=item *

C<Serve with auxiliary-recipe.>

This invokes a sous-chef to immediately prepare the named auxiliary-recipe.
The calling chef waits until the sous-chef is finished before continuing.
See the section on auxiliary recipes below.

=item *

C<Refrigerate [for number hours].>

This causes execution of the recipe in which it appears to end immediately.
If in an auxiliary recipe, the auxiliary recipe ends and the sous-chef's
first mixing bowl is passed back to the calling chef as normal. If a number
of hours is specified, the recipe will print out its first number baking
dishes (see the Serves statement below) before ending.

=back

=head2 Serves

The final statement in a Chef recipe is a statement of how many people
it serves.

  Serves number-of-diners.

This statement writes to STDOUT the contents of the first number-of-diners
baking dishes. It begins with the 1st baking dish, removing values from the
top one by one and printing them until the dish is empty, then progresses to
the next dish, until all the dishes have been printed. The serves statement
is optional, but is required if the recipe is to output anything!

=head2 Auxiliary Recipes

These are small recipes which are needed to produce specialised ingredients
for the main recipe (such as sauces). They are listed after the main recipe.
Auxiliary recipes are made by sous-chefs, so they have their own set of
mixing bowls and baking dishes which the head Chef never sees, but take
copies of all the mixing bowls and baking dishes currently in use by the
calling chef when they are called upon. When the auxiliary recipe is
finished, the ingredients in its first mixing bowl are placed in the same
order into the calling chef's first mixing bowl.

For example, the main recipe calls for a sauce at some point. The sauce
recipe is begun by the sous-chef with an exact copy of all the calling
chef's mixing bowls and baking dishes. Changes to these bowls and dishes
do not affect the calling chef's bowls and dishes. When the sous-chef is
finished, he passes his first mixing bowl back to the calling chef, who
empties it into his first mixing bowl.

An auxiliary recipe may have all the same items as a main recipe. 

=head1 BUGS

A lot. This is a boring night's result.

In particular, the implementation does not always comply to the specification.
While this is admittedly very bad behaviour, the author claims in defense that
it usually allows a broader syntax than the specification so you should be safe
when sticking to the specification.

=head1 AUTHOR

Steffen Mueller.

Chef was designed by David Morgan-Mar.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2008 Steffen Mueller. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

Author can be reached at chef-module at steffen-mueller dot net

=cut


