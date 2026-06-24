package Business::BR::NFSe;
use strict;
use warnings;
use Carp        qw(croak);
use Encode      qw(encode);
use MIME::Base64 qw(encode_base64);
use Digest::SHA  qw(sha256);
use IO::Compress::Gzip qw(gzip $GzipError);
use JSON;
use HTTP::Tiny;
use Crypt::PK::RSA;

our $VERSION = '0.01';


sub new {
    my ($class, %args) = @_;

    for my $req (qw(cert_pem_path key_pem_path cnpj_prestador ibge_cidade)) {
        croak "Business::BR::NFSe->new: '$req' is required" unless defined $args{$req};
    }

    my $cert_pem = _slurp($args{cert_pem_path});
    my $key_pem  = _slurp($args{key_pem_path});

    my ($cert_b64) = $cert_pem =~ /-----BEGIN CERTIFICATE-----(.+?)-----END CERTIFICATE-----/s;
    croak "Business::BR::NFSe->new: could not parse certificate PEM" unless $cert_b64;
    $cert_b64 =~ s/\s+//g;

    return bless {
        cert_pem_path       => $args{cert_pem_path},
        key_pem_path        => $args{key_pem_path},
        key_pem             => $key_pem,
        cert_b64            => $cert_b64,
        cnpj_prestador      => $args{cnpj_prestador},
        ibge_cidade         => $args{ibge_cidade},
        op_simples_nacional => $args{op_simples_nacional} // '3',
        reg_ap_trib_sn      => $args{reg_ap_trib_sn}      // '1',
        regime_especial     => $args{regime_especial}      // '0',
        p_tot_trib_sn       => $args{p_tot_trib_sn}        // '17.99',
        ambiente            => $args{ambiente}              // '1',
        _namespace          => 'http://www.sped.fazenda.gov.br/nfse',
        _versao             => '1.01',
        _url                => $args{url} // 'https://sefin.nfse.gov.br/SefinNacional/nfse',
        http => HTTP::Tiny->new(
            SSL_options => {
                SSL_cert_file => $args{cert_pem_path},
                SSL_key_file  => $args{key_pem_path},
            },
        ),
    }, $class;
}


