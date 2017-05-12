package ClearCase::ClearPrompt;

require 5.001;

$VERSION = $VERSION = '1.31';
@EXPORT_OK = qw(clearprompt clearprompt_dir redirect tempname die
		$CT $TriggerSeries
);

%EXPORT_TAGS = ( 'all' => [ qw(
	clearprompt
	clearprompt_dir
	redirect
	tempname
) ] );

require Exporter;
@ISA = qw(Exporter);

# Conceptually this is "use constant MSWIN ..." but ccperl can't do that.
sub MSWIN { ($^O || $ENV{OS}) =~ /MSWin32|Windows_NT/i ? 1 : 0 }

use vars qw($TriggerSeries $StashFile);
$TriggerSeries = $ENV{CLEARCASE_CLEARPROMPT_TRIGGERSERIES};

# Make $CT read-only but not a constant so it can be interpolated.
*CT = *CT = \ccpath('cleartool');	# double assignment suppresses warning

if ($] > 5.004) {
    use strict;
    eval "use subs 'die'";  # We override this and may also export it to caller
}

my %Dialogs = ();
my %Mailings = ();
my %MailTo = (); # accumulates lists of users to mail various msgs to.

(my $prog = $0) =~ s%.*[/\\]%%;

sub rerun_in_debug_mode {
    # Re-exec ourself with debugging turned on. If in GUI mode,
    # rerun in a new window. This allows "perl -d" debugging of
    # triggers in a GUI env.
    delete $ENV{CLEARCASE_CLEARPROMPT_DEBUG};	# suppress recursion
    return if $ENV{PERL_DL_NONLAZY};		# marker for 'make test'
    my @cmd = ($^X, '-d', $0, @ARGV);
    if (MSWIN()) {
	for (@cmd) {
	    $_ = qq("$_") if m%\s%;
	}
	unshift(@cmd, qw(start /wait)) if $ENV{ATRIA_FORCE_GUI};
    } else {
	unshift(@cmd, qw(xterm -e)) if $ENV{ATRIA_FORCE_GUI};
    }
    if (MSWIN()) {
	# This does not work with ccperl (5.001) if CC is installed to
	# "C:\Program Files\...".
	my $rc = system(@cmd);
	exit($rc != 0);
    } else {
	exec(@cmd);
    }
}

sub dbg_shell {
    # Fork an interactive shell and wait for it. Useful in triggers because
    # it lets you explore the runtime environment of the trigger script.
    return if $ENV{PERL_DL_NONLAZY};		# marker for 'make test'
    my $cmd = $ENV{CLEARCASE_CLEARPROMPT_DEBUG_SHELL};
    $cmd = MSWIN() ? $ENV{COMSPEC} : '/bin/sh' unless $cmd && -x $cmd;
    if ($ENV{ATRIA_FORCE_GUI}) {
	if (MSWIN()) {
	    $cmd = "start /wait $cmd";
	} else {
	    $cmd = "xterm -e $cmd";
	}
    }
    exit 1 if system $cmd;
}

# Debugging aids. Documented in POD section. These can also be
# controlled via cmds at import time.
if ($ENV{CLEARCASE_CLEARPROMPT_DEBUG} ||
	($ENV{ATRIA_FORCE_GUI} && $ENV{PERL5OPT} && $ENV{PERL5OPT} =~ /-d/)) {
    rerun_in_debug_mode();
} elsif ($ENV{CLEARCASE_CLEARPROMPT_DEBUG_SHELL}) {
    dbg_shell();
}

# Make an attempt to supply a full path to the specified program.
# Else fall back to relying on PATH.
sub ccpath {
    my $name = shift;
    if (MSWIN()) {
	return $name;	# no way to avoid relying on PATH in &^&@$! Windows
    } else {
	return join('/', $ENV{ATRIAHOME} || q(/usr/atria), 'bin', $name);
    }
}

# Generates a random-ish name for a temp file that doesn't yet exist.
# This function makes no pretense of being atomic; it's conceivable,
# though highly unlikely, that the generated filename could be
# taken between the time it's generated and the time it's used.
# The optional parameter becomes a filename extension. The optional
# 2nd parameter overrides the basename part of the generated path.
sub tempname {
    my($custom, $tmpf) = @_;
    # The preferred directory for temp files.
    my $tmpd = MSWIN() ?
	    ($ENV{TEMP} || $ENV{TMP} || ( -d "$ENV{SYSTEMDRIVE}/temp" ?
			      "$ENV{SYSTEMDRIVE}/temp" : $ENV{SYSTEMDRIVE})) :
	    ($ENV{TMPDIR} || '/tmp');
    $tmpd =~ s%\\%/%g;
    my $ext = 'tmp';
    return "$tmpd/$tmpf.$custom.$ext" if $tmpf;
    (my $pkg = lc __PACKAGE__) =~ s/:+/-/g;
    while (1) {
	$tmpf = join('.', "$tmpd/$pkg", $$, int(rand 10000));
	$tmpf .= $custom ? ".$custom.$ext" : ".$ext";
	return $tmpf if ! -f $tmpf;
    }
}

