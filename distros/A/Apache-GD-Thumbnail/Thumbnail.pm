package Apache::GD::Thumbnail;

use strict;
use warnings;
use vars qw($VERSION @ISA);
use GD;
use Image::GD::Thumbnail;
use Apache::File;
use Apache::Constants qw(OK NOT_FOUND);

BEGIN {
    $VERSION = "0.03";
    $Apache::GD::Thumbnail::DEBUG=0;
}

### ChangeLog
#
# 0.01 - Jan 21, 2002 - Started
# 0.02 - Jan 22, 2002 - Removed some debug code that shouldn't have been there

sub handler
{
    my $r=shift;
    # Read config
    my $uri=$r->path_info;
    my $base=$r->dir_config("ThumbnailBaseDir") || "0";
    if ($base eq "0") {
	my $subr=$r->lookup_uri($r->uri."/../../");
	$base=$subr->filename;
    }
    $base=~s/\/$//;
    my $loc=$base.$uri;    
    my $MaxSize=$r->dir_config("ThumbnailMaxSize") || 50;
    # Verify file
    if (!(-e $loc)) {
	return NOT_FOUND;
    }
    # Prepare response
    $r->set_last_modified((stat $loc)[9]);
    $r->content_type('image/jpeg');
    if ((my $rc=$r->meets_conditions) != OK) {
	return $rc;
    }
    $r->send_http_header;
    if ($r->header_only)
    {
	return OK;
    }
    # Read JPEG
    my $fh=Apache::File->new($loc) || die ("Couldn't open $loc for reading: $!");
    my $src=undef;
    $src=GD::Image->newFromJpeg(*{$fh});
    $fh->close || die "Error closing $loc: $!";
    warn $loc if _conf("DEBUG") > 0;
    #Create thumbnail
    my ($thumb,$x,$y)=Image::GD::Thumbnail::create($src,$MaxSize);
    $r->print($thumb->jpeg);
    return OK;
}

sub _conf($)
{
    my $arg=shift;
    return eval("\$".__PACKAGE__."::".$arg);
}


1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Apache::GD::Thumbnail - Apache module which generates on-the-fly thumbnails using GD and libjpeg

=head1 SYNOPSIS

  <Location /pics/thumbnails>
  SetHandler perl-handler
  PerlHandler Apache::GD::Thumbnail
  PerlSetVar ThumbnailMaxSize 75
  PerlSetVar ThumbnailBaseDir "/usr/local/httpd/htdocs/pics"
  </Location>

=head1 DESCRIPTION

Just what it looks like: creates on-the-fly thumbnails of jpeg images.  There are two optional configuration directives.

=over

=item *
ThumbnailMaxSize 

Sets the maximum number of pixels to be used in the thumbnail for length or width (whichever is larger).  Defaults to 50 if not specified.

=item *
ThumbnailBaseDir

Sets the directory that contains the images to be thumbnailed.  Defaults to ".." if not specified.

=back

=head1 EXAMPLES

  <Location /pics/thumbnails>
  SetHandler perl-handler
  PerlHandler Apache::GD::Thumbnail
  PerlSetVar ThumbnailMaxSize 75
  PerlSetVar ThumbnailBaseDir "/usr/local/httpd/htdocs/pics"
  </Location>

In the above example, the URI /pics/thumbnails/img001.jpg will cause the module to generate a 75xnn (where nn < 75) thumbnail of /usr/local/httpd/htdocs/pics/img001.jpg

  <Location /pics/*/thumbs>
  SetHandler perl-handler
  PerlHandler Apache::GD::Thumbnail
  </Location>

In the above example, the URI /pics/foo/img001.jpg will cause the module to generate a 50xnn (nn < 50) thumbnail of DIRECTORYROOT/pics/somedirectory/img001.jpg  As you can tell, this allows for much more dynamic configuration.


=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2002 Issac Goldstand - All rights reserved.

This library is free software.  It can be redistributed and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

GD(3)

=cut
