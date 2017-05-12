package Acme::MetaSyntactic::christmas;

our $DATE = '2017-02-04'; # DATE
our $VERSION = '0.003'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: The Christmas theme

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::christmas - The Christmas theme

=head1 VERSION

This document describes version 0.003 of Acme::MetaSyntactic::christmas (from Perl distribution Acme-MetaSyntactic-christmas), released on 2017-02-04.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=christmas -le 'print metaname'
 rudolph

 % meta christmas 2
 santa
 frosty

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-christmas>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-christmas>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-christmas>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::MetaSyntactic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# default
:all
# names santa
santa saint clause nicholas nick kris kringle santy
# names elf
bushy evergreen
shinny upatree
wunorse opneslae
pepper minstix
sugarplum mary
alabaster snowball
# names snowman
frosty
jingle merry bells tinkle angel twinkle rosie holly berry festive
candy magic sparkle sugarplum joy tinsel robin cookie hope sweetie
teddy jolly cosy sherry eve pinky
mcsnowy mcslushy mcchilly mcglisten mcsparkle mcfrosty
mcfreeze mcsnowballs mcicicles mcblizzard mcsparkles mcsnowflakes
# names reindeer
dasher
dancer
prancer
vixen
comet
cupid
donner
blitzen
rudolf
