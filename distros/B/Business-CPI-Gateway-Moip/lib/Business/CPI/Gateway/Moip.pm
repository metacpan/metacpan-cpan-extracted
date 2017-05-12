package Business::CPI::Gateway::Moip;
use Moo;
use MIME::Base64;
use Carp 'croak';
use bareword::filehandles;
use indirect;
use multidimensional;
use HTTP::Tiny;
use Data::Dumper;
extends 'Business::CPI::Gateway::Base';

our $VERSION     = '0.05';

=pod

=encoding utf-8

=head1 NAME

Business::CPI::Gateway::Moip - Inteface para pagamentos Moip

=head1 SYNOPSIS

    use Data::Printer;
    use Business::CPI::Buyer::Moip;
    use Business::CPI::Cart::Moip;
    use Business::CPI::Gateway::Moip;

    my $cpi = Business::CPI::Gateway::Moip->new(
        currency        => 'BRL',
        sandbox         => 1,
        token_acesso    => 'YC110LQX7UQXEMQPLYOPZ1LV9EWA8VKD',
        chave_acesso    => 'K03JZXJLOKJNX0CNL0NPGGTHTMGBFFSKNX6IUUWV',
        receiver_email  => 'teste@oemail.com.br',
        receiver_label  => 'Nome Cliente ou Loja',
        id_proprio      => 'ID_INTERNO_'.int rand(int rand(99999999)),

    );

    my $cart = $cpi->new_cart({
        buyer => {
            name               => 'Mr. Buyer',
            email              => 'sender@andrewalker.net',
            address_street     => 'Rua das Flores',
            address_number     => '360',
            address_district   => 'Vila Mariana',
            address_complement => 'Ap 35',
            address_city       => 'São Paulo',
            address_state      => 'SP',
            address_country    => 'Brazil',
            address_zip_code   => '04363-040',
            phone              => '11-9911-0022',
            id_pagador         => 'O11O22X33X',
        },
        mensagens => [
            'Produto adquirido no site X',
            'Total pago + frete - Preço: R$ 144,10',
            'Mensagem linha3',
        ],
        boleto => {
            expiracao       => {
                dias => 7,
                tipo => 'corridos', #ou uteis
            },
            data_vencimento => '2012/12/30T24:00:00.0-03:00',
            instrucao1      => 'Primeira linha de instrução de pagamento do boleto bancário',#OPT
            instrucao2      => 'Segunda linha de instrução de pagamento do boleto bancário', #OPT
            instrucao3      => 'Terceira linha de instrução de pagamento do boleto bancário',#OPT
            logo_url        => 'http://www.nixus.com.br/img/logo_nixus.png',                 #OPT
        },
        formas_pagamento => [
            'BoletoBancario',
            'CartaoDeCredito',
            'DebitoBancario',
            'CartaoDeDebito',
            'FinanciamentoBancario',
            'CarteiraMoIP',
        ],
        url_retorno => 'http://www.url_retorno.com.br',
        url_notificacao => 'http://www.url_notificacao.com.br',
        entrega => {
            destino => 'MesmoCobranca',
            calculo_frete => [
                {
                    tipo => 'proprio', #ou correios
                    valor_fixo => 2.30, #ou valor_percentual
                    prazo => {
                        tipo  => 'corridos', #ou uteis
                        valor => 2,
                    }
                },
                {
                    tipo             => 'correios',
                    valor_percentual => 12.30,
                    prazo => {
                        tipo    => 'corridos',#ou uteis
                        valor   => 2,
                    },
                    correios => {
                        peso_total          => 12.00,
                        forma_entrega       => 'Sedex10', #ou sedex sedexacobrar sedexhoje
                        mao_propria         => 'PagadorEscolhe', #ou SIM ou NAO
                        valor_declarado     => 'PagadorEscolhe', #ou SIM ou NAO
                        aviso_recebimento   => 'PagadorEscolhe', # ou SIM ou NAO
                        cep_origem          => '01230-000',
                    },
                },
                {
                    tipo => 'correios',
                    valor_percentual => 12.30,
                    prazo => {
                        tipo    => 'corridos',#ou uteis
                        valor   => 2,
                    },
                    correios => {
                        peso_total          => 12.00,
                        forma_entrega       => 'Sedex10', #ou sedex sedexacobrar sedexhoje
                        mao_propria         => 'PagadorEscolhe', #ou SIM ou NAO
                        valor_declarado     => 'PagadorEscolhe', #ou SIM ou NAO
                        aviso_recebimento   => 'PagadorEscolhe', # ou SIM ou NAO
                        cep_origem          => '01230-000',
                    },
                },
            ]
        }
    },
    );

    my $item = $cart->add_item({
        id          => 2,
        quantity    => 1,
        price       => 222,
        description => 'produto2',
    });

    my $item = $cart->add_item({
        id          => 1,
        quantity    => 2,
        price       => 111,
        description => 'produto1',
    });

    my $res = $cpi->make_xml_transaction( $cart );

    Return on success:
        $res = {
            code    "SUCCESS",
            id      201301231157322850000001500872,
            token   "C2R0A1V3K0P132J3Q1C1S5M7R3N2P2N8B5L0Q0M0J05070U1W5K0P018D7T2"
        }

    Return on error:
        $res = {
            code    "ERROR",
            raw_error   "<ns1:EnviarInstrucaoUnicaResponse xmlns:ns1="http://www.moip.com.br/ws/alpha/"><Resposta><ID>201301231158069350000001500908</ID><Status>Falha</Status><Erro Codigo="2">O valor do pagamento deverá ser enviado obrigator
        iamente</Erro></Resposta></ns1:EnviarInstrucaoUnicaResponse>"
        }

=head1 EXAMPLE USING Business:CPI

The following example will use Business::CPI directly

    use Business::CPI;
    use Data::Printer;

    my $moip = Business::CPI->new(
        gateway        => "Moip",
        sandbox         => 1,
        token_acesso    => 'YC110LQX7UQXEMQPLYOPZ1LV9EWA8VKD',
        chave_acesso    => 'K03JZXJLOKJNX0CNL0NPGGTHTMGBFFSKNX6IUUWV',
        receiver_email  => 'teste@oemail.com.br',
        receiver_label  => 'Nome Cliente ou Loja',
        id_proprio      => 'ID_INTERNO_'.int rand(int rand(99999999)),
    );

    my $cart = $moip->new_cart({
        buyer => {
            name               => 'Mr. Buyer',
            email              => 'sender@andrewalker.net',
            address_street     => 'Rua das Flores',
            address_number     => '360',
            address_district   => 'Vila Mariana',
            address_complement => 'Ap 35',
            address_city       => 'São Paulo',
            address_state      => 'SP',
            address_country    => 'BRA',
            address_zip_code   => '04363-040',
            phone              => '11-9911-0022',
            id_pagador         => 'O11O22X33X',
        }
    });

    $cart->parcelas([
        {
            parcelas_min => 2,
            parcelas_max => 6,
            juros        => 2.99,
        },
        {
            parcelas_min => 7,
            parcelas_max => 12,
            juros        => 10.99,
        },
    ]);

    my $item = $cart->add_item({
        id          => 2,
        quantity    => 1,
        price       => 222,
        description => 'produto2',
    });

    my $item = $cart->add_item({
        id          => 1,
        quantity    => 2,
        price       => 111,
        description => 'produto1',
    });

    my $res = $moip->make_xml_transaction( $cart );
    warn p $res;

=head1 MOIP DOCUMENTATION REFERENCE

http://labs.moip.com.br

http://labs.moip.com.br/referencia/minuto/

http://labs.moip.com.br/referencia/pagamento_parcelado/

=head1 SANDBOX

Register yourself in the Moip sandbox: http://labs.moip.com.br/

=head1 DESCRIPTION

Business::CPI::Gateway::Moip allows you to make moip transactions using Business::CPI standards.

Currently, Moip uses XML format for transactions.

This module will allow you to easily create a cart with items and buyer infos and payment infos. And, after setting up all this information, you will be able to:

    ->make_xml_transaction

and register your transaction within moip servers to obtain a moip transaction tokenid.

** make_xml_transaction will return a TOKEN and code SUCCESS upon success. You will need this info so your user can checkout afterwards.

* see the tests for examples

=head1 MOIP TRANSACTION FLOW

Here, ill try to describe how the moip transaction flow works:

    1. You post the paymentXML to the moip servers
    2. Moip returns a transaction token id upon success

Then, you have 2 options for checkout:

    - option1 (send the user to moip site to finish transaction):
    - 3. You redirect your client to moip servers passing the transaction token id

    - option2 (use the moip transaction id and some javascript for checkout):
    3. You use some javascript with the transaction token id

    4. Your client pays

=head1 CRUDE EXAMPLE

Ive prepared this example just in case you want to test the moip payment sistem without using any other module.
The following snippet uses only HTTP::Tiny to register the moip transaction.

        my $conteudo = <<'XML';
    <EnviarInstrucao>
      <InstrucaoUnica>
            <Razao>Pagamento com HTTP Tiny</Razao>
            <Valores>
                <Valor moeda='BRL'>1.50</Valor>
            </Valores>
            <Pagador>
                <IdPagador>cliente_id</IdPagador>
            </Pagador>
      </InstrucaoUnica>
    </EnviarInstrucao>
    XML
        my $res = HTTP::Tiny->new( verify_SSL => $self->verify_ssl )->request(
            'POST',
            $self->api_url,
            {
                headers => {
                    'Authorization' => 'Basic ' . MIME::Base64::encode($self->token_acesso.":".$self->chave_acesso,''),
                    'Content-Type' => 'application/x-www-form-urlencoded',
                },
                content => $conteudo,
            }
        );
        warn p $res;

=cut


=head1 ATTRIBUTES

=head2 sandbox

Indicates whether or not this module will use the sandbox url or production url.

=cut

has sandbox => (
    is => 'rw',
    default => sub { return 0 },
);

=head2 api_url

Holds the api_url. You DONT need to pass it, it will figure out its own url based on $self->sandbox

=cut

has 'api_url' => (
    is => 'rw',
);

=head2 token_acesso

Moip token

=cut

has token_acesso => (
    is => 'rw',
    required => 1,
);

=head2 chave_acesso

Moip access-key

=cut

has chave_acesso => (
    is => 'rw',
    required => 1,
);

=head2 id_proprio

Your own internal transaction id.
ie. e39jd2390jd92d030000001

=cut

has id_proprio => (
    is => 'rw',
);

=head2 receiver_label

Name that will receive this payment
ie. My Store Name

=cut

has receiver_label => ( #to print the store name on the paypment form
    is => 'rw',
);

=head2 receiver_email

Email that will receive this payment
ie. sales@mystore.com

=cut

has receiver_email => ( #to print the sotre name on the paypment form
    is => 'rw',
);

=head2 ua

Uses HTTP::Tiny as useragent

=cut

has ua => (
    is => 'rw',
    default => sub { HTTP::Tiny->new() },
);

=head1 METHODS

=cut

sub BUILD {
    my $self = shift;
    if ( $self->sandbox ) {
        $self->api_url('https://desenvolvedor.moip.com.br/sandbox/ws/alpha/EnviarInstrucao/Unica');
    } else {
        $self->api_url('https://www.moip.com.br/ws/alpha/EnviarInstrucao/Unica');
    }
};

=head2 make_xml_transaction

Registers the transaction on the Moip servers.

Receives an $cart, generates the XML and register the transaction on the Moip Server.

Returns the moip transaction token upon success.

Returns the full raw_error when fails.

Return on success:

        {
            code    "SUCCESS",
            id      201301231157322850000001500872,
            token   "C2R0A1V3K0P132J3Q1C1S5M7R3N2P2N8B5L0Q0M0J05070U1W5K0P018D7T2"
        }

Return on error:

        {
            code    "ERROR",
            raw_error   "<ns1:EnviarInstrucaoUnicaResponse xmlns:ns1="http://www.moip.com.br/ws/alpha/"><Resposta><ID>201301231158069350000001500908</ID><Status>Falha</Status><Erro Codigo="2">O valor do pagamento deverá ser enviado obrigator
        iamente</Erro></Resposta></ns1:EnviarInstrucaoUnicaResponse>"
        }

=cut

sub make_xml_transaction {
    my ( $self, $cart ) = @_;
    my $xml = $self->payment_to_xml( $cart );
    #warn $xml;
    $self->log->debug("moip-xml: " . $xml);
    my $res = $self->ua->request(
        'POST',
        $self->api_url,
        {
            headers => {
                'Authorization' =>
                    'Basic ' .
                    MIME::Base64::encode($self->token_acesso.":".$self->chave_acesso,''),
                'Content-Type' => 'application/x-www-form-urlencoded',
            },
            content => $xml,
        }
    );
    my $final_res = {};
    if ( $res->{content} =~ m|\<Status\>Sucesso\</Status\>|mig ) {
        $final_res->{ code } = 'SUCCESS';
        #pega token:
        my ( $token ) = $res->{content} =~ m|\<Token\>([^<]+)\</Token\>|mig;
        $final_res->{ token } = $token if defined $token;
        #pega id:
        my ( $id ) = $res->{content} =~ m|\<ID\>([^<]+)\</ID\>|mig;
        $final_res->{ id } = $id if defined $id;
    } else {
        $final_res->{ code } = 'ERROR';
        $final_res->{ raw_error } = $res->{ content };
    }
    return $final_res;
}

=head2 notify

Not implemented yet for Moip

=cut

sub notify {
    my ( $self, $req ) = @_;
}

=head2 payment_to_xml

Generates an XML with the information in $cart and other attributes ie. receiver_label, id_proprio, buyer email, etc

returns the Moip XML format

=cut

sub payment_to_xml {
    my ( $self, $cart ) = @_;
    #TODO:
    #http://labs.moip.com.br/parametro/Recebedor/
    #é so implementar no CPI::Cart::Moip e incluir aqui no xml abaixo com as devidas validacoes

    $self->log->debug("\$cart: " . Dumper( $cart));
    $self->log->debug("\$cart->buyer: " . Dumper( $cart->buyer));

    my $xml;

    $xml = "<EnviarInstrucao>
                <InstrucaoUnica TipoValidacao=\"Transparente\">";

    $xml = $self->add_url_retorno       ( $xml, $cart );
    $xml = $self->add_url_notificacao   ( $xml, $cart );
    $xml = $self->add_formas_pagamento  ( $xml, $cart );
    $xml = $self->add_mensagens         ( $xml, $cart );
    $xml = $self->add_razao             ( $xml, $cart );
    $xml = $self->add_valores           ( $xml, $cart );
    $xml = $self->add_id_proprio        ( $xml, $cart );
    $xml = $self->add_pagador           ( $xml, $cart );
    $xml = $self->add_boleto            ( $xml, $cart );
    $xml = $self->add_parcelas          ( $xml, $cart );
    $xml = $self->add_comissoes         ( $xml, $cart );
    $xml = $self->add_entrega           ( $xml, $cart );

    $xml .= "\n</InstrucaoUnica>
        </EnviarInstrucao>";

    return $xml;
}

sub add_url_retorno {
    my ( $self, $xml , $cart ) = @_;
    if ( defined $cart->url_retorno ) {
        $xml .= "<URLRetorno>".$cart->url_retorno."</URLRetorno>";
    }
    return $xml;
}

