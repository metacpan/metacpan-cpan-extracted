package App::streamfinder;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-03'; # DATE
our $DIST = 'App-streamfinder'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Object;

our %SPEC;

$SPEC{app} = {
    v => 1.1,
    summary => 'CLI for StreamFinder, a module to fetch actual raw streamable URLs from video & podcasts sites',
    description => <<'_',

Examples:

    % streamfinder https://www.youtube.com/watch?v=6yVIKvcPa6Q
    https://r5---sn-htgx20capjpq-jb3l.googlevideo.com/videoplayback?exp...

    % streamfinder https://www.youtube.com/watch?v=6yVIKvcPa6Q -l
    +--------------+------------------------- ...+-------+-------------+------------+--------------...+-----------...+-------------------------...+
    | artist       | description                 | genre | num_streams | stream_num | stream_url      | title        | url                        |
    +--------------+------------------------- ...+-------+-------------+------------+--------------...+-----------...+-------------------------...+
    | Powerful JRE | Another hilarious moment ...|       | 1           | 1          | https://r5---...| Pinky And ...| https://www.youtube.com/...|
    +--------------+--------------------------...+-------+-------------+------------+--------------...+-----------...+-------------------------...+

    % streamfinder https://www.youtube.com/watch?v=6yVIKvcPa6Q https://www.youtube.com/watch?v=6yzVtlUI02w --json
    ...

_
    args => {
        urls => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'url',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub app {
    require StreamFinder;

    my %args = @_;

    my $envres = envresmulti();
    my $i = -1;
    for my $url (@{ $args{urls} }) {
        $i++;
        my $station = StreamFinder->new($url);
        unless ($station) {
            $envres->add_result(500, "Invalid URL or no streams found: $url", {item_id=>$i});
            next;
        }
        my @streams = $station->get;
        for my $j (0..$#streams) {
            $envres->add_result(200, "OK", {payload=>{
                url=>$url,
                stream_num=>$j+1,
                num_streams=>scalar(@streams),
                stream_url=>$streams[$j],
                title=>$station->getTitle,
                description=>$station->getTitle('desc'),
                artist=>$station->{artist},
                genre=>$station->{genre},
            }, item_id=>$i});
        }
    }

    my $res = $envres->as_struct;
    $res->[2] //= [];
    if (!$args{detail} && @{ $args{urls} } == 1 && @{ $res->[2] } == 1) {
        $res->[2] = $res->[2][0]{stream_url};
    }
    $res;
}

1;
# ABSTRACT: CLI for StreamFinder, a module to fetch actual raw streamable URLs from video & podcasts sites

__END__

=pod

=encoding UTF-8

=head1 NAME

App::streamfinder - CLI for StreamFinder, a module to fetch actual raw streamable URLs from video & podcasts sites

=head1 VERSION

This document describes version 0.002 of App::streamfinder (from Perl distribution App-streamfinder), released on 2020-01-03.

=head1 FUNCTIONS


=head2 app

Usage:

 app(%args) -> [status, msg, payload, meta]

CLI for StreamFinder, a module to fetch actual raw streamable URLs from video & podcasts sites.

Examples:

 % streamfinder https://www.youtube.com/watch?v=6yVIKvcPa6Q
 https://r5---sn-htgx20capjpq-jb3l.googlevideo.com/videoplayback?exp...
 
 % streamfinder https://www.youtube.com/watch?v=6yVIKvcPa6Q -l
 +--------------+------------------------- ...+-------+-------------+------------+--------------...+-----------...+-------------------------...+
 | artist       | description                 | genre | num_streams | stream_num | stream_url      | title        | url                        |
 +--------------+------------------------- ...+-------+-------------+------------+--------------...+-----------...+-------------------------...+
 | Powerful JRE | Another hilarious moment ...|       | 1           | 1          | https://r5---...| Pinky And ...| https://www.youtube.com/...|
 +--------------+--------------------------...+-------+-------------+------------+--------------...+-----------...+-------------------------...+
 
 % streamfinder https://www.youtube.com/watch?v=6yVIKvcPa6Q https://www.youtube.com/watch?v=6yzVtlUI02w --json
 ...

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<urls>* => I<array[str]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-streamfinder>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-streamfinder>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-streamfinder>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<StreamFinder>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
