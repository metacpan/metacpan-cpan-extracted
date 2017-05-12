#!/usr/bin/perl;


use strict;
use warnings;
use FindBin;
use Config::Checker;
use Test::More qw(no_plan);
use YAML::Syck qw(Load);
use Time::ParseDate;
use Clone::PP qw(clone);

my $finished = 0;

my $prototype_config = <<'END_PROTOTYPE';
---
master_node:            The control node where the header information and metadata is kept[HOSTNAME]
headers:                path to the header information (on master_node)[PATH]
metadata:               path to the metadata informatin (on master_node)[PATH]
state_variables:        '*path to where to keep internal state information in YAML files[PATH]'
parameters:             %additional global configuration parameters
sources:
  -
    name:               =name of this source -- will be used later[TEXT]
    hosts:              '*name of hosts where the data can be found[HOSTNAME]'
    path:               filesystem path name where the data can be found[PATH]
    valid_from:         '?date from which this source is valid[DATE]{=parsedate($_[0]) || die "invalid date: $_[0]"}'
    valid_to:           '?date until which this source is valid[DATE]{=parsedate($_[0]) || die "invalid date: $_[0]"}'
    format:             'record format for this source{valid_parser($_[0]) or $error = "invalid parser: <$_[0]> at $context"}'
    remove_after:       '?data expiration policy{parse_expiration_policy($_[0])}'
jobs:
  -
    name:               =name of this step[WORD]
    DISABLED:           '?(=0)1 or 0'
    source:             '+name of input the data[TEXT]'
    destination:        name of the output data[TEXT]
    hosts:              '*where to do the work and store the output[HOSTNAME]'
    path:               where to write the output data[PATH]
    valid_from:         '?the first day to do this job this way[DATE]{=parsedate($_[0]) || die "invalid date: $_[0]"}'
    valid_to:           '?the last day to do this job this way[DATE]{=parsedate($_[0]) || die "invalid date: $_[0]"}'
    filter:             '?perl expression: to apply to choose input[CODE]'
    group_by:           '?perl expression: re-group input (expand or contract)[CODE]'
    sort_by:            '*list of job fields to sort by[WORD]'
    bucketizer:         '?perl expression: returns data to choose bucket[CODE]'
    buckets:            '?(=1)the total number of output buckets[INTEGER]'
    remove_after:       '?data expiration policy{parse_expiration_policy($_[0])}'
    output_format:      'name of perl module to handle $object -> ascii{valid_parser($_[0]) or $error = "invalid parser: <$_[0]> at $context"}'
    config:             '%additional configuration parameters'
    frequency:          '?how often to generate the data, eg "monthly"[FREQUENCY]'
    timespan:           '?how much data from previous steps to include[TIMESPAN]'
hostsinfo:
  hostname[HOSTNAME]:
    max_threads:        '?(=4)maximum number of processes to run at once[INTEGER]'
    max_memory:         '?(=5G)maximum amount of memory to use at once[SIZE]'
    temporary_storage:  '?(=/tmp)Where to keep tmp files[PATH]'
    datadir:            '?Where relative paths start on this system[PATH]'
END_PROTOTYPE

my $good_config = Load(<<'END_CONFIG'); 
---
parameters:
  ignore_IPs:
    - 10/8
    - 192.168/16
hostsinfo:
  www.google.com:
    max_threads:        2
    max_memory:         1G
    temporary_storage:  /tmp
    datadir:            /data1/delogs
master_node:            www.yahoo.com
headers:                /data2/david/logtmp/headers/%NAME%
metadata:               /data2/david/logtmp/metadata/%YYYY%.%MM%.%DD%.%JOBNAME%
sources:
  -
    # ----------------------------------------------------------------
    name:                       client logs
    hosts:
     - ds16-r50
    path:                       /data1/delogs/backup/%YYYY%/%MM%/%DD%/clientlog_%loghost=\w+-r\d+%.%YYYY%-%M%-%D%-%hour=\d+%-%=\d+%
    remove_after:               90 days
    format:                     JSON
    valid_from:                 2008-03-03
    valid_to:                   2008-09-30
    # ----------------------------------------------------------------
    name:                       client logs
    hosts:
     - www.facebook.com
     - www.linkedin.com
     - www.myspace.com
     - www.microsoft.com
     - www.oracle.com
    path:                       /data1/delogs/clientlog_%loghost=\w+-r\d+%.%YYYY%-%M%-%D%-%hour%=\d+%-%=\d+%
    remove_after:               90 days
    format:                     JSON
    valid_from:                 2008-10-01
    valid_to:                   now
