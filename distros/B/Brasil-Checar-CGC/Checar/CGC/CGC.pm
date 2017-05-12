package Brasil::Checar::CGC;

#################################################################
#								#
# (c) 1997-2000 Equipe Olimpus, todos os direitos reservados	#
#								#
#               Author:	Paul Pierre Hodel (paul@olimpus.com)	#
#		URL:	http://www.olimpus.com/			#
#								#
#################################################################

@ISA = qw(Exporter AutoLoader);

@EXPORT = qw($VCGC);

$VERSION = '1.01';

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $CGC $VCGC);

require Exporter;
require AutoLoader;

sub verificar {

 $VCGC = 1;

 my ($i, $strCaracter, $strCampo, $strCGC, $strConf, $intNumero, $intMais,$intSoma, $intSoma1, $intSoma2, $div, $intDiv, $intInteiro, $intResto, $intd1, $intd2);

 my $type = shift;

 my $CGC;

 $CGC = shift;

 bless \$CGC, $type;

 if ((length($CGC) < 14) || (length($CGC) > 15)) {

   $VCGC = 0;

 }

 else {

   if (length($CGC) == 15) { $CGC = substr($CGC, 1, 14); }

   $intSoma = 0;
   $intSoma2 = 0;
   $intNumero = 0;
   $intMais = 0;
   $strCGC = substr($CGC, -6);
   $strCGC = substr($strCGC, 0, 4);
   $strCampo = substr($CGC, 0, 8);
   $strCampo = substr($strCampo, -4);
   $strCampo = "$strCampo$strCGC";

   for ($i = 2; $i <= 9; $i++) {

     $strCaracter = substr($strCampo, 1 - $i);
     $intNumero = substr($strCaracter, 0 ,1);
     $intMais = $intNumero * $i;
     $intSoma1 = $intSoma1 + $intMais;

   }

   $strCampo = substr($CGC, 0, 4); 

   for ($i = 2; $i <= 5; $i++) {
    
     $strCaracter = substr($strCampo, 1 - $i);
     $intNumero = substr($strCaracter, 0 ,1);
     $intMais = $intNumero * $i;
     $intSoma2 = $intSoma2 + $intMais;

   }

   $intSoma = $intSoma1 + $intSoma2;
   $div = $intSoma / 11;
   $intDiv = sprintf ("%d", $div);
   $intInteiro = $intDiv * 11;
   $intResto = $intSoma - $intInteiro;

   if (($intResto == 0) || ($intResto == 1)) { $intd1 = 0; }

   else { $intd1 = 11 - $intResto; }

   $intSoma = 0;
   $intSoma1 = 0;
   $intSoma2 = 0;
   $intNumero = 0;
   $intMais = 0;
   $strCGC = substr($CGC, -6);
   $strCGC = substr($strCGC, 0, 4);
   $strCampo = substr($CGC, 0, 8);
   $strCampo = substr($strCampo, -3);
   $strCampo = "$strCampo$strCGC$intd1";

   for ($i = 2; $i <= 9; $i++) {

     $strCaracter = substr($strCampo, 1 - $i);
     $intNumero = substr($strCaracter, 0 ,1);
     $intMais = $intNumero * $i;
     $intSoma1 = $intSoma1 + $intMais;

   }

   $strCampo = substr($CGC, 0, 5);

   for ($i = 2; $i <= 6; $i++) {

     $strCaracter = substr($strCampo, 1 - $i);
     $intNumero = substr($strCaracter, 0 ,1);
     $intMais = $intNumero * $i;
     $intSoma2 = $intSoma2 + $intMais;

   }

   $intSoma = $intSoma1 + $intSoma2;

   $div = $intSoma / 11;
   $intDiv = sprintf ("%d", $div);
   $intInteiro = $intDiv * 11;
   $intResto = $intSoma - $intInteiro;

   if (($intResto == 0) || ($intResto == 1)) { $intd2 = 0; }
   else { $intd2 = 11 - $intResto; }

   $strConf = "$intd1$intd2";

   if ($strConf != substr($CGC, -2)) { $VCGC = 0; }

 }

 return($VCGC);

}

1;

__END__

=head1 NAME

Brasil::Checar::CCG

- Perl extension for check a CGC number.
- Extensão Perl para validação de números de CGC/CNPJ (Cadastro Nacional de Pessoa Jurídica)

=head1 SYNOPSIS

  use Brasil::Checar::CGC;

=head1 DESCRIPTION

English:

This is the first module in Brazil. Create by Brazilians,
this help to create your own Perl programs.

This module verify the validate of CCG number.

Portugues:

Este é um dos primeiros módulos voltados para o Brasil, criado
por Brasileiros para auxiliar na criação de seus programas em Perl.

Em particular este módulo faz a verificação do númerode CGC/CNPJ
(Cadastro Nacional de Pessoa Jurídica), documento válido no Brasil.

=head1 AUTHOR

Hodel, Paul <paul@olimpus.com>

=head1 SEE ALSO

perl(1).

=cut
