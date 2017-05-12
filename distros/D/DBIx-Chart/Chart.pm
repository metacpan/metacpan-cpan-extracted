#
#	DBIx::Chart - subclass of DBI to transparently provide
#		charting capability
#
#	History:
#
#	2005-01-26		D. Arnold
#		- added fetch() alias
#		- added state() functions
#		- improved err/errstr/state retrieval
#
#	2002-09-10		D. Arnold
#		Coded.
#

require 5.6.0;
use DBI 1.27;
use DBD::Chart 0.82;

BEGIN {
$DBIx::Chart::VERSION = '0.05';
}
#
#	immediately grab a DBD::Chart handle for our use
#
our $chartdbh = DBI->connect('dbi:Chart:');

package DBIx::Chart;
@ISA = qw(DBI);

# inherits connect etc

package DBIx::Chart::db;
@ISA = qw(DBI::db);

use strict 'vars';
use Carp;

#
#	we should really let DBD::Chart
#	provide something to tell us which
#	types of charts it supports
my %chart_types = qw(
BOXCHART 1
LINEGRAPH 1
AREAGRAPH 1
POINTGRAPH 1
BARCHART 1
PIECHART 1
HISTOGRAM 1
GANTT 1
QUADTREE 1
CANDLESTICK 1
IMAGE 1);

#
#	for now we're not supporting these
#
#  $rc = $sth->bind_param_array($p_num, $bind_values, \%attr);
#  $rv = $sth->execute_array(\%attr);
#  $rv = $sth->execute_array(\%attr, @bind_values);
#
#	eventually we may need to handle this to cover the case
#	when a chart failure should induce a rollback
#
#  $rc  = $dbh->begin_work;
#  $rc  = $dbh->commit;
#  $rc  = $dbh->rollback;
#

sub prepare_cached {
	my ($dbh, $stmt, @args) = @_;
    return $dbh->SUPER::prepare_cached($stmt, @args)
    	unless $dbh->_chart_is_chart($stmt);
#
#	we're cheating here; at some point we'll realy cache things
#
	return $dbh->prepare($stmt, @args);
}

sub _chart_is_chart {
	my ($dbh, $stmt) = @_;

	my $sql = (ref $stmt) ? $$stmt : $stmt;
	my $strary = _chart_remove_strings(\$sql);
	$$stmt = $sql if ref $stmt;
    return ((($sql=~/\bRETURNING\s+(\w+)\b.+$/si) && $chart_types{uc $1}) ||
    	($sql=~/^\s*(INSERT\s+INTO\s+|UPDATE\s+|DELETE\s+FROM\s+)CHART\.COLORMAP\b/si)) ?
    	$strary : undef;
}

