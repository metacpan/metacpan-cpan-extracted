package Business::BR::NFe::RPS::TXT;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use Carp;


subtype 'DataRps', as 'Str',
  where { /^[1-2][0-9][0-9][0-9][0-1][0-9][0-3][0-9]$/ },
  message { 'The date you provided is not for NFe::RPS' };

has data_ini => (
    is       => 'ro',
    isa      => 'DataRps',
    required => 1
);

has data_fim => (
    is       => 'ro',
    isa      => 'DataRps',
    required => 1
);

has inscricao_municipal => (
    is       => 'ro',
    required => 1
);

has _total_servico => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    handles => {
        inc_total_servico   => 'inc',
        dec_total_servico   => 'dec',
        reset_total_servico => 'reset'
    },
);

has _total_deducao => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    handles => {
        inc_total_deducao   => 'inc',
        dec_total_deducao   => 'dec',
        reset_total_deducao => 'reset'
    },
);

has _rps_lines => (
    traits  => ['String'],
    is      => 'ro',
    isa     => 'Str',
    default => q{},
    handles => {
        add_rps_lines     => 'append',
        replace_rps_lines => 'replace',
    },
);

has _total_linhas => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    handles => {
        inc_total_linhas   => 'inc',
        dec_total_linhas   => 'dec',
        reset_total_linhas => 'reset'
    },
);

sub _pad_str {
    my ( $str, $size ) = @_;
    return $str . ' ' x ( $size - length($str) );
}

sub _pad_num {
    my ( $num, $size, $round ) = @_;

    if ( $round && $round =~ /^[0-9]$/ ) {
        $round = int( '1' . '0' x ( $round - 1 ) );
    }
    else {
        $round = 1;
    }
    $num = $num * $round;
    if ( ref $size eq 'ARRAY' ) {
        croak "Not a number";
    }
    else {
        return sprintf( '%0' . $size . 's', $num * $round );
    }
}


sub adiciona_rps {
    my ( $self, %params ) = @_;

    # TODO Data::Verifier
    # param 1: esse daqui aceita date, str e num.
    # param 2: tamanho : positivo = pad, negativo = maximo
    # param 3:
    #    INT = pra numero = round de truncate
    #    ARRAY = valores aceitos

    # ps: todos os campos sao relativos ao tomador
    my $campos = {
        serie   => [ 'str', 5 ],
        numero  => [ 'num', 12 ],
        emissao => ['date'],
        situacao => [ 'str', 1, [ 'T', 'I', 'F', 'C', 'E', 'J' ] ],
        valor_servico  => [ 'num', 15, 2 ],
        valor_deducao  => [ 'num', 15, 2 ],
        codigo_servico => [ 'num', 5 ],
        aliquota       => [ 'num', 4,  2 ],
        iss_retido    => [ 'num', [ 1, 2, 3 ] ],
        cpf_cnpj_flag => [ 'num', [ 1, 2, 3 ] ],
        cpf_cnpj             => [ 'num', 14 ],
        inscricao_municipal  => [ 'num', 8 ],
        inscricao_estadual   => [ 'num', 12 ],
        razao_social         => [ 'str', 75 ],
        endereco_tipo        => [ 'str', 3 ],
        endereco             => [ 'str', 50 ],
        endereco_num         => [ 'str', 10 ],
        endereco_complemento => [ 'str', 30 ],
        endereco_bairro      => [ 'str', 30 ],
        endereco_cidade      => [ 'str', 50 ],
        endereco_uf          => [ 'str', 2 ],
        endereco_cep         => [ 'num', 8 ],
        email                => [ 'str', 75 ],
        discriminacao        => [ 'str', -1000 ],
    };
    $params{aliquota} = $params{aliquota} * 100 if $params{aliquota};
    $params{discriminacao} =~ s/\r?\n/|/g;

    my $out = $self->_formata( $campos, %params );
    my @ordem = qw/
      serie
      numero
      emissao
      situacao
      valor_servico
      valor_deducao
      codigo_servico
      aliquota
      iss_retido
      cpf_cnpj_flag
      cpf_cnpj
      inscricao_municipal
      inscricao_estadual
      razao_social
      endereco_tipo
      endereco
      endereco_num
      endereco_complemento
      endereco_bairro
      endereco_cidade
      endereco_uf
      endereco_cep
      email
      discriminacao/;
    my $line = '2';    # registro 2 versao 001
    $line .= _pad_str( defined $params{tipo} &&
        $params{tipo} =~ /^RPS(\-M)?$/ ? $params{tipo} : 'RPS', 5 );

    foreach (@ordem) {
        $line .= $out->{$_};
    }
    $line .= "\r\n";

    $self->add_rps_lines($line);

    $self->inc_total_deducao( $params{valor_deducao} );
    $self->inc_total_servico( $params{valor_servico} );

    $self->inc_total_linhas;
    return 1;
}

