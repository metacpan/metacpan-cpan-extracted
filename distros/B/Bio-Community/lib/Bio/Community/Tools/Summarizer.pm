# BioPerl module for Bio::Community::Tools::Summarizer
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::Summarizer - Create a summary of communities

=head1 SYNOPSIS

  use Bio::Community::Tools::Summarizer;

  # Given a metacommunity, merge community members with the same taxonomy, then
  # group members at the second level of their taxonomy (i.e. phylum level when
  # using the Greengenes taxonomy), then group members at less than 1% relative
  # abundance into a single group called 'Other':
  my $summarizer = Bio::Community::Tools::Summarizer->new(
     -metacommunity => $meta,
     -merge_dups    => 1,
     -by_tax_level  => 2,
     -by_rel_ab     => ['<', 1],
  );
  my $summarized_meta = $summarizer->get_summary;

=head1 DESCRIPTION

Summarize communities in a metacommunity by grouping members based on their
taxonomic affiliation first, then by collapsing or removing members with a
relative abundance above or below a specified threshold. Summarizing communities
should be the last step of any community analysis, because it compresses
communities (members, weights, taxonomy, etc.) in a way that cannot be undone.

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

 Function: Create a new Bio::Community::Tool::Summarizer object
 Usage   : my $summarizer = Bio::Community::Tools::Summarizer->new(
              -metacommunity => $meta,
           );
 Args    : -metacommunity   : See metacommunity().
           -merge_dups      : See merge_dups().
           -identify_dups_by: See identify_dups_by().
           -by_tax_level    : See by_tax_level().
           -by_rel_ab       : See by_rel_ab().
 Returns : a Bio::Community::Tools::Summarizer object

=cut


package Bio::Community::Tools::Summarizer;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::IO;
use Bio::Community::Meta;
use Bio::Community::TaxonomyUtils
   qw(get_taxon_lineage get_lineage_string clean_lineage_arr);

use POSIX; # defines DBL_EPSILON to something like 2.22044604925031e-16
use constant EPSILON => 100 * DBL_EPSILON; # suggested in "Mastering Algorithms in Perl"


extends 'Bio::Root::Root';


=head2 metacommunity

 Function: Get/set communities, given as metacommunity, to summarize.
 Usage   : my $meta = $summarizer->metacommunity;
 Args    : A Bio::Community::Meta object
 Returns : A Bio::Community::Meta object

=cut

has metacommunity => (
   is => 'rw',
   isa => 'Maybe[Bio::Community::Meta]',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-metacommunity',
);


=head2 merge_dups

 Function: Merge duplicate community members into a single one. For example, if
           your community contained several members with a taxonomic lineage of
           'Archaea;Euryarchaeota;Halobacteria', all would be merged into a new
           member with the same taxonomy and the sum of the counts. See the
           identify_dups_by() method to specify what constitutes duplicates.
           Note that merging duplicates takes place before grouping by taxonomy
           level, by_tax_level().
 Usage   : $summarizer->merge_dups(1);
 Args    : 0 (no) or 1 (yes). Default: 1
 Returns : a positive integer

=cut

has merge_dups => (
   is => 'rw',
   isa => 'Bool',
   required => 0,
   lazy => 1,
   default => 1,
   init_arg => '-merge_dups',
);


=head2 identify_dups_by

 Function: Define what constitute duplicates, i.e. members that have the same
           desc() or the same taxon().
 Usage   : $summarizer->identify_dups_by('taxon');
 Args    : 'desc' or 'taxon'. Default: 'desc'
 Returns : 'desc' or 'taxon'

=cut

has identify_dups_by => (
   is => 'rw',
   isa => 'IdentifyDupsByType',
   required => 0,
   lazy => 1,
   default => 'desc',
   init_arg => '-identify_dups_by',
);


