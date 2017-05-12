
###
# AxKit XSP taglib for MD5 digests
# Robin Berjon <robin@knowscape.com>
# 25/06/2001 - v.0.01
###

package AxKit::XSP::MD5;
use strict;
use Digest::MD5 qw();

use vars qw($VERSION $NS);
$VERSION = '0.01';

use base qw(Apache::AxKit::Language::XSP);

# define the namespace we use (RDDL there one of these days)
$NS = 'http://xmlns.knowscape.com/xsp/MD5';



#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Parser subs `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

sub parse_start {
    my $e    = shift;
    my $tag  = shift;
    my %attr = @_;

    my $code;
    if ($tag eq 'md5' or $tag eq 'md5-hex' or $tag eq 'md5-base64') {
        $code = "{ #start md5\n my \$axmd5_text = ''";
    }
    else {
        die "Unknown tag $tag in MD5 taglib";
    }
    return $code;
}

sub parse_end {
    my $e    = shift;
    my $tag  = shift;

    if ($tag eq 'md5' or $tag eq 'md5-hex' or $tag eq 'md5-base64') {
        $e->append_to_script(";\n");
        $e->start_expr;
        $tag =~ s/-/_/g;
        $e->append_to_script("    Digest::MD5::$tag(\$axmd5_text)");
        $e->end_expr;
        $e->append_to_script("} # end of md5\n");
    }
    return '';
}

sub parse_char {
    my $e = shift;
    my $txt = shift;

    $txt =~ s/\|/\\\|/;
    my $code = " . q|$txt|";
    return $code;
}

sub parse_comment   {}
sub parse_final     {}


1;

#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Documentation `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

=pod

=head1 NAME

AxKit::XSP::MD5 - AxKit XSP taglib for MD5 digests

=head1 SYNOPSIS

Add the md5 namespace to your XSP C<<xsp:page>> tag:

  <xsp:page
    language='Perl'
    xmlns:xsp='http://apache.org/xsp/core/v1'
    xmlns:md5='http://xmlns.knowscape.com/xsp/MD5'>

And add the taglib to AxKit (via httpd.conf or .htaccess):

  AxAddXSPTaglib AxKit::XSP::MD5

=head1 DESCRIPTION

The XSP MD5 taglib implements MD5 digests (as provided by the
Digest::MD5 module). You may use it to generate keys for cookies or
checksums for files (if there is demand for this, I'll implement
MD5'ing an external file).

=head2 Tag Reference

There are three tags provided by this taglib, which map to
Digest::MD5's three functions: md5:md5, md5:md5-hex, md5:md5-base64.
Please refer to Digest::MD5's documentation for these. The data is
quite simply the content of the tags.

=head1 AUTHOR

Robin Berjon, robin@knowscape.com

=head1 COPYRIGHT

Copyright (c) 2001 Robin Berjon. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
