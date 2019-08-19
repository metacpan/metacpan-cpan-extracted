package Data::Object::Rule::Comparison;

use strict;
use warnings;

use Data::Object::Rule;

our $VERSION = '0.99'; # VERSION

# BUILD

requires 'eq';
requires 'gt';
requires 'ge';
requires 'lt';
requires 'le';
requires 'ne';

# METHODS

1;
=encoding utf8

=head1 NAME

Data::Object::Rule::Comparison

=cut

=head1 ABSTRACT

Data-Object Comparison Rules

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Rule::Comparison';

=cut

=head1 DESCRIPTION

Data::Object::Rule::Comparison provides routines for operating on Perl 5 data
objects which meet the criteria for being comparable.

=cut
