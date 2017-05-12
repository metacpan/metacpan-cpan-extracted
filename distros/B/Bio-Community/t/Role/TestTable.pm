package t::Role::TestTable;

use Moose;
use Method::Signatures;

extends 'Bio::Community::IO';
with 'Bio::Community::Role::Table';

# This is simply a test module that consumes the Table role.

#method _next_metacommunity_init () {
#   my $name = 'dummy community';
#   return $name;
#}

#method _next_community_init () {
#   my $name = 'dummy community';
#   return $name;
#}

#method next_member () {
#   my ($member, $count);
#   # Somehow read and create a member here...
#   $self->_attach_weights($member);
#   return $member, $count;
#}

#method _next_community_finish () {
#   return 1;
#}

method _next_metacommunity_finish () {
   return 1;
}

#method _write_metacommunity_init (Bio::Community::Meta $meta?) {
#   return 1;
#}

#method _write_community_init (Bio::Community $community) {
#   return 1;
#}

#method write_member (Bio::Community::Member $member, Count $count) {
#   return 1;
#}

#method _write_community_finish (Bio::Community $community) {
#   return 1;
#}

method _write_metacommunity_finish (Maybe[Bio::Community::Meta] $meta?) {
   return 1;
}


__PACKAGE__->meta->make_immutable;

1;
