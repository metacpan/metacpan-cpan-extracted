#!/usr/bin/env perl
use strict;
use warnings;

use Time::HiRes ('gettimeofday', 'tv_interval');

{

   package My::Form;
   use HTML::FormHandler::Moose;
   extends 'HTML::FormHandler';

   has '+name'         => ( default  => 'testform_' );

   has_field 'optname' => ( label     => 'First' );
   has_field 'reqname' => ( required => 1 );
   has_field 'somename';
   has_field 'my_selected' => ( type => 'Checkbox' );
   has_field 'must_select' => ( type => 'Checkbox', required => 1 );

   sub field_list
   {
      return [
         { name => 'fruit', type => 'Select' },
         { name => 'optname', label => 'Second' },
      ];
   }

   sub options_fruit
   {
      return (
         1 => 'apples',
         2 => 'oranges',
         3 => 'kiwi',
      );
   }
}

my $start_run = [gettimeofday];

my $index = 0;
while ( $index < 1000 ) {
  my $form = My::Form->new;
  my $params = $form->fif;
  $form->process( params => $params );
  $index++;
}

my $end_run = [gettimeofday];

my $elapsed = tv_interval( $start_run, $end_run );

print "Elapsed: $elapsed\n";

