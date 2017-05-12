# 
# Copyright (c) 2007 Cybozu Labs, Inc.  All rights reserved.
# 

package Cache::Adaptive;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use List::Util qw(min max reduce);
use Time::HiRes qw(gettimeofday tv_interval);

our $VERSION = '0.03';

my %DEFAULTS = (
    backend         => undef,
    check_interval  => 0,
    check_load      => sub { int(shift->{process_time} * 2) - 1 },
    expires_initial => 5,
    expires_min     => 1,
    expires_max     => 60,
    increase_factor => 1.5,
    decrease_factor => 0.8,
    log             => sub {},
);

__PACKAGE__->mk_accessors($_) for (keys(%DEFAULTS), qw(purge_after));

sub new {
    my ($class, $opts) = @_;
    my $self = bless {
        %DEFAULTS,
        $opts ? %$opts : (),
    }, $class;
    die "no backend\n" unless $self->backend;
    $self->{purge_after} ||= $self->{expires_max} * 2;
    $self;
}

sub access {
    my ($self, $opts) = @_;
    
    die "no key\n" unless $opts->{key};
    die "no builder callback\n" unless $opts->{builder};
    
    my $at = gettimeofday;
    
    # obtain cache entry, return it if possible, or build a new entry
    my $entry = $self->backend->get($opts->{key});
    my $purge_after = $opts->{purge_after} || $self->purge_after;
    if ($entry) {
        if ($entry->{value} && ! $opts->{force}) {
            my $expires_at =
                $entry->{expires_at} - rand() * $entry->{expires_in} * 0.2;
            if ($entry->{_no_write} || $at < $expires_at) {
                # printf(STDERR "Cache-Adaptive $$ %s no write is on\n", $entry->{build_at}) if $entry->{_no_write};
                $self->log->({
                    %$opts,
                    type  => q(hit),
                    at    => $at,
                    entry => $entry,
                });
                return $entry->{value};
            }
            $entry->{_no_write} = 1;
            # printf(STDERR "Cache-Adaptive $$ %s setting no_write\n", $entry->{build_at});
            $self->backend->set(
                $opts->{key},
                $entry,
                int($purge_after - $entry->{expires_in}));
        }
    } else {
        $entry = {
            expires_in         => 0,
            _cumu_process_time => 0,
            _cumu_start_at     => $at,
        };
        $entry->{_build_cnt_array}->[$purge_after - 1] = 1;
    }
    
    # build
    my $value = $opts->{builder}->($opts);
    $entry->{process_time} = gettimeofday - $at;
    $entry->{_cumu_process_time} += $entry->{process_time};
    $entry->{build_at} = $at;
    $self->_update_lifetime($entry, $opts);
    # save
    delete $entry->{_no_write};
    delete $entry->{value};
    $entry->{value} = $value if $entry->{expires_in};
    $self->backend->set($opts->{key}, $entry, $purge_after);
    # printf(STDERR "Cache-Adaptive $$ %s new entry saved\n", $at);
    # log
    $self->log->({
        %$opts,
        type  => q(miss),
        at    => $at,
        entry => $entry,
    });
    
    $value;
}

sub _update_lifetime {
    my ($self, $entry, $opts) = @_;
    
    my %params = (
        %$self,
        %$opts,
    );
    my $now = gettimeofday;
    
    if (! $params{check_interval}
            || ($entry->{last_check_at} || 0) + $params{check_interval}
                <= $now) {
        $entry->{last_check_at} = $now;
        $params{load} =
            $entry->{_cumu_process_time} / ($now - $entry->{_cumu_start_at})
                if $self->check_interval;
        $entry->{_cumu_process_time} = 0;
        $entry->{_cumu_start_at} = $now;
        my $decision = $params{check_load}->($entry, \%params);
        if ($decision > 0) { # increase
            if ($entry->{expires_in}) {
                $entry->{expires_in} = min(
                    $params{expires_max},
                    $entry->{expires_in} * $params{increase_factor});
            } else {
                $entry->{expires_in} = $params{expires_initial};
            }
        } elsif ($decision < 0) { # decrease
            if ($entry->{expires_in}) {
                if ($entry->{expires_in} > $params{expires_min}) {
                    $entry->{expires_in} =
                        max($params{expires_min},
                            $entry->{expires_in} * $params{decrease_factor});
                } else {
                    $entry->{expires_in} = 0;
                }
            }
        }
    }
    
    $entry->{expires_at} =
        $entry->{expires_in} ? $now + $entry->{expires_in} : 0;
}

1;

=head1 NAME

Cache::Adaptive - A Cache Engine with Adaptive Lifetime Control

