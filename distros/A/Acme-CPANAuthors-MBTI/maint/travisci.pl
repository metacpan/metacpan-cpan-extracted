#!/usr/bin/env perl
# ABSTRACT: Fixup vars for this

use strict;
use warnings;
use utf8;

use version;

sub {
  my ($yaml)       = @_;
  my $support      = {};
  my $base_version = version->parse('v5.14');
  my @extra_allow_fail;

  for my $include_matrix ( @{ $yaml->{matrix}->{include} } ) {
    my $support_version = $include_matrix->{perl};
    next unless $support_version;
    next unless version->parse( 'v' . $support_version ) < $base_version;
    push @extra_allow_fail, { %{$include_matrix} };
  }
  push @{ $yaml->{matrix}->{allow_failures} }, @extra_allow_fail;
  return $yaml;
};
