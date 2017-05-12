package Business::BR::Boleto::Renderer::PDF;
$Business::BR::Boleto::Renderer::PDF::VERSION = '0.000002';
use Moo;
use PDF::API2;
use Const::Fast;
use Locale::Currency::Format;

use Business::BR::Boleto::Utils qw{ mod11 };

use Cwd qw{ abs_path };
use Digest::SHA qw{ sha1_hex };
use Encode qw{ decode_utf8 };
use File::Path qw{ make_path };
use File::ShareDir qw{ module_file };
use File::Spec::Functions qw{ catdir };

has 'boleto' => (
    is       => 'ro',
    required => 1,
);

has 'base_dir' => (
    is       => 'ro',
    required => 1,
);

has 'file' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;

        my $hash = sha1_hex $self->boleto->codigo_barras;
        my $dir  = $self->base_dir;
        my $path = catdir( $dir, map { substr $hash, 0, $_ } 1 .. 3 );

        make_path($path);

        return abs_path( catdir( $path, $hash . '.pdf' ) );
    }
);

has 'template' => (
    is      => 'ro',
    builder => sub {
        module_file( 'Business::BR::Boleto::Renderer::PDF', 'template.pdf' );
    },
);

sub render {
    my ($self) = @_;

    my $pdf  = PDF::API2->open( $self->template );
    my $font = $pdf->corefont('Helvetica');
    my $page = $pdf->openpage(1);
    my $text = $page->text;

    ## Data do documento / data de processamento
    my $data_documento =
      $self->boleto->pagamento->data_documento->strftime('%d/%m/%Y');

    ## Data de vencimento
    my $data_vencimento =
      $self->boleto->pagamento->data_vencimento->strftime('%d/%m/%Y');

    ## Valor do documento
    my $valor_documento =
      currency_format( 'BRL', $self->boleto->pagamento->valor_documento,
        FMT_COMMON );

    ##########################################################################
    ## Corpo - Ficha de Compensação
    ##########################################################################
    $text->font( $font, 8 );

    _print( $text, 19,  421, $self->boleto->pagamento->local_pagamento );
    _print( $text, 19,  398, $self->boleto->cedente->nome );
    _print( $text, 19,  375, $data_documento );
    _print( $text, 334, 375, $data_documento );
    _print( $text, 93,  375, $self->boleto->pagamento->numero_documento );
    _print( $text, 183, 375, $self->boleto->pagamento->especie );
    _print( $text, 271, 375, $self->boleto->pagamento->aceite );
    _print( $text, 93,  353, $self->boleto->cedente->carteira );
    _print( $text, 150, 353, $self->boleto->pagamento->moeda );
    _print( $text, 228, 353, $self->boleto->pagamento->quantidade );
    _print( $text, 334, 353, $self->boleto->pagamento->valor );
    _print( $text, 455, 421, $data_vencimento );
    _print( $text, 455, 375, $self->boleto->pagamento->nosso_numero );
    _print( $text, 455, 353, $valor_documento );
    _print( $text, 19,  217, $self->boleto->sacado->nome );
    _print( $text, 19,  205, $self->boleto->sacado->documento );
    _print( $text, 19,  193, $self->boleto->sacado->endereco );
    _print( $text, 19,  168, $self->boleto->avalista->nome );
    _print( $text, 19,  156, $self->boleto->avalista->documento );
    _print( $text, 19,  144, $self->boleto->avalista->endereco );

    ## Instruções
    my @instrucoes =
      ref $self->boleto->pagamento->instrucoes eq 'ARRAY'
      ? @{ $self->boleto->pagamento->instrucoes }
      : split /\n/,
      $self->boleto->pagamento->instrucoes;

    foreach my $linha ( 0 .. @instrucoes ) {
        _print( $text, 19, 324 - 12 * $linha, $instrucoes[$linha] );
    }

    ##########################################################################
    ## Corpo - Recibo do Sacado
    ##########################################################################

    _print( $text, 19,  641, $self->boleto->cedente->nome );
    _print( $text, 397, 641, $self->boleto->pagamento->especie );
    _print( $text, 432, 641, $self->boleto->pagamento->quantidade );
    _print( $text, 478, 641, $self->boleto->pagamento->nosso_numero );
    _print( $text, 19,  618, $self->boleto->pagamento->numero_documento );
    _print( $text, 195, 618, $self->boleto->cedente->documento );
    _print( $text, 313, 618, $data_vencimento );
    _print( $text, 432, 618, $valor_documento );
    _print( $text, 19,  572, $self->boleto->sacado->nome );
    _print( $text, 460, 572, $self->boleto->sacado->documento );

    ##########################################################################
    ## Código de barras
    ##########################################################################
    my $barcode = $pdf->xo_2of5int(
        '-code' => $self->boleto->codigo_barras,
        '-zone' => 40,
    );

    $page->gfx->formimage( $barcode, 19, 90 );

    ##########################################################################
    ## Cabeçalho
    ##########################################################################
    $font = $pdf->corefont('Helvetica-Bold');
    $text->font( $font, 13 );
    _print( $text, 214, 670, $self->boleto->linha_digitavel );
    _print( $text, 214, 450, $self->boleto->linha_digitavel );

    $text->font( $font, 18 );
    my $cod_banco = 431;#$self->boleto->banco->codigo;
    my $dv_banco  = mod11($cod_banco);
    _print( $text, 155, 668, $cod_banco . '-' . $dv_banco );
    _print( $text, 155, 448, $cod_banco . '-' . $dv_banco );

    my $logo = $self->boleto->banco->logo;
    my $png  = $pdf->image_png($logo);
    $page->gfx->image( $png, 13.05, 658.25, 133.60, 34.10 );
    $page->gfx->image( $png, 13.05, 439.30, 133.60, 34.10 );

    $pdf->saveas( $self->file );
}

sub _print {
    my ( $element, $x, $y, $content ) = @_;

    $element->translate( $x, $y );
    $element->text( decode_utf8 $content);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BR::Boleto::Renderer::PDF

=head1 VERSION

version 0.000002

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
