package Data::Sah::Coerce::perl::To_datenotime::From_str::iso8601;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-22'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.053'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce datenotime from (a subset of) ISO8601 string',
        might_fail => 1, # we match any (YYYY-MM-DD... string, so the conversion to date might fail on invalid dates)
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(epoch)';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "!ref($dt)",
        #            1=Y        2=M        3=D
        "$dt =~ /\\A([0-9]{4})-([0-9]{2})-([0-9]{2})\\z/",
    );

    if ($coerce_to eq 'float(epoch)') {
        $res->{modules}{"Time::Local"} //= 0;
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = Time::Local::timelocal_modern(0, 0, 0, \$3, \$2-1, \$1) }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err", \$time] } else { [undef, \$time] } });
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{"DateTime"} //= 0;
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = DateTime->new(year=>\$1, month=>\$2, day=>\$3) };          my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err", \$time] } else { [undef, \$time] } });
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{modules}{"Time::Moment"} //= 0;
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = Time::Moment->new(year=>\$1, month=>\$2, day=>\$3) };      my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err", \$time] } else { [undef, \$time] } });
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(epoch), DateTime, or Time::Moment";
    }

    $res;
}

1;
# ABSTRACT: Coerce datenotime from (a subset of) ISO8601 string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_datenotime::From_str::iso8601 - Coerce datenotime from (a subset of) ISO8601 string

=head1 VERSION

This document describes version 0.053 of Data::Sah::Coerce::perl::To_datenotime::From_str::iso8601 (from Perl distribution Data-Sah-Coerce), released on 2022-09-22.

=head1 SYNOPSIS

To use in a Sah schema:

 ["datenotime",{"x.perl.coerce_rules"=>["From_str::iso8601"]}]

=head1 DESCRIPTION

This rule coerces datenotime from a subset of ISO8601 string. Currently only the
following formats are accepted:

 "YYYY-MM-DD"            ; # date (local time), e.g.: 2016-05-13

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
