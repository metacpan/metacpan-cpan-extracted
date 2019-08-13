package Data::Object::Rule::Collection;

use strict;
use warnings;

use Data::Object::Rule;

our $VERSION = '0.97'; # VERSION

# BUILD

requires 'each';
requires 'each_key';
requires 'each_n_values';
requires 'each_value';
requires 'exists';
requires 'invert';
requires 'iterator';
requires 'list';
requires 'keys';
requires 'get';
requires 'set';
requires 'slice';
requires 'values';

# METHODS

1;
=encoding utf8

=head1 NAME

Data::Object::Rule::Collection

=cut

=head1 ABSTRACT

Data-Object Collection Rules

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Rule::Collection';

=cut

=head1 DESCRIPTION

Data::Object::Rule::Collection provides routines for operating on Perl 5 data
objects which meet the criteria for being a collection.

=cut
