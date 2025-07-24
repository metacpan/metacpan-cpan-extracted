# Brannigan

A comprehensive, flexible Perl library for validating and processing input data,
particularly useful for web applications and APIs.

## Features

- **Schema-based validation** - Define reusable validation schemas with comprehensive rules
- **Nested data structures** - Full support for validating arrays, hashes, and deeply nested combinations
- **Unknown parameter handling** - Control how unknown parameters are handled (ignore, remove, or reject)
- **Schema inheritance** - Create new schemas by extending existing ones
- **Custom validators** - Easy integration of custom validation logic
- **Pre/post processing** - Transform data before validation and after successful validation
- **Rich error reporting** - Detailed error information with dot-notation paths for nested structures

## Installation

### From CPAN

```bash
cpanm Brannigan
```

### From Source

```bash
git clone https://github.com/ido50/Brannigan.git
cd Brannigan
perl Makefile.PL
make
make test
make install
```

## Quick Start

```perl
use Brannigan;

# Create validator
my $b = Brannigan->new({ handle_unknown => 'remove' });

# Define a schema
my $user_schema = {
    params => {
        name => {
            required => 1,
            length_between => [2, 50],
            preprocess => sub { s/^\s+|\s+$//gr }, # trim whitespace
        },
        email => {
            required => 1,
            matches => qr/^[^@]+@[^@]+\.[^@]+$/,
        },
        age => {
            required => 0,
            integer => 1,
            value_between => [13, 120],
            default => 18,
        },
        preferences => {
            hash => 1,
            keys => {
                newsletter => { default => 0 },
                theme => { one_of => ['light', 'dark'], default => 'light' },
            },
        },
    },
};

# Register the schema
$b->register_schema('user', $user_schema);

# Validate input data
my %input = (
    name => '  John Doe  ',
    email => 'john@example.com',
    preferences => { newsletter => 1 },
    unknown_field => 'will be removed',
);

my $rejects = $b->process('user', \%input);

if ($rejects) {
    # Validation failed
    print "Validation errors:\n";
    for my $field (keys %$rejects) {
        print "  $field: " . join(', ', keys %{$rejects->{$field}}) . "\n";
    }
} else {
    # Validation passed - input has been processed in-place
    print "User data: " . Dumper(\%input);
    # Output: name is trimmed, age defaults to 18, theme defaults to 'light'
}
```

## Key Concepts

### Validation Process

Brannigan processes input through a 5-stage pipeline:

1. **Schema Preparation** - Load and merge inherited schemas
2. **Preprocessing** - Apply default values and preprocess functions
3. **Validation** - Check all validation rules
4. **Postprocessing** - Apply postprocess functions if validation passed
5. **Result** - Return `undef` (success) or rejects hash-ref (failure)

### Unknown Parameter Handling

Control how unknown parameters are handled:

```perl
my $b = Brannigan->new({ handle_unknown => 'ignore' });  # Keep unknown params (default)
my $b = Brannigan->new({ handle_unknown => 'remove' });  # Delete unknown params
my $b = Brannigan->new({ handle_unknown => 'reject' });  # Fail validation on unknown params
```

### Schema Inheritance

Schemas can inherit from other schemas:

```perl
my $base_schema = {
    params => {
        name => { required => 1, length_between => [2, 50] },
        email => { required => 1 },
    },
};

my $user_update_schema = {
    inherits_from => 'base_user',
    params => {
        name => { required => 0 },  # Override: name no longer required for updates
        last_login => { required => 0 },  # Add new field
    },
};

$b->register_schema('base_user', $base_schema);
$b->register_schema('user_update', $user_update_schema);
```

## Documentation

Run `perldoc Brannigan` after installation for the complete documentation.

## Development

### Running Tests

```bash
# Run all tests
prove -l t/

# Run specific test files
perl -Ilib t/01-validations.t
perl -Ilib t/07-complex-structures.t
```

### Building Distribution

```bash
perl Makefile.PL
make dist
```

### Releasing to CPAN

Use the included release script:

```bash
./release.sh
```

This will:

1. Run all tests
2. Create the distribution tarball
3. Provide instructions for CPAN upload

For CPAN upload, you'll need:

- A PAUSE account (https://pause.perl.org/)
- CPAN::Uploader installed (`cpanm CPAN::Uploader`)
- PAUSE credentials in `~/.pause`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Ensure all tests pass: `prove -l t/`
5. Submit a pull request

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) file for details.

## Links

- **GitHub**: https://github.com/ido50/Brannigan
- **Issues**: https://github.com/ido50/Brannigan/issues
- **CPAN**: https://metacpan.org/pod/Brannigan
