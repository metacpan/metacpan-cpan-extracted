# BioPerl module for Bio::Community::IO
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::IO - Read and write files that describe communities

=head1 SYNOPSIS

  use Bio::Community::IO;

  # Read communities from a file, one by one
  my $in = Bio::Community::IO->new(
     -file   => 'otu_table.qiime',
     -format => 'qiime', # format is optional
  );
  my $community1 = $in->next_community(); # a Bio::Community object
  my $community2 = $in->next_community();
  $in->close;

  # Write communities in another file
  my $out = Bio::Community::IO->new(
     -file   => '>new_otu_table.generic',
     -format => 'generic',
  );
  $out->write_community($community);
  $out->close;

  # Re-read communities, but all at once
  $in = Bio::Community::IO->new( -file => 'new_otu_table.generic' );
  my $meta = $in->next_metacommunity(); # a Bio::Community::Meta object
  $in->close;

=head1 DESCRIPTION

A Bio::Community::IO object implement methods to read and write communities in
formats used by popular programs such as BIOM, GAAS, QIIME, Unifrac, or as
generic tab-separated tables. The format should be automatically detected though
it can be manually specified. This module can also convert community member
abundance between counts, absolute abundance, relative abundance and fractions.

When reading communities, the next_member() method is called by next_community(),
which itself is called by next_metacommunity(). Similarly, when writing,
write_member() is called by write_community(), which is called by
write_metacommunity().

=head2 DRIVER IMPLEMENTATION

Bio::Community::IO provides the higher-level organisation to read and write
community files, but it is the modules located in the Bio::Community::IO::Driver::*
namespaces that do the low-level format-specific work.

All drivers are expected to implement specific methods, e.g. for reading:

=over

=item _next_metacommunity_init()

A private hook called at the beginning of next_metacommunity() that returns the
name of the metacommunity (if applicable). It also allows drivers to do an
action before the metacommunity is read.

=item _next_community_init()

A private hook called at the beginning of next_community() that returns the name
of the community. It also allows drivers to do an action before the current
community is read.

=item next_member()

A public method that returns a Bio::Community::Member and its count in the
community being read.

=item _next_community_finish()

A private hook called at the end of next_community(). It allows drivers to do
an action after the current community has been read.

=item _next_metacommunity_finish()

A private hook called at the end of next_metacommunity(). It allows drivers to
do an action after the metacommunity has been read.

=back

Similarly, for a driver to write community information to a file or stream,
it should implement these methods:

=over

=item _write_metacommunity_init()

A private hook called at the beginning of write_metacommunity() and that accepts
a Bio::Community::Meta as argument. It allows drivers to do an action before the
metacommunity is written.

=item _write_community_init()

A private hook called at the beginning of write_community() and that accepts
a Bio::Community as argument. It allows drivers to do an action before the
current community is written.

=item write_member()

A public method that accepts as arguments a Bio::Community::Member and its count
in the community being written, and processes them.

=item _write_community_finish()

A private hook called at the end of write_community() and that accepts a
Bio::Community as argument. It allows drivers to do an action after the
current community has been written.

=back _write_metacommunity_finish()

A private hook called at the end of write_metacommunity() and that accepts a
Bio::Community::Meta as argument. It allows drivers to do an action after the
metacommunity has been written.

=back
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

 Function: Create a new Bio::Community::IO object
 Usage   : # Reading a file
           my $in = Bio::Community::IO->new( -file => 'community.txt' );
           # Writing a file
           my $out = Bio::Community::IO->new( -file => '>community.txt',
                                              -format => 'generic'       );
 Args    : -file : Path of a community file. See file() in Bio::Root::IO.
           -format : Format of the file, either 'generic', 'biom', 'gaas',
               'qiime' or 'unifrac'. This is optional when reading a community
               file because the format is automatically detected by the
               Bio::Community::IO::FormatGuesser module. See also format() in
               Bio::Root::IO.
           -weight_files : Arrayref of files (or filehandles) that contain
               weights to assign to members. See weight_files().
           -weight_assign : When using files of weights, define what to do for
               community members that do not have weights. See weight_assign().
           -taxonomy: Given a Bio::DB::Taxonomy object, try to place the community
               members in this taxonomy. See taxonomy().
           -skip_empty_communities: Skip communities with no members. See
               skip_empty_communities()
           See the documentation for _initialize_io() in Bio::Root::IO for other
           accepted constructors like -fh, -string, -input, or -url.
 Returns : A Bio::Community::IO object

