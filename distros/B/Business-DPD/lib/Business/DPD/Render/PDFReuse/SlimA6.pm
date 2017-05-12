package Business::DPD::Render::PDFReuse::SlimA6;

use strict;
use warnings;
use 5.010;

use version; our $VERSION = version->new('0.22');

use parent qw(Business::DPD::Render::PDFReuse);
use Carp;
use PDF::Reuse;
use PDF::Reuse::Barcode;
use Encode;
use DateTime;
use File::Spec::Functions qw(catfile);
use List::MoreUtils 'any';
use POSIX;

=head1 NAME

Business::DPD::Render::PDFReuse::SlimA6 - render a label in slim A6 using PDF::Reuse

=head1 SYNOPSIS

    use Business::DPD::Render::PDFReuse::SlimA6;
    my $renderer = Business::DPD::Render::PDFReuse::SlimA6->new( $dpd, {
        outdir => '/path/to/output/dir/',    
        originator => ['some','lines','of text'],
    });
    my $path = $renderer->render( $label );

=head1 DESCRIPTION

Render a DPD label using a slim A6-based template that also fits on a 
A4-divided-by-three-page. This is what we need at the moment. If you 
want to provide other formats, please go ahead and either release them 
as a standalone dist on CPAN or contact me to include your design.

=head1 METHODS

=head2 Public Methods

=cut

=head3 render

    my $path_to_file = $renderer->render( $label );

Render the label. Currently there is nearly no error checking. Also, 
things might not fit into their boxes...

The finished PDF will be named C<$barcode.pdf> (i.e. without checksum or starting char)

=cut

sub render {
    my ( $self, $label, $y_offset ) = @_;
    $y_offset //=0;

    my $outfile = catfile($self->outdir,$label->code . '.pdf');

    my @open_fd = _open_fd();

    $self->_begin_doc($label, $outfile, $y_offset);
    $self->_add_elements($label, $y_offset);
    $self->_end_doc($label, $y_offset);

    # tidy-up file descriptors after bug in PDF::Reuse (http://rt.cpan.org/Ticket/Display.html?id=41287)
    foreach my $fd_num (_open_fd()) {
        POSIX::close($fd_num)
            unless any { $_ == $fd_num } @open_fd;
    }

    return $outfile;
}

sub _open_fd {
    return (
        sort
        map { m{/(\d+)$} ? $1 : () }
        glob "/proc/$$/fd/*"
    );
}

sub _begin_doc {
    my ( $self, $label, $outfile, $y_offset ) = @_;
    
    prFile( $outfile );
    prMbox( 0, 0, 258, $y_offset+414 );
    prForm( {
            file => $self->template($label),
            page => 1,
            x    => 0,
            y    => $y_offset+0,
        }
    );
}

