# BioPerl module for Bio::Community::IO::Driver::generic
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::IO::Driver::generic - Driver to read and write files in a generic tab-delimited site-by-species table format

=head1 SYNOPSIS

   my $in = Bio::Community::IO->new( -file => 'gaas_communities.txt', -format => 'generic' );

   # See Bio::Community::IO for more information

=head1 DESCRIPTION

This Bio::Community::IO::Driver::generic driver reads and writes files in a generic
format. Multiple communities can be written in a file to generate a site-by-
species table (OTU table), in which the entries are tab-delimited. Example:

  Species	site A	site B
  species 1	321	94
  species 2	0	58
  species 3	47	26

For each Bio::Community::Member $member generated from a generic site-by-species
file, $member->desc() contains the content of the species field. Since the
generic format does not specify a member ID, one is automatically generated
and can be retrieved using $member->id().

=head1 CONSTRUCTOR

See L<Bio::Community::IO>.

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

=cut


package Bio::Community::IO::Driver::generic;

use Moose;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::Member;

extends 'Bio::Community::IO';
with 'Bio::Community::Role::IO',
     'Bio::Community::Role::Table';


our $multiple_communities   =  1;      # format supports several communities per file
our $explicit_ids           =  0;      # IDs are not explicitly recorded
#### sorting only effective for first community???
our $default_sort_members   =  0;      # unsorted
our $default_abundance_type = 'count'; # absolute count (positive integer)
our $default_missing_string =  0;      # empty members get a '0'


has '_line' => (
   is => 'rw',
   isa => 'PositiveInt',
   required => 0,
   init_arg => undef,
   default => 1,
   lazy => 1,
);


has '_col' => (
   is => 'rw',
   isa => 'PositiveInt',
   required => 0,
   init_arg => undef,
   default => 1,
   lazy => 1,
);


has '_members' => (
   is => 'rw',
   isa => 'ArrayRef', # ArrayRef[Bio::Community::Member] but keep it lean
   required => 0,
   init_arg => undef,
   default => sub { [] },
   lazy => 1,
   predicate => '_has_members',
);


has '_id2line' => (
   is => 'rw',
   isa => 'HashRef', # HashRef[String] but keep it lean
   required => 0,
   init_arg => undef,
   default => sub { {} },
   lazy => 1,
);


has '_write_desc' => (
   is => 'rw',
   isa => 'Bool',
   required => 0,
   init_arg => undef,
   default => undef,
   lazy => 1,
   predicate => '_has_write_desc',
);


method _generate_members () {
   # Make members from the first column
   my @members;
   my $col = 1;
   for my $line (2 .. $self->_get_max_line) {
      my $value = $self->_get_value($line, $col);
      my $member = Bio::Community::Member->new( -desc => $value );
      $self->_attach_taxon($member, $value, 1);
      $self->_attach_weights($member);
      push @members, $member;
   }
   $self->_members(\@members);
}


method next_member () {
   my ($member, $count);
   my $line = $self->_line;
   while ( $line++ ) {
      # Get the abundance of the member (undef if out-of-bounds)
      $count = $self->_get_value($line, $self->_col);
      # No more members for this community.
      last if not defined $count;
      # Skip members with no abundance
      next if not $count;  # e.g. ''
      next if $count == 0; # e.g. 0.0
      # Get the member itself
      $member = $self->_members->[$line - 2];
      $self->_line($line);
      last;
   }
   return $member, $count;
}


method _next_community_init () {
   # Go to start of next column and return name of new community.
   my $col  = $self->_col + 1;
   my $line = 1;
   my $name = $self->_get_value($line, $col);
   $self->_col( $col );
   $self->_line( $line );
   return $name;
}


method _next_community_finish () {
   return 1;
}


method _next_metacommunity_init () {
   $self->_generate_members();
   my $name = ''; # no provision for metacommunity name in this format
   return $name;
}


method _next_metacommunity_finish () {
   return 1;
}


method write_member (Bio::Community::Member $member, Count $count) {
   my $id   = $member->id;
   my $line = $self->_id2line->{$id};
   if (not defined $line) {
      # Determine whether to write desc or id for all members
      if (not $self->_has_write_desc) {
         if ( (defined $member->desc) && (not $member->desc eq '') ) {
            $self->_write_desc(1);
         } else {
            $self->_write_desc(0);
         }
      }
      # This member has not been written previously for another community
      $line = $self->_get_max_line + 1;
      $self->_set_value( $line, 1, $self->_write_desc ? $member->desc : $member->id );
      $self->_id2line->{$id} = $line;
   }
   $self->_set_value($line, $self->_col, $count);
   $self->_line( $line + 1 );
   return 1;
}


method _write_community_init (Bio::Community $community) {
   # Write header for that community
   my $col  = $self->_col + 1;
   my $line = 1;
   $self->_set_value($line, $col, $community->name);
   $self->_line( $line + 1);
   $self->_col( $col );
   return 1;
}


method _write_headers () {
   $self->_set_value(1, 1, 'Species');
}


method _write_community_finish (Bio::Community $community) {
   return 1;
}


method _write_metacommunity_init (Bio::Community::Meta $meta) {
   $self->_write_headers; # write first column header
   return 1;
}


method _write_metacommunity_finish (Bio::Community::Meta $meta) {
   return 1;
}



__PACKAGE__->meta->make_immutable;

1;
