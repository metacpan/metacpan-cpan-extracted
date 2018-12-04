#
# This file is part of Acme-CPANAuthors-Danish
#
# This software is copyright (c) 2011 by Kaare Rasmussen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Acme::CPANAuthors::Danish;
# ABSTRACT: We are Danish CPAN authors
$Acme::CPANAuthors::Danish::VERSION = '0.04';
use strict;
use warnings;
use utf8;

use Acme::CPANAuthors::Register (
    ABH      => 'Ask Bjørn Hansen',
    GRUBER   => 'Anton Berezon',
    WARMING  => 'Casper Warming',
    BORUP    => 'Christian Borup',
    KARASIK  => 'Dmitry Karasik',
    UNIEJO   => 'Erik Johansen',
    HTOUG    => 'Henrik Tougaard',
    JONASBN  => 'jonasbn',
    KAARE    => 'Kaare Rasmussen',
    LBR      => 'Lars Balker',
    LTHEGLER => 'Lars Thegler',
    LEGART   => 'Michael Legart',
    MADZ     => 'Michael Anton Dines Zedeler',
    THOMAS   => 'Thomas Eibner',
    TLBDK    => 'Troels Liebe Bentsen',
);


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::CPANAuthors::Danish - We are Danish CPAN authors

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use Acme::CPANAuthors;
    use Acme::CPANAuthors::Danish;

    my $authors = Acme::CPANAuthors->new('Danish');

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions('ABH');
    my $url      = $authors->avatar_url('JONASBN');
    my $kwalitee = $authors->kwalitee('MADZ');

=head1 DESCRIPTION

This class provides a hash of Pause ID/name of Danish CPAN authors.

=head1 MAINTENANCE

If you are an Danish CPAN author and are not listed here, please mail me. If
you are listed and don't want to be, mail me as well.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one.

=head1 AUTHOR

Kaare Rasmussen <kaare@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
