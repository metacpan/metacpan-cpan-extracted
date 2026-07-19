# NAME

Date::Cmp - Compare two dates with approximate parsing support

# VERSION

Version 0.06

# SYNOPSIS

    use Date::Cmp qw(datecmp);

    my $cmp = datecmp('1914', '1918');            # -1 (1914 is earlier)
    my $cmp = datecmp('Abt. 1850', '1855');       # -1
    my $cmp = datecmp('BET 1830 AND 1832', '1831'); # 0 (within range)

    # Optional complaint callback for ambiguous range edge-cases:
    $cmp = datecmp('1996-2000', '1996',
        sub { warn "ambiguous: @_" });

# DESCRIPTION

`Date::Cmp` provides a single exported function, `datecmp`, which compares
two date strings or date-like objects, returning a numeric result like Perl's
`<=>` operator.

The comparison handles approximate dates (`Abt. 1902`, `BET 1830 AND 1832`,
`Oct/Nov/Dec 1950`), partial dates (year-only), and the common genealogy
qualifiers `BEF` and `AFT`.  Exact parsing delegates to
[DateTime::Format::Genealogy](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AGenealogy); a cascade of fast-path heuristics handles
the most common year-only comparisons without invoking the heavier parser.

# FUNCTIONS

## datecmp

### Purpose

Compare two genealogy-style date strings (or date-like objects) and return
a value equivalent to Perl's spaceship operator (`<=>`): `-1` if the
left operand is earlier, `0` if equivalent, or `1` if later.

### Arguments

