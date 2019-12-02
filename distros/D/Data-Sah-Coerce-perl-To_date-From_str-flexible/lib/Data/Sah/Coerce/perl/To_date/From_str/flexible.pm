package Data::Sah::Coerce::perl::To_date::From_str::flexible;

# AUTHOR
our $DATE = '2019-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce-perl-To_date-From_str-flexible'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce date from string parsed by DateTime::Format::Flexible',
        might_fail => 1,
        prio => 60, # a bit lower than normal
        precludes => [qr/\A(From_str::alami(_.+)?|From_str::natural)\z/],
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
        "do { my \$datetime; eval { \$datetime = DateTime::Format::Flexible->parse_datetime($dt) }; ",
        ($coerce_to eq 'float(epoch)' ? "if (\$@) { ['Invalid date format'] } else { [undef, \$datetime->epoch] } " :
             $coerce_to eq 'Time::Moment' ? "if (\$@) { ['Invalid date format'] } else { \$datetime->set_time_zone('UTC'); [undef, Time::Moment->from_object(\$datetime) ] } " :
             $coerce_to eq 'DateTime' ? "if (\$@) { ['Invalid date format'] } else { [undef, \$datetime] } " :
             (die "BUG: Unknown coerce_to '$coerce_to'")),
        "}",
    );

    $res;
}

1;
# ABSTRACT: Coerce date from string parsed by DateTime::Format::Flexible

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_date::From_str::flexible - Coerce date from string parsed by DateTime::Format::Flexible

=head1 VERSION

This document describes version 0.006 of Data::Sah::Coerce::perl::To_date::From_str::flexible (from Perl distribution Data-Sah-Coerce-perl-To_date-From_str-flexible), released on 2019-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["date",{"x.perl.coerce_rules"=>["From_str::flexible"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-To_date-From_str-flexible>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-To_date-From_str-flexible>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-To_date-From_str-flexible>

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
