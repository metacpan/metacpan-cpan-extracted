package Business::PT::CodigoPostal;

# ABSTRACT: Validação de códigos postais portugueses: distrito, região e localidades

use strict;
use warnings;

## Los nombres de distrito llevan acentos (Setúbal, Santarém, Évora, Bragança).
## Sin 'use utf8' saldrian como bytes UTF-8 crudos y quien los guardase en una
## base de datos con la conexion en UTF-8 acabaria con doble codificacion.
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(validate_cp localidades asignado distritos);

use Class::XSAccessor {
  accessors => [qw(codigo distrito distrito_code error iso_3166_2 region strict valid)]
};

our $VERSION = '0.02';


use constant {
    ERROR_FORMATO  => "Código postal não tem o formato NNNN-NNN",
    ERROR_DEFINIDO => "Código postal não definido",
    ERROR_ATRIBUIDO=> "Código postal não atribuído",
};

## Açores y Madeira pagan porte aparte, como Baleares o Canarias en Espana.
my %INSULAR = ('Açores' => 'Açores', 'Madeira' => 'Madeira');

## ISO 3166-2:PT. Los 18 distritos son PT-01..PT-18 por orden alfabetico, y las
## dos regiones autonomas rompen la serie: PT-20 y PT-30. Los ERP suelen
## elegir el estado o provincia por este codigo, asi que sin el una direccion
## portuguesa no se puede mapear.
my %ISO = (
    'Aveiro'           => 'PT-01', 'Beja'      => 'PT-02', 'Braga'     => 'PT-03',
    'Bragança'         => 'PT-04', 'Castelo Branco' => 'PT-05', 'Coimbra' => 'PT-06',
    'Évora'            => 'PT-07', 'Faro'      => 'PT-08', 'Guarda'    => 'PT-09',
    'Leiria'           => 'PT-10', 'Lisboa'    => 'PT-11', 'Portalegre'=> 'PT-12',
    'Porto'            => 'PT-13', 'Santarém'  => 'PT-14', 'Setúbal'   => 'PT-15',
    'Viana do Castelo' => 'PT-16', 'Vila Real' => 'PT-17', 'Viseu'     => 'PT-18',
    'Açores'           => 'PT-20', 'Madeira'   => 'PT-30',
);


