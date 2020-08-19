package App::perlmv::scriptlet::prefix_with_number;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-18'; # DATE
our $DIST = 'App-perlmv-scriptlet-prefix_with_number'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $SCRIPTLET = {
    summary => 'Prefix filenames with number (usually to make them easily sortable)',
    description => <<'_',


_
    args => {
        digits => {
            summary => 'Number of digits to use (1 means 1,2,3,..., 2 means 01,02,03,...); the default is to autodetect',
            schema => 'posint*',
            req => 1,
        },
        start => {
            summary => 'Number to start from',
            schema => 'int*',
            default => 1,
        },
        interval => {
            summary => 'Interval from one number to the next',
            schema => 'int*',
            default => 1,
        },
    },
    code => sub {
        package
            App::perlmv::code;

        use vars qw($ARGS $FILES $TESTING $i);

        $ARGS //= {};
        my $digits = $ARGS->{digits} // (@$FILES >= 1000 ? 4 : @$FILES >= 100 ? 3 : @$FILES >= 10 ? 2 : 1);
        my $start  = $ARGS->{start} // 1;
        my $interval = $ARGS->{interval} // 1;

        $i //= 0;
        $i++ unless $TESTING;

        my $num  = $start + ($i-1)*$interval;
        my $fnum = sprintf("%0${digits}d", $num);
        "$fnum-$_";
    },
};

1;

# ABSTRACT: Prefix filenames with number (usually to make them easily sortable)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::prefix_with_number - Prefix filenames with number (usually to make them easily sortable)

=head1 VERSION

This document describes version 0.001 of App::perlmv::scriptlet::prefix_with_number (from Perl distribution App-perlmv-scriptlet-prefix_with_number), released on 2020-08-18.

=head1 SYNOPSIS

The default is sorted ascibetically:

 % perlmv prefix-with-number foo bar.txt baz.mp3

 1-bar.txt
 2-baz.mp3
 3-foo

Don't sort (C<-T> perlmv option), use two digits:

 % perlmv prefix-with-number -T -a digits=2 foo bar.txt baz.mp3

 01-foo
 02-bar.txt
 03-baz.mp3

=head1 DESCRIPTION

=head1 SCRIPTLET ARGUMENTS

Arguments can be passed using the C<-a> (C<--arg>) L<perlmv> option, e.g. C<< -a name=val >>.

=head2 digits

Required. Number of digits to use (1 means 1,2,3,..., 2 means 01,02,03,...); the default is to autodetect. 

=head2 interval

Interval from one number to the next. 

=head2 start

Number to start from. 

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv-scriptlet-prefix_with_number>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv-scriptlet-prefix_with_number>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv-scriptlet-prefix_with_number>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<perlmv> (from L<App::perlmv>)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
