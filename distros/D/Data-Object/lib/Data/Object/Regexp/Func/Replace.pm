package Data::Object::Regexp::Func::Replace;

use 5.014;

use strict;
use warnings;

use registry 'Data::Object::Types';

use Data::Object::Class;
use Data::Object::ClassHas;

use Data::Object::Replace;

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

has arg3 => (
  is => 'ro',
  isa => 'StringLike',
  opt => 1
);

has arg4 => (
  is => 'ro',
  isa => 'StringLike',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $string, $replacement, $flags) = $self->unpack;

  my $captures;
  my @matches;

  my $result = "$data";
  my $op     = '$string =~ s/$result/$replacement/';
  my $capt   = '$captures = (' . $op . ($flags // '') . ')';
  my $mtch   = '@matches  = ([@-], [@+], {%-})';
  my $expr   = join ';', $capt, $mtch;

  my $initial = $string;

  my $error = do { local $@; eval $expr; $@ };

  throw($error) if $error;

  return Data::Object::Replace->new([
    $result,
    $string,
    $captures,
    @matches,
    $initial
  ]);
}

sub mapping {
  return ('arg1', 'arg2', 'arg3', 'arg4');
}

1;
