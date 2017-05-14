package Business::ReportWriter::Pdf;

use strict;
use POSIX qw(setlocale LC_NUMERIC);
use utf8;

use base 'Business::ReportWriter';

sub init_fields {
    my ( $self, $parms ) = @_;

    $self->SUPER::fields($parms);
    my @fields = @$parms if $parms;

    # Find maximum line height
    $self->{font}{maxheight} = 8;
    for ( 0 .. $#{ $self->{report}{fields} } ) {
        $self->{fields}{ $fields[$_]{name} } = $_;
        if ( defined( $fields[$_]{font}{size} )
            && $fields[$_]{font}{size} > $self->{font}{_maxheight} )
        {
            $self->{font}{_maxheight} = $fields[$_]{font}{size};
        }
    }
}

sub init_breaks {
    my ( $self, $parms ) = @_;

    $self->SUPER::breaks($parms);

    # Find total break height
    $| = 1;

    for ( keys %$parms ) {
        next if /^_/;
        my $brk  = $parms->{$_};
        my $hbs  = $brk->{beforespace} || 0;
        my $hts  = 10;
        my $hfhs = 10;
        my $ts   = 10;

        #    $self->{fields}{$fields[$_]{name}} = $_;
        #    if (defined($fields[$_]{font}{size}) &&
        #      $fields[$_]{font}{size} > $self->{font}{_maxheight}) {
        #      $self->{font}{_maxheight} = $fields[$_]{font}{size};
        #    }
        $brk->{breakheight} = $hbs + $hts + $hfhs + $ts;
    }
}

# Routines for report writing
sub calc_yoffset {
    my ( $self, $fontsize ) = @_;

    $self->{ypos} -= $fontsize + 2;
    $self->check_page;

    return $self->{ypos};
}

sub page_footer {
    my ( $self, $fontsize ) = @_;

    my $break = '_page';
    $self->{breaks}{$break} = '_break';
    my $text = $self->make_text( 0, $self->{report}{breaks}{$break}{text} );
    $self->{breaktext}{$break} = $text;

    #$self->print_break();
    $self->{breaks}{$break} = "";
}

sub header_text {
    my $self = shift;

    my $page = $self->{pageData};

    for my $th ( @{ $self->{report}{page}{text} } ) {
        $self->process_field( $th, $page );
    }
}

sub print_pagenumber {
    my $self = shift;

    my $page = $self->{report}{page};

    my $text = $page->{number}{text} . $self->{pageData}{pagenr};
    $self->out_field( $text, $page->{number} );
    $self->calc_yoffset( $self->{font}{size} )
        unless $page->{number}{sameline};
}

sub print_pageheader {
    my $self = shift;

    my $page = $self->{pageData};
    $self->{ypos} = $self->{paper}{topmargen};

    $self->{ypos} -= mm_to_pt( $self->{report}{page}{number}{ypos} )
        if $page->{number}{ypos};

    $self->header_text();
    $self->print_pagenumber;
}

sub start_body {
    my $self = shift;

    my $body = $self->{report}{body};

    $self->set_font( $body->{font} );
    $self->{ypos} = $self->{paper}{topmargen} - mm_to_pt( $body->{ypos} )
        if $body->{ypos};
    my $heigth = mm_to_pt( $body->{heigth} ) if $body->{heigth};
    $heigth += mm_to_pt( $body->{ypos} ) if $body->{ypos};
    $self->{paper}{heigth} = $heigth if $heigth;

    $self->make_field_headers( $body->{FieldHeaders} );

    $self->{inHeader} = 0;
}

sub draw_graphics {
    my $self = shift;

    my $p        = $self->{pdf};
    my $graphics = $self->{report}{graphics};
    $p->set_gfxlinewidth( $graphics->{width} + 0 )
        if defined( $graphics->{width} );
    for ( @{ $graphics->{boxes} } ) {
        my $bottomy = $self->{paper}{topmargen} - mm_to_pt( $_->{bottomy} );
        my $topy    = $self->{paper}{topmargen} - mm_to_pt( $_->{topy} );
        $p->draw_rect(
            mm_to_pt( $_->{topx} ),    $bottomy,
            mm_to_pt( $_->{bottomx} ), $topy
        );
    }
}

