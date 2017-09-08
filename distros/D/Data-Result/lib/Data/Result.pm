package Data::Result;

use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Carp qw(croak);
use Scalar::Util qw(blessed);
use boolean;
use namespace::clean;

use overload
  fallback=>1,
  '""'=>sub { $_[0]->msg },
  bool=>sub { $_[0]->is_true },
;

our $VERSION='1.0002';

=head1 NAME

Data::Result - Handling true and false in a better way!

=head1 SYNOPSIS

  use Modern::Perl;
  use Data::Result;

  # just true 
  my $result=Data::Result->new(is_true=>0);
  if($result) {
    print "Yup its true!\n";
  }

  # True with data
  $result=Data::Result->new(is_true=>1,data=>'Yup This is true!');
  if($result) {
    print $result->data,"\n";
  }

  # just flase
  $result=Data::Result->new(is_true=>0);
  if($result) {
    print $result->data,"\n";
  } else {
    print "well, something went wrong!\n";
  }

  # handle false, but give us an error!
  $result=Data::Result->new(is_true=>0,msg=>'this is our message');
  if($result) {
    print $result->data,"\n";
  } else {
    print "$result\n";
  }

=head1 DESCRIPTION

Handling true and false isn't always enough.  This alows true and false to encapsulate things as a simple state.

=cut

# This method runs after the new constructor
sub BUILD {
  my ($self)=@_;
}

# this method runs before the new constructor, and can be used to change the arguments passed to the module
around BUILDARGS => sub {
  my ($org,$class,@args)=@_;
  
  return $class->$org(@args);
};


=head1 Object Constructor Arguments

Data::Result provides the following constructor arguments

Required arguments:

  is_true: true or fale
    # if not blessed it will be converted to a boolean true or false object

Optional arguments

  data: Data this object contains
  msg:  A human readable string representing this object.
  extra: another slot to put data in

=cut

has is_true=>(
  is=>'rw',
  isa=>Bool,
  required=>1,
  coerce=>sub { blessed $_[0] ? $_[0] : $_[0] ? true : false }
);

has msg=>(
  is=>'rw',
  isa=>Str,
  default=>'',
  lazy=>1,
);

has data=>(
  is=>'rw',
  lazy=>1,
);

has extra=>(
  is=>'rw',
  lazy=>1,
);

=head1 OO Methods

=over 4

=item * my $data=$result->get_data

Simply a wrapper for $result->data

=cut

sub get_data { $_[0]->data }

=item * if($result->is_false) { ... }

Inverts $self->is_true

=cut

sub is_false { !$_[0]->is_true }

=item * my $result=Data::Result->new_true($data,$extra);

Wrapper for 

  my $result=Data::Result->new(is_true=>1,data=>$data,extra=>$data);

=cut

sub new_true {
  my ($self,$data,$extra)=@_;
  return $self->new(is_true=>1,data=>$data,extra=>$extra);
}

=item * my $result=Data::Result->new_false($msg,$extra);

Wrapper for 

  my $result=Data::Result->new(is_true=>1,msg=>$msg,extra=>$data);

=cut

sub new_false {
  my ($self,$msg,$extra)=@_;
  croak '$msg is a required argument' unless defined($msg);
  return $self->new(is_true=>0,msg=>$msg,extra=>$extra);
}

sub DEMOLISH {
  my ($self)=@_;
  return unless defined($self);
  delete $self->{extra};
  delete $self->{data};
  delete $self->{msg};
}

=back

=head1 See Also

L<boolean>

=head1 AUTHOR

Mike Shipper <AKALINUX@CPAN.ORG>

=cut

1;
