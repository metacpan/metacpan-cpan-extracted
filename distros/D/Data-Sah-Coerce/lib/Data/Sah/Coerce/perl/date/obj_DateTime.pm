package Data::Sah::Coerce::perl::date::obj_DateTime;

our $DATE = '2018-06-02'; # DATE
our $VERSION = '0.025'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 3,
        enable_by_default => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(epoch)';

    my $res = {};

    $res->{modules}{'Scalar::Util'} //= 0;

    $res->{expr_match} = join(
        " && ",
        "Scalar::Util::blessed($dt)",
        "$dt\->isa('DateTime')",
    );

    if ($coerce_to eq 'float(epoch)') {
        $res->{expr_coerce} = "$dt\->epoch";
    } elsif ($coerce_to eq 'DateTime') {
        $res->{expr_coerce} = $dt;
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{modules}{'Time::Moment'} //= 0;
        $res->{expr_coerce} = "Time::Moment->from_object($dt)";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(epoch), DateTime, or Time::Moment";
    }

    $res;
}

1;
# ABSTRACT: Coerce date from DateTime object

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::date::obj_DateTime - Coerce date from DateTime object

=head1 VERSION

This document describes version 0.025 of Data::Sah::Coerce::perl::date::obj_DateTime (from Perl distribution Data-Sah-Coerce), released on 2018-06-02.

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
