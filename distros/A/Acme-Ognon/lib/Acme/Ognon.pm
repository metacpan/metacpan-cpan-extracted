 package Acme::Ognon;

=encoding utf8

=head1 NAME

Acme::Ognon - Suivez le Conseil supérieur de la langue française ... peut-être

=head1 VERSION

1990.8

=head1 DESCRIPTION

Acme::Ognon existe pour suivre le Conseil supérieur de la langue française
à la lettre... peut-être. Le module supprime et ajoute, de temps en temps,
des accents circonflexes sur les lettres S<« i »> et S<« u »>.

Le module a deux S<fonctions :> C<ognon> pour supprimer des accents 
circonflexes et C<oignon> pour en ajouter. Gardez à l'esprit que ces 
opérations ne s'effectuent que de temps en temps.

=head1 SYNOPSIS

    use Acme::Ognon qw/ ognon oignon /;

    my $peut_etre_sans_accent_circonflexe = ognon( 'coût' );
	my $peut_etre_avec_accent_circonflexe = oignon( 'cout' );

=cut

use strict;
use warnings;

require Exporter;
use vars qw/ @ISA @EXPORT_OK @EXPORT /;
@ISA       = qw/ Exporter /;
@EXPORT    = qw/ ognon oignon /;

$Acme::Ognon::VERSION = "1990.8";

sub ognon {
	my ( $text ) = @_;

	$text =~ s/î/i/g if rand(10) > 5;
	$text =~ s/Î/I/g if rand(10) > 5;
	$text =~ s/û/u/g if rand(10) > 5;
	$text =~ s/Û/U/g if rand(10) > 5;

	return $text;
}

sub oignon {
	my ( $text ) = @_;

	$text =~ s/i/î/g if rand(10) > 5;
	$text =~ s/I/Î/g if rand(10) > 5;
	$text =~ s/u/û/g if rand(10) > 5;
	$text =~ s/U/Û/g if rand(10) > 5;

	return $text;
}

=head1 REMERCIEMENTS

Merci au Conseil supérieur de la langue française, bien S<sûr !> Hein,
bien S<sur !> Je pense...

=head1 VOIR AUSSI

L<https://fr.wikipedia.org/wiki/Rectifications_orthographiques_du_français_en_1990>

=head1 AUTEUR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENCE

Cette bibliothèque est un logiciel S<libre ;> vous pouvez la redistribuer et/ou
la modifier selon les mêmes conditions que Perl lui-même. 

Si vous souhaitez contribuer (documentation, fonctionnalités, corrections de 
bugs, etc), merci de soumettre un I<pull request> ou de remplir un ticket à 
l'adresse S<suivante :>

    https://github.com/leejo/acme-ognon


=cut

1;
