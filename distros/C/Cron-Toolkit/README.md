# NAME

Cron::Toolkit - Cron parser, describer, and scheduler with full Quartz support

# SYNOPSIS

    use Cron::Toolkit;
    use Time::Moment; # For epoch examples

    # Standard constructor (auto-detects Unix/Quartz)
    my $cron = Cron::Toolkit->new(
        expression => "0 30 14 * * 1#3 ?",
        time_zone => "America/New_York" # Or utc_offset => -300
    );

    # Unix-specific constructor
    my $unix_cron = Cron::Toolkit->new_from_unix(
        expression => "30 14 * * MON" # Unix 5-field
    );

    # Quartz-specific constructor
    my $quartz_cron = Cron::Toolkit->new_from_quartz(
        expression => "0 30 14 * * MON 2025" # Quartz 6/7-field
    );

    # Crontab file or string (supports @aliases)
    my @crons = Cron::Toolkit->new_from_crontab('/etc/crontab');

    $cron->begin_epoch(Time::Moment->new(year => 2025, month => 1, day => 1)->epoch); # Bound to 2025-01-01
    $cron->end_epoch(Time::Moment->new(year => 2025, month => 12, day => 31)->epoch); # Bound to 2025-12-31

    say $cron->describe; # "at 2:30 PM on the third Sunday of every month"
    say $cron->describe(locale => 'en'); # English (stub for locales like 'fr')

    say $cron->is_match(time) ? "RUN NOW!" : "WAIT";

    say $cron->next; # Next matching epoch after begin_epoch or now (within end)
    say $cron->previous; # Previous matching epoch before now

    my $nexts = $cron->next_n(3); # Or $cron->next_occurrences(3)
    say join ", ", map { Time::Moment->from_epoch($_)->strftime('%Y-%m-%d %H:%M:%S') } @$nexts;

    # Utils
    say $cron->as_string; # "0 30 14 * * ? *"
    use JSON::MaybeXS; say decode_json($cron->to_json); # Hash of attrs
    $cron->dump_tree; # Pretty-print AST

# DESCRIPTION

