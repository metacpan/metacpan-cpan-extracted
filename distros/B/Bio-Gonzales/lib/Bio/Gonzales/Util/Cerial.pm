package Bio::Gonzales::Util::Cerial;

use warnings;
use strict;
use Carp;
use Bio::Gonzales::Util::File qw/open_on_demand/;

use YAML::XS;
use JSON::XS;
use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT = qw(
    ythaw yfreeze yslurp yspew
    jthaw jfreeze jslurp jspew
);

BEGIN {
    *yfreeze = \&YAML::XS::Dump;
    *ythaw   = \&YAML::XS::Load;
    #*jfreeze = \&JSON::XS::encode_json;
    *jthaw = \&JSON::XS::decode_json;
}

sub jfreeze {
    return JSON::XS->new->indent(1)->utf8->allow_nonref->encode(@_);
}

sub _spew {
    my $dest = shift;
    my $data = shift;

    my ( $fh, $was_open ) = open_on_demand( $dest, '>' );
    binmode $fh, ':utf8' unless(ref $fh eq 'IO::Zlib');
    local $/ = "\n";

    print $fh $data;
    $fh->close unless $was_open;
}

sub _slurp {
    my $src = shift;
    my ( $fh, $was_open ) = open_on_demand( $src, '<' );
    binmode $fh, ':utf8' unless(ref $fh eq 'IO::Zlib');
    local $/ = "\n";

    my $data = do { local $/; <$fh> };

    $fh->close unless $was_open;
    return $data;
}

sub yslurp { return ythaw( _slurp(shift) ) }
sub jslurp { return jthaw( _slurp(shift) ) }
sub yspew  { my $file = shift; _spew( $file, yfreeze( $_[0] ) ) }
sub jspew  { my $file = shift; _spew( $file, jfreeze( $_[0] ) ) }

__END__

=head1 NAME

Bio::Gonzales::Util::Cerial - convenience functions for yaml storage

=head1 SYNOPSIS

    use Bio::Gonzales::Util::YAML;

    my $yaml_string = freeze \%data;
    my $data = thaw $yaml_string;

    freeze_file $filename, \%data ;
    my $data = thaw_file $filename;

=head1 DESCRIPTION
    
    Bio::Gonzales::Util::YAML provides some handy functions to work with yaml data

=head1 EXPORT

=head2 $yaml_string = freeze($data,...);

=head2 $data = thaw($yaml_string);

=head2 freeze_file($filename, $data, ...);

=head2 $data = thaw_file($filename);

=cut
