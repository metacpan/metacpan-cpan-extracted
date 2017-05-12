=head1 NAME

DPKG::Log - Parse the dpkg log

=head1 VERSION

version 1.20

=head1 SYNOPSIS

use DPKG::Log;

my $dpkg_log = DPKG::Log->new('filename' => 'dpkg.log', 'parse' => 1);

=head1 DESCRIPTION

This module is used to parse a logfile and store each line
as a DPKG::Log::Entry object.

=head1 METHODS

=over 4

=cut

package DPKG::Log;
BEGIN {
  $DPKG::Log::VERSION = '1.20';
}

use strict;
use warnings;
use 5.010;

use Carp;
use DPKG::Log::Entry;
use DateTime::Format::Strptime;
use DateTime::TimeZone;
use Params::Validate qw(:all);
use Data::Dumper;

=item $dpkg_log = DPKG::Log->new()

=item $dpkg_log = DPKG::Log->new('filename' => 'dpkg.log')

=item $dpkg_log = DPKG::Log->new('filename' => 'dpkg.log', 'parse' => 1 )

Returns a new DPKG::Log object. If parse is set to a true value the logfile
specified by filename is parsed at the end of the object initialisation.
Otherwise the parse routine has to be called.
Filename parameter can be ommitted, it defaults to /var/log/dpkg.log.

Optionally its possible to specify B<from> or B<to> arguments as timestamps
in the standard dpkg.log format or as DateTime objects.
This will limit the entries which will be stored in the object to entries in the
given timerange.
Note that, if this is not what you want, you may ommit these attributes and
can use B<filter_by_time()> instead.

By default the module will assume that those timestamps are in the local timezone
as determined by DateTime::TimeZone. This can be overriden by giving the
argument B<time_zone> which takes a timezone string (e.g. 'Europe/Berlin')
or a DateTime::TimeZone object.
Additionally its possible to override the timestamp_pattern by specifying
B<timestamp_format>. This has to be a valid pattern for DateTime::Format::Strptime.

=cut
sub new {
    my $package = shift;
    $package = ref($package) if ref($package);

    my %params = validate(@_,
        {
            'filename' => { 'type' => SCALAR, 'default' => '/var/log/dpkg.log' },
            'parse' => 0,
            'time_zone' => { 'type' => SCALAR, 'default' => 'local' },
            'timestamp_pattern' => { 'type' => SCALAR, 'default' => '%F %T' },
            'from' => 0,
            'to' => 0
        }
    );
    my $self = {
        entries => [],
        invalid_lines => [],
        time_zone => undef,
        from => undef,
        to => undef,
        offset => 0,
        %params
    
    };

    bless($self, $package);
    
    $self->parse if $params{'parse'};

    return $self;
}

=item $dpkg_log->filename

=item $dpkg_log->filename('newfilename.log')

Get or set the filename of the dpkg logfile.

=cut
sub filename {
    my ($self, $filename) = @_;
    if ($filename) {
        $self->{filename} = $filename;
    } else {
        $filename = $self->{filename};
    }
    return $filename;
}

=item $dpkg_log->parse

=item $dpkg_log->parse('time_zone' => 'Europe/Berlin')

=item $dpkg_log->parse('time_zone' => $dt_tz )

Call the parser.

