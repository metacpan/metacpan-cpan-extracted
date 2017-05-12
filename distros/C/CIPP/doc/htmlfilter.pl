#!/usr/local/bin/perl -p

use lib qw ( lib ../lib );
use CIPP;

BEGIN {
	open (IN, "header.html") or die "can't read header.html";
	s/\$CIPP:\:VERSION/$CIPP::VERSION/,
	s/\$DATE/scalar(localtime(time))/e, print while <IN>;
	close IN;
}

# skip HTML header
$in_body = 1 if /<body>/i;
$_='' if not $in_body;

# remove <P> after <DD> tags
s/^<P>$// if $dd;
$dd = /<DD>$/;

# too much lines here
s/^<HR>$//;

# add a <P> before <DT>
s/<DT>/<P><DT>/g;

# each command on it's own page
s/(<H1><A NAME="(COMM|NAME))/<!--NewPage-->\n$1/;
s!(<H1><A NAME="COMMAND.*?>(.*)</A></H1>)!$1<HR>!;

# remove the sub menus of the command description chapters
$in_index = 1 if /-- INDEX BEGIN/;
$in_index = 0 if /-- INDEX END/;

if ( $in_index ) {
	$command_chapters = 1 if /HREF=".COMMAND/;
	$ul = 1 if /<UL>/;
	$ul = 0 if m!</UL>!;
	$_ = '' if $command_chapters and $ul and /<LI>/;
	$_ = '' if $command_chapters and /<.?UL>/;
}

# convert h2 to big
s!<H2>(.*?)</H2>!<BIG><B>$1</B></BIG>!g;

++$pre if m!<pre>!i;
--$pre if m!</pre>!i;

if ( not $pre ) {
	s!&amp;lt;!&lt;!g;
	s!&amp;gt;!&gt;!g;
	s!([\$\@\%]\w*)!<code>$1</code>!g;
	s!(([A-Z_]+)\s*=\s*``([^']*?)'')!<code>$2="$3"</code>!g;
}

