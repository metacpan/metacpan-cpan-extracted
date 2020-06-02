package Data::Object::Data;

use 5.014;

use strict;
use warnings;
use routines;

use Moo;

require Carp;

our $VERSION = '2.03'; # VERSION

# BUILD

has data => (
  is => 'ro',
  builder => 'new_data',
  lazy => 1
);

fun new_data($self) {
  my $file = $self->file;
  my $data = $self->parser($self->lines);

  return $data;
}

has file => (
  is => 'ro',
  builder => 'new_file',
  lazy => 1
);

fun new_file($self) {
  my $from = $self->from or return;
  my $path = $from =~ s/::/\//gr;

  return $INC{"$path.pm"};
}

has from => (
  is => 'ro',
  lazy => 1
);

has string => (
  is => 'ro',
  lazy => 1
);

fun BUILD($self, $args) {
  $self->file;
  $self->data;

  return $self;
}

# METHODS

method content($name) {
  my $item = $self->item($name) or return;
  my $data = $item->{data};

  return $data;
}

method contents($name, $seek) {
  my $items = $self->list($name) or return;
  @$items = grep { $_->{name} eq $seek } @$items if $seek;
  my $data = [map { $_->{data} } @$items];

  return $data;
}

method item($name) {
  for my $item (@{$self->{data}}) {
    return $item if !$item->{list} && $item->{name} eq $name;
  }

  return;
}

method lines() {
  my $file = $self->file;

  return $self->string || '' if !$file || !-f $file;

  open my $fh, '<', $file or Carp::confess "$!: $file";
  my $lines = join "\n", <$fh>;
  close $fh;

  return $lines;
}

method list($name) {
  return if !$name;

  my @list;

  for my $item (@{$self->{data}}) {
    push @list, $item if $item->{list} && $item->{list} eq $name;
  }

  return [sort { $a->{index} <=> $b->{index} } @list];
}

method list_item($list, $name) {
  my $items = $self->list($list) or return;
  my $data = [grep { $_->{name} eq $name } @$items];

  return $data;
}

method parser($data) {
  $data =~ s/\n*$/\n/;

  my @chunks = split /^(?:@=|=)\s*(.+?)\s*\r?\n/m, $data;

  shift @chunks;

  my $items = [];

  while (my ($meta, $data) = splice @chunks, 0, 2) {
    next unless $meta && $data;
    next unless $meta ne 'cut';

    my @info = split /\s/, $meta, 2;
    my ($list, $name) = @info == 2 ? @info : (undef, @info);

    $data =~ s/\n\+=/\n=/g; # auto-escape nested pod syntax
    $data = [split /\n\n/, $data];

    my $item = { name => $name, data => $data, index => @$items + 1, list => $list };

    push @$items, $item;
  }

  return $items;
}

method pluck($type, $name) {
  return if !$name;
  return if !$type || ($type ne 'item' && $type ne 'list');

  my (@list, @copy);

  for my $item (@{$self->{data}}) {
    my $matched = 0;

    $matched = 1 if $type eq 'list' && $item->{list} && $item->{list} eq $name;
    $matched = 1 if $type eq 'item' && $item->{name} && $item->{name} eq $name;

    push @list, $item if $matched;
    push @copy, $item if !$matched;
  }

  $self->{data} = [sort { $a->{index} <=> $b->{index} } @copy];

  return $type eq 'name' ? $list[0] : [@list];
}

1;

=encoding utf8

=head1 NAME

Data::Object::Data

=cut

=head1 ABSTRACT

Podish Parser for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Data;

  my $data = Data::Object::Data->new(
    file => 't/Data_Object_Data.t'
  );

=cut

=head1 DESCRIPTION

This package provides methods for parsing and extracting pod-like sections from
any file or package. The pod-like syntax allows for using these sections
anywhere in the source code and having Perl properly ignoring them.

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 syntax

  # POD

  # =head1 NAME
  #
  # Example #1
  #
  # =cut
  #
  # =head1 NAME
  #
  # Example #2
  #
  # =cut

  # Podish Syntax

  # =name
  #
  # Example #1
  #
  # =cut
  #
  # =name
  #
  # Example #2
  #
  # =cut

  # Podish Syntax (Nested)

  # =name
  #
  # Example #1
  #
  # +=head1 WHY?
  #
  # blah blah blah
  #
  # +=cut
  #
  # More information on the same topic as was previously mentioned in the
  # previous section demonstrating the topic as-is obvious from said section
  # ...
  #
  # =cut

  # Alternate Podish Syntax

  # @=name
  #
  # Example #1
  #
  # @=cut
  #
  # @=name
  #
  # Example #2
  #
  # @=cut

  my $data = Data::Object::Data->new(
    file => 't/examples/alternate.pod'
  );

  $data->contents('name');

  # [['Example #1'], ['Example #2']]

