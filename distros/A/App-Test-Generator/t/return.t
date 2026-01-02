#!/usr/bin/env perl
use strict;
use warnings;

use Test::DescribeMe qw(extended);
use Test::Most;
use File::Temp qw(tempdir);

# Tests for enhanced context-aware return analysis
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

# List vs Scalar Context Detection
subtest 'List vs Scalar Context Detection' => sub {
	my $module = <<'END_MODULE';
package Test::ContextAware;
use strict;
use warnings;

=head2 get_items

Returns list of items in list context, count in scalar context.

=cut

sub get_items {
	my ($self) = @_;
	my @items = qw(foo bar baz);
	return wantarray ? @items : scalar(@items);
}

=head2 fetch_data

Context-aware data fetcher.

=cut

sub fetch_data {
	my ($self) = @_;
	return unless wantarray;
	return ($self->{id}, $self->{name}, $self->{email});
}

END_MODULE

	my $extractor = create_extractor($module);
	my $schemas = $extractor->extract_all();

	my $get_items = $schemas->{get_items};
	ok($get_items->{output}{context_aware}, 'Detects wantarray usage');
	is($get_items->{output}{list_context}{type}, 'array', 'List context returns array');
	is($get_items->{output}{scalar_context}{type}, 'integer', 'Scalar context returns integer');

	my $fetch_data = $schemas->{fetch_data};
	ok($fetch_data->{output}{context_aware}, 'Detects wantarray in conditional');
	ok($fetch_data->{output}{list_context}, 'Has list context return');

	done_testing();
};

# Void Context Methods
subtest 'Void Context Detection' => sub {
	my $module = <<'END_MODULE';
package Test::VoidContext;
use strict;
use warnings;

sub set_name {
	my ($self, $name) = @_;
	$self->{name} = $name;
	return;
}

sub add_item {
	my ($self, $item) = @_;
	push @{$self->{items}}, $item;
	return;
}

sub log_message {
	my ($self, $msg) = @_;
	print STDERR $msg;
	return;
}

sub update_status {
	my ($self, $status) = @_;
	$self->{status} = $status;
	return 1;
}

END_MODULE

	my $extractor = create_extractor($module);
	my $schemas = $extractor->extract_all();

	# Void context methods
	is($schemas->{set_name}{output}{type}, 'void', 'Setter is void context');
	ok($schemas->{set_name}{output}{void_context_hint}, 'Detected setter pattern');

	is($schemas->{add_item}{output}{type}, 'void', 'Mutator is void context');
	ok($schemas->{add_item}{output}{void_context_hint}, 'Detected mutator pattern');

	is($schemas->{log_message}{output}{type}, 'void', 'Logger is void context');

	# Success indicator (not void)
	is($schemas->{update_status}{output}{type}, 'boolean', 'Update returns success indicator');
	ok($schemas->{update_status}{output}{_success_indicator}, 'Detected success indicator pattern');

	done_testing();
};

# Method Chaining Detection
subtest 'Method Chaining Detection' => sub {
	my $module = <<'END_MODULE';
package Test::Chainable;
use strict;
use warnings;

=head2 set_width

Sets width. Chainable method.

Returns: self

=cut

sub set_width {
	my ($self, $width) = @_;
	$self->{width} = $width;
	return $self;
}

=head2 set_height

Fluent interface for setting height.

=cut

sub set_height {
	my ($self, $height) = @_;
	$self->{height} = $height;
	return $self;
}

sub configure {
	my ($self, %opts) = @_;

	foreach my $key (keys %opts) {
		$self->{$key} = $opts{$key};
	}

	return $self;
}

sub mixed_returns {
	my ($self, $validate) = @_;

	return unless $self->{valid};
	return $self;
}

END_MODULE

	my $extractor = create_extractor($module);
	my $schemas = $extractor->extract_all();

	# Fully chainable methods
	ok($schemas->{set_width}{output}{returns_self}, 'Returns self');
	is($schemas->{set_width}{output}{type}, 'object', 'Returns object type');
	is($schemas->{set_width}{output}{isa}, 'Test::Chainable', 'Returns correct class');

	ok($schemas->{set_height}{output}{returns_self}, 'POD indicates returns_self');

	ok($schemas->{configure}{output}{returns_self}, 'configure is returns_self');

	# Mixed returns - not consistently returns_self
	ok(!$schemas->{mixed_returns}{output}{returns_self}, 'Mixed returns not marked returns_self');

	done_testing();
};