# Run clearprompt with specified args and return what it returned. Uses the
# exact same syntax as the clearprompt executable ('ct man clearprompt')
# except for -outfile <file> which is handled internally here.
sub clearprompt {
    my $mode = shift;
    my @args = @_;
    my $data;

    return 0 if $ENV{ATRIA_WEB_GUI};	# must assume "" or 0 if ccweb interface

    local $!;	# don't mess up errno in the caller's world.

    # Play back responses from the StashFile if it exists and other conditions
    # are satisfied. It seems that CC sets the series id to all zeroes
    # after an error condition (??) so we avoid that case explicitly.
    my $lineno = (caller)[2];
    my $subtext = "from $prog:$lineno";
    if ($TriggerSeries && $ENV{CLEARCASE_SERIES_ID} &&
				    $ENV{CLEARCASE_SERIES_ID} !~ /^[0:.]+$/) {
	(my $sid = $ENV{CLEARCASE_SERIES_ID}) =~ s%:+%-%g;
	$StashFile = tempname($prog, "CLEARCASE_SERIES_ID=$sid");
	if (!$ENV{CLEARCASE_BEGIN_SERIES} && -f $StashFile) {
	    do $StashFile;
	    if ($ENV{CLEARCASE_END_SERIES} &&
				    !$ENV{CLEARCASE_CLEARPROMPT_KEEP_CAPTURE}) {
		# We delay the unlink due to weird  Windows locking behavior
		eval "END { unlink '$StashFile' }";
	    }
	    no strict 'vars';
	    my $data = eval "\$stash$lineno";
	    _automail('PROMPT', "Replay $subtext", "REPLAY:\n",
			    defined($data) ? $data : 'undef');
	    return $data;
	}
    }

    # On Windows we must add an extra level of escaping to any args
    # which might have special chars since all forms of system()
    # appear to go through the %^%@# cmd shell (boo!). This is
    # also handled by Perl 5.6.1, ActiveState build 630 but it will
    # be a long time till we can count on that fix being present.
    if (MSWIN()) {
	for (0..$#args) {
	    my $i = $_;
	    if ($args[$i] =~ /^-(?:pro|ite|def|dfi|dir)/) {
		$args[$i+1] =~ s/"/'/gs;
		$args[$i+1] = qq("$args[$i+1]");
	    }
	}
    }

    # For clearprompt modes in which we get textual data back via a file,
    # derive here a reasonable temp-file name and handle the details
    # of reading the data out of it and unlinking it when done.
    # For other modes, just fire off the cmd and return the status.
    # In a void context, don't wait for the button to be pushed; just
    # "fork" and proceed asynchonously since this is presumably just an
    # informational message.
    # If the cmd took a signal, return undef and leave the signal # in $?.
    if ($mode =~ /text|file|list/) {
	my $outf = tempname($mode);
	my @cmd = (ccpath('clearprompt'), $mode, '-out', $outf, @args);
	print STDERR "+ @cmd\n" if $ClearCase::ClearPrompt::Verbose;
	if (!system(@cmd)) {
	    if (open(OUTFILE, $outf)) {
		local $/ = undef;
		$data = <OUTFILE>;
		$data = '' if !defined $data;
		close(OUTFILE);
	    }
	} else {
	    # If we took a signal, return undef with the signal # in $?. The
	    # clearprompt cmd apparently catches SIGINT and returns 0x400 for
	    # some reason; we fix it here so $? looks like a normal sig2.
	    $? = 2 if $? == 0x400;
	    $data = undef if $? && $? <= 0x80;
	}
	unlink $outf if -f $outf;
	_automail('PROMPT', "Prompt $subtext", "PROMPT:\n", "@cmd\n",
			    "\nRESPONSE:\n", defined($data) ? $data : 'undef');
    } else {
	my @cmd = (ccpath('clearprompt'), $mode, @args);
	print STDERR "+ @cmd\n" if $ClearCase::ClearPrompt::Verbose;
	if (defined wantarray) {
	    system(@cmd);
	    $? = 2 if $? == 0x400;  # see above
	    $data = ($? && $? <= 0x80) ? undef : $?>>8;
	    _automail('PROMPT', "Prompt $subtext", "PROMPT:\n",
		"@cmd\n", "\nRESPONSE:\n", defined($data) ? $data : 'undef');
	} else {
	    _automail('PROMPT', "Prompt $subtext", "PROMPT:\n", "@cmd\n");
	    if (MSWIN()) {
		# Windows (always) GUI - fork new thread to run async
		system(1, @cmd);
		return;
	    } elsif (exists $ENV{DISPLAY}) {
		# Unix GUI - must fork to run async
		return if fork;
		exec(@cmd);
	    } else {
		# Unix cmd line - must close stdin to run async
		open(SAVE_STDIN, ">&STDIN");
		close(STDIN);
		system(@cmd);
		open(STDIN, ">&SAVE_STDIN");
		close(SAVE_STDIN);
	    }
	}
    }

    # Record responses if $TriggerSeries is turned on.
    if ($StashFile) {
	if ($ENV{CLEARCASE_BEGIN_SERIES} && !$ENV{CLEARCASE_END_SERIES}) {
	    my $top = ! -f $StashFile;
	    eval { require Data::Dumper };
	    if ($@ || $] < 5.004) {
		warn "$prog: Warning: TriggerSeries requires Data::Dumper\n";
	    } else {
		open(STASH, ">>$StashFile") || die "$prog: $StashFile: $!";
		print STASH "# This file contains data stashed for $prog\n"
									if $top;
		print STASH Data::Dumper->new([$data], ["stash$lineno"])->Dump;
		close(STASH);
		if (! $ENV{CLEARCASE_CLEARPROMPT_KEEP_CAPTURE}) {
		    $SIG{INT} = sub { unlink $StashFile };
		}
	    }
	}
    }

    return $data;
}

