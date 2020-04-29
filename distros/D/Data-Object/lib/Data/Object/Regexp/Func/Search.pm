package Data::Object::Regexp::Func::Search;

use 5.014;

use strict;
use warnings;

use registry 'Data::Object::Types';

use Data::Object::Class;
use Data::Object::ClassHas;

use Data::Object::Search;

extends 'Data::Object::Regexp::Func';

our $VERSION = '2.05'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'RegexpLike',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'StringLike',
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