The B<time_zone> parameter is optional and specifies in which time zone
the dpkg log timestamps are.  If its omitted it will use the default
local time zone.
Its possible to specify either a DateTime::TimeZone object or a string.
=cut
sub parse {
    my $self = shift;
    open(my $log_fh, "<", $self->{filename})
        or croak("unable to open logfile for reading: $!");
 
    my %params = validate(
        @_, {
                'from' => { default => $self->{from} },
                'to' => { default => $self->{to} }, 
                'time_zone' => {  default => $self->{time_zone} },
                'timestamp_pattern' => { default => $self->{timestamp_pattern} },
            }
    );

    # Determine system timezone
    my $tz;
    if (ref($params{time_zone}) and (ref($params{time_zone}) eq "DateTime::TimeZone")) {
        $tz = $params{time_zone};
    } elsif (ref($params{time_zone})) {
        croak "time_zone argument has to be a string or a DateTime::TimeZone object";
    } else {
        $tz =  DateTime::TimeZone->new( 'name' => $params{time_zone} );
    }
    my $ts_parser = DateTime::Format::Strptime->new( 
        pattern => $params{timestamp_pattern},
        time_zone => $params{time_zone}
    );

    my $lineno = 0;
    while  (my $line = <$log_fh>) {
        $lineno++;
        chomp $line;
        next if $line =~ /^$/;

        my $timestamp;
              
        my @entry = split(/\s/, $line);
        if (not $entry[0] and not $entry[1]) {
            push(@{$self->{invalid_lines}}, $line);
            next;
        }

        my ($year, $month, $day) = split('-', $entry[0]);
        my ($hour, $minute, $second) = split(':', $entry[1]);

        if ($year and $month and $day and $hour and $minute and $second) {
            $timestamp = DateTime->new(
                year => $year,
                month => $month,
                day => $day,
                hour => $hour,
                minute => $minute,
                second => $second,
                time_zone => $tz
            );
        } else {
            push(@{$self->{invalid_lines}}, $line);
            next;
        }

        my $entry_obj;
        if ($entry[2] eq "update-alternatives:") {
            next;
        } elsif ($entry[2] eq "startup") {
            $entry_obj = {  line => $line,
                lineno => $lineno,
                timestamp => $timestamp,
                type => 'startup',
                subject => $entry[3],
                action => $entry[4]
            };
        } elsif ($entry[2] eq "status") {
            $entry_obj = { line => $line,
                lineno => $lineno,
                timestamp => $timestamp,
                type => 'status',
                subject => 'package',
                status => $entry[3],
                associated_package => $entry[4],
                installed_version => $entry[5]
            };
         } elsif (defined($valid_actions->{$entry[2]}) ) {
            $entry_obj = { line => $line,
                lineno => $lineno,
                timestamp => $timestamp,
                subject => 'package',
                type => 'action',
                action => $entry[2],
                associated_package => $entry[3],
                installed_version => $entry[4],
                available_version => $entry[5]
            };
        } elsif ($entry[2] eq "conffile") {
            $entry_obj = { line => $line,
                lineno => $lineno,
                timestamp => $timestamp,
                subject => 'conffile',
                type => 'conffile_action',
                conffile => $entry[3],
                decision => $entry[4]
            };
        } else {
            print $line . " invalid\n";
            push(@{$self->{invalid_lines}}, $line);
            next;
        }

        push(@{$self->{entries}}, $entry_obj);
    }
    close($log_fh);

    if ($self->{from} or $self->{to}) {
        @{$self->{entries}} = $self->filter_by_time( entry_ref => $self->{entries}, %params);
    }

    return scalar(@{$self->{entries}});
}

=item @entries = $dpkg_log->entries;

=item @entries = $dpkg_log->entries('from' => '2010-01-01.10:00:00', to => '2010-01-02 24:00:00')

Return all entries or all entries in a given timerange.

B<from> and B<to> are optional arguments, specifying a date before (from) and after (to) which
entries aren't returned.
If only B<to> is specified all entries from the beginning of the log are read.
If only B<from> is specified all entries till the end of the log are read.

=cut
sub entries {
    my $self = shift;

    my %params = validate(
        @_, {  
                from => 0,
                to => 0,
                time_zone => { type => SCALAR, default => $self->{time_zone} }
            }
    );
    croak "Object does not store entries. Eventually parse function were not run or log is empty. " if (not @{$self->{entries}});

    if (not ($params{from} or $params{to})) {
        return map { DPKG::Log::Entry->new($_) } @{$self->{entries}};
    } else {
        return $self->filter_by_time(%params);
    }
}

