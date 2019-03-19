package Bencher::Scenario::preloadable;

our $DATE = '2019-03-19'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub _uses_require {
    require strict;
}

sub _uses_preloadable {
    use preloadable "strict";
}

our $scenario = {
    summary => 'Benchmark preloadable.pm',
    participants => [
        {
            name => 'require',
            fcall_template => "Bencher::Scenario::preloadable::_uses_require",
        },
        {
            name => 'preloadable',
            fcall_template => "Bencher::Scenario::preloadable::_uses_preloadable",
        },
    ],
};

1;
# ABSTRACT: Benchmark preloadable.pm

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::preloadable - Benchmark preloadable.pm

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::preloadable (from Perl distribution Bencher-Scenario-preloadable), released on 2019-03-19.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-preloadable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-preloadable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-preloadable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
