#!perl -w

# Test if CGI::Buffer adds Content-Length and Etag headers, also simple
# check that optimise_content and gzips does something.

# TODO: check optimise_content and gzips do the *right* thing
# TODO: check ETags are correct

use strict;
use warnings;

use Test::Most tests => 9;
use Test::TempDir::Tiny;
# use Test::NoWarnings;	# HTML::Clean has them
eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('CGI::Buffer');
}

OUTPUT: {
	delete $ENV{'HTTP_ACCEPT_ENCODING'};
	delete $ENV{'SERVER_PROTOCOL'};

	my $input = << 'EOF';
	use CGI::Buffer;

	CGI::Buffer::set_options(optimise_content => 2);

	print "Content-type: text/html; charset=ISO=8859-1";
	print "\n\n";

	print "<HTML><BODY>\n";
	print "document.write(\"1\");\n";
	print "document.write(\"2\");\n";
	print "<script type=\"text/javascript\">\n";
	print "var i = 1;\n";
	print "document.write(\"foo\");\n";
	print "document.write(\"bar\");\n";
	print "var j = 1;\n";
	print "document.write(\"a\");\n";
	print "document.write(\"b\");\n";
	print "</script>\n";
	print "Hello World!\n";
	print "<script type=\"text/javascript\">\n";
	print "document.write(\"a\");\n";
	print "document.write(\"b\");\n";
	print "</script>\n";
	print "<script type=\"text/javascript\">\n";
	print "document.write(\"fred\");\n";
	print "var k = 1;\n";
	print "document.write(\"wilma\");\n";
	print "</script>\n";
	print "</body>\n";
EOF

	my $filename = tempdir() . 'js.t';
	open(my $tmp, '>', $filename);
	print $tmp $input;

	if(open(my $fout, '-|', "$^X -Iblib/lib $filename")) {
		my $keep = $_;
		undef $/;
		my $output = <$fout>;
		$/ = $keep;

		close $tmp;

		ok($output =~ /^Content-Length:\s+(\d+)+/m);
		my $length = $1;

		my ($headers, $body) = split /\r?\n\r?\n/, $output, 2;
		ok(defined($headers));
		ok(defined($body));
		is(length($body), $length, 'Check length of body');

		ok($output =~ /document\.write\("a"\+"b"\);/m);
		ok($output =~ /document\.write\("foo"\+"bar"\);/m);
		ok($output !~ /document\.write\("1"\+"2"\);/m);
		ok($output !~ /document\.write\("fred"\+"wilma"\);/m);
	} else {
		diag "$filename: $!";
		print "Bail out!";
	}
}
