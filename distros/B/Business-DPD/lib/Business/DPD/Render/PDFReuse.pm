package Business::DPD::Render::PDFReuse;

use strict;
use warnings;
use 5.010;

use version; our $VERSION = version->new('0.22');

use parent qw(Business::DPD::Render);
use Carp;
use Encode;
use PDF::Reuse;
use PDF::Reuse::Barcode;
use Text::Autoformat;

__PACKAGE__->mk_accessors(qw(template));

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

=head3 _multiline

    $renderer->_multiline(
        ['some','lines of','text'],
        {
            fontsize => 6,
            base_x   => 35,
            base_y   => 120,
            rotate   => 270,   # or 0
            align    =>
        },
    )

Render several lines of text using a some very crappy placing 
"algorithm". Patches welcome!

B<Note:> Input is expected to be C<utf8> and will be encoded as 
C<latin1> until someone can show me how to stuff utf8 into 
C<PDF::Reuse>.

=cut

sub _multiline {
    my ( $self, $data, $opts ) = @_;

    my $fontsize =  $opts->{fontsize} || 6;
    my $base_x = $opts->{base_x} // 0;
    my $base_y = $opts->{base_y} // 0;
    my $rotate = $opts->{rotate} // 0;
    my $line_height = $opts->{line_height} // 1;
    my $max_width = $opts->{max_width};

    prFontSize( $fontsize );

    $data=[$data] unless ref($data) eq 'ARRAY';

    foreach my $rawline (@$data) {
        next unless $rawline && $rawline =~ /[\w ]/;
        my @lines;
        if ( $max_width && length($rawline) >  $max_width) {
            my $formatted = autoformat($rawline, {left=>1,right=>$max_width});
            @lines = split(/\n/,$formatted);
        }
        else {
            push(@lines,$rawline);
        }
       
        foreach my $line (@lines) {
            prText(
                $base_x, $base_y,
                $line,
                $opts->{'align'} || '', $rotate
            );
            if ( $rotate == 270 ) {
                $base_x -= ( $fontsize + $line_height );
            }
            elsif ( $rotate == 0 ) {
                $base_y -= ( $fontsize + $line_height  );
            }
        }
    }
}

=head3 inc2pdf

    my $pdf_template = $class->inc2pdf(__PACKAGE__);

Returns the path to the PDF template with the same name as the 
implementing class (the PDF templates are installed alongside their 
class).

=cut

sub inc2pdf {
    my ( $class, $package ) = @_;
    $package =~ s/::/\//g;
    $package.='.pm';
    my $from_inc = $INC{$package};
    $from_inc =~ s/pm$/pdf/;
    return $from_inc;

    
}

1;

__END__

=head1 AUTHOR

Thomas Klausner C<<domm {at} cpan.org>>
RevDev E<lt>we {at} revdev.atE<gt>

=head1 SEE ALSO

PDF::Reuse

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
