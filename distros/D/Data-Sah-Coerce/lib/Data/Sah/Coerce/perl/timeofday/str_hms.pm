package Data::Sah::Coerce::perl::timeofday::str_hms;

our $DATE = '2018-12-16'; # DATE
our $VERSION = '0.030'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 3,
        enable_by_default => 1,
        might_fail => 1, # we match any (hh:mm:ss string, so the conversion might fail on invalid value)
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'str_hms';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "$dt =~ /\\A([0-9]{2}):([0-9]{2}):([0-9]{2})(\.[0-9]{1,9})?\\z/",
    );

    my $code_check = qq(if (\$1 > 23) { ["Invalid hour '\$1', must be between 0-23"] } elsif (\$2 > 59) { ["Invalid minute '\$2', must be between 0-59"] } elsif (\$3 > 59) { ["Invalid second '\$3', must be between 0-59"] });

    if ($coerce_to eq 'float') {
        $res->{expr_coerce} = qq(do { $code_check else { [undef, \$1*3600 + \$2*60 + \$3 + (defined \$4 ? \$4 : 0)] } });
    } elsif ($coerce_to eq 'str_hms') {
        $res->{expr_coerce} = qq(do { $code_check else { [undef, $dt] } });
    } elsif ($coerce_to eq 'Date::TimeOfDay') {
        $res->{modules}{"Date::TimeOfDay"} //= 0.002;
        $res->{expr_coerce} = qq([undef, Date::TimeOfDay->new(hour=>\$1, minute=>\$2, second=>\$3, nanosecond=>(defined \$4 ? \$4*1e9 : 0))]);
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float, str_hms, or Date::TimeOfDay";
    }

    $res;
}

1;
# ABSTRACT: Coerce timeofday from string in the form of hh:mm:ss

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::timeofday::str_hms - Coerce timeofday from string in the form of hh:mm:ss

=head1 VERSION

This document describes version 0.030 of Data::Sah::Coerce::perl::timeofday::str_hms (from Perl distribution Data-Sah-Coerce), released on 2018-12-16.

=head1 DESCRIPTION

Timeofday can be coerced into one of: C<float> (seconds after midnight, e.g.
86399 is 23:59:59), C<str_hms> (string in the form of hh:mm:ss), or
C<Date::TimeOfDay> (an instance of L<Date::TimeOfDay> class).

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
