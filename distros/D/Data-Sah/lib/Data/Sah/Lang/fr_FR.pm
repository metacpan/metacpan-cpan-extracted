package Data::Sah::Lang::fr_FR;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use 5.010;
use strict;
use warnings;

use Tie::IxHash;

# currently incomplete

our %translations;
tie %translations, 'Tie::IxHash', (

    # punctuations

    q[ ], # inter-word boundary
    q[ ],

    q[, ],
    q[, ],

    q[: ],
    q[: ],

    q[. ],
    q[. ],

    q[(],
    q[(],

    q[)],
    q[)],

    # modal verbs

    q[must],
    q[doit],

    q[must not],
    q[ne doit pas],

    q[should],
    q[devrait],

    q[should not],
    q[ne devrait pas],

    # field/fields/argument/arguments

    q[field],
    q[champ],

    q[fields],
    q[champs],

    q[argument],
    q[argument],

    q[arguments],
    q[arguments],

    # multi

    q[%s and %s],
    q[%s et %s],

    q[%s or %s],
    q[%s ou %s],

    q[one of %s],
    q[une des %s],

    q[all of %s],
    q[toutes les valeurs %s],

    q[%(modal_verb)s satisfy all of the following],
    q[%(modal_verb)s satisfaire à toutes les conditions suivantes],

    q[%(modal_verb)s satisfy one of the following],
    q[%(modal_verb)s satisfaire l'une des conditions suivantes],

    q[%(modal_verb)s satisfy none of the following],
    q[%(modal_verb)s satisfaire à aucune des conditions suivantes],

    # type: BaseType

    # type: Sortable

    # type: Comparable

    # type: HasElems

    # type: num

    # type: int

    q[integer],
    q[nombre entier],

    q[integers],
    q[nombres entiers],

    q[%(modal_verb)s be divisible by %s],
    q[%(modal_verb)s être divisible par %s],

    q[%(modal_verb)s leave a remainder of %2$s when divided by %1$s],
    q[%(modal_verb)s laisser un reste %2$s si divisé par %1$s],

    # messages for compiler
);

1;
# ABSTRACT: fr_FR locale

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Lang::fr_FR - fr_FR locale

=head1 VERSION

This document describes version 0.897 of Data::Sah::Lang::fr_FR (from Perl distribution Data-Sah), released on 2019-07-19.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
