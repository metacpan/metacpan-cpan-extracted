package Complete::App::perlmv;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-03'; # DATE
our $DIST = 'App-perlmv'; # DIST
our $VERSION = '0.601'; # VERSION

use 5.010001;
use strict;
use warnings;

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

This document describes version 0.601 of Complete::App::perlmv (from Perl distribution App-perlmv), released on 2020-08-03.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
