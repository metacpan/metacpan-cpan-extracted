#!/usr/bin/perl -w

#use strict;
use Getopt::Std;

use Tk;
use Tk qw(exit);
use Tk::BrowseEntry;
use Tk::DialogBox;
#use Tk::FileSelect;
require Tk::TextUndo;
require Tk::ROText;

sub usage () {
print <<X;
$0 [-D][-h]
	-D run in DOS mode
	-h prints this message 
X
}


sub getMaxLength {
	local $maxl = 0;
	foreach $s (@_) {
		if ( length($s) > $maxl ) {
			$maxl = length($s);
		}
	}
	return $maxl;
}

getopts('Dh');

my $DOS = 0;
if ( $opt_D ) { $DOS = 1; };
if ( $opt_h ) { &usage(); exit; };

my $SQLLDR = "sqlldr";
my $USER = "ACESPROD";
my $DATABASE = "ACESPROD";
my $TOPDIR = ".";
my $CTLFILE = "Please select a table from the list";
my $LOGFILE = "Please select a table from the list";
my $BADFILE = "Please select a table from the list";
my $DISCFILE = "Please select a table from the list";
my $SHFILE = "Please select a table from the list";
my $PASSWORD = "";
my $selectedTable = "";
my %tables = (
	DOD_CIV_MASTER 	=> {
		InitDir	=> "E:\\russ\\co\\tables\\DOD_CIV_MASTER\\",
		CtlFile => "DOD_CIV_MASTER.ctl", 
		LogFile => "DOD_CIV_MASTER.log", 
		BadFile => "DOD_CIV_MASTER.bad", 
		DisFile => "DOD_CIV_MASTER.dis", 
		FFFile => "DOD_CIV_MASTER.in", 
		SHFile => "sqlldr.sh"
		},
	DOD_CIV_PAY	=> {
		InitDir	=> "E:\\russ\\co\\tables\\DOD_CIV_PAY\\",
		CtlFile => "DOD_CIV_PAY.ctl", 
		LogFile => "DOD_CIV_PAY.log", 
		BadFile => "DOD_CIV_PAY.bad", 
		DisFile => "DOD_CIV_PAY.dis", 
		FFFile => "DOD_CIV_PAY.in", 
		SHFile => "sqlldr.sh" 
		},
	DOD_CIV_TRNS	=> {
		InitDir	=> "E:\\russ\\co\\tables\\DOD_CIV_TRNS\\",
		CtlFile => "DOD_CIV_TRNS.ctl", 
		LogFile => "DOD_CIV_TRNS.log", 
		BadFile => "DOD_CIV_TRNS.bad", 
		DisFile => "DOD_CIV_TRNS.dis", 
		FFFile => "DOD_CIV_TRNS.in", 
		SHFile => "sqlldr.sh"
		},
	DOD_ENL_MIL_PAY	=> {
		InitDir	=> "E:\\russ\\co\\tables\\DOD_ENL_MIL_PAY\\",
		CtlFile => "DOD_ENL_MIL_PAY.ctl", 
		LogFile => "DOD_ENL_MIL_PAY.log", 
		BadFile => "DOD_ENL_MIL_PAY.bad", 
		DisFile => "DOD_ENL_MIL_PAY.dis", 
		FFFile => "DOD_ENL_MIL_PAY.in", 
		SHFile => "sqlldr.sh"
		},
	DOD_OFF_MIL_PAY	=> {
		InitDir	=> "E:\\russ\\co\\tables\\DOD_OFF_MIL_PAY\\",
		CtlFile => "DOD_OFF_MIL_PAY.ctl", 
		LogFile => "DOD_OFF_MIL_PAY.log", 
		BadFile => "DOD_OFF_MIL_PAY.bad", 
		DisFile => "DOD_OFF_MIL_PAY.dis", 
		FFFile => "DOD_OFF_MIL_PAY.in", 
		SHFile => "sqlldr.sh"
		},
	PR_SRVC_MASTER	=> {
		InitDir	=> "E:\\russ\\co\\tables\\PR_SRVC_MASTER\\",
		CtlFile => "PR_SRVC_MASTER.ctl", 
		LogFile => "PR_SRVC_MASTER.log", 
		BadFile => "PR_SRVC_MASTER.bad", 
		DisFile => "PR_SRVC_MASTER.dis", 
		FFFile => "PR_SRVC_MASTER.in", 
		SHFile => "sqlldr.sh"
		},
	Other 	=> {
		InitDir	=> "E:\\russ\\co\\tables\\",
		CtlFile => "other.ctl", 
		LogFile => "other.log", 
		BadFile => "other.bad", 
		DisFile => "other.dis", 
		FFFile => "other.in", 
		SHFile => "sqlldr.sh"
		}
);

