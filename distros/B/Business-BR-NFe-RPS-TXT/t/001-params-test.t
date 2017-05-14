use strict;
use Business::BR::NFe::RPS::TXT;
use Test::More;

my $txt = new Business::BR::NFe::RPS::TXT(
    data_ini => '20120202',
    data_fim => '20120204',
    inscricao_municipal => '12345667',
);

ok($txt->adiciona_rps(
        serie  => '011',
        numero => '00',
        emissao => '20121222',
        situacao => '0',
        valor_servico => 2400.34,
        valor_deducao => 140.45,
        codigo_servico => '00',
        aliquota => '00',
        iss_retido => '1',
        cpf_cnpj_flag => '1',
        cpf_cnpj      => '00',
        inscricao_municipal => '00',
        inscricao_estadual => '00',
        razao_social => '00',
        endereco_tipo => '00',
        endereco => '00',
        endereco_num => '00',
        endereco_complemento => '00',
        endereco_bairro => '00',
        endereco_cidade => '00',
        endereco_uf => '00',
        endereco_cep => '00',
        email => '00',
        discriminacao => '00',
), 'adicionado rps');


ok(my $rps = $txt->gerar_txt, 'gerando txt');

is($rps,'1001123456672012020220120204'."\r\n".
        '2RPS  011  000000000000201212220000000000240'.
        '034000000000014045000000000110000000000000000'.
        '00000000000000000000                         '.
        '                                             '.
        '   00 00                                     '.
        '           00        00                      '.
        '      00                            00       '.
        '                                         0000'.
        '00000000                                     '.
        '                                    00'."\r\n".
        '90000001000000000240034000000000014045'."\r\n", 'Conteudo gerado OK');

done_testing;



