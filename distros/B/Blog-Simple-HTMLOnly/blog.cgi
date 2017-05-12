#!/usr/bin/perl

=head1 NAME

blog.cgi - simple blog example

=head1 USE

	blog.cgi        			- display the current blog
	blog.cgi?x      			- where 'x' is anything: add a blog
	blog.cgi?all=1&author=y     - display all the blogs of author 'y'
	blog.cgi?date=x&author=y	- where 'x' and 'y' are a timestamp
								  and an author name: shows that blog
	 ...&template=false         - do not use the template

If the template is used, it should be HTML with a comment <!-- insert ---> where
the calendar is to go.

Copyright (C) 2003, Lee Goddard (lgoddard -at- cpan -dot- org)
All Rights Reserved. Available under the same terms as Perl.

=cut

my $VERSION = 0.3;

use CGI::Carp qw(fatalsToBrowser);
use strict;
use Blog::Simple::HTMLOnly;
use HTML::Calendar::Simple;
use CGI 2.47 qw/:standard/;
use Cwd;

my $PASSWORD 		= 'password!';
my $TEMPLATE_PATH	= $^O =~ /win/i? 'D:/www/leegoddard_net/blank.html' : "/home/leeg1644/public_html/blank.html";
my $BLOG_DIR		= $^O =~ /win/i? 'D:/www/leegoddard_net/.blog/' : "/home/leeg1644/private_data/Lee_Blog";
my $CGI 	= CGI->new;
my $TITLE   = 'Moaning&nbsp;and Groaing at the Edge of ...';
my $FORMAT = {
	simple_blog_wrap => '<div class="blogs">',
	simple_blog => '<div class="blog">',
	title       => '<h3>',
	author      => '<span style="display:none">',
	email       => '<span style="display:none">',
	ts          => '<div class="ts">',
	summary     => '<div class="summary">',
	content     => '<div class="content">',
};

my ($TEMPLATE_TOP, $TEMPLATE_BOTTOM);
my $BLOGGER = Blog::Simple::HTMLOnly->new($BLOG_DIR);

$CGI->param('author' => 'Lee');

if (!-e $BLOGGER->{blog_idx}){
	$BLOGGER->create_index();
	$BLOGGER->add(
		"Blogging...",
		$CGI->param('author'),
		'code@leegoddard.com',
		'Started to blog',
		"<p>This is the first blog using <code>Blog::Simple</code> from CPAN.</p>"
	);
}

if ($CGI->param('template') and $CGI->param('template') eq 'false'){
	print $CGI->header;
	$ENV{QUERY_STRING} =~ s/template=false;?//g;
} else {
	&print_header
}

if ($ENV{QUERY_STRING}){
	my $n;
	if ($CGI->param('all') or $ENV{QUERY_STRING} eq 'all'){
		$BLOGGER->render_all($FORMAT);
	}

	# Latest
	elsif ($n = $CGI->param('latest') or $n = $ENV{QUERY_STRING} =~ /latest=(\d+)/g){
		$BLOGGER->render_current_by_author($FORMAT, $n, $CGI->param('author'));
	}

	# Blog by date and author
	elsif ($CGI->param('date') and $CGI->param('author')){
		$BLOGGER->render_this_blog($CGI->param('date'), $CGI->param("author"), $FORMAT)
	}

	# Write a blog
	elsif ($CGI->param('title') and $CGI->param('title') ne ''
		and $CGI->param('author') and $CGI->param('author') ne ''
		and $CGI->param('email') and $CGI->param('email') ne ''
		and $CGI->param('summary') and $CGI->param('summary') ne ''
		and $CGI->param('content') and $CGI->param('content') ne ''
	){
		if (not $CGI->param('password') or $CGI->param('password') ne $PASSWORD){
			&form('You either supplied the wrong password or none at all.');
		} else {
			my $content = &format_text($CGI->param('content')) ;
			$BLOGGER->add(
				$CGI->param('title'),
				$CGI->param('author'),
				$CGI->param('email'),
				$CGI->param('summary'),
				$content
			);
			print h2("Blogged!");
			$BLOGGER->render_current($FORMAT,1);
			print p("<a href='$ENV{SCRIPT_NAME}?all'>SHOW ALL BLOGS</a>");
		}
	} else {
		my $err = join", ", (grep { $CGI->param($_) eq '' } $CGI->param);
		if ($err){
			$err = "Your forgot to do the <i>$err</i>.";
		}
		&form($err);
	}
} else {
	$BLOGGER->render_current($FORMAT,1);
}

&print_footer unless $CGI->param('template') and $CGI->param('template') eq 'false';
exit;

sub print_header {
	local (*IN,$_);
	open IN,$TEMPLATE_PATH or die "Could not open $TEMPLATE_PATH from dir ".cwd;
	read IN,$_,-s IN;
	close IN;
	($TEMPLATE_TOP,$TEMPLATE_BOTTOM) = /^(.*)<!--\sinsert.*?-->(.*)$/sig;
	$TEMPLATE_TOP =~ s/<\s*title\s*>.*?<\/\s*title\s*>/<title>$TITLE<\/title>/si;
	print $CGI->header, $TEMPLATE_TOP;
}

sub print_footer { print $TEMPLATE_BOTTOM }

sub form { my $err=shift;
	print
		h1("Add a Blog"),
		($err? h3($err):""),
		start_form,
		"<table align='center' cellpadding='1' cellspacing='1' border='0'>\n",
		"<tr>",
		"<td>Title:</small></td><td>",
		textfield(
			-name=>'title',
			-size=>65,
			-maxlength=>65
		),
		"</td></tr><tr><td>Summary: </td><td>",
		textfield(
			-name=>'summary',
			-default=>'',
			-size=>65,
			-maxlength=>65
		),
		"</td></tr><tr><td>Content:</small></td><td>",
		"<textarea name='content' rows='15' cols='50' wrap='soft'>",
		$CGI->param("content")?$CGI->param("content"):"",
		"</textarea>",
		"</td></tr><tr><td>",
		"Author: </td><td>",$CGI->popup_menu(
			-name=>'author',
			-values=>[qw/Lee/],
			-default=>'Lee'
		),
		"</td></tr><tr><td>",
		"E-mail: </td><td>", textfield(
			-name=>'email',
			-default=>'blog@leegoddard.com',
			-size=>65,
			-maxlength=>65
		),
		"</td></tr><tr><td>",
		"Password: </td><td>",
		password_field(
			-name=>'password',
			-default=>'',
			-override=>1,
			-size=>65,
			-maxlength=>65
		),
		"</td></tr><tr><td colspan='2'><hr size='1'/>",
		"</td></tr><tr><td>&nbsp;</td><td>",
		submit,
		"</td></tr></table>",
		end_form;
}



sub format_text {
	@_ = map {"<p>$_</p>"} split (/[\n\r\f]+/,shift) ;
	return join ("",@_);
}







=head1 HTML TEMPLATE

The template isn't used by this script; instead SSI is used to pull this script's output
into an SHTML page. Note the C<template=false> in the query string.

	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
	<html>
	<head>
		<title>Blah Blah Blah</title>
	</head>
	<body>

	<!--#include virtual="/cgi-bin/blog.cgi?template=false" -->

	<!--#include virtual="/cgi-bin/blogcal.cgi?template=false" -->

	</body>
	</html>

