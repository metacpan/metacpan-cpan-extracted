package Bencher::ScenarioUtil::DataCSel;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

our @datasets = (
    {name => 'small1-hash'  , summary => '16 elements, 4 levels (hash-based nodes)'  , args=>{tree=>'small1-hash'}},
    {name => 'small1-array' , summary => '16 elements, 4 levels (array-based nodes)' , args=>{tree=>'small1-array'}},
    {name => 'medium1-hash' , summary => '20k elements, 7 levels (hash-based nodes)' , args=>{tree=>'medium1-hash'}},
    {name => 'medium1-array', summary => '20k elements, 7 levels (array-based nodes)', args=>{tree=>'medium1-array'}},
);

# we want to record the version of these modules too in the benchmark result
# metadata
our @extra_modules = (
    'PERLANCAR::Tree::Examples',
);

1;
# ABSTRACT: Utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioUtil::DataCSel - Utility routines

=head1 VERSION

This document describes version 0.04 of Bencher::ScenarioUtil::DataCSel (from Perl distribution Bencher-Scenarios-DataCSel), released on 2017-01-25.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataCSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataCSel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataCSel>

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
