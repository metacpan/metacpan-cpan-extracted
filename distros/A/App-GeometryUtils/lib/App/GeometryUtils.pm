package App::GeometryUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use List::Util qw(max);
use POSIX qw(floor);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-25'; # DATE
our $DIST = 'App-GeometryUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to geometry',
};

my $re_dim3 = qr/\A
                 (\d+(?:\.\d+)?) \s*x\s*
                 (\d+(?:\.\d+)?) \s*x\s*
                 (\d+(?:\.\d+)?)
                 \z/ix;

sub _fit0 {
    my ($ls, $ws, $hs, $lL, $wL, $hL, $allow_multiple_orientation) = @_;

    my $nl = floor($lL/$ls);
    my $nw = floor($wL/$ws);
    my $nh = floor($hL/$hs);

    my $n = $nl*$nw*$nh;

    my $m = 0;
  TRY_FIT_DIFFERENT_ORIENTATION:
    {
        # try fitting the smaller box in different orientation in the remaining
        # space
        last unless $n;
        last unless $allow_multiple_orientation;

        # S = small (n times), R = remaining
        my $lS = $nl*$ls;
        my $wS = $nw*$ws;
        my $hS = $nh*$hs;
        my $lR = $lL - $lS;
        my $wR = $wL - $wS;
        my $hR = $hL - $hS;

        # lL wL
        $m +=
            _fit($ls, $ws, $hs, $lL, $wL, $hR, 1, 1) +
            _fit($ls, $ws, $hs, $lL, $wR, $hS, 1, 1) +
            _fit($ls, $ws, $hs, $lR, $wS, $hS, 1, 1) ;
        $m +=
            _fit($ls, $ws, $hs, $lL, $wL, $hR, 1, 1) +
            _fit($ls, $ws, $hs, $lR, $wL, $hS, 1, 1) +
            _fit($ls, $ws, $hs, $lR, $wS, $hS, 1, 1) ;

        # lL hL
        $m +=
            _fit($ls, $ws, $hs, $lL, $wR, $hL, 1, 1) +
            _fit($ls, $ws, $hs, $lR, $wS, $hL, 1, 1) +
            _fit($ls, $ws, $hs, $lS, $wS, $hR, 1, 1) ;
        $m +=
            _fit($ls, $ws, $hs, $lL, $wR, $hR, 1, 1) +
            _fit($ls, $ws, $hs, $lL, $wS, $hR, 1, 1) +
            _fit($ls, $ws, $hs, $lR, $wS, $hS, 1, 1) ;

        # wL hL
        $m +=
            _fit($ls, $ws, $hs, $lR, $wL, $hL, 1, 1) +
            _fit($ls, $ws, $hs, $lS, $wR, $hL, 1, 1) +
            _fit($ls, $ws, $hs, $lS, $wS, $hR, 1, 1) ;
        $m +=
            _fit($ls, $ws, $hs, $lR, $wL, $hL, 1, 1) +
            _fit($ls, $ws, $hs, $lS, $wL, $hR, 1, 1) +
            _fit($ls, $ws, $hs, $lS, $wR, $hS, 1, 1) ;
    }

    if ($n) {
        log_trace "${ls}x${ws}x${hs} -> ${lL}x${wL}x${hL} = $n" .
            ($m ? " + $m (in different orientation)" : "");
    }
    $n;
}

sub _fit {
    my ($ls, $ws, $hs, $lL, $wL, $hL, $allow_rotation, $allow_multiple_orientation) = @_;

    my @res;

    push @res, _fit0($ls, $ws, $hs, $lL, $wL, $hL, $allow_multiple_orientation);
    goto RETURN_RES unless $allow_rotation;
    push @res, _fit0($ls, $hs, $ws, $lL, $wL, $hL, $allow_multiple_orientation);
    push @res, _fit0($ws, $ls, $hs, $lL, $wL, $hL, $allow_multiple_orientation);
    push @res, _fit0($ws, $hs, $ls, $lL, $wL, $hL, $allow_multiple_orientation);
    push @res, _fit0($hs, $ls, $ws, $lL, $wL, $hL, $allow_multiple_orientation);
    push @res, _fit0($hs, $ws, $ls, $lL, $wL, $hL, $allow_multiple_orientation);

  RETURN_RES:
    my $n = max(@res);
    if ($n) {
        log_trace "Results of all possible combinations (rotation): %s", \@res;
    }
    $n;
}

