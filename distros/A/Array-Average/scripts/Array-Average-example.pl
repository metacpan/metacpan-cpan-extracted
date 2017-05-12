#!/usr/bin/perl
use strict;
use warnings;
use Array::Average;

my @array=(2,3,4,5);
printf "Average (array): %s\n", average(@array);

printf "Average (list): %s\n", average(2,3,4,5);

printf "Average (array ref): %s\n", average(\@array);

printf "Average (anonymous array ref): %s\n", average([2,3,4,5]);

my %hash=(a=>3, b=>4);
printf "Average (hash ref): %s\n", average(\%hash);

printf "Average (anonymous hash ref): %s\n", average({a=>3, b=>4});

printf "Average (undef not counted): %s\n", average(undef, 3, undef, 4, undef);

printf "Average (undef not counted): %s\n", average({a=>undef, b=>3, c=>undef, d=>4, e=>undef});

{
  no warnings 'uninitialized';

  printf "Average (empty list): %s\n", average(());

  printf "Average (undef): %s\n", average(undef);
}
