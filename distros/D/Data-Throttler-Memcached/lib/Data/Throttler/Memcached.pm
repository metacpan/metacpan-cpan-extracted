# $Id: /mirror/perl/Data-Throttler-Memcached/trunk/lib/Data/Throttler/Memcached.pm 8774 2007-11-08T09:43:20.728908Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.
package Data::Throttler::Memcached;
use strict;
use warnings;
use base qw(Data::Throttler);
use Data::Throttler::BucketChain::Memcached;

our $VERSION = '0.00003';

sub new
{
    my $class = shift;
    my %args  = @_;
    my $empty = sub {};
    my $self  = bless {
        lock   => $empty,
        unlock => $empty,
        db     => { chain => {} }
    }, $class;

    $self->{lock}->();
    $self->{db}->{chain} = Data::Throttler::BucketChain::Memcached->new(
        max_items => $args{max_items},
        interval  => $args{interval},
        cache     => $args{cache}
    );
    $self->{unlock}->();

    return $self;
}

1;

__END__

=head1 NAME

Data::Throttler::Memcached - Memcached-Based Data::Throttler

=head1 SYNOPSIS

  my $t = Data::Throttler::Memcached->new(
    max_items => 10,
    interval  => 60,
    cache     => {
      data  => '127.0.0.1:11211', # optional
    }
  );
  
  $t->try_push( 'foo' );
  $t->try_push( key => 'foo' );

=head1 DESCRIPTION

Data::Throttler does a good job throttling data for you, but unfortunately
it's not distributed -- that is, since the storage is in memory, if you have
a system with multiple hosts, throttling will be done individually on each 
host.

To workaround this limitation, Data::Throttler::Memcached uses 
Cache::Memcached::Managed to store the actual data.

=head1 CAVEATS

There's no locking mechanism when checking/incrementing counts. This means
that each process could possibly overwrite another's value -- but since
throttling is something that isn't "exact", I'm not considering this to be
such a big issue.

We may in the future work around this problem by utilizing distributed locks
like KeyedMutex. Patches welcome.

=head1 METHODS

=head2 new

Creates a new instance of Data::Throttler::Memcached.
Accepts the same arguments as Data::Throttler, plus the "cache" argument.

The cache argument must be a hashref, which contains the arguments passed
to the cache backend. For example, if you wanted to change the data server,
you can specify it like so:

  cache => {
    data => 'my.data.host:11211'
  }

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut