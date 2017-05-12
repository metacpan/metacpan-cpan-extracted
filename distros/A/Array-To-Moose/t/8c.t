#!perl -w

use strict;

use Test::More;

# Simple test of throw_nonunique_keys(), example from POD

use Array::To::Moose qw (:ALL);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 3;

eval 'use VarianReportsMoose qw(print_obj)';

use Data::Dumper;

use Carp;

package Employer;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has 'year'    => (is => 'rw', isa => 'Str');
has 'name'    => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;

package Person;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has 'name'        => (is => 'rw', isa => 'Str'              );
has 'Employers'   => (is => 'rw', isa => 'HashRef[Employer]');

__PACKAGE__->meta->make_immutable;

package main;

my $data = [
  [ 'Anne Miller', '2005', 'Acme Corp'    ],
  [ 'Anne Miller', '2006', 'Acme Corp'    ],
  [ 'Anne Miller', '2007', 'Widgets, Inc' ],
];

my $desc = {  class     => 'Person',
              name      => 0,
              Employers => {
                class => 'Employer',
                key   => 2, # using employer name as key
                year  => 1,
              } # Employer
            }; # Person

my $obj = array_to_moose(
                  data => $data,
                  desc => $desc,
);

is($obj->[0]->Employers->{'Acme Corp'}->year, '2006',
                  "Non-unique keys, warnings off");

throw_nonunique_keys();

throws_ok { array_to_moose( data => $data, desc => $desc) }
            qr/^Non-unique key 'Acme Corp' in 'Employer' class/,
            "Non-unique keys, warnings on, exception thrown";

throw_nonunique_keys(0);

$obj = array_to_moose(
                  data => $data,
                  desc => $desc,
);

is($obj->[0]->Employers->{'Acme Corp'}->year, '2006',
                  "Non-unique keys, warnings off again");
