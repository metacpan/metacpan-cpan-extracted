package Data::Unixish::DNS::resolve;

our $DATE = '2019-05-30'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
use Log::ger;

use Data::Unixish::Util qw(%common_args);
use Net::DNS::Async;

our %SPEC;

$SPEC{resolve} = {
    v => 1.1,
    summary => 'Resolve DNS',
    description => <<'_',

Note that by default names are resolved in parallel (`queue_size` is 30) and the
results will not be shown in the order they are received. If you want the same
order, you can set `order` to true (not yet implemented), but currently you will
have to wait until the whole list is resolved.

_
    args => {
        %common_args,
        type => {
            schema => 'str*',
            default => 'A',
        },
        order => {
            schema => 'bool*',
        },
        queue_size => {
            schema => ['posint*'],
            default => 30,
        },
        retries => {
            schema => ['uint*'],
            default => 2,
        },
        server => {
            schema => 'net::hostname*',
            cmdline_aliases => {s=>{}},
        },
    },
    tags => [qw/text dns itemfunc/],
};
sub resolve {
    require Net::DNS::Async;

    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});
    my $type = $args{type} // 'A';

    my $resolver = Net::DNS::Async->new(
        QueueSize => $args{queue_size} // 30,
        Retries   => $args{retries}    // 2,
    );

    while (my ($index, $item) = each @$in) {
        $resolver->add({
            #(Nameservers => [$args{server}]) x !!defined($args{server}),
            Callback    => sub {
                my $pkt = shift;
                return unless defined $pkt;
                my @rr = $pkt->answer;
                my %addrs;
                for my $r (@rr) {
                    my $k = $r->owner;
                    next unless $r->type eq $type;
                    $addrs{$k} //= "";
                    $addrs{$k} .=
                        (length($addrs{$k}) ? ", ":"") .
                        $r->address;
                }
                for (sort keys %addrs) {
                    push @$out, "$item: $addrs{$_}";
                }
            }
        }, $item, $type);
    }

    # XXX how to show results as we have them? we must not await here
    $resolver->await;

    [200, "OK"];
}

1;
# ABSTRACT: Resolve DNS

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::DNS::resolve - Resolve DNS

=head1 VERSION

This document describes version 0.001 of Data::Unixish::DNS::resolve (from Perl distribution Data-Unixish-DNS), released on 2019-05-30.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 $addresses = lduxl(['DNS::resolved' => {}], "example.com", "www.example.com"); # => ["example.com: 1.2.3.4","www.example.com: 1.2.3.5"]

In command line:

 % echo -e "example.com\nwww.example.com" | dux DNS::resolve
 example.com: 1.2.3.4
 www.example.com: 1.2.3.5

=head1 FUNCTIONS


=head2 resolve

Usage:

 resolve(%args) -> [status, msg, payload, meta]

Resolve DNS.

Note that by default names are resolved in parallel (C<queue_size> is 30) and the
results will not be shown in the order they are received. If you want the same
order, you can set C<order> to true (not yet implemented), but currently you will
have to wait until the whole list is resolved.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<order> => I<bool>

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<queue_size> => I<posint> (default: 30)

=item * B<retries> => I<uint> (default: 2)

=item * B<server> => I<net::hostname>

=item * B<type> => I<str> (default: "A")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish-DNS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish-DNS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish-DNS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
