package Complete::Pod;

our $DATE = '2019-06-03'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);
use Complete::Module ();
use List::Util qw(uniq);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(complete_pod);

$SPEC{complete_pod} = {
    v => 1.1,
    summary => 'Complete with installed Perl .pod names',
    description => <<'_',

This is basically <pm:Complete::Module>'s `complete_module` but with
`find_pm`=0, `find_pmc`=0, and `find_pod`=1.

_
    args => {
        %arg_word,
        path_sep    => $Complete::Module::SPEC{complete_module}{args}{path_sep},
        find_prefix => $Complete::Module::SPEC{complete_module}{args}{find_prefix},
        ns_prefix   => $Complete::Module::SPEC{complete_module}{args}{ns_prefix},
    },
    result_naked => 1,
};
sub complete_pod {
    my %args = @_;

    my $word = $args{word} // '';
    Complete::Module::complete_module(
        word => $word,
        find_pm => 0,
        find_pmc => 0,
        find_pod => 1,
        %args);
}

1;
# ABSTRACT: Complete with installed Perl .pod names

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Pod - Complete with installed Perl .pod names

=head1 VERSION

This document describes version 0.001 of Complete::Pod (from Perl distribution Complete-Pod), released on 2019-06-03.

=head1 SYNOPSIS

 use Complete::Pod qw(complete_pod);
 my $res = complete_pod(word => 'Text::A');
 # -> ['CGI', 'CORE', 'Config', 'perllocal', 'perlsecret']

=head1 FUNCTIONS


=head2 complete_pod

Usage:

 complete_pod(%args) -> any

Complete with installed Perl .pod names.

This is basically L<Complete::Module>'s C<complete_module> but with
C<find_pm>=0, C<find_pmc>=0, and C<find_pod>=1.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<find_prefix> => I<bool> (default: 1)

Whether to find module prefixes.

=item * B<ns_prefix> => I<str>

Namespace prefix.

This is useful if you want to complete module under a specific namespace
(instead of the root). For example, if you set C<ns_prefix> to
C<Dist::Zilla::Plugin> (or C<Dist::Zilla::Plugin::>) and word is C<F>, you can get
C<['FakeRelease', 'FileFinder::', 'FinderCode']> (those are modules under the
C<Dist::Zilla::Plugin::> namespace).

=item * B<path_sep> => I<str>

Path separator.

For convenience in shell (bash) completion, instead of defaulting to C<::> all
the time, will look at C<word>. If word does not contain any C<::> then will
default to C</>. This is because C<::> (contains colon) is rather problematic as
it is by default a word-break character in bash and the word needs to be quoted
to avoid word-breaking by bash.

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Pod>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Pod>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Pod>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete::Module>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
