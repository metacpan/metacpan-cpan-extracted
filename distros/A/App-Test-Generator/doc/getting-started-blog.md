# Stop Writing Test Cases By Hand: An Introduction to Specification-Driven Testing in Perl

**TL;DR:** Imagine describing what your function *should do* once, and automatically generating hundreds of test cases that probe edge cases, boundary conditions, and error handling. That's `App::Test::Generator`.

## The Problem

You've just written a function that validates email addresses. You know you should test it thoroughly:

```perl
sub validate_email {
    my ($email) = @_;
    # ... validation logic ...
    return 1 if valid, dies otherwise
}
```

So you start writing tests:

```perl
ok(validate_email('user@example.com'), 'basic email works');
ok(validate_email('user+tag@example.com'), 'plus addressing works');
dies_ok { validate_email('') } 'empty string dies';
dies_ok { validate_email('not-an-email') } 'invalid format dies';
# ... 50 more test cases you need to think of ...
```

**The questions that keep you up at night:**
- Did I test empty strings? What about strings with only whitespace?
- What about null bytes? Unicode? Emoji?
- What if someone passes `undef`? An array reference?
- Did I check the boundary between valid and invalid lengths?
- Am I testing the same cases I tested last month, or did I miss something new?

## The Solution: Write a Specification, Get Tests for Free

Instead of writing individual test cases, describe what your function *should accept*:

```yaml
---
module: Email::Validator
function: validate_email

input:
  email:
    type: string
    min: 3
    max: 254  # RFC 5321 limit
    matches: "^[\\w.+-]+@[\\w.-]+\\.[a-zA-Z]{2,}$"

output:
  type: boolean

config:
  test_undef: yes
  test_empty: yes
  test_nuls: yes

seed: 42
iterations: 100
```

Save this as `t/conf/validate_email.yml`, then run:

```bash
$ fuzz-harness-generator t/conf/validate_email.yml > t/validate_email_fuzz.t
$ prove -v t/validate_email_fuzz.t
```

**What just happened?**

The generator created a test file with:
- ✅ 100 random valid emails (fuzzing)
- ✅ Edge cases: exactly 3 chars, exactly 254 chars, 2 chars (too short), 255 chars (too long)
- ✅ Regex boundary tests: strings that almost match, strings with special chars
- ✅ Invalid inputs: `undef`, empty string, null bytes, emoji, full-width characters
- ✅ Wrong types: arrays, hashes, numbers passed as email
- ✅ Reproducible: Same seed = same random tests every time

That's **200+ test cases** from a 15-line YAML file.

## Real-World Example: Testing a Math Function

Let's test something more complex. Here's a function that normalizes numbers to a 0-1 range:

```perl
package Math::Utils;

sub normalize {
    my ($value, $min, $max) = @_;
    die "min must be less than max" unless $min < $max;
    die "value out of range" if $value < $min || $value > $max;

    return ($value - $min) / ($max - $min);
}
```

The specification captures both valid inputs **and** the transformation rules:

```yaml
---
module: Math::Utils
function: normalize

input:
  value:
    type: number
    position: 0
  min:
    type: number
    position: 1
  max:
    type: number
    position: 2

output:
  type: number
  min: 0
  max: 1

transforms:
  min_value_returns_zero:
    input:
      value: { type: number, value: 0 }
      min: { type: number, value: 0 }
      max: { type: number, value: 100 }
    output:
      type: number
      value: 0

  max_value_returns_one:
    input:
      value: { type: number, value: 100 }
      min: { type: number, value: 0 }
      max: { type: number, value: 100 }
    output:
      type: number
      value: 1

  midpoint_returns_half:
    input:
      value: { type: number, value: 50 }
      min: { type: number, value: 0 }
      max: { type: number, value: 100 }
    output:
      type: number
      value: 0.5

  inverted_range_dies:
    input:
      value: { type: number, value: 50 }
      min: { type: number, value: 100 }
      max: { type: number, value: 0 }
    output:
      _STATUS: DIES

iterations: 50
seed: 42
```

This generates tests that verify:
1. The math is correct (transforms)
2. Boundary conditions work (min=0 returns 0, max=100 returns 1)
3. Invalid inputs are rejected (inverted range dies)
4. Random inputs within range work correctly

## The Five-Minute Quick Start

### 1. Install the module

```bash
cpanm App::Test::Generator
```

### 2. Create a configuration file

`t/conf/my_function.yml`:

```yaml
---
module: My::Module
function: my_function

input:
  name:
    type: string
    min: 1
    max: 100
  age:
    type: integer
    min: 0
    max: 150
    optional: true

output:
  type: string

seed: 12345
iterations: 50
```

### 3. Generate and run tests

```bash
# Generate the test file
fuzz-harness-generator t/conf/my_function.yml > t/my_function_fuzz.t

# Run it
prove -v t/my_function_fuzz.t
```

### 4. Add to your CI/CD

The best part? Add this to GitHub Actions and it runs automatically:

`.github/workflows/fuzz.yml`:

```yaml
name: Fuzz Testing

on:
  push:
    branches: [main, master]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  fuzz-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
 
      - name: Setup Perl
        uses: shogo82148/actions-setup-perl@v1
        with:
          perl-version: '5.38'

      - name: Install dependencies
        run: |
          cpanm App::Test::Generator
          cpanm --installdeps .

      - name: Generate and run fuzz tests
        run: |
          mkdir -p t/fuzz
          for config in t/conf/*.yml; do
            test_name=$(basename "$config" .yml)
            fuzz-harness-generator "$config" > "t/fuzz/${test_name}_fuzz.t"
          done
          prove -lr t/fuzz/
```

