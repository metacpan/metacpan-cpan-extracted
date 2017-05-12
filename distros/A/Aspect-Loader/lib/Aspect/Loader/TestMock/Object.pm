package Aspect::Loader::TestMock::Object;
use strict;
use warnings;

sub new{
  my $class = shift;
  return bless {},$class;

}

sub hoge{return "hoge";}

1;
