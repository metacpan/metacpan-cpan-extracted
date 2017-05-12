# $Id: /mirror/perl/Data-Throttler-Memcached/trunk/lib/Data/Throttler/BucketChain/Memcached.pm 8774 2007-11-08T09:43:20.728908Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Data::Throttler::BucketChain::Memcached;
use strict;
use warnings;
use base qw(Class::Accessor::Fast Data::Throttler::BucketChain);
use Cache::Memcached::Managed;
use Log::Log4perl qw(:easy);

__PACKAGE__->mk_accessors($_) for qw(id max_items interval cache);
__PACKAGE__->mk_accessors($_) for qw(buckets bucket_time_span nof_buckets );

sub new
{
    my $class = shift;
    my %args  = @_;

    my $self = bless {
        max_items   => delete $args{max_items},
        interval    => delete $args{interval},
        nof_buckets => delete $args{nof_buckets},
        id          => delete $args{id} || do {
            no warnings;
            require Digest::MD5;
            Digest::MD5::md5_hex($$, time(), rand(), {})
        }
    }, $class;

    my $cache = Cache::Memcached::Managed->new(
        # defaults
        data      => '127.0.0.1:11211',
        namespace => $class,
        # user-specified
        %{ $args{cache} || {} },
        # overrides
        expiration => $self->interval * 2
    );
    $self->cache( $cache );

    if(!$self->max_items or !$self->interval) {
        LOGDIE "Both max_items and interval need to be defined";
    }

    if(!$self->nof_buckets) {
        $self->nof_buckets(10);
    }

    if($self->nof_buckets > $self->interval) {
        $self->nof_buckets( $self->interval );
    }

    $self->reset();
    return $self;
}

sub reset
{
    my $self = shift;

    $self->cache->delete_group( group => $self->id );
    $self->buckets([]);

    my $bucket_time_span = int ($self->interval / $self->nof_buckets);
    $self->bucket_time_span( $bucket_time_span );

    my $time_start = time() - ($self->nof_buckets - 1) * $bucket_time_span;

    for(1..$self->nof_buckets) {
        my $time_end = $time_start + $bucket_time_span - 1;
        DEBUG "Creating bucket ", _hms($time_start), " - ", _hms($time_end);
        push @{$self->{buckets}}, { 
            time  => Data::Throttler::Range->new($time_start, $time_end),
            id    => join('.', $self->id, $time_start, $time_end),
            count => {},
        };
        $time_start = $time_end + 1;
    }

    $self->{head_bucket_idx} = 0;
    $self->{tail_bucket_idx} = $#{$self->{buckets}};
}

sub as_string
{
    my($self) = @_;

    warn "as_string for Data::Throttler::Memcached is currently unimplemented";
}

sub _hms {
    my($time) = @_;

    my ($sec,$min,$hour) = localtime($time);
    return sprintf "%02d:%02d:%02d", 
           $hour, $min, $sec;
}

sub bucket_add
{
    my($self, $time) = @_;

      # ... and append a new one at the end
    my $time_start = $self->{buckets}->
                      [$self->{tail_bucket_idx}]->{time}->max + 1;
    my $time_end   = $time_start + $self->{bucket_time_span} - 1;

    DEBUG "Adding bucket: ", _hms($time_start), " - ", _hms($time_end);

    $self->{tail_bucket_idx}++;
    $self->{tail_bucket_idx} = 0 if $self->{tail_bucket_idx} >
                                    $#{$self->{buckets}};
    $self->{head_bucket_idx}++;
    $self->{head_bucket_idx} = 0 if $self->{head_bucket_idx} >
                                    $#{$self->{buckets}};

    $self->{buckets}->[ $self->{tail_bucket_idx} ] = { 
          time  => Data::Throttler::Range->new($time_start, $time_end),
          id    => join('.', $self->id, $time_start, $time_end),
          count => {},
    };
}

sub try_push
{
    my($self, %options) = @_;

    my $key = "_default";
    $key = $options{key} if defined $options{key};

    my $time = time();
    $time = $options{time} if defined $options{time};

    my $count = 1;
    $count = $options{count} if defined $options{count};

    DEBUG "Trying to push $key ", _hms($time), " $count";

    my $b = $self->bucket_find($time);

    if(!$b) {
       $self->rotate($time);
       $b = $self->bucket_find($time);
    }

    # Determine the total count for this key
    my %count = %{ $self->cache->get_multi(
        id  => [ map { [ $key, $_->{id} ] } @{ $self->buckets } ],
        key => 'count'
    ) };
    my $val = 0;
    $val += $_ for values %count;


    if($val >= $self->{max_items}) {
        DEBUG "Not increasing counter $key by $count (already at max $val|$self->{max_items})";
        return 0;
    } else {
        DEBUG "Increasing counter $key by $count ",
              "($val|$self->{max_items})";
        $self->cache->incr(
            value => 1,
            id    => [ $key, $b->{id} ],
            key   => 'count'
        );
        return 1;
    }

    LOGDIE "Time $time is outside of bucket range\n", $self->as_string;
    return undef;
}

1;

__END__

=head1 NAME

Data::Throttler::BucketChain::Memcached - Backend Store for Data::Throttler::Memcached

=head1 SYNOPSIS

  # Internal use only

=head1 METHODS

=head2 new 

=head2 try_push

=head2 as_string

=head2 bucket_add

=head2 reset

=cut