#!/usr/bin/perl

package Bio::LITE::Taxonomy;

=head1 NAME

Bio::LITE::Taxonomy - Lightweight and efficient taxonomic tree manager

=head1 SYNOPSIS

 use Bio::LITE::Taxonomy

 my $taxNCBI = Bio::LITE::Taxonomy::NCBI->new (
                                               names=> "/path/to/names.dmp",
                                               nodes=>"/path/to/nodes.dmp"
                                              );

 my @taxNCBI = $taxNCBI->get_taxonomy(1442);

 my $taxRDP = Bio::LITE::Taxonomy::RDP->new (
                                             bergeyXML=>"/media/disk-1/bergeyTrainingTree.xml"
                                            )

 my @taxRDP = $taxRDP->get_taxonomy(22075);

=head1 DESCRIPTION

This module provides easy and efficient access to different taxonomies (NCBI and RDP) with minimal dependencies and without intermediate databases. This module should be used through specific taxonomic interfaces (e.g. L<Bio::LITE::Taxonomy::NCBI> or L<Bio::LITE::Taxonomy::RDP>).

This module is not part of the Bioperl bundle. For Bioperl alternatives, see the L</"SEE ALSO"> section of this document. If you are dealing with big datasets or you don't need the rest of the Bioperl bundle to process taxonomic queries this module is for you.

These modules are designed with performance in mind. The trees are stored in memory (as plain hashes). The GI to Taxid mappings provided by L<Bio::LITE::Taxonomy::NCBI::Gi2taxid> are very efficient. It also supports both NCBI and RDP taxonomies following the same interface.


=head1 METHODS

The following methods are available:

=over 4

=item get_taxonomy

Accepts a taxid as input and returns an array with its ascendants ordered from top to bottom.

  my @tax = $tax->get_taxonomy($taxid);
  print "$_\n" for (@tax);

If called in scalar context, returns an array reference.

=item get_taxonomy_with_levels

The same as get_taxonomy but instead of getting the ascendants returns an array of array references. Each array reference has the ascendant and its taxonomic level (at positions 0 and 1 respectively). This is simpler than it sounds. Check this:

  my @taxL = $tax->get_taxonomy_with_levels($taxid);
  for my $l (@taxL) {
    print "Taxon $l->[0] has rank $l->[1]\n";
  }

If called in scalar context, returns an array reference.

=item get_taxid_from_name

Accepts the scientific name of a taxon and returns its associated taxid.

=item get_taxonomy_from_name

Same as before but returns the full taxonomy of the scientific name. This is the same as:

 my $taxid = $tax->get_taxid_from_name($name);
 my @taxonomy = $tax->get_taxonomy($taxid);

If called in scalar context returns an array reference.

=item get_term_at_level

Given a taxid and a taxonomic level as input, returns the taxon. For example,

  my $taxon = $tax->get_term_at_level(1442,"family"); # $taxon = Bacillaceae

=item get_level_from_name

Given a taxon's scientific name, returns its associated taxonomic level.

=back

=head1 SEE ALSO

L<Bio::LITE::Taxonomy::RDP>

L<Bio::LITE::Taxonomy::NCBI>

L<Bio::LITE::Taxonomy::NCBI::Gi2taxid>: Module to obtain NCBIs Taxids from GIs.

L<Bio::DB::Taxonomy::*>: Bioperl alternative to handle taxonomies.

L<Bio::Taxon>: Bioperl module to handle nodes in taxonomies

=head1 AUTHOR

Miguel Pignatelli

Any comments or suggestions should be addressed to emepyc@gmail.com

=head1 LICENSE

Copyright 2009 Miguel Pignatelli, all rights reserved.

This library is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use Carp qw/croak/;

use vars qw/$VERSION @ISA/;
$VERSION = '0.07';

sub _check_level
  {
    my ($self, $level) = @_;
    croak "Level not defined" unless defined $level;;
    return $self->{allowed_levels}{$level};
  }

sub _print_levels
  {
    my ($self) = @_;
    print STDERR "$_\n" for sort keys %{$self->{allowed_levels}}; 
  }