jobs:
  -
    # ----------------------------------------------------------------
    #
    #           Rejoin user sessions together
    #
    name:               rejoin
    source:
      - raw weblogs
      - client logs
    destination:        rejoined sessions
    #
    # no toolbar logs in this stream
    # 
    filter:             $log->{type} ne 'toolbar'
    hosts:
      - www.sun.com
      - www.ibm.com
    path:               %DATADIR%/bysession/%YYYY%/%MM%/%DD%/sessions.%BUCKET%.dirty
    buckets:            16
    bucketizer:         $log->{user_id} || $log->{machine_id} || $log->{session_id}
    valid_from:         2008-03-03
    valid_to:           yesterday
    sort_by:            $log->{user_id} || $log->{machine_id} || $log->{session_id}, $log->{timestamp}
    output_format:      Unified
    frequency:          daily
  -
    # ----------------------------------------------------------------
    #
    #           Filter the sessions to remove internal hits, and bots.
    #           Save as sessions.
    #
    name:               filter
    source:             rejoined sessions
    destination:        cleaned sessions
    group_by:           session_grouper($log)
    filter:             clean_logs($log)     
    path:               %DATADIR%/bysession/%YYYY%/%MM%/%DD%/sessions.%BUCKET%.clean
    valid_from:         2008-03-03
    valid_to:           yesterday
    output_format:      Sessions
    frequency:          daily
END_CONFIG

sub valid_parser
{
	my ($pname) = @_;
	return 1 if $pname eq 'JSON';
	return 1 if $pname eq 'Unified';
	return 1 if $pname eq 'Sessions';
	return 0;
}

sub parse_expiration_policy
{
	return 1;
}

sub validate_config
{
	my ($config, $prototype) = @_;

	my $checker = eval config_checker_source;
	die $@ if $@;

	$checker->($config, $prototype, '');
}

END { ok($finished, 'finished') }

my $c1 = eval config_checker_source;
BAIL_OUT($@) if $@;
ok(1, 'eval');

eval validate_config(clone($good_config), $prototype_config);
is($@, '', 'good config');

my $config;

sub mangle_and_test(&@)
{
	my ($mangle, $message, $name) = @_;
	$config = clone($good_config);
	&$mangle;
	eval { validate_config($config, $prototype_config) };
	like($@, qr/$message/, $name || $message);
}

mangle_and_test { $config->{jobs}[0]{output_format} = 'NewFangled' } 'invalid parser';

mangle_and_test { $config->{newthing} = 'trendy' } 'Unexpected configuration key';

mangle_and_test { delete $config->{jobs}[0]{name} } 'Missing required item';


my $prototype_config2 = <<'END_PROTOTYPE';
alcatraz:
  dbi:
    dsn:                'Alcatraz rules Database DSN[STRING]'
    user:               '?Alcatraz rules Database user[STRING]'
    rootuser:           '?Alcatraz rules Database password[STRING]'
    pass:               '?Alcatraz rules Database super user[STRING]'
    rootpass:           '?Alcatraz rules Database super user password[STRING]'
  corr_url_scan:
    sources:            '*<,>List of cat_data sources to update[INTEGER]'
    all:                '?<Yes>Update all rules (url rules included) or just domain path rules[BOOLEAN]'
  corr_clean:           '%old-style config junk'
  corr_insert:          '%old-style config junk'
  corr_insert_db:       '%old-style config junk'
END_PROTOTYPE

my $aconfig = Load(<<'END_ACONFIG');
---
alcatraz:
  dbi:
    dsn: dbi:mysql:database=corrections;host=127.0.0.1
    user: david
    pass: spiral
    #user: foo
    #pass: bar
  corr_clean:
    source: low_content
    user_id: 1
  corr_insert_db:
    source: low_content
    user_id: 1
END_ACONFIG

eval validate_config($aconfig, $prototype_config2);
is($@, '', 'other style');

$finished = 1;

1;