sub emitir {
    my ($self, %dados) = @_;

    for my $req (qw(serie n_dps data_emissao nome_tomador
                    cod_tributacao_nacional cod_tributacao_municipal
                    descricao_servico valor_servico)) {
        croak "emitir: '$req' is required" unless defined $dados{$req};
    }
    croak "emitir: one (and only one) of 'cpf_tomador', 'cnpj_tomador', or 'nao_nif_tomador' is required"
        if !!$dados{cpf_tomador} + !!$dados{cnpj_tomador} + !!$dados{nao_nif_tomador} != 1;

    # Mesclando dados do objeto com dados do método:
    my %d = (
        cnpj_prestador      => $self->{cnpj_prestador},
        ibge_cidade         => $self->{ibge_cidade},
        op_simples_nacional => $self->{op_simples_nacional},
        reg_ap_trib_sn      => $self->{reg_ap_trib_sn},
        regime_especial     => $self->{regime_especial},
        p_tot_trib_sn       => $self->{p_tot_trib_sn},
        ambiente            => $self->{ambiente},
        %dados,
    );

    my $NS     = $self->{_namespace};
    my $VERSAO = $self->{_versao};

    # --- 1. identificador DPS (TSIdDPS: "DPS" + ibge(7) + type(1) + cnpj(14) + serie(5) + ndps(15)) ---
    # type=2 para prestador com CNPJ, type=1 para prestador com CPF
    my $id_dps = sprintf('DPS%s2%014s%05s%015s',
        $d{ibge_cidade}, $d{cnpj_prestador}, $d{serie}, $d{n_dps},
    );

    # dCompet é YYYY-MM-DD
    my $d_compet = substr($d{data_emissao}, 0, 10);

    # --- 2. Tomador ---
    my $toma_id;
    if    (defined $d{cpf_tomador})    { $toma_id = "<CPF>$d{cpf_tomador}</CPF>" }
    elsif (defined $d{cnpj_tomador})   { $toma_id = "<CNPJ>$d{cnpj_tomador}</CNPJ>" }
    else                               { $toma_id = "<cNaoNIF>$d{nao_nif_tomador}</cNaoNIF>" }

    # --- 3. Constrói XML infDPS ---
    my $inf_dps = join '',
        qq(<infDPS Id="$id_dps">),
        qq(<tpAmb>$d{ambiente}</tpAmb>),
        qq(<dhEmi>$d{data_emissao}</dhEmi>),
         q(<verAplic>BUSINESS_BR_NFSE_V1</verAplic>),
        qq(<serie>$d{serie}</serie>),
        qq(<nDPS>$d{n_dps}</nDPS>),
        qq(<dCompet>$d_compet</dCompet>),
         q(<tpEmit>1</tpEmit>),
        qq(<cLocEmi>$d{ibge_cidade}</cLocEmi>),
         q(<prest>),
          qq(<CNPJ>$d{cnpj_prestador}</CNPJ>),
          (defined $d{email_prestador} ? qq(<email>$d{email_prestador}</email>) : ()),
           q(<regTrib>),
            qq(<opSimpNac>$d{op_simples_nacional}</opSimpNac>),
            qq(<regApTribSN>$d{reg_ap_trib_sn}</regApTribSN>),
            qq(<regEspTrib>$d{regime_especial}</regEspTrib>),
           q(</regTrib>),
         q(</prest>),
        qq(<toma>${toma_id}<xNome>) . _xml_escape($d{nome_tomador}) . q(</xNome></toma>),
         q(<serv>),
          qq(<locPrest><cLocPrestacao>$d{ibge_cidade}</cLocPrestacao></locPrest>),
           q(<cServ>),
            qq(<cTribNac>$d{cod_tributacao_nacional}</cTribNac>),
            qq(<cTribMun>$d{cod_tributacao_municipal}</cTribMun>),
            qq(<xDescServ>) . _xml_escape($d{descricao_servico}) . q(</xDescServ>),
           q(</cServ>),
         q(</serv>),
         q(<valores>),
          qq(<vServPrest><vServ>$d{valor_servico}</vServ></vServPrest>),
           q(<trib>),
             q(<tribMun><tribISSQN>1</tribISSQN><tpRetISSQN>1</tpRetISSQN></tribMun>),
             q(<tribFed><piscofins><CST>00</CST></piscofins></tribFed>),
            qq(<totTrib><pTotTribSN>$d{p_tot_trib_sn}</pTotTribSN></totTrib>),
           q(</trib>),
         q(</valores>),
         q(</infDPS>);

    # --- 4. Digest do infDPS ---
    # O elemento sendo assinado herda o namespace do pai no documento final,
    # então adicionamos o xmlns explicitamente antes do hash.
    (my $inf_dps_for_hash = $inf_dps) =~ s/<infDPS/<infDPS xmlns="$NS"/;
    my $digest_b64 = encode_base64(sha256(encode('UTF-8', $inf_dps_for_hash)), '');

    # --- 5. SignedInfo ---
    # Precisa fechar tags explicitamente (nada de auto-fechar) porque o servidor verifica
    # as tags contra o formulário canônico exc-c14n#WithComments, que expande <Bla/> em <Bla></Bla>.
    my $signed_info = join '',
        q(<SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#">),
        q(<CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#WithComments"></CanonicalizationMethod>),
        q(<SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"></SignatureMethod>),
        qq(<Reference URI="#$id_dps">),
          q(<Transforms>),
            q(<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></Transform>),
            q(<Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#WithComments"></Transform>),
          q(</Transforms>),
          q(<DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"></DigestMethod>),
          qq(<DigestValue>$digest_b64</DigestValue>),
        q(</Reference>),
        q(</SignedInfo>);

    # --- 6. Assinatura RSA-SHA256 sobre os bytes SignedInfo ---
    my $rsa     = Crypt::PK::RSA->new(\$self->{key_pem});
    my $sig_b64 = encode_base64($rsa->sign_message(encode('UTF-8', $signed_info), 'SHA256', 'v1.5'), '');

    # --- 7. Monta o XML final ---
    my $xml = join '',
        q(<?xml version="1.0" encoding="UTF-8"?>),
        qq(<DPS xmlns="$NS" versao="$VERSAO">),
          $inf_dps,
          q(<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">),
            $signed_info,
            qq(<SignatureValue>$sig_b64</SignatureValue>),
            qq(<KeyInfo><X509Data><X509Certificate>$self->{cert_b64}</X509Certificate></X509Data></KeyInfo>),
          q(</Signature>),
        q(</DPS>);

    # --- 8. GZip + base64 ---
    my $xml_bytes = encode('UTF-8', $xml);
    my $gzipped;
    gzip(\$xml_bytes, \$gzipped) or croak "gzip failed: $GzipError";
    my $payload_b64 = encode_base64($gzipped, '');

    # --- 9. POST com TLS mútuo ---
    my $res = $self->{http}->post(
        $self->{_url},
        {
            content => encode_json({ dpsXmlGZipB64 => $payload_b64 }),
            headers => { 'Content-Type' => 'application/json' },
        },
    );
    my $body = eval { decode_json($res->{content}) } // {};
    return $body;
}


sub danfse {
    my ($self, $chave_acesso) = @_;
    croak "danfse() precisa de uma chave de acesso." unless defined $chave_acesso;
    my $res = $self->{http}->get('https://adn.nfse.gov.br/danfse/' . $chave_acesso);
    return $res->{success} ? $res->{content} : ();
}


sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or croak "Cannot open '$path': $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub _xml_escape {
    my ($str) = @_;
    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    return $str;
}

1;

__END__
=encoding utf8

=head1 NAME

Business::BR::NFSe - Consulta e emissão de NFS-e (Nota Fiscal de Serviços Eletrônica)
via API REST do Emissor Nacional (Sefin)

=head1 SYNOPSIS

    use Business::BR::NFSe;

    my $nfse = Business::BR::NFSe->new(
        cert_pem_path  => 'certificado.pem',
        key_pem_path   => 'chave_privada.pem',
        cnpj_prestador => '26744350000156',
        ibge_cidade    => '3304557',
        # Simples Nacional ME/EPP - ajuste como necessário
        op_simples_nacional => '3',
        reg_ap_trib_sn      => '1',
        regime_especial     => '0',
        p_tot_trib_sn       => '17.99',
    );

    my $resp = $nfse->emitir(
        serie                    => '1',
        n_dps                    => '12345',   # obrigatório incrementar por emissão
        data_emissao             => '2026-06-23T12:59:00-03:00',
        cpf_tomador              => '12345678909',
        nome_tomador             => 'Fulano de Tal',
        cod_tributacao_nacional  => '100201',
        cod_tributacao_municipal => '001',
        descricao_servico        => 'Descrição do serviço prestrado.',
        valor_servico            => '49.99',
    );

    if ($resp->{success}) {
        say 'OK ' . $resp->{content};
    } else {
        say "ERRO $resp->{status}: $resp->{content}\n";
    }

=head1 DESCRIPTION

This module provides a way to query and emit Brazilian service tax invoices
via the government's official REST API. Since the main audience
for this module are Brazilian developers, the documentation is provided
in portuguese only. If you need help with this module but don't speak
portuguese, please contact the author.

=head1 DESCRIÇÃO

Este módulo permite a consulta e emissão de Notas Fiscais de Serviço
Eletrônicas (NFS-e) diretamente da API REST do Emissor Nacional, sem
intermediários.

Este módulo incorpora uma postura minimalista de oferecer 80%
das funcionalidades com 20% do código, de modo a ser fácil de carregar
e utilizar em programas já existentes.

B<ATENÇÃO>: Este módulo emite I<somente> notas de serviço (NFSe).
Não é possível utilizá-lo para emitir notas fiscais de produto (NFe).

=head1 CONSTRUTOR

=head2 new( %args )

Instancia um novo objeto Business::BR::NFSe. Aceita os seguintes argumentos:

=over 4

=item cert_pem_path, key_pem_path

Caminhos para o certificado A1/A3 do ICP-Brasil e para a chave privada,
ambos em formato PEM. O certificado deve conter somente o bloco PEM puro,
sem os cabeçalhos de atributos do OpenSSL.

Obrigatório para emissão de notas de serviço.

=item cnpj_prestador

CNPJ da empresa prestadora dos serviços, utilize caso seu programa emita
de apenas um CNPJ. Somente dígitos, sem pontuação.

=item ibge_cidade

Código de cidade do IBGE da empresa prestadora do serviço. 7 digitos.
Veja L<IBGE::Municipios> para uma interface de consulta.

=item op_simples_nacional

Indicador do status da prestadora no Simples Nacional
1=Não Optante, 2=MEI, 3=ME/EPP. Padrão: 3.

=item reg_ap_trib_sn

Regime de apuração para os optantes do Simples Nacional:

1=federal+municipal no Simples, 2=federal no Simples, ISSQN fora do Simples.
Padrão: 1.

=item regime_especial

Código do regime especial. Padrão é 0 (nenhum).

=item p_tot_trib_sn

Valor aproximado do percentual de taxa do Simples Nacional (Lei 12.741/2012).
Padrão: '17.99'. Verifique o percentual da empresa prestadora pela alíquota do DAS.

=item ambiente

1=Produção, 2=Homologação. Padrão: 1.

=back

=head1 Emissão de Notas de Serviço Eletrônicas (NFS-e)

=head2 emitir( %dados )

Utilize esse método para emitir notas. Ele aceita os mesmos argumentos
descritos no construtor, de modo que você possa emitir notas de diferentes
prestadores de serviço com o mesmo objeto.

Além disso, é obrigatório especificar os dados do tomador do serviço,
preenchendo uma (e somente uma) das opções abaixo:

=over 4

=item cpf_tomador — CPF, somente dígitos

ou

=item cnpj_tomador — CNPJ, somente dígitos

ou

=item nao_nif_tomador — '1' (dispensado) ou '2' (não exigência), para estrangeiros.

=back

Outras propriedades obrigatórias na emissão da nota de serviço:

=over 4

=item serie - o número da série DPS

=item n_dps - o número sequencial do DPS (precisa ser único e incremental)

=item data_emissao - data da emissão em formato ISO8601, ex: '2026-03-04T12:59:00-03:00'

=item nome_tomador - nome completo (ou razão social) do tomador do serviço

=item cod_tributacao_nacional - código de 6 dígitos do serviço prestado (ex: '100201')

=item cod_tributacao_municipal - código do serviço municipal, ex: '001'

=item descricao_servico - texto livre para descrever o serviço (máx: 2000 caracteres)

=item valor_servico - valor do serviço prestado em reais (BRL), ex: '3869.49'

=back

Este método devolve um hashref com a resposta do HTTP::Tiny, com informações
a respeito da emissão (ou do erro gerado). Em caso de sucesso, um dos elementos
retornados será a chave de acesso da NFSe.

=head1 Obtendo o DANFSe (PDF da Nota de Serviço)

=head2 danfse( $chave )

Recebe uma chave de acesso (retornada ao chamar C<< emitir() >>) e retorna o
pdf da DANFSe em bytes, pronto para ser gravado em arquivo ou servido na sua
aplicação.


=head1 LICENÇA / LICENSE

As mesmas do Perl.
Same terms as Perl itself.

=cut
