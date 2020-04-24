package Data::Object::Role::Dumpable;

use 5.014;

use strict;
use warnings;
use routines;

use Moo::Role;

our $VERSION = '2.02'; # VERSION

# METHODS

method dump() {
  require Data::Dumper;

  no warnings 'once';

  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Deepcopy = 1;
  local $Data::Dumper::Deparse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Useqq = 1;

  my $data = Data::Dumper::Dumper($self);

  $data =~ s/^"|"$//g;

  return $data;
}

method pretty_dump() {
  require Data::Dumper;

  no warnings 'once';

  local $Data::Dumper::Indent = 2;
  local $Data::Dumper::Trailingcomma = 0;
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Pad = '';
  local $Data::Dumper::Varname = 'VAR';
  local $Data::Dumper::Useqq = 0;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Freezer = '';
  local $Data::Dumper::Toaster = '';
  local $Data::Dumper::Deepcopy = 1;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Bless = 'bless';
  local $Data::Dumper::Pair = ' => ';
  local $Data::Dumper::Maxdepth = 0;
  local $Data::Dumper::Maxrecurse = 1000;
  local $Data::Dumper::Useperl = 0;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Deparse = 1;
  local $Data::Dumper::Sparseseen = 0;

  my $data = Data::Dumper::Dumper($self);

  $data =~ s/^'|'$//g;

  chomp $data;

  return $data;
}

method pretty_print(@args) {

  return $self->printer(map &pretty_dump($_), $self, @args);
}

method pretty_say(@args) {

  return $self->printer(map +(&pretty_dump($_), "\n"), $self, @args);
}

method print(@args) {

  return $self->printer(map &dump($_), $self, @args);
}

method printer(@args) {

  return CORE::print(@args);
}

method say(@args) {

  return $self->printer(map +(&dump($_), "\n"), $self, @args);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Dumpable

=cut

=head1 ABSTRACT

Dumpable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  with 'Data::Object::Role::Dumpable';

  package main;

  my $example = Example->new;

  # $example->dump

=cut

=head1 DESCRIPTION

This package provides methods for dumping the object and underlying value.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 dump

  dump() : Str

The dump method returns a string representation of the underlying data.

=over 4

=item dump example #1

  # given: synopsis

  my $dumped = $example->dump;

=back

=cut

=head2 pretty_dump

  pretty_dump() : Str

The pretty_dump method returns a string representation of the underlying data
that is human-readable and useful for debugging.

=over 4

=item pretty_dump example #1

  # given: synopsis

  my $dumped = $example->pretty_dump;

=back

=cut

=head2 pretty_print

  pretty_print(Any @args) : Int

The pretty_print method prints a stringified human-readable representation of
the underlying data.

=over 4

=item pretty_print example #1

  # given: synopsis

  my $printed = $example->pretty_print;

=back

=over 4

=item pretty_print example #2

  # given: synopsis

  my $printed = $example->pretty_print({1..4});

=back

=cut

=head2 pretty_say

  pretty_say(Any @args) : Int

The pretty_say method prints a stringified human-readable representation of the
underlying data, with a trailing newline.

=over 4

=item pretty_say example #1

  # given: synopsis

  my $printed = $example->pretty_say;

=back

=over 4

=item pretty_say example #2

  # given: synopsis

  my $printed = $example->pretty_say({1..4});

=back

=cut

=head2 print

  print(Any @args) : Int

The print method prints a stringified representation of the underlying data.

=over 4

=item print example #1

  # given: synopsis

  my $printed = $example->print;

=back

=over 4

=item print example #2

  # given: synopsis

  my $printed = $example->print({1..4});

=back

=cut

=head2 say

  say(Any @args) : Int

The say method prints a stringified representation of the underlying data, with
a trailing newline.

=over 4

=item say example #1

  # given: synopsis

  my $printed = $example->say;

=back

=over 4

=item say example #2

  # given: synopsis

  my $printed = $example->say({1..4});

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role-dumpable/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role-dumpable/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role-dumpable>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role-dumpable/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role-dumpable/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role-dumpable/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role-dumpable/issues>

=cut
