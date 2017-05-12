# BioPerl module for Bio::Community::IO::Driver::dummy
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::IO::Driver::dummy - Dummy driver (does nothing)

=head1 SYNOPSIS

   my $in = Bio::Community::IO->new( -file => 'dummy_communities.txt', -format => 'dummy' );

   # See Bio::Community::IO for more information

=head1 DESCRIPTION

This module does nothing useful. Its sole purpose is to demonstrate the basic
way to create a driver for Bio::Community::IO.

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


package Bio::Community::IO::Driver::dummy;

use Moose;
use namespace::autoclean;
use Method::Signatures;

extends 'Bio::Community::IO';
with 'Bio::Community::Role::IO';


our $multiple_communities   =  0;      # the format supports one community per file
our $default_sort_members   =  0;      # members not sorted by abundance
our $default_abundance      = 'count'; # report raw counts
our $default_missing_string = '-';     # empty members represented as '-'
our $explicit_ids           =  0;      # IDs are not explicitly recorded


has 'dummy' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   init_arg => undef,
);


# The methods that must be implemented by a driver are:
# For reading:
#    _next_metacommunity_init(), _next_community_init(), next_member(), _next_community_finish(), _next_metacommunity_finish()
# For writing:
#    _write_metacommunity_init(), _write_community_init(), write_member(), _write_community_finish(), write_metacommunity_finish()


method _next_metacommunity_init () {
   my $name = 'dummy community';
   return $name;
}

method _next_community_init () {
   my $name = 'dummy community';
   return $name;
}

method next_member () {
   my ($member, $count);
   # Somehow read and create a member here...
   $self->_attach_weights($member);
   return $member, $count;
}

method _next_community_finish () {
   return 1;
}

method _next_metacommunity_finish () {
   return 1;
}


method _write_metacommunity_init (Bio::Community::Meta $meta) {
   return 1;
}

method _write_community_init (Bio::Community $community) {
   return 1;
}

method write_member (Bio::Community::Member $member, Count $count) {
   return 1;
}

method _write_community_finish (Bio::Community $community) {
   return 1;
}

method _write_metacommunity_finish (Bio::Community::Meta $meta) {
   return 1;
}

__PACKAGE__->meta->make_immutable;

1;