sub add_url_notificacao {
    my ( $self, $xml , $cart ) = @_;
    if ( defined $cart->url_notificacao ) {
        $xml .= "<URLNotificacao>".$cart->url_notificacao."</URLNotificacao>";
    }
    return $xml;
}

sub add_formas_pagamento {
    my ( $self, $xml , $cart ) = @_;
    if ( defined $cart->formas_pagamento and ref $cart->formas_pagamento eq ref [] ) {
        $xml .= "<FormasPagamento>";
        foreach my $forma ( @{ $cart->formas_pagamento } ) {
            $xml .= "<FormaPagamento>".$forma."</FormaPagamento>";
        }
        $xml .= "</FormasPagamento>";
    }
    return $xml;
}

sub add_entrega {
    my ( $self, $xml, $cart ) = @_;
    if ( defined $cart->entrega ) {
        $xml .= "<Entrega>";
        if ( exists $cart->entrega->{destino} ) {
            $xml .= "<Destino>".$cart->entrega->{destino}."</Destino>";
        }
        foreach my $e ( @{ $cart->entrega->{ calculo_frete } } ) {
            $xml .= "<CalculoFrete>";
            if ( exists $e->{ tipo } ) {
                $xml .= "<Tipo>Proprio</Tipo>"  if $e->{ tipo } =~ m/proprio/ig;
                $xml .= "<Tipo>Correios</Tipo>" if $e->{ tipo } =~ m/correio/ig;
            }
            if ( exists $e->{ valor_fixo } ) {
                $xml .= "<ValorFixo>".$e->{ valor_fixo }."</ValorFixo>";
            }
            if ( exists $e->{ valor_percentual } ) {
                $xml .= "<ValorPercentual>". $e->{ valor_percentual } ."</ValorPercentual>";
            }
            if ( exists $e->{ prazo } and
                 exists $e->{ prazo }->{ valor } and
                 exists $e->{ prazo }->{ tipo }
            ) {
                if ( $e->{ prazo }->{ tipo } =~ m/corridos/ig ) {
                    $xml .= '<Prazo Tipo="Corridos">'.$e->{ prazo }->{ valor }.'</Prazo>' ;
                }
                if ($e->{ prazo }->{ tipo } =~ m/uteis/ig ) {
                    $xml .= '<Prazo Tipo="Uteis">'.   $e->{ prazo }->{ valor }.'</Prazo>' ;
                }
            }
            if ( exists $e->{ correios } ) {
                $xml .= "<Correios>";
                if ( exists $e->{correios}->{peso_total} ) {
                    $xml .= "<PesoTotal>".$e->{correios}->{peso_total}."</PesoTotal>";
                }
                if ( exists $e->{correios}->{forma_entrega} ) {
                    $xml .= "<FormaEntrega>".$e->{correios}->{forma_entrega}."</FormaEntrega>";
                }
                if ( exists $e->{correios}->{mao_propria} ) {
                    $xml .= "<MaoPropria>".$e->{correios}->{mao_propria}."</MaoPropria>";
                }
                if ( exists $e->{correios}->{valor_delarado} ) {
                    $xml .= "<ValorDeclarado>".$e->{correios}->{valor_declarado}."</ValorDeclarado>";
                }
                if ( exists $e->{correios}->{aviso_recebimento} ) {
                    $xml .= "<AvisoRecebimento>".$e->{correios}->{aviso_recebimento}."</AvisoRecebimento>";
                }
                if ( exists $e->{correios}->{cep_origem} ) {
                    $xml .= "<CepOrigem>".$e->{correios}->{cep_origem}."</CepOrigem>";
                }
                $xml .= "</Correios>";
            }
            $xml .= "</CalculoFrete>";
        }
        $xml .= "</Entrega>";
    }
    return $xml;
}

