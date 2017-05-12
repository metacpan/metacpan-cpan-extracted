package Data::Range::Compare::Stream::Sort;

use strict;
use warnings;
use Exporter;
our @ISA=qw(Exporter);
our @EXPORT=qw(
  sort_in_presentation_order
  sort_in_consolidate_order_asc
  sort_in_consolidate_order_desc
  sort_largest_range_end_first
  sort_smallest_range_start_first
  sort_smallest_range_end_first
  sort_largest_range_start_first

);

sub sort_in_presentation_order ($$) {
  my ($cmp_a,$cmp_b)=@_;
  $cmp_a->cmp_ranges($cmp_b);
}

sub sort_in_consolidate_order_asc ($$) {
  my ($range_a,$range_b)=@_;
  $range_a->cmp_range_start($range_b)
    ||
  $range_b->cmp_range_end($range_a);
}

sub sort_in_consolidate_order_desc($$) {
  my ($range_a,$range_b)=@_;
  $range_b->cmp_range_end($range_a)
    ||
  $range_a->cmp_range_start($range_b);
}

sub sort_largest_range_end_first ($$) {
  my ($range_a,$range_b)=@_;
  $range_b->cmp_range_end($range_a)
}

sub sort_smallest_range_start_first ($$) {
  my ($range_a,$range_b)=@_;
  $range_a->cmp_range_start($range_b)
}

sub sort_smallest_range_end_first ($$) {
  my ($range_a,$range_b)=@_;
  $range_a->cmp_range_end($range_b)

}

sub sort_largest_range_start_first ($$) {
  my ($range_a,$range_b)=@_;
  $range_b->cmp_range_start($range_a)
}

1;