This package supports parsing standard POD and pod-like sections from any file
or package, anywhere in the document. Additionally, this package supports an
alternative POD definition syntax which helps differentiate between the
traditional POD usage and other usages.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 data

  data(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 file

  file(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 from

  from(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 content

  content(Str $name) : ArrayRef[Str]

The content method the pod-like section where the name matches the given
string.

=over 4

=item content example #1

  # =name
  #
  # Example #1
  #
  # =cut
  #
  # =name
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/content.pod'
  );

  $data->content('name');

  # ['Example #1']

=back

=over 4

=item content example #2

  # =name
  #
  # Example #1
  #
  # +=head1 WHY?
  #
  # blah blah blah
  #
  # +=cut
  #
  # More information on the same topic as was previously mentioned in the
  # previous section demonstrating the topic as-is obvious from said section
  # ...
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/nested.pod'
  );

  $data->content('name');

  # ['Example #1', '', '=head1 WHY?', ...]

=back

=cut

=head2 contents

  contents(Str $list, Str $name) : ArrayRef[ArrayRef]

The contents method returns all pod-like sections that start with the given
string, e.g. C<pod> matches C<=pod foo>. This method returns an arrayref of
data for the matched sections. Optionally, you can filter the results by name
by providing an additional argument.

=over 4

=item contents example #1

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->contents('name');

 # [['Example #1'], ['Example #2']]

=back

=over 4

=item contents example #2

  # =name example-1
  #
  # Example #1
  #
  # +=head1 WHY?
  #
  # blah blah blah
  #
  # +=cut
  #
  # ...
  #
  # =cut

  my $data = Data::Object::Data->new(
    string => join "\n\n", (
      '=name example-1',
      '',
      'Example #1',
      '',
      '+=head1 WHY?',
      '',
      'blah blah blah',
      '',
      '+=cut',
      '',
      'More information on the same topic as was previously mentioned in the',
      '',
      'previous section demonstrating the topic as-is obvious from said section',
      '',
      '...',
      '',
      '=cut'
    )
  );

  $data->contents('name');

  # [['Example #1', '', '=head1 WHY?', ...]]

=back

=cut

=head2 item

  item(Str $name) : HashRef

The item method returns metadata for the pod-like section that matches the
given string.

=over 4

=item item example #1

  # =name
  #
  # Example #1
  #
  # =cut
  #
  # =name
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/content.pod'
  );

  $data->item('name');

  # {
  #   index => 1,
  #   data => ['Example #1'],
  #   list => undef,
  #   name => 'name'
  # }

=back

=cut

=head2 list

  list(Str $name) : ArrayRef

The list method returns metadata for each pod-like section that matches the
given string.

=over 4

=item list example #1

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->list('name');

  # [{
  #   index => 1,
  #   data => ['Example #1'],
  #   list => 'name',
  #   name => 'example-1'
  # },
  # {
  #   index => 2,
  #   data => ['Example #2'],
  #   list => 'name',
  #   name => 'example-2'
  # }]

=back

=cut

=head2 list_item

  list_item(Str $list, Str $item) : ArrayRef[HashRef]

The list_item method returns metadata for the pod-like sections that matches
the given list name and argument.

=over 4

=item list_item example #1

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->list_item('name', 'example-2');

  # [{
  #   index => 2,
  #   data => ['Example #2'],
  #   list => 'name',
  #   name => 'example-2'
  # }]

=back

=cut

=head2 parser

  parser(Str $string) : ArrayRef

The parser method extracts pod-like sections from a given string and returns an
arrayref of metadata.

=over 4

=item parser example #1

  # given: synopsis

  $data->parser("=pod\n\nContent\n\n=cut");

  # [{
  #   index => 1,
  #   data => ['Content'],
  #   list => undef,
  #   name => 'pod'
  # }]

=back

=cut

=head2 pluck

  pluck(Str $type, Str $item) : ArrayRef[HashRef]

The pluck method splices and returns metadata for the pod-like section that
matches the given list or item by name. Splicing means that the parsed dataset
will be reduced each time this method returns data, making this useful with
iterators and reducers.

=over 4

=item pluck example #1

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->pluck('list', 'name');

  # [{
  #   index => 1,
  #   data => ['Example #1'],
  #   list => 'name',
  #   name => 'example-1'
  # },{
  #   index => 2,
  #   data => ['Example #2'],
  #   list => 'name',
  #   name => 'example-2'
  # }]

=back

=over 4

=item pluck example #2

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->pluck('item', 'example-1');

  # [{
  #   index => 1,
  #   data => ['Example #1'],
  #   list => 'name',
  #   name => 'example-1'
  # }]

  $data->pluck('item', 'example-2');

  # [{
  #   index => 2,
  #   data => ['Example #2'],
  #   list => 'name',
  #   name => 'example-2'
  # }]

=back

=over 4

=item pluck example #3

  # =name example-1
  #
  # Example #1
  #
  # =cut
  #
  # =name example-2
  #
  # Example #2
  #
  # =cut

  my $data = Data::Object::Data->new(
    file => 't/examples/contents.pod'
  );

  $data->pluck('list', 'name');

  # [{
  #   index => 1,
  #   data => ['Example #1'],
  #   list => 'name',
  #   name => 'example-1'
  # },{
  #   index => 2,
  #   data => ['Example #2'],
  #   list => 'name',
  #   name => 'example-2'
  # }]

  $data->pluck('list', 'name');

  # []

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-data/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-data/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-data>

L<Initiatives|https://github.com/iamalnewkirk/data-object-data/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-data/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-data/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-data/issues>

=cut