sub add_razao {
    my ( $self, $xml, $cart ) = @_;
    $xml .= "<Razao>Pagamento para loja ".$self->receiver_label." </Razao>";
    return $xml;
}

sub add_comissoes {
    my ( $self, $xml, $cart ) = @_;
    if ( defined $cart->comissoes || defined $cart->pagador_taxa ) {
        $xml .= "\n<Comissoes>";
        if ( defined $cart->comissoes ) {
            foreach my $comissao ( @{ $cart->comissoes } ) {
                $xml .= "\n<Comissionamento>";
                if ( exists $comissao->{razao} ) {
                    $xml .= "\n<Razao>".$comissao->{razao}."</Razao>" if exists $comissao->{razao};
                }
                if ( exists $comissao->{login_moip} ) {
                    $xml .= "\n<Comissionado><LoginMoIP>".$comissao->{login_moip}."</LoginMoIP></Comissionado>"
                }
                if ( exists $comissao->{valor_percentual} ) {
                    $xml .= "\n<ValorPercentual>".$comissao->{valor_percentual}."</ValorPercentual>";
                }
                if ( exists $comissao->{valor_fixo} ) {
                    $xml .= "\n<ValorFixo>".$comissao->{valor_fixo}."</ValorFixo>";
                }
                $xml .= "\n</Comissionamento>";
            }
        }
        if ( defined $cart->pagador_taxa ) {
            $xml .= "\n<PagadorTaxa><LoginMoIP>".$cart->pagador_taxa."</LoginMoIP></PagadorTaxa>";
        }
        $xml .= "\n</Comissoes>";
    }
    return $xml;
}

sub add_parcelas {
    my ( $self, $xml, $cart ) = @_;
    if ( defined $cart->parcelas and scalar @{ $cart->parcelas } > 0 ) {
        $xml .= "\n<Parcelamentos>";
        foreach my $parcela ( @{ $cart->parcelas } ) {
            if ( defined $parcela->{parcelas_max} and defined $parcela->{parcelas_min} ) {
                $xml .= "\n<Parcelamento>";
                        if ( defined $parcela->{parcelas_min}  ) {
                            $xml .= "\n<MinimoParcelas>".$parcela->{parcelas_min}."</MinimoParcelas>";
                        }
                        if ( defined $parcela->{parcelas_max} ) {
                            $xml .= "\n<MaximoParcelas>".$parcela->{parcelas_max}."</MaximoParcelas>";
                        }
                        $xml .= "\n<Juros>"; $xml .= ( defined $parcela->{juros} )?$parcela->{juros}:'0'; $xml .= "</Juros>";
                $xml .= "\n</Parcelamento>";
            }
        }
        $xml .= "\n</Parcelamentos>";
    }
    return $xml;
}

sub add_id_proprio {
    my ( $self, $xml, $cart ) = @_;
    # id proprio
    if ( $self->id_proprio ) {
        $xml .=     "\n<IdProprio>". $self->id_proprio ."</IdProprio>";
    }
    return $xml;
}

sub add_valores {
    my ( $self, $xml, $cart ) = @_;
    $xml .= "<Valores>";
    # valores
    foreach my $item ( @{$cart->_items} ) {
        $xml .=             "\n<Valor moeda=\"BRL\">".$item->price."</Valor>";
    }
    $xml .=             "\n</Valores>";
    return $xml;
}

sub add_mensagens {
    my ( $self, $xml, $cart ) = @_;
    if ( defined $cart->mensagens and scalar @{ $cart->mensagens } > 0 ) {
        $xml .= "<Mensagens>";
        foreach my $msg ( @{ $cart->mensagens } ) {
            $xml .= "<Mensagem>".$msg."</Mensagem>";
        }
        $xml .= "</Mensagens>";
    }
    return $xml;
}

