package Data::Object::Search;

use 5.014;

use strict;
use warnings;
use routines;

use overload (
  '""'     => 'detract',
  '~~'     => 'detract',
  'bool'   => 'detract',
  'qr'     => 'regexp',
  '@{}'    => 'self',
  fallback => 1
);

use parent 'Data::Object::Array';

our $VERSION = '2.05'; # VERSION

# METHODS

method captures() {
  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my @captures;

  for (my $i = 1; $i < @$last_match_end; $i++) {
    my $start = $last_match_start->[$i] || 0;
    my $end   = $last_match_end->[$i]   || 0;

    push @captures, substr "$string", $start, $end - $start;
  }

  return [@captures];
}

method count() {

  return $self->[2];
}

method initial() {

  return $self->[6];
}

method last_match_end() {

  return $self->[4];
}

method last_match_start() {

  return $self->[3];
}

method named_captures() {

  return $self->[5];
}

method matched() {
  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return substr "$string", $start, $end - $start;
}

method prematched() {
  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return substr "$string", 0, $start;
}

method postmatched() {
  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return substr "$string", $end;
}

method regexp() {

  return qr($self->[0]);
}

method string() {

  return $self->[1];
}

1;

=encoding utf8

=head1 NAME

Data::Object::Search

=cut

=head1 ABSTRACT

Search Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Search;

  my $search = Data::Object::Search->new([
    '(?^:(test))',
    'this is a test',
    1,
    [
      10,
      10
    ],
    [
      14,
      14
    ],
    {},
    'this is a test'
  ]);

=cut

=head1 DESCRIPTION

This package provides methods for manipulating search data.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Array>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Dumpable>

L<Data::Object::Role::Proxyable>

L<Data::Object::Role::Throwable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 captures

  captures() : ArrayRef

The captures method returns the capture groups from the result object which
contains information about the results of the regular expression operation..

=over 4

=item captures example #1

  # given: synopsis

  $search->captures; # ['test']

=back

=cut

=head2 count

  count() : Num

The count method returns the regular expression used to perform the match from
the result object which contains information about the results of the regular
expression operation..

=over 4

=item count example #1

  # given: synopsis

  $search->count; # 1

=back

=cut

=head2 initial

  initial() : Str

The initial method returns the unaltered string from the result object which
contains information about the results of the regular expression operation..

=over 4

=item initial example #1

  # given: synopsis

  $search->initial; # this is a test

=back

=cut

=head2 last_match_end

  last_match_end() : Maybe[ArrayRef[Int]]

The last_match_end method returns an array of offset positions into the string
where the capture(s) stopped matching from the result object which contains
information about the results of the regular expression operation..

=over 4

=item last_match_end example #1

  # given: synopsis

  $search->last_match_end; # [14, 14]

=back

=cut

=head2 last_match_start

  last_match_start() : Maybe[ArrayRef[Int]]

The last_match_start method returns an array of offset positions into the
string where the capture(s) matched from the result object which contains
information about the results of the regular expression operation..

=over 4

=item last_match_start example #1

  # given: synopsis

  $search->last_match_start; # [10, 10]

=back

=cut

=head2 matched

  matched() : Maybe[Str]

The matched method returns the portion of the string that matched from the
result object which contains information about the results of the regular
expression operation..

=over 4

=item matched example #1

  # given: synopsis

  $search->matched; # test

=back

=cut

=head2 named_captures

  named_captures() : HashRef

The named_captures method returns a hash containing the requested named regular
expressions and captured string pairs from the result object which contains
information about the results of the regular expression operation..

=over 4

=item named_captures example #1

  # given: synopsis

  $search->named_captures; # {}

=back

=cut

=head2 postmatched

  postmatched() : Maybe[Str]

The postmatched method returns the portion of the string after the regular
expression matched from the result object which contains information about the
results of the regular expression operation..

=over 4

=item postmatched example #1

  # given: synopsis

  $search->postmatched; # ''

=back

=cut

=head2 prematched

  prematched() : Maybe[Str]

The prematched method returns the portion of the string before the regular
expression matched from the result object which contains information about the
results of the regular expression operation..

=over 4

=item prematched example #1

  # given: synopsis

  $search->prematched; # 'this is a '

=back

=cut

=head2 regexp

  regexp() : RegexpRef

The regexp method returns the regular expression used to perform the match from
the result object which contains information about the results of the regular
expression operation..

=over 4

=item regexp example #1

  # given: synopsis

  $search->regexp; # qr/(test)/

=back

=cut

=head2 string

  string() : Str

The string method returns the string matched against the regular expression
from the result object which contains information about the results of the
regular expression operation..

=over 4

=item string example #1

  # given: synopsis

  $search->string; # this is a test

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object/wiki>

L<Project|https://github.com/iamalnewkirk/data-object>

L<Initiatives|https://github.com/iamalnewkirk/data-object/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object/issues>

=cut
