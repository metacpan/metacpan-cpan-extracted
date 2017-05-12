use 5.6.0;
package DBIx::Informix::Perform;

use strict;
use warnings;
use Carp;
use Curses;			# to get KEY_*
use Curses::Application;
use DBI;
use POSIX;
use DBIx::Informix::Perform::DButils;

#  Apparently it's necessary to directly "use" the derived form types one wants...

use DBIx::Informix::Perform::Forms;
# use DBIx::Informix::Perform::Widgets;
use DBIx::Informix::Perform::Widgets::TextField;
use DBIx::Informix::Perform::Widgets::ButtonSet;

use base 'Exporter';

our $VERSION = 0.01;

use vars qw(@EXPORT_OK %FORM %APP
	    $APP $FORM $DB $NO_MORE_ROWS);

$NO_MORE_ROWS = "No more rows in the direction you are going.";

@EXPORT_OK = qw(run);

%FORM =
    (TABORDER	=> ['Buttons', 'DBForm'],
     TYPE	=> '',		# but from DBIx::Informix::Perform::Forms
     #  There is some bug in the alt[f]base stuff in Curses::Forms.
     ALTFBASE	=> ['DBIx::Informix::Perform::Forms', 'DBIx::Informix::Perform::Widgets'],
     ALTBASE	=> ['DBIx::Informix::Perform::Forms', 'DBIx::Informix::Perform::Widgets'],
     FOCUSED	=> 'Buttons',
     WIDGETS	=> {
	 Buttons	=> {
	     TYPE	=> 'ButtonSet',
	     BORDER	=> 0,
	     X		=> 1,
	     Y		=> 0,
	     LABELS	=> [qw(Query Next Prev. Add Update Remove Exit)],
	     LENGTH	=> 6,
	     FOCUSSWITCH=> "\t\nmd",
	     OnExit	=> \&ButtonPush,
	 },
     },
     );

%APP =
(
 FOREGROUND	=> 'white',
 BACKGROUND	=> 'black',
 MAINFORM	=> { Dummy	=> 'DummyDef' }, # changed at runtime
 STATUSBAR	=> 1,
 EXIT		=> 0,
 form_name 	=> 'Run0',
 form_names	=> ['Run0'],		# set later
 form_name_indexes => { Run0 => 0 }, # also set later
 md_mode	=> 'm',		# master/detail mode, "m" or "d".
 resume_command => undef,	# do the specified command after switching
				# master/detail context or screens.
 );


	    
sub run
{
    my $arg = shift;

    my $form = load($arg);
    $DB = DBIx::Informix::Perform::DButils::open_db($form->{'db'});
    run_form($form);
}


