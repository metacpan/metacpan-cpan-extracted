package Cache::Profile; # git description: v0.05-2-gd123baf
# ABSTRACT: Measure the performance of a cache

our $VERSION = '0.06';

use Moose;
use Carp;
use Time::HiRes 1.84 qw(tv_interval gettimeofday time clock);
use Try::Tiny;
use Class::MOP;
use namespace::autoclean;

has cache => (
    isa => "Object",
    is  => "ro",
    required => 1,
);

sub AUTOLOAD {
    my $self = shift;

    my ( $method ) = ( our $AUTOLOAD =~ /([^:]+)$/ );

    $self->cache->$method(@_);
}

sub isa {
    my ( $self, $class ) = @_;

    $self->SUPER::isa($class) or $self->cache->isa($class);
}

my @timer_names = qw(hit get set miss);

sub timer_names { @timer_names }

foreach my $method ( "all", @timer_names ) {
    my $count = "call_count_$method";

    has $count => (
        traits => [qw(Counter)],
        isa => "Num",
        is  => "ro",
        default => sub { 0 },
        handles => {
            "_inc_call_count_$method" => "inc",
            "reset_call_count_$method" => [ set => 0 ],
        },
    );

    foreach my $measure ( qw(real cpu) )  {
        my $time = "total_${measure}_time_${method}";
        has $time => (
            traits => [qw(Number)],
            isa => "Num",
            is  => "ro",
            default => sub { 0 },
            handles => {
                "_add_${method}_${measure}"  => "add",
                "reset_${method}_${measure}" => [ set => 0 ],
            },
        );

        __PACKAGE__->meta->add_method( "average_${method}_time_${measure}" => sub {
            my $self = shift;

            try { $self->$time / $self->$count } # undef if no count;
        });

        __PACKAGE__->meta->add_method( "${method}_call_rate" => sub {
            my $self = shift;

            try { $self->$count / $self->$time } # undef if no time;
        });
    }
}

foreach my $counter ( qw(hit_count miss_count) ) {
    has $counter => (
        traits => [qw(Number)],
        isa => "Int",
        is  => "ro",
        default => sub { 0 },
        handles => {
            "_add_$counter"  => "add",
            "_inc_$counter"  => [ add => 1 ],
            "reset_$counter" => [ set => 0 ],
        },
    );
}

sub miss_rate {
    my $self = shift;

    try { $self->miss_count / $self->query_count };
}

sub hit_rate {
    my $self = shift;

    try { $self->hit_count / $self->query_count };
}

# query count is individual keys
sub query_count {
    my $self = shift;

    my $hit = $self->hit_count;
    my $miss = $self->miss_count;

    return unless defined($hit) and defined($miss);

    return $hit+$miss;
}

sub hit { shift->_trace( hit => @_ ) }
sub set { shift->_trace( set => @_ ) }
sub get { shift->_trace( get => @_ ) }

# stolen from CHI::Driver
sub compute {
    my ( $self, $key, $code, @args ) = @_;

    croak "must specify key and code" unless defined($key) && defined($code);

    my $value = $self->get($key);
    if ( !defined $value ) {
        $value = $self->_trace_full(
            args => [ $key ], # for subclasses to use if they wish
            method => sub { $code->() },
            trace_method => "_record_miss",
        ),
        $self->set( $key, $value, @args );
    }
    return $value;
}

sub _record_hit { shift->_record_time(@_) }
sub _record_set { shift->_record_time(@_) }
sub _record_miss { shift->_record_time(@_, counter => "miss") }

sub _record_get {
    my ( $self, %args ) = @_;

    $self->_record_time(%args);

    if ( $self->cache->isa("Cache::Ref") ) {
        # mget
        my $hits = grep { defined } @{ $args{ret} };
        my $misses = @{ $args{ret} } - $hits;
        $self->_add_hit_count($hits);
        $self->_add_miss_count($misses);
    } else {
        if ( defined $args{ret}[0] ) {
            $self->_inc_hit_count;
        } else {
            $self->_inc_miss_count;
        }
    }

}

sub _record_time {
    my ( $self, %args ) = @_;

    my $name = $args{counter} || $args{method};

    my ( $time_c, $time_r ) = @{ $args{timing} }{qw(time_c time_r)};

    foreach my $counter ( $name, "all" ) {
        $self->${\"_add_${counter}_cpu"}($time_c);
        $self->${\"_add_${counter}_real"}($time_r);
        $self->${\"_inc_call_count_${counter}"};
    }
}

sub _trace {
    my $self = shift;
    my $method = shift;
    $self->_trace_full( method => $method, args => \@_ );
}

sub _trace_full {
    my ( $self, %args ) = @_;

    my $cache = $self->cache;

    my $method = $args{method};
    my $args = $args{args} || [];

    my @ret;

    my $start_c = clock;
    my $start_r = [gettimeofday];

    if ( wantarray ) {
        @ret = $cache->$method(@$args);
    } else {
        $ret[0] = $cache->$method(@$args);
    }

    my $end_c = clock;
    my $end_r = [gettimeofday];

    my $trace_method = $args{trace_method} || "_record_$method";
    $self->$trace_method(
        %args,
        ret  => \@ret,
        wantarray => wantarray,
        timing => {
            start_c => $start_c,
            end_c => $end_c,
            time_c => $end_c - $start_c,
            start_r => $start_r,
            end_r => $end_r,
            time_r => tv_interval($start_r, $end_r),
        },
    );

    return wantarray ? @ret : $ret[0];
}