=head2 by_tax_level

 Function: Get/set the taxonomic level at which to group community members. When
           community members have taxonomic information attached, add the
           relative abundance of all members belonging to the same taxonomic
           level. The taxonomic level depends on which taxonomy is used. For the
           Greengenes taxonomy, level 1 represents kingdom, level 2 represents
           phylum, and so on, until level 7, representing the species level.
           Members without taxonomic information are grouped together in a Member
           with the description 'Unknown taxonomy'.
           Note that summarizing by taxonomy level takes place before grouping by
           relative abundance, by_rel_ab(). Also, since each community member
           represents the combination of multiple members, they have to be given
           a new weight, that is specific to the community they belong to.
 Usage   : $summarizer->by_tax_level(2);
 Args    : a positive integer
 Returns : a positive integer

=cut

has by_tax_level => (
   is => 'rw',
   isa => 'Maybe[StrictlyPositiveInt]',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-by_tax_level',
);


=head2 by_rel_ab

 Function: Get/set the relative abundance threshold to group members together.
           Example: You provide a metacommunity containing multiple communities
           and you specify to group members with a relative abundance less than
           1%. If the abundance of member A is less than 1% in all the
           communities, it is removed from the communities and added as a new
           member with the desciption 'Other < 1%' along with all other members
           that are less than 1% in all the communities.
           Note that when community members are weighted, the 'Other' group also
           has to be weighted differently for each community.
 Usage   : $summarizer->by_rel_ab('<', 1);
 Args    : * the type of numeric comparison, '<', '<=', '>=', '>'
           * the relative abundance threshold (in %)
 Returns : * the type of numeric comparison, '<', '<=', '>=', '>'
           * the relative abundance threshold (in %)

=cut

has by_rel_ab => (
   is => 'rw',
   isa => 'Maybe[ArrayRef]', # how to specify ArrayRef[Str, Num]?
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-by_rel_ab',
);


=head2 get_summary

 Function: Summarize the communities and return an arrayref of fresh communities.
 Usage   : my $summary = $summarizer->get_summary;
 Args    : None
 Returns : A Bio::Community::Meta object

=cut

method get_summary () {
   # Sanity check
   my $meta = $self->metacommunity;
   if ( (not $meta) || ($meta->get_communities_count == 0) ) {
      $self->throw('Should have a metacommunity containing at least one community');
   }

   my $summary = $meta;

   # Then merge duplicates
   my $merge_dups = $self->merge_dups();
   if ($merge_dups) {
      $summary = $self->_merge_duplicates($summary, $merge_dups);
   }

   # Then summarize by taxonomy
   my $tax_level = $self->by_tax_level();
   if (defined $tax_level) {
      $summary = $self->_group_by_taxonomic_level($summary, $tax_level);
   }

   # Finally, group members by abundance
   my $rel_ab_params = $self->by_rel_ab;
   if (defined $rel_ab_params) {
      $summary = $self->_group_by_relative_abundance($summary, $rel_ab_params);
   }

   return $summary;
};


method _merge_duplicates ( $meta, $merge_dups ) {
   # Create fresh community objects to hold the summary
   my $summary = $self->_new_summary($meta);
   my $use_desc = $self->identify_dups_by eq 'desc' ? 1 : 0;
   my $taxa_counts = {};
   my $taxa_objs   = {};
   for my $member ( @{$meta->get_all_members} ) {
      my $taxon = $use_desc ? $member->desc : $member->taxon;
      if ($taxon) {
         # Member has taxonomic information
         my $lineage_str = $use_desc ? $taxon : get_lineage_string(get_taxon_lineage($taxon));

         # Save taxon object
         if (not exists $taxa_objs->{$lineage_str}) {
            $taxa_objs->{$lineage_str} = $taxon;
         }

         # For each community, add member counts and weighted counts to the taxonomic group
         my $i = -1;
         while (my $community = $meta->next_community) {
            $i++;
            my $count = $community->get_count($member);
            my $wcount = $count / $member->get_weights_prod;
            $taxa_counts->{$lineage_str}->{$i}->[0] += $count;
            $taxa_counts->{$lineage_str}->{$i}->[1] += $wcount;
         }

      } else {
         # Member has no taxonomic assignment. Add member as-is in the summary.
         my $i = -1;
         while (my $community = $meta->next_community) {
            $i++;
            my $count = $community->get_count($member);
            my $summary = $summary->get_community_by_name($community->name);
            $summary->add_member($member, $count);
         }
      }

   }

   # Add taxonomic groups to all communities
   $self->_add_groups($taxa_objs, $taxa_counts, $summary, $use_desc);

   return $summary;
}


