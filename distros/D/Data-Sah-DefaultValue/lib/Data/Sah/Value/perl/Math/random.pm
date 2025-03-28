package Data::Sah::Value::perl::Math::random;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-17'; # DATE
our $DIST = 'Data-Sah-DefaultValue'; # DIST
our $VERSION = '0.005'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'A random value from 0 (inclusive) to 1 (exclusive)',
        prio => 50,
        args => {
        },
    };
}

sub value {
    my %cargs = @_;

    #my $gen_args = $cargs{args} // {};
    my $res = {};

    $res->{expr_value} = 'rand()';

    $res;
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Value::perl::Math::random

=head1 VERSION

This document describes version 0.005 of Data::Sah::Value::perl::Math::random (from Perl distribution Data-Sah-DefaultValue), released on 2024-01-17.

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|value)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-DefaultValue>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-DefaultValue>.

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

This software is copyright (c) 2024, 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-DefaultValue>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
