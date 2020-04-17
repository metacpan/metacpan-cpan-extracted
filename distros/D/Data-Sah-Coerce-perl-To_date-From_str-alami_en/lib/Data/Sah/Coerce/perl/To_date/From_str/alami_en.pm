package Data::Sah::Coerce::perl::To_date::From_str::alami_en;

# AUTHOR
our $DATE = '2019-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce-perl-To_date-From_str-alami_en'; # DIST
our $VERSION = '0.012'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

# TMP
our $time_zone;

sub meta {
    +{
        v => 4,
        summary => 'Coerce date from string parsed by DateTime::Format::Alami::EN',
        might_fail => 1,
        prio => 60, # a bit lower than normal
        precludes => [qr/\AFrom_str::alami(_.+)?\z/, 'From_str::natural', 'From_str::flexible'],
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(epoch)';

    my $res = {};

    $res->{expr_match} = "!ref($dt)";
    $res->{modules}{"DateTime::Format::Alami::EN"} //= 0;
    $res->{expr_coerce} = join(
        "",
        "do { my \$datetime; eval { \$datetime = DateTime::Format::Alami::EN->new->parse_datetime($dt, {_time_zone => ".dmp($time_zone)."}) }; my \$err = \$@; ",
        ($coerce_to eq 'float(epoch)' ? "if (\$err) { \$err =~ s/ at .+//s; [\$err] } else { [undef, \$datetime->epoch ] } " :
             $coerce_to eq 'Time::Moment' ? "if (\$err) { \$err =~ s/ at .+//s; [\$err] } else { [undef, Time::Moment->from_object(\$datetime) ] } " :
             $coerce_to eq 'DateTime' ? "if (\$err) { \$err =~ s/ at .+//s; [\$err] } else { [undef, \$datetime] } " :
             (die "BUG: Unknown coerce_to '$coerce_to'")),
        "}",
    );

    $res;
}

1;
# ABSTRACT: Coerce date from string parsed by DateTime::Format::Alami::EN

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_date::From_str::alami_en - Coerce date from string parsed by DateTime::Format::Alami::EN

=head1 VERSION

This document describes version 0.012 of Data::Sah::Coerce::perl::To_date::From_str::alami_en (from Perl distribution Data-Sah-Coerce-perl-To_date-From_str-alami_en), released on 2019-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["date",{"x.perl.coerce_rules"=>["From_str::alami_en"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-To_date-From_str-alami_en>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-To_date-From_str-Alami_EN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-To_date-From_str-alami_en>

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