# Fake up a directory chooser using opendir/readdir/closedir and
# 'clearprompt list'.
sub clearprompt_dir {
    require Cwd;
    require File::Spec;
    my($dir, $msg) = @_;
    my(%subdirs, $items, @drives);
    my $iwd = Cwd::abs_path('.');
    $dir = $iwd if $dir eq '.';

    return 0 if $ENV{ATRIA_WEB_GUI};	# must assume "" or 0 if ccweb interface

    while (1) {
	if (opendir(DIR, $dir)) {
	    %subdirs = map {$_ => 1} grep {-d "$dir/$_" || ! -e "$dir/$_"}
								readdir(DIR);
	    chomp %subdirs;
	    closedir(DIR);
	} else {
	    warn "$dir: $!\n";
	    $dir = File::Spec->rootdir;
	    next;
	}
	if (MSWIN() && $dir =~ m%^[A-Z]:[\\/]?$%i) {
	    delete $subdirs{'.'};
	    delete $subdirs{'..'};
	    @drives = grep {-e} map {"$_:"} 'C'..'Z' if !@drives;
	    $items = join(',', @drives, sort keys %subdirs);
	} else {
	    $items = join(',', sort keys %subdirs);
	}
	my $resp = clearprompt(qw(list -items), $items,
						    '-pro', "$msg  [ $dir ]");
	if (!defined $resp) {
	    undef $dir;
	    last;
	}
	chomp $resp;
	last if ! $resp || $resp eq '.';
	if (MSWIN() && $resp =~ m%^[A-Z]:[\\/]?$%i) {
	    $dir = $resp;
	    chdir $dir || warn "$dir: $!\n";
	} else {
	    $dir = Cwd::abs_path(File::Spec->catdir($dir, $resp));
	}
    }
    chdir $iwd || warn "$iwd: $!\n";
    return $dir;
}

# Takes args in the form "redirect(STDERR => 'OFF', STDOUT => 'ON')" and
# enables or disables stdout/stderr as specified.
sub redirect {
    # Stash these away at first use for potential future use, e.g. debugging.
    open(SAVE_STDOUT, '>&STDOUT') if !defined fileno(SAVE_STDOUT);
    open(SAVE_STDERR, '>&STDERR') if !defined fileno(SAVE_STDERR);

    while(@_) {
	my $stream = uc shift;
	my $state  = shift;

	if ($stream ne 'STDOUT' && $stream ne 'STDERR') {
	    print SAVE_STDERR "unrecognized stream $stream\n";
	    next;
	}

	if ($stream eq 'STDOUT') {
	    if ($state =~ /^OFF$/i) {
		if (defined fileno(STDOUT)) {
		    open(HIDE_STDOUT, '>&STDOUT')
					    if !defined fileno(HIDE_STDOUT);
		    close(STDOUT);
		}
	    } elsif ($state =~ /^ON$/i) {
		open(STDOUT, '>&HIDE_STDOUT');
	    } else {
		if (defined fileno(STDOUT)) {
		    open(HIDE_STDOUT, '>&STDOUT')
					    if !defined fileno(HIDE_STDOUT);
		    open(STDOUT, $state) || warn "$state: $!\n";
		}
	    }
	} elsif ($stream eq 'STDERR') {
	    if ($state =~ /^OFF$/i) {
		if (defined fileno(STDERR)) {
		    open(HIDE_STDERR, '>&STDERR')
					    if !defined fileno(HIDE_STDERR);
		    close(STDERR);
		}
	    } elsif ($state =~ /^ON$/i) {
		open(STDERR, '>&HIDE_STDERR');
	    } else {
		if (defined fileno(STDERR)) {
		    open(HIDE_STDERR, '>&STDERR')
					    if !defined fileno(HIDE_STDERR);
		    open(STDERR, $state) || warn "$state: $!\n";
		}
	    }
	}
    }
}

# Called like this "sendmsg([<to-list>], $subject, @body_of_message)".
# I.e. a ref to a list of email addresses followed by a string
# scalar containing the subject. Remaining parameters are used
# as the body of the message. Returns true on successful delivery
# of msg to the MTA.
sub sendmsg {
    my($r_to, $subj, @body) = @_;
    # If no mailto list, no mail.
    return 1 unless @$r_to;

    # Only drag Net::SMTP in at runtime since it's not core perl.
    eval { require Net::SMTP };
    if (! $@) {
	my $name = $ENV{CLEARCASE_USER} || $ENV{USERNAME} || $ENV{LOGNAME};
	my $smtp;
	eval { $smtp = Net::SMTP->new };
	if ($smtp) {
	    local $^W = 0; # hide a spurious warning from deep in Net::SMTP
	    $smtp->mail($name) &&
		$smtp->to(@$r_to, {SkipBad => 1}) &&
		$smtp->data() &&
		$smtp->datasend("To: @$r_to\n") &&
		$smtp->datasend("Subject: $subj\n") &&
		$smtp->datasend(join(' ', 'X-Mailer:',__PACKAGE__,$VERSION)) &&
		$smtp->datasend("\n") &&
		$smtp->datasend(@body) &&
		$smtp->dataend() &&
		$smtp->quit &&
		return 1;	# succeeded, so return
	}
    }

    # If Net::SMTP isn't installed or didn't work, try notify.exe
    my $nexe = MSWIN() ? 'notify' : '/usr/atria/bin/notify';
    my $notify = qq($nexe -l triggers -s "$subj" ) .
					    join(' ', map {qq("$_")} @$r_to);
    if (open(NOTIFY, "| $notify")) {
	print NOTIFY @body;
	return close(NOTIFY);
    }
    return 0;	# failure
}

# A private wrapper over sendmsg() to reformat the subj/msg
# appropriately for error message captures.
sub _automail {
    return 0 if defined $ENV{CLEARCASE_CLEARPROMPT_NO_SENDMSG};
    my $type = shift;
    return unless exists $MailTo{$type} && $MailTo{$type};
    my $addrs = $MailTo{$type};
    my $subj = shift;
    # We don't need Sys::Hostname except in this situation, so ...
    eval { require Sys::Hostname; };
    $subj .= ' on ' . Sys::Hostname::hostname() unless $@;
    $subj .= ' via ClearCase::ClearPrompt';
    sendmsg($addrs, $subj, @_);
}