sub _formata {
    my ( $self, $config, %params ) = @_;
    my $x = {};
    foreach my $campo ( keys %$config ) {
        my $ref = $config->{$campo};
        next unless ref $ref eq 'ARRAY';

        croak "The field '$campo' not send." unless defined $params{$campo};

        if ( $ref->[0] eq 'str' ) {
            my $size = $ref->[1];

            if ( $size > 0 && length( $params{$campo} ) > $size ) {
                croak "The field '$campo' (str) is bigger than $size (length)";
            }
            elsif ( $size < 0 ) {
                $size = $size * -1;
                if ( length( $params{$campo} ) > $size ) {
                    croak
                      "The field '$campo' (str) is bigger than $size (length)";
                }
                $x->{$campo} = $params{$campo};
            }
            else {
                $x->{$campo} = _pad_str( $params{$campo}, $size );
            }

        }
        elsif ( $ref->[0] eq 'num' ) {
            $params{$campo} ||= 0;
            if ( $params{$campo} !~ /^[0-9]+(?:\.[0-9]+)?$/ ) {
                croak
"The field '$campo' (num) with value $params{$campo} is not valid";
            }
            else {
                my $size  = $ref->[1];
                my $round = $ref->[2];
                if ( ref $size eq 'ARRAY' ) {
                    my %valid = map { $_ => 1 } @$size;
                    croak "The field '$campo' (num) is invalid."
                      unless $valid{ $params{$campo} };
                    $size = 1;    # WARNING nao era pra ser assim..
                }
                elsif ( length( $params{$campo} ) > $size ) {
                    croak
                      "The field '$campo' (num) is bigger than $size (length)";
                }
                $x->{$campo} = _pad_num( $params{$campo}, $size, $round );
            }

        }
        elsif ( $ref->[0] eq 'date' ) {
            if ( $params{$campo} !~ /^\d{4}\d{2}\d{2}$/ ) {
                croak "The field '$campo' (date) is not in format AAAAMMDD";
            }
            else {
                $x->{$campo} = $params{$campo};
            }
        }
    }
    return $x;
}


sub gerar_txt {
    my ($self) = @_;

    my $campos = {
        data_fim            => ['date'],
        data_ini            => ['date'],
        inscricao_municipal => [ 'num', 8 ],
    };

    my $out = $self->_formata(
        $campos,
        data_fim            => $self->data_fim,
        data_ini            => $self->data_ini,
        inscricao_municipal => $self->inscricao_municipal
    );

    my $str = '1001'
      . $out->{inscricao_municipal}
      . $out->{data_ini}
      . $out->{data_fim} . "\r\n"
      . $self->_rps_lines;

    $str .= '9'
      . _pad_num( $self->_total_linhas,  7 )
      . _pad_num( $self->_total_servico, 15, 2 )
      . _pad_num( $self->_total_deducao, 15, 2 ) . "\r\n";

    return $str;
}

1;

__END__

=pod

=head1 NAME

Business::BR::NFe::RPS::TXT

=head1 VERSION

version 0.0124

=head1 SYNOPSIS

    my $txt = new Business::BR::NFe::RPS::TXT(
        data_ini => '20120202',
        data_fim => '20120204',
        inscricao_municipal => '12345667',
    );

    $txt->adiciona_rps(
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
    );

    $txt->gerar_txt;

=head1 DESCRIPTION

O sistema da Nota Fiscal Paulistana permite que sejam transferidas informações dos contribuintes para a  Prefeitura em arquivos no formato texto. Tais arquivos devem atender a um layout pré-definido, apresentado em http://nfpaulistana.prefeitura.sp.gov.br/arquivos/manual/NFe_Layout_RPS.pdf

=head1 METHODS

=head2 adiciona_rps

Adicionar informações sobre um RPS. Verificar a SYNOPSIS para exemplo.

=head2 gerar_txt

Retorna o conteúdo para ser gravado em um arquivo.

Atenção: O arquivo deve ser salvo em ISO 8859-1,
este modulo não modifica nenhum campo enviado além de ajustar os paddings.

=head1 NAME

=UTF8

Business::BR::NFe::RPS::TXT - Gerar arquivo de envio de RPS em lote baseado no sistema de nota fiscal paulistana.

Formato do arquivo na versao TXT 001.

=head1 TODO

=over 4

=item *

Limitar os dados em 10MB.

=item *

Adicionar suporte para RPS-C = Recibo Provisório de Serviços simplificado (Cupons).

=back

=head1 SUPPORT

=head2 Perldoc

Você pode encontrar documentação para este módulo com o comando perldoc (para ler)

    perldoc Business::BR::NFe::RPS::TXT

=head2 Github

Se você quiser contribuir com o código, você pode fazer um fork deste módulo no github:

L<https://github.com/renatoaware/perl-business-br-nfe-txt>

Você também pode reportar problemas por lá!

=head1 AUTHOR

Renato Cron <renato@aware.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Aware TI <http://www.aware.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