my @USERNAMES = (
	"SYS",
	"SYSTEM",
	"OUTLN",
	"DBSNMP",
	"ORDSYS",
	"ORDPLUGINS",
	"MDSYS",
	"RUSSELL",
	"JPAS",
	"CTXSYS",
	"ACES",
	"NRE",
	"CREDITARCHIVE",
	"CREDIT724",
	"CREDIT627",
	"TOAD",
	"PLVISION",
	"CREDIT822",
	"REMOTEDBA",
	"RMAN",
	"ACESPROD",
	"ORACLEEM"
);
my $USERNAMES_INDEX = -1;

$top = MainWindow->new();
$frame = $top->Frame();

@t = keys(%tables);
$tableList = $top->Listbox(
	"width" => &getMaxLength(keys(%tables)) + 10, 
	"height" => $#t + 1 
	);
$tableList->packAdjust( -side => 'left', -fill => 'both', -delay => 1);
$frame->pack( -side => 'left', -fill => 'y', -expand => 'y', anchor => 'w');

$buttonSqlldr = $frame->Button( 
	-relief => "groove", 
	-text => "SQLLDR", 
	-command => \&buttonSqlldrCallback )->pack(anchor => 'w');
$entrySqlldr = $frame->Entry( 
	-width => 60, 
	-textvariable => \$SQLLDR  );
$entrySqlldr->form( -top=>[$buttonSqlldr,0] );

$buttonUser = $frame->Button( 
	-relief => "groove", 
	-text => "User", 
	-command => \&buttonUserCallback )->form( -top => [$entrySqlldr,0]);
$entryUser = $frame->BrowseEntry( 
	-width => 60, 
	-background => 'white',  
	-variable => \$USER  );
$entryUser->insert( "end", @USERNAMES );
$entryUser->form(-top => [$buttonUser,0]);

$labelPassWord = $frame->Label( 
	-relief => "groove", 
	-justify => "left", 
	-text => "Password", 
	-width => 10 )->form( -top=> [$entryUser,0]);
$entryPassWord = $frame->Entry( 
	-width => 60, 
	-show => '*', 
	-textvariable => \$PASSWORD )->form(-top=>[$labelPassWord,0]);

$labelDatabase = $frame->Label( 
	-relief => "groove", 
	-justify => "left", 
	-text => "Database", 
	-width => 10 )->form(-top=> [$entryPassWord,0]);
$entryDatabase = $frame->Entry( 
	-width => 60, 
	-textvariable => \$DATABASE  )->form(-top => [$labelDatabase,0]);

$buttonCtlFile = $frame->Button( 
	-relief => "groove", 
	-state => "disable", 
	-text => "Control File", -command => \&buttonCtlFileCallback)->form(-top=>[$entryDatabase,0]);
$buttonViewCtlFile = $frame->Button( 
	-relief => "groove", 
	-text => 'View', 
	-state => 'disabled', 
	-command => \&buttonViewCtlCallback )->form(-top=>['&',$buttonCtlFile,0], -left=>[$buttonCtlFile,0]);
$entryCtlFile = $frame->Entry( 
	-width => 60, 
	-textvariable => \$CTLFILE )->form(-top=>[$buttonViewCtlFile,0]);

$buttonBadFile = $frame->Button( 
	-relief => "groove", 
	-state => "disable", 
	-text => "Bad File", 
	-command => \&buttonBadFileCallback)->form(-top => [$entryCtlFile,0] );
$buttonViewBadFile = $frame->Button( 
	-relief => "groove", 
	-text => 'View', 
	-state => 'disabled', 
	-command => \&buttonViewBadCallback )->form(-top => ['&',$buttonBadFile,0], -left=>[$buttonBadFile,0]);
$entryBadFile = $frame->Entry( 
	-width => 60, 
	-textvariable => \$BADFILE )->form(-top=>[$buttonViewBadFile,0]);

$buttonLogFile = $frame->Button( 
	-relief => "groove", 
	-state => "disable", 
	-text => "Log File", 
	-command => \&buttonLogFileCallback)->form(-top =>[$entryBadFile,0]);

$buttonViewLogFile = $frame->Button( 
	-relief => "groove", 
	-text => 'View', 
	-state => 'disabled', 
	-command => \&buttonViewLogCallback )->form(-top => ['&',$buttonLogFile,0], -left=>[$buttonLogFile,0]);