# Warning: significant hackery here. Basically, normal-looking symbol
# names are passed on to the Exporter import method as usual, whereas
# names of the form /WORD or +WORD or +WORD=<list> are commands which
# cause special behavior within this routine. All commands start with
# '/', such as /TRIGGERSERIES and /ENV. Captures start with '+' and
# include +{CAPTURE,ERRORS,WARN,DIE,STDOUT,STDERR}. If the capture
# name has a list of users attached, eg "+STDERR=user1,user2,..",
# the captured messages are sent via email to the specified users.
# Use +CAPTURE=<list> to email messages from all channels to <list>.
## Apologies to anyone trying to read this ... it's a real mess, due
## mostly to my attempts to stay compatible with earler versions which
## may not have involved the best design decisions.
my($tmpout, $tmperr);	# these must be here for scoping reasons
sub import {
    # First remember the entire parameter list.
    my @p = @_;

    # Then separate it into "normal-looking" symbols to export into
    # caller's namespace, "captures" which describe channels we need
    # to arrange to capture here, and "commands" to deal with otherwise.
    # Also, provide our own implementation of export tags for qw(:all).
    # I'd prefer not to support that any more but do for back compat.
    my %exports = map { $_ => 1 } grep !m%^[+/:]%, @p;
    my %tags = map {substr($_, 1) => 1} grep m%^:%, @p;
    my %caps = map {m%^.(\w+)=?(.*)%; $1 => $2} grep m%^\+%, @p;
    my %cmds = map {m%^.(\w+)%; $1 => 1} grep m%^/%, @p;

    # Allow trigger series stashing to be turned on at import time,
    # but let the EV override. We allow '+TRIGGERSERIES' for
    # compatibility but '/TRIGGERSERIES' is preferred.
    if (exists($cmds{TRIGGERSERIES}) || exists($caps{TRIGGERSERIES})) {
	$cmds{TRIGGERSERIES} ||= $caps{TRIGGERSERIES};
	delete $caps{TRIGGERSERIES};
	$ClearCase::ClearPrompt::TriggerSeries = 1
			if !exists($ENV{CLEARCASE_CLEARPROMPT_TRIGGERSERIES});
    }

    # If requested to via '/ENV', modify all CLEARCASE_* EV's which
    # use back (\) slashes such that they use forward (/) slashes
    # instead, assuming that these will refer to pathnames or parts
    # of pathnames, perhaps in MVFS space (e.g. CLEARCASE_VERSION_ID).
    if (MSWIN() && exists($cmds{ENV})) {
	for (keys %ENV) {
	    $ENV{$_} =~ s%\\%/%g if m%^CLEARCASE_%;
	}
    }

    # The user may request via /DEBUG that the script (typically a trigger)
    # be rerun in debug mode. See POD.
    rerun_in_debug_mode() if exists($cmds{DEBUG});

    # The user may request via /SHELL that the script (typically a trigger)
    # fork an interactive shell so its runtime env can be explored.
    dbg_shell() if exists($cmds{SHELL});

    # Allow this EV to override the capture list.
    if ($ENV{CLEARCASE_CLEARPROMPT_CAPTURE_LIST}) {
	@p = split /\s+/, $ENV{CLEARCASE_CLEARPROMPT_CAPTURE_LIST};
	%caps = map {m%^.(\w+)=?(.*)%; $1 => $2} grep /^\+/, @p;
	for (split /\s+/, @p) {
	    m%^.(\w+)=?(.*)%;
	    $caps{$1} = $2;
	}
    }

    # Now divide capture requests into those for dialog boxes and
    # those for mailings.
    %Dialogs  = map {substr($_, 1) => 1} grep /^\+\w+$/, @p;
    %Mailings = map {m%^.(\w+)=(.*)%; $1 => $2 } grep /^\+\w+=/, @p;

    # If :tags were requested, map them to their predefined export lists.
    for (keys %tags) {
	my $tag = $_;
	next unless $EXPORT_TAGS{$tag};
	for (@{$EXPORT_TAGS{$tag}}) {
	    $exports{$_} = 1;
	}
    }

    # Export the die func if its corresponding channel was requested.
    $exports{'die'} = 1 if exists($caps{DIE}) ||
				exists($caps{CAPTURE}) || exists($caps{ERRORS});

    # Set up the override hook for warn() if requested.
    $SIG{__WARN__} = \&cpwarn if exists($caps{WARN}) ||
				exists($caps{CAPTURE}) || exists($caps{ERRORS});

    # Export the non-cmd symbols, which may include die().
    my @shares = grep {!/:/} keys %exports;
    if ($] <= 5.001) {
	# This weird hackery needed for ccperl (5.001) ...
	my $caller = caller;
	$caller = 'main' if $caller eq 'DB';	# hack for ccperl -d bug
	for (@shares) {
	    if (s/^(\W)//) {
		eval "*{$caller\::$_} = \\$1$_";
	    } else {
		*{"$caller\::$_"} = \&$_;
	    }
	}
    } else {
	# ... and this "normal" hackery is for modern perls.
	__PACKAGE__->export_to_level(1, $p[0], @shares);
    }

    # +CAPTURE grabs all forms of output while +ERRORS grabs only error
    # forms (meaning everything but stdout). NOTE: we must be very careful
    # about the fact that there may be keys which EXIST but whose
    # values are UNDEFINED.
    if (exists($Dialogs{CAPTURE})) {
	$Dialogs{WARN}		||= $Dialogs{CAPTURE};
	$Dialogs{DIE}		||= $Dialogs{CAPTURE};
	$Dialogs{STDERR}	||= $Dialogs{CAPTURE};
	$Dialogs{STDOUT}	||= $Dialogs{CAPTURE};
	delete $Dialogs{CAPTURE};
    } elsif (exists($Dialogs{ERRORS})) {
	$Dialogs{WARN}		||= $Dialogs{ERRORS};
	$Dialogs{DIE}		||= $Dialogs{ERRORS};
	$Dialogs{STDERR}	||= $Dialogs{ERRORS};
	delete $Dialogs{ERRORS};
    }
    if (exists($Mailings{CAPTURE})) {
	$Mailings{WARN}		||= $Mailings{CAPTURE};
	$Mailings{DIE}		||= $Mailings{CAPTURE};
	$Mailings{STDERR}	||= $Mailings{CAPTURE};
	$Mailings{STDOUT}	||= $Mailings{CAPTURE};
	delete $Mailings{CAPTURE};
    } elsif (exists($Mailings{ERRORS})) {
	$Mailings{WARN}		||= $Mailings{ERRORS};
	$Mailings{DIE}		||= $Mailings{ERRORS};
	$Mailings{STDERR}	||= $Mailings{ERRORS};
	delete $Mailings{ERRORS};
    }

    # Set up the mailing lists for each channel as requested.
    $MailTo{WARN}	= [split /,/, $Mailings{WARN}]   if $Mailings{WARN};
    $MailTo{DIE}	= [split /,/, $Mailings{DIE}]    if $Mailings{DIE};
    $MailTo{STDOUT}	= [split /,/, $Mailings{STDOUT}] if $Mailings{STDOUT};
    $MailTo{STDERR}	= [split /,/, $Mailings{STDERR}] if $Mailings{STDERR};
    $MailTo{PROMPT}	= [split /,/, $Mailings{PROMPT}] if $Mailings{PROMPT};

    # Last, handle generic stdout and stderr unless the caller asks us not to.
    if (exists($caps{STDOUT}) || exists($caps{STDERR})) {
	$tmpout = tempname('stdout');
	$tmperr = tempname('stderr');

	# Connect stdout and stderr to temp files for later use in END {}.
	if (exists($caps{STDOUT}) && ($ENV{ATRIA_FORCE_GUI} || $caps{STDOUT})) {
	    open(HOLDOUT, '>&STDOUT');
	    open(STDOUT, ">$tmpout") || warn "$tmpout: $!";
	}
	if (exists($caps{STDERR}) && ($ENV{ATRIA_FORCE_GUI} || $caps{STDERR})) {
	    open(HOLDERR, '>&STDERR');
	    open(STDERR, ">$tmperr") || warn "$tmperr: $!";
	}

	# After program finishes, collect any stdout/stderr and display
	# with clearprompt and/or mail it out.
	sub endfunc {
	    # retain original exit code on stack
	    my $rc = $?;
	    local $?;

	    # Restore stdout and stderr to their original fd's.
	    if (defined fileno HOLDOUT) {
		open(STDOUT, '>&HOLDOUT');
		close(HOLDOUT);
	    }
	    if (defined fileno HOLDERR) {
		open(STDERR, '>&HOLDERR');
		close(HOLDERR);
	    }

	    # Then display any stdout we captured in a dialog box.
	    if (defined($tmpout) && -e $tmpout) {
		open(OUT, $tmpout) || warn "$prog: $tmpout: $!";
		my @msg = <OUT>;
		close(OUT);
		if (@msg) {
		    _automail('STDOUT', "Stdout from $prog", @msg);
		    if ($Dialogs{STDOUT}) {
			my $t = "STDOUT\n\n @msg";
			clearprompt(qw(proceed -type o -mask p -pref -pro), $t);
		    }
		}
		if (!$ENV{CLEARCASE_CLEARPROMPT_KEEP_CAPTURE}) {
		    # On Windows, we can't unlink this tempfile while
		    # any asynchronous dialog boxes are still on the
		    # screen due to threading/locking design, so we
		    # give the user some time to read & close them.
		    if (MSWIN()) {
			system(1, qq($^X -e "sleep 30; unlink '$tmpout'"));
		    } else {
			unlink($tmpout) || print "$prog: $tmpout: $!\n";
		    }
		}
	    }
	    # Same as above but for stderr.
	    if (defined($tmperr) && -e $tmperr) {
		my @msg;
		{
		    open(ERR, $tmperr) || warn "$prog: $tmperr: $!";
		    local $^W = 0; # <ERR> gives bogus error with AS build 623
		    @msg = <ERR>;
		    close(ERR);
		}
		if (@msg) {
		    _automail('STDERR', "Stderr from $prog", @msg);
		    if ($Dialogs{STDERR}) {
			my $t = "STDERR\n\n @msg";
			clearprompt(qw(proceed -type o -mask p -pref -pro), $t);
		    }
		}
		if (!$ENV{CLEARCASE_CLEARPROMPT_KEEP_CAPTURE}) {
		    if (MSWIN()) {
			system(1, qq($^X -e "sleep 30; unlink '$tmperr'"));
		    } else {
			unlink($tmperr) || print "$prog: $tmperr: $!\n";
		    }
		}
	    }
	};
	eval "END { endfunc(); }";
    }
}

