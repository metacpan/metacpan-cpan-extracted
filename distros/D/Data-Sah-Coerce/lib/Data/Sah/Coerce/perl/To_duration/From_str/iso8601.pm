package Data::Sah::Coerce::perl::To_duration::From_str::iso8601;

# AUTHOR
our $DATE = '2019-12-04'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.040'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce duration from (subset of) ISO8601 string (e.g. "P1Y2M", "P14M")',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(secs)';

    my $res = {};

    my $re_num = '[0-9]+(?:\\.[0-9]+)?';
    $res->{expr_match} = join(
        " && ",
        "!ref($dt)",
        #                #1=Y            #2=M(on)        #3=W            #4=D                  #5=H            #6=M(in)        #7=S
        "$dt =~ /\\AP(?:($re_num)Y)? (?:($re_num)M)? (?:($re_num)W)? (?:($re_num)D)? (?: T (?:($re_num)H)? (?:($re_num)M)? (?:($re_num)S)? )?\\z/x",
    );

    if ($coerce_to eq 'float(secs)') {
        # approximation
        $res->{expr_coerce} = "((\$1||0)*365.25*86400 + (\$2||0)*30.4375*86400 + (\$3||0)*7*86400 + (\$4||0)*86400 + (\$5||0)*3600 + (\$6||0)*60 + (\$7||0))";
    } elsif ($coerce_to eq 'DateTime::Duration') {
        $res->{modules}{"DateTime::Duration"} //= 0;
        $res->{expr_coerce} = "DateTime::Duration->new( (years=>\$1) x !!defined(\$1), (months=>\$2) x !!defined(\$2), (weeks=>\$3) x !!defined(\$3), (days=>\$4) x !!defined(\$4), (hours=>\$5) x !!defined(\$5), (minutes=>\$6) x !!defined(\$6), (seconds=>\$7) x !!defined(\$7))";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(secs) or DateTime::Duration";
    }

    $res;
}

1;
# ABSTRACT: Coerce duration from (subset of) ISO8601 string (e.g. "P1Y2M", "P14M")

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_duration::From_str::iso8601 - Coerce duration from (subset of) ISO8601 string (e.g. "P1Y2M", "P14M")

=head1 VERSION

This document describes version 0.040 of Data::Sah::Coerce::perl::To_duration::From_str::iso8601 (from Perl distribution Data-Sah-Coerce), released on 2019-12-04.

=head1 DESCRIPTION

The format is:

 PnYnMnWnDTnHnMnS

Examples: "P1Y2M" (equals to "P14M", 14 months), "P1DT13M" (1 day, 13 minutes).

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

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