$entryLogFile = $frame->Entry( 
	-width => 60, 
	-textvariable => \$LOGFILE )->form(-top=>[$buttonLogFile,0]);

$buttonDisFile = $frame->Button( 
	-relief => "groove", 
	-state => "disable", 
	-text => "Discard File", 
	-command => \&buttonDisFileCallback)->form(-top => [$entryLogFile,0]);
$buttonViewDisFile = $frame->Button( 
	-relief => "groove", 
	-text => 'View', 
	-state => 'disabled', 
	-command => \&buttonViewDisCallback )->form(-top => ['&',$buttonDisFile,0], -left=>[$buttonDisFile,0]);
$entryDiscardFile = $frame->Entry( 
	-width => 60, 
	-textvariable => \$DISCFILE )->form(-top=>[$buttonViewDisFile,0]);

$buttonFFFile = $frame->Button( 
	-relief => "groove", 
	-state => "disable", 
	-text => "Flat File", 
	-command => \&buttonFFFileCallback)->form(-top=>[$entryDiscardFile,0]);
$buttonViewFFFile = $frame->Button( 
	-relief => "groove", 
	-text => 'View', 
	-state => 'disabled', 
	-command => \&buttonViewFFFileCallback )->form(-top => ['&',$buttonFFFile,0], -left=>[$buttonFFFile,0]);
$entryFlatFile = $frame->Entry( 
	-width => 60,  
	-textvariable => \$FLATFILE )->form(-top=>[$buttonViewFFFile,0] );

$buttonSHFile = $frame->Button( 
	-relief => "groove", 
	-state => "disable", 
	-text => "Script", 
	-command => \&buttonSHFileCallback)->form(-top=>[$entryFlatFile,0]);
$buttonViewSHFile = $frame->Button( 
	-relief => "groove", 
	-text => 'View', 
	-state => 'disabled', 
	-command => \&buttonViewSHFileCallback )->form(-top => ['&',$buttonSHFile,0], -left=>[$buttonSHFile,0]);
$entryScript = $frame->Entry( 
	-width => 60,  
	-textvariable => \$SHFILE )->form(-top=>[$buttonViewSHFile,0]);

$buttonPreview = $frame->Button( 
	-text => 'Preview', 
	-state => 'disabled', 
	-command => \&buttonPreviewCallback )->form(-top=>[$entryScript,0]);
$buttonClear = $frame->Button( 
	-text => 'Clear', 
	-state => 'disabled', 
	-command => \&buttonClearCallback )->form(-top => ['&', $buttonPreview,0], -left=>[$buttonPreview,0]);
$frame->Button( 
	-text => 'Exit', 
	-state => 'active', 
	-command => \&buttonExitCallback )->form(-top =>['&',$buttonClear,0], -right=>['&',$entryScript,0] );

$tableList->insert( 'end', keys(%tables) );
$tableList->bind('<Double-1>', \&tableListCallback );

sub buttonExitCallback { Tk::exit; }

sub buttonClearCallback {
	$CTLFILE 	= "Please select a table from the list";
	$LOGFILE 	= "Please select a table from the list";
	$BADFILE 	= "Please select a table from the list";
	$DISCFILE 	= "Please select a table from the list";
	$FLATFILE 	= "Please select a table from the list";
	$SHFILE 	= "Please select a table from the list";
	###
	### disable buttons
	###
	$buttonPreview->configure	( -state => 'disable' );
	$buttonCtlFile->configure	( -state => 'disable' );
	$buttonBadFile->configure	( -state => 'disable' );
	$buttonLogFile->configure	( -state => 'disable' );
	$buttonDisFile->configure	( -state => 'disable' );
	$buttonFFFile->configure	( -state => 'disable' );
	$buttonSHFile->configure	( -state => 'disable' );
	$buttonViewCtlFile->configure	( -state => 'disable' );
	$buttonViewBadFile->configure	( -state => 'disable' );
	$buttonViewLogFile->configure	( -state => 'disable' );
	$buttonViewDisFile->configure	( -state => 'disable' );
	$buttonViewFFFile->configure	( -state => 'disable' );
	$buttonViewSHFile->configure	( -state => 'disable' );

	$selectedTable = "None";
}

