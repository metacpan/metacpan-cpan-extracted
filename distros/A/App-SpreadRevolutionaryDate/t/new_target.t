#!/usr/bin/perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2026 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use utf8;

BEGIN {
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
}
binmode(DATA, ":encoding(UTF-8)");

use Test::More tests => 5;
use Test::Output;
use Test::NoWarnings;

package App::SpreadRevolutionaryDate::Target::Ezln;
use Moose;
with 'App::SpreadRevolutionaryDate::Target' => {worker => 'Bool'};
use namespace::autoclean;

has 'subcomandantes' => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
has 'land' => (is => 'ro', isa => 'Str', required => 1);

around BUILDARGS => sub {
  my ($orig, $class) = @_;

  # App::SpreadRevolutionaryDate::Target consumer classes
  # should have a mandatory 'obj' parameter valued by an
  # instance of the 'worker' class.
  # Since we do not need any worker here to simply printing
  # an output message, we just defined the 'worker' as 'Bool'
  # and instanciate obj to a true value.
  return $class->$orig(@_, obj => 1);
};

sub spread {
  my ($self, $msg) = @_;
  print "From " . $self->land . "\n$msg\nSubcomandantes " . join(', ', @{$self->subcomandantes}) . "\n";
}

1;

package main;

use App::SpreadRevolutionaryDate;

my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
is_deeply($spread_revolutionary_date->config->targets, ['ezln'], 'EZLN target option set');
is($spread_revolutionary_date->config->ezln_land, 'Chiapas', 'EZLN land value');
is_deeply($spread_revolutionary_date->config->ezln_subcomandantes, ['Marcos', 'Moisés', 'Galeano'], 'EZLN subcomandantes values');
stdout_like {$spread_revolutionary_date->spread } qr/^From Chiapas\nWe are .+\nSubcomandantes Marcos, Moisés, Galeano\n$/u, 'Spread to Ezln';

__DATA__
targets = 'ezln'
locale = 'en'

[ezln]
subcomandantes = 'Marcos'
subcomandantes = 'Moisés'
subcomandantes = 'Galeano'
land = 'Chiapas'