$SPEC{calc_box_fit} = {
    v => 1.1,
    summary => 'Calculate how many small boxes fit inside a larger box',
    description => <<'MARKDOWN',

Keywords: packing algorithm, bin packing

MARKDOWN
    args => {
        smaller_dimension => {
            summary => 'Dimension (LxWxH) of the smaller box',
            schema => [str => {req=>1, match=>$re_dim3}],
            req => 1,
            pos => 0,
        },
        larger_dimension => {
            summary => 'Dimension (LxWxH) of the smaller box',
            schema => [str => {req=>1, match=>$re_dim3}],
            req => 1,
            pos => 1,
        },
        allow_rotation => {
            schema => 'bool*',
            default => 1,
            cmdline_aliases => {
                R => {is_flag=>1, summary=>"Short for for --disallow-rotation", code=>sub { $_[0]{allow_rotation} = 0 }},
            },
        },
        # note: i haven't seen a case where doing multiple orientation can
        # increase the number of smaller boxes to fit inside
        allow_multiple_orientation => {
            schema => 'bool*',
            default => 1,
            cmdline_aliases => {
                M => {is_flag=>1, summary=>"Short for for --disallow-multiple-orientation", code=>sub { $_[0]{allow_multiple_orientation} = 0 }},
            },
        },
    },
    examples => [
        {argv=>["5x3x2", "35x19x18"]},
    ],
    result_naked => 1,
    result => {
        #schema => 'int*',
    },
    links => [
        {
            url => 'pm:Box::Calc',
            description => <<'MARKDOWN',

Given one or more of "smaller boxes" ("items" in Box::Calc lingo) of different
sizes, what kind and how many "larger boxes" ("boxes" in Box::Calc lingo) are
needed for shipping?

MARKDOWN
        },
        {
            url => 'pm:Algorithm::BinPack',
            description => <<'MARKDOWN',

This is a one-dimensional packing problem instead of 3D one. Given multiple
items of different size, and a container (bin) size, how many containers are
needed?

MARKDOWN
        },
    ],
};
sub calc_box_fit {
    my %args = @_;

    my ($ls, $ws, $hs) = $args{smaller_dimension} =~ $re_dim3 or die;
    my ($lL, $wL, $hL) = $args{larger_dimension}  =~ $re_dim3 or die;

    my $n = _fit($ls, $ws, $hs, $lL, $wL, $hL,
                 $args{allow_rotation} // 1,
                 $args{allow_multiple_orientation} // 1);

    sprintf "%d (%.2f%% full)", $n, ($n*$ls*$ws*$hs / ($lL*$wL*$hL))*100;
}

$SPEC{calc_box_surface_area} = {
    v => 1.1,
    summary => 'Calculate surface area of a box with specified dimension',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        dimension => {
            summary => 'Dimension (LxWxH) of the box',
            schema => [str => {req=>1, match=>$re_dim3}],
            req => 1,
            pos => 0,
        },
    },
    examples => [
        {argv=>["5x3x2"]},
    ],
    result_naked => 1,
    result => {
        schema => 'float*',
    },
    links => [
    ],
};
sub calc_box_surface_area {
    my %args = @_;

    my ($l, $w, $h) = $args{dimension} =~ $re_dim3 or die;

    sprintf "%g", (2*$l*$w + 2*$l*$h + 2*$w*$h);
}

1;
# ABSTRACT: Utilities related to geometry

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GeometryUtils - Utilities related to geometry

=head1 VERSION

This document describes version 0.001 of App::GeometryUtils (from Perl distribution App-GeometryUtils), released on 2024-06-25.

=head1 DESCRIPTION

This distribution provides the following command-line utilities related to
geometry:

=over

=item * L<calc-box-fit>

=item * L<calc-box-surface-area>

=back

=head1 FUNCTIONS


=head2 calc_box_fit

Usage:

 calc_box_fit(%args) -> any

Calculate how many small boxes fit inside a larger box.

Examples:

=over

=item * Example #1:

 calc_box_fit(smaller_dimension => "5x3x2", larger_dimension => "35x19x18"); # -> "378 (94.74% full)"

=back

Keywords: packing algorithm, bin packing

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_multiple_orientation> => I<bool> (default: 1)

(No description)

=item * B<allow_rotation> => I<bool> (default: 1)

(No description)

=item * B<larger_dimension>* => I<str>

Dimension (LxWxH) of the smaller box.

=item * B<smaller_dimension>* => I<str>

Dimension (LxWxH) of the smaller box.


=back

Return value:  (any)



=head2 calc_box_surface_area

Usage:

 calc_box_surface_area(%args) -> float

Calculate surface area of a box with specified dimension.

Examples:

=over

=item * Example #1:

 calc_box_surface_area(dimension => "5x3x2"); # -> 62

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dimension>* => I<str>

Dimension (LxWxH) of the box.


=back

Return value:  (float)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GeometryUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GeometryUtils>.

=head1 SEE ALSO


L<Box::Calc>. Given one or more of "smaller boxes" ("items" in Box::Calc lingo) of different
sizes, what kind and how many "larger boxes" ("boxes" in Box::Calc lingo) are
needed for shipping?

L<Algorithm::BinPack>. This is a one-dimensional packing problem instead of 3D one. Given multiple
items of different size, and a container (bin) size, how many containers are
needed?

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GeometryUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
