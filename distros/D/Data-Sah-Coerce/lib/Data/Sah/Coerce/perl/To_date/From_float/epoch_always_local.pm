package Data::Sah::Coerce::perl::To_date::From_float::epoch_always_local;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.052'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce date from number (all range assumed to be epoch) (local time zone)',
        prio => 50,
        precludes => [qr/\AFrom_float::epoch(.*)\z/],
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(epoch)';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "!ref($dt)",
        "$dt =~ /\\A[0-9]+(?:\.[0-9]+)?\\z/",
    );

    if ($coerce_to eq 'float(epoch)') {
        $res->{expr_coerce} = $dt;
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{DateTime} //= 0;
        $res->{expr_coerce} = "DateTime->from_epoch(epoch => $dt, time_zone=>'local')";
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{modules}{'Time::Moment'} //= 0;
        $res->{expr_coerce} = "Time::Moment->from_epoch($dt)";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(epoch), DateTime, or Time::Moment";
    }

    $res;
}

1;
# ABSTRACT: Coerce date from number (all range assumed to be epoch) (local time zone)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_date::From_float::epoch_always_local - Coerce date from number (all range assumed to be epoch) (local time zone)

=head1 VERSION

This document describes version 0.052 of Data::Sah::Coerce::perl::To_date::From_float::epoch_always_local (from Perl distribution Data-Sah-Coerce), released on 2021-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["date",{"x.perl.coerce_rules"=>["From_float::epoch_always_local"]}]

=head1 DESCRIPTION

This rule coerces date from number (which assumed to be epoch). If data is a
number and C<coerce_to> is "float(epoch)" (the default), then this rule does
nothing. If C<coerce_to> is "DateTime" or "Time::Moment" then this rule
instantiates the appropriate date object using the epoch value.

Additionally, this rule sets time zone to local.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_date::From_float::epoch_always>

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

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
