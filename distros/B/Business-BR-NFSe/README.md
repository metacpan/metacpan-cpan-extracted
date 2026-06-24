# Business-BR-NFSe

Business::BR::NFSe - Consulta e emissão de NFS-e (Nota Fiscal de Serviços Eletrônica)
via API REST do Emissor Nacional (Sefin)

### SYNOPSIS

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

### DESCRIPTION

This module provides a way to query and emit Brazilian service tax invoices
via the government's official REST API. Since the main audience
for this module are Brazilian developers, the documentation is provided
in portuguese only. If you need help with this module but don't speak
portuguese, please contact the author.

### DESCRIÇÃO

Este módulo permite a consulta e emissão de Notas Fiscais de Serviço
Eletrônicas (NFS-e) diretamente da API REST do Emissor Nacional, sem
intermediários.

Este módulo incorpora uma postura minimalista de oferecer 80%
das funcionalidades com 20% do código, de modo a ser fácil de carregar
e utilizar em programas já existentes.

**ATENÇÃO**: Este módulo emite I<somente> notas de serviço (NFSe).
Não é possível utilizá-lo para emitir notas fiscais de produto (NFe).

### USO

Para detalhes dos métodos disponíveis, consultar a [documentação oficial](https://metacpan.org/pod/Business::BR::NFSe).
