package String::Indent::Join;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-31'; # DATE
our $DIST = 'Bencher-Scenarios-StringFunctions'; # DIST
our $VERSION = '0.005'; # VERSION

#use 5.010001;
use strict;
use warnings;

use Exporter;
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

This document describes version 0.005 of String::Indent::Join (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2021-07-31.

=head1 FUNCTIONS

=head2 indent

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-StringFunctions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-StringFunctions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-StringFunctions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<String::Indent>, L<String::Nudge>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
