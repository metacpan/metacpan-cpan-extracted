package Bio::Gonzales::Feat::IO;

use warnings;
use strict;
use Carp;

use 5.010;
use Bio::Gonzales::Util::File qw/open_on_demand/;
use Bio::Gonzales::Util qw/flatten/;
use Bio::Gonzales::Feat::IO::GFF3;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(gffiterate);

sub gffiterate {
  my ($src) = @_;

  my ( $fh, $fh_was_open ) = open_on_demand( $src, '<' );

  my $gff = Bio::Gonzales::Feat::IO::GFF3->new($fh);

  return sub {
    my $feat = $gff->next_feat;

    unless ( defined($feat) ) {
      $fh->close unless ($fh_was_open);
      return;
    }
    return $feat;
  };
}

1;
