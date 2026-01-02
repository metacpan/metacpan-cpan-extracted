package App::Test::Generator::SchemaExtractor;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(carp croak);
use Data::Dumper;	# For debugging
use PPI;
use Pod::Simple::Text;
use YAML::XS;
use File::Basename;
use File::Path qw(make_path);
use Safe;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.25';

# Configure YAML::XS to not quote numeric strings
$YAML::XS::QuoteNumericStrings = 0;

=head1 NAME

App::Test::Generator::SchemaExtractor - Extract test schemas from Perl modules

=head1 VERSION

Version 0.25

=head1 SYNOPSIS

	use App::Test::Generator::SchemaExtractor;

	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => 'lib/MyModule.pm',
		output_dir => 'schemas/',
		verbose	=> 1,
	);

	my $schemas = $extractor->extract_all();

=head1 DESCRIPTION

App::Test::Generator::SchemaExtractor analyzes Perl modules and generates
structured YAML schema files suitable for automated test generation by L<App::Test::Generator>.
This module employs
static analysis techniques to infer parameter types, constraints, and
method behaviors directly from your source code.

=head2 Analysis Methods

The extractor combines multiple analysis approaches for comprehensive schema generation:

=over 4

=item * B<POD Documentation Analysis>

Parses embedded documentation to extract:
  - Parameter names, types, and descriptions from =head2 sections
  - Method signatures with positional parameters
  - Return value specifications from "Returns:" sections
  - Constraints (ranges, patterns, required/optional status)
  - Semantic type detection (email, URL, filename)

=item * B<Code Pattern Detection>

Analyzes source code using PPI to identify:
  - Method signatures and parameter extraction patterns
  - Type validation (ref(), isa(), blessed())
  - Constraint patterns (length checks, numeric comparisons, regex matches)
  - Return statement analysis and value type inference
  - Object instantiation requirements and accessor methods

=item * B<Signature Analysis>

Examines method declarations for:
  - Parameter names and positional information
  - Instance vs. class method detection
  - Method modifiers (Moose-style before/after/around)
  - Various parameter declaration styles (shift, @_ assignment)

=item * B<Heuristic Inference>

Applies Perl-specific domain knowledge:
  - Boolean return detection from method names (is_*, has_*, can_*)
  - Common Perl idioms and coding patterns
  - Context awareness (scalar vs list, wantarray usage)
  - Object-oriented patterns (constructors, accessors, chaining)

=back

=head2 Generated Schema Structure

The extracted schemas follow this YAML structure:

    function: method_name
    module: Package::Name
    input:
      param1:
        type: string
        min: 3
        max: 50
        optional: 0
        position: 0
      param2:
        type: integer
        min: 0
        max: 100
        optional: 1
        position: 1
    output:
      type: boolean
      value: 1
    new: Package::Name # if object instantiation required
    config:
      test_empty: 1
      test_nuls: 0
      test_undef: 0
      test_non_ascii: 0

=head2 Advanced Detection Capabilities

=over 4

=item * B<Accessor Method Detection>

Automatically identifies getter, setter, and combined accessor methods
by analyzing common patterns like C<return $self-E<gt>{field}> and
C<$self-E<gt>{field} = $value>.

=item * B<Boolean Return Inference>

Detects boolean-returning methods through multiple signals:
  - Method name patterns (is_*, has_*, can_*)
  - Return patterns (consistent 1/0 returns)
  - POD descriptions ("returns true on success")
  - Ternary operators with boolean results

=item * B<Context Awareness>

Identifies methods that use C<wantarray> and can return different
values in scalar vs list context.

=item * B<Object Lifecycle Management>

Detects instance methods requiring object instantiation and
automatically adds the C<new> field to schemas.

=item * B<Enhanced Object Detection>

The extractor includes sophisticated object detection capabilities that go beyond simple instance method identification:

=over 4

=item * B<Factory Method Recognition>

Automatically identifies methods that create and return object instances, such as methods named C<create_*>, C<make_*>, C<build_*>, or C<get_*>. Factory methods are correctly classified as class methods that don't require pre-existing objects for testing.

=item * B<Singleton Pattern Detection>

Recognizes singleton patterns through multiple signals: method names like C<instance> or C<get_instance>, static variables holding instance references, lazy initialization patterns (C<$instance ||= new()>), and consistent return of the same instance variable.

=item * B<Constructor Parameter Analysis>

Examines C<new> methods to determine required and optional parameters, validation requirements, and default values. This enables test generators to provide appropriate constructor arguments when object instantiation is needed.

=item * B<Inheritance Relationship Handling>

Detects parent classes through C<use parent>, C<use base>, and C<@ISA> declarations. Identifies when methods use C<SUPER::> calls and determines whether the current class or a parent class constructor should be used for object instantiation.

=item * B<External Object Dependency Detection>

Identifies when methods create or depend on objects from other classes, enabling proper test setup with mock objects or real dependencies.

=back

These enhancements ensure that generated test schemas accurately reflect the object-oriented structure of the code, leading to more meaningful and effective test generation.

=back

=head2 Confidence Scoring

Each generated schema includes detailed confidence assessments:

=over 4

=item * B<High Confidence>

Multiple independent analysis sources converge on consistent,
well-constrained parameters with explicit validation logic and
comprehensive documentation.

=item * B<Medium Confidence>

Reasonable evidence from code patterns or partial documentation,
but may lack comprehensive constraints or have some ambiguities.

=item * B<Low Confidence>

Minimal evidence - primarily based on naming conventions,
default assumptions, or single-source analysis.

=item * B<Very Low Confidence>

Barely any detectable signals - schema should be thoroughly
reviewed before use in test generation.

=back

=head2 Use Cases

=over 4

=item * B<Automated Test Generation>

Generate comprehensive test suites with L<App::Test::Generator> using
extracted schemas as input. The schemas provide the necessary structure
for generating both positive and negative test cases.

=item * B<API Documentation Generation>

Supplement existing documentation with automatically inferred interface
specifications, parameter requirements, and return types.

=item * B<Code Quality Assessment>

Identify methods with poor documentation, inconsistent parameter handling,
or unclear interfaces that may benefit from refactoring.

=item * B<Refactoring Assistance>

Detect method dependencies, object instantiation requirements, and
parameter usage patterns to inform refactoring decisions.

=item * B<Legacy Code Analysis>

Quickly understand the interface contracts of legacy Perl codebases
without extensive manual code reading.

=back

=head2 Integration with Testing Ecosystem

The generated schemas are specifically designed to work with the
L<App::Test::Generator> ecosystem:

    # Extract schemas from your module
    my $extractor = App::Test::Generator::SchemaExtractor->new(...);
    my $schemas = $extractor->extract_all();

    # Use with test generator (typically as separate steps)
    # fuzz-harness-generator -r schemas/method_name.yml

=head2 Limitations and Considerations

=over 4

=item * B<Dynamic Code Patterns>

Highly dynamic code (string evals, AUTOLOAD, symbolic references)
may not be fully detected by static analysis.

=item * B<Complex Validation Logic>

Sophisticated validation involving multiple parameters or external
dependencies may require manual schema refinement.

=item * B<Confidence Heuristics>

Confidence scores are based on heuristics and should be reviewed
by developers familiar with the codebase.

=item * B<Perl Idiom Recognition>

Some Perl-specific idioms may require custom pattern recognition
beyond the built-in detectors.

=item * B<Documentation Dependency>

Analysis quality improves significantly with comprehensive POD
documentation following consistent patterns.

=back

=head2 Best Practices for Optimal Results

=over 4

=item * B<Comprehensive POD Documentation>

Write detailed POD with explicit parameter documentation using
consistent patterns like C<$param - type (constraints), description>.

=item * B<Consistent Coding Patterns>

Use consistent parameter validation patterns and method signatures
throughout your codebase.

=item * B<Schema Review Process>

Review and refine automatically generated schemas, particularly
those with low confidence scores.

=item * B<Descriptive Naming>

Use descriptive method and parameter names that clearly indicate
purpose and expected types.

=item * B<Progressive Enhancement>

Start with automatically generated schemas and progressively
refine them based on test results and code understanding.

=back

The module is particularly valuable for large codebases where manual schema
creation would be prohibitively time-consuming, and for maintaining test
coverage as code evolves through continuous integration pipelines.

=head2 Advanced Type Detection

The schema extractor includes enhanced type detection capabilities that identify specialized Perl types beyond basic strings and integers.
L<DateTime> and L<Time::Piece> objects are detected through isa() checks and method call patterns, while date strings (ISO 8601, YYYY-MM-DD) and UNIX timestamps are recognized through regex validation and numeric range checks.
File handles and file paths are identified via I/O operations and file test operators, coderefs are detected through ref() checks and invocation patterns, and enum-like parameters are extracted from validation code including regex patterns (C</^(a|b|c)$/>), hash lookups, grep statements, and if/elsif chains.
These detected types are preserved in the generated YAML schemas with appropriate semantic annotations, enabling test generators to create more accurate and meaningful test cases.

=head3 Example Advanced Type Schema

For a method like:

    sub process_event {
        my ($self, $timestamp, $status, $callback) = @_;
        croak unless $timestamp > 1000000000;
        croak unless $status =~ /^(active|pending|complete)$/;
        croak unless ref($callback) eq 'CODE';
        $callback->($timestamp, $status);
    }

The extractor generates:

    ---
    function: process_event
    module: MyModule
    input:
      timestamp:
        type: integer
        # min: 0
        # max: 2147483647
        position: 0
        _note: Unix timestamp
	semantic: unix_timestamp
      status:
        type: string
        enum:
          - active
          - pending
          - complete
        position: 1
        _note: 'Must be one of: active, pending, complete'
      callback:
        type: coderef
        position: 2
        _note: 'CODE reference - provide sub { } in tests'

=head1 RELATIONSHIP DETECTION

The schema extractor detects relationships and dependencies between parameters,
enabling more sophisticated validation and test generation.

=head2 Relationship Types

=over 4

=item * B<mutually_exclusive>

Parameters that cannot be used together.

    die if $file && $content;  # Can't specify both

Generated schema:

    relationships:
      - type: mutually_exclusive
        params: [file, content]
        description: Cannot specify both file and content

=item * B<required_group>

At least one parameter from the group must be specified (OR logic).

    die unless $id || $name;  # Must provide one

Generated schema:

    relationships:
      - type: required_group
        params: [id, name]
        logic: or
        description: Must specify either id or name

=item * B<conditional_requirement>

If one parameter is specified, another becomes required (IF-THEN logic).

    die if $async && !$callback;  # async requires callback

Generated schema:

    relationships:
      - type: conditional_requirement
        if: async
        then_required: callback
        description: When async is specified, callback is required

=item * B<dependency>

One parameter depends on another being present.

    die "Port requires host" if $port && !$host;

Generated schema:

    relationships:
      - type: dependency
        param: port
        requires: host
        description: port requires host to be specified

=item * B<value_constraint>

Specific value requirements between parameters.

    die if $ssl && $port != 443;  # ssl requires port 443

Generated schema:

    relationships:
      - type: value_constraint
        if: ssl
        then: port
        operator: ==
        value: 443
        description: When ssl is specified, port must equal 443

=item * B<value_conditional>

Parameter required when another has a specific value.

    die if $mode eq 'secure' && !$key;

Generated schema:

    relationships:
      - type: value_conditional
        if: mode
        equals: secure
        then_required: key
        description: When mode equals 'secure', key is required

=back

=head2 Default Value Extraction

The extractor comprehensively extracts default values from both code and POD documentation:

=head3 Code Pattern Recognition

Extracts defaults from multiple Perl idioms:

=over 4

=item * Logical OR operator: C<$param = $param || 'default'>

=item * Defined-or operator: C<$param //= 'default'>

=item * Ternary operator: C<$param = defined $param ? $param : 'default'>

=item * Unless conditional: C<$param = 'default' unless defined $param>

=item * Chained defaults: C<$param = $param || $self->{default} || 'fallback'>

=item * Multi-line patterns: C<$param = {} unless $param>

=back

=head3 POD Pattern Recognition

Extracts defaults from documentation:

=over 4

=item * Standard format: C<Default: 'value'>

=item * Alternative format: C<Defaults to: 'value'>

=item * Inline format: C<Optional, default: 'value'>

=item * Parameter lists: C<$param - type, default 'value'>

=back

=head3 Value Processing

Properly handles:

=over 4

=item * String literals with quotes and escape sequences

=item * Numeric values (integers and floats)

=item * Boolean values (true/false converted to 1/0)

=item * Empty data structures ([] and {})

=item * Special values (undef, __PACKAGE__)

=item * Complex expressions (preserved as-is when unevaluatable)

=item * Quote operators (q{}, qq{}, qw{})

=back

=head3 Type Inference

When a parameter has a default value but no explicit type annotation,
the type is automatically inferred from the default:

    $options = {}        # inferred as hashref
    $items = []          # inferred as arrayref
    $count = 42          # inferred as integer
    $ratio = 3.14        # inferred as number
    $enabled = 1         # inferred as boolean

=head2 Context-Aware Return Analysis

The extractor provides comprehensive analysis of method return behavior,
including context sensitivity, error handling conventions, and method chaining patterns.

=head3 List vs Scalar Context Detection

Automatically detects methods that return different values based on calling context:

    sub get_items {
        my ($self) = @_;
        return wantarray ? @items : scalar(@items);
    }

Detection captures:

=over 4

=item * C<context_aware> flag - Method uses wantarray

=item * C<list_context> - Type returned in list context (e.g., 'array')

=item * C<scalar_context> - Type returned in scalar context (e.g., 'integer')

=back

Recognizes both ternary operator patterns and conditional return patterns.

=head3 Void Context Methods

Identifies methods that don't return meaningful values:

=over 4

=item * Setters (C<set_*> methods)

=item * Mutators (C<add_*, remove_*, delete_*, clear_*, reset_*, update_*>)

=item * Loggers (C<log, debug, warn, error, info>)

=item * Methods with only empty returns

=back

Example:

    sub set_name {
        my ($self, $name) = @_;
        $self->{name} = $name;
        return;  # Void context
    }

Sets C<void_context> flag and C<type =E<gt> 'void'>.

=head3 Method Chaining Detection

Identifies chainable methods that return C<$self> for fluent interfaces:

    sub set_width {
        my ($self, $width) = @_;
        $self->{width} = $width;
        return $self;  # Chainable
    }

Detection provides:

=over 4

=item * C<returns_self> - Returns invocant for chaining

=item * C<class> - The class name being returned

=back

Also detects chaining documentation in POD (keywords: "chainable", "fluent interface",
"returns self", "method chaining").

=head3 Error Return Conventions

Analyzes how methods signal errors:

B<Pattern Detection:>

=over 4

=item * C<undef_on_error> - Explicit C<return undef if/unless condition>

=item * C<implicit_undef> - Bare C<return if/unless condition>

=item * C<empty_list> - C<return ()> for list context errors

=item * C<zero_on_error> - Returns 0/false for boolean error indication

=item * C<exception_handling> - Uses eval blocks with error checking

=back

B<Example Analysis:>

    sub fetch_user {
        my ($self, $id) = @_;

        return undef unless $id;        # undef_on_error
        return undef if $id < 0;        # undef_on_error

        return $self->{users}{$id};
    }

Results in:

    error_return: 'undef'
    success_failure_pattern: 1
    error_handling: {
        undef_on_error: ['$id', '$id < 0']
    }

B<Success/Failure Pattern:>

Methods that return different types for success vs. failure are flagged with
C<success_failure_pattern>. Common patterns:

=over 4

=item * Returns value on success, undef on failure

=item * Returns true on success, false on failure

=item * Returns data on success, empty list on failure

=back

=head3 Success Indicator Detection

Methods that always return true (typically for side effects):

    sub update_status {
        my ($self, $status) = @_;
        $self->{status} = $status;
        return 1;  # Success indicator
    }

Sets C<_success_indicator> flag when method consistently returns 1.

=head3 Schema Output

Enhanced return analysis adds these fields to method schemas:

    output:
      type: boolean              # Inferred return type
      context_aware: 1           # Uses wantarray
      list_context:
        type: array
      scalar_context:
        type: integer
      returns_self: 1               # Returns $self
      void_context: 1            # No meaningful return
      _success_indicator: 1       # Always returns true
      error_return: undef        # How errors are signaled
      success_failure_pattern: 1 # Mixed return types
      error_handling:            # Detailed error patterns
        undef_on_error: [...]
        exception_handling: 1

This comprehensive analysis enables:

=over 4

=item * Better test generation (testing both contexts, error paths)

=item * Documentation generation (clear error conventions)

=item * API design validation (consistent error handling)

=item * Contract specification (precise return behavior)

=back

=head2 Example

For a method like:

    sub connect {
        my ($self, $host, $port, $ssl, $file, $content) = @_;

        die if $file && $content;                    # mutually exclusive
        die unless $host || $file;                   # required group
        die "Port requires host" if $port && !$host; # dependency
        die if $ssl && $port != 443;                 # value constraint

        # ... connection logic
    }

The extractor generates:

    relationships:
      - type: mutually_exclusive
        params: [file, content]
        description: Cannot specify both file and content
      - type: required_group
        params: [host, file]
        logic: or
        description: Must specify either host or file
      - type: dependency
        param: port
        requires: host
        description: port requires host to be specified
      - type: value_constraint
        if: ssl
        then: port
        operator: ==
        value: 443
        description: When ssl is specified, port must equal 443

=head1 MODERN PERL FEATURES

This module adds support for:

=head2 Subroutine Signatures (Perl 5.20+)

    sub connect($host, $port = 3306, %options) {
        ...
    }

Extracts: required params, optional params with defaults, slurpy params

=head2 Type Constraints (Perl 5.36+)

    sub calculate($x :Int, $y :Num) {
        ...
    }

Recognizes: Int, Num, Str, Bool, ArrayRef, HashRef, custom classes

=head3 Subroutine Attributes

    sub get_value :lvalue :Returns(Int) {
        ...
    }

Detects: :lvalue, :method, :Returns(Type), custom attributes

=head2 Postfix Dereferencing (Perl 5.20+)

    my @array = $arrayref->@*;
    my %hash = $hashref->%*;
    my @slice = $arrayref->@[1,3,5];

Tracks usage of modern dereferencing syntax

=head2 Field Declarations (Perl 5.38+)

    field $host :param = 'localhost';
    field $port :param(port_number) = 3306;
    field $logger :param :isa(Log::Any);

Extracts fields and maps them to parameters

=head2 Modern Perl Features Support

The schema extractor supports modern Perl syntax introduced in versions 5.20, 5.36, and 5.38+.

=head3 Subroutine Signatures (Perl 5.20+)

Automatically extracts parameters from native Perl signatures:

    use feature 'signatures';

    sub connect($host, $port = 3306, $database = undef) {
        ...
    }

Extracted schema includes:

=over 4

=item * Parameter positions

=item * Optional vs required parameters

=item * Default values from signature

=item * Slurpy parameters (@array, %hash)

=back

B<Example:>

    # Signature with defaults
    sub process($file, %options) { ... }

    # Extracts:
    # $file: position 0, required
    # %options: position 1, optional, slurpy hash

=head3 Type Constraints in Signatures (Perl 5.36+)

Recognizes type constraints in signature parameters:

    sub calculate($x :Int, $y :Num, $name :Str = "result") {
        return $x + $y;
    }

Supported constraint types:

=over 4

=item * C<:Int, :Integer> -> integer

=item * C<:Num, :Number> -> number

=item * C<:Str, :String> -> string

=item * C<:Bool, :Boolean> -> boolean

=item * C<:ArrayRef, :Array> -> arrayref

=item * C<:HashRef, :Hash> -> hashref

=item * C<:ClassName> -> object with isa constraint

=back

Type constraints are combined with defaults when both are present.

=head3 Subroutine Attributes

Extracts and documents subroutine attributes:

    sub get_value :lvalue {
        my $self = shift;
        return $self->{value};
    }

    sub calculate :Returns(Int) :method {
        my ($self, $x, $y) = @_;
        return $x + $y;
    }

Recognized attributes stored in C<_attributes> field:

=over 4

=item * C<:lvalue> - Method can be assigned to

=item * C<:method> - Explicitly marked as method

=item * C<:Returns(Type)> - Declares return type

=item * Custom attributes with values: C<:MyAttr(value)>

=back

=head3 Postfix Dereferencing (Perl 5.20+)

Detects usage of postfix dereferencing syntax:

    use feature 'postderef';

    sub process_array {
        my ($self, $arrayref) = @_;
        my @array = $arrayref->@*;        # Array dereference
        my @slice = $arrayref->@[1,3,5];  # Array slice
        return @array;
    }

    sub process_hash {
        my ($self, $hashref) = @_;
        my %hash = $hashref->%*;          # Hash dereference
        return keys %hash;
    }

Tracked features stored in C<_modern_features>:

=over 4

=item * C<array_deref> - Uses C<-E<gt>@*>

=item * C<hash_deref> - Uses C<-E<gt>%*>

=item * C<scalar_deref> - Uses C<-E<gt>$*>

=item * C<code_deref> - Uses C<-E<gt>&*>

=item * C<array_slice> - Uses C<-E<gt>@[...]>

=item * C<hash_slice> - Uses C<-E<gt>%{...}>

=back

=head3 Field Declarations (Perl 5.38+)

Extracts field declarations from class syntax and maps them to method parameters:

    use feature 'class';

    class DatabaseConnection {
        field $host :param = 'localhost';
        field $port :param = 3306;
        field $username :param(user);
        field $password :param;
        field $logger :param :isa(Log::Any);

        method connect() {
            # Fields available as instance variables
        }
    }

Field attributes:

=over 4

=item * C<:param> - Field is a constructor parameter (uses field name)

=item * C<:param(name)> - Field maps to parameter with different name

=item * C<:isa(Class)> - Type constraint for the field

=item * Default values in field declarations

=back

Extracted schema includes both field information in C<_fields> and merged parameter
information in C<input>, allowing proper validation of class constructors.

=head3 Mixed Modern and Traditional Syntax

The extractor handles code that mixes modern and traditional syntax:

    sub modern($x, $y = 5) {
        # Modern signature with default
    }

    sub traditional {
        my ($self, $x, $y) = @_;
        $y //= 5;  # Traditional default in code
        # Both extract same parameter information
    }

Priority order for parameter information:

=over 4

=item 1. Signature declarations (highest priority)

=item 2. Field declarations (for class methods)

=item 3. POD documentation

=item 4. Code analysis (lowest priority)

=back

This ensures that explicit declarations in signatures take precedence over
inferred information from code analysis.

=head3 Backwards Compatibility

All modern Perl feature detection is optional and automatic:

=over 4

=item * Traditional C<sub> declarations continue to work

=item * Code without modern features extracts parameters as before

=item * Modern features are additive - they enhance rather than replace existing extraction

=item * Schemas include C<_source> field indicating where parameter info came from

=back

=head2 _yamltest_hints

Each method schema returned by L</extract_all> now optionally includes a
C<_yamltest_hints> key, which provides guidance for automated test generation
based on the code analysis.

This is intended to help L<App::Test::Generator> create meaningful tests,
including boundary and invalid input cases, without manually specifying them.

The structure is a hashref with the following keys:

=over 4

=item * boundary_values

An arrayref of numeric values that represent boundaries detected from
comparisons in the code. These are derived from literals in statements
like C<$x < 0> or C<$y >= 255>. The generator can use these to create
boundary tests.

Example:

    _yamltest_hints:
      boundary_values: [0, 1, 100, 255]

=item * invalid_inputs

An arrayref of values that are likely to be rejected by the method,
based on checks like C<defined>, empty strings, or numeric validations.

Example:

    _yamltest_hints:
      invalid_inputs: [undef, '', -1]

=item * equivalence_classes

An arrayref intended to capture detected equivalence classes or patterns
among inputs. Currently this is empty by default, but future enhancements
may populate it based on detected input groupings.

Example:

    _yamltest_hints:
      equivalence_classes: []

=back

=head3 Usage

When calling C<extract_all>, each method schema will include
C<_yamltest_hints> if any hints were detected:

    my $schemas = $extractor->extract_all;
    my $hints  = $schemas->{example_method}->{_yamltest_hints};

You can then feed these hints into automated test generators to produce
negative tests, boundary tests, and parameter-specific test cases.

=head3 Notes

=over 4

=item * Hints are inferred heuristically from code and validation statements.

=item * Not all inputs are guaranteed to be detected; the feature is additive
and will never remove information from the schema.

=item * Currently, equivalence classes are not populated, but the field exists
for future extension.

=item * Boundary and invalid input hints are deduplicated to avoid repeated
test values.

=back

=head3 Examples

Given a method like:

    sub example {
        my ($x) = @_;
        die "negative" if $x < 0;
        return unless defined($x);
        return $x * 2;
    }

After running:

    my $extractor = App::Test::Generator::SchemaExtractor->new(
        input_file => 'TestHints.pm',
        output_dir => '/tmp',
        quiet      => 1,
    );

    my $schemas = $extractor->extract_all;

