package Set::Tiny::_ModuleFeatures;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-Set'; # DIST
our $VERSION = '0.001'; # VERSION

our %FEATURES = (
    module_v => "1.0",
    features => {
        Set => {
            can_insert_value => 1,
            can_delete_value => 1,
            can_search_value => 1,
            can_count_values => 1,

            can_union_sets                => 1,
            can_intersect_sets            => 1,
            can_difference_sets           => 1,
            can_symmetric_difference_sets => 1,

            speed           => 'fast',
            memory_overhead => 'low',
            features        => 'medium',
        },
    },
);

1;
# ABSTRACT: Features declaration for Set::Tiny

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::Tiny::_ModuleFeatures - Features declaration for Set::Tiny

=head1 VERSION

This document describes version 0.001 of Set::Tiny::_ModuleFeatures (from Perl distribution Acme-CPANModules-Set), released on 2022-03-18.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Set>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Set>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Set>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