sub prepare {
    my($dbh, $stmt, $attribs) = @_;
#
#	check if stmt might be interesting to us
#	in future, we need to support configurable statement
#	types, and support platform specific prefixes,
#	as well as referencing resultset fields within
#	our returning clause
#
#	prepare orig. stmt if munged version isn't interesting
#
	my $sql = $stmt;
	my $strary = $dbh->_chart_is_chart(\$sql);
    return $dbh->SUPER::prepare($stmt, $attribs)
    	unless $strary;
#
#	if its a colormap operations, send to the chartdbh
#
	return $chartdbh->SUPER::prepare($stmt, $attribs)
		if ($sql=~/^\s*(INSERT|UPDATE|DELETE)\s+/si);

	my $phcnt = 0;
	$sql = _chart_count_phs($sql, \$phcnt);
#
#	parse request into component parts
#
	my $qryhash = $dbh->_chart_parse_sql($sql, $strary, $phcnt);
	return unless $qryhash;
#
#	!!!THIS MUST BE DERIVED THRU THE DBI!!!
#
	my $sth = { };
#	bless $sth, DBIx::Chart::st;

	$sth->{_src_sths} = [ ];
	$sth->{_src_cols} = [ ];
	$sth->{_src_phs} = $qryhash->{_qry_phs};
	$sth->{_chart_phs} = $qryhash->{_chart_phs};
	$sth->{_chart_src_idx} = $phcnt;

	my $chart_no_verify = $$attribs{chart_no_verify};
	my $chart_map_modifier = $$attribs{chart_map_modifier};
	my $chart_type_map = $$attribs{chart_type_map};
	my %tattrs = $attribs ? %$attribs : undef;

	delete $tattrs{chart_no_verify},
	delete $tattrs{chart_map_modifier},
	delete $tattrs{chart_type_map}
		if %tattrs;
#
#	we'll need to trap driver-specific attributes
#	if/when we support a multiDBMS syntax
#
	my $src_sth;
	foreach (0..$#{$qryhash->{_queries}}) {
		$src_sth = $dbh->SUPER::prepare($qryhash->{_queries}->[$_], \%tattrs)
			or return undef;
		push @{$sth->{_src_sths}}, $src_sth;
	}
#
#	need a way to indicate which columns of the source stmt we want
#
	my $chartsth = $sth->{_chart_sth} =
		$chartdbh->prepare($qryhash->{_chartqry},
		{
			chart_no_verify => $chart_no_verify,
			chart_map_modifier => $chart_map_modifier,
			chart_type_map =>	$chart_type_map
		}) || return undef;
#
#	clone the chart sth into our own version
#
	my($outer, $osth) = DBI::_new_sth($dbh, {
		Statement     => $stmt,
	});

	map { $osth->{$_} = $chartsth->{$_}; }
		(qw(NUM_OF_FIELDS NUM_OF_PARAMS NAME TYPE PRECISION SCALE NULLABLE));

	$osth->{private_dbix_chart_sth} = $sth;
    return $outer;
}

sub _chart_remove_strings {
	my ($sql) = @_;

	my @strlits = ();
	my $i = 0;
#
#	for now we only handle single quotes...in future,
#	we'll need dbl quote support
	push(@strlits, $1),
	$$sql=~s/'(.*?)'/<$i>/s,
	$i++
		while ($$sql=~/'(.*?)'/s);
	return \@strlits;
}

sub _chart_count_phs {
	my ($sql, $count) = @_;

	my $i = $$count;
	my @phpos = ();
	push @phpos, pos($sql)
		while ($sql=~/\?/gcs);

	substr($sql, (pop @phpos) - 1, 1) = "?$i",
	$i++
		while @phpos;

	$$count = $i;
	return $sql;
}

sub _chart_parse_sql {
	my ($dbh, $sql, $strary, $phcnt) = @_;
#
#	check for this form:
#
#	SELECT * FROM
#		(SELECT <collist> FROM <table>
#		[ WHERE ...] [ GROUP BY | ORDER BY | HAVING | ...]
#		RETURNING <charttype> WHERE ....) [<qryname>]
#		[,(SELECT <collist> FROM <table>
#		[ WHERE ...] [ GROUP BY | ORDER BY | HAVING | ...]
#		RETURNING <charttype> WHERE ....) [<qryname>]
#	RETURNING IMAGE [, IMAGEMAP] WHERE ...
#
	my @queries = ();
	my @chartqueries = ();
	my @qrynames = ();
	my @qryphs = ();
	my $chartqry;
	my $remnant;
#	$sql=~s/[\n\r]/ /g;
	if ($sql=~/\bRETURNING\s+IMAGE(\s*,\s*IMAGEMAP)?\s+WHERE\s+(.+?)$/si) {
		my $imagemap = $1;
		my $global_props = $2;

		return $dbh->SUPER::set_err(-1, 'Composite image must use SELECT *.', 'S1000')
			unless ($sql=~/^\s*SELECT\s+\*\s+FROM\s+(.+)$/si);
		$remnant = $1;
#
#	fish out each subquery
#
		my $i = 0;
		while ($remnant=~/^\(\s*(.+?)\s+RETURNING\s+(CANDLESTICK|LINEGRAPH|AREAGRAPH|POINTGRAPH|QUADTREE|BARCHART|BOXCHART|HISTOGRAM|PIECHART|GANTT)\s*\(\s*([^\)]+)\)\s+WHERE\s+(.+)$/si) {
			push @queries, $1;
			$chartqry = "SELECT $2($3) FROM ?$phcnt WHERE ";
			$phcnt++;
			$remnant=~s/^\(\s*.+?\s+RETURNING\s+(CANDLESTICK|LINEGRAPH|AREAGRAPH|POINTGRAPH|QUADTREE|BARCHART|BOXCHART|HISTOGRAM|PIECHART|GANTT)\s*\(\s*[^\)]+\)\s+WHERE\s+(.+)$/$2/si;
			$remnant = ' AND ' . $remnant;
#
#	note we can't handle expressions yet
			while ($remnant=~/^\s*AND\s+([\w\.]+)\s*(=\s*[^\)\s]+|IN\s+\(\s*[^\)]+\))(.+)$/si) {
				$chartqry .= "$1 $2";
				$remnant = $3;
				$chartqry .= ' AND ' if ($remnant=~/^\s+AND\s+/si);
			}
			push @chartqueries, $chartqry;
			push(@qrynames, $2),
			$remnant = $4
				if ($remnant=~/^\s*\)(\s+(\w+))?(\s*,)?\s*(.*)$/s);
