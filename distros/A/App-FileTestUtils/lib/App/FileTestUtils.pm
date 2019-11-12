package App::FileTestUtils;

our $DATE = '2019-09-29'; # DATE
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: More CLIs for file testing

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FileTestUtils - More CLIs for file testing

=head1 VERSION

This document describes version 0.002 of App::FileTestUtils (from Perl distribution App-FileTestUtils), released on 2019-09-29.

=head1 DESCRIPTION

This distributions provides the following command-line utilities which are
related to file testing:

=over

=item * L<dir-empty>

=item * L<dir-has-dot-files>

=item * L<dir-has-dot-subdirs>

=item * L<dir-has-files>

=item * L<dir-has-non-dot-files>

=item * L<dir-has-non-dot-subdirs>

=item * L<dir-has-subdirs>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FileTestUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FileTestUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FileTestUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

The file testing operators in L<perlfunc>, e.g. C<-s>, C<-x>, C<-r>, etc.

L<File::MoreUtil>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
