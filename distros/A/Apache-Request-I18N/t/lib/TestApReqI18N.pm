package TestApReqI18N;

use 5.008;
use strict;
use warnings FATAL => 'all';
  
use Apache::TestRequest;
use Carp;
use Exporter;
use HTTP::Request;
use IO::File;

our @ISA = qw(Exporter);
our @EXPORT = qw(request_from_file last_test_name);


my $ua = Apache::TestRequest::user_agent;
my $hostport = Apache::TestRequest::hostport(Apache::Test::config);
my %headers = ('Host' => (split ':', $hostport)[0]);

my $test_name;


sub last_test_name { $test_name }

sub request_from_file {
	my ($source, $root) = @_;

	$root ||= '';

	my $fh = new IO::File $source
		or croak "Cannot read from $source: $!";
	
	undef $test_name;

	my $line;
	while ($line = $fh->getline) {
		next if $line =~ /^\s*$/;
		last unless $line =~ s/^\s*#\s*//;
		chomp $line;
		$test_name = $line if $line && ! defined $test_name;
		if ($line =~ s/^\s*TODO\b\s*(:\s*)?//) {
			no strict 'refs';
			my $caller = caller;
			${"$caller\::TODO"} = $line;
		}
	}

	# FIXME: What to do with an empty request?

	$line =~ s!^(\s*\w+\s+)!$1http://$hostport$root!;
	$line = join ('' => $line, $fh->getlines);

	my $request = parse HTTP::Request $line
		or croak "Cannot parse request $source";
	
	my $content_type = $request->header('Content-Type');
	if ($content_type && $content_type =~ /x-www-form-urlencoded/) {
		my $content = $request->content_ref;
		chomp $$content;
	}

	unless (defined $request->header('Content-Length')) {
		$request->header('Content-Length', length $request->content);
	}

	Apache::TestRequest::content_assert($ua->request($request));
}


1;

