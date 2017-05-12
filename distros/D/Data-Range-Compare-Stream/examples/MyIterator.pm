package # Hidden from pause
  MyIterator;

use strict;
use warnings;
use IO::File;
use base qw(Data::Range::Compare::Stream::Iterator::Base);
use Data::Range::Compare::Stream;


sub new {
  my ($class,%args)=@_;
  my $has_next;
  my $self=$class->SUPER::new(%args);

  if(defined($args{filename})) {
    my $fh=IO::File->new($args{filename});
    if($fh) {
       $self->{fh}=$fh;
       my $line=$fh->getline;
       $self->{next_line}=$line;
       $has_next=defined($line);
    } else {
      $self->{msg}="Error could not open $args{filename} error was: $!";
    }

  }

  $self->{has_next}=$has_next;
  return $self;
}

sub get_next {
  my ($self)=@_;
  return undef unless $self->has_next;

  my $line=$self->{next_line};
  $self->{next_line}=$self->{fh}->getline;
  $self->{has_next}=defined($self->{next_line});

  chomp $line;
  return new Data::Range::Compare::Stream(split /\s+/,$line);
}



1;