- `$left` (required)

    The left-hand date.  Accepted types:

    - A string in any format listed under ["SUPPORTED FORMATS"](#supported-formats).
    - A blessed object with a `date()` method returning a date string.
    - A hash reference with a `date` key whose value is a date string.

- `$right` (required)

    The right-hand date.  Accepts the same types as `$left`.

- `$complain` (optional)

    A CODE reference invoked with a diagnostic string for ambiguous conditions:
    equal range endpoints or an inverted range.  `undef` and other falsy values
    are silently ignored (the guard is never triggered).  A truthy non-CODE
    value causes an immediate `croak`.

### Returns

- `-1` — `$left` is earlier than `$right`
- `0`  — the two dates are considered equivalent
- `1`  — `$left` is later than `$right`

When either argument is `undef` (or resolves to `undef` after unwrapping),
the function prints a diagnostic to STDERR and returns `0` rather than dying.
On a fatal parse failure it dies; the exception string begins with
`"Date parse failure: "`.

### Side Effects

May print coloured diagnostics to STDERR when dates cannot be parsed, when a
range is inverted, or when an argument is undefined.  The `$complain`
callback is invoked (instead of STDERR output) for selected ambiguous
conditions.

### EXAMPLE

    use Date::Cmp qw(datecmp);

    # Plain years
    datecmp('1900', '1950');              # -1

    # Approximate prefixes are stripped
    datecmp('Abt. 1850', '1850');        # 0
    datecmp('ca. 1799',  '1800');        # -1

    # Year ranges — any year within the range is "equal"
    datecmp('1 Jan 1831', '1830-1832');  # 0
    datecmp('BET 1830 AND 1832', '1829'); # 1  (range is later)

    # Blessed object with date() method
    package MyDate;
    sub new  { bless { d => $_[1] }, $_[0] }
    sub date { $_[0]->{d} }
    package main;
    datecmp(MyDate->new('1900'), '1950'); # -1

    # Hash ref with 'date' key
    datecmp({ date => '1900' }, '1950'); # -1

    # Sort a list of dates
    my @sorted = sort { datecmp($a, $b) } qw(1832 Abt. 1800 1756 BET 1815 AND 1820);

### API SPECIFICATION

#### Input

    $left    : Str | Object(date) | HashRef(date => Str)   # required
    $right   : Str | Object(date) | HashRef(date => Str)   # required
    $complain: CodeRef | undef | false                      # optional

Valid string formats (see ["SUPPORTED FORMATS"](#supported-formats)):

    exact    => qr/^\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2})?$/
    slash    => qr{^\d+/\d+/\d{4}$}
    year     => qr/^\d{3,4}$/
    approx   => qr/^(?:Abt\.?|ca?\.?)\s+.+/i  |  qr/.+\s?\?$/
    range    => qr/^\d{3,4}-\d{3,4}$/  |  qr/^BET \d+ AND \d+$/i
    month_rng=> qr/^[a-z\/]+\s+\d{3,4}$/i
    before   => qr/^bef\b/i
    after    => qr/^aft\b/i

#### Output

    Int: -1 | 0 | 1

    Or croaks("Date parse failure: ...") when a date cannot be parsed.
    Returns 0 (after STDERR output) when either argument is undef.

### MESSAGES

The following diagnostics may be emitted.  **\[STDERR\]** entries print a
message and stack trace then return 0.  **\[croak\]** entries die (catchable
with `eval {}`).

- **\[STDERR\]** "left not defined" / "right not defined"

    `$left` or `$right` was `undef` on entry.

- **\[STDERR\]** "left date is undefined after input normalisation" / "right ..."

    A hashref was passed with no `date` key, or `date => undef`.

- **\[croak\]** "Third argument to datecmp() must be a CODE reference"

    `$complain` was truthy but not a `CODE` reference (e.g. a string or
    array-ref).

- **\[croak\]** "Date parse failure: left is an unsupported reference type (...)"

    `$left` was a reference that could not be unwrapped (not a blessed
    `date()`-capable object and not a hash).

- **\[croak\]** "Date parse failure: right is an unsupported reference type (...)"

    Same for `$right`.

- **\[croak\]** "Date parse failure: left contains characters not permitted in a date string"

    `$left` contained a character outside the allowed set
    `[A-Za-z0-9 .,/-?:]`.  The string is rejected before any parsing.

- **\[croak\]** "Date parse failure: right contains characters not permitted in a date string"

    Same for `$right`.

- **\[croak\]** "Date parse failure: left = ... (year must be 3-4 digits)"

    `$left` was a bare integer with 5 or more digits.

- **\[croak\]** "Date parse failure: right = ... (year must be 3-4 digits)"

    Same for `$right`.

- **\[croak\]** "Date parse failure: left = ..."

    `$left` failed the first-character semantic check or could not be parsed
    by DFG.

- **\[croak\]** "Date parse failure: right = ..."

    `$right` could not be parsed by DFG (and no year suffix was extractable).

- **\[STDERR\]** "... <=> ...: not handled yet"

    A `BEF`/`AFT` qualifier on the left with a right-hand value that does not
    fit any handled pattern.  Returns 0.

- **\[STDERR\]** "... <=> ...: Before not handled"

    A `BEF` qualifier on the right with a left-hand value that is not a plain
    integer.  Returns 0.

- **\[STDERR\]** "datecmp(): N > M in daterange ..."

    The right-hand year range was inverted (`from > to`).  Returns 0.

### PSEUDOCODE

    1.  Validate $complain: croak if truthy but not a CODE reference.
    2.  Guard undef: if either input is undef → STDERR + stack trace + return 0.
    3.  Normalise: blessed date()-objects → call date(); hash refs → 'date' key.
    4.  Guard post-normalise undef → STDERR + stack trace + return 0.
    5.  Reject surviving reference types (croak).
    6.  Identity short-circuit: return 0 if left eq right (no parsing needed).
    7.  Taint-scrub: validate all characters against $DATE_CHARS;
        also produces untainted copies safe for use under perl -T.
    8.  First-char semantic check: first char must be [A-S0-9] (croak if not).
    9.  Reject 5+ digit bare integers (croak).
    10. Fast path 1: 4-digit year in both non-range strings → return if differ.
    11. Fast path 2: trailing 3-4 digit year in both → return if differ.
    12. Normalise LEFT (if string):
        a.  Strip trailing ISO T-timestamp.
        b.  Fast path 3: trailing 4-digit years in both → return if differ.
        c.  BEF/AFT on left: numeric-right or BEF-with-4-digit-right handled;
            otherwise STDERR + stack trace + return 0.
        d.  Strip approximate prefix (Abt./ca.) or suffix (?) or month-range.
        e.  Fast path 4: digit-starting years on both sides → return if differ.
        f.  Fast path 5: left year vs right starting with lowercase "bet".
        g.  "YEAR or YEAR" form: use first year; fire $complain if both equal.
        h.  Dash / BET range on left: compare $right against [from, to].
        i.  Complex date string: parse via DFG (croak if DFG returns nothing).
    13. Normalise RIGHT (if string):
        a.  BEF on right: numeric left → compare; otherwise STDERR + return 0.
        b.  Strip approximate prefix/suffix/month-range.
        c.  Bare 3-4 digit year: compare directly with left (unwrap if ref).
        d.  Dash / BET range on right: compare $left against [from, to].
        e.  Fast path 6: matching year in both → return if differ.
        f.  Parse right via DFG (croak if DFG returns nothing).
    14. Final comparison: unwrap any remaining DateTime objects via ->year(); <=>.

# SUPPORTED FORMATS

- Exact dates: `1941-08-02`, `5/27/1872`
- Years only: `1828`, `822`
- Approximate dates: `Abt. 1802`, `ca. 1802`, `1802 ?`
- Date ranges: `1802-1803`, `BET 1830 AND 1832`
- Month ranges: `Oct/Nov/Dec 1950`
- Qualifiers: `BEF 1940`, `AFT 1855`

# ERROR HANDLING

When a date cannot be parsed, diagnostic messages are printed to STDERR and
the function either returns 0 (for recoverable conditions such as undef
input) or `croak`s with a string beginning `"Date parse failure: "`.
All `croak` exceptions are catchable via `eval {}`.

# LIMITATIONS

- **Month-only dates**

    Dates where only the month is known (no year) are not supported.

- **Incomplete BEF/AFT handling**

    Many `BEF`/`AFT` combinations—especially `AFT` on the left or `BEF`
    against a non-integer right—are not implemented and fall back to returning
    0 with a STDERR diagnostic.

- **Dead fast-path code**

    Certain fast-path branches and a redundant `ref($right)` guard inside the
    left-side range handler are unreachable at runtime (documented in
    `t/extended_tests.t` subtest 10).

- **Public singleton**

    `$Date::Cmp::dfg` is a package variable.  Concurrent threads replacing it
    with different mocks are not safe.

- **No Sub::Private enforcement**

    The `_sanitize_for_diag` and `_emit_stack_trace` private helpers rely on
    naming convention only.  Runtime enforcement via `Sub::Private` is not yet
    declared as a dependency.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Date-Cmp/coverage/)
