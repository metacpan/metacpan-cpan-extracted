# -*- encoding: utf-8; indent-tabs-mode: nil -*-

package Arithmetic::PaperAndPencil::Label;

use 5.38.0;
use utf8;
use strict;
use warnings;
use open ':encoding(UTF-8)';

our $VERSION = '0.01';

my %label = ('fr' => {
                 'TIT01' => 'Addition (base #1#)'
               , 'TIT02' => 'Soustraction de #1# et #2# (base #3#)'
               , 'TIT03' => 'Multiplication de #1# et #2#, procédé standard, base #3#'
               , 'TIT04' => 'Multiplication de #1# et #2#, procédé avec raccourci, base #3#'
               , 'TIT05' => 'Multiplication de #1# et #2#, avec préparation, base #3#'
               , 'TIT06' => 'Multiplication de #1# et #2#, procédé "par jalousie" (A), base #3#'
               , 'TIT07' => 'Multiplication de #1# et #2#, procédé "par jalousie" (B), base #3#'
               , 'TIT08' => 'Multiplication de #1# et #2#, procédé "bateau", base #3#'
               , 'TIT09' => 'Division de #1# par #2#, procédé standard, base #3#'
               , 'TIT10' => 'Division de #1# par #2#, procédé standard avec triche, base #3#'
               , 'TIT11' => 'Division de #1# par #2#, avec préparation, base #3#'
               , 'TIT12' => 'Division de #1# par #2#, procédé "bateau", base #3#'
               , 'TIT13' => 'Racine carrée de #1#, base #2#'
               , 'TIT14' => 'Conversion de #1#, base #2# vers base #3#, multiplications en cascade (schéma de Horner)'
               , 'TIT15' => 'Soustraction de #1# et #2# par addition du complément à #3#'
               , 'TIT16' => 'Conversion de #1#, base #2# vers base #3#, divisions en cascade'
               , 'TIT17' => 'PGCD de #1# et #2#, base #3#'
               , 'TIT18' => 'PGCD de #1# et #2#, base #3#, avec triche'
               , 'TIT19' => 'Multiplication de #1# et #2#, procédé "du paysan russe", base #3#'
               , 'NXP01' => 'Changement de page'
               , 'ADD01' => '#1# et #2#, #3#'
               , 'ADD02' => 'et #1#, #2#'
               , 'WRI01' => "J'écris #1#"
               , 'WRI02' => "Je pose #1# et je retiens #2#"
               , 'WRI03' => "Je pose #1# et je ne retiens rien"
               , 'WRI04' => "Je pose #1#"
               , 'WRI05' => "Je recopie la ligne #1#"
               , 'MUL01' => '#1# fois #2#, #3#'
               , 'MUL02' => 'Fastoche, #1# fois #2#, #3#'
               , 'MUL03' => '#1# est pair, je barre #2#'
               , 'CNV01' => 'Fastoche, #1# converti de la base #2# vers la base #3# donne #1#'
               , 'CNV02' => 'La conversion de #1# donne #2#'
               , 'CNV03' => 'Déjà converti : #1#, reste à convertir : #2#'
               , 'SUB01' => '#1# et #2#, #3#'
               , 'SUB02' => 'et #1#, #2#'
               , 'SUB03' => 'Le complément à #1# de #2# est #3#'
               , 'SUB04' => "J'élimine le chiffre de gauche et le résultat est #1#"
               , 'DIV01' => 'En #1# combien de fois #2#, il y va #3# fois'
               , 'DIV02' => "C'est trop fort, j'essaie #1#"
               , 'DIV03' => "Je triche, j'essaie directement #1#"
               , 'DIV04' => "J'abaisse le #1#"
               , 'DIV05' => 'Fastoche, #1# divisé par 1 donne #1#, reste 0'
               , 'DIV06' => 'Fastoche, #1# divisé par #2# donne 0, reste #1#'
               , 'DIV07' => 'En #1# combien de fois 2, il y va #2# fois, reste #3#'
               , 'SQR01' => 'Racine carrée de #1# égale #2#'
               , 'SHF01' => 'Je décale #1#, ce qui donne #2#'
               }
          , 'en' => {
                 'TIT01' => 'Addition (radix #1#)'
               , 'TIT02' => 'Subtraction of #1# and #2# (radix #3#)'
               , 'TIT03' => 'Multiplication of #1# and #2#, standard processus, radix #3#'
               , 'TIT04' => 'Multiplication of #1# and #2#, with short-cuts, radix #3#'
               , 'TIT05' => 'Multiplication of #1# and #2#, with preparation, radix #3#'
               , 'TIT06' => 'Multiplication of #1# and #2#, "jalousie" processus (A), radix #3#'
               , 'TIT07' => 'Multiplication of #1# and #2#, "jalousie" processus (B), radix #3#'
               , 'TIT08' => 'Multiplication of #1# and #2#, "boat" processus, radix #3#'
               , 'TIT09' => 'Division of #1# by #2#, standard processus, radix #3#'
               , 'TIT10' => 'Division of #1# by #2#, with cheating, radix #3#'
               , 'TIT11' => 'Division of #1# by #2#, with preparation, radix #3#'
               , 'TIT12' => 'Division of #1# by #2#, "boat" processus, radix #3#'
               , 'TIT13' => 'Square root of #1#, radix #2#'
               , 'TIT14' => 'Conversion of #1#, radix #2# to radix #3#, cascading multiplications (Horner scheme)'
               , 'TIT15' => 'Subtraction of #1# and #2# by adding the #3#-complement)'
               , 'TIT16' => 'Conversion of #1#, radix #2# to radix #3#, cascading divisions'
               , 'TIT17' => 'GCD of #1# and #2#, radix #3#'
               , 'TIT18' => 'GCD of #1# and #2#, radix #3#, cheating'
               , 'TIT19' => 'Multiplication of #1# and #2#, "Russian peasant" processus, radix #3#'
               , 'MUL01' => '#1# times #2#, #3#'    # guesswork
               }
               )
               ;

our sub full_label($label, $val1, $val2, $val3, $ln) {
  my $result;
  if ($label{$ln}{$label}) {
    $result = $label{$ln}{$label};
  }
  else {
    return undef;
  }
  $result =~ s/\#1\#/$val1/g;
  $result =~ s/\#2\#/$val2/g;
  $result =~ s/\#3\#/$val3/g;
  return $result;
}

'Zéro plus zéro égale la tête à Toto'; # End of Arithmetic::PaperAndPencil::Label

=head1 NAME

Arithmetic::PaperAndPencil::Label -- Used internally by Arithmetic::PaperAndPencil

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Arithmetic::PaperAndPencil::Action;
    use Arithmetic::PaperAndPencil::Label;
    my $action = Arithmetic::PaperAndPencil::Label->new(level => $lvl, label => ...);
    my $line = Arithmetic::PaperAndPencil::Label::full_label($action->label
                                                           , $action->val1
                                                           , $action->val2
                                                           , $action->val3
                                                           , $lang);

=head1 EXPORT

None.

=head1 SUBROUTINES/METHODS

=head2 full_label

Retrieves  the label  from the  hashtable and  replaces variable  tags
(C<#1#> and similar) with the proper values.

=head1 AUTHOR

Jean Forget, C<< <J2N-FORGET at orange.fr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-arithmetic-paperandpencil at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Arithmetic-PaperAndPencil>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Arithmetic::PaperAndPencil


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Arithmetic-PaperAndPencil>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Arithmetic-PaperAndPencil>

=item * Search CPAN

L<https://metacpan.org/release/Arithmetic-PaperAndPencil>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by jforget.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

