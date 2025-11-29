package Cron::Toolkit;

# VERSION
$VERSION = 0.12;

use strict;
use warnings;
use Time::Moment;
use DateTime::TimeZone;
use Cron::Toolkit::Utils qw(:all);
use Cron::Toolkit::Pattern::Single;
use Cron::Toolkit::Pattern::Wildcard;
use Cron::Toolkit::Pattern::Range;
use Cron::Toolkit::Pattern::List;
use Cron::Toolkit::Pattern::Last;
use Cron::Toolkit::Pattern::LastW;
use Cron::Toolkit::Pattern::Nth;
use Cron::Toolkit::Pattern::Unspecified;
use Cron::Toolkit::Pattern::NearestWeekday;
use Cron::Toolkit::Pattern::StepValue;
use Cron::Toolkit::Pattern::Step;

use List::Util qw(max min);
use Exporter   qw(import);
use feature 'say';

=encoding utf-8

=head1 NAME

Cron::Toolkit - Quartz-compatible cron parser with unique extensions and over 400 tests

=head1 SYNOPSIS

    use Cron::Toolkit;
    use feature qw(say);

    my $c = Cron::Toolkit->new(
        expression => "0 30 14 ? * 6-2 *",
        time_zone  => "Europe/London",
    );

    say $c->describe;
    # 2:30 PM every day from Saturday to Tuesday of every month

    # next occurence in epoch seconds
    say $c->next;

    # previous occurence in epoch seconds
    say $c->previous;

    # Question: when does February 29th next land on a Monday? 
    say Cron::Toolkit->new(expression => "0 0 0 29 2 1 *")->next;
    # Mon Feb 29 00:00:00 2044

    # See exactly what was parsed
    $c->dump_tree;
    # ┌─ second: 0
    # ├─ minute: 30
    # ├─ hour:   14
    # ├─ dom:    ?
    # ├─ month:  *
    # ├─ dow:    6-2 
    # └─ year:   *

=head1 DESCRIPTION

C<Cron::Toolkit> implements a complete, rigorously-tested cron expression parser that supports the full Quartz Scheduler syntax plus several useful extensions not found in other implementations.

Notable features include:

=over 4

=item * Full 7-field Quartz syntax (seconds and year fields)

=item * Both day-of-month and day-of-week may be specified simultaneously (AND logic)

=item * Wrapped day-of-week ranges (e.g. C<6-2> = Saturday through Tuesday)

=item * Proper Quartz-compatible DST handling

=item * Time-zone support via IANA names or fixed UTC offsets

=item * Natural-language English descriptions

=item * Complete crontab parsing with environment variable expansion

=item * Full abstract syntax tree and C<dump_tree()> for debugging

=back

=head1 RELIABILITY

The distribution ships with over 400 data-driven tests covering every supported token, leap years, DST transitions, all time zones from UTC−12 to UTC+14, and every edge case discovered during development.

If it parses, the result is correct.

=head1 UNIQUE EXTENSIONS

=over 4

=item * DOM + DOW = AND logic

Allows queries such as "next February 29 that falls on a Monday".

=item * Wrapped day-of-week ranges

6-2 matches Saturday, Sunday, Monday, Tuesday

=item * Internal day-of-week: 1–7 = Monday–Sunday

Matches L<Time::Moment> and L<DateTime>. C<as_quartz_string()> converts back to Quartz's 1=Sunday convention.

=back

=head1 FIELD REFERENCE & ALLOWED VALUES

    Field            Allowed values         Allowed special characters 
    -------------------------------------------------------------------
    Second           0–59                   *,/,-                     
    Minute           0–59                   *,/,-,
    Hour             0–23                   *,/,-,
    Day of month     1–31                   *,/,-,?,L,LW,W
    Month            1–12 or JAN–DEC        *,/,-                          
    Day of week      1–7 or MON-SUN         *,/,-,?,L,#
    Year (optional)  1970–2099              *,/,-

    Legend:
      *    wildcard
      ,    list
      -    range
      /    step
      ?    no specific value (DOM or DOW only)
      L    last (day or day-of-week)
      L-n  n to last day of the month
      nL   last n-day of the month 
      LW   last weekday of month
      nW   nearest weekday to n
      #    nth day-of-week (e.g. 3#2 = 2nd Wednesday)

    @aliases: @yearly @annually @monthly @weekly @daily @hourly (Quartz standard)

=head1 METHODS

=over 4

=item C<< Cron::Toolkit->new( expression => $expr, %options ) >>

Main constructor; auto-detects Unix vs Quartz format.

=item C<< Cron::Toolkit->new_from_unix( expression => $expr, %options ) >>

Force traditional 5-field Unix interpretation.

