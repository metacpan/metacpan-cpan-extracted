#!/usr/bin/env perl
use strict;
use warnings;

use Test::DescribeMe qw(extended);
use Test::Most;
use Test::Needs 'Type::Params';
use File::Temp qw(tempdir);
use File::Spec;

# Load the module
BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

TODO: {
    local $TODO = 'Type::Params extraction not yet implemented';


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
	subtest 'Extact schema from Type::Params' => sub {
		my $module = <<'END_MODULE';
use Types::Standard qw(Str ArrayRef Bool);
use Type::Params qw(compile);

my $check = compile(
    Str,                    # username (required)
    ArrayRef[Str],           # roles (optional via slurpy/default handling)
    Bool,                    # uppercase
);

sub format_user {
    my ($username, $roles, $uppercase) = $check->(@_);

    $roles     ||= [];
    $uppercase ||= 0;

    my $name = $uppercase ? uc($username) : $username;

    return join(':', $name, @$roles);
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
}

done_testing();
