package Data::Sah::Coerce::perl::date::str_alami;

our $DATE = '2017-01-09'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

# TMP
our $time_zone;

sub meta {
    +{
        v => 2,
        enable_by_default => 0,
        might_die => 1,
        prio => 60, # a bit lower than normal
        precludes => [qr/\Astr_alami(_.+)?\z/, 'str_natural'],
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(epoch)';

    my $res = {};

    $res->{expr_match} = "!ref($dt)";
    $res->{modules}{"DateTime::Format::Alami::EN"} //= 0;
    $res->{modules}{"DateTime::Format::Alami::ID"} //= 0;
    $res->{expr_coerce} = join(
        "",
        "do { my \$res = ((\$ENV{LANG} // '') =~ /id_ID/ ? 'DateTime::Format::Alami::ID' : 'DateTime::Format::Alami::EN')->new->parse_datetime($dt, {_time_zone => ".dmp($time_zone)."}); ",
        ($coerce_to eq 'float(epoch)' ? "\$res = \$res->epoch; " :
             $coerce_to eq 'Time::Moment' ? "\$res = Time::Moment->from_object(\$res); " :
             $coerce_to eq 'DateTime' ? "" :
             (die "BUG: Unknown coerce_to '$coerce_to'")),
        "\$res }",
    );

    $res;
}

1;
# ABSTRACT: Coerce date from string parsed by DateTime::Format::Alami

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::date::str_alami - Coerce date from string parsed by DateTime::Format::Alami

=head1 VERSION

This document describes version 0.007 of Data::Sah::Coerce::perl::date::str_alami (from Perl distribution Data-Sah-Coerce-perl-date-str_alami), released on 2017-01-09.

=head1 DESCRIPTION

The rule is not enabled by default. You can enable it in a schema using e.g.:

 ["date", "x.perl.coerce_rules"=>["str_alami"]]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-date-str_alami>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-date-str_alami>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-date-str_alami>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
