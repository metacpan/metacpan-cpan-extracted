#!perl -w

use strict;

use Test::More;

# Simple test of throw_multiple_rows(), example from POD

use Array::To::Moose qw (:ALL);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 3;

eval 'use VarianReportsMoose qw(print_obj)';

use Data::Dumper;

use Carp;

package Salary;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has 'year'    => (is => 'rw', isa => 'Str');
has 'amount'  => (is => 'rw', isa => 'Int');

__PACKAGE__->meta->make_immutable;

package Person;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has 'name'     => (is => 'rw', isa => 'Str'   );
has 'Salary'   => (is => 'rw', isa => 'Salary'); # a single object

__PACKAGE__->meta->make_immutable;

package main;

my $data = [
  [ 'John Smith', '2005', 23_350 ],
  [ 'John Smith', '2006', 24_000 ],
  [ 'John Smith', '2007', 26_830 ],
];

my $desc = {  class     => 'Person',
              name      => 0,
              Salary => {
                class => 'Salary',
                year   => 1,
                amount => 2
              } # Salary
            }; # Person

my $obj = array_to_moose(
                  data => $data,
                  desc => $desc,
);

is($obj->[0]->Salary->year, '2005',
                  "Multiple rows, warnings off");

throw_multiple_rows();

throws_ok {array_to_moose( data => $data, desc => $desc) }
      qr/^Expected a single 'Salary' object, but got 3 of them at/,
      "Multiple rows, warnings on";

throw_multiple_rows(0);

lives_ok {array_to_moose( data => $data, desc => $desc) }
      "Multiple rows, warnings turned on again";
