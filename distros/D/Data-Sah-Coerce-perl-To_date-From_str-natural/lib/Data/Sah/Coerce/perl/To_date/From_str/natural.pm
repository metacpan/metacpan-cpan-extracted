package Data::Sah::Coerce::perl::To_date::From_str::natural;

# AUTHOR
our $DATE = '2019-11-29'; # DATE
our $DIST = 'Data-Sah-Coerce-perl-To_date-From_str-natural'; # DIST
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

# TMP
our $time_zone = 'UTC';

sub meta {
    +{
        v => 4,
        summary => 'Coerce date from string parsed by DateTime::Format::Natural',
        might_fail => 1,
        prio => 60, # a bit lower than normal
        precludes => [qr/\A(From_str::alami(_.+)?|From_str::flexible)\z/],
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(epoch)';

    my $res = {};

    $res->{expr_match} = "!ref($dt)";
    $res->{modules}{"DateTime::Format::Natural"} //= 0;
    $res->{expr_coerce} = join(
        "",
        "do { my \$p = DateTime::Format::Natural->new(time_zone => ".dmp($time_zone)."); my \$datetime = \$p->parse_datetime($dt); ",
        "if (!\$p->success) { [\$p->error] } else { ",
        ($coerce_to eq 'float(epoch)' ? "[undef, \$datetime->epoch] " :
             $coerce_to eq 'Time::Moment' ? "[undef, Time::Moment->from_object(\$datetime)] " :
             $coerce_to eq 'DateTime' ? "[undef, \$datetime] " :
             (die "BUG: Unknown coerce_to '$coerce_to'")),
        "} }",
    );

    $res;
}

1;
# ABSTRACT: Coerce date from string parsed by DateTime::Format::Natural

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_date::From_str::natural - Coerce date from string parsed by DateTime::Format::Natural

=head1 VERSION

This document describes version 0.010 of Data::Sah::Coerce::perl::To_date::From_str::natural (from Perl distribution Data-Sah-Coerce-perl-To_date-From_str-natural), released on 2019-11-29.

=head1 SYNOPSIS

To use in a Sah schema:

 ["date",{"x.perl.coerce_rules"=>["From_str::natural"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-To_date-From_str-natural>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-To_date-From_str-natural>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-To_date-From_str-natural>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
