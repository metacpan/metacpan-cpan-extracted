#!/opt/local/bin/perl
##
## Example hanlder using Apache::Mmap
##
## Copyright (c) 1997
## Mike Fletcher <lemur1@mindspring.com>
## 11/20/97
##
## THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED 
## WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
## OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
##
## See the files 'Copying' or 'Artistic' for conditions of use.
##

##
## $Id: MmapHandler.pm,v 1.3 1997/11/21 15:41:26 fletch Exp $ 
##

## Feel free to change the package name, but make sure you change your
## httpd config correspondingly and it's in the proper location
package MmapHandler;

use strict ();
use vars qw($rcsinfo $VERSION);

## Use neccessary Apache modules
use Apache qw(:DEFAULT);
use Apache::Constants qw(:common);
use Apache::Mmap qw(:DEFAULT);

$rcsinfo = 
  q!$Id: MmapHandler.pm,v 1.3 1997/11/21 15:41:26 fletch Exp $!;
$VERSION = $Apache::Mmap::VERSION;

sub handler {
  my $r = shift;		# Get request object

  $r->request($r);		# Apache magic

  my $filename = $r->filename;	# get translated URI -> filename

  unless( -f $filename ) {
    ## If the file referenced doesn't exist, we can't handle it.
    return NOT_FOUND;
  } else {
    my $ctype = 'application/octet-stream'; # Default file type

    ## Set file type by extension
    $ctype = 'image/gif' if $filename =~ /.gif$/i;
    $ctype = 'image/jpeg' if $filename =~ /.jpe?g$/i;
    $ctype = 'image/png' if $filename =~ /.png$/i;

    ## Set up OK headers and send them
    $r->content_type( $ctype );
    $r->send_http_header;

    ## Send file contents
    $r->print( ${Apache::Mmap::mmap( $r->filename() )} );

    ## Return successfully
    return OK;
  }
}

1;				# Return something true for require

__END__

=head1 NAME

MmapHandler - Example Apache handler using Apache::Mmap

=head1 SYNOPSIS

 <Files ~ "/some/htdocs/dir/images/.*(gif|jpe?g|png)$">
 SetHandler perl-script
 PerlHandler MmapHandler
 </Files>

=head1 DESCRIPTION

This module is an example handler showing how Apache::Mmap can be
used.  Any file requested will be mmap'd into the httpd's memory on
the first request.  Subsequent requests will simply send the version
already in memory.  

If you want to handle file types other than the big three image files,
add lines which set C<$ctype> in the C<handler> sub correctly.

=head1 CONFIGURATION

Place lines similar to those shown above in your Apache config.

=head1 AUTHOR

Mike Fletcher, lemur1@mindspring.com

=head1 SEE ALSO

Apache::Mmap(3), Apache(3), mod_perl(3), mmap(2), perl(1).

=cut
