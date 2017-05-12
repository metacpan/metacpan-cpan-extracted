package Cikl::Smrt::Decoders::Zip;

use strict;
use warnings;
use Cikl::Smrt::DecoderRole;
use Cikl::Smrt::AutoDecodableRole;
use IO::Uncompress::Unzip qw(unzip $UnzipError);
use Mouse;
use namespace::autoclean;
use Cikl::Logging;
with 'Cikl::Smrt::DecoderRole';
with 'Cikl::Smrt::AutoDecodableRole';

my $logger = get_logger();

has 'zip_filename' => (
  is => 'ro',
  isa => 'Maybe[Str]',
  required => 0
);

use constant MIME_TYPES => (
  'application/x-zip',
  'application/zip'
);
sub mime_types { return MIME_TYPES; }

sub decode {
    my $self = shift;
    my $fh = shift;

    my $file = $self->zip_filename;
    if(!defined($file)){
      $logger->warn("No zip_filename provided. We'll be extracting the FIRST file that appears within the zip, whatever that may be!");
    }

    my $foundit = 0;
    my $zipfh = IO::Uncompress::Unzip->new($fh, AutoClose => 1) or die($!);
    my $status;
    for ($status = 1; $status > 0; $status = $zipfh->nextStream()) {
      if (defined($file)) {
        if ($zipfh->getHeaderInfo()->{Name} eq $file) {
          # Found the file.
          $foundit = 1;
          last;
        }
      } else {
        $foundit = 1;
        last;
      }
    }

    if (!$foundit) {
      die("Failed to find file named $file");
    }
    return $zipfh;
}

__PACKAGE__->meta->make_immutable();

1;
