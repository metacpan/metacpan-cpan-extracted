package CAPE::Utils;

use 5.006;
use strict;
use warnings;
use JSON;
use Config::Tiny;
use DBI;
use File::Slurp qw(append_file write_file read_file write_file);
use Config::Tiny;
use IPC::Cmd qw[ run ];
use Text::ANSITable;
use File::Spec;
use IPC::Cmd qw(run);
use Net::Subnet;
use Sys::Hostname;
use Sys::Syslog;
use File::Copy;

=head1 NAME

CAPE::Utils - A helpful library for with CAPE.

=head1 VERSION

Version 2.8.0

=cut

our $VERSION = '2.8.0';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use CAPE::Utils;

    my $cape_util=CAPE::Utils->new();

    my $sub_results=$cape_util->submit(items=>@to_detonate,unique=>0, quiet=>1);
    use JSON;
    print encode_json($sub_results)."\n";

=head1 METHODS

=head2 new

Initiates the object. One argument is taken and that is the
path to the INI config file. The default is '/usr/local/etc/cape_utils.ini'
and if not found, the defaults will be used.

    my $cape_util=CAPE::Utils->new('/path/to/some/config.ini');

=cut

sub new {
	my $ini = $_[1];

	if ( !defined($ini) ) {
		$ini = '/usr/local/etc/cape_utils.ini';
	}

	my $base_config = {
		'_' => {
			dsn                 => 'dbi:Pg:dbname=cape',
			user                => 'cape',
			pass                => '',
			base                => '/opt/CAPEv2/',
			eve                 => '/opt/CAPEv2/log/eve.json',
			poetry              => 1,
			fail_all            => 0,
			pending_columns     => 'id,target,package,timeout,ET,route,options,clock,added_on',
			running_columns     => 'id,target,package,timeout,ET,route,options,clock,added_on,started_on,machine',
			task_columns        => 'id,target,package,timeout,ET,route,options,clock,added_on,latest,machine,status',
			running_target_clip => 1,
			running_time_clip   => 1,
			pending_target_clip => 1,
			pending_time_clip   => 1,
			task_target_clip    => 1,
			task_time_clip      => 1,
			table_color         => 'Text::ANSITable::Standard::NoGradation',
			table_border        => 'ASCII::None',
			set_clock_to_now    => 1,
			timeout             => 200,
			enforce_timeout     => 0,
			subnets             => '192.168.0.0/16,127.0.0.1/8,::1/128,172.16.0.0/12,10.0.0.0/8',
			apikey              => '',
			auth                => 'ip',
			incoming            => '/malware/client-incoming',
			incoming_json       => '/malware/incoming-json',
			eve_look_back       => 360,
			malscore            => 0,
		},
	};

	my $config = Config::Tiny->read( $ini, 'utf8' );
	if ( !defined($config) ) {
		$config = $base_config;
	} else {
		my @to_merge = keys( %{ $base_config->{_} } );
		foreach my $item (@to_merge) {
			if ( !defined( $config->{_}->{$item} ) ) {
				$config->{_}->{$item} = $base_config->{_}->{$item};
			}
		}
	}

	# init the object
	my $self = { config => $config, };
	bless $self;

	return $self;
} ## end sub new

=head2 connect

Return a DBH from DBI->connect for the CAPE SQL server.

This will die with the output from $DBI::errstr if it fails.

    my $dbh = $cape->connect;

=cut

sub connect {
	my $self = $_[0];

	my $dbh = DBI->connect( $self->{config}->{_}->{dsn}, $self->{config}->{_}->{user}, $self->{config}->{_}->{pass} )
		|| die($DBI::errstr);

	return $dbh;
}

=head2 fail

Set one or more pending tasks to failed as below.

    UPDATE tasks SET status = 'failed_processing' WHERE status = 'pending'

The following options are also supported.

    - where :: Additional SQL where statements to add. Something must
               be specified for this, unless fail_all in the config is
               true. Otherwise this method will die.

    my $rows=$cape_util->fail( where=>"target like '%foo%'");

=cut

sub fail {
	my ( $self, %opts ) = @_;

	if ( defined( $opts{where} ) && $opts{where} =~ /\;/ ) {
		die '$opts{where},"' . $opts{where} . '", contains a ";"';
	}

	if ( !defined( $opts{where} ) && !$self->{config}->{_}->{fail_all} ) {
		die "fail_all is disabled and nothing specified for where";
	}

	my $dbh = $self->connect;

	my $statement = "UPDATE tasks SET status = 'failed_processing' WHERE status = 'pending'";

	if ( defined( $opts{where} ) ) {
		$statement = $statement . ' AND ' . $opts{where};
	}

	$statement = $statement . ';';

	my $sth = $dbh->prepare($statement);

	$sth->execute;

	my $rows = $sth->rows;

	$sth->finish;
	$dbh->disconnect;

	return $rows;
} ## end sub fail

=head2 get_pending_count

Get pending count pending tasks.

    - where :: And additional where part of the SQL statement. "and" will
               automatically be used to join it with the rest of the
               statement. May not contain a ';'.
        - Default :: undef

    my $count=$cape_util->get_pending_count;

=cut

sub get_pending_count {
	my ( $self, %opts ) = @_;

	if ( defined( $opts{where} ) && $opts{where} =~ /\;/ ) {
		die '$opts{where},"' . $opts{where} . '", contains a ";"';
	}

	my $dbh = $self->connect;

	my $statement = "select * from tasks where status = 'pending'";
	if ( defined( $opts{where} ) ) {
		$statement = $statement . ' AND ' . $opts{where};
	}

	my $sth = $dbh->prepare($statement);
	$sth->execute;

	my $rows = $sth->rows;

	$sth->finish;
	$dbh->disconnect;

	return $rows;
} ## end sub get_pending_count

=head2 get_pending

Returns a arrah ref of hash refs of rows from the tasks table where the
status is set to pending via "select * from tasks where status = 'pending'"

    - where :: And additional where part of the SQL statement. "and" will
               automatically be used to join it with the rest of the
               statement. May not contain a ';'.
        - Default :: undef

    - where :: Additional SQL where statements to add.

=cut

