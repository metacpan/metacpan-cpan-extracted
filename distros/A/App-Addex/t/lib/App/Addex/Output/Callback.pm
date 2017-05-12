#!perl
use strict;
use warnings;

package App::Addex::Output::Callback;
use App::Addex::Output;
BEGIN { our @ISA = 'App::Addex::Output' }

sub new {
  my ($self, $arg) = @_;

  bless $arg->{callback} => $self;
}

sub process_entry { $_[0]->(@_); } 

1;
