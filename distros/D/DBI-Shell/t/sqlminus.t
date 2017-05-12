#!../../perl -w

$|=1;

BEGIN {
	require Getopt::Long;

	if ($Getopt::Long::VERSION && $Getopt::Long::VERSION < 2.17) {
		print "# DBI::Shell needs Getopt::Long version 2.17 or later\n";
		print "1..0\n";
		exit 0;
	}

	# keep dumb Term::ReadKey happy
	$ENV{COLUMNS} = 80;
	$ENV{LINES} = 24;
	{
		local ($^W) = 0;
		delete $ENV{DBI_DSN};
		delete $ENV{DBI_USER};
		delete $ENV{DBI_PASS};
		delete $ENV{DBISH_CONFIG};
	}


	eval {

		require Text::Reform;
	};
	if ($@) {
		# warn "Text::Reform is not installed, skipping tests";
		print "1..0 ";
		warn " Text::Reform not installed\n";
		exit;
	}
}

my $LOAD_SQL=q{testsqlminus.sql};
my $SAVE_SQL=q{testsql.tmp};

# my $sqlminus = {
#	archive	=> {
#		log	=> undef,
#		},
#	'clear'	=> {
#		break	=> undef,
#		buffer	=> undef,
#		columns	=> undef,
#		computes	=> undef,
#		screen	=> undef,
#		sql		=> undef,
#		timing	=> undef,
#	},
#	db	=> undef,
#	dbh => undef,
#	column => {
#		column_name => [ qw{text} ],
#		alias		=> [ qw{text} ],
#		clear		=> [ qw{command} ],
#		fold_after	=> [ qw{text} ],
#		fold_before	=> [ qw{text} ],
#		format		=> [ qw{text} ],
#		heading		=> [ qw{text} ],
#		justify		=> [ qw{center centre left right} ],
#		like		=> [ qw{text} ],
#		newline		=> [ qw{text} ],
#		new_value	=> [ qw{text} ],
#		noprint		=> [ qw{on off} ],
#		'print'		=> [ qw{on off} ],
#		null		=> [ qw{text} ],
#		on			=> 1,
#		off			=> 0,
#		truncated	=> [ qw{on off} ],
#		wordwrapped	=> [ qw{on off} ],
#		wrapped		=> [ qw{on off} ],
#		column_format	=> undef,
#	},
#	# hash ref contains formats for code.
#	column_format => {
#	},
#	commands => {
#		'@'		=> undef,
#		'accept'=> undef,
#		append	=> undef,
#		attribute => undef,
#		break	=> undef,
#		btitle	=> undef,
#		change	=> undef,
#		clear	=> undef,
#		copy	=> undef,
#		column	=> undef,
#		compute	=> undef,
#		define	=> undef,
#		edit	=> undef,
#		get		=> undef,
#		pause	=> undef,
#		prompt	=> undef,
#		repheader=> undef,
#		repfooter=> undef,
#		run		=> undef,
#		save	=> undef,
#		set		=> undef,
#		show	=> undef,
#		spool	=> undef,
#		start	=> undef,
#		ttitle	=> undef,
#		undefine=> undef,
#	},
#	set => {
#		appinfo		=> ['_unimp'],
#		arraysize	=> ['_unimp'],
#		autocommit	=> ['_unimp'],
#		autoprint	=> ['_unimp'],
#		autorecovery=> ['_unimp'],
#		autotrace	=> ['_unimp'],
#		blockterminator=> ['_unimp'],
#		buffer		=> ['_unimp'],
#		closecursor	=> ['_unimp'],
#		cmdsep		=> ['_unimp'],
#		compatibility=> ['_unimp'],
#		concat		=> ['_unimp'],
#		copycommit	=> '_unimp',
#		copytypecheck=> ['_unimp'],
#		define		=> ['_unimp'],
#		document	=> ['_unimp'],
#		echo		=> ['_unimp'],
#		editfile	=> ['_unimp'],
#		embedded	=> ['_unimp'],
#		escape		=> ['_unimp'],
#		feedback	=> ['_unimp'],
#		flagger		=> ['_unimp'],
#		flush		=> ['_unimp'],
#		heading 	=> 1,
#		headsep 	=> ' ',
#		instance 	=> ['_unimp'],
#		linesize	=> 72,
#		loboffset	=> ['_unimp'],
#		logsource	=> ['_unimp'],
#		long		=> ['_unimp'],
#		longchunksize	=> ['_unimp'],
#		maxdata		=> ['_unimp'],
#		newpage		=> ['_unimp'],
#		null		=> ['_unimp'],
#		numwidth	=> ['_unimp'],
#		pagesize	=> ['_unimp'],
#		pause		=> ['_unimp'],
#		recsep 		=> 1,
#		recsepchar 	=> ' ',
#		scan		=> ['_print_buffer', 
#			qq{obsolete command: use 'set define' instead}],
#		serveroutput=> ['_unimp'],
#		shiftinout	=> ['_unimp'],
#		showmode	=> ['_unimp'],
#		space		=> qq{obsolete command: use 'set define' instead},
#		sqlblanklines=> ['_unimp'],
#		sqlcase		=> ['_unimp'],
#		sqlcontinue	=> ['_unimp'],
#		sqlnumber	=> ['_unimp'],
#		sqlprefix	=> ['_unimp'],
#		sqlprompt	=> ['_unimp'],
#		sqlterminator=> ['_unimp'],
#		suffix		=> ['_unimp'],
#		tab			=> ['_unimp'],
#		termout		=> ['_unimp'],
#		'time'		=> ['_unimp'],
#		'timing'	=> ['_unimp'],
#		trimout		=> ['_unimp'],
#		trimspool	=> ['_unimp'],
#		'truncate'	=> ['_unimp'],
#		underline	=> '-',
#		verify		=> ['_unimp'],
#		wrap		=> ['_unimp'],
#	},
#	show => {
#		all           => ['_all'],
#		btitle        => ['_unimp'],
#		columns       => ['_unimp'],
#		errors        => ['_unimp'],
#		grants        => ['_unimp'],
#		help          => ['_help'],
#		hints         => ['_hints'],
#		lno           => ['_hints'],
#		me            => ['_me'],
#		objects       => ['_unimp'],
#		packages      => ['_unimp'],
#		parameters    => ['_unimp'],
#		password      => ['_print_buffer', qq{I don\'t think so!} ], #		# '
#		pno           => ['_unimp'],
#		release       => ['_unimp'],
#		repfooter     => ['_unimp'],
#		repheader     => ['_unimp'],
#		sga           => ['_unimp'],
#		show          => ['_show_all_commands'],
#		spool         => ['_unimp'],
#		sqlcode       => ['_unimp'],
#		roles         => ['_unimp'],
#		ttitle        => ['_unimp'],
#		tables        => ['_unimp'],
#		users         => ['_unimp'],
#		views         => ['_unimp'],
#	},
#	sql => {
#		pno	=> undef,
#		lno	=> undef,
#		release	=> undef,
#		user	=> undef,
#	},
#};


