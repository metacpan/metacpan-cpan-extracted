package Data::Result::Moo;

use Modern::Perl;
use Data::Result;
use Moo::Role;
use Carp qw(croak);
use namespace::clean;


=head1 NAME

Data::Result::Moo - Data::Result Moo Role

=head1 SYNOPSIS

  use Modern::Perl;
  use Moo;
  with('Data::Result::Moo);

=head1 Description

A simple Moo role wrapper for Data::Result


=head1 OO Methods

=over 4

=item * my $result->new_true($data,$extra|undef)

Creates a new true Data::Result Object

=item * my $result=$self->new_false($msg,$extra|undef)

Creates a new false Data::Result Object

=item * $class=$self->RESULT_CLASS;

Returns the class being used to generate result object.  Defaults to Data::Result;

=cut

sub new_true {
  my ($self,$data,$extra)=@_;
  return $self->RESULT_CLASS->new_true($data,$extra);
  
}

sub new_false {
  my ($self,$msg,$extra)=@_;
  croak '$msg is a required argument' unless defined($msg);
  return $self->RESULT_CLASS->new_false($msg,$extra);
}

sub RESULT_CLASS { 'Data::Result' }

=back

=head1 Author

Mike Shipper <AKALINUX@CPAN.ORG>

=cut

1;
