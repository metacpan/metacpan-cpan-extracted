package App::resolvetable;

our $DATE = '2019-08-20'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Color::ANSI::Util qw(ansifg);
use Data::Cmp qw(cmp_data);
use Time::HiRes qw(time);

our %SPEC;

# colorize majority values with green, minority values with red
sub _colorize_maj_min {
    my $row = shift;

    my %freq;
    my @keys = keys %$row;
    for (@keys) {
        next unless defined $row->{$_};
        next if $_ eq 'name';
        $freq{ $row->{$_} }++;
    }
    my @vals_by_freq = sort { $freq{$b} <=> $freq{$a} } keys %freq;

    # no defined values
    return unless @vals_by_freq;

    my $green = "33cc33";
    my $red   = "33cc33";

    my %colors_by_val;
    my $freq;
    my $decreased;
    for my $val (@vals_by_freq) {
        if (!defined $freq) {
            $freq = $freq{$val};
            $colors_by_val{$val} = $green;
            next;
        }
        if (!$decreased) {
            if ($freq > $freq{$val}) {
                $decreased++;
            }
        }
        $colors_by_val{$val} = $decreased ? $red : $green;
    }
    for (@keys) {
        my $val = $row->{$_};
        next unless defined $val;
        next if $_ eq 'name';
        $row->{$_} = ansifg($colors_by_val{$val}) . $row->{$_} . "\e[0m";
    }
}

# colorize the shortest time with green
sub _colorize_shortest_time {
    my $row = shift;
    no warnings 'numeric';

    my %time;
    my @keys = keys %$row;
    for (@keys) {
        next unless defined $row->{$_};
        next if $_ eq 'name';
        my $time =
            $row->{$_} =~ /^\s*</ ? 0.01 :
            $row->{$_} =~ /^\s*>/ ? 4001 : $row->{$_}+0;
        $time{ $row->{$_} } = $time;
    }
    my @times_from_shortest = sort { $time{$a} <=> $time{$b} } keys %time;

    # no defined values
    return unless @times_from_shortest;

    my $green = "33cc33";

    for (@keys) {
        my $val = $row->{$_};
        next unless defined $val;
        next if $_ eq 'name';
        $row->{$_} = ansifg($green) . $row->{$_} . "\e[0m"
            if $row->{$_} eq $times_from_shortest[0];
    }
}

sub _mark_undef_with_x {
    my $row = shift;
    for (keys %$row) {
        next if $_ eq 'name';
        next if defined $row->{$_};
        $row->{$_} = ansifg("ff0000")."X"."\e[0m";
    }
}

