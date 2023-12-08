package App::FileTestUtils;

use strict 'subs', 'vars';
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-30'; # DATE
our $DIST = 'App-FileTestUtils'; # DIST
our $VERSION = '0.005'; # VERSION

use Getopt::Long qw(:config auto_help auto_version gnu_getopt no_ignore_case);

sub do_script {
    require File::Util::Test;
    my ($func) = @_;

    (my $script = $func) =~ s/_/-/g;

    my $opt_grep_mode;
    my $opt_invert_match;
    GetOptions(
        "grep-mode|g" => \$opt_grep_mode,
        "invert-match|v" => \$opt_invert_match,
    ) or die "$script: Error in processing command-line options, exiting\n";

    if ($opt_grep_mode) {
        my @files = @ARGV;
        unless (@files) { chomp(@files = <STDIN>) }
        for my $file (@files) {
            if (&{"File::Util::Test::$func"}($file) xor $opt_invert_match) { print $file, "\n" }
        }
        exit 0;
    } else {
        unless (@ARGV == 1) {
            die "Usage: $script <path>\n";
        }
        exit(&{"File::Util::Test::$func"}($ARGV[0]) ? 0:1);
    }
}

1;
# ABSTRACT: More CLIs for file testing

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FileTestUtils - More CLIs for file testing

=head1 VERSION

This document describes version 0.005 of App::FileTestUtils (from Perl distribution App-FileTestUtils), released on 2023-11-30.

=head1 DESCRIPTION

This distributions provides the following command-line utilities which are
related to file testing:

=over

=item 1. L<dir-empty>

=item 2. L<dir-has-dot-files>

=item 3. L<dir-has-dot-subdirs>

=item 4. L<dir-has-files>

=item 5. L<dir-has-non-dot-files>

=item 6. L<dir-has-non-dot-subdirs>

=item 7. L<dir-has-subdirs>

=item 8. L<dir-not-empty>

=item 9. L<dir-only-has-dot-files>

=item 10. L<dir-only-has-dot-subdirs>

=item 11. L<dir-only-has-files>

=item 12. L<dir-only-has-non-dot-files>

=item 13. L<dir-only-has-non-dot-subdirs>

=item 14. L<dir-only-has-subdirs>

=back

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FileTestUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FileTestUtils>.

=head1 SEE ALSO

The file testing operators in L<perlfunc>, e.g. C<-s>, C<-x>, C<-r>, etc.

L<File::Util::Test>

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

This software is copyright (c) 2023, 2021, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FileTestUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
