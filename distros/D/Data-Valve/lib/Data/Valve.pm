# $Id: /mirror/coderepos/lang/perl/Data-Valve/trunk/lib/Data/Valve.pm 87019 2008-10-02T02:11:03.080140Z daisuke  $

package Data::Valve;
use Moose;
use Data::Valve::Bucket;
use Scalar::Util ();

use XSLoader;
our $VERSION   = '0.00010';
our $AUTHORITY = 'cpan:DMAKI';

XSLoader::load __PACKAGE__, $VERSION;

has 'max_items' => (
    is => 'rw',
    isa => 'Int',
    required => 1
);

has 'interval' => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

has 'strict_interval' => (
    is => 'rw',
    isa => 'Bool',
    required => 1,
    default => 0
);

has '__bucket_store' => (
    accessor => 'bucket_store',
    is => 'rw',
    does => 'Data::Valve::BucketStore',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub BUILDARGS {
    my ($self, %args) = @_;

    my $store = delete $args{bucket_store} || { module => 'Memory' };
    if (! Scalar::Util::blessed($store) ) {
        my $module = $store->{module};
        if ($module !~ s/^\+//) {
            $module = "Data::Valve::BucketStore::$module";
        }
        Class::MOP::load_class($module);

        $store = $module->new( %{ $store->{args} } );
    }

    if ($args{strict_interval}) {
        # in strict_interval mode, max_items doesn't mean anything
        $args{max_items} = 0;
    }

    return { %args, __bucket_store => $store };
}

sub BUILD {
    my $self = shift;
    $self->bucket_store->context($self);
}

sub try_push {
    my ($self, %args) = @_;
    $args{key} ||= '__default';
    $self->bucket_store->try_push(%args);
}

sub reset {
    my ($self, %args) = @_;
    $args{key} ||= '__default';
    $self->bucket_store->reset(%args);
}

sub fill {
    my ($self, %args) = @_;
    $args{key} ||= '__default';
    $self->bucket_store->fill(%args);
}

1;

__END__

=head1 NAME

Data::Valve - Throttle Your Data

=head1 SYNOPSIS

  use Data::Valve;

  my $valve = Data::Valve->new(
    max_items => 10,
    interval  => 30
  );

  if ($valve->try_push()) {
    print "ok\n";
  } else {
    print "throttled\n";
  }

  if ($valve->try_push(key => "foo")) {
    print "ok\n";
  } else {
    print "throttled\n";
  }

=head1 DESCRIPTION

Data::Valve is a throttler based on Data::Throttler. The underlying throttling
mechanism is much simpler than Data::Throttler, and so is faster.

It also comes with Memcached support for a distributed throttling via
memcached + keyedmutexd. This means that you can have multiple hosts throttling
on the same "key". For example, multiple crawler instances can throttle 
requests against a single host safely. To enable distributed throttling,
you simply need to specify a Data::Valve::BucketStore instance that supports
distribution (i.e. Data::Valve::BucketStore::Memcached) or create your own
instance, and pass it to the constructor:

  Data::Valve->new(
    ...,
    bucket_store => {
      module => "Memcached", # to use Data::Valve::BucketStore::Memcached
      args   => {
        servers => [ '127.0.0.1:11211' ]
      }
    }
  );

Please note that for distributed throttling to work, you must specify the
correct values in max_items, interval, and so forth, for each Data::Valve
instance. Data::Valve will not try to automatically adjust this for you.
You must coordinate it in the client side (i.e., whatever that's using
Data::Valve)

Since version 0.00006, Data::Valve supports "strict_interval" mode, where
instead of counting the number of items over a range of time, it simply
calculates the amount of time elapsed since the last logged request.

To enable, specify it in the constrctor:

  # This specifies that at least 5 seconds should have passed before
  # the next item can go
  Data::Valve->new(
    interval        => 5,
    strict_interval => 1, 
  );

=head1 METHODS

=head2 new(%args)

=over 4

=item max_items

In strict interval mode, does not mean anything. If NOT in strict interval
mode, specifies the max number of items that can go through this throttler
in the given interval.

=item interval

In strict interval mode, this specifies the number of seconds to wait between
each request. If NOT in strict interval mode, specifies the number of seconds
to span the requests, up to the value specified in max_items

C<interval> may be a fractional number, denoting fractional seconds.

=item strict_interval

Boolean. Enable/Disable strict interval mode. Default is off.

=back

=head2 fill([key => $key_name])

Fills up the specified bucket until it starts throttling

=head2 reset([key => $key_name])

Clears the specified bucket so the next request will succeed for sure

=head2 try_push([key => $key_name])

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut