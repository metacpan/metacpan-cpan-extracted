=head1 NAME

Bio::Polloc::GroupCriteria::operator::cons - A constant

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::GroupCriteria::operator::cons;
use base qw(Bio::Polloc::GroupCriteria::operator);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 GLOBALS

=head2 OP_CONS

A hashref containing any eventual constant value.

=cut

our $OP_CONS = {};

=head1 APPENDIX

Methods provided by the package

=head2 new

Generic initialization method.

=head3 Arguments

See L<Bio::Polloc::GroupCriteria::operator->new()>

=head3 Returns

A L<Bio::Polloc::GroupCriteria::operator::bool> object.

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 operate

=head3 Returns

A L<Bio::Seq> object.

=cut

sub operate {
   my $self = shift;
   return $self->val if defined $self->val;
   my $out = $Bio::Polloc::GroupCriteria::operator::cons::OP_CONS->{$self->operation};
   return $out if defined $out;
   $self->throw("Unknown constant", $self->operation);
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize { }

1;