sub draw_logos {
    my $self = shift;

    my $p     = $self->{pdf};
    my $logos = $self->{report}{logo};
    for ( @{ $logos->{logo} } ) {
        my $x = mm_to_pt( $_->{x} );
        my $y = $self->{paper}{topmargen} - mm_to_pt( $_->{y} );
        $p->add_img_scaled( $_->{name}, $x, $y, $_->{scale} );
    }
}

sub new_page {
    my $self = shift;

    $self->{inHeader} = 1;
    my $p = $self->{pdf};
    $self->{pageData}{pagenr}++;
    $self->{breaks}{'_page'} = "";
    $self->page_footer() if $self->{pageData}{pagenr} > 1;
    $self->{ypos} = $self->{paper}{topmargen};
    $p->new_page;
    $self->set_font( $self->{report}{page}{font} );
    $self->print_pageheader() if defined( $self->{report}{page} );
    $self->start_body();
    $self->draw_graphics();
    $self->draw_logos();
}

sub text_color {
    my ( $self, $color ) = @_;

    my $p = $self->{pdf};
    $p->set_textcolor($color);
}

sub set_linecolor {
    my ( $self, $fld_fgcolor ) = @_;

    my $fgcolor =
          $fld_fgcolor
        ? $fld_fgcolor
        : $self->{report}{textcolor} || 'black';
    $self->text_color($fgcolor);
}

sub draw_topline {
    my ($self) = @_;

    my $p = $self->{pdf};
    my $width = $self->{paper}{width} - 20;
    my $ypos  = $self->{ypos} - 3;
    $p->draw_line( 10, $ypos, $width, $ypos );
}

sub draw_underline {
    my ($self) = @_;

    my $p = $self->{pdf};
    my $width = $self->{paper}{width} - 20;
    my $ypos  = $self->{ypos} - $self->{font}{size} - 3;
    $p->draw_line( 10, $ypos, $width, $ypos );
}

sub draw_linebox {
    my ( $self, $shade ) = @_;

    my $p = $self->{pdf};
    my $width    = $self->{paper}{width} - 20;
    my $ypos     = $self->{ypos} - 3;
    my $fontsize = $self->{font}{size} + 2;
    $p->shade_rect( 10, $ypos, $width, $ypos - $fontsize, $shade );
}

sub begin_break {
    my ( $self, $rec, $fld ) = @_;

    $self->check_page( $fld->{breakheight} );
}

sub begin_line {
    my ( $self, $rec, $fld ) = @_;

    $self->set_font( $rec->{font} );
    $self->calc_yoffset( $fld->{beforespace} ) if $fld->{beforespace};
    $self->set_linecolor( $fld->{fgcolor} );
    $self->draw_linebox( $fld->{shade} ) if $fld->{shade};
    $self->draw_topline                  if $rec->{topline};
    $self->draw_underline                if $rec->{underline};
    $self->calc_yoffset( $self->{font}{size} );
}

sub begin_field {
    my ( $self, $field ) = @_;

    $self->set_font( $field->{font} );
    my $fontsize = $self->{font}{size};
}

sub out_field {
    my ( $self, $text, $field, $alt ) = @_;

    my $font = $alt->{font} || $field->{font};
    $self->set_font($font);
    $self->{ypos} = $self->{paper}{topmargen} - mm_to_pt( $field->{ypos} )
        if $field->{ypos};
    $self->calc_yoffset( $self->{font}{size} )
        if defined( $field->{nl} ) && $text;
    my $width = mm_to_pt( $field->{width} );
    $self->out_text( $text, $field->{xpos}, $self->{ypos}, $field->{align},
        $width );

}

