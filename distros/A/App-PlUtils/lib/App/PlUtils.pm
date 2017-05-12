package App::PlUtils;

our $DATE = '2016-07-20'; # DATE
our $VERSION = '0.11'; # VERSION

use 5.010001;
use strict;
use warnings;

our $arg_file_single = {
    summary => 'Perl script',
    description => <<'_',

For convenience, if filename does not contain path separator, it will first be
searched in the current directory, then in `PATH` (using `File::Which`).

_
    schema  => 'filename*',
    req     => 1,
    pos     => 0,
    completion => sub {
        require Complete::Program;
        my %args = @_;
        Complete::Program::complete_program(word=>$args{word});
    },
};

our $arg_file_multiple = {
    summary => 'Perl script',
    description => <<'_',

For convenience, if filename does not contain path separator, it will first be
searched in the current directory, then in `PATH` (using `File::Which`).

_
    schema  => ['array*', of=>'filename*', min_len=>1],
    req     => 1,
    pos     => 0,
    greedy  => 1,
    element_completion => sub {
        require Complete::Program;
        my %args = @_;
        Complete::Program::complete_program(word=>$args{word});
    },
};

our $arg_module_single = {
    schema => 'perl::modname*',
    completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(word=>$args{word});
    },
    cmdline_aliases => {m=>{}},
};

1;
# ABSTRACT: Command-line utilities related to Perl scripts

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PlUtils - Command-line utilities related to Perl scripts

=head1 VERSION

This document describes version 0.11 of App::PlUtils (from Perl distribution App-PlUtils), released on 2016-07-20.

=head1 SYNOPSIS

This distribution provides tha following command-line utilities related to Perl
scripts.

=over

=item * L<plcost>

=item * L<pllex>

=item * L<pllines>

=item * L<plsub>

=item * L<pluse>

=back

The main feature of these utilities is tab completion.

=head1 FAQ

=head2 What is the purpose of this distribution? Haven't other similar utilities existed?

For example, L<mpath> from L<Module::Path> distribution is similar to L<pmpath>
in L<App::PMUtils>, and L<mversion> from L<Module::Version> distribution is
similar to L<pmversion> from L<App::PMUtils> distribution, and so on.

True. The main point of these utilities is shell tab completion, to save
typing.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PlUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PlUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PlUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Below is the list of distributions that provide CLI utilities for various
purposes, with the focus on providing shell tab completion feature.

L<App::DistUtils>, utilities related to Perl distributions.

L<App::DzilUtils>, utilities related to L<Dist::Zilla>.

L<App::GitUtils>, utilities related to git.

L<App::IODUtils>, utilities related to L<IOD> configuration files.

L<App::LedgerUtils>, utilities related to Ledger CLI files.

L<App::PlUtils>, utilities related to Perl scripts.

L<App::PMUtils>, utilities related to Perl modules.

L<App::ProgUtils>, utilities related to programs.

L<App::WeaverUtils>, utilities related to L<Pod::Weaver>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
