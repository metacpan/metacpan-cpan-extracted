package Acme::CPANAuthors::Catalonian;

use warnings;
use strict;
use utf8;

our $VERSION = '0.02';

use Acme::CPANAuthors::Register ( ALEXM     => 'Alex Muntada',
                                  BREQUESEN => 'Bernat Requesens',
                                  DIEGOK    => 'Diego Kuperman',
                                  ENELL     => 'Enrique Nell',
                                  FXN       => 'Xavier Noria',
                                  JAVIER    => 'Javier Arturo Rodríguez Gutiérrez',
                                  JLMARTIN  => 'Jose Luis Martínez',
                                  MRUIZ     => 'Miquel Ruiz',
                                );

__END__

=head1 NAME

Acme::CPANAuthors::Catalonian - We are the Catalonian CPAN Authors

=head1 SYNOPSIS

	use Acme::CPANAuthors;

	my $authors = Acme::CPANAuthors->new('Catalonian');

	my $number   = $authors->count;
	my @ids      = $authors->ids();
	my @distros  = $authors->distributions('MRUIZ');
	my $url      = $authors->avatar_url('ENELL');

=head1 DESCRIPTION

This class provides a hash of Catalonian CPAN authors' PAUSE ID and name
to the Acme::CPANAuthors module.

=head1 MAINTENANCE

If you are an Catalonian CPAN author not listed here, please send me your
ID/name via email or RT so we can always keep this module up to date.
If there's a mistake and you're listed here but are not Catalan
(or just don't want to be listed), sorry for the inconvenience:
please contact me and I'll remove the entry right away.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-cpanauthors-catalonian@rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-CPANAuthors-Catalonian>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::CPANAuthors::Catalonian

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CPANAuthors-Catalonian>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-CPANAuthors-Catalonian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-CPANAuthors-Catalonian>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-CPANAuthors-Catalonian/>

=item * Github - get the source code

L<http://github.com/pplu/p5-Acme-CPANAuthors-Catalonian>

=back

=head1 COPYRIGHT & LICENSE

This module is in the public domain.

=cut

1; # End of Acme::CPANAuthors::Catalonian
