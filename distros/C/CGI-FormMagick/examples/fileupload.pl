#!/usr/bin/perl -w

# Copyright (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

use strict;
use lib "../lib/";
use CGI::FormMagick;
use Carp;

#
# Example of a file upload form. Note that you *must* include the
# <ENCTYPE>multipart/form-data</ENCTYPE> field in order to use 
# fields of type FILE. 
#

#
# suck in the XML from down below __DATA__
#

undef $/;
my $data = <DATA>;

my $fm = new CGI::FormMagick(
        TYPE => "STRING",
	SOURCE => "$data",
);

$fm->display();
exit 0;

sub dump_file
{
	print "This is the dump_file routine.\n\n";
	my $file = CGI::param('filename');
	my $buf;
	read($file, $buf, 1024);
	print "The first 1024 bytes are:\n<pre>",$buf,"\n</pre>\n";
}

__END__
<FORM HEADER="" FOOTER="">
    <TITLE>File upload test</TITLE>

    <PAGE NAME="Upload" POST-EVENT="dump_file">
        <TITLE>Upload a file to the server</TITLE>
  
        <FIELD ID="filename" TYPE="FILE" VALIDATION="nonblank">
            <LABEL>Choose a file to send</LABEL>
        </FIELD>
    </PAGE>
</FORM>

