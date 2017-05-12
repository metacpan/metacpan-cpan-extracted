
###
# AxKit XSP taglib for character conversion
# Robin Berjon <robin@knowscape.com>
# 03/08/2001 - v0.02
# 18/07/2001 - v0.01
###

package AxKit::XSP::CharsetConv;
use strict;
use Apache::AxKit::CharsetConv  qw();

use vars qw($VERSION $NS);
$VERSION = '0.02';

use base qw(Apache::AxKit::Language::XSP);

# define the namespace we use (RDDL there one of these days)
$NS = 'http://xmlns.knowscape.com/xsp/CharsetConv';


#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Parser subs `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

sub parse_start {
    my $e    = shift;
    my $tag  = shift;
    my %attr = @_;

    if ($tag eq 'charset-convert') {
        $attr{from} ||= 'iso-8859-1';
        $attr{to}   ||= 'utf-8';
        $e->append_to_script("{ #start charset-convert\n");
        $e->append_to_script("  my \$charconv = Apache::AxKit::CharsetConv->new('$attr{from}','$attr{to}');\n");
        $e->append_to_script("  my \$to_convert = ''");
    }
    else {
        die "Unknown tag $tag in CharsetConv taglib";
    }

    return '';
}

sub parse_end {
    my $e    = shift;
    my $tag  = shift;

    if ($tag eq 'charset-convert') {
        $e->append_to_script(";\n");
        $e->start_expr;
        $e->append_to_script("  \$charconv->convert(\$to_convert);");
        $e->end_expr;
        $e->append_to_script("} # end of charset-convs\n");
    }

    return '';
}

sub parse_char {
    my $e = shift;
    my $txt = shift;

    $txt =~ s/\|/\\\|/;
    $e->append_to_script(" . q|$txt|");

    return '';
}

sub parse_comment   {}
sub parse_final     {}


1;

#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Documentation `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

=pod

=head1 NAME

AxKit::XSP::CharsetConv - AxKit XSP taglib for charset conversion

=head1 SYNOPSIS

Add the CharsetConv namespace to your XSP C<<xsp:page>> tag:

  <xsp:page
    language='Perl'
    xmlns:xsp='http://apache.org/xsp/core/v1'
    xmlns:conv='http://xmlns.knowscape.com/xsp/CharsetConv'>

And add the taglib to AxKit (via httpd.conf or .htaccess):

  AxAddXSPTaglib AxKit::XSP::CharsetConv

=head1 DESCRIPTION

The XSP CharsetConv taglib implements character set conversion as
implemented in iconv(), through the Apache::AxKit::CharsetConv module
that comes with your standard AxKit install. You may wish to use it
to convert data from misc. sources (databases, files, browser posts,
the environment, etc...) that are not UTF-8 yet need to be included in
the output of your XSP.

=head2 Tag Reference

There is only one tag provided by this taglib: charset-convert. It
has two mandatory attributes, from and to, which are the character
codes to convert (surprise) from and to.

The to attribute defaults to UTF-8, which usually makes sense. The from
attribute on the other hand defaults to ISO-8859-1. While this default
is very eurocentric, it would have been an arbitrary choice no matter
what my choice would have been... so I picked the one that's most
useful to me :-)

=head1 AUTHOR

Robin Berjon, robin@knowscape.com

=head1 COPYRIGHT

Copyright (c) 2001 Robin Berjon. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