=cut


package Bio::Community::IO;

use Moose;
use Moose::Util qw/does_role/;
use MooseX::NonMoose;
use namespace::autoclean;
use Module::Runtime;
use Method::Signatures;
use Bio::Community;
use Bio::Community::Meta;
use Bio::Community::Types;
use Bio::Community::IO::FormatGuesser;
use Bio::Community::TaxonomyUtils
   qw(split_lineage_string get_taxon_lineage get_lineage_string clean_lineage_arr);

extends 'Bio::Root::Root',
        'Bio::Root::IO';


has '_meta' => (
   is => 'rw',
   #isa => undef, # Bio::Community::Meta
   required => 0,
   init_arg => undef,
   default => undef,
   lazy => 1,
);


# Overriding new... Is there a better alternative?

func new ($class, @args) {
   my $real_class = Scalar::Util::blessed($class) || $class;

   # These all come from the same base, Moose::Object, so this is fine
   my $params = $real_class->BUILDARGS(@args);
   my $format = delete $params->{'-format'};
   if (not defined $format) {
      # Try to guess format
      my $guesser = Bio::Community::IO::FormatGuesser->new();
      if ($params->{'-file'}) {
         $guesser->file( $params->{'-file'} );
      } elsif ($params->{'-fh'}) {
         $guesser->fh( $params->{'-fh'} );
      }
      $format = $guesser->guess;
   }
   if (not defined $format) {
      $real_class->throw("Could not automatically detect input format.");
   }

   # Use the real driver class here
   $real_class = __PACKAGE__.'::Driver::'.$format;
   Module::Runtime::use_module($real_class);
   $class->throw("Module $real_class does not implement a community IO stream")
       unless $real_class->does('Bio::Community::Role::IO');

   $params = $real_class->BUILDARGS(%$params);
   my $self = Class::MOP::Class->initialize($real_class)->new_object($params);

   return $self;
}


method BUILD ($args) {
   # Start IOs
   $self->_initialize_io(%$args);
   return 1;
}


=head2 next_member

 Usage   : my ($member, $count) = $in->next_member;
 Function: Get the next member from the community and its abundance. This
           function is implemented by the Bio::Community::IO::Driver used to
           parse the given file format.
 Args    : None
 Returns : An array containing:
             A Bio::Community::Member object (or undef)
             A positive number (or undef)

=cut

method next_member () {
   $self->throw_not_implemented;
}


=head2 next_community

 Usage   : my $community = $in->next_community;
 Function: Get the next community. Note that communities without members are
           skipped.
 Args    : None
 Returns : A Bio::Community object
             or
           undef if there were no communities left

=cut

method next_community () {
   my $community;

   if (not defined $self->_meta) {
      $self->_next_metacommunity_init( );
      $self->_meta(Bio::Community::Meta->new);
   }

   while ( 1 ) { # Skip communities with no members

      # Initialize driver for next community and set community name
      my $name = $self->_next_community_init;

      # All communities have been read
      last if not defined $name;

      # Create a new community object
      $community = Bio::Community->new( -name => $name );

      # Reinitialize queue
      my $count_queue = {};
      my $member_queue = $self->_member_queue;

      # Populate the community with members
      while ( my ($member, $count) = $self->next_member() ) {

         # All members have been read
         last if not defined $member;

         # Skip members without proper weights for now
         if (exists $member_queue->{$member->id}) {
            $count_queue->{$member->id} = $count;
            next;
         }

         # Add this member to the community
         $community->add_member($member, $count);
      }
      $self->_count_queue( $count_queue );

      # Process member queue now
      if (scalar keys %$count_queue > 0) {
         $self->_process_member_queue($community);
      }

      $self->_next_community_finish;

      if ( ($community->get_richness > 0) || (not $self->skip_empty_communities) ) {
         last;
      } else {
         $community = undef;
      }

   }
   # Community is undef if all communities have been seen
   return $community;
}


