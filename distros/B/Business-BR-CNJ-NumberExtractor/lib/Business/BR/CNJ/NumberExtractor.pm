package Business::BR::CNJ::NumberExtractor;

use strict;
use utf8;
use Exporter 'import';
use Business::BR::CNJ;

our $VERSION = 0.03;
our @EXPORT_OK = qw/ cnj_extract_numbers cnj_extract_numbers_lwp /;

sub cnj_extract_numbers {
 my $txt = shift;

 my @n = $txt =~ m|(\d{7}.?\d{2}.?\d{4}.?\d.?\d{2}.?\d{4})|g;

 # Hard check and return
 return map { ( Business::BR::CNJ::cnj_check_number($_) ? ($_) : () ) } @n; 
}

sub cnj_extract_lwp {
 require LWP::UserAgent;
 require Mojo::DOM;

 my $req = LWP::UserAgent->new()->get( @_ );

 die $req->status_line if !$req->is_success;

 # text/html
 if ( $req->header( 'Content-type' ) eq 'text/html' ) {
  my $dom = Mojo::DOM->new( $req->decoded_content );

  return cnj_extract_numbers( $dom->all_text );

 # Everything else
 } else {
  return cnj_extract_numbers( $req->decoded_content );
 }

}

1;

__END__

=head1 NAME

Business::BR::CNJ::NumberExtractor - Extract brazilian CNJ numbers (Conselho Nacional de Justiça) from strings.

=head1 SYNOPSIS

   use Business::BR::CNJ::NumberExtractor ( qw/ cnj_extract_numbers / );

   my @numbers =  cnj_extract_numbers(' This is a test: 0058967-77.2016.8.19.0000, but this is not: 0058967-71.2016.8.99.0000 - wrong verification digits.');

   # or...

   use Business::BR::CNJ::NumberExtractor;

   my @numbers = Business::BR::CNJ::NumberExtractor::cnj_extract_numbers('This is a test: 0058967-77.2016.8.19.0000');

   # Or, using LWP::UseAgent and Mojo::DOM (if text/html repsonse)

   my @numbers = Business::BR::CNJ::NumberExtractor::cnj_extract_numbers_lwp('http://arquivo.trf1.jus.br/PesquisaMenuArquivo.asp?p1=10284120114013819&pN=10284120114013819&pA=10284120114013819&data_publicacao=02/10/2017&nome_orgao=%20Todos%20&orgao=');

   # Works even od DOC or PDF files

   my @numbers = Business::BR::CNJ::NumberExtractor::cnj_extract_numbers_lwp('http://arquivo.trf1.gov.br/AGText/2011/0001000/00010284120114013819_3.doc');

=head1 DESCRIPTION

This module handles CNJ numbers and data.

=head1 METHDOS

=head2 cnj_extract_numbers

Given a string as input, returns an array with all CNJ numbers present in the text.

References:

http://www.cnj.jus.br/busca-atos-adm?documento=2748

§ 2º O campo (DD), com 2 (dois) dígitos, identifica o dígito verificador, cujo cálculo de verificação deve ser efetuado pela aplicação do algoritmo Módulo 97 Base 10, conforme Norma ISO 7064:2003, nos termos das instruções constantes do Anexo VIII desta Resolução.

Art. 1º Fica instituída a numeração única de processos no âmbito do Poder Judiciário, observada a estrutura NNNNNNN-DD.AAAA.J.TR.OOOO, composta de 6 (seis) campos obrigatórios, nos termos da tabela padronizada constante dos Anexos I a VII desta Resolução. 

=over

=head2 cnj_extract_numbers_lwp

Same as cnj_extract_numbers, but instead of a string, it expects a URI to be sent to LWP::UserAgent.

If the response is a text/html, Mojo::DOM is used to extract the visible text. Otherwise, response data won't be parsed and will be processed as is.

=over

=head1 SEE ALSO

Please check CNJ website at http://www.cnj.jus.br/

=head1 AUTHOR

Diego de Lima, E<lt>diego_de_lima@hotmail.comE<gt>

=head1 SPECIAL THANKS

This module was kindly made available by the https://modeloinicial.com.br/ team.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Diego de Lima

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
