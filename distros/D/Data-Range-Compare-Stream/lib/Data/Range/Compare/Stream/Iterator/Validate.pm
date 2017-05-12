package Data::Range::Compare::Stream::Iterator::Validate;

use strict;
use warnings;
use Carp qw(croak);

use base qw(Data::Range::Compare::Stream::Iterator::Base);

sub new {
  my ($class,$it,%args)=@_;

  croak 'Iterator is a required argument' unless defined($it);
  my $self=$class->SUPER::new(iterator=>$it,%args);

  $self;
}

sub prepare {
  my ($self)=@_;
  return 1 if defined($self->{next_valid_range});

  my $it=$self->{iterator};
  while($it->has_next) {
    my $next=$it->get_next;
    if($next->get_common->boolean) {
      $self->{next_valid_range}=$next;
      return 1;
    }
    $self->on_bad_range($next)
  }

  0;
}

sub on_bad_range {
  my ($self,$range)=@_;
  $self->{on_bad_range}->($range) if defined($self->{on_bad_range});
}

sub has_next {
  my ($self)=@_;
  $self->prepare;
}

sub get_next {
  my ($self)=@_;
  my $range=$self->{next_valid_range};
  $self->{next_valid_range}=undef;
  return $range;
}

1;
