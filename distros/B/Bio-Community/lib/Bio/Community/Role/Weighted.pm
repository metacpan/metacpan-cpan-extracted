# BioPerl module for Bio::Community::Role::Weighted
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Role::Weighted - Role for objects that have a weight

=head1 SYNOPSIS

  package My::Package;

  use Moose;
  with 'Bio::Community::Role::Weighted';

  # Use the weights() method as needed
  # ...

  1;

=head1 DESCRIPTION

This role provides the capability to add an arrayref of weights (strictly positive
numbers) to objects of the class that consumes this role.

=head1 AUTHOR

Florent Angly L<florent.angly@gmail.com>

=head1 SUPPORT AND BUGS

User feedback is an integral part of the evolution of this and other Bioperl
modules. Please direct usage questions or support issues to the mailing list, 
L<bioperl-l@bioperl.org>, rather than to the module maintainer directly. Many
experienced and reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem with code and
data examples if at all possible.

If you have found a bug, please report it on the BioPerl bug tracking system
to help us keep track the bugs and their resolution:
L<https://redmine.open-bio.org/projects/bioperl/>

=head1 COPYRIGHT

Copyright 2011-2014 by Florent Angly <florent.angly@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


package Bio::Community::Role::Weighted;

use Moose::Role;
use namespace::autoclean;
use Method::Signatures;
use Bio::Community::Types;


=head2 weights

 Usage   : my $weights = $member->weights();
 Function: Get or set some weights for this object. Weights represent how biased
           the sampling of this organism is. For example, when random shotgun
           sequencing microorganisms in the environment, the relative abundance
           of reads in the sequence library is not proportional to the relative
           abundance of the genomes because larger genomes contribute
           disproportionalely more reads than small genomes. In such a case, you
           could set the weight to the length of the genome. Do not attempt to
           change weights after a member has been added to a community!
           Note: Do not use a weight value of zero, except temporarily, and make
           sure to give a proper weight (>0) before adding a member to a community.
 Args    : An arrayref of positive integers
 Returns : An arrayref of positive integers

=cut

has weights => (
   is => 'rw',
   ###isa => 'Maybe[ArrayRef[StrictlyPositiveNum]]',
   isa => 'Maybe[ArrayRef[PositiveNum]]',
   required => 0,
   default => sub {[ 1 ]},
   init_arg => '-weights',
   lazy => 1,
   trigger => sub { shift->_clear_weights_prod; },
);


=head2 get_weights_prod

 Usage   : my $product = $member->get_weights_prod();
 Function: Calculate the product of the weights.
 Args    : None
 Returns : Product of the weights

=cut

has _weights_prod => (
   is => 'ro',
   ###isa => 'Num',
   required => 0,
   default => sub { my $prod = 1; $prod *= $_ for @{shift->weights}; return $prod; },
   init_arg => undef,
   lazy => 1,
   clearer => '_clear_weights_prod',
   reader => 'get_weights_prod',
);


1;
