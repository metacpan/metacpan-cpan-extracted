package Bencher::Scenario::IPCRun::run_stdin;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => "Benchmark run()'s stdin vs opening a pipe",
    modules => {
    },
    participants => [
        {
            module => 'IPC::Run',
            function => 'run',
            code_template => 'state $in = "a" x <input_size>; IPC::Run::run(["true"], \$in) or die',
        },
        {
            name => 'system',
            code_template => 'state $in = "a" x <input_size>; open my($fh), "|true" or die; print $fh $in',
        },
    ],
    datasets => [
        {args=>{input_size=>0}},
        {args=>{input_size=>1024}},
        #{args=>{input_size=>50*1024}}, # also dies when we run under PWP:Bencher::Scenario
        # 1MB causes silent exit, why
    ],
};

1;
# ABSTRACT: Benchmark run()'s stdin vs opening a pipe

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::IPCRun::run_stdin - Benchmark run()'s stdin vs opening a pipe

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::IPCRun::run_stdin (from Perl distribution Bencher-Scenarios-IPCRun), released on 2017-01-25.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-IPCRun>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-IPCRun>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-IPCRun>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