=item $entry = $dpkg_log->next_entry;

Return the next entry. 

=cut
sub next_entry {
    my $self = shift;
    my $offset = $self->{offset}++;
    return DPKG::Log::Entry->new(@{$self->{entries}}[$offset]);
}

=item @entries = $dpkg_log->filter_by_time(from => ts, to => ts)

=item @entries = $dpkg_log->filter_by_time(from => ts)

=item @entries = $dpkg_log->filter_by_time(to => ts)

=item @entries = $dpkg_log->filter_by_time(from => ts, to => ts, entry_ref => $entry_ref)

Filter entries by given B<from> - B<to> range. See the explanations for
the new sub for the arguments.

If entry_ref is given and an array reference its used instead of $self->{entries}
as input source for the entries which are to be filtered.
=cut
sub filter_by_time {
    my $self = shift;
    my %params = validate( 
        @_, {
                from => 0,
                to => 0,
                time_zone => { default => $self->{time_zone} },
                timestamp_pattern => { default => $self->{timestamp_pattern} },
                entry_ref => { default => $self->{entries} },
            }
    );
    
    my @entries = @{$params{entry_ref}};
    if (not @entries) {
        croak "Object does not store entries. Eventually parse function were not run or log is empty.";
    }

    $self->__eval_datetime_info(%params);

    @entries = grep { (DPKG::Log::Entry->new($_)->timestamp >= $self->{from}) and (DPKG::Log::Entry->new($_)->timestamp <= $self->{to}) } @entries;
    return map { DPKG::Log::Entry->new($_) } @entries;
}

=item ($from, $to) = $dpkg_log->get_datetime_info()

Returns the from and to timestamps of the logfile or (if from/to values are set) the
values set during object initialisation.

=cut
sub get_datetime_info {
    my $self = shift;

    my $from;
    my $to;
    if ($self->{from}) {
        $from = $self->{from};
    } else {
        $from = DPKG::Log::Entry->new(%{$self->{entries}->[0]})->timestamp;
    }

    if ($self->{to}) {
        $to = $self->{to};
    } else {
        $to = DPKG::Log::Entry->new(%{$self->{entries}->[-1]})->timestamp;
    }
    return ($from, $to);
}

## Internal methods
sub __eval_datetime_info {
    my $self = shift;
    
    my %params = validate(
        @_, {
                from => { default => $self->{from} },
                to => { default => $self->{to} },
                time_zone => { default => $self->{time_zone} },
                timestamp_pattern => { default => $self->{timestamp_pattern} },
                entry_ref => { default => $self->{entries} },
            }
    );

    my $entry_ref = $params{entry_ref};
    my $from = $params{from};
    my $to = $params{to};

    my $ts_parser = DateTime::Format::Strptime->new(
        pattern => $params{timestamp_pattern},
        time_zone => $params{time_zone}
    );

    if (not $from) {
        $from = DPKG::Log::Entry->new($entry_ref->[0])->timestamp;
    }
    if (not $to) {
        $to = DPKG::Log::Entry->new($entry_ref->[-1])->timestamp;
    }
    if (ref($from) ne "DateTime") {
        $from = $ts_parser->parse_datetime($from);
    }
    if (ref($to) ne "DateTime") {
        $to = $ts_parser->parse_datetime($to);
    }

    $self->{from} = $from;
    $self->{to} = $to;
    return;
}


=back

=head1 SEE ALSO

L<DPKG::Log::Entry>, L<DateTime>, L<DateTime::TimeZone>

=head1 AUTHOR

Patrick Schoenfeld <schoenfeld@debian.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Patrick Schoenfeld <schoenfeld@debian.org>

This library is free software.
You can redistribute it and/or modify it under the same terms as perl itself.

=cut

1;
# vim: expandtab:ts=4:sw=4