sub set_font {
    my ( $self, $font ) = @_;

    my $p = $self->{pdf};
    if ( defined($font) ) {
        if ( $font->{size} ) {
            my $font_size = $font->{size} + 0;
            $p->set_size( $font->{size} ) if $self->{font}{size} != $font_size;
            $self->{font}{size} = $font_size;
        }
        if ( $font->{face} ) {
            $p->set_font( $font->{face} )
                if $self->{font}{face} ne $font->{face};
            $self->{font}{face} = $font->{face};
        }
    }
}

sub begin_list {
    my ($self) = @_;

    my $papersize   = $self->{report}{papersize}   || 'A4';
    my $orientation = $self->{report}{orientation} || 'Portrait';
    my $p           = new Business::ReportWriter::Pdf::Report(
        PageSize        => $papersize,
        PageOrientation => $orientation
    );

    $self->{pdf}  = $p;
    $self->{ypos} = -1;
    $self->set_papersize();
}

sub check_page {
    my ( $self, $yplus ) = @_;

    return if $self->{inHeader};
    my $bottommargen = $self->{paper}{topmargen} - $self->{paper}{heigth};
    $self->new_page() if $self->{ypos} - $yplus < $bottommargen;
}

sub get_doc {
    my ($self) = @_;

    my $p = $self->{pdf};
    $p->finish_report("none");
}

sub print_doc {
    my ( $self, $filename ) = @_;

    my $p = $self->{pdf};
    if ($filename) {
        open OUT, ">$filename";
        print OUT $p->finish_report("none");
        close OUT;
    }
}

sub set_papersize {
    my $self = shift;

    my $p    = $self->{pdf};
    my ( $pagewidth, $pageheigth ) = $p->get_pagedimensions();
    $self->{paper} = {
        width     => $pagewidth,
        topmargen => $pageheigth - 20,
        heigth    => $self->{paper}{topmargen}
    };
}

sub out_text {
    my ( $self, $text, $x, $y, $align, $width ) = @_;

    my $p = $self->{pdf};
    $x = mm_to_pt($x);
##
##print "$text er utf8\n" if utf8::is_utf8($text);
##print "$text er ikke utf8\n" unless utf8::is_utf8($text);
    utf8::decode($text);
    utf8::decode($text) if utf8::is_utf8($text);
    my $sw = 0;
    $sw = int( $p->get_stringwidth($text) + .5 ) if lc($align) eq 'right';
    $x -= $sw;
    my $margen    = 20;
    $width ||= $self->{paper}{width} - $x - 20;
    my $linespace = $self->{font}{size} + 2;

    $p->add_paragraph(
        $text, $x, $y,
        $self->{paper}{width} - $x - 20,
        $self->{paper}{topmargen} - $y,
        0, $linespace
    );
    my ( $hPos, $vPos ) = $p->get_add_textpos();
    $self->{ypos} = $vPos + $linespace if $self->{ypos} - $linespace > $vPos;
}

sub mm_to_pt {
    my $mm = shift;

    return int( $mm / .3527777 );
}

1;
__END__

=head1 NAME

Business::ReportWriter::Pdf - A Business Oriented ReportWriter.

=head1 SYNOPSIS

  use Business::ReportWriter::Pdf;

  my $rw = new Business::ReportWriter::Pdf();
  $rw->process_report($outfile, $report, $head, $list);

=head1 DESCRIPTION

Business::ReportWriter is a tool to make a Business Report from an array of
data.  The report output is generated based on a XML description of the report.

The report is written to a PDF file.

=head2 Method calls

=over 4

=item $obj->get_doc()

Deprecated (?)

=back

=head1 SEE ALSO

 Business::ReportWriter

=head1 COPYRIGHT

Copyright (C) 2003-2006 Kaare Rasmussen. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kaare Rasmussen <kar at jasonic.dk>
