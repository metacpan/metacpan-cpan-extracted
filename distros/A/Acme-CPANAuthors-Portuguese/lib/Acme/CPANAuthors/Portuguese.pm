package Acme::CPANAuthors::Portuguese;

use warnings;
use strict;

our $VERSION = '0.04';

use Acme::CPANAuthors::Register (
    BRACETA   => "Luis Azevedo",
    COG       => "José Alves de Castro",
    CVICENTE  => "Carlos Vicente",
    MANU      => "Manuel Valente",
    PLANK     => "Claudio Valente",
    SANTOS    => "José Santos",
    JJOAO     => "José João Dias de Almeida",
    MBATISTA  => "Manuel Batista",
    UNOBE     => "David Romano",
    MELO      => "Pedro Melo",
    BALINHA   => "Ricardo Filipe Liquito Balinha",
    ANUNES    => "Alex Nunes",
    AMBS      => "Alberto Manuel Brandao Simões",
    NEVES     => "Marco Neves",
    NFMNUNES  => "Nuno Nunes",
    ROOT      => "Rúben Fonseca",
    SMASH     => "Nuno Carvalho",
    JOAOP     => "João Pedro Goncalves",
    JGDA      => "Jonas Galhordas Duarte Alves",
    LEITE     => "Pedro Leite",
    ZBUH      => "Nuno Martins",                           #
    DMCS      => "Diogo Miguel Constantino dos Santos",    #
    MARISABT  => "Marisa Fernanda Pereira Brites",         #
    MALDUARTE => "Miguel Angelo Lapa Duarte",              #
    MEGA      => "Cristina Martins Nunes",                 #
    JPO       => "Jose Pedro Oliveira",                    #
    HUGOCOSTA => "Hugo Costa",                             #
    BONANZA   => "Paulo Dutra",                            #
    DBCM      => "Delfim Machado",                         #
    JACM      => "José Machado",                           #
    JRG       => "João Gomes",                             #
    CAO       => "José Pinheiro Neta",                     #
    FARO      => "Tiago Faro Pedroso",                     #
    ACARVALHO => "Alexandre Martins de Carvalho",          #
    FAPG      => "Fernando A. P. Gomes",                   #
    STRANGE   => "Luciano Miguel Ferreira Rocha",          #
    AFFC      => "Ari Constâncio",                         #

);

__END__

# If you are reading this source code, you probably need to grab some beers instead... O:)

=head1 NAME

Acme::CPANAuthors::Portuguese - We are the Portuguese CPAN Authors

=head1 SYNOPSIS

	use Acme::CPANAuthors;

	my $authors = Acme::CPANAuthors->new('Portuguese');

	my $number   = $authors->count;
	my @ids      = $authors->ids();
	my @distros  = $authors->distributions('BRACETA');
	my $url      = $authors->avatar_url('COG');
	my $kwalitee = $authors->kwalitee('BALINHA');
	my $name     = $authors->name('AMBS');

=head1 DESCRIPTION

This class provides a hash of Portuguese CPAN authors' PAUSE ID and name to the Acme::CPANAuthors module.

=head1 MAINTENANCE

If you are an Portuguese CPAN author not listed here, please send me your
ID/name via email or RT so we can always keep this module up to date.
If there's a mistake and you're listed here but are not Portuguese
(or just don't want to be listed), sorry for the inconvenience:
please contact me and I'll remove the entry right away.

=head1 AUTHOR

Luis Azevedo (Braceta), C<< <braceta at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-cpanauthors-portuguese at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-CPANAuthors-Portuguese>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::CPANAuthors::Portuguese


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CPANAuthors-Portuguese>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-CPANAuthors-Portuguese>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-CPANAuthors-Portuguese>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-CPANAuthors-Portuguese/>

=item * Github - get the source code

L<http://github.com/braceta/acme-cpanauthors-portuguese/>

=back


=head1 ACKNOWLEDGEMENTS

All the Lisbon.pm guys and Cog for the idea for this module.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Luis Azevedo (Braceta), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::CPANAuthors::Portuguese
