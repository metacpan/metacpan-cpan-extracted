package Complete::App::perlmv;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-24'; # DATE
our $DIST = 'App-perlmv'; # DIST
our $VERSION = '0.606'; # VERSION

use Exporter 'import';
our @EXPORT_OK = qw(
                       complete_perlmv_scriptlet
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to App::perlmv',
};

$SPEC{complete_perlmv_scriptlet} = {
    v => 1.1,
    summary => 'Complete from available scriptlet names',
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub complete_perlmv_scriptlet {
    require App::perlmv;
    require Complete::Util;

    my %args = @_;

    my $scriptlets = App::perlmv->new->find_scriptlets;

    Complete::Util::complete_hash_key(
        word  => $args{word},
        hash  => $scriptlets,
    );
}

1;
# ABSTRACT: Completion routines related to App::perlmv

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::App::perlmv - Completion routines related to App::perlmv

=head1 VERSION

This document describes version 0.606 of Complete::App::perlmv (from Perl distribution App-perlmv), released on 2022-06-24.

=head1 FUNCTIONS


=head2 complete_perlmv_scriptlet

Usage:

 complete_perlmv_scriptlet(%args) -> any

Complete from available scriptlet names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv>.

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

This software is copyright (c) 2022, 2020, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
