package ArrayData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-20'; # DATE
our $DIST = 'ArrayData'; # DIST
our $VERSION = '0.2.0'; # VERSION

1;
# ABSTRACT: Specification for ArrayData::*, modules that contains array data

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayData - Specification for ArrayData::*, modules that contains array data

=head1 SPECIFICATION VERSION

0.2

=head1 VERSION

This document describes version 0.2.0 of ArrayData (from Perl distribution ArrayData), released on 2021-04-20.

=head1 SYNOPSIS

Use one of the C<ArrayData::*> modules.

=head1 DESCRIPTION

B<NOTE: EARLY SPECIFICATION; THINGS WILL STILL CHANGE A LOT>.

C<ArrayData::*> modules are modules that contain array data. The array can be
accessed via a standard interface (see L<ArrayDataRole::Spec::Basic>). Some
examples of array data are:

=over

=item * list of country names in English (L<ArrayData::CountryNames::EN>)

=item * list of Indonesian words from L<KBBI|https://kbbi.kemdikbud.go.id/> dictionary (L<ArrayData::Words::ID::KBBI>)

Also under L<WordList::ID::KBBI>.

=item * list of CPAN authors' PAUSE ID's (L<ArrayData::CPAN::PAUSEIDs>)

Also under L<WordList::CPAN::PAUSEID>.

=back

Why put data in a Perl module, as a Perl distribution? To leverage the Perl/CPAN
toolchain and infrastructure: 1) ease of installation, update, and
uninstallation; 2) allowing dependency expression and version comparison; 3)
ease of packaging further as OS packages, e.g. Debian packages (converted from
Perl distribution); 4) testing by CPAN Testers.

The array data can actually be stored as Perl array in the Perl module source
code, or as lines in the DATA section of the Perl module, or in a shared file of
the distribution.

To get started, see L<ArrayDataRole::Spec::Basic> and one of existing
C<ArrayData::*> modules.

=head1 NAMESPACE ORGANIZATION

C<ArrayData> (this module) is the specification.

C<ArrayDataRole::*> the roles.

All the modules under C<ArrayData::*> will be modules with actual data.

C<ArrayDataBundle-*> is name for distribution that contains several C<ArrayData>
modules.

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-ArrayData/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HashData>, L<TableData> are related projects.

L<WordList> is an older, related project. ArrayData and its sister projects
HashData & TableData are a generalization and cleanup of the WordList API.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
