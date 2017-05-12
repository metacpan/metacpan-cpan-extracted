#!/usr/bin/perl


use strict;
use warnings;
use lib qw(../lib);

my $iterator=new MyIterator(filename=>'file_example.src');
while($iterator->has_next) {
  print $iterator->get_next,"\n";
}

package MyIterator;
use strict;
use warnings;
use IO::File;
use IO::Select;
use base qw(Data::Range::Compare::Stream::Iterator::Base);
use Data::Range::Compare::Stream::Iterator::Consolidate::Result;
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
  my $range=new Data::Range::Compare::Stream(split /\s+/,$line);
  return new Data::Range::Compare::Stream::Iterator::Consolidate::Result($range,$range,$range);
}



1;
