package Data::Range::Compare::Stream::CallBack;

use strict;
use warnings;
use base qw(Data::Range::Compare::Stream Exporter);

use constant NEW_FROM_CLASS=>'Data::Range::Compare::Stream::CallBack';

use constant HELPER=>0;
use constant RANGE_START =>1;
use constant RANGE_END   =>2;
use constant RANGE_DATA  =>3;

use overload 
   '""'=>\&to_string,
   bool=>\&boolean,
   fallback=>1;

# global happy helper
our %HELPER=(
  sub_one=>sub { $_[0] - 1 },
  add_one=>sub { $_[0] + 1 },
  cmp_values=>sub { $_[0] <=> $_[1] },
);

our @EXPORT_OK=qw(%HELPER);

sub to_string { $_[0]->SUPER::to_string }

sub get_helper { $_[0]->[$_[0]->HELPER] }

sub boolean { $_[0]->SUPER::boolean }

sub new {
  my ($class,@args)=@_;
  return bless [@args],$class;
}

sub factory {
  my ($self,@args)=@_;
  my $new=$self->NEW_FROM_CLASS->new($self->get_helper,@args);
  return $new;
}

sub sub_one {
  my ($self,$value)=@_;
  return $self->get_helper->{sub_one}->($value);
}

sub add_one {
  my ($self,$value)=@_;
  return $self->get_helper->{add_one}->($value);
}

sub cmp_values {
  my ($self,$value_a,$value_b)=@_;
  return $self->get_helper->{cmp_values}->($value_a,$value_b);
}

1;
