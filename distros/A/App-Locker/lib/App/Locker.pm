package App::Locker;

use strict;
use Storable;
use Convert::Base64;
use IO::Handle;

=head1 NAME

App::Locker - lock/unlock you perl script

=head1 SYNOPSIS

use App::Locker;

my $locker=App::Locker->create;

my $pid=fork();

if (!$pid){

  # child
  sleep(1);
  $locker->unlock;
  sleep(1);

} else {
  # parent
          
  print "LOCK\n";
  $locker->lock();
  print "UNLOCK\n";
}

=head1 DESCRIPTION

This module provides create lock point in any place scipt and unlock it from another script place (main, fork, thread).

=cut

$Storable::Deparse = 1;

=head2 create
my $locker=App::Locker->create;

create main object thith lock api
=cut

sub create{
  my ($class, %params)=@_;
  
  my ($reader, $writer);
  pipe($reader, $writer);
  $writer->autoflush(1);

  my $self={
    reader=>$reader,
    writer=>$writer
  };
  
  bless($self, $class);
  
  return $self;  
}

=head2 destroy
$locker->destroy

destroy main object
=cut
sub destroy{
  my ($self)=@_;
  my $reader=$self->{reader};
  my $writer=$self->{writer};
  
  close $reader;
  close $writer;
  
  delete $self->{reader};
  delete $self->{writer};
}


sub dpack{
  my ($data)=@_;
  
  my $ret;
  if ($data){
    $ret=encode_base64(Storable::freeze($data));
    $ret=~s/[\r\n]//gs;
  }
  
  return $ret;
}

sub dunpack{
  my ($data)=@_;
  $data=~s/[\r\n]//gs;
  my $ret=Storable::thaw(decode_base64($data)) if $data;
  
  return $ret;
}

=head2 lock
$locker->lock # for simple lock
OR
my $data = $locker->lock # lock thith transfer any data

lock execute script
=cut
sub lock{
  my ($self)=@_;
  
  my $reader=$self->{reader};
  my $ret=<$reader>;

  my $data=dunpack($ret);
    
  return $data;
}

=head2 unlock
$locker->unlock # for simple unlock
OR

$locker->unlock($data) # unlock thith transfer any data ($data - must by reference)

lock execute script
=cut
sub unlock{
  my ($self, $data)=@_;

  if (!ref($data) && $data){
    print "Error: Sended data may be reference not simple SCALAR\n";
  }
  my $writer=$self->{writer};
  
  my $send=dpack($data);
  if ($send){
    print $writer "$send\n";
  } else {
    print $writer "\n";
  }
}



=head1 AUTHOR

Bulichev Evgeniy, F<bes@cpan.org>>.

=head1 COPYRIGHT

  Copyright (c) 2017 Bulichev Evgeniy.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut

1;
