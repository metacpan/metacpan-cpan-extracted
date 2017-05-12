package App::LinguaENUtils;

our $DATE = '2016-01-18'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::LinguaCommonUtils qw(%arg_words %arg_nums);

our %SPEC;

$SPEC{plural_to_singular} = {
    v => 1.1,
    summary => 'Convert plural noun to singular',
    'x.no_index' => 1,
    args => {
        %arg_words,
    },
    result_naked => 1,
};
sub plural_to_singular {
    require Lingua::EN::PluralToSingular;

    my %args = @_;

    [map {Lingua::EN::PluralToSingular::to_singular($_)} @{ $args{words} }];
}

$SPEC{singular_to_plural} = {
    v => 1.1,
    summary => 'Convert singular noun to plural',
    'x.no_index' => 1,
    args => {
        %arg_words,
    },
    result_naked => 1,
};
sub singular_to_plural {
    require Lingua::EN::Inflect;

    my %args = @_;

    [map {Lingua::EN::Inflect::PL($_)} @{ $args{words} }];
}

$SPEC{num_to_word} = {
    v => 1.1,
    summary => 'Convert number (123) to word ("one hundred twenty three")',
    'x.no_index' => 1,
    args => {
        %arg_nums,
    },
    result_naked => 1,
};
sub num_to_word {
    require Lingua::EN::Nums2Words;

    my %args = @_;

    [map {lc(Lingua::EN::Nums2Words::num2word($_))} @{ $args{nums} }];
}

$SPEC{word_to_num} = {
    v => 1.1,
    summary => 'Convert phrase ("one hundred twenty three") to number (123)',
    'x.no_index' => 1,
    args => {
        %arg_words,
    },
    result_naked => 1,
};
sub word_to_num {
    require Lingua::EN::Words2Nums;

    my %args = @_;

    [map {Lingua::EN::Words2Nums::words2nums($_)} @{ $args{words} }];
}

# note: term for converting to_singular & to_plural = inflect (to singular or plural)
# XXX: is_plural (LE:PluralToSingular)
# XXX: stem
# XXX: fathom - measure readability of English text
# XXX: count-syllables (LE:Styllable)
# XXX: namecase - convert johnsmith to JohnSmith
# XXX: prase-verb (LE:VerbTense)
# XXX: split text to sentences (Lingua::EN::Sentence)
# XXX: Identify-EN
# XXX: LE:Segmenter
# XXX: LE:Fractions
# XXX: hyphenate
# XXX: infinitive - define infinitive form of conjugated word, e.g. ?
# XXX: LE:summarize
# XXX: LE:NameParse
# XXX: LE:Conjugate (e.g. verb look + pronoun he + tense perfect_prog + negation = he was not looking)
# XXX: LE:Contraction (e.g. I am not going to explain it, if you cannot' -> I'm not going to explain it, if you can't'
# XXX: LE:FindNumber
# XXX: LE:AddressParse
# XXX: LE:Number:Years (word_to_num_year?)

1;
# ABSTRACT: Command-line utilities related to the English language

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LinguaENUtils - Command-line utilities related to the English language

=head1 VERSION

This document describes version 0.05 of App::LinguaENUtils (from Perl distribution App-LinguaENUtils), released on 2016-01-18.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<en-2plural>

=item * L<en-2singular>

=item * L<en-n2w>

=item * L<en-w2n>

=back

=head1 DESCRIPTION

This distribution will become a collection of CLI utilities related to English
language. Currently it contains very little and the collection will be expanded
in subsequent releases.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-LinguaENUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LinguaENUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LinguaENUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
