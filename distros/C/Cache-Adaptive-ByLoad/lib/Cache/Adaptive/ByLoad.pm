package Cache::Adaptive::ByLoad;

use strict;
use warnings;

use base qw(Cache::Adaptive);

our $VERSION = '0.01';

my %MY_DEFAULTS = (
    load_factor    => 8,
    target_loadavg => 1,
);

my %DEFAULTS = (
    %MY_DEFAULTS,
    expires_initial => 1,
    expires_min     => 0.3,
    increase_factor => 1.25,
    decrease_factor => 0.8,
    expires_max     => 60,
    purge_after     => 80,
    check_interval  => 10,
);

__PACKAGE__->mk_accessors($_) for keys %MY_DEFAULTS;
        
BEGIN {
    my $load_avg;
    eval {
        require Sys::Statistics::Linux::LoadAVG;
        my $l = Sys::Statistics::Linux::LoadAVG->new;
        $load_avg = sub {
            $l->get->{avg_1};
        };
    } unless $load_avg;
    eval {
        require BSD::Sysctl;
        $load_avg = sub {
            my $la = BSD::Sysctl::sysctl('vm.loadavg');
            $la->[0];
        };
    } unless $load_avg;
    eval {
        require BSD::getloadavg;
        $load_avg = sub {
            my @la = BSD::getloadavg::getloadavg();
            $la[0];
        };
    } unless $load_avg;
    
    die "Cache::Adaptive::ByLoad requires either of the following: Sys::Statistics::Linux::LoadAVG, BSD::Sysctl, BSD::Getloadavg.\n" unless $load_avg;
    *_load_avg = $load_avg;
};

sub new {
    my ($class, $opts) = @_;
    my $self = Cache::Adaptive::new($class, {
        %DEFAULTS,
        $opts ? %$opts : (),
    });
    $self->check_load(sub { $self->_check_load(@_); });
    $self;
}

sub _check_load {
    my ($self, $entry, $params) = @_;
    my $l = _load_avg() * $self->target_loadavg;
    int($params->{load} * $self->load_factor * $l <= 1 ? $l : $l ** 2) - 1;
} 

1;

=head1 NAME

Cache::Adaptive::ByLoad - Automatically adjusts the cache lifetime by load

=head1 SYNOPSIS

  use Cache::Adaptive::ByLoad;
  use Cache::FileCache;

  my $cache = Cache::Adaptive::ByLoad->new({
    backend => Cache::FileCache->new({
      namespace => 'cache_adaptive',
    }),
  });
  
  ...
  
  print "Content-Type: text/html\n\n";
  print $cache->access({
    key     => $uri,
    builder => sub {
      # your HTML build logic here
      $html;
    },
  });

=head1 DESCRIPTION

C<Cache::Adaptive::ByLoad> is a subclass of L<Cache::Adaptive>.  The module adjusts cache lifetime by two factors; the load average of the platform and the percentage of the total time spent by the builder.  In other words, the module tries to utilize the cache for bottlenecks under heavy load.

=head1 METHODS

=head2 new

Constructor.  Takes a hashref of properties.

=head1 PROPERTIES

C<Cache::Adaptive::ByLoad> defines two properties in addition to the properties defined by L<Cache::Adaptive>.

=head2 load_factor

=head2 target_loadavg

=head1 SEE ALSO

L<Cache::Adaptive>

=head1 AUTHOR

Copyright (c) 2007 Cybozu Labs, Inc.  All rights reserved.

written by Kazuho Oku E<lt>kazuhooku@gmail.comE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under t
he same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