sub tableListCallback {
	my $table = $tableList->get('active');
	return if (!$table);
	$CTLFILE = $tables{$table}{"CtlFile"};
	$LOGFILE = $tables{$table}{"LogFile"};
	$BADFILE = $tables{$table}{"BadFile"};
	$DISCFILE = $tables{$table}{"DisFile"};
	$FLATFILE = $tables{$table}{"FFFile"};
	$SHFILE = $tables{$table}{"SHFile"};
	###
	### enable buttons
	###
	$buttonPreview->configure( -state => 'active' );
	$buttonCtlFile->configure( -state => 'active' );
	$buttonBadFile->configure( -state => 'active' );
	$buttonLogFile->configure( -state => 'active' );
	$buttonDisFile->configure( -state => 'active' );
	$buttonFFFile->configure( -state => 'active' );
	$buttonSHFile->configure( -state => 'active' );

	$buttonViewCtlFile->configure( -state => 'active' );
	$buttonViewBadFile->configure( -state=> 'active' ); 
	$buttonViewLogFile->configure( -state=> 'active' ); 
	$buttonViewDisFile->configure( -state=> 'active' ); 
	$buttonViewFFFile->configure( -state=> 'active' );
	$buttonViewSHFile->configure( -state=> 'active' ); 

	$buttonClear->configure( -state => 'active' );
	$selectedTable = $table;
}

