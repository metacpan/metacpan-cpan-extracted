package Data::Object::Rule::List;

use strict;
use warnings;

use Data::Object::Rule;

our $VERSION = '0.97'; # VERSION

# BUILD

requires 'grep';
requires 'head';
requires 'join';
requires 'length';
requires 'list';
requires 'map';
requires 'reverse';
requires 'sort';
requires 'tail';
requires 'values';

# METHODS

1;
=encoding utf8

=head1 NAME

Data::Object::Rule::List

=cut

=head1 ABSTRACT

Data-Object List Rules

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Rule::List';

=cut

=head1 DESCRIPTION

Data::Object::Rule::List provides routines for operating on Perl 5 data
objects which meet the criteria for being considered lists.

=cut