# This is a pseudo warn() func which is called via the $SIG{__WARN__} hook.
sub cpwarn {
    my @msg = @_;
    # always show line numbers if this dbg flag set
    if ($ENV{CLEARCASE_CLEARPROMPT_SHOW_LINENO}) {
	my($file, $line) = (caller)[1,2];
	chomp $msg[-1];
	push(@msg, " at $file line $line.\n");
    }
    _automail('WARN', "Warning from $prog", @msg);
    if ($ENV{ATRIA_FORCE_GUI} && $Dialogs{WARN}) {
	clearprompt(qw(proceed -type w -mask p -pref -pro), "WARNING\n\n@msg");
	return undef; 	# to keep clearprompt() in void context
    } else {
	warn @msg;
    }
}

# A pseudo die() which can be made to override the caller's builtin.
sub die {
    my @msg = @_;
    # always show line numbers if this dbg flag set
    if ($ENV{CLEARCASE_CLEARPROMPT_SHOW_LINENO}) {
	my($file, $line) = (caller)[1,2];
	chomp $msg[-1];
	push(@msg, " at $file line $line.\n");
    }
    _automail('DIE', "Error from $prog", @msg);
    if ($ENV{ATRIA_FORCE_GUI} && $Dialogs{DIE}) {
	clearprompt(qw(proceed -type e -mask p -pref -pro), "ERROR\n\n@msg");
	exit $! || $?>>8 || 255;	# suppress the msg to stderr
    } else {
	require Carp;
	CORE::die Carp::shortmess(@_);

    }
}

