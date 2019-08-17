package Data::Object::Role::Output;

use strict;
use warnings;

use Data::Object::Role;

our $VERSION = '0.98'; # VERSION

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

  print() : NumObject

Output stringified object data.

=over 4

=item print example

  my $print = $self->print();

=back

=cut

=head2 say

  say() : NumObject

Output stringified object data with newline.

=over 4

=item say example

  my $say = $self->say();

=back

=cut