method _group_by_taxonomic_level ( $meta, $tax_level ) {

   # Create fresh community objects to hold the summary
   my $summary = $self->_new_summary($meta);

   my $taxa_counts = {};
   my $taxa_objs   = {};
   for my $member ( @{$meta->get_all_members} ) {
      my $taxon = $member->taxon;
      if ($taxon) {
         # Member has taxonomic information
         my $lineage_arr = get_taxon_lineage($taxon);
         my $end_idx = $tax_level-1 > $#$lineage_arr ?  $#$lineage_arr : $tax_level-1;
         $lineage_arr = [ @{$lineage_arr}[0 .. $end_idx] ];
         
         # Need to clean lineage again to prevent this from happening:
         #   o__Rickettsiales;f__;g__Candidatus P. -> o__Rickettsiales;f__
         $lineage_arr = clean_lineage_arr($lineage_arr);

         if ( scalar @$lineage_arr > 0 ) {
            # Could find Bio::Taxon at requested taxonomic level
            my $lineage_str = get_lineage_string($lineage_arr);
            $taxon = $lineage_arr->[-1];

            # Save taxon object
            if (not exists $taxa_objs->{$lineage_str}) {
               $taxa_objs->{$lineage_str} = $taxon;
            }

            # For each community, add member counts and weighted counts to the taxonomic group
            my $i = -1;
            while (my $community = $meta->next_community) {
               $i++;
               my $count = $community->get_count($member);
               my $wcount = $count / $member->get_weights_prod;
               $taxa_counts->{$lineage_str}->{$i}->[0] += $count;
               $taxa_counts->{$lineage_str}->{$i}->[1] += $wcount;
            }

         } else {
            # Member had taxonomic information at a higher level than requested.
            # Add member as-is in the summary.
            my $i = -1;
            while (my $community = $meta->next_community) {
               $i++;
               my $count = $community->get_count($member);
               my $summary = $summary->get_community_by_name($community->name);
               $summary->add_member($member, $count);
            }
         }
      }

      if (not $taxon) {
         # Member had no taxonomic info. Add it in a separate group.
         my $lineage_str = 'Unknown taxonomy';
         if (not exists $taxa_objs->{$lineage_str}) {
            $taxa_objs->{$lineage_str} = undef;
         }
         my $i = -1;
         while (my $community = $meta->next_community) {
            $i++;
            my $count = $community->get_count($member);
            my $wcount = $count / $member->get_weights_prod;
            $taxa_counts->{$lineage_str}->{$i}->[0] += $count;
            $taxa_counts->{$lineage_str}->{$i}->[1] += $wcount;
         }
      }

   }

   # Add taxonomic groups to all communities
   $self->_add_groups($taxa_objs, $taxa_counts, $summary);

   return $summary;
}


