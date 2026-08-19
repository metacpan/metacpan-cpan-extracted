package App::Test::Generator::BenchmarkGenerator;

use 5.036;
use Carp qw(croak);
use Params::Get qw(get_params);
use Readonly;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.46';

Readonly my %TYPE_DEFAULTS => (
	number  => 42,
	integer => 42,
	float   => 3.14,
	string  => "'hello'",
	boolean => 1,
	arrayref => '[]',
	hashref  => '{}',
);

=head1 NAME

App::Test::Generator::BenchmarkGenerator - Generate Benchmark harnesses from ATG schemas

=head1 VERSION

Version 0.46

=head1 SYNOPSIS

    use App::Test::Generator::BenchmarkGenerator;
    use YAML::XS qw(LoadFile);

    my $schema = LoadFile('schemas/my_func.yml');
    my $bg     = App::Test::Generator::BenchmarkGenerator->new(schema => $schema);
    print $bg->generate();

=head1 DESCRIPTION

Given an ATG YAML schema (as produced by C<extract-schemas> or written by hand),
generates a self-contained Perl benchmark script using L<Benchmark/cmpthese>.

Each transform defined in the schema becomes one variant in the C<cmpthese> call,
with representative input values derived from the transform's type and range
constraints.  When no transforms are defined, a single C<'default'> variant is
emitted using the base input specification.

The generated script is a plain C<.pl> file suitable for running directly with
C<perl>.  It is not a test file and has no dependency on any test framework.

=head1 METHODS

=head2 new

Construct a new BenchmarkGenerator for a given ATG schema.

    my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => $schema);

=head3 Arguments

=over 4

=item * C<schema>

A hashref representing the parsed YAML schema for the target function, as
produced by C<extract-schemas> or written by hand.  Must contain at minimum
C<module> and C<function> keys.  Required.

=back

=head3 Returns

A blessed C<App::Test::Generator::BenchmarkGenerator> object.
Croaks if C<schema> is missing or not a hashref.

=head3 EXAMPLE

    use YAML::XS qw(LoadFile);
    use App::Test::Generator::BenchmarkGenerator;

    my $schema = LoadFile('schemas/greet.yml');
    my $bg     = App::Test::Generator::BenchmarkGenerator->new(schema => $schema);
    print $bg->generate();

=head3 MESSAGES

=over 4

=item C<schema is required>

C<schema> was not supplied or was C<undef>.

=item C<schema must be a hashref>

C<schema> was supplied but is not a plain hashref (e.g. an arrayref or string
was passed instead).

=back

=head3 API SPECIFICATION

=head4 input

    schema   => HashRef   (required) - ATG schema hashref as loaded from YAML

=head4 output

An C<App::Test::Generator::BenchmarkGenerator> object.

=head3 FORMAL SPECIFICATION

Pre:  C<defined schema ∧ ref(schema) eq 'HASH'>

Post: C<ref(result) eq 'App::Test::Generator::BenchmarkGenerator'>
      ∧ C<result-E<gt>{schema} eq schema>

=cut

sub new {
	my ($class, @args) = @_;
	my $params = get_params('schema', \@args);
	croak 'schema is required' unless defined $params->{schema};
	croak 'schema must be a hashref' unless ref $params->{schema} eq 'HASH';
	return bless { schema => $params->{schema} }, $class;
}

=head2 generate

Generate the complete benchmark script as a string.

    my $script = $bg->generate();
    write_file('benchmarks/greet.pl', $script);

=head3 Arguments

None beyond C<$self>.

=head3 Returns

A string containing the complete, self-contained Perl benchmark script
using C<Benchmark::cmpthese>.  The string is ready to write directly to a
C<.pl> file and run with C<perl>.

Croaks if the schema is missing a C<module> or C<function> key.

=head3 EXAMPLE

    my $script = $bg->generate();
    # Write to file
    open my $fh, '>', 'benchmarks/my_func.pl' or die $!;
    print $fh $script;
    close $fh;

    # Or run immediately:
    require File::Temp;
    my $tmp = File::Temp->new(SUFFIX => '.pl');
    print $tmp $script;
    system($^X, "$tmp");

=head3 MESSAGES

=over 4

=item C<schema missing module>

