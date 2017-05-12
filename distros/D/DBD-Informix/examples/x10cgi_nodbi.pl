#!/usr/bin/perl -w
#
# @(#)$Id: x10cgi_nodbi.pl,v 100.1 2002/02/08 22:50:13 jleffler Exp $
#
# Simple example of self-populating (self-regenerating) CGI Form
# Cribbed from CGI.pm documentation.
#
# Copyright 1998 Jonathan Leffler
# Copyright 2000 Informix Software Inc
# Copyright 2002 IBM

use strict;
use CGI qw/:standard/;

my $clear = (param('reset')) ? 1 : 0;
my @rainbow = ('red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'violet');
Delete_all if $clear;

print header,
		start_html('A Simple Example'),
		h1('A Simple Example'),
		start_form,
		"What's your name? ",
		textfield(-name=>'name', -default=>'', -override=>$clear), p,
		"What's the combination?", p,
		checkbox_group(	-name=>'words', -override=>$clear,
						-value=>['eenie', 'meenie', 'minie', 'moe'],
						-default=>['eenie', 'meenie']), p,
		"What's your favourite colour? ",
		popup_menu( -name=>'colour', -override=>$clear,
					-value=>[@rainbow]), p,
		submit, submit(-name=>'reset', -value=>'Clear Form'),
		end_form,
		hr;

if (param('name'))
{
	print "Your name is ", em(param('name')), p,
			"You think the keywords are: ", em(join(", ", param('words'))), p,
			"Your favourite colour is ", em(param('colour')),
			hr;
}

