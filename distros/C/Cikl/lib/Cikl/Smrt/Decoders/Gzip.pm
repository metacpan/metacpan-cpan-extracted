package Cikl::Smrt::Decoders::Gzip;

use strict;
use warnings;
use Cikl::Smrt::DecoderRole;
use Cikl::Smrt::AutoDecodableRole;
use namespace::autoclean;
use Mouse;
with 'Cikl::Smrt::DecoderRole';
with 'Cikl::Smrt::AutoDecodableRole';

use IO::Uncompress::Gunzip qw/gunzip $GunzipError/;

use constant MIME_TYPES => (
  'application/x-gzip'
);
sub mime_types { return MIME_TYPES; }

sub decode {
    my $class = shift;
    my $fh = shift;
    my $gzfh = IO::Uncompress::Gunzip->new($fh, AutoClose => 1) or die($!);
    return $gzfh;
}

__PACKAGE__->meta->make_immutable();

1;