#
#	restore the source query and map any PHs
			my $qry = pop @queries;
			push @qryphs, _chart_restore_phs(\$qry);
			$qry = _chart_restore_strings($qry, $strary);
			push @queries, $qry;
			$i++;
		}
		$chartqry = $imagemap ? 'SELECT IMAGE, IMAGEMAP FROM ' : 'SELECT IMAGE FROM ';
		$chartqry .= '(' . $chartqueries[$_] . ') ' . ($qrynames[$_] || "PLOT$_") . ','
			foreach (0..$#chartqueries);
		chop $chartqry;
		$chartqry .= ' WHERE ' . $global_props;
#
#	restore the chart query and map any PHs
		my $phs = _chart_restore_phs(\$chartqry);
		$chartqry = _chart_restore_strings($chartqry, $strary);

		return { _chartqry => $chartqry,
				_queries => \@queries,
				_qry_phs => \@qryphs,
				_chart_phs => $phs };
	}
#
# now handle the simpler form
#
#	<arbitrary SELECT stmt>
#	RETURNING <charttype>(<collist>) [, IMAGEMAP] WHERE ....
#
	return undef unless ($sql=~/^\s*(.+?)\s+RETURNING\s+(CANDLESTICK|LINEGRAPH|AREAGRAPH|POINTGRAPH|QUADTREE|BARCHART|BOXCHART|HISTOGRAM|PIECHART|GANTT)\s*\(\s*([^\)]+)\)(\s*,\s*IMAGEMAP)?\s+(WHERE\s+.*)/si);

	push @queries, $1;
	$chartqry = $4 ? "SELECT $2($3), IMAGEMAP FROM ?$phcnt $5" : "SELECT $2($3) FROM ?$phcnt $5";
#
#	restore the source query and map any PHs
	my $qry = pop @queries;
	push @qryphs, _chart_restore_phs(\$qry);
	$qry = _chart_restore_strings($qry, $strary);
	push @queries, $qry;
#
#	restore the chart query and map any PHs
	my $phs = _chart_restore_phs(\$chartqry);
	$chartqry = _chart_restore_strings($chartqry, $strary);

	return {
		_chartqry => $chartqry,
		_queries => \@queries,
		_qry_phs => \@qryphs,
		_chart_phs => $phs
		};
#
# should/can we handle this form of composite ?
#
#	<arbitrary SELECT stmt>
#	RETURNING <charttype>(<collist>) [, <charttype>(<collist>) ...] [, IMAGEMAP] WHERE ....
#
# probably not, due to the need for multiple WHERE clauses...unless we used named syntax, ie.,
#	RETURNING <charttype>(<collist>) AS <name> [, <charttype>(<collist>) AS <name> ...] [, IMAGEMAP] WHERE ....
#	and then use the names to associate the individual properties with their specific graph
#	we'll tinker with it after we've got a prototype working
#
}

sub _chart_restore_strings {
	my ($sql, $strary) = @_;
	my $str;
	$str = $$strary[$1],
	$sql=~s/<\d+>/'$str'/s
		while ($sql=~/<(\d+)>/s);

	return $sql
}

sub _chart_restore_phs {
	my ($sql) = @_;
	my $phs = [ ];
	push (@$phs, $1),
	$$sql=~s/\?$1/\?/s
		while ($$sql=~/\?(\d+)/s);
	return $phs;
}

no strict 'vars';

package DBIx::Chart::st;
@ISA = qw(DBI::st);

use strict 'vars';

sub bind_param {
	my ($sth, $parmnum, @args) = @_;
#
#	we need to apply the bound params to the appropriate stmt's
#	matching placeholder position

	return $sth->SUPER::bind_param($parmnum, @args)
		unless $sth->{private_dbix_chart_sth};

	my $chartsth = $sth->{private_dbix_chart_sth};

	my $phcnt = $chartsth->{_chart_src_idx};

	return $sth->set_err(-1, 'Invalid parameter number.', 'S1000')
		unless ($parmnum <= $phcnt);
#
#	check if its a chart PH
#
	return $chartsth->{_chart_sth}->bind_param(
		$parmnum - $chartsth->{_chart_phs}[0], @args)
		if ($chartsth->{_chart_phs}[0] &&
			$parmnum > $chartsth->{_chart_phs}[0]);

	my $phmap = $chartsth->{_src_phs};
	foreach my $i (0..$#$phmap) {	# for each stmt
		foreach (@{$phmap->[$i]}) { # for each PH of the stmt
			return $chartsth->{_src_sths}[$i]->SUPER::bind_param($_+1, @args)
				if ($phmap->[$i][$_] == $parmnum-1);
		}
	}
#
#	if we get here, its not a recognized PH
	return $sth->SUPER::set_err(-1, 'Invalid parameter number.', 'S1000');
}

#
#	we rely on DBI's default array binding support
#