sub add_pagador {
    my ( $self, $xml, $cart ) = @_;
    # dados do pagador
    if ( $cart->buyer ) {
        $xml .= "\n<Pagador>";
        if ( $cart->buyer->name ) {
                $xml .= "\n<Nome>".$cart->buyer->name."</Nome>";
        }
        if ( $cart->buyer->email ) {
                $xml .= "\n<Email>".$cart->buyer->email."</Email>";
        }
        if ( $cart->buyer->id_pagador ) {
                $xml .= "\n<IdPagador>".$cart->buyer->id_pagador."</IdPagador>";
        }
        if (
            defined $cart->buyer->address_district  ||
            defined $cart->buyer->address_number    ||
            defined $cart->buyer->address_country   ||
            defined $cart->buyer->address_district  ||
            defined $cart->buyer->address_state     ||
            defined $cart->buyer->address_street    ||
            defined $cart->buyer->address_zip_code
        ) {
            $xml .= "\n<EnderecoCobranca>";
            if ( defined $cart->buyer->address_street ) {
                $xml .= "\n<Logradouro>".$cart->buyer->address_street."</Logradouro>";
            }
            if ( defined $cart->buyer->address_number ) {
                $xml .= "\n<Numero>".$cart->buyer->address_number."</Numero>";
            }
            if ( defined $cart->buyer->address_complement ) {
                $xml .= "\n<Complemento>".$cart->buyer->address_complement."</Complemento>";
            }
            if ( defined $cart->buyer->address_district ) {
                $xml .= "\n<Bairro>".$cart->buyer->address_district."</Bairro>";
            }
            if ( defined $cart->buyer->address_city ) {
                $xml .= "\n<Cidade>".$cart->buyer->address_city."</Cidade>";
            }
            if ( defined $cart->buyer->address_state ) {
                $xml .= "\n<Estado>".$cart->buyer->address_state."</Estado>";
            }
            if ( defined $cart->buyer->address_country ) {
warn $cart->buyer->address_country;
                my $sigla = uc(
                    Locale::Country::country_code2code(
                        $cart->buyer->address_country, 'alpha-2', 'alpha-3'
                    )
                );
                $xml .= "\n<Pais>".$sigla."</Pais>";
            }
            if ( defined $cart->buyer->address_zip_code ) {
                $xml .= "\n<CEP>".$cart->buyer->address_zip_code."</CEP>";
            }
            if ( defined $cart->buyer->phone ) {
                $xml .= "\n<TelefoneFixo>".$cart->buyer->phone."</TelefoneFixo>";
            }
            $xml .= "\n</EnderecoCobranca>";
        }
        $xml .= "</Pagador>";
    }
    return $xml;
}

sub add_boleto {
    my ( $self, $xml, $cart ) = @_;
    if (
            defined $cart->boleto
        ) {
        $xml .= "\n<Boleto>";
        if ( exists $cart->boleto->{ data_vencimento } ) {
            $xml .= "\n<DataVencimento>".$cart->boleto->{ data_vencimento }."</DataVencimento>";
        }
        if ( exists $cart->boleto->{ instrucao1 } ) {
            $xml .= "\n<Instrucao1>".$cart->boleto->{ instrucao1 }."</Instrucao1>";
        }
        if ( exists $cart->boleto->{ instrucao2 } ) {
            $xml .= "\n<Instrucao2>".$cart->boleto->{ instrucao2 }."</Instrucao2>";
        }
        if ( exists $cart->boleto->{ instrucao3 } ) {
            $xml .= "\n<Instrucao3>".$cart->boleto->{ instrucao3 }."</Instrucao3>";
        }
        if ( exists $cart->boleto->{ logo_url } ) {
            $xml .= "\n<URLLogo>".$cart->boleto->{ logo_url }."</URLLogo>";
        }
        if ( exists $cart->boleto->{ expiracao } ) {
            my $tipo='';
            if ( exists $cart->boleto->{ expiracao }->{ tipo } ) {
                $tipo = ' Tipo="Corridos"' if $cart->boleto->{ expiracao }->{ tipo } =~ m/corridos/gi;
                $tipo = ' Tipo="Uteis"' if $cart->boleto->{ expiracao }->{ tipo } =~ m/uteis/gi;
            }
            $xml .= "\n<DiasExpiracao$tipo>".$cart->boleto->{ expiracao }->{ dias }."</DiasExpiracao>";
        }
        $xml .= "\n</Boleto>";
    }
    return $xml;
}