sub reset {
    my $self = shift;

    foreach my $method ( $self->timer_names ) {
        foreach my $measure ( qw(real cpu) ) {
            $self->${\"reset_${method}_${measure}"};
        }
        $self->${\"reset_call_count_$method"};
    }

    $self->reset_hit_count;
    $self->reset_miss_count;
}

sub speedup {
    my $self = shift;

    my $miss = $self->total_real_time_miss;

    my $sum = $self->total_real_time_all;

    my $cache_overhead = $sum - $miss;

    my $estimated_without_cache = $miss * ( 1 / $self->miss_rate );

    return ( $sum / $estimated_without_cache );
}

sub report {
    my $self = shift;

    my $report = "";

    if ( $self->hit_count ) {
        $report .= sprintf "Hit rate: %0.2f%% (%d/%d)\n", ( $self->hit_rate * 100 ), $self->hit_count, $self->query_count;
    }

    foreach my $method ( $self->timer_names, "all" ) {
        if ( my $calls = $self->${\"call_count_$method"} ) {
            my %times;
            foreach my $measure ( qw(real cpu) ) {
                $times{$measure} = $self->${\"total_${measure}_time_${method}"};
            }

            $report .= sprintf "% 3s: %d time(s), %.2fs cpu, %0.2fs real\n", $method, $calls, @times{qw(cpu real)};
        }
    }

    if ( my $_calls = $self->call_count_miss ) {
        my $gets = $self->call_count_get;

        foreach my $measure (qw(cpu real)) {
            my $miss = $self->${\"total_${measure}_time_miss"};

            my $sum = $self->${\"total_${measure}_time_all"};

            my $cache_overhead = $sum - $miss;

            my $estimated_without_cache = $miss * ( 1 / $self->miss_rate );

            if ( $sum > $estimated_without_cache ) {
                $report .= sprintf
                    "%s time slowdown: %0.2f%% (%.2fs overhead, %.2fs est. compute time w/o cache)\n",
                    $measure, ( ( $sum - $estimated_without_cache ) / $sum ) * 100,
                    $cache_overhead, $estimated_without_cache;
            } else {
                $report .= sprintf
                    "%s time speedup: %0.2f%% (%.2fs est. compute time w/o cache)\n",
                    $measure, ( ( $estimated_without_cache - $sum ) / $estimated_without_cache ) * 100,
                    $estimated_without_cache, $measure;
            }
        }
    }

    return $report;
}

sub moniker {
    my $self = shift;

    if ( my $meta = Class::MOP::class_of($self->cache) ) {
        # CHI drivers
        foreach my $class ( $meta->linearized_isa ) {
            return $class unless Class::MOP::class_of($class)->is_anon_class;
        }
    }

    return ref($self->cache);
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__;

=pod

=encoding UTF-8

=head1 NAME

Cache::Profile - Measure the performance of a cache

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $cache = Cache::Profile->new(
        cache => $real_cache, # CHI, Cache::FastMmap, Cache::Ref, etc
    );

    # use normally:

    $cache->set( foo => "bar" );

    $cache->get("foo");

    # if you want to count speedup, use CHI's compute method:

    $cache->compute( $key, sub {
        # compute the value for $key, this is called on miss
        return something();
    });

    # on caches that don't support 'compute' use Cache::Profile::CorrelateMissTiming
    # it measures the elapsed time between subsequent calls to `get` and `set`
    # with the same key (only on a cache miss)
    Cache::Profile::CorrelateMissTiming->new( cache => Cache::FastMmap->new );


    # print a short stat report:
    warn $cache->report;

    # or check stats manually:
    $cache->hit_rate;

    # compare various caches to pick the best one:

    $cmp = Cache::Profile::Compare->new(
        caches => [
            Cache::Foo->new,
            Cache::Bar->new,
        ],
    );

    $cmp->set( foo => "bar" );

    $cmp->get("foo");

    warn $cmp->report;

=head1 DESCRIPTION

This modules provide a wrapper object for various caching modules (it should
work with most caching modules on the CPAN).

The idea is to measure the performance of caches (both timing info and hit/miss
rates), in order to help make an informed decision on whether caching is really
worth it, and to decide between several caches.

Note that this should increase the overhead of caching by a bit while in use,
especially for quick in memory caches, so don't benchmark with profiling in
case.

=head1 METHODS

=over 4

=item AUTOLOAD

Delegates everything to the cache.

=item get

=item set

=item compute

Standard cache API methods.

=item report

Returns a simple report as a human readable string.

=item {average,total}_{real,cpu}_time_{get,set,miss,all}

Returns the time value (as floating seconds) for the given method.

C<miss> is the time value for the callback provided to C<compute>.

C<compute> is counted as a C<get>, optionally followed by a C<miss> and a
C<set>.

=item call_count_{get,set,miss,all}

Returns the number of times a method is called.

=item query_count

Returns the number of queried keys. For caches supporting multi key get this
may be bigger than C<call_count_get>.

=item hit_rate

=item miss_count

Returns the number of keys whose corresponding return values from C<get> were
defined or C<undef>, respectively.

=item speedup

Returns the actual time elapsed using caching divided the estimated time to
compute all values (based on the average time to compute cache misses).

Smaller is better.

If the overhead of C<get> and C<set> is higher, this will be bigger than 1.

=item reset

Resets the counters/timers.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Cache-Profile>
(or L<bug-Cache-Profile@rt.cpan.org|mailto:bug-Cache-Profile@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# ex: set sw=4 et:

