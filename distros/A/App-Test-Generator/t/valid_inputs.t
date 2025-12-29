#!/usr/bin/env perl
use strict;
use warnings;

use Test::DescribeMe qw(extended);
use Test::Most;
use File::Temp qw(tempdir);

# POD SYNOPSIS Example Extraction
# Load the module
BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

# Helper to create a temporary Perl module file
sub create_test_module {
	my $content = $_[0];
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'TestModule.pm');
	open my $fh, '>', $file or die "Cannot create $file: $!";
	print $fh $content;
	close $fh;
	return $file;
}

# Helper to create an extractor for testing
sub create_extractor {
	my $module_content = $_[0];
	my $module_file = create_test_module($module_content);
	return App::Test::Generator::SchemaExtractor->new(
		input_file => $module_file,
		output_dir => tempdir(CLEANUP => 1),
		verbose	=> 0,
	);
}

subtest 'POD SYNOPSIS Example Extraction' => sub {
	my $module = <<'END_MODULE';
package Test::PodExamples;
use strict;
use warnings;

=head2 new

Create a new object.

=head2 SYNOPSIS

	my $obj = Test::PodExamples->new(
		host => 'localhost',
		port => 8080,
		debug => 1,
	);

=cut

sub new {
	my ($class, %args) = @_;
	return bless \%args, $class;
}

=head2 connect

Connect to a remote service.

=head2 SYNOPSIS

	my $conn = $obj->connect('api.example.com', 443);

=cut

sub connect {
	my ($self, $host, $port) = @_;
	return unless $host;
	return { host => $host, port => $port };
}

=head2 search

Search with optional filters.

=head2 SYNOPSIS

	my @results = $obj->search(query => 'perl', limit => 10);

=cut

sub search {
	my ($self, %opts) = @_;
	return ();
}

END_MODULE

	my $extractor = create_extractor($module);
	my $schemas   = $extractor->extract_all();

	# use Data::Dumper;
	# diag(Dumper($schemas));

	# Constructor examples
	my $new = $schemas->{new};
	ok($new->{_yamltest_hints}, 'Constructor has yamltest hints');
	ok($new->{_yamltest_hints}{valid_inputs}, 'Constructor has valid_inputs');

	is(
		scalar @{ $new->{_yamltest_hints}{valid_inputs} },
		1,
		'One constructor example extracted'
	);

	my $new_example = $new->{_yamltest_hints}{valid_inputs}[0];
	is($new_example->{style}, 'named', 'Constructor example is named args');
	is($new_example->{source}, 'pod', 'Constructor example source is pod');
	is($new_example->{args}{host}, 'localhost', 'Extracted host argument');
	is($new_example->{args}{port}, 8080, 'Extracted port argument');
	is($new_example->{args}{debug}, 1, 'Extracted debug argument');

	# Positional method example
	my $connect = $schemas->{connect};
	ok($connect->{_yamltest_hints}{valid_inputs}, 'connect has valid_inputs');

	my $connect_example = $connect->{_yamltest_hints}{valid_inputs}[0];
	is($connect_example->{style}, 'positional', 'connect example is positional');
	is($connect_example->{source}, 'pod', 'connect example source is pod');
	is_deeply(
		$connect_example->{args},
		[ "'api.example.com'", '443' ],
		'Extracted positional arguments'
	);

	# Named args method example
	my $search = $schemas->{search};
	ok($search->{_yamltest_hints}{valid_inputs}, 'search has valid_inputs');

	my $search_example = $search->{_yamltest_hints}{valid_inputs}[0];
	is($search_example->{style}, 'named', 'search example uses named args');
	is($search_example->{args}{query}, 'perl', 'Extracted query argument');
	is($search_example->{args}{limit}, 10, 'Extracted limit argument');

	done_testing();
};

done_testing();
