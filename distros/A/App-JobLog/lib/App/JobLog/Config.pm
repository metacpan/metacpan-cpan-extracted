package App::JobLog::Config;
$App::JobLog::Config::VERSION = '1.042';
# ABSTRACT: central depot for App::JobLog configuration parameters and controller allowing their modification


use Exporter 'import';
our @EXPORT_OK = qw(
  columns
  day_length
  dir
  editor
  hidden_columns
  init_file
  is_hidden
  is_workday
  log
  merge
  pay_period_length
  precision
  readme
  start_pay_period
  sunday_begins_week
  time_zone
  _tz
  vacation
  workdays
  DAYS
  DIRECTORY
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

use Class::Autouse qw{
  File::HomeDir
  File::Spec
  Config::Tiny
  FileHandle
  App::JobLog::Command::info
};
use autouse 'File::Path'    => qw(mkpath);
use autouse 'Cwd'           => qw(abs_path);
use autouse 'Term::ReadKey' => qw(GetTerminalSize);
use Modern::Perl;

# default precision
use constant PRECISION => 2;

# default pay period
use constant PERIOD => 14;

# hours worked in day
use constant HOURS => 8;

# whether Sunday is the first day of the week
# otherwise it's Monday, as in DateTime
use constant SUNDAY_BEGINS_WEEK => 1;

# environment variables

# identifies directory to write files into
use constant DIRECTORY => 'JOB_LOG_DIRECTORY';

# expected abbreviations for working days in week
use constant WORKDAYS => 'MTWHF';

# expected abbreviations for weekdays
use constant DAYS => 'S' . WORKDAYS . 'A';

# default level of merging
use constant MERGE => 'adjacent same tags';

# name of hide nothing "column"
use constant NONE_COLUMN => 'none';

# array of hidable columns
use constant HIDABLE_COLUMNS => [
    NONE_COLUMN, qw(
      date
      description
      duration
      tags
      time
      )
];

# default time zone; necessary because Cygwin doesn't support local
use constant TIME_ZONE => $^O eq 'cygwin' ? 'floating' : 'local';


sub init_file {
    my ($path) = @_;
    unless ( -e $path ) {
        my ( $volume, $directories, $file ) = File::Spec->splitpath($path);
        my $dir = File::Spec->catfile( $volume, $directories );
        mkpath( $dir, { verbose => 0, mode => 0711 } ) unless -d $dir;
        unless ( -e readme() ) {
            my $fh = FileHandle->new( readme(), 'w' )
              or die 'could not create file ' . readme();
            my $executable = abs_path($0);

            # to protect against refactoring
            my $command = App::JobLog::Command::info->name;
            print $fh <<END;

Job Log

This directory holds files used by Job Log to maintain
a work log. For more details type

$executable $command

on the command line.

END
            $fh->close;
        }
    }
}


my $dir;

sub dir {
    $dir ||= $ENV{ DIRECTORY() };
    $dir ||= File::Spec->catfile( File::HomeDir->my_home, '.joblog' );
    return $dir;
}


my $log;

sub log {
    $log ||= File::Spec->catfile( dir(), 'log' );
    return $log;
}


my $readme;

sub readme {
    $readme ||= File::Spec->catfile( dir(), 'README' );
    return $readme;
}

# configuration file for basic parameters
my $config_file;

sub _config_file {
    $config_file ||= File::Spec->catfile( dir(), 'config.ini' );
    return $config_file;
}


my $vacation_file;

sub vacation {
    $vacation_file ||= File::Spec->catfile( dir(), 'vacation' );
    return $vacation_file;
}

# configuration object and whether any changes need to be written to this file
my ( $config, $config_changed );

END {
    if ($config_changed) {
        init_file( _config_file() );
        $config->write( _config_file() );
    }
}

# construct configuration object as necessary
sub _config {
    unless ($config) {
        my $f = _config_file();
        $config = -e $f ? Config::Tiny->read($f) : Config::Tiny->new;
    }
    return $config;
}


sub precision {
    my ($value) = @_;
    return _param( 'precision', PRECISION, 'summary', $value );
}

sub merge {
    my ($value) = @_;
    return _param( 'merge', MERGE, 'summary', $value );
}


sub day_length {
    my ($value) = @_;
    return _param( 'day-length', HOURS, 'time', $value );
}


sub pay_period_length {
    my ($value) = @_;
    return _param( 'pay-period-length', PERIOD, 'time', $value );
}


sub sunday_begins_week {
    my ($value) = @_;
    return _param( 'sunday-begins-week', SUNDAY_BEGINS_WEEK, 'time', $value );
}


sub start_pay_period {
    my ($value) = @_;
    require DateTime;
    if ( ref $value eq 'DateTime' ) {
        $value = sprintf '%d %d %d', $value->year, $value->month, $value->day;
    }
    $value = _param( 'start-pay-period', undef, 'time', $value );
    if ($value) {
        my @parts = split / /, $value;
        return DateTime->new(
            year      => $parts[0],
            month     => $parts[1],
            day       => $parts[2],
            time_zone => _tz(),
        );
    }
    return;
}

# abstracts out code for maintaining config file
sub _param {
    my ( $param, $default, $section, $new_value ) = @_;
    $section ||= 'main';
    my $config = _config();
    my $value  = $config->{$section}->{$param};
    if ( defined $new_value ) {
        if ( defined $default && $new_value eq $default && !defined $value ) {
            return $new_value;
        }
        return $value if defined $value && $value eq $new_value;
        $config_changed = 1;
        return $config->{$section}->{$param} = $new_value;
    }
    else {
        return defined $value ? $value : $default;
    }
}


sub editor {
    my ($value) = @_;
    $value = _param( 'editor', undef, 'external', $value );
    return $value;
}


sub columns {
    my ($cols) = GetTerminalSize;
    $cols ||= 76;
    return $cols;
}


sub workdays {
    my ($value) = @_;
    return _param( 'workdays', WORKDAYS, 'time', $value );
}


my %workdays;

sub is_workday {
    my ($date) = @_;

    # initialize map
    unless (%workdays) {
        my @days = split //, DAYS;

        # move Sunday into DateTime's expected position
        push @days, shift @days;
        my %day_map;
        for ( 0 .. $#days ) {
            $day_map{ $days[$_] } = $_ + 1;
        }
        for ( split //, workdays() ) {
            $workdays{ $day_map{$_} } = 1;
        }
    }
    return $workdays{ $date->day_of_week };
}


sub hidden_columns {
    my ($value) = @_;
    return _param( 'hidden_columns', NONE_COLUMN, 'summary', $value );
}


my %hidden_columns;

sub is_hidden {
    my ($value) = @_;
    unless (%hidden_columns) {
        %hidden_columns = map { $_ => 1 } split / /, hidden_columns();
    }
    return $hidden_columns{$value};
}


sub time_zone {
    my ($value) = @_;
    return _param( 'time_zone', TIME_ZONE, 'time', $value );
}

our $tz;

# removed from App::JobLog::Time to prevent dependency cycle
sub _tz {
    if ( !defined $tz ) {
        require DateTime::TimeZone;
        eval { $tz = DateTime::TimeZone->new( name => time_zone() ) };
        if ($@) {
            print STDERR 'DateTime::TimeZone doesn\'t like the time zone '
              . time_zone()
              . "\nreverting to floating time\n full error: $@";
            $tz = DateTime::TimeZone->new( name => 'floating' );
        }
    }
    return $tz;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Config - central depot for App::JobLog configuration parameters and controller allowing their modification

=head1 VERSION

version 1.042

=head1 DESCRIPTION

C<App::JobLog::Config> is a central repository for program state that may be conserved from
session to session. It also serves as a general interface between the program and the machine.

This wasn't written to be used outside of C<App::JobLog>. 

=head1 METHODS

=head2 init_file

C<init_file> manages configuration files. It ensures that the 
working directory and the README file exist before
we try to create or modify any files in the working directory.

=head2 dir

Working directory.

=head2 log

Log file.

=head2 readme

README file.

=head2 vacation

Obtain the file in which vacation information is stored.

=head2 precision

Obtain the number of decimal places represented when displaying the duration
of events.

=head2 day_length

The number of hours one is expected to work in a day.

=head2 pay_period_length

The number of days between paychecks.

=head2 sunday_begins_week

Whether to regard Sunday or Monday as the first day in the week
when interpreting time expressions such as 'last week'. L<DateTime>
uses Monday. The default for L<App::JobLog> is Sunday. For the purposes
of calculating hours worked this will make no difference for most people.

=head2 start_pay_period

Returns DateTime representing start date of pay period or null if none is defined.

=head2 editor

Log editing program.

=head2 columns

The number of columns available in the terminal. This defaults to
76 when L<Term::ReadKey> is unable to determine terminal width.

=head2 workdays

The days of the week when one expects to be working.

=head2 is_workday

Returns whether a particular L<DateTime> object represents a workday.

=head2 hidden_columns

Returns those columns never displayed by summary command.

=head2 is_hidden

Whether a particular column is among those hidden.

=head2 time_zone

Time zone used for time calculations.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
