package App::JobLog::Log;
$App::JobLog::Log::VERSION = '1.042';
# ABSTRACT: the code that lets us interact with the log


use Modern::Perl;
use App::JobLog::Config qw(log init_file);
use App::JobLog::Log::Line;
use IO::All -utf8;
use autouse 'Carp'              => qw(carp);
use autouse 'App::JobLog::Time' => qw(now);
use Class::Autouse qw(
  App::JobLog::Log::Event
  App::JobLog::Log::Note
  DateTime
  FileHandle
);
no if $] >= 5.018, warnings => "experimental::smartmatch";

# some stuff useful for searching log
use constant WINDOW   => 30;
use constant LOW_LIM  => 1 / 10;
use constant HIGH_LIM => 1 - LOW_LIM;

# some indices
use constant IO          => 0;
use constant FIRST_EVENT => 1;
use constant LAST_EVENT  => 2;
use constant FIRST_INDEX => 3;
use constant LAST_INDEX  => 4;

# timestamp format
use constant TS => '%Y/%m/%d';


sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    # touch log into existence
    unless ( -e log ) {
        init_file log;
        my $fh = FileHandle->new( log, 'w' );
        $fh->close;
    }

    # using an array to make things a little snappier
    my $self = bless [], $class;
    $self->[IO] = io log;
    return $self;
}


sub lines {
  [ shift->[IO]->getlines ];
}


sub all_taglines {
    my ($self) = @_;

    # reopen log in sequential reading mode
    $self->[IO] = io log;
    my (@lines);
    while ( my $line = $self->[IO]->getline ) {
        my $ll = App::JobLog::Log::Line->parse($line);
        push @lines, $ll if $ll->is_beginning;
    }
    return \@lines;
}


sub all_events {
    my ($self) = @_;

    # reopen log in sequential reading mode
    $self->[IO] = io log;
    my ( @events, $previous );
    while ( my $line = $self->[IO]->getline ) {
        my $ll = App::JobLog::Log::Line->parse($line);
        if ( $ll->is_endpoint ) {
            $previous->end = $ll->time if $previous;
            if ( $ll->is_beginning ) {
                $previous = App::JobLog::Log::Event->new($ll);
                push @events, $previous;
            }
            else {
                $previous = undef;
            }
        }
    }
    return \@events;
}


sub all_notes {
    my ($self) = @_;

    # reopen log in sequential reading mode
    $self->[IO] = io log;
    my @notes;
    while ( my $line = $self->[IO]->getline ) {
        my $ll = App::JobLog::Log::Line->parse($line);
        push @notes, App::JobLog::Log::Note->new($ll) if $ll->is_note;
    }
    return \@notes;
}


sub validate {
    my ($self) = @_;
    my ( $i, $previous_event ) = (0);
    my $errors = 0;
    while ( my $line = $self->[IO][$i] ) {
        my $ll = App::JobLog::Log::Line->parse($line);
        if ( $ll->is_malformed ) {
            $errors++;
            print STDERR "line $i -- '$line' -- is malformed; commenting out\n";
            splice @{ $self->[IO] }, $i, 0,
              App::JobLog::Log::Line->new( comment => 'ERROR; malformed line' );
            $self->[IO][ ++$i ] = $ll->comment_out;
        }
        elsif ( $ll->is_event ) {
            if ($previous_event) {
                if ( DateTime->compare( $previous_event->time, $ll->time ) > 0 )
                {
                    $errors++;
                    print STDERR
"line $i -- '$line' -- is out of order relative to the last event; commenting out\n";
                    splice @{ $self->[IO] }, $i, 0,
                      App::JobLog::Log::Line->new(
                        comment => 'ERROR; dates out of order' );
                    $self->[IO][ ++$i ] = $ll->comment_out;
                }
                elsif ( $previous_event->is_end && $ll->is_end ) {
                    $errors++;
                    print STDERR
"line $i -- '$line' -- specifies the end of a task not yet begun; commenting out\n";
                    splice @{ $self->[IO] }, $i, 0,
                      App::JobLog::Log::Line->new( comment =>
                          'ERROR; task end without corresponding beginning' );
                    $self->[IO][ ++$i ] = $ll->comment_out;
                }
                else {
                    $previous_event = $ll;
                }
            }
            elsif ( $ll->is_end ) {
                $errors++;
                print STDERR
"line $i -- '$line' -- specifies the end of a task not yet begun; commenting out\n";
                splice @{ $self->[IO] }, $i, 0,
                  App::JobLog::Log::Line->new( comment =>
                      'ERROR; task end without corresponding beginning' );
                $self->[IO][ ++$i ] = $ll->comment_out;
            }
            else {
                $previous_event = $ll;
            }
        }
        $i++;
    }
    return $errors;
}