method _next_community_init () {
   # Driver-side method to initialize new community and return its name
   $self->throw_not_implemented;
}


method _next_community_finish () {
   # Driver-side method to finalize a community
   $self->throw_not_implemented;
}


=head2 next_metacommunity

 Usage   : my $meta = $in->next_metacommunity;
 Function: Get the next metacommunity. It may contain one or several communities
           depending on the format of the file read,
 Args    : None
 Returns : A Bio::Community::Meta object
             or
           undef after the metacommunity has been read

=cut

method next_metacommunity () {
   my $meta;
   if (not defined $self->_meta) {
      $meta = Bio::Community::Meta->new();
      my $name = $self->_next_metacommunity_init;
      if (defined $name) {
         $meta->name($name);
      }
      $self->_meta($meta);
      while (my $community = $self->next_community) {
         $self->_meta->add_communities([$community]);
      }
      # _next_metacommunity_finish will happen before close()
   }
   return $meta;
}


method _next_metacommunity_init () {
   # Driver-side method to initialize new metacommunity and return its name
   $self->throw_not_implemented;
}


method _next_metacommunity_finish () {
   # Driver-side method to finalize reading a metacommunity
   $self->throw_not_implemented;
}


=head2 write_member

 Usage   : $out->write_member($member, $abundance);
 Function: Write the next member from the community and its count or relative
           abundance. This function is implemented by a Bio::Community::IO::Driver
           specific to the given file format.
 Args    : A Bio::Community::Member object
           A positive number
 Returns : 1 for success

=cut

method write_member (Bio::Community::Member $member, Count $count) {
   $self->throw_not_implemented;
}


=head2 write_community

 Usage   : $out->write_community($community);
 Function: Write the next community.
 Args    : A Bio::Community object
 Returns : 1 for success

=cut

method write_community (Bio::Community $community) {
   if (not defined $self->_meta) {
      my $meta = Bio::Community::Meta->new;
      $self->_write_metacommunity_init($meta);
      $self->_meta($meta);
   }

   # Write community but skip empty ones if desired
   if ( ($community->get_richness > 0) || (not $self->skip_empty_communities) ) {   
      $self->_write_community_init($community);
      if (not defined $self->_meta->get_community_by_name($community->name)) {
         $self->_meta->add_communities([$community]);
      }
      my $sort_members = $self->sort_members;
      if ($sort_members == 1) {
         my $rank = $community->get_richness;
         while ( my $member = $community->get_member_by_rank($rank) ) {
            $self->_process_member($member, $community);
            $rank--;
            last if $rank == 0;
         }
      } elsif ($sort_members == -1) {
         my $rank = 1;
         while ( my $member = $community->get_member_by_rank($rank) ) {
            $self->_process_member($member, $community);
            $rank++;
         }
      } elsif ($sort_members == 0) {
         while ( my $member = $community->next_member('_write_community_ite') ) {
            $self->_process_member($member, $community);
         }
      } else {
         $self->throw("$sort_members is not a valid sort value.\n");
      }
      $self->_write_community_finish($community);
   }

   if ( ($self->_meta->get_communities_count > 1) && (not $self->multiple_communities) ) {
      $self->throw('Format '.$self->format.' only supports writing one community per file');
   }

   return 1;
}


method _write_community_init (Bio::Community $community) {
   # Driver-side method to initialize writing a community
   $self->throw_not_implemented;
}


