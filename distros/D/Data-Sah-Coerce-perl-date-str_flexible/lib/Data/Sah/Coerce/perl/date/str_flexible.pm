package Data::Sah::Coerce::perl::date::str_flexible;

our $DATE = '2016-06-30'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 2,
        enable_by_default => 0,
        might_die => 1,
        prio => 60, # a bit lower than normal
        precludes => [qr/\A(str_alami(_.+)?|str_natural)\z/],
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(epoch)';

    my $res = {};

    $res->{expr_match} = "!ref($dt)";
    $res->{modules}{"DateTime::Format::Flexible"} //= 0;
    $res->{expr_coerce} = join(
        "",
        "do { my \$res = DateTime::Format::Flexible->parse_datetime($dt); ",
        ($coerce_to eq 'float(epoch)' ? "\$res = \$res->epoch; " :
             $coerce_to eq 'Time::Moment' ? "\$res->set_time_zone('UTC'); \$res = Time::Moment->from_object(\$res); " :
             $coerce_to eq 'DateTime' ? "" :
             (die "BUG: Unknown coerce_to '$coerce_to'")),
        "\$res }",
    );

    $res;
}

1;
# ABSTRACT: Coerce date from string parsed by DateTime::Format::Flexible

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::date::str_flexible - Coerce date from string parsed by DateTime::Format::Flexible

=head1 VERSION

This document describes version 0.001 of Data::Sah::Coerce::perl::date::str_flexible (from Perl distribution Data-Sah-Coerce-perl-date-str_flexible), released on 2016-06-30.

=head1 DESCRIPTION

The rule is not enabled by default. You can enable it in a schema using e.g.:

 ["date", "x.perl.coerce_rules"=>["str_flexible"]]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-date-str_flexible>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-date-str_flexible>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-date-str_flexible>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
