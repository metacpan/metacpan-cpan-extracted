package String::Indent::Join;

#use 5.010001;
use strict;
use warnings;

use Exporter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-27'; # DATE
our $DIST = 'Bencher-Scenarios-StringFunctions'; # DIST
our $VERSION = '0.006'; # VERSION

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       indent
               );

sub indent {
    my ($indent, $str) = @_;

    #$opts //= {};
    #my $ibl = $opts->{indent_blank_lines} // 1;
    #my $fli = $opts->{first_line_indent} // $indent;
    #my $sli = $opts->{subsequent_lines_indent} // $indent;
    ##say "D:ibl=<$ibl>, fli=<$fli>, sli=<$sli>";

    join("", map {($indent, $_)} split /^/m, $str);
}

1;
# ABSTRACT: String indenting routines

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Indent::Join - String indenting routines

=head1 VERSION

This document describes version 0.006 of String::Indent::Join (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2022-03-27.

=head1 FUNCTIONS

=head2 indent

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-StringFunctions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-StringFunctions>.

=head1 SEE ALSO

L<String::Indent>, L<String::Nudge>

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

This software is copyright (c) 2022, 2021, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-StringFunctions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
