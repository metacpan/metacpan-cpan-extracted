package Data::Object::Data;

use Data::Object::Class;

use parent 'Data::Object::Kind';

# BUILD

sub BUILD {
  my ($self, $data) = @_;

  my @attrs = qw(data file from);

  for my $attr (grep { defined $data->{$_} } @attrs) {
    $self->{$attr} = $data->{$attr};
  }

  unless (%$data) {
    $data->{from} = 'main';
  }

  if ($data->{file} && !$data->{data}) {
    $self->from_file($data->{file});
  }

  if ($data->{from} && !$data->{data}) {
    $self->from_data($data->{from});
  }

  return $self;
}

sub from_file {
  my ($self, $file) = @_;

  my $data = $self->file($file);

  $self->{file} = $file;
  $self->{data} = $self->parser(join("\n", @$data)) if @$data;

  return $self;
}

sub from_data {
  my ($self, $class) = @_;

  my $data = $self->data($class) or return;

  $self->{from} = $class;
  $self->{data} = $self->parser(join("\n", @$data)) if @$data;

  return $self;
}

# METHODS

sub file {
  my ($self, $file) = @_;

  open(my $handle, "<:encoding(UTF-8)", $file) or die "Error with $file: $!";

  my $data = [(<$handle>)];

  return $data;
}

sub data {
  my ($self, $class) = @_;

  my $handle = do { no strict 'refs'; \*{"${class}::DATA"} };

  fileno $handle or die "Error with $class: DATA not accessible";

  seek $handle, 0, 0;

  my $data = [(<$handle>)];

  return $data;
}

sub item {
  my ($self, $name) = @_;

  for my $item (@{$self->{data}}) {
    return $item if $item->{name} eq $name;
  }

  return;
}

sub list {
  my ($self, $name) = @_;

  return if !$name;

  my @list;

  for my $item (@{$self->{data}}) {
    push @list, $item if $item->{list} && $item->{list} eq $name;
  }

  return [sort { $a->{index} <=> $b->{index} } @list];
}

sub pluck {
  my ($self, $type, $name) = @_;

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

sub content {
  my ($self, $name) = @_;

  my $item = $self->item($name) or return;
  my $data = $item->{data};

  return $data;
}

sub contents {
  my ($self, $name) = @_;

  my $items = $self->list($name) or return;
  my $data = [map { $_->{data} } @$items];

  return $data;
}

sub parser {
  my ($self, $data) = @_;

  my @chunks = split /^=\s*(.+?)\s*\r?\n/m, $data;

  shift @chunks;

  my $items = [];

  while (my ($meta, $data) = splice @chunks, 0, 2) {
    next unless $meta && $data;
    next unless $meta ne 'cut';

    my @info = split /\s/, $meta, 2;

    my ($list, $name) = @info == 2 ? @info : (undef, @info);

    $data = [split /\n\n/, $data];

    my $item = { name => $name, data => $data, index => @$items + 1, list => $list };

    push @$items, $item;
  }

  return $items;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Data

=cut

=head1 ABSTRACT

Data-Object Data Class

=cut

=head1 SYNOPSIS

  package Command;

  use Data::Object::Data;

  =help

  fetches results from the api

  =cut

  my $data = Data::Object::Data->new;

  my $help = $data->content('help');
  # fetches results ...

  my $token = $data->content('token');
  # token: the access token ...

  my $secret = $data->content('secret');
  # secret: the secret for ...

  my $flag = $data->contents('flag');
  # [,...]

  __DATA__

  =flag secret

  secret: the secret for the account

  =flag token

  token: the access token for the account

  =cut

=cut

=head1 DESCRIPTION

Data::Object::Data provides methods for parsing and extracting pod-like data
sections from any file or package. The pod-like syntax allows for using these
sections anywhere in the source code and Perl properly ignoring them.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 from_file

  # given $data

  $data->from_file($file);

  # ...

The from_data method returns content for the given file to be passed to the
constructor.

=cut

=head2 from_data

  # given $data

  $data->from_data($class);

  # ...

The from_data method returns content for the given class to be passed to the
constructor.

=cut

=head2 file

  # given $data

  $data->file($args);

  # ...

The file method returns the contents of a file which contains pod-like sections
for a given filename.

=cut

=head2 data

  # given $data

  $data->data($class);

  # ...

The data method returns the contents from the C<DATA> and C<END> sections of a
package.

=cut

=head2 item

  =pod help

  Example content

  =cut

  # given $data

  $data->item('help');

  # {,...}

The item method returns metadata for the pod-like section that matches the
given string.

=cut

=head2 list

  =pod help

  Example content

  =cut

  # given $data

  $data->list('pod');

  # [,...]

The list method returns metadata for each pod-like section that matches the
given string.

=cut

=head2 pluck

  =pod help

  Example content

  =cut

  # given $data

  $data->pluck('item', 'help');

  # {,...}

The pluck method splices and returns metadata for the pod-like section that
matches the given list or item by name.

=cut

=head2 content

  =pod help

  Example content

  =cut

  # given $data

  $data->content('help');

  # Example content

The content method returns the pod-like section where the name matches the
given string.

=cut

=head2 contents

  =pod help

  Example content

  =cut

  # given $data

  $data->contents('pod');

  # [,...]

The contents method returns all pod-like sections that start with the given
string, e.g. C<pod> matches C<=pod foo>. This method returns an arrayref of
data for the matched sections.

=cut

=head2 parser

  # given $data

  $data->parser($string);

  # [,...]

The parser method extracts pod-like sections from a given string and returns an
arrayref of metadata.

=cut
