#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Comics::Fetcher::Base;

=head1 NAME

Comics::Fetcher::Base -- Base class for Fetchers.

=head1 SYNOPSIS

  package Comics::Fetcher::Direct;
  use parent qw(Comics::Fetcher::Base);

=head1 DESCRIPTION

The Fetcher Base class provides tools for fetching URLs and saving
data to disk.

The primary entry point for a Fetcher is method C<fetch>, which must
be implemented by the derived classes.

=cut

use parent qw(Comics::Plugin::Base);

our $VERSION = "1.00";

sub fetch {
    my ( $self ) = @_;
    die( ref($self), ": Method 'fetch' not defined\n" );
}

################ Subroutines ################

use File::Spec;

=head1 METHODS

=head2 spoolfile($file)

Returns the full name for the given i<file> in the configured spool
directory.

=cut

sub spoolfile {
    my ( $self, $file ) = @_;
    ::spoolfile($file);
}

use Digest::MD5 qw(md5_base64);

use Image::Info qw(image_info);

=head2 urlabs($url, $path)

Returns the full URL for the given i<path>, possibly relative to I<url>.

=cut

sub urlabs {
    my ( $self, $url, $path ) = @_;
    if ( $path =~ m;^/; ) {
	if ( $path =~ m;^//; ) {
	    $path = "http:" . $path;
	}
	else {
	    $url =~ s;(^\w+://.*?)/.*;$1;;
	    $path = $url . $path;
	}
    }
    elsif ( $path !~ m;^\w+://; ) {
	$path = $url . "/" . $path;
    }

    return $path;
}

=head2 save_image($image, $dataref)

Saves the contents of I<dataref> to the spooldir, using I<image> as
the name for the file.

See also: B<spoolfile>.

=cut

sub save_image {
    my ( $self, $image, $data ) = @_;
    my $f = $self->spoolfile($image);
    open( my $fd, ">:raw", $f );
    print $fd $$data;
    close($fd) or warn("$f: $!\n");
    ::debug("Wrote: $f");
}

=head2 save_html($html)

Generates and saves the HTML fragment for this comic to the spooldir,
using I<html> as the name for the file.

See also: B<spoolfile>.

=cut

sub save_html {
    my ( $self, $html, $data ) = @_;
    my $f = $self->spoolfile($html);
    open( my $fd, ">:utf8", $f );
    print $fd ( $data // $self->html );
    close($fd) or warn("$f: $!\n");
    ::debug("Wrote: $f");
}

1;
