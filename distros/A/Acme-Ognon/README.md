# NAME

Acme::Ognon - Suivez le Conseil supérieur de la langue française ... peut-être

# VERSION

1990.8

# DESCRIPTION

Acme::Ognon existe pour suivre le Conseil supérieur de la langue française
à la lettre... peut-être. Le module supprime et ajoute, de temps en temps,
des accents circonflexes sur les lettres « i » et « u ».

Le module a deux fonctions : `ognon` pour supprimer des accents 
circonflexes et `oignon` pour en ajouter. Gardez à l'esprit que ces 
opérations ne s'effectuent que de temps en temps.

# SYNOPSIS

    use Acme::Ognon qw/ ognon oignon /;

    my $peut_etre_sans_accent_circonflexe = ognon( 'coût' );
        my $peut_etre_avec_accent_circonflexe = oignon( 'cout' );

# REMERCIEMENTS

Merci au Conseil supérieur de la langue française, bien sûr ! Hein,
bien sur ! Je pense...

# VOIR AUSSI

[https://fr.wikipedia.org/wiki/Rectifications\_orthographiques\_du\_français\_en\_1990](https://fr.wikipedia.org/wiki/Rectifications_orthographiques_du_français_en_1990)

# AUTEUR

Lee Johnson - `leejo@cpan.org`

# LICENCE

Cette bibliothèque est un logiciel libre ; vous pouvez la redistribuer et/ou
la modifier selon les mêmes conditions que Perl lui-même. 

Si vous souhaitez contribuer (documentation, fonctionnalités, corrections de 
bugs, etc), merci de soumettre un _pull request_ ou de remplir un ticket à 
l'adresse suivante :

    https://github.com/leejo/acme-ognon
