package App::loggrep;

# ABSTRACT: quickly find relevant lines in a log searching by date

$App::loggrep::VERSION //= 'dev';
use strict;
use warnings;

use Tie::File;
use Date::Parse qw(str2time);

=method new

  App::loggrep->new( $log, $opt );

Constructs an uninitialized grepper. The C<$log> file is a file name and the
C<$opt> parameter a L<Getopt::Long::Descriptive::Opts> object.

=cut

sub new {
   my ( $class, $log, $opt ) = @_;
   bless { filename => $log, options => $opt }, $class;
}

=method init

Validates all parameters and compiles regexes, returning a list of error
messages.

=cut

sub init {
   my $self = shift;
   my @errors;
   my $filename = $self->{filename};
   my @lines;
   my $opt = delete $self->{options};
   {
      unless ( defined $filename ) {
         push @errors, 'no log file provided';
         last;
      }
      unless ( -e $filename ) {
         push @errors, "file $filename does not exist";
         last;
      }
      if ( -d $filename ) {
         push @errors, "$filename is a directory";
         last;
      }
      unless ( -r $filename ) {
         push @errors, "cannot read $filename";
         last;
      }
      tie @lines, 'Tie::File', $filename or push @errors, $!;
      $self->{lines} = \@lines;
   }
   $self->{date} = _make_rx( $opt->date, \@errors, 'date' );
   my @inclusions = @{ $opt->include // [] };
   my $insensitive = $opt->case_insensitive;
   $_ = _make_rx( $_, \@errors, 'inclusion', 0, $insensitive ) for @inclusions;
   push @inclusions, _make_rx( $_, \@errors, 'inclusion', 1, $insensitive )
     for @{ $opt->include_quoted // [] };
   $self->{include} = [ sort { length($a) <=> length($b) } @inclusions ];
   my @exclusions = @{ $opt->exclude // [] };
   $_ = _make_rx( $_, \@errors, 'exclude', 0, $insensitive ) for @exclusions;
   push @exclusions, _make_rx( $_, \@errors, 'exclude', 1, $insensitive )
     for @{ $opt->exclude_quoted // [] };
   $self->{exclude} = [ sort { length($a) <=> length($b) } @exclusions ];
   my $start = $opt->start // $opt->moment;

   if ($start) {
      my $s = str2time $start;
      push @errors, "cannot parse start time: $start" unless $s;
      $self->{start} = $s;
   }
   my $end = $opt->end // $opt->moment;
   if ($end) {
      my $s = str2time $end;
      push @errors, "cannot parse end time: $end" unless $s;
      $self->{end} = $s;
   }
   push @errors, 'you are not filtering at all'
     unless @inclusions || @exclusions || $start || $end;

   $self->{blank}     = $opt->blank || defined $opt->separator;
   $self->{separator} = $opt->separator;
   $self->{warn}      = $opt->warn;
   $self->{die}       = $opt->die;
   my ( $before, $after ) = ( 0, 0 );
   if ( $opt->context || $opt->before || $opt->after ) {
      $before = $opt->context // 0;
      $before = $opt->before if $opt->before && $opt->before > $before;
      $after = $opt->context // 0;
      $after = $opt->after if $opt->after && $opt->after > $after;
   }
   @$self{qw(before after)} = ( $before, $after );

   {    # code options live in their own namespace

      package __evaled;
      for my $m ( @{ $opt->module // [] } ) {
         eval "use $_" for @{ $opt->module // [] };
         if ($@) {
            push @errors, "could not load $m";
         }
      }
      my $evaler = sub {
         my ( $orig, $option ) = shift;
         return unless $orig;
         my $majv = int $];
         my $minv = int( 1000 * ( $] - $majv ) );
         my $code =
           eval "sub { use v$majv.$minv; no strict; no warnings; $orig }";
         if ( my $e = $@ ) {
            $e =~ s/(.*?) at \(eval \d+\).*/$1/s;
            push @errors,
              sprintf 'bad option: --%s; could not evaluate "%s" as perl: %s',
              $option,
              $orig,
              $e;
         }
         return $code;
      };
      $self->{code} = $evaler->( $opt->exec, 'exec' ) // sub { shift };
      $self->{time} = $evaler->( $opt->time, 'time' );
   }

   return @errors;
}

# parse a regular expression parameter, registering any errors
sub _make_rx {
   my ( $rx, $errors, $type, $quote, $insensitive ) = @_;
   unless ($rx) {
      push @$errors, "inadequate $type pattern";
      return;
   }
   $rx = quotemeta $rx if $quote;
   eval { $rx = $insensitive ? qr/$rx/i : qr/$rx/ };
   if ($@) {
      push @$errors, "bad $type regex: $rx; error: $@";
      return;
   }
   return $rx;
}

=method grep

Perform the actual grep. Lines are printed to STDOUT.

=cut

sub grep {
   my $self = shift;
   my ( $start, $end, $lines, $include, $exclude, $date, $time ) =
     @$self{qw(start end lines include exclude date time)};
   $time //= sub { str2time $1 if shift =~ $date };
   my ( $blank, $warn, $die, $separator, $before, $after, $code ) =
     @$self{qw(blank warn die separator before after code)};
   return unless @$lines;
   my $quiet = !( $warn || $die );
   $blank ||= defined $separator;
   $separator //= "" if $blank;
   my $gd = sub {
      my $l = shift;
      my $t = $time->($l);
      return $t if $t;
      return if $quiet;
      my $msg = qq(could not find date in "$l");
      if ($warn) {
         print STDERR $msg, "\n";
         return;
      }
      print STDERR $msg, "\n";
      exit;
   };
   my @include = @$include;
   my @exclude = @$exclude;
   my ( $previous, @bbuf, $abuf );
   my $buffer = sub {
      my ( $line, $lineno ) = @_;
      if ($abuf) {
         print $code->( $line, $lineno ), "\n";
         $previous = $lineno;
         $abuf--;
      }
      elsif ($before) {
         my $pair = [ $line, $lineno ];
         push @bbuf, $pair;
         shift @bbuf if @bbuf > $before;
      }
   };
   my $printline = sub {
      my ( $line, $lineno, $match ) = @_;
      print $separator, "\n"
        if $blank && $previous && $previous + 1 < $lineno;
      $previous = $lineno;
      print $code->( $line, $lineno, $match ), "\n";
   };
   my $i = 0;
   my $time_filter = $start || $end;
   if ($time_filter) {
      my ( $t1, $t2, $j );
      for ( 0 .. $#$lines ) {
         $t1 = $gd->( $lines->[$_] );
         $j  = $_;
         last if $t1;
      }
      return unless $t1;
      for ( reverse $j .. $#$lines ) {
         $t2 = $gd->( $lines->[$_] );
         last if $t2;
      }
      $start = $t1 unless $start;
      $end   = $t2 unless $end;
      return unless $end >= $t1;
      return unless $start <= $t2;
      $i = _get_start( $lines, $start, $t1, $t2, $gd );
   }
   if ($before) {
      $i -= $before;
      $i = 0 if $i < 0;
   }
   while ( my $line = $lines->[$i] ) {
      my $lineno = $i++;
      if ($time_filter) {
         my $t = $gd->($line) // 0;
         unless ($t) {
            $buffer->( $line, $lineno );
            next;
         }
         if ( $t > $end ) {
            if ( $abuf-- ) {
               print $code->( $line, $lineno ), "\n";
               next;
            }
            else {
               last;
            }
         }
         if ( $t < $start ) {
            $buffer->( $line, $lineno );
            next;
         }
      }
      my $good = !@include;
      for (@include) {
         if ( $line =~ $_ ) {
            $good = 1;
            last;
         }
      }
      if ($good) {
         for (@exclude) {
            if ( $line =~ $_ ) {
               undef $good;
               last;
            }
         }
      }
      if ($good) {
         $printline->(@$_) for @bbuf;
         $printline->( $line, $lineno, 1 );
         splice @bbuf, 0, scalar @bbuf if $before;
         $abuf = $after;
      }
      else {
         $buffer->( $line, $lineno );
      }
   }
}

# find the log line to begin grepping at
sub _get_start {
   my ( $lines, $start, $t1, $t2, $gd ) = @_;
   return 0 if $start <= $t1;
   my $lim = $#$lines;
   my ( $s, $e ) = ( [ 0, $t1 ], [ $lim, $t2 ] );
   my ( $last, $revcount ) = ( -1, 0 );
   {
      my $i = _guess( $s, $e, $start );
      return $i if $i == $s->[0];
      my $rev = $last == $i;
      $last = $i;
      if ($rev) {    # if we find ourselves looping; bail out
         $revcount++;
         if ( $revcount > 1 ) {
            --$i if $i;
            return $i;
         }
      }
      else {
         $revcount = 0;
      }
      my $t;
      {
         $t = $gd->( $lines->[$i] );
         unless ($t) {
            $i += $rev ? -1 : 1;
            return 0 unless $i;
            return $lim if $i > $lim;
            redo;
         }
      }
      return $i if $t == $start;
      if ( $t < $start ) {
         $s = [ $i, $t ];
      }
      else {
         $e = [ $i, $t ];
      }
      if ( $s->[0] == $e->[0] ) {
         --$i if $i;
         return $i;
      }
      redo;
   }
}

# estimate the next log line to try
sub _guess {
   my ( $s, $e, $start ) = @_;
   my $delta = $start - $s->[1];
   return $s->[0] unless $delta;
   my $diff = $e->[1] - $s->[1];
   my $offset = int( ( $e->[0] - $s->[0] ) * $delta / $diff );
   return $s->[0] + $offset;
}

1;
