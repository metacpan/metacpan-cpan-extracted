package Alien::LibJQ;
use strict;
use warnings;
use base qw/Alien::Base/;
use vars qw/$VERSION/;

$VERSION = '0.06';

=head1 NAME

Alien::LibJQ - Build libjq library (https://stedolan.github.io/jq/)

=head1 SYNOPSIS

  In C<Makefile.PL>:
    use strict;
    use warnings;

    use ExtUtils::MakeMaker;
    use Alien::Base::Wrapper;

    ...
    WriteMakefile(
        Alien::Base::Wrapper->new('Alien::LibJQ')->mm_args2(
            ...
            CONFIGURE_REQUIRES => {
                ...
                'Alien::LibJQ' => '0.01',
                ...
            },
            ...
        ),
    );
    ...

=head1 DESCRIPTION

Provide libjq.so to other modules.

=head1 AUTHOR

    Dongxu Ma
    CPAN ID: DONGXU
    dongxu __at__ cpan.org
    https://github.com/dxma/perl5-cpan

=head1 COPYRIGHT

This program is free software licensed under the...

	The MIT License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;