sub run_form
{
    my $form = shift;

    my %appdef = %APP;
    if (defined (my $minsize = $form->{'screen'}{'MINSIZE'})) {
	@appdef{'MINX', 'MINY'} = @$minsize;
    }
    my $instrs = $appdef{'instrs'} = $form->{'instrs'};
    my $masters = $instrs && $$instrs{'MASTERS'};
    $appdef{'MASTERS'} = $masters; 		# n.b. add it even if undef'd.
    $appdef{'BACKGROUND'} = $ENV{'BGCOLOR'}
      if $ENV{'BGCOLOR'};
    $APP = new Curses::Application (\%appdef)
	or die "Unable to create application object";
    my $mwh = $APP->mwh();	# main window handle.
    my ($maxy, $maxx) = $APP->maxyx();
    my $i = 0;
    my @subformdefs = curses_formdefs($form, $maxy-2, $maxx, \%appdef);
    my @formnames;
    foreach my $sfd (@subformdefs) {
	my %runformdef = %FORM;
	my $defname = "RunDef$i";
	my $formname = "Run$i";
	@runformdef{qw(X Y LINES COLUMNS DERIVED SUBFORMS)} =
	    (0, 0, $maxy-1, $maxx, 1, { 'DBForm' => $sfd });
	push (@formnames, $formname);
	$APP->addFormDef($defname, { %runformdef });
	$APP->createForm($formname, $defname);
	$i++;
    }
    $APP->setField(MAINFORM => {Run0 => 'RunDef0'});
    $APP->setField(form_names => [ @formnames ]);
    $APP->setField(form_name_indexes =>
		   +{ map {($formnames[$_], $_)} 0..$#formnames });
    $APP->draw();
    while (! $APP->getField('EXIT')) { # run until user exits.
	my $fname = $APP->getField('form_name');
	local $FORM = $APP->getForm($fname);
	my $resumecmd = $APP->getField('resume_command');
	if ($resumecmd) {
	    &$resumecmd($FORM);
	    $APP->setField('resume_command', undef);
	}
	$APP->execForm($fname);
    }
}


# returns a (spread) array of form defs.
# In a master/detail arrangement, the master form is presumed to be first.
sub curses_formdefs
{
    my $formspec = shift;	# parsed from a .per file...
    my $maxy = shift;
    my $maxx = shift;
    my $appdef = shift;

    my @screens = @{$formspec->{'screens'}};
    my $attrs = $formspec->{'attrs'};
    my $lineoffset = 0;		# used for combining screens
    my @formdefs = ();
    my $i = 0;
    my $appbg = $$appdef{'BACKGROUND'};
    my $deffldbg = $ENV{'FIELDBGCOLOR'} || 'blue';
    foreach my $screen (@screens) { 
	my $widgets = $$screen{'WIDGETS'};
	my $fields = $$screen{'FIELDS'};
	my $subformfields =
	#    [ grep { $$widgets{$_} } @$fields ] ;
	    $fields;		# may not need this, really.
	my $add_taborder =	# fields without NOENTRY attribute
	    [ grep { ! $$attrs{$_}[1]{NOENTRY} } @$subformfields ];
	my $update_taborder =	# fields without NOUPDATE attribute
	    [ grep { ! $$attrs{$_}[1]{NOUPDATE} } @$subformfields ];
	my $defaults =
	    +{map { my $d = $$attrs{$_}[1]{DEFAULT};
		     defined($d) ? ($_, $d) : (); }    @$subformfields };
	my %def = (
		   X => 0,  Y => 1,
		   COLUMNS => $maxx,
		   LINES => $maxy,
		   DERIVED => 1,
		   ALTFBASE => 'DBIx::Informix::Perform::Forms',
		   ALTBASE => 'DBIx::Informix::Perform::Widgets',
		   TABORDER => $fields,
		   tables => $formspec->{'tables'}, # pass these two straight on
		   attrs => $attrs, # to the runtime system.
		   fields => $subformfields, # this is taborder for query mode, too.
		   add_taborder => $add_taborder,
		   update_taborder => $update_taborder,
		   defaults => $defaults,
		   md_mode => 'm', # master/detail mode.
		   editmode => '',
		   # query_save => {},
		   );
	# Now install OnExit trampolines and more for each field...
	foreach my $f (@$fields) {
	    my $w = $widgets->{$f};
	    my ($cols, $fattrs) = @{$$attrs{$f}};
	    #  This "trampoline" function gives field name to the real OnExit fcn.
	    $w->{'OnExit'} = sub{ &OnFieldExit($f, @_); };
	    my $comments = $$fattrs{'COMMENTS'};
	    $w->{'OnEnter'} = sub{ $APP->statusbar($comments); }
	      if ($comments);
	    $w->{'FOCUSSWITCH'} = "\t\n\cp\cw\cc\ck\c[";
	    $w->{'FOCUSSWITCH_MACROKEYS'} = [KEY_UP, KEY_DOWN, KEY_DC];
	    my $color = $fattrs->{'COLOR'}  || $deffldbg;
	    $w->{'BACKGROUND'} = $color;
	    if ($color eq $appbg) {
		# Need the open/close brackets if no color difference.
		$$widgets{"$f.openbracket"} =
		    +{ TYPE => 'Label', COLUMNS => 1, ROWS => 1,
		       Y => $w->{'Y'},  X => $w->{'X'}-1, VALUE => "[" };
		$$widgets{"$f.closebracket"} =
		    +{ TYPE => 'Label', COLUMNS => 1, ROWS => 1,
		       Y => $w->{'Y'},  X => $w->{'X'} + $w->{'COLUMNS'},
		       VALUE => "]" };
	    }
	    # Copy the attributes & columns out in the widgets where
	    # they may be handier.
	    $w->{'columns'} = $cols; # [ [ tbl, col ], ...]
	    $w->{'attrs'} = $fattrs; # { NOENTRY => 1, DEFAULT => '"33"',... }
	    $w->{'savevalue'} = '';
	}
	$def{'WIDGETS'} = { %$widgets },
	push (@formdefs, { %def });
    }
    return @formdefs;
}


sub load
{
    my $arg = shift;

    if (length($arg) < 500) {
	# Assume filename.
	if ($arg =~ /\.per$/) {
	    return load_per($arg);
	}
	elsif ($arg =~ /\.pps/) {
	    return load_file($arg);
	}
	else {
	    die "Unknown file extension on '$arg'";
	}
    }
    else {
	if (ref($arg) =~ /HASH/) {
	    return $arg;
	}
	elsif ($arg =~ /^\s*database\s/m) {
	    require "DBIx/Informix/Perform/DigestPer.pm";
	    return DBIx::Informix::Perform::DigestPer::digest_string($arg);
	}
	elsif ($arg =~ /^\$form\s*=/) {
	    return load_string($arg);
	}
	die "Unrecognized string arg.";
    }
}

# Digest it on the fly.
sub load_per 
{
    my $file = shift;

    open (PER_IN, "< $file")
	|| die "Unable to open '$file' for reading: $!";
    require "DBIx/Informix/Perform/DigestPer.pm";
    my $digest = DBIx::Informix::Perform::DigestPer::digest(\*PER_IN);
    die "File did not digest to a Perl Perform Spec"
	unless $digest =~ /\$form\s*=/;
    return load_string($digest);
}
    
    

sub load_file 
{
    my $file = shift;
    load_internal(sub { require $file });
}

sub load_string
{
    my $string = shift;
    load_internal(sub { eval $string });
}


sub load_internal
{
    my $sub = shift;

    our $form;
    local ($form);
    &$sub();
    return $form;
}


# Run-time functions...

use vars '%BUTTONSUBS';
%BUTTONSUBS =
    (query	=> \&querymode,
     next	=> \&do_next,
     'prev.'	=> \&do_prev,
     add	=> \&addmode,
     update	=> \&updatemode,
     remove	=> \&do_remove,
     exit	=> \&doquit,
     );

sub ButtonPush
{
    my $form = shift;
    my $key = shift;

    if (lc($key) =~ /[md]/) {
	do_master_detail(lc($key), $form);
	return;
    }
    my $wid = $form->getWidget('Buttons');
    my $val = $wid->getField('VALUE');
    my $labels = $wid->getField('LABELS');
    my $thislabel = lc($$labels[$val]);
    my $btnsub = $BUTTONSUBS{$thislabel};
    if ($btnsub && ref($btnsub) eq 'CODE') {
	&$btnsub($form);
    }
    else {
	print STDERR "No button sub for '$thislabel'\n";
	$form->setField('DONTSWITCH', 1);
    }
}

sub clear_textfields
{
    my $subform = shift;

    my $fields = $subform->getField('fields');
    return unless $fields;
    foreach my $f (@$fields) {
	$subform->getWidget($f)->setField('VALUE', '');
    }
}

#  Hope this suffices to switch forms.
sub setSubform
{
    my $form = shift;		# top-level form.
    my $n = shift;

    my $forms = $APP->getField('form_names');
    my $fname = $$forms[$n];
    if ($fname) {
	$APP->setField('form_name', $fname);
	$form->setField('EXIT', 1);
    }
}

use vars qw($STH @ROWS $ROWNUM $STHDONE
	    $MASTER_STH @MASTER_ROWS $MASTER_ROWNUM $MASTER_STHDONE);


sub clear_STH
{
    if ($STH) {
	eval { $STH->finish() }; # ignore errors from this.
	undef $STH;
	@ROWS = ();
	$ROWNUM = -1;
	undef $STHDONE;
    }
}

# If there are no rows, it sets DONTSWITCH and statusbars a message.
#  Returns true if no rows.
sub check_rows_and_advise
{
    my $form = shift;

    if ($#ROWS < 0  ||  !defined($ROWNUM)) {
	$APP->statusbar("There are no rows in the current list.");
	$form->setField('DONTSWITCH', 1);
	return 1;
    }
    return undef;
}

# called from button_push with the top-level form.
sub querymode
{
    my $form = shift;

    #  Shift forcibly back to master mode for query.
    #  FIX_ME? This is an incompatibility, no querying in detail mode.
    if ($APP->getField('md_mode') ne 'm') {
	do_master_detail('m', $form);
	$APP->setField('resume_command', \&querymode_resume);
    }
    my $subform =
	$form->getSubform('DBForm')  ||  $form;
    clear_textfields($subform);
    my $to = $subform->getField('fields');
    $subform->setField('TABORDER', $to);
    $subform->setField('FOCUSED', $to->[0]); # first field.
    $subform->setField('editmode', 'query');
    $APP->statusbar("Enter fields to query.  ESC queries, DEL cancels.");
    # go ahead and switch to the form.
}

# Called as a resume entry, 'cause we have to force the form into
# the subform since we can't rely on lack of DONTSWITCH to switch there.
sub querymode_resume
{
    my ($form) = @_;
    querymode(@_);
    $form->setField('FOCUSED', 'DBForm');
}
    

sub do_master_detail
{
    my $m_or_d = shift;
    my $form = shift;

    my $masters = $APP->getField('MASTERS');
    return ($form->setField('DONTSWITCH', 1) ,
	    $APP->statusbar('No detail table for this form.'))
	unless $masters;	# if not in a m/d form, skip it.
    return undef
	if ($APP->getField('md_mode') eq $m_or_d);
    # Switch modes.
    my $subform = $form->getSubform('DBForm');
    $APP->setField('md_mode', $m_or_d);
    my (@wheres, @vals);
    if ($m_or_d eq 'd') {
	if (@ROWS && $ROWNUM >= 0 && $ROWS[$ROWNUM]) {
	    # Do detail query...
	    # Save state of master query...
	    $MASTER_STH = $STH;
	    @MASTER_ROWS = @ROWS;
	    $MASTER_ROWNUM = $ROWNUM;
	    $MASTER_STHDONE = $STHDONE;
	    $STH = {};		# so the object doesn't get finish()'ed.
	    my $mrow = $MASTER_ROWS[$MASTER_ROWNUM];
	    my $mtable = $masters->[0][0];
	    my $dtable = $masters->[0][1];
	    my $attrs = $subform->getField('attrs');
	    # Get all the join columns...
	    my @keys = grep { scalar @{$$attrs{$_}->[0]} > 1 } keys %$attrs;
	    foreach my $k (@keys) {
		my $f = $$attrs{$k};
		my ($mcol) = grep { $_ ->[0] eq $mtable } @{$f->[0]};
		my ($dcol) = grep { $_ ->[0] eq $dtable } @{$f->[0]};
		push (@wheres, "$dcol->[1] = ?");
		push (@vals, $mrow->{$mcol->[1]});
	    }
	    my $n = do_query_internal($dtable, \@wheres, \@vals);
	    setSubform($form, 1);
	    $APP->setField('resume_command',
			   \&do_next);
	    $n = 0 + $n;	# numericize it.
	    my $p = ($n == 1 ? '' : 's');
	    $APP->statusbar("Detail: $n row$p found; row 0")
		if $n;
	}
	else {
	    $APP->statusbar("No active query; not switching to detail mode.");
	}
    }
    else {
	clear_STH();		# mostly to finish the statement handle.
	$STH = $MASTER_STH;
	@ROWS = @MASTER_ROWS;
	$ROWNUM = $MASTER_ROWNUM;
	$STHDONE = $MASTER_STHDONE;
	setSubform($form, 0);
	display_row_fields($form, $ROWS[$ROWNUM], $ROWNUM);
    }
    
}

# called from button_push with the top-level form.
sub do_next
{
    my $form = shift;
    my $switch = shift;

    $form->setField('DONTSWITCH', 1)
	unless $switch;
    unless ($STH) {
	$APP->statusbar("No query is active.");
	return;
    }
    my ($row, $msg);
    if (!defined($ROWNUM) || $ROWNUM >= $#ROWS) {
	# We're at the end of the fetched rows...
	$row = $STH->fetchrow_hashref()
	    if !$STHDONE;
	if ($row) {
	    push (@ROWS, $row);
	    $ROWNUM = $#ROWS;
	}
	else {
	    # No row was fetched...
	    $msg = $#ROWS < 0 ? "No rows found" : $NO_MORE_ROWS;
	    $APP->statusbar($msg);
	    my $newbtn = @ROWS ? 2 : 0;	# FIX_ME use constants
	    $form->getWidget('Buttons')->setField('VALUE', $newbtn);
	    $STHDONE = 1;
	    if (@ROWS) {
		# Redisplay current row
		$row = $ROWS[$ROWNUM];
		# display_row_fields($form, , $ROWNUM);
	    } else {
		# Punt on the whole thing.
		my $subform = $form->getSubform('DBForm');
		clear_textfields($subform);
		return;
	    }
	}
    }
    else {
	# we are marching forward through already-fetched rows...
	$row = $ROWS[++$ROWNUM];
    }
    display_row_fields($form, $row, $msg ? undef : $ROWNUM);
}

# called from button_push with the top-level form.
sub do_prev
{
    my $form = shift;

    my $display_rownum = $ROWNUM;
    $form->setField('DONTSWITCH', 1);
    if ($ROWNUM <= 0) {
	$APP->statusbar($NO_MORE_ROWS);
	undef $display_rownum;
	my $newbtn = @ROWS ? 1 : 0;	# FIX_ME use constants
	$form->getWidget('Buttons')->setField('VALUE', $newbtn);
    }
    else {
	--$ROWNUM;
    }
    display_row_fields($form, $ROWS[$ROWNUM], $display_rownum);
}

# called from button_push with the top-level form.
sub addmode
{
    my $form = shift;

    my $subform = $form->getSubform('DBForm');
    clear_textfields($subform);
    # go ahead and switch to form.
    
    my $to = $subform->getField('add_taborder');
    $subform->setField('TABORDER', $to);
    $subform->setField('FOCUSED', $to->[0]); # first field.
    $subform->setField('editmode', 'add');
    my $defs = $subform->getField('defaults');
    foreach my $f (keys %{ $defs || {} }) {
	my $v = $$defs{$f};
	$v = POSIX::strftime("%Y-%m-%d", localtime())
	    if uc($v) eq 'TODAY';
	$subform->getWidget($f)->setField('VALUE', $v);
    }
    $APP->statusbar("Enter row to add.  ESC stores; DEL cancels the add.");
}

# called from button_push with the top-level form.
sub updatemode
{
    my $form = shift;

    return if check_rows_and_advise($form);
    my $subform = $form->getSubform('DBForm');
    my $fields = $subform->getField('fields');
    my $row = $ROWS[$ROWNUM];
    my $attrs = $subform->getField('attrs');
    foreach my $f (@$fields) {
	my $w = $subform->getWidget($f);
	my $col = $attrs->{$f}[0][0][1];
	$w->setField('savevalue', $row->{$col});
    }
    # go ahead and switch to form.
    my $to = $subform->getField('update_taborder');
    $subform->setField('TABORDER', $to);
    $subform->setField('FOCUSED', $to->[0]); # first field.
    $subform->setField('editmode', 'update');
    $APP->statusbar("Update the row.  ESC stores; DEL cancels the update.");
}

sub edit_control		# Needs to be generalized to more events.
{
    my $field = shift;
    my $subform = shift;
    my $when = lc(shift);		# before or after

    my $instrs = $APP->getField('instrs');
    my $controls = $instrs->{'CONTROLS'};
    my $attrs = $subform->getField('attrs');
    my ($fldtblcols, $fldattrs) = @{$attrs->{$field}};
    my @cols = map { $_->[1] } @$fldtblcols;
    my $emode = $subform->getField('editmode');
    my $event = "edit$emode";
    my @actions = map {$controls->{$_}{$event}{$when}} @cols;
    @actions = map {$_ ? @$_ : () } @actions; # spread the arrayrefs.
    foreach my $ac (@actions) {
	my ($ac, $field, $opd1, $op, $opd2) = @$ac;
	if ($ac eq 'nextfield'){
	    if (grep { $field eq $_ } @{$subform->getField('TABORDER')}) {
		$subform->setField('FOCUSED', $field);
	    }
	}
	elsif ($ac eq 'let') {
	    ## FIX_ME  *extremely* limited functionality here.
	    my $widget = $subform->getWidget($field);
	    $APP->statusbar("No field '$field' in control block."),
	      return ()
		  unless $widget;
	    $APP->statusbar("Unrecognized operator '$op' in control block."),
	      return()
		  unless $op =~ /^[-+*\/]$/;
	    
	    my $val1 = field_value_or_require_quotes($opd1, $subform);
	    my $val2 = field_value_or_require_quotes($opd2, $subform);
	    my $result = eval "$val1 $op $val2";
	    if ($@) {
		$APP->statusbar("In control block: $@");
		return;
	    }
	    $widget->setField('VALUE', $result);
	    $subform->setField('REDRAW', 1);
	    # $APP->redraw();
	}
    }
}
    
sub field_value_or_require_quotes			# single-quote value.
{
    my $opd = shift;
    my $subform = shift;

    my $w1 = $subform->getWidget($opd);
    if ($w1) {
	my $val = $w1->getField('VALUE');
	$val =~ s/\'/\\\'/;
	return "'$val'";
    }
    unless ($opd =~ /^\"(.*)\"$|^(\d+(\.\d_)?)$/) {
	$APP->statusbar("Neither field, number nor quoted string: '$opd' in control block");
	return "''";
    }
    my $val = defined($1) ? $1 : $2;
    $val =~ s/\'/\\\'/;
    return "'$val'";		# hard-quote it lest any monkey biz happen.
}
    

# called from button_push with the top-level form.
sub do_remove
{
    my $form = shift;

    return if check_rows_and_advise($form);
    my $subform = $form->getSubform('DBForm');
    my $fields = $subform->getField('fields');
    my @wheres = ();
    my @values = ();
    my $tables = $subform->getField('tables');
    my ($table) = @$tables;	# only one table for now.
    my $row = $ROWS[$ROWNUM];
    ## FIX_ME!  Do a two-table remove if necessary.
    {  # this block to be a loop someday
	foreach my $f (@$fields) {
	    my $fieldspec = $subform->getField('attrs')->{$f}[0];
	    my ($tbl, $col) = @$fieldspec[0,1];
	    next if $tbl ne $table;
	    # my $v = $subform->getWidget($f)->getField('VALUE');
	    my $v = $$row{$col}; # get value straight from source.
	    push (@wheres, defined($v) ? "$col = ?" : "$col is null");
	    push (@values, $v) if defined($v);
	}
	my $wheres = join ' and ', @wheres;
	my $cmd = "delete from $table where $wheres";
	my $rc = $DB->do($cmd, {}, @values);
	if (!defined $rc) {
	    $APP->statusbar("Database error: $DBI::errstr");
	}
	else {
	    my $msg = "Row removed.";
	    splice(@ROWS, $ROWNUM, 1);
	    $ROWNUM = $#ROWS if $ROWNUM > $#ROWS;
	    clear_textfields($subform);
	}
    }
    $form->setField('DONTSWITCH', 1); # in all cases.
}

# called from button_push with the top-level form.
sub doquit
{
    my $form = shift;
    #  This assumes the form is the top-level one.
    $form->setField('EXIT', 1);
    $APP->setField('EXIT', 1);
}

# When the user hits ESC from the subform, run one of the following
# based on the value of the button set.
use vars '%MODESUBS';
%MODESUBS =
    ( query => \&do_query,
      add => \&do_add,
      update => \&do_update,
      );

sub OnFieldExit
{
    my ($field, $form, $key) = @_; # leaving @_ for back-patching

    my $widget = $form->getWidget($field);
    edit_control($field, $form, 'after'); # do any AFTER control blocks.
    if ($key eq "\t" || $key eq "\n"
	       || $key eq KEY_DOWN) {	# shift to next field
	$APP->statusbar("")	# erase our comments
	    if ($widget->getField('attrs')->{COMMENTS});
	return;
    }

    my $dontswitch = 1;
    # printf STDERR ("Field Exit: Field = $field; Widget = $widget; Key = %o\n", $key);
    if ($key eq "\c[") {		# Do The Mode
	my $btns = $FORM->getWidget('Buttons');
	my $mode = lc(($btns->getField('LABELS'))->[$btns->getField('VALUE')]);
	my $sub = $MODESUBS{$mode};
	if ($sub && ref($sub) eq 'CODE') {
	    $dontswitch = 0;	# let the sub decide.
	    &$sub($field, $widget, $form);
	}
	else {
	    beep();
	}
    }
    elsif ($key eq "\cw") {
	my $msg = $widget->getField('HELPMSG');
	$APP->statusbar($msg) if ($msg);
    }
    elsif ($key eq "\cp") {
	$APP->statusbar("Current-Value-Of-This-Row not working yet");
    }
    elsif ($key eq "\cc") {
	# FIX_ME not working?!
	clear_textfields($form);
    }
    elsif ($key eq KEY_DC) {	# DEL
	# Bailing out of Query, Update or Modify.
	# Re-display the row as it was, if any.
	if ($#ROWS >= 0) {
	    display_row_fields($form, $ROWS[$ROWNUM], $ROWNUM);
	}
	else {
	    clear_textfields($form);
	}
	# Back to top menu
	$APP->statusbar("")	# erase our comments
	    if ($widget->getField('attrs')->{COMMENTS});
	$form->setField('EXIT', 1);
    }
    elsif ($key eq "\cK" || $key eq KEY_UP || $key eq KEY_STAB) {
	my $taborder = $form->getField('TABORDER');
	my %taborder = map { ($$taborder[$_], $_) } (0..$#$taborder);
	my $i = $taborder{$form->getField('FOCUSED')};
	$i = ($i <= 0) ? $#$taborder : $i - 1;
	$form->setField('FOCUSED', $$taborder[$i]);
	$APP->statusbar("")	# erase our comments
	    if ($widget->getField('attrs')->{COMMENTS});
	$dontswitch = 0;
    }

    if ($dontswitch) {
	$form->setField('DONTSWITCH', 1);
    }
}

# Validates a field value against applicable field attributes.
# If valid, returns true.  If invalid, does statusbar, sets focus  
# to the field and sets DONTSWITCH and then returns false.
sub validate_contents 
{
    my $subform = shift;
    my $f = shift;		# vield name
    my $attrs = shift;		# field's attributes hash
    my $v = shift;		# value from widget.

    my $msg;
    $msg = "This field requires a value"
	if ($$attrs{'REQUIRED'} && !defined($v)) ;
    my $inc = $$attrs{'INCLUDE'};
    my $inchash = $$attrs{'INCLUDEHASH'};	# made in curses_formdef
    $msg ||= "Field permissible values: $inc"
	if ($inchash && !$$inchash{$v});
    return 1 unless $msg;	# Value is OK.
    $APP->statusbar($msg);
    $subform->setField('FOCUSED', $f);
    $subform->setField('DONTSWITCH', 1);
    return undef;
}



sub do_query
{
    my $field = shift;
    my $widget = shift;
    my $subform = shift;

    my $masters = $APP->getField('MASTERS');
    my $attrs = $subform->getField('attrs');
    my @tables = @{$subform->getField('tables')};
    my ($table, $detail);
    if ($masters) {
	my $mdpair = $$masters[0];
	my $indexes = $APP->getField('form_name_indexes');
	my $formindex = $$indexes{$APP->getField('form_name')};
	my $mdmode = $APP->getField('md_mode');
	my $mdindex = $mdmode eq 'm' ? 0 : $mdmode eq 'd' ? 1 : undef;
	die "Masters exist in instructions but md_mode is '$mdmode'"
	    unless defined($mdindex);
	$table = $$mdpair[$mdindex];
	$detail = $mdindex != 0;
    }
    my @wheres = ();
    my @vals = ();
    foreach my $f (@{$subform->getField('fields')}) {
	my ($fldtblcols, $fldattrs) = @{$attrs->{$f}};
	my @fldtblcols = @$fldtblcols;
	next if $masters &&
	    ! grep { $fldtblcols[$_]->[0] eq $table } 0..$#fldtblcols;
	my ($tbl, $col) = @{$fldtblcols[0]};
	if (! $masters  &&  $#fldtblcols > 0) {
	    my ($tbl2, $col2) = @{$fldtblcols[1]}; # FIX_ME two tables only
	    push (@wheres, "$tbl.$col = $tbl2.$col2");
	}
	my $val = $subform->getWidget($f)->getField('VALUE');
	next if ($val eq '');
	# Non-empty field; decide what kind of comparison...
	my $op = '=';
	my $cval = $val;
	if ($val =~ /[*%?]$/) {
	    $cval =~ tr/*?/%_/;	# SQL wildcard characters
	    $op = 'like';
	}
	if ($val eq '=') {
	    $op = 'is null';
	    $cval = undef;
	}
	elsif ($val =~ /^(<<|>>)\s*(.*)$/) {
	    $APP->statusbar("The $1 operator is not supported yet.");
	}
	elsif ($val =~ /^([<>][<=>]?)\s*(.*)$/) {
	    $op = $1;
	    $cval = $2;
	}
	elsif ($val =~ /^(.+?):(.+)$/) {
	    $op = "between ? and ";
	    push (@vals, $1);
	    $cval = $2;
	}
	elsif ($val =~ /^(.+?)\|(.+)$/) {
	    $op = "= ? or $col = "; # might should use in ($1,$2)
	    push (@vals, $1);
	    $cval = $2;
	}
	my $where = "$tbl.$col $op" . (defined($cval) ? ' ?' : '');
	push (@wheres, $where);
	push (@vals, $cval) if defined($cval);
    }
    my $tables = $masters ? $table : join ', ', @tables;
    my $n = do_query_internal($tables, \@wheres, \@vals);
    $subform->setField('EXIT', 1); # Focus back to menu if we got this far.
    unless (defined($n)) {
	$APP->statusbar("DB Error on execute: $DBI::errstr");
	return;
    }
    $n = 0 + $n;		# coerce to number.
    do_next($FORM, 'switch');
    $APP->statusbar("$n row" . ($n == 1 ? '' : 's') . " found;  Row 0")
	if $n > 0;
}

sub do_query_internal
{
    my $tables = shift;
    my $wheres_ref = shift;
    my $vals_ref = shift;
    
    my $wheres = join ' and ', @$wheres_ref;
    my $query = "select * from $tables " . ($wheres ? "where $wheres" : '');
    clear_STH();
    $STH = $DB->prepare_cached($query);
    unless($STH) {
	$APP->statusbar("DB Error on prepare: $DBI::errstr");
	return;
    }
    return $STH->execute(@$vals_ref);
}

sub do_add
{
    my $field = shift;
    my $widget = shift;
    my $subform = shift;

    my $fields = $subform->getField('fields');
    my @cols = ();
    my @values = ();
    my $tables = $subform->getField('tables');
    my ($table) = @$tables;	# only one table for now.
    my $row = {};
    ## FIX_ME!  Do a two-table add if necessary.
    {  # this block to be a loop someday
	foreach my $f (@$fields) {
	    my $fieldattrs = $subform->getField('attrs')->{$f};
	    my ($fieldspecs, $attrs) = @$fieldattrs;
	    next if $$attrs{'NOENTRY'};	# don't include  in cols/vals.
	    my $fieldspec = $$fieldspecs[0];
	    my ($tbl, $col) = @$fieldspec[0,1];
	    next if $tbl ne $table;
	    my $v = $subform->getWidget($f)->getField('VALUE');
	    undef $v if $v eq ''; # give NULL for empty fields.
	    return		# function below has side-effects on form.
		unless validate_contents($subform, $f, $attrs, $v);
	    push (@cols, $col);
	    push (@values, $v);
	    $$row{$col} = $v;
	}
	my $holders = join ', ', map { "?" } @cols;
	my $cols = join ', ', @cols;
	my $cmd = "insert into $table ($cols) values ($holders)";
	my $rc = $DB->do($cmd, {}, @values);
	if (!defined $rc) {
	    $APP->statusbar("Database error: $DBI::errstr");
	    return;
	}
	else {
	    $APP->statusbar("Row Added.");
	}
    }
    $subform->setField('EXIT', 1);	# back to menu
    # Pretend it's a result of one row, so it can be removed / modified.
    clear_STH();
    @ROWS = ( $row );
    $ROWNUM = 0;
    $STH = {};
    $STHDONE = 1;
}

sub do_update
{
    my $field = shift;
    my $widget = shift;
    my $subform = shift;

    my $fields = $subform->getField('fields');
    my %wheres = ();
    my %upds = ();
    my $tables = $subform->getField('tables');
    my ($table) = @$tables;	# only one table for now.
    my $row = {};
    my $attrs = $subform->getField('attrs');
    ## FIX_ME!  Do a two-table add if necessary.
    {  # this block to be a loop someday
	foreach my $f (@$fields) {
	    my ($fieldspec, $attrs) = @{$attrs->{$f}};
	    my ($tbl, $col) = @{$$fieldspec[0]};
	    next if $tbl ne $table;
	    my $w = $subform->getWidget($f);
	    my $v = $w->getField('VALUE');
	    undef $v if $v eq ''; # empty field means NULL.
	    return
		unless validate_contents($subform, $f, $attrs, $v);
	    my $sv = $w->getField('savevalue');
	    $$row{$col} = $v;
	    $upds{$col} = $v
		if ($v ne $sv  && !$$attrs{'NOUPDATE'});
	    $wheres{$col} = $sv;
	}
	my @updcols = keys (%upds);
	my @updvals = map { $upds{$_} } @updcols;
	my $sets = join(', ', map { "$_ = ?" } @updcols);
	my @wherecols = keys (%wheres);
	my @wherevals = map { my $w = $wheres{$_}; defined($w) ?
				  ($w)  :  () } @wherecols;
	# my %whereinds = map { ($wherecols[$_], $_) } 0..$#wherecols;
	my %updinds = map { ($updcols[$_], $_) } 0..$#updcols;
	my $wheres = join(' and ', map { defined($wheres{$_}) ?
					"$_ = ?" :
					    "$_ is null"
					    } @wherecols);
	my $cmd = "update $table set $sets where $wheres";
	my $rc = $DB->do($cmd, {}, @updvals, @wherevals);
	if (!defined $rc) {
	    $APP->statusbar("Database error: $DBI::errstr");
	    return;
	}
	else {
	    $APP->statusbar((0+$rc) . " rows affected");
	    my $query = "select * from $table where $wheres";
	    # Since the new value is now in, change the where value...
	    grep {$ROWS[$ROWNUM]->{$_} = $row->{$_} = $updvals[$updinds{$_}];}
	        @updcols;
	    display_row_fields($subform, $ROWS[$ROWNUM]);
	}
    }
    $subform->setField('EXIT', 1);	# back to menu
}


sub display_row_fields
{
    my $form = shift;
    my $row = shift;
    my $n = shift;

    my $subform =
	$form->getSubform('DBForm')  ||  $form;

    my $fields = $subform->getField('fields');
    my $attrs = $subform->getField('attrs');
    foreach my $f (@$fields) {
	my $attr = $attrs->{$f}[0][0];
	my ($tbl, $col, $stuff) = @$attr;
	$subform->getWidget($f)->setField('VALUE', $row->{$col});
    }
    $APP->statusbar("Row number $n")
	if (defined($n));
    # $subform->draw();  ??
}


# What a kludge...  required by Curses::Application
package main;
__DATA__
%forms = ( DummyDef => {} );


__END__
=head1 NAME

DBIx::Informix::Perform - Informix Perform(tm) emulator

=head1 SYNOPSIS

On the shell command line: 

=over

export DB_CLASS=[Pg|mysql|whatever] DB_USER=usename DB_PASSWORD=pwd

[$install-bin-path/]generate dbname tablename  > per-file-name.per

[$install-bin-path/]perform per-file-name.per  (or pps-file-name.pps)

=back

Or in perl, with the above environment settings:

=over

  DBIx::Informix::Perform::run ($filename_or_description_string);

=back

=head1 ABSTRACT

Emulates the Informix Perform character-terminal-based database query
and update utility.  

=head1 DESCRIPTION

The filename given to the I<perform> command may be a Perform
specification (.per) file.  The call to the I<run> function may be a
filename of a .per file or of a file pre-digested by the
DBIx::Informix::Perform::DigestPer class (extension .pps).  [Using
pre-digested files does not appreciably speed things up, so this
feature is not highly recommended.]

The argument to the I<run> function may also be a string holding the
contents of a .per or .pps file, or a hash ref with the contents of a
.pps file (keys db, screen, tables, attrs).

The database named in the screen spec may be a DBI connect argument, or
just a database name.  In that case, the database type is taken from
environment variable DB_CLASS.  The username and password are taken from
DB_USER and DB_PASSWORD, respectively.

Supports the following features of Informix's Perform:

 Field Attributes: COLOR, NOENTRY, NOUPDATE, DEFAULT, UPSHIFT, DOWNSHIFT,
		   INCLUDE, COMMENTS

 2-table Master/Detail  (though no query in detail mode)

 VERY simple control blocks (nextfield= and let f1 = f2 op f3-or-constant)
 
=head1  COMMANDS

The first letter of each item on the button menu can be pressed.

Q = query.  Enter values to match in fields to match.  Field values
	may start with >, >=, <, <=, contain val1:val2 or val1|val2
	or end with * (for wildcard suffix).  Value of the "=" sign 
	matches a null value.  The ESC key queries; DEL key aborts.

A = add.  Enter values for the row to add.  ESC/DEL when done.

U = update.  Edit row values.  ESC/DEL when done.  

R = remove.  NO CONFIRMATION!  BE CAREFUL USING THIS!

E = exit.

M / D = Master / Detail screen when a MASTER OF relationship exists between
	two tables.


=head1  REQUIREMENTS

Curses Curses::Application Curses::Forms Curses::Widgets

DBI  and DBD::whatever

Note: For the B<generate> function / script to work, the DBD driver
must implement the I<column_info> method.

=head1   ENVIRONMENT VARIABLES

DB_CLASS	this goes into the DBI connect string.  NOTE: knows how
		to prefix database names for Pg and mysql but not much else.

DB_USER		User name for DBI->connect.

DB_PASSWORD	Corresponding.

BGCOLOR		One of eight Curses-known colors for form background
    		(default value is 'black').

FIELDBGCOLOR	Default field background color (default is 'blue').
    		Fields' background colors may be individually overridden
		by the "color" attribute of the field.

Note, any field whose background matches the form background gets
displayed with brackets around it:   [field_here] .

=head1	FUNDING CREDIT

Development of DBIx::Informix::Perform was generously funded by Telecom
Engineering Associates of San Carlos, CA, a full-service 2-way radio
and telephony services company primarily serving public-sector
organizations in the SF Bay Area.  On the web at
http://www.tcomeng.com/ .  (do I sound like Frank Tavares yet?)

=head1 AUTHOR

Eric C. Weaver  E<lt>weav@sigma.netE<gt> 

=head1 COPYRIGHT AND LICENSE and other legal stuff

Copyright 2003 by Eric C. Weaver and 
Telecom Engineering Associates (a California corporation).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

INFORMIX and probably PERFORM is/are trademark(s) of
Informix Software Inc.

=cut