Now you get **continuous fuzzing** - your code is tested against hundreds of edge cases every day.

## Common Patterns

### Pattern 1: Security-Critical Input Validation

```yaml
input:
  user_input:
    type: string
    max: 1000
    nomatch: "[<>\"'&;]"  # Block XSS attempts

edge_case_array:
  - "<script>alert('xss')</script>"
  - "'; DROP TABLE users; --"
  - "../../../etc/passwd"
  - "test\0null"
```

### Pattern 2: API Response Validation

```yaml
module: API::Client
function: fetch_user

input:
  user_id:
    type: string
    matches: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"  # UUID

output:
  type: hashref
  # The response should be a hash

config:
  test_undef: yes
```

### Pattern 3: Data Transformation Pipeline

```yaml
module: Data::Pipeline
function: clean_phone

input:
  phone:
    type: string

output:
  type: string
  matches: "^\\+?[1-9]\\d{1,14}$"  # E.164 format

edge_cases:
  phone:
    - "+1 (555) 123-4567"  # Should normalize
    - "555-1234"           # Should add country code
    - "(555) 123-4567"     # Should normalize
```

## When Should You Use This?

**Perfect for:**
- ✅ Input validation functions
- ✅ Data transformation/normalization
- ✅ API clients with strict schemas
- ✅ Parser/serializer code
- ✅ Any function with clear input/output contracts

**Not ideal for:**
- ❌ Functions with complex side effects (use traditional mocking)
- ❌ UI testing (use Selenium/Playwright)
- ❌ Functions that depend heavily on external state
- ❌ Integration tests (this is for unit testing)

## The Hidden Benefits

Beyond just generating tests, specification-driven testing gives you:

1. **Living Documentation** - Your YAML files document what your functions should do
2. **Regression Prevention** - Changes that break the spec fail immediately
3. **Refactoring Confidence** - Rewrite internals, keep the same spec, tests still pass
4. **Cross-Team Communication** - QA can write specs, developers implement
5. **Security Mindset** - Forces you to think about malicious inputs

## What Gets Tested Automatically?

Every schema generates tests for:

- **Type errors**: Passing wrong types (string instead of int, etc.)
- **Boundary conditions**: Min-1, min, min+1, max-1, max, max+1
- **Empty inputs**: '', [], {}, undef
- **Unicode handling**: Emoji, combining characters, full-width digits
- **Injection attacks**: Null bytes, path traversal, SQL/XSS patterns (if configured)
- **Large inputs**: 10,000 character strings
- **Edge case combinations**: Your edge_cases + random fuzzing

## Debugging Failed Tests

When a test fails, you get clear output:

```
not ok 42 - my_function(name => 'a' x 101) dies
#   Failed test 'my_function(name => 'a' x 101) dies'
#   at t/my_function_fuzz.t line 347.
# Expected function to die but it returned: 'processed'
```

You can see:
1. **What input caused the failure** (name with 101 'a' characters)
2. **What was expected** (function should die)
3. **What actually happened** (returned 'processed')

Add `TEST_VERBOSE=1` to see the full input/output:

```bash
TEST_VERBOSE=1 prove -v t/my_function_fuzz.t
```

## Advanced Features

### Static Corpus Testing

Combine fuzzing with known test cases:

```yaml
cases:
  success_case:
    input: ["valid@email.com"]
    status: OK
  failure_case:
    input: ["not-an-email"]
    status: DIES
```

### Object-Oriented Testing

```yaml
module: My::Class
function: process

new:
  api_key: ABC123
  timeout: 30

input:
  data:
    type: string
```

This generates `my $obj = My::Class->new(api_key => 'ABC123', ...)` automatically.

### Custom Edge Cases by Type

```yaml
type_edge_cases:
  string:
    - ''
    - ' '
    - "\t\n"
    - 'x' x 10000
    - "😊🎉"  # emoji
  integer:
    - 0
    - -1
    - 2147483647   # 32-bit max
    - -2147483648  # 32-bit min
```

## Getting Help

- 📚 **Full documentation**: `perldoc App::Test::Generator`
- 🐛 **Issues/Questions**: https://github.com/nigelhorne/App-Test-Generator/issues
- 💬 **Examples**: See `t/conf/` in the repository
- 📊 **Coverage reports**: https://nigelhorne.github.io/App-Test-Generator/coverage/

## Try It Today

Pick one function in your codebase that:
1. Has clear input requirements
2. You're nervous about (parsing, validation, critical path)
3. Could use more test coverage

Write a 10-line YAML file describing it. Generate 200+ tests. Find bugs you didn't know existed.

That's the power of specification-driven testing.

---

*App::Test::Generator is open source and available on CPAN. Contributions welcome!*

---

## Appendix: Complete Example

Here's a complete example testing CGI::Info's `script_path` function (which takes no arguments and returns an absolute path):

`t/conf/script_path.yml`:
```yaml
---
module: CGI::Info
function: script_path

input: undef  # Takes no arguments

output:
  type: string
  min: 1
  matches: "^(?:[A-Za-z]:[/\\\\]|/)"  # Windows or Unix absolute path

config:
  test_undef: yes

seed: 42
iterations: 50
```

Generated test output:
```
ok 1 - use CGI::Info;
ok 2 - script_path survives
ok 3 - output validates
ok 4 - script_path survives
ok 5 - output validates
# ... 50+ tests of calling with no arguments ...
1..52
```

Simple, clear, comprehensive.
