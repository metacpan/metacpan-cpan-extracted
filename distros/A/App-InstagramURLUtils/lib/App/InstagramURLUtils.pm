package App::InstagramURLUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-03-27'; # DATE
our $DIST = 'App-InstagramURLUtils'; # DIST
our $VERSION = '0.001'; # VERSION

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

$SPEC{parse_instagram_url} = {
    v => 1.1,
    summary => 'Parse Instagram URL(s)',
    args => {
        %common_args,
    },
    result_naked => 1,
};
sub parse_instagram_url {
    require URI::Parse::Instagram;
    my %args = @_;
    [map {URI::Parse::Instagram::parse_instagram_url($_)}
         @{ $args{urls} }];
}

$SPEC{instagram_url2username} = {
    v => 1.1,
    summary => 'Extract username from Instagram URL(s)',
    args => {
        %common_args,
    },
    result_naked => 1,
    examples => [
        {
            summary => 'Accept URLs from pipe',
            src => 'cat urls.txt | [[prog]]',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        }
    ],
};
sub instagram_url2username {
    require URI::Parse::Instagram;
    my %args = @_;
    [map { my $res = URI::Parse::Instagram::parse_instagram_url($_); $res ? $res->{user} : undef }
         @{ $args{urls} }];
}

1;

# ABSTRACT: Utilities related to Instagram URLs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::InstagramURLUtils - Utilities related to Instagram URLs

=head1 VERSION

This document describes version 0.001 of App::InstagramURLUtils (from Perl distribution App-InstagramURLUtils), released on 2025-03-27.

=head1 DESCRIPTION

This distribution contains the following utilities:

=over

=item * L<instagram-url2username>

=item * L<parse-instagram-url>

=back

=head1 FUNCTIONS


=head2 instagram_url2username

Usage:

 instagram_url2username(%args) -> any

Extract username from Instagram URL(s).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<urls>* => I<array[str]>

(No description)


=back

Return value:  (any)



=head2 parse_instagram_url

Usage:

 parse_instagram_url(%args) -> any

Parse Instagram URL(s).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<urls>* => I<array[str]>

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-InstagramURLUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-InstagramURLUtils>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-InstagramURLUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
