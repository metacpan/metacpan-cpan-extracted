#!perl -w

# Test if CGI::Buffer adds Content-Length and Etag headers, also simple
# check that optimise_content does something.

# TODO: check optimise_content and gzips do the *right* thing
# TODO: check ETags are correct
# TODO: Write a test to check that 304 is sent when a cached object
# TODO:	Consider Test::File::Contents

use strict;
use warnings;

use Test::Most tests => 101;
use Compress::Zlib;
use Test::TempDir::Tiny;
use IO::Uncompress::Brotli;
use DateTime;
use Test::HTML::Lint;
# use Test::NoWarnings;	# HTML::Clean has them
eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('CGI::Buffer');
}

OUTPUT: {
	delete $ENV{'HTTP_ACCEPT_ENCODING'};
	delete $ENV{'HTTP_TE'};
	delete $ENV{'SERVER_PROTOCOL'};
	delete $ENV{'HTTP_RANGE'};

	$ENV{'REQUEST_METHOD'} = 'GET';

	my $filename = tempdir() . 'test1';
	open(my $tmp, '>', $filename);
	print $tmp "use strict;\n",
		"use CGI::Buffer;\n",
		"print \"Content-type: text/html; charset=ISO-8859-1\";\n",
		"print \"\\n\\n\";\n",
		"print \"<HTML><BODY>   Hello, world</BODY></HTML>\\n\";\n";

	open(my $fin, '-|', "$^X -Iblib/lib " . $filename);

	my $keep = $_;
	undef $/;
	my $output = <$fin>;
	$/ = $keep;

	close $tmp;

	ok($output !~ /^ETag: "/m);
	ok($output !~ /^Content-Encoding: gzip/m);

	my ($headers, $body) = split /\r?\n\r?\n/, $output, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	my $length = $1;
	ok(defined($length));

	ok($body eq "<HTML><BODY>   Hello, world</BODY></HTML>\n");
	ok(length($body) eq $length);

	$filename = tempdir() . 'test2';
	open($tmp, '>', $filename);
	print $tmp "use CGI::Buffer;\n";
	print $tmp "CGI::Buffer::set_options(optimise_content => 1);\n";
	print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n";
	print $tmp "print \"\\n\\n\";\n";
	print $tmp "print \"<HTML>\\n<BODY>\\n\\t    Hello, world\\n  </BODY>\\n</HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	ok($output =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	# Extra spaces should have been removed
	ok($output =~ /<HTML><BODY>Hello, world<\/BODY><\/HTML>/mi);
	ok($output !~ /^Content-Encoding: gzip/m);
	ok($output !~ /^ETag: "/m);

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok(defined($headers));
	ok(defined($body));
	ok(length($body) eq $length);

	$ENV{'HTTP_ACCEPT_ENCODING'} = 'gzip, deflate, sdch, br';

	$filename = tempdir() . 'test3';
	open($tmp, '>', $filename);
	print $tmp "use CGI::Buffer;\n";
	print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n";
	print $tmp "print \"\\n\\n\";\n";
	print $tmp "print \"<HTML><HEAD>Test</HEAD><BODY><P>Hello, world></BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	ok($output =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	# It's not gzipped, because it's so small the gzip version would be
	# bigger
	ok($output =~ /<HTML><HEAD>Test<\/HEAD><BODY><P>Hello, world><\/BODY><\/HTML>/m);
	ok($output !~ /^Content-Encoding: gzip/m);
	ok($output !~ /^ETag: "/m);

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok(length($body) eq $length);

	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	$ENV{'HTTP_ACCEPT_ENCODING'} = undef;
	# delete($ENV{'HTTP_ACCEPT_ENCODING'});
	$ENV{'HTTP_TE'} = 'br,gzip';

	$filename = tempdir() . 'test4';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer {optimise_content => 0};\n",
		"print \"Content-type: text/html; charset=ISO-8859-1\\n\";\n",
		"print \"X-foo: \$ENV{HTTP_TE}\\n\";\n",
		"print \"X-foo: \$ENV{HTTP_ACCEPT_ENCODING}\\n\";\n",
		"print \"\\n\";\n";
	# Put in a large body so that it gzips - small bodies won't
	print $tmp "print \"<!DOCTYPE HTML PUBLIC \\\"-//W3C//DTD HTML 4.01 Transitional//EN\\\">\\n\";\n",
		"print \"<HTML><HEAD><TITLE>Hello, world</TITLE></HEAD><BODY><P>The quick brown fox jumped over the lazy dog.</P></BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib $filename");

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	ok($output =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok($headers =~ /^Content-Encoding: br/m);
	ok($headers =~ /ETag: "[A-Za-z0-F0-f]{32}"/m);

	ok(defined($body));
	ok(length($body) eq $length);
	$body = unbro($body, 1024);
	ok(defined($body));
	ok($body =~ /<HTML><HEAD><TITLE>Hello, world<\/TITLE><\/HEAD><BODY><P>The quick brown fox jumped over the lazy dog.<\/P><\/BODY><\/HTML>\n$/);
	html_ok($body, 'HTML:Lint shows no errors');

	#..........................................
	delete $ENV{'SERVER_PROTOCOL'};
	delete $ENV{'HTTP_TE'};

	$ENV{'SERVER_NAME'} = 'www.example.com';

	$filename = tempdir() . 'test5';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer;\n",
		"CGI::Buffer::set_options({ optimise_content => 1 });\n",
		"print \"Content-type: text/html; charset=ISO-8859-1\";\n",
		"print \"\\n\\n\";\n",
		"print \"<HTML><BODY><A HREF=\\\"http://www.example.com\\\">Click</A>\n<script>\nalert(foo);\n</script></BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	ok($output =~ /href="\/"/m);
	ok($output !~ /<script>\s/m);

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	ok(length($body) eq $length);
	ok($body !~ /www.example.com/m);

	#..........................................
	$filename = tempdir() . 'test6';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer;\n";
	print $tmp "CGI::Buffer::set_options(optimise_content => 1);\n";
	print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n";
	print $tmp "print \"\\n\\n\";\n";
	print $tmp "print \"<HTML><BODY><A HREF= \\\"http://www.example.com/foo.htm\\\">Click</A></BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	ok($output =~ /href="\/foo.htm"/m);
	ok($output =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok(length($body) eq $length);
	ok($body !~ /www.example.com/m);

	#..........................................
	$filename = tempdir() . 'test7';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer;\n";
	print $tmp "CGI::Buffer::set_options(optimise_content => 1, lint_content=> 1);\n";
	print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n",
		"print \"\\n\\n\";\n",
		"print \"<HTML><HEAD><TITLE>test 7</TITLE></HEAD><BODY><A HREF= \n\\\"http://www.example.com/foo.htm\\\">Click</A></BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok(length($body) eq $length);
	ok($body =~ /href="\/foo.htm"/mi);
	# Server is www.example.com (set in a previous test), so the href
	# should be optimised, therefore www.example.com shouldn't appear
	# anywhere at all
	ok($body !~ /www\.example\.com/m);

	#..........................................
	# Check for removal of consecutive white space between links
	delete $ENV{'HTTP_TE'};
	$filename = tempdir() . 'test8';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer;\n",
		"CGI::Buffer::set_options(optimise_content => 1, lint_content=> 1);\n",
		"print \"Content-type: text/html; charset=ISO-8859-1\";\n",
		"print \"\\n\\n\";\n",
		"print \"<HTML><HEAD><TITLE>test 8</TITLE></HEAD><BODY><A HREF= \n\\\"http://www.example.com/foo.htm\\\">Click </A> \\n\\t<a href=\\\"http://www.example.com/bar.htm\\\">Or here</a> </BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	ok($output =~ /<a href="\/foo\.htm">Click<\/A> <a href="\/bar\.htm">Or here<\/a>/mi);

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok(length($body) eq $length);
	ok($body =~ /href="\/foo.htm"/mi);
	# Server is www.example.com (set in a previous test), so the href
	# should be optimised, therefore www.example.com shouldn't appear
	# anywhere at all
	ok($body !~ /www\.example\.com/m);

	#..........................................

	$filename = tempdir() . 'test9';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer;\n";
	print $tmp "CGI::Buffer::set_options(optimise_content => 1);\n";
	print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n";
	print $tmp "print \"\\n\\n\";\n";
	print $tmp "print \"<HTML><BODY><A HREF=\\\"http://www.example.com/foo.htm\\\">Click</a> <hr> A Line \n<HR>\r\n Foo</BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok(length($body) eq $length);
	ok($headers !~ /^Status: 500/m);
	ok($body =~ /<hr>A Line<hr>Foo/);

	#..........................................
	# Space left intact after </em>
	$filename = tempdir() . 'test10';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer { optimise_content => 1, lint_content => 0 };\n";
	print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n";
	print $tmp "print \"\\n\\n\";\n";
	print $tmp "print \"<HTML><BODY>\n<p><em>The Brass Band Portal</em> is visited some 500 times</BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok(length($body) eq $length);
	ok($headers !~ /^Status: 500/m);
	ok($body eq "<HTML><BODY><p><em>The Brass Band Portal</em> is visited some 500 times</BODY></HTML>");

	#..........................................
	diag('Ignore warning about <a> is never closed');
	delete $ENV{'SERVER_NAME'};
	$filename = tempdir() . 'test11';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer;\n";
	print $tmp "CGI::Buffer::set_options(optimise_content => 1, lint_content=> 1);\n";
	print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n";
	print $tmp "print \"\\n\\n\";\n";
	print $tmp "print \"<HTML><BODY><A HREF=\\\"http://www.example.com/foo.htm\\\">Click</BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));
	ok(length($body) eq $length);
	ok($headers =~ /^Status: 500/m);
	ok($body =~ /<a>.+is never closed/);

	#..........................................
	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	delete $ENV{'HTTP_ACCEPT_ENCODING'};

	$filename = tempdir() . 'test12';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer;\n";
	print $tmp "CGI::Buffer::set_options({optimise_content => 1});\n";
	print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n";
	print $tmp "print \"\\n\\n\";\n";
	print $tmp "print \"<HTML><BODY><TABLE><TR><TD>foo</TD>  <TD>bar</TD></TR></TABLE></BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	ok($output =~ /<TD>foo<\/TD><TD>bar<\/TD>/mi);
	ok($output =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	ok($output =~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	my $etag = $1;
	ok(defined($etag));

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok(length($body) eq $length);
	ok(length($body) > 0);

	#..........................................
	$ENV{'HTTP_IF_NONE_MATCH'} = "\"$etag\"";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok($headers =~ /^Status: 304 Not Modified/mi);
	ok(length($body) == 0);

	$ENV{'REQUEST_METHOD'} = 'HEAD';

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok($headers =~ /^Status: 304 Not Modified/mi);
	ok(length($body) == 0);

	#..........................................
	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	delete $ENV{'HTTP_ACCEPT_ENCODING'};
	$ENV{'REQUEST_METHOD'} = 'GET';

	$filename = tempdir() . 'test13';
	open($tmp, '>', $filename);
	print $tmp "use CGI::Buffer;\n";
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "CGI::Buffer::set_options(optimise_content => 1, generate_304 => 0);\n";
	print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n";
	print $tmp "print \"\\n\\n\";\n";
	print $tmp "print \"<HTML><BODY><TABLE><TR><TD>foo</TD>\\t  <TD>bar</TD></TR></TABLE></BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	ok(defined($output));
	ok($output =~ /<TD>foo<\/TD><TD>bar<\/TD>/mi);
	ok($output !~ /^Status: 304 Not Modified/mi);
	ok($output =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;
	ok(defined($length));

	ok($output =~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	$etag = $1;
	ok(defined($etag));

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok(defined($length));
	ok(length($body) eq $length);
	ok(length($body) > 0);

	#..........................................
	$ENV{'HTTP_IF_NONE_MATCH'} = $etag;

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	ok($output !~ /^Status: 304 Not Modified/mi);
	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
	ok(length($body) > 0);

	#..........................................
	delete $ENV{'HTTP_IF_NONE_MATCH'};
	$ENV{'HTTP_IF_MODIFIED_SINCE'} = DateTime->now();

	$filename = tempdir() . 'test14';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer { optimise_content => 1, generate_etag => 0 };\n",
		"print \"Content-type: text/html; charset=ISO-8859-1\";\n",
		"print \"\\n\\n\";\n",
		"print \"<HTML><BODY><TABLE><TR><TD>foo</TD>  <TD>bar</TD></TR></TABLE></BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	ok($output !~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	ok($output =~ /^Status: 304 Not Modified/mi);

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;

	ok($headers !~ /^Content-Length:/m);

	ok(length($body) == 0);

	#......................................
	$ENV{'HTTP_IF_MODIFIED_SINCE'} = 'This is an invalid date';

	$filename = tempdir() . 'test15';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use CGI::Buffer { optimise_content => 1, generate_etag => 0 };\n";
	print $tmp "print \"Content-type: text/html; charset=ISO-8859-1\";\n";
	print $tmp "print \"\\n\\n\";\n";
	print $tmp "print \"<HTML><BODY><TABLE><TR><TD>foo</TD>   <TD>bar</TD></TR></TABLE></BODY></HTML>\\n\";\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;

	ok($output !~ /ETag: "([A-Za-z0-F0-f]{32})"/m);
	ok($output !~ /^Status: 304 Not Modified/mi);

	($headers, $body) = split /\r?\n\r?\n/, $output, 2;

	ok($headers =~ /^Content-Length:\s+(\d+)/m);
	$length = $1;

	ok(length($body) != 0);
	ok(defined($length));
	ok(length($body) == $length);

	#......................................
	# Check no output does nothing strange

	delete $ENV{'HTTP_IF_MODIFIED_SINCE'};

	$filename = tempdir() . 'test16';
	open($tmp, '>', $filename);
	if($ENV{'PERL5LIB'}) {
		foreach (reverse split(/:/, $ENV{'PERL5LIB'})) {
			print $tmp "use lib '$_';\n";
		}
	}
	print $tmp "use strict;\n",
		"use CGI::Buffer;\n";

	open($fin, '-|', "$^X -Iblib/lib " . $filename);

	$keep = $_;
	undef $/;
	$output = <$fin>;
	$/ = $keep;

	close $tmp;
	close $fin;

	ok($output eq '');
}