sub execute {
	my ($sth, @args) = @_;

	return $sth->SUPER::execute(@args)
		unless $sth->{private_dbix_chart_sth};
#
#	first execute each source sth, then execute the chart sth,
#	passing in the source sth's as a param, and picking up any
#	other placeholders we might need
	my @exec_parms;
	my $chartsth = $sth->{private_dbix_chart_sth};

	my $src_sths = $chartsth->{_src_sths};
	my $src_phs = $chartsth->{_src_phs};
	my $chart_phs = $chartsth->{_chart_phs};
	my $phcnt = $chartsth->{_chart_src_idx};
	my $rc;
	foreach my $i (0..$#$src_sths) {
		@exec_parms = ();
		if (@args > 0) {
			push @exec_parms, $args[$_]
				foreach (@{$src_phs->[$i]});
		}
#
#	fill out our param list w/ sths to simplify the chart ph mapping
#
		$args[$phcnt++] = DBIx::Chart::SthContainer->new($src_sths->[$i], @exec_parms);
	}
#
#	now map each src_sth into its chart_sth placeholder,
#	along with any other relevant placeholders
#
	@exec_parms = ();

	$exec_parms[$_] =  $args[$chart_phs->[$_]]
		foreach (0..$#$chart_phs);

	return $chartsth->{_chart_sth}->SUPER::execute(@exec_parms);
#
#	do we need to explicitly finish each of our src_sth's ?
#	I don't think so...
#
#	some day we'll turn this into a generalized distributed JOIN
#	mechanism...maybe w/ some optimizations ?
}
#
#	for future consideration: extansion to specify another sth as
#	a general datasource for any other sth
#
sub set_producer {
	my ($sth, $srcsth, $attrs) = @_;
}

sub get_producer {
	my ($sth) = @_;
}

sub remove_producer {
	my ($sth, $srcsth) = @_;
}

sub bind_col {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::bind_col(@args) :
    	$sth->SUPER::bind_col(@args);
}

sub bind_columns {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::bind_columns(@args) :
    	$sth->SUPER::bind_columns(@args);
}

sub rows {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::rows(@args) :
    	$sth->SUPER::rows(@args);
}

sub fetchrow_array {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::fetchrow_array(@args) :
    	$sth->SUPER::fetchrow_array(@args);
}

sub fetchrow_arrayref {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::fetchrow_arrayref(@args) :
    	$sth->SUPER::fetchrow_arrayref(@args);
}
*fetch = \&fetchrow_arrayref;

sub fetchrow_hashref {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::fetchrow_hashref(@args) :
    	$sth->SUPER::fetchrow_hashref(@args);
}

sub fetchall_array {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::fetchall_array(@args) :
    	$sth->SUPER::fetchall_array(@args);
}

sub fetchall_arrayref {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::fetchall_arrayref(@args) :
    	$sth->SUPER::fetchall_arrayref(@args);
}

sub fetchall_hashref {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::fetchall_hashref(@args) :
    	$sth->SUPER::fetchall_hashref(@args);
}

sub cancel {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::cancel(@args) :
    	$sth->SUPER::cancel(@args);
}

sub func {
    my($sth, @args) = @_;

    return $sth->{private_dbix_chart_sth} ?
    	$sth->{private_dbix_chart_sth}{_chart_sth}->SUPER::cancel(@args) :
    	$sth->SUPER::func(@args);
}

sub finish {
    my($sth, @args) = @_;

    return $sth->SUPER::finish(@args)
    	unless $sth->{private_dbix_chart_sth};
#
#	finish each of our subordinate sths
#
	my $chartsth = $sth->{private_dbix_chart_sth};
	$_->SUPER::finish
		foreach (@{$chartsth->{_src_sths}});
	$_->{_chart_sth}->SUPER::finish
		if $_->{_chart_sth};
	return 1;
}

sub err {
	my ($sth) = @_;
	return $sth->SUPER::err;
}

sub errstr {
	my ($sth) = @_;
	return $sth->SUPER::errstr;
}

sub state {
	my ($sth) = @_;
	return $sth->SUPER::state;
}

sub DESTROY { }

1;
#
#	added in 0.05 to provide a container for unexecuted
#	stmt handles w/ their parameters
#
package DBIx::Chart::SthContainer;

sub new {
	my ($class, $sth, @params) = @_;

	return bless [ $sth, @params ], $class;
}

sub execute {
	my $self = shift;
	my $pcnt = $#$self;

#print STDERR "In SthContainer::execute\n";
	my $sth = $self->[0];
	my $rc = $sth->execute(@$self[1..$pcnt]);
	return $rc || $sth->set_err($sth->err, $sth->errstr, $sth->state);
}

sub num_of_fields { return $_[0]->[0]{NUM_OF_FIELDS}; }

sub finish { return $_[0]->[0]->finish(); }

sub get_metadata {
	my ($self, $item) = @_;
	my $t;
	return eval { $t = $self->[0]->{$item}; };
}

sub fetchall_arrayref {
	my $self = shift;
#print STDERR "In SthContainer::fetchall\n";
	return $self->[0]->fetchall_arrayref(@_);
}

1;

=pod

=head1 NAME

DBIx::Chart - DBI extension for Rendering Charts and Graphs

=head1 SYNOPSIS

	use DBIx::Chart;
	use DBI qw(:sql_types);
	#
	#	some data to plot
	#
	my @data = (
	[ 10, 23, 102 ],
	[ 20, 94, 222 ],
	[ 30, 44, 40 ],
	[ 40, 64, 38 ],
	[ 50, 90, 67 ]
	);
	#
	#	type info for DBD::Chart; this is
	#	ONLY NEEDED FOR DBI DRIVERS WHICH DO NOT RETURN
	#	NAME OR TYPE INFORMATION!!!!
	#
	my $typemap = [
		{
			NAME => qw[ X1 Y1 Y2 ],
			TYPE => [ SQL_INTEGER, SQL_INTEGER, SQL_INTEGER ],
			PRECISION => [ 0, 0, 0 ],
			SCALE => [0, 0, 0]
		}
	];
	#
	#	connect as usual
	#
	$dbh = DBIx::Chart->connect('dbi:CSV:');
	#
	#	populate the CSV
	#
	$dbh->do('DROP TABLE dbixtst');
	$dbh->do('CREATE TABLE dbixtst (
		x INTEGER, y1 integer, y2 integer)')
	        or die $dbh->errstr();

	$sth = $dbh->prepare('insert into dbixtst values(?,?,?)');
	$sth->execute(@{$_})
		foreach (@data);
	#
	#	now render the graph
	#
	$row = $dbh->selectrow_arrayref(
	"select * from
	(select * from dbixtst
	returning areagraph(x,y1,y2)
	where colors in ('red','blue')) plot1,
	(select * from dbixtst
	returning linegraph(x,y1,y2)
	where colors in ('black', 'yellow')
	and linewidth=3
	and shapes in ('fillsquare', 'opencircle')) plot2
	returning image, imagemap
	where width=400 and height=400
	and title='sample areagraph'
	and signature='(C) 2002 GOWI Inc.'
	and mapurl='http://www.goiwsys.com/cgi-bin/sample.pl?x=:X&y1=:Y'
	and mapname='comparea'
	and keeporigin=1
	and showgrid=0");
	#
	#	and save it
	#
	open(OUTF, '>comparea.png');
	binmode OUTF;
	print OUTF $$row[0];
	close OUTF;

	$dbh->disconnect;

=head1 WARNING

THIS IS ALPHA SOFTWARE.

=head1 DESCRIPTION

The DBIx::Chart extends SQL syntax to provide directives for
generating chart images. By subclassing DBI, it makes every
SQL capable data source with a DBI driver appear to natively
support charting/graphing.

DBIx::Chart builds on the SQL syntax introduced in DBD::Chart
to render pie charts, bar charts, box&whisker charts (aka boxcharts),
histograms, Gantt charts, and line, point, and area graphs.

For detailed usage information, see the included L<dbixchart.html>
webpage. Also refer to L<DBD::Chart> homepage at
www.presicient.com/dbdchart.
See L<DBI(3)> for details on DBI.

=head2 Prerequisites

=over 4

=item Perl 5.6.0 minimum

=item DBI 1.28 minimum

=item DBD::Chart 0.80

=item GD 1.19 minimum

=item GD::Text 0.80 minimum

=item DBD::CSV (for t/plottest.t)

=item Time::HiRes

=item libpng

=item zlib

=item libgd

=item jpeg-6b (only if JPEG output required)

=back


=head2 Installation

For Windows users, use WinZip or similar to unpack the file, then copy
Chart.pm to wherever your site-specific modules are kept (usually
\Perl\site\lib\DBIx for ActiveState Perl installations).
Note that you won't be able to execute the install test with this, but you need
a copy of 'nmake' and all its libraries to run that anyway. I may
whip up a PPM in the future.

For Unix, extract it with

    gzip -cd DBIx-Chart-0.01.tar.gz | tar xf -

and then enter the following:

    cd DBIx-Chart-0.01
    perl Makefile.PL
    make

You can test the installation by running

	make test

this will render a bunch of charts and an HTML page to view
them with. NOTE that the test requires the DBD::CSV driver,
which is usually bundled with the standard DBI installation.
Assuming the test completes successfully, you should
use a web browser to view the file t/plottest.html and verify
the images look reasonable.

If tests succeed, proceed with installation via

    make install

Note that you probably need root or administrator permissions.
If you don't have them, read the ExtUtils::MakeMaker man page for details
on installing in your own directories. L<ExtUtils::MakeMaker>.

=head1 FOR MORE INFO

Check out http://www.presicient.com/dbixchart with your
favorite browser.  It includes all the usage information.

=head1 AUTHOR AND COPYRIGHT

This module is Copyright (C) 2001, 2002 by Presicient Corporation

    Email: darnold@presicient.com

You may distribute this module under the terms of the Artistic
License, as specified in the Perl README file.

=head1 SEE ALSO

L<DBI(3)>

For help on the use of DBIx::Chart, see the DBI users mailing list:

  dbi-users-subscribe@perl.org

For general information on DBI see

  http://dbi.perl.org

=cut