method _group_by_relative_abundance ( $meta, $params ) {

   # Get grouping parameters
   my $thresh   = $params->[1] || $self->throw("No grouping threshold was provided.");
   my $operator = $params->[0] || $self->throw("No comparison operator was provided.");
   my $cmp;
   if      ($operator eq '<' ) {
      $cmp =  sub { $_[0] < $_[1] };
   } elsif ($operator eq '<=' ) {
      $cmp =  sub { $_[0] - $_[1] < EPSILON };
   } elsif ($operator eq '>=' ) {
      $cmp =  sub { $_[1] - $_[0] < EPSILON };
   } elsif ($operator eq '>' ) {
      $cmp =  sub { $_[1] <  $_[0] };
   } else {
      $self->throw("Invalid comparison operator provided, '$operator'.");
   }

   # Create fresh community objects to hold the summary
   my $summary = $self->_new_summary($meta);

   my $taxa_counts = {};
   my $desc = "Other $operator $thresh %";
   my $taxa_objs = { $desc => undef };

   for my $member ( @{$meta->get_all_members} ) {

      # Determine if this member should be grouped
      my $member_to_group = 1;
      my $rel_abs;
      while (my $community = $meta->next_community) {
         push @$rel_abs, $community->get_rel_ab($member);
      }
      for my $rel_ab (@$rel_abs) {
         if ( not &$cmp($rel_ab, $thresh) ) {
            $member_to_group = 0; # This member needs no grouping
            last;
         }
      }

      my $i = 0;
      while (my $community = $meta->next_community) {
         my $rel_ab = $rel_abs->[$i];
         my $count  = $community->get_count($member);
         if ($count > 0) {
            if ($member_to_group) {
               # Will group member
               $taxa_counts->{$desc}->{$i}->[0] += $count; # count
               $taxa_counts->{$desc}->{$i}->[1] += $count / $member->get_weights_prod;
            } else {
               # Add member as-is, ungrouped
               $summary->get_community_by_name($community->name)->add_member($member, $count);
            }
         }
         $i++;
      }

   }

   # Add taxonomic groups to all communities
   $self->_add_groups($taxa_objs, $taxa_counts, $summary);

   return $summary;
}


method _calc_weights ($count, $weighted_count) {
   # Given a count and a weighted count, calcualte
   my $weight = ($count > 0) ? ($count / $weighted_count) : 1;
   return [ $weight ];
}

method _add_groups ($taxa_objs, $taxa_counts, $summary, $use_desc = 0) {
   # Add groups to the summary metacommunity provided
   while (my ($lineage_str, $taxon) = each %$taxa_objs) {
      # Make a group template
      my $group_template = Bio::Community::Member->new( );
      if ($use_desc) {
         $group_template->desc($taxon);
         #### TODO: Need to make taxonomy. Ideally instead of re-making it, it should not be lost.
         #use Bio::Community::TaxonomyUtils qw(split_lineage_string);
         #my @names = @{split_lineage_string($lineage_str)};
         #my $taxonomy = $tax_obj->db_handle;
         #my $tax_obj = $self->taxonomy->get_taxon( -names => \@names );
         #$group_template->taxon($tax_obj);
      } else {
         $group_template->desc($lineage_str);
         if ($taxon) {
            $group_template->taxon($taxon);
         }
      }
      # Make a group based on the template and add it to each community
      my $i = 0;
      while (my $summary = $summary->next_community) {
         my $count_info = $taxa_counts->{$lineage_str}->{$i} || next;
         my ($count, $wcount) = @{$count_info};
         my $group = $group_template->clone;
         $group->weights( $self->_calc_weights($count, $wcount) );
         $summary->add_member($group, $count) if $count > 0;
         $i++;
      }
   }
   return 1;
}


method _new_summary ($meta) {
   # Create a fresh metacommunity object to hold the summary. One summary per
   # input community.
   my $summary = Bio::Community::Meta->new;
   while (my $community = $meta->next_community) {
      my $name = $community->name;
      #if ($name !~ / summarized$/) {
      #   $name .= ' summarized';
      #}
      my $use_weights = $community->use_weights;
      my $comm_summary = Bio::Community->new(
         -name        => $name,
         -use_weights => $use_weights,
      );
      $summary->add_communities([$comm_summary]);
   }
   return $summary;
}


__PACKAGE__->meta->make_immutable;

1;
