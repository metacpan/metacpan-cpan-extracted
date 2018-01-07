package Complete::PPR;

our $DATE = '2017-12-31'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

use Exporter 'import';
our @EXPORT_OK = qw(
                       complete_ppr_subpattern
               );

our $SubPatterns = ["PerlDocument","PerlStatement","PerlExpression","PerlLowPrecedenceNotExpression","PerlAssignment","PerlScalarExpression","PerlBinaryExpression","PerlPrefixPostfixTerm","PerlTerm","PerlLvalue","PerlControlBlock","PerlDoBlock","PerlEvalBlock","PerlStatementModifier","PerlFormat","PerlBlock","PerlCall","PerlAttributes","PerlCommaList","PerlParenthesesList","PerlList","PerlAnonymousArray","PerlAnonymousHash","PerlArrayIndexer","PerlHashIndexer","PerlDiamondOperator","PerlComma","PerlPrefixUnaryOperator","PerlPostfixUnaryOperator","PerlInfixBinaryOperator","PerlAssignmentOperator","PerlLowPrecedenceInfixOperator","PerlAnonymousSubroutine","PerlVariable","PerlVariableScalar","PerlVariableArray","PerlVariableHash","PerlTypeglob","PerlScalarAccess","PerlScalarAccessNoSpace","PerlScalarAccessNoSpaceNoArrow","PerlArrayAccess","PerlArrayAccessNoSpace","PerlArrayAccessNoSpaceNoArrow","PerlHashAccess","PerlLabel","PerlLiteral","PerlString","PerlQuotelike","PerlHeredoc","PerlQuotelikeQ","PerlQuotelikeQQ","PerlQuotelikeQW","PerlQuotelikeQX","PerlSubstitution","PerlTransliteration","PerContextuallMatch","PerlMatch","PerlQuotelikeQR","PerlContextualRegex","PerlRegex","PerlBuiltinFunction","PerlNullaryBuiltinFunction","PerlVersionNumber","PerlVString","PerlNumber","PerlIdentifier","PerlQualifiedIdentifier","PerlOldQualifiedIdentifier","PerlBareword","PerlPod","PerlOWS","PerlNWS","PerlEndOfLine","PerlKeyword"]; # PRECOMPUTE

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to PPR',
};

$SPEC{complete_ppr_subpattern} = {
    v => 1.1,
    summary => 'Complete from available PPR subpattern names',
    args => {
        %arg_word,
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_ppr_subpattern {
    require Complete::Util;

    my %args  = @_;
    Complete::Util::complete_array_elem(%args, array => $SubPatterns);
}

1;
# ABSTRACT: Completion routines related to PPR

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::PPR - Completion routines related to PPR

=head1 VERSION

This document describes version 0.001 of Complete::PPR (from Perl distribution Complete-PPR), released on 2017-12-31.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_ppr_subpattern

Usage:

 complete_ppr_subpattern(%args) -> array

Complete from available PPR subpattern names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-PPR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-PPR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-PPR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
