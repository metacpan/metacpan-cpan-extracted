package Bio::Gonzales::Util::Cerial;

use warnings;
use strict;
use Carp;
use Bio::Gonzales::Util::File qw/open_on_demand/;

use Try::Tiny;
use YAML::XS;
use JSON::XS;
use Data::Dumper;
use Storable qw/nstore_fd fd_retrieve/;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.062'; # VERSION

@EXPORT = qw(
  ythaw yfreeze yslurp yspew
  jthaw jfreeze jslurp jspew
  stoslurp stospew
);

BEGIN {
  *yfreeze = \&YAML::XS::Dump;
  *ythaw   = \&YAML::XS::Load;
  #*jfreeze = \&JSON::XS::encode_json;
  *jthaw = \&JSON::XS::decode_json;
}

our $JSON = JSON::XS->new->indent(1)->utf8->allow_nonref;

sub jfreeze {
  my $r;
  my @d = @_;
  try {
    $r = $JSON->encode(@d);
  }
  catch {
    confess Dumper \@d;
  };

}

sub _spew {
  my $dest = shift;
  my $data = shift;

  my ( $fh, $was_open ) = open_on_demand( $dest, '>' );
  binmode $fh, ':utf8' unless ( ref $fh eq 'IO::Zlib' );
  local $/ = "\n";

  print $fh $data;
  $fh->close unless $was_open;
}

sub _slurp {
  my $src = shift;
  my ( $fh, $was_open ) = open_on_demand( $src, '<' );
  binmode $fh, ':utf8' unless ( ref $fh eq 'IO::Zlib' );
  local $/ = "\n";

  my $data = do { local $/; <$fh> };

  $fh->close unless $was_open;
  return $data;
}

sub yslurp { return ythaw( _slurp(shift) ) }
sub jslurp { return jthaw( _slurp(shift) ) }
sub yspew  { my $file = shift; _spew( $file, yfreeze( $_[0] ) ) }
sub jspew  { my $file = shift; _spew( $file, jfreeze( $_[0] ) ) }

sub stospew {
  my $dest = shift;
  my $data = shift;

  my ( $fh, $was_open ) = open_on_demand( $dest, '>' );
  nstore_fd( $data, $fh );
  $fh->close unless ($was_open);
}

sub stoslurp {
  my $src = shift;
  my ( $fh, $was_open ) = open_on_demand( $src, '<' );
  my $data = fd_retrieve($fh);
  $fh->close unless $was_open;
  return $data;
}

__END__

=head1 NAME

Bio::Gonzales::Util::Cerial - convenience functions for yaml and json IO

=head1 SYNOPSIS

    use Bio::Gonzales::Util::Cerial;

    # YAML IO
    my $yaml_string = yfreeze(\%data);
    my $data = ythaw($yaml_string);

    yspew($filename, \%data);
    my $data = yslurp($filename);

    # JSON IO
    my $json_string = jfreeze(\%data);
    my $data = jthaw($json_string);

    jspew($filename, \%data);
    my $data = jslurp($filename);


=head1 DESCRIPTION
    
=item B<< $yaml_string = yfreeze(\%data) >>

Serialize data structure as yaml string

=item B<< $data = ythaw($yaml_string) >>

UNserialize data structure from yaml string

=item B<< yspew($filename, \%data) >>

Serialize data structure as yaml string to a file

=item B<< my $data = yslurp($filename) >>

UNserialize data structure from yaml file

=item B<< my $json_string = jfreeze(\%data) >>

Serialize data structure as json string

=item B<< my $data = jthaw($json_string) >>

UNserialize data structure from json string

=item B<< jspew($filename, \%data) >>

Serialize data structure as json string to a file

=item B<< my $data = jslurp($filename) >>

UNserialize data structure from json file

=head1 EXPORT

The following functions are exported by default

    ythaw
    yfreeze
    yslurp
    yspew

    jthaw
    jfreeze
    jslurp
    jspew

=cut
