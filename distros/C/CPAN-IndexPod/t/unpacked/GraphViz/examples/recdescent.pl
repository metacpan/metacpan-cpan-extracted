#!/usr/bin/perl -w

use strict;
use lib '../lib';
use GraphViz::Parse::RecDescent;

# The grammar below was taken from the Parse::RecDescent
# demo_recipe.pl script

# "Potato, Egg, Red meat & Lard Cookbook",
# T. Omnicient Rash & N. Hot Ignorant-Kant
# O'Besity & Associates

my $recipegrammar =
q{
        Recipe: Step(s)

        Step:
                Verb Object Clause(s?)
                        { print "$item[1]\n" }
              | <resync:[ ]{2}>

        Verb: 
                'boil'
              | 'peel'
              | 'mix'
              | 'melt'
              | 'fry'
              | 'steam'
              | 'marinate'
              | 'sprinkle'
              | 'is'
              | 'are'
              | 'has'

        Object:
                IngredientQualifier(s) Ingredient
              | ReferenceQualifier(s) Ingredient
              | Reference
              
        Clause:
                SubordinateClause
              | CoordinateClause

        SubordinateClause:
                'until' State
              | 'while' State
              | 'for' Time

        CoordinateClause:
                /and( then)?/ Step
              | /or/ Step

        State:
                Object Verb Adjective
              | Adjective

        Time:
                Number TimeUnit

        TimeUnit:
                /hours?/
                /minutes?/
                /seconds?/

        QuantityUnit:
                /lbs?/


        Object:
                ReferenceQualifier Ingredient
              | Reference

        Reference:
                'they'
              | 'it'
              | 'them'

        Ingredient:
                'potatoes'
              | 'lard'
              | 'olive oil'
              | 'sugar'
              | 'bacon fat'
              | 'butter'
              | 'salt'
              | 'vinegar'

        IngredientQualifier:
                Amount
              | Number
              | 'a'
              | 'some'
              | 'large'
              | 'small'

        Amount: Number QuantityUnit

        ReferenceQualifier:
                'the'
              | 'those'
              | 'each'
              | 'half the'

        Number:
                /[1-9][0-9]*/
              | /one|two|three|four|five|six|seven|eight|nine/
              | 'a dozen'

        Adjective:
                'soft'
              | 'tender'
              | 'done'
              | 'charred'
              | 'grey'

};


my $graph = GraphViz::Parse::RecDescent->new($recipegrammar);
$graph->as_png("recdescent.png");
