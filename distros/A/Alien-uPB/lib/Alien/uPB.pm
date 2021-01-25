package Alien::uPB;
# ABSTRACT: build and find uPB (a.k.a. Unleaded)

use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.15'; # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::uPB - build and find uPB (a.k.a. Unleaded)

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Alien::uPB;

    my $cflags = Alien::uPB->cflags;
    my $libs = Alien::uPB->libs;

    # use $cflags and $libs to compile a program using uPB

=head1 AUTHOR

Mattia Barbon <mattia@barbon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mattia Barbon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
