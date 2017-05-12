
=head1 NAME

Apache::PassHtml - print out the html file

=cut

package Apache::PassHtml;
use strict;
use Apache::Constants ':common';
sub handler
	{
	my $r = shift;
	my $filename = $r->filename();
	return DECLINED unless $filename =~ /\.html$/;

	if (-f $filename and -r $filename and open FILE, $filename)
		{
		$r->status(200);
		$r->send_http_header;
		local ($_);
		while (<FILE>)
			{ print $_; }
		close FILE;
		return OK;
		}
	return DECLINED;
	}
1;

=head1 SYNOPSIS

In the conf/access.conf file of your Apache installation add lines

	<Files *.html>
	SetHandler perl-script
	PerlHandler Apache::OutputChain Apache::MakeCapital Apache::PassHtml
	</Files>

=head1 DESCRIPTION

This is simple script to show the use of module B<Apache::OutputChain>.
It will pick up a html file and send it to the output, STDOUT. We
assume that the output is tied either to Apache (by default), or some
user-defined perl handler. We need to read and write to STDOUT in perl
since Apache will not pass its output into perl handlers.

=head1 AUTHOR

(c) 1997--1998 Jan Pazdziora

=cut

