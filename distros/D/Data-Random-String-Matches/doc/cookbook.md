# Quick Pattern Reference

A handy reference for common regex patterns to use with Data::Random::String::Matches.

## Table of Contents

- [Numbers](#numbers)
- [Letters](#letters)
- [Mixed Alphanumeric](#mixed-alphanumeric)
- [Identifiers](#identifiers)
- [Contact Information](#contact-information)
- [Financial](#financial)
- [Passwords](#passwords)
- [Codes & References](#codes--references)
- [Web & URLs](#web--urls)
- [Technical](#technical)
- [Dates & Times](#dates--times)

---

## Numbers

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d{4}` | 4-digit number | 1234 |
| `\d{6}` | 6-digit number | 123456 |
| `[1-9]\d{3}` | 4-digit, no leading zero | 5432 |
| `\d{3}-\d{3}-\d{4}` | Phone format | 555-123-4567 |
| `\d{5}` | ZIP code | 12345 |
| `\d{5}-\d{4}` | ZIP+4 | 12345-6789 |

## Letters

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[A-Z]{3}` | 3 uppercase letters | ABC |
| `[a-z]{5}` | 5 lowercase letters | hello |
| `[A-Z][a-z]{4}` | Title case word | Hello |
| `[a-z]{3,8}` | 3-8 lowercase letters | word |

## Mixed Alphanumeric

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[A-Za-z0-9]{8}` | 8 mixed chars | aB3cD9eF |
| `[A-Z0-9]{6}` | 6 uppercase + digits | A1B2C3 |
| `[A-Z]{3}\d{4}` | 3 letters + 4 digits | ABC1234 |
| `\w{10}` | 10 word chars | aB3_cD9eF_ |

## Identifiers

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `AIza[0-9A-Za-z_-]{35}` | Google API key style | AIzaSyB1c2D3e4F5g6H7i8J9k0L1m2N3o4P5 |
| `[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}` | UUID v4 | 550e8400-e29b-41d4-a716-446655440000 |
| `[0-9a-f]{7}` | Git short hash | a1b2c3d |
| `[A-Z]{3}\d{10}` | Database ID | ABC1234567890 |
| `[A-Za-z0-9]{32}` | Session token | aB3cD9eFgH1iJ2kL3mN4oP5qR6sT7uV8 |

## Contact Information

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d{3}-\d{3}-\d{4}` | US Phone | 555-123-4567 |
| `\+1-\d{3}-\d{3}-\d{4}` | US Phone (intl) | +1-555-123-4567 |
| `\(\d{3}\) \d{3}-\d{4}` | US Phone (formatted) | (555) 123-4567 |
| `[a-z]{5,10}@[a-z]{5,10}\.com` | Simple email | hello@world.com |
| `[a-z]{5,10}@(gmail\|yahoo\|hotmail)\.com` | Email with domains | user@gmail.com |
| `\d{5}` | US ZIP | 12345 |
| `[A-Z]{2} \d[A-Z] \d[A-Z]\d` | Canadian postal | K1A 0B1 |

## Financial

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `4\d{15}` | Visa test card | 4123456789012345 |
| `5[1-5]\d{14}` | Mastercard test | 5412345678901234 |
| `\d{4}-\d{4}-\d{4}-\d{4}` | Card formatted | 1234-5678-9012-3456 |
| `\d{3}` | CVV | 123 |
| `\d{10,12}` | Bank account | 1234567890 |
| `TXN[A-Z0-9]{12}` | Transaction ID | TXNA1B2C3D4E5F6 |

## Passwords

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[A-Za-z0-9]{12}` | Simple 12-char | aB3cD9eFgH1i |
| `[A-Za-z0-9!@#$%^&*]{16}` | Strong 16-char | aB3!cD9@eFgH#1iJ |
| `[A-Z][a-z]{3}\d{4}` | Temp password | Pass1234 |
| `[a-z]{4,8}-[a-z]{4,8}-[a-z]{4,8}` | Passphrase | word-another-third |
| `[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}` | Recovery code | A1B2-C3D4-E5F6 |

## Codes & References

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `ORD-\d{8}` | Order number | ORD-12345678 |
| `INV-\d{4}-[A-Z]{3}` | Invoice number | INV-2024-ABC |
| `(SAVE\|DEAL\|SALE)\d{2}[A-Z]{3}` | Coupon code | SAVE10ABC |
| `[A-Z]{2}-\d{4}-[A-Z]{2}` | Product SKU | AB-1234-CD |
| `SN[A-Z0-9]{10}` | Serial number | SNA1B2C3D4E5 |
| `CONF-[A-Z0-9]{6}` | Confirmation | CONF-A1B2C3 |

## Web & URLs

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[a-z]{5,10}\.example\.com` | Subdomain | hello.example.com |
| `[A-Za-z0-9]{6}` | Short URL code | aB3cD9 |
| `[a-z]{3,8}\d{2,4}` | Username | user123 |
| `[a-z]{4,8}-[a-z]{4,8}` | URL slug | some-slug |
| `[a-z0-9]{8,16}` | Username (strict) | user1234 |

## Technical

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}` | IPv4 address | 192.168.1.1 |
| `[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}` | MAC address | 00:1A:2B:3C:4D:5E |
| `\d{1,2}\.\d{1,2}\.\d{1,3}` | Version number | 1.2.345 |
| `#[0-9A-F]{6}` | Hex color | #FF5733 |
| `[0-9a-f]{32}` | MD5 hash | 5d41402abc4b2a76b9719d911017c592 |
| `[0-9a-f]{40}` | SHA-1 hash | 356a192b7913b04c54574d18c28d46e6395428ab |

## Dates & Times

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `20\d{2}-(0[1-9]\|1[0-2])-(0[1-9]\|[12]\d\|3[01])` | Date YYYY-MM-DD | 2024-03-15 |
| `(0[1-9]\|1[0-2])/([0-2]\d\|3[01])/\d{4}` | Date MM/DD/YYYY | 03/15/2024 |
| `([01]\d\|2[0-3]):[0-5]\d` | Time HH:MM | 14:30 |
| `([01]\d\|2[0-3]):[0-5]\d:[0-5]\d` | Time HH:MM:SS | 14:30:45 |
| `(Mon\|Tue\|Wed\|Thu\|Fri\|Sat\|Sun)` | Day abbreviation | Mon |

## Vehicle & Transportation

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[A-Z]{3}\d{4}` | License plate | ABC1234 |
| `[A-Z]{3} \d{3}` | License plate (alt) | ABC 123 |
| `[A-HJ-NPR-Z0-9]{17}` | VIN | 1HGBH41JXMN109186 |
| `(AA\|UA\|DL\|SW)\d{3,4}` | Flight number | AA123 |
| `1Z[A-Z0-9]{16}` | UPS tracking | 1Z999AA10123456784 |

## Healthcare

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `P\d{7}` | Patient ID | P1234567 |
| `MRN-\d{6}` | Medical record | MRN-123456 |
| `RX\d{10}` | Prescription | RX1234567890 |

## Advanced Patterns

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `(\w{4})-\1` | Repeated pattern | abcd-abcd |
| `(\d{2})-(\w{3})-\1-\2` | Multiple repeats | 12-abc-12-abc |
| `(cat\|dog\|bird)` | Alternation | cat, dog, or bird |
| `(red\|blue)-(small\|large)` | Multi-alternation | red-small |
| `((foo\|bar)\d{2}){2}` | Nested groups | foo12bar34 |
| `[A-Z](?:[a-z]{2})\d+` | Non-capturing group | Abc123 |
| `(?<n>\w{3})-\k<n>` | Named capture | abc-abc |
| `\d++[A-Z]` | Possessive quantifier | 123A |
| `\d{3}(?=[A-Z])` | Positive lookahead | 123 |
| `\w{4}(?!\d)` | Negative lookahead | abcd |
| `\p{L}{5}` | Unicode letters | Hello |
| `\p{N}{3}` | Unicode numbers | 123 |

## Unicode Properties

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\p{L}` or `\p{Letter}` | Any letter | a, A, é, ñ |
| `\p{N}` or `\p{Number}` | Any number | 1, 2, ① |
| `\p{Lu}` or `\p{Uppercase_Letter}` | Uppercase letter | A, Z, À |
| `\p{Ll}` or `\p{Lowercase_Letter}` | Lowercase letter | a, z, ñ |
| `\p{P}` or `\p{Punctuation}` | Punctuation | . , ! ? |
| `\p{S}` or `\p{Symbol}` | Symbol | $ € © ® |
| `\p{Z}` or `\p{Separator}` | Separator | space, tab |
| `\p{Nd}` or `\p{Decimal_Number}` | Decimal digit | 0-9 |

## Named Captures

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `(?<year>\d{4})` | Named capture group | 2024 |
| `(?<n>\w{3})-\k<n>` | Named backreference | abc-abc |
| `(?<a>\d{2})(?<b>\w{3})\k<a>` | Multiple named | 12abc12 |
| `(?<prefix>[A-Z]{2})-(?<id>\d{4})` | Multiple captures | AB-1234 |

## Possessive Quantifiers

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d++` | Possessive one or more | 123 |
| `\w*+[A-Z]` | Possessive zero or more | abcD |
| `[a-z]?+\d{3}` | Possessive optional | a123 or 123 |
| `\d{2,5}+` | Possessive range | 12345 |

## Lookaheads and Lookbehinds

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d{3}(?=[A-Z])` | Positive lookahead | 123 (if followed by uppercase) |
| `\w{4}(?!\d)` | Negative lookahead | abcd (if not followed by digit) |
| `(?<=PRE)\d{3}` | Positive lookbehind | 123 (if preceded by PRE) |
| `(?<!XX)\w{4}` | Negative lookbehind | abcd (if not preceded by XX) |

---

## Tips for Creating Patterns

### Character Classes

- `[abc]` - any of a, b, or c
- `[^abc]` - anything except a, b, or c
- `[a-z]` - any lowercase letter
- `[A-Z]` - any uppercase letter
- `[0-9]` or `\d` - any digit
- `[A-Za-z]` - any letter
- `[A-Za-z0-9]` or `\w` - any alphanumeric or underscore

### Quantifiers

- `{n}` - exactly n times
- `{n,m}` - between n and m times
- `{n,}` - n or more times
- `+` - one or more times
- `*` - zero or more times
- `?` - zero or one time

### Special Sequences

- `\d` - digit (0-9)
- `\D` - non-digit
- `\w` - word character (A-Za-z0-9_)
- `\W` - non-word character
- `\s` - whitespace
- `\t` - tab
- `\n` - newline
- `.` - any character

### Groups

- `(...)` - capturing group (can be referenced with \1, \2, etc.)
- `(?:...)` - non-capturing group
- `(a|b|c)` - alternation (matches a, b, or c)

### Anchors

- `^` - start of string (stripped by generator)
- `# Quick Pattern Reference

A handy reference for common regex patterns to use with Data::Random::String::Matches.

## Table of Contents

- [Numbers](#numbers)
- [Letters](#letters)
- [Mixed Alphanumeric](#mixed-alphanumeric)
- [Identifiers](#identifiers)
- [Contact Information](#contact-information)
- [Financial](#financial)
- [Passwords](#passwords)
- [Codes & References](#codes--references)
- [Web & URLs](#web--urls)
- [Technical](#technical)
- [Dates & Times](#dates--times)

---

## Numbers

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d{4}` | 4-digit number | 1234 |
| `\d{6}` | 6-digit number | 123456 |
| `[1-9]\d{3}` | 4-digit, no leading zero | 5432 |
| `\d{3}-\d{3}-\d{4}` | Phone format | 555-123-4567 |
| `\d{5}` | ZIP code | 12345 |
| `\d{5}-\d{4}` | ZIP+4 | 12345-6789 |

## Letters

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[A-Z]{3}` | 3 uppercase letters | ABC |
| `[a-z]{5}` | 5 lowercase letters | hello |
| `[A-Z][a-z]{4}` | Title case word | Hello |
| `[a-z]{3,8}` | 3-8 lowercase letters | word |

## Mixed Alphanumeric

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[A-Za-z0-9]{8}` | 8 mixed chars | aB3cD9eF |
| `[A-Z0-9]{6}` | 6 uppercase + digits | A1B2C3 |
| `[A-Z]{3}\d{4}` | 3 letters + 4 digits | ABC1234 |
| `\w{10}` | 10 word chars | aB3_cD9eF_ |

## Identifiers

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `AIza[0-9A-Za-z_-]{35}` | Google API key style | AIzaSyB1c2D3e4F5g6H7i8J9k0L1m2N3o4P5 |
| `[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}` | UUID v4 | 550e8400-e29b-41d4-a716-446655440000 |
| `[0-9a-f]{7}` | Git short hash | a1b2c3d |
| `[A-Z]{3}\d{10}` | Database ID | ABC1234567890 |
| `[A-Za-z0-9]{32}` | Session token | aB3cD9eFgH1iJ2kL3mN4oP5qR6sT7uV8 |

## Contact Information

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d{3}-\d{3}-\d{4}` | US Phone | 555-123-4567 |
| `\+1-\d{3}-\d{3}-\d{4}` | US Phone (intl) | +1-555-123-4567 |
| `\(\d{3}\) \d{3}-\d{4}` | US Phone (formatted) | (555) 123-4567 |
| `[a-z]{5,10}@[a-z]{5,10}\.com` | Simple email | hello@world.com |
| `[a-z]{5,10}@(gmail\|yahoo\|hotmail)\.com` | Email with domains | user@gmail.com |
| `\d{5}` | US ZIP | 12345 |
| `[A-Z]{2} \d[A-Z] \d[A-Z]\d` | Canadian postal | K1A 0B1 |

## Financial

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `4\d{15}` | Visa test card | 4123456789012345 |
| `5[1-5]\d{14}` | Mastercard test | 5412345678901234 |
| `\d{4}-\d{4}-\d{4}-\d{4}` | Card formatted | 1234-5678-9012-3456 |
| `\d{3}` | CVV | 123 |
| `\d{10,12}` | Bank account | 1234567890 |
| `TXN[A-Z0-9]{12}` | Transaction ID | TXNA1B2C3D4E5F6 |

## Passwords

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[A-Za-z0-9]{12}` | Simple 12-char | aB3cD9eFgH1i |
| `[A-Za-z0-9!@#$%^&*]{16}` | Strong 16-char | aB3!cD9@eFgH#1iJ |
| `[A-Z][a-z]{3}\d{4}` | Temp password | Pass1234 |
| `[a-z]{4,8}-[a-z]{4,8}-[a-z]{4,8}` | Passphrase | word-another-third |
| `[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}` | Recovery code | A1B2-C3D4-E5F6 |

## Codes & References

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `ORD-\d{8}` | Order number | ORD-12345678 |
| `INV-\d{4}-[A-Z]{3}` | Invoice number | INV-2024-ABC |
| `(SAVE\|DEAL\|SALE)\d{2}[A-Z]{3}` | Coupon code | SAVE10ABC |
| `[A-Z]{2}-\d{4}-[A-Z]{2}` | Product SKU | AB-1234-CD |
| `SN[A-Z0-9]{10}` | Serial number | SNA1B2C3D4E5 |
| `CONF-[A-Z0-9]{6}` | Confirmation | CONF-A1B2C3 |

## Web & URLs

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `[a-z]{5,10}\.example\.com` | Subdomain | hello.example.com |
| `[A-Za-z0-9]{6}` | Short URL code | aB3cD9 |
| `[a-z]{3,8}\d{2,4}` | Username | user123 |
| `[a-z]{4,8}-[a-z]{4,8}` | URL slug | some-slug |
| `[a-z0-9]{8,16}` | Username (strict) | user1234 |

## Technical

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}` | IPv4 address | 192.168.1.1 |
| `[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}` | MAC address | 00:1A:2B:3C:4D:5E |
| `\d{1,2}\.\d{1,2}\.\d{1,3}` | Version number | 1.2.345 |
| `#[0-9A-F]{6}` | Hex color | #FF5733 |
| `[0-9a-f]{32}` | MD5 hash | 5d41402abc4b2a76b9719d911017c592 |
| `[0-9a-f]{40}` | SHA-1 hash | 356a192b7913b04c54574d18c28d46e6395428ab |

## Dates & Times

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `20\d{2}-(0[1-9]\|1[0-2])-(0[1-9]\|[12]\d\|3[01])` | Date YYYY-MM-DD | 2024-03-15 |
| `(0[1-9]\|1[0-2])/([0-2]\d\|3[01])/\d{4}` | Date MM/DD/YYYY | 03/15/2024 |
 - end of string (stripped by generator)

---

## Usage Examples

### In Code

```perl
use Data::Random::String::Matches;

# Simple pattern
my $gen = Data::Random::String::Matches->new(qr/\d{4}/);
my $pin = $gen->generate();

# With alternation
my $gen = Data::Random::String::Matches->new(qr/(cat|dog|bird)/);
my $animal = $gen->generate();

# With backreferences
my $gen = Data::Random::String::Matches->new(qr/(\w{3})-\1/);
my $code = $gen->generate();  # e.g., "abc-abc"
```

### Command Line

```bash
# Generate a 4-digit PIN
random-string '\d{4}'

# Generate 10 email addresses
random-string '[a-z]{5,10}@[a-z]{5,10}\.com' --count 10

# Generate API keys
random-string 'AIza[0-9A-Za-z_-]{35}' -c 5

# Generate with custom separator
random-string '[A-Z]{3}' -c 5 -S ', '
```

---

## Common Pattern Recipes

### For Testing

```perl
# Test credit cards
my $visa = qr/4\d{15}/;
my $mastercard = qr/5[1-5]\d{14}/;
my $amex = qr/3[47]\d{13}/;

# Test emails
my $email = qr/[a-z]{5,10}@(test|example)\.com/;

# Test phone numbers
my $phone = qr/\d{3}-\d{3}-\d{4}/;
```

### For Security

```perl
# Strong passwords
my $password = qr/[A-Za-z0-9!@#$%^&*]{16}/;

# API keys
my $api_key = qr/[A-Za-z0-9]{32}/;

# One-time codes
my $otp = qr/\d{6}/;
```

### For Identifiers

```perl
# Order numbers
my $order = qr/ORD-\d{8}/;

# User IDs
my $user_id = qr/USR[A-Z0-9]{8}/;

# Session tokens
my $session = qr/[A-Za-z0-9]{40}/;
```

---

## Pattern Building Worksheet

Use this template to build your own patterns:

1. **What format do you need?**
   - Only letters? `[A-Za-z]`
   - Only numbers? `\d`
   - Mixed? `[A-Za-z0-9]`
   - Special chars? `[A-Za-z0-9!@#$]`

2. **How long?**
   - Exact length: `{n}`
   - Range: `{n,m}`
   - At least: `{n,}`
   - Variable: `+` or `*`

3. **Any fixed parts?**
   - Prefix: `PREFIX[A-Z0-9]{6}`
   - Suffix: `[A-Z0-9]{6}SUFFIX`
   - Separators: `[A-Z]{3}-\d{4}`

4. **Any choices?**
   - Use alternation: `(option1|option2|option3)`

5. **Any repetition?**
   - Use backreferences: `(\w{4})-\1`

### Example Building Process

**Goal:** Generate order numbers like "ORD-2024-ABC123"

1. Start with prefix: `ORD-`
2. Add year: `ORD-20\d{2}-`
3. Add letters: `ORD-20\d{2}-[A-Z]{3}`
4. Add numbers: `ORD-20\d{2}-[A-Z]{3}\d{3}`

**Final pattern:** `qr/ORD-20\d{2}-[A-Z]{3}\d{3}/`

---

## See Also

- [Cookbook](cookbook.pl) - Working examples
- [Module Documentation](../lib/Data/Random/String/Matches.pm)
- [README](../README.md)

## Quick Links

- **GitHub Issues:** Report bugs or request features
- **Tests:** See `t/` directory for more examples
- **CLI Help:** `random-string --help`
- **CLI Examples:** `random-string --examples`