#! /usr/bin/perl

#
# Use:
#	blogcal.cgi?author=x	- print blog calendar for author x
#
# Copyright (C) 2003, Lee Goddard (lgoddard -at- cpan -dot- org)
# All Rights Reserved. Available under the same terms as Perl.
#

my $VERSION = 0.2;

use strict;
use CGI::Carp qw(fatalsToBrowser);
use Blog::Simple::HTMLOnly;
use HTML::Calendar::Simple;
use CGI 2.47 qw/:standard/;
use Cwd;



my $cgi 	= CGI->new;
my $PASSWORD = 'password!';
my $win = $^O =~ /win/i;
my $TEMPLATE_PATH = $win? 'D:/www/leegoddard_net/blank.html' : "/home/leeg1644/public_html/blank.html";
my $BLOG_DIR = {
	Polar 	=> $win? 'D:/www/paulacska_com/.blog/' : '/home/leeg1644/private_data/Polar_Blog',
	Lee		=> $win? 'D:/www/leegoddard_net/.blog/' : "/home/leeg1644/private_data/Lee_Blog",
};
my ($TEMPLATE_TOP, $TEMPLATE_BOTTOM, $FORMAT, $TITLE, $blogger);

if ($cgi->param('author') and $cgi->param('author') eq 'Polar'){
	$blogger = new Blog::Simple::HTMLOnly($BLOG_DIR->{$cgi->param('author')});
	$TITLE = "Weblog";
} else {
	my $a = $cgi->param('author') || 'Lee';
	$blogger = new Blog::Simple::HTMLOnly($BLOG_DIR->{$a});
	$TITLE = 'Moaning&nbsp;and Groaing at the Edge of ...';
}

if ($cgi->param('template') and $cgi->param('template') eq 'false'){
	print $cgi->header;
	$ENV{QUERY_STRING} = "";
} else {
	&print_header
}

&print_calendar;

&print_footer unless $cgi->param('template') and $cgi->param('template') eq 'false';

exit;



sub print_header {
	local (*IN,$_);
	open IN,$TEMPLATE_PATH or die "Could not open $TEMPLATE_PATH from ".cwd;
	read IN,$_,-s IN;
	close IN;
	($TEMPLATE_TOP,$TEMPLATE_BOTTOM) = /^(.*)<!--\sinsert.*?-->(.*)$/sig;
	$TEMPLATE_TOP =~ s/<\s*title\s*>.*?<\/\s*title\s*>/<title>Moaning&nbsp;and Groaing at the Edge of ...<\/title>/si;
	print $cgi->header, $TEMPLATE_TOP;
}

sub print_footer { print $TEMPLATE_BOTTOM }

sub print_calendar {
	local (*DIR, @_, $_);
	my $done;
	my $author = $cgi->param('author') || "Lee";
	my $cal = HTML::Calendar::Simple->new;
	$_ = scalar localtime;
	my @date = split/\s+/,$_;

	chdir $blogger->{blog_base};
	opendir DIR, "." or die "No blog base dir";
	@_ = grep { -d && /^\w{3}_+$date[1].*?$date[4]_\Q$author\E$/ } readdir DIR;
	closedir DIR;

	foreach (@_){
		my 	@date = split/_+/,$_;
		next if exists $done->{$date[2]};
		s/_$author$//;
		$done->{$date[2]} = 1;
		my ($daydate) = ($_ =~ m/^(\w\w\w_\w\w\w_+\d+)/);
		$daydate .= '*';
		$cal->daily_info({
			'day' => $date[2],
			'day_link' => "javascript:parent.location.href='/cgi-bin/blog.cgi?author=$author&date=$daydate';void(0)",
		});
	}

	print "
	<style type='text/css'>
	.cal table { border-collapse: collapse; padding:0; margin:0; border:none }
	.cal a {
		position:relative;
		color:black;
		font-weight:bold;
		width:100%;
		height:100%;
		text-decoration:none;
		background: lime;
	}
	.cal a:hover {
		background:black;
		color:white;
		text-decoration:underline;
	}
	.cal {
		font-size:8px;
		font-family: Verdana, Arial, Helvetica, sans
	}
	.cal td, .cal h3 { font-size: 8px; padding:0; margin:0;}
	.cal h3 { font-size: 10px; }
	.cal td { padding: 2px; text-align:right}
	.cal th { font-size: 8px; border:none; padding: 1px}
	</style>
	<div class='cal'>
	";
	print $cal->calendar_month;
	print "
	</div>
	"

}





