package Data::Range::Compare::Stream::Iterator::File::MergeSortAsc;

# based on http://en.wikipedia.org/wiki/Merge_sort

use strict;
use warnings;
use Carp qw(croak);
use IO::File;

use Data::Range::Compare::Stream::Sort;
use Data::Range::Compare::Stream::Iterator::Stack;
use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream::Iterator::File::MergeSortAsc::Stack;
use Data::Range::Compare::Stream::Iterator::File;


use base qw(Data::Range::Compare::Stream::Iterator::Base Data::Range::Compare::Stream::Iterator::File::Temp);


sub new {
  my ($class,%args)=@_;
  my $self=$class->SUPER::new(
      bucket_size=>4000,
      NEW_ITERATOR_FROM=>'Data::Range::Compare::Stream::Iterator::File',
      NEW_ARRAY_ITERATOR_FROM=>'Data::Range::Compare::Stream::Iterator::Array',
      NEW_FROM=>'Data::Range::Compare::Stream',
      file_list=>[],
      iterator_list=>[],
      auto_prepare=>0,
      unlink_result_file=>1,
      prepared=>0,
      %args
  );

  if($self->{bucket_size} < 1) {
    croak 'bucket_size < 1';;
  }

  my $it_list=$self->{iterator_list};
  if($args{filename}) {
    push @{$self->{file_list}},$args{filename};
  }
  foreach my $filename (@{$self->{file_list}}) {
     my $it=$self->create_file_iterator(filename=>$filename);
     croak "Could not open: [$filename]" if $it->in_error;
     push @$it_list,$it;
  }
  $self->prepare if $self->{auto_prepare};
  
  return $self;
}

sub NEW_FROM { $_[0]->{NEW_FROM} }

sub NEW_ARRAY_ITERATOR_FROM { $_[0]->{NEW_ARRAY_ITERATOR_FROM} }

sub NEW_ITERATOR_FROM { $_[0]->{NEW_ITERATOR_FROM} }

sub create_file_iterator {
  my ($self,%args)=@_;

  my $obj=$self->NEW_ITERATOR_FROM->new(
    NEW_FROM=>$self->NEW_FROM,
    parse_line=>$self->{parse_line},
    result_to_line=>$self->{result_to_line},
    factory_instance=>$self->{factory_instance},
    %args
  );

  return $obj;
}

sub prepare {
  my ($self)=@_;
  return if $self->{prepared};
  $self->{prepared}=1;

  my $it_list=$self->{iterator_list};
  
  $self->create_stack($it_list);
  my $result_file=$self->walk_stack;
  $self->{result_file}=$result_file;
  $self->{stack}=undef;
  $self->{iterator}=$self->create_file_iterator(filename=>$result_file);
}

sub get_result_file { $_[0]->prepare;$_[0]->{result_file} }

sub DESTROY {
  my ($self)=@_;
  return unless defined($self);

  if(defined($self->{result_file})) {
    $self->{iterator}=undef;
    unlink $self->{result_file} if $self->{unlink_result_file};
  }

  if(defined($self->{stack})) {
    my $stack=$self->{stack};
    while($stack->has_next) {
      unlink $stack->get_next;
    }
    $self->{stack}=undef;
  }
}

sub has_next { $_[0]->prepare;$_[0]->{iterator}->has_next }
sub get_next { return undef unless defined($_[0]->{iterator});$_[0]->{iterator}->get_next }


sub walk_stack {
  my ($self)=@_;

  my $stack=$self->{stack};
  while($stack->has_next==2) {
    my $left=$stack->get_next;
    my $right=$stack->get_next;
    my $left_fh=IO::File->new($left,'r');
    my $right_fh=IO::File->new($right,'r');
    my $it_left=$self->create_file_iterator(fh=>$left_fh);
    my $it_right=$self->create_file_iterator(fh=>$right_fh);

    $stack->push($self->merge($it_left,$it_right));

    $right_fh->close;
    $left_fh->close;
    unlink $right,$left;

  }
  my $next=$stack->get_next;
  $next;
}

sub create_stack {
  my ($self,$list)=@_;

  my $merged=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc::Stack(tmpdir=>$self->{tmpdir});
  $self->{stack}=$merged;

  my $stack=new Data::Range::Compare::Stream::Iterator::Stack(stack=>$list);

  my $load_count=$self->{bucket_size};

  my $left=[];
  my $right=[];

  while($stack->has_next) {
    my $result=$stack->get_next;

    if($#$left < $load_count) {
      push @$left,$result;
    } else {
      if($#$right < $load_count) {
        push @$right,$result;
      } else {
        @$left=sort { $self->sort_method($a,$b) } @$left;
        @$right=sort { $self->sort_method($a,$b) } @$right;

	my $it_left=$self->NEW_ARRAY_ITERATOR_FROM->new(factory_instance=>$self->{factory_instance},sorted=>1,range_list=>$left);
	my $it_right=$self->NEW_ARRAY_ITERATOR_FROM->new(factory_instance=>$self->{factory_instance},sorted=>1,range_list=>$right);

	$merged->push($self->merge($it_left,$it_right));
	@$right=();
	@$left=($result);
        
      }
    }


  }

  foreach my $array ($left,$right) {

    next if $#$array==-1;

    @$array=sort { $self->sort_method($a,$b) } @$array;

    my $it=$self->NEW_ARRAY_ITERATOR_FROM->new(factory_instance=>$self->{factory_instance},sorted=>1,range_list=>$array);
    my $tmp=$self->get_temp;

    while($it->has_next) {
      my $result=$it->get_next;
      $tmp->print($self->result_to_line($result));
    }

    $merged->push($tmp->filename);
    $tmp->close;

  }

}

sub sort_method {
  my ($self,$left_range,$right_range)=@_;
  
  return $self->{sort_func}->($left_range,$right_range) if $self->{sort_func};
  my $cmp=sort_in_consolidate_order_asc($left_range->get_common,$right_range->get_common);

  return $cmp;
}

sub merge {
  my ($self,$left,$right)=@_;

  my $tmp_result=$self->get_temp;
  
  my ($left_range,$right_range);
  
  if($left->has_next) {
    $left_range=$left->get_next;
  }

  if($right->has_next) {
    $right_range=$right->get_next;
  }


  while(defined($left_range) or defined($right_range)) {

    if(defined($left_range) and defined($right_range)) {
      
      my $cmp=$self->sort_method($left_range,$right_range);

      if($cmp!=1) {

        $tmp_result->print($self->result_to_line($left_range));
	$left_range=undef;
	if($left->has_next) {
	  $left_range=$left->get_next;
	}
      } else {

        $tmp_result->print($self->result_to_line($right_range));
	$right_range=undef;
	if($right->has_next) {
	  $right_range=$right->get_next;
	}

      }

    } elsif(defined($left_range)) {

        $tmp_result->print($self->result_to_line($left_range));
	$left_range=undef;
	if($left->has_next) {
	  $left_range=$left->get_next;
	}

    } elsif(defined($right_range)) {

        $tmp_result->print($self->result_to_line($right_range));
	$right_range=undef;
	if($right->has_next) {
	  $right_range=$right->get_next;
	}

    }
  }

  my $result_name=$tmp_result->filename;
  $tmp_result->close;


  return $result_name;
}

1;