sub get_term_at_level
    {
      my ($self,$taxid,$level) = @_;
      do {
    print STDERR "Level $level not recognized\nAllowed levels:\n";
    $self->_print_levels;
    croak;
      } if (! defined $self->_check_level($level));
      return "" unless (defined ${$self->{nodes}->{$taxid}}{name});
      while (${$self->{nodes}->{$taxid}}{name} ne "root"){
    return ${$self->{nodes}->{$taxid}}{name} if (${$self->{nodes}->{$taxid}}{level} eq $level);
    $taxid = ${$self->{nodes}->{$taxid}}{parent};
      }
      return "undef";
    }

sub get_taxonomy
    {
      my ($self, $taxid) = @_;
      return undef unless defined $taxid;
      return "" unless defined ${$self->{nodes}->{$taxid}}{name};
      my @taxonomy;
      while (${$self->{nodes}->{$taxid}}{name} ne "root"){
        push @taxonomy, ${$self->{nodes}->{$taxid}}{name};
        $taxid = ${$self->{nodes}->{$taxid}}{parent};
      }
#      pop @taxonomy;  # Causes lost of first non-root annotation
      return wantarray
        ? reverse @taxonomy
          : [reverse @taxonomy];
#      return reverse do{pop @taxonomy;@taxonomy};
    }

# Note:
# This may change in the future.
# It would be simpler to return a hash reference, but (specially in the NCBI taxonomy)
# many taxons has not associated level (i.e. C<no rank>) which would imply collapsing the keys.
# And of course, use an ordered hash or keep an extra array with the ordering.
# The code for doing this is commented below.
# Look for user feedback about this.
sub get_taxonomy_with_levels
    {
      my ($self,$taxid) = @_;
      return undef unless defined $taxid;
      return "" unless defined ${$self->{nodes}->{$taxid}}{name};
      my @taxonomy;
      while (${$self->{nodes}->{$taxid}}{name} ne "root"){
        push @taxonomy, [${$self->{nodes}->{$taxid}}{name},${$self->{nodes}->{$taxid}}{level}];
        $taxid = ${$self->{nodes}->{$taxid}}{parent};
      }
#      pop @taxonomy; # Last element is cellular_organism... always?
      return wantarray 
        ? reverse @taxonomy
          :  [reverse @taxonomy];
#      return reverse do{pop @taxonomy;@taxonomy};
    }

sub get_level_from_name
      {
        my ($self,$name) = @_;
        return defined $self->{names}{$name} ? $self->{nodes}->{$self->{names}{$name}}->{level} : undef;
      }

sub get_taxid_from_name
        {
          my ($self,$name) = @_;
          return defined $self->{names}{$name} ? $self->{names}{$name} : undef;
        }

sub get_taxonomy_from_name
          {
            my ($self,$name) = @_;
            return $self->get_taxonomy($self->{names}{$name});
          }

# Currently not in use. May apply in the future
# sub _get_taxonomy
#       {
#         my ($self,$taxid) = @_;
#         return undef unless (defined $taxid);
#         return "" unless defined ${$self->{nodes}->{$taxid}}{name};
#         my %taxonomy;
#         my @order;
#         while (${$self->{nodes}->{$taxid}}{name} ne "root"){
#           push @{$taxonomy{${$self->{nodes}->{$taxid}}{level}}}, ${$self->{nodes}->{$taxid}}{name};
#           push @order, ${$self->{nodes}->{$taxid}}{level};
#           $taxid = ${$self->{nodes}->{$taxid}}{parent};
#         }
#         return (\%taxonomy,\@order);
#       }

# Currently not in use. May apply in the future
# sub get_taxonomy1
#         {
#           my ($self,$taxid) = @_;
#           my ($t,$o) = $self->_get_taxonomy($taxid);
#           my @taxonomy;
#           for my $l (@$o) {
#             push @taxonomy,shift @{$t->{$l}};
#           }
#           return reverse do{pop @taxonomy; @taxonomy};
#         }

# Currently not in use. May apply in the future
# sub get_taxonomy_with_levels1
#           {
#             my ($self,$taxid) = @_;
#             my ($t,$o) = $self->_get_taxonomy($taxid);
#             my @taxonomy;
#             for my $l (@$o) {
#               push @taxonomy, ($l.":".shift @{$t->{$l}});
#             }
#             return join "\t",@taxonomy;
#           }

1;
