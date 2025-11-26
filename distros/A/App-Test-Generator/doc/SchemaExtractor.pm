# App::Test::Generator::SchemaExtractor

Automatically extract test schemas from Perl modules for use with App::Test::Generator.

## Overview

This tool analyzes Perl modules and generates YAML schema files describing each method's parameters, types, and constraints. These schemas can then be used to automatically generate comprehensive test suites.

### Features

- **POD Parsing**: Extracts type information from method documentation
- **Code Analysis**: Detects validation patterns (length checks, ref checks, regex matching)
- **Signature Analysis**: Identifies parameter names from method signatures
- **Confidence Scoring**: Rates each schema as high/medium/low confidence
- **YAML Output**: Generates clean, editable schema files

## Installation

### Prerequisites

```bash
cpanm PPI
cpanm Pod::Simple
cpanm YAML::XS
```

### Install the Module

```bash
# Copy files to your project
cp SchemaExtractor.pm lib/App/Test/Generator/
cp extract-schemas bin/
chmod +x bin/extract-schemas
```

## Quick Start

### 1. Extract schemas from a module

```bash
perl bin/extract-schemas lib/MyModule.pm
```

This creates schema YAML files in `./schemas/` directory.

### 2. Review generated schemas

```bash
cat schemas/validate_email.yaml
```

Example output:
```yaml
---
confidence: high
input:
  email:
    max: 254
    min: 5
    matches: /^[^@]+@[^@]+\.[^@]+$/
    optional: 0
    type: string
method: validate_email
notes: []
```

### 3. Edit schemas as needed

Low confidence schemas may need manual correction:

```yaml
---
confidence: low
input:
  thing:
    optional: 0
    type: string  # <- You might need to fix this
method: mysterious_method
notes:
  - 'thing: type unknown - please review'
```

### 4. Use with Test Generator

```bash
fuzz-harness-generator -r schemas/validate_email.yaml
```

## Usage Examples

### Basic Usage

```bash
# Extract schemas with default settings
extract-schemas lib/MyModule.pm

# Specify output directory
extract-schemas --output-dir my_schemas lib/MyModule.pm

# Verbose mode (shows analysis details)
extract-schemas --verbose lib/MyModule.pm
```

### Run the Demo

Test the extractor with the included demo:

```bash
perl demo_extractor.pl
```

This creates a sample module, extracts schemas, and validates the results.

## How It Works

### 1. POD Analysis

The extractor looks for parameter documentation in POD:

```perl
=head2 validate_email($email)

=head3 INPUT

  $email - string (5-254 chars), email address

Returns: 1 if valid
=cut
```

Extracts:
- Type: `string`
- Min: `5`
- Max: `254`
- Optional: `false` (inferred from "required")

### 2. Code Pattern Analysis

Detects validation patterns:

```perl
sub validate_email {
    my ($self, $email) = @_;

    croak "Email required" unless defined $email;
    croak "Too short" unless length($email) >= 5;     # min: 5
    croak "Too long" unless length($email) <= 254;    # max: 254
    croak "Invalid" unless $email =~ /pattern/;       # matches: /pattern/

    return 1;
}
```

### 3. Type Inference

Infers types from usage:

```perl
if (ref($param) eq 'ARRAY')  # → type: arrayref
if (ref($param) eq 'HASH')   # → type: hashref
if ($param =~ /regex/)       # → type: string
if ($param > 5)              # → type: number
```

### 4. Confidence Scoring

- **High**: Well-documented with POD and validation code
- **Medium**: Some information from code or partial POD
- **Low**: Minimal information, needs manual review

## Schema Format

Generated YAML schemas follow this structure:

```yaml
---
method: method_name
confidence: high|medium|low
notes:
  - Warning or suggestion messages
input:
  param_name:
    type: string|integer|number|boolean|arrayref|hashref|object
    min: 5              # Minimum value/length
    max: 100            # Maximum value/length
    optional: 0         # 0=required, 1=optional
    matches: /regex/    # Regex pattern for validation
    memberof:           # List of allowed values
      - value1
      - value2
```

## Supported POD Formats

### Format 1: Inline Type

```perl
=head2 method($param)

Parameters:
  $param - string (5-50 chars), description
```

### Format 2: Type Keywords

```perl
=head2 method($param)

Parameters:
  $param - integer, positive number
  $email - string, matches /\@/
  $config - hashref, configuration options
```

### Format 3: Constraint Description

```perl
=head2 method($count)

Parameters:
  $count - integer (min 1, max 100), item count
```

## Improving Accuracy

### Write Better POD

Good documentation = better extraction:

```perl
# ✓ Good - specific and clear
=head2 validate_age($age)

Parameters:
  $age - integer (1-150), person's age in years
```

```perl
# ✗ Bad - vague
=head2 validate_age($age)

Validates age.
```

### Add Type Comments

Help the extractor with inline comments:

```perl
sub process {
    my ($self, $data) = @_;  # $data is arrayref

    croak unless ref($data) eq 'ARRAY';
    # ... rest of code
}
```

### Use Consistent Validation

Standard patterns are easier to detect:

```perl
# ✓ Detectable
croak "Too short" unless length($str) >= 5;
croak "Too long" unless length($str) <= 100;

# ✗ Hard to detect
my $len = length($str);
die "Bad length" if $len < 5 || $len > 100;
```

## Troubleshooting

### Low Confidence Scores

**Problem**: Most methods rated "low confidence"

**Solutions**:
1. Add POD documentation with parameter types
2. Use explicit validation (ref checks, length checks)
3. Review and manually edit generated schemas

### Missing Parameters

**Problem**: Parameters not detected

**Solutions**:
1. Ensure parameters are in the signature: `my ($self, $param) = @_;`
2. Document parameters in POD
3. Add manual schema entries

### Wrong Types

**Problem**: Incorrect type inference

**Solutions**:
1. Add explicit type in POD: `$param - integer`
2. Add ref checks in code: `ref($param) eq 'HASH'`
3. Manually correct the YAML file

### Regex Patterns Not Captured

**Problem**: Regex validation not detected

**Solutions**:
1. Use simple pattern: `$param =~ /pattern/`
2. Document in POD: `$param - string, matches /pattern/`
3. Add manually to YAML: `matches: '/pattern/'`

## Limitations

1. **No Type System**: Perl has no native types, so inference is heuristic-based
2. **Dynamic Code**: Cannot analyze runtime-conditional validation
3. **Complex Logic**: Nested if/else validation is hard to parse
4. **Context-Dependent**: Same parameter might have different types in different contexts

## Roadmap

- [ ] Support for Moose/Moo type constraints
- [ ] Function::Parameters signature parsing
- [ ] Type::Tiny integration
- [ ] Machine learning to improve heuristics
- [ ] Interactive review mode
- [ ] Batch processing for entire directory trees

## Contributing

To improve the extractor:

1. Test on real modules and report accuracy
2. Submit examples of patterns that aren't detected
3. Suggest new heuristics or validation patterns
4. Improve POD parsing patterns

## License

This software is free and open source.

## See Also

- [App::Test::Generator](https://github.com/nigelhorne/App-Test-Generator)
- [PPI](https://metacpan.org/pod/PPI) - Perl parsing
- [Pod::Simple](https://metacpan.org/pod/Pod::Simple) - POD parsing

## Author

Created with assistance from Claude (Anthropic)