method _write_community_finish (Bio::Community $community) {
   # Driver-side method to finalize writing a community
   $self->throw_not_implemented;
}


=head2 write_metacommunity

 Usage   : $out->write_metacommunity($meta);
 Function: Write a metacommunity.
 Args    : A Bio::Community::Meta object
 Returns : 1 for success

=cut

method write_metacommunity (Bio::Community::Meta $meta) {
   if (not defined $self->_meta) {
      $self->_meta($meta);
      $self->_write_metacommunity_init($meta);
      while (my $community = $meta->next_community) {
         $self->write_community($community);
      }
      # _write_metacommunity_finish will happen before close()
   } else {
      $self->throw('Can write only one metacommunity');
   }
   return 1;
}


method _write_metacommunity_init (Bio::Community::Meta $meta) {
   # Driver-side method to initialize writing a metacommunity
   $self->throw_not_implemented;
}


method _write_metacommunity_finish (Bio::Community::Meta $meta) {
   # Driver-side method to finalize writing a metacommunity
   $self->throw_not_implemented;
}


before 'close' => sub {
   my $self = shift;
   if ($self->mode eq 'r') {
      $self->_next_metacommunity_finish();
   } else {
      # Finish preparing the metacommunity for writing
      $self->_write_metacommunity_finish($self->_meta);
      # For objects consuming Bio::Community::Role::Table, write the table now
      if (does_role($self, 'Bio::Community::Role::Table')) {
         $self->_write_table unless $self->_was_written;
      }
   }
   return 1;
};


#method _process_member (Bio::Community::Member $member, Bio::Community $community) {
method _process_member ($member, $community) {
   my $ab_value;
   my $ab_type = $self->abundance_type;
   if ($ab_type eq 'count') {
      $ab_value = $community->get_count($member);
   } elsif ($ab_type eq 'absolute') {
      $ab_value = $community->get_abs_ab($member);
   } elsif ($ab_type eq 'percentage') {
      $ab_value = $community->get_rel_ab($member);
   } elsif ($ab_type eq 'fraction') {
      $ab_value = $community->get_rel_ab($member) / 100;
   } else {
      $self->throw("$ab_value is not a valid abundance type.\n");
   }
   $self->write_member($member, $ab_value);
   return 1;
}


=head2 skip_empty_communities

 Usage   : $in->skip_empty_communities;
 Function: Get or set whether empty communities (with no members) should be
           read/written or skipped.
 Args    : 0 or 1
 Returns : 0 or 1

=cut

has 'skip_empty_communities' => (
   is => 'rw',
   isa => 'Bool',
   required => 0,
   lazy => 1,
   default => 0,
   init_arg => '-skip_empty_communities',
);


=head2 sort_members

 Usage   : $in->sort_members();
 Function: When writing a community to a file, sort the community members based
           on their abundance: 0 (off), 1 (by increasing abundance), -1 (by 
           decreasing abundance). The default is specific to each driver used.
 Args    : 0, 1 or -1
 Returns : 0, 1 or -1

=cut

has 'sort_members' => (
   is => 'ro',
   isa => 'NumericSort',
   required => 0,
   lazy => 1,
   init_arg => '-sort_members',
   default => sub { return eval('$'.ref(shift).'::default_sort_members') || 0  },
);


=head2 abundance_type

 Usage   : $in->abundance_type();
 Function: When writing a community to a file, report member abundance in one
           of four possible representations:
            * count     : observed count
            * absolute  : absolute abundance
            * percentage: relative abundance, in percent (0-100%)
            * fraction  : relative abundance, as a fractional number (0-1)
           The default is specific to each driver
 Args    : count, absolute, percentage or fraction
 Returns : count, absolute, percentage or fraction

=cut

