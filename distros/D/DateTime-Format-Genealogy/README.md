# NAME

DateTime::Format::Genealogy - Create a DateTime object from a genealogy date string

# VERSION

Version 0.13

# SYNOPSIS

`DateTime::Format::Genealogy` is a Perl module designed to parse genealogy-style
date strings (primarily GEDCOM format) and convert them into [DateTime](https://metacpan.org/pod/DateTime) objects.
It wraps [Genealogy::Gedcom::Date](https://metacpan.org/pod/Genealogy%3A%3AGedcom%3A%3ADate) and [DateTime::Format::Natural](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ANatural), adds GEDCOM
calendar-escape handling, and accepts common non-standard month names found in
exported genealogical trees.

    use DateTime::Format::Genealogy;
    my $dtg = DateTime::Format::Genealogy->new();
    my $dt  = $dtg->parse_datetime('25 Dec 2022');
    print $dt->dmy;  # 25-12-2022

# SUBROUTINES/METHODS

## new

Creates or clones a `DateTime::Format::Genealogy` object.

### EXAMPLE

    # Bare construction
    my $dtg = DateTime::Format::Genealogy->new();

    # Construction with flags stored on the object
    my $dtg_quiet = DateTime::Format::Genealogy->new(quiet => 1, strict => 1);

    # Clone with an override (inherits quiet => 1, overrides strict)
    my $clone = $dtg_quiet->new(strict => 0);

### API SPECIFICATION

    # Input (hash or hashref, all keys optional):
    {
        quiet  => $bool,  # suppress carp in internal helpers
        strict => $bool,  # enforce 3-letter GEDCOM month abbreviations
        # Any extra keys from Object::Configure are also accepted.
    }

    # Output: blessed DateTime::Format::Genealogy object

### MESSAGES

This method does not emit any diagnostics directly.

### PSEUDOCODE

    FUNCTION new(class, *args):
      params = get_params(undef, args)
      IF class is not defined:
        class = __PACKAGE__
      ELSE IF class is already an object (blessed):
        RETURN bless( merge(class.attrs, params), ref(class) )
      params = configure(class, params)   # merge any config-file settings
      RETURN bless(params, class)
    END FUNCTION

## parse\_datetime

Parses a genealogy-style date string and returns a [DateTime](https://metacpan.org/pod/DateTime) object.

Recognises GEDCOM calendar escapes (`@#DJULIAN@`, `@#DHEBREW@`,
`@#DFRENCH R@`) and converts them via the appropriate calendar module when
available.

Can be called as a class method, an object method, or a bare function.

Returns:

- A single [DateTime](https://metacpan.org/pod/DateTime) object for exact, parseable dates.
- A two-element list of [DateTime](https://metacpan.org/pod/DateTime) objects in _list_ context when the date
string is a range (`bet X and Y` / `from X to Y`).
- `undef` (scalar) or the empty list (list context) when the date cannot be
parsed, is a year-only string, is prefixed with an approximation keyword
(`bef`, `aft`, `abt`), or represents a date before AD 100.

Mandatory argument:

- `date`

    The date string to parse.

Optional arguments (may be set at construction time and/or overridden
per-call; per-call values take precedence):

- `quiet`

    Suppress [Carp](https://metacpan.org/pod/Carp) warnings on unparseable or approximate dates.

- `strict`

    Enforce the GEDCOM standard: only 3-letter month abbreviations (`Jan`,
    `Feb`, ...) are accepted.  Long English names and French/German variants
    are rejected.

### EXAMPLE

    my $dtg = DateTime::Format::Genealogy->new();

    # Simple exact date
    my $dt = $dtg->parse_datetime('25 Dec 2022');
    print $dt->dmy;  # 25-12-2022

    # Date range (list context)
    my ($start, $end) = $dtg->parse_datetime('bet 1 Sep 1939 and 2 Sep 1945');

    # GEDCOM calendar escape
    my $julian = $dtg->parse_datetime('@#DJULIAN@ 15 Mar 1620');

    # Class-method form (no constructor required)
    my $dt2 = DateTime::Format::Genealogy->parse_datetime('1 Jan 2000');

    # Long month name (non-strict only)
    my $dt3 = $dtg->parse_datetime('12 June 2020');

    # French month variant (non-strict only)
    my $dt4 = $dtg->parse_datetime('21 Mai 1681');

### API SPECIFICATION

    # Input (hash or hashref):
    {
        date   => $string,         # required (non-ref, non-empty)
        quiet  => $bool,           # optional; falls back to $self->{'quiet'}
        strict => $bool,           # optional; falls back to $self->{'strict'}
    }

    # Return values:
    #   DateTime                   exact parseable date
    #   (DateTime, DateTime)       date range (list context only)
    #   undef / ()                 unparseable, approximate, or year-only

### MESSAGES

- `Usage: DateTime::Format::Genealogy::parse_datetime(date => $date)`

    Thrown (croak) when no arguments are supplied or when the `date` value is
    undef or a reference.

- `Invalid parse_datetime parameters: ...`

    Thrown (croak) when an unknown parameter key is passed (e.g. a typo).

- `$date is invalid, need an exact date to create a DateTime`

    Warned (carp) when the date begins with an approximation prefix (`bef`,
    `aft`, `abt`).  Silenced by `quiet`.

- `$date is invalid, there are only 30 days in November`

    Warned (carp) for the impossible date `31 Nov`.  Always emitted; not
    silenced by `quiet`.

- `Changing date '$original' to '$new'`

    Warned (carp) when a date is automatically rewritten (ISO dash format or
    dash-separated range).  Silenced by `quiet`.

- `Unparseable date $date - often because the month name isn't 3 letters`

    Warned (carp) in strict mode for non-3-letter months, or in non-strict mode
    for unrecognised long month names.  Silenced by `quiet`.

- `$dfn_error_string`

    Warned (carp) when [DateTime::Format::Natural](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ANatural) rejects the date string.
    Silenced by `quiet`.

- `Hebrew calendar conversion failed: ...`

    Warned (carp) when [DateTime::Calendar::Hebrew](https://metacpan.org/pod/DateTime%3A%3ACalendar%3A%3AHebrew) is unavailable or throws.
    Silenced by `quiet`.

- `French Republican calendar conversion failed: ...`

    Warned (carp) when [DateTime::Calendar::FrenchRevolutionary](https://metacpan.org/pod/DateTime%3A%3ACalendar%3A%3AFrenchRevolutionary) is unavailable
    or throws.  Silenced by `quiet`.

- `Calendar type $type not supported`

    Warned (carp) for GEDCOM calendar escapes other than GREGORIAN, JULIAN,
    HEBREW, and FRENCH R.  Silenced by `quiet`.

### PSEUDOCODE

    FUNCTION parse_datetime(self, *args):
      -- Dispatch class/function/hash-invocant calls to an object instance
      IF self is not a reference:
        RETURN new()->parse_datetime(args or self)
      IF ref(self) == 'HASH':
        RETURN new()->parse_datetime(self)

      ABORT unless args non-empty
      params = get_params('date', args)
      ABORT on unknown keys (validate_strict)

      date   = params.date
      quiet  = params.quiet  // self.quiet
      strict = params.strict // self.strict

      ABORT unless date is defined, non-empty, and not a reference

      -- Strip GEDCOM calendar escape if present
      IF date =~ s/^@#D([A-Z ]+?)@\s*//: calendar_type = 'D' + uc(match)

      -- Reject approximate/relative dates
      IF date =~ /^(bef|aft|abt)\s/i: CARP and RETURN undef

      -- Reject calendar impossibilities
      IF date =~ /^31\s+Nov/: CARP and RETURN undef

      -- Rewrite dash-separated ranges and ISO dates
      IF date =~ /X - Y/:
        IF date =~ /YYYY-MM-DD/: REFORMAT to "DD Mon YYYY" (carp)
        ELSE: REFORMAT to "bet X and Y" (carp)

      -- Dispatch ranges to recursive calls
      IF date =~ /^bet X and Y/i:
        RETURN (parse_datetime(X), parse_datetime(Y)) IF wantarray
        RETURN undef

      IF !strict AND date =~ /^from X to Y/i:
        RETURN (parse_datetime(X), parse_datetime(Y)) IF wantarray
        RETURN undef

      -- Normalise non-standard month names (non-strict mode only)
      IF !strict:
        IF date =~ DD + Aout + YYYY (French non-ASCII August):
          REWRITE month to 'Aug'
        ELSE IF date =~ /DD LONG_OR_VARIANT YYYY/:
          lookup = MONTH_ALIAS{ucfirst(lc(month))}
          IF lookup: REWRITE month to lookup
          ELSE IF month is more than 3 letters: CARP and RETURN undef
          -- 3-letter unknown months fall through unchanged to the parser

      -- Parse with Genealogy::Gedcom::Date (cached) then DateTime::Format::Natural
      IF date starts with digit:
        d = _date_parser_cached(date)
        IF d defined:
          RETURN undef if date ends with year-only (< AD100 guard)
          rc = DateTime::Format::Natural->parse_datetime(d.canonical)
          IF calendar_type != DGREGORIAN:
            rc = _convert_calendar(rc, calendar_type, quiet)
          RETURN rc

      -- Fallback: try DateTime::Format::Natural directly on the raw string
      IF date not ~= /^(Abt|ca?)/i AND date =~ /^[\w\s,]+$/:
        rc = DateTime::Format::Natural->parse_datetime(date)
        IF rc AND success: RETURN rc
        ELSE: CARP error

      RETURN undef
    END FUNCTION

# LIMITATIONS

- Dates before AD 100 are rejected because [DateTime::Format::Natural](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ANatural) cannot
parse them reliably (it returns today's date instead of an error).
- The `Aout` (French August with circumflex-u) entry in the month-alias table
uses a non-ASCII Unicode escape (`\x{FB}`).  The module file must be read as
UTF-8; this is satisfied by the standard `perl -Ilib` invocation but may
require `use utf8` or `open ':encoding(UTF-8)'` in unusual environments.
- Hebrew and French Republican calendar conversions require
[DateTime::Calendar::Hebrew](https://metacpan.org/pod/DateTime%3A%3ACalendar%3A%3AHebrew) and [DateTime::Calendar::FrenchRevolutionary](https://metacpan.org/pod/DateTime%3A%3ACalendar%3A%3AFrenchRevolutionary)
respectively.  These are optional and not listed as hard dependencies.  When
absent, the GEDCOM escape is silently discarded and undef is returned unless
the `quiet` flag is off, in which case a carp is emitted.
- [Genealogy::Gedcom::Date](https://metacpan.org/pod/Genealogy%3A%3AGedcom%3A%3ADate) cannot parse native Hebrew or French Revolutionary
month names (e.g. `Tishri`, `Vendemiaire`).  Only dates written in
Gregorian form with the `@#DHEBREW@` escape are converted.
- The `quiet` and `strict` flags may be set at construction time
(`->new(quiet => 1)`) and will be respected by all subsequent calls to
`parse_datetime` unless overridden on a per-call basis.  The per-call value
always takes precedence.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report any bugs or feature requests to the author.
This module is provided as-is without any warranty.

# SEE ALSO

- [Genealogy::Gedcom::Date](https://metacpan.org/pod/Genealogy%3A%3AGedcom%3A%3ADate)
- [DateTime](https://metacpan.org/pod/DateTime)
- [DateTime::Format::Natural](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ANatural)
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/DateTime-Format-Genealogy/coverage/)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Genealogy

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Genealogy](http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-Genealogy)

- GitHub Issues

    [https://github.com/nigelhorne/DateTime-Format-Genealogy/issues](https://github.com/nigelhorne/DateTime-Format-Genealogy/issues)

# FORMAL SPECIFICATION

## new

    State S ::= [ attrs : Name -> Value ]

    new(class, params) = bless(params U configure(class))   when !blessed(class)
    new(obj,   params) = bless(obj.attrs (+) params)         when  blessed(obj)

    where (+) denotes right-biased union (params values take precedence).

## parse\_datetime

Let D be the set of genealogical date strings and DT the co-domain of
[DateTime](https://metacpan.org/pod/DateTime) objects.

    parse_datetime : D -> DT | bot | (DT x DT)

    YearOnly ::= { s in D | s ~ /^\d{3,4}$/ }
    Approx   ::= { s in D | s ~ /^(bef|aft|abt)\s/i }
    Ranges   ::= { s in D | s ~ /^bet\s.+\sand\s.+/i
                           | s ~ /^from\s.+\sto\s.+/i }

    Pre:  date != bot

    Post:
      date in YearOnly              => result = bot
      date in Approx                => result = bot  (carp unless quiet)
      date in Ranges /\ wantarray   => result in DT x DT
      date in Ranges /\ !wantarray  => result = bot
      date in Parseable \
        (YearOnly u Approx u Ranges) => result in DT
      date not in Parseable         => result = bot  (carp unless quiet)

# LICENSE AND COPYRIGHT

Copyright 2018-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
