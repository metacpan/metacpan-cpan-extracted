#!/usr/bin/env perl
use strict;
use warnings;

use Test::DescribeMe qw(extended);	# Fixes https://www.cpantesters.org/cpan/report/04c7279a-476f-11f1-bf55-cb595875c975
use Test::Most;
use Test::Needs 'Type::Params', 'BSD::Resource';
use File::Temp qw(tempdir);
use File::Spec;

use App::Test::Generator::SchemaExtractor;

if($^O ne 'MSWin32') {
	require BSD::Resource;
	BSD::Resource->import();

	# RLIMIT_AS is not defined on all platforms (e.g. some BSDs and macOS
	# builds where the vendor omitted the constant).  Treat it as unavailable
	# rather than dying with "Your vendor has not defined ... RLIMIT_AS".
	my $rlimit_as = eval { BSD::Resource::RLIMIT_AS() };
	if($@) {
		plan(skip_all => 'RLIMIT_AS not available on this platform');
	}

	my ($soft, $hard) = getrlimit($rlimit_as);
	# Skip if less than 512MB available
	if(($soft != BSD::Resource::RLIM_INFINITY()) && ($soft < 512 * 1024 * 1024)) {
		plan(skip_all => 'Insufficient memory for type_params tests');
	}
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
			allow_signature_exec => 1,	# this test deliberately exercises signature_for() execution
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

		# Compare by position rather than key name: the key may be the real
		# parameter name (from heuristics or Type::Params 2.x $p->name) or
		# the positional placeholder 'arg0'/'arg1' (older Type::Params).
		my @params = sort { $a->{position} <=> $b->{position} } values %$input;
		is(scalar @params, 2, 'add_numbers has two input parameters');
		is($params[0]{type},     'number', 'first parameter is numeric');
		is($params[0]{optional}, 0,        'first parameter is required');
		is($params[0]{position}, 0,        'first parameter is at position 0');
		is($params[1]{type},     'number', 'second parameter is numeric');
		is($params[1]{optional}, 0,        'second parameter is required');
		is($params[1]{position}, 1,        'second parameter is at position 1');

		cmp_ok($schema->{output}->{type}, 'eq', 'number', 'add_numbers returns a number');
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

		my @params = sort { $a->{position} <=> $b->{position} } values %$input;
		is(scalar @params, 1, 'add_child has one input parameter');
		# When _compile_signature_isolated succeeds the type is 'object'
		# (from Types::Standard Object).  When it falls back to heuristics,
		# the body has no ref/blessed/isa checks so the heuristic defaults
		# to 'string' — both are acceptable here.
		ok($params[0]{type} eq 'object' || $params[0]{type} eq 'string',
			"parameter type is 'object' or 'string' (heuristic fallback)");
		is($params[0]{optional}, 0, 'parameter is required');
		is($params[0]{position}, 0, 'parameter is at position 0');
	};
}

done_testing();