sub get_pending {
	my ( $self, %opts ) = @_;

	if ( defined( $opts{where} ) && $opts{where} =~ /\;/ ) {
		die '$opts{where},"' . $opts{where} . '", contains a ";"';
	}

	my $dbh = $self->connect;

	my $statement = "select * from tasks where status = 'pending'";
	if ( defined( $opts{where} ) ) {
		$statement = $statement . ' AND ' . $opts{where};
	}

	my $sth = $dbh->prepare($statement);
	$sth->execute;

	my $row;
	my @rows;
	while ( $row = $sth->fetchrow_hashref ) {
		push( @rows, $row );
	}

	$sth->finish;
	$dbh->disconnect;

	return \@rows;
} ## end sub get_pending

=head2 get_pending_table

Generates a ASCII table for pending.

The following config variables can are relevant to this and
may be overriden.

    table_border
    table_color
    pending_columns
    pending_target_clip
    pending_time_clip

The following options are also supported.

    - where :: And additional where part of the SQL statement. "and" will
               automatically be used to join it with the rest of the
               statement. May not contain a ';'.
        - Default :: undef

    print $cape_util->get_pending_table( pending_columns=>'id,package');

=cut

sub get_pending_table {
	my ( $self, %opts ) = @_;

	my @overrides = ( 'table_border', 'table_color', 'pending_columns', 'pending_target_clip', 'pending_time_clip' );
	foreach my $override (@overrides) {
		if ( !defined( $opts{$override} ) ) {
			$opts{$override} = $self->{config}->{_}->{$override};
		}
	}

	my $rows = $self->get_pending( where => $opts{where} );

	my $tb = Text::ANSITable->new;
	$tb->border_style( $opts{table_border} );
	$tb->color_theme( $opts{table_color} );

	my @columns    = split( /,/, $opts{pending_columns} );
	my $header_int = 0;
	my $padding    = 0;
	foreach my $header (@columns) {
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }

		$tb->set_column_style( $header_int, pad => $padding );

		$header_int++;
	}

	$tb->columns( \@columns );

	my @td;
	foreach my $row ( @{$rows} ) {
		my @new_line;
		foreach my $column (@columns) {
			if ( $column eq 'ET' ) {
				$row->{ET} = $row->{enforce_timeout};
			}

			if ( defined( $row->{$column} ) ) {
				if ( $column eq 'ET' ) {
					$row->{ET} = $row->{enforce_timeout};
				}

				if ( ( $column eq 'clock' || $column eq 'added_on' ) && $opts{pending_time_clip} ) {
					$row->{$column} =~ s/\.[0-9]+$//;
				} elsif ( $column eq 'target' && $opts{pending_target_clip} ) {
					$row->{target} =~ s/^.*\///;
				}
				push( @new_line, $row->{$column} );
			} else {
				push( @new_line, '' );
			}
		} ## end foreach my $column (@columns)

		push( @td, \@new_line );
	} ## end foreach my $row ( @{$rows} )

	$tb->add_rows( \@td );

	return $tb->draw;
} ## end sub get_pending_table

=head2 get_running

Returns a array ref of hash refs of rows from the tasks table where the
status is set to pending.

     select * from tasks where status = 'running'

The statement above is used to find running tasks.

    - where :: And additional where part of the SQL statement. "and" will
               automatically be used to join it with the rest of the
               statement. May not contain a ';'.
        - Default :: undef

    use Data::Dumper;

    my $running=$cape_utils->get_running;
    print Dumper($running);

=cut

sub get_running {
	my ( $self, %opts ) = @_;

	if ( defined( $opts{where} ) && $opts{where} =~ /\;/ ) {
		die '$opts{where},"' . $opts{where} . '", contains a ";"';
	}

	my $dbh = $self->connect;

	my $statement = "select * from tasks where status = 'running'";
	if ( defined( $opts{where} ) ) {
		$statement = $statement . ' AND ' . $opts{where};
	}

	my $sth = $dbh->prepare($statement);
	$sth->execute;

	my $row;
	my @rows;
	while ( $row = $sth->fetchrow_hashref ) {
		push( @rows, $row );
	}

	$sth->finish;
	$dbh->disconnect;

	return \@rows;
} ## end sub get_running

=head2 get_running_count

Get pending count running tasks.

     select * from tasks where status = 'running'

The statement above is used to find running tasks.

    - where :: And additional where part of the SQL statement. "and" will
               automatically be used to join it with the rest of the
               statement. May not contain a ';'.
        - Default :: undef

    my $count=$cape_util->get_running_count;

=cut

sub get_running_count {
	my ( $self, %opts ) = @_;

	if ( defined( $opts{where} ) && $opts{where} =~ /\;/ ) {
		die '$opts{where},"' . $opts{where} . '", contains a ";"';
	}

	my $dbh = $self->connect;

	my $statement = "select * from tasks where status = 'running'";
	if ( defined( $opts{where} ) ) {
		$statement = $statement . ' AND ' . $opts{where};
	}

	my $sth = $dbh->prepare($statement);
	$sth->execute;

	my $rows = $sth->rows;

	$sth->finish;
	$dbh->disconnect;

	return $rows;
} ## end sub get_running_count

=head2 get_running_table

Generates a ASCII table for pending.

The following config variables can are relevant to this and
may be overriden.

    table_border
    table_color
    running_columns
    running_target_clip
    running_time_clip

The statement below is used to find running tasks.

     select * from tasks where status = 'running'

The following options are also supported.

    - where :: And additional where part of the SQL statement. "and" will
               automatically be used to join it with the rest of the
               statement. May not contain a ';'.
        - Default :: undef

    print $cape_util->get_pending_table( pending_columns=>'id,package');

=cut

