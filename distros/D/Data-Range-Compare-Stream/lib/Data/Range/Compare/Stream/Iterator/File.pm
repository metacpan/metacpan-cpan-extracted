package Data::Range::Compare::Stream::Iterator::File;

use strict;
use warnings;
use IO::File;
use Carp qw(croak);
use base qw(Data::Range::Compare::Stream::Iterator::Base);
use Data::Range::Compare::Stream;


sub NEW_FROM { $_[0]->{NEW_FROM} }

sub new {
  my ($class,%args)=@_;

  my $self=$class->SUPER::new(%args);

  $self->{pos}=0;
  my $has_next;

  if(defined($args{fh})) {
    $self->{fh}=$args{fh};
    $self->{filename}=ref($args{fh});
    my $fh=$self->{fh};

    croak 'fh=>$fh does not suppot getline' unless $fh->can('getline');

    my $line=$fh->getline;
    $self->{next_line}=$line;
    $has_next=defined($line);

  } elsif(defined($args{filename})) {
    my $fh=IO::File->new($args{filename},'r');
    if($fh) {
       $self->{fh}=$fh;
       my $line=$fh->getline;
       $self->{next_line}=$line;
       $has_next=defined($line);
       $self->{created_fh}=1;
    } else {
      $self->{msg}="Error could not open $args{filename} error was: $!";
    }

  } else {
    $self->{msg}="filename=>undef";
  }

  $self->{has_next}=$has_next;
  return $self;
}

sub get_size {
  my ($self)=@_;
  return $self->{size} if defined($self->{size});

  my $fh=$self->get_fh;
  my $pos=tell($fh);
  seek($fh,0,0);
  my $size=0;
  while($fh->getline) {
    ++$size;
  }
  $self->{size}=$size;
  seek($fh,$pos,0);
  $size;
}

sub get_pos { $_[0]->{pos} }

sub in_error {
  my ($self)=@_;
  return 1 if defined($self->{msg});
  return 0;
}

sub get_error { $_[0]->{msg} }

sub to_string {
  my ($self)=@_;
  return $self->{filename};
}

sub get_next {
  my ($self)=@_;
  return undef unless $self->has_next;
  ++$self->{pos};

  my $line=$self->{next_line};
  $self->{next_line}=$self->{fh}->getline;
  $self->{has_next}=defined($self->{next_line});

  return $self->create_from_factory(@{$self->parse_line($line)});
}

sub get_fh { $_[0]->{fh} }

sub created_fh { $_[0]->{created_fh} }

sub DESTROY {
  my ($self)=@_;
  return unless defined($self);
  return unless defined($self->{fh});
  return unless $self->{created_fh};
  $self->{fh}->close;
  $self->{fh}=undef;
}

1;