sub first_event {
    my ($self) = @_;
    return $self->[FIRST_EVENT], $self->[FIRST_INDEX] if $self->[FIRST_EVENT];
    my $io = $self->[IO];
    my ( $i, $e ) = 0;
    while ( $i <= $#$io ) {
        my $line = $io->[$i];
        my $ll   = App::JobLog::Log::Line->parse($line);
        if ( $ll->is_endpoint ) {
            if ($e) {
                $e->end = $ll->time;
                last;
            }
            else {
                $e = App::JobLog::Log::Event->new($ll);
                $self->[FIRST_INDEX] = $i;
            }
        }
        $i++;
    }
    $self->[FIRST_EVENT] = $e;
    return $e, $self->[FIRST_INDEX];
}


sub last_ts {
    my ($self) = @_;
    my $io     = $self->[IO];
    my $i      = $#$io;
    for ( ; $i >= 0 ; $i-- ) {
        my $ll = App::JobLog::Log::Line->parse( $io->[$i] );
        return ( $ll->time, $i ) if $ll->is_event;
    }
    return;
}


sub first_ts {
    my ($self) = @_;
    my $io     = $self->[IO];
    my $i      = 0;
    for ( my $lim = $#$io ; $i <= $lim ; $i++ ) {
        my $ll = App::JobLog::Log::Line->parse( $io->[$i] );
        return ( $ll->time, $i ) if $ll->is_event;
    }
    return;
}


sub last_event {
    my ($self) = @_;
    return $self->[LAST_EVENT], $self->[LAST_INDEX] if $self->[LAST_EVENT];
    my $io = $self->[IO];

    # was hoping to use IO::All::backwards for this, but seems to be broken
    # uncertain how to handle utf8 issue with File::ReadBackwards
    my @lines;
    my $i = $#$io;
    for ( ; $i >= 0 ; $i-- ) {
        my $line = $self->[IO][$i];
        my $ll   = App::JobLog::Log::Line->parse($line);
        if ( $ll->is_endpoint ) {
            push @lines, $ll;
            last if $ll->is_beginning;
        }
    }
    return () unless @lines;
    my $e = App::JobLog::Log::Event->new( pop @lines );
    $e->end = $lines[0]->time if @lines;
    $self->[LAST_EVENT] = $e;
    $self->[LAST_INDEX] = $i;
    return $e, $i;
}


sub last_note {
    my ($self) = @_;
    my $io = $self->[IO];
    for ( my $i = $#$io ; $i >= 0 ; $i-- ) {
        my $line = $io->[$i];
        my $ll   = App::JobLog::Log::Line->parse($line);
        return ( App::JobLog::Log::Note->new($ll), $i ) if $ll->is_note;
    }
    return ();
}


