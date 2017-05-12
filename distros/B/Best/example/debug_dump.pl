#!/usr/bin/perl -w

use strict;
use warnings;

use Best qw[ YAML::XS YAML::Syck YAML ];

my $data = {
  a => 'b',
  c => [ qw(d e f) ],
  g => {
	h => 'i',
   	j => [ qw(k l m) ],
  },
};
$data->{g}{n} = $data->{c};

sub ::Y  { Dump(@_) }
sub ::YY { require Carp; Carp::confess(::Y(@_)) }

print ::Y($data);
