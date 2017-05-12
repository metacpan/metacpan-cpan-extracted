
###
# AxKit XSP taglib for HTTP request parameters
# Robin Berjon <robin@knowscape.com>
# 03/05/2001 - v.0.01
###

package AxKit::XSP::AttrParam;
use strict;
use vars qw($VERSION $NS $IN_NAME);
$VERSION = '0.01';

use base qw(Apache::AxKit::Language::XSP);

# define the namespace we use (RDDL there one of these days)
$NS = 'http://xmlns.knowscape.com/xsp/AttrParam';
$IN_NAME = 0;

#---> Parser subs <-------------------------------------------------#

sub parse_start {
    my $e    = shift;
    my $tag  = shift;
    my %attr = @_;

    my $code;
    if ($tag eq 'param') {
        $e->start_expr($tag);
        $code = 'my $name; ';
        if (exists $attr{name}) {
            $attr{name} =~ s/"/\\"/;
            $code .= '$name = "' . $attr{name} . '"; ';
        }
    }
    elsif ($tag eq 'name') {
        $IN_NAME = 1;
        $code = '$name = "" ';
    }
    $e->append_to_script($code);

    return '';
}

sub parse_end {
    my $e    = shift;
    my $tag  = shift;

    if ($tag eq 'param') {
        $e->append_to_script('$cgi->param($name); ');
        $e->end_expr();
    }
    elsif ($tag eq 'name') {
        $e->append_to_script(';');
        $IN_NAME = 0;
    }
    return '';
}

sub parse_char {
    return unless $IN_NAME;
    my $e = shift;
    my $txt = shift;

    $txt =~ s/"/\\"/;
    $e->append_to_script(' . "' . $txt . '"');
    return '';
}
sub parse_comment   {}
sub parse_final     {}

1;

#---> The End <-----------------------------------------------------#

=pod

=head1 NAME

AxKit::XSP::AttrParam - XSP taglib for HTTP request parameters

=head1 SYNOPSIS

Add the aprm: namespace to your XSP C<<xsp:page>> tag:

  <xsp:page
    language='Perl'
    xmlns:xsp='http://apache.org/xsp/core/v1'
    xmlns:aprm='http://xmlns.knowscape.com/xsp/AttrParam'>

And add the taglib to AxKit (via httpd.conf or .htaccess):

  AxAddXSPTaglib AxKit::XSP::AttrParam

=head1 DESCRIPTION

The XSP aprm: tag library implements a simple way to access HTTP
request parameters (query string and posted form data) by field name.
it is shamelessly stolen from Kip Hampton's AxKit::XSP::Param but
allows one to use parameter names that may not be valid XML names, as
well as parametre names derived from expressions.

Thus, the B<value> submitted from this text box

  <input type='text' size='20' name='foo' />

is available after submitting the form either as

  <aprm:param name='foo' />

or as

  <aprm:param>
    <aprm:name>foo</aprm:name>
  </aprm:param>

or yet again (and more usefully)

  <aprm:param>
    <aprm:name><xsp:expr>$perl_that_returns_foo</xsp:expr></aprm:name>
  </aprm:param>

=head2 Tag Reference

There are no named functions for this tag library.

=head1 ACKNOWLEDGEMENTS

Special thanks to Matt and Kip from the entire Knowscape dev team.

=head1 AUTHOR

Robin Berjon,

=head1 COPYRIGHT

Copyright (c) 2001 Robin Berjon. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