1;

__END__

=head1 NAME

ClearCase::ClearPrompt - Handle clearprompt in a portable, convenient way

=head1 SYNOPSIS

 use ClearCase::ClearPrompt qw(clearprompt);

 # Boolean usage
 my $rc = clearprompt(qw(yes_no -mask y,n -type ok -prompt), 'Well?');

 # Returns text into specified variable (context sensitive).
 my $txt = clearprompt(qw(text -pref -pro), 'Enter text data here: ');

 # Asynchronous usage - show dialog box and continue
 clearprompt(qw(proceed -mask p -type ok -prompt), "You said: $txt");

 # Trigger series (record/replay responses for multiple elements)
 use ClearCase::ClearPrompt qw(clearprompt /TRIGGERSERIES);
 my $txt = clearprompt(qw(text -pref -pro), 'Response for all elems: ');

 # Clean up environment on Windows to use /-style paths:
 use ClearCase::ClearPrompt qw(/ENV);

 # Cause the program to run in the debugger, even in a GUI environment:
 use ClearCase::ClearPrompt qw(/DEBUG);

 # Automatically divert trigger error msgs to clearprompt dialogs
 use ClearCase::ClearPrompt qw(+ERRORS);

 # As above but send error msgs via email instead to user1 and user2
 use ClearCase::ClearPrompt qw(+ERRORS=user1,user2);

 # As above but send msgs to the current user
 use ClearCase::ClearPrompt '+ERRORS=' . ($ENV{LOGNAME} || $ENV{USERNAME});

 # Prompt for a directory (not supported natively by clearprompt cmd)
 use ClearCase::ClearPrompt qw(clearprompt_dir);
 my $dir = clearprompt_dir('/tmp', "Please choose a directory");

=head1 DESCRIPTION

This module provides various areas of functionality, each based on
clearprompt in some way but otherwise orthogonal. These are:

=over 4

=item * Clearprompt Abstraction

Provides a simplified interface to the B<clearprompt> program, taking
care of creating and removing temp files as required.

=item * Trigger Series Support

Records and replays responses across multiple trigger firings.

=item * Message Capture

Catches output to stdout or stderr which would otherwise be lost in a
GUI environment and pops them up as dialog boxes using clearprompt.

=item * GUI trigger debugging support

Can be told to run the trigger in a perl debugger session in a
separate window. Useful for debugging trigger problems that come up
only in the GUI.

=item * InterOp Environment Normalization

Modifies %ENV on Windows such that all C<CLEARCASE_*> values use
forward (/) slashes instead of backslashes. Generally useful in
triggers where many path values such as $ENV{CLEARCASE_PN} are provided
in the environment.

=item * Directory Chooser

Allows clearprompt to be used for selecting directories (aka folders).

=back

Many of these are of particular value within trigger scripts. All are
discussed in more detail below, but first the import/export scenario
needs some detail. Most modules are intended to be used like this

	use Some::Module qw(X Y Z);

where X, Y, and Z are symbols (variables, functions, etc) you want
exported (or imported, depending where you stand) from the module into
the current namespace. ClearPrompt extends this: X, Y, and Z may be
imports as above, or they may be I<commands>, or they may represent
I<captures>.  Command names start with C</>, capture names start with
C<+>, and all others are assumed to be traditional symbols for
import/export. All may be intermingled. Thus,

	# These are all the currently-recognized commands
	use ClearCase::ClearPrompt qw(/ENV /TRIGGERSERIES);

	# This shows a sample of the captures available.
	use ClearCase::ClearPrompt qw(+DIE +ERRORS=vobadm);

	# This shows how to import a couple of useful symbols
	use ClearCase::ClearPrompt qw($CT clearprompt);

	# And this specifies some of each
	use ClearCase::ClearPrompt qw($CT /ENV +ERRORS=vobadm);

=head2 CLEARPROMPT ABSTRACTION

Native ClearCase provides a utility (B<clearprompt>) for collecting
user input or displaying messages within triggers. However, use of this
tool is awkward and error prone, especially in multi-platform
environments.  Often you must create temp files, invoke clearprompt to
write into them, open them and read the data, then unlink them. In many
cases this code must run seamlessly on both Unix and Windows systems
and is replicated throughout many scripts. ClearCase::ClearPrompt
abstracts this dirty work without changing the interface to
B<clearprompt>.

The C<clearprompt()> function takes the exact same set of flags as the
eponymous ClearCase command except that the C<-outfile> flag is
unnecessary since creation, reading, and removal of this temp file is
managed internally. Thus the single function call:

    my $response = clearprompt('text', '-def', '0', '-pro', 'So nu? ');

