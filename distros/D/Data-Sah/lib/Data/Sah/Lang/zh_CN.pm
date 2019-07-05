package Data::Sah::Lang::zh_CN;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010;
use strict;
use utf8;
use warnings;

use Tie::IxHash;

# currently incomplete

our %translations;
tie %translations, 'Tie::IxHash', (

    # punctuations

    q[ ], # inter-word boundary
    q[],

    q[, ],
    q[，],

    q[: ],
    q[：],

    q[. ],
    q[。],

    q[(],
    q[（],

    q[)],
    q[）],

    # modal verbs

    q[must],
    q[必须],

    q[must not],
    q[必须不],

    q[should],
    q[应],

    q[should not],
    q[应不],

    # field/fields/argument/arguments

    q[field],
    q[字段],

    q[fields],
    q[字段],

    q[argument],
    q[参数],

    q[arguments],
    q[参数],

    # multi

    q[%s and %s],
    q[%s和%s],

    q[%s or %s],
    q[%s或%s],

    q[one of %s],
    q[这些值%s之一],

    q[all of %s],
    q[所有这些值%s],

    q[%(modal_verb)s satisfy all of the following],
    q[%(modal_verb)s满足所有这些条件],

    q[%(modal_verb)s satisfy one of the following],
    q[%(modal_verb)s满足这些条件之一],

    q[%(modal_verb)s satisfy none of the following],
    q[%(modal_verb_neg)s满足所有这些条件],

    # type: BaseType

    # type: Sortable

    # type: Comparable

    # type: HasElems

    # type: num

    # type: int

    q[integer],
    q[整数],

    q[integers],
    q[整数],

    q[%(modal_verb)s be divisible by %s],
    q[%(modal_verb)s被%s整除],

    q[%(modal_verb)s leave a remainder of %2$s when divided by %1$s],
    q[除以%1$s时余数%(modal_verb)s为%2$s],

    # messages for compiler
);

1;
# ABSTRACT: zh_CN locale

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Lang::zh_CN - zh_CN locale

=head1 VERSION

This document describes version 0.896 of Data::Sah::Lang::zh_CN (from Perl distribution Data-Sah), released on 2019-07-04.

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
