package Data::Object::Role::Detract;

use strict;
use warnings;

use Data::Object::Role;

# BUILD
# METHODS

sub data {
  goto \&detract;
}

sub detract {
  my ($data) = @_;

  require Data::Object::Export;

  return Data::Object::Export::detract_deep($data);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Detract

=cut

=head1 ABSTRACT

Data-Object Detract Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Detract';

=cut

=head1 DESCRIPTION

Data::Object::Role::Detract provides routines for operating on Perl 5
data objects which meet the criteria for being detractable.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 data

  my $data = $self->data();

The data method returns the underlying data structure.

=cut

=head2 detract

  my $detract = $self->detract();

The detract method returns the underlying data structure.

=cut
