package DBI::Dumper;

=pod

=head1 NAME

DBI::Dumper - Dump data from a DBI datasource to file.

=head1 SYNOPSIS

	<< in test.ctl >>
	OPTIONS (export=100,rows=100)
	EXPORT DATA REPLACE INTO FILE 'test.dat'
	FIELDS TERMINATED BY TAB 
		ENCLOSED BY '"' AND '"' 
		ESCAPED BY '\'
	WITH HEADER FROM
	SELECT * FROM MY_TABLE

	my $dumper = DBI::Dumper->new(
		-dbh => $dbh,
		-control => 'test.ctl',
		-output => 'test.dat',
	);

	$dumper->prepare;
	$dumper->execute;

	
	# have DBI::Dumper login to database
	my $dumper = DBI::Dumper->new(
		-userid => 'user/pass@sid',
		...
	);


	# send a statement handle instead of database handle
	my $sth = DBI->connect()->prepare("SELECT * FROM MY TABLE");
	$dumper->execute($sth);

=head1 DESCRIPTION

Dumps data from a select statement into an output file. dbidumper tries to
mirror the functionality and behavior of sql*loader. The control file syntax is
similar, and DBI::Dumper utilizes a subset of the sql*loader options.

Configuration options can be set either in the control file, passed to the
new() method, or by calling the option's accessor.

=head2 Options

=over

=item userid=username/password@sid

Login information for database connection.

If the sid includes a colon, the full string will be used as the DBI dsn. For example:

	userid=username/password@mysql:database

Will connect to mysql's 'database' database as username.

Otherwise, DBI::Dumper assumes a dbi:Oracle connection and prefixes the dsn with dbi:Oracle:. If no dsn is passed, DBI::Dumper first looks in $ENV{DBI_DSN} then $ENV{ORACLE_SID}.

=item control=filename

Input control filename. Defaults to standard input. See L<CONTROL FILE> for
layout and description.

=item output=filename

Output filename for data. Defaults to standard output. If rows is given, can
contain template consisting of three or more Xs. The Xs will be replaced with
the file sequence number. If the template does not contain three or more Xs,
the sequence number will be appended to the filename with a dot. Examples:

=item rows=n

Number of rows per output file. Defaults to all rows in one output file.

=item export=n

Total number of rows to export. Use to limit output or restart dump.

=item skip=n

Number of rows to skip from beginning. File sequence number will be preserved,
so if rows=n is set, this can be used to restart a job.

=item bindsize=n

Block size to write file. Defaults to write each record as returned from
database. If set, dbidumper will collect rows into a buffer at most n bytes large
before writing to file.

=item silent=true

Suppress normal logging information. dbidumper will only report errors.

=back

=head2 Exporting to Multiple Files

=over

=item rows=1000 output=outputXXXXX.dat

Data will be written to output00001.dat, output00002.dat, etc.

=item rows=1000 output=output.dat

Data will be written to output.dat.0001, output.dat.0002, etc.

=item output=outputXXXXX.dat

Data will be written to outputXXXXX.dat

=back

=head1 DEPENDENCIES

This program depends on the following perl modules, available from a CPAN
mirror near you:

=over

=item Parse::RecDescent - Recursive parser

=item DBI - Standard database interface

=back

=head1 CONTROL FILE

The control file used for dbidumper is very similar to sql*loader's. The full
specification is:

	[ OPTIONS ([option], ...) ]
	EXPORT DATA [ REPLACE | APPEND ] [ INTO FILE 'filename' ]
	[ FIELDS
		[ TERMINATED [BY] {TAB | 'string' | X'hexstring'} ] |
		[ ENCLOSED [BY] {'string' | X'hexstring'} 
			[AND] ['string' | X'hexstring'] ]
		[ ESCAPED [BY] {'string' | X'hexstring'} ]
	]
	[ WITH HEADER ]
	FROM
	select_statement

=head1 AUTHOR

Written by Warren Smith (warren.smith@acxiom.com)

=head1 BUGS

None yet.

=cut

use strict;
use warnings;

use Parse::RecDescent;
use DBI;
use Time::HiRes qw(time);

use DBI::Dumper::Grammar;
use DBI::Dumper::PurePerl;

our $VERSION = '2.01';
our $parser;
our $USE_INLINE_C;

our $silent; # define behavior of debug()
sub debug($);

# should we use the xsub module?
BEGIN {
	eval { require Inline; };
	if($@) {
		$USE_INLINE_C = 0;
	}
	else {
		$USE_INLINE_C = 1;
		eval q{ use DBI::Dumper::C };
	}
}

my @accessors = qw(
	dbh rows export skip
	bindsize silent output action
	dsn header left_delim right_delim
	terminator escape query control
	control_text
);
for my $accessor (@accessors) {
	no strict 'refs';

	*{ __PACKAGE__ . "::$accessor" } = sub {
		my ($self, $value) = @_;
		$self->{$accessor} = $value if @_ == 2;
		return $self->{$accessor};
	};
}

sub new {
	my ($class, %options) = (@_);

	my $self = {
		# control options
		rows => undef, # rows per file
		export => undef, # total rows to export
		skip => undef, # rows to skip
		bindsize => undef, # block size to write
		silent => undef, # keep quiet
		output => undef, # output file name
		action => "REPLACE", # overwrite output file
		dsn => undef,

		# data layout options
		header => '', # add header line
		left_delim => '', # left field delimiter
		right_delim => '', # right field delimiter
		terminator => "\t", # field separator
		escape => undef,
	};
	bless $self, $class;

	while( my($option, $value) = each(%options) ) {
		$option =~ s/^-//;
		$self->{$option} = $value;
	}

	# create grammar parser
	if(! $parser) {
		$parser = DBI::Dumper::Grammar->new();
	}
	$self->{parser} = $parser;

	return $self;
}

sub delim {
	my ($self, $left_delim, $right_delim) = @_;
	if( defined $left_delim ) {
		$self->left_delim($left_delim);
		$self->right_delim($right_delim || $left_delim);
	}

	return ( $self->left_delim, $self->right_delim );
}

sub prepare {
	my ($self, $control) = @_;

	my ($control_fn, $control_text) = ($self->control, $self->control_text);

	if($control) {
		if($control =~ /EXPORT\s+DATA\s+/) {
			$control_text = $control;
		}
		else {
			$control_fn = $control;
		}
	}

	die "No control file." unless $control_fn || $control_text;

	if($control_fn) {
		# slurp in the control file (stdin if not specified)
		local $/;
		open(my $control_fh, "<", $control_fn) 
			or die "Could not open control file $control_fn: $!";
		$control_text = <$control_fh>;
		close $control_fh;
	}

	{
		# add a reference to ourself in the parser namespace
		no strict 'refs';
		${ $self->{parser}->{namespace} . '::dumper' } = $self;
	}

	# preprocess comments out
	$control_text = $self->{parser}->preprocess($control_text);

	if(! $self->{parser}->control($control_text) ) {
		$control_fn ||= $control_text;
		die "Syntax error in $control_fn.";
	}

	if(! $self->query ) {
		die "No sql query in control file!";
	}

	$self->{_prepared} = 1;

	return 1;
}

sub execute {
	my ($self, $sth) = @_;

	$silent = $self->{silent};

	if(! $sth) {
		if(! $self->dbh) {
			die "No database handle available and no statement handle provided";
		}

		$sth = $self->dbh->prepare($self->query);
		$sth->execute;
	}

	# run parse() if it hasn't already been run
	$self->prepare unless $self->{_prepared};

	# figure out where to start
	my $start_line_num = ($self->{skip} || 0);
	my $end_line_num = $self->{export} 
		? $start_line_num + $self->{export} : undef;

	# make sure variables are set to something
	for my $var qw(left_delim right_delim escape terminator) {
		$self->{$var} = defined $self->{$var} ? $self->{$var} : '';
	}

	# determine which row builder to use
	my $build_row_string_sub;
	if($USE_INLINE_C) {
		$build_row_string_sub = \&DBI::Dumper::C::build;
		DBI::Dumper::C::init($self);
	}
	else {
		$build_row_string_sub = \&DBI::Dumper::PurePerl::build;
		DBI::Dumper::PurePerl::init($self);
	}

	# build the escape regex ( will escape escape characters and embedded terminators )
	my $header;
	if($self->{header}) {
		# $sth->{NAME} is dereferenced and rereferenced because
		# the Inline::C module returns false for SvOK() from the value
		# that DBI returns
		$header = $build_row_string_sub->($self, [ @{ $sth->{NAME} } ]);
	}

	# open output file
	my $file_sequence = 0;
	my $output_fh = $self->_open_output_file($file_sequence);

	# print the header if the flag is set
	if($self->{header}) {
		syswrite($output_fh, $header);
	}

	# make some local copy of these (saves typing)
	my($rows, $bindsize) = @{ $self }{qw(rows bindsize)};

	my ($buffer, $buffer_length) = ('', 0);
	my ($job_line_num, $file_line_num) = (0, 0);

	# process each row
	my $row;
	while($row = $sth->fetchrow_arrayref) {
		$job_line_num++;
		$file_line_num++;

		debug "$job_line_num rows written.\n" if !($job_line_num % 1000);

		# skip record if skip= provided (start_line_num => line to start at)
		if($job_line_num <= $start_line_num) {
			next;
		}

		# build data row
		my $data = $build_row_string_sub->($self, $row);

		# write directly if no bindsize specified
		if(! $bindsize) {
			syswrite($output_fh, $data);
		}

		# otherwise, collect a buffer up to bindsize
		else {
			my $data_length = length($data);
			# is it time to end this block?
			if($buffer_length + $data_length > $bindsize) {
				# dump to file
				syswrite($output_fh, $buffer);
				$buffer = '';
				$buffer_length = 0;
			}
			else {
				# collect if not
				$buffer .= $data;
				$buffer_length += $data_length;
			}
		}

		# end early if export= provided (end_line_number => line to end at)
		if($end_line_num && $job_line_num >= $end_line_num) {
			last
		}

		# create new file (flushing first) if we've hit our linecount per file
		if( $rows && $file_line_num >= $rows ) {
			# flush write buffer
			if($output_fh && $bindsize && $buffer_length) {
				debug "Writing buffer on line: $job_line_num\n";
				syswrite($output_fh, $buffer);
				$buffer = '';
				$buffer_length = 0;
			}

			$file_sequence++;
			$output_fh = $self->_open_output_file($file_sequence);
			$file_line_num = 0;

			# print the header if the flag is set
			if($self->{header}) {
				syswrite($output_fh, $header);
			}
		}
	}

	# write the last bits of data
	if($buffer_length) {
		syswrite($output_fh, $buffer);
	}
	close $output_fh;

	debug sprintf "%d row(s) dumped.\n", $job_line_num;
	
	return $job_line_num;
}

sub _open_output_file {
	my ($self, $sequence) = (@_);
	my $filename = $self->{output};
	if($filename) {
		# append .XXXX if $self->{rows}
		if($self->{rows}) {
			# put the sequence number on the end if no template specified
			if(!($filename =~ /X{3,}/)) {
				$filename .= ".XXXX";
			}

			# replace string of "X"s with a zero-padded sequence number
			$filename =~ s/(X{3,})/sprintf "%0" . length($1) . "d", $sequence/ge;
		}

		debug "Opening file: $filename\n";
	}

	my $output_fh;
	if(! $filename) {
		open $output_fh, ">&STDOUT";
	}
	else {
		open $output_fh, ($self->{action} eq 'APPEND' ? ">>" : ">"), $filename
			or die "Could not open output file $filename: $!";
	}

	return $output_fh;
}

sub debug($) {
	my ($msg) = @_;
	print STDERR $msg if ! $silent;
}

1;