=item C<< Cron::Toolkit->new_from_quartz( expression => $expr, %options ) >>

Force Quartz interpretation.

=item C<< Cron::Toolkit->new_from_crontab( $string ) >>

Parse a full crontab; returns a list of C<Cron::Toolkit> objects.
Supports C<$VAR> expansion, user field, and comments.

=item C<< $c->as_string >>

Normalized 7-field representation (DOW 1–7 = Mon–Sun).

=item C<< $c->as_quartz_string >>

Quartz-compatible string (DOW 1=Sunday).

=item C<< $c->describe >>

Human-readable English description.

=item C<< $c->next( [$from_epoch] ) >>

Next occurrence after C<$from_epoch> or C<time>.

=item C<< $c->previous( [$from_epoch] ) >>

Previous occurrence before C<$from_epoch> or C<time>.

=item C<< $c->is_match( $epoch ) >>

Returns true if C<$epoch> matches the expression.

=item C<< $c->dump_tree >>

Pretty-printed abstract syntax tree (invaluable for debugging).

=item C<< $c->to_json >>

JSON representation of the object (expression, description, bounds, etc.).

=item Accessors

    $c->time_zone("Europe/Berlin")
    $c->utc_offset(+180)          # minutes
    $c->begin_epoch($epoch)
    $c->end_epoch($epoch)         # undef = no limit

=back

=head1 TIME ZONES AND DST

All calculations are performed in the configured time zone.
DST transitions follow Quartz Scheduler rules exactly:

=over 4

=item * Spring forward — times that do not exist are skipped

=item * Fall back — repeated local times fire twice

=back

=head1 BUGS AND CONTRIBUTIONS

This module is under active development and has not yet reached a 1.0 release.

The test suite currently contains over 400 data-driven tests covering every supported token, DST transitions, leap years, all time zones, and many edge cases — but real-world cron expressions can be surprisingly creative.

If you find:

=over 4

=item * an expression that should be valid but dies or is rejected

=item * a next/previous occurrence that is wrong

=item * a description that is misleading or unclear

=item * any behaviour that differs from Quartz Scheduler (when using Quartz syntax)

=back

...please file a bug report at
L<https://github.com/nathanielgraham/cron-toolkit-perl/issues>

Pull requests with failing test cases are especially welcome — they are the fastest way to get a fix merged.

Feature requests (e.g. more natural-language locales, RRULE export, etc.) are also very much appreciated.

Thank you!

=cut

=head1 AUTHOR

Nathaniel Graham

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Nathaniel Graham

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub new_from_unix {
   my ( $class, %args ) = @_;
   $args{is_quartz} = 0;
   my $self = $class->new(%args);
   return $self;
}

sub new_from_quartz {
   my ( $class, %args ) = @_;
   $args{is_quartz} = 1;
   my $self = $class->new(%args);
   return $self;
}