sub _colorize_reference_result {
    my ($row, $reference_server) = @_;
    my %colors_by_server;
    for (keys %$row) {
        next if $_ eq 'name';
        $colors_by_server{$_} =
            $_ eq $reference_server || cmp_data($row->{$_}, $row->{$reference_server}) == 0 ?
            (defined($row->{$_}) ? "33cc33" : "7f7f7f") :
            "ff0000";
    }
    for (keys %$row) {
        next if $_ eq 'name';
        $row->{$_} = ansifg($colors_by_server{$_}).($row->{$_} // 'X')."\e[0m";
    }
}

$SPEC{'resolvetable'} = {
    v => 1.1,
    summary => 'Produce a colored table containing DNS resolve results of '.
        'several names from several servers/resolvers',
    args => {
        action => {
            schema => ['str*', in=>[qw/show-addresses compare-addresses show-timings/]],
            default => 'show-addresses',
            cmdline_aliases => {
                timings => {is_flag=>1, summary=>'Shortcut for --action=show-timings', code=>sub { $_[0]{action} = 'show-timings' }},
                compare => {is_flag=>1, summary=>'Shortcut for --action=compare-addresses', code=>sub { $_[0]{action} = 'compare-addresses' }},
            },
            description => <<'_',

The default action is to show resolve result (`show-addresses`). Will highlight
the majority result with green, and minority result with red. Failed resolve
(undef) will also be highlighted with a red "X".

The `compare-addresses` action is similar to `show-addresses`, but will assume
the first server/resolver as the reference and compare the results of the other
servers with the first. When the result is different, it will be highlighted
with red; when the result is the same, it will be highlighted with green. Failed
resolve (undef) are highlighted with a grey X (if result is the same as
reference server) or a red X (if result is different than reference server). So
basically whenever you see a red, the results of the other servers are not
identical with the first (reference) server.

The `show-timings` action will show resolve times instead of addresses, to
compare speed among DNS servers/resolvers. Will highlight the fastest server
with green.

_
        },
        servers => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'server',
            schema => ['array*', of=>'str*'], # XXX hostname
            cmdline_aliases => {s=>{}},
            req => 1,
        },
        names => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'name',
            schema => ['array*', of=>'str*'],
            cmdline_src => 'stdin_or_args',
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        type => {
            summary => 'Type of DNS record to query',
            schema => ['str*'],
            default => 'A',
            cmdline_aliases => {t=>{}},
        },
        colorize => {
            schema => 'bool*',
            default => 1,
        },
    },
    examples => [
        {
            src => 'cat names.txt | [[prog]] -s 8.8.8.8 -s my.dns.server -s my2.dns.server',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub resolvetable {
    require Net::DNS::Async;

    my %args = @_;
    my $type = $args{type} // "A";
    my $names   = $args{names};
    my $servers = $args{servers};
    my $action  = $args{action} // 'show-addresses';

    my %res;       # key=name, val={server=>result, ...}
    my %starttime; # key=name, val={server=>time, ...}
    my %endtime  ; # key=name, val={server=>time, ...}

    log_info "Resolving ...";
    my $resolver = Net::DNS::Async->new(QueueSize => 30, Retries => 2);
    for my $name (@$names) {
        for my $server (@$servers) {
            $starttime{$name}{$server} = time();
            $resolver->add({
                Nameservers => [$server],
                Callback    => sub {
                    my $time = time();
                    my $pkt = shift;
                    return unless defined $pkt;
                    my @rr = $pkt->answer;
                    for my $r (@rr) {
                        my $k = $r->owner;
                        $res{ $k }{$server} //= "";
                        $res{ $k }{$server} .=
                            (length($res{ $k }{$server}) ? ", ":"") .
                            $r->address
                            if $r->type eq $type;
                        $endtime{$name}{$server} //= $time;
                    }
                },
            }, $name, $args{type});
        }
    }
    $resolver->await;

    log_trace "Returning table result ...";
    my @rows;
    for my $name (@$names) {
        my $row;
        if ($action eq 'show-addresses') {
            $row = {
                name => $name,
                map { $_ => $res{$name}{$_} } @$servers,
            };
            if ($args{colorize}) {
                _colorize_maj_min($row);
                _mark_undef_with_x($row);
            }
        } elsif ($action eq 'compare-addresses') {
            $row = {
                name => $name,
                map { $_ => $res{$name}{$_} } @$servers,
            };
            if ($args{colorize}) {
                _colorize_reference_result($row, $servers->[0]);
            }
        } elsif ($action eq 'show-timings') {
            $row = {
                name => $name,
                map {
                    my $server = $_;
                    my $starttime = $starttime{$name}{$_};
                    my $endtime   = $endtime{$name}{$_};
                    my $val;
                    if (defined $endtime) {
                        my $ms = ($endtime - $starttime)*1000;
                        if ($ms > 4000) {
                            $val = ">4000ms";
                        } elsif ($ms <= 0.5) {
                            $val = "<=0.5ms";
                        } else {
                            $val = sprintf("%3.0fms", $ms);
                        }
                    } else {
                        $val = undef;
                    }
                    ($server => $val);
                } @$servers,
            };
        } else {
            die "Unknown action '$action'";
        }
        if ($args{colorize}) {
            _colorize_shortest_time($row);
            _mark_undef_with_x($row);
        }
        push @rows, $row;
    }

    [200, "OK", \@rows, {'table.fields'=>['name', @$servers]}];
}

1;
# ABSTRACT: Produce a colored table containing DNS resolve results of several names from several servers/resolvers

__END__

=pod

=encoding UTF-8

=head1 NAME

App::resolvetable - Produce a colored table containing DNS resolve results of several names from several servers/resolvers

=head1 VERSION

This document describes version 0.007 of App::resolvetable (from Perl distribution App-resolvetable), released on 2019-08-20.

=head1 DESCRIPTION

Sample screenshot 1:

=head1 FUNCTIONS


=head2 resolvetable

Usage:

 resolvetable(%args) -> [status, msg, payload, meta]

Produce a colored table containing DNS resolve results of several names from several servers/resolvers.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "show-addresses")

The default action is to show resolve result (C<show-addresses>). Will highlight
the majority result with green, and minority result with red. Failed resolve
(undef) will also be highlighted with a red "X".

The C<compare-addresses> action is similar to C<show-addresses>, but will assume
the first server/resolver as the reference and compare the results of the other
servers with the first. When the result is different, it will be highlighted
with red; when the result is the same, it will be highlighted with green. Failed
resolve (undef) are highlighted with a grey X (if result is the same as
reference server) or a red X (if result is different than reference server). So
basically whenever you see a red, the results of the other servers are not
identical with the first (reference) server.

The C<show-timings> action will show resolve times instead of addresses, to
compare speed among DNS servers/resolvers. Will highlight the fastest server
with green.

=item * B<colorize> => I<bool> (default: 1)

=item * B<names>* => I<array[str]>

=item * B<servers>* => I<array[str]>

=item * B<type> => I<str> (default: "A")

Type of DNS record to query.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for html <img src="https://st.aticpan.org/source/PERLANCAR/App-resolvetable-0.007/share/images/Screenshot_20190530_111051.png" />

Sample screenshot 2 (with C<--timings>):

=for html <img src="https://st.aticpan.org/source/PERLANCAR/App-resolvetable-0.007/share/images/Screenshot_20190530_112052.png" />

Sample screenshot 3 (with C<--compare>):

=for html <img src="https://st.aticpan.org/source/PERLANCAR/App-resolvetable-0.007/share/images/Screenshot_20190820_235000-redacted.png" />

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-resolvetable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-resolvetable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-resolvetable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
