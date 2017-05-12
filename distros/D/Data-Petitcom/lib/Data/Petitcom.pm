package Data::Petitcom;

use 5.10.0;
use strict;
use warnings;
our $VERSION = '0.03';

use parent qw{ Exporter };
our @EXPORT      = qw{ Save Load QRCode };
our @EXPORT_OK   = qw{ SaveFile LoadFile };
our %EXPORT_TAGS = ( all => [qw{ Save Load QRCode SaveFile LoadFile }] );

use Carp ();
use Data::Petitcom::PTC;
use Data::Petitcom::QRCode;
use Data::Petitcom::Resource;
use Path::Class;

sub Save {
    my $raw_data     = shift;
    my %opts         = @_;
    my $resource     = delete $opts{resource} || 'PRG';
    my $obj_resource = get_resource( resource => $resource, %opts );
    $obj_resource->data($raw_data);
    my $obj_ptc = $obj_resource->save(%opts);
    return $obj_ptc->dump;
}

sub Load {
    my $raw_ptc      = shift;
    my %opts         = @_;
    my $obj_ptc      = Data::Petitcom::PTC->new->load($raw_ptc);
    my $obj_resource = $obj_ptc->restore(%opts);
    return $obj_resource->data;
}

sub QRCode {
    my $ptc        = shift;
    my %opts       = @_;
    my $qr_type    = delete $opts{type};
    my $qr_ecc     = delete $opts{ecc};
    my $qr_version = delete $opts{version};

    my $raw_ptc = undef;
    given ($ptc) {
        when ( ref $ptc eq 'Data::Petitcom::PTC' ) {
            $raw_ptc = $ptc->dump;
        }
        when ( ! Data::Petitcom::PTC->is_ptc($ptc) ) {
            $raw_ptc = Save($ptc, %opts);
        }
        default { $raw_ptc = $ptc }
    }

    my $qr = Data::Petitcom::QRCode->new(
        type    => $qr_type,
        ecc     => $qr_ecc,
        version => $qr_version
    );
    return $qr->plot($raw_ptc);
}

sub SaveFile {
    my $save_file = shift;
    my $raw_data  = shift;
    my $save_fh
        = ( ref $save_file eq 'GLOB' )
        ? $save_file
        : file($save_file)->open('>') || Carp::croak "open failed: $!";
    my $raw_ptc = Save($raw_data, @_);
    binmode $save_fh;
    print $save_fh $raw_ptc;
}

sub LoadFile {
    my $load_file = shift;
    my $load_fh
        = ( ref $load_file eq 'GLOB' )
        ? $load_file
        : file($load_file)->open('<') || Carp::croak "open failed: $!";
    binmode $load_fh;
    my $raw_data = Load( do { local $/; <$load_fh> }, @_ );
    return $raw_data;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Data::Petitcom - Data converter for Petitcom mkII

=head1 SYNOPSIS

  use Data::Petitcom;

  my $prg = <<'EOP';
  PRINT "Hello World"
  EOP
  my $qrcodes = QRCode($prg, type => 'term', version => 5);
  my $qr_num = @$qrcodes;
  for my $i ( 1 .. $qr_num ) {
      printf(
          "QR: %d / %d\n%s\n",
          $i,
          $qr_num,
          $qrcodes->[ $i - 1 ],
      );
  }


  use Path::Class;
  use GD::Tiler;
  my $bmp = '8b_256x192.bmp';
  my $raw_bmp = file($bmp)->slurp;
  my $qrcodes = QRCode($raw_bmp, resource => 'GRP', name => 'TEST_GRP', type => 'img');
  my $tiled = GD::Tiler->tile(
      Images       => $qrcodes,
      Background   => 'white',
      ImagesPerRow => 3,
  );
  file('qrcodes.png')->open('>')->print($tiled);

=head1 DESCRIPTION

Data::Petitcom is data converter for Petitcom mkII.

following resources supported.

=over

=item PRG: Program

=item GRP: Graphics (256x192 pixels 8bit-color bitmap)

=item CHR: User character (256x64 pixels 8bit-color bitmap)

=item COL: Color (8bit-color bitmap)

=back

=head1 FUNCTIONS

=head2 Exported Functions

=over 4

=item Save($raw_data, %opts)

Turn raw data into PTC.

=item Load($raw_ptc, %opts)

Turn PTC into raw data.

=item QRCode(($raw_ptc|$raw_data|$obj_ptc), %opts)

Returns barcode for the data (or object) specified.

=back

=head2 Exportable Functions

=over 4

=item SaveFile($ptc_file, $raw_data, %opts)

Writes the PTC to a file.

=item LoadFile($ptc_file, %opts)

Reads the PTC from a file.

=back

=head1 AUTHOR

hayajo <hayajo@cpan.org>

=head1 SEE ALSO

L<プチコンmkII|http://smileboom.com/special/ptcm2/>

L<Petit Computer|http://www.petitcomputer.com/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
