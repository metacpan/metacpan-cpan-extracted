# $Id: MimeXML.pm,v 1.2 2000/05/10 21:23:41 matt Exp $

package Apache::MimeXML;

use strict;
use Apache::Constants qw(:common);
use Apache::File;

$Apache::MimeXML::VERSION = '0.08';

my $feff = chr(0xFE) . chr(0xFF);
my $fffe = chr(0xFF) . chr(0xFE);

my @ebasci = (
0x00, 0x01, 0x02, 0x03, 0x9C, 0x09, 0x86, 0x7F,
0x97, 0x8D, 0x8E, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
0x10, 0x11, 0x12, 0x13, 0x9D, 0x85, 0x08, 0x87,
0x18, 0x19, 0x92, 0x8F, 0x1C, 0x1D, 0x1E, 0x1F,
0x80, 0x81, 0x82, 0x83, 0x84, 0x0A, 0x17, 0x1B,
0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x05, 0x06, 0x07,
0x90, 0x91, 0x16, 0x93, 0x94, 0x95, 0x96, 0x04,
0x98, 0x99, 0x9A, 0x9B, 0x14, 0x15, 0x9E, 0x1A,
0x20, 0xA0, 0xE2, 0xE4, 0xE0, 0xE1, 0xE3, 0xE5,
0xE7, 0xF1, 0xA2, 0x2E, 0x3C, 0x28, 0x2B, 0x7C,
0x26, 0xE9, 0xEA, 0xEB, 0xE8, 0xED, 0xEE, 0xEF,
0xEC, 0xDF, 0x21, 0x24, 0x2A, 0x29, 0x3B, 0xAC,
0x2D, 0x2F, 0xC2, 0xC4, 0xC0, 0xC1, 0xC3, 0xC5,
0xC7, 0xD1, 0xA6, 0x2C, 0x25, 0x5F, 0x3E, 0x3F,
0xF8, 0xC9, 0xCA, 0xCB, 0xC8, 0xCD, 0xCE, 0xCF,
0xCC, 0x60, 0x3A, 0x23, 0x40, 0x27, 0x3D, 0x22,
0xD8, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
0x68, 0x69, 0xAB, 0xBB, 0xF0, 0xFD, 0xFE, 0xB1,
0xB0, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x70,
0x71, 0x72, 0xAA, 0xBA, 0xE6, 0xB8, 0xC6, 0xA4,
0xB5, 0x7E, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
0x79, 0x7A, 0xA1, 0xBF, 0xD0, 0xDD, 0xDE, 0xAE,
0x5E, 0xA3, 0xA5, 0xB7, 0xA9, 0xA7, 0xB6, 0xBC,
0xBD, 0xBE, 0x5B, 0x5D, 0xAF, 0xA8, 0xB4, 0xD7,
0x7B, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
0x48, 0x49, 0xAD, 0xF4, 0xF6, 0xF2, 0xF3, 0xF5,
0x7D, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50,
0x51, 0x52, 0xB9, 0xFB, 0xFC, 0xF9, 0xFA, 0xFF,
0x5C, 0xF7, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
0x59, 0x5A, 0xB2, 0xD4, 0xD6, 0xD2, 0xD3, 0xD5,
0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
0x38, 0x39, 0xB3, 0xDB, 0xDC, 0xD9, 0xDA, 0x9F);

sub handler {
	my $r = shift;
	
	return DECLINED unless -e $r->finfo;
	return DECLINED if -d $r->finfo;
		
	my $encoding = check_for_xml($r->filename);
	
	if ($encoding) {
		my $type = $r->dir_config('XMLMimeType') || 'application/xml';

		if ($encoding eq 'utf-16-be') {
			$encoding = $r->dir_config('XMLUtf16EncodingBE') || 'utf-16';
			$type =~ s/^text\/xml$/application\/xml/;
		}
		elsif ($encoding eq 'utf-16-le') {
			$encoding = $r->dir_config('XMLUtf16EncodingLE') || 'utf-16-le';
			$type =~ s/^text\/xml$/application\/xml/;
		}
		
		$r->notes('is_xml', 1);
		$r->push_handlers('PerlFixupHandler', 
				sub { 
					my $r = shift;
					$r->content_type("$type; charset=$encoding");
					return OK;
				});
	}

	return DECLINED;
}

