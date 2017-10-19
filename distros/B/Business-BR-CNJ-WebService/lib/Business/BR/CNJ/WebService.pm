package Business::BR::CNJ::WebService;

use strict;
use utf8;
use Exporter 'import';
use SOAP::Lite;

our $VERSION = 0.03;

sub new {
 my $class = bless {}, shift;
 $class->{ws} = SOAP::Lite->new(
    proxy => 'http://www.cnj.jus.br/sgt/sgt_ws.php',
 );
 $class;
}

sub errstr { shift->{errstr} }

sub cnj_ws_call {
 my $class = shift;

 $class->{errstr} = undef;

 my $som;
 eval { $som = $class->{ws}->call( @_ ) };

 if ( $@ ) {
  $class->{errstr} = $@;
  return undef;

 } else {
  return $som->result;
 }
}

sub pesquisarItemPublicoWS {
 shift->cnj_ws_call( 'pesquisarItemPublicoWS', @_ );
}

sub getArrayDetalhesItemPublicoWS {
 shift->cnj_ws_call( 'getArrayDetalhesItemPublicoWS', @_ );
}

sub getArrayFilhosItemPublicoWS {
 shift->cnj_ws_call( 'getArrayFilhosItemPublicoWS', @_ );
}

sub getStringPaisItemPublicoWS {
 shift->cnj_ws_call( 'getStringPaisItemPublicoWS', @_ );
}

sub getComplementoMovimentoWS {
 shift->cnj_ws_call( 'getComplementoMovimentoWS', @_ );
}

sub getDataUltimaVersao {
 shift->cnj_ws_call( 'getDataUltimaVersao', @_ );
}

1;

__END__

=head1 NAME

Business::BR::CNJ::WebService - Interacts with brazilian CNJ (Conselho Nacional de Justiça) SOAP WebService.

=head1 SYNOPSIS

   use Business::BR::CNJ::WebService;

   my $cnj = Business::BR::CNJ::WebService->new();

   print $cnj->getDataUltimaVersao();

   my $data = $cnj->pesquisarItemPublicoWS( 'C', 'N', 'Agravo' );

   my $data = $cnj->getArrayDetalhesItemPublicoWS( '2', 'C' );
   
=head1 DESCRIPTION

This module is a direct brindge to the brazilian CNJ (Conselho Nacional de Justiça) SOAP WebServices.

All interface and docs are from CNJ website itself: http://www.cnj.jus.br/sgt/infWebService.php

=head1 METHDOS

=head2 pesquisarItemPublicoWS($tipoTabela, $tipoPesquisa, $valorPesquisa)

Pesquisa as tabelas públicas de acordo com os parametros passados 
 
@param string $tipoTabela -Tipo da tabela a ser pesquisada(A,M,C) - Assuntos, Movimentos, Classes
@param string $tipoPesquisa -Tipo da pesquisa(G,N,C) - Glossário, Nome, Código
@param string $valorPesquisa -Valor da pesquisa
 
@return Item[] Array de itens encontrados

=over

=head2 getArrayDetalhesItemPublicoWS($seqItem,$tipoItem)

Retorna uma array do objeto preenchido de acordo com o item requisitado
 
@param string $seqItem -Sequencial do item requisitado(código do item)
@param string $tipoItem -Tipo do item(A,M,C) - Assuntos, Movimentos, Classes
 
@return Array Array das variaveis do objeto preenchidas

=over

=head2 getArrayFilhosItemPublicoWS($seqItem,$tipoItem)

Retorna um Array contendo uma lista de Classes/Assuntos 

@param int $seqItem -Sequencial do item requisitado(código do item)
@param string $tipoItem	-Tipo do item(A,M,C) - Assuntos, Movimentos, Classes
@return arvoreGenerica[]

=over

=head2 getStringPaisItemPublicoWS($seqItem,$tipoItem)

Retorna uma string contendo o encadeamento de pais de um item
 
@param int $seqItem	-Sequencial do item requisitado(código do item)
@param string $tipoItem	-Tipo do item(A,M,C) - Assuntos, Movimentos, Classes
@return string

=over

=head2 getComplementoMovimentoWS($codMovimento)

Retorna uma Array contendo os complementos tabelados
 
@param int $codMovimento - Sequencial do movimento que se deseja obter os complementos, esse campo pode ser vazio, assim irá trazer todos os complementos cadastrados. 
@return ComplementoMovimento[]

=over

=head2 getDataUltimaVersao()

Retorna uma String contendo a data da última versão
 
@return String

=over

=head2 errstr

Returns undef if no error was thrown in the last call, or any true value if an error was thown (normally a string with the error).

=over

=head2 cnj_ws_call

Makes a plain SOAP call to the end point and returns the data structure.
Used internally only - all other methods use this to make the HTTP SOAP requests.

If an error happens, it return undef and sets the "errstr" attribute to the error value.
Check for error with the errstr method call.

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