has 'abundance_type' => (
   is => 'ro',
   isa => 'AbundanceRepr',
   required => 0,
   lazy => 1,
   init_arg => '-abundance_type',
   default => sub { return eval('$'.ref(shift).'::default_abundance_type') || 'percentage' },
);


=head2 missing_string

 Usage   : $in->missing_string();
 Function: When writing a community to a file, specify what abundance string to
           use for members that are not present in the community. The default is
           specific to each driver used.
 Args    : string e.g. '', '0', 'n/a', '-'
 Returns : string

=cut

has 'missing_string' => (
   is => 'ro',
   isa => 'Str',
   required => 0,
   lazy => 1,
   init_arg => '-missing_string',
   default => sub { return eval('$'.ref(shift).'::default_missing_string') || 0 },
);


=head2 multiple_communities

 Usage   : $in->multiple_communities();
 Function: Return whether or not the file format can represent multiple
           communities in a single file.
 Args    : 0 or 1
 Returns : 0 or 1

=cut

has 'multiple_communities' => (
   is => 'ro',
   isa => 'Bool',
   required => 0,
   lazy => 1,
   default => sub { return eval('$'.ref(shift).'::multiple_communities') || 0 },
);


=head2 explicit_ids

 Usage   : $in->explicit_ids();
 Function: Return whether or not the file format explicitly records member IDs.
 Args    : 0 or 1
 Returns : 0 or 1

=cut

has 'explicit_ids' => (
   is => 'ro',
   isa => 'Bool',
   required => 0,
   lazy => 1,
   default => sub { return eval('$'.ref(shift).'::explicit_ids') || 0 },
);


=head2 weight_files

 Usage   : $in->weight_files();
 Function: When reading a community, specify files (or filehandles opened in
           read mode) containing weights to assign to the community members.
           Each file can contain a different type of weight to add. The file
           should contain at least two tab-delimited columns: the first one
           should contain the ID, description or string lineage of the member
           and the second one the weight to assign to this member. Other columns
           are ignored. A tab-delimited header line starting with '#' and
           containing the name of the weight can be included.
 Args    : arrayref of file names (or filehandles)
 Returns : arrayref of filehandles

=cut

has 'weight_files' => (
   is => 'rw',
   isa => 'ArrayRefOfReadableFileHandles',
   coerce => 1,
   required => 0,
   lazy => 1,
   default => sub { [] },
   init_arg => '-weight_files',
   trigger => \&_read_weights,
);


has '_weights' => (
   is => 'rw',
   #isa => 'ArrayRef[HashRef[Num]]', # keep internals light
   required => 0,
   lazy => 1,
   default => sub { [] },
   predicate => '_has_weights',
);


has '_file_average_weights' => (
   is => 'rw',
   #isa => 'ArrayRef[Num]', # keep internals light
   required => 0,
   lazy => 1,
   default => sub { [] },
);


=head2 weight_names

 Usage   : $in->weight_names();
 Function: After weight files have been read, you can get the name of the
           weights using this method. You can also set them manually.
 Args    : arrayref of weight names
 Returns : arrayref of weight names

=cut

has 'weight_names' => ( # hashref of Bio::Community::Members, keyed by member ID
   is => 'rw',
   isa => 'ArrayRef[Str]',
   required => 0,
   lazy => 1,
   default => sub { [] },
);


# The member queue contains members that will need to be given proper weights
# and to be added to the community

has '_member_queue' => ( # hashref of Bio::Community::Members, keyed by member ID
   is => 'rw',
   required => 0,
   lazy => 1,
   default => sub { {} },
);

has '_count_queue' => ( # hashref of member counts, keyed by member ID
   is => 'rw',
   required => 0,
   lazy => 1,
   default => sub { {} },
);