use Test::More tests => 109;

BEGIN { use_ok( 'DBI::Shell' ); }

	require_ok( 'Text::Reform' );

$ENV{DBISH_CONFIG} = qq{dbish_config};

ok (exists $ENV{DBISH_CONFIG}, "Testing SQLMinus plugin for dbish. Configuration file dbish_config." );

$sh = DBI::Shell->new(qw(dbi:ExampleP:));
ok(defined $sh, "Create statement handler" );

ok( ! $sh->do_connect( qw(dbi:ExampleP:)), "Connecting to source" );


ok( $sh->do_format( q{sqlm} ), "Change format to sqlminus" );

# nlink,ino,blocks,ctime,rdev,mtime,mode,blksize,gid,size,dev,name,atime,uid

# List of all format defined columns.
ok( ! $sh->do_column(), "List columns defined with formats" );

ok( $sh->do_column(q{fred}),  "Show column  format for fred" );
ok( $sh->do_column(q{nlink}), "Show column  format for nlink" );

ok( $sh->do_column(q{clear}), "Clear all column formats" );

ok( ! $sh->do_column(qw{nlink format a20}) );
ok( ! $sh->do_column(qw{ino format a20}) );
ok( ! $sh->do_column(qw{blocks format a20}) );
ok( ! $sh->do_column(qw{ctime format a20}) );
ok( ! $sh->do_column() );
ok( ! $sh->do_load( $LOAD_SQL ));
ok( ! $sh->do_go );

ok( ! $sh->do_column(qw{ctime noprint}) );

ok( ! $sh->do_column() );

ok( ! $sh->do_load( $LOAD_SQL ));
ok( ! $sh->do_go );

ok( ! $sh->do_column(qw{ctime print}) );
ok( ! $sh->do_load( $LOAD_SQL ));
ok( ! $sh->do_go );

ok(  $sh->do_column(q{clear}) );
ok( ! $sh->do_column() );

ok( ! $sh->do_column(qw{ctime format a10}) );

