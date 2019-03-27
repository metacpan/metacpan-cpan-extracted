package Data::Object::Func::Regexp::Search;

use Data::Object 'Class';

use Data::Object::Search;

extends 'Data::Object::Func::Regexp';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $string, $flags) = $self->unpack;

  my $captures;
  my @matches;

  my $result = "$data";
  my $op     = '$string =~ m/$result/';
  my $capt   = '$captures = (' . $op . ($flags // '') . ')';
  my $mtch   = '@matches  = ([@-], [@+], {%-})';
  my $expr   = join ';', $capt, $mtch;

  my $error = do { local $@; eval $expr; $@ };

  throw($error) if $error;

  return Data::Object::Search->new([
    $result,
    $string,
    $captures,
    @matches,
    $string
  ]);
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Regexp::Search

=cut

=head1 ABSTRACT

Data-Object Regexp Function (Search) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Regexp::Search;

  my $func = Data::Object::Func::Regexp::Search->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Regexp::Search is a function object for Data::Object::Regexp.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Regexp->new(qr/test/);

  my $func = Data::Object::Func::Regexp::Search->new(
    arg1 => $data,
    arg2 => 'test case'
  );

  my $result = $func->execute;

=back

=cut

=head2 mapping

  mapping() : (Str)

Returns the ordered list of named function object arguments.

=over 4

=item mapping example

  my @data = $self->mapping;

=back

=cut
