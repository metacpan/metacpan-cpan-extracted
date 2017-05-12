package Apache::File::Resumable;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Apache::File::Resumable ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = sprintf '%s', 'q$Revision: 1.1.1.1 $' =~ /\S+\s+(\S+)\s+/ ;


# Preloaded methods go here.


use strict ;

use Apache::Constants ;

#
# Format time as necessary by http headers
# Taken from CGI.pm
#

sub formattime

    {
    my $time = shift ;
    my(@MON)=qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    my(@WDAY) = qw/Sun Mon Tue Wed Thu Fri Sat/;

    # make HTTP/cookie date string from GMT'ed time
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($time);
    $year += 1900;
    return sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
                   $WDAY[$wday],$mday,$MON[$mon],$year,$hour,$min,$sec);
    }

#
# Actual Download
#

sub download {
    my ($self, $file, $req) = @_;

    open T, "/tmp/headers_in";
    print T $req->headers_in;
    close(T);

    ### Create an ETag
    ###  The ETag is required, otherwise IE won't resume a download
    ###  The ETag can have any value, but it must be garanteed that is
    ### unique
    ###  for every file and it changes whenever the file changes
    ###  The idea below is copied form Apache ap_make_etag (http_protocol.c)

#    /*
#     * Make an ETag header out of various pieces of information. We use
#     * the last-modified date and, if we have a real file, the
#     * length and inode number - note that this doesn't have to match
#     * the content-length (i.e. includes), it just has to be unique
#     * for the file.
#     *
#     * If the request was made within a second of the last-modified date,
#     * we send a weak tag instead of a strong one, since it could
#     * be modified again later in the second, and the validation
#     * would be incorrect.
#     */

    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime)
= stat ($file) ;

    my $weak = ($req->request_time - $mtime > 1)? "" : "W/";
    my $etag ;
    if ($mode != 0)
        {
        $etag = sprintf ('%s"%x-%x-%x"', $weak, $ino, $size, $mtime) ;
        }
    else
        {
        $etag = sprintf ('%s"%x"', $weak, $mtime) ;
        }

    ### Set ETag header, without ETag resuming download doesn't work at all
    $req->header_out('ETag', $etag) ;

    ### Check is there is an incoming if-none-match header
    my $if_none_match = $req->header_in('If-None-Match') ;

    if ($if_none_match eq $etag)
        {
        ### send not_modified headers in case file doesn't have changed
        ### and return
        $req->status (304) ;
        $req->send_http_header ;
        return OK ;
        }

    open PATCH, "$file" or die "$file: $!";

    ### Check is there is an incoming range and if-range header
    my $range = $req->header_in('Range') ;
    my $if_range = $req->header_in('If-Range') ;

    ### If there is a correct range header and the if-range header matches
    ### the etag
    ### i.e. the file doesn't have changed, add the correct headers for
    ### resuming the
    ### download and advance the file pointer to the correct possition
    if (($range =~ /bytes=(\d+)-/) && $if_range eq $etag)
        { # continue download
        my $start = $1 ;
        my $end   = $size - 1 ;
        $req->status (206) ;
        $req->header_out('Content-Range', "bytes $start-$end/$size" ) ;

        $size -= $start ;

        seek PATCH, $start, 0 ;
        }

    ### To make resuming a download work, we need _all_ of the follwing
    ### headers!
    $req->header_out('Accept-Ranges', 'bytes');
    $req->header_out('Last-Modified', formattime ($mtime)) ;
    $req->header_out('Content-Length', $size) ;

    ### Setup the content-type
    if ($file =~ /\.zip$/i) {
      $req->content_type('application/zip');
    }
    elsif ($file =~ /\.Z$/i) {
        $req->content_type('Content-type: application/compress');
    }
    else {
        $req->content_type('application/octet-stream');
    }

    ### Send the headers
    $req->send_http_header ;

    ### ... and now send the content
    no strict 'subs';
    $req->send_fd(PATCH);
    close PATCH;

    return OK ;

}

sub doit {
    my $r = shift ;

download ({}, '/home/httpd/html/old.zip', $r) ;
#download ({}, '/home/httpd/html/c.zip', $r) ;
}

#doit;

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Apache::File::Resumable - example of how to serve resumable files under modperl

=head1 SYNOPSIS

This code can be adapted to serve resumable downloads under mod_perl.

As it is setup now, you could put this file in some directory under your
document root with a name like /home/httpd/htdocs/bigfile.afr (that's
right, name an executable Perl file with this extension), then setup
Apache to run files with that extension as a script:

 <Files *.afr>
    however that is done
 </Files>

Then uncomment the line
 
 #doit 

in the same file and it will serve the zip file indicated in the
subroutine download(), in a resumeable fashion.

I'm sorry for not giving you a complete handholding on this, but I
feel that this code is close enough to be of great service to some
that I think that you should just go the extra few more yards to the
goal-line to finish it off. And email me the fixes to the docs when
you do.

I have used this code to get resumable downloads working, I just
forgot
the Apache settings to do it.

=head1 DESCRIPTION


=head2 EXPORT

None by default.


=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>


=cut
