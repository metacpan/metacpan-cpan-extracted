#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Debug;
our $VERSION = '0.98';
use base qw (Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::Debug - Debugging Wyrd

=head1 SYNOPSIS

	<BASENAME::Debug output="/monitor.html" loglevel="4">
	
	..yada yada yada...
	
	</BASENAME::Debug>

=head1 DESCRIPTION

Wyrd for monitoring the debugging process while working with Wyrds.  It is
designed to enclose the entire Wyrd-enabled file.  The debug log will be loaded
on a popup window in the browser (you will need to enable popups).

B<Note:> You will almost certainly want to specify a loglevel higher than the
default of 1/error.

=head2 HTML ATTRIBUTES

=over

=item output

The file (on the web site where the debugging is taking place) which
will be used to monitor the debugging.  The file should be writable by
the server and should be visible to the browser.  It should begin with a
'/' and contain the path from the document root to the file, as if it
was an absolute path to another page on the same site inside the href
attribute of an anchor tag.

=item logfile

The file where the log is temporarily stored while processing.  By
default, this will be a file under /tmp, but if this is not possible,
you should specify it. It must be writable by the server.

=back

=head2 PERL METHODS

NONE

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _setup method.

=cut

sub _setup{
	my ($self) = @_;
	my $templatefile = join('/', $self->dbl->req->document_root, $self->{'output'});
	my $dumpfile = ($self->dbl->globals->{logfile} || '/tmp/' . $self->dbl->req->hostname . '.debuglog');
	$self->_info("using $dumpfile to record debugging.");
	open (OUTLOG, '>',  $dumpfile) || die ("Could not open $dumpfile");
	$self->dbl->set_logfile(*OUTLOG);
	open (TEMPLATE, '>', $templatefile) || die ("Could not open $templatefile");
	my $dumper = '<' . $self->base_class . '::LogDump></' . $self->base_class . '::LogDump>';
	print TEMPLATE <<__FILE__;
<html>
<head><title>Debug Log</title></head>
<body>
<h1>Debug Log:</h1>
<hr>
<code><small>
	$dumper
</small></code>
__FILE__
	close(TEMPLATE);
	my $url = $self->dbl->req->hostname . $self->{output};
	$self->_data(
"<HTML>
<HEAD>
<SCRIPT language=\"Javascript1.1\">
	function logwindow (source) {
		logwindow = window.open('', 'debug_log', 'toolbar=yes,scrollbars=yes,resizable=yes');
		logwindow.close;
		logwindow = window.open('', 'debug_log', 'toolbar=yes,scrollbars=yes,resizable=yes');
		logwindow.location = source;
		logwindow.focus;
	}
</SCRIPT></HEAD>
<BODY onload=\"logwindow('http://$url');\">"
		. $self->_data .
"</body>"
	);
}

=pod

This is a quick-and-dirty Wyrd and really meant only for internal use under
controlled conditions.

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;