sub _add_elements {
    my ( $self, $label, $y_offset ) = @_;
    
    
    PDF::Reuse::Barcode::Code128(
        mode           => 'graphic',
        x              => 8,
        text           => 0,
        ySize          => 4.6,
        xSize          => 1,
        y              => $y_offset-25,
        drawBackground => 0,
        value          => chr(0xf5) . $label->code_barcode
    );

    my $font_path = $self->template($label);
    $font_path=~s/SlimA6(-.+)?.pdf/MONACO.TTF/;
    prTTFont($font_path);
#	prFont('Courier-Bold');
    
    # Barcode field
    prFontSize(9);
    prText( 126, $y_offset+6, $label->code_human, 'center' );

    # tracking number (inside Route field, above "Track" label)
    prFontSize(26);
    prText( 8, $y_offset+168, $label->depot );
    prFontSize(16);
    prText( 72, $y_offset+168, $label->serial );
    prFontSize(12);
    prText( 170, $y_offset+168, $label->checksum_tracking_number );

    # Service (inside Route field, above "Service" label)
    prFontSize(16);
    prText( 253, $y_offset+168, $label->service_text, 'right' );

    # Label-Origin (inside Route field, above barcode)
    prFontSize(4);
    my $now = DateTime->now;
    prText(
        126,
        $y_offset+111,
        join('; ',
            $now->strftime('%F %H:%M'),
            $self->_dpd->schema->resultset('DpdMeta')->search()->first->version,
            "Business-DPD-". Business::DPD->VERSION,
        ),
        'center'
    );

    # Servicecode-Country-RecipientZIP  (inside Route field, above Label-Origin)
    prFontSize(9);
    prText( 126, $y_offset+116,
        join( '-', $label->service_code, $label->country, $label->zip ),
        'center' );

    # Outbound-Sort, Destination-Sort (inside Route field, around Servicecode-Country-RecipientZIP)
    prFontSize(19);
    prText( 20, $y_offset+111, $label->o_sort );
    prText( 237, $y_offset+111, $label->d_sort, 'right' );

    # Destination text (inside Route field, below Track and Service label)
    if ( $label->route_code ) {
        prFontSize(30);
        prText(
            126,
            $y_offset+128,
            $label->country . '-'
                . $label->d_depot . '-'
                . $label->route_code,
            'center'
        );
    }
    else {
        prFontSize(38);
        prText( 126, $y_offset+128, $label->country . '-' . $label->d_depot, 'center' );
    }

    # depot info
    my $depot
        = $self->_dpd->schema->resultset('DpdDepot')->find( $label->depot );
    my @dep = (
        $depot->name1, $depot->name2, $depot->address1, $depot->address2,
        $depot->country . '-' . $depot->postcode . ' ' . $depot->city
    );
    push( @dep, 'Tel: ' . $depot->phone ) if $depot->phone;
    push( @dep, 'Fax: ' . $depot->fax )   if $depot->fax;
    $self->_multiline(
        \@dep,
        {   fontsize => 5,
            base_x   => 250,
            base_y   => $y_offset+387,
            rotate   => '270',
            line_height => 0.5,
        }
    );

    # originator
    $self->_multiline(
        $self->originator,
        {   fontsize => 5,
            base_x   => 217,
            base_y   => $y_offset+387,
            rotate   => '270',
            line_height => 0.5,
        }
    );


    # recipient
    my (@recipient,$locality);
    
    foreach my $line (@{$label->recipient}) {
        if (index($line,$label->zip) >= 0
            && ! defined $locality) {
            $locality = $line;
            $locality = uc($label->country).'-'.$locality
                unless index($locality,uc($label->country)) == 0;
        } else {
            push(@recipient,$line);
        }   
    }
    
    $self->_multiline( \@recipient,
        {   fontsize => 9,
            base_x   => 3,
            base_y   => $y_offset+381,
            max_width=> 35,
        }
    );
    
    prFontSize(13);
    prText( 3, $y_offset+316, $locality, 'left' );

    # weight
    prFontSize(11);
    prText( 155, $y_offset+268, $label->weight, 'center' );

    # lieferung n / x
    my $count;
    if ( $label->shipment_count_this && $label->shipment_count_total ) {
        $count = $label->shipment_count_this . '/'
            . $label->shipment_count_total;
    }
    else {
        $count = '1/1';
    }
    prText( 155, $y_offset+291, $count, 'center' );

    # referenznr
    $self->_multiline( $label->reference_number,
        {   fontsize => 8,
            base_x   => 37,
            base_y   => $y_offset+302,
            max_width=>15,
        }
    );

    # auftragsnr
    $self->_multiline( $label->order_number,
        {   fontsize => 8,
            base_x   => 37,
            base_y   => $y_offset+276,
            max_width=>15,
        }
    );
}

sub _end_doc {
    my ( $self, $label ) = @_;

    prEnd();
}

sub template {
    my ( $self, $label ) = @_;
    my $depot            = $self->_dpd->schema->resultset('DpdDepot')->find( $label->depot );
    my $depot_country    = lc($depot->country);
    my $default_tempate  = $self->inc2pdf(__PACKAGE__);
    my $country_template = $default_tempate;
    $country_template =~ s/\.pdf$/-$depot_country.pdf/;
    return (-f $country_template ? $country_template : $default_tempate);
}

1;

__END__

=head1 AUTHOR

Thomas Klausner C<<domm {at} cpan.org>>
RevDev E<lt>we {at} revdev.atE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