Cron::Toolkit is a comprehensive Perl module for parsing, describing, and scheduling cron expressions. It evolved from a descriptive focus into a versatile toolkit for cron manipulation, featuring timezone-aware matching, bounded searches, and complete Quartz enterprise syntax support (seconds field, L/W/#, steps, ranges, lists).

Key features:

- Natural Language Descriptions: Generates readable English like "at 2:30 PM on the third Monday of every month in 2025". Extensible for locales via Composer/Visitor.
- Timezone Awareness: Supports time\_zone (e.g., "America/New\_York") or utc\_offset (-300 minutes) for local-time matching and next/previous calculations. Uses DateTime::TimeZone for DST handling.
- Bounded Searches: Optional begin\_epoch/end\_epoch limits next/previous to a time window, preventing infinite loops or off-by-one errors.
- AST Architecture: Tree-based parsing with Pattern nodes (Single, Range, Step, List, Last, Nth, NearestWeekday). Dual visitors for description (Composer + EnglishVisitor) and matching (Matcher + MatchVisitor)—easy to extend for custom patterns or locales.
- Quartz Compatibility: Full support for seconds field, L (last day), W (nearest weekday), # (nth DOW), steps/ranges/lists. Unix 5-field auto-converts to Quartz (adds seconds=0, year=\*).
- Production-Ready: 50+ tests covering edges like leap years, month lengths, DOW normalization, DST flips, and bounded clamps. Handles @aliases (@hourly, etc.) in expressions and crontabs.

# TREE ARCHITECTURE

Cron::Toolkit employs an Abstract Syntax Tree (AST) for robust expression handling:

- Parse: TreeParser constructs Pattern nodes from fields (Single for 15, Range for 1-5, Step for \*/15, List for 1,15, Last for L, Nth for 1#3, NearestWeekday for 15W).
- Describe: Composer fuses node outputs via templates, using EnglishVisitor (or locale subclass) for human-readable text.
- Match: Matcher evaluates recursively against timestamps, using MatchVisitor for field-by-field checks (context-aware for L/nth/W).

This separation enables extensibility: Subclass Visitor for new locales (e.g., FrenchVisitor) or patterns (add parse clause + visit method).

# METHODS

## new

    my $cron = Cron::Toolkit->new(
        expression => "0 30 14 * * ?",
        time_zone => "America/New_York", # Auto-calculates offset (DST-aware)
        utc_offset => -300, # Minutes from UTC (overrides time_zone if both set)
        begin_epoch => 1640995200, # Optional: Start bound (default: time)
        end_epoch => 1672531200, # Optional: End bound (default: undef/unbounded)
    );

Primary constructor. Auto-detects Unix (5 fields) or Quartz (6/7 fields). Supports @aliases (@hourly → "0 0 \* \* \* ? \*"). Normalizes to 7-field Quartz internally.

Parameters:

- expression: Required cron string or @alias.
- time\_zone: Optional TZ string (e.g., "America/New\_York"); auto-calculates utc\_offset if not set.
- utc\_offset: Optional minutes from UTC (-1080 to +1080); overrides time\_zone calc.
- begin\_epoch: Optional non-negative epoch; floors searches (default: time).
- end\_epoch: Optional non-negative epoch; caps searches (default: unbounded).

Returns: Blessed Cron::Toolkit object.

## new\_from\_unix

    my $unix_cron = Cron::Toolkit->new_from_unix(
        expression => "30 14 * * MON"
    );

Unix-specific constructor for 5-field expressions. Auto-converts to Quartz (adds seconds=0, year=\*, normalizes DOW: MON=1→2, SUN=0→1).

Parameters: Same as ["new"](#new), but expression must be 5 fields.

## new\_from\_quartz

    my $quartz_cron = Cron::Toolkit->new_from_quartz(
        expression => "0 30 14 * * MON 2025"
    );

Quartz-specific constructor for 6/7-field expressions. Validates and normalizes (adds year=\* if 6 fields, DOW names to numbers).

Parameters: Same as ["new"](#new), but expression must be 6/7 fields.

## new\_from\_crontab

    my @crons = Cron::Toolkit->new_from_crontab('/etc/crontab');  # Or string

Parses a crontab file or string into array of Cron::Toolkit objects. Skips comments (#), empty lines, invalid exprs (warns). Supports @aliases (@hourly → "0 0 \* \* \* ? \*").

Parameters:

- input: File path or multi-line string.

Returns: Array of valid objects (empty if none).

## describe

    my $english = $cron->describe;
    my $french = $cron->describe(locale => 'fr');  # Stub; falls back to English

Returns human-readable description with fused combos (e.g., "at 2:30 PM on the third Monday of every month"). Defaults to English; locale param for extensibility (warns on unsupported, e.g., 'fr'—extend via Visitor subclass).

## is\_match

    my $match = $cron->is_match($epoch_seconds); # True/false

Returns true if the timestamp matches the cron in the object's timezone (local time, DST-aware).

Parameters:

- epoch\_seconds: Non-negative Unix timestamp (UTC).

## next

    my $next_epoch = $cron->next($epoch_seconds);
    my $next_epoch = $cron->next; # Defaults to begin_epoch or time

Returns the next matching epoch after the given/current time, clamped >= begin\_epoch and <= end\_epoch (undef if none).

Parameters:

- epoch\_seconds: Optional non-negative timestamp (defaults: begin\_epoch // time, clamped to bounds).

## previous

    my $prev_epoch = $cron->previous($epoch_seconds);
    my $prev_epoch = $cron->previous; # Defaults to time

Returns the previous matching epoch before the given/current time, clamped <= end\_epoch and >= begin\_epoch (undef if none).

Parameters:

- epoch\_seconds: Optional non-negative timestamp (defaults: time, clamped to bounds).

## next\_n

    my $next_epochs = $cron->next_n($epoch_seconds, $n, $max_iter);
    my $next_epochs = $cron->next_n(undef, $n); # Defaults: time, n=1, max_iter=10000

Returns arrayref of the next $n matching epochs after the given/current time, clamped to bounds. Guards against loops with max\_iter (dies on exceed).

Parameters:

- epoch\_seconds: Optional start timestamp (defaults: time).
- n: Number of occurrences (defaults: 1).
- max\_iter: Max iterations (defaults: 10000; dies if exceeded).

Returns: Arrayref of epochs (empty if none).

## next\_occurrences

Alias for ["next\_n"](#next_n). Same parameters and return.

## begin\_epoch (GETTER/SETTER)

    say $cron->begin_epoch; # Current value
    $cron->begin_epoch(1640995200); # Set to 2022-01-01 UTC

Gets/sets the start epoch for bounded searches (non-negative integer or undef). Clamps next/previous from this time onward (defaults: time if undef).

## end\_epoch (GETTER/SETTER)

    say $cron->end_epoch; # undef or current value
    $cron->end_epoch(1672531200); # Set to 2023-01-01 UTC
    $cron->end_epoch(undef); # Unbounded

Gets/sets the end epoch for bounded searches (non-negative integer or undef). Caps next/previous at this time (defaults: unbounded if undef).

## utc\_offset (GETTER/SETTER)

    say $cron->utc_offset; # -300
    $cron->utc_offset(-480); # Switch to PST

Gets/sets UTC offset in minutes (-1080 to +1080). Validates input; overrides time\_zone calc.

## time\_zone (GETTER/SETTER)

    say $cron->time_zone; # "America/New_York"
    $cron->time_zone("Europe/London"); # Recalcs utc_offset (DST-aware)

Gets/sets time zone string (e.g., "America/New\_York"). Validates via DateTime::TimeZone; recalculates utc\_offset on set (current DST).

## as\_string

    say $cron->as_string; # "0 30 14 * * ? *"

Returns the normalized Quartz expression as a string.

## to\_json

    say $cron->to_json; # '{"expression":"0 30 14 * * ? *", ...}'

Returns JSON-encoded hash of core attributes (expression, description, utc\_offset, time\_zone, begin\_epoch, end\_epoch). Requires JSON::MaybeXS.

## dump\_tree

    $cron->dump_tree; # Prints indented AST to STDOUT

Pretty-prints the AST root (or pass a node). Recursive indent for types/values/children.

# QUARTZ SYNTAX SUPPORTED

- Basic: "0 30 14 \* \* ?"
- Steps: "\*/15", "5/3", "10-20/5"
- Ranges: "1-5", "10-14"
- Lists: "1,15", "MON,WED,FRI"
- Last Day: "L", "L-2", "LW"
- Nth DOW: "1#3" = "3rd Sunday"
- Weekday: "15W" = "nearest weekday to 15th"
- Seconds Field: "0 0 30 14 \* \* ? \*" (7-field)
- Names: JAN-MAR, MON-FRI (normalized; mixed-case OK)
- Aliases: @hourly, @daily, @monthly, etc. (Vixie-style, mapped to Quartz)

Unix 5-field auto-converted to Quartz (adds seconds=0, year=\*, DOW normalize: MON=1→2, SUN=0→1).

# EXAMPLES

### New York Stock Market Open

    my $ny_open = Cron::Toolkit->new(
        expression => "0 30 9.5 * * 2-6 ?",
        time_zone => "America/New_York"
    );
    say $ny_open->describe; # "at 9:30 AM every Monday through Friday"

### Bounded Monthly Backup

    my $backup = Cron::Toolkit->new(
        expression => "0 0 2 LW * ? *",
        time_zone => "Europe/London"
    );
    $backup->begin_epoch(Time::Moment->new(year => 2025, month => 1, day => 1)->epoch);
    $backup->end_epoch(Time::Moment->new(year => 2025, month => 4, day => 1)->epoch);
    if ($backup->is_match(time)) {
        system("backup.sh");
    }

### Third Monday in 2025

    my $third_mon = Cron::Toolkit->new(expression => "0 0 0 * * 2#3 ? 2025");
    say $third_mon->describe; # "at midnight on the third Monday in 2025"

### Seconds Field (Quartz ATS)

    my $sec_cron = Cron::Toolkit->new_from_quartz(
        expression => "0 0 30 14 * * ? *"
    );
    say $sec_cron->describe; # "at 2:30:00 PM every month"

### Crontab Parse + Utils

    my @crons = Cron::Toolkit->new_from_crontab('my_tab');
    my $cron = $crons[0];
    say $cron->next_occurrences(3); # Next 3 epochs
    say decode_json($cron->to_json)->{description}; # JSON attrs

# DEBUGGING

    $ENV{Cron_DEBUG} = 1;
    $cron->utc_offset(-300); # "DEBUG: utc_offset: set to -300"
    $cron->dump_tree; # AST structure

# AUTHOR

Nathaniel J Graham <ngraham@cpan.org>

# COPYRIGHT & LICENSE

Copyright 2025 Nathaniel J Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License (2.0).
