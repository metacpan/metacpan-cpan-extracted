package Data::Queue;

=head1 NAME

Data::Queue - Order/Unordered stack

=head1 SYNOPSIS

  use Data::Queue;

  my $stack=new Data::Queue;

  my $id=$stack->add($job);

  while($stack->has_next) {
    my ($id,$job)=$stack->get_next;
  }

=head1 DESCRIPTION

Stack, with the ablity to add and remove elements by id on the fly. Elements go in and out of the stack in the id order.

=cut

use Modern::Perl;
use Moo;
use Data::Result;
use namespace::clean;
our $VERSION='1.0001';

with 'Data::Result::Moo';

sub BUILD {
  my ($self,$args)=@_;
  my $data={};
  $self->{id}=0;
  $self->{data}={};
  $self->{stack}=[];
};

=head1 OO Methods

=over 4

=item * my @ids=$stack->add(@list)

Adds a list of objects onto the stack

Arguments:

  @ids:  List of ids relative to @list
  @list: List of elements to put on the stack

=cut

sub add {
  my ($self,@list)=@_;

  my @result;
  my $list=$self->{list};
  foreach my $obj (@list) {
    $self->{id}++;
    my $set=[$self->{id},$obj];

    $self->{data}->{$self->{id}}=$set;
    push @{$self->{stack}},$self->{id};
    push @result,$self->{id};
  }

  @result;
}

=item * my ($id,$value)=$stack->get_next

Returns the next id=>value pair from the set.

=cut

sub get_next {
  my ($self)=@_;
  my $id=shift @{$self->{stack}};
  my $set=delete $self->{data}->{$id};

  return wantarray ? @{$set} : $set->[1];
}

=item * if($stack->has_next) { ... }

Returns a Data::Result object, when true, it is safe to call $stack->get_next

=cut

sub has_next {
  my ($self)=@_;
  return $#{$self->{stack}}==-1 ?
    $self->new_false("No elements left on the stack!") :
    $self->new_true("yes we have more");
}

=item * if($self->has_id($id)) { ... }

Returns a Data::Result object:

  When true:  it contains the object from the stack
  When false: it contains an error message

=cut

sub has_id {
  my ($self,$id)=@_;

  my $result=$self->new_false('Object Not on stack');
  if(exists $self->{data}->{$id}) {
    $result=$self->new_true($self->{data}->{$id}->[1]);
  }
  return $result;
}

=item * my $id=$stack->add_by_id($id=>$obj);

Adds the element pair to the stack, with a given id, if the id existed the old element is removed.

=cut

sub add_by_id {
  my ($self,$id,$value)=@_;
  $self->{data}->{$id}=[$id,$value];

  $self->{id}=$id if $id >$self->{id};
  my $stack=$self->{stack};

  if($#{$stack}==-1) {
    $self->rebuild_stack;
  } elsif($stack->[0] > $id) {
    unshift @{$stack},$id;
  } elsif($stack->[0]==$id) {
    # do nothing!
  } elsif($stack->[$#{$stack}] < $id) {
    push @{$stack},$id;
  } elsif($stack->[$#{$stack}] == $id) {
    # do nothing!
  } else {
    $self->rebuild_stack;
  }
  return $id;
}

=item * $stack->remove($id)

Removes the $id from the stack

=cut

sub remove {
  my ($self,$id)=@_;
  delete $self->{data}->{$id};
  $self->rebuild_stack;
  return;
}

=item * $self->rebuild_stack

Internal method for rebuilding the internal stack as needed.

=cut

sub rebuild_stack {
  my ($self)=@_;
  my @set=sort { $a->[0] <=> $b->[0] } values %{$self->{data}};
  @{$self->{stack}}=();
  foreach my $set (@set) {
    push  @{$self->{stack}},$set->[0];
  }
  return;
}

=item * my $total=$stack->total

Returns the total number of elements on the stack

=cut

sub total {
  my ($self)=@_;
  return scalar(keys %{$self->{data}});
}

=back

=head1 AUTHOR

Mike Shipper Mike Shipper <AKALINUX@CPAN.ORG>

=cut

1;
