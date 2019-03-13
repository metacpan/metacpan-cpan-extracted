package Data::Object::Role::Output;

use strict;
use warnings;

use Data::Object::Role;

# BUILD
# METHODS

sub print {
  my ($self) = @_;

  my @result = Data::Object::Role::Dumper::dump($self);

  return CORE::print(@result);
}

sub say {
  my ($self) = @_;

  my @result = Data::Object::Role::Dumper::dump($self);

  return CORE::print(@result, "\n");
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Output

=cut

=head1 ABSTRACT

Data-Object Output Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Output';

=cut

=head1 DESCRIPTION

Data::Object::Role::Output provides routines for operating on Perl 5 data
objects which meet the criteria for being outputable.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 print

  my $print = $self->print();

Output stringified object data.

=cut

=head2 say

  my $say = $self->say();

Output stringified object data with newline.

=cut
