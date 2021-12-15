package Data::Sah::Coerce::perl::To_datetime::From_str::iso8601;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.052'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce datetime from (a subset of) ISO8601 string',
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
        #            1=Y        2=M        3=D          4="T" 5=h        6=m        7=s       8="Z"
        "$dt =~ /\\A([0-9]{4})-([0-9]{2})-([0-9]{2})([T ])([0-9]{2}):([0-9]{2}):([0-9]{2})(Z?)\\z/",
    );

    if ($coerce_to eq 'float(epoch)') {
        $res->{modules}{"Time::Local"} //= 0;
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = \$8 ? Time::Local::timegm_modern(\$7, \$6, \$5, \$3, \$2-1, \$1) : Time::Local::timelocal_modern(\$7, \$6, \$5, \$3, \$2-1, \$1) }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err", \$time] } else { [undef, \$time] } });
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{"DateTime"} //= 0;
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = DateTime->new(year=>\$1, month=>\$2, day=>\$3, hour=>\$5, minute=>\$6, second=>\$7, time_zone => \$8 ? 'UTC' : 'local') };          my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err", \$time] } else { [undef, \$time] } });
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{modules}{"Time::Moment"} //= 0;
        # XXX set offset=>... when $8 is not Z
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = Time::Moment->new(year=>\$1, month=>\$2, day=>\$3, hour=>\$5, minute=>\$6, second=>\$7, offset=>0) };                               my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err", \$time] } else { [undef, \$time] } });
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(epoch), DateTime, or Time::Moment";
    }

    $res;
}

1;
# ABSTRACT: Coerce datetime from (a subset of) ISO8601 string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_datetime::From_str::iso8601 - Coerce datetime from (a subset of) ISO8601 string

=head1 VERSION

This document describes version 0.052 of Data::Sah::Coerce::perl::To_datetime::From_str::iso8601 (from Perl distribution Data-Sah-Coerce), released on 2021-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["datetime",{"x.perl.coerce_rules"=>["From_str::iso8601"]}]

=head1 DESCRIPTION

Currently only the following formats are accepted:

 "YYYY-MM-DDThh:mm:ss"   ; # date+time (local time), e.g.: 2016-05-13T22:42:00
 "YYYY-MM-DDThh:mm:ssZ"  ; # date+time (UTC), e.g.: 2016-05-13T22:42:00Z

 "YYYY-MM-DD hh:mm:ss"   ; # date+time (local time), MySQL format, e.g.: 2016-05-13 22:42:00
 "YYYY-MM-DD hh:mm:ssZ"  ; # date+time (UTC), MySQL format, e.g.: 2016-05-13 22:42:00Z

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