sub buttonSqlldrCallback { $SQLLDR = `/usr/bin/which sqlldr`; }
sub buttonUserCallback { 
	$USERNAMES_INDEX++;
	$USER = $USERNAMES[$USERNAMES_INDEX%$#USERNAMES+1];	
}

sub dosify {
	my ($fileName) = @_;
	if ( $DOS == 0 ) {
		$_ = $fileName;
		s/E:/\/cygdrive\/e/g;
		s/\\/\//g;
		$fileName = $_;
	} 
	return $fileName;
}

sub buttonCtlFileCallback  {
	local $userSelectedFile = $top->getOpenFile(
		-defaultextension => ".ctl",
		-filetypes	=> 
			[
				['Control Files', '.ctl'],
				['All Files', '*']
			],
		-initialdir	=>	$tables{$selectedTable}{"InitDir"},
		-initialfile	=>	$tables{$selectedTable}{"CtlFile"},
		-title		=> 	"Select a control file for $selectedTable"
	);
	if ($userSelectedFile) {
		$CTLFILE = &dosify( $userSelectedFile );
	}
}

sub buttonViewCtlCallback {
	local $d = $top->DialogBox( -title => "View Control File", -buttons => ["Done"] );
	local $t = $d->add( 'Scrolled', 'TextUndo', -wrap => 'none' );
	$t->pack();
	if( -T $CTLFILE ) {
		$t->Load( $CTLFILE );
		local $button = $d->Show;
	} else {
		print "$CTLFILE does not exist\n";
		&buttonCtlFileCallback;
	}
}

sub buttonBadFileCallback  { 
	local $userSelectedFile = $top->getSaveFile(
		-defaultextension => ".bad",
		-filetypes	=> 
			[
				['Bad Files', '.bad'],
				['All Files', '*']
			],
		-initialdir	=>	$tables{$selectedTable}{"InitDir"},
		-initialfile	=>	$tables{$selectedTable}{"BadFile"},
		-title		=> 	"Select a bad file for $selectedTable"
	); 
	if ($userSelectedFile) {
		$BADFILE = &dosify( $userSelectedFile );
	}
}

sub buttonViewBadCallback {
	local $d = $top->DialogBox( -title => "View Bad File", -buttons => ["Done"] );
	local $t = $d->add( 'Scrolled', 'TextUndo', -wrap => 'none' );
	$t->pack();
	if( -T $BADFILE ) {
		$t->Load( $BADFILE );
		local $button = $d->Show;
	} else {
		print "$BADFILE does not exist\n";
		&buttonBadFileCallback;
	}
}

sub buttonLogFileCallback  { 
	local $userSelectedFile = $top->getSaveFile(
		-defaultextension => ".log",
		-filetypes	=> 
			[
				['Log Files', '.log'],
				['All Files', '*']
			],
		-initialdir	=>	$tables{$selectedTable}{"InitDir"},
		-initialfile	=>	$tables{$selectedTable}{"LogFile"},
		-title		=> 	"Select a log file for $selectedTable"
	); 
	if ($userSelectedFile) {
		$LOGFILE = &dosify( $userSelectedFile );
	}
}

sub buttonViewLogCallback {
	local $d = $top->DialogBox( -title => "View Log File", -buttons => ["Done"] );
	local $t = $d->add( 'Scrolled', 'TextUndo', -wrap => 'none' );
	$t->pack();
	if( -T $LOGFILE ) {
		$t->Load( $LOGFILE );
		local $button = $d->Show;
	} else {
		print "$LOGFILE does not exist\n";
		&buttonLogFileCallback;
	}
}

sub buttonDisFileCallback  { 
	local $userSelectedFile = $top->getSaveFile(
		-defaultextension => ".dis",
		-filetypes	=> 
			[
				['Discard Files', '.dis'],
				['All Files', '*']
			],
		-initialdir	=>	$tables{$selectedTable}{"InitDir"},
		-initialfile	=>	$tables{$selectedTable}{"DisFile"},
		-title		=> 	"Select a discard file for $selectedTable"
	); 
	if ($userSelectedFile) {
		$DISCFILE = &dosify( $userSelectedFile );
	}
}

sub buttonViewDisCallback {
	local $d = $top->DialogBox( -title => "View Discard File", -buttons => ["Done"] );
	local $t = $d->add( 'Scrolled', 'TextUndo', -wrap => 'none' );
	$t->pack();
	if( -T $DISCFILE ) {
		$t->Load( $DISCFILE );
		local $button = $d->Show;
	} else {
		print "$DISCFILE does not exist\n";
		&buttonDisFileCallback;
	}
}

sub buttonFFFileCallback   { 
	local $userSelectedFile = $top->getOpenFile(
		-defaultextension => ".dat",
		-filetypes	=> 
			[
				['Flat Files', '.dat'],
				['Flat Files', '.in'],
				['All Files', '*']
			],
		-initialdir	=>	$tables{$selectedTable}{"InitDir"},
		-initialfile	=>	$tables{$selectedTable}{"FFFile"},
		-title		=> 	"Select a flat file for $selectedTable"
	); 
	if ($userSelectedFile) {
		$FLATFILE = &dosify( $userSelectedFile );
	}
}


sub buttonViewFFFileCallback {
	local $d = $top->DialogBox( -title => "View Flat File", -buttons => ["Done"] );
	local $t = $d->add( 'Scrolled', 'TextUndo', -wrap => 'none' );
	$t->pack();
	if( -T $FLATFILE ) {
		$t->Load( $FLATFILE );
		local $button = $d->Show;
	} else {
		print "$FLATFILE does not exist\n";
		&buttonFFFileCallback;
	}
}

sub buttonSHFileCallback  { 
	local $userSelectedFile = $top->getSaveFile(
		-defaultextension => ".sh",
		-filetypes	=> 
			[
				['Shell Program', '.sh'],
				['All Files', '*']
			],
		-initialdir	=>	$tables{$selectedTable}{"InitDir"},
		-initialfile	=>	$tables{$selectedTable}{"SHFile"},
		-title		=> 	"Name the shell script to load $selectedTable"
	); 
	if ($userSelectedFile) {
		$SHFILE = &dosify( $userSelectedFile );
	}
}

sub buttonViewSHFileCallback {
	local $d = $top->DialogBox( -title => "View Shell Script", -buttons => ["Done"] );
	local $t = $d->add( 'Scrolled', 'TextUndo', -wrap => 'none' );
	$t->pack();
	if( -T $SHFILE ) {
		$t->Load( $SHFILE );
		local $button = $d->Show;
	} else {
		print "$SHFILE does not exist\n";
		&buttonSHFileCallback;
	}
}

sub buttonPreviewCallback  { 
open OUT, ">$SHFILE" or die "Cannot open $SHFILE:$!\n";
print OUT<<EOT;
#!/bin/bash
SQLLDR=$SQLLDR
USERID=$USER/$PASSWORD\@$DATABASE
CONTROL=$CTLFILE
BAD=$BADFILE
LOG=$LOGFILE
DISCARD=$DISCFILE
DATA=$FLATFILE
echo \$SQLLDR userid=\$USERID control=\$CONTROL log=\$LOG data=\$DATA
\$SQLLDR userid=\$USERID control=\$CONTROL log=\$LOG bad=\$BAD discard=\$DISCARD data=\$DATA
EOT
close(OUT);
	local $d = $top->DialogBox( -title => "Preview Shell Script", -buttons => ["Execute", "Cancel"] );
	local $t = $d->add( 'Scrolled', 'TextUndo', -wrap => 'none' );
	$t->pack();
	if( -T $SHFILE ) {
		$t->Load( $SHFILE );
		local $button = $d->Show;
		print "Button = $button\n";
		if ( $button =~ /Execute/ ) {
			@args = ( $SHFILE );
			system( @args ) == 0 or die "Could not execute @args:$!\n";
		}
	} else {
		print "$SHFILE does not exist\n";
		&buttonSHFileCallback;
	}
}
MainLoop();
