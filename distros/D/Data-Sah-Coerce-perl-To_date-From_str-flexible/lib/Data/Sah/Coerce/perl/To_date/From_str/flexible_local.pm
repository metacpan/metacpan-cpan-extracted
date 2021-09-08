package Data::Sah::Coerce::perl::To_date::From_str::flexible_local;

use 5.010001;
use strict;
use warnings;

# AUTHOR
our $DATE = '2021-09-07'; # DATE
our $DIST = 'Data-Sah-Coerce-perl-To_date-From_str-flexible'; # DIST
our $VERSION = '0.009'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce date from string parsed by DateTime::Format::Flexible (local time zone)',
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
        "do { my \$datetime; eval { \$datetime = DateTime::Format::Flexible->parse_datetime($dt)->set_time_zone('local') }; ",
        ($coerce_to eq 'float(epoch)' ? "if (\$@) { ['Invalid date format'] } else { [undef, \$datetime->epoch] } " :
             $coerce_to eq 'Time::Moment' ? "if (\$@) { ['Invalid date format'] } else { [undef, Time::Moment->from_object(\$datetime) ] } " :
             $coerce_to eq 'DateTime' ? "if (\$@) { ['Invalid date format'] } else { [undef, \$datetime] } " :
             (die "BUG: Unknown coerce_to '$coerce_to'")),
        "}",
    );

    $res;
}

1;
# ABSTRACT: Coerce date from string parsed by DateTime::Format::Flexible (local time zone)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_date::From_str::flexible_local - Coerce date from string parsed by DateTime::Format::Flexible (local time zone)

=head1 VERSION

This document describes version 0.009 of Data::Sah::Coerce::perl::To_date::From_str::flexible_local (from Perl distribution Data-Sah-Coerce-perl-To_date-From_str-flexible), released on 2021-09-07.

=head1 SYNOPSIS

To use in a Sah schema:

 ["date",{"x.perl.coerce_rules"=>["From_str::flexible_local"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-To_date-From_str-flexible>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-To_date-From_str-flexible>.

=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_date::From_str::flexible_utc>

L<Data::Sah::Coerce::perl::To_date::From_str::natural_local>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2018, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-To_date-From_str-flexible>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
