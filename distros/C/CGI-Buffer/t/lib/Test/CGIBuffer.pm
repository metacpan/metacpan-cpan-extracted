package Test::CGIBuffer;

# Helpers for testing CGI::Buffer.  It does its work in an END block, so each
# case is a CGI script run in its own process

use strict;
use warnings;
use Exporter qw(import);
use File::Spec;
use Test::TempDir::Tiny;

our @EXPORT_OK = qw(run_script second_request header);

# The CGI::Buffer under test.  CGI_BUFFER_LIB lets a test be run against
# another version, e.g. to check that it fails on the code before a fix
my $lib = File::Spec->rel2abs($ENV{CGI_BUFFER_LIB} || 'lib');

# Run a CGI script, returning a hashref of:
#	headers: an arrayref of the header lines
#	body: the body
#	output: everything printed to STDOUT
#	stderr: everything printed to STDERR
# Arguments:
#	code: the script, after CGI::Buffer has been loaded
#	preamble: code before CGI::Buffer is loaded
#	init: the arguments to CGI::Buffer::init(), as a string of Perl
#	cache: if true, use a File cache in dir, with the key "k", and exit if
#		the page is in it
#	dir: the directory for the script and the cache, default a new one
#	env: a hashref of environment variables to add
sub run_script {
	my (%args) = @_;

	my $dir = $args{dir} || tempdir();
	my $script = File::Spec->catfile($dir, 'script.pl');
	my $stderr = File::Spec->catfile($dir, 'stderr');

	my $cache = '';
	if($args{cache}) {
		$cache = "use CHI;\n" .
			"CGI::Buffer::init(cache => CHI->new(driver => 'File', root_dir => '$dir/cache'), cache_key => 'k');\n" .
			"exit if CGI::Buffer::is_cached();\n";
	}

	open(my $fout, '>', $script) or die "$script: $!";
	print $fout "use strict;\nuse warnings;\n", ($args{preamble} || ''),
		"use CGI::Buffer;\n",
		($args{init} ? "CGI::Buffer::init($args{init});\n" : ''),
		$cache,
		$args{code};
	close $fout;

	# Keep PERL5LIB so that modules installed with local::lib (as in CI)
	# can still be found by the script
	local %ENV = (
		PATH => $ENV{'PATH'},
		(defined($ENV{'PERL5LIB'}) ? (PERL5LIB => $ENV{'PERL5LIB'}) : ()),
		SERVER_PROTOCOL => 'HTTP/1.1',
		REQUEST_METHOD => 'GET',
		SCRIPT_NAME => '/cgi-bin/script.pl',
		SCRIPT_FILENAME => $script,
		DOCUMENT_ROOT => $dir,
		%{$args{env} || {}}
	);
	my $output = `$^X -I$lib $script 2>$stderr`;

	my $errors = '';
	if(open(my $fin, '<', $stderr)) {
		local $/;
		$errors = <$fin> // '';
		close $fin;
	}

	my ($headers, $body) = split(/\r?\n\r?\n/, $output, 2);
	return {
		headers => [ split(/\r?\n/, $headers // '') ],
		body => $body // '',
		output => $output,
		stderr => $errors,
	};
}

# Run the same script twice in the same directory, returning the result of
# the second.  The first is run with FIRST set in its environment
sub second_request {
	my (%args) = @_;

	$args{dir} ||= tempdir();
	run_script(%args, env => { %{$args{env} || {}}, FIRST => 1 });
	return run_script(%args);
}

# The values of a header in the result of run_script(), as a list
sub header {
	my ($result, $name) = @_;

	return map { /^\Q$name\E:\s*(.*?)\s*$/i ? $1 : () } @{$result->{headers}};
}

1;
