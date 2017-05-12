package Cache::Range;

use strict;
use warnings;

use Tree::R;
use Storable qw(freeze thaw);

use namespace::clean;

our $VERSION = '0.01';

sub new {
    my ( $class, $cache ) = @_;
    
    return bless \$cache, $class;
}

sub set {
    my $self  = shift;
    my $key   = shift;
    my $start = shift;
    my $data  = shift;
    my $cache = $$self;
    my $end   = $start + $#$data;

    $cache->set(join('_', $key, $start, $end), freeze($data), @_);
    $data = {
        end   => $end,
        start => $start,
    };
    my $rtree = $cache->get($key . '_rtree');
    if($rtree) {
        $rtree = thaw($rtree);
    } else {
        $rtree = Tree::R->new;
    }
    $rtree->insert($data, $start, 0, $end, 0);
    $cache->set($key . '_rtree', freeze($rtree), $Cache::EXPIRES_NEVER);
}

sub get {
    my ( $self, $key, $start, $end ) = @_;

    my $cache = $$self;
    my $rtree = $cache->get($key . '_rtree');
    my $dirty = 0;

    return unless $rtree;
    $rtree = thaw($rtree);

    my @results;
    my @retval;
    $rtree->query_partly_within_rect($start, 0, $end, 0, \@results);
    @results = sort { $a->{'start'} <=> $b->{'start'} } @results;

    foreach my $entry (@results) {
        my ( $e, $s ) = @{$entry}{qw/end start/};
        my $data = $cache->get(join('_', $key, $s, $e));

        unless($data) {
            $rtree->remove($entry);
            $dirty = 1;
            next;
        }
        $data = thaw($data);

        $data = [ @$data ];

        if($s < $start) {
            splice @$data, 0, $start - $s;
            $s = $start;
        }
        if($e > $end) {
            splice @$data, $end - $e;
        }

        push @retval, $s, $data;
    }
    if($dirty) {
        $cache->set($key . '_rtree', freeze($rtree), $Cache::EXPIRES_NEVER);
    }
    return @retval;
}

1;

__END__

=head1 NAME

Cache::Range - Caches entries that are associated with an interval in a dataset

=head1 VERSION

0.01

=head1 SYNOPSIS

  use Cache::Range;

  my $cache  = Cache::Memory->new; # or any other Cache impl
  my $rcache = Cache::Range->new($cache);
  my $rows = [ 0..99 ];
  $rcache->set($key, 0, $rows, '5 minutes'); # the end of the range is taken
                                             # from the length of the value
  $rcache->set($key, 110, $rows, '5 minutes');
  my @entries = $rcache->get($key, 50, 90);

  for(my $i = 0; $i < @entries; $i += 2) {
    my ( $start, $data ) = @entries[$i, $i + 1];
    # $start will be 50 here, and $data will contain
    # rows 50-90
  }


=head1 DESCRIPTION

This utility module builds off of a cache implementation to store data that
are associated with an interval.  For example, say you're querying a database
for ranges of entries, and one query fetches the first one hundred rows.
If on your next query you want rows twenty five through fifty back, the
cache will give them to you, because those rows are contained within an
interval you've already stored.

=head1 METHODS

=head2 Cache::Range->new($cache)

Creates a new Cache::Range object, which stores its entries in C<$cache>.

=head2 $rcache->set($key, $start, $value, $expiry)

Stores entries under C<$key> which correspond to the interval C<$start> - C<scalar(@$value) - 1>,
with an optional expiry time.  NOTE: Because this module stores some internal state in the
cache itself, I wouldn't recommend messing around with any cache entries prefixed by C<$key>.

=head2 $rcache->get($key, $start, $end)

Returns a list of pairs; each pair is a previously cached entry that overlaps
the requested region.  The first member of the pair is the start of the
interval, and the second is the data associated with that interval.

=head1 AUTHOR

Rob Hoelz, C<< rhoelz at inoc.com >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Cache-Range at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cache-Range>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Rob Hoelz.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Cache>

=cut