# Error Return Conventions
subtest 'Error Return Conventions' => sub {
	my $module = <<'END_MODULE';
package Test::ErrorHandling;
use strict;
use warnings;

sub fetch_user {
	my ($self, $id) = @_;

	return undef unless $id;
	return undef if $id < 0;

	return $self->{users}{$id};
}

sub process_data {
	my ($self, $data) = @_;

	return if !defined $data;
	return if $data eq '';

	return $self->_process($data);
}

sub validate {
	my ($self, $input) = @_;

	return 0 unless $input;
	return 0 if $input =~ /invalid/;

	return 1;
}

sub get_items {
	my ($self) = @_;

	return () unless $self->{items};
	return @{$self->{items}};
}

sub safe_operation {
	my ($self) = @_;

	eval {
		$self->risky_thing();
	};
	if ($@) {
		warn "Error: $@";
		return undef;
	}

	return $self->{result};
}

END_MODULE

	my $extractor = create_extractor($module);
	my $schemas = $extractor->extract_all();

	# Explicit undef on error
	is($schemas->{fetch_user}{output}{error_return}, 'undef', 'Returns undef on error');
	ok($schemas->{fetch_user}{output}{error_handling}{undef_on_error}, 'Detected explicit undef returns');
	ok($schemas->{fetch_user}{output}{success_failure_pattern}, 'Has success/failure pattern');

	# Implicit undef (bare return)
	is($schemas->{process_data}{output}{error_return}, 'undef', 'Returns implicit undef');
	ok($schemas->{process_data}{output}{error_handling}{implicit_undef}, 'Detected bare returns');

	# Boolean return (0/1)
	is($schemas->{validate}{output}{type}, 'boolean', 'Validation returns boolean');
	is($schemas->{validate}{output}{error_return}, 'false', 'Returns false on error');

	# Empty list on error
	is($schemas->{get_items}{output}{error_return}, 'empty_list', 'Returns empty list on error');
	ok($schemas->{get_items}{output}{error_handling}{empty_list}, 'Detected empty list return');

	# Exception handling
	ok($schemas->{safe_operation}{output}{error_handling}{exception_handling}, 'Detected exception handling');

	done_testing();
};

# Complex Return Patterns
subtest 'Complex Return Patterns' => sub {
	my $module = <<'END_MODULE';
package Test::ComplexReturns;
use strict;
use warnings;

sub get_status {
	my ($self) = @_;

	return wantarray
		? ($self->{code}, $self->{message}, $self->{details})
		: $self->{code};
}

sub builder_method {
	my ($self, $value) = @_;

	if (defined $value) {
		$self->{value} = $value;
		return $self;
	}

	return $self->{value};
}

sub conditional_list {
	my ($self, $filter) = @_;

	my @items = @{$self->{items}};

	return () unless @items;
	return grep { $_->{type} eq $filter } @items if $filter;
	return @items;
}

END_MODULE

	my $extractor = create_extractor($module);
	my $schemas = $extractor->extract_all();

	# Context-aware with ternary
	ok($schemas->{get_status}{output}{context_aware}, 'Ternary wantarray detected');
	is($schemas->{get_status}{output}{list_context}{type}, 'array', 'List context returns array');
	is($schemas->{get_status}{output}{scalar_context}{type}, 'scalar', 'Scalar context returns scalar');

	# Getter/setter pattern (not consistently returns_self)
	ok(!$schemas->{builder_method}{output}{returns_self}, 'Getter/setter not marked returns_self');

	# Conditional list returns
	ok($schemas->{conditional_list}{output}{error_handling}{empty_list}, 'Can return empty list');

	done_testing();
};

# Real-world Examples
subtest 'Real-World Return Analysis' => sub {
	my $module = <<'END_MODULE';
package Test::RealWorld;
use strict;
use warnings;

=head2 connect

Connects to the server. Returns connection object on success, undef on failure.

=cut

sub connect {
	my ($self, $host, $port) = @_;

	return undef unless $host;

	my $conn = eval { $self->_connect($host, $port) };
	return undef if $@;

	return $conn;
}

=head2 set_timeout

Sets the timeout value. Method chaining supported.

Returns: $self for chaining

=cut

sub set_timeout {
	my ($self, $timeout) = @_;
	$self->{timeout} = $timeout;
	return $self;
}

sub search {
	my ($self, $query) = @_;

	my @results = $self->_execute_search($query);

	return wantarray ? @results : \@results;
}

sub debug {
	my ($self, @messages) = @_;

	return unless $self->{debug_mode};

	print STDERR "[DEBUG] ", join(' ', @messages), "\n";
	return;
}

=head2	is_debug

Are we running in debug mode?

=cut

sub is_debug
{
	my $self = $_[0];

	return $self->{'debug_mode'} ? 1 : 0;
}

END_MODULE

	my $extractor = create_extractor($module);
	my $schemas = $extractor->extract_all();

	# Connection method
	is($schemas->{connect}{output}{error_return}, 'undef', 'connect returns undef on error');
	ok($schemas->{connect}{output}{success_failure_pattern}, 'Has success/failure pattern');

	# Chainable setter
	ok($schemas->{set_timeout}{output}{returns_self}, 'POD indicates returns_self');
	ok($schemas->{set_timeout}{output}{returns_self}, 'Returns self for chaining');

	# Context-aware search
	ok($schemas->{search}{output}{context_aware}, 'search is context-aware');

	# Debug logger (void context)
	is($schemas->{debug}{output}{type}, 'void', 'debug is void context');

	# Strong boolean signal: ternary returning 1/0
	is($schemas->{is_debug}{output}{type}, 'boolean', 'ternary returning 1/0 is taken as boolean');

	done_testing();
};

done_testing();