sub get_running_table {
	my ( $self, %opts ) = @_;

	my @overrides = ( 'table_border', 'table_color', 'running_columns', 'running_target_clip', 'running_time_clip' );
	foreach my $override (@overrides) {
		if ( !defined( $opts{$override} ) ) {
			$opts{$override} = $self->{config}->{_}->{$override};
		}
	}

	my $rows = $self->get_running( where => $opts{where} );

	my $tb = Text::ANSITable->new;
	$tb->border_style( $opts{table_border} );
	$tb->color_theme( $opts{table_color} );

	my @columns    = split( /,/, $opts{running_columns} );
	my $header_int = 0;
	my $padding    = 0;
	foreach my $header (@columns) {
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }

		$tb->set_column_style( $header_int, pad => $padding );

		$header_int++;
	}

	$tb->columns( \@columns );

	my @td;
	foreach my $row ( @{$rows} ) {
		my @new_line;
		foreach my $column (@columns) {
			if ( $column eq 'ET' ) {
				$row->{ET} = $row->{enforce_timeout};
			}

			if ( defined( $row->{$column} ) ) {
				if ( $column eq 'ET' ) {
					$row->{ET} = $row->{enforce_timeout};
				}

				if ( ( $column eq 'clock' || $column eq 'added_on' || $column eq 'started_on' )
					&& $opts{running_time_clip} )
				{
					$row->{$column} =~ s/\.[0-9]+$//;
				} elsif ( $column eq 'target' && $opts{running_target_clip} ) {
					$row->{target} =~ s/^.*\///;
				}
				push( @new_line, $row->{$column} );
			} else {
				push( @new_line, '' );
			}
		} ## end foreach my $column (@columns)

		push( @td, \@new_line );
	} ## end foreach my $row ( @{$rows} )

	$tb->add_rows( \@td );

	return $tb->draw;
} ## end sub get_running_table

=head2 get_tasks

Returns a array ref of hash refs of rows from the tasks table where the
status is set to pending.

    - where :: The where part of the SQL statement. May not contain a ';'.
        - Default :: undef

    - order :: Column to order by.
        - Default :: id

    - limit :: Number of items to return.
        - Default :: 100

    - direction :: Direction to order in.
        - Default :: desc

    use Data::Dumper;

A small example showing getting running, ordering by category, and limiting to 20.

    my $tasks=$cape_utils->get_tasks(where=>"status = 'running'", limit=>20, order=>"category", direction=>'desc');
    print Dumper($running);

=cut

sub get_tasks {
	my ( $self, %opts ) = @_;

	if ( defined( $opts{where} ) && $opts{where} =~ /\;/ ) {
		die '$opts{where},"' . $opts{where} . '", contains a ";"';
	}

	if ( defined( $opts{order} ) && $opts{order} !~ /^[0-9a-zA-Z]+$/ ) {
		die '$opts{order},"' . $opts{order} . '", does not match /^[0-9a-zA-Z]+$/';
	} else {
		$opts{order} = 'id';
	}

	if ( defined( $opts{limit} ) && $opts{limit} !~ /^[0-9]+$/ ) {
		die '$opts{limit},"' . $opts{limit} . '", does not match /^[0-9]+$/';
	} else {
		$opts{limit} = '100';
	}

	if ( defined( $opts{direction} ) ) {
		$opts{direction} = lc( $opts{direction} );
	}
	if ( defined( $opts{direction} ) && ( $opts{direction} ne 'desc' || $opts{direction} ne 'asc' ) ) {
		die '$opts{diirection},"' . $opts{direction} . '", does not match desc or asc';
	} else {
		$opts{direction} = 'desc';
	}

	my $dbh;
	eval { $dbh = $self->connect or die $DBI::errstr };
	if ($@) {
		die( 'Failed to connect to the DB... ' . $@ );
	}

	my $statement = "select * from tasks";
	if ( defined( $opts{where} ) ) {
		$statement = $statement . ' where ' . $opts{where};
	}

	$statement = $statement . ' order by ' . $opts{order} . ' ' . $opts{direction} . ' limit ' . $opts{limit} . ';';

	my $sth;
	eval {
		$sth = $dbh->prepare($statement) or die $DBI::errstr;
		$sth->execute                    or die $DBI::errstr;
	};
	if ($@) {
		die( 'Failed to connect to run the search... ' . $@ );
	}

	my $row;
	my @rows;
	while ( $row = $sth->fetchrow_hashref ) {
		push( @rows, $row );
	}

	$sth->finish;
	$dbh->disconnect;

	return \@rows;
} ## end sub get_tasks

=head2 get_tasks_count

Gets a count of tasks.

    - where :: The where part of the SQL statement. May not contain a ';'.
        - Default :: undef

    use Data::Dumper;

A small example showing getting running, ordering by category, and limiting to 20.

    my $count=$cape_util->get_tasks_count(where=>"status = 'running'", limit=>20, order=>"category", direction=>'desc');

=cut

sub get_tasks_count {
	my ( $self, %opts ) = @_;

	if ( defined( $opts{where} ) && $opts{where} =~ /\;/ ) {
		die '$opts{where},"' . $opts{where} . '", contains a ";"';
	}

	my $dbh = $self->connect;

	my $statement = "select * from tasks";
	if ( defined( $opts{where} ) ) {
		$statement = $statement . ' ' . $opts{where};
	}

	my $sth = $dbh->prepare($statement);
	$sth->execute;

	my $rows = $sth->rows;

	$sth->finish;
	$dbh->disconnect;

	return $rows;
} ## end sub get_tasks_count

=head2 get_tasks_table

Generates a ASCII table for tasks.

The following config variables can are relevant to this and
may be overriden.

    table_border
    table_color
    task_columns
    task_target_clip
    task_time_clip

The following options are also supported.

    - where :: Additional SQL where statements to add.
        - Default :: undef

    - order :: Column to order by.
        - Default :: id

    - limit :: Number of items to return.
        - Default :: 100

    - direction :: Direction to order in.
        - Default :: desc

    print $cape_util->get_tasks_table( where => "status = 'reported'");

=cut

sub get_tasks_table {
	my ( $self, %opts ) = @_;

	my @overrides = ( 'table_border', 'table_color', 'task_columns', 'task_target_clip', 'task_time_clip' );
	foreach my $override (@overrides) {
		if ( !defined( $opts{$override} ) ) {
			$opts{$override} = $self->{config}->{_}->{$override};
		}
	}

	my $rows = $self->get_tasks(
		where     => $opts{where},
		order     => $opts{order},
		limit     => $opts{limit},
		direction => $opts{direction}
	);

	my $tb = Text::ANSITable->new;
	$tb->border_style( $opts{table_border} );
	$tb->color_theme( $opts{table_color} );

	my @columns    = split( /,/, $opts{task_columns} );
	my $header_int = 0;
	my $padding    = 0;
	foreach my $header (@columns) {
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }

		$tb->set_column_style( $header_int, pad => $padding );

		$header_int++;
	}

	$tb->columns( \@columns );

	my @td;
	my @latest_check = (
		'started_on',             'analysis_started_on',   'analysis_finished_on',   'analysis_finished_on',
		'processing_finished_on', 'signatures_started_on', 'signatures_finished_on', 'reporting_started_on',
		'reporting_finished_on',  'completed_on'
	);
	foreach my $row ( @{$rows} ) {
		my @new_line;
		foreach my $column (@columns) {
			if ( $column eq 'ET' ) {
				$row->{ET} = $row->{enforce_timeout};
			}

			if ( $column eq 'latest' ) {
				$row->{latest} = '';
				foreach my $item (@latest_check) {
					if ( defined( $row->{$item} ) ) {
						$row->{latest} = $row->{$item};
					}
				}
			}

			if ( defined( $row->{$column} ) ) {
				if ( $column eq 'ET' ) {
					$row->{ET} = $row->{enforce_timeout};
				}

				if (
					(
						   $column eq 'clock'
						|| $column eq 'added_on'
						|| $column eq 'started_on'
						|| $column eq 'completed_on'
						|| $column eq 'analysis_started_on'
						|| $column eq 'analysis_finished_on'
						|| $column eq 'processing_started_on'
						|| $column eq 'processing_finished_on'
						|| $column eq 'signatures_started_on'
						|| $column eq 'signatures_finished_on'
						|| $column eq 'reporting_started_on'
						|| $column eq 'reporting_finished_on'
						|| $column eq 'latest'
					)
					&& $opts{task_time_clip}
					)
				{
					$row->{$column} =~ s/\.[0-9]+$//;
				} elsif ( $column eq 'target' && $opts{task_target_clip} ) {
					$row->{target} =~ s/^.*\///;
				}
				push( @new_line, $row->{$column} );
			} else {
				push( @new_line, '' );
			}
		} ## end foreach my $column (@columns)

		push( @td, \@new_line );
	} ## end foreach my $row ( @{$rows} )

	$tb->add_rows( \@td );

	return $tb->draw;
} ## end sub get_tasks_table

=head2 munge

Munges the specified report file.

    $cape_utils->munge(file=>$report_file);

=cut

sub munge {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{file} ) ) {
		die('No file specified via $opts{file}');
	}

	if ( !-f $opts{file} ) {
		die( '"' . $opts{file} . '" is not a file' );
	}

	# create a backup copy prior to munging
	# also only create it if it does not exist
	my $pre_munge_file = $opts{file} . '.pre-cape_utils_munge';
	if ( !-f $pre_munge_file ) {
		copy( $opts{file}, $pre_munge_file )
			|| die( 'Creating pre-munge file for "' . $opts{file} . '" failed... ' . $! );
	} else {
		warn( 'Pre-munge file, "' . $pre_munge_file . '", already exists, skippying coppying' );
	}

	# read the file on in
	my $report;
	eval { $report = decode_json( read_file( $opts{file} ) ); };
	if ($@) {
		die( 'Failed to parse "' . $opts{file} . '"... ' . $@ );
	}

	# find the munge keys
	my @sections = sort( keys( %{ $self->{config} } ) );
	my @munges;
	foreach my $item (@sections) {
		if ( $item =~ /^munge\_/ ) {
			push( @munges, $item );
		}
	}

	# should be set by a munge if it made a change
	my $changed = 0;
	# scratch space for between all munges
	my %all_scratch;
	foreach my $item (@munges) {
		# scratch space for the munges to use
		my %scratch;

		# only process the specified munge if we have both keys
		if ( defined( $self->{config}{$item}{check} ) && defined( $self->{config}{$item}{munge} ) ) {
			# now that we know we have the keys, get the full file path if needed
			my $check_file = $self->{config}{$item}{check};
			my $munge_file = $self->{config}{$item}{munge};
			if ( $check_file !~ /^\// && $check_file !~ /^.\// && $check_file !~ /^..\// ) {
				$check_file = '/usr/local/etc/cape_utils_munge/' . $check_file;
			}
			if ( $munge_file !~ /^\// && $munge_file !~ /^.\// && $munge_file !~ /^..\// ) {
				$munge_file = '/usr/local/etc/cape_utils_munge/' . $munge_file;
			}

			# figure out if we need to munge it or not
			my $munge_it = 0;
			eval {
				my $check_code = read_file($check_file);
				eval($check_code);
				if ($@) {
					die($@);
				}
			};
			if ($@) {
				warn( 'Munge "' . $item . '" errored during the check... ' . $@ );

				# override this even if set before dying
				$munge_it = 0;
			}

			# if so, try to munge it
			if ($munge_it) {
				eval {
					my $munge_code = read_file($munge_file);
					eval($munge_code);
					if ($@) {
						die($@);
					}
				};
				if ($@) {
					warn( 'Munge "' . $item . '" errored during the munge... ' . $@ );
				}
			} ## end if ($munge_it)
		} else {
			warn( 'Section "' . $item . '" missing either the key "check" or munge"' );
		}
	} ## end foreach my $item (@munges)

	# save the file if it changed
	if ($changed) {
		# if changed, update the malscore
		my $malscore = 0.0;
		my $sig_int  = 0;
		while ( defined( $report->{signatures}[$sig_int] ) ) {
			if ( $report->{signatures}[$sig_int]{severity} ) {
				$malscore += $report->{signatures}[$sig_int]{weight} * 0.5
					* ( $report->{signatures}[$sig_int]{confidence} / 100 );
			} else {
				$malscore
					+= $report->{signatures}[$sig_int]{weight}
					* ( $report->{signatures}[$sig_int]{weight} - 1 )
					* ( $report->{signatures}[$sig_int]{confidence} / 100 );
			}

			$sig_int++;
		} ## end while ( defined( $report->{signatures}[$sig_int...]))
		if ( $malscore > 10.0 ) {
			$malscore = 10.0;
		}
		$report->{malscore} = $malscore;

		eval { write_file( $opts{file}, encode_json($report) ); };
		if ($@) {
			die( 'Failed to encode updated report post munging and write it to "' . $opts{file} . '"... ' . $@ );
		}
	} ## end if ($changed)

	return 1;
} ## end sub munge