$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok( ! $sh->do_column(qw{ctime noprint}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok( ! $sh->do_column(qw{ctime print}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok( ! $sh->do_column(qw{ctime off}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok(  $sh->do_column(qw{clear}) );

ok( ! $sh->do_column(qw{ctime format a10}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok(  $sh->do_set(qw{heading undef}) );
is(  $sh->do_set(qw{underline off}), undef, "turn underline off" );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok(  $sh->do_set(qw{underline -}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok(  $sh->do_set(qw{underline undef}) );
ok(  $sh->do_set(qw{heading on}) );
ok( ! $sh->do_column(qw{ctime format a10 heading 'This is my heading'}) );
ok( ! $sh->do_column() );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok(  $sh->do_set(qw{underline -}) );
ok( ! $sh->do_column(qw{ctime heading 'New Heading'}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok( ! $sh->do_column(qw{ctime}) );

ok(  $sh->do_column(qw{clear}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok(  $sh->do_set(qw{underline -}) );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Underline test -'}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

is(  $sh->do_set(qw{underline off} ), undef, "Turn underline off" );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Underline test off'}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok(  $sh->do_set(qw{underline on} ) );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Underline test on'}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );

ok( ! $sh->do_column(qw{ctime format a20 heading 'Justify test center' justify center}) );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Justify test centre' justify centre}) );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Justify test right'  justify right}) );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Justify test left'   justify left}) );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Justify test off'    justify off}) );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Justify test of'    justify of}) );
ok(  $sh->do_column(qw{ctime format a20 heading 'Justify test o'    justify o}) );
ok(  $sh->do_column(qw{ctime format a20 heading 'Justify test on'    justify on}) );
ok(  $sh->do_column(qw{ctime format a20 heading 'Justify test yuck'    justify yuck}) );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Justify test rihgt'  justify rihgt}) );
ok(  $sh->do_column(qw{ctime format a20 heading 'Justify test irhgt'  justify irhgt}) );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Justify test r'      justify r}) );
ok( ! $sh->do_column(qw{ctime format a20 heading 'Justify test j r'      j r}) );

ok( ! $sh->do_column() );
ok(  $sh->do_column(qw{clear}) );

ok(  $sh->do_set(qw{underline -} ) );
is(  $sh->do_set(qw{heading off} ), undef, "Turn heading off" );
ok(  $sh->do_set(qw{heading on} ) );
ok( ! $sh->do_column(qw{ctime format a20 j l heading 'Justify left'}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );
ok( ! $sh->do_column() );
ok( ! $sh->do_column(qw{ctime format a20 j r heading 'Justify right'}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );
ok( ! $sh->do_column() );
ok( ! $sh->do_column(qw{ctime format a20 j c heading 'Justify center'}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );
ok( ! $sh->do_column() );
ok( ! $sh->do_column(qw{ctime format a20 j of heading 'Justify off'}) );
$sh->{current_buffer} = q{select ctime from t};
ok( ! $sh->do_go );
ok( ! $sh->do_column() );

ok( ! $sh->do_column() );
ok(  $sh->do_column(qw{clear}) );

ok(  $sh->do_set(qw{null 'stuff'} ), "Null value text tests" );
ok(  $sh->do_set(qw{null 'null boring stuff'} ) );
ok(  $sh->do_set(qw{null ""} ) );
ok(  $sh->do_set(qw{null &localtime()} ) );
is(  $sh->do_set(qw{null off}), undef, "set null off");

is(  $sh->do_set(qw{pagesize off})	, undef, "pagesize off" );
is(  $sh->do_set(qw{pagesize 10})	, 10, "set pagesize 10" );
is(  $sh->do_set(qw{pagesize} )		, 10, "is pagesize 10" );

is(  $sh->do_set(qw{limit})	, undef, "row limit undef" );
is(  $sh->do_set(qw{limit 100})	, 100, "set row limit 100" );
is(  $sh->do_set(qw{limit})	, 100, "row limit is 100" );
is(  $sh->do_set(qw{limit off})	, undef, "row limit is off" );

$sh->{current_buffer} = q{select yuck_error from t};
ok( ! $sh->do_go );
ok( $sh->do_show(qw{sqlcode}) );

=heading
ok( $sh->do_set(qw{appinfo}) );
ok( $sh->do_set(qw{arraysize}) );
ok( $sh->do_set(qw{autocommit}) );
ok( $sh->do_set(qw{autoprint}) );
ok( $sh->do_set(qw{autorecovery}) );
ok( $sh->do_set(qw{autotrace}) );
ok( $sh->do_set(qw{blockterminator}) );
ok( $sh->do_set(qw{buffer}) );
ok( $sh->do_set(qw{closecursor}) );
ok( $sh->do_set(qw{cmdsep}) );
ok( $sh->do_set(qw{compatibility}) );
ok( $sh->do_set(qw{concat}) );
ok( $sh->do_set(qw{copycommit}) );
ok( $sh->do_set(qw{copytypecheck}) );
ok( $sh->do_set(qw{define}) );
ok( $sh->do_set(qw{document}) );
ok( $sh->do_set(qw{echo}) );
ok( $sh->do_set(qw{editfile}) );
ok( $sh->do_set(qw{embedded}) );
ok( $sh->do_set(qw{escape}) );
ok( $sh->do_set(qw{feedback}) );
ok( $sh->do_set(qw{flagger}) );
ok( $sh->do_set(qw{flush}) );
ok( $sh->do_set(qw{heading}) );
ok( $sh->do_set(qw{headsep}) );
ok( $sh->do_set(qw{instance}) );
ok( $sh->do_set(qw{linesize}) );
ok( $sh->do_set(qw{logsource}) );
ok( $sh->do_set(qw{long}) );
ok( $sh->do_set(qw{longchunksize}) );
ok( $sh->do_set(qw{maxdata}) );
ok( $sh->do_set(qw{newpage}) );
ok( $sh->do_set(qw{null}) );
ok( $sh->do_set(qw{numwidth}) );
ok( $sh->do_set(qw{pagesize}) );
ok( $sh->do_set(qw{pause}) );
ok( $sh->do_set(qw{recsep}) );
ok( $sh->do_set(qw{recsepchar}) );
ok( $sh->do_set(qw{scan}) );
ok( $sh->do_set(qw{serveroutput}) );
ok( $sh->do_set(qw{shiftinout}) );
ok( $sh->do_set(qw{showmode}) );
ok( $sh->do_set(qw{space}) );
ok( $sh->do_set(qw{sqlblanklines}) );
ok( $sh->do_set(qw{sqlcase}) );
ok( $sh->do_set(qw{sqlcontinue}) );
ok( $sh->do_set(qw{sqlnumber}) );
ok( $sh->do_set(qw{sqlprefix}) );
ok( $sh->do_set(qw{sqlprompt}) );
ok( $sh->do_set(qw{sqlterminator}) );
ok( $sh->do_set(qw{suffix}) );
ok( $sh->do_set(qw{tab}) );
ok( $sh->do_set(qw{termout}) );
ok( $sh->do_set(qw{time}) );
ok( $sh->do_set(qw{timing}) );
ok( $sh->do_set(qw{trimout}) );
ok( $sh->do_set(qw{trimspool}) );
ok( $sh->do_set(qw{truncate}) );
ok( $sh->do_set(qw{underline}) );
ok( $sh->do_set(qw{verify}) );
ok( $sh->do_set(qw{wrap}) );

ok( ! $sh->do_show() );
ok( ! $sh->do_show(qw{all}) );
ok( ! $sh->do_show(qw{btitle}) );
ok( ! $sh->do_show(qw{columns}) );
ok( ! $sh->do_show(qw{errors}) );
ok( ! $sh->do_show(qw{grants}) );
ok( ! $sh->do_show(qw{help}) );
ok( ! $sh->do_show(qw{hints}) );
ok( ! $sh->do_show(qw{lno}) );
ok( ! $sh->do_show(qw{me}) );
ok( ! $sh->do_show(qw{objects}) );
ok( ! $sh->do_show(qw{packages}) );
ok( ! $sh->do_show(qw{parameters}) );
ok( ! $sh->do_show(qw{password}) );
ok( ! $sh->do_show(qw{pno}) );
ok( ! $sh->do_show(qw{release}) );
ok( ! $sh->do_show(qw{repfooter}) );
ok( ! $sh->do_show(qw{repheader}) );
ok( ! $sh->do_show(qw{sga}) );
ok( ! $sh->do_show(qw{show}) );
ok( ! $sh->do_show(qw{spool}) );
ok( ! $sh->do_show(qw{sqlcode}) );
ok( ! $sh->do_show(qw{roles}) );
ok( ! $sh->do_show(qw{ttitle}) );
ok( ! $sh->do_show(qw{users}) );
ok( ! $sh->do_show(qw{views}) );

ok( ! $sh->do_accept );
ok( ! $sh->do_append );
ok( ! $sh->do_attribute );
ok( ! $sh->do_break );
ok( ! $sh->do_btitle );
ok( ! $sh->do_change );
ok(  $sh->do_clear );
ok( ! $sh->do_copy );
ok( ! $sh->do_column );
ok( ! $sh->do_define );
ok( ! $sh->do_edit );
ok( ! $sh->do_get );
ok( ! $sh->do_pause );
ok( ! $sh->do_prompt );
ok( ! $sh->do_repheader );
ok( ! $sh->do_repfooter );
ok( ! $sh->do_run );
ok( ! $sh->do_save );
ok( ! $sh->do_set );
ok( ! $sh->do_show );
ok( ! $sh->do_spool );
ok( ! $sh->do_start );
ok( ! $sh->do_ttitle );
ok( ! $sh->do_undefine );
=cut

ok( ! $sh->do_disconnect, "Disconnect from source." );
$sh = undef;

END { unlink $SAVE_SQL if -f $SAVE_SQL }

__END__
