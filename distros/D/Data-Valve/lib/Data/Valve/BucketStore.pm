# $Id: /mirror/coderepos/lang/perl/Data-Valve/trunk/lib/Data/Valve/BucketStore.pm 66567 2008-07-22T08:55:23.819173Z daisuke  $

package Data::Valve::BucketStore;
use Moose::Role;

requires qw(try_push fill reset);

has 'context' => (
    is       => 'rw',
    isa      => 'Data::Valve',
    handles  => [ qw(max_items interval strict_interval) ],
);

no Moose;

1;

__END__

=head1 NAME

Data::Valve::BucketStore - Manage Buckets

=head1 METHODS

=head2 setup

=cut