=head2 search

Searches the list of tasks. By default everything will be return ed.

    - where :: Additional SQL where statements to use for searching.
               May not contain a ';'.
      - Default :: undef

Addtionally there are also helpers for searching. These may not contain either a /\'/
or a /\\/. They will be joined via and.

The following are handled as a simple equality.

    - timeout
    - memory
    - enforce_timeout
    - timedout

The following are numeric. Each one may accept multiple
comma sperated values. The equalities =, >,>=, <=, and !
are supported. If no equality is specified, then = is used.

    - id
    - timeout
    - priority
    - dropped_files
    - running_processes
    - api_calls
    - domains
    - signatures_total
    - signatures_alert
    - files_written
    - registry_keys_modified
    - crash_issues
    - anti_issues
    - sample_id
    - machine_id

    # will result in id >= 3 and id < 44
    id => '>=3,<44'

    # either of these will be id = 4
    id => '=4'
    id => '4'

The following are string items. As is, they
are evaluated as a simple equality. If ending with
ending in '_like', they will be evaluated as a like.

    - target
    - category
    - custom
    - machine
    - package
    - route
    - tags_tasks
    - options
    - platform

    # becomes... target = 'foo'
    target => 'foo'

    # becomes... target like 'foo%'
    target_like => 'foo%'

=cut

