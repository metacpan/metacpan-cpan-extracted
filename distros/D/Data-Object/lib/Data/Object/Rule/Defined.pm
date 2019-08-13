package Data::Object::Rule::Defined;

use strict;
use warnings;

use Data::Object::Rule;

our $VERSION = '0.97'; # VERSION

# BUILD

requires 'defined';

# METHODS

1;
=encoding utf8

=head1 NAME

Data::Object::Rule::Defined

=cut

=head1 ABSTRACT

Data-Object Defined Rules

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Rule::Defined';

=cut

=head1 DESCRIPTION

Data::Object::Rule::Defined provides routines for operating on Perl 5
data objects which meet the criteria for being defined.

=cut