sub reverse_iterator {
    my ( $self, $event ) = @_;
    if ( ref $event ) {
        if ( $event->isa('DateTime') ) {
            my $events =
              $self->find_events( $event, $self->first_event->start );
            if (@$events) {
                $event = $events->[$#$events];
            }
            else {
                $event = undef;
            }
        }
    }
    else {
        ($event) = $self->last_event;
    }
    return sub { }
      unless $event;
    my ( undef, $index, $io ) =
      ( $self->find_previous( $event->start ), $self->[IO] );
    return sub {
        return () unless $event;
        my $e        = $event;
        my $end_time = $event->start;
        $event = undef;
        while ( --$index >= 0 ) {
            my $line = $io->[$index];
            my $ll   = App::JobLog::Log::Line->parse($line);
            if ( $ll->is_beginning ) {
                $event = App::JobLog::Log::Event->new($ll);
                $event->end = $end_time;
                last;
            }
            elsif ( $ll->is_end ) {
                $end_time = $ll->time;
            }
        }
        return $e;
    };
}


sub find_events {
    my ( $self, $start, $end ) = @_;
    my $io = $self->[IO];
    my ( $end_event, $bottom, $start_event, $top ) =
      ( $self->last_event, $self->first_event );

    # if the log is empty, return empty list
    return [] unless $start_event && $end_event;

    # if the log concerns events before the time in question, return empty list
    return []
      unless $end_event->is_open
          || DateTime->compare( $start, $end_event->end ) < 0;

    # likewise if it concerns events after
    return [] if DateTime->compare( $start_event->start, $end ) > 0;

    # narrow time range to that in log
    my $c1 = DateTime->compare( $start, $start_event->start ) <= 0;
    my $c2 =
      $end_event->is_open
      ? DateTime->compare( $end, $end_event->start ) >= 0
      : DateTime->compare( $end, $end_event->end ) >= 0;
    return $self->all_events if $c1 && $c2;
    $start = $start_event->start if $c1;
    $end   = $end_event->end     if $c2;

    # matters are simple if what we want is at the start of the log
    if ($c1) {
        my ( $line, $previous, @events );
        while ( my $line = $io->getline ) {
            chomp $line;
            my $ll = App::JobLog::Log::Line->parse($line);
            if ( $ll->is_endpoint ) {
                if ( DateTime->compare( $ll->time, $end ) >= 0 ) {
                    $previous->end = $end if $previous->is_open;
                    last;
                }
                if ( $previous && $previous->is_open ) {
                    $previous->end = $ll->time;
                }
                if ( $ll->is_beginning ) {
                    $previous = App::JobLog::Log::Event->new($ll);
                    push @events, $previous;
                }
            }
        }
        return \@events;
    }

    # matters are likewise simple if what we want is at the end of the log
    if ($c2) {

        # must restart io
        $io = $self->[IO] = io log;
        $io->backwards;
        my ( $line, $previous, @events );
        while ( my $line = $io->getline ) {
            chomp $line;
            my $ll = App::JobLog::Log::Line->parse($line);
            if ( $ll->is_endpoint ) {
                my $e;
                if ( $ll->is_beginning ) {
                    $e = App::JobLog::Log::Event->new($ll);
                    $e->end = $previous->time if $previous;
                    unshift @events, $e;
                }
                if ( DateTime->compare( $ll->time, $start ) <= 0 ) {
                    $e->start = $start if $e;
                    last;
                }
                $previous = $ll;
            }
        }
        return \@events;
    }

    # otherwise, do binary search for first event in range
    my ( undef, $i ) = $self->find_previous($start);
    return $self->_scan_from( $i, $start, $end );
}


sub find_notes {
    my ( $self, $start, $end ) = @_;
    my $io = $self->[IO];
    my ( $end_time, $bottom, $start_time, $top ) =
      ( $self->last_ts, $self->first_ts );

    # if the log is empty, return empty list
    return [] unless $start_time && $end_time;

    # if the log concerns events before the time in question, return empty list
    return []
      unless DateTime->compare( $start, $end_time ) <= 0;

    # likewise if it concerns events after
    return [] if DateTime->compare( $start_time, $end ) > 0;

    # narrow time range to that in log
    my $c1 = DateTime->compare( $start, $start_time ) <= 0;
    my $c2 = DateTime->compare( $end,   $end_time ) >= 0;
    return $self->all_notes if $c1 && $c2;
    $start = $start_time if $c1;
    $end   = $end_time   if $c2;

    # matters are simple if what we want is at the start of the log
    if ($c1) {
        my ( $line, @notes );
        while ( my $line = $io->getline ) {
            chomp $line;
            my $ll = App::JobLog::Log::Line->parse($line);
            if ( $ll->is_event ) {
                if ( DateTime->compare( $ll->time, $end ) >= 0 ) {
                    last;
                }
                push @notes, App::JobLog::Log::Note->new($ll) if $ll->is_note;
            }
        }
        return \@notes;
    }

    # matters are likewise simple if what we want is at the end of the log
    if ($c2) {

        # must restart io
        $io = $self->[IO] = io log;
        $io->backwards;
        my ( $line, @notes );
        while ( my $line = $io->getline ) {
            chomp $line;
            my $ll = App::JobLog::Log::Line->parse($line);
            if ( $ll->is_event ) {
                $c2 = DateTime->compare( $ll->time, $start );
                last if $c2 < 0;
                unshift @notes, App::JobLog::Log::Note->new($ll)
                  if $ll->is_note;
                last unless $c2;
            }
        }
        return \@notes;
    }

    # otherwise, do binary search for first note in range
    my $i =
      $self->_find_previous_note( $start, $end_time, $bottom, $start_time,
        $top );
    return [] unless defined $i;
    return $self->_scan_for_note_from( $i, $start, $end );
}


sub find_previous {
    my ( $self, $e ) = @_;
    my $io = $self->[IO];
    my ( $end_event, $bottom, $start_event, $top ) =
      ( $self->last_event, $self->first_event );

    # if the log is empty, return empty list
    return () unless $start_event && $end_event;

    # if the start time (improbably but fortuitously) happens to be what we're
    # looking for, return it
    return ( $start_event, $top )
      if DateTime->compare( $start_event->start, $e ) == 0;

    # likewise for the end time
    return ( $end_event, $bottom ) if $end_event->start < $e;

    # return the empty list if the event in question precede the first
    # event in the log
    return () unless $start_event->start < $e;

    # otherwise, do binary search for first event in range
    my ( $et, $eb ) = ( $start_event->start, $end_event->start );
    my $previous_index;
  OUTER: while (1) {
        return $self->_scan_for_previous( $top, $e )
          if $bottom - $top + 1 <= WINDOW / 2;
        my $index = _estimate_index( $top, $bottom, $et, $eb, $e );
        if ( defined $previous_index && $previous_index == $index ) {

            # search was too clever by half; we've entered an infinite loop
            return $self->_scan_for_previous( $top, $e );
        }
        $previous_index = $index;
        my $event;
        for my $i ( $index .. $#$io ) {
            my $line = $io->[$i];
            my $ll   = App::JobLog::Log::Line->parse($line);
            if ( $ll->is_beginning ) {
                my $do_next = 1;
                for ( DateTime->compare( $ll->time, $e ) ) {
                    when ( $_ < 0 ) {
                        $top = $i;
                        $et  = $ll->time;
                    }
                    when ( $_ > 0 ) {
                        $bottom = $i;
                        $eb     = $ll->time;
                    }
                    default {

                        # found beginning!!
                        # this should happen essentially never
                        $do_next = 0;
                    }
                }
                next OUTER if $do_next;
                return $self->_scan_for_previous( $i, $e );
            }
        }
    }
}


sub _find_previous_note {
    my ( $self, $e, $eb, $bottom, $et, $top ) = @_;
    my $io = $self->[IO];

    # binary search for first note in range
    my $previous_index;
  OUTER: while (1) {
        return $self->_scan_for_previous_note( $top, $e )
          if $bottom - $top + 1 <= WINDOW / 2;
        my $index = _estimate_index( $top, $bottom, $et, $eb, $e );
        if ( defined $previous_index && $previous_index == $index ) {

            # search was too clever by half; we've entered an infinite loop
            return $self->_scan_for_previous_note( $top, $e );
        }
        $previous_index = $index;
        my $event;
        for my $i ( $index .. $#$io ) {
            my $line = $io->[$i];
            my $ll   = App::JobLog::Log::Line->parse($line);
            if ( $ll->is_event ) {
                for ( DateTime->compare( $ll->time, $e ) ) {
                    when ( $_ < 0 ) {
                        $top = $i;
                        $et  = $ll->time;
                        next OUTER;
                    }
                    when ( $_ > 0 ) {
                        $bottom = $i;
                        $eb     = $ll->time;
                        next OUTER;
                    }
                    default {

                        # found beginning!!
                        # this should happen essentially never
                        return $self->_scan_for_previous_note( $i, $e );
                    }
                }
            }
        }
    }
}

# now that we're close to the section of the log we want, we
# scan it sequentially
sub _scan_from {
    my ( $self, $i, $start, $end ) = @_;
    my $io = $self->[IO];

    # collect events
    my ( $previous, @events );
    for my $index ( $i .. $#$io ) {
        my $line = $io->[$index];
        my $ll   = App::JobLog::Log::Line->parse($line);
        if ( $ll->is_endpoint ) {
            if ($previous) {
                $previous->end = $ll->time if $previous->is_open;
                push @events, $previous
                  if DateTime->compare( $start, $previous->end ) < 0;
            }
            if ( $ll->is_beginning ) {
                last if DateTime->compare( $ll->time, $end ) >= 0;
                $previous = App::JobLog::Log::Event->new($ll);
            }
            else {
                $previous = undef;
            }
        }
    }
    push @events, $previous
      if $previous
          && $previous->is_open
          && DateTime->compare( $previous->start, $end ) < 0;

    # return only overlap
    my @return = map { $_->overlap( $start, $end ) } @events;
    return \@return;
}

sub _scan_for_note_from {
    my ( $self, $i, $start, $end ) = @_;
    my $io = $self->[IO];

    # collect notes
    my @notes;
    for my $index ( $i .. $#$io ) {
        my $line = $io->[$index];
        my $ll   = App::JobLog::Log::Line->parse($line);
        if ( $ll->is_event ) {
            last if $ll->time > $end;
            if ( $ll->is_note && $ll->time >= $start ) {
                push @notes, App::JobLog::Log::Note->new($ll);
            }
        }
    }
    return \@notes;
}

sub _scan_for_previous {
    my ( $self, $i, $e ) = @_;
    my $io = $self->[IO];

    # collect events
    my ( $previous, $previous_index );
  OUTER: {
        for my $index ( $i .. $#$io ) {
            my $line = $io->[$index];
            my $ll   = App::JobLog::Log::Line->parse($line);
            if ( $ll->is_endpoint ) {
                $previous->end = $ll->time if $previous && $previous->is_open;
                if ( $ll->time > $e ) {
                    last if $previous;
                    $i--;
                    redo OUTER;
                }
                if ( $ll->is_beginning ) {
                    $previous       = App::JobLog::Log::Event->new($ll);
                    $previous_index = $index;
                }
            }
        }
    }
    return $previous, $previous_index;
}

sub _scan_for_previous_note {
    my ( $self, $i, $e ) = @_;
    my $io = $self->[IO];

    # collect events
    my ( $previous, $previous_index );
    for my $index ( $i .. $#$io ) {
        my $line = $io->[$index];
        my $ll   = App::JobLog::Log::Line->parse($line);
        if ( $ll->is_event ) {
            last if $ll->time > $e;
            if ( $ll->is_note ) {
                $previous       = App::JobLog::Log::Note->new($ll);
                $previous_index = $index;
            }
        }
    }
    return $previous_index // $i;
}

# your generic O(log_n) complexity bisecting search
sub _estimate_index {
    my ( $top, $bottom, $et, $eb, $s ) = @_;
    my $delta = $bottom - $top + 1;
    my $i;
    if ( $delta > WINDOW ) {
        my $d1       = $s->epoch - $et->epoch;
        my $d2       = $eb->epoch - $et->epoch;
        my $fraction = $d1 / $d2;
        if ( $fraction < LOW_LIM ) {
            $fraction = LOW_LIM;
        }
        elsif ( $fraction > HIGH_LIM ) {
            $fraction = HIGH_LIM;
        }
        $i = sprintf '%.0f', $delta * $fraction;
    }
    else {
        $i = sprintf '%.0f', $delta / 2;
    }
    $i ||= 1;
    return $top + $i;
}


sub append_event {
    my ( $self, @args ) = @_;
    my $current = @args == 1 ? $args[0] : App::JobLog::Log::Line->new(@args);
    my $io = $self->[IO];
    my $duration;
    if ( $current->is_event ) {
        my ( $previous, $last_index ) = $self->last_event;
        if ($previous) {

            # validation to prevent inconsistency
            carp 'no currently open task'
              if $current->is_end && $previous->is_closed;
            if (
                $current->is_beginning
                && (   $current->time < $previous->start
                    || $previous->is_closed && $current->time < $previous->end )
              )
            {
                carp
'attempting to append event to log younger than last event in log';
            }

            # apply default tags
            $current->tags = $previous->tags if $current->tags_unspecified;

            # check for day change
            my ($last_ts) = $self->last_ts;
            if ( !$last_ts || _different_day( $last_ts, $current->time ) ) {
                $io->append(
                    App::JobLog::Log::Line->new(
                        comment => $current->time->strftime(TS)
                    )
                )->append("\n");
            }
            if ( $previous->is_open ) {
                $duration =
                  $current->time->subtract_datetime( $previous->start );
                $duration = undef unless $duration->in_units('days');
            }
        }
        else {

            # first record in log
            $io->append(
                App::JobLog::Log::Line->new(
                    comment => $current->time->strftime(TS)
                )
            )->append("\n");
        }

        # cache last event; useful during debugging
        if ( $current->is_beginning ) {
            $self->[LAST_EVENT] = App::JobLog::Log::Event->new($current);
            $self->[LAST_INDEX] = @$io;
        }
        elsif ( $self->[LAST_EVENT] && $self->[LAST_EVENT]->is_open ) {
            $self->[LAST_EVENT]->end = $current->time;
        }
    }
    $io->append($current)->append("\n");
    $io->close;    # flush contents
    return $duration;
}


sub append_note {
    my ( $self, @args ) = @_;
    my $note = App::JobLog::Log::Line->new( time => now, @args );
    $note->{note} = 1;    # force this to be marked as a note
    my $io = $self->[IO];

    # check for day change
    my ($last_ts) = $self->last_ts;
    if ( !$last_ts || _different_day( $last_ts, $note->time ) ) {
        $io->append(
            App::JobLog::Log::Line->new( comment => $note->time->strftime(TS) )
        )->append("\n");
    }
    $io->append($note)->append("\n");
    $io->close;           # flush contents
}

# a test to determine whether two DateTime objects
# represent different days
sub _different_day {
    my ( $d1, $d2 ) = @_;
    return !( $d1->day == $d2->day
        && $d1->month == $d2->month
        && $d1->year == $d2->year );
}


sub close {
    my ($self) = @_;
    my $io = $self->[IO];
    $io->close if $io && $io->is_open;
}


sub insert {
    my ( $self, $index, @lines ) = @_;

    # silently return unless some content to insert has been provided
    return unless @lines;
    my $comment =
      App::JobLog::Log::Line->new( comment => 'the following '
          . ( @lines == 1 ? ''  : scalar(@lines) . ' ' ) . 'line'
          . ( @lines == 1 ? ''  : 's' ) . ' ha'
          . ( @lines == 1 ? 's' : 've' )
          . ' been inserted by '
          . __PACKAGE__
          . ' rather than having been appended' );
    splice @{ $self->[IO] }, $index, 0, $comment, @lines;
}


sub replace {
    my ( $self, $index, $line ) = @_;
    carp 'expected integer and log line'
      unless $index =~ /^\d++$/ && ref $line eq 'App::JobLog::Log::Line';
    $self->[IO][$index] = $line;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Log - the code that lets us interact with the log

=head1 VERSION

version 1.042

=head1 DESCRIPTION

C<App::JobLog::Log> uses an L<IO::All> object to extract information from the
log file or add lines to it.

This wasn't written to be used outside of C<App::JobLog>. The code itself contains interlinear comments if
you want the details.

=head1 METHODS

=head2 new

C<new> is the constructor, naturally. It touches the log file into existence
if it does not yet exist, initializing the hidden job log directory in the
process, which means creating the directory and the README file. It also opens
an L<IO::All> object to read or modify the log with.

=head2 lines

A reference to the list of lines in the current log. This is useful chiefly
for debugging.

=head2 all_taglines

C<all_taglines> returns a list of all lines in the log that may have tags.

=head2 all_events

C<all_events> processes the log as a stream, extracting all events and
returning them as an array reference.

=head2 all_notes

C<all_notes> processes the log as a stream, extracting all notes and
returning them as an array reference.

=head2 validate

C<validate> makes sure the log contains only valid lines, all events are
in chronological order, and every ending follows a beginning. Invalid lines
are commented out and a warning is emitted. The number of errors found is
returned.

=head2 first_event

C<first_event> returns the first event in the log and the index
of its line. Its return object is an L<App::JobLog::Log::Event>.

=head2 last_ts

Returns last L<DateTime> timestamp in log and the index of this timestamp.

=head2 first_ts

Returns first L<DateTime> timestamp in log.

=head2 last_event

C<last_event> returns the last event in the log and the index
of its line. Its return object is an L<App::JobLog::Log::Event>.

=head2 last_note

Returns most recent note in log and its index, or the empty list if none is found.

=head2 reverse_iterator

C<reverse_iterator> returns a closure that allows you to iterate
over the events in the log in reverse. Every time you call the closure
it returns the next unvisited event.

If you pass this method an optional argument, either a L<DateTime> or a
L<App::JobLog::Log::Event>, it will iterate from the event beginning at or
after this event or time.

=head2 find_events

C<find_events> expects two L<DateTime> objects representing the
termini of an interval. It returns an array reference containing
the portion of all logged events falling within this interval. These
portions are represented as L<App::JobLog::Log::Event> objects.

=head2 find_notes

C<find_notes> expects two L<DateTime> objects representing the
termini of an interval. It returns an array reference containing
the portion of all logged notes falling within this interval. These
portions are represented as L<App::JobLog::Log::Note> objects.

=head2 find_previous

C<find_previous> looks for the logged event previous to a given
moment, returning the L<App::JobLog::Log::Event> objects and the
appropriate log line number, or the empty list if no such
event exists. It expects a L<DateTime> object as its parameter.

=head2 find_previous

C<find_previous> looks for the logged event previous to a given
moment, returning the L<App::JobLog::Log::Event> objects and the
appropriate log line number, or the empty list if no such
event exists. It expects a L<DateTime> object as its parameter.

=head2 append_event

C<append_event> expects an array of event properties. It constructs an event
object and appends its stringification to the log, returning a L<DateTime::Duration>
object if the previous event was left open and spanned more than one day.

=head2 append_note

Takes a description and a set of tags and appends it to the log as a note with the
current timestamp.

=head2 close

C<close> closes the L<IO::All> object, if it exists and is open, forcing
all content to be written to the log.

=head2 insert

C<insert> takes an insertion index and a list of L<App::JobLog::Log::Line> objects
and inserts the latter into the log at the index preceded by a comment explaining
that these lines have been inserted.

=head2 replace

Replace one line with another.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
