package Business::ReportWriter::Pdf::Report;

use strict;
use PDF::API2;

my %DEFAULTS = (
    PageSize        => 'A4',
    PageOrientation => 'Portrait',
    Compression     => 1,
    PdfVersion      => 3,
    marginX         => 30,
    marginY         => 30,
    font            => "Helvetica",
    size            => 12,
);

my ( $day, $month, $year ) = ( localtime(time) )[ 3 .. 5 ];
my $DATE = sprintf "%02d/%02d/%04d", ++$month, $day, 1900 + $year;

my %INFO = (
    Creator      => "None",
    Producer     => "None",
    CreationDate => $DATE,
    Title        => "Untitled",
    Subject      => "None",
    Author       => "Auto-generated",
);

my @parameterlist = qw(
    PageSize
    PageWidth
    PageHeight
    PageOrientation
    Compression
    PdfVersion
);

sub new {
    my $class    = shift;
    my %defaults = @_;

    foreach my $dflt (@parameterlist) {
        if ( defined( $defaults{$dflt} ) ) {
            $DEFAULTS{$dflt} = $defaults{$dflt};    # Overridden from user
        }
    }

    # Set the width and height of the page
    my ( $x1, $y1, $pageWidth, $pageHeight )
        = PDF::API2::Util::page_size( $DEFAULTS{PageSize} );

    # Swap w and h if landscape
    if ( lc( $DEFAULTS{PageOrientation} ) =~ /landscape/ ) {
        my $tempW = $pageWidth;
        $pageWidth  = $pageHeight;
        $pageHeight = $tempW;
        $tempW      = undef;
    }

    my $MARGINX = $DEFAULTS{marginX};
    my $MARGINY = $DEFAULTS{marginY};

    # May not need alot of these, will review later
    my $self = {    #pdf          => PDF::API2->new(),
        hPos         => undef,
        vPos         => undef,
        size         => 12,                          # Default
        font         => undef,                       # the font object
        PageWidth    => $pageWidth,
        PageHeight   => $pageHeight,
        Xmargin      => $MARGINX,
        Ymargin      => $MARGINY,
        BodyWidth    => $pageWidth - $MARGINX * 2,
        BodyHeight   => $pageHeight - $MARGINY * 2,
        page         => undef,                       # the current page object
        page_nbr     => 1,
        align        => 'left',
        linewidth    => 1,
        linespacing  => 0,
        FtrFontName  => 'Helvetica-Bold',
        FtrFontSize  => 11,
        MARGIN_DEBUG => 0,
        PDF_API2_VERSION => $PDF::API2::VERSION,

        ########################################################
        # Cache for font object caching -- used by set_font() ###
        ########################################################
        __font_cache => {},
    };

    if ( length( $defaults{File} ) ) {
        $self->{pdf} = PDF::API2->open( $defaults{File} )
            or die "$defaults{File} not found: $!\n";

    }
    else {
        $self->{pdf} = PDF::API2->new();
    }

    # Default fonts
    $self->{font} = $self->{pdf}->corefont('Helvetica'); # Default font object
         #$self->{font}->encode('latin1');

    # Set the users options
    foreach my $key ( keys %defaults ) {
        $self->{$key} = $defaults{$key};
    }

    bless $self, $class;

    return $self;
}

sub get_pages {
    my $self = shift;

    return $self->{pdf}->pages;
}

sub new_page {
    my ($self, $no_page_number) = @_;

    # make a new page
    $self->{page} = $self->{pdf}->page;
    $self->{page}->mediabox( $self->{PageWidth}, $self->{PageHeight} );

    # Handle the page numbering if this page is to be numbered
    my $total = $self->get_pages;
    push( @{ $self->{no_page_num} }, $no_page_number );

    $self->{page_nbr}++;
    return (0);
}

sub get_pagedimensions {
    my $self = shift;

    return ( $self->{PageWidth}, $self->{PageHeight} );
}

sub set_size {
    my ( $self, $size ) = @_;

    $self->{size} = $size;
}

sub set_font {
    my ( $self, $font, $size ) = @_;

    if ( exists $self->{__font_cache}->{$font} ) {
        $self->{font} = $self->{__font_cache}->{$font};
    }
    else {
        $self->{font} = $self->{pdf}->corefont($font);
        $self->{__font_cache}->{$font} = $self->{font};
    }

    $self->{fontname} = $font;
}

