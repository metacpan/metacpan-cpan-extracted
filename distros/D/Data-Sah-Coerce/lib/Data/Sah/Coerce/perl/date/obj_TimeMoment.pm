package Data::Sah::Coerce::perl::date::obj_TimeMoment;

our $DATE = '2018-10-30'; # DATE
our $VERSION = '0.027'; # VERSION

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
        "$dt\->isa('Time::Moment')",
    );

    if ($coerce_to eq 'float(epoch)') {
        $res->{expr_coerce} = "$dt\->epoch";
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{'DateTime'} //= 0;
        $res->{expr_coerce} = "DateTime->from_epoch(epoch => $dt\->epoch, time_zone => sprintf('%s%04d', $dt\->offset >= 0 ? '+':'-', abs(int($dt\->offset / 60)*100) + abs(int($dt\->offset % 60))))";
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{expr_coerce} = $dt;
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(epoch), DateTime, or Time::Moment";
    }

    $res;
}

1;
# ABSTRACT: Coerce date from Time::Moment object

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::date::obj_TimeMoment - Coerce date from Time::Moment object

=head1 VERSION

This document describes version 0.027 of Data::Sah::Coerce::perl::date::obj_TimeMoment (from Perl distribution Data-Sah-Coerce), released on 2018-10-30.

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
