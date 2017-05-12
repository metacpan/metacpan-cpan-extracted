# vim:set syntax=perl:

use strict;
use warnings FATAL => 'all';
  
use Apache::TestRequest qw(GET_BODY_ASSERT);
use File::Find;
use Test::More;
use TestApReqI18N;

use constant URL => '/TestApReqI18N__dump';
use constant DIR => 't/dump.d';
use constant TESTS_PER_FILE => 2;


my @sources;
if (@ARGV) {
	@sources = @ARGV;
} else {
	find( sub { push @sources, $File::Find::name if -f $_ && /\.in$/ }, DIR );
}
  
plan tests => 1 + TESTS_PER_FILE * @sources;
  
our (%vars, @uploads);

eval GET_BODY_ASSERT (URL . '?foo=bar');
is_deeply(\%vars, { foo => [ 'bar' ] }, 'Basic param() test');

foreach my $source (sort @sources) {
    SKIP: {
	my $target = $source;
	$target =~ s/\.in$/.pl/;

	-e $target || skip "Cannot find $target", TESTS_PER_FILE;

	(%vars, @uploads) = ();
	do $target;

	my %expected_vars = %vars;
	my @expected_uploads = @uploads;

	local $TODO;
	eval request_from_file($source, URL);

	is_deeply(\%vars, \%expected_vars, '[V] ' . last_test_name);
	is_deeply(\@uploads, \@expected_uploads, '[U] ' . last_test_name);
    }
}

