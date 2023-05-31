#!/usr/bin/perl -w
use strict;
#use CGI;
#use CGI::Simple;
use Test::More tests => 2;

# this script shows how can one upload a file using CGI.pm as the back end.
# there is no need for CGI.pm in the client part of the test script.

$ENV{REQUEST_METHOD} = 'POST';
$ENV{CONTENT_LENGTH} = '217';
$ENV{CONTENT_TYPE}   = 'multipart/form-data; boundary=----------9GN0yM260jGW3Pq48BILfC';
$ENV{HTTP_USER_AGENT} = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.3) Gecko/20030312";

unlink "local.file";
hmm();
#unlink "local.file";
#hmm();

sub hmm {
	die if not @ARGV;
	my $q;

	
	local *STDIN;
	open(STDIN,'<local/plain.txt_multi') or die "missing test file 'local/plain.txt_multi'\n";
	
	# The in-memory variable does not work with CGI::Simple
	#my $original;
	#{
	#	open(my $ffh,'<local/plain.txt_multi') or die "missing test file 'local/plain.txt_multi'\n";
	#	$original = join "", <$ffh>;
	#	close $ffh;
	#}
	#open STDIN, "<", \$original;
	
	
	
	
	#binmode(STDIN);

	if ($ARGV[0] eq 1) {
		$q = "CGI";
	}
	if ($ARGV[0] eq 2) {
		require CGI;
		$q = new CGI;
	}

	if ($ARGV[0] eq 3) {
		$q = "CGI::Simple";
	}
	if ($ARGV[0] eq 4) {
		require CGI::Simple;
		$CGI::Simple::DISABLE_UPLOADS = 0;
		$q = new CGI::Simple;
	}

	if ($ARGV[0] eq 5) {
		$q = "CGI::Minimal";
	}

	upload($q);
}


open my $fhs, "<", "local.file" or die "Could not open local.file $!\n";
my $uploaded_content;
my $uploaded_size = read $fhs, $uploaded_content, 10000;

open my $fhc, "<", "local/plain.txt" or die "Cannot open local/plain.txt\n";
my $original_content;
my $original_size = read $fhc, $original_content, 10000;

is($uploaded_size, $original_size, "size is correct");
is($uploaded_content, $original_content, "Content is the same");



sub upload {

	my $arg = shift;
	my $q;
	my $fh;
	
	#warn "$arg\n";
	if (ref $arg) { # passed an object
		$q = $arg;
	} else {
		(my $file = $arg) =~ s{::}{/}g;
		$file .= ".pm";
		require $file;
		
		if ("CGI::Simple" eq $arg) {
			$CGI::Simple::DISABLE_UPLOADS = 0;
		}
		$q = new $arg;
	}
	$fh = $q->upload('field');
	
	my $buffer;

	if (open my $localfh, ">", "local.file") {

		while (read $fh, $buffer, 100) {
			print $localfh $buffer;
		}
	} else {
		die "could not open local.file $!";
	}
}




