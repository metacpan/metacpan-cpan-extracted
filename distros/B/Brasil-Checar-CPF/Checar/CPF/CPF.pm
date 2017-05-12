package Brasil::Checar::CPF;

#################################################################
#								#
# (c) 1997-2000 Equipe Olimpus, todos os direitos reservados	#
#								#
#               Author:	Paul Pierre Hodel (paul@olimpus.com)	#
#		URL:	http://www.olimpus.com/			#
#								#
#################################################################

@ISA = qw(Exporter AutoLoader);

@EXPORT = qw($VCPF);

$VERSION = '1.01';

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $SOM $RET $i $VCPF $SOMX $SOMY);

require Exporter;
require AutoLoader;

my $VCPF = 1;

sub verificar {

 my $type = shift;

 my $CPF;

 $CPF = shift;

 bless \$CPF, $type;

 if ((length($CPF) < 11) || (length($CPF) > 11)) {

  $VCPF = $CPF;

 }

 else {

  for ($i = 0; $i <= 8; $i++) {

  $SOM = $SOM + substr($CPF,$i,1) * (10 - $i);

  }                     

  $SOMX = $SOM / 11;

  $SOMY = sprintf ("%d", $SOMX);

  $RET = 11 - ($SOM - ($SOMY * 11));

  if (($RET eq "10") || ($RET eq "11")) { $RET = 0; }

  if (substr($CPF,9,1) ne "$RET") { $VCPF = 0; }

  $SOM = 0;

  for ($i = 0; $i <= 9; $i++) {

   $SOM = $SOM + substr($CPF,$i,1) * (11 - $i);

  }

  $SOMX = $SOM / 11;

  $SOMY = sprintf ("%d", $SOMX);

  $RET = 11 - ($SOM - ($SOMY * 11));

  if (($RET eq "10") || ($RET eq "11")) { $RET = 0; }

  if (substr($CPF,10,1) ne "$RET") { $VCPF = 0; }

 }

 return($VCPF);

}

1;

__END__

=head1 NAME

Brasil::Checar::CPF

- Perl extension for check a CPF number.
- Extensão Perl para validação de números de CPF (Cadastro de Pessoa Física)

=head1 SYNOPSIS

  use Brasil::Checar::CPF;

=head1 DESCRIPTION

English:

This is the first module in Brazil. Create by Brazilians,
this help to create your own Perl programs.

This module checks by module 11 the validate of CPF number.

Portugues:

Este é um dos primeiros módulos voltados para o Brasil, criado
por Brasileiros para auxiliar na criação de seus programas em Perl.

Em particular este módulo faz a verificação via módulo 11 do número
CPF (Cadastro de Pessoal Física), documento válido no Brasil.

=head1 AUTHOR

Hodel, Paul <paul@olimpus.com>

=head1 SEE ALSO

perl(1).

=cut