sub validate_cp {
    my ($cp, $opts) = @_;
    $opts ||= {};

    $cp = _normalize($cp) unless $opts->{strict} // 1;

    return { valid => 0, error => ERROR_DEFINIDO } unless defined $cp && length $cp;

    return { valid => 0, error => ERROR_FORMATO, codigo => $cp }
        unless $cp =~ /\A([0-9]{4})-([0-9]{3})\z/;

    my ($p4, $suf) = ($1, $2);

    require Business::PT::CodigoPostal::Datos;

    ## Primero el prefijo, que resuelve el 98% de los casos; el codigo entero
    ## solo hace falta en los 13 prefijos que caen entre dos distritos.
    my $distrito = $Business::PT::CodigoPostal::Datos::PREFIJOS{$p4}
                // $Business::PT::CodigoPostal::Datos::EXCEPCIONES{"$p4$suf"};

    return { valid => 0, error => ERROR_ATRIBUIDO, codigo => "$p4-$suf" }
        unless defined $distrito;

    return {
        valid         => 1,
        codigo        => "$p4-$suf",
        cp4           => $p4,
        distrito      => $distrito,
        distrito_code => ($ISO{$distrito} // '') =~ s/^PT-//r,
        iso_3166_2    => $ISO{$distrito},
        region        => $INSULAR{$distrito} // 'Continente',
    };
}


## Los 18 distritos mas Açores y Madeira. No cambian: van como constante y no
## derivados de la tabla, para que la lista no dependa de que el volcado de
## GeoNames traiga al menos un codigo de cada uno.
##
## Por orden alfabetico sin contar los signos: 'Açores' antes que 'Aveiro'
## (acores/aveiro) y 'Évora' entre Coimbra y Faro. Ordenarlas con un sort a
## secas las mandaria al final, porque 'Ç' y 'É' caen detras de la 'Z' por
## punto de codigo.
my @DISTRITOS = (
    'Açores', 'Aveiro', 'Beja', 'Braga', 'Bragança', 'Castelo Branco',
    'Coimbra', 'Évora', 'Faro', 'Guarda', 'Leiria', 'Lisboa', 'Madeira',
    'Portalegre', 'Porto', 'Santarém', 'Setúbal', 'Viana do Castelo',
    'Vila Real', 'Viseu',
);

sub distritos { return @DISTRITOS }


sub localidades {
    my $cp = ref($_[0]) ? $_[0]->codigo : $_[0];

    my $r = validate_cp($cp, { strict => 0 });
    return () unless $r->{valid};

    require Business::PT::CodigoPostal::Localidades;

    (my $plano = $r->{codigo}) =~ s/-//;

    return Business::PT::CodigoPostal::Localidades::localidades($plano);
}


sub asignado {
    my $cp = ref($_[0]) ? $_[0]->codigo : $_[0];

    my $r = validate_cp($cp, { strict => 0 });
    return 0 unless $r->{valid};

    require Business::PT::CodigoPostal::Localidades;

    (my $plano = $r->{codigo}) =~ s/-//;

    return Business::PT::CodigoPostal::Localidades::asignado($plano);
}


sub _normalize {
    my $cp = shift;

    return unless defined $cp;

    $cp =~ s/\D//g;

    return unless length($cp) == 7;

    return substr($cp, 0, 4) . '-' . substr($cp, 4);
}


sub new {
    my $class = shift;
    my %args  = @_ == 1 && ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
    my $self  = bless {}, $class;

    $self->strict(defined $args{strict} ? $args{strict} : 1);
    $self->set($args{codigo}) if defined $args{codigo};

    return $self;
}


sub set {
    my ($self, $cp) = @_;

    my $res = $self->strict ? validate_cp($cp)
                            : validate_cp($cp, { strict => 0 });

    if ($res->{valid}) {
        $self->codigo($res->{codigo});
        $self->distrito($res->{distrito});
        $self->distrito_code($res->{distrito_code});
        $self->iso_3166_2($res->{iso_3166_2});
        $self->region($res->{region});
        $self->valid(1);
        $self->error(undef);

        return 1;
    }

    $self->error($res->{error});
    $self->codigo(undef);
    $self->distrito(undef);
    $self->distrito_code(undef);
    $self->iso_3166_2(undef);
    $self->region(undef);
    $self->valid(0);

    return 0;
}


sub insular {
    my $self = shift;

    return unless $self->valid;

    return ($self->region // '') eq 'Continente' ? 0 : 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::PT::CodigoPostal - Validação de códigos postais portugueses: distrito, região e localidades

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Business::PT::CodigoPostal qw(validate_cp localidades asignado);

  my $cp = validate_cp('1000-001');

  if ($cp->{valid}) {
      print $cp->{distrito};   # Lisboa
      print $cp->{region};     # Continente
  }
  else {
      print $cp->{error};
  }

  my @l = localidades('2100-049');   # Coruche
  asignado('9999-999');              # 0

  # interface OO
  my $cp = Business::PT::CodigoPostal->new(codigo => '4000-001');
  $cp->distrito;   # Porto
  $cp->insular;    # 0
  $cp->set('9000-001');

=head1 DESCRIPTION

Valida códigos postais portugueses no formato C<NNNN-NNN> e devolve o distrito,
a região e as localidades correspondentes.

=head2 O prefixo não chega

Em Espanha os dois primeiros dígitos do código postal I<são> o número da
província, por definição administrativa. Em Portugal não: o código postal é uma
divisão de distribuição e não respeita as fronteiras dos distritos. O prefixo de
dois dígitos é ambíguo em 25 dos 79 casos --- C<20> tanto é Lisboa como
Santarém.

Com quatro dígitos restam 13 prefixos ambíguos em 750, e esses resolvem-se com o
código completo. É por isso que este módulo traz tabelas em vez de uma regra.

=head1 NAME

Business::PT::CodigoPostal - Validação de códigos postais portugueses

=head1 SUBROUTINES/METHODS

=head2 codigo

O código postal guardado no objecto, já normalizado para C<NNNN-NNN>.

  my $codigo = $cp->codigo;

=head2 distrito

O nome do distrito, em português e com acentos: C<Bragança>, C<Setúbal>,
C<Évora>, C<Açores>.

  my $distrito = $cp->distrito;

=head2 region

A região logística: C<Continente>, C<Açores> ou C<Madeira>. O arquipélago paga
portes à parte, tal como as Baleares ou as Canárias em Espanha.

  my $region = $cp->region;

=head2 distrito_code

O número do distrito dentro da norma ISO 3166-2, sem o prefixo do país:
C<'11'> para Lisboa, C<'13'> para o Porto.

  my $code = $cp->distrito_code;

=head2 iso_3166_2

O código ISO 3166-2 completo: C<'PT-11'>, C<'PT-13'>, C<'PT-20'> para os Açores
e C<'PT-30'> para a Madeira.

Os 18 distritos são C<PT-01> a C<PT-18> por ordem alfabética; as duas regiões
autónomas quebram a série.

  my $iso = $cp->iso_3166_2;

=head2 error

A mensagem de erro quando o código não é válido; C<undef> quando é.

  print $cp->error unless $cp->valid;

=head2 strict

Controla se a entrada se normaliza. Ligado por omissão, isto é, não normaliza.

  $cp->strict(0);

=head2 valid

1 se o código postal é válido, 0 se não.

  my $ok = $cp->valid;

=head2 validate_cp

  my $r = validate_cp('1000-001');
  my $r = validate_cp('1000001', { strict => 0 });   # normaliza

Devolve sempre uma referência a hash, nunca lança excepção. Com C<valid> a 1
traz C<codigo>, C<cp4>, C<distrito> e C<region>; com C<valid> a 0 traz C<error>
e as restantes chaves não existem.

C<strict> está ligado por omissão e não normaliza a entrada. A 0 aceita o código
sem hífen ou com espaços, que é o que faz falta ao processar ficheiros.

Atenção ao alcance: nos 737 prefixos inequívocos basta o prefixo para saber o
distrito, e o sufixo não é verificado --- tal como C<Business::ES::CodigoPostal>
valida a gama e não o código concreto. Nos 13 prefixos que ficam entre dois
distritos o sufixo I<tem> de constar, porque sem ele não há maneira de decidir;
aí um sufixo desconhecido devolve C<não atribuído>. Para perguntar se um código
completo existe, use L</asignado>.

=head2 distritos

  my @d = distritos;   # ('Aveiro', 'Açores', 'Beja', ... 'Viseu')

Os 18 distritos mais as duas regiões autónomas, por ordem alfabética. Serve
para montar uma lista de escolha sem ter de a manter à parte.

=head2 localidades

  my @l = localidades('2100-049');   # ('Coruche')

Localidades do código postal, ordenadas. Lista vazia se não constar.

Os dados vivem em L<Business::PT::CodigoPostal::Localidades> e carregam-se
B<só ao chamar aqui>: validar um código ou resolver o distrito não lhes toca.

=head2 asignado

  asignado('1000-001');   # 1
  asignado('1000-999');   # 0

Certo se o código postal está atribuído a alguma localidade. É uma verificação
mais estreita do que C<valid>: um código pode ter um prefixo real e um sufixo
que nunca foi atribuído.

=head2 _normalize

Limpa a entrada quando C<strict> está a 0: tira tudo o que não seja dígito e
volta a pôr o hífen.

=head2 new

  my $cp = Business::PT::CodigoPostal->new(codigo => '1000-001');
  my $cp = Business::PT::CodigoPostal->new({ codigo => '1000001', strict => 0 });

=head2 set

Fixa um novo código postal. Devolve 1 se for válido, 0 se não.

=head2 insular

Certo se o código postal fica nos Açores ou na Madeira, que pagam portes à
parte.

=head2 localidades / asignado como métodos

Ambas as funções aceitam também um objecto:

  $cp->localidades;
  $cp->asignado;

=head1 AUTHOR

HDELGADO E<lt>hdelgado@cpan.orgE<gt>

=head1 FONTE DOS DADOS

Distritos, códigos postais e localidades de
L<GeoNames|https://www.geonames.org/> (ficheiro C<export/zip/PT.zip>), sob
licença Creative Commons Attribution 4.0:
L<https://creativecommons.org/licenses/by/4.0/>.

=head1 VER TAMBÉM

L<Business::ES::CodigoPostal> para códigos postais espanhóis.

=head1 LICENÇA

Copyright 2026 HDELGADO.

Software livre nos mesmos termos que o Perl. Os dados de localidades mantêm a
sua própria licença (CC BY 4.0).

=head1 AUTHOR

HDELGADO <hdelgado@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by HDELGADO.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
