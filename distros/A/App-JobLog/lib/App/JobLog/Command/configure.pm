package App::JobLog::Command::configure;
$App::JobLog::Command::configure::VERSION = '1.042';
# ABSTRACT: examine or modify App::JobLog configuration

use App::JobLog -command;
use Modern::Perl;
use App::JobLog::Config qw(
  day_length
  editor
  hidden_columns
  merge
  pay_period_length
  precision
  start_pay_period
  sunday_begins_week
  time_zone
  workdays
  DAYS
  HIDABLE_COLUMNS
  HOURS
  MERGE
  NONE_COLUMN
  PERIOD
  PRECISION
  SUNDAY_BEGINS_WEEK
  TIME_ZONE
  WORKDAYS
);
use autouse 'App::JobLog::TimeGrammar' => qw(parse);
no if $] >= 5.018, warnings => "experimental::smartmatch";

sub execute {
    my ( $self, $opt, $args ) = @_;
    _list_params() if $opt->list;
    if ( defined $opt->precision ) {
        my $precision = precision( $opt->precision );
        say "precision set to $precision";
    }
    if ( defined $opt->start_pay_period ) {
        eval {
            my ($s) = parse( $opt->start_pay_period );
            my $d = start_pay_period($s);
            say 'beginning of pay period set to ' . $d->strftime('%F');
        };
        $self->usage_error(
            'could not understand date: ' . $opt->start_pay_period )
          if $@;
    }
    if ( defined $opt->length_pay_period ) {
        my $length_pp = pay_period_length( $opt->length_pay_period );
        say "length of pay period in days set to $length_pp";
    }
    if ( defined $opt->day_length ) {
        my $day_length = day_length( $opt->day_length );
        say "length of work day set to $day_length";
    }
    if ( defined $opt->workdays ) {
        my $days = uc $opt->workdays;
        my %days = map { $_ => 1 } split //, $days;
        my @days;
        for ( split //, DAYS ) {
            push @days, $_ if $days{$_};
        }
        $days = join '', @days;
        $days = workdays($days);
        say "workdays set to $days";
    }
    if ( defined $opt->sunday_begins_week ) {
        my $bool;
        for ( $opt->sunday_begins_week ) {
            when (/true/i)  { $bool = 1 }
            when (/false/i) { $bool = 0 }
            default { $bool = $opt->sunday_begins_week || 0 };
        }
        $bool = sunday_begins_week($bool);
        say "Sunday begins week is now " . ( $bool ? 'true' : 'false' );
    }
    if ( defined $opt->merge ) {
        my $m = lc $opt->merge;
        $m =~ s/^\s++|\s++$//g;
        $m =~ s/\s++/ /g;
        my $value = merge($m);
        say "merge level is now '$value'";
    }
    if ( defined $opt->editor ) {
        my $value = editor( $opt->editor );
        say "log editor is now $value";
    }
    if ( defined $opt->hidden_columns ) {
        my @cols = map { my $v = $_; lc $v } @{ $opt->hidden_columns };
        my %cols = map { $_ => 1 } @cols;
        my $value = join ' ', sort keys %cols;
        $value = hidden_columns($value);
        say "hidden columns: $value";
    }
    if ( defined $opt->time_zone ) {
        my $value = time_zone( $opt->time_zone );
        say "time zone is now $value";
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o' }

sub abstract { 'set or display various parameters' }

sub options {
    return (
        [
            'precision=i',
            'decimal places of precision in display of time; '
              . 'e.g., --precision=1; '
              . 'default is '
              . PRECISION
        ],
        [
            'start-pay-period=s',
            'the first day of some pay period; '
              . 'pay period boundaries will be calculated based on this date and the pay period length; '
              . 'e.g., --start-pay-period="June 14, 1912"'
        ],
        [
            'time-zone=s',
            'time zone used in calendar calculations; default is ' . TIME_ZONE
        ],
        [
            'sunday-begins-week=s',
            'whether Sundays should be regarded as the first day in the week; '
              . 'the alternative is Monday; default is '
              . ( SUNDAY_BEGINS_WEEK ? 'TRUE' : 'FALSE' )
        ],
        [
            'length-pay-period=i',
'the length of the pay period in days; e.g., --length-pay-period 7; '
              . 'default is '
              . PERIOD
        ],
        [
            'day-length=f',
            'length of workday; '
              . 'e.g., --day-length 7.5; '
              . 'default is: '
              . HOURS
        ],
        [
            'workdays=s',
            'which days of the week you work represented as some subset of '
              . DAYS
              . '; e.g., --workdays=MTWH; '
              . 'default is '
              . WORKDAYS
        ],
        [
            'merge=s',
            'amount of merging of events in summaries; '
              . 'available options are : '
              . "'adjacent same tags', 'adjacent', 'all', 'none', 'same day same tags', 'same day', 'same tags'; "
              . "default is '@{[MERGE]}'"
        ],
        [
            'hidden-columns=s@',
            'columns not to display with the '
              . App::JobLog::Command::summary->name
              . ' command; '
              . 'available options are: '
              . join( ', ', map { "'$_'" } @{ HIDABLE_COLUMNS() } ) . '; '
              . "default is '@{[NONE_COLUMN]}'; "
              . 'multiple columns may be specified'
        ],
        [ 'editor=s', 'text editor to use when manually editing the log' ],
        [ 'list|l',   'list all configuration parameters' ],
    );
}

#
# list values of all params
#
sub _list_params {
    my @params = sort qw(
      precision
      day_length
      editor
      hidden_columns
      merge
      pay_period_length
      start_pay_period
      sunday_begins_week
      time_zone
      workdays
    );
    my %booleans = map { $_ => 1 } qw(
      sunday_begins_week
    );
    my ( $l1, $l2, %h ) = ( 0, 0 );

    for my $method (@params) {
        my $l     = length $method;
        my $value = eval "App::JobLog::Config::$method()";
        $value = $value ? 'true' : 'false' if $booleans{$method};
        $value = 'not defined' unless defined $value;
        $value = $value->strftime('%F') if ref $value eq 'DateTime';
        $l1    = $l                     if $l > $l1;
        $l     = length $value;
        $l2    = $l                     if $l > $l2;
        $h{$method} = $value;
    }
    my $format = '%-' . $l1 . 's %' . $l2 . "s\n";
    for my $method (@params) {
        my $value = $h{$method};
        $method =~ s/_/ /g;
        printf $format, $method, $value;
    }
}

sub validate {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error('specify some parameter to set or display') unless %$opt;
    $self->usage_error('cannot parse work days')
      if $opt->workdays && $opt->workdays !~ /^[SMTWHFA]*+$/i;
    $self->usage_error(
        'cannot understand argument ' . $opt->sunday_begins_week )
      if $opt->sunday_begins_week
          && $opt->sunday_begins_week !~ /^(?:true|false|[01])?$/i;
    if ( defined $opt->merge ) {
        my $m = lc $opt->merge;
        $m =~ s/^\s++|\s++$//g;
        $m =~ s/\s++/ /g;
        if ( $m !~
/^(?:adjacent|adjacent same tags|all|none|same day|same day same tags|same tags)$/
          )
        {
            $self->usage_error( 'unknown merge option: ' . $opt->merge );
        }
    }
    if ( defined $opt->hidden_columns ) {
        my %h = map { $_ => 1 } @{ HIDABLE_COLUMNS() };
        my ( $found_none, $found_something ) = ( 0, 0 );
        for my $c ( @{ $opt->hidden_columns } ) {
            my $col = lc $c;
            $self->usage_error("unknown column: $c") unless $h{$col};
            if ( $col eq NONE_COLUMN ) {
                $found_none ||= 1;
            }
            else {
                $found_something ||= 1;
            }
        }
        $self->usage_error(
"you have specified that something should be hidden and that nothing should be hidden"
        ) if $found_none && $found_something;
    }
    if ( defined $opt->time_zone ) {
        require DateTime::TimeZone;
        eval { DateTime::TimeZone->new( name => $opt->time_zone ) };
        $self->usage_error(
                'DateTime::TimeZone does not like the time zone name '
              . $opt->time_zone
              . "\n$@" )
          if $@;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::configure - examine or modify App::JobLog configuration

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job configure --help
 job <command>
 
 job configure [-l] [long options...]
 	--precision               decimal places of precision in display of
 	                          time; e.g., --precision=1; default is 2
 	--start-pay-period        the first day of some pay period; pay
 	                          period boundaries will be calculated based
 	                          on this date and the pay period length;
 	                          e.g., --start-pay-period="June 14, 1912"
	--time-zone               time zone used in calendar calculations;
	                          default is local
 	--sunday-begins-week      whether Sundays should be regarded as the
 	                          first day in the week; the alternative is
 	                          Monday; default is TRUE
 	--length-pay-period       the length of the pay period in days; e.g.,
 	                          --pp-length= 7; default is 14
 	--day-length              length of workday; e.g., -d 7.5; default is
 	                          8
 	--workdays                which days of the week you work represented
 	                          as some subset of SMTWHFA; e.g.,
 	                          --workdays=MTWH; default is MTWHF
 	--merge                   amount of merging of events in summaries;
 	                          available options are : 'adjacent same
 	                          tags', 'adjacent', 'all', 'none', 'same day
 	                          same tags', 'same day', 'same tags';
 	                          default is 'adjacent same tags'
 	--hidden-columns          columns not to display with the summary
 	                          command; available options are: 'none',
 	                          'date', 'description', 'duration', 'tags',
 	                          'time'; default is 'none'; multiple columns
 	                          may be specified
 	--editor                  text editor to use when manually editing
 	                          the log
 	-l --list                 list all configuration parameters
 	--help                    this usage screen
 houghton@NorthernSpy:~$ job configure --list
 day length                          8
 editor                   /usr/bin/vim
 hidden columns                   none
 merge              adjacent same tags
 pay period length                  14
 precision                           1
 start pay period           2009-01-11
 sunday begins week               true
 time zone                       local
 workdays                        MTWHF
 houghton@NorthernSpy:~$ job configure --precision 2
 precision set to 2
 houghton@NorthernSpy:~$ job configure -l
 day length                          8
 editor                   /usr/bin/vim
 hidden columns                   none
 merge              adjacent same tags
 pay period length                  14
 precision                           2
 start pay period           2009-01-11
 sunday begins week               true
 time zone                       local
 workdays                        MTWHF

=head1 DESCRIPTION

B<App::JobLog::Command::configure> is the command one should use to edit F<~/.joblog/config.ini>. It will
validate the parameters, preventing you from producing a broken configuration file. If you specify
no configuration parameters sensible defaults will be used when possible. For some, such as the beginning
of the pay period, no such default is available. L<App::JobLog::TimeGrammar> will be unable to interpret
time expressions involving pay periods until this parameter is set. The other parameter for which there
is no default is editor. See L<App::JobLog::Command::editor> for further details.

=head1 PARAMETERS

=over 8

=item day length

To calculate vacation time and how much time you have left to work in a day L<App::JobLog> needs to
know how much time you work in a typical workday. This is the day length parameter.

=item editor

L<App::JobLog::Command::editor> requires some text editor to edit the log. Specify it here.

Note that this editor must be invokable like so:

  <editor> <file>

Also, if you need to provide any additional arguments you can provide them as part of this parameter.

=item hidden columns

When you invoke L<App::JobLog::Command::summary> or the other log summarizing commands you have the option
of hiding various pieces of information which by default are displayed: time, date, duration, tags, description,
and total hours. If you wish certain of these always to be hidden you can specify this with this parameter. If
you wish to hide multiple columns you must provide multiple instances of this parameter, each with a column to
hide.

=item merge

L<App::JobLog::Command::summary> can produce a report keeping each event separate, merging them by day, merging
them by tag, merging immediately adjoining events, and so forth. If you find you are always specifying a particular
variety of merge you can set this parameter so it becomes the default.

=item pay period length

In order to calculate the beginning of pay periods one needs to know when a particular period began and the
length of pay periods generally. The parameter supplies the latter.

=item precision

This parameter specifies the number of digits appearing after the decimal point in the reported duration of events.

=item start pay period

In order to calculate the beginnings and ends of pay periods, and hence how many hours one has left to work
in a particular pay period, for instance, one needs to know both their length generally and the beginning
of some particular pay period. This parameter supplies the latter.

=item sunday begins week

L<App::JobLog> uses L<DateTime> for all calendar math. L<DateTime> regards Monday as the first day of the week.
Another convention is to regard Sunday as the first day of the week. This is significant because it changes the
meaning of phrases such as I<this week> and I<March 1 until the end of the week>. Use this parameter to choose
your preferred interpretation of such phrases.

=item time zone

This is the time zone used for converting the system time to the time of the day. Most likely you will not need
to set this parameter, but go here if your times look funny.

=item workdays

L<App::JobLog> needs to know which days you are expected to work in order to determine when to assign vacation
hours and calculate how much time you still have to work in a particular period. The default assumption is that
you work from Monday to Friday, signified by the string I<MTWHF> (case is ignored). Sunday is I<S> and Saturday
is I<A>. Use this parameter to modify or affirm this assumption.

=back

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
