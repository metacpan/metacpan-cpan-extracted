package Acme::MJD::FR;

use strict;
use warnings;

our $VERSION = '0.01';

my @advice = <DATA>;

sub advice {
    my $number = shift;
    if ($number) {
	(my $advice) = grep /\Q$number/, @advice;
	return $advice || '';
    }
    else {
	return $advice[int rand @advice];
    }
}

1;

=head1 NAME

Acme::MJD::FR - the wisdom of Klortho the Magnificent, in French

=head1 SYNOPSIS

    use Acme::MJD::Fr;
    print Acme::MJD::Fr::advice;

=head1 DESCRIPTION

MJD's I<Good advice and maxims for programmers>,
translated in idiomatic French by Rafael Garcia-Suarez.

=head1 LICENSE

    (c) Rafael Garcia-Suarez <rgarciasuarez@gmail.com>

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Acme::MJD>

=cut

__DATA__
#11900 Tu peux pas copier coller du code à l'aveugle, et t'attendre à ce que ça marche.
#11901 Tu peux pas inventer des trucs et t'attendre à ce que l'ordinateur devine tout seul ce que ça veut dire, Mongolito!
#11902 Tu as dit que ça ne marchait pas, mais pas ce que ça aurait dû faire si ça avait marché.
#11903 Tu veux faire quoi, là, en fait ?
#11904 On s'en bat les couilles de savoir lequel est le plus rapide.
#11905 Et maintenant nous arrivons au moment où il va falloir consulter la doc.
#11906 Regarde le message d'erreur! Regarde le message d'erreur!
#11907 Chercher un bug dans le compilateur ne se fait qu'en DERNIER ressort. DERNIER ressort.
#11908 L'optimisation prématurée est la mère de tous les vices.
#11909 Mauvais programmeur!  Pas de susucre!
#11910 Je vois que tu n'as pas mis $! dans le message d'erreur. Il va pas te dire ce qui plante si tu lui demandes pas.
#11911 Tu as écrit la même chose deux fois, là. La première règle du savoir programmer est de ne jamais écrire la même chose deux fois.
#11912 Il est évident que ce que tu veux, c'est d'avoir une mauvaise réponse le plus vite possible.
#11913 J'en sais rien moi. Je me demande ce que dit la doc ?
#11914 Ben non. C'est parce que tu as ignoré le message d'erreur.
#11915 Seul Sherlock Holmes peut débugguer le programme par pure déduction à partir de sa sortie. Tu n'est pas Sherlock Holmes. Utilise le putain de débuggueur.
#11916 Toujours ignorer le deuxième message d'erreur sauf si sa signification est évidente.
#11917 Lis. Apprends. Evolue.
#11918 Eh ben prends celui qui fait de l'auto-indentation. On ne fait pas du bon boulot avec des outils pourris.
#11919 Non. Tu dois croire le MESSAGE D'ERREUR. Tu dois CROIRE le message d'erreur.
#11920 Le message d'erreur est la Vérité. Le message d'erreur est Dieu.
#11921 Ca peut venir de n'importe quoi. Dommage que tu n'aies pas songé à tracer l'erreur hein ?
#11922 Tu ne supprimes pas les messages d'erreur, idiot, tu les LIS avec ATTENTION et tu essaies de les comprendre.
#11923 Ne pas intercepter de signal sauf en dernier ressort.
#11924 Bon, si tu sais pas ce que ça fait, pourquoi tu l'as mis dans ton programme ?
#11925 Eh bien, ce n'était pas une très bonne idée, non ?
#11926 C'est un peu comme chier sur le paillasson de quelqu'un et sonner à la porte pour demander du PQ.
#11927 Un bon moyen de résoudre ce problème serait d'embaucher un programmeur.
#11928 D'abord, procure-toi un bouquin sur la programmation. Ensuite lis-le. Enfin, écris le programme.
#11929 D'abord, demande-toi "comment ferais-je sans ordinateur ?". Puis programme l'ordinateur pour le faire de la même façon.
#11930 Tu veux mes tarifs ?
#11931 Je pense que tu poses la mauvaise question.
#11932 Sapristi.
#11933 Parce que c'est une erreur de syntaxe.
#11934 Parce que c'est du Perl, pas du C.
#11935 Parce que c'est du Perl, pas du LISP.
#11936 Parce que c'est comme ça.
#11937 Parce que.
#11938 Si tu as "une erreur chelou", ça vient probablement du vistemboir.
#11939 Parce que l'ordinateur ne peut pas voir dans ton cerveau. Et tu sais quoi ? Moi non plus.
#11940 Tu as dit "ça marche pas". La prochaine infraction sera punie de mort.
#11941 Bien sûr que ça marche pas! C'est parce que tu sais pas ce que tu fais!
#11942 Oui, mais il faut comprendre un peu, aussi.
#11943 Oui, et tu es le premier a avoir remarqué ce bug depuis 1987. C'est cela.
#11944 Oui, c'est ce qu'il est censé faire quand tu dis ça.
#11945 Tu t'attendais à quoi ?
#11946 Tu sembles perdre de vue que ceci est de l'ingénierie logicielle, et non une sorte de rituel vaudou.
#11947 Ce genre de chose peut se vérifier expérimentalement tu sais.
#11948 Peut-être que ton vistemboir est bouché.
#11949 Ca fait quoi quand t'essayes ?
#11950 C'est de la pure superstition.
#11951 Votre question a dépassé la limite système du nombre de pronoms permis pour une seule phrase. Déréférencez et réessayez de nouveau.
#11952 D'après mon expérience, c'est une mauvaise stratégie, parce que les gens qui posent ce genre de questions sont ceux qui vont aussi coller la réponse dans leur code sans comprendre, pour ensuite râler que "ça marche pas".
#11953 Bien sûr, ce n'est qu'une heuristique, ce qui veut dire plus prosaïquement que ça ne marche pas.
#11954 Si cette fonction est écrite correctement, elle acceptera un tableau vide ou non-vide de la même façon.
#11955 Dans le doute, utilise la force brutale.
#11956 C'est peut-être plus intuitif comme ça, mais aussi complètement inutile.
#11957 Fais voir le code.
#11958 Le bug vient de toi, pas de Perl.
#11959 Cargo-culte.
#11960 Donc, tu as mis de la ponctuation au hasard, et tu n'as pas le résultat escompté. Hmmmm.
#11961 Comment je peux deviner ce qui ne va pas sans voir le code ? Je ne suis pas Madame Soleil.
#11962 Comment je peux dire comment faire ce que tu veux faire, alors que tu n'as pas *dit* ce que tu veux faire ?
#11963 Il est facile d'avoir la mauvaise réponse en un temps O(1).
#11964 Je pense que cela ne fait que démontrer qu'il n'y a pire sourd qui ne veut entendre.
#11999 Tu n'es qu'un sombre crétin. Ferme-la.
