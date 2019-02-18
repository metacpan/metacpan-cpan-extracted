package Acme::CPANModules::ConvertingToRegex;

our $DATE = '2019-02-17'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Convert various stuffs to regular expression',
    tags => ['task'],
    entries => [
        {module=>'Number::Range::Regex', summary=>'from number range'},
        {module=>'Regex::Range::Number', summary=>'from number range'},
        {module=>'Regexp::English', summary=>'From a more verbose English specification'},
        {module=>'Regexp::Shellish', summary=>'From shell wildcard'},
        {module=>'Regexp::Wildcards', summary=>'From shell wildcard (include Win32 shell)'},
        {module=>'String::Wildcard::DOS', summary=>'From DOS wildcard'},
        {module=>'String::Wildcard::SQL', summary=>'From SQL wildcard'},
        {module=>'String::Wildcard::Bash', summary=>'From Bash wildcard'},
    ],
};

1;
# ABSTRACT: Convert various stuffs to regular expression

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ConvertingToRegex - Convert various stuffs to regular expression

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ConvertingToRegex (from Perl distribution Acme-CPANModules-ConvertingToRegex), released on 2019-02-17.

=head1 DESCRIPTION

Convert various stuffs to regular expression.

=head1 INCLUDED MODULES

=over

=item * L<Number::Range::Regex> - from number range

=item * L<Regex::Range::Number> - from number range

=item * L<Regexp::English> - From a more verbose English specification

=item * L<Regexp::Shellish> - From shell wildcard

=item * L<Regexp::Wildcards> - From shell wildcard (include Win32 shell)

=item * L<String::Wildcard::DOS> - From DOS wildcard

=item * L<String::Wildcard::SQL> - From SQL wildcard

=item * L<String::Wildcard::Bash> - From Bash wildcard

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ConvertingToRegex>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ConvertingToRegex>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ConvertingToRegex>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::ConvertingFromRegex>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