can replace the entire code sequence:

    my $outfile = "/tmp/clearprompt.$$";
    system('clearprompt', '-outfile', $outfile, 'text', '-def', '0', '-pro', 'So nu? ');
    open(OF, $outfile);
    my $response = <OF>;
    close(OF);
    unlink $outfile;

With the further caveat that the code sequence would need a few more
lines to be portable to Windows and to check for error conditions.

In a void context, clearprompt() behaves asynchronously; i.e. it
displays the dialog box and returns so that execution can continue.
This allows it to be used for informational displays. In any other
context it waits for the dialog's button to be pushed and returns the
appropriate data type.

The clearprompt() I<function> always leaves the return code of the
clearprompt I<command> in C<$?> just as C<system('clearprompt ...')>
would.  If the prompt was interrupted via a signal, the function
returns the undefined value.

=head2 TRIGGER SERIES

Since clearprompt is often used in triggers, special support is
provided in ClearCase::ClearPrompt for multiple trigger firings
deriving from a single CC operation upon multiple objects.

If the boolean $ClearCase::ClearPrompt::TriggerSeries has a true value,
clearprompt will 'stash' its responses through multiple trigger
firings. For instance, assuming a checkin trigger which prompts the
user for a bugfix number and a command "cleartool ci *.c", the
TriggerSeries flag would cause all response(s) to clearprompts for the
first file to be recorded and replayed for the 2nd through nth trigger
firings. The user gets prompted only once.

Trigger series behavior can be requested at import time via:

    use ClearCase::ClearPrompt qw(/TRIGGERSERIES);

This feature is only available on CC versions which support the
CLEARCASE_SERIES_ID environment variable (3.2.1 and up) but attempts to
use it are harmless in older versions. The module will just drop back
to prompting per-file in that case.

=head2 MESSAGE CAPTURE

In a ClearCase GUI environment, output to stdout or stderr (typically
from a trigger) has no console to go to and thus disappears without a
trace. This applies to both Unix and Windows GUI's and - especially on
Windows where the GUI is used almost exclusively - can cause trigger
bugs to go undetected for long periods. Trigger scripts sometimes exec
I<clearprompt> manually to display error messages but this is laborious
and will not catch unanticipated errors such as those emanating from
included modules or child processes.

ClearCase::ClearPrompt can be told to fix this problem by capturing all
stderr/stdout and displaying it automatically using I<clearprompt>.
There's also a facility for forwarding error messages to a specified
list of users via email.

ClearPrompt can capture messages to 4 "channels": the stdout and stderr
I/O streams and the Perl C<warn()> and C<die()> functions.  Now, since
C<warn()> and C<die()> send their output to stderr they could be
subsumed by the STDERR channel, but they have different semantics and
are thus treated separately. Messages thrown by warn/die are
I<anticipated> errors from within the current (perl) process, whereas
other messages arriving on stderr will typically be I<unexpected>
messages not under the control of the running script (for instance
those from a backquoted cleartool command). This distinction is quite
important in triggers, where the former may represent a policy decision
and the latter a plain old programming bug or system error such as a
locked VOB. Warn/die captures are also displayed with the appropriate
GUI icons and the title C<Warning> or C<Error>.

The 4 channels are known to ClearPrompt as WARN, DIE, STDOUT, and
STDERR.  To capture any of them to clearprompt just specify them with a
leading C<+> at I<use> time:

	use ClearCase::ClearPrompt qw(+STDERR +WARN +DIE);

These 3 "error channels" can also be requested via the meta-command

	use ClearCase::ClearPrompt qw(+ERRORS);

while all 4 can be captured with

	use ClearCase::ClearPrompt qw(+CAPTURE);

Messages may be automatically mailed to a list of users by attaching
the comma-separated list to the name of the channel using '=' in the
import method, e.g.

    use ClearCase::ClearPrompt '+ERRORS=vobadm';
    use ClearCase::ClearPrompt qw(+STDOUT=vobadm +STDERR=tom,dick,harry);

An additional pseudo-channel can be specified for email representing
interactions with the user via the clearprompt program itself. I.e. the
following

    use ClearCase::ClearPrompt qw(+PROMPT=vobadm);

will take all prompt strings and the user's responses and mail them to
the specified user(s).

=head2 MESSAGE CAPTURE NOTES

=over 4

=item *

The capture-to-dialog-box feature appears to be largely obsoleted by
ClearCase v4.2 which implements similar functionality. In 4.2, messages
to stdout/stderr are placed in the "trigger failed" dialog box. Of
course this doesn't help if the trigger generated warnings but didn't
fail but it solves the main problem.

=item *

As of ClearPrompt 1.25, the capture-to-dialog and capture-to-email
lists are discrete. This means that C<+WARN> will capture warnings to a
dialog box, while C<+WARN=vobadm> will send warnings via email but NOT
to a dialog box. To get both you must request both, e.g. C<+WARN
+WARN=vobadm>. This change was made as a result of the CC fix mentioned
above.

=item *

The email feature first attempts to use the Net::SMTP module.  If this
is uninstalled or reports failure, the I<notify> utility which first
shipped in CC 4.0 is used. Thus you must have either Net::SMTP or CC
4.0 (or both) for email to succeed.

=item *

When using message capture for triggers, it may be preferable to handle
it as a property of the trigger type rather than as part of the script.
For instance, here's one of my triggers:

    % ct lstype -l trtype:uncheckout_post@/vobs_test
    trigger type "uncheckout_post"
     17-Dec-01.17:09:55 by [VOB Admin] (vobadm.ccusers@u10)
      owner: vobadm
      group: ccusers
      all element trigger 
      post-operation uncheckout
      action: -execunix /opt/perl/bin/perl -MClearCase::ClearPrompt=+CAPTURE=dsb /data/ccase/triggers/uncheckout_post.tgr
      action: -execwin //u10/perl5/bin/perl -MClearCase::ClearPrompt=+CAPTURE=dsb //data/ccase/triggers/uncheckout_post.tgr

