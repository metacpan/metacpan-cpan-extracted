package Data::Range::Compare::Stream::Iterator::Base;

use strict;
use warnings;
use overload '""'=>\&to_string,fallback=>1;

use constant NEW_FROM_CLASS=>'Data::Range::Compare::Stream';

sub NEW_FROM { $_[0]->{NEW_FROM} }

sub new { 
  my ($class,%args)=@_;
  my $self=bless {NEW_FROM=>$class->NEW_FROM_CLASS,%args},$class;

  unless(exists $self->{factory_instance}) {
    $self->{factory_instance}= exists $self->{new_from} ? $self->{new_from} : $self->NEW_FROM;
  }

  return $self;
}

sub create_from_factory {
  my ($self,@args)=@_;
  
  my $range=$self->{factory_instance}->factory(@args);

  return $range;
}

sub on_consolidate { }

sub has_next { $_[0]->{has_next} }

sub get_next { undef }

sub to_string { ref($_[0]) }

sub delete_from_root { }

sub get_child_column_id { undef }

sub get_child { undef }

sub set_column_id { $_[0]->{column_id}=$_[1] }

sub get_column_id { $_[0]->{column_id} }

sub get_root_column_id {$_[0]->get_column_id }

sub get_root { $_[0] }

sub is_child { 0 }
sub has_child { 0 }
sub is_root { 1 }
sub has_root {0}

sub result_to_line {
  my ($self,$result)=@_;
  return $self->{result_to_line}->($result) if defined($self->{result_to_line});

  my $range=$result->get_common;
  my $line=$range->range_start_to_string.' '.$range->range_end_to_string."\n";
  return $line;
}

sub parse_line {
  my ($self,$line)=@_;
  return $self->{parse_line}->($line) if defined($self->{parse_line});
  chomp $line;
  [split /\s+/,$line];
}


1;