=head1 SYNOPSIS

  use Cache::Adaptive;
  use Cache::FileCache;
  
  my $cache = Cache::Adaptive->new({
    backend     => Cache::FileCache->new({
      namespace => 'html_cache',
      max_size  => 10 * 1024 * 1024,
    }),
    expires_min => 3,
    expires_max => 60,
    check_load  => sub {
      my $entry = shift;
      int($entry->{process_time} * 2) - 1;
    },
  });
  
  ...
  
  print "Content-Type: text/html\n\n";
  print $cache->access({
    key     => $uri,
    builder => sub {
      # your HTML generation logic here
      $html;
    },
  });

=head1 DESCRIPTION

C<Cache::Adaptive> is a cache engine with adaptive lifetime control.  Cache lifetimes can be increased or decreased by any factor, e.g. load average, process time for building the cache entry, etc., through the definition of the C<check_load> callback.

=head1 PROPERTIES

C<Cache::Adaptive> recognizes following properties.  The properties can be set though the constructor, or by calling the accessors.

=head2 backend

Backend storage to be used.  Should be a L<Cache::Cache> object.  Note: do not use Cache::SizeAwareFileCache, since its L<get> method might overwrite data saved by other processes.  The update algorithm of C<Cache::Adaptive> needs a reliable L<set> method.

=head2 check_interval

Interval between calls to the C<check_load> callback for each cache entry.  Default is 0, meaning that C<check_load> will be called every time the cache entry is being built.

=head2 check_load

User supplied callback for deciding the cache policy.  If a positive number is returned, cache lifetime for the entry will be increased.  If a negative number is returned, the lifetime will be decreased.  If 0 is returned, the lifetime will not be modified.  For detail, see the L<"DEFINING THE CACHE STRATEGY"> section.

=head2 increase_factor,  decrease_factor

Cache lifetime will be increased or decreased by applying either factor to current lifetime.

=head2 expires_min, expires_max

Minimal and maximal expiration times, in seconds.

=head2 log

An optional callback for logging.

=head2 purge_after

Seconds until per-entry information used for deciding caching algorithm will be purged.  Defaults to C<expires_max> * 2.

=head1 METHODS

=head2 new

See above.

=head2 access({ key => cache_key, builder => sub { ... } })

Returns the cached entry if possible, or builds the entry by calling the builder function, and optionally stores the build entry to cache.

=head1 DEFINING THE CACHE STRATEGY

A variety of cache strategies can be implemented by defining the C<check_load> callback.  Below are some examples.

=head2 CACHING HEAVY OPERATIONS

  my $cache = Cache::Adaptive->new({
    ...
    check_load => sub {
      my ($entry, $params) = @_;
      int($entry->{process_time} * 2) - 1;
    },
  });

Assume that the process time of each operation increases as the system becomes heavily loaded.  Above code will start caching or increase cache lifetime if the process time for each operation takes more than a second.  As more entries become cached, the system load will become lighter, leading to faster process times, and cache lifetimes will no more be increased.  When the process time becomes smaller than 0.5 seconds, the cache lifetime will be decreased.

=head2 CACHING FREQUENTLY ACCESSED ENTRIES

  my $cache = Cache::Adaptive->new({
    ...
    check_interval => 60,
    check_load     => sub {
      my ($entry, $params) = @_;
      int($params->{load} * 4) - 1;
    },
  });

C<$params->{load}> contains C<$entry->{process_time}> divided by build frequency.  The above code increases cache lifetime if the system is building the entry during more than 50% of its operation recently.  Note that the system may be running multiple processes simultaneously.  This value represents the C<real> time, not CPU cycles that were actually spent for handling the operation.

=head2 UTILIZING CACHE UNDER HEAVY LOAD

  use BSD::Sysctl qw(sysctl);

  my $cache = Cache::Adaptive->new({
    ...
    check_interval => 60,
    check_load     => sub {
      my $load_avg = sysctl('vm.loadavg');
      int($load_avg->[0] * 2) - 1;
    },
  });

The example updates the cache lifetime by referring to the load average.  The example should only work on BSD systems.

=head2 A COMPLEX EXAMPLE

  my $cache = Cache::Adaptive->new({
    ...
    check_interval => 60,
    check_load     => sub {
      my ($entry, $params) = @_;
      my $load_avg = sysctl('vm.loadavg');
      int($params{load} * 4 * $load_avg->[0] ** 2) - 1;
    },
  });

The example utilizes the cache for heavily accessed entries under heavy load.

=head1 UPDATES

For updates, see

  http://labs.cybozu.co.jp/blog/kazuho/
  http://labs.cybozu.co.jp/blog/kazuhoatwork/

=head1 AUTHOR

Copyright (c) 2007 Cybozu Labs, Inc.  All rights reserved.

written by Kazuho Oku E<lt>kazuhooku@gmail.comE<gt>

=head1 CONTRIBUTORS

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