The schema for the method "example" will include:

    $schemas->{example} = {
        function => 'example',
        _confidence => {
            input  => 'unknown',
            output => 'unknown',
        },
        input => {
            x => {
                type     => 'scalar',
                optional => 0,
            }
        },
        output => {
            type => 'scalar',
        },
        _yamltest_hints => {
            boundary_values => [0, 1],
            invalid_inputs  => [undef, -1],
            equivalence_classes => [],
        },
        _notes => '...',
        _analysis => {
            input_confidence  => 'low',
            output_confidence => 'unknown',
            confidence_factors => {
                input  => {...},
                output => {...},
            },
            overall_confidence => 'low',
        },
        _fields => {},
        _modern_features => {},
        _attributes => {},
    };

=head1 METHODS

=head2 new

Private methods are not included, unless C<include_private> is used in C<new()>.

The extractor supports several configuration parameters:

    my $extractor = App::Test::Generator::SchemaExtractor->new(
        input_file          => 'lib/MyModule.pm',  # Required
        output_dir          => 'schemas/',         # Default: 'schemas'
        verbose             => 1,                  # Default: 0
        include_private     => 1,                  # Default: 0
        max_parameters      => 50,                 # Default: 20
        confidence_threshold => 0.7,               # Default: 0.5
    );

=cut

sub new {
	my ($class, %args) = @_;

	my $self = {
		input_file => ($args{input_file} || die 'input_file required'),
		output_dir => $args{output_dir} || 'schemas',
		verbose	=> $args{verbose} || 0,
		confidence_threshold => $args{confidence_threshold} || 0.5,
		include_private => $args{include_private} || 0,	# include _private methods
		max_parameters => $args{max_parameters} || 20,	# safety limit
	};

	# Validate input file exists
	unless (-f $self->{input_file}) {
		croak(__PACKAGE__, ": Input file '$self->{input_file}' does not exist");
	}

	return bless $self, $class;
}

=head2 extract_all

Extract schemas for all methods in the module.

Returns a hashref of method_name => schema.

=head3 Pseudo Code

  FOREACH method
  DO
	analyze the method
	write a schema file for that method
  END

=cut

sub extract_all {
	my $self = $_[0];

	$self->_log("Parsing $self->{input_file}...");

	my $document = PPI::Document->new($self->{input_file}) or die "Failed to parse $self->{input_file}: $!";

	# Store document for later use
	$self->{_document} = $document;

	my $package_name = $self->_extract_package_name($document);
	$self->_log("Package: $package_name");

	my $methods = $self->_find_methods($document);
	$self->_log("Found " . scalar(@$methods) . ' methods');

	my %schemas;
	foreach my $method (@{$methods}) {
		$self->_log("\nAnalyzing method: $method->{name}");

		my $schema = $self->_analyze_method($method);
		$schemas{$method->{name}} = $schema;
		$schema->{'module'} = $package_name;

		# Write individual schema file
		$self->_write_schema($method->{name}, $schema);
	}

	return \%schemas;
}

=head2 _extract_package_name

Extract the package name from the document.

=cut

sub _extract_package_name {
	my ($self, $document) = @_;

	if(!defined($document)) {
		$document = $self->{_document};
	}
	my $package_stmt = $document->find_first('PPI::Statement::Package');
	return $package_stmt ? $package_stmt->namespace : 'Unknown';
}

=head2 _find_methods

Find all subroutines/methods in the document.

Returns an arrayref of hashrefs with the structure:
  { name => $name, node => $ppi_node, body => $code_text }

=cut

sub _find_methods {
	my ($self, $document) = @_;

	my $subs = $document->find('PPI::Statement::Sub') || [];
	my $sub_decls = $document->find('PPI::Statement::Scheduled') || []; # for method modifiers

	my @methods;
	foreach my $sub (@$subs) {
		my $name = $sub->name();

		# Skip private methods unless explicitly included, or they're special
		if ($name =~ /^_/ && $name !~ /^_(new|init|build)/) {
			next unless $self->{include_private};
		}

		# Get the POD before this sub
		my $pod = $self->_extract_pod_before($sub);

		push @methods, {
			name => $name,
			node => $sub,
			body => $sub->content(),
			pod => $pod,
			type => 'sub',
		};
	}

	# Look for class { method } syntax (Perl 5.38+)
	my $content = $document->content();
	if ($content =~ /\bclass\b/) {
		$self->_log("  Detecting class/method syntax...");
		$self->_extract_class_methods($content, \@methods);
	}

	# Process method modifiers (Moose)
	foreach my $decl (@$sub_decls) {
		my $content = $decl->content;
		if ($content =~ /^(before|after|around)\s+['"]?(\w+)['"]?\s*/) {
			my ($modifier, $method_name) = ($1, $2);
			my $full_name = "${modifier}_$method_name";

			# Look for the actual sub definition that follows
			my $next_sib = $decl->next_sibling;
			while ($next_sib && !$next_sib->isa('PPI::Statement::Sub')) {
				$next_sib = $next_sib->next_sibling;
			}

			if ($next_sib && $next_sib->isa('PPI::Statement::Sub')) {
				my $pod = $self->_extract_pod_before($decl); # POD might be before modifier
				push @methods, {
					name => $full_name,
					node => $next_sib,
					body => $next_sib->content,
					pod => $pod,
					type => 'modifier',
					original_method => $method_name,
					modifier => $modifier,
				};
				$self->_log("  Found method modifier: $full_name");
			}
		}
	}

	return \@methods;
}

sub _extract_class_methods {
	my ($self, $content, $methods) = @_;

	# Simple pattern: find "class Name {" blocks
	# This won't handle all edge cases but will work for simple classes
	while ($content =~ /class\s+(\w+)\s*\{/g) {
		my $class_name = $1;
		my $start_pos = pos($content);

		# Find the matching closing brace (simple brace counting)
		my $depth = 1;
		my $class_end = $start_pos;

		while ($depth > 0 && $class_end < length($content)) {
			my $char = substr($content, $class_end, 1);
			$depth++ if $char eq '{';
			$depth-- if $char eq '}';
			$class_end++;
		}

		my $class_body = substr($content, $start_pos, $class_end - $start_pos - 1);

		$self->_log("  Found class $class_name");

		# Extract field declarations from class
		my $fields = $self->_extract_field_declarations($class_body);

		# Find methods in the class body
		while ($class_body =~ /method\s+(\w+)\s*(\([^)]*\))?\s*\{/g) {
			my ($method_name, $sig_with_parens) = ($1, $2 || '()');

			# Skip private unless configured
			if ($method_name =~ /^_/ && $method_name !~ /^_(new|init|build)/) {
				next unless $self->{include_private};
			}

			# Reconstruct as sub for analysis
			my $signature = $sig_with_parens;
			$signature =~ s/^\(//;
			$signature =~ s/\)$//;

			# Build a fake sub declaration
			my $fake_sub = "sub $method_name($signature) { }";

			push @$methods, {
				name => $method_name,
				node => undef,
				body => $fake_sub,  # Just the signature for now
				pod => '',
				type => 'method',
				class => $class_name,
				fields => $fields,
			};

			$self->_log("  Found method $method_name in class $class_name");
		}
	}
}

=head2 _extract_pod_before

Extract POD documentation that appears before a subroutine.

=cut

sub _extract_pod_before {
	my ($self, $sub) = @_;

	my $pod = '';
	my $current = $sub->previous_sibling();

	# Walk backwards collecting POD
	while ($current) {
		if ($current->isa('PPI::Token::Pod')) {
			$pod = $current->content . $pod;
					} elsif ($current->isa('PPI::Token::Comment')) {
			# Include comments that might contain parameter info
			my $comment = $current->content;
			if ($comment =~ /#\s*(?:param|arg|input)\s+\$(\w+)\s*:\s*(.+)/i) {
				$pod .= "=item \$$1\n$2\n\n";
			}
		} elsif ($current->isa('PPI::Token::Whitespace') ||
			 $current->isa('PPI::Token::Separator')) {
			# Skip whitespace and separators
		} else {
			# Hit non-POD, non-whitespace - stop
			last;
		}
		$current = $current->previous_sibling;
	}

	return $pod;
}

=head2 _analyze_method

Analyze a method and generate its schema.

Combines POD analysis, code pattern analysis, and signature analysis.

=cut

sub _analyze_method {
	my ($self, $method) = @_;
	my $code = $method->{body};
	my $pod = $method->{pod};

	# Extract modern features
	my $attributes = $self->_extract_subroutine_attributes($code);
	my $postfix_derefs = $self->_analyze_postfix_dereferencing($code);
	my $fields = $self->_extract_field_declarations($code);

	# If this method came from a class, use those field declarations
	if ($method->{fields} && keys %{$method->{fields}}) {
		$fields = $method->{fields};
	}

	my $schema = {
		function => $method->{name},
		_confidence => {
			'input' => 'unknown',
			'output' => 'unknown',
		},
		input => {},
		output => {},
		setup => undef,
		transforms => {},
	};

	# Analyze different sources
	my $pod_params = $self->_analyze_pod($pod);
	my $code_params = $self->_analyze_code($code);

	my $validator_params = $self->_extract_validator_schema($code);

	if ($validator_params) {
		$schema->{input} = $validator_params->{input};
		$schema->{input_style} = 'hash';
		$schema->{_confidence}{input} = { 'factors' => [ 'Determined from validator' ], 'level' => 'high' };
		$schema->{_analysis}{confidence_factors}{input} = [
			'Input schema extracted from validator'
		];
	} else {
		# Merge field declarations into code_params before merging analyses
		if (keys %$fields) {
			$self->_merge_field_declarations($code_params, $fields);
		}

		# Merge analyses
		$schema->{input} = $self->_merge_parameter_analyses(
			$pod_params,
			$code_params,
		);
	}

	# Analyze output/return values
	$schema->{output} = $self->_analyze_output($method->{pod}, $method->{body}, $method->{name});

	# Detect accessor methods
	$self->_detect_accessor_methods($method, $schema);

	# Detect if this is an instance method that needs object instantiation
	my $needs_object = $self->_needs_object_instantiation($method->{name}, $method->{body}, $method);
	if ($needs_object) {
		$schema->{new} = $needs_object;
		$self->_log("  NEW: Method requires object instantiation: $needs_object");
	}

	# Calculate confidences
	my $input_confidence = $schema->{_confidence}{'input'};
	if(!ref($input_confidence)) {
		$input_confidence = $schema->{_confidence}{'input'} = $self->_calculate_input_confidence($schema->{input});
	}
	my $output_confidence = $schema->{_confidence}{'output'} = $self->_calculate_output_confidence($schema->{output});

	# Add metadata
	$schema->{_notes} = $self->_generate_notes($schema->{input});

	# Add analytics
	$schema->{_analysis} = {
		input_confidence => $input_confidence->{level},
		output_confidence => $output_confidence->{level},
		confidence_factors => {
			input => $input_confidence->{factors},
			output => $output_confidence->{factors}
		}
	};

	foreach my $mode('input', 'output') {
		$self->_set_defaults($schema, $mode);
	}

	# Optionally store detailed per-parameter analysis
	if ($input_confidence->{per_parameter}) {
		$schema->{_analysis}{per_parameter_scores} = $input_confidence->{per_parameter};
	}

	# Calculate overall confidence (for backward compatibility)
	my $input_level = $input_confidence->{level};
	my $output_level = $output_confidence->{level};

	my %level_rank = (
		none => 0,
		very_low => 1,
		low => 2,
		medium => 3,
		high => 4
	);

	# Overall is the lower of input and output
	my $overall = $level_rank{$input_level} < $level_rank{$output_level} ? $input_level : $output_level;

	$schema->{_analysis}{overall_confidence} = $overall;

	# Analyze parameter relationships
	my $relationships = $self->_analyze_relationships($method);
	if ($relationships && @{$relationships}) {
		$schema->{relationships} = $relationships;
		$self->_log("  Found " . scalar(@$relationships) . " parameter relationships");
	}

	# Store modern feature info in schema
	$schema->{_attributes} = $attributes if keys %$attributes;
	$schema->{_modern_features}{postfix_dereferencing} = $postfix_derefs if keys %$postfix_derefs;
	$schema->{_fields} = $fields if keys %$fields;

	# Store class info if this is a class method
	if ($method->{class}) {
		$schema->{_class} = $method->{class};
	}

	my $hints = $self->_extract_test_hints($method, $schema);
	$self->_extract_pod_examples($pod, $hints);

	for my $k (qw(boundary_values invalid_inputs valid_inputs equivalence_classes)) {
		my %seen;
		$hints->{$k} = [
			grep { !$seen{ defined $_ ? $_ : '__undef__' }++ }
			@{ $hints->{$k} }
		];
	}

	# --------------------------------------------------
	# YAML test hints: numeric boundaries
	# --------------------------------------------------
	if ($self->_method_has_numeric_intent($schema)) {
		$schema->{_yamltest_hints} ||= {};

		# Do not override existing hints
		$schema->{_yamltest_hints}{boundary_values} ||= [];

		my %seen = map { $_ => 1 } @{ $schema->{_yamltest_hints}{boundary_values} };

		foreach my $v (@{ $self->_numeric_boundary_values }) {
			push @{ $schema->{_yamltest_hints}{boundary_values} }, $v
			unless $seen{$v}++;
		}

		$self->_log('  HINTS: Added numeric boundary values');
	}

	if (keys %$hints) {
		$schema->{_yamltest_hints} ||= {};
		foreach my $k (keys %$hints) {
			$schema->{_yamltest_hints}{$k} = $hints->{$k}
			unless exists $schema->{_yamltest_hints}{$k};
		}
	}

	return $schema;
}

sub _method_has_numeric_intent {
	my ($self, $schema) = @_;

	# Numeric output
	return 1 if ($schema->{output} && $schema->{output}{type} && $schema->{output}{type} =~ /^(number|integer)$/);

	# Numeric inputs
	foreach my $p (values %{ $schema->{input} || {} }) {
		return 1 if ($p->{type} && $p->{type} =~ /^(number|integer)$/);
	}

	return 0;
}

sub _numeric_boundary_values {
	return [ -1, 0, 1, 2, 100 ];
}

sub _detect_accessor_methods {
	my ($self, $method, $schema) = @_;

	my $body = $method->{body};
	# my $name = $method->{name};

	# Simple getter: return $self->{field};
	if ($body =~ /return\s+\$self\s*->\s*\{([^}]+)\}\s*;/) {
		$schema->{_accessor} = { type => 'getter', field => $1 };
		$self->_log("  Detected getter accessor for field: $1");
	}
	# Setter: $self->{field} = $value; return $self;
	elsif ($body =~ /\$self\s*->\s*\{([^}]+)\}\s*=\s*\$(\w+)\s*;/ && $body =~ /return\s+\$self\s*;/) {
		my ($field, $param) = ($1, $2);
		if (defined $field && defined $param) {
			$schema->{_accessor} = { type => 'setter', field => $field, param => $param };
			$self->_log("  Detected setter accessor for field: $field");
		}
	}
	# Getter/Setter combination
	elsif ($body =~ /if\s*\(\s*\@_\s*>\s*1\s*\)/ &&
	       $body =~ /\$self\s*->\s*\{([^}]+)\}\s*=\s*shift\s*;/ &&
	       $body =~ /return\s+\$self\s*->\s*\{[^}]+\}\s*;/) {
		my $field = $1;
		if (defined $field) {
			$schema->{_accessor} = { type => 'getset', field => $field };
			$self->_log("  Detected getter/setter accessor for field: $field");
		}
	}

	if ($schema->{_accessor}) {
		if ($schema->{_accessor}{type} eq 'setter') {
			my $param = $schema->{_accessor}{param};
			if (defined $param) {
				$schema->{input}{$param} ||= { type => 'scalar' };
			}
		}
	}
}

# Look at the parameters validation that may exist in the code, and infer the input schema from that
sub _extract_validator_schema {
	my ($self, $code) = @_;

	return $self->_extract_pvs_schema($code)
		|| $self->_extract_pv_schema($code)
		# || $self->_extract_type_params_schema($code)
		|| $self->_extract_moosex_params_schema($code);
}