The schema hashref has no C<module> key.

=item C<schema missing function>

The schema hashref has no C<function> key.

=back

=head3 API SPECIFICATION

=head4 input

None (reads from the schema passed to C<new>).

=head4 output

A string containing the complete benchmark script, ready to write to a file.

=head3 FORMAL SPECIFICATION

Pre:  C<defined schema-E<gt>{module} ∧ defined schema-E<gt>{function}>

Post: C<result> is a syntactically valid Perl script
      ∧ C<result> contains exactly one C<cmpthese(...)> call
      ∧ C<|variants| == max(1, |schema-E<gt>{transforms}|)>

=head3 PSEUDOCODE

    read module, function, input, transforms from schema
    emit shebang, use strict/warnings, use Benchmark
    unless module eq 'builtin': emit use $module
    if schema has 'new' key and not builtin:
        emit my $obj = Module->new(...)
    if transforms defined and non-empty:
        for each transform: build a named variant call
    else:
        build a single 'default' variant call
    emit cmpthese($COUNT, { variant => sub { ... }, ... })

=cut

sub generate {
	my $self = $_[0];

	my $schema   = $self->{schema};
	my $module   = $schema->{module}   // croak 'schema missing module';
	my $function = $schema->{function} // croak 'schema missing function';

	unless($module eq 'builtin') {
		croak("BenchmarkGenerator: module '$module' is not a valid Perl identifier")
			unless $module =~ /^[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/;
	}
	croak("BenchmarkGenerator: function '$function' is not a valid Perl identifier")
		unless $function =~ /^[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/;
	my $has_new  = exists $schema->{new};
	my %input    = %{ $schema->{input} // {} };
	my %xforms   = %{ $schema->{transforms} // {} };

	my $is_builtin = ($module eq 'builtin');

	my @lines;

	push @lines,
		'#!/usr/bin/env perl',
		"# Benchmark for $function (" . ($is_builtin ? 'builtin' : "module: $module") . ')',
		'# Generated by benchmark-generator (App::Test::Generator ' . $VERSION . ')',
		'# DO NOT EDIT -- regenerate with: benchmark-generator -i SCHEMA.yml',
		q{},
		'use strict;',
		'use warnings;',
		'use Benchmark qw(cmpthese);';

	unless($is_builtin) {
		push @lines, "use $module;";
	}

	push @lines,
		q{},
		'my $COUNT = -3;    # seconds per variant (negative = time-based)',
		q{};

	if($has_new && !$is_builtin) {
		my $new_spec = $schema->{new};
		if(ref $new_spec eq 'HASH' && %$new_spec) {
			my $args = join(', ', map { "$_ => " . _quote_value($new_spec->{$_}) } sort keys %$new_spec);
			push @lines, "my \$obj = ${module}->new($args);";
		} else {
			push @lines, "my \$obj = ${module}->new();";
		}
		push @lines, q{};
	}

	push @lines, "printf \"Benchmarking ${function}\\n\\n\";", q{};

	my %variants;
	if(%xforms) {
		for my $name (sort keys %xforms) {
			my %xinput = %{ $xforms{$name}{input} // \%input };
			$variants{$name} = _build_call($module, $function, $has_new, \%xinput);
		}
	} else {
		$variants{'default'} = _build_call($module, $function, $has_new, \%input);
	}

	push @lines, 'cmpthese($COUNT, {';
	my $name_width = length((sort { length($b) <=> length($a) } keys %variants)[0]);
	for my $name (sort keys %variants) {
		my $padded = sprintf "%-*s", $name_width, "'$name'";
		push @lines, "\t$padded => sub { $variants{$name} },";
	}
	push @lines, '});', q{};

	return join("\n", @lines);
}

# --------------------------------------------------
# _build_call
#
# Purpose:    Build the Perl expression that calls the target function
#             with representative values derived from the input spec.
#
# Entry:      $module   - module name string
#             $function - function/method name
#             $has_new  - true if schema has 'new:' key (OOP call)
#             $input    - hashref of param name → spec
#
# Exit:       Returns a Perl expression string suitable for use inside
#             an anonymous sub in a cmpthese() call.
# --------------------------------------------------
sub _build_call {
	my ($module, $function, $has_new, $input) = @_;

	my $has_positions = grep { defined $_->{position} } values %$input;
	my $call;

	if($has_positions) {
		my @positional = sort { $a->{position} <=> $b->{position} }
		                 grep { defined $_->{position} }
		                 values %$input;
		my $args = join(', ', map { _representative_value($_) } @positional);
		$call = $has_new ? "\$obj->$function($args)"
		                 : ($module eq 'builtin' ? "$function($args)"
		                                         : "${module}::$function($args)");
	} else {
		my @pairs = map { "$_ => " . _representative_value($input->{$_}) }
		            sort keys %$input;
		my $args = join(', ', @pairs);
		$call = $has_new ? "\$obj->$function($args)"
		                 : "${module}::$function($args)";
	}

	return $call;
}

# --------------------------------------------------
# _representative_value
#
# Purpose:    Return a Perl literal string that is a plausible representative
#             value for a parameter given its schema spec.  The choice is
#             informed by type, min, max, and enum constraints.
#
# Entry:      $spec - hashref with at minimum a 'type' key
#
# Exit:       Returns a Perl literal string (e.g. '42', "'hello'", 'undef').
# --------------------------------------------------
sub _representative_value {
	my ($spec) = @_;
	return 'undef' unless defined $spec;

	my $type = lc($spec->{type} // 'string');

	if($type eq 'number' || $type eq 'integer' || $type eq 'float') {
		my $min = $spec->{min};
		my $max = $spec->{max};
		my $default = $TYPE_DEFAULTS{$type} // 42;
		if(defined $min && looks_like_number($min) && defined $max && looks_like_number($max)) {
			return int(($min + $max) / 2);
		}
		if(defined $min && looks_like_number($min)) {
			# pick the type default if it already satisfies >= min, else min+1
			return $default > $min ? $default : $min + 1;
		}
		if(defined $max && looks_like_number($max)) {
			# pick the type default if it already satisfies <= max, else max-1
			return $default < $max ? $default : $max - 1;
		}
		return $default;
	}

	return $TYPE_DEFAULTS{$type} // "'value'";
}

# --------------------------------------------------
# _quote_value
#
# Purpose:    Quote a scalar value for use in generated Perl source.
#
# Entry:      $v - scalar value (undef, number, or string)
#
# Exit:       Returns a Perl literal string.
# --------------------------------------------------
sub _quote_value {
	my ($v) = @_;
	return 'undef' unless defined $v;
	return $v if looks_like_number($v);
	(my $escaped = $v) =~ s/'/\\'/g;
	return "'$escaped'";
}

=head1 COMMON PITFALLS

=over 4

=item Schema missing C<module> or C<function>

C<generate> croaks immediately if either key is absent.  Always ensure the
schema has been loaded from a valid ATG YAML file before calling C<generate>.

=item Expecting test-framework output

The generated script uses C<Benchmark::cmpthese> and prints timing results to
STDOUT.  It is B<not> a test file and produces no TAP output.  Do not run it
with C<prove>.

=item OOP schemas need a C<new:> key

If the function under benchmark is an instance method, the schema must have a
C<new:> key (even if its value is an empty hashref C<{}>) so C<generate> emits
a C<my $obj = Module->new(...)> constructor call before the C<cmpthese> block.
Without it, the variant calls use C<Module::function(...)> form.

=item Transforms that omit the C<input> key

If a transform's hashref has no C<input> key, C<generate> falls back to the
base schema C<input> spec for that variant.  This is intentional but may
produce identical argument lists across variants if you forgot to add per-
transform input overrides.

=back

=head1 LIMITATIONS

=over 4

=item Representative values are heuristic

C<_representative_value> picks a single value based on type and C<min>/C<max>
constraints.  It does not guarantee the chosen value exercises any particular
code path, and it does not use the schema's C<enum> or C<matches> keys.

=item No round-trip with C<extract-schemas>

The generator reads any conforming ATG YAML schema, but it does not verify
that the schema accurately describes the actual function's signature.  If the
schema is stale, the generated benchmark may pass wrong argument types.

=back

=head1 SEE ALSO

=over 4

=item L<Benchmark>

=item C<bin/benchmark-generator>

=item L<App::Test::Generator>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut

1;
