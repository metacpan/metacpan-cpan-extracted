package App::Memcached::Roaster;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/ds/],
);

use Carp;
use Cache::Memcached::Fast;
use Getopt::Long qw(:config posix_default no_ignore_case no_ignore_case_always);
use List::Util qw(first);
use POSIX qw(strftime);
use Time::HiRes;

use version; our $VERSION = 'v0.2.2';

my $DEFAULT_NAMESPACE = 'memcached-roaster:';
my $DEFAULT_PORT      = 11211;
my $DEFAULT_ADDR      = '127.0.0.1:' . $DEFAULT_PORT;
my $DEFAULT_MAX_BYTES = 1_000_000;
my $DEFAULT_DATA_NUM  = 100;
my $INTERVAL          = 100;

sub new {
    my $class  = shift;
    my %params = @_;

    my $addr = $params{addr} // $DEFAULT_ADDR;
    my $ds = Cache::Memcached::Fast->new(+{
        servers         => [$addr],
        namespace       => $DEFAULT_NAMESPACE,
        connect_timeout => 3,
    }) or confess "Can't connect to $addr !";
    unless ($ds->server_versions->{$addr}) {
        confess "Can't get memcached versions! server = $addr";
    }
    $params{ds} = $ds;

    bless \%params, $class;
}

sub parse_args {
    my $class = shift;
    my @args  = @_;

    Getopt::Long::GetOptionsFromArray(
        \@args, \my %opts, 'addr|a=s', 'num|n=s',
        'max-size|S=s', 'debug|d', 'help|h', 'man',
    ) or return +{ help => 1 };
    warn "Unevaluated args remain: @args" if (@args);

    if ($opts{'max-size'} && ($opts{'max-size'} =~ m/^(\d+)[kK]$/)) {
        $opts{'max-size'} = $1 * 1000;
    }

    return \%opts;
}

sub run {
    my $self = shift;
    put("[start] random-generate");

    my @data = (+{
            max_size => $self->{'max-size'} || $DEFAULT_MAX_BYTES,
            num      => $self->{num}        || $DEFAULT_DATA_NUM,
        });

    my $i = 0;
    for my $data (@data) {
        $i++;
        my $pos = 0;
        local $| = 1; # disable output buffering
        print "{$i}:[";
        for my $j (1..$data->{num}) {
            my $size = int( rand() * $data->{max_size} );
            my $key  = join(q{:}, "random-generate$i", "data$j");
            unless ($self->ds->set($key, 'x' x $size)) {
                warn "failed to set $key, $size B";
            }
            if ( (my $_pos = int($j*20 / $data->{num})) > $pos ) {
                $pos = $_pos;
                print '.';
            }
            Time::HiRes::sleep(0.1) if ($j % $INTERVAL == 0);
        }
        print "]\n";
        put("random-generate $i ... complete.");
    }

    put("[end] random-generate");
    return;
}

sub put {
    my ($message, $level) = @_;
    $level ||= 'info';
    printf "%s [$level] $message\n", strftime('%F %T', localtime time());
}

sub DESTROY {
    my $self = shift;
    if ($self->ds) { $self->ds->disconnect_all }
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::Roaster - Random data generator for Memcached

=head1 SYNOPSIS

    use App::Memcached::Roaster;
    my $params = App::Memcached::Roaster->parse_args(@ARGV);
    App::Memcached::Roaster->new(%$params)->run;

=head1 DESCRIPTION

This module is used by <memcached-roaster> script to generates random data for
Memcached.
Depends on L<Cache::Memcached::Fast>.

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<memcached-roaster>,
L<Cache::Memcached::Fast>,

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

