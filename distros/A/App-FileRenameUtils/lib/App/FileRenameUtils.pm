package App::FileRenameUtils;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-20'; # DATE
our $DIST = 'App-FileRenameUtils'; # DIST
our $VERSION = '0.014'; # VERSION

our @EXPORT_OK = qw(add_filename_suffix find_unique_filename);

sub add_filename_suffix {
    no warnings 'uninitialized';

    my ($filename, $suffix) = @_;
    $filename =~ s/(.+?)(\.\w+)?\z/$1 . $suffix . $2/e;
    $filename;
}

sub find_unique_filename {
    my $filename = shift;

    my $orig_filename = $filename;
    my $i = 0;
    while (-e $filename) {
        $i++;
        $filename = add_filename_suffix($orig_filename, " ($i)");
    }
    $filename;
}

1;
# ABSTRACT: Utilities related to renaming/moving files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FileRenameUtils - Utilities related to renaming/moving files

=head1 VERSION

This document describes version 0.014 of App::FileRenameUtils (from Perl distribution App-FileRenameUtils), released on 2023-11-20.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item 1. L<datestamp>

=item 2. L<move-files-here>

=item 3. L<mv-add-prefix>

=item 4. L<mv-add-prefix-datestamp>

=item 5. L<mv-add-prefix-number>

=item 6. L<mv-files-to-dirs>

=item 7. L<mv-reverse>

=item 8. L<mv-swap>

=item 9. L<mv-to-from>

=item 10. L<rename-add-prefix>

=item 11. L<rename-add-prefix-datestamp>

=item 12. L<rename-add-prefix-number>

=item 13. L<rename-swap>

=item 14. L<rename-to-from>

=back

=head1 FUNCTIONS

=head2 add_filename_suffix

Usage:

 $new_name = add_filename_suffix($filename, $suffix);

Examples:

 add_filename_suffix("foo.jpg", " (1)"); # -> "foo (1).jpg"
 add_filename_suffix("foo", " (1)"); # -> "foo (1)"

=head2 find_unique_filename

Usage:

 $new_name = find_unique_filename($filename);

Continue adding suffix " (1)", " (2)", and so on to C<$filename> (see
L</add_filename_suffix>) until the new name does not exist on the filesystem. If
C<$filename> already does not exist, it will be returned as-is.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FileRenameUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FileRenameUtils>.

=head1 SEE ALSO

L<rename> from L<File::Rename>

L<perlmv> from L<App::perlmv>, and its various scriptlets under
C<App::perlmv::scriptlet::*>, e.g. L<App::perlmv::scriptlet::add_prefix> or
L<App::perlmv::scriptlet::according_to_containing_dir>.

L<renwd> from L<App::renwd>

Other similar distributions: L<App::FileModifyUtils>,
L<App::FileRemoveUtilities>.

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

This software is copyright (c) 2023, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FileRenameUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