The C<-MClearCase::ClearPrompt=+CAPTURE=dsb> on the cmdline for both
Unix and Windows tells the trigger to email error messages to C<dsb>.
The advantage, of course, is that the scripts aren't polluted by C<use>
statements which aren't critical to their functionality, and the
mailing list or capture options can be maintained in one place (the
trigger-install script) rather than in each trigger script.

=back

=head2 SAMPLE CAPTURE USAGE

Try setting ATRIA_FORCE_GUI=1 by hand and running the following little
script which generates a warning via C<warn()> and a hard error from a
child process:

   BEGIN { $ENV{ATRIA_FORCE_GUI} = 1 }
   use ClearCase::ClearPrompt qw(+CAPTURE);
   warn qq(This is a warning\n);
   system q(perl nosuchscript);

You should see a couple of error msgs in dialog boxes, and none on
stderr.  Removing the C<+CAPTURE> would leave the messages on text-mode
stderr.  Changing it to C<+WARN> would put the I<warning> in a dialog
box but let the I<error msg> come to text stderr, while C<+STDERR>
would put both messages in the same dialog since C<warn()> would no
longer be treated specially. Appending "=E<lt>usernameE<gt>" would
cause mail to be sent to E<lt>usernameE<gt>. See also
C<./examples/capture.pl>.

=head2 TRIGGER DEBUGGING SUPPORT

If C</DEBUG> is specified, e.g.:

    use ClearCase::ClearPrompt '/DEBUG';

Then the trigger script will run in a Perl debugger session.  If the
trigger was fired from a GUI environment (Unix or Windows), the
debugger session will run in a separate text window. This same feature
is available by setting the environment variable

    export CLEARCASE_CLEARPROMPT_DEBUG=1

Or, an interactive shell can be automatically invoked at trigger firing
time if the C<use> statement includes C</SHELL> or the
B<CLEARCASE_CLEARPROMPT_DEBUG_SHELL> EV is set.  This is also valuable
for developing and debugging trigger scripts because it lets the user
explore the script's runtime environment (the C<CLEARCASE_*> env vars,
the current working directory, etc.). Thus either of

    use ClearCase::ClearPrompt '/SHELL';
    export CLEARCASE_CLEARPROMPT_DEBUG_SHELL=1

causes an interactive shell (/bin/sh or cmd.exe) to be started just
before the script executes.  In a GUI environment the shell will be
started in a separate window. The script waits for the shell to finish
before continuing and will exit immediately if the shell returns a
nonzero exit status.

=head2 INTEROP ENVIRONMENT NORMALIZATION

If C</ENV> is specified:

    use ClearCase::ClearPrompt '/ENV';

Any environment variables whose names match C<CLEARCASE_*> and whose
value contains back C<\> slashes will be modified to use forward
(C</>) slashes instead.  This is a no-op except on Windows.

=head2 DIRECTORY PROMPTING

The clearprompt command has no builtin directory chooser, so this
module provides a separate C<clearprompt_dir()> function which
implements it with "clearprompt list" and C<opendir/readdir/closedir>.
Usage is

    use ClearCase::ClearPrompt qw(clearprompt_dir);
    $dir = clearprompt_dir($starting_dir, $prompt_string);

This is pretty awkward to use since it doesn't employ a standard
directory-chooser interface but it works.  The only way to make your
selection final is to select "." or hit the Abort button.  And there's
no way to I<create> a directory via this interface. You would not use
this feature unless you had to, typically.

=head1 MORE EXAMPLES

Examples of advanced usage can be found in the test.pl script. There
is also a C<./examples> subdir with some sample scripts.

=head1 ENVIRONMENT VARIABLES

There are a few other EV's which can affect this module's behavior.
Those not mentioned above are advanced debugging features and are
documented only in the code. They are all in the
C<CLEARCASE_CLEARPROMPT_*> namespace.

=head1 NOTES

I<An apparent undocumented "feature" of clearprompt(1) is that it
catches SIGINT (Ctrl-C) and provides a status of 4 rather than
returning the signal number in C<$?> according to normal (UNIX) signal
semantics.>  We fix that up here so it looks like a normal signal 2.
Thus, if C<clearprompt()> returns undef the signal number is reliably
in $? as it's documented to be.

Also, there is a bug in ClearCase 4.0 for Win32. The list option
doesn't display the prompt text correctly. This is a bug in CC itself,
not the module, and is fixed in CC 4.1.

=head1 PORTING

This package has been known to work fine on Solaris2.5.1/perl5.004_04,
Solaris7/perl5.6, Solaris8/perl5.6.1, WindowsNT4.0SP3/perl5.005_02, and
Win2KSP2/perl5.6.1. As these platforms are cover a wide range they
should take care of any I<significant> portability issues but please
send reports of tweaks needed for other platforms to the address
below. Note also that I no longer test on the older platforms so the
may inadvertently have done something to break them.

It will work in a degraded form with I<ccperl> (the 5.001 version
supplied with ClearCase through at least CC5.0). Most features seem to
work with ccperl (in limited testing); the trigger series code is an
exception because it uses Data::Dumper which in turn requires
Perl5.004. However, though I've made some effort to port this
to ccperl, I still strongly recommend you use a modern Win32 Perl
configured for network use, as described at http://www.cleartool.com/.

=head1 AUTHOR

David Boyce <dsbperl@cleartool.com>

Copyright (c) 1999-2002 David Boyce. All rights reserved.  This Perl
program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

clearprompt(1), perl(1)

=cut
