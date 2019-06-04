package App::PODUtils;

our $DATE = '2019-06-03'; # DATE
our $VERSION = '0.041'; # VERSION

use 5.010001;
use strict;
use warnings;

our $arg_pod_multiple = {
    schema => ['array*' => of=>'perl::podname*', min_len=>1],
    req    => 1,
    pos    => 0,
    greedy => 1,
    element_completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(
            find_pm=>0, find_pmc=>0, find_pod=>1, word=>$args{word});
    },
};

our $arg_pod_single = {
    schema => 'perl::podname*',
    req    => 1,
    pos    => 0,
    completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(
            find_pm=>0, find_pmc=>0, find_pod=>1, word=>$args{word});
    },
};

1;
# ABSTRACT: Command-line utilities related to POD

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PODUtils - Command-line utilities related to POD

=head1 VERSION

This document describes version 0.041 of App::PODUtils (from Perl distribution App-PODUtils), released on 2019-06-03.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to Perl
POD:

=over

=item * L<elide-pod>

=item * L<podless>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PODUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PODUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PODUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<pod2html>

L<podtohtml> from L<App::podtohtml>

L<App::PMUtils>

L<App::PlUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
