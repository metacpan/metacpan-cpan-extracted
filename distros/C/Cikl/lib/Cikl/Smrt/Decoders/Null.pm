package Cikl::Smrt::Decoders::Null;

use strict;
use warnings;
use Cikl::Smrt::DecoderRole;
use namespace::autoclean;
use Mouse;
with 'Cikl::Smrt::DecoderRole';
with 'Cikl::Smrt::AutoDecodableRole';
use constant MIME_TYPES => (
  'application/octet-stream'
);
sub mime_types { return MIME_TYPES; }

sub decode {
    my $class = shift;
    my $fh = shift;
    return $fh;
}

__PACKAGE__->meta->make_immutable();

1;


