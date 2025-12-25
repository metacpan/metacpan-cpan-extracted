#!/usr/bin/env perl
use strict;
use warnings;

use Test::DescribeMe qw(extended);
use Test::Most;
use Test::Needs ('MooseX::Params::Validate', 'MooseX::Types::Moose');
use File::Temp qw(tempdir);
use File::Spec;

# Load the module
BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

# Helper to create a temporary Perl module file
sub create_test_module {
	my ($content) = @_;
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'TestModule.pm');
	open my $fh, '>', $file or die "Cannot create $file: $!";
	print $fh $content;
	close $fh;
	return $file;
}

# Helper to create an extractor for testing
sub create_extractor {
	my ($module_content) = @_;
	my $module_file = create_test_module($module_content);
	return App::Test::Generator::SchemaExtractor->new(
		input_file => $module_file,
		output_dir => tempdir(CLEANUP => 1),
		verbose	=> 0,
	);
}

# Basic default value patterns
subtest 'Extact schema from Moose::Params::Validate' => sub {
	my $module = <<'END_MODULE';
use MooseX::Params::Validate qw(ValidatedMethod);
use MooseX::Types::Moose qw(Str ArrayRef Bool);

sub format_user {
    my ($self, %args) = @_;

    # Define parameter schema
    my $params = validated_hash(
        \%args,
        username => { isa => Str, required => 1 },
        roles    => { isa => ArrayRef[Str], default => sub { [] } },
        uppercase => { isa => Bool, default => 0 },
    );

    my $name = $params->{uppercase} ? uc($params->{username}) : $params->{username};

    return join(':', $name, @{$params->{roles}});
}

END_MODULE

	my $extractor = create_extractor($module);

	# Extract all schemas
	my $schemas = $extractor->extract_all();

	ok(defined($schemas));

	# use Data::Dumper;
	# diag(Dumper($schemas));

	# Verify we determined the input for format_user
	my $format_user_schema = $schemas->{format_user};
	ok($format_user_schema, 'Found format_user method schema');

	my $format_user_input = $format_user_schema->{input};
	ok($format_user_input, 'Found input method schema');

	cmp_deeply($format_user_input,  {
		'uppercase' => {
			'optional' => 1,
			'default' => 0,
			'type' => 'Bool'
		}, 'username' => {
			'type' => 'Str',
			'optional' => 0
		}, 'roles' => {
			'optional' => 1,
			'type' => 'arrayref',
			'element_type' => 'Str'
		}
	});

	done_testing();
};

done_testing();