sub check_for_xml {
	my $filename = shift;
	
	my $firstline;
	
	if (ref($filename) && UNIVERSAL::isa($filename, 'IO::Handler')) {
		my $fh = $filename;
		binmode $fh;
		sysread($fh, $firstline, 200); # Read 200 bytes. This is a guestimate...
	}
	else {
		eval {
			my $fh = *{$filename}{IO};
			binmode $fh;
			sysread($fh, $firstline, 200); # Read 200 bytes. This is a guestimate...
		};
		if ($@) {
			eval {
				open(FH, $filename) or die "Open failed: $!";
				binmode FH;
				sysread(FH, $firstline, 200); # Read 200 bytes. This is a guestimate...
				close FH;
			};
			if ($@) {
				warn "failed? $@\n";
				return;
			}
		}
	}
	
	if (substr($firstline, 0, 2) eq $feff) {
		# Probably utf-16
		if ($firstline =~ m/^$feff\x00<\x00\?\x00x\x00m\x00l/) {
			return 'utf-16-be';
		}
	}
	elsif (substr($firstline, 0, 2) eq $fffe) {
		# Probably utf-16-little-endian...
		if ($firstline =~ m/^$fffe<\x00\?\x00x\x00m\x00l\x00/) {
			return 'utf-16-le';
		}
	}
	elsif (substr($firstline, 0, 1) eq chr(0x4C)) {
		# Possibly ebdic...
		if ($firstline =~ m/^\x4C\x6F\xA7\x94\x93(.*?)\x6F\x6E/s) {
			my $attribs = $1;
			
			# EBCDIC things we need to know...
			# encoding = 85 95 83 96 84 89 95 87
			# whitespace = [ 40 05 0D 25 ]
			# quote/apos = [ 7F 7D ]
			# '=' = 7E

			my $ws = '\x40\x05\x0d\x25';

			if ($attribs =~ m/\x85\x95\x83\x96\x84\x89\x95\x87[$ws]*\x7e[$ws]*(\x7f|\x7d)(.*?)\1/s) {
				my $encoding = $2;
				$encoding =~ s/(.)/chr($ebasci[ord($1)])/eg;
				return $encoding;
			}
		}
	}
	else {
		if ($firstline =~ m/^<\?xml(.*?)\?>/s) {
			my $attribs = $1;
			if ($attribs =~ m/encoding[\s]*=[\s]*(["'])(.*?)\1/s) {
				return $2;
			}
			else {
				# Assume utf-8
				return 'utf-8';
			}
		}
	}

	return;
}

1;
__END__

=head1 NAME

Apache::MimeXML - mod_perl mime encoding sniffer for XML files

=head1 SYNOPSIS

Simply add this line to srm.conf or httpd.conf:

  PerlTypeHandler +Apache::MimeXML

Alternatively add it only for certain files or directories using
the standard Apache methods. There is about a 30% slowdown for
files using this module, so you probably want to restrict
it to certain XML locations only.

=head1 DESCRIPTION

An XML Content-Type sniffer. This module reads the encoding
attribute in the xml declaration and returns an appropriate
content-type heading. If no encoding declaration is found it
returns utf-8 or utf-16 depending on the specific encoding.

=head1 CONFIGURATION

There are a few small configuration options for this module,
allowing you to set various parameters.

=head2 XMLMimeType

Allows you to set the mime type for XML files:

	PerlSetVar XMLMimeType application/xml

That changes the mime type from the default text/xml to
application/xml. You can use this on a per-directory basis.

=head2 XMLUtf16EncodingBE

Allows you to set the encoding of big-endian (read: normal) 
utf 16 (unicode) documents. The default is 'utf-16'

	PerlSetVar XMLUtf16EncodingBE utf-16-be

=head2 XMLUtf16EncodingLE

Allows you to set the encoding of little-endian utf-16
encoded documents. The default is 'utf-16-le'

	PerlSetVar XMLUtf16EncodingLE utf-16-wierd

=head1 Use From Other Modules

If you want to use Apache::MimeXML's detection routines from
other modules, you can manually call the check_for_xml()
function yourself, passing in either a filename, or an open
filehandle. The function returns the encoding
if it finds that the file contains XML, otherwise it returns
nothing:

	my $encoding;
	if ($encoding = Apache::MimeXML::check_for_xml($filename)) {
		print "$filename is XML in $encoding encoding\n";
	}

=head1 AUTHOR

Matt Sergeant matt@sergeant.org

=head1 LICENCE

This module is distributed under the same terms as perl itself

=cut
