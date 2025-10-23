package Cron::Toolkit;
$VERSION = 0.04;
use strict;
use warnings;
use Time::Moment;
use Cron::Toolkit::Tree::Utils qw(:all %aliases);
use Cron::Toolkit::Tree::CompositePattern;
use Cron::Toolkit::Tree::TreeParser;
use Cron::Toolkit::Tree::Composer;
use List::Util qw(max min);
use Exporter   qw(import);
use feature 'say';

our @EXPORT_OK   = qw(new new_from_unix new_from_quartz new_from_crontab);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

=head1 NAME

Cron::Toolkit - Cron parser, describer, and scheduler with full Quartz support

=encoding utf8

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Cron::Toolkit is a comprehensive Perl module for parsing, describing, and scheduling cron expressions. It evolved from a descriptive focus into a versatile toolkit for cron manipulation, featuring timezone-aware matching, bounded searches, and complete Quartz enterprise syntax support (seconds field, L/W/#, steps, ranges, lists).

Key features:

=over 4

=item *

Natural Language Descriptions: Generates readable English like "at 2:30 PM on the third Monday of every month in 2025". Extensible for locales via Composer/Visitor.

=item *

Timezone Awareness: Supports time_zone (e.g., "America/New_York") or utc_offset (-300 minutes) for local-time matching and next/previous calculations. Uses DateTime::TimeZone for DST handling.

=item *

Bounded Searches: Optional begin_epoch/end_epoch limits next/previous to a time window, preventing infinite loops or off-by-one errors.

=item *

AST Architecture: Tree-based parsing with Pattern nodes (Single, Range, Step, List, Last, Nth, NearestWeekday). Dual visitors for description (Composer + EnglishVisitor) and matching (Matcher + MatchVisitor)—easy to extend for custom patterns or locales.

=item *

Quartz Compatibility: Full support for seconds field, L (last day), W (nearest weekday), # (nth DOW), steps/ranges/lists. Unix 5-field auto-converts to Quartz (adds seconds=0, year=*).

=item *

Production-Ready: 50+ tests covering edges like leap years, month lengths, DOW normalization, DST flips, and bounded clamps. Handles @aliases (@hourly, etc.) in expressions and crontabs.

=back

=head1 TREE ARCHITECTURE

Cron::Toolkit employs an Abstract Syntax Tree (AST) for robust expression handling:

=over 4

=item *

Parse: TreeParser constructs Pattern nodes from fields (Single for 15, Range for 1-5, Step for */15, List for 1,15, Last for L, Nth for 1#3, NearestWeekday for 15W).

=item *

Describe: Composer fuses node outputs via templates, using EnglishVisitor (or locale subclass) for human-readable text.

=item *

Match: Matcher evaluates recursively against timestamps, using MatchVisitor for field-by-field checks (context-aware for L/nth/W).

=back

This separation enables extensibility: Subclass Visitor for new locales (e.g., FrenchVisitor) or patterns (add parse clause + visit method).

=head1 METHODS

=head2 new

  my $cron = Cron::Toolkit->new(
      expression => "0 30 14 * * ?",
      time_zone => "America/New_York", # Auto-calculates offset (DST-aware)
      utc_offset => -300, # Minutes from UTC (overrides time_zone if both set)
      begin_epoch => 1640995200, # Optional: Start bound (default: time)
      end_epoch => 1672531200, # Optional: End bound (default: undef/unbounded)
  );

Primary constructor. Auto-detects Unix (5 fields) or Quartz (6/7 fields). Supports @aliases (@hourly → "0 0 * * * ? *"). Normalizes to 7-field Quartz internally.

Parameters:

=over 4

=item *

expression: Required cron string or @alias.

=item *

time_zone: Optional TZ string (e.g., "America/New_York"); auto-calculates utc_offset if not set.

=item *

utc_offset: Optional minutes from UTC (-1080 to +1080); overrides time_zone calc.

=item *

begin_epoch: Optional non-negative epoch; floors searches (default: time).

=item *

end_epoch: Optional non-negative epoch; caps searches (default: unbounded).

=back

Returns: Blessed Cron::Toolkit object.

=head2 new_from_unix

  my $unix_cron = Cron::Toolkit->new_from_unix(
      expression => "30 14 * * MON"
  );

Unix-specific constructor for 5-field expressions. Auto-converts to Quartz (adds seconds=0, year=*, normalizes DOW: MON=1→2, SUN=0→1).

Parameters: Same as L</new>, but expression must be 5 fields.

=head2 new_from_quartz

  my $quartz_cron = Cron::Toolkit->new_from_quartz(
      expression => "0 30 14 * * MON 2025"
  );

Quartz-specific constructor for 6/7-field expressions. Validates and normalizes (adds year=* if 6 fields, DOW names to numbers).

Parameters: Same as L</new>, but expression must be 6/7 fields.

=head2 new_from_crontab

  my @crons = Cron::Toolkit->new_from_crontab('/etc/crontab');  # Or string

Parses a crontab file or string into array of Cron::Toolkit objects. Skips comments (#), empty lines, invalid exprs (warns). Supports @aliases (@hourly → "0 0 * * * ? *").

Parameters:

=over 4

=item *

input: File path or multi-line string.

=back

Returns: Array of valid objects (empty if none).

=head2 describe

  my $english = $cron->describe;
  my $french = $cron->describe(locale => 'fr');  # Stub; falls back to English

Returns human-readable description with fused combos (e.g., "at 2:30 PM on the third Monday of every month"). Defaults to English; locale param for extensibility (warns on unsupported, e.g., 'fr'—extend via Visitor subclass).

=head2 is_match

  my $match = $cron->is_match($epoch_seconds); # True/false

Returns true if the timestamp matches the cron in the object's timezone (local time, DST-aware).

Parameters:

=over 4

=item *

epoch_seconds: Non-negative Unix timestamp (UTC).

=back

=head2 next

  my $next_epoch = $cron->next($epoch_seconds);
  my $next_epoch = $cron->next; # Defaults to begin_epoch or time

Returns the next matching epoch after the given/current time, clamped >= begin_epoch and <= end_epoch (undef if none).

Parameters:

=over 4

=item *

epoch_seconds: Optional non-negative timestamp (defaults: begin_epoch // time, clamped to bounds).

=back

=head2 previous

  my $prev_epoch = $cron->previous($epoch_seconds);
  my $prev_epoch = $cron->previous; # Defaults to time

Returns the previous matching epoch before the given/current time, clamped <= end_epoch and >= begin_epoch (undef if none).

Parameters:

=over 4

=item *

epoch_seconds: Optional non-negative timestamp (defaults: time, clamped to bounds).

=back

=head2 next_n

  my $next_epochs = $cron->next_n($epoch_seconds, $n, $max_iter);
  my $next_epochs = $cron->next_n(undef, $n); # Defaults: time, n=1, max_iter=10000

Returns arrayref of the next $n matching epochs after the given/current time, clamped to bounds. Guards against loops with max_iter (dies on exceed).

Parameters:

=over 4

=item *

epoch_seconds: Optional start timestamp (defaults: time).

=item *

n: Number of occurrences (defaults: 1).

=item *

max_iter: Max iterations (defaults: 10000; dies if exceeded).

=back

Returns: Arrayref of epochs (empty if none).

=head2 next_occurrences

Alias for L</next_n>. Same parameters and return.

=head2 begin_epoch (GETTER/SETTER)

  say $cron->begin_epoch; # Current value
  $cron->begin_epoch(1640995200); # Set to 2022-01-01 UTC

Gets/sets the start epoch for bounded searches (non-negative integer or undef). Clamps next/previous from this time onward (defaults: time if undef).

=head2 end_epoch (GETTER/SETTER)

  say $cron->end_epoch; # undef or current value
  $cron->end_epoch(1672531200); # Set to 2023-01-01 UTC
  $cron->end_epoch(undef); # Unbounded

Gets/sets the end epoch for bounded searches (non-negative integer or undef). Caps next/previous at this time (defaults: unbounded if undef).

=head2 utc_offset (GETTER/SETTER)

  say $cron->utc_offset; # -300
  $cron->utc_offset(-480); # Switch to PST

Gets/sets UTC offset in minutes (-1080 to +1080). Validates input; overrides time_zone calc.

=head2 time_zone (GETTER/SETTER)

  say $cron->time_zone; # "America/New_York"
  $cron->time_zone("Europe/London"); # Recalcs utc_offset (DST-aware)

Gets/sets time zone string (e.g., "America/New_York"). Validates via DateTime::TimeZone; recalculates utc_offset on set (current DST).

=head2 as_string

  say $cron->as_string; # "0 30 14 * * ? *"

Returns the normalized Quartz expression as a string.

=head2 to_json

  say $cron->to_json; # '{"expression":"0 30 14 * * ? *", ...}'

Returns JSON-encoded hash of core attributes (expression, description, utc_offset, time_zone, begin_epoch, end_epoch). Requires JSON::MaybeXS.

=head2 dump_tree

  $cron->dump_tree; # Prints indented AST to STDOUT

Pretty-prints the AST root (or pass a node). Recursive indent for types/values/children.

=head1 QUARTZ SYNTAX SUPPORTED

=over 4

=item *

Basic: "0 30 14 * * ?"

=item *

Steps: "*/15", "5/3", "10-20/5"

=item *

Ranges: "1-5", "10-14"

=item *

Lists: "1,15", "MON,WED,FRI"

=item *

Last Day: "L", "L-2", "LW"

=item *

Nth DOW: "1#3" = "3rd Sunday"

=item *

Weekday: "15W" = "nearest weekday to 15th"

=item *

Seconds Field: "0 0 30 14 * * ? *" (7-field)

=item *

Names: JAN-MAR, MON-FRI (normalized; mixed-case OK)

=item *

Aliases: @hourly, @daily, @monthly, etc. (Vixie-style, mapped to Quartz)

=back

Unix 5-field auto-converted to Quartz (adds seconds=0, year=*, DOW normalize: MON=1→2, SUN=0→1).

=head1 EXAMPLES

=head3 New York Stock Market Open

  my $ny_open = Cron::Toolkit->new(
      expression => "0 30 9.5 * * 2-6 ?",
      time_zone => "America/New_York"
  );
  say $ny_open->describe; # "at 9:30 AM every Monday through Friday"

=head3 Bounded Monthly Backup

  my $backup = Cron::Toolkit->new(
      expression => "0 0 2 LW * ? *",
      time_zone => "Europe/London"
  );
  $backup->begin_epoch(Time::Moment->new(year => 2025, month => 1, day => 1)->epoch);
  $backup->end_epoch(Time::Moment->new(year => 2025, month => 4, day => 1)->epoch);
  if ($backup->is_match(time)) {
      system("backup.sh");
  }

=head3 Third Monday in 2025

  my $third_mon = Cron::Toolkit->new(expression => "0 0 0 * * 2#3 ? 2025");
  say $third_mon->describe; # "at midnight on the third Monday in 2025"

=head3 Seconds Field (Quartz ATS)

  my $sec_cron = Cron::Toolkit->new_from_quartz(
      expression => "0 0 30 14 * * ? *"
  );
  say $sec_cron->describe; # "at 2:30:00 PM every month"

=head3 Crontab Parse + Utils

  my @crons = Cron::Toolkit->new_from_crontab('my_tab');
  my $cron = $crons[0];
  say $cron->next_occurrences(3); # Next 3 epochs
  say decode_json($cron->to_json)->{description}; # JSON attrs

=head1 DEBUGGING

  $ENV{Cron_DEBUG} = 1;
  $cron->utc_offset(-300); # "DEBUG: utc_offset: set to -300"
  $cron->dump_tree; # AST structure

=head1 AUTHOR

Nathaniel J Graham <ngraham@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2025 Nathaniel J Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License (2.0).

=cut

sub new_from_unix {
   my ( $class, %args ) = @_;
   $args{is_quartz} = 0;
   my $self = $class->_new(%args);
}

sub new_from_quartz {
   my ( $class, %args ) = @_;
   $args{is_quartz} = 1;
   my $self = $class->_new(%args);
}

sub new {
   my ( $class, %args ) = @_;
   die "expression required" unless defined $args{expression};

   # alias support
   if ( $args{expression} =~ /^(@.*)/ ) {
      my $alias = $1;
      $args{expression} = $aliases{$alias} // $args{expression};
      print STDERR "DEBUG: Alias '$alias' mapped to '$args{expression}'\n" if $ENV{Cron_DEBUG};
   }

   my @fields = split /\s+/, $args{expression};
   if ( @fields == 6 || @fields == 7 ) {
      $args{is_quartz} = 1;
   }
   elsif ( @fields == 5 ) {
      $args{is_quartz} = 0;
   }
   else {
      die "expected 5-7 fields";
   }
   my $self = $class->_new(%args);
}

sub _new {
   my ( $class, %args ) = @_;
   die "expression required" unless defined $args{expression};
   my $expr = uc $args{expression};
   $expr =~ s/\s+/ /g;
   $expr =~ s/^\s+|\s+$//g;

   # Convert month names to quartz numerical equivalent
   while ( my ( $name, $num ) = each %month_map ) { $expr =~ s/\b\Q$name\E\b/$num/gi; }
   my @fields = split /\s+/, $expr;

   # Convert dow names to quartz numerical equivalent
   # and normalize expression to 7-field quartz
   if ( $args{is_quartz} ) {
      die "expected 6-7 fields, got " . scalar(@fields) unless @fields == 6 || @fields == 7;
      push( @fields, '*' ) if @fields == 6;    # year
      $fields[5] = quartz_dow_normalize( $fields[5] );
   }
   else {
      die "expected 5 fields, got " . scalar(@fields) unless @fields == 5;
      while ( my ( $name, $num ) = each %dow_map_unix ) { $expr =~ s/\b\Q$name\E\b/$num/gi; }
      unshift( @fields, 0 );                   # seconds
      push( @fields, '*' );                    # year
      $fields[5] = unix_dow_normalize( $fields[5] );

      # $fields[3] = dom, $fields[5] = dow
      if ( $fields[3] eq '*' ) {
         if ( $fields[5] eq '*' ) {
            $fields[5] = '?';
         }
         else {
            $fields[3] = '?';
         }
      }
      elsif ( $fields[5] eq '*' ) {
         $fields[5] = '?';
      }
      elsif ( $fields[5] ne '?' && $fields[3] ne '?' ) {
         die "dow and dom cannot both be specified\n";
      }
   }

   # stitch it back together
   $expr = join( ' ', @fields );
   die "Invalid characters" unless $expr =~ /^[#LW\d\?\*\s\-\/,]+$/;

   # DEFAULTS: UTC (0 minutes)
   my $utc_offset = $args{utc_offset} // 0;
   my $time_zone  = $args{time_zone};

   my $self = bless {
      expression  => $expr,
      is_quartz   => $args{is_quartz},
      utc_offset  => $utc_offset,
      time_zone   => $time_zone // 'UTC',
      begin_epoch => $args{begin_epoch},    # undef = use method start_epoch
      end_epoch   => $args{end_epoch},      # undef = unbounded
   }, $class;

   $self->time_zone($time_zone) if defined $time_zone;

   my @types = qw(second minute hour dom month dow year);
   $self->{root} = Cron::Toolkit::Tree::CompositePattern->new( type => 'root' );
   for my $i ( 0 .. 6 ) {
      validate( $fields[$i], $types[$i] );
      my $node = Cron::Toolkit::Tree::TreeParser->parse_field( $fields[$i], $types[$i] );
      $node->{field_type} = $types[$i];
      $self->{root}->add_child($node);
   }
   return $self;
}

sub utc_offset {
   my ( $self, $new_offset ) = @_;
   if ( @_ > 1 ) {
      if ( !defined $new_offset || $new_offset !~ /^-?\d+$/ || $new_offset < -1080 || $new_offset > 1080 ) {
         die "Invalid utc_offset '$new_offset': must be an integer between -1080 and 1080 minutes";
      }
      $self->{utc_offset} = $new_offset;
      print STDERR "DEBUG: utc_offset: set to $new_offset\n" if $ENV{Cron_DEBUG};
   }
   print STDERR "DEBUG: utc_offset: returning $self->{utc_offset}\n" if $ENV{Cron_DEBUG};
   return $self->{utc_offset};
}

sub time_zone {
   my ( $self, $new_tz ) = @_;
   if ( @_ > 1 ) {
      require DateTime::TimeZone;
      my $tz   = $new_tz;
      my $zone = eval { DateTime::TimeZone->new( name => $tz ); } or do {
         die "Invalid time_zone '$tz': must be a valid TZ identifier ($@)";
      };
      $self->{time_zone} = $tz;
      my $tm = Time::Moment->now_utc;
      $self->{utc_offset} = $zone->offset_for_datetime($tm) / 60;    # Recalc to minutes (DST-aware)
      print STDERR "DEBUG: time_zone: set to $tz (offset: $self->{utc_offset})\n" if $ENV{Cron_DEBUG};
   }
   print STDERR "DEBUG: time_zone: returning $self->{time_zone}\n" if $ENV{Cron_DEBUG};
   return $self->{time_zone};
}

sub begin_epoch {
   my ( $self, $new_begin ) = @_;
   if ( @_ > 1 ) {
      die "Invalid begin_epoch '$new_begin': must be a non-negative integer" unless defined $new_begin && $new_begin =~ /^\d+$/ && $new_begin >= 0;
      $self->{begin_epoch} = $new_begin;
   }
   return $self->{begin_epoch};
}

sub end_epoch {
   my ( $self, $new_end ) = @_;
   if ( @_ > 1 ) {
      die "Invalid end_epoch '$new_end': must be undef or a non-negative integer" unless !defined $new_end || ( $new_end =~ /^\d+$/ && $new_end >= 0 );
      $self->{end_epoch} = $new_end;
   }
   return $self->{end_epoch};
}

# PHASE2: describe with locale stub
sub describe {
   my ( $self, %args ) = @_;
   my $locale = $args{locale} // 'en';
   my $composer = Cron::Toolkit::Tree::Composer->new(locale => $locale);
   if ($locale ne 'en') {
       warn "Locale '$locale' not supported; falling back to English. Extend Composer/Visitor for i18n.";
       $locale = 'en';
   }
   return $composer->describe($self->{root}, $locale);  # Composer must pass $locale (see note below)
}

sub is_match {
   my ( $self, $epoch_seconds ) = @_;
   return unless $self->{root};
   require Cron::Toolkit::Tree::Matcher;
   my $matcher = Cron::Toolkit::Tree::Matcher->new(
      tree       => $self->{root},
      utc_offset => $self->utc_offset,
      owner      => $self
   );
   return $matcher->match($epoch_seconds);
}

# Symmetric next() with auto-clamp defaults
sub next {
   my ( $self, $epoch_seconds ) = @_;
   $epoch_seconds //= $self->begin_epoch // time;
   die "Invalid epoch_seconds: must be a non-negative integer" unless defined $epoch_seconds && $epoch_seconds =~ /^\d+$/ && $epoch_seconds >= 0;

   # Clamp to begin_epoch floor if set
   $epoch_seconds = max( $epoch_seconds, $self->begin_epoch // 0 ) if defined $self->begin_epoch;
   require Cron::Toolkit::Tree::Matcher;
   my $matcher = Cron::Toolkit::Tree::Matcher->new(
      tree       => $self->{root},
      utc_offset => $self->utc_offset,
      owner      => $self
   );
   my ( $window, $step ) = $self->_estimate_window;
   my $result = $matcher->_find_next( $epoch_seconds, $epoch_seconds + $window, $step, 1 );

   # Cap to end_epoch if set
   return undef if defined $self->end_epoch && $result && $result > $self->end_epoch;
   return $result;
}

# Symmetric previous() with auto-clamp defaults
sub previous {
   my ( $self, $epoch_seconds ) = @_;
   $epoch_seconds //= time;
   die "Invalid epoch_seconds: must be a non-negative integer" unless defined $epoch_seconds && $epoch_seconds =~ /^\d+$/ && $epoch_seconds >= 0;

   # Clamp to end_epoch cap if set
   $epoch_seconds = min( $epoch_seconds, $self->end_epoch // $epoch_seconds ) if defined $self->end_epoch;
   require Cron::Toolkit::Tree::Matcher;
   my $matcher = Cron::Toolkit::Tree::Matcher->new(
      tree       => $self->{root},
      utc_offset => $self->utc_offset,
      owner      => $self
   );
   my ( $window, $step ) = $self->_estimate_window;
   my $result = $matcher->_find_next( $epoch_seconds, $epoch_seconds - $window, $step, -1 );

   # Floor to begin_epoch if set
   return undef if defined $self->begin_epoch && $result && $result < $self->begin_epoch;
   return $result;
}

# next_n with max_iter guard
use constant MAX_ITER => 10000;    # Configurable? Later.

sub next_n {
   my ( $self, $epoch_seconds, $n, $max_iter ) = @_;
   $epoch_seconds //= time;
   $n             //= 1;
   $max_iter      //= MAX_ITER;
   die "Invalid epoch_seconds: must be a non-negative integer" unless defined $epoch_seconds && $epoch_seconds =~ /^\d+$/ && $epoch_seconds >= 0;
   die "Invalid n: must be positive integer"                   unless defined $n             && $n             =~ /^\d+$/ && $n > 0;
   die "Invalid max_iter: must be positive integer >= n"       unless defined $max_iter      && $max_iter      =~ /^\d+$/ && $max_iter >= $n;
   my @results;
   my $current = $epoch_seconds;
   my $iter    = 0;

   for ( 1 .. $n ) {
      $iter++;
      die "Exceeded max_iter ($max_iter) in next_n; possible infinite loop? Tighten end_epoch or reduce n." if $iter > $max_iter;
      my $next = $self->next($current);
      last unless defined $next;
      push @results, $next;
      $current = $next + 1;    # Skip self-match
   }
   return \@results;
}

# PHASE2: next_occurrences alias
sub next_occurrences {
    my $self = shift;
    return $self->next_n(@_);
}

# PHASE2: as_string
sub as_string {
    my ($self) = @_;
    return $self->{expression};
}

# PHASE2: to_json
sub to_json {
    my ($self) = @_;
    require JSON::MaybeXS;
    return JSON::MaybeXS::encode_json({
        expression => $self->as_string,
        description => $self->describe,
        utc_offset => $self->utc_offset,
        time_zone => $self->time_zone,
        begin_epoch => $self->begin_epoch,
        end_epoch => $self->end_epoch,
    });
}

# new_from_crontab class method
sub new_from_crontab {
   my ( $class, $input ) = @_;
   my $content = $input;
   if ( -f $input ) {
      open my $fh, '<', $input or die "Cannot open crontab '$input': $!";
      local $/;
      $content = <$fh>;
   }
   my @crons;
   foreach my $line ( split /\n/, $content ) {
      $line =~ s/\s+#.*$//;                # Strip comments + trailing space
      next unless $line =~ /\S/;
      chomp $line;

      next if $line eq '';                 # Empty post-strip
      eval {
         my $cron = $class->new( expression => $line );
         push @crons, $cron;
      };
      warn "Skipped invalid crontab line: '$line' ($@)" if $@;
   }
   return @crons;
}

sub _estimate_window {
   my ($self) = @_;
   my @fields = split /\s+/, $self->{expression};

   # Dom constrained or DOW special: 2-month window, daily step (covers cross-month, intra-month)
   if ( $fields[3] ne '*' || $fields[5] =~ /^(L|LW|\d+W|\d+#\d+)$/ ) {
      return ( 62 * 24 * 3600, 24 * 3600 );
   }

   # Year or month constrained (no dom/DOW special): yearly window, monthly step
   if ( $fields[4] ne '*' || $fields[6] ne '*' ) {
      return ( 365 * 24 * 3600, 30 * 24 * 3600 );
   }

   # Second or minute steps: daily window, second step
   if ( $fields[0] =~ /\/\d+/ || $fields[1] =~ /\/\d+/ ) {
      return ( 24 * 3600, 1 );
   }

   # Every-second schedules: immediate window, second step
   if ( $fields[0] eq '*' && $fields[1] eq '*' && $fields[2] eq '*' && $fields[3] eq '*' && $fields[4] eq '*' && $fields[5] eq '?' && $fields[6] eq '*' ) {
      return ( 1, 1 );
   }

   # Default: monthly window, daily step
   return ( 31 * 24 * 3600, 24 * 3600 );
}

# PHASE2: dump_tree (self or node; recursive pretty-print)
sub dump_tree {
    my ($self_or_node, $indent) = @_;
    $indent //= 0;
    my $node = ref($self_or_node) eq 'Cron::Toolkit' ? $self_or_node->{root} : $self_or_node;
    return unless $node;
    my $prefix = '  ' x $indent;
    my $type = $node->{type} // 'root';
    my $val = $node->{value} ? " ($node->{value})" : '';
    my $field = $node->{field_type} ? " [$node->{field_type}]" : '';
    say $prefix . ucfirst($type) . $val . $field;
    # Recurse children
    for my $child (@{$node->{children} || []}) {
        $child->dump_tree($indent + 1);
    }
}

1;