method _read_weights ($args) {
   my $all_weights = [];
   my $all_names = [];
   my $file_average_weights = [];
   for my $fh (@{$self->weight_files}) {
      my $average = 0;
      my $num = 0;
      my $file_weights = {};
      my $weight_name;
      while (my $line = <$fh>) {
         if ($line =~ m/^#/) {
            chomp $line;
            my ($col1, $col2) = (split "\t", $line)[0..1];
            if ( (defined $col1) && (defined $col2) && (not defined $weight_name) ) {
               # Process header
               $weight_name = $col2;
               $weight_name =~ s/^weight$//i;
            }
            next;
         }
         next if $line =~ m/^\s*$/;
         chomp $line;
         my ($id, $weight) = (split "\t", $line)[0..1];
         $file_weights->{$id} = $weight;
         $average += $weight;
         $num++;
      }
      $weight_name = '' if not defined $weight_name;
      close $fh;
      push @$all_weights, $file_weights;
      push @$all_names, $weight_name;
      $average /= $num if $num > 0;
      push @$file_average_weights, $average;
   }
   $self->weight_names($all_names);
   $self->_weights( $all_weights );
   $self->_file_average_weights( $file_average_weights );
   return 1;
}


=head2 weight_identifier

 Usage   : $in->weight_identifier('id');
 Function: Get or set whether to lookup and assign weights to community members
           based on the member description or their ID.
 Args    : 'desc' (default), or 'id'
 Returns : 'desc' or 'id'

=cut

has 'weight_identifier' => (
   is => 'rw',
   isa => 'IdentifyMembersByType',
   required => 0,
   lazy => 1,
   default => 'desc',
   init_arg => '-weight_identifier',
);


=head2 weight_assign

 Usage   : $in->weight_assign();
 Function: When using weights, specify what value to assign to the members for
           which no weight is found in the provided weight file:
            * $num : Check the member description against each file of weights.
                 If no weight is found in a file, assign the arbitrary weight
                 provided as argument to the member.
            * file_average : Check the member description against each file of
                 weights. If no weight is found in a file, assign the average
                 weight in this file to the member.
            * community_average : Check the member description against each file
                 of weights. If no weight is found in a file, the weight given
                 to the member is the average weight of all the other members in
                 in this community. If none of the community members have
                 weights, the weight assignment method defaults to 'file_average'
                 for this community. Note that because the assigned weight is
                 the average weight in this community, this means that the same
                 members will have different weights in different communities.
                 Note also that the processing of members with no explicit
                 weights can only be done after all other members have been
                 added and is effective only if the community is built using the
                 next_community() method.
            * ancestor : Provided the member have a taxonomic assignment, check
                 the taxonomic lineage of this member against each file of
                 weights. When no weight is found for this taxonomic lineage in
                 a weight file, go up the taxonomic lineage of the member and
                 assign to it the weight of the first ancestor that has a
                 weight in the weights file. Fall back to the 'community_average'
                 method if no taxonomic information is available for this member
                 (for example a member with no BLAST hit), or if none of the
                 ancestors have a specified weight.
 Args    : 'file_average', 'community_average', 'ancestor' or a number
 Returns : 'file_average', 'community_average', 'ancestor' or a number

=cut

has 'weight_assign' => (
   is => 'rw',
   isa => 'WeightAssignType',
   required => 0,
   lazy => 1,
   default => 'file_average',
   init_arg => '-weight_assign',
);


=head2 _attach_weights

 Usage   : $in->_attach_weights($member);
 Function: Once a member has been created, a driver should call this method
           to attach the proper weights (read from the user-provided weight
           files) to a member. If no member is provided, this method will not
           complain and will do nothing.
 Args    : a Bio::Community::Member or nothing
 Returns : 1 for success

=cut