=head2 query_transactions()

TODO: http://labs.moip.com.br/blog/saiba-quais-foram-suas-ultimas-transacoes-no-moip-sem-sair-do-seu-site-com-o-moipstatus/

TODO: https://github.com/moiplabs/moip-php/blob/master/lib/MoipStatus.php

*** Não foi implementado pois o moip possúi api boa para transações mas não tem implementado meios para analisar transações entre período.
O único jeito é fazer login no site via lwp ou similar e pegar as informações direto do markup.. mas ao menos neste momento não há seletores que indicam quais os dados.

=head2 query_transactions example

*** NOT IMPLEMENTED... but this is what it would would like more or less.

Thats how it can be done today... making login and parsing the welcome html screen (no good).
Not good because they dont have it on their api... and its not good to rely on markup to read
this sort of important values.

moipstatus.php, on their github acc: https://github.com/moiplabs/moip-php/blob/master/lib/MoipStatus.php

    use HTTP::Tiny;
    use MIME::Base64;
    use Data::Printer;
    use HTTP::Request::Common qw(POST);
    use Mojo::DOM;
    my $url_login = "https://www.moip.com.br/j_acegi_security_check";
    my $login = 'XXXXXXXXXXX';
    my $pass = "XXXXXXX";
    my $url_transactions = 'https://www.moip.com.br/rest/reports/last-transactions';

    my $form_login = [
        j_password => $pass,
        j_username => $login,
    ];

    my $res = HTTP::Tiny->new( verify_SSL => 0 )->request(
        'POST',
        $url_login,
        {
            headers => {
                'Authorization' => 'Basic ' . MIME::Base64::encode($login.":".$pass,''),
                'Content-Type' => 'application/x-www-form-urlencoded',
            },
            content => POST( $url_login, [], Content => $form_login )->content,
        }
    );
    warn p $res;

    warn "login fail" and die if $res->{ headers }->{ location } =~ m/fail/ig;

    my $res2 = HTTP::Tiny->new( verify_SSL => 0 )->request(
        'GET',
        $res->{headers}->{location}
    );
    # warn p $res2;
    my $dom = Mojo::DOM->new($res2->{content});

    SALDO_STATS: {
        my $saldo       = $dom->at('div.textoCinza11 b.textoAzul11:nth-child(3)');
        my $a_receber   = $dom->at('div.textoCinza11 b.textoAzul11:nth-child(10)');
        my $stats = {
            saldo           => (defined $saldo)     ?   $saldo->text     : undef,
            saldo_a_receber => (defined $a_receber) ?   $a_receber->text : undef,
        };
        warn p $stats;
    }

    LAST_TRANSACTIONS:{
        my $selector = 'div.conteudo>div:eq(1)>div:eq(1)>div:eq(1)>div:eq(0) div.box table[cellpadding=5]>tbody tr';
        my $nenhuma = $dom->at( $selector );
        warn p $nenhuma;
    }


=cut

sub query_transactions {}

=head2 get_transaction_details()

TODO: http://labs.moip.com.br/referencia/consulta-de-instrucao/

=cut

sub get_transaction_details {}

=head1 AUTHOR

    Hernan Lopes
    CPAN ID: HERNAN
    -
    hernan@cpan.org
    http://github.com/hernan604

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SPONSOR

http://www.nixus.com.br

=head1 SEE ALSO

perl(1).

=cut

1;
# The preceding line will help the module return a true value

