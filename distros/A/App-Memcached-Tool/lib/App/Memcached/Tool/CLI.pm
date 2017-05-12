package App::Memcached::Tool::CLI;

use strict;
use warnings;
use 5.008_001;

use Getopt::Long qw(:config posix_default no_ignore_case no_ignore_case_always);
use List::Util qw(first);

use App::Memcached::Tool;
use App::Memcached::Tool::Constants ':all';
use App::Memcached::Tool::DataSource;
use App::Memcached::Tool::Util ':all';

use version; our $VERSION = 'v0.9.4';

sub new {
    my $class  = shift;
    my %params = @_;
    $params{ds}
        = App::Memcached::Tool::DataSource->connect(
            $params{addr}, timeout => $params{timeout}
        );

    bless \%params, $class;
}

sub parse_args {
    my $class = shift;

    my %params; # will be passed to new()
    if (defined $ARGV[0] and looks_like_addr($ARGV[0])) {
        $params{addr} = shift @ARGV;
    }
    if (defined $ARGV[0] and first { $_ eq $ARGV[0] } MODES()) {
        $params{mode} = shift @ARGV;
    }

    GetOptions(
        \my %opts, 'addr|a=s', 'mode|m=s', 'timeout|t=i',
        'debug|d', 'help|h', 'man',
    ) or return +{};
    warn "Unevaluated args remain: @ARGV" if (@ARGV);

    if (defined $opts{man}) {
        $params{mode} = 'man';
    }
    if (defined $opts{help}) {
        $params{mode} = 'help';
    }
    if (defined $opts{debug}) {
        $App::Memcached::Tool::DEBUG = 1;
    }

    %params = (
        addr    => create_addr($params{addr} || $opts{addr}),
        mode    => $params{mode} || $opts{mode} || DEFAULT_MODE(),
        timeout => $opts{timeout},
        debug   => $opts{debug},
    );
    unless (first { $_ eq $params{mode} } MODES()) {
        warn "Invalid mode! $params{mode}";
        delete $params{mode};
    }

    return \%params;
}

sub run {
    my $self = shift;
    debug "[start] $self->{mode} $self->{addr}";
    my $method = $self->{mode};
    my $ret    = $self->$method;
    $self->{ds}->disconnect;
    unless ($ret) {
        warn "Command '$self->{mode}' seems failed. Set '--debug' option if you want to see debug logs.";
        exit 1;
    }
    debug "[end] $self->{mode} $self->{addr}";
}

sub display {
    my $self = shift;

    my %stats;
    my $max = 1;

    my $resp_items = $self->{ds}->query('stats items');
    for my $line (@$resp_items) {
        if ($line =~ m/^STAT items:(\d+):(\w+) (\d+)/) {
            $stats{$1}{$2} = $3;
        }
    }

    my $resp_slabs = $self->{ds}->query('stats slabs');
    for my $line (@$resp_slabs) {
        if ($line =~ m/^STAT (\d+):(\w+) (\d+)/) {
            $stats{$1}{$2} = $3;
            $max = $1;
        }
    }

    print "  #  Item_Size  Max_age   Pages   Count   Full?  Evicted Evict_Time OOM\n";
    for my $class (1..$max) {
        my $slab = $stats{$class};
        next unless $slab->{total_pages};

        my $size
            = $slab->{chunk_size} < 1024 ? "$slab->{chunk_size}B"
            : sprintf("%.1fK", $slab->{chunk_size} / 1024.0) ;

        my $full = ($slab->{free_chunks_end} == 0) ? 'yes' : 'no';
        printf(
            "%3d %8s %9ds %7d %7d %7s %8d %8d %4d\n",
            $class, $size, $slab->{age} || 0, $slab->{total_pages},
            $slab->{number} || 0, $full, $slab->{evicted} || 0,
            $slab->{evicted_time} || 0, $slab->{outofmemory} || 0,
        );
    }

    return 1;
}

sub stats {
    my $self = shift;
    my $response = $self->{ds}->query('stats');
    _print_stats_of_response("stats - $self->{addr}", @$response);
    return 1;
}

sub settings {
    my $self = shift;
    my $response = $self->{ds}->query('stats settings');
    _print_stats_of_response("stats settings - $self->{addr}", @$response);
    return 1;
}

sub _print_stats_of_response {
    my $title  = shift;
    my @lines  = @_;

    my %stats;
    my ($max_key_l, $max_val_l) = (0, 0);

    for my $line (@lines) {
        next if ($line !~ m/^STAT\s+(\S*)\s+(.*)/);
        my ($key, $value) = ($1, $2);
        if (length $key   > $max_key_l) { $max_key_l = length $key; }
        if (length $value > $max_val_l) { $max_val_l = length $value; }
        $stats{$key} = $value;
    }

    print  "# $title\n";
    printf "#%${max_key_l}s  %${max_val_l}s\n", 'Field', 'Value';
    for my $field (sort {$a cmp $b} (keys %stats)) {
        printf (" %${max_key_l}s  %${max_val_l}s\n", $field, $stats{$field});
    }
}

sub dump {
    my $self = shift;
    my %items;
    my $total;

    my $response = $self->{ds}->query('stats items');
    for my $line (@$response) {
        if ($line =~ m/^STAT items:(\d*):number (\d*)/) {
            $items{$1} = $2;
            $total += $2;
        }
    }

    print  STDERR "Dumping memcache contents\n";
    printf STDERR "  Number of buckets: %d\n", scalar(keys(%items));
    print  STDERR "  Number of items  : $total\n";

    for my $bucket (sort(keys %items)) {
        print STDERR "Dumping bucket $bucket - " . $items{$bucket} . " total items\n";
        $response = $self->{ds}->query("stats cachedump $bucket $items{$bucket}");

        my %expires;
        for my $line (@$response) {
            # Ex) ITEM foo [6 b; 1176415152 s]
            if ($line =~ m/^ITEM (\S+) \[.* (\d+) s\]/) {
                $expires{$1} = $2;
            }
        }

        my $now = time();
        my @keys_bucket = keys %expires;
        while (my @keys = splice(@keys_bucket, 0, 20)) {
            my $list = $self->{ds}->get(@keys);
            for my $d (@$list) {
                my $expire = ($expires{$d->{key}} < $now) ? 0 : $expires{$d->{key}};
                print "add $d->{key} $d->{flags} $expire $d->{length}\r\n";
                print "$d->{value}\r\n";
            }
        }
    }

    return 1;
}

sub sizes {
    my $self = shift;
    my $response = $self->{ds}->query('stats sizes');
    my %stats;
    for my $line (@$response) {
        if ($line =~ m/^STAT\s+(\S*)\s+(.*)/) {
            $stats{$1} = $2;
        }
    }
    print "# stats sizes - $self->{addr}\n";
    printf "#%17s  %12s\n", 'Size', 'Count';
    for my $field (sort {$a cmp $b} (keys %stats)) {
        printf ("%18s  %12s\n", $field, $stats{$field});
    }
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::Tool::CLI - CLI module for L<memcached-tool>

=head1 SYNOPSIS

    use App::Memcached::Tool::CLI;
    my $params = App::Memcached::Tool::CLI->parse_args;
    App::Memcached::Tool::CLI->new(%$params)->run

=head1 DESCRIPTION

App::Memcached::Tool::CLI executes procedure of L<memcached-tool>.

=head1 SEE ALSO

L<memcached-tool>

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