- [Sort::Key::DateTime](https://metacpan.org/pod/Sort%3A%3AKey%3A%3ADateTime)

# SUPPORT

This module is provided as-is without any warranty.

Please report bugs to `bug-date-cmp at rt.cpan.org` or via
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Cmp](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Cmp).

    perldoc Date::Cmp

# FORMAL SPECIFICATION

## datecmp

    [DATESTR, DIAGMSG]

    DATE ::= exact⟨year: ℕ⟩
           | approx⟨year: ℕ⟩
           | before⟨year: ℕ⟩
           | after⟨year: ℕ⟩
           | range⟨from: ℕ; to: ℕ⟩
           | invalid

    COMPARISON ::= lt | eq | gt | error

    DateCmp
    left?, right?: DATESTR
    diagnostic!: ℙ DIAGMSG
    result!: COMPARISON

    ∀d: DATESTR @ validDate(d)

    ≙
    ∃ l, r: DATE •
        l = parse(left?) ∧ r = parse(right?) ∧
        (
          (l = invalid ∨ r = invalid ⇒ result! = error) ∧
          (l = r ⇒ result! = eq) ∧
          (compare(l, r, diagnostic!) = -1 ⇒ result! = lt) ∧
          (compare(l, r, diagnostic!) = 0  ⇒ result! = eq) ∧
          (compare(l, r, diagnostic!) = 1  ⇒ result! = gt)
        )

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