sub _parse_schema_hash {
	my ($self, $hash) = @_;

	my %result;

	for my $child ($hash->children) {
		# skip whitespace and operators
		next if $child->isa('PPI::Token::Whitespace') || $child->isa('PPI::Token::Operator');

		if ($child->isa('PPI::Statement') || $child->isa('PPI::Statement::Expression')) {
			my $key;
			my $val;

			my @tokens = $child->children;

			# find key => value
			for (my $i = 0; $i < @tokens; $i++) {
				my $t = $tokens[$i];
				if ($t->isa('PPI::Token::Word') || $t->isa('PPI::Token::Symbol')) {
					$key = $t->content;
				}
				if ($t->isa('PPI::Structure::Constructor')) {
					$val = $t;
					last;
				}
			}

			if ($key && $val) {
				# process inner hash (type, optional)
				my %param;
				for my $inner ($val->children) {
					next if $inner->isa('PPI::Token::Whitespace') || $inner->isa('PPI::Token::Operator');
					if ($inner->isa('PPI::Statement') || $inner->isa('PPI::Statement::Expression')) {
						my ($k_token, $op, $v_token) = $inner->children;
						my $k = $k_token->content;
						my $v = $v_token->isa('PPI::Token::Word') ? $v_token->content : undef;

						if ($k eq 'type') {
							$param{type} = lc($v // 'string'); # Str -> string
						} elsif ($k eq 'optional') {
							$param{optional} = $v eq '1' ? 1 : 0;
						}
					}
				}

				# defaults
				$param{type}     //= 'string';
				$param{optional} //= 0;

				$result{$key} = \%param;
			}
		}
	}

	return {
		input => \%result,
		input_style => 'hash',
		_confidence => {
			input => {
				level => 'high',
				factors => ['Input schema extracted from validator'],
			},
		},
	};
}

# Normalize to PPI::Document if needed
sub _ppi {
	my ($self, $code) = @_;

	return $code if ref($code) && $code->can('find');
	return PPI::Document->new(\$code);
}

# Params::Validate::Strict
sub _extract_pvs_schema {
	my ($self, $code) = @_;

	return unless $code =~ /\bvalidate_strict\s*\(/;

	my $doc = $self->_ppi($code) or return;

	my $calls = $doc->find(sub {
		$_[1]->isa('PPI::Token::Word') && ($_[1]->content eq 'validate_strict' || $_[1]->content eq 'Params::Validate::Strict::validate_strict')
	}) or return;

	for my $call (@$calls) {
		my $list = $call->parent;
		while ($list && !$list->isa('PPI::Structure::List')) {
			$list = $list->parent;
		}
		if(!defined($list)) {
			my $next = $call->next_sibling();
			if($next->content() =~ /schema\s*=>\s*(\{(?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*\})/s) {
				my $schema_text = $1;
				my $compartment = Safe->new();
				$compartment->permit_only(qw(:base_core :base_mem :base_orig));

				my $schema_str = "my \$schema = $schema_text";
				my $schema = $compartment->reval($schema_str);
				if(scalar keys %{$schema}) {
					return {
						input => $schema,
						style => 'hash',
						source => 'validator'
					}
				}
			}
		}
		next unless $list;

		my ($schema_block) = grep { $_->isa('PPI::Structure::Block') } $list->children;

		next unless $schema_block;

		my $schema = $self->_extract_schema_hash_from_block($schema_block);
		return $self->_normalize_validator_schema($schema) if $schema;
	}

	if($code =~ /validate_strict\s*\(\s*(\{.*?\})\s*\)/s) {
		my $schema_text = $1;
		my $schema = $self->_parse_schema_hash($schema_text);
		return {
			input => $schema,
			style => 'hash',
			source => 'validator',
		};
	}

	return;
}

# Params::Validate
sub _extract_pv_schema
{
	my ($self, $code) = @_;

	return unless $code =~ /\bvalidate\s*\(/;

	my $doc = $self->_ppi($code) or return;

	my $calls = $doc->find(sub {
		$_[1]->isa('PPI::Token::Word') && ($_[1]->content eq 'validate' || $_[1]->content eq 'Params::Validate::validate')
	}) or return;

	for my $call (@$calls) {
		my $list = $call->parent;
		while ($list && !$list->isa('PPI::Structure::List')) {
			$list = $list->parent;
		}
		if(!defined($list)) {
			my $next = $call->next_sibling();
			my ($arglist, $schema_text) = $self->_parse_pv_call($next);

			if($schema_text) {
				my $compartment = Safe->new();
				$compartment->permit_only(qw(:base_core :base_mem :base_orig));

				my $schema_str = "my \$schema = $schema_text";
				my $schema = $compartment->reval($schema_str);

				if(scalar keys %{$schema}) {
					foreach my $arg(keys %{$schema}) {
						my $field = $schema->{$arg};
						if(my $type = $field->{'type'}) {
							if($type eq 'ARRAYREF') {
								$field->{'type'} = 'arrayref';
							} elsif($type eq 'SCALAR') {
								$field->{'type'} = 'string';
							}
						}
						delete $field->{'callbacks'};
					}

					return {
						input => $schema,
						style => 'hash',
						source => 'validator'
					}
				}
			}
		}
		next unless $list;

		my ($schema_block) = grep { $_->isa('PPI::Structure::Block') } $list->children;

		next unless $schema_block;

		my $schema = $self->_extract_schema_hash_from_block($schema_block);
		return $self->_normalize_validator_schema($schema) if $schema;
	}

	if($code =~ /validate_strict\s*\(\s*(\{.*?\})\s*\)/s) {
		my $schema_text = $1;
		my $schema = $self->_parse_schema_hash($schema_text);
		return {
			input => $schema,
			style => 'hash',
			source => 'validator',
		};
	}

	return;
}

# Parse the calls to Params::Validate
# Usage:
# my ($first, $hash) = parse_params_call($string);
# returns:
#	$first_arg = '@_'
#	$hash_str = '{ username => { ... }, ... }'

sub _parse_pv_call {
	my ($self, $string) = @_;

	# Remove outer parentheses and whitespace
	$string =~ s/^\s*\(\s*//;
	$string =~ s/\s*\)\s*$//;

	# Find the first comma at brace-depth 0
	my $depth = 0;
	my $comma_pos;

	for my $i (0 .. length($string) - 1) {
		my $char = substr($string, $i, 1);

		if ($char eq '{') {
			$depth++;
		} elsif ($char eq '}') {
			$depth--;
		} elsif ($char eq ',' && $depth == 0) {
			$comma_pos = $i;
			last;
		}
	}

	return unless defined $comma_pos;

	my $first_arg = substr($string, 0, $comma_pos);
	my $hash_str = substr($string, $comma_pos + 1);

	# Trim whitespace
	$first_arg =~ s/^\s+|\s+$//g;
	$hash_str =~ s/^\s+|\s+$//g;

	return ($first_arg, $hash_str);
}

# TODO: Type::Params this may not be doable
# sub _extract_type_params_schema {
	# my ($self, $code) = @_;
#
	# my $doc = $self->_ppi($code) or return;
#
	# my $calls = $doc->find(sub {
		# $_[1]->isa('PPI::Token::Word') && $_[1]->content eq 'compile'
	# }) or return;
#
	# # Conservative: treat Dict[...] as hash input
	# return {
		# input_style => 'hash',
		# input => {},
		# _notes => ['Type::Params detected (schema opaque)'],
		# _confidence => { input => 'medium' },
	# };
# }

sub _extract_moosex_params_schema
{
	my ($self, $code) = @_;

	return unless $code =~ /\bvalidated_hash\s*\(/;

	my $doc = $self->_ppi($code) or return;

	my $calls = $doc->find(sub {
		$_[1]->isa('PPI::Token::Word') && ($_[1]->content eq 'validated_hash')
	}) or return;

	for my $call (@$calls) {
		my $list = $call->parent;
		while ($list && !$list->isa('PPI::Structure::List')) {
			$list = $list->parent;
		}
		if(!defined($list)) {
			my $next = $call->next_sibling();
			my ($arglist, $schema_text) = $self->_parse_pv_call($next);

			if($schema_text) {
				my $compartment = Safe->new();
				$compartment->permit_only(qw(:base_core :base_mem :base_orig));

				my $schema_str = "my \$schema = { $schema_text }";
				$schema_str =~ s/ArrayRef\[(.+?)\]/arrayref, element_type => $1/g;
				my $schema = $compartment->reval($schema_str);

				if(scalar keys %{$schema}) {
					foreach my $arg(keys %{$schema}) {
						my $field = $schema->{$arg};
						if(my $isa = delete $field->{'isa'}) {
							$field->{'type'} = $isa;
						}
						if(exists($field->{'required'})) {
							my $required = delete $field->{'required'};
							$field->{'optional'} = $required ? 0 : 1;
						} else {
							$field->{'optional'} = 1;
						}
						if(ref($field->{'default'}) eq 'CODE') {
							delete $field->{'default'};	# TODO
						}
					}

					foreach my $arg(keys %{$schema}) {
						my $field = $schema->{$arg};
						if(my $type = $field->{'type'}) {
							if($type eq 'ARRAYREF') {
								$field->{'type'} = 'arrayref';
							} elsif($type eq 'SCALAR') {
								$field->{'type'} = 'string';
							}
						}
						delete $field->{'callbacks'};
					}

					return {
						input => $schema,
						style => 'hash',
						source => 'validator'
					}
				}
			}
		}
		next unless $list;

		my ($schema_block) = grep { $_->isa('PPI::Structure::Block') } $list->children;

		next unless $schema_block;

		my $schema = $self->_extract_schema_hash_from_block($schema_block);
		return $self->_normalize_validator_schema($schema) if $schema;
	}

	if($code =~ /validate_strict\s*\(\s*(\{.*?\})\s*\)/s) {
		my $schema_text = $1;
		my $schema = $self->_parse_schema_hash($schema_text);
		return {
			input => $schema,
			style => 'hash',
			source => 'validator',
		};
	}

	return;
}

sub _normalize_validator_schema {
	my ($self, $schema) = @_;

	my %input;

	for my $name (keys %$schema) {
		my $spec = $schema->{$name};

		$input{$name} = {
			%$spec,
			optional => $spec->{optional} // 0,
			_source => 'validator',
			_type_confidence => 'high',
		};
	}

	return {
		input_style => 'hash',
		input => \%input,
	};
}

=head2 _analyze_pod

Parse POD documentation to extract parameter information.

Looks for patterns like:
  $name - string (3-50 chars), username
  $age - integer, must be positive
  $email - string, matches /\@/

=cut

sub _analyze_pod {
	my ($self, $pod) = @_;

	return {} unless $pod;

	my %params;
	my $position_counter = 0;

	# Check for positional arguments in method signature
	# Pattern: =head2 method_name($arg1, $arg2, $arg3)
	if ($pod =~ /=head2\s+\w+\s*\(([^)]+)\)/s) {
		my $sig = $1;
		# Extract parameter names in order
		my @sig_params = $sig =~ /\$(\w+)/g;

		# Skip $self or $class
		shift @sig_params if @sig_params && $sig_params[0] =~ /^(self|class)$/i;

		# Assign positions
		foreach my $param (@sig_params) {
			$params{$param}{position} = $position_counter unless(exists($params{$param}{position}));
			$position_counter++;
			$self->_log("  POD: $param has position $params{$param}{position}");
		}
	}

	$self->_log("  POD: Found $position_counter unnamed parameters to add to the position list");

	# Pattern 1: Parse line-by-line in Parameters section
	# First, extract the Parameters section
	my $param_section;
	if ($pod =~ /(?:Parameters?|Arguments?|Inputs?):?\s*\n(.*?)(?=\n\n|\n=[a-z]|$)/si) {
		$param_section = $1;
	} elsif ($pod =~ /^=head\d+\s+(?:Parameters?|Arguments?|Inputs?)\b.*?\n(.*?)(?=^=head|\Z)/msi) {
		$param_section = $1;
	}
	if($param_section) {
		my $param_order = 0;

		$self->_log("  POD: Scan for named parameters in '$param_section'");
		# Now parse each line that starts with $varname
		foreach my $line (split /\n/, $param_section) {
			# Match: $name - type (constraints), description
			# or:	$name - type, description
			# or:	$name - type
			if ($line =~ /^\s*\$(\w+)\s*-\s*(\w+)(?:\s*\(([^)]+)\))?\s*,?\s*(.*)$/i) {
				my ($name, $type, $constraint, $desc) = ($1, lc($2), $3, $4);

				# Clean up
				$desc =~ s/^\s+|\s+$//g if $desc;

				# Skip common non-parameters
				next if $name =~ /^(self|class|return|returns?)$/i;

				$params{$name} ||= { _source => 'pod' };

				# If we haven't already assigned a position from the signature, use order in Parameters section
				unless (exists $params{$name}{position}) {
					$params{$name}{position} = $param_order++;
					$self->_log("  POD: $name has position $params{$name}{position} (from Parameters order)");
				}

				# Normalize type names
				$type = 'integer' if $type eq 'int';
				$type = 'number' if $type eq 'num' || $type eq 'float';
				$type = 'boolean' if $type eq 'bool';
				$type = 'arrayref' if $type eq 'array';
				$type = 'hashref' if $type eq 'hash';

				$params{$name}{type} = $type;

				# Parse constraints
				if ($constraint) {
					$self->_parse_constraints($params{$name}, $constraint);
				}

				# Check for optional/required in description OR constraint
				my $full_text = ($constraint || '') . ' ' . ($desc || '');
				if ($full_text =~ /optional/i) {
					$params{$name}{optional} = 1;
					$self->_log("  POD: $name marked as optional");
				} elsif ($full_text =~ /required|mandatory/i) {
					$params{$name}{optional} = 0;
					$self->_log("  POD: $name marked as required");
				}

				# Detect semantic types:
				if ($desc =~ /\b(email|url|uri|path|filename)\b/i) {
					# TODO: ensure properties is set to 1 in $config
					carp('Manually set config->properties to 1 in ', $self->{'input_file'});
					$params{$name}{semantic} = lc($1);
				}

				# Look for regex patterns
				if ($desc && $desc =~ m{matches?\s+(/[^/]+/|qr/.+?/)}i) {
					$params{$name}{matches} = $1;
				}

				$self->_log("  POD: Found parameter '$name' in parameters section, type=$type" .
						($constraint ? " ($constraint)" : '') .
						($desc ? " - $desc" : ''));
			}
		}
	}

	# Pattern 2: Also try the inline format in case Parameters: section wasn't found
	while ($pod =~ /\$(\w+)\s*-\s*(string|integer|int|number|num|float|boolean|bool|arrayref|array|hashref|hash|object)(?:\s*\(([^)]+)\))?\s*,?\s*(.*)$/gim) {
		my ($name, $type, $constraint, $desc) = ($1, lc($2), $3, $4);

		# Only process if we haven't already found this param in the Parameters section
		next if exists $params{$name};

		# Clean up description - remove leading/trailing whitespace
		$desc =~ s/^\s+|\s+$//g if $desc;

		# Skip common words that aren't parameters
		next if $name =~ /^(self|class|return|returns?)$/i;

		$params{$name} ||= { _source => 'pod' };

		# Normalize type names
		$type = 'integer' if $type eq 'int';
		$type = 'number' if $type eq 'num' || $type eq 'float';
		$type = 'boolean' if $type eq 'bool';
		$type = 'arrayref' if $type eq 'array';
		$type = 'hashref' if $type eq 'hash';

		$params{$name}{type} = $type;

		# Parse constraints
		if ($constraint) {
			$self->_parse_constraints($params{$name}, $constraint);
		}

		# Check for optional/required in description
		if ($desc) {
			if ($desc =~ /optional/i) {
				$params{$name}{optional} = 1;
			} elsif ($desc =~ /required|mandatory/i) {
				$params{$name}{optional} = 0;
			}

			# Look for regex patterns in description
			if ($desc =~ m{matches?\s+(/[^/]+/|qr/.+?/)}i) {
				$params{$name}{matches} = $1;
			}
		}

		$self->_log("  POD: Found parameter '$name' in the inline documentation, type=$type" .
					($constraint ? " ($constraint)" : ''));
	}

	# Pattern 3: Parse =over /=item list
	if ($pod =~ /=over\b.*?=item\s+\$(\w+)\s*\n(.*?)(?==item\s+\$|\=back)/sig) {
		my $name = $1;
		my $desc = $2;
		$desc =~ s/^\s+|\s+$//g;

		# Skip common non-parameters
		next if $name =~ /^(self|class|return|returns?)$/i;

		$params{$name} ||= { _source => 'pod' };

		# Explicit typed form only:
		#   $param - type (constraints)
		if ($desc =~ /^\s*(string|integer|int|number|num|float|boolean|bool|array|arrayref|hash|hashref)\b(?:\s*\(([^)]+)\))?/i) {
			my $type = lc($1);
			my $constraint = $2;

			# Normalize type names
			$type = 'integer'  if $type eq 'int';
			$type = 'number'   if $type eq 'num' || $type eq 'float';
			$type = 'boolean'  if $type eq 'bool';
			$type = 'arrayref' if $type eq 'array';
			$type = 'hashref'  if $type eq 'hash';

			$params{$name}{type} = $type;

			if ($constraint) {
				$self->_parse_constraints($params{$name}, $constraint);
			}

			$self->_log("  POD: Explicit type '$type' for $name");
		} else {
			# Heuristic inference from description text
			if ($desc =~ /\bstring\b/i) {
				$params{$name}{type} = 'string';
			} elsif ($desc =~ /\b(int|integer)\b/i) {
				$params{$name}{type} = 'integer';
			} elsif ($desc =~ /\b(num|number|float)\b/i) {
				$params{$name}{type} = 'number';
			} elsif ($desc =~ /\b(bool|boolean)\b/i) {
				$params{$name}{type} = 'boolean';
			}
		}

		# Check for optional/required in description
		if ($desc =~ /optional/i) {
			$params{$name}{optional} = 1;
		} elsif ($desc =~ /required|mandatory/i) {
			$params{$name}{optional} = 0;
		}

		# Look for regex patterns
		if ($desc =~ m{matches?\s+(/[^/]+/|qr/.+?/)}i) {
			$params{$name}{matches} = $1;
		}

		$self->_log("  POD: Found parameter '$name' from =item list");
	}

	# Extract default values from POD
	my $pod_defaults = $self->_extract_defaults_from_pod($pod);
	foreach my $param (keys %$pod_defaults) {
		if (exists $params{$param}) {
			$params{$param}{default} = $pod_defaults->{$param};
			$params{$param}{optional} = 1 unless defined $params{$param}{optional};
			$self->_log(sprintf("  POD: %s has default value: %s",
			    $param,
			    defined($pod_defaults->{$param}) ? $pod_defaults->{$param} : 'undef'));
		}
	}

	return \%params;
}

=head2 _analyze_output

Analyze return values from POD and code.

Looks for:
  - Returns: section in POD
  - return statements in code
  - Common patterns like "returns 1 on success"

=cut

# Enhanced _analyze_output that incorporates all improvements
sub _analyze_output {
	my ($self, $pod, $code, $method_name) = @_;

	my %output;

	$self->_analyze_output_from_pod(\%output, $pod);
	$self->_analyze_output_from_code(\%output, $code, $method_name);
	$self->_enhance_boolean_detection(\%output, $pod, $code, $method_name);
	$self->_detect_list_context(\%output, $code);
	$self->_detect_void_context(\%output, $code, $method_name);
	$self->_detect_chaining_pattern(\%output, $code, $method_name);
	$self->_detect_error_conventions(\%output, $code);

	$self->_validate_output(\%output) if keys %output;

	# Don't return empty output
	return (keys %output) ? \%output : {};
}

# Analyze POD for Returns section
sub _analyze_output_from_pod {
	my ($self, $output, $pod) = @_;

	if ($pod) {
		# Pattern 1: Returns: section
		if ($pod =~ /Returns?:\s+(.+?)(?=\n\n|\n=[a-z]|$)/si) {
			my $returns_desc = $1;
			$returns_desc =~ s/^\s+|\s+$//g;

			$self->_log("  OUTPUT: Found Returns section: $returns_desc");

			# Try to infer type from description
			if ($returns_desc =~ /\b(string|text)\b/i) {
				$output->{type} = 'string';
			} elsif ($returns_desc =~ /\b(integer|int|number|count)\b/i) {
				$output->{type} = 'integer';
			} elsif ($returns_desc =~ /\b(float|decimal|number)\b/i) {
				$output->{type} = 'number';
			} elsif ($returns_desc =~ /\b(boolean|true|false)\b/i) {
				$output->{type} = 'boolean';
			} elsif ($returns_desc =~ /\b(array|list)\b/i) {
				$output->{type} = 'arrayref';
			} elsif ($returns_desc =~ /\b(hash|hashref|dictionary)\b/i) {
				$output->{type} = 'hashref';
			} elsif ($returns_desc =~ /\b(object|instance)\b/i) {
				$output->{type} = 'object';
			} elsif ($returns_desc =~ /\bundef\b/i) {
				$output->{type} = 'undef';
			}

			# Look for specific values
			if ($returns_desc =~ /\b1\s+(?:on\s+success|if\s+successful)\b/i) {
				$output->{value} = 1;
				if(defined($output->{'type'}) && ($output->{type} eq 'scalar')) {
					$output->{type} = 'boolean';
				} else {
					$output->{type} ||= 'boolean';
				}
				$self->_log("  OUTPUT: Returns 1 on success");
			} elsif ($returns_desc =~ /\b0\s+(?:on\s+failure|if\s+fail)\b/i) {
				$output->{alt_value} = 0;
			} elsif ($returns_desc =~ /dies\s+on\s+(?:error|failure)/i) {
				$output->{_STATUS} = 'LIVES';
				$self->_log('  OUTPUT: Should not die on success');
			}
		}

		# Pattern 2: Inline "returns X"
		if((!$output->{type}) && ($pod =~ /returns?\s+(?:an?\s+)?(\w+)/i)) {
			my $type = lc($1);

			$type = 'boolean' if $type =~ /^(true|false|bool)$/;

			# Skip if it's just a number (like "returns 1")
			$type = 'integer' if $type eq 'int';
			$type = 'number' if $type =~ /^(num|float)$/;
			$type = 'boolean' if $type eq 'bool';
			$type = 'arrayref' if $type eq 'array';
			$type = 'hashref' if $type eq 'hash';

			if($type =~ /^\d+$/) {
				if($type eq '1' || $type eq '0') {
					# Try hard to guess if the result is a boolean
					if($pod =~ /1 on success.+0 (on|if) /i) {
						$type = 'boolean';
					} elsif($pod =~ /return 0 .+ 1 on success/) {
						$type = 'boolean';
					} else {
						$type = 'integer';
					}
				} else {
					$type = 'integer';
				}
			}

			$type = 'arrayref' if !$type && $pod =~ /returns?\s+.+\slist\b/i;
			$output->{type} = $type if $type && $type !~ /^\d+$/;
			$self->_log("  OUTPUT: Inferred type from POD: $type");
		}
	}

}

=head2 _extract_defaults_from_pod

Extract default values from POD documentation.

Looks for patterns like:
  - Default: 'value'
  - Defaults to: value
  - Optional, default: value

=cut

sub _extract_defaults_from_pod {
	my ($self, $pod) = @_;

	return {} unless $pod;

	my %defaults;

	# Pattern 1: Default: 'value' or Defaults to: 'value'
	while ($pod =~ /(?:Default(?:s? to)?|default(?:s? to)?)[:]\s*([^\n\r]+)/gi) {
		my $default_text = $1;
		my $match_pos = pos($pod);
		$default_text =~ s/^\s+|\s+$//g;

		# Look backwards in the POD to find the parameter name
		my $context = substr($pod, 0, $match_pos);
		my @param_matches = ($context =~ /\$(\w+)/g);
		my $param = $param_matches[-1] if @param_matches;  # Last parameter before default

		if ($param) {
			# Always clean the default value - let _clean_default_value handle everything
			if ($default_text =~ /(\w+)\s*=\s*(.+)$/) {
				# Has explicit param = value format in the default text
				my ($p, $value) = ($1, $2);
				$defaults{$p} = $self->_clean_default_value($value);
			} else {
				# Just a value, associate with the found param
				$defaults{$param} = $self->_clean_default_value($default_text, 0);  # NOT from code
			}
		}
	}

	# Pattern 2: Optional, default 'value'
	while ($pod =~ /Optional(?:,)?\s+(?:default|value)\s*[:=]?\s*([^\n\r,;]+)/gi) {
		my $default_text = $1;
		my $match_pos = pos($pod);
		$default_text =~ s/^\s+|\s+$//g;

		# Look backwards for parameter name
		my $context = substr($pod, 0, $match_pos);
		my @param_matches = ($context =~ /\$(\w+)/g);
		if (@param_matches) {
			my $param = $param_matches[-1];  # Last parameter before the default
			$defaults{$param} = $self->_clean_default_value($default_text, 0);
		}
	}

	# Pattern 3: In parameter descriptions: $param - type, default 'value'
	while ($pod =~ /\$(\w+)\s*-\s*\w+(?:\([^)]*\))?[,\s]+default\s+['"]?([^'",\n]+)['"]?/gi) {
		my ($param, $value) = ($1, $2);
		$defaults{$param} = $self->_clean_default_value($value, 0);
	}

	return \%defaults;
}

# Analyze code for return statements
sub _analyze_output_from_code
{
	my ($self, $output, $code, $method_name) = @_;

	if ($code) {
		# Early boolean detection - check for consistent 1/0 returns
		my @all_returns = $code =~ /return\s+([^;]+);/g;
		if (@all_returns) {
			my $boolean_count = 0;
			my $total_count = scalar(@all_returns);

			foreach my $ret (@all_returns) {
				$ret =~ s/^\s+|\s+$//g;
				# Match 0 or 1, even with conditions
				$boolean_count++ if ($ret =~ /^(?:0|1)(?:\s|$)/);
			}

			# If most returns are 0 or 1, strongly suggest boolean
			if ($boolean_count >= 2 && $boolean_count >= $total_count * 0.8) {
				unless ($output->{type}) {
					$output->{type} = 'boolean';
					$self->_log("  OUTPUT: Early detection - $boolean_count/$total_count returns are 0/1, setting boolean");
				}
			}
		}

		my @return_statements;

		if ($code =~ /return\s+bless\s*\{[^}]*\}\s*,\s*['"]?(\w+)['"]?/s) {
			# Detect blessed refs
			$output->{type} = 'object';
			if($method_name eq 'new') {
				# If we found the new() method, the object we're returning should be a sensible one
				if($self->{_document} && (my $package_stmt = $self->{_document}->find_first('PPI::Statement::Package'))) {
					$output->{isa} = $package_stmt->namespace();
				}
			} else {
				$output->{isa} = $1;
			}
			$self->_log("  OUTPUT: Bless found, inferring type from code is $output->{isa}");
		} elsif ($code =~ /return\s+bless/s) {
			$output->{type} = 'object';
			if($method_name eq 'new') {
				$output->{isa} = $self->_extract_package_name();
				$self->_log("  OUTPUT: Bless found, inferring type from code is $output->{isa}");
			} else {
				$self->_log('  OUTPUT: Bless found, inferring type from code is object');
			}
		} elsif ($code =~ /return\s*\(\s*[^)]+\s*,\s*[^)]+\s*\)\s*;/) {
			# Detect array context returns - must end with semicolon to be actual return
			$output->{type} = 'array';	# Not arrayref - actual array
			$self->_log('  OUTPUT: Found array contect return');
		} elsif ($code =~ /return\s+bless[^,]+,\s*__PACKAGE__/) {
			# Detect: bless {}, __PACKAGE__
			$output->{type} = 'object';
			# Get package name from the extractor's stored document
			if ($self->{_document}) {
				my $pkg = $self->{_document}->find_first('PPI::Statement::Package');
				$output->{isa} = $pkg ? $pkg->namespace : 'UNKNOWN';
				$self->_log('  OUTPUT: Object blessed into __PACKAGE__: ' . ($output->{isa} || 'UNKNOWN'));
			}
		} elsif ($code =~ /return\s*\(([^)]+)\)/) {
			my $content = $1;
			if ($content =~ /,/) {	# Has comma = multiple values
				$output->{type} = 'array';
			}
		}
		elsif ($code =~ /return\s+\$self\s*;/ && $code =~ /\$self\s*->\s*\{[^}]+\}\s*=/) {
			# Returns $self for chaining
			$output->{type} = 'object';
			if ($self->{_document}) {
				my $pkg = $self->{_document}->find_first('PPI::Statement::Package');
				$output->{isa} = $pkg ? $pkg->namespace : 'UNKNOWN';
				$self->_log('  OUTPUT: Object chained into __PACKAGE__: ' . ($output->{isa} || 'UNKNOWN'));
			}
		}

		# Find all return statements
		while ($code =~ /return\s+([^;]+);/g) {
			my $return_expr = $1;
			push @return_statements, $return_expr;
		}

		if (@return_statements) {
			$self->_log('  OUTPUT: Found ' . scalar(@return_statements) . ' return statement(s)');

			# Analyze return patterns
			my %return_types;

			if($output->{'type'}) {
				$return_types{$output->{'type'}} += 3;	# Add weighting to what's already been found
			}
			foreach my $ret (@return_statements) {
				$ret =~ s/^\s+|\s+$//g;

				# Literal values
				if ($ret eq '1' || $ret eq '0') {
					$return_types{boolean}++;
				} elsif ($ret =~ /^['"]/) {
					$return_types{string}++;
				} elsif ($ret =~ /^-?\d+$/) {
					$return_types{integer}++;
				} elsif ($ret =~ /^-?\d+\.\d+$/) {
					$return_types{number}++;
				} elsif ($ret eq 'undef') {
					$return_types{undef}++;
				}
				# Data structures
				elsif ($ret =~ /^\[/) {
					$return_types{arrayref}++;
				} elsif ($ret =~ /^\{/) {
					$return_types{hashref}++;
				} elsif ($ret =~ m{
					# Numeric expressions (heuristic, medium confidence)
				    (?:
					\+ | - | \* | / | %
				      | \+\+ | --
				    )
				}x) {
					$return_types{number} += 2;
				}
				# Variables/expressions
				elsif ($ret =~ /\$\w+/) {
					if ($ret =~ /\\\@/) {
						$return_types{arrayref}++;
					} elsif ($ret =~ /\\\%/) {
						$return_types{hashref}++;
					} elsif ($ret =~ /bless/) {
						$return_types{object} += 2;	# Heigher weight
					} elsif ($ret =~ /^\{[^}]*\}$/) {
						$return_types{hashref}++;
					} elsif ($ret =~ /^\[[^\]]*\]$/) {
						$return_types{arrayref}++;
					} else {
						$return_types{scalar}++;
					}
				}
			}

			# Determine most common return type
			if (keys %return_types) {
				my ($most_common) = sort { $return_types{$b} <=> $return_types{$a} } keys %return_types;
				unless ($output->{type}) {
					$output->{type} = $most_common;

					# Assign confidence for inferred numeric expressions
					if ($most_common eq 'number') {
						$output->{_type_confidence} ||= 'medium';
					}

					$self->_log("  OUTPUT: Inferred type from code: $most_common");
				}
			}

			# Check for consistent single value returns
			if (@return_statements == 1 && $return_statements[0] eq '1') {
				$output->{value} = 1;
				$output->{type} = 'boolean' if !$output->{type} || $output->{type} eq 'scalar';
				$self->_log("  OUTPUT: Type already set to '$output->{type}', overriding with boolean") if($output->{'type'});
			}
		} else {
			# No explicit return - might return nothing or implicit undef
			$self->_log("  OUTPUT: No explicit return statement found");
		}
	}
}

sub _enhance_boolean_detection {
	my ($self, $output, $pod, $code, $method_name) = @_;

	my $boolean_score = 0;	# Track evidence for boolean return

	# Look for stronger boolean indicators
	if ($pod && !$output->{type}) {
		# Common boolean return patterns in POD
		if ($pod =~ /returns?\s+(true|false|true|false|1|0)\s+(?:on|for|upon)\s+(success|failure|error|valid|invalid)/i) {
			$boolean_score += 30;
			$self->_log('  OUTPUT: Strong boolean indicator in POD (+30)');
		}

		# Check for method names that suggest boolean returns
		if ($pod =~ /(?:method|sub)\s+(\w+)/) {
			my $inferred_method_name = $1;
			if ($inferred_method_name =~ /^(is_|has_|can_|should_|contains_|exists_)/) {
				$boolean_score += 20;
				$self->_log("  OUTPUT: Inferred method name '$inferred_method_name' suggests boolean return (+20)");
			}
		}
	}

	# Analyze code for boolean patterns
	if ($code) {
		# Count boolean return idioms
		my $true_returns = () = $code =~ /return\s+1\s*;/g;
		my $false_returns = () = $code =~ /return\s+0\s*;/g;

		if ($true_returns + $false_returns >= 2) {
			$boolean_score += 40;
			$self->_log('  OUTPUT: Multiple 1/0 returns suggest boolean (+40)');
		} elsif ($true_returns + $false_returns == 1) {
			$boolean_score += 10;
			$self->_log('  OUTPUT: Single 1/0 return (+10)');
		}

		# Ternary operators that return booleans
		if ($code =~ /return\s+(?:\w+\s*[!=]=\s*\w+|\w+\s*>\s*\w+|\w+\s*<\s*\w+)\s*\?\s*(?:1|0)\s*:\s*(?:1|0)/) {
			$boolean_score += 25;
			$self->_log('  OUTPUT: Ternary with 1/0 suggests boolean (+25)');
		}

		# Check for common boolean method patterns
		if ($code =~ /return\s+[!\$\@\%]/) {
			# Returns negation or existence check
			$boolean_score += 15;
			$self->_log('  OUTPUT: Returns negation/existence check (+15)');
		}
	}

	# Check method name for boolean indicators
	if ($method_name) {
		if ($method_name =~ /^(is_|has_|can_|should_|contains_|exists_|check_|verify_|validate_)/) {
			$boolean_score += 25;
			$self->_log("  OUTPUT: Method name '$method_name' suggests boolean return (+25)");
		}
		if ($method_name =~ /_ok$/) {
			$boolean_score += 30;
			$self->_log("  OUTPUT: Method name '$method_name' ends with '_ok' (+30)");
		}
	}

	# Apply boolean type if we have strong evidence
	# Override weak type assignments (like 'array' from false positive)
	if ($boolean_score >= 30) {
		if (!$output->{type} || $output->{type} eq 'scalar' || $output->{type} eq 'array' || $output->{type} eq 'undef') {
			my $old_type = $output->{type} || 'none';
			$output->{type} = 'boolean';
			$self->_log("  OUTPUT: Boolean score $boolean_score >= 30, setting type to boolean (was: $old_type)");
		}
	}
}