sub search {
	my ( $self, %opts ) = @_;

	if ( defined( $opts{where} ) && $opts{where} =~ /\;/ ) {
		die '$opts{where},"' . $opts{where} . '", contains a ";"';
	}

	#
	# make sure all the set variables are not dangerous or potentially dangerous
	#

	my @to_check = (
		'id',            'target',                 'route',            'machine',
		'timeout',       'priority',               'route',            'tags_tasks',
		'options',       'clock',                  'added_on',         'started_on',
		'completed_on',  'status',                 'dropped_files',    'running_processes',
		'api_calls',     'domains',                'signatures_total', 'signatures_alert',
		'files_written', 'registry_keys_modified', 'crash_issues',     'anti_issues',
		'timedout',      'sample_id',              'machine_id',       'parent_id',
		'tlp',           'category',               'package'
	);

	foreach my $var_to_check (@to_check) {
		if ( defined( $opts{$var_to_check} ) && $opts{$var_to_check} =~ /[\\\']/ ) {
			die( '"' . $opts{$var_to_check} . '" for "' . $var_to_check . '" matched /[\\\']/' );
		}
	}

	#
	# init the SQL statement
	#

	my $sql = "select * from tasks where id >= 0";

	if ( defined( $opts{where} ) ) {
		$sql = $sql . ' AND ' . $opts{where};
	}

	#
	# add simple items
	#

	my @simple = ( 'timeout', 'memory', 'enforce_timeout', 'timedout' );

	foreach my $item (@simple) {
		if ( defined( $opts{$item} ) ) {
			$sql = $sql . " and " . $item . " = '" . $opts{$item} . "'";
		}
	}

	#
	# add numeric items
	#

	my @numeric = (
		'id',                'timeout',       'priority',               'dropped_files',
		'running_processes', 'api_calls',     'domains',                'signatures_total',
		'signatures_alert',  'files_written', 'registry_keys_modified', 'crash_issues',
		'anti_issues',       'sample_id',     'machine_id'
	);

	foreach my $item (@numeric) {
		if ( defined( $opts{$item} ) ) {

			# remove and tabs or spaces
			$opts{$item} =~ s/[\ \t]//g;
			my @arg_split = split( /\,/, $opts{$item} );

			# process each item
			foreach my $arg (@arg_split) {

				# match the start of the item
				if ( $arg =~ /^[0-9]+$/ ) {
					$sql = $sql . " and " . $item . " = '" . $arg . "'";
				} elsif ( $arg =~ /^\=[0-9]+$/ ) {
					$arg =~ s/^\=//;
					$sql = $sql . " and " . $item . " <= '" . $arg . "'";
				} elsif ( $arg =~ /^\<\=[0-9]+$/ ) {
					$arg =~ s/^\<\=//;
					$sql = $sql . " and " . $item . " <= '" . $arg . "'";
				} elsif ( $arg =~ /^\<[0-9]+$/ ) {
					$arg =~ s/^\<//;
					$sql = $sql . " and " . $item . " < '" . $arg . "'";
				} elsif ( $arg =~ /^\>\=[0-9]+$/ ) {
					$arg =~ s/^\>\=//;
					$sql = $sql . " and " . $item . " >= '" . $arg . "'";
				} elsif ( $arg =~ /^\>[0-9]+$/ ) {
					$arg =~ s/^\>\=//;
					$sql = $sql . " and " . $item . " > '" . $arg . "'";
				} elsif ( $arg =~ /^\![0-9]+$/ ) {
					$arg =~ s/^\!//;
					$sql = $sql . " and " . $item . " != '" . $arg . "'";
				} elsif ( $arg =~ /^$/ ) {

					# only exists for skipping when some one has passes something starting
					# with a ,, ending with a,, or with ,, in it.
				} else {
					# if we get here, it means we don't have a valid use case for what ever was passed and should error
					die( '"' . $arg . '" does not appear to be a valid item for a numeric search for the ' . $item );
				}
			} ## end foreach my $arg (@arg_split)
		} ## end if ( defined( $opts{$item} ) )
	} ## end foreach my $item (@numeric)

	#
	# handle string items
	#

	my @strings
		= ( 'target', 'category', 'custom', 'machine', 'package', 'route', 'tags_tasks', 'options', 'platform', );

	foreach my $item (@strings) {
		if ( defined( $opts{$item} ) ) {
			if ( defined( $opts{ $item . '_like' } ) && $opts{ $item . '_like' } ) {
				$sql = $sql . " and host like '" . $opts{$item} . "'";
			} else {
				$sql = $sql . " and " . $item . " = '" . $opts{$item} . "'";
			}
		}
	}

	#
	# finalize it and search
	#

	$sql = $sql . ';';

	my $dbh = $self->connect;
	my $sth = $dbh->prepare($sql);

	$sth->execute;

	my $rows;

	return $rows;
} ## end sub search

=head2 submit

Submits files to CAPE.

    - clock :: Timestamp to use for setting the clock to of the VM for
      when executing the item. If left undefined, it will be
      autogenerated.
      - Format :: mm-dd-yyy HH:MM:ss

    - items :: A array ref of items to submit. If a directory is listed in
      here, it will be read, but subdirectories will not be recursed. They
      will be ignored.

    - name_regex :: Regex to use for matching items in a submitted dir.
      Only used if the a submitted item is a dir.
      - Default :: undef

    - mime_regex :: Array ref of desired mime types to match via
      regex. Only used if the a submitted item is a dir.
      - Default :: undef

    - timeout :: Value to use for timeout. Set to 0 to not enforce.
      - Default :: 200

    - machine :: The machine to use for this. If not defined, first
      available will be used.
      - Default :: undef

    - package :: Package to use, if not letting CAPE decide.
      - Default :: undef

    - options :: Option string to be passed via --options.
      - Default :: undef

    - random :: If it should randomize the order of submission.
      - Default :: 1

    - tags :: Tags to be passed to the script via --tags.
      - Default :: undef

    - platform :: What to pass to --platform.
      - Default :: undef

    - custom :: Any custom values to pass via --custom.
      - Default :: undef

    - enforce_timeout :: Force it to run the entire period.
      - Default :: 0

    - unique :: Only submit it if it is unique.
        - Default :: 0

    -quiet :: Do not print the results.
        - Default :: 0

The retuned value is a hash ref where the keys are successfully submitted files
and values of those keys is the task ID.

    my $sub_results=$cape_util->submit(items=>@to_detonate,unique=>0, quiet=>1);
    use JSON;
    print encode_json($sub_results)."\n";

=cut

sub submit {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{items}[0] ) ) {
		die 'No items to submit passed';
	}

	if ( !defined( $opts{clock} ) && $self->{config}->{_}->{set_clock_to_now} ) {
		$opts{clock} = $self->timestamp;
	}

	if ( !defined( $opts{timeout} ) ) {
		$opts{timeout} = $self->{config}->{_}->{timeout};
	}

	if ( !defined( $opts{enforce_timeout} ) ) {
		$opts{enforce_timeout} = $self->{config}->{_}->{enforce_timeout};
	}

	my @to_submit;

	foreach my $item ( @{ $opts{items} } ) {
		if ( -f $item ) {
			push( @to_submit, File::Spec->rel2abs($item) );
		} elsif ( -d $item ) {
			opendir( my $dh, $item );
			while ( readdir($dh) ) {
				if ( -f $item . '/' . $_ ) {
					push( @to_submit, File::Spec->rel2abs( $item . '/' . $_ ) );
				}
			}
			closedir($dh);
		}
	} ## end foreach my $item ( @{ $opts{items} } )

	chdir( $self->{config}->{_}->{base} ) || die( 'Unable to CD to "' . $self->{config}->{_}->{base} . '"' );

	my @to_run = ();

	if ( $self->{config}->{_}->{poetry} ) {
		push( @to_run, 'poetry', 'run' );
	}

	push( @to_run, 'python3', $self->{config}->{_}->{base} . '/utils/submit.py' );

	if ( defined( $opts{clock} ) ) {
		push( @to_run, '--clock', $opts{clock} );
	}

	if ( defined( $opts{unique} ) && $opts{unique} ) {
		push( @to_run, '--unique' );
	}

	if ( defined( $opts{timeout} ) ) {
		push( @to_run, '--timeout', $opts{timeout} );
	}

	if ( $opts{enforce_timeout} && $opts{enforce_timeout} ) {
		push( @to_run, '--enforce-timeout' );
	}

	if ( defined( $opts{package} ) ) {
		push( @to_run, '--package', $opts{package} );
	}

	if ( defined( $opts{machine} ) ) {
		push( @to_run, '--machine', $opts{machine} );
	}

	if ( defined( $opts{options} ) ) {
		push( @to_run, '--options', $opts{options} );
	}

	if ( defined( $opts{tags} ) ) {
		push( @to_run, '--tags', $opts{tags} );
	}

	my $added = {};
	foreach (@to_submit) {
		my @tmp_to_run = @to_run;
		push( @tmp_to_run, $_ );
		my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) = run(
			command => \@tmp_to_run,
			verbose => 0
		);
		my $results = join( '', @{$full_buf} );
		if ( !$opts{quiet} ) {
			print $results;
		}

		my @results_split = split( /\n/, $results );
		foreach my $item (@results_split) {
			$item =~ s/\e\[[0-9;]*m(?:\e\[K)?//g;
			chomp($item);
			if ( $item =~ /^Success\:\ File\ \".*\"\ added\ as\ task\ with\ ID\ \d+$/ ) {
				$item =~ s/^Success\:\ File\ \"//;
				my ( $file, $task ) = split( /\"\ added\ as\ task\ with\ ID\ /, $item );
				$added->{$file} = $task;
			}
		}
	} ## end foreach (@to_submit)

	return $added;
} ## end sub submit

=head2 timestamp

Creates a timestamp to be used with utils/submit. localtime
is used to get the current time.

    print $cape_util->timestamp."\n";

=cut

sub timestamp {
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime;
	$year += 1900;
	$mon++;
	if ( $sec < 10 ) {
		$sec = '0' . $sec;
	}
	if ( $min < 10 ) {
		$min = '0' . $min;
	}
	if ( $hour < 10 ) {
		$hour = '0' . $hour;
	}
	if ( $mon < 10 ) {
		$mon = '0' . $mon;
	}
	if ( $mday < 10 ) {
		$mday = '0' . $mday;
	}

	return $mon . '-' . $mday . '-' . $year . ' ' . $hour . ':' . $min . ':' . $sec;
} ## end sub timestamp

=head2 shuffle

Performa a Fisher Yates shuffle on the passed array ref.

=cut

sub shuffle {
	my $self  = shift;
	my $array = shift;
	my $i;
	for ( $i = @$array; --$i; ) {
		my $j = int rand( $i + 1 );
		next if $i == $j;
		@$array[ $i, $j ] = @$array[ $j, $i ];
	}
	return $array;
} ## end sub shuffle

=head2 check_remote

Checks the remote connection.

Two variablesare required, API key and IP.

    $results=$cape_utils->check_remote(apikey=>$apikey, remote=>$remote_ip);
    if (!$results){
        print "unauthed\n";
        return;
    }

=cut

sub check_remote {
	my ( $self, %opts ) = @_;

	# if we don't have a API key, we can only auth via IP
	if ( ( $self->{config}->{_}->{auth} ne 'ip' || $self->{config}->{_}->{auth} ne 'either' )
		&& !defined( $opts{apikey} ) )
	{
		return 0;
	}

	# make sure the API key is what it is expecting if we are not using IP only
	if (   $self->{config}->{_}->{auth} ne 'ip'
		&& defined( $opts{apikey} )
		&& $opts{apikey} ne $self->{config}->{_}->{apikey} )
	{
		# don't return if it is either as IP may still go off
		if ( $self->{config}->{_}->{auth} ne 'either' ) {
			return 0;
		}
	}

	# if we have a apikey and method is set to apikey or either, we are good to return true
	if ( defined( $opts{apikey} )
		&& ( $self->{config}->{_}->{auth} ne 'apikey' || $self->{config}->{_}->{auth} ne 'either' ) )
	{
		return 1;
	}

	# can't do anything else with out a IP
	if ( !defined( $opts{ip} ) ) {
		return 0;
	}

	my $subnets_string = $self->{config}->{_}->{subnets};
	$subnets_string =~ s/[\ \t]+//g;
	$subnets_string =~ s/\,+/,/g;
	my @subnets_split = split( /,/, $subnets_string );
	my @subnets;
	foreach my $item (@subnets_split) {
		if ( $item =~ /^[\:A-Fa-f0-9]+$/ ) {
			push( @subnets, $item . '/128' );
		} elsif ( $item =~ /^[\:A-Fa-f0-9]+\/[0-9]+$/ ) {
			push( @subnets, $item );
		} elsif ( $item =~ /^[\.0-9]+$/ ) {
			push( @subnets, $item . '/32' );
		} elsif ( $item =~ /^[\.0-9]+\/[0-9]+$/ ) {
			push( @subnets, $item );
		}
	} ## end foreach my $item (@subnets_split)
	my $allowed_subnets;
	eval { $allowed_subnets = subnet_matcher(@subnets); };
	if ($@) {
		die( 'Failed it init subnet matcher... ' . $@ );
	}

	if ( $allowed_subnets->( $opts{ip} ) ) {
		return 1;
	}

	return 0;
} ## end sub check_remote

=head2 eve_process

Process the finished tasks for CAPEv2.

    $cape_utils->eve_process;

=cut

sub eve_process {
	my ( $self, %opts ) = @_;

	my $dbh;
	eval { $dbh = $self->connect or die $DBI::errstr };
	if ($@) {
		die( 'Failed to connect to the DB... ' . $@ );
	}

	my $statement
		= "select * from tasks where ( status = 'reported' ) AND ( completed_on  >= CURRENT_TIMESTAMP - interval '"
		. $self->{config}{_}{eve_look_back}
		. " seconds' )";

	my $sth = $dbh->prepare($statement);
	$sth->execute;

	my $row;
	my @rows;
	while ( $row = $sth->fetchrow_hashref ) {
		push( @rows, $row );
	}

	$sth->finish;
	$dbh->disconnect;

	my $main_eve = $self->{config}{_}{eve};

	foreach my $row (@rows) {
		my $report        = $self->{config}{_}{base} . '/storage/analyses/' . $row->{id} . '/reports/lite.json';
		my $id_eve        = $self->{config}{_}{incoming_json} . '/' . $row->{id} . '.eve.json';
		my $incoming_json = $self->{config}{_}{incoming_json} . '/' . $row->{id} . '.json';

		# make sure we have the required files and they are accessible
		# id_eve is being used as a lock file to make sure we don't reprocess it
		if ( -f $report && -r $report && !-f $id_eve ) {
			my $eve_json;
			# the incoming json needs to exist if the following is to work
			# if it does not, just a mostly empty one
			if ( -f $incoming_json ) {
				eval {
					$eve_json = decode_json( read_file($incoming_json) );
					$eve_json->{cape_eve_process} = { incoming_json_error => undef, };
				};
				if ($@) {
					my $error_message = 'Failed to decode incoming JSON for ' . $row->{id} . ' ... ' . $@;
					$self->log_drek( 'cape_eve_process', 'err', $error_message );
					$eve_json = {
						cape_eve_process => {
							incoming_json_error => $error_message,
						},
					};
				}
			} else {
				$eve_json = { cape_eve_process => {}, };
			}

			# sets various common items so they don't need to be dealt with more than once
			# hash creation
			$eve_json->{cape_eve_process}{time} = time;
			$eve_json->{cape_eve_process}{host} = hostname;
			$eve_json->{row}                    = $row;
			$eve_json->{event_type}             = 'potential_malware_detonation';
			if ( !defined( $eve_json->{cape_eve_process}{incoming_json_error} ) ) {
				$eve_json->{cape_eve_process}{incoming_json_error} = undef,;
			}

			my $lite_json;
			eval {
				$lite_json = decode_json( read_file($report) );

				if ( defined( $lite_json->{signatures} ) ) {
					$eve_json->{signatures} = $lite_json->{signatures};
				}

				if ( defined( $lite_json->{malscore} ) ) {
					$eve_json->{malscore} = $lite_json->{malscore};

					if ( $lite_json->{malscore} >= $self->{config}{_}{malscore} ) {
						$eve_json->{event_type} = 'alert';
					}
				}
			};
			if ($@) {
				my $error_message = 'Failed to decode lite.json for ' . $row->{id} . ' ... ' . $@;
				$self->log_drek( 'cape_eve_process', 'err', $error_message );
				$eve_json->{cape_eve_process}{lite_json_error} = $error_message,;
			}

			# new line is needed as encode_json does not add one and this prevents the eve file
			# from being one long line when appended to
			my $raw_eve_json = encode_json($eve_json) . "\n";

			eval { write_file( $id_eve, $raw_eve_json ); };
			if ($@) {
				my $error_message = 'Failed to write out ID EVE for ' . $row->{id} . ' at ' . $id_eve . '  ... ' . $@;
				$self->log_drek( 'cape_eve_process', 'err', $error_message );
			}

			eval { append_file( $self->{config}{_}{eve}, $raw_eve_json ); };
		} else {
			if ( !-f $report || !-r $report ) {
				warn( $row->{id} . ' reported, but lite.json does not exist for it or it is not readable' );
			}
		}
	} ## end foreach my $row (@rows)

} ## end sub eve_process

# sends stuff to syslog
sub log_drek {
	my ( $self, $sender, $level, $message ) = @_;

	if ( !defined($level) ) {
		$level = 'info';
	}

	if ( !defined($sender) ) {
		$sender = 'CAPE::Utils';
	}

	openlog( $sender, 'cons,pid', 'daemon' );
	syslog( $level, '%s', $message );
	closelog();
} ## end sub log_drek

=head1 CONFIG FILE

The default config file is '/usr/local/etc/cape_utils.ini'.

The defaults are as below, which out of the box, it will work by
default with CAPEv2 in it's default config.

    # The DBI dsn to use
    dsn=dbi:Pg:dbname=cape
    # DB user
    user=cape
    # DB password
    pass=
    # the install base for CAPEv2
    base=/opt/CAPEv2/
    # 0/1 if poetry should be used
    poetry=1
    # 0/1 if fail should be allowed to run with out a where statement
    fail_all=0
    # colums to use for pending table show
    pending_columns=id,target,package,timeout,ET,route,options,clock,added_on
    # colums to use for runniong table show
    running_columns=id,target,package,timeout,ET,route,options,clock,added_on,started_on,machine
    # colums to use for tasks table
    task_columns=id,target,package,timeout,ET,route,options,clock,added_on,latest,machine,status
    # if the target column for running table display should be clipped to the filename
    running_target_clip=1
    # if microseconds should be clipped from time for running table display
    running_time_clip=1
    # if the target column for pending table display should be clipped to the filename
    pending_target_clip=1
    # if microseconds should be clipped from time for pending table display
    pending_time_clip=1
    # if the target column for task table display should be clipped to the filename
    task_target_clip=1
    # if microseconds should be clipped from time for task table display
    task_time_clip=1
    # default table color
    table_color=Text::ANSITable::Standard::NoGradation
    # default table border
    table_border=ASCII::None
    # when submitting use now for the current time
    set_clock_to_now=1
    # default timeout value for submit
    timeout=200
    # default value for enforce timeout for submit
    enforce_timeout=0
    # how to auth for mojo_cape_submit
    # ip = match against subnets
    # apikey = use apikey
    # both = require both to match
    # either = either may work
    auth=ip
    # the api key to for with mojo_cape_submit
    #apikey=
    # comma seperated list of allowed subnets for mojo_cape_submit
    subnets=192.168.0.0/16,127.0.0.1/8,::1/128,172.16.0.0/12,10.0.0.0/8
    # incoming dir to use for mojo_cape_submit
    incoming=/malware/client-incoming
    # directory to store json data files for submissions recieved by mojo_cape_submit
    # this directory is also used for storing run specific eves
    incoming_json=/malware/incoming-json
    # Location to write the eve log to.
    eve=/opt/CAPEv2/log/eve.json
    # how far to go back for processing eve
    eve_look_back=360
    # malscore for changing the event_type for eve from potential_malware_detonation to alert
    malscore=0

=head2 Report Munge Section

INI sections matching /^munge\_/ will be used for report munging. This requires two values for that sections,
'check' and 'munge'.

'check' is a path to a Perl script that will wrapped in a eval and require to check if the file should be
munged or not.

'munge' is a path to a Perl script that will wrapped in a eval and require to do the munging.

Below is a example showing the setup for a single script.

    [munge_pdf]
    check=/usr/local/etc/cape_utils_munge/pdf_check
    munge=/usr/local/etc/cape_utils_munge/pdf_munge

If more than one munge section exists, they are ran in sorted order.

If the paths specied do not start with a '/', './', or '../', then '/usr/local/etc/cape_utils_munge/' is
applied to the start.

The scripts are read as evaled strings.

The relevant variables are as below.

    - $munge_it :: Perl boolean for if it should be munged or not. Should be set by the check script.

    - $report :: The hash ref containing the parsed JSON report.

    - $changed :: Perl boolean for if it changed or not.

For some examples see the directory 'munge_examples'.

=head1 CAPEv2 lite.json to EVE handling

Tasks are found by looking back X number of seconds in the tasks table for tasks that have reported.
The amount of time is determined by the config value 'eve_look_back'.

It will check if a task has been processed already or not be seeing if a task specified EVE JSON
has been created under the 'incoming_json' directory. This is in the format $task_id.'eve.json'.
If not, it will proceed.

It reads the 'lite.json' report for task as well as the incoming JSON. It then copies the keys
'signatures' and 'malscore' into the hash for the incoming JSON and writes it out to
$task_id.'eve.json' and appending it to the file specified via the config value 'eve'.

The are two possible values for 'event_type', 'potential_malware_detonation' and 'alert'.
'potential_malware_detonation' is changed to alert when 'malscore' goves over the value
specified via config value 'malscore'.

'row' is the full row for the task in question from the task table as a hash.

'signatures' is copied from '.signature' in the report JSON.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cape-utils at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=CAPE-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CAPE::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=CAPE-Utils>

=item * Search CPAN

L<https://metacpan.org/release/CAPE-Utils>

=item * Git

L<git@github.com:VVelox/CAPE-Utils.git>

=item * Web

L<https://github.com/VVelox/CAPE-Utils>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of CAPE::Utils
