package Business::CPI::Cart::Moip;
use Moo;

extends qw/Business::CPI::Cart/;

=pod

=encoding utf-8

=head1 NAME

Business::CPI::Cart::Moip

=head1 DESCRIPTION

extends Business::CPI::Cart

=head1 ATTRIBUTES

=head2 boleto

Recebe parametros para criação do boleto.

* a data é datetime padrão W3C

* a expiracao pode ser de 2 tipos:

- corridos

- uteis

    $cart->boleto({
        expiracao       => {
            dias => 7,
            tipo => 'corridos', #ou uteis
        },
        data_vencimento => '2012/12/30T24:00:00.0-03:00',
        instrucao1      => 'Primeira linha de instrução de pagamento do boleto bancário',
        instrucao2      => 'Segunda linha de instrução de pagamento do boleto bancário',
        instrucao3      => 'Terceira linha de instrução de pagamento do boleto bancário',
        logo_url        => 'http://www.nixus.com.br/img/logo_nixus.png',
    });

Data de vencimento

ex: 2012/12/30T24:00:00.0-03:00

*** O formato é esse ai: 2012/12/30T24:00:00.0-03:00

  YYYY-MM-DDThh:mm:ss.sTZD

  YYYY = ano (4 dígitos)
  MM = mês (2 dígitos)
  DD = dia (2 dígitos)
  hh = hora (2 dígitos) (24h)
  mm = minutos (2 dígitos)
  ss = segundos (2 dígitos)
  s = fração de segundo (1 ou mais dígitos)
  TZD = fuso horário (pode ser +hh:mm ou -hh:mm)

  Referência: http://www.w3.org/TR/NOTE-datetime

=cut

has boleto => (
    is => 'rw',
);


=head2 parcelas

  $self->parcelas([
      {
          parcelas_min => 2
          parcelas_max => 6
          juros => 2.99
      },
      {
          parcelas_min => 7
          parcelas_max => 12
          juros => 10.99
      }
  ]);

=cut

has parcelas => (
    is => 'rw',
);

=head2 comissoes

http://labs.moip.com.br/referencia/secundarios/

  $cart->comissoes([
  {
      razao => 'Motivo da divisao',
      login_moip => 'loginmoip1',
      valor_fixo => 5.50,
  },
  {
      razao => 'Motivo da divisao',
      login_moip => 'loginmoip2',
      valor_percentual => 10,
  }
  ]);

=cut

has comissoes => (
    is => 'rw',
);

=head2 pagador_taxa

http://labs.moip.com.br/referencia/secundarios/

  $cart->pagador_taxa('login_moip_3');

=cut

has pagador_taxa => (
    is => 'rw',
);

=head2 mensagens

http://labs.moip.com.br/parametro/Mensagens/

Com o node Mensagens você pode exibir mensagens adicionais no checkout Moip ao seu comprador.

    $cart->mensagens([
        'mensagem linha 1',
        'mensagem linha 2',
        'mensagem linha 3',
    ]);

=cut

has mensagens => (
    is => 'rw',
);

=head2 entrega

define as opcões de entrega

http://labs.moip.com.br/parametro/Entrega/

=cut

has entrega => (
    is => 'rw',
);

=head2 formas_pagamento

http://labs.moip.com.br/parametro/FormaPagamento/

    formas_pagamento => [
        'BoletoBancario',
        'CartaoDeCredito',
        'DebitoBancario',
        'CartaoDeDebito',
        'FinanciamentoBancario',
        'CarteiraMoIP',
    ],

=cut

has formas_pagamento => (
    is => 'rw',
);


has url_retorno     => ( is => 'rw' );
has url_notificacao => ( is => 'rw' );

1;
