package Data::Sah::Value::perl::Date::datetime::end_of_yesterday_local;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-09'; # DATE
our $DIST = 'Data-Sah-ValueBundle-Date'; # DIST
our $VERSION = '0.003'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'End of yesterday (23:59:59/60), local time',
        prio => 50,
        args => {
        },
    };
}

sub value {
    my %cargs = @_;

    #my $gen_args = $cargs{args} // {};
    my $res = {};

    $res->{modules}{'Time::Local'} //= 0;

    my $coerce_to = $cargs{coerce_to} // 'float(epoch)';

    if ($coerce_to eq 'float(epoch)') {
        $res->{expr_value} = 'do { my @lt = localtime(); $lt[0] = $lt[1] = $lt[2] = 0; Time::Local::timelocal_posix(@lt)-1 }';
    } elsif ($coerce_to eq 'DateTime') {
        $res->{expr_value} = 'do { my @lt = localtime(); $lt[0] = $lt[1] = $lt[2] = 0; my $eoy = Time::Local::timelocal_posix(@lt)-1; @lt = localtime($eoy); DateTime->new(year=>$lt[5]+1900, month=>$lt[4]+1, day=>$lt[3], hour=>$lt[2], minute=>$lt[1], second=>$lt[0]) }';
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{expr_value} = 'do { my @lt = localtime(); $lt[0] = $lt[1] = $lt[2] = 0; my $eoy = Time::Local::timelocal_posix(@lt)-1; @lt = localtime($eoy); my $tm = Time::Moment->now; Time::Moment->new(year=>$lt[5]+1900, month=>$lt[4]+1, day=>$lt[3], hour=>$lt[2], minute=>$lt[1], second=>$lt[0], offset=>$tm->offset) }';
    } else {
        die "Unknown 'coerce_to'";
    }

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Value::perl::Date::datetime::end_of_yesterday_local

=head1 VERSION

This document describes version 0.003 of Data::Sah::Value::perl::Date::datetime::end_of_yesterday_local (from Perl distribution Data-Sah-ValueBundle-Date), released on 2023-12-09.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|value)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-ValueBundle-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-ValueBundle-Date>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-ValueBundle-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