sub get_add_textpos {
    my ($self) = @_;

    return ( $self->{hPos}, $self->{vPos} );
}

sub get_stringwidth {
    my ($self, $string) = @_;

    my $txt = $self->{page}->text;
    $txt->font( $self->{font}, $self->{size} );

    return $txt->advancewidth($string);
}

sub draw_line {
    my ( $self, $x1, $y1, $x2, $y2 ) = @_;

    my $gfx = $self->{page}->gfx;
    $gfx->move( $x1, $y1 );
    $gfx->linewidth( $self->{linewidth} );
    $gfx->linewidth(.1);
    $gfx->line( $x2, $y2 );
    $gfx->stroke;
}

sub draw_rect {
    my ( $self, $x1, $y1, $x2, $y2 ) = @_;

    my $gfx = $self->{page}->gfx;
    $gfx->linewidth( $self->{linewidth} );
    $gfx->rectxy( $x1, $y1, $x2, $y2 );
    $gfx->stroke;
}

sub shade_rect {
    my ( $self, $x1, $y1, $x2, $y2, $color ) = @_;

    my $gfx = $self->{page}->gfx;

    $gfx->fillcolor($color);
    $gfx->rectxy( $x1, $y1, $x2, $y2 );
    $gfx->fill;
    $gfx->fillcolor('black');
}

sub set_gfxlinewidth {
    my ( $self, $width ) = @_;

    $self->{linewidth} = $width;
}

sub add_img_scaled {
    my ( $self, $file, $x, $y, $scale ) = @_;

    $self->add_img( $file, $x, $y, $scale );
}

sub add_img {
    my ( $self, $file, $x, $y, $scale ) = @_;

    my %type = (
        jpeg => "jpeg",
        jpg  => "jpeg",
        tif  => "tiff",
        tiff => "tiff",
        pnm  => "pnm",
        gif  => "gif",
        png  => "png",
    );

    $file =~ /\.(\w+)$/;
    my $ext = $1;

    my $sub = "image_$type{$ext}";
    my $img = $self->{pdf}->$sub($file);
    my $gfx = $self->{page}->gfx;

    $gfx->image( $img, $x, $y, $scale );
}

sub set_textcolor {
    my ( $self, $color ) = @_;

    $self->{textcolor} = $color;
}

sub add_paragraph {
    my ( $self, $text, $hPos, $vPos, $width, $height, $indent, $lead ) = @_;

    my $txt = $self->{page}->text;
    $txt->font( $self->{font}, $self->{size} );

    my $textcolor = $self->{textcolor} || 'black';
    $txt->fillcolor($textcolor);
    $txt->lead($lead);    # Line spacing
    $txt->translate( $hPos, $vPos );
    $txt->paragraph( $text, $width, $height, -align => 'justified' );

    ( $self->{hPos}, $self->{vPos} ) = $txt->textpos;
}

sub finish_report {
    my ($self, $callback) = @_;

    my $total = $self->{page_nbr} - 1;

    # Call the callback if one was given to us
    if ( ref($callback) eq 'CODE' ) {
        &$callback( $self, $total );

        # This will print a footer if no $callback is passed for backwards
        # compatibility
    }
    elsif ( $callback !~ /none/i ) {
        &gen_page_footer( $self, $total, $callback );
    }

    $self->{pdf}->info(%INFO);
    my $out = $self->{pdf}->stringify;

    return $out;
}

1;
__END__

=head1 NAME

Business::ReportWriter::Pdf::Report - PDF helper routines.

=head1 SYNOPSIS

  use Business::ReportWriter::Pdf::Report;

  my $p = new Business::ReportWriter::Pdf::Report();

=head1 DESCRIPTION

Business::ReportWriter::Pdf::Report contains helper routines for 
Business::ReportWriter::Pdf

=head1 SEE ALSO

 Business::ReportWriter::Pdf

=head1 COPYRIGHT

Copyright (C) 2003-2006 Kaare Rasmussen. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kaare Rasmussen <kar at jasonic.dk>

