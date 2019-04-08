package Data::Object::Role::Dumper;

use strict;
use warnings;

use Data::Object::Role;

our $VERSION = '0.95'; # VERSION

# BUILD
# METHODS

sub dump {
  my ($data) = @_;

  require Data::Dumper;
  require Data::Object::Export;

  no warnings 'once';

  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Deepcopy = 1;
  local $Data::Dumper::Deparse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Useqq = 1;

  $data = Data::Object::Export::detract_deep($_[0]);
  $data = Data::Dumper::Dumper($data);
  $data =~ s/^"|"$//g;

  return $data;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Dumper

=cut

=head1 ABSTRACT

Data-Object Dumper Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Dumper';

=cut

=head1 DESCRIPTION

Data::Object::Role::Dumper provides routines for operating on Perl 5 data
objects which meet the criteria for being dumpable.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 dump

  dump() : Str

The dump method returns a string representation of the underlying data.

=over 4

=item dump example

  my $dump = $self->dump();

=back

=cut
