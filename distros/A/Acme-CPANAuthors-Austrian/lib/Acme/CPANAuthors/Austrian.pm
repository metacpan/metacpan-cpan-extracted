use 5.008;
use strict;
use warnings;
use utf8;

package Acme::CPANAuthors::Austrian;
our $VERSION = 1.131810;
# ABSTRACT: We are Austrian CPAN authors

use Acme::CPANAuthors::Register (
    ANDK     => 'Andreas J. König',
    AREIBENS => 'Alfred Reibenschuh',
    DOMM     => 'Thomas Klausner',
    DRRHO    => 'Robert Barta',
    FLORIAN  => 'Florian Helmberger',
    GARGAMEL => 'Karlheinz Zöchling',
    GORTAN   => 'Philipp Gortan',
    KALEX    => 'Alexander Keusch',
    LAMMEL   => 'Roland Lammel',
    LANTI    => 'Ingo Lantschner',
    MARCEL   => 'Marcel Gruenauer == hanekomu',
    MAROS    => 'Maroš Kollár',
    NINE     => 'Stefan Seifert',
    NUFFIN   => 'Yuval Kogman',
    OPITZ    => 'Oliver Falk',
    PEPL     => 'Michael Kröll',
    RGIERSIG => 'Roland Giersig',
    RURBAN   => 'Reini Urban',
    ZEYA     => 'Hansjörg Pehofer',
);
1;

__END__

=pod

=head1 NAME

Acme::CPANAuthors::Austrian - We are Austrian CPAN authors

=head1 VERSION

version 1.131810

=head1 SYNOPSIS

   use Acme::CPANAuthors;
   use Acme::CPANAuthors::Austrian;

   my $authors = Acme::CPANAuthors->new('Austrian');

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions('MARCEL');
   my $url      = $authors->avatar_url('DOMM');
   my $kwalitee = $authors->kwalitee('GARGAMEL');

=head1 DESCRIPTION

This class provides a hash of Pause ID/name of Austrian CPAN authors.

=head1 MAINTENANCE

If you are an Austrian CPAN author and are not listed here, please
mail the maintainers.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-Austrian>.

=head1 AVAILABILITY

The project homepage is L<http://search.cpan.org/dist/Acme-CPANAuthors-Austrian/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Acme::CPANAuthors::Austrian/>.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Philipp Gortan <gortan@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
