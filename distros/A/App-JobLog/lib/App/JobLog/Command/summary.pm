package App::JobLog::Command::summary;
$App::JobLog::Command::summary::VERSION = '1.042';
# ABSTRACT: show what you did during a particular period

use App::JobLog -command;
use Modern::Perl;
use Class::Autouse qw(
  App::JobLog::Log
  App::JobLog::Log::Day
);
use autouse 'App::JobLog::TimeGrammar'  => qw(parse daytime);
use autouse 'Carp'                      => qw(carp);
use autouse 'Getopt::Long::Descriptive' => qw(prog_name);
use autouse 'App::JobLog::Config'       => qw(
  columns
  is_hidden
  merge
);
use autouse 'App::JobLog::Log::Format' => qw(
  display
  single_interval
  summary
);
use autouse 'App::JobLog::Log::Synopsis' => qw(
  MERGE_ALL
  MERGE_ADJACENT
  MERGE_ADJACENT_SAME_TAGS
  MERGE_SAME_TAGS
  MERGE_SAME_DAY
  MERGE_SAME_DAY_SAME_TAGS
  MERGE_NONE
);
use autouse 'App::JobLog::Time' => qw(today);
no if $] >= 5.018, warnings => "experimental::smartmatch";

sub execute {
   my ( $self, $opt, $args ) = @_;

   my $tags          = $opt->{tag}         || [];
   my $excluded_tags = $opt->{exclude_tag} || [];
   my $match         = $opt->{match}       || [];
   my $no_match      = $opt->{no_match}    || [];
   my $time_expr = join( ' ', @$args ) || $opt->{date};
   my $time = $opt->{time};

   $time_expr ||= $opt->{date};

   # validate regexes, if any, while generating test

 # NOTE: using $opt->{x} form rather than $opt->x to facilitate invoking summary
 # from today command

   my $test = _make_test( $tags, $excluded_tags, $match, $no_match, $time );
   my $merge_level;
   for ( $opt->{merge} || '' ) {
      when ('no_merge') {
         $merge_level = MERGE_NONE
      }
      when ('merge_all') {
         $merge_level = MERGE_ALL
      }
      when ('merge_adjacent') {
         $merge_level = MERGE_ADJACENT
      }
      when ('merge_adjacent_same_tags') {
         $merge_level = MERGE_ADJACENT_SAME_TAGS
      }
      when ('merge_same_tags') {
         $merge_level = MERGE_SAME_TAGS
      }
      when ('merge_same_day') {
         $merge_level = MERGE_SAME_DAY
      }
      when ('merge_same_day_same_tags') {
         $merge_level = MERGE_SAME_DAY_SAME_TAGS
      }
      default {

         # some dark wizardry here
         my $m = uc merge;
         $m =~ s/ /_/g;
         $m           = \&{"MERGE_$m"};
         $merge_level = &$m;
      }
   }
   my $dateless = $merge_level == MERGE_ALL || $merge_level == MERGE_SAME_TAGS;
   if (
         $opt->{no_totals}
      && ( $dateless || $opt->{no_date} || is_hidden('date') )
      && (  !single_interval($merge_level)
         || $opt->{no_time}
         || is_hidden('time') )
      && ( $opt->{no_duration}    || is_hidden('duration') )
      && ( $opt->{no_tags}        || is_hidden('tags') )
      && ( $opt->{no_description} || is_hidden('description') )
     )
   {
      $self->usage_error('you have chosen not to display anything');
   }

   # record hiding options in hash reference
   my $hidden = {
      vacation => $opt->{no_vacation} || $opt->{notes},
      date => $dateless || $opt->{no_date} || is_hidden('date'),
      time => $opt->{no_time} || is_hidden('time'),
      duration => $opt->{notes} || $opt->{no_duration} || is_hidden('duration'),
      tags        => $opt->{no_tags}        || is_hidden('tags'),
      description => $opt->{no_description} || is_hidden('description'),
      totals      => $opt->{notes}          || $opt->{no_totals},
   };

   # parse time expression
   my ( $days, $show_year );
   eval {
      ( $days, $show_year ) = summary $time_expr, $test, $hidden, $opt->{notes};
   };
   $self->usage_error($@) if $@;
   unless ( $opt->{hidden} ) {

      # figure out how wide to make things
      my $screen_width;
      if ( $opt->{wrap} ) {
         if ( $opt->{no_wrap} ) {
            $screen_width = -1;
         }
         else {
            $screen_width = $opt->columns;
         }
      }
      else {
         $screen_width = columns;
      }
      if ($dateless) {

         # create "day" containing all events
         my $duck_day = App::JobLog::Log::Day->new(
            start   => $days->[0]->start->clone,
            end     => $days->[$#$days]->end->clone,
            no_date => 1,
         );
         for my $d (@$days) {
            push @{ $duck_day->events },   @{ $d->events };
            push @{ $duck_day->vacation }, @{ $d->vacation };
         }
         display [$duck_day], $merge_level, $hidden, $screen_width;
      }
      else {
         display $days, $merge_level, $hidden, $screen_width, $show_year;
      }

      # check for long task
      my ($last_e) = App::JobLog::Log->new->last_event;
      if ( $last_e && $last_e->is_open ) {
         my ( $then, $today ) = ( $last_e->start, today );
         if (
            !(
                  $then->year == $today->year
               && $then->month == $today->month
               && $then->day == $today->day
            )
           )
         {
            print <<END;

WARNING! The last event in the log has been open since before 12:00 am today!

END
         }
      }
   }
}

# Construct a test from the tags, excluded-tags, match, no-match, and time options.
# The test determines what portion of what events are included in synopses.
sub _make_test {
   my ( $tags, $excluded_tags, $match, $no_match, $time ) = @_;

   my %tags          = map { $_ => 1 } @$tags;
   my %excluded_tags = map { $_ => 1 } @$excluded_tags;
   my @no_match = map { _re_test($_); qr/$_/ } @$no_match;
   my @match    = map { _re_test($_); qr/$_/ } @$match;
   $time = _parse_time($time);
   return unless %tags || %excluded_tags || @no_match || @match || $time;

   my $test = sub {
      my ($e) = @_;
      if ( %tags || %excluded_tags ) {
         my $good = !%tags;
         for my $t ( @{ $e->tags } ) {
            return if $excluded_tags{$t};
            $good ||= $tags{$t};
         }
         return unless $good;
      }
      if ( @no_match || @match ) {
         my $good = !@match;
         for my $d ( @{ $e->data->description } ) {
            for my $re (@no_match) {
               return if $d =~ $re;
            }
            unless ($good) {
               for my $re (@match) {
                  $good = $d =~ $re;
                  last if $good;
               }
            }
         }
         return unless $good;
      }
      if ($time) {
         my $start = $e->start->clone->set( %{ $time->{start} } );
         my $end   = $e->end->clone->set( %{ $time->{end} } );
         return $e->overlap( $start, $end );
      }
      return $e;
   };
   return $test;
}

# look for regular expressions with side effects
sub _re_test {
   carp 'regex ' . $_[0] . '" appears to contain executable code'
     if $_[0] =~ /\(\?{1,2}{/;
}

# parse time expressions
our ( $b1, $b2 );
my $time_re = qr/
  ^ \s*+ (?&start) (?&end) \s*+ $
  (?(DEFINE)
    (?<start> (?&ba) | (?&time) )
    (?<ba> (?:(?&before)|(?&after)) \s*+)
    (?<before> (?: b(?:e(?:f(?:o(?:r(?:e)?)?)?)?)? | < ) (?{$b1 = 'before'}))
    (?<after> (?: a(?:f(?:t(?:e(?:r)?)?)?)? | > ) (?{$b1 = 'after'}))
    (?<time> (.*?) \s*+ - \s*+ (?{$b1 = $^N}))
    (?<end> (\S.*) (?{$b2 = $^N}))
  ) 
/xi;

sub _parse_time {
   my ($time) = @_;
   local ( $b1, $b2 );
   return unless $time;
   if ( $time =~ $time_re ) {
      my ( $t1, $t2 );
      for ($b1) {
         when ('before') {
            $t1 = {
               hour   => 0,
               minute => 0,
               second => 0
            };
            $t2 = { daytime $b2 };
         }
         when ('after') {
            $t1 = { daytime $b2 };
            $t2 = {
               hour   => 23,
               minute => 59,
               second => 59
            };
         }
         default {
            $t1 = { daytime $b1 };
            $t2 = { daytime $b2 };
         }
      }
      if (  $t2->{hour} < $t1->{hour}
         || $t2->{minute} < $t1->{minute}
         || $t2->{second} < $t1->{second} )
      {
         if ( $t2->{suffix} && $t2->{suffix} eq 'x' ) {
            $t2->{hour} += 12;
         }
         else {
            carp '"' . $time
              . '" invalid time expression: endpoints out of order';
         }
      }
      delete $t1->{suffix}, delete $t2->{suffix};
      return { start => $t1, end => $t2 };
   }
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o [<date or date range>]' }

sub abstract {
   'list tasks with certain properties in a particular time range';
}

sub full_description {
   <<END
List events or notes with certain properties in a particular time range. Only the notes or
portions of events falling within the range will be listed.

Events and notes may be filtered in numerous ways: by tag, time of day, or terms used in descriptions.
If tags to match are provided, only those items that contain at least one such tag will be shown. If
tags not to match are provided, only those items that contain none of these tags will be shown.

If you provide description filters to match or avoid, these will be interpreted as regexes. Try 'perldoc perlre'
for more details, or perhaps 'perldoc perlretut' (these will only work if you have the Perl documentation
installed on your machine). If you don't want to worry about regular expressions, simple strings will work.
Prefix your expression with '(?i)' to turn off case sensitivity. And don't enclose regexes in slashes or any other
sort of delimiter. Use 'ab', not '/ab/' or 'm!ab!', etc. Finally, you may need to enclose your regexes in quotes
to prevent the shell from trying to interpret them.

Time subranges may be of the form '11-12pm', '1am-12:30:15', 'before 2', 'after 6:12pm', etc. Either 'before'
or 'after' (or some prefix of these such as 'bef' or 'aft') may be followed by a time or you may use two time
expressions separated by a dash. The code will attempt to infer the precise time of ambiguous time expressions,
but it's best to be explicit. Case is ignored. Whitespace is optional in the expected places.

Note that any filtering of events specifying particular times for the start and end of the period in question,
e.g., "yesterday at 8:00 am until today", will cause all flex time vacation to be ignored. This is because, given
the flexible nature of this vacation, it is unclear how much should be accounted for when filtering events. Since
notes are not "on the clock", no consideration of vacation periods is used in filtering them.

@{[__PACKAGE__->name]} provides many ways to consolidate events and notes. These are the "merge" options
By default items are grouped into days and within days into subgroups of adjacent items with the same tags.
All the merge options that require adjacency will also group by days but not vice versa. 
END
}

sub options {
   return (
      [
             "Use '@{[prog_name]} help "
           . __PACKAGE__->name
           . '\' to see full details.'
      ],
      [],
      [
         'date|d=s',
         'provide the time expression as an option instead of an argument'
      ],
      [ 'notes|n', 'show notes instead of events' ],
      [
         'tag|t=s@',
         'filter events/notes to include only those with given tags; '
           . 'multiple tags may be specified'
      ],
      [
         'exclude-tag|T=s@',
         'filter events/notes to exclude those with given tags; '
           . 'multiple tags may be specified'
      ],
      [
         'match|m=s@',
'filter events/notes to include only those one of whose descriptions matches the given regex; '
           . 'multiple regexes may be specified'
      ],
      [
         'no-match|M=s@',
'filter events/notes to include only those one of whose descriptions do not match the given regex; '
           . 'multiple regexes may be specified'
      ],
      [
         'time|i=s',
'consider only those portions of events/notes that overlap the given time range'
      ],
      [
         "merge" => hidden => {
            one_of => [
               [
                  "merge-all|mall|ma" =>
                    "glom all events/notes into one synopsis"
               ],
               [ "merge-adjacent|madj" => "merge contiguous events" ],
               [
                  "merge-adjacent-same-tags|mast" =>
"merge contiguous, identically-tagged events/notes (default)"
               ],
               [
                  "merge-same-tags|mst" =>
                    "merge all identically tagged events/notes"
               ],
               [
                  "merge-same-day|msd" =>
                    "merge all events/notes in a given day"
               ],
               [
                  "merge-same-day-same-tags|msdst" =>
                    "merge all events/notes in a given day"
               ],
               [ "no-merge|nm" => "keep all events/notes separate" ],
            ]
         }
      ],
      [ 'no-vacation|V', 'do not display vacation hours' ],
      [ 'no-date',       'do not display a date before each distinct day' ],
      [
         'no-time',
         'do not display event or note start times and event end times'
      ],
      [ 'no-duration',    'do not display event durations' ],
      [ 'no-tags',        'do not display tags' ],
      [ 'no-description', 'do not display event/note descriptions' ],
      [
         'no-totals',
         'do not display the footer containing total hours worked, etc.'
      ],
      [
         'wrap' => 'hidden' => {
            one_of => [
               [
                  'columns|c=i',
'limit the width of the report to the specified number of columns; '
                    . ' by default the width of the terminal is automatically detected and, if that fails, a width of 76 is used'
               ],
               [ 'no-wrap|W', 'do not wrap the text to fit columns' ],
            ]
         }
      ],
      [ 'hidden', 'display nothing', { hidden => 1 } ],
   );
}

sub validate {
   my ( $self, $opt, $args ) = @_;

   $self->usage_error('no time expression provided')
     unless @$args || $opt->date;
   $self->usage_error('two time expression provided') if @$args && $opt->date;
   $self->usage_error('columns must be positive')
     if defined $opt->{columns} && $opt->columns < 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::summary - show what you did during a particular period

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job summary --help
 job <command>
 
 job summary [-cdiMmnTtVW] [long options...] [<date or date range>]
     Use 'job help summary' to see full details.
                                        
     -d STR --date STR                    provide the time expression as
                                          an option instead of an argument
     -n --notes                           show notes instead of events
     -t STR... --tag STR...               filter events/notes to include
                                          only those with given tags;
                                          multiple tags may be specified
     -T STR... --exclude-tag STR...       filter events/notes to exclude
                                          those with given tags; multiple
                                          tags may be specified
     -m STR... --match STR...             filter events/notes to include
                                          only those one of whose
                                          descriptions matches the given
                                          regex; multiple regexes may be
                                          specified
     -M STR... --no-match STR...          filter events/notes to include
                                          only those one of whose
                                          descriptions do not match the
                                          given regex; multiple regexes
                                          may be specified
     -i STR --time STR                    consider only those portions of
                                          events/notes that overlap the
                                          given time range
     --ma --mall --merge-all              glom all events/notes into one
                                          synopsis
     --madj --merge-adjacent              merge contiguous events
     --mast --merge-adjacent-same-tags    merge contiguous,
                                          identically-tagged events/notes
                                          (default)
     --mst --merge-same-tags              merge all identically tagged
                                          events/notes
     --msd --merge-same-day               merge all events/notes in a
                                          given day
     --msdst --merge-same-day-same-tags   merge all events/notes in a
                                          given day
     --nm --no-merge                      keep all events/notes separate
     -V --no-vacation                     do not display vacation hours
     --no-date                            do not display a date before
                                          each distinct day
     --no-time                            do not display event or note
                                          start times and event end times
     --no-duration                        do not display event durations
     --no-tags                            do not display tags
     --no-description                     do not display event/note
                                          descriptions
     --no-totals                          do not display the footer
                                          containing total hours worked,
                                          etc.
     -c INT --columns INT                 limit the width of the report to
                                          the specified number of columns;
                                           by default the width of the
                                          terminal is automatically
                                          detected and, if that fails, a
                                          width of 76 is used
     -W --no-wrap                         do not wrap the text to fit
                                          columns
     --help                               this usage screen
 houghton@NorthernSpy:~$ job s this week
 Sunday,  6 March, 2011
      7:36 - 7:37 pm  0.01  bar, foo  something to add; and still more                                                                                                  
 
 Monday,  7 March
   8:01 am - ongoing  1.05  bar, foo  something to add; and still more                                                                                                  
 
   TOTAL HOURS 1.07
   bar         1.07
   foo         1.07
 houghton@NorthernSpy:~$ job s --notes this week
 Monday,  6 February
   1:32 - 1:33 pm         giving this thing a test run; maybe the second note will be faster                                                     
   2:08 - 4:31 pm  foo    testing out note tagging; another note that should have the same tag; taking a note                                    
   4:32 - 4:33 pm  money  taking a note about money; taking another note that will be tagged with money                                          
          4:33 pm         taking a note without any tags                                                                                         
 
 houghton@NorthernSpy:~$ job s this month
 Tuesday,  1 March, 2011
      8:00 - 9:23 am  1.39  widgets   adding handling of simplified pdf docs                                                                                            
 
 Friday,  4 March
      1:48 - 2:55 pm  1.11  widgets   trying to get Eclipse working properly again                                                                                      
      3:50 - 5:30 pm  1.66  widgets   figuring out why some files are really, really slow                                                                               
 
 Sunday,  6 March
      7:36 - 7:37 pm  0.01  bar, foo  something to add; and still more                                                                                                  
 
 Monday,  7 March
   8:01 am - ongoing  1.05  bar, foo  something to add; and still more                                                                                                  
 
   TOTAL HOURS 5.23
   bar         1.07
   foo         1.07
   widgets     4.16
 houghton@NorthernSpy:~$ job s 2011/3/1
 Tuesday,  1 March, 2011
   8:00 - 9:23 am  1.39  widgets  adding handling of simplified pdf docs                                                                                            
 
   TOTAL HOURS 1.39
   widgets     1.39
 houghton@NorthernSpy:~$ job s Friday through today
 Friday,  4 March, 2011
      1:48 - 2:55 pm  1.11  widgets   trying to get Eclipse working properly again                                                                                      
      3:50 - 5:30 pm  1.66  widgets   figuring out why some files are really, really slow                                                                               
 
 Sunday,  6 March
      7:36 - 7:37 pm  0.01  bar, foo  something to add; and still more                                                                                                  
 
 Monday,  7 March
   8:01 am - ongoing  1.06  bar, foo  something to add; and still more                                                                                                  
 
   TOTAL HOURS 3.84
   bar         1.07
   foo         1.07
   widgets     2.77
 houghton@NorthernSpy:~$ job s --merge-same-tags Friday through today
   2.77  widgets   trying to get Eclipse working properly again; figuring out why some files are really, really slow                                   
   1.07  bar, foo  something to add; and still more                                                                                                    
 
   TOTAL HOURS 3.85
   bar         1.07
   foo         1.07
   widgets     2.77

=head1 DESCRIPTION

B<App::JobLog::Command::summary> is the command that extracts pretty reports from the log. Its options are all
concerned with filtering events and formatting the report. The report must be either a report of tasks or a
report of notes.

=head1 SEE ALSO

L<App::JobLog::Command::today>, L<App::JobLog::Command::last>, L<App::JobLog::Command::parse>, L<App::JobLog::Command::tags>, L<App::JobLog::TimeGrammar>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