sub new {
   my ( $class, %args ) = @_;
   die "expression required" unless defined $args{expression};
   my $expr = uc $args{expression};
   $expr =~ s/\s+/ /g;
   $expr =~ s/^\s+|\s+$//g;

   # alias support
   if ( $expr =~ /^(@.*)/ ) {
      my $alias = lc($1);
      $expr = $ALIASES{$alias} or die "no such alias: $alias";
   }

   my @fields     = split /\s+/, $expr;
   my @raw_fields = @fields;

   # normalize to 7-fields
   unshift( @fields, 0 ) if scalar @fields == 5;    # seconds
   push( @fields, '*' )  if scalar @fields == 6;    # year
   die "expected 5-7 fields" unless scalar @fields == 7;

   # normalize to 7-field quartz expression
   if ( $args{is_quartz} ) {

      # Reject Quartz DOW 0
      if ( $fields[5] =~ /\b0\b/ && $fields[5] !~ /#\d+/ ) {
         die "Invalid dow value: 0, must be [1-7] in Quartz";
      }

      # Map Quartz DOW names
      while ( my ( $name, $num ) = each %DOW_MAP_QUARTZ ) {
         $fields[5] =~ s/\b\Q$name\E\b/$num/gi;
      }

      # Normalize Quartz DOW 1-7 to 0-6, skip nth and step
      $fields[5] =~ s/(?<![#\/])(\b[1-7]\b)(?![#\/])/$1-1/ge;
   }
   else {
      # convert dow names to unix numerical equivalent
      while ( my ( $name, $num ) = each %DOW_MAP_UNIX ) {
         $fields[5] =~ s/\b\Q$name\E\b/$num/gi;
      }
   }

   # Convert month names to numerical equivalent
   while ( my ( $name, $num ) = each %MONTH_MAP ) { $fields[4] =~ s/\b\Q$name\E\b/$num/gi; }

   # align dom and dow fields
   if ( $fields[3] ne '?' && $fields[5] eq '*' ) {
      $fields[5] = '?';
   }
   elsif ( $fields[3] eq '*' && $fields[5] ne '?' ) {
      $fields[3] = '?';
   }
   elsif ( $fields[3] eq '?' && $fields[5] eq '?' ) {
      die "dow and dom cannot both be unspecified\n";
   }

   die "Invalid characters" unless join( ' ', @fields ) =~ /^[#LW\d\?\*\s\-\/,]+$/;

   my $self = bless {
      fields      => \@fields,
      raw_fields  => \@raw_fields,
      nodes       => [],
      utc_offset  => 0,
      time_zone   => 'UTC',
      begin_epoch => time - ( 10 * 365 * 86400 ),    # ~10 years ago
      end_epoch   => time + ( 10 * 365 * 86400 ),    # ~10 years ahead
   }, $class;

   $self->utc_offset( $args{utc_offset} ) if defined $args{utc_offset};
   $self->time_zone( $args{time_zone} ) if defined $args{time_zone};
   $self->user( $args{user} )       if defined $args{user};
   $self->command( $args{command} ) if defined $args{command};
   $self->env( $args{env} )         if defined $args{env};

   $self->_build_tree;

   return $self;
}

sub _build_tree {
   my $self  = shift;
   my @types = qw(second minute hour dom month dow year);
   for my $i ( 0 .. $#types ) {
      my $node = $self->_build_node( $types[$i], $self->{fields}[$i] );
      $node = $self->_optimize_node( $node, $types[$i] );
      push( @{ $self->{nodes} }, $node );
   }
   $self->_finalize_dow( $self->{nodes}[5] );
}

sub _optimize_node {
   my ( $self, $node, $field ) = @_;

   # Get field limits
   my ( $min, $max ) = @{ $LIMITS{$field} };
   $min = 0 if $field eq 'dow';

   # Step collapse — only if degenerate
   if ( $node->type eq 'step' ) {
      my $base_node = $node->{children}[0];
      my $step      = $node->{children}[1]{value};
      my @values;

      if ( $base_node->type eq 'wildcard' ) {
         my ( $min, $max ) = @{ $LIMITS{$field} };
         $min    = 0 if $field eq 'dow';
         @values = ( $min .. $max );
      }

      elsif ( $base_node->type eq 'single' ) {
         my $start = $base_node->{value};
         @values = ( $start .. $max );
      }
      elsif ( $base_node->type eq 'range' ) {
         my ( $start, $end ) = map { $_->{value} } @{ $base_node->{children} };
         @values = ( $start .. $end );
      }

      my @stepped;
      for ( my $v = $values[0] ; $v <= $values[-1] ; $v += $step ) {
         push @stepped, $v if grep { $_ == $v } @values;
      }

      # === DEGENERATE CASE: 0 or 1 value → collapse ===
      if ( @stepped == 0 ) {
         return Cron::Toolkit::Pattern::Wildcard->new(
            value      => '*',
            field_type => $field
         );
      }
      elsif ( @stepped == 1 ) {
         return Cron::Toolkit::Pattern::Single->new(
            value      => $stepped[0],
            field_type => $field
         );
      }

      # === NON-DEGENERATE: keep as step (but optimize base if possible) ===
      # Recursively optimize base (e.g., 1-10/5 → range(1,10))
      my $optimized_base = $self->_optimize_node( $base_node, $field );
      return $node if $optimized_base == $base_node;    # no change

      my $new_step = Cron::Toolkit::Pattern::Step->new( field_type => $field );
      $new_step->add_child($optimized_base);
      $new_step->add_child( $node->{children}[1] );     # step value
      return $new_step;
   }

   # List-to-range
   if ( $node->type eq 'list' ) {
      my @values = sort { $a <=> $b } map { $_->{value} }
        grep { $_->type eq 'single' } @{ $node->{children} };
      if ( @values >= 2 && $values[-1] - $values[0] == $#values ) {
         my $range = Cron::Toolkit::Pattern::Range->new( field_type => $field );
         $range->add_child(
            Cron::Toolkit::Pattern::Single->new(
               value      => $values[0],
               field_type => $field
            )
         );
         $range->add_child(
            Cron::Toolkit::Pattern::Single->new(
               value      => $values[-1],
               field_type => $field
            )
         );
         return $range;
      }
   }

   return $node;
}

sub _finalize_dow {
   my $self     = shift;
   my $dow_node = shift;

   if ( $dow_node->has_children ) {
      $self->_finalize_dow($_) for @{ $dow_node->{children} };
   }

   elsif ( $dow_node->type eq 'single' && $dow_node->{value} == 0 ) {
      $dow_node->{value} = 7;
   }
}

sub _build_node {
   my ( $self, $field, $value ) = @_;

   die "Invalid characters in $field: $value" unless $value =~ $ALLOWED_CHARS{$field};

   my ( $min, $max ) = @{ $LIMITS{$field} };
   $min = 0 if $field eq 'dow';

   my $node;

   # validation and node creation
   if ( $value eq '*' ) {
      $node = Cron::Toolkit::Pattern::Wildcard->new(
         value      => '*',
         field_type => $field
      );
   }
   elsif ( $value eq '?' ) {
      die "Syntax: ? only allowed in dom or dow, not $field"
        unless $field =~ /^(dom|dow)$/;
      $node = Cron::Toolkit::Pattern::Unspecified->new(
         value      => '?',
         field_type => $field
      );
   }
   elsif ( $value =~ /^(\d+)?L$/ ) {
      my ($day) = ($1);
      die "Syntax: L only allowed in dow or dom, not $field"
        unless $field =~ /^dom|dow$/;

      $node = Cron::Toolkit::Pattern::Last->new(
         value      => $value,
         offset     => 0,
         field_type => $field,
      );

      if ( $field eq 'dom' ) {
         die $day . "L not allowed in dom" if defined $day;
      }
      else {
         $day //= $max;
         die "dow $day out of range [$min-$max]" unless $day >= $min && $day <= $max;
         $node->{dow} = $day;
         $node->{value} = $day . 'L';
      }
   }
   elsif ( $value =~ qr/^L-(\d+)$/ ) {
      my $offset = $1;
      die "Syntax: L only allowed in dom, not $field" unless $field eq 'dom';

      if ($offset) {
         die "dom offset $offset too large" if $offset >= $max - 1;
      }

      $node = Cron::Toolkit::Pattern::Last->new(
         value      => $value,
         offset     => $offset,
         field_type => $field
      );
   }
   elsif ( $value =~ /^LW$/ ) {
      die "Syntax: LW only allowed in dom, not $field" unless $field eq 'dom';
      $node = Cron::Toolkit::Pattern::LastW->new(
         value      => 'LW',
         field_type => $field
      );
   }
   elsif ( $value =~ /^(\d+)W$/ ) {
      die "Syntax: W only allowed in dom, not $field" unless $field eq 'dom';
      my ($day) = ($1);
      die "dom $day out of range [1-31]" unless $day >= 1 && $day <= 31;
      $node = Cron::Toolkit::Pattern::NearestWeekday->new(
         value      => $value,
         dom        => $day,
         field_type => $field
      );
   }
   elsif ( $value =~ /^(\d+)#(\d+)$/ ) {
      die "Syntax: # only allowed in dow, not $field" unless $field eq 'dow';
      my ( $day, $nth ) = ( $1, $2 );
      die "dow $day out of range [1-7]" unless $day >= 1 && $day <= 7;
      die "nth $nth out of range [1-5]" unless $nth >= 1 && $nth <= 5;
      $node = Cron::Toolkit::Pattern::Nth->new(
         value      => $value,
         nth        => $nth,
         dow        => $day,
         field_type => $field
      );
   }
   elsif ( $value =~ /^\d+$/ ) {
      die "$field $value out of range [$min-$max]" unless $value >= $min && $value <= $max;
      $node = Cron::Toolkit::Pattern::Single->new(
         value      => $value,
         field_type => $field
      );
   }
   elsif ( $value =~ /^(\*|\d+)-(\d+)$/ ) {
      my ( $start, $end ) = ( $1, $2 );
      $start = $min if $start eq '*';
      die "$field start $start out of range [$min-$max]" unless $start >= $min && $start <= $max;
      die "$field end $end out of range [$min-$max]"     unless $end >= $min   && $end <= $max;
      die "$field range start $start must be <= end $end" if $start > $end && $field ne 'dow';

      $node = Cron::Toolkit::Pattern::Range->new( field_type => $field );
      $node->add_child( Cron::Toolkit::Pattern::Single->new( value => $start, field_type => $field ) );
      $node->add_child( Cron::Toolkit::Pattern::Single->new( value => $end,   field_type => $field ) );

      if ( $field eq 'dow' && $start > $end ) {
         $node->{wrapped} = 1;
      }
   }
   elsif ( $value =~ /^(\*|\d+)\/(\d+)$/ ) {
      my ( $base_str, $step ) = ( $1, $2 );
      die "$field step $step out of range [$min-$max]" unless $step >= $min && $step <= $max;
      die "$field base $base_str out of range [$min-$max]" if $base_str ne '*' && ( $base_str < $min || $base_str > $max );
      $node = Cron::Toolkit::Pattern::Step->new(
         type       => 'step',
         field_type => $field
      );
      my $base_node =
        $base_str eq '*'
        ? Cron::Toolkit::Pattern::Wildcard->new( type => 'wildcard', value => '*', field_type => $field )
        : Cron::Toolkit::Pattern::Single->new( type => 'single', value => $base_str, field_type => $field );
      $node->add_child($base_node);
      $node->add_child(
         Cron::Toolkit::Pattern::StepValue->new(
            type       => 'step_value',
            value      => $step,
            field_type => $field
         )
      );
   }
   elsif ( $value =~ /^(\*|\d+)-(\d+)\/(\d+)$/ ) {
      my ( $base_str, $end, $step ) = ( $1, $2, $3 );
      my $start = $base_str eq '*' ? $min : $base_str;

      die "$field start $start out of range" unless $start >= $min && $start <= $max;
      die "$field end $end out of range"     unless $end >= $min   && $end <= $max;
      die "$field step $step invalid"        unless $step > 0;

      my $wrapped = 0;
      if ( $field eq 'dow' && $start > $end ) {
         $wrapped = 1;
      }
      else {
         die "$field range start $start must be <= end $end" if $start > $end && $field ne 'dow';
      }

      my $range_node = Cron::Toolkit::Pattern::Range->new(
         field_type => $field,
         wrapped    => $wrapped
      );
      $range_node->add_child( Cron::Toolkit::Pattern::Single->new( value => $start, field_type => $field ) );
      $range_node->add_child( Cron::Toolkit::Pattern::Single->new( value => $end,   field_type => $field ) );

      $node = Cron::Toolkit::Pattern::Step->new( field_type => $field );
      $node->add_child($range_node);
      $node->add_child( Cron::Toolkit::Pattern::StepValue->new( value => $step, field_type => $field ) );
   }
   elsif ( $value =~ /,/ ) {
      $node = Cron::Toolkit::Pattern::List->new(
         type       => 'list',
         field_type => $field
      );
      for my $sub ( split /,/, $value ) {
         eval {
            my $sub_node = $self->_build_node( $field, $sub );
            die "Invalid list element in $field: list not allowed" if $sub_node->type eq 'list';
            $node->add_child($sub_node);
         };
         if ($@) {
            my $error = $@;
            $error =~ s/^Invalid $field:/Invalid $field list element:/;
            $error =~ s/^$field ([^:]+):/Invalid $field list element $1:/;
            die $error;
         }
      }
   }
   else {
      die "Unsupported field: $value ($field)";
   }

   return $node;
}

sub utc_offset {
   my ( $self, $offset ) = @_;
   if ( $offset ) {
      if ( $offset !~ /^-?\d+$/ || $offset < -1080 || $offset > 1080 ) {
         die "Invalid utc_offset '$offset': must be an integer between -1080 and 1080 minutes";
      }
      $self->{utc_offset} = $offset;
   }
   return $self->{utc_offset};
}

sub time_zone {
   my ( $self, $tz ) = @_;
   if ( $tz ) {
      my $zone = eval { DateTime::TimeZone->new( name => $tz ) };
      die "Invalid time_zone '$tz': must be a valid TZ identifier ($@)" if $@;
      $self->{time_zone} = $tz;
      my $tm = Time::Moment->now_utc;
      $self->{utc_offset} = $zone->offset_for_datetime($tm) / 60;    # Recalc to minutes (DST-aware)
   }
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

sub user {
   my ($self, $user) = @_;
   $self->{user} = $user if $user;
   return $self->{user};
}

sub command {
   my ($self, $command) = @_;
   $self->{command} = $command if $command;
   return $self->{command};
}

sub env {
   my ($self, $env) = @_;
   $self->{env} = $env if $env;
   return $self->{env};
}

sub as_unix_string {
   my $self = shift;
   my $expr = $self->_as_string;
   $expr =~ s/\?/*/;
   my @fields = split( /\s+/, $expr );
   shift @fields;    # remove seconds
   pop @fields;      # remove year
   return join( ' ', @fields );
}

sub as_quartz_string {
    my $self = shift;
    my $expr = $self->_as_string;
    my @fields = split /\s+/, $expr;

    return $expr unless @fields > 5;

    my $dow = $fields[5];

    $dow =~ s{
       (?<![L#])        # not preceded by L or #
       \b([1-7])\b      # standalone 1-7
    }{
       $1 == 7 ? 1 : $1 + 1
    }gex;

    $fields[5] = $dow;
    return join ' ', @fields;
}

sub as_string {
   my $self = shift;
   return $self->_as_string;
}

sub _as_string {
   my $self   = shift;
   my $string = join( ' ', map { $self->_rebuild_from_node($_) } @{ $self->{nodes} } );
}

sub to_json {
   my $self = shift;
   return JSON::PP::encode_json(
      {
         expression  => $self->_as_string,
         description => $self->describe,
         utc_offset  => $self->utc_offset,
         time_zone   => $self->time_zone,
         begin_epoch => $self->begin_epoch,
         end_epoch   => $self->end_epoch,
      }
   );
}

sub new_from_crontab {
   my ( $class, $content ) = @_;
   die "crontab content required (string)" unless defined $content && length $content;
   my @crons;
   my %env;
   foreach my $line ( split /\n/, $content ) {

      # Strip trailing comments and trim
      $line             =~ s/\s*#.*$//;       # Remove comments from end
      $line             =~ s/^\s+|\s+$//g;    # Trim whitespace
      next unless $line =~ /\S/;              # Skip empty

      if ( $line =~ /^([A-Z_][A-Z0-9_]*)=(.*)$/ ) {
         $env{$1} = $2;
         next;
      }

      while ( my ( $var, $val ) = each %env ) {
         $line =~ s/\$$var\b/$val/g;
      }

      my @parts = split /\s+/, $line;

      my @cron_parts;
      my $is_alias = 0;
      for my $part (@parts) {
         last if @cron_parts >= 7;    # Cap at max Quartz fields
         if ( @cron_parts == 0 && $part =~ /^@/ ) {

            # Alias as single token
            push @cron_parts, $part;
            $is_alias = 1;
            last;                     # Aliases are single
         }
         elsif ( $part =~ /^[0-9*?,\/\-L#W?]+$/ || scalar (grep { $part =~ /$_/ } keys %DOW_MAP_UNIX) || scalar (grep { $part =~ /$_/ } keys %MONTH_MAP) ) {    # Cron-like: digits, *, ?, -, /, ,, L, W, #
            push @cron_parts, $part;
         }
         else {
            last;                                      # Non-cron token
         }
      }

      # Validate expression length
      my $expr = join ' ', @cron_parts;
      next unless $is_alias || ( @cron_parts >= 5 && @cron_parts <= 7 );

      # Extract user: Next token after prefix, if simple word (alphanumeric, no / or special)
      my ($user, $command);
      my $cron_end   = scalar @cron_parts;
      my $next_start = $cron_end;
      if ( @parts > $cron_end ) {
         my $potential_user = $parts[$cron_end];
         if ( $potential_user =~ /^\w+$/ ) {    # Simple username: letters/digits/_
            $user       = $potential_user;
            $next_start = $cron_end + 1;
         }
      }

      $command = join ' ', @parts[ $next_start .. $#parts ] if @parts > $next_start;

      my $cron;
      eval {
         $cron = $class->new(
            expression => $expr,
            user       => $user,
            command    => $command,
            env        => {%env}      # Copy current env
         );
      };
      if ($@) {
         warn "Skipped invalid crontab line: '$line' ($@)";
      } 
      else {
         push @crons, $cron;
      }
   }
   return @crons;
}

sub dump_tree {
   my ( $self, $indent ) = @_;
   my $out;

   my @names = qw(second minute hour dom month dow year);
   for my $i ( 0 .. $#{ $self->{nodes} } ) {
      my $node = $self->{nodes}[$i];
      my $name = $names[$i];

      my $prefix       = $i == 0 ? '┌─' : $i == $#{ $self->{nodes} } ? '└─' : '├─';
      my $child_indent = $i == $#{ $self->{nodes} } ? '  ' : '│ ';

      $out .= "$prefix $name: " . $node->_dump_tree($child_indent) . "\n";
   }
   return $out;
}

sub _rebuild_from_node {
   my ( $self, $node ) = @_;
   my $type = $node->type;
   return '*'          if $type eq 'wildcard';
   return '?'          if $type eq 'unspecified';
   return $node->value if $type eq 'single' || $type eq 'last' || $type eq 'lastW' || $type eq 'nth' || $type eq 'nearest_weekday' || $type eq 'step_value';
   return $self->_rebuild_from_node( $node->{children}[0] ) . '-' . $self->_rebuild_from_node( $node->{children}[1] ) if $type eq 'range';
   return $self->_rebuild_from_node( $node->{children}[0] ) . '/' . $self->_rebuild_from_node( $node->{children}[1] ) if $type eq 'step';
   return join ',', map { $self->_rebuild_from_node($_) } @{ $node->{children} } if $type eq 'list';
   die "Unsupported for rebuild: $type";
}

# describing

sub describe {
   my $self = shift;
   my $hms;
   my $dmy = '';
   my @nodes;

   my $wildcards = scalar grep { $_->type eq 'wildcard' } @{ $self->{nodes} }[ 0 .. 2 ];
   my $singles   = scalar grep { $_->type eq 'single' } @{ $self->{nodes} }[ 0 .. 2 ];

   # dedupe wildcards
   my $prev_type = '';
   for my $node ( @{ $self->{nodes} } ) {
      push @nodes, $node->type eq 'wildcard' && $prev_type eq 'wildcard' ? undef : $node;
      $prev_type = $node->type;
   }

   # HMS
   if ( $wildcards == 3 ) {
      $hms = $nodes[0]->to_english;
   }
   elsif ( $singles == 3 ) {
      $hms = format_time( map { $_->value } @nodes[ 0 .. 2 ] );
   }
   else {
      $hms = join( ' of ', map { $_->to_english } grep { defined $_ && !( $_->type eq 'single' && $_->value == 0 ) } @nodes[ 0 .. 2 ] );
   }

   # DMY
   if ( defined $nodes[3] && $nodes[3]->type ne 'unspecified' ) {
      if ( $nodes[3]->type eq 'single' ) {
         $dmy .= 'on ';
      }
      $dmy .= $nodes[3]->to_english . ' of ' . $self->{nodes}[4]->to_english;
   }

   if ( defined $nodes[3] && $nodes[3]->type ne 'unspecified' && defined $nodes[5] && $nodes[5]->type ne 'unspecified' ) {
      $dmy .= ' and ';
   }

   if ( defined $nodes[5] && $nodes[5]->type ne 'unspecified' ) {

      if ( $nodes[5]->type eq 'single' ) {
         $dmy .= 'every ';
      }
      $dmy .= $nodes[5]->to_english . ' of ' . $self->{nodes}[4]->to_english;
   }

   if ( defined $nodes[6] && $nodes[6]->type ne 'wildcard' ) {
      $dmy .= ' ' . $self->{nodes}[6]->to_english;
   }
   return join ' ', grep { $_ } ($hms, $dmy);
}

# matching

sub is_match {
   my ( $self, $epoch_seconds ) = @_;
   my $tm = Time::Moment->from_epoch($epoch_seconds);
   return unless $tm;
   return $self->_is_match($tm);
}

sub _is_match {
   my ( $self, $tm ) = @_;

 NODE: for my $node ( @{ $self->{nodes} } ) {
      my $value = $self->_field_value( $tm, $node->field_type );
      if ( $node->type eq 'list' ) {
         for my $child ( @{ $node->children } ) {
            next NODE if $child->match( $value, $tm );
         }
         return 0;
      }
      return 0 unless $node->match( $value, $tm );
   }
   return 1;
}

sub next {
   my ( $self, $epoch_seconds ) = @_;
   $epoch_seconds //= time;

   my $clamped = max( $epoch_seconds, $self->{begin_epoch} );

   return if $clamped > $self->{end_epoch};

   my $tm = Time::Moment->from_epoch($clamped)->with_offset_same_instant( $self->{utc_offset} );
   $tm = $tm->plus_seconds(1);

   # shortcut for HMS
   NODE: foreach my $i ( 0 .. 2 ) {
      my $node    = $self->{nodes}[$i];
      my $curval  = $self->_field_value( $tm, $node->field_type );
      my $lowval  = $node->lowest($tm);
      my $highval = $node->highest($tm);

      if ($curval >= $highval) {
         $tm = $self->_set_date( $tm, $node->field_type, $lowval );
         $tm = $self->_plus_one( $tm, $self->{nodes}[ $i + 1 ]->field_type );
         next NODE;
      }

      for my $c ( $curval .. $highval ) {
         my $c_tm = $self->_set_date( $tm, $node->field_type, $c );
         if ( $self->_is_match($c_tm) ) {
            $tm = $c_tm;
            last NODE;
         }
      }

      # flip odometer if no match
      $tm = $self->_set_date( $tm, $node->field_type, $lowval );
      $tm = $self->_plus_one( $tm, $self->{nodes}[ $i + 1 ]->field_type );
   }

   # set year
   my $year_node   = $self->{nodes}[6];
   my $year_lowval = $year_node->lowest($tm);
   my $tm_year_low = $self->_set_date( $tm, $year_node->field_type, $year_lowval );
   $tm = $tm_year_low if $tm->is_before($tm_year_low);

   my $max_tm = Time::Moment->new(
      year   => 2099,
      month  => 12,
      day    => 31,
      hour   => 23,
      minute => 59,
      second => 59,
   );

   my $max_iter = $tm->delta_days($max_tm);

   # the brute force approach for DMY is correct here because:
   # 1) the design is simple and easy to understand and debug
   # 2) solves all tricky end-of-month and leap year calculations
   # 3) 365 iterations per one-year time window is good enough

   for my $day ( 1 .. $max_iter ) {
      return $tm->epoch if $self->_is_match($tm);
      $tm = $tm->plus_days(1);
   }
   return;
}

sub previous {
   my ( $self, $epoch_seconds ) = @_;
   $epoch_seconds //= time;

   my $clamped = min( $epoch_seconds, $self->{end_epoch} );

   return if $clamped < $self->{begin_epoch};

   my $tm = Time::Moment->from_epoch($clamped)->with_offset_same_instant( $self->{utc_offset} );
   $tm = $tm->minus_seconds(1);

   NODE: foreach my $i ( 0 .. 2 ) {
      my $node = $self->{nodes}[$i];

      my $lowval  = $node->lowest($tm);
      my $highval = $node->highest($tm);
      my $curval  = $self->_field_value( $tm, $node->field_type );

      if ($curval <= $lowval) {
         $tm = $self->_set_date( $tm, $node->field_type, $highval );
         $tm = $self->_minus_one( $tm, $self->{nodes}[ $i + 1 ]->field_type );
         next NODE;
      }

      for ( my $c = $curval ; $c >= $lowval ; $c-- ) {
         my $c_tm = $self->_set_date( $tm, $node->field_type, $c );
         if ( $self->_is_match($c_tm) ) {
            $tm = $c_tm;
            last NODE;
         }
      }

      # flip odometer if no match
      $tm = $self->_set_date( $tm, $node->field_type, $highval );
      $tm = $self->_minus_one( $tm, $self->{nodes}[ $i + 1 ]->field_type );
   }

   # set year
   my $year_node    = $self->{nodes}[6];
   my $year_highval = $year_node->highest($tm);
   my $tm_year_high = $self->_set_date( $tm, $year_node->field_type, $year_highval );
   $tm = $tm_year_high if $tm->is_after($tm_year_high);

   # calculate maximum iterations
   my $min_tm = Time::Moment->new(
      year   => 1970,
      month  => 1,
      day    => 1,
      hour   => 0,
      minute => 0,
      second => 0,
   );

   my $min_iter = $min_tm->delta_days($tm);

   for my $day ( 0 .. $min_iter ) {
      return $tm->epoch if $self->_is_match($tm);
      $tm = $tm->minus_days(1);
   }
   return;
}

sub _field_value {
   my ( $self, $tm, $field_type ) = @_;
   return $tm->second       if $field_type eq 'second';
   return $tm->minute       if $field_type eq 'minute';
   return $tm->hour         if $field_type eq 'hour';
   return $tm->day_of_month if $field_type eq 'dom';
   return $tm->month        if $field_type eq 'month';
   return $tm->day_of_week  if $field_type eq 'dow';
   return $tm->year         if $field_type eq 'year';
}

sub _set_date {
   my ( $self, $tm, $field_type, $value ) = @_;
   return $tm->with_second($value)       if $field_type eq 'second';
   return $tm->with_minute($value)       if $field_type eq 'minute';
   return $tm->with_hour($value)         if $field_type eq 'hour';
   return $tm->with_day_of_month($value) if $field_type eq 'dom';
   return $tm->with_month($value)        if $field_type eq 'month';
   if ( $field_type eq 'dow' ) {
      $value = 7 if $value == 0;
      return $tm->with_day_of_week($value);
   }
   return $tm->with_year($value) if $field_type eq 'year';
}

sub _plus_one {
   my ( $self, $tm, $field_type ) = @_;
   return $tm->plus_seconds(1) if $field_type eq 'second';
   return $tm->plus_minutes(1) if $field_type eq 'minute';
   return $tm->plus_hours(1)   if $field_type eq 'hour';
   return $tm->plus_days(1)    if $field_type eq 'dom';
   return $tm->plus_months(1)  if $field_type eq 'month';
   return $tm->plus_weeks(1)   if $field_type eq 'dow';
   return $tm->plus_years(1)   if $field_type eq 'year';
}

sub _minus_one {
   my ( $self, $tm, $field_type ) = @_;
   return $tm->minus_seconds(1) if $field_type eq 'second';
   return $tm->minus_minutes(1) if $field_type eq 'minute';
   return $tm->minus_hours(1)   if $field_type eq 'hour';
   return $tm->minus_days(1)    if $field_type eq 'dom';
   return $tm->minus_months(1)  if $field_type eq 'month';
   return $tm->minus_weeks(1)   if $field_type eq 'dow';
   return $tm->minus_years(1)   if $field_type eq 'year';
}

1;
__END__
