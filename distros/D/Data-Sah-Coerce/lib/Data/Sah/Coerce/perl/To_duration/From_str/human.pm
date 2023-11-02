package Data::Sah::Coerce::perl::To_duration::From_str::human;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-24'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.054'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce duration from human notation string (e.g. "2 days 10 hours", "3h")',
        might_fail => 1, # we feed most string to Time::Duration::Parse::AsHash which might croak when fed invalid string
        prio => 60,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(secs)';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "!ref($dt)",
        "$dt =~ /\\d.*[a-z]/",
    );

    $res->{modules}{"Time::Duration::Parse::AsHash"} //= 0;
    if ($coerce_to eq 'float(secs)') {
        # approximation
        $res->{expr_coerce} = qq(do { my \$p; eval { \$p = Time::Duration::Parse::AsHash::parse_duration($dt) }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid duration: \$err"] } else { [undef, (\$p->{years}||0) * 365.25*86400 + (\$p->{months}||0) * 30.4375*86400 + (\$p->{weeks}||0) * 7*86400 + (\$p->{days}||0) * 86400 + (\$p->{hours}||0) * 3600 + (\$p->{minutes}||0) * 60 + (\$p->{seconds}||0)] } });
    } elsif ($coerce_to eq 'DateTime::Duration') {
        $res->{modules}{"DateTime::Duration"} //= 0;
        $res->{expr_coerce} = qq(do { my \$p; eval { \$p = Time::Duration::Parse::AsHash::parse_duration($dt) }; my \$err = \$@; if (\$err) { \$err =~ s/ at .+//s; ["Invalid duration: \$err"] } else { [undef, DateTime::Duration->new( (years=>\$p->{years}) x !!defined(\$p->{years}), (months=>\$p->{months}) x !!defined(\$p->{months}), (weeks=>\$p->{weeks}) x !!defined(\$p->{weeks}), (days=>\$p->{days}) x !!defined(\$p->{days}), (hours=>\$p->{hours}) x !!defined(\$p->{hours}), (minutes=>\$p->{minutes}) x !!defined(\$p->{minutes}), (seconds=>\$p->{seconds}) x !!defined(\$p->{seconds}))] } });
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(secs) or DateTime::Duration";
    }

    $res;
}

1;
# ABSTRACT: Coerce duration from human notation string (e.g. "2 days 10 hours", "3h")

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_duration::From_str::human - Coerce duration from human notation string (e.g. "2 days 10 hours", "3h")

=head1 VERSION

This document describes version 0.054 of Data::Sah::Coerce::perl::To_duration::From_str::human (from Perl distribution Data-Sah-Coerce), released on 2023-10-24.

=head1 SYNOPSIS

To use in a Sah schema:

 ["duration",{"x.perl.coerce_rules"=>["From_str::human"]}]

=head1 DESCRIPTION

The human notation is parsed using L<Time::Duration::Parse::AsHash>.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
