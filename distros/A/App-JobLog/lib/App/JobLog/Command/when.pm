package App::JobLog::Command::when;
$App::JobLog::Command::when::VERSION = '1.042';
# ABSTRACT: when you'll be done for the day

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
use autouse 'App::JobLog::Time' => qw(today now);

use constant FULL_FORMAT      => '%l:%M:%S %p on %A, %B %d, %Y';
use constant SAME_YEAR_FORMAT => '%l:%M:%S %p on %A, %B %d';
use constant SAME_WEEK_FORMAT => '%l:%M:%S %p on %A';
use constant SAME_DAY_FORMAT  => '%l:%M:%S %p';

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $tags          = $opt->tag         || [];
    my $excluded_tags = $opt->exclude_tag || [];
    my $match         = $opt->match       || [];
    my $no_match      = $opt->no_match    || [];

    # validate regexes, if any, while generating test

    my $test =
      App::JobLog::Command::summary::_make_test( $tags, $excluded_tags, $match,
        $no_match, undef );

    # parse time expression
    my $days;
    my $start = ( join ' ', @$args ) || 'today';
    eval { ( $days, undef ) = summary "$start through today", $test, {} };
    $self->usage_error($@) if $@;

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
    my $remaining = 0;
    $remaining += $_->time_remaining for @$days;
    if ( $remaining == 0 ) {
        say "\nyou are just now done";
    }
    else {
        my $then = now->add( seconds => $remaining );
        my $format;
        if ( $then->year == now->year ) {
            my $delta = abs $then->delta_days(now)->in_units('days');
            if ( $delta > 7 ) {
                $format = SAME_YEAR_FORMAT;
            }
            elsif ( $then->month == now->month && $then->day == now->day ) {
                $format = SAME_DAY_FORMAT;
            }
            else {
                $format = SAME_WEEK_FORMAT;
            }
        }
        else {
            $format = FULL_FORMAT;
        }
        if ( $then < now ) {
            $then = ( $days->[-1]->last_event->end // now )->add( seconds => $remaining );
            say "\nyou were finished at " . $then->strftime($format);
        }
        else {
            say "\nyou will be finished at " . $then->strftime($format);
        }
        print "\n";
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o <date or date range>' }

sub abstract {
    'report when work is done for the day';
}

sub full_description {
    <<END
Calculate when you'll be done for the day given how much work you've already done.
If no time expression is provided, all task time since the beginning of the day
is considered. A useful time expression is 'pay period' (equivalently, 'pay', 'payperiod',
or 'pp').

It is possible that you won't want all tasks in the log in the given period included in the 
time worked sum. As with the summary command, events may be filtered in numerous ways: by tag,
or terms used in descriptions.  If tags to match are provided, only those events
that contain at least one such tag will be shown. If tags not to match are provided, only those
events that contain none of these tags will be shown.

If you provide description filters to match or avoid, these will be interpreted as regexes. Try 'perldoc perlre'
for more details, or perhaps 'perldoc perlretut' (these will only work if you have the Perl documentation
installed on your machine). If you don't want to worry about regular expressions, simple strings will work.
Prefix your expression with '(?i)' to turn off case sensitivity. And don't enclose regexes in slashes or any other
sort of delimiter. Use 'ab', not '/ab/' or 'm!ab!', etc. Finally, you may need to enclose your regexes in single quotes
to prevent the shell from trying to interpret them.
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
            'tag|t=s@',
            'filter events to include only those with given tags; '
              . 'multiple tags may be specified'
        ],
        [
            'exclude-tag|T=s@',
            'filter events to exclude those with given tags; '
              . 'multiple tags may be specified'
        ],
        [
            'match|m=s@',
'filter events to include only those one of whose descriptions matches the given regex; '
              . 'multiple regexes may be specified'
        ],
        [
            'no-match|M=s@',
'filter events to include only those one of whose descriptions do not match the given regex; '
              . 'multiple regexes may be specified'
        ],
        [ 'no-vacation|V', 'do not display vacation hours' ],
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::when - when you'll be done for the day

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~job when --help
 job <command> 

 job when [-MmTtV] [long options...] <date or date range>
 	Use 'job help when' to see full details.
	                    
 	-t --tag              filter events to include only those with given
	                      tags; multiple tags may be specified
	-T --exclude-tag      filter events to exclude those with given tags;
	                      multiple tags may be specified
	-m --match            filter events to include only those one of
	                      whose descriptions matches the given regex;
	                      multiple regexes may be specified
	-M --no-match         filter events to include only those one of
	                      whose descriptions do not match the given
	                      regex; multiple regexes may be specified
	-V --no-vacation      do not display vacation hours
	--help                this usage screen
 houghton@NorthernSpy:~$ job w payperiod
 
 you will be finished at  7:17:32 pm

=head1 DESCRIPTION

B<App::JobLog::Command::when> says when you will be able to punch out for the day. It does this by iterating over
the days in some range of dates, adding up the time worked and subtracted the work hours expected. If no argument
is given, the range only includes the current day. (See the C<workday> parameter of L<App::JobLog::Command::configure>.)
If you wish to use the pay period as your interval, you need to have defined the C<start pay period> parameter of
L<App::JobLog::Command::configure>.

Various options are provided to facilitate eliminating certain tasks from the calculation. This is useful if you
have more than one employer and you are committed to working a certain number of hours a day for each.

=head1 ACKNOWLEDGEMENTS

This command was inspired by my wife Paula, who frequently wanted to know when I'd be done for the day. In an earlier
incarnation of this application one obtained it by passing in the option C<-p> and I knew it as the Paula feature.

=head1 SEE ALSO

L<App::JobLog::Command::summary>, L<App::JobLog::Command::last>, L<App::JobLog::Command::tags>, L<App::JobLog::Command::configure>,
L<App::JobLog::Command::vacation>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

__END__

