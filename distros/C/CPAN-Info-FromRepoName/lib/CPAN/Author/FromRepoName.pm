package CPAN::Author::FromRepoName;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-02'; # DATE
our $DIST = 'CPAN-Info-FromRepoName'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use CPAN::Info::FromRepoName qw(extract_cpan_info_from_repo_name);

use Exporter qw(import);
our @EXPORT_OK = qw(extract_cpan_author_from_repo_name);

our %SPEC;

$SPEC{extract_cpan_author_from_repo_name} = {
    v => 1.1,
    summary => 'Extract CPAN author from a repo name',
    args => {
        repo_name => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str',
    },
    result_naked => 1,
    examples => [
    ],
};
sub extract_cpan_author_from_repo_name {
    my $repo_name = shift;

    my $ecires = extract_cpan_info_from_repo_name($repo_name);
    return undef unless defined $ecires;
    $ecires->{author};
}

1;
# ABSTRACT: Extract CPAN author from a repo name

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Author::FromRepoName - Extract CPAN author from a repo name

=head1 VERSION

This document describes version 0.001 of CPAN::Author::FromRepoName (from Perl distribution CPAN-Info-FromRepoName), released on 2020-10-02.

=head1 FUNCTIONS


=head2 extract_cpan_author_from_repo_name

Usage:

 extract_cpan_author_from_repo_name($repo_name) -> str

Extract CPAN author from a repo name.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$repo_name>* => I<str>


=back

Return value:  (str)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Info-FromRepoName>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Info-FromRepoName>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Info-FromRepoName>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Author::FromURL>.

L<CPAN::Info::FromRepoName>, the more generic module which is used by this module.

L<CPAN::Dist::FromRepoName>

L<CPAN::Module::FromRepoName>

L<CPAN::Release::FromRepoName>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
