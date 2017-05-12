package Apache::PassFile;
use Apache::Constants ':common';
use FileHandle;
use strict;
use vars qw($VERSION $BUFFERSIZE);
$BUFFERSIZE = 16384;

$VERSION = "0.05";

sub BUFFERSIZE {
  my($self,$new) = @_;
  $new += 0 if $new;
  $BUFFERSIZE = $new || $BUFFERSIZE || 16384;
}

sub handler {
  my $r = shift;
  my $filename = $r->filename();
  my $fh;

  if (-f $filename and
      -r _ and
      $fh = FileHandle->new($filename)) {
    unless ($r->dir_config('no_mtime')) {
      my $mtime = (stat _)[9];
      require HTTP::Date;
      $r->header_out('Last-Modified',HTTP::Date::time2str($mtime));
    }
    $r->send_http_header;
    my($buf,$read);
    local $\;

    while (){
      defined($read = sysread($fh, $buf, $BUFFERSIZE)) or return SERVER_ERROR;
      last unless $read;
      print $buf;
    }
    $fh->close;
    return OK;
  } else {
    return NOT_FOUND; 
  }
}

1;

__END__

=head1 NAME

Apache::PassFile - print a file to STDOUT

=head1 SYNOPSIS

In the conf/access.conf file of your Apache installation add lines

	<Files *.html>
	SetHandler perl-script
	PerlHandler Apache::OutputChain Apache::GzipChain Apache::PassFile
	</Files>

=head1 DESCRIPTION

This handler implements nothing but a quite efficient cat(1) in perl.
While it innocently prints to STDOUT it may well be the case that
STDOUT has been tied, and that's the only reason why this module is
needed. Once we can stack any apache modules on top of each other,
this module becomes obsolete.

PassFile reads files from disk in chunks of size BUFFERSIZE.
BUFFERSIZE is a global variable that can be set via the BUFFERSIZE
method. The default value is 16384.

=head1 CONFIGURATION

Per default the module sets the C<Last Modified> header. It requires
HTTP::Date in order to do so. You can suppress that by setting

    PerlSetVar no_mtime true

=head1 AUTHOR

(c) 1997 Jan Pazdziora, adelton@fi.muni.cz, at Faculty of Informatics,
Masaryk University, Brno (small performance changes by Andreas Koenig)

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

