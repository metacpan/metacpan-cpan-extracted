package Cikl::Smrt::Fetchers::File;

use strict;
use warnings;
use URI::file;
use Mouse;
use IO::File;
use Cikl::Smrt::Fetcher;
extends 'Cikl::Smrt::Fetcher';

use namespace::autoclean;

use constant SCHEMES => (
      'file', 
      '__undef__'# this tells us that it's a relative path.
    ); 

sub schemes { 
  return SCHEMES;
}

sub fetch {
    my $self = shift;
    my $feedurl = $self->feedurl();

    if (!defined($feedurl->scheme())) {
      # it's going to be a relative URL.
      $feedurl = URI::file->new_abs($feedurl->as_string());
    }

    unless ($feedurl->scheme() eq 'file') {
      die("Unsupported URI scheme: " . $feedurl->scheme);
    }

    my $fh = IO::File->new("< " . $feedurl->path) || die($!.': '.$feedurl->path);
    
    return $fh;
}

__PACKAGE__->meta->make_immutable;

1;