method _attach_weights (Maybe[Bio::Community::Member] $member) {
   # Once we have a member, attach weights to it
   if ( defined($member) && $self->_has_weights ) {

      my $weights;
      my $assign_method = $self->weight_assign;
      my $weight_names = $self->weight_names;
      for my $i (0 .. scalar @{$self->_weights} - 1) {
         my $weight;
         my $weight_type = $self->_weights->[$i];

         if ($assign_method eq 'ancestor') {
            my $taxon = $member->taxon;
            if (defined $taxon) {
               # Method based on member taxonomic lineage
               my $lineage_arr = get_taxon_lineage($taxon);
               my $lineage;
               do {
                  $lineage = get_lineage_string(clean_lineage_arr($lineage_arr));
                  $weight = $weight_type->{$lineage};
                  if ( (not defined $weight) && ($lineage =~ s/ //g) ) {
                     # If no weight found, try lineage again without white spaces
                     $weight = $weight_type->{$lineage};
                  }
                  if (defined $weight) {
                     # Weight found. Get ready to exit loop.
                     my $weight_name = $weight_names->[$i] || 'weight number '.($i+1);
                     $self->debug("Member '".get_lineage_string(get_taxon_lineage($taxon)).
                        "' (ID ".$member->id.") got $weight_name from ".$lineage_arr->[-1]->node_name.
                        ": $weight\n");
                     @$lineage_arr = ();
                  }
              } while ( pop @$lineage_arr );
            }
            if (not defined $weight) {
               # Use the 'community_average' assignment method:
               # Correct weight will be assigned when community is 100% created
               $weight = 0;
               $self->_member_queue->{$member->id}->{$i} = $member;
            }

         } else {

            # Methods based on member description (or ID)
            my $lookup = $self->weight_identifier eq 'desc' ? $member->desc : $member->id;
            if ( defined($lookup) && exists($weight_type->{$lookup}) ) {
               # This member has a weight
               $weight = $weight_type->{$lookup};
            } else {
               # This member has no weight, provide an alternative weight
               if ($assign_method eq 'file_average') {
                  # Use the average weight in the weight file
                  $weight = $self->_file_average_weights->[$i];
               } elsif ($assign_method eq 'community_average') {
                  # Proper weight will be assigned when community is 100% created
                  $weight = 0;
                  $self->_member_queue->{$member->id}->{$i} = $member;
               } else {
                  # Use an arbitrary weight
                  $weight = $assign_method;
               }
            }

         }

         push @$weights, $weight;
      }

      $member->weights($weights);
   }

   return 1;
}


method _process_member_queue ($community) {
   # Now is the time to add the community average weight to members that lack
   # weight, and to add the members themselves to the community

   my $counts  = $self->_count_queue;
   my $members = $self->_member_queue;

   # Calculate average weights in community
   my $community_average_weights = $community->_calc_average_weights();

   # Default to file-average weight if needed
   for my $i (0 .. scalar @{$self->_weights} - 1) {
      if (not defined $community_average_weights->[$i]) {
         $community_average_weights->[$i] = $self->_file_average_weights->[$i];
      }
   }

   # Assign average weight to members that need it
   my $weight_names = $self->weight_names;
   while ( my ($id, $count) = each %$counts) {
      # Clone member
      my $trait_num = (keys %{$members->{$id}})[0];
      my $member = $members->{$id}->{$trait_num}->clone;
      my $member_weights = $member->weights;
      # Update member weights
      for my $i (0 .. scalar @{$self->_weights} - 1) {
         my $weight_name = $weight_names->[$i] || 'weight number '.($i+1);
         if ( $member_weights->[$i] == 0 ) {
            $member_weights->[$i] = $community_average_weights->[$i];
            $self->debug("Member '".$member->desc."' (ID ".$member->id.") got ".
               "average $weight_name from community '".$community->name."': ".
               $community_average_weights->[$i]."\n");
         }
      }
      # Add member to community
      $community->add_member($member, $count);
   }

   # If multiple weights, update averages now
   if ( scalar @{$self->_weights} > 1 ) {
      $community_average_weights = $community->_calc_average_weights();
   }

   $community->_set_average_weights($community_average_weights);

   return 1;
}


=head2 taxonomy

 Usage   : $in->taxonomy();
 Function: When reading communities, try to place the community members on the
           provided taxonomy (provided taxonomic assignments are specified in
           the input. Make sure that you use the same taxonomy as in the
           community file to ensure that members are placed.
           
           As an alternative to using a full-fledged taxonomy, if you provide a
           Bio::DB::Taxonomy::list object containing no taxa, the taxonomy will
           be constructed on the fly from the taxonomic information provided in
           the community file. The advantages are that you build an arbitrary
           taxonomy, and this taxonomy contains only the taxa present in your
           samples, which is fast and memory efficient. A drawback is that
           unfortunately, you can only do this with community file formats that
           report full lineages (e.g. the qiime and generic formats).

           A basic curation is done on the taxonomy strings, so that a GreenGenes
           lineage such as:
              k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__
           becomes:
              k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II
           Or a Silva lineage such as:
              Bacteria; Cyanobacteria; Chloroplast; uncultured; Other; Other
           becomes:
              Bacteria; Cyanobacteria; Chloroplast; uncultured

 Args    : Bio::DB::Taxonomy
 Returns : Bio::DB::Taxonomy

=cut

has 'taxonomy' => (
   is => 'rw',
   isa => 'Maybe[Bio::DB::Taxonomy]',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-taxonomy',
   trigger => \&_is_taxonomy_empty,
);


has '_onthefly_taxonomy' => (
   is => 'rw',
   #isa => 'Bool', # keep internals light
   required => 0,
   lazy => 1,
   default => 0,
);


method _is_taxonomy_empty ($taxonomy) {
   # If taxonomy object is a Bio::DB::Taxonomy and contains no taxa, mark that
   # we'll need to build the taxonomy on the fly
   if ( (ref $taxonomy eq 'Bio::DB::Taxonomy::list') && ($taxonomy->get_num_taxa == 0) ) {
      $self->_onthefly_taxonomy(1);
   }
   return 1;
}


=head2 _attach_taxon

 Usage   : $in->_attach_taxon($member, $taxonomy_string);
 Function: Once a member has been created, a driver should call this method
           to attach the proper taxon object to the member. If no member is
           provided, this method will not complain and will do nothing.
 Args    : * a Bio::Community::Member or nothing
           * the taxonomic string
           * whether the taxonomic string is a taxon name (1) or taxon ID (0)
 Returns : 1 for success

=cut

method _attach_taxon (Maybe[Bio::Community::Member] $member, $taxo_str, $is_name) {
   # Given a Bio::DB::Taxonomy::list with no taxa, build a taxonomy on the fly
   # with the provided member. Regardless of the given taxonomy object, place 
   # the member place the member in the taxonomy. The taxonomy is defined by
   # $taxo_str. If $is_name is 0, $taxo_str is used as a taxon ID. If $is_name
   # is 1, $taxo_str should be a taxon name. See _get_lineage_arr();
   my $taxonomy = $self->taxonomy;
   if ( defined($member) && defined($taxonomy) ) {

      # First do some lineage curation
      my @names;
      if ($is_name) {
         @names = @{split_lineage_string($taxo_str)};
      }

      # Then add lineage to taxonomy if desired
      if ( $self->_onthefly_taxonomy && scalar @names > 0 ) {
         # Adding the same lineage multiple times is not an issue...
         $taxonomy->add_lineage( -names => \@names );
      }

      # Then find where the member belong in the taxonomy
      my $taxon;
      if ($is_name) {
         # By taxon name
         if (scalar @names > 0) {
            $taxon = $self->taxonomy->get_taxon( -names => \@names );
         }# else {
         #   $self->warn("Could not place '$taxo_str' in the given taxonomy");
         #}
      } else {
         # By taxon ID
         $taxon = $self->taxonomy->get_taxon( -taxonid => $taxo_str );
      }

      # Finally, if member could be placed, update its taxon information
      if ($taxon) {
         $member->taxon($taxon);
      }
   }
   return 1;
}


# Do not inline so that new() can be overridden
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
