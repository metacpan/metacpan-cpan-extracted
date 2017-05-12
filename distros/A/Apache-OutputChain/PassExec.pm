package Apache::PassExec;
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
      -x _ and
      $fh = FileHandle->new("$filename |")) {
      print STDERR "$filename |\n";
    my $headers;
    { local $/ = "\n\n";
    $headers = <$fh>; $r->send_cgi_header($headers); }

    my $buf;
    local $\;

    while (defined($buf = <$fh>)){
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

Apache::PassExec - run CGI and catch its output

=head1 SYNOPSIS

In the conf/access.conf file of your Apache installation add lines

	<Files *.html>
	SetHandler perl-script
	PerlHandler Apache::OutputChain Apache::GzipChain Apache::PassExec
	</Files>

=head1 DESCRIPTION

Runs a script (process) and fetches its output, passes it to next
chained handlers.

=head1 AUTHOR

(c) 1997--1998 Andreas Koenig, Jan Pazdziora

=cut

