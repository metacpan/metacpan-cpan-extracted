# BioPerl module for Bio::Community::Tools::Transformer
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::Transformer - Arbitrary transformation of member counts

=head1 SYNOPSIS

  use Bio::Community::Tools::Transformer;

  # Hellinger-transform the counts of community members in a metacommunity
  my $transformer = Bio::Community::Tools::Transformer->new(
     -metacommunity => $meta,
     -type          => 'hellinger',
  );

  my $transformed_meta = $summarizer->get_transformed_meta;

=head1 DESCRIPTION

This module takes a metacommunity and transform the count of the community
members it contains. Several transformation methods are available: identity,
binary, or hellinger.

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

=head2 new

 Function: Create a new Bio::Community::Tool::Transformer object
 Usage   : my $transformer = Bio::Community::Tool::Transformer->new( );
 Args    : -metacommunity: see metacommunity()
           -type         : see type()
 Returns : a new Bio::Community::Tools::Transformer object

=cut


package Bio::Community::Tools::Transformer;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::Meta;
use Scalar::Util;


extends 'Bio::Root::Root';


=head2 metacommunity

 Function: Get or set the metacommunity to normalize.
 Usage   : my $meta = $transformer->metacommunity;
 Args    : A Bio::Community::Meta object
 Returns : A Bio::Community::Meta object

=cut

has metacommunity => (
   is => 'rw',
   isa => 'Maybe[Bio::Community::Meta]',
   required => 0,
   default => undef,
   lazy => 1,
   init_arg => '-metacommunity',
);


=head2 type

 Function: Get or set the type of transformation that is to be applied to member
           counts (not relative abundance):
            * identity  : Keep the counts as-is
            * binary    : Assign 1 if member is present, 0 if absent
            * relative  : Set count of member equal to its relative abundance (%)
            * chisquare : Chi-square transformation
            * chord     : Chord transformation
            * hellinger : Hellinger transformation
 Usage   : my $type = $transformer->type;
 Args    : identity, binary, relative, chisquare, chord, or hellinger
 Returns : identity, binary, relative, chisquare, chord, or hellinger

=cut

has type => (
   is => 'rw',
   isa => 'TransformationType',
   required => 0,
   default => 'identity',
   lazy => 1,
   init_arg => '-type',
);


=head2 get_transformed_meta

 Function: Calculate and return a transformed metacommunity.
 Usage   : my $meta = $transformer->get_transformed_meta;
 Args    : none
 Returns : a new Bio::Community::Meta object

=cut

has transformed_meta => (
   is => 'rw',
   isa => 'Bio::Community::Meta',
   required => 0,
   default => sub { undef },
   lazy => 1,
   reader => 'get_transformed_meta',
   writer => '_set_transformed_meta',
   predicate => '_has_transformed_meta',
);

before get_transformed_meta => sub {
   my ($self) = @_;
   $self->_transform if not $self->_has_transformed_meta;
   return 1;
};


method _transform () {
   # Sanity check
   my $meta = $self->metacommunity;
   if ( (not $meta) || ($meta->get_communities_count == 0) ) {
      $self->throw('Should have a metacommunity containing at least one community');
   }

   # Register transformation functions
   my ($sub, $pre_sub);
   my $type = $self->type;
   if ($type eq 'identity') {
      $pre_sub = undef;
      $sub     = sub {
                    # Keep same count
                    my ($com, $mem) = @_;
                    return $com->get_count($mem);
                 };
   }
   elsif ($type eq 'binary') {
      $pre_sub = undef;
      $sub     = sub {
                    # 1 for presence, 0 otherwise
                    my ($com, $mem) = @_;
                    return $com->get_count($mem) > 0 ? 1 : 0;
                 };
   }
   elsif ($type eq 'relative') {
      $pre_sub = undef;
      $sub     = sub {
                    # Use relative abundance
                    my ($com, $mem) = @_;
                    return $com->get_rel_ab($mem);
                 };
   }
   elsif ($type eq 'chord') {
      $pre_sub = sub {
                    # Add the squares of count
                    my ($com, $mem, $sum) = @_;
                    return $sum + $com->get_count($mem)**2;
                 }; 
      $sub     = sub {
                    # Count divided by sum of squares
                    my ($com, $mem, $sum) = @_;
                    return $com->get_count($mem) / $sum;
                 };
   }
   elsif ($type eq 'hellinger') {
      $pre_sub = undef;
      $sub     = sub {
                    # Square root of count
                    my ($com, $mem) = @_;
                    return sqrt $com->get_count($mem);
                 };
   }
   else {
      $self->throw("Unsupported transformation type '$type'");
   }

   # Create new transformed metacommunity
   my $transformed_meta = Bio::Community::Meta->new( -name => $meta->name );
   while (my $community = $meta->next_community) {
      my $name = $community->name;
      my $transformed = Bio::Community->new(
         -name        => $name,
         -use_weights => $community->use_weights,
      );

      # Pre-processing (if needed)
      my $pre = 0;
      if (defined $pre_sub) {
         while ( my $member = $community->next_member('_transform') ) {
            $pre = $pre_sub->($community, $member, $pre);
         }
      }

      # Transform counts
      while ( my $member = $community->next_member('_transform') ) {
         my $transf_count = $sub->($community, $member, $pre);
         $transformed->add_member($member, $transf_count);
      }
      $transformed_meta->add_communities([$transformed]);
   }
   $self->_set_transformed_meta($transformed_meta);

   return 1;
}


__PACKAGE__->meta->make_immutable;

1;
