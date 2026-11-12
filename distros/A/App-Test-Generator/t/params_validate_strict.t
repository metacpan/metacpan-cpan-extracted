#!/usr/bin/env perl
use strict;
use warnings;

# use Test::DescribeMe qw(extended);
#
# No Test::Needs gate: Params::Validate::Strict is a hard PREREQ_PM of
# App::Test::Generator itself (see Makefile.PL), not an optional test
# dependency -- use_ok() below already fails loudly if it is missing.
use Test::Most;
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
subtest 'Extact schema from Params::Validate::Strict' => sub {
	my $module = <<'END_MODULE';
use Params::Validate::Strict qw(validate_strict);

sub format_user {
    my $args = validate_strict(
        args => @_,
        schema => {
            username => {
                type     => 'string',
                optional => 0,
            },
            roles => {
                type     => 'arrayref',
                optional => 1,
                default  => [],
            },
            uppercase => {
                type     => 'boolean',
                optional => 1,
                default  => 0,
            },
        }
    );

    my $name = $args->{username};
    $name = uc($name) if $args->{uppercase};

    return join(':', $name, @{ $args->{roles} });
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
			'type' => 'boolean',
			'_type_checked' => 1
		}, 'username' => {
			'type' => 'string',
			'optional' => 0,
			'_type_checked' => 1
		}, 'roles' => {
			'optional' => 1,
			'type' => 'arrayref',
			'default' => [],
			'_type_checked' => 1
		}
	});

	ok($format_user_schema->{input}{username}{_type_checked},
		'Validator-enforced parameter is marked as type-checked');

	done_testing();
};

# A validator schema built from runtime lexicals is not a description of how
# the routine is called. CGI::Info::params validates each parameter inside a
# loop with validate_strict({ schema => { $key => $schema }, ... });
# evaluating that with both lexicals undefined yields { '' => undef }, and
# accepting it gave the method an empty parameter name, which the harness
# generator refuses to turn into a Perl variable, so no harness at all could
# be generated for the routine.
subtest 'Runtime-built validator schema is not mistaken for the input spec' => sub {
	my $module = <<'END_MODULE';
use Params::Validate::Strict qw(validate_strict);

sub validate_each_env {
	my $self = shift;

	my %clean;
	foreach my $key (keys %ENV) {
		my $schema = { type => 'string', optional => 1 };
		my $value = $ENV{$key};
		eval {
			$value = validate_strict({
				schema => { $key => $schema },
				args => { $key => $value },
				unknown_parameter_handler => 'die',
			});
		};
		$clean{$key} = $value;
	}

	return \%clean;
}
END_MODULE

	my $extractor = create_extractor($module);
	my $schemas = $extractor->extract_all();

	my $schema = $schemas->{validate_each_env};
	ok($schema, 'Found method schema');

	ok(!exists($schema->{input}{''}), 'No empty parameter name invented');
	is(scalar(keys %{ $schema->{input} || {} }), 0, 'No parameters invented from the runtime schema');

	done_testing();
};

done_testing();
