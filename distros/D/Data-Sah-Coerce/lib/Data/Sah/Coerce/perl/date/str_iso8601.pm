package Data::Sah::Coerce::perl::date::str_iso8601;

our $DATE = '2018-12-16'; # DATE
our $VERSION = '0.030'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 3,
        enable_by_default => 1,
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
        "$dt =~ /\\A([0-9]{4})-([0-9]{2})-([0-9]{2})(?:([T ])([0-9]{2}):([0-9]{2}):([0-9]{2})(Z?))?\\z/",
    );

    $res->{modules}{"Time::Local"} //= 0;

    my $code_epoch = '$4 ? ($8 ? Time::Local::timegm($7, $6, $5, $3, $2-1, $1-1900) : Time::Local::timelocal($7, $6, $5, $3, $2-1, $1-1900)) : Time::Local::timelocal(0, 0, 0, $3, $2-1, $1-1900)';
    if ($coerce_to eq 'float(epoch)') {
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = $code_epoch }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err"] } else { [undef, \$time] } });
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{"DateTime"} //= 0;
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = $code_epoch }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err"] } else { [undef, DateTime->from_epoch(epoch => \$time, time_zone => \$8 ? 'UTC' : 'local')] } });
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{modules}{"Time::Moment"} //= 0;
        $res->{expr_coerce} = qq(do { my \$time; eval { \$time = $code_epoch }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid date/time: \$err"] } else { [undef, Time::Moment->from_epoch(\$time)] } });
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(epoch), DateTime, or Time::Moment";
    }

    $res;
}

1;
# ABSTRACT: Coerce date from (a subset of) ISO8601 string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::date::str_iso8601 - Coerce date from (a subset of) ISO8601 string

=head1 VERSION

This document describes version 0.030 of Data::Sah::Coerce::perl::date::str_iso8601 (from Perl distribution Data-Sah-Coerce), released on 2018-12-16.

=head1 DESCRIPTION

Currently only the following formats are accepted:

 "YYYY-MM-DD"            ; # date (local time), e.g.: 2016-05-13
 "YYYY-MM-DDThh:mm:ss"   ; # date+time (local time), e.g.: 2016-05-13T22:42:00
 "YYYY-MM-DDThh:mm:ssZ"  ; # date+time (UTC), e.g.: 2016-05-13T22:42:00Z

 "YYYY-MM-DD hh:mm:ss"   ; # date+time (local time), MySQL format, e.g.: 2016-05-13 22:42:00
 "YYYY-MM-DD hh:mm:ssZ"  ; # date+time (UTC), MySQL format, e.g.: 2016-05-13 22:42:00Z

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