# Enhanced return value analysis
sub _detect_list_context {
	my ($self, $output, $code) = @_;
	return unless $code;

	# Check for wantarray usage
	if ($code =~ /wantarray/) {
		$output->{context_aware} = 1;
		$self->_log('  OUTPUT: Method uses wantarray - context sensitive');

		# Debug: show what we're matching against
		if ($code =~ /(wantarray[^;]+;)/s) {
			$self->_log("  DEBUG wantarray line: $1");
		}

		if ($code =~ /wantarray\s*\?\s*\(([^)]+)\)\s*:\s*([^;]+)/s) {
			# Pattern 1: wantarray ? (list, items) : scalar_value (with parens)
			my ($list_return, $scalar_return) = ($1, $2);
			$self->_log("  DEBUG list (with parens): [$list_return], scalar: [$scalar_return]");

			$output->{list_context} = $self->_infer_type_from_expression($list_return);
			$output->{scalar_context} = $self->_infer_type_from_expression($scalar_return);
			$self->_log('  OUTPUT: Detected context-dependent returns (parenthesized)');
		} elsif ($code =~ /wantarray\s*\?\s*([^:]+?)\s*:\s*([^;]+)/s) {
			# Pattern 2: wantarray ? @array : scalar (no parens around list)
			my ($list_return, $scalar_return) = ($1, $2);
			# Clean up
			$list_return =~ s/^\s+|\s+$//g;
			$scalar_return =~ s/^\s+|\s+$//g;

			$self->_log("  DEBUG list (no parens): [$list_return], scalar: [$scalar_return]");

			$output->{list_context} = $self->_infer_type_from_expression($list_return);
			$output->{scalar_context} = $self->_infer_type_from_expression($scalar_return);
			$self->_log('  OUTPUT: Detected context-dependent returns (non-parenthesized)');
		} elsif ($code =~ /return[^;]*unless\s+wantarray.*?return\s*\(([^)]+)\)/s) {
			# Pattern 3: return unless wantarray; return (list);
			$output->{list_context} = { type => 'array' };
			$self->_log('  OUTPUT: Detected list context return after wantarray check');
			}
		}

	# Detect explicit list returns (multiple values in parentheses)
	# Avoid false positives from function calls
	if ($code =~ /return\s*\(\s*([^)]+)\s*\)\s*;/) {
		my $content = $1;
		# Count commas outside of nested structures
		my $comma_count = 0;
		my $depth = 0;
		for my $char (split //, $content) {
			$depth++ if $char eq '(' || $char eq '[' || $char eq '{';
			$depth-- if $char eq ')' || $char eq ']' || $char eq '}';
			$comma_count++ if $char eq ',' && $depth == 0;
		}

		if ($comma_count > 0 && $content !~ /\b(?:bless|new)\b/) {
			# Multiple values returned
			unless ($output->{type} && $output->{type} eq 'boolean') {
				$output->{type} = 'array';
				$output->{list_return} = $comma_count + 1;
				$self->_log('  OUTPUT: Returns list of ' . ($comma_count + 1) . ' values');
			}
		}
	}
}

sub _detect_void_context {
	my ($self, $output, $code, $method_name) = @_;
	return unless $code;

	$self->_log("  DEBUG _detect_void_context called for $method_name");

	# Methods that typically don't return meaningful values
	my $void_patterns = {
		'setter' => qr/^set_\w+$/,
		'mutator' => qr/^(?:add|remove|delete|clear|reset|update)_/,
		'logger' => qr/^(?:log|debug|warn|error|info)$/,
		'printer' => qr/^(?:print|say|dump)_/,
	};

	# Check if method name suggests void context
	foreach my $type (keys %$void_patterns) {
		if ($method_name =~ $void_patterns->{$type}) {
			$output->{void_context_hint} = $type;
			$self->_log("  OUTPUT: Method name suggests $type (typically void context)");
			last;
		}
	}

	# Analyze return statements
	my @returns = $code =~ /return\s*([^;]*);/g;

	$self->_log('  DEBUG Found ' . scalar(@returns) . ' return statements');

	# Count different return patterns
	my $no_value_returns = 0;
	my $true_returns = 0;
	my $self_returns = 0;

	foreach my $ret (@returns) {
		$ret =~ s/^\s+|\s+$//g;
		$self->_log("  DEBUG return value: [$ret]");
		$no_value_returns++ if $ret eq '';
		$no_value_returns++ if($ret =~ /^(if|unless)\s/);
		$true_returns++ if $ret eq '1';
		$self_returns++ if $ret eq '$self';
		if ($ret =~ /\?\s*1\s*:\s*0\b/) {
			# Strong boolean signal: ternary returning 1/0
			$true_returns++;
			# $self->_log("  OUTPUT: Ternary 1:0 return detected, treating as boolean (+40)");
			$self->_log('  OUTPUT: Ternary 1:0 return detected, treating as boolean');
		}
	}

	my $total_returns = scalar(@returns);

	$self->_log("  DEBUG no_value=$no_value_returns, true=$true_returns, self=$self_returns, total=$total_returns");

	# Void context indicators
	if ($no_value_returns > 0 && $no_value_returns == $total_returns) {
		$output->{void_context} = 1;
		$output->{type} = 'void';  # This should override any previous type
		$self->_log('  OUTPUT: All returns are empty - void context method');
	} elsif ($true_returns > 0 && $true_returns == $total_returns && $total_returns >= 1) {
		# Methods that always return true (success indicator)
		$output->{_success_indicator} = 1;
		# Don't override type if already set to boolean
		unless ($output->{type} && $output->{type} eq 'boolean') {
			$output->{type} = 'boolean';
		}
		$self->_log('  OUTPUT: Always returns 1 - success indicator pattern');
	}
}

# Detect method chaining patterns
sub _detect_chaining_pattern {
	my ($self, $output, $code, $method_name) = @_;
	return unless $code;

	# Count returns of $self
	my $self_returns = 0;
	my $total_returns = 0;

	while ($code =~ /return\s+([^;]+);/g) {
		my $ret = $1;
		$ret =~ s/^\s+|\s+$//g;
		$total_returns++;
		$self_returns++ if $ret eq '$self';
	}

	# If most/all returns are $self, it's a chaining method
	if ($self_returns > 0 && $total_returns > 0) {
		my $ratio = $self_returns / $total_returns;

		if ($ratio >= 0.8) {
			$output->{type} = 'object';
			$output->{returns_self} = 1;

			# Get the class name
			if ($self->{_document}) {
				my $pkg = $self->{_document}->find_first('PPI::Statement::Package');
				$output->{isa} = $pkg ? $pkg->namespace : 'UNKNOWN';
			}

			$self->_log("  OUTPUT: Chainable method - returns \$self ($self_returns/$total_returns returns)");
		}
	}
}

