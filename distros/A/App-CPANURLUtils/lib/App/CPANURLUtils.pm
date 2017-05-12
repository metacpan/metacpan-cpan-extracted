package App::CPANURLUtils;

our $DATE = '2017-03-21'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our %common_args = (
    urls => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'url',
        schema => ['array*', of=>'str*', min_len=>1],
        req => 1,
        pos => 0,
        greedy => 1,
        cmdline_src => 'stdin_or_args',
    },
);

$SPEC{url2cpaninfo} = {
    v => 1.1,
    summary => 'Extract CPAN information from URL(s)',
    args => {
        %common_args,
    },
    result_naked => 1,
};
sub url2cpaninfo {
    require CPAN::Info::FromURL;
    my %args = @_;
    [map {CPAN::Info::FromURL::extract_cpan_info_from_url($_)}
         @{ $args{urls} }];
}

$SPEC{url2cpanmod} = {
    v => 1.1,
    summary => 'Extract CPAN module from URL(s)',
    args => {
        %common_args,
    },
    result_naked => 1,
};
sub url2cpanmod {
    require CPAN::Module::FromURL;
    my %args = @_;
    [map {CPAN::Module::FromURL::extract_cpan_module_from_url($_)}
         @{ $args{urls} }];
}

$SPEC{url2cpandist} = {
    v => 1.1,
    summary => 'Extract CPAN distribution from URL(s)',
    args => {
        %common_args,
    },
    result_naked => 1,
};
sub url2cpandist {
    require CPAN::Dist::FromURL;
    my %args = @_;
    [map {CPAN::Dist::FromURL::extract_cpan_dist_from_url($_)}
         @{ $args{urls} }];
}

$SPEC{url2cpanauthor} = {
    v => 1.1,
    summary => 'Extract CPAN author from URL(s)',
    args => {
        %common_args,
    },
    result_naked => 1,
};
sub url2cpanauthor {
    require CPAN::Author::FromURL;
    my %args = @_;
    [map {CPAN::Author::FromURL::extract_cpan_author_from_url($_)}
         @{ $args{urls} }];
}

$SPEC{url2cpanrel} = {
    v => 1.1,
    summary => 'Extract CPAN release (tarball) name from URL(s)',
    args => {
        %common_args,
    },
    result_naked => 1,
};
sub url2cpanrel {
    require CPAN::Release::FromURL;
    my %args = @_;
    [map {CPAN::Release::FromURL::extract_cpan_release_from_url($_)}
         @{ $args{urls} }];
}

1;

# ABSTRACT: Utilities related to CPAN URLs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CPANURLUtils - Utilities related to CPAN URLs

=head1 VERSION

This document describes version 0.02 of App::CPANURLUtils (from Perl distribution App-CPANURLUtils), released on 2017-03-21.

=head1 DESCRIPTION

This distribution contains the following utilities:

=over

=item * L<url2cpanauthor>

=item * L<url2cpandist>

=item * L<url2cpaninfo>

=item * L<url2cpanmod>

=item * L<url2cpanrel>

=back

=head1 FUNCTIONS


=head2 url2cpanauthor

Usage:

 url2cpanauthor(%args) -> any

Extract CPAN author from URL(s).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<urls>* => I<array[str]>

=back

Return value:  (any)


=head2 url2cpandist

Usage:

 url2cpandist(%args) -> any

Extract CPAN distribution from URL(s).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<urls>* => I<array[str]>

=back

Return value:  (any)


=head2 url2cpaninfo

Usage:

 url2cpaninfo(%args) -> any

Extract CPAN information from URL(s).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<urls>* => I<array[str]>

=back

Return value:  (any)


=head2 url2cpanmod

Usage:

 url2cpanmod(%args) -> any

Extract CPAN module from URL(s).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<urls>* => I<array[str]>

=back

Return value:  (any)


=head2 url2cpanrel

Usage:

 url2cpanrel(%args) -> any

Extract CPAN release (tarball) name from URL(s).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<urls>* => I<array[str]>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CPANURLUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CPANURLUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CPANURLUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
