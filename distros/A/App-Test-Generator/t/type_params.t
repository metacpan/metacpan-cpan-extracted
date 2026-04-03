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
	subtest 'Extact schema from Type::Params - using compiles' => sub {
		local $TODO = 'compile type of Types::Params not yet implemented';

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

	subtest 'Extact schema from Type::Params - using signature_for' => sub {
		my $module = <<'END_MODULE';
use Types::Standard qw(Num);
use Type::Params qw(-sigs);

signature_for add_numbers => (
  method      => 1,
  positional  => [ Num, Num ],
  returns     => Num
);

sub add_numbers ( $self, $first, $second ) {
	return $first + $second;
}

END_MODULE

		my $extractor = create_extractor($module);

		# Extract all schemas
		my $schemas = $extractor->extract_all();

		ok(defined($schemas));

		my $schema = $schemas->{add_numbers};
		ok($schema, 'Found add_numbers method schema');

		my $input = $schema->{input};
		ok($input, 'Found input method schema');

		cmp_deeply($input, {
			'arg0' => {
				'type' => 'number',
				'optional' => 0,
				'position' => 0,
			}, 'arg1' => {
				'type' => 'number',
				'optional' => 0,
				'position' => 1,
			}
		});

		cmp_ok($schema->{output}->{type}, 'eq', 'number', 'add_numbers returns a number');

		done_testing();
	};

	subtest 'Extact schema from Type::Params - using documented example' => sub {
		my $module = <<'END_MODULE';
use v5.36;
use builtin qw( true false );
package Horse {
  use Moo;
  use Types::Standard qw( Object );
  use Type::Params -sigs;
  use namespace::autoclean;

  # ...;   # define attributes, etc

  signature_for add_child => (
    # method     => true,
    method     => 1,
    positional => [ Object ],
  );

  sub add_child ( $self, $child ) {
    push $self->children->@*, $child;
    return $self;
  }
}
# package main;
# my $boldruler = Horse->new;
# $boldruler->add_child( Horse->new );
# $boldruler->add_child( 123 );   # dies (123 is not an Object
END_MODULE

		my $extractor = create_extractor($module);

		# Extract all schemas
		my $schemas = $extractor->extract_all();

		ok(defined($schemas));

		my $schema = $schemas->{add_child};
		ok($schema, 'Found add_child method schema');

		my $input = $schema->{input};
		ok($input, 'Found input method schema');

		cmp_deeply($input, {
			'arg0' => {
				'type' => 'object',
				'optional' => 0,
				'position' => 0,
			}
		});
		done_testing();
	};
}

done_testing();