# Detect error return conventions
sub _detect_error_conventions {
	my ($self, $output, $code) = @_;
	return unless $code;

	$self->_log('  DEBUG _detect_error_conventions called');

	my %error_patterns;

    # Pattern 1: return undef if/unless condition
    while ($code =~ /return\s+undef\s+(?:if|unless)\s+([^;]+);/g) {
        push @{$error_patterns{undef_on_error}}, $1;
        $self->_log("  DEBUG Found 'return undef' pattern");
    }

	# Pattern 2: return if/unless (implicit undef)
	while ($code =~ /return\s+(?:if|unless)\s+([^;]+);/g) {
		push @{$error_patterns{implicit_undef}}, $1;
		$self->_log("  DEBUG Found implicit undef pattern");
	}

    # Pattern 3: return () - matches with or without conditions
    if ($code =~ /return\s*\(\s*\)\s*(?:if|unless|;)/) {
        $error_patterns{empty_list} = 1;
        $self->_log("  DEBUG Found empty list return");
    }

    # Pattern 4: return 0/1 pattern (indicates boolean with error handling)
my $zero_returns = 0;
my $one_returns = 0;
# Match "return 0" or "return 1" followed by anything (condition or semicolon)
while ($code =~ /return\s+(0|1)\s*(?:;|if|unless)/g) {
    if ($1 eq '0') {
        $zero_returns++;
    } else {
        $one_returns++;
    }
}
if ($zero_returns > 0 && $one_returns > 0) {
    $error_patterns{zero_on_error} = 1;
    $self->_log("  DEBUG Found 0/1 return pattern ($zero_returns zeros, $one_returns ones)");
}

    # Pattern 5: Exception handling with eval
    if ($code =~ /eval\s*\{/) {
        # Check if there's error handling after eval
        if ($code =~ /eval\s*\{.*?\}[^}]*(?:if\s*\(\s*\$\@|catch|return\s+undef)/s) {
            $error_patterns{exception_handling} = 1;
            $self->_log("  DEBUG Found exception handling with eval");
        }
    }

	# Detect success/failure return pattern
	my @all_returns = $code =~ /return\s+([^;]+);/g;
	my $has_undef = grep { /^\s*undef\s*(?:if|unless|$)/ } @all_returns;
	my $has_value = grep { !/^\s*undef\s*$/ && !/^\s*$/ } @all_returns;

	if ($has_undef && $has_value && scalar(@all_returns) >= 2) {
		$output->{success_failure_pattern} = 1;
		$self->_log("  OUTPUT: Uses success/failure return pattern");
	}

    # Store error conventions in output
    if (keys %error_patterns) {
        $output->{error_handling} = \%error_patterns;

        # Determine primary error convention
        if ($error_patterns{undef_on_error}) {
            $output->{error_return} = 'undef';
            $self->_log("  OUTPUT: Returns undef on error");
        } elsif ($error_patterns{implicit_undef}) {
            $output->{error_return} = 'undef';
            $self->_log("  OUTPUT: Returns implicit undef on error");
        } elsif ($error_patterns{empty_list}) {
            $output->{error_return} = 'empty_list';
            $self->_log("  OUTPUT: Returns empty list on error");
        } elsif ($error_patterns{zero_on_error}) {
            $output->{error_return} = 'false';
            $self->_log("  OUTPUT: Returns 0/false on error");
        }

        if ($error_patterns{exception_handling}) {
            $self->_log("  OUTPUT: Has exception handling");
        }
    }
}

# Helper method: Infer type from an expression
sub _infer_type_from_expression {
	my ($self, $expr) = @_;

	return { type => 'scalar' } unless defined $expr;

	$expr =~ s/^\s+|\s+$//g;

	# Check for multiple comma-separated values (indicates array/list)
	if ($expr =~ /,/) {
		my $comma_count = 0;
		my $depth = 0;
		for my $char (split //, $expr) {
			$depth++ if $char =~ /[\(\[\{]/;
			$depth-- if $char =~ /[\)\]\}]/;
			$comma_count++ if $char eq ',' && $depth == 0;
		}

		if ($comma_count > 0) {
			return { type => 'array' };
		}
	}

	# Check for @ prefix (array)
	if ($expr =~ /^\@\w+/ || $expr =~ /^qw\(/ || $expr =~ /^\@\{/) {
		return { type => 'array' };
	}

	# Check for scalar() function - returns count
	if ($expr =~ /scalar\s*\(/) {
		return { type => 'integer' };
	}

    # Check for array reference
    if ($expr =~ /^\[/ || $expr =~ /^\\\@/) {
        return { type => 'arrayref' };
    }

    # Check for hash reference
    if ($expr =~ /^\{/ || $expr =~ /^\\\%/) {
        return { type => 'hashref' };
    }

    # Check for hash
    if ($expr =~ /^\%\w+/ || $expr =~ /^\%\{/) {
        return { type => 'hash' };
    }

    # Check for strings
    if ($expr =~ /^['"]/ || $expr =~ /['"]$/) {
        return { type => 'string' };
    }


    # Check for numbers
    if ($expr =~ /^-?\d+$/) {
        return { type => 'integer' };
    }
    if ($expr =~ /^-?\d+\.\d+$/) {
        return { type => 'number' };
    }

    # Check for booleans
    if ($expr =~ /^[01]$/) {
        return { type => 'boolean' };
    }

    # Check for objects
    if ($expr =~ /bless/) {
        return { type => 'object' };
    }

    # Default to scalar
    return { type => 'scalar' };
}

# Addition to _analyze_output_from_pod to detect chaining documentation
sub _detect_chaining_from_pod {
	my ($self, $output, $pod) = @_;
	return unless $pod;

	# Look for explicit chaining documentation
	if ($pod =~ /returns?\s+(?:\$)?self\b/i ||
		$pod =~ /chainable/i ||
		$pod =~ /fluent\s+interface/i ||
		$pod =~ /method\s+chaining/i) {

		$output->{returns_self} = 1;
		$self->_log("  OUTPUT: POD indicates chainable/fluent interface");
	}
}

sub _validate_output {
	my ($self, $output) = @_;

	# Warn about suspicious combinations
	if (defined $output->{type} && $output->{type} eq 'boolean' && !defined($output->{value})) {
		$self->_log('  WARNING Boolean type without value - may want to set value: 1');
	}
	if ($output->{value} && defined $output->{type} && $output->{type} ne 'boolean') {
		$self->_log("  WARNING Value set but type is not boolean: $output->{type}");
	}
	my %valid_types = map { $_ => 1 } qw(string integer number boolean arrayref hashref object void);
	if(exists $output->{type}) {
		if(!$valid_types{$output->{type}}) {
			$self->_log("  WARNING Output value type is unknown: '$output->{type}', setting to string");
			$output->{type} = 'string';
		}
	}
}

=head2 _parse_constraints

Parse constraint strings like "3-50 chars" or "positive" or "1-100".

=cut

sub _parse_constraints {
	my ($self, $param, $constraint) = @_;

	# Range: "3-50" or "1-100 chars"
	if ($constraint =~ /(\d+)\s*-\s*(\d+)/) {
		$param->{min} = $1;
		$param->{max} = $2;
	}
	elsif ($constraint =~ /(\d+)\s*\.\.\s*(\d+)/) {
		# Range: 0..19
		$param->{min} = $1;
		$param->{max} = $2;
	}
	# Minimum: "min 3" or "at least 5"
	elsif ($constraint =~ /(?:min|minimum|at least)\s*(\d+)/i) {
		$param->{min} = $1;
	}
	# Maximum: "max 50" or "up to 100"
	elsif ($constraint =~ /(?:max|maximum|up to)\s*(\d+)/i) {
		$param->{max} = $1;
	}
	# Positive
	elsif ($constraint =~ /positive/i) {
		$param->{min} = 1 if $param->{type} && $param->{type} eq 'integer';
		$param->{min} = 0.01 if $param->{type} && $param->{type} eq 'number';
	}
	# Non-negative
	elsif ($constraint =~ /non-negative/i) {
		$param->{min} = 0;
	} elsif($constraint =~ /(.+)?\s(.+)/) {
		my ($op, $val) = ($1, $2);
		if(looks_like_number($val)) {
			if ($op eq '<') {
				$param->{max} = $val - 1;
			} elsif ($op eq '<=') {
				$param->{max} = $val;
			} elsif ($op eq '>') {
				$param->{min} = $val + 1;
			} elsif ($op eq '>=') {
				$param->{min} = $val;
			}
		}
	}

	if(defined($param->{max})) {
		$self->_log("  Set max to $param->{max}");
	}
	if(defined($param->{min})) {
		$self->_log("  Set min to $param->{min}");
	}
}

=head2 _analyze_code

Analyze code patterns to infer parameter types and constraints.

Looks for common validation patterns:
  - defined checks
  - ref() checks
  - regex matches
  - length checks
  - numeric comparisons

=cut

# Enhanced _analyze_code with more pattern detection
sub _analyze_code {
	my ($self, $code) = @_;

	my %params;

	# Safety check - limit parameter analysis to prevent runaway processing
	my $param_count = 0;

	# Extract parameter names from various signature styles
	$self->_extract_parameters_from_signature(\%params, $code);

	$self->_extract_defaults_from_code(\%params, $code);

	# Infer types from defaults
	foreach my $param (keys %params) {
		if ($params{$param}{default} && !$params{$param}{type}) {
			my $default = $params{$param}{default};
			if (ref($default) eq 'HASH') {
				$params{$param}{type} = 'hashref';
				$self->_log("  CODE: $param type inferred as hashref from default");
			} elsif (ref($default) eq 'ARRAY') {
				$params{$param}{type} = 'arrayref';
				$self->_log("  CODE: $param type inferred as arrayref from default");
			}
		}
	}

	if($code =~ /(croak|die)\(.*\)\s+if\s*\(\s*scalar\(\@_\)\s*<\s*(\d+)\s*\)/s) {
		my $required_count = $2;
		my @param_names = sort { $params{$a}{position} <=> $params{$b}{position} } keys %params;
		for my $i (0 .. $required_count-1) {
			$params{$param_names[$i]}{optional} = 0;
			$self->_log("  CODE: $param_names[$i] marked required due to croak scalar check");
		}
	} elsif ($code =~ /(croak|die)\(.*\)\s+if\s*\(\s*scalar\(\@_\)\s*==\s*(0)\s*\)/s) {
		foreach my $param (keys %params) {
			$params{$param}{optional} = 0;
			$self->_log("  CODE: $param: all parameters are required to so scalar check against 0");
		}
	}

	# Analyze each parameter (with safety limit)
	foreach my $param (keys %params) {
		if ($param_count++ > $self->{max_parameters}) {
			$self->_log("  WARNING: Max parameters ($self->{max_parameters}) exceeded, skipping remaining");
			last;
		}

		my $p = \$params{$param};

		$self->_analyze_parameter_type($p, $param, $code);
		$self->_analyze_parameter_constraints($p, $param, $code);
		$self->_analyze_parameter_validation($p, $param, $code);
		$self->_analyze_advanced_types($p, $param, $code);

		# Defined checks
		if ($code =~ /defined\s*\(\s*\$$param\s*\)/) {
			$$p->{optional} = 0;
			$self->_log("  CODE: $param is required (defined check)");
		}

		# Exists checks for hash keys
		if ($code =~ /exists\s*\(\s*\$$param\s*\)/) {
			$$p->{type} = 'hashkey';
			$self->_log("  CODE: $param is a hash key");
		}

		# Scalar context for arrays
		if ($code =~ /scalar\s*\(\s*\@?\$$param\s*\)/) {
			$$p->{type} = 'array';
			$self->_log("  CODE: $param used in scalar context (array)");
		}

		$self->_extract_error_constraints($p, $param, $code);
	}

	return \%params;
}

sub _analyze_parameter_type {
	my ($self, $p_ref, $param, $code) = @_;
	my $p = $$p_ref;

	# Type inference from ref() checks
	if ($code =~ /ref\s*\(\s*\$$param\s*\)\s*eq\s*['"](ARRAY|HASH|SCALAR)['"]/gi) {
		my $reftype = lc($1);
		$p->{type} = $reftype eq 'array' ? 'arrayref' :
					 $reftype eq 'hash' ? 'hashref' :
					 'scalar';
		$self->_log("  CODE: $param is $p->{type} (ref check)");
	}
	# ISA checks for objects
	elsif ($code =~ /\$$param\s*->\s*isa\s*\(\s*['"]([^'"]+)['"]\s*\)/i) {
		$p->{type} = 'object';
		$p->{isa} = $1;
		$self->_log("  CODE: $param is object of class $1");
	}
	# Blessed references
	elsif ($code =~ /bless\s+.*\$$param/) {
		$p->{type} = 'object';
		$self->_log("  CODE: $param is blessed object");
	}
	# Array/hash operations
	if (!$p->{type}) {
		if ($code =~ /\@\{\s*\$$param\s*\}/ || $code =~ /push\s*\(\s*\@?\$$param/) {
			$p->{type} = 'arrayref';
		} elsif ($code =~ /\%\{\s*\$$param\s*\}/ || $code =~ /\$$param\s*->\s*\{/) {
			$p->{type} = 'hashref';
		}
	}

	# Infer type from the default value if type is unknown
	if (!$p->{type} && exists $p->{default}) {
		my $default = $p->{default};
		if (ref($default) eq 'HASH') {
			$p->{type} = 'hashref';
			$self->_log("  CODE: $param type inferred as hashref from default");
		} elsif (ref($default) eq 'ARRAY') {
			$p->{type} = 'arrayref';
			$self->_log("  CODE: $param type inferred as arrayref from default");
		}
	}

	# ------------------------------------------------------------
	# Heuristic numeric inference (low confidence)
	# ------------------------------------------------------------
	if (!$p->{type}) {
		# Numeric operators: + - * / % **
		if (
			$code =~ /\$$param\s*[\+\-\*\/%]/ ||
			$code =~ /[\+\-\*\/%]\s*\$$param/ ||
			$code =~ /\bint\s*\(\s*\$$param\s*\)/ ||
			$code =~ /\babs\s*\(\s*\$$param\s*\)/
		) {
			$p->{type} = 'number';
			$p->{_type_confidence} = 'heuristic';
			$self->_log("  CODE: $param inferred as number (numeric operator)");
		}
		# Numeric comparison
		elsif (
			$code =~ /\$$param\s*(?:==|!=|<=|>=|<|>)/ ||
			$code =~ /(?:==|!=|<=|>=|<|>)\s*\$$param/
		) {
			$p->{type} = 'number';
			$p->{_type_confidence} = 'heuristic';
			$self->_log("  CODE: $param inferred as number (numeric comparison)");
		}
	}
}

=head2 _analyze_advanced_types

Enhanced type detection for DateTime, file handles, coderefs, and enums.
This adds semantic type information that can guide test generation.

=cut

sub _analyze_advanced_types {
	my ($self, $p_ref, $param, $code) = @_;

	# Dereference once to get the hash reference
	my $p = $$p_ref;

	# Now pass the dereferenced hash to the detection methods
	$self->_detect_datetime_type($p, $param, $code);
	$self->_detect_filehandle_type($p, $param, $code);
	$self->_detect_coderef_type($p, $param, $code);
	$self->_detect_enum_type($p, $param, $code);
}

=head2 _detect_datetime_type

Detect DateTime objects and date/time string parameters.

=cut

sub _detect_datetime_type {
	my ($self, $p, $param, $code) = @_;

	# Validate param is just a simple word
	return unless defined $param && $param =~ /^\w+$/;

	# DateTime object detection via isa/UNIVERSAL checks
	if ($code =~ /\$$param\s*->\s*isa\s*\(\s*['"]DateTime['"]\s*\)/i) {
		$p->{type} = 'object';
		$p->{isa} = 'DateTime';
		$p->{semantic} = 'datetime_object';
		$self->_log("  ADVANCED: $param is DateTime object");
		return;
	}

	# Check for DateTime method calls
	if ($code =~ /\$$param\s*->\s*(ymd|dmy|mdy|hms|iso8601|epoch|strftime)/) {
		$p->{type} = 'object';
		$p->{isa} = 'DateTime';
		$p->{semantic} = 'datetime_object';
		$self->_log("  ADVANCED: $param uses DateTime methods");
		return;
	}

	# Time::Piece detection
	if ($code =~ /\$$param\s*->\s*isa\s*\(\s*['"]Time::Piece['"]\s*\)/i ||
	    $code =~ /\$$param\s*->\s*(strftime|epoch|year|mon|mday)/) {
		$p->{type} = 'object';
		$p->{isa} = 'Time::Piece';
		$p->{semantic} = 'timepiece_object';
		$self->_log("  ADVANCED: $param is Time::Piece object");
		return;
	}

	# String date/time patterns via regex matching
	if ($code =~ /\$$param\s*=~\s*\/.*?\\d\{4\}.*?\\d\{2\}.*?\\d\{2\}/) {
		$p->{type} = 'string';
		$p->{semantic} = 'date_string';
		$p->{format} = 'YYYY-MM-DD or similar';
		$self->_log("  ADVANCED: $param validated as date string pattern");
		return;
	}

	# ISO 8601 date pattern
	if ($code =~ /\$$param\s*=~\s*\/.*?[Tt].*?[Zz].*?\//) {
		$p->{type} = 'string';
		$p->{semantic} = 'iso8601_string';
		$p->{matches} = '/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z?$/';
		$self->_log("  ADVANCED: $param validated as ISO 8601 datetime");
		return;
	}

	# UNIX timestamp detection (numeric with specific range)
	if ($code =~ /\$$param\s*>\s*\d{9,}/ || # UNIX timestamps are 10+ digits
	    $code =~ /time\(\s*\)\s*-\s*\$$param/ ||
	    $code =~ /\$$param\s*-\s*time\(\s*\)/) {
		$p->{type} = 'integer';
		$p->{semantic} = 'unix_timestamp';
		$p->{min} = 0;
		$self->_log("  ADVANCED: $param appears to be UNIX timestamp");
		return;
	}

	# Date parsing with strptime or similar
	if ($code =~ /strptime\s*\(\s*\$$param/ ||
	    $code =~ /DateTime::Format::\w+\s*->\s*parse_datetime\s*\(\s*\$$param/) {
		$p->{type} = 'string';
		$p->{semantic} = 'datetime_parseable';
		$self->_log("  ADVANCED: $param is parsed as datetime");
		return;
	}
}

=head2 _detect_filehandle_type

Detect file handle parameters and file path strings.

=cut

sub _detect_filehandle_type {
	my ($self, $p, $param, $code) = @_;

	return unless defined $param && $param =~ /^\w+$/;

	# File handle operations
	if ($code =~ /(?:open|close|read|print|say|sysread|syswrite)\s*\(?\s*\$$param/) {
		$p->{type} = 'object';
		$p->{isa} = 'IO::Handle';
		$p->{semantic} = 'filehandle';
		$self->_log("  ADVANCED: $param is a file handle");
		return;
	}

	# Filehandle-specific operations
	if ($code =~ /\$$param\s*->\s*(readline|getline|print|say|close|flush|autoflush)/) {
		$p->{type} = 'object';
		$p->{isa} = 'IO::Handle';
		$p->{semantic} = 'filehandle';
		$self->_log("  ADVANCED: $param uses filehandle methods");
		return;
	}

	# File test operators
	if ($code =~ /(?:-[frwxoOeszlpSbctugkTBMAC])\s+\$$param/) {
		$p->{type} = 'string';
		$p->{semantic} = 'filepath';
		$self->_log("  ADVANCED: $param is tested as file path");
		return;
	}

	# File::Spec operations or path manipulation
	if ($code =~ /File::(?:Spec|Basename)::\w+\s*\(\s*\$$param/ ||
	    $code =~ /(?:basename|dirname|fileparse)\s*\(\s*\$$param/) {
		$p->{type} = 'string';
		$p->{semantic} = 'filepath';
		$self->_log("  ADVANCED: $param manipulated as file path");
		return;
	}

	# Path validation patterns
	# Only match a literal path assigned or defaulted to this variable
	if(defined $p->{default} && $p->{default} =~ m{^([A-Za-z]:\\|/|\./|\.\./)}) {
		$p->{type} = 'string';
		$p->{semantic} = 'filepath';
		$self->_log("  ADVANCED: $param default looks like a path");
		return;
	}

	# IO::File detection
	if ($code =~ /\$$param\s*->\s*isa\s*\(\s*['"]IO::File['"]\s*\)/ ||
	    $code =~ /IO::File\s*->\s*new\s*\(\s*\$$param/) {
		$p->{type} = 'object';
		$p->{isa} = 'IO::File';
		$p->{semantic} = 'filehandle';
		$self->_log("  ADVANCED: $param is IO::File object");
		return;
	}
}

=head2 _detect_coderef_type

Detect coderef/callback parameters.

=cut

sub _detect_coderef_type {
	my ($self, $p, $param, $code) = @_;

	return unless defined $param && $param =~ /^\w+$/;

	# ref() check for CODE
	if ($code =~ /ref\s*\(\s*\$$param\s*\)\s*eq\s*['"]CODE['"]/i) {
		$p->{type} = 'coderef';
		$p->{semantic} = 'callback';
		$self->_log("  ADVANCED: $param is coderef (ref check)");
		return;
	}

	# Invocation as coderef - note the escaped @ in \@_
	if ($code =~ /\$$param\s*->\s*\(/ ||
	    $code =~ /\$$param\s*->\s*\(\s*\@_\s*\)/ ||
	    $code =~ /&\s*\{\s*\$$param\s*\}/) {
		$p->{type} = 'coderef';
		$p->{semantic} = 'callback';
		$self->_log("  ADVANCED: $param invoked as coderef");
		return;
	}

	# Parameter name suggests callback
	if ($param =~ /^(?:callback|cb|handler|sub|code|fn|func|on_\w+)$/i) {
		$p->{type} = 'coderef';
		$p->{semantic} = 'callback';
		$self->_log("  ADVANCED: $param name suggests coderef");
		return;
	}

	# Blessed coderef (unusual but valid)
	if ($code =~ /blessed\s*\(\s*\$$param\s*\)/ &&
	    $code =~ /ref\s*\(\s*\$$param\s*\)\s*eq\s*['"]CODE['"]/i) {
		$p->{type} = 'object';
		$p->{isa} = 'blessed_coderef';
		$p->{semantic} = 'callback';
		$self->_log("  ADVANCED: $param is blessed coderef");
		return;
	}
}

=head2 _detect_enum_type

Detect enum-like parameters with fixed set of valid values.

=cut

sub _detect_enum_type {
	my ($self, $p, $param, $code) = @_;

	return unless defined $param && $param =~ /^\w+$/;

	# Pattern 1: die/croak unless value is in list
	# die 'Invalid status' unless $status =~ /^(active|inactive|pending)$/;
	if ($code =~ /unless\s+\$$param\s*=~\s*\/\^?\(([^)]+)\)/) {
		my $values = $1;
		my @enum_values = split(/\|/, $values);
		$p->{type} = 'string' unless $p->{type};
		$p->{enum} = \@enum_values;
		$p->{semantic} = 'enum';
		$self->_log("  ADVANCED: $param is enum with values: " . join(', ', @enum_values));
		return;
	}

	# Pattern 2: Hash lookup for validation
	# my %valid = map { $_ => 1 } qw(red green blue);
	# die unless $valid{$param};
	if ($code =~ /\%(\w+)\s*=.*?qw\s*[\(\[<{]([^)\]>}]+)[\)\]>}]/) {
		my $hash_name = $1;
		my $values_str = $2;
		if (defined $values_str && $code =~ /\$$hash_name\s*\{\s*\$$param\s*\}/) {
			my @enum_values = split(/\s+/, $values_str);
			$p->{type} = 'string' unless $p->{type};
			$p->{enum} = \@enum_values;
			$p->{semantic} = 'enum';
			$self->_log("  ADVANCED: $param validated via hash lookup: " . join(', ', @enum_values));
			return;
		}
	}

	# Pattern 3: Array grep validation
	# die unless grep { $_ eq $param } qw(foo bar baz);
	if ($code =~ /grep\s*\{[^}]*\$$param[^}]*\}\s*qw\s*[\(\[<{]([^)\]>}]+)[\)\]>}]/) {
		my $values_str = $1;
		my @enum_values = split(/\s+/, $values_str);
		$p->{type} = 'string' unless $p->{type};
		$p->{enum} = \@enum_values;
		$p->{semantic} = 'enum';
		$self->_log("  ADVANCED: $param validated via grep: " . join(', ', @enum_values));
		return;
	}

	# Pattern 4: Given/when (Perl 5.10+)
	if ($code =~ /given\s*\(\s*\$$param\s*\)/) {
		my @enum_values;
		while ($code =~ /when\s*\(\s*['"]([^'"]+)['"]\s*\)/g) {
			push @enum_values, $1;
		}
		if (@enum_values >= 2) {
			$p->{type} = 'string' unless $p->{type};
			$p->{enum} = \@enum_values;
			$p->{semantic} = 'enum';
			$self->_log("  ADVANCED: $param has enum values from given/when: " .
			           join(', ', @enum_values));
			return;
		}
	}

	# Pattern 5: Multiple if/elsif checking specific values
	my @if_values;
	while ($code =~ /if\s*\(\s*\$$param\s*eq\s*['"]([^'"]+)['"]\s*\)/g) {
		push @if_values, $1;
	}
	while ($code =~ /elsif\s*\(\s*\$$param\s*eq\s*['"]([^'"]+)['"]\s*\)/g) {
		push @if_values, $1;
	}
	if (@if_values >= 3) {
		$p->{type} = 'string' unless $p->{type};
		$p->{enum} = \@if_values;
		$p->{semantic} = 'enum';
		$self->_log("  ADVANCED: $param appears to be enum from if/elsif: " .
		           join(', ', @if_values));
		return;
	}

	# Pattern 6: Smart match (~~) with array
	if ($code =~ /\$$param\s*~~\s*\[([^\]]+)\]/ ||
	    $code =~ /\$$param\s*~~\s*qw\s*[\(\[<{]([^)\]>}]+)[\)\]>}]/) {
		my $values_str = $1;
		my @enum_values;
		if ($values_str =~ /['"]/) {
			@enum_values = $values_str =~ /['"](.*?)['"]/g;
		} else {
			@enum_values = split(/\s+/, $values_str);
		}
		if (@enum_values) {
			$p->{type} = 'string' unless $p->{type};
			$p->{enum} = \@enum_values;
			$p->{semantic} = 'enum';
			$self->_log("  ADVANCED: $param validated with smart match: " .
				   join(', ', @enum_values));
			return;
		}
	}
}

sub _extract_error_constraints {
	my ($self, $p, $param, $code) = @_;

	# Look for die/croak/confess with a condition involving this param
	while ($code =~ /
		(?:die|croak|confess)       # error call
		\s*
		(?:
			["']([^"']+)["']        # captured error message
		|
			q[qw]?\s*[\(\[]([^)\]]+)[\)\]]  # q(), qq(), qw()
		)?
		\s*
		if\s+
		(.+?)                      # condition
		\s*;
	/gsx) {

		my $message = $1 || $2;
		my $condition = $3;

		# Only keep conditions that reference this parameter
		next unless $condition =~ /\$$param\b/;

		# Initialize storage
		$$p->{_invalid} ||= [];
		$$p->{_errors}  ||= [];

		# Normalize condition (strip surrounding parens)
		$condition =~ s/^\(|\)$//g;
		$condition =~ s/\s+/ /g;

		# Try to extract a meaningful invalid constraint
		my $constraint;

		# Examples:
		#   $age <= 0
		#   $x eq ''
		#   length($s) < 3
		if ($condition =~ /\$$param\s*([!<>=]=?|eq|ne|lt|gt|le|ge)\s*(.+)/) {
			$constraint = "$1 $2";
		}
		elsif ($condition =~ /length\s*\(\s*\$$param\s*\)\s*([<>=!]+)\s*(\d+)/) {
			$constraint = "length $1 $2";
		}
		elsif ($condition =~ /\$$param\s*==\s*0/) {
			$constraint = '== 0';
		}

		# Store results
		push @{ $$p->{_invalid} }, $constraint if $constraint;
		push @{ $$p->{_errors}  }, $message   if defined $message;

		$self->_log(
			"  ERROR: $param invalid when [$condition]" .
			(defined $message ? " => '$message'" : '')
		);
	}

	# Numeric comparison with literal
	if ($code =~ /\b\Q$param\E\s*(<=|<|>=|>)\s*(-?\d+)/) {
		my ($op, $num) = ($1, $2);

		# Mark required
		$$p->{optional} = 0;

		if ($op eq '<=') {
			$$p->{min} = $num + 1;
			# push @{ $$p->{_invalid} }, "<= $num";
		} elsif ($op eq '<') {
			$$p->{min} = $num;
			# push @{ $$p->{_invalid} }, "< $num";
		} elsif ($op eq '>=') {
			$$p->{max} = $num - 1;
			# push @{ $$p->{_invalid} }, ">= $num";
		} elsif ($op eq '>') {
			$$p->{max} = $num;
			# push @{ $$p->{_invalid} }, "> $num";
		}

		$self->_log("  ERROR: $param normalized constraint from '$op $num'");
	}
}

# Enhanced signature extraction with modern Perl support
sub _extract_parameters_from_signature {
	my ($self, $params, $code) = @_;

	# Modern Style: Subroutine signatures with attributes
	# Handle multi-line signatures
	# sub foo :attr1 :attr2(val) (
	#     $self,
	#     $x :Type,
	#     $y = default
	# ) { }

	# Try to match signature after attributes
	# Look for the parameter list - it's the last (...) before the opening brace
	# that contains sigils ($, %, @)
	if ($code =~ /sub\s+\w+\s*(?::\w+(?:\([^)]*\))?\s*)*\(((?:[^()]|\([^)]*\))*)\)\s*\{/s) {
		my $potential_sig = $1;

		# Check if this looks like parameters (has sigils)
		if ($potential_sig =~ /[\$\%\@]/) {
			$self->_log("  SIG: Found modern signature: ($potential_sig)");
			$self->_parse_modern_signature($params, $potential_sig);
			return;
		}
	}

	# Traditional Style 1: my ($self, $arg1, $arg2) = @_;
	if ($code =~ /my\s*\(\s*([^)]+)\)\s*=\s*\@_/s) {
		my $sig = $1;
		my $pos = 0;

		while ($sig =~ /\$(\w+)/g) {
			my $name = $1;

			next if $name =~ /^(self|class)$/i;

			$params->{$name} //= {
				_source => 'code',
				optional => 1,
			};

			$params->{$name}{position} = $pos unless exists $params->{$name}{position};

			$pos++;
		}
		return;
	} elsif ($code =~ /my\s+\$self\s*=\s*shift/) {
		# Traditional Style 2: my $self = shift; my $arg1 = shift;
		my @shifts;
		while ($code =~ /my\s+\$(\w+)\s*=\s*shift/g) {
			push @shifts, $1;
		}
		shift @shifts if @shifts && $shifts[0] =~ /^(self|class)$/i;
		my $pos = 0;
		foreach my $param (@shifts) {
			$params->{$param} ||= { _source => 'code', optional => 1, position => $pos++ };
		}
		return;
	}

	# Traditional Style 3: Function parameters (no $self)
	if ($code =~ /my\s*\(\s*([^)]+)\)\s*=\s*\@_/s) {
		my $sig = $1;
		my @param_names = $sig =~ /\$(\w+)/g;
		my $pos = 0;
		foreach my $param (@param_names) {
			next if $param =~ /^(self|class)$/i;
			$params->{$param} ||= { _source => 'code', optional => 1, position => $pos++ };
		}
	}

	# De-duplicate
	my %seen;
	foreach my $param (keys %$params) {
		if ($seen{$param}++) {
			$self->_log("  WARNING: Duplicate parameter '$param' found");
		}
	}
}

# Parse modern Perl signatures (5.20+)
sub _parse_modern_signature {
	my ($self, $params, $sig) = @_;

	$self->_log("  DEBUG: Parsing signature: [$sig]");

	# Split signature by commas, but respect nested structures
	my @parts;
	my $current = '';
	my $depth = 0;

	for my $char (split //, $sig) {
		if ($char eq '(' || $char eq '[' || $char eq '{') {
			$depth++;
			$current .= $char;
		} elsif ($char eq ')' || $char eq ']' || $char eq '}') {
			$depth--;
			$current .= $char;
		} elsif ($char eq ',' && $depth == 0) {
			push @parts, $current;
			$current = '';
		} else {
			$current .= $char;
		}
	}
	push @parts, $current if $current =~ /\S/;

	my $position = 0;

	foreach my $part (@parts) {
		$part =~ s/^\s+|\s+$//g;

		# Skip empty parts
		next unless $part;

		# Parse different parameter types
		my $param_info = $self->_parse_signature_parameter($part, $position);

		if ($param_info) {
			my $name = $param_info->{name};

			# Skip self/class
			if ($name =~ /^(self|class)$/i) {
				next;
			}

			$params->{$name} = $param_info;
			$self->_log("  SIG: $name has position $position" .
				($param_info->{optional} ? " (optional)" : '') .
				($param_info->{default} ? ", default: $param_info->{default}" : ''));
			$position++;
		}
	}
}

# Parse individual signature parameter
sub _parse_signature_parameter {
	my ($self, $part, $position) = @_;

	my %info = (
		_source => 'signature',
		position => $position,
		optional => 0,
	);

	# Pattern 1: Type constraint WITH default: $name :Type = default
	if ($part =~ /^\$(\w+)\s*:\s*(\w+)\s*=\s*(.+)$/s) {
		my ($name, $constraint, $default) = ($1, $2, $3);
		$default =~ s/^\s+|\s+$//g;

		$info{name} = $name;
		$info{optional} = 1;
		$info{default} = $self->_clean_default_value($default, 1);

		# Apply type constraint
		if ($constraint =~ /^(Int|Integer)$/i) {
			$info{type} = 'integer';
		} elsif ($constraint =~ /^(Num|Number)$/i) {
			$info{type} = 'number';
		} elsif ($constraint =~ /^(Str|String)$/i) {
			$info{type} = 'string';
		} elsif ($constraint =~ /^(Bool|Boolean)$/i) {
			$info{type} = 'boolean';
		} elsif ($constraint =~ /^(Array|ArrayRef)$/i) {
			$info{type} = 'arrayref';
		} elsif ($constraint =~ /^(Hash|HashRef)$/i) {
			$info{type} = 'hashref';
		} else {
			$info{type} = 'object';
			$info{isa} = $constraint;
		}

		return \%info;
	} elsif ($part =~ /^\$(\w+)\s*:\s*(\w+)\s*$/s) {
		# Pattern 2: Type constraint WITHOUT default: $name :Type
		my ($name, $constraint) = ($1, $2);
		$info{name} = $name;
		$info{optional} = 0;

		# Apply type constraint (same as above)
		if ($constraint =~ /^(Int|Integer)$/i) {
			$info{type} = 'integer';
		} elsif ($constraint =~ /^(Num|Number)$/i) {
			$info{type} = 'number';
		} elsif ($constraint =~ /^(Str|String)$/i) {
			$info{type} = 'string';
		} elsif ($constraint =~ /^(Bool|Boolean)$/i) {
			$info{type} = 'boolean';
		} elsif ($constraint =~ /^(Array|ArrayRef)$/i) {
			$info{type} = 'arrayref';
		} elsif ($constraint =~ /^(Hash|HashRef)$/i) {
			$info{type} = 'hashref';
		} else {
			$info{type} = 'object';
			$info{isa} = $constraint;
		}

		return \%info;
	} elsif ($part =~ /^\$(\w+)\s*=\s*(.+)$/s) {
		# Pattern 3: Default WITHOUT type: $name = default
		my ($name, $default) = ($1, $2);
		$default =~ s/^\s+|\s+$//g;

	$info{name} = $name;
	$info{optional} = 1;
	$info{default} = $self->_clean_default_value($default, 1);
	$info{type} = $self->_infer_type_from_default($info{default}) if $self->can('_infer_type_from_default');

	return \%info;
	}

    # Pattern 4: Plain parameter: $name
    elsif ($part =~ /^\$(\w+)$/s) {
        $info{name} = $1;
        $info{optional} = 0;
        return \%info;
    }

    # Pattern 5: Array parameter: @name
    elsif ($part =~ /^\@(\w+)$/s) {
        $info{name} = $1;
        $info{type} = 'array';
        $info{slurpy} = 1;
        $info{optional} = 1;
        return \%info;
    }

    # Pattern 6: Hash parameter: %name
    elsif ($part =~ /^\%(\w+)$/s) {
        $info{name} = $1;
        $info{type} = 'hash';
        $info{slurpy} = 1;
        $info{optional} = 1;
        return \%info;
    }

	return undef;
}

# Helper: Infer type from default value
sub _infer_type_from_default {
	my ($self, $default) = @_;

	return undef unless defined $default;

	if (ref($default) eq 'HASH') {
		return 'hashref';
	} elsif (ref($default) eq 'ARRAY') {
		return 'arrayref';
	} elsif ($default =~ /^-?\d+$/) {
		return 'integer';
	} elsif ($default =~ /^-?\d+\.\d+$/) {
		return 'number';
	} elsif ($default eq '1' || $default eq '0') {
		return 'boolean';
	} else {
		return 'string';
	}
}

# Extract subroutine attributes
sub _extract_subroutine_attributes {
	my ($self, $code) = @_;

	my %attributes;

	# Extract all attributes from the sub declaration
	# Attributes are :name or :name(value) between sub name and either ( or {
	# Pattern: sub name ATTRIBUTES ( params ) { }
	# or:      sub name ATTRIBUTES { }

	# First, find the attributes section (everything between sub name and ( or { )
	my $attr_section = '';

	if ($code =~ /sub\s+\w+\s+((?::\w+(?:\([^)]*\))?\s*)+)/s) {
		$attr_section = $1;
	}

	# Parse individual attributes from the section
	if ($attr_section) {
		while ($attr_section =~ /:(\w+)(?:\(([^)]*)\))?/g) {
			my ($name, $value) = ($1, $2);

			if (defined $value && $value ne '') {
				$attributes{$name} = $value;
				$self->_log("  ATTR: Found attribute :$name($value)");
			} else {
				$attributes{$name} = 1;
				$self->_log("  ATTR: Found attribute :$name");
			}
		}
	}

	# Process common attributes
	if ($attributes{Returns}) {
		my $return_type = $attributes{Returns};
		if ($return_type ne '1') {  # Only log if it's an actual type, not just the flag
			$self->_log("  ATTR: Method declares return type: $return_type");
		}
	}

	if ($attributes{lvalue}) {
		$self->_log("  ATTR: Method is lvalue (can be assigned to)");
	}

	if ($attributes{method}) {
		$self->_log("  ATTR: Method explicitly marked as :method");
	}

	return \%attributes;
}

# Detect postfix dereferencing in code
sub _analyze_postfix_dereferencing {
	my ($self, $code) = @_;

	my %derefs;

    # Array dereference: $ref->@*
    if ($code =~ /\$\w+\s*->\s*\@\*/) {
        $derefs{array_deref} = 1;
        $self->_log("  MODERN: Uses postfix array dereferencing (->@*)");
    }

    # Hash dereference: $ref->%*
    if ($code =~ /\$\w+\s*->\s*\%\*/) {
        $derefs{hash_deref} = 1;
        $self->_log("  MODERN: Uses postfix hash dereferencing (->%*)");
    }

    # Scalar dereference: $ref->$*
    if ($code =~ /\$\w+\s*->\s*\$\*/) {
        $derefs{scalar_deref} = 1;
        $self->_log('  MODERN: Uses postfix scalar dereferencing (->$*)');
    }

    # Code dereference: $ref->&*
    if ($code =~ /\$\w+\s*->\s*\&\*/) {
        $derefs{code_deref} = 1;
        $self->_log("  MODERN: Uses postfix code dereferencing (->&*)");
    }

    # Array element: $ref->@[0,2,4]
    if ($code =~ /\$\w+\s*->\s*\@\[/) {
        $derefs{array_slice} = 1;
        $self->_log("  MODERN: Uses postfix array slice (->@[...])");
    }

    # Hash element: $ref->%{key1,key2}
    if ($code =~ /\$\w+\s*->\s*\%\{/) {
        $derefs{hash_slice} = 1;
        $self->_log("  MODERN: Uses postfix hash slice (->%{...})");
    }

    return \%derefs;
}

# Extract field declarations (Perl 5.38+)
sub _extract_field_declarations {
	my ($self, $code) = @_;

	my %fields;

	# Pattern: field $name :param;
	# Pattern: field $name :param(name);
	# Pattern: field $name = default;
	# More lenient pattern to catch various formats
	while ($code =~ /^\s*field\s+\$(\w+)\s*([^;]*);/gm) {
		my ($name, $modifiers) = ($1, $2);

		$self->_log("  FIELD: Found field \$$name with modifiers: [$modifiers]");

		my %field_info = (
			name => $name,
			_source => 'field'
		);

        # Check for :param attribute
        if ($modifiers =~ /:param(?:\(([^)]+)\))?/) {
            $field_info{is_param} = 1;

            if (defined $1) {
                # Explicit parameter name
                $field_info{param_name} = $1;
            } else {
                # Implicit - field name is param name
                $field_info{param_name} = $name;
            }

            $self->_log("  FIELD: $name maps to parameter: $field_info{param_name}");
        }

        # Check for default value - must come before type constraint check
        if ($modifiers =~ /=\s*([^:;]+)(?::|;|$)/) {
		my $default = $1;
		$default =~ s/\s+$//;
		$field_info{default} = $self->_clean_default_value($default, 1);
		$field_info{optional} = 1;
		$self->_log("  FIELD: $name has default: " .  (defined $field_info{default} ? $field_info{default} : 'undef'));
	}

	# Check for type constraints
	if ($modifiers =~ /:isa\(([^)]+)\)/) {
	    $field_info{isa} = $1;
	    $field_info{type} = 'object';
	    $self->_log("  FIELD: $name has type constraint: $1");
	}

		$fields{$name} = \%field_info;
	}

	return \%fields;
}

# Integrate field declarations into parameters
sub _merge_field_declarations {
	my ($self, $params, $fields) = @_;

	foreach my $field_name (keys %$fields) {
		my $field = $fields->{$field_name};

		# Only process fields that are parameters
		next unless $field->{is_param};

	my $param_name = $field->{param_name};

	# Create or update parameter info
        $params->{$param_name} ||= {};
	my $p = $params->{$param_name};

        # Merge field information into parameter
        $p->{_source} = 'field' unless $p->{_source};
        $p->{field_name} = $field_name if $field_name ne $param_name;

        if ($field->{default}) {
            $p->{default} = $field->{default};
            $p->{optional} = 1;
        }

        if ($field->{isa}) {
            $p->{isa} = $field->{isa};
            $p->{type} = 'object';
        }

        $self->_log("  MERGED: Field $field_name -> parameter $param_name");
    }
}

sub _extract_defaults_from_code {
	my ($self, $params, $code) = @_;

	# Pattern 1: my $param = value;
	while ($code =~ /my\s+\$(\w+)\s*=\s*([^;]+);/g) {
		my ($param, $value) = ($1, $2);
		next unless exists $params->{$param};

		$params->{$param}{default} = $self->_clean_default_value($value, 1);
		$params->{$param}{optional} = 1;
	$self->_log("  CODE: $param has default: " . $self->_format_default($params->{$param}{default}));
	}

	# Pattern 2: $param = value unless defined $param;
	while ($code =~ /\$(\w+)\s*=\s*([^;]+?)\s+unless\s+(?:defined\s+)?\$\1/g) {
		my ($param, $value) = ($1, $2);
		next unless exists $params->{$param};

		$params->{$param}{default} = $self->_clean_default_value($value, 1);
		$params->{$param}{optional} = 1;
		$self->_log("  CODE: $param has default (unless): " . $self->_format_default($params->{$param}{default}));
	}

	# Pattern 3: $param = value unless $param;
	while ($code =~ /\$(\w+)\s*=\s*([^;]+?)\s+unless\s+\$\1/g) {
		my ($param, $value) = ($1, $2);
		next unless exists $params->{$param};

		$params->{$param}{default} = $self->_clean_default_value($value, 1);
		$params->{$param}{optional} = 1;
		$self->_log("  CODE: $param has default (unless): " . $self->_format_default($params->{$param}{default}));
	}

	# Pattern 4: $param = $param || 'default';
	while ($code =~ /\$(\w+)\s*=\s*\$\1\s*\|\|\s*([^;]+);/g) {
		my ($param, $value) = ($1, $2);
		next unless exists $params->{$param};

		$params->{$param}{default} = $self->_clean_default_value($value, 1);
		$params->{$param}{optional} = 1;
		$self->_log("  CODE: $param has default (||): " . $self->_format_default($params->{$param}{default}));
	}

	# Pattern 5: $param ||= 'default';
	while ($code =~ /\$(\w+)\s*\|\|=\s*([^;]+);/g) {
		my ($param, $value) = ($1, $2);
		next unless exists $params->{$param};

		$params->{$param}{default} = $self->_clean_default_value($value, 1);
		$params->{$param}{optional} = 1;
		$self->_log("  CODE: $param has default (||=): " . $self->_format_default($params->{$param}{default}));
	}

	# Pattern 6: $param //= 'default';
	while ($code =~ /\$(\w+)\s*\/\/=\s*([^;]+);/g) {
		my ($param, $value) = ($1, $2);
		next unless exists $params->{$param};  # Using -> because $params is a reference

		$params->{$param}{default} = $self->_clean_default_value($value, 1);

		$params->{$param}{optional} = 1;
		$self->_log("  CODE: $param has default (//=): " . $self->_format_default($params->{$param}{default}));
	}

	# Pattern 7: $param = defined $param ? $param : 'default';
	while ($code =~ /\$(\w+)\s*=\s*defined\s+\$\1\s*\?\s*\$\1\s*:\s*([^;]+);/g) {
		my ($param, $value) = ($1, $2);

		# Create param entry if it doesn't exist
		$params->{$param} ||= {};

		my $cleaned = $self->_clean_default_value($value, 1);

		$params->{$param}{default} = $cleaned;
		$params->{$param}{optional} = 1;
		$self->_log("  CODE: $param has default (ternary): " . $self->_format_default($params->{$param}{default}));
	}

	# Pattern 8: $param = $args{param} || 'default';
	while ($code =~ /\$(\w+)\s*=\s*\$args\{['"]?\w+['"]?\}\s*\|\|\s*([^;]+);/g) {
		my ($param, $value) = ($1, $2);
		next unless exists $params->{$param};

		$params->{$param}{default} = $self->_clean_default_value($value, 1);
		$params->{$param}{optional} = 1;
		$self->_log("  CODE: $param has default (from args): " . $self->_format_default($params->{$param}{default}));
	}

	# Pattern for non-empty hashref
	while ($code =~ /\$(\w+)\s*\|\|=\s*\{[^}]+\}/gs) {
		my $param = $1;
		next unless exists $params->{$param};

		# Return empty hashref as placeholder (can't evaluate complex hashrefs)
		$params->{$param}{default} = {};
		$params->{$param}{optional} = 1;
		$self->_log("  CODE: $param has hashref default (||=)");
	}
}

sub _format_default {
	my ($self, $default) = @_;
	return 'undef' unless defined $default;
	return ref($default) . ' ref' if ref($default);
	return $default;
}

sub _analyze_parameter_constraints {
	my ($self, $p_ref, $param, $code) = @_;
	my $p = $$p_ref;

	# Do not treat comparisons inside die/croak/confess as valid constraints
	my $guarded = 0;
		if ($code =~ /(die|croak|confess)\b[^{;]*\bif\b[^{;]*\$$param\b/s) {
		$guarded = 1;
	}

	# Length checks for strings
	if ($code =~ /length\s*\(\s*\$$param\s*\)\s*([<>]=?)\s*(\d+)/) {
		my ($op, $val) = ($1, $2);
		$p->{type} ||= 'string';
		if ($op eq '<') {
			$p->{max} = $val - 1;
		} elsif ($op eq '<=') {
			$p->{max} = $val;
		} elsif ($op eq '>') {
			$p->{min} = $val + 1;
		} elsif ($op eq '>=') {
			$p->{min} = $val;
		}
		$self->_log("  CODE: $param length constraint $op $val");
	}

	# Numeric range checks (only if NOT part of error guard)
	if (
		!$guarded
		&& $code =~ /\$$param\s*([<>]=?)\s*([+-]?(?:\d+\.?\d*|\.\d+))/
	) {
		my ($op, $val) = ($1, $2);
		$p->{type} ||= looks_like_number($val) ? 'number' : 'integer';

		if ($op eq '<' || $op eq '<=') {
			# Only set max if it tightens the range
			my $max = ($op eq '<') ? $val - 1 : $val;
			$p->{max} = $max if !defined($p->{max}) || $max < $p->{max};
		} elsif ($op eq '>' || $op eq '>=') {
			my $min = ($op eq '>') ? $val + 1 : $val;
			$p->{min} = $min if !defined($p->{min}) || $min > $p->{min};
		}
	}

	# Regex pattern matching with better capture
	if ($code =~ /\$$param\s*=~\s*((?:qr?\/[^\/]+\/|\$[\w:]+|\$\{\w+\}))/) {
		my $pattern = $1;
		$p->{type} ||= 'string';

		# Clean up the pattern if it's a straightforward regex
		if ($pattern =~ /^qr?\/([^\/]+)\/$/) {
			$p->{matches} = "/$1/";
		} else {
			$p->{matches} = $pattern;
		}
		$self->_log("  CODE: $param matches pattern: $p->{matches}");
	}
}

sub _analyze_parameter_validation {
	my ($self, $p_ref, $param, $code) = @_;
	my $p = $$p_ref;

	# Required/optional checks
	my $is_required = 0;

	# Die/croak if not defined
	if ($code =~ /(?:die|croak|confess)\s+[^;]*unless\s+(?:defined\s+)?\$$param/s) {
		$is_required = 1;
	}

	# Extract default values with the new method
	my $default_value = $self->_extract_default_value($param, $code);
	if (defined $default_value && !exists $p->{default}) {
		$p->{optional} = 1;
		$p->{default} = $default_value;

		# Try to infer type from default value if not already set
		unless ($p->{type}) {
			if (looks_like_number($default_value)) {
				$p->{type} = $default_value =~ /\./ ? 'number' : 'integer';
			} elsif (ref($default_value) eq 'ARRAY') {
				$p->{type} = 'arrayref';
			} elsif (ref($default_value) eq 'HASH') {
				$p->{type} = 'hashref';
			} elsif ($default_value eq 'undef') {
				$p->{type} = 'scalar';	# undef can be any scalar
			} elsif (defined $default_value && !ref($default_value)) {
				$p->{type} = 'string';
			}
		}

		$self->_log("  CODE: $param has default value: " .
		(ref($default_value) ? Dumper($default_value) : $default_value));
	}

	# Also check for simple default assignment without condition
	# Pattern: $param = 'value';
	if (!$default_value && !exists $p->{default} && $code =~ /\$$param\s*=\s*([^;{}]+?)(?:\s*[;}])/s) {
		my $assignment = $1;
		# Make sure it's not part of a larger expression
		if ($assignment !~ /\$$param/ && $assignment !~ /^shift/) {
			my $possible_default = $assignment;
			$possible_default =~ s/\s*;\s*$//;
			$possible_default = $self->_clean_default_value($possible_default);
			if (defined $possible_default) {
				$p->{default} = $possible_default;
				$p->{optional} = 1;
				$self->_log("  CODE: $param has unconditional default: $possible_default");
			}
		}
	}

	# Explicit required check overrides default detection
	if ($is_required) {
		$p->{optional} = 0;
		delete $p->{default} if exists $p->{default};
		$self->_log("  CODE: $param is required (validation check)");
	}
}

=head2 _merge_parameter_analyses

Merge parameter information from multiple sources.

Priority: POD > Code > Signature

=cut

# Enhanced merge with better position handling
sub _merge_parameter_analyses {
	my ($self, $pod, $code, $sig) = @_;

	my %merged;

	# Start with all parameters from all sources
	my %all_params = map { $_ => 1 } (keys %$pod, keys %$code, keys %$sig);

	foreach my $param (keys %all_params) {
		my $p = $merged{$param} = {};

		# Collect position from all sources
		my @positions;
		push @positions, $pod->{$param}{position} if $pod->{$param} && defined $pod->{$param}{position};
		push @positions, $sig->{$param}{position} if $sig->{$param} && defined $sig->{$param}{position};
		push @positions, $code->{$param}{position} if $code->{$param} && defined $code->{$param}{position};

		# Use the most common position, or lowest if tie
		if (@positions) {
			my %pos_count;
			$pos_count{$_}++ for @positions;
			my ($best_pos) = sort { $pos_count{$b} <=> $pos_count{$a} || $a <=> $b } keys %pos_count;
			$p->{position} = $best_pos unless(exists($p->{position}));
		}

		# POD has highest priority for type info and explicit declarations
		if ($pod->{$param}) {
			%$p = (%$p, %{$pod->{$param}});
		}

		# Code analysis adds concrete evidence (but doesn't override POD explicit types)
		if ($code->{$param}) {
			foreach my $key (keys %{$code->{$param}}) {
				next if $key eq '_source';
				next if $key eq 'position';

				# Only override if POD didn't provide this info or it's a stronger signal
				my $from_pod = exists $pod->{$param};
				if (!exists $p->{$key} ||
				   ($key eq 'type' && $from_pod && $p->{type} eq 'string' &&
				   $code->{$param}{$key} ne 'string')) {
					$p->{$key} = $code->{$param}{$key};
				}
			}
		}

		# Signature fills in remaining gaps
		if ($sig->{$param}) {
			foreach my $key (keys %{$sig->{$param}}) {
				next if $key eq '_source';
				next if $key eq 'position';
				$p->{$key} //= $sig->{$param}{$key};
			}
		}

		# Handle optional field with better logic
		$self->_determine_optional_status($p, $pod->{$param}, $code->{$param});

		# Clean up internal fields
		delete $p->{_source};
	}

	# Debug logging
	if ($self->{verbose}) {
		foreach my $param (sort { ($merged{$a}{position} || 999) <=> ($merged{$b}{position} || 999) } keys %merged) {
			my $p = $merged{$param};
			$self->_log("  MERGED $param: " .
					"pos=" . ($p->{position} || 'none') .
					", type=" . ($p->{type} || 'none') .
					", optional=" . (defined($p->{optional}) ? $p->{optional} : 'undef'));
		}
	}

	return \%merged;
}

sub _determine_optional_status {
	my ($self, $merged_param, $pod_param, $code_param) = @_;

	my $pod_optional = $pod_param ? $pod_param->{optional} : undef;
	my $code_optional = $code_param ? $code_param->{optional} : undef;

	# Explicit POD declaration wins
	if (defined $pod_optional) {
		$merged_param->{optional} = $pod_optional;
	}
	# Code validation evidence
	elsif (defined $code_optional) {
		$merged_param->{optional} = $code_optional;
	}
	# Default: if we have any info about the param, assume required
	elsif (keys %$merged_param > 0) {
		$merged_param->{optional} = 0;
	}
	# Otherwise leave undef (unknown)
}


=head2 _calculate_confidence

Calculate confidence score for parameter analysis.

Returns: 'high', 'medium', 'low'

=cut

# Enhanced confidence scoring with detailed factor tracking

sub _calculate_input_confidence {
	my ($self, $params) = @_;

	my @factors;  # Track all confidence factors

	return { level => 'none', factors => ['No parameters found'] } unless keys %$params;

	my $total_score = 0;
	my $count = 0;
	my %param_details;	# Store per-parameter analysis

	foreach my $param (keys %$params) {
		my $p = $params->{$param};
		my $score = 0;
		my @param_factors;

		# Type information
		if ($p->{type}) {
			if ($p->{type} eq 'string' && ($p->{min} || $p->{max} || $p->{matches})) {
				$score += 25;
				push @param_factors, "Type: constrained string (+25)";
			} elsif ($p->{type} eq 'string') {
				$score += 10;
				push @param_factors, "Type: plain string (+10)";
			} else {
				$score += 30;
				push @param_factors, "Type: $p->{type} (+30)";
			}
		} else {
			push @param_factors, "No type information (-0)";
		}

		# Constraints
		if (defined $p->{min}) {
			$score += 15;
			push @param_factors, 'Has min constraint (+15)';
		}
		if (defined $p->{max}) {
			$score += 15;
			push @param_factors, "Has max constraint (+15)";
		}
		if (defined $p->{optional}) {
			$score += 20;
			push @param_factors, "Optional/required explicitly defined (+20)";
		}
		if ($p->{matches}) {
			$score += 20;
			push @param_factors, "Has regex pattern constraint (+20)";
		}
		if ($p->{isa}) {
			$score += 25;
			push @param_factors, "Specific class constraint: $p->{isa} (+25)";
		}

		# Position information
		if (defined $p->{position}) {
			$score += 10;
			push @param_factors, "Position defined: $p->{position} (+10)";
		}

		# Default value
		if (exists $p->{default}) {
			$score += 10;
			push @param_factors, "Has default value (+10)";
		}

		# Semantic information
		if ($p->{semantic}) {
			$score += 15;
			push @param_factors, "Semantic type: $p->{semantic} (+15)";
		}

		$param_details{$param} = {
			score => $score,
			factors => \@param_factors
		};

		$total_score += $score;
		$count++;
	}

	my $avg = $count ? ($total_score / $count) : 0;

	# Build summary factors
	push @factors, sprintf("Analyzed %d parameter%s", $count, $count == 1 ? '' : 's');
	push @factors, sprintf("Average confidence score: %.1f", $avg);

	# Add top contributing factors
	my @sorted_params = sort { $param_details{$b}{score} <=> $param_details{$a}{score} } keys %param_details;

	if (@sorted_params) {
		my $highest = $sorted_params[0];
		my $highest_score = $param_details{$highest}{score};
		push @factors, sprintf("Highest scoring parameter: \$$highest (score: %d)", $highest_score);

		if (@sorted_params > 1) {
			my $lowest = $sorted_params[-1];
			my $lowest_score = $param_details{$lowest}{score};
			push @factors, sprintf("Lowest scoring parameter: \$$lowest (score: %d)", $lowest_score);
		}
	}

	# Determine confidence level
	my $level;
	if ($avg >= 60) {
		$level = 'high';
		push @factors, "High confidence: comprehensive type and constraint information";
	} elsif ($avg >= 35) {
		$level = 'medium';
		push @factors, "Medium confidence: some type or constraint information present";
	} elsif ($avg >= 15) {
		$level = 'low';
		push @factors, "Low confidence: minimal type information";
	} else {
		$level = 'very_low';
		push @factors, "Very low confidence: little to no type information";
	}

	return {
		level => $level,
		score => $avg,
		factors => \@factors,
		per_parameter => \%param_details
	};
}

sub _calculate_output_confidence {
	my ($self, $output) = @_;

	my @factors;

	return { level => 'none', factors => ['No return information found'] } unless keys %$output;

	my $score = 0;

	# Type information
	if ($output->{type}) {
		$score += 30;
		push @factors, "Return type defined: $output->{type} (+30)";
	} else {
		push @factors, 'No return type information (-0)';
	}

	# Specific value known
	if (defined $output->{value}) {
		$score += 30;
		push @factors, "Specific return value: $output->{value} (+30)";
	}

	# Class information for objects
	if ($output->{isa}) {
		$score += 30;
		push @factors, "Returns specific class: $output->{isa} (+30)";
	}

    # Context-aware returns
    if ($output->{context_aware}) {
        $score += 20;
        push @factors, "Context-aware return (wantarray) (+20)";

        if ($output->{list_context}) {
            push @factors, "  List context: $output->{list_context}{type}";
        }
        if ($output->{scalar_context}) {
            push @factors, "  Scalar context: $output->{scalar_context}{type}";
        }
    }

    # Error handling information
    if ($output->{error_return}) {
        $score += 15;
        push @factors, "Error return convention documented: $output->{error_return} (+15)";
    }

    # Success/failure pattern
    if ($output->{success_failure_pattern}) {
        $score += 10;
        push @factors, "Success/failure pattern detected (+10)";
    }

    # Chainable methods
    if ($output->{returns_self}) {
        $score += 15;
        push @factors, "Chainable method (fluent interface) (+15)";
    }

	# Void context
	if ($output->{void_context}) {
		$score += 20;
		push @factors, "Void context method (no meaningful return) (+20)";
	}

	# Exception handling
	if ($output->{error_handling} && $output->{error_handling}{exception_handling}) {
		$score += 10;
		push @factors, 'Exception handling present (+10)';
	}

	push @factors, sprintf("Total output confidence score: %d", $score);

	# Determine confidence level
	my $level;
	if ($score >= 60) {
		$level = 'high';
		push @factors, "High confidence: detailed return type and behavior";
	} elsif ($score >= 30) {
		$level = 'medium';
		push @factors, "Medium confidence: return type defined";
	} elsif ($score >= 15) {
		$level = 'low';
		push @factors, "Low confidence: minimal return information";
	} else {
		$level = 'very_low';
		push @factors, 'Very low confidence: little return information';
	}

	return {
		level => $level,
		score => $score,
		factors => \@factors
	};
}

# Method to generate human-readable confidence report
sub _generate_confidence_report
{
	my ($self, $schema) = @_;

	return unless $schema->{_analysis};

	my $analysis = $schema->{_analysis};
	my @report;

	push @report, "Confidence Analysis for " . ($schema->{method_name} || 'method');
	push @report, '=' x 60;
	push @report, '';

	push @report, "Overall Confidence: " . uc($analysis->{overall_confidence});
	push @report, '';

	if ($analysis->{confidence_factors}{input}) {
		push @report, (
			"Input Parameters:",
			 "  Confidence Level: " . uc($analysis->{input_confidence})
		);
		foreach my $factor (@{$analysis->{confidence_factors}{input}}) {
			push @report, "  - $factor";
		}
		push @report, '';
	}

	if ($analysis->{confidence_factors}{output}) {
		push @report, 'Return Value:',
			"  Confidence Level: " . uc($analysis->{output_confidence});
		foreach my $factor (@{$analysis->{confidence_factors}{output}}) {
			push @report, "  - $factor";
		}
		push @report, '';
	}

	if ($analysis->{per_parameter_scores}) {
		push @report, 'Per-Parameter Analysis:';
		foreach my $param (sort keys %{$analysis->{per_parameter_scores}}) {
			my $details = $analysis->{per_parameter_scores}{$param};
			push @report, "  \$$param (score: $details->{score}):";
			foreach my $factor (@{$details->{factors}}) {
				push @report, "    - $factor";
			}
		}
		push @report, '';
	}

	return join("\n", @report);
}

=head2 _generate_notes

Generate helpful notes about the analysis.

=cut

sub _generate_notes {
	my ($self, $params) = @_;

	my @notes;

	foreach my $param (keys %$params) {
		my $p = $params->{$param};

		unless ($p->{type}) {
			push @notes, "$param: type unknown - please review - will set to 'string' as a default";
		}

		unless (defined $p->{optional}) {
			push @notes, "$param: optional status unknown";
			# Don't automatically set - let it be undef if we don't know
		}
	}

	return \@notes;
}

=head2 _set_defaults

Set defaults in the schema, called after the schema has been set up

=cut

sub _set_defaults
{
	my ($self, $schema, $mode) = @_;

	my $params = $schema->{$mode};

	foreach my $param (keys %$params) {
		my $p = $params->{$param};

		next unless(ref($p) eq 'HASH');
		unless ($p->{type}) {
			$self->_log("  DEBUG ${mode}{$param}: Setting to 'string' as a default");
			$p->{'type'} = 'string';
			$schema->{_confidence}{mode}->{level} = 'low';	# Setting a default means it's a guess
		}
	}
}

=head2 _analyze_relationships

Analyze relationships and dependencies between parameters.

Detects:
- Mutually exclusive parameters (can't use both)
- Required parameter groups (must use one of)
- Conditional requirements (if X then Y)
- Parameter dependencies (X requires Y)
- Value-based constraints (X=5 requires Y)

=cut

sub _analyze_relationships {
	my ($self, $method) = @_;

	my $code = $method->{body};
	my @relationships;

	# Extract all parameter names from the method
	my @param_names;
	if ($code =~ /my\s*\(\s*\$\w+\s*,\s*(.+?)\)\s*=\s*\@_/s) {
		my $params = $1;
		@param_names = $params =~ /\$(\w+)/g;
	}

	return [] unless @param_names;

	# Detect mutually exclusive parameters
	push @relationships, @{$self->_detect_mutually_exclusive($code, \@param_names)};

	# Detect required groups (OR logic)
	push @relationships, @{$self->_detect_required_groups($code, \@param_names)};

	# Detect conditional requirements (IF-THEN)
	push @relationships, @{$self->_detect_conditional_requirements($code, \@param_names)};

	# Detect dependencies
	push @relationships, @{$self->_detect_dependencies($code, \@param_names)};

	# Detect value-based constraints
	push @relationships, @{$self->_detect_value_constraints($code, \@param_names)};

	# Deduplicate relationships
	my @unique = $self->_deduplicate_relationships(\@relationships);

	return \@unique;
}

=head2 _deduplicate_relationships

Remove duplicate relationship entries.

=cut

sub _deduplicate_relationships {
	my ($self, $relationships) = @_;

	my @unique;
	my %seen;

	foreach my $rel (@$relationships) {
		# Create a signature for this relationship
		my $sig;
		if ($rel->{type} eq 'mutually_exclusive') {
			$sig = join(':', 'mutex', sort @{$rel->{params}});
		} elsif ($rel->{type} eq 'required_group') {
			$sig = join(':', 'reqgroup', sort @{$rel->{params}});
		} elsif ($rel->{type} eq 'conditional_requirement') {
			$sig = join(':', 'condreq', $rel->{if}, $rel->{then_required});
		} elsif ($rel->{type} eq 'dependency') {
			$sig = join(':', 'dep', $rel->{param}, $rel->{requires});
		} elsif ($rel->{type} eq 'value_constraint') {
			$sig = join(':', 'valcon', $rel->{if}, $rel->{then}, $rel->{operator}, $rel->{value});
		} elsif ($rel->{type} eq 'value_conditional') {
			$sig = join(':', 'valcond', $rel->{if}, $rel->{equals}, $rel->{then_required});
		} else {
			$sig = join(':', $rel->{type}, %$rel);
		}

		unless ($seen{$sig}++) {
			push @unique, $rel;
		}
	}

	return @unique;
}

=head2 _detect_mutually_exclusive

Detect parameters that cannot be used together.

Patterns:
  die if $file && $content
  croak "Cannot specify both" if $x && $y
  die unless !($a && $b)

=cut

sub _detect_mutually_exclusive {
	my ($self, $code, $param_names) = @_;

	my @relationships;

	# Pattern 1: die/croak if $x && $y
	# Look for: die/croak ... if $param1 && $param2
	foreach my $param1 (@$param_names) {
		foreach my $param2 (@$param_names) {
			next if $param1 eq $param2;

			# Check various patterns
			if ($code =~ /(?:die|croak|confess)[^;]*if\s+\$$param1\s+&&\s+\$$param2/ ||
			    $code =~ /(?:die|croak|confess)[^;]*if\s+\$$param2\s+&&\s+\$$param1/) {

				# Avoid duplicates (param1,param2 vs param2,param1)
				my $found_reverse = 0;
				foreach my $rel (@relationships) {
					if ($rel->{type} eq 'mutually_exclusive' &&
					    (($rel->{params}[0] eq $param2 && $rel->{params}[1] eq $param1))) {
						$found_reverse = 1;
						last;
					}
				}

				next if $found_reverse;

				push @relationships, {
					type => 'mutually_exclusive',
					params => [$param1, $param2],
					description => "Cannot specify both $param1 and $param2"
				};

				$self->_log("  RELATIONSHIP: $param1 and $param2 are mutually exclusive");
			}

			# Pattern 2: die "Cannot specify both X and Y"
			if ($code =~ /(?:die|croak|confess)\s+['"](Cannot|Can't)[^'"]*both[^'"]*$param1[^'"]*$param2/i ||
			    $code =~ /(?:die|croak|confess)\s+['"](Cannot|Can't)[^'"]*both[^'"]*$param2[^'"]*$param1/i) {

				my $found_reverse = 0;
				foreach my $rel (@relationships) {
					if ($rel->{type} eq 'mutually_exclusive' &&
					    (($rel->{params}[0] eq $param2 && $rel->{params}[1] eq $param1))) {
						$found_reverse = 1;
						last;
					}
				}

				next if $found_reverse;

				push @relationships, {
					type => 'mutually_exclusive',
					params => [$param1, $param2],
					description => "Cannot specify both $param1 and $param2"
				};

				$self->_log("  RELATIONSHIP: $param1 and $param2 are mutually exclusive (from error message)");
			}
		}
	}

	return \@relationships;
}

=head2 _detect_required_groups

Detect parameter groups where at least one must be specified (OR logic).

Patterns:
  die unless $id || $name
  croak "Must specify either X or Y" unless $x || $y

=cut

sub _detect_required_groups {
	my ($self, $code, $param_names) = @_;

	my @relationships;

	# Pattern 1: die/croak unless $x || $y
	foreach my $param1 (@$param_names) {
		foreach my $param2 (@$param_names) {
			next if $param1 eq $param2;

			if ($code =~ /(?:die|croak|confess)[^;]*unless\s+\$$param1\s+\|\|\s+\$$param2/ ||
			    $code =~ /(?:die|croak|confess)[^;]*unless\s+\$$param2\s+\|\|\s+\$$param1/) {

				# Avoid duplicates
				my $found_reverse = 0;
				foreach my $rel (@relationships) {
					if ($rel->{type} eq 'required_group' &&
					    (($rel->{params}[0] eq $param2 && $rel->{params}[1] eq $param1))) {
						$found_reverse = 1;
						last;
					}
				}

				next if $found_reverse;

				push @relationships, {
					type => 'required_group',
					params => [$param1, $param2],
					logic => 'or',
					description => "Must specify either $param1 or $param2"
				};

				$self->_log("  RELATIONSHIP: Must specify either $param1 or $param2");
			}

			# Pattern 2: die "Must specify either X or Y"
			if ($code =~ /(?:die|croak|confess)\s+['"]Must\s+specify\s+either[^'"]*$param1[^'"]*or[^'"]*$param2/i ||
			    $code =~ /(?:die|croak|confess)\s+['"]Must\s+specify\s+either[^'"]*$param2[^'"]*or[^'"]*$param1/i) {

				my $found_reverse = 0;
				foreach my $rel (@relationships) {
					if ($rel->{type} eq 'required_group' &&
					    (($rel->{params}[0] eq $param2 && $rel->{params}[1] eq $param1))) {
						$found_reverse = 1;
						last;
					}
				}

				next if $found_reverse;

				push @relationships, {
					type => 'required_group',
					params => [$param1, $param2],
					logic => 'or',
					description => "Must specify either $param1 or $param2"
				};

				$self->_log("  RELATIONSHIP: Must specify either $param1 or $param2 (from error message)");
			}
		}
	}

	return \@relationships;
}

=head2 _detect_conditional_requirements

Detect conditional requirements (IF-THEN logic).

Patterns:
  die if $async && !$callback
  croak "X requires Y" if $x && !$y

=cut

sub _detect_conditional_requirements {
	my ($self, $code, $param_names) = @_;

	my @relationships;

	foreach my $param1 (@$param_names) {
		foreach my $param2 (@$param_names) {
			next if $param1 eq $param2;

			# Pattern 1: die if $x && !$y  (if x then y required)
			if ($code =~ /(?:die|croak|confess)[^;]*if\s+\$$param1\s+&&\s+!\$$param2/) {
				push @relationships, {
					type => 'conditional_requirement',
					if => $param1,
					then_required => $param2,
					description => "When $param1 is specified, $param2 is required"
				};

				$self->_log("  RELATIONSHIP: $param1 requires $param2");
			}

			# Pattern 2: die if $x && !defined($y)
			if ($code =~ /(?:die|croak|confess)[^;]*if\s+\$$param1\s+&&\s+!defined\s*\(\s*\$$param2\s*\)/) {
				push @relationships, {
					type => 'conditional_requirement',
					if => $param1,
					then_required => $param2,
					description => "When $param1 is specified, $param2 is required"
				};

				$self->_log("  RELATIONSHIP: $param1 requires $param2 (defined check)");
			}

			# Pattern 3: Error message "X requires Y"
			if ($code =~ /(?:die|croak|confess)\s+['"]\w*$param1[^'"]*requires[^'"]*$param2/i) {
				push @relationships, {
					type => 'conditional_requirement',
					if => $param1,
					then_required => $param2,
					description => "When $param1 is specified, $param2 is required"
				};

				$self->_log("  RELATIONSHIP: $param1 requires $param2 (from error message)");
			}
		}
	}

	return \@relationships;
}

=head2 _detect_dependencies

Detect simple parameter dependencies (X requires Y to exist).

Patterns:
  die 'Port requires host' if $port && !$host

=cut

sub _detect_dependencies {
	my ($self, $code, $param_names) = @_;

	my @relationships;

	foreach my $param1 (@$param_names) {
		foreach my $param2 (@$param_names) {
			next if $param1 eq $param2;

			# Pattern 1: Error message mentions "X requires Y" AND code checks $x && !$y
			# Split into two checks to be more flexible
			if (($code =~ /(?:die|croak|confess)\s+['"]\w*$param1[^'"]*requires[^'"]*$param2/i) &&
			    ($code =~ /if\s+\$param1\s+&&\s+!\$param2/)) {

				push @relationships, {
					type => 'dependency',
					param => $param1,
					requires => $param2,
					description => "$param1 requires $param2 to be specified"
				};

				$self->_log("  RELATIONSHIP: $param1 depends on $param2");
			}
		}
	}

	return \@relationships;
}

=head2 _detect_value_constraints

Detect value-based constraints between parameters.

Patterns:
  die if $ssl && $port != 443
  croak "Invalid combination" if $mode eq 'secure' && !$key

=cut

sub _detect_value_constraints {
	my ($self, $code, $param_names) = @_;

	my @relationships;

	foreach my $param1 (@$param_names) {
		foreach my $param2 (@$param_names) {
			next if $param1 eq $param2;

			# Pattern 1: die if $x && $y != value
			if ($code =~ /(?:die|croak|confess)[^;]*if\s+\$$param1\s+&&\s+\$$param2\s*!=\s*(\d+)/) {
				my $value = $1;
				push @relationships, {
					type => 'value_constraint',
					if => $param1,
					then => $param2,
					operator => '==',
					value => $value,
					description => "When $param1 is specified, $param2 must equal $value"
				};

				$self->_log("  RELATIONSHIP: $param1 requires $param2 == $value");
			}

			# Pattern 2: die if $x && $y < value
			if ($code =~ /(?:die|croak|confess)[^;]*if\s+\$$param1\s+&&\s+\$$param2\s*<\s*(\d+)/) {
				my $value = $1;
				push @relationships, {
					type => 'value_constraint',
					if => $param1,
					then => $param2,
					operator => '>=',
					value => $value,
					description => "When $param1 is specified, $param2 must be >= $value"
				};

				$self->_log("  RELATIONSHIP: $param1 requires $param2 >= $value");
			}

			# Pattern 3: die if $x eq 'value' && !$y
			if ($code =~ /(?:die|croak|confess)[^;]*if\s+\$$param1\s+eq\s+['"]([^'"]+)['"]\s+&&\s+!\$$param2/) {
				my $value = $1;
				push @relationships, {
					type => 'value_conditional',
					if => $param1,
					equals => $value,
					then_required => $param2,
					description => "When $param1 equals '$value', $param2 is required"
				};

				$self->_log("  RELATIONSHIP: $param1='$value' requires $param2");
			}
		}
	}

	return \@relationships;
}

=head2 _write_schema

Write a schema to a YAML file.

=cut

sub _write_schema {
	my ($self, $method_name, $schema) = @_;

	die if(!defined($self->{'output_dir'}));
	make_path($self->{output_dir}) unless -d $self->{output_dir};

	my $filename = "$self->{output_dir}/${method_name}.yml";

	# Extract package name for module field
	my $package_name = '';
	if ($self->{_document}) {
		my $package_stmt = $self->{_document}->find_first('PPI::Statement::Package');
		$package_name = $package_stmt ? $package_stmt->namespace : '';
	}

	# Clean up schema for output - use the format expected by test generator
	my $output = {
		function => $method_name,
		module => $package_name,
		config => {
			dedup => 1,
			test_nuls => 0,
			test_undef => 0,
			test_empty => 1,
			test_non_ascii => 0
		}
	};

	# Process input parameters with advanced type handling
	if($schema->{'input'} && (scalar(keys %{$schema->{'input'}}))) {
		$output->{'input'} = {};

		foreach my $param_name (keys %{$schema->{'input'}}) {
			my $param = $schema->{'input'}{$param_name};
			my $cleaned_param = $self->_serialize_parameter_for_yaml($param);
			$output->{'input'}{$param_name} = $cleaned_param;
		}
	}

	# Process output
	if($schema->{'output'} && (scalar(keys %{$schema->{'output'}}))) {
		$output->{'output'} = $schema->{'output'};
	}

	if($schema->{'output'}{'type'} && ($schema->{'output'}{'type'} eq 'scalar')) {
		$schema->{'output'}{'type'} = 'string';
	}

	# Add 'new' field if object instantiation is needed
	if ($schema->{new}) {
		# Don't try to pull in other packages - FIXME: but that would be OK up the ISA chain
		if(ref($schema->{new}) || ($schema->{new} eq $package_name)) {
			$output->{new} = $schema->{new} eq $package_name ? undef : $schema->{'new'};
		} else {
			$self->_log("  NEW: Don't use $schema->{new} for object insantiation");
			delete $schema->{new};
			delete $output->{new};
		}
	}

	# Add relationships if detected
	if ($schema->{relationships} && @{$schema->{relationships}}) {
		$output->{relationships} = $schema->{relationships};
	}

	open my $fh, '>', $filename;
	print $fh YAML::XS::Dump($output);
	print $fh $self->_generate_schema_comments($schema, $method_name);
	close $fh;

	my $rel_info = $schema->{relationships} ?
		' [' . scalar(@{$schema->{relationships}}) . ' relationships]' : '';
	$self->_log("  Wrote: $filename (input confidence: $schema->{_confidence}{input}->{level})" .
				($schema->{new} ? " [requires: $schema->{new}]" : '') . $rel_info);
}

=head2 _generate_schema_comments

Generate helpful comments at the end of the YAML file.

=cut

sub _generate_schema_comments {
	my ($self, $schema, $method_name) = @_;

	my @comments;

	push @comments, '';
	push @comments, "# Generated by " . ref($self);
	push @comments, "# Run: fuzz-harness-generator -r $self->{output_dir}/${method_name}.yml";
	push @comments, '#';
	push @comments, "# Input confidence: $schema->{_confidence}{input}->{level}";
	push @comments, "# Output confidence: $schema->{_confidence}{output}->{level}";

	# Add notes about parameters
	if ($schema->{input}) {
		my @param_notes;
		foreach my $param_name (sort keys %{$schema->{input}}) {
			my $p = $schema->{input}{$param_name};

			if ($p->{semantic}) {
				push @param_notes, "$param_name: $p->{semantic}";
			}

			if ($p->{enum}) {
				push @param_notes, "$param_name: enum with " . scalar(@{$p->{enum}}) . " values";
			}

			if ($p->{isa}) {
				push @param_notes, "$param_name: requires $p->{isa} object";
			}
		}

		if (@param_notes) {
			push @comments, '#';
			push @comments, '# Parameter types detected:';
			foreach my $note (@param_notes) {
				push @comments, "#   - $note";
			}
		}
	}

	# Add relationship notes
	if ($schema->{relationships} && @{$schema->{relationships}}) {
		push @comments, (
			'#',
			'# Parameter relationships detected:'
		);
		foreach my $rel (@{$schema->{relationships}}) {
			my $desc = $rel->{description} || _format_relationship($rel);
			push @comments, "#   - $desc";
		}
	}

	# Add general notes
	if ($schema->{_notes} && scalar(@{$schema->{_notes}})) {
		push @comments, '#';
		push @comments, '# Notes:';
		foreach my $note (@{$schema->{_notes}}) {
			push @comments, "#   - $note";
		}
	}

	if($schema->{_analysis}) {
		push @comments, (
			'#',
			'# Analysis:',
			'# TODO:',
		);
		# confidence_factors:
		#   input:
		#   - No parameters found
		#   output:
		#   - 'Return type defined: object (+30)'
		#   - 'Total output confidence score: 30'
		#   - 'Medium confidence: return type defined'
		#   input_confidence: none
		#   output_confidence: medium
		#   overall_confidence: none
	}

	# Add warnings for complex types
	my @warnings;
	if ($schema->{input}) {
		foreach my $param_name (keys %{$schema->{input}}) {
			my $p = $schema->{input}{$param_name};

			if ($p->{type} && $p->{type} eq 'coderef') {
				push @warnings, "Parameter '$param_name' is a coderef - you'll need to provide a sub {} in tests";
			}

			if ($p->{semantic} && $p->{semantic} eq 'filehandle') {
				push @warnings, "Parameter '$param_name' is a filehandle - consider using IO::String or mock";
			}

			if ($p->{isa} && $p->{isa} =~ /DateTime/) {
				push @warnings, "Parameter '$param_name' requires DateTime - ensure DateTime is loaded";
			}
		}
	}

	if (@warnings) {
		push @comments, '#';
		push @comments, '# WARNINGS - Manual test setup may be required:';
		foreach my $warning (@warnings) {
			push @comments, "#   ! $warning";
		}
	}

	push @comments, '';

	return join("\n", @comments);
}

=head2 _serialize_parameter_for_yaml

Convert parameter hash to YAML-serializable format with proper type handling.

=cut

sub _serialize_parameter_for_yaml {
	my ($self, $param) = @_;

	my %cleaned;

	# Copy basic fields that App::Test::Generator expects
	foreach my $field (qw(type position optional min max matches default)) {
		$cleaned{$field} = $param->{$field} if defined $param->{$field};
	}

	# Handle advanced type mappings
	my $semantic = $param->{semantic};

	if ($semantic) {
		if ($semantic eq 'datetime_object') {
			# DateTime objects: test generator needs to know how to create them
			$cleaned{type} = 'object';
			$cleaned{isa} = $param->{isa} || 'DateTime';
			$cleaned{_note} = 'Requires DateTime object';

		} elsif ($semantic eq 'timepiece_object') {
			$cleaned{type} = 'object';
			$cleaned{isa} = $param->{isa} || 'Time::Piece';
			$cleaned{_note} = 'Requires Time::Piece object';

		} elsif ($semantic eq 'date_string') {
			# Date strings: provide regex pattern
			$cleaned{type} = 'string';
			$cleaned{matches} ||= '/^\d{4}-\d{2}-\d{2}$/';
			$cleaned{_example} = '2024-12-12';

		} elsif ($semantic eq 'iso8601_string') {
			$cleaned{type} = 'string';
			$cleaned{matches} ||= '/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z?$/';
			$cleaned{_example} = '2024-12-12T10:30:00Z';

		} elsif ($semantic eq 'unix_timestamp') {
			$cleaned{type} = 'integer';
			$cleaned{min} ||= 0;
			$cleaned{max} ||= 2147483647;	# 32-bit max
			$cleaned{_note} = 'UNIX timestamp';

		} elsif ($semantic eq 'datetime_parseable') {
			$cleaned{type} = 'string';
			$cleaned{_note} = 'Must be parseable as datetime';

		} elsif ($semantic eq 'filehandle') {
			# File handles: special handling needed
			$cleaned{type} = 'object';
			$cleaned{isa} = $param->{isa} || 'IO::Handle';
			$cleaned{_note} = 'File handle - may need mock in tests';

		} elsif ($semantic eq 'filepath') {
			# File paths: string with path pattern
			$cleaned{type} = 'string';
			$cleaned{matches} ||= '/^[\\w\\/.\\-_]+$/';
			$cleaned{_note} = 'File path';

		} elsif ($semantic eq 'callback') {
			# Coderefs: mark as special type
			$cleaned{type} = 'coderef';
			$cleaned{_note} = 'CODE reference - provide sub { } in tests';

		} elsif ($semantic eq 'enum') {
			# Enum: keep as string but add valid values
			$cleaned{type} = 'string';
			if ($param->{enum} && ref($param->{enum}) eq 'ARRAY') {
				$cleaned{enum} = $param->{enum};
				$cleaned{_note} = 'Must be one of: ' . join(', ', @{$param->{enum}});
			}
		}
	}

	# Handle memberof even if not marked with semantic
	if($param->{enum} && ref($param->{enum}) eq 'ARRAY') {
		$cleaned{memberof} = $param->{enum};
	}
	if($param->{memberof} && ref($param->{memberof}) eq 'ARRAY') {
		$cleaned{memberof} = $param->{memberof};
	}

	# Handle object class
	if ($param->{isa} && !$cleaned{isa}) {
		$cleaned{isa} = $param->{isa};
	}

	# Add format hints where available
	if ($param->{format}) {
		$cleaned{_format} = $param->{format};
	}

	# Remove internal fields
	delete $cleaned{_source};
	delete $cleaned{semantic};

	return \%cleaned;
}

sub _format_relationship {
	my $rel = $_[0];

	if ($rel->{type} eq 'mutually_exclusive') {
		return 'Mutually exclusive: ' . join(', ', @{$rel->{params}});
	} elsif ($rel->{type} eq 'required_group') {
		return "Required group (OR): " . join(', ', @{$rel->{params}});
	} elsif ($rel->{type} eq 'conditional_requirement') {
		return "If $rel->{if} then $rel->{then_required} required";
	} elsif ($rel->{type} eq 'dependency') {
		return "$rel->{param} depends on $rel->{requires}";
	} elsif ($rel->{type} eq 'value_constraint') {
		return "If $rel->{if} then $rel->{then} $rel->{operator} $rel->{value}";
	} elsif ($rel->{type} eq 'value_conditional') {
		return "If $rel->{if}='$rel->{equals}' then $rel->{then_required} required";
	}
	return 'Unknown relationship';
}

=head2 _needs_object_instantiation

Enhanced object detection that:
- Detects factory methods that return instances
- Recognizes singleton patterns
- Identifies when constructor needs specific parameters
- Handles inheritance (when parent class new() is needed)
- Detects both instance methods and class methods that require objects

Returns:
- undef if no object needed
- package name if object instantiation is needed
- hashref with constructor details if specific parameters are needed

=cut

sub _needs_object_instantiation {
	my ($self, $method_name, $method_body, $method_info) = @_;

	# Allow method_info to be optional for backward compatibility
	$method_info ||= {};

	my $doc = $self->{_document};
	return undef unless $doc;

	# Get the current package name
	my $package_stmt = $doc->find_first('PPI::Statement::Package');
	my $current_package = $package_stmt ? $package_stmt->namespace : 'UNKNOWN';

	# Skip constructors and destructors
	return undef if $method_name eq 'new';
	return undef if $method_name =~ /^(create|build|construct|init|DESTROY)$/i;

	# Initialize result structure
	my $result = {
		package => $current_package,
		needs_object => 0,
		type => 'unknown',
		details => {},
		constructor_params => undef,
	};

	# 1. Check for factory methods that return instances
	my $is_factory = $self->_detect_factory_method($method_name, $method_body, $current_package, $method_info);
	if ($is_factory) {
		$result->{needs_object} = 0;	# Factory methods CREATE objects, don't need them
		$result->{type} = 'factory';
		$result->{details} = $is_factory;
		$self->_log("  OBJECT: Detected factory method '$method_name' returns $is_factory->{returns_class} objects") if $is_factory->{returns_class};
		return undef;	# Factory methods don't need pre-existing objects
	}

	# 2. Check for singleton patterns
	my $is_singleton = $self->_detect_singleton_pattern($method_name, $method_body);
	if ($is_singleton) {
		$result->{needs_object} = 0;	# Singleton methods return the singleton instance
		$result->{type} = 'singleton_accessor';
		$result->{details} = $is_singleton;
		$self->_log("  OBJECT: Detected singleton accessor '$method_name'");
		# Singleton accessors typically don't need object creation in tests
		# as they're called on the class, not instance
		return undef;
	}

	# 3. Check if this is an instance method that needs an object
	my $is_instance_method = $self->_detect_instance_method($method_name, $method_body);
	if($is_instance_method &&
	    ($is_instance_method->{explicit_self} ||
			$is_instance_method->{shift_self} ||
			$is_instance_method->{accesses_object_data})) {
		$result->{needs_object} = 1;
		$result->{type} = 'instance_method';
		$result->{details} = $is_instance_method;

		# 4. Check for inheritance - if parent class constructor should be used
		my $inheritance_info = $self->_check_inheritance_for_constructor($current_package, $method_body);
		if ($inheritance_info && $inheritance_info->{use_parent_constructor}) {
			$result->{package} = $inheritance_info->{parent_class};
			$result->{details}{inheritance} = $inheritance_info;
			$self->_log("  OBJECT: Method '$method_name' uses parent class constructor: $inheritance_info->{parent_class}");
		}

		# 5. Check if constructor needs specific parameters
		my $constructor_needs = $self->_detect_constructor_requirements($current_package, $result->{package});
		if ($constructor_needs) {
			$result->{constructor_params} = $constructor_needs;
			$result->{details}{constructor_requirements} = $constructor_needs;
			$self->_log("  OBJECT: Constructor for $result->{package} requires parameters");
		}

		# Return the package name (or parent package) that needs instantiation
		return $result->{package} if $result->{needs_object};
	}

	# 6. Check for class methods that might need objects from other classes
	my $needs_other_object = $self->_detect_external_object_dependency($method_body);
	if ($needs_other_object) {
		$result->{needs_object} = 1;
		$result->{type} = 'external_dependency';
		$result->{package} = $needs_other_object->{package} if $needs_other_object->{package};
		$result->{details} = $needs_other_object;

		$self->_log("  OBJECT: Method '$method_name' depends on external object: $needs_other_object->{package}");
		return $result->{package} if $result->{package};
	}

	return undef;
}

=head2 _detect_factory_method

Detect factory methods that create and return instances.

Patterns:
- Returns blessed references
- Returns objects created with ->new()
- Method names like create_*, make_*, build_*
- Returns $self->new(...) or Class->new(...)

=cut

sub _detect_factory_method {
	my ($self, $method_name, $method_body, $current_package, $method_info) = @_;

	my %factory_info;

	# Check method name patterns
	if ($method_name =~ /^(create_|make_|build_|get_)/i) {
		$factory_info{name_pattern} = 1;
	}

	# Look for object creation patterns in the method body
	if ($method_body) {
		# Pattern 1: Returns a blessed reference
		if ($method_body =~ /return\s+bless\s*\{[^}]*\},\s*['"]?(\w+(?:::\w+)*|\$\w+)['"]?/s ||
			$method_body =~ /bless\s*\{[^}]*\},\s*['"]?(\w+(?:::\w+)*|\$\w+)['"]?.*return/s) {
			my $class_name = $1;

			# Handle variable class names
			if ($class_name =~ /^\$(class|self|package)$/) {
				$factory_info{returns_class} = $current_package;
			} elsif ($class_name =~ /^\$/) {
				$factory_info{returns_class} = 'VARIABLE';	# Unknown variable
			} else {
				$factory_info{returns_class} = $class_name;
			}

			$factory_info{returns_blessed} = 1;
			$factory_info{confidence} = 'high';
			return \%factory_info;
		}

		# Pattern 2: Returns ->new() call on class or $self
		if ($method_body =~ /return\s+([\$\w:]+)->new\(/s ||
			$method_body =~ /([\$\w:]+)->new\(.*return/s) {
			my $target = $1;

			# Determine what class is being instantiated
			if ($target eq '$self' || $target eq 'shift' || $target =~ /^\$/) {
				$factory_info{returns_class} = $current_package;
				$factory_info{self_new} = 1;
			} elsif ($target =~ /::/) {
				$factory_info{returns_class} = $target;
				$factory_info{external_class} = 1;
			} else {
				$factory_info{returns_class} = $target;
			}

			$factory_info{returns_new} = 1;
			$factory_info{confidence} = 'medium';
			return \%factory_info;
		}

		# Pattern 3: Returns an object from another factory method
		if ($method_body =~ /return\s+([\$\w:]+)->(create_|make_|build_|get_)/i ||
			$method_body =~ /([\$\w:]+)->(create_|make_|build_|get_).*return/si) {
			$factory_info{returns_factory_result} = 1;
			$factory_info{confidence} = 'low';
			return \%factory_info;
		}
	}

	# Check for return type hints in POD if available
	if ($method_info && ref($method_info) eq 'HASH' && $method_info->{pod}) {
		my $pod = $method_info->{pod};
		if ($pod =~ /returns?\s+(?:an?\s+)?(object|instance|new\s+\w+)/i) {
			$factory_info{pod_hint} = 1;
			$factory_info{confidence} = 'low';
			return \%factory_info;
		}
	}

	return undef;
}

=head2 _detect_singleton_pattern

Detect singleton patterns:
- Class methods that return $instance or $_instance
- Static variable holding instance
- Method names like instance(), get_instance()

=cut

sub _detect_singleton_pattern {
	my ($self, $method_name, $method_body) = @_;

	# Check method name patterns
	return undef unless $method_name =~ /^(instance|get_instance|singleton|shared_instance)$/i;

	my %singleton_info = (
		name_pattern => 1,
	);

	# Look for singleton patterns in code
	if ($method_body) {
		# Pattern 1: Static/state variable holding instance
		if ($method_body =~ /(?:my\s+)?(?:our\s+)?\$(?:instance|_instance|singleton)\b/s ||
			$method_body =~ /state\s+\$(?:instance|_instance|singleton)\b/s) {
			$singleton_info{static_variable} = 1;
			$singleton_info{confidence} = 'high';
		}

		# Pattern 2: Returns $instance if defined (with better regex)
		if ($method_body =~ /return\s+\$instance\s+if\s+(?:defined\s+)?\$instance/ ||
			$method_body =~ /unless\s+\$instance.*?=\s*.*?new/) {
			$singleton_info{returns_instance} = 1;
			$singleton_info{confidence} = 'high';
		}

		# Pattern 3: ||= new() pattern (with better regex)
		if ($method_body =~ /\$instance\s*\|\|=\s*.*?new/ ||
			$method_body =~ /\$instance\s*=\s*.*?new\s+unless\s+(?:defined\s+)?\$instance/) {
			$singleton_info{lazy_initialization} = 1;
			$singleton_info{confidence} = 'medium';
		}

		# Pattern 4: Direct return of $instance variable
		if ($method_body =~ /return\s+\$instance;/) {
			$singleton_info{returns_instance} = 1;
			$singleton_info{confidence} = 'high' unless $singleton_info{confidence};
		}
	}

	return \%singleton_info if keys %singleton_info > 0;	# Need at least name pattern

	return undef;
}

=head2 _detect_instance_method

Detect if a method is an instance method that needs an object.

Enhanced detection with multiple patterns.

=cut

sub _detect_instance_method {
	my ($self, $method_name, $method_body) = @_;

	my %instance_info;

	# Pattern 1: my ($self, ...) = @_;
	if ($method_body =~ /my\s*\(\s*\$self\s*[,)]/) {
		$instance_info{explicit_self} = 1;
		$instance_info{confidence} = 'high';
	}

	# Pattern 2: my $self = shift;
	elsif ($method_body =~ /my\s+\$self\s*=\s*shift/) {
		$instance_info{shift_self} = 1;
		$instance_info{confidence} = 'high';
	}

	# Pattern 3: Uses $self->something (including hash/array access)
	# This catches $self->{value} and $self->[0] as well as $self->method()
	elsif ($method_body =~ /\$self\s*->\s*(\w+|[\{\[])/) {
		$instance_info{uses_self} = 1;
		$instance_info{confidence} = 'medium';
	}

	# Pattern 4: Accesses object data: $self->{...}, $self->[...]
	if ($method_body =~ /\$self\s*->\s*[\{\[]/) {
		$instance_info{accesses_object_data} = 1;
		$instance_info{confidence} = 'high' unless $instance_info{confidence} eq 'high';
	}

	# Pattern 5: Calls other instance methods on $self
	if ($method_body =~ /\$self\s*->\s*(\w+)\s*\(/s) {
		$instance_info{calls_instance_methods} = [];
		while ($method_body =~ /\$self\s*->\s*(\w+)\s*\(/g) {
			push @{$instance_info{calls_instance_methods}}, $1;
		}
		$instance_info{confidence} = 'high' if @{$instance_info{calls_instance_methods}};
	}

	# Pattern 6: Method name suggests instance method (not perfect but helpful)
	if ($method_name =~ /^_/ && $method_name !~ /^_new/) {
		# Private methods are usually instance methods
		$instance_info{private_method} = 1;
		$instance_info{confidence} = 'low' unless exists $instance_info{confidence};
	}

	return \%instance_info if keys %instance_info;
	return undef;
}

=head2 _check_inheritance_for_constructor

Check if inheritance affects which constructor should be used.

Patterns:
- use parent/base statements
- @ISA array
- SUPER::new calls
- parent class methods

=cut

sub _check_inheritance_for_constructor {
	my ($self, $current_package, $method_body) = @_;

	my $doc = $self->{_document};
	return undef unless $doc;

	my %inheritance_info;

	# 1. Look for parent/base statements
	my @parent_classes;

	# Find all 'use parent' or 'use base' statements
	my $includes = $doc->find('PPI::Statement::Include') || [];
	foreach my $inc (@$includes) {
		my $content = $inc->content;
		if ($content =~ /use\s+(parent|base)\s+['"]?([\w:]+)['"]?/) {
			push @parent_classes, $2;
			$inheritance_info{parent_statements} = \@parent_classes;
		}
		# Also check for multiple parents: use parent qw(Class1 Class2)
		if ($content =~ /use\s+(parent|base)\s+qw?[\(\[]?(.+?)[\)\]]?;/) {
			my $parents = $2;
			my @multi_parents = split /\s+/, $parents;
			push @parent_classes, @multi_parents;
			$inheritance_info{parent_statements} = \@parent_classes;
		}
	}

	# 2. Look for @ISA assignments (with or without 'our')
	my $isas = $doc->find('PPI::Statement::Variable') || [];
	foreach my $isa (@$isas) {
		my $content = $isa->content();
		# Match both "our @ISA = qw(...)" and "@ISA = qw(...)"
		if ($content =~ /(?:our\s+)?\@ISA\s*=\s*qw?[\(\[]?(.+?)[\)\]]?/) {
			my $parents = $1;
			my @isa_parents = split(/\s+/, $parents);
			push @parent_classes, @isa_parents;
			$inheritance_info{isa_array} = \@isa_parents;
		}
	}

	# Also look for @ISA in regular statements
	my $statements = $doc->find('PPI::Statement') || [];
	foreach my $stmt (@$statements) {
		my $content = $stmt->content;
		if ($content =~ /\@ISA\s*=\s*qw?[\(\[]?(.+?)[\)\]]?/) {
			my $parents = $1;
			my @isa_parents = split(/\s+/, $parents);
			push @parent_classes, @isa_parents;
			$inheritance_info{isa_array} = \@isa_parents;
		}
	}

	# 3. Check if method uses SUPER:: calls
	if ($method_body && $method_body =~ /SUPER::/) {
		$inheritance_info{uses_super} = 1;
		if ($method_body =~ /SUPER::new/) {
			$inheritance_info{calls_super_new} = 1;
		}
	}

	# 4. Check if current package has its own new method
	my $has_own_new = $doc->find(sub {
		$_[1]->isa('PPI::Statement::Sub') &&
		$_[1]->name eq 'new'
	});

	if ($has_own_new) {
		$inheritance_info{has_own_constructor} = 1;
	} elsif (@parent_classes) {
		# No own constructor, but has parents - might need parent constructor
		$inheritance_info{use_parent_constructor} = 1;
		$inheritance_info{parent_class} = $parent_classes[0];	# Use first parent
	}

	return \%inheritance_info if keys %inheritance_info;
	return undef;
}

=head2 _detect_constructor_requirements

Detect if constructor (new method) needs specific parameters.

Analyzes the new method to determine required parameters.

=cut

sub _detect_constructor_requirements {
	my ($self, $current_package, $target_package) = @_;

	my $doc = $self->{_document};
	return undef unless $doc;

	# If target is different from current, we can't analyze it
	# (external class, parent class in different file)
	if ($target_package ne $current_package) {
		return {
			external_class => 1,
			package => $target_package,
			note => "Constructor for external class $target_package - parameters unknown"
		};
	}

	# Find the new method in current package
	my $new_method = $doc->find_first(sub {
		$_[1]->isa('PPI::Statement::Sub') &&
		$_[1]->name eq 'new'
	});

	return undef unless $new_method;

	my %requirements;

	# Get method body
	my $body = $new_method->content;

	# Look for parameter extraction patterns - handle both $self and $class
	if ($body =~ /my\s*\(\s*\$(self|class)\s*,\s*(.+?)\)\s*=\s*\@_/s) {
		my $params = $2;
		my @param_names = $params =~ /\$(\w+)/g;

		if (@param_names) {
			$requirements{parameters} = \@param_names;
			$requirements{parameter_count} = scalar @param_names;
		}
	}

	# Look for shift patterns
	my @shift_params;
	while ($body =~ /my\s+\$(\w+)\s*=\s*shift/g) {
		push @shift_params, $1;
	}
	# Remove $self or $class if present
	@shift_params = grep { $_ !~ /^(self|class)$/i } @shift_params;

	if (@shift_params) {
		$requirements{parameters} = \@shift_params;
		$requirements{parameter_count} = scalar @shift_params;
		$requirements{shift_pattern} = 1;
	}

	# Look for validation of parameters (more flexible pattern)
	my @required_params;
	if ($body =~ /croak.*unless.*(?:defined\s+)?\$(\w+)/g) {
		push @required_params, $1;
	}
	if ($body =~ /die.*unless.*(?:defined\s+)?\$(\w+)/g) {
		push @required_params, $1;
	}

	if (@required_params) {
		$requirements{required_parameters} = \@required_params;
	}

	# Look for default values (optional parameters)
	my @optional_params;
	my %default_values;

	# Use the new _extract_default_value method
	# Check for each parameter in the constructor body
	if ($requirements{parameters}) {
		foreach my $param (@{$requirements{parameters}}) {
			my $default = $self->_extract_default_value($param, $body);
			if (defined $default) {
				push @optional_params, $param;
				$default_values{$param} = $default;
			}
		}
	}

	if (@optional_params) {
		$requirements{optional_parameters} = \@optional_params;
		$requirements{default_values} = \%default_values;
	}

	return \%requirements if keys %requirements;
	return undef;
}


=head2 _detect_external_object_dependency

Detect if method depends on objects from other classes.

Patterns:
- Creates objects of other classes
- Calls methods on objects from other classes
- Receives objects as parameters

=cut

sub _detect_external_object_dependency {
	my ($self, $method_body) = @_;

	return undef unless $method_body;

	my %dependency_info;

	# Pattern 1: Creates objects of other classes with ->new() or ->create()
	# Reset pos for global match
	pos($method_body) = 0;
	while ($method_body =~ /(\w+(?:::\w+)*)->(?:new|create)\(/g) {
		my $class = $1;
		next if $class eq 'main' || $class eq '__PACKAGE__' || $class =~ /^\$/;
		push @{$dependency_info{creates_objects}}, $class;
	}

	if ($dependency_info{creates_objects}) {
		# Remove duplicates
		my %seen;
		$dependency_info{creates_objects} = [grep { !$seen{$_}++ } @{$dependency_info{creates_objects}}];
		$dependency_info{package} = $dependency_info{creates_objects}[0];
	}

	# Pattern 2: Calls methods on objects from other classes
	if ($method_body =~ /\$(\w+)->\w+\(/g) {
		my %object_vars;
		while ($method_body =~ /\$(\w+)->\w+\(/g) {
			$object_vars{$1}++;
		}

		# Try to determine type of object variables
		my @object_classes;
		foreach my $var (keys %object_vars) {
			# Look for type declarations or assignments
			if ($method_body =~ /my\s+\$$var\s*=\s*(\w+(?:::\w+)+)->(?:new|create)/) {
				push @object_classes, $1;
			} elsif ($method_body =~ /my\s+\$$var\s*=\s*(\w+(?:::\w+)+)->/) {
				push @object_classes, $1;
			}
		}

		if (@object_classes) {
			$dependency_info{uses_objects} = \@object_classes;
			$dependency_info{package} = $object_classes[0] unless $dependency_info{package};
		}
	}

	# Pattern 3: Receives objects as parameters (type hints in comments/POD)
	# This would need integration with parameter analysis

	return \%dependency_info if keys %dependency_info;
	return undef;
}

sub _get_parent_class {
	my $self = $_[0];

	my $doc = $self->{_document};
	return unless $doc;

	# Look for use parent statements
	my $parent_stmt = $doc->find_first(sub {
		$_[1]->isa('PPI::Statement::Include') &&
		$_[1]->type eq 'use' &&
		$_[1]->module =~ /^(parent|base)$/ &&
		$_[1]->arguments =~ /['"](\w+(?:::\w+)*)['"]/
	});
	if ($parent_stmt) {
		my $parent = $1;
		return $parent;
	}

	# Look for @ISA assignment
	my $isa_stmt = $doc->find_first(sub {
		$_[1]->isa('PPI::Statement') &&
		$_[1]->content =~ /our\s+\@ISA\s*=\s*\(\s*['"](\w+(?:::\w+)*)['"]\s*\)/
	});
	if ($isa_stmt && $isa_stmt->content =~ /['"](\w+(?:::\w+)*)['"]/) {
		return $1;
	}

	return;
}

sub _get_class_for_instance_method {
	my $self = $_[0];

	# Get the current package
	my $doc = $self->{_document};
	my $package_stmt = $doc->find_first('PPI::Statement::Package');
	return 'UNKNOWN_PACKAGE' unless $package_stmt;
	my $package_name = $package_stmt->namespace;

	# Check if the current package has a 'new' method
	my $has_new = $doc->find(sub {
		$_[1]->isa('PPI::Statement::Sub') && $_[1]->name eq 'new'
	});

	if ($has_new) {
		return $package_name;
	}

	# Otherwise, try to get the parent class
	my $parent = $self->_get_parent_class();
	return $parent if $parent;

	# Fallback to current package
	return $package_name;
}

=head2 _extract_default_value

Extract default values from common Perl patterns:

Patterns:
  - $param = $param || 'default_value'
  - $param //= 'default_value'
  - $param = defined $param ? $param : 'default'
  - $param = 'default' unless defined $param;
  - $param = $arg // 'default'
  - $param ||= 'default'

Returns the default value as a string if found, undef otherwise.

=cut

sub _extract_default_value {
	my ($self, $param, $code) = @_;

	return undef unless $param && $code;

	# Clean up the code for easier pattern matching
	# Remove comments to avoid false positives
	my $clean_code = $code;
	$clean_code =~ s/#.*$//gm;
	$clean_code =~ s/^\s+|\s+$//g;

	# Pattern 1: $param = $param || 'default_value'
	# Also handles: $param = $arg || 'default'
	if ($clean_code =~ /\$$param\s*=\s*(?:\$$param|\$[a-zA-Z_]\w*)\s*\|\|\s*([^;]+)/) {
		my $default = $1;
		$default =~ s/\s*;\s*$//;
		$default = $self->_clean_default_value($default);
		return $default if defined $default;
	}

	# Pattern 2: $param //= 'default_value'
	if ($clean_code =~ /\$$param\s*\/\/=\s*([^;]+)/) {
		my $default = $1;
		$default =~ s/\s*;\s*$//;
		$default = $self->_clean_default_value($default);
		return $default if defined $default;
	}

	# Pattern 3: $param = defined $param ? $param : 'default'
	# Also handles: $param = defined $arg ? $arg : 'default'
	if ($clean_code =~ /\$$param\s*=\s*defined\s+(?:\$$param|\$[a-zA-Z_]\w*)\s*\?\s*(?:\$$param|\$[a-zA-Z_]\w*)\s*:\s*([^;]+)/) {
		my $default = $1;
		$default =~ s/\s*;\s*$//;
		$default = $self->_clean_default_value($default);
		return $default if defined $default;
	}

	# Pattern 4: $param = 'default' unless defined $param;
	if ($clean_code =~ /\$$param\s*=\s*([^;]+?)\s+unless\s+defined\s+(?:\$$param|\$[a-zA-Z_]\w*)/) {
		my $default = $1;
		$default = $self->_clean_default_value($default);
		return $default if defined $default;
	}

	# Pattern 5: $param ||= 'default'
	if ($clean_code =~ /\$$param\s*\|\|=\s*([^;]+)/) {
		my $default = $1;
		$default =~ s/\s*;\s*$//;
		$default = $self->_clean_default_value($default);
		return $default if defined $default;
	}

	# Pattern 6: $param = $arg // 'default'
	if ($clean_code =~ /\$$param\s*=\s*(?:\$$param|\$[a-zA-Z_]\w*)\s*\/\/\s*([^;]+)/) {
		my $default = $1;
		$default =~ s/\s*;\s*$//;
		$default = $self->_clean_default_value($default);
		return $default if defined $default;
	}

	# Pattern 7: Multi-line: if (!defined $param) { $param = 'default'; }
	if ($clean_code =~ /if\s*\(\s*!defined\s+\$$param\s*\)\s*\{[^}]*\$$param\s*=\s*([^;]+)/s) {
		my $default = $1;
		$default =~ s/\s*;\s*$//;
		$default = $self->_clean_default_value($default);
		return $default if defined $default;
	}

	# Pattern 8: unless (defined $param) { $param = 'default'; }
	if ($clean_code =~ /unless\s*\(\s*defined\s+\$$param\s*\)\s*\{[^}]*\$$param\s*=\s*([^;]+)/s) {
		my $default = $1;
		$default =~ s/\s*;\s*$//;
		$default = $self->_clean_default_value($default);
		return $default if defined $default;
	}

	return undef;
}

sub _extract_test_hints {
	my ($self, $method, $schema) = @_;

	my %hints = (
		boundary_values => [],
		invalid_inputs => [],
		equivalence_classes => [],
		valid_inputs => [],
	);

	my $code = $method->{body};
	return {} unless $code;

	$self->_extract_invalid_input_hints($code, \%hints);
	$self->_extract_boundary_value_hints($code, \%hints);

	# prune empties
	for my $k (keys %hints) {
		delete $hints{$k} unless @{$hints{$k}};
	}

	return \%hints;
}

sub _extract_invalid_input_hints {
	my ($self, $code, $hints) = @_;

	# undef invalid
	if ($code =~ /defined\s*\(\s*\$/) {
		push @{ $hints->{invalid_inputs} }, 'undef';
	}

	# empty string invalid
	if ($code =~ /\beq\s*''/ || $code =~ /\blength\s*\(/) {
		push @{ $hints->{invalid_inputs} }, '';
	}

	# negative number invalid
	if ($code =~ /\$\w+\s*<\s*0/) {
		push @{ $hints->{invalid_inputs} }, -1;
	}
}

sub _extract_boundary_value_hints {
	my ($self, $code, $hints) = @_;

	while ($code =~ /\$\w+\s*(<=|<|>=|>)\s*(\d+)/g) {
		my ($op, $n) = ($1, $2);

		if ($op eq '<') {
			push @{ $hints->{boundary_values} }, $n, $n+1;
		} elsif ($op eq '<=') {
			push @{ $hints->{boundary_values} }, $n, $n+1;
		} elsif ($op eq '>') {
			push @{ $hints->{boundary_values} }, $n, $n-1;
		} elsif ($op eq '>=') {
			push @{ $hints->{boundary_values} }, $n, $n-1;
		}
	}

	# Remove duplicates
	my %seen;
	$hints->{boundary_values} = [ grep { !$seen{$_}++ } @{ $hints->{boundary_values} } ];
}

# --- POD example extraction (non-authoritative hints) ---
sub _extract_pod_examples {
	my ($self, $pod, $hints) = @_;

	return $hints unless $pod;

	my @examples;

	# Extract SYNOPSIS
	return $hints unless $pod =~ /=head2\s+SYNOPSIS\s*(.+?)(?=\n=head|\z)/s;
	my $synopsis = $1;

	# Constructor examples: ->wilma(foo => 'bar', count => 5)
	while ($synopsis =~ /->([a-z_0-9A-Z]+)\s*\(\s*(.*?)\s*\)/sg) {
		my ($method, $args) = ($1, $2);
		my %kv;

		while ($args =~ /(\w+)\s*=>\s*(?:'([^']*)'|"([^"]*)"|(\d+))/g) {
			my $key = $1;
			my $val = defined $2 ? $2 : defined $3 ? $3 : $4;
			$kv{$key} = $val;
		}

		push @examples, {
			style => 'named',
			source => 'pod',
			args => \%kv,
			function => $method,	# TODO: add a sanity check this is what we expect
		} if %kv;
	}

	unless(scalar(@examples)) {
		# Positional calls: func($a, $b)
		while ($synopsis =~ /\b(\w+)\s*\(\s*(.*?)\s*\)/sg) {
			my ($func, $argstr) = ($1, $2);

			# next if $func eq 'new';	# already handled

			my @args = map { s/^\s+|\s+$//gr } split /\s*,\s*/, $argstr;

			next unless @args;

			push @examples, {
				style	=> 'positional',
				source	=> 'pod',
				function => $func,
				args	=> \@args,
			};
		}
	}

	if (scalar(@examples)) {
		$hints->{valid_inputs} ||= [];
		push @{ $hints->{valid_inputs} }, @examples;

		$self->_log("  POD: extracted " . scalar(@examples) . " example call(s)");
	}

	return $hints;
}

=head2 _clean_default_value

Clean and normalize extracted default values.

Handles:
  - Removing quotes from strings
  - Converting numeric strings to actual numbers
  - Handling boolean values
  - Removing parentheses

=cut

sub _clean_default_value
{
	my ($self, $value, $from_code) = @_;

	return unless defined $value;

	# Remove leading/trailing whitespace
	$value =~ s/^\s+|\s+$//g;

	# Remove parenthetical notes like "(no password)" only if there's content before them
	$value =~ s/(\S+)\s*\([^)]+\)\s*$/$1/;
	$value =~ s/^\s+|\s+$//g;

	# Handle chained || or // operators - extract the rightmost value
	if ($value =~ /\|\||\/{2}/) {
		my @parts = split(/\s*(?:\|\||\/{2})\s*/, $value);
		$value = $parts[-1];
		$value =~ s/^\s+|\s+$//g;
	}

	# Remove trailing semicolon if present
	$value =~ s/;\s*$//;

	# Handle q{}, qq{}, qw{} quotes
	if ($value =~ /^qq?\{(.*?)\}$/s) {
		$value = $1;
	} elsif ($value =~ /^qw\{(.*?)\}$/s) {
		$value = $1;
	} elsif ($value =~ /^q[qwx]?\s*([^a-zA-Z0-9\{\[])(.*?)\1$/s) {
		$value = $2;
	}

	# Handle quoted strings
	if ($value =~ /^(['"])(.*)\1$/s) {
		$value = $2;

		if ($from_code) {
			# In regex captures from source code, escape sequences are doubled
			# \\n in capture needs to become \n for the test
			$value =~ s/\\\\/\\/g;
		}

		# Only unescape the quote characters themselves
		$value =~ s/\\"/"/g;
		$value =~ s/\\'/'/g;

		# If NOT from code (i.e., from POD), interpret escape sequences
		unless ($from_code) {
			$value =~ s/\\n/\n/g;
			$value =~ s/\\r/\r/g;
			$value =~ s/\\t/\t/g;
			$value =~ s/\\\\/\\/g;
		}
	}

	# Sometimes trailing ) is left on
	if($value !~ /^\(/) {
		$value =~ s/\)$//;
	}

	# Handle Perl empty hash (must be before numeric/boolean checks)
	if ($value =~ /^\{\s*\}$/) {
		return {};
	}

	# Handle Perl empty list/array
	if ($value =~ /^\[\s*\]$/) {
		return [];
	}

	# Handle numeric values
	if ($value =~ /^-?\d+(?:\.\d+)?$/) {
		if ($value =~ /\./) {
			return $value + 0;
		} else {
			return int($value);
		}
	}

	# Handle boolean keywords
	if ($value =~ /^(true|false)$/i) {
		return lc($1) eq 'true' ? 1 : 0;
	}

	# Handle Perl boolean constants
	if ($value eq '1') {
		return 1;
	} elsif ($value eq '0') {
		return 0;
	}

	# Handle undef
	if ($value eq 'undef') {
		return undef;
	}

	# Handle __PACKAGE__ and similar constants
	if ($value eq '__PACKAGE__') {
		return '__PACKAGE__';
	}

	# Remove surrounding parentheses
	$value =~ s/^\((.+)\)$/$1/;

	# Handle expressions we can't evaluate
	if ($value =~ /^\$[a-zA-Z_]/ || $value =~ /\(.*\)/) {
		return if($value =~ /^\$|\@|\%/);	# The default is a value, so who knows its type?
		# return $value;
	}

	return $value;
}

=head2 _log

Log a message if verbose mode is on.

=cut

sub _log {
	my ($self, $msg) = @_;
	print "$msg\n" if $self->{verbose};
}

=head1 NOTES

This is pre-pre-alpha proof of concept code.
Nevertheless,
it is useful for creating a template which you can modify to create a working schema to pass into L<App::Test::Generator>.

=head1 SEE ALSO

=over 4

=item * L<App::Test::Generator> - Generate fuzz and corpus-driven test harnesses

Output from this module serves as input to that module.
So with well-documented code, you can automatically create your tests.

=item * L<App::Test::Generator::Template> - Template of the file of tests created by C<App::Test::Generator>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's initial design and documentation were created with the
assistance of AI.

=cut

1;
