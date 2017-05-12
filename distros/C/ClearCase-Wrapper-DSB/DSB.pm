package ClearCase::Wrapper::DSB;

$VERSION = '1.14';

use AutoLoader 'AUTOLOAD';

use strict;

#############################################################################
# Usage Message Extensions
#############################################################################
{
   local $^W = 0;
   no strict 'vars';

   # Usage message additions for actual cleartool commands that we extend.
   $catcs	= "\n* [-cmnt|-expand|-sources|-start]";
   $describe	= "\n* [--par/ents <n>]";
   $lock	= "\n* [-allow|-deny login-name[,...]] [-iflocked]";
   $lsregion	= "\n* [-current]";
   $mklabel	= "\n* [-up]";
   $setcs	= "\n* [-clone view-tag] [-expand] [-sync|-needed]";
   $setview	= "\n* [-me] [-drive drive:] [-persistent]";
   $update	= "\n* [-quiet]";
   $winkin	= "\n* [-vp] [-tag view-tag]";

   # Usage messages for pseudo cleartool commands that we implement here.
   # Note: we used to localize $0 but that turns out to trigger a bug
   # in perl 5.6.1.
   my $z = (($ARGV[0] eq 'help') ? $ARGV[1] : $ARGV[0]) || '';
   $comment	= "$z [-new] [-element] object-selector ...";
   $diffcs	= "$z view-tag-1 [view-tag-2]";
   $eclipse	= "$z element ...";
   $edattr	= "$z [-view [-tag view-tag]] | [-element] object-selector ...";
   $grep	= "$z [grep-flags] pattern element";
   $protectview	= "$z [-force] [-replace]"
		.  "\n[-chown login-name] [-chgrp group-name] [-chmod permissions]"
		.  "\n[-add_group group-name[,...]]"
		.  "\n[-delete_group group-name[,...]]"
		.  "\n{-tag view-tag | view-storage-dir-pname ...}";
   $recheckout	= "$z [-keep|-rm] pname ...";
   $winkout	= "$z [-dir|-rec|-all] [-f file] [-pro/mote] [-do]"
		.  "\n[-meta file [-print] file ...";
   $workon	= "$z [-me] [-login] [-exec command-invocation] view-tag";
}

#############################################################################
# Command Aliases
#############################################################################
*des		= *describe;
*desc		= *describe;
*edcmnt		= *comment;
*egrep		= *grep;
*mkbrtype	= *mklbtype;	# not synonyms but the code's the same
*reco		= *recheckout;
*work		= *workon;

1;

__END__

=head1 NAME

ClearCase::Wrapper::DSB - David Boyce's contributed cleartool wrapper functions

=head1 SYNOPSIS

This is an C<overlay module> for B<ClearCase::Wrapper> containing David
Boyce's non-standard extensions. See C<perldoc ClearCase::Wrapper> for
more details.

=head1 CLEARTOOL ENHANCEMENTS

=over 4

=item * CATCS

=over 4

=item 1. New B<-expand> flag

Follows all include statements recursively in order to print a complete
config spec. When used with the B<-cmnt> flag, comments are stripped
from this listing.

=item 2. New B<-sources> flag

Prints all files involved in the config spec (the I<config_spec> file
itself plus any files it includes).

=item 3. New B<-attribute> flag

This introduces the concept of user-defined I<view attributes>. A view
attribute is a keyword-value pair embedded in the config spec using the
conventional notation

    ##:Keyword: value ...

The value of any attribute may be retrieved by running

    <cmd-context> catcs -attr keyword ...

And to print all attributes:

    <cmd-context> catcs -attr -all

=item 4. New B<-start> flag

Prints the I<preferred initial working directory> of a view by
examining its config spec. This is simply the value of the C<Start>
attribute as described above; in other words I<-start> is a synonym for
I<-attr Start>.

The B<workon> command (see) uses this value.  E.g., using B<workon>
instead of I<setview> with the config spec:

    ##:Start: /vobs_fw/src/java
    element * CHECKEDOUT
    element * /main/LATEST

would set the view and automatically cd to C</vobs_fw/src/java>.

=back

=cut

sub catcs {
    my(%opt, $op);
    GetOptions(\%opt, qw(attribute=s cmnt expand rdl start sources viewenv vobs));
    if ($opt{sources}) {
	$op = '';
    } elsif ($opt{expand}) {
	$op = 'print';;
    } elsif ($opt{'rdl'}) {
	$op = 's%##:RDL:\s*(.+)%print "$+\n";exit 0%ie';
    } elsif ($opt{viewenv}) {
	$op = 's%##:ViewEnv:\s+(\S+)%print "$+\n";exit 0%ie';
    } elsif ($opt{start}) {
	$op = 's%##:Start:\s+(\S+)|^\s*element\s+(\S*)/\.{3}\s%print "$+\n";exit 0%ie';
    } elsif ($opt{attribute}) {
	if ($opt{attribute} eq '-all') {
	    $op = 's%##:(\S+):\s+(\S+)%print "$1=$2\n"%ie';
	} else {
	    $op = 's%##:'.$opt{attribute}.':\s+(\S+)%print "$1\n";exit 0%ie';
	}
    } elsif ($opt{vobs}) {
	$op = 's%^element\s+(\S+)/\.{3}\s%print "$1\n"%e';
    }
    if (defined $op) {
	$op .= ' unless /^\s*#/' if $op && $opt{cmnt};
	my $tag = ViewTag(@ARGV);
	die Msg('E', "view tag cannot be determined") if !$tag;;
	my($vws) = reverse split '\s+', ClearCase::Argv->lsview($tag)->qx;
	exit Burrow('CATCS_00', "$vws/config_spec", $op);
    }
}

=item * COMMENT

For each ClearCase object specified, dump the current comment into a
temp file, allow the user to edit it with his/her favorite editor, then
change the objects's comment to the results of the edit. This is
useful if you mistyped a comment and want to correct it.

The B<-new> flag causes it to ignore the previous comment.

See B<edattr> for the editor selection algorithm.

=cut

sub comment {
    shift @ARGV;
    my %opt;
    GetOptions(\%opt, qw(element new));
    Assert(@ARGV > 0);	# die with usage msg if untrue
    my $retstat = 0;
    my $editor = $ENV{WINEDITOR} || $ENV{VISUAL} || $ENV{EDITOR} ||
						    (MSWIN ? 'notepad' : 'vi');
    my $ct = ClearCase::Argv->new;
    # Checksum before and after edit - only update if changed.
    my($csum_pre, $csum_post) = (0, 0);
    for my $obj (@ARGV) {
	my @input = ();
	$obj .= '@@' if $opt{element};
	if (!$opt{new}) {
	    @input = $ct->desc([qw(-fmt %c)], $obj)->qx;
	    next if $?;
	}
	my $edtmp = ".$::prog.comment.$$";
	open(EDTMP, ">$edtmp") || die Msg('E', "$edtmp: $!");
	for (@input) {
	    next if /^~\w$/;  # Hack - allow ~ escapes for ci-trigger a la mailx
	    $csum_pre += unpack("%16C*", $_);
	    print EDTMP $_;
	}
	close(EDTMP) || die Msg('E', "$edtmp: $!");

	# Run editor on temp file
	Argv->new($editor, $edtmp)->system;

	open(EDTMP, $edtmp) || die Msg('E', "$edtmp: $!");
	while (<EDTMP>) { $csum_post += unpack("%16C*", $_); }
	close(EDTMP) || die Msg('E', "$edtmp: $!");
	unlink $edtmp, next if $csum_post == $csum_pre;
	$retstat++ if $ct->chevent([qw(-replace -cfi), $edtmp], $obj)->system;
	unlink $edtmp;
    }
    exit $retstat;
}

=item * DESCRIBE

Enhancement. Adds the B<-parents> flag, which takes an integer argument
I<N> and runs the I<describe> command on the version I<N> predecessors
deep instead of the currently-selected version.
into temp files and diffs them. If only one view is specified, compares
against the current working view's config spec.

=cut

sub describe {
    my $desc = ClearCase::Argv->new(@ARGV);
    $desc->optset(qw(CC WRAPPER));

    $desc->parseCC(qw(g|graphical local l|long s|short 
	    fmt=s alabel=s aattr=s ahlink=s ihlink=s
	    cview version=s ancestor
	    predecessor pname type=s cact));
    $desc->parseWRAPPER(qw(parents|par9999=s));
    my $generations = abs($desc->flagWRAPPER('parents') || 0);
    if ($generations) {
	my $pred = ClearCase::Argv->desc([qw(-fmt %En@@%PVn)]);
	$pred->autofail(1);
	my @nargs;
	my @args = $desc->args;
	for my $arg (@args) {
	    my $narg = $arg;
	    for (my $i = $generations; $i; $i--) {
		$narg = $pred->args($narg)->qx;
	    }
	    push(@nargs, $narg);
	}
	$desc->args(@nargs);
    }
    $desc->exec('CC');
}

=item * DIFFCS

New command.  B<Diffcs> dumps the config specs of two specified views
into temp files and diffs them. If only one view is specified, compares
against the current working view's config spec.

=cut

sub diffcs {
    my %opt;
    GetOptions(\%opt, qw(tag=s@));
    my @tags = @{$opt{tag}} if $opt{tag};
    push(@tags, @ARGV[1..$#ARGV]);
    if (@tags == 1) {
	my $cwv = ViewTag();
	push(@tags, $cwv) if $cwv;
    }
    die Msg('E', "two view-tag arguments required") if @tags != 2;
    my $ct = ClearCase::Argv->find_cleartool;
    my @cstmps = map {"$_.cs"} @tags;
    for my $i (0..1) {
	Argv->new("$ct catcs -tag $tags[$i] >$cstmps[$i]")->autofail(1)->system;
    }
    Argv->new('diff', @cstmps)->dbglevel(1)->system;
    unlink(@cstmps);
    exit 0;
}

=item * ECLIPSE

New command. B<Eclipse>s an element by copying a view-private version
over it. This is the dynamic-view equivalent of "hijacking" a file in a
snapshot view. Typically of use if you need temporary write access to a
file when the VOB or current branch is locked, or it's checked out
reserved.  B<Eclipsing elements can lead to dangerous confusion - use
with care!>

=cut

sub eclipse {
    require File::Copy;

    Assert(@ARGV > 1);	# die with usage msg if untrue
    shift @ARGV;	# dump the cmd name leaving only the elems to eclipse

    # Create a cleartool object.
    my $ct = ClearCase::Argv->new;

    # Retrieve the original config spec.
    my @orig = $ct->catcs->qx;
    exit 2 if $?;

    my $retstat = 0;
    for my $elem (@ARGV) {
	if (! -f $elem || -w _) {
	    warn Msg('W', "don't know how to eclipse '$elem'");
	    $retstat++;
	    next;
	}

	# Make a config spec template that hides the to-be-eclipsed elem.
	my $cstmp = ".$::prog.eclipse.$$";
	open(CSTMP, ">$cstmp") || die Msg('E', "$cstmp: $!");
	print CSTMP "element $elem -none\n";
	print CSTMP @orig;
	close(CSTMP) || die Msg('E', "$cstmp: $!");

	# Copy the element aside before it gets hidden.
	my $eltmp = "$elem.eclipse.$$";
	if (! File::Copy::copy($elem, $eltmp)) {
	    warn Msg('W', "$elem: $!");
	    $retstat++;
	    next;
	}

	# Now set the modified config spec to hide the element.
	if ($ct->setcs($cstmp)->system) {
	    unlink $eltmp;
	    $retstat++;
	    next;
	}

	# Copy the copy back to its original place. It will become
	# writeable as a side effect.
	if (! File::Copy::copy($eltmp, $elem)) {
	    warn Msg('W', "$elem: $!");
	    $retstat++;
	}
	unlink $eltmp;

	# Now set the config spec back to what it was and we're done.
	open(CSTMP, ">$cstmp") || die Msg('E', "$cstmp: $!");
	print CSTMP @orig;
	close(CSTMP) || die Msg('E', "$cstmp: $!");
	if ($ct->setcs($cstmp)->system) {
	    die Msg('W', "your config spec is broken! - original is in $cstmp");
	}
	unlink $cstmp;
    }
    exit $retstat;
}

=item * EDATTR

New command, inspired by the I<edcs> cmd.  B<Edattr> dumps the
attributes of the specified object into a temp file, then execs your
favorite editor on it, and adds, removes or modifies the attributes as
appropriate after you've modified the temp file and exited the editor.
Attribute types are created and deleted automatically.  This is
particularly useful on Unix platforms because as of CC 3.2 the Unix GUI
doesn't support modification of attributes and the quoting rules make
it difficult to use the command line.

If the B<-view> flag is used I<view attributes> are edited instead. See
the enhanced I<catcs> command for further discussion of view
attributes.

The environment variables WINEDITOR, VISUAL, and EDITOR are checked
in that order for editor names. If none of the above are set, the
default editor used is vi on UNIX and notepad on Windows.

=cut

sub edattr {
    my %opt;
    GetOptions(\%opt, qw(element view));
    shift @ARGV;
    my $retstat = 0;
    my $editor = $ENV{WINEDITOR} || $ENV{VISUAL} || $ENV{EDITOR} ||
						    (MSWIN ? 'notepad' : 'vi');
    my $ct = ClearCase::Argv->new;
    my $ctq = $ct->clone({-stdout=>0, -stderr=>0});

    my $edtmp = ".$::prog.edattr.ed.$$";
    my $cstmp = ".$::prog.edattr.cs.$$";

    if ($opt{view}) {
	my($csum_pre, $csum_post) = (0, 0);
	my $tag = ViewTag(@ARGV);
	GetOptions(\%opt, qw(tag=s));
	Assert(@ARGV == 0);	# no file args allowed
	my @cs = $ct->catcs(['-tag', $tag])->qx;
	my @rest = grep !m%^##:\w+:%, @cs;
	my @attrs = map {m%^##:(\w+):\s*(\S*)%; "$1=$2\n"}
		    grep m%^##:(\w+):%, @cs;
	open(EDTMP, ">$edtmp") || die Msg('E', "$edtmp: $!");
	for (@attrs) {
	    $csum_pre += unpack("%16C*", $_);
	    print EDTMP $_;
	}
	close(EDTMP) || die Msg('E', "$edtmp: $!");
	Argv->new($editor, $edtmp)->system;
	open(EDTMP, $edtmp) || die Msg('E', "$edtmp: $!");
	my %nattrs;
	for (<EDTMP>) {
	    $csum_post += unpack("%16C*", $_);
	    chomp;
	    next if /(^\s*#|^\s*$)/;
	    my($attr, $val) = split(/=/, $_, 2);
	    $attr = ucfirst(lc($attr));
	    for ($attr, $val) {
		s%^\s+%%;
		s%\s+$%%;
	    }
	    $nattrs{$attr} = $val;
	}
	close(EDTMP) || die Msg('E', "$edtmp: $!");
	unlink $edtmp;
	# No need to reset the config spec if editor didn't change it.
	exit 0 if $csum_pre == $csum_post;
	open(CSTMP, ">$cstmp") || die Msg('E', "$cstmp: $!");
	for (sort keys %nattrs) {
	    printf CSTMP "%-10s %s\n", "##:$_:", $nattrs{$_};
	}
	print CSTMP @rest;
	close(CSTMP) || die Msg('E', "$cstmp: $!");
	$retstat = $ct->setcs(['-tag', $tag], $cstmp)->system;
	unlink $cstmp if !$retstat;
	exit $retstat;
    }

    Assert(@ARGV > 0);	# die with usage msg if untrue
    for my $obj (@ARGV) {
	my %indata = ();
	$obj .= '@@' if $opt{element};
	my @lines = $ct->desc([qw(-aattr -all)], $obj)->qx;
	if ($?) {
	    $retstat++;
	    next;
	}
	for my $line (@lines) {
	    next unless $line =~ /\s*(\S+)\s+=\s+(.+)/;
	    $indata{$1} = $2;
	}
	open(EDTMP, ">$edtmp") || die Msg('E', "$edtmp: $!");
	print EDTMP "# $obj (format: attr = \"val\"):\n\n" if !keys %indata;
	for (sort keys %indata) { print EDTMP "$_ = $indata{$_}\n" }
	close(EDTMP) || die Msg('E', "$edtmp: $!");

	# Run editor on temp file
	Argv->new($editor, $edtmp)->system;

	open(EDTMP, $edtmp) || die Msg('E', "$edtmp: $!");
	while (<EDTMP>) {
	    chomp;
	    next if /^\s*$|^\s*#.*$/;	# ignore null and comment lines
	    if (/\s*(\S+)\s+=\s+(.+)/) {
		my($attr, $newval) = ($1, $2);
		my $oldval;
		if (defined($oldval = $indata{$attr})) {
		    delete $indata{$attr};
		    # Skip if data unchanged.
		    next if $oldval eq $newval;
		}
		# Figure out what type the new attype needs to be.
		# Sorry, didn't bother with -vtype time.
		if ($ctq->lstype("attype:$attr")->system) {
		    if ($newval =~ /^".*"$/) {
			$ct->mkattype([qw(-nc -vty string)], $attr)->system;
		    } elsif ($newval =~ /^[+-]?\d+$/) {
			$ct->mkattype([qw(-nc -vty integer)], $attr)->system;
		    } elsif ($newval =~ /^-?\d+\.?\d*$/) {
			$ct->mkattype([qw(-nc -vty real)], $attr)->system;
		    } else {
			$ct->mkattype([qw(-nc -vty opaque)], $attr)->system;
		    }
		    next if $?;
		}
		# Deal with broken quoting on &^&@# Windows.
		if (MSWIN && $newval =~ /^"(.*)"$/) {
		    $newval = qq("\\"$1\\"");
		}
		# Make the new attr value.
		if (defined($oldval)) {
		    $retstat++ if $ct->mkattr([qw(-rep -c)],
			 "(Was: $oldval)", $attr, $newval, $obj)->system;
		} else {
		    $retstat++ if $ct->mkattr([qw(-rep)],
			 $attr, $newval, $obj)->system;
		}
	    } else {
		warn Msg('W', "incorrect line format: '$_'");
		$retstat++;
	    }
	}
	close(EDTMP) || die Msg('E', "$edtmp: $!");
	unlink $edtmp;

	# Now, delete any attrs that were deleted from the temp file.
	# First we do a simple rmattr; then see if it was the last of
	# its type and if so remove the type too.
	for (sort keys %indata) {
	    if ($ct->rmattr($_, $obj)->system) {
		$retstat++;
	    } else {
		# Don't remove the type if its vob serves as an admin vob!
		my @deps = grep /^<-/,
				$ct->desc([qw(-s -ahl AdminVOB)], 'vob:.')->qx;
		next if $? || @deps;
		$ct->rmtype(['-rmall'], "attype:$_")->system;
	    }
	}
    }
    exit $retstat;
}

=item * GREP

New command. Greps through past revisions of a file for a pattern, so
you can see which revision introduced a particular function or a
particular bug. By analogy with I<lsvtree>, I<grep> searches only
"interesting" versions unless B<-all> is specified. I<Note that
this will expand cleartext for all grepped versions>.

Flags B<-nnn> are accepted where I<nnn> represents the number of versions
to go back. Thus C<grep -1 foo> would search only the predecessor.

=cut

sub grep {
    my %opt;
    GetOptions(\%opt, 'all');
    my $elem = pop(@ARGV);
    my $limit = 0;
    if (my @num = grep /^-\d+$/, @ARGV) {
	@ARGV = grep !/^-\d+$/, @ARGV;
	die Msg('E', "incompatible flags: @num") if @num > 1;
	$limit = -int($num[0]);
    }
    my $lsvt = ClearCase::Argv->new('lsvt', ['-s'], $elem);
    $lsvt->opts('-all', $lsvt->opts) if $opt{all} || $limit > 1;
    chomp(my @vers = sort {($b =~ m%/(\d+)%)[0] <=> ($a =~ m%/(\d+)%)[0]}
						grep {m%/\d+$%} $lsvt->qx);
    exit 2 if $?;
    splice(@vers, $limit) if $limit;
    splice(@ARGV, 0, 1, 'egrep');
    Argv->new(@ARGV, @vers)->dbglevel(1)->exec;
}

=item * LOCK

New B<-allow> and B<-deny> flags. These work like I<-nuser> but operate
incrementally on an existing I<-nuser> list rather than completely
replacing it. When B<-allow> or B<-deny> are used, I<-replace> is
implied.

When B<-iflocked> is used, no lock will be created where one didn't
previously exist; the I<-nusers> list will only be modified for
existing locks.

=cut

sub lock {
    my %opt;
    GetOptions(\%opt, qw(allow=s deny=s iflocked));
    return 0 unless %opt;
    my $lock = ClearCase::Argv->new(@ARGV);
    $lock->parse(qw(c|cfile=s c|cquery|cqeach nusers=s
						    pname=s obsolete replace));
    die Msg('E', "cannot specify -nusers along with -allow or -deny")
					if $lock->flag('nusers');
    die Msg('E', "cannot use -allow or -deny with multiple objects")
					if $lock->args > 1;
    my $lslock = ClearCase::Argv->lslock([qw(-fmt %c)], $lock->args);
    my($currlock) = $lslock->autofail(1)->qx;
    if ($currlock && $currlock =~ m%^Locked except for users:\s+(.*)%) {
	my %nusers = map {$_ => 1} split /\s+/, $1;
	if ($opt{allow}) {
	    for (split /,/, $opt{allow}) { $nusers{$_} = 1 }
	}
	if ($opt{deny}) {
	    for (split /,/, $opt{deny}) { delete $nusers{$_} }
	}
	$lock->opts($lock->opts, '-nusers', join(',', sort keys %nusers))
								    if %nusers;
    } elsif (!$currlock && $opt{iflocked}) {
	exit 0;
    } elsif ($opt{allow}) {
	$lock->opts($lock->opts, '-nusers', $opt{allow});
    }
    $lock->opts($lock->opts, '-replace') unless $lock->flag('replace');
    $lock->exec;
}

=item * LSREGION

A surprising lapse of the real cleartool CLI is that there's no
way to determine the current region. This extension adds a
B<-current> flag to lsregion.

=cut

sub lsregion {
    my %opt;
    # -cu999 is only to enforce -cur/rent
    GetOptions(\%opt, qw(current cu999));
    return 0 unless $opt{current};
    if (MSWIN) {
	use vars '%RegHash';
	require Win32::TieRegistry;
	Win32::TieRegistry->import('TiedHash', '%RegHash');
	my $region = $RegHash{LMachine}->{SOFTWARE}->
		{Atria}->{ClearCase}->{CurrentVersion}->{Region};
	print $region, "\n";
    } else {
	my $regfile = '/var/adm/atria/rgy/rgy_region.conf';
	open(REGFILE, $regfile) || die Msg('E', "$regfile: $!");
	my $region = <REGFILE>;
	close(REGFILE);
	print $region;
    }
    exit 0;
}

=item * MKBRTYPE,MKLBTYPE

Modification: if user tries to make a type in the current VOB without
explicitly specifying -ordinary or -global, and if said VOB is
associated with an admin VOB, then by default create the type as a
global type in the admin VOB instead. B<I<In effect, this makes -global
the default iff a suitable admin VOB exists>>.

=cut

sub mklbtype {
    return if grep /^-ord|^-glo|vob:/i, @ARGV;
    if (my($ahl) = grep /^->/,
		    ClearCase::Argv->desc([qw(-s -ahl AdminVOB vob:.)])->qx) {
	if (my $avob = (split /\s+/, $ahl)[1]) {
	    # Save aside all possible flags for mkxxtype,
	    # then add the vob selector to each type selector
	    # and add the new -global to opts before exec-ing.
	    my $ntype = ClearCase::Argv->new(@ARGV);
	    $ntype->parse(qw(replace|global|ordinary
			    vpelement|vpbranch|vpversion
			    pbranch|shared
			    gt|ge|lt|le|enum|default|vtype=s
			    cqe|nc c|cfile=s));
	    my @args = $ntype->args;
	    for (@args) {
		next if /\@/;
		$_ = "$_\@$avob";
		warn Msg('W', "making global type $_ ...");
	    }
	    $ntype->args(@args);
	    $ntype->opts('-global', $ntype->opts);
	    $ntype->exec;
	}
    }
}

=item * MKLABEL

The new B<-up> flag, when combined with B<-recurse>, also labels the parent
directories of the specified I<pname>s all the way up to their vob tags.

=cut

sub mklabel {
    my %opt;
    GetOptions(\%opt, qw(up));
    return 0 unless $opt{up};
    die Msg('E', "-up requires -recurse") if !grep /^-re?$|^-rec/, @ARGV;
    my $mkl = ClearCase::Argv->new(@ARGV);
    my $dsc = ClearCase::Argv->new({-autochomp=>1});
    $mkl->parse(qw(replace|recurse|ci|cq|nc
				version|c|cfile|select|type|name|config=s));
    $mkl->syfail(1)->system;
    require File::Basename;
    require File::Spec;
    File::Spec->VERSION(0.82);
    my($label, @elems) = $mkl->args;
    my %ancestors;
    for my $pname (@elems) {
	my $vobtag = $dsc->desc(['-s'], "vob:$pname")->qx;
	for (my $dad = File::Basename::dirname(File::Spec->rel2abs($pname));
		    length($dad) >= length($vobtag);
			    $dad = File::Basename::dirname($dad)) {
	    $ancestors{$dad}++;
	}
    }
    exit(0) if !%ancestors;
    $mkl->opts(grep !/^-r(ec)?$/, $mkl->opts);
    $mkl->args($label, sort {$b cmp $a} keys %ancestors)->exec;
}

=item * MOUNT

This is a Windows-only enhancement: on UNIX, I<mount> behaves correctly
and we do not mess with its behavior. On Windows, for some bonehead
reason I<cleartool mount -all> gives an error for already-mounted VOBs;
these are now ignored as on UNIX. At the same time, VOB tags containing
I</> are normalized to I<\> so they'll match the registry, and an
extension is made to allow multiple VOB tags to be passed to one
I<mount> command.

=cut

sub mount {
    return 0 if !MSWIN || @ARGV < 2;
    my %opt;
    GetOptions(\%opt, qw(all));
    my $mount = ClearCase::Argv->new(@ARGV);
    $mount->autofail(1);
    $mount->parse(qw(persistent options=s));
    die Msg('E', qq(Extra arguments: "@{[$mount->args]}"))
						if $mount->args && $opt{all};
    my @tags = $mount->args;
    my $lsvob = ClearCase::Argv->lsvob(@tags);
    # The set of all known public VOBs.
    my @public = grep /\spublic\b/, $lsvob->qx;
    # The subset which are not mounted.
    my @todo = map {(split /\s+/)[1]} grep /^\s/, @public;
    # If no vobs are mounted, let the native mount -all proceed.
    if ($opt{all} && @public == @todo) {
	push(@ARGV, '-all');
	return 0;
    }
    # Otherwise mount what's needed one by one.
    for (@todo) {
	$mount->args($_)->system;
    }
    exit 0;
}

=item * PROTECTVIEW

Modifies user or group permissions for one or more views.
Analogous to the native ClearCase command I<protectvob> (see).
Most flags accepted by B<protectview> behave similarly to those
of I<protectvob>.

The B<-replace> flag is special; it uses the administrative I<fix_prot>
tool to completely replace any pre-existing identity information. This
gives the view's permissions a "clean start"; in particular, any grants
of access to other groups will be removed.

This operation will not work on a running view. Views must be
manually stopped with C<endview -server> before reprotection may proceed.

B<Warning>: this is an experimental interface which has not been tested
in all scenarios. It cannot destroy any data, so there's nothing it
could break which could't be fixed with an administrator's help, but it
should still be used with care.  In particular, it's possible to
specify values to B<-chmod> which will confuse the view greatly.

=cut

sub protectview {
    die Msg('E', "not yet supported on Windows") if MSWIN;
    my %opt;
    GetOptions(\%opt, qw(force replace tag=s add_group=s delete_group=s
				    chown=s chgrp=s chmod=s));
    my $cmd = shift @ARGV;
    if ($opt{tag}) {
	Assert(@ARGV == 0);	# -tag and vws area are mutually exclusive
	my($vws) = (split ' ', ClearCase::Argv->lsview($opt{tag})->qx)[-1];
	push(@ARGV, $vws);
    }
    Assert(@ARGV > 0);	# die with usage msg if no vws area specified
    Assert(scalar %opt, 'no options specified');
    die Msg('E', "$cmd -chown requires administrative privileges")
						    if $opt{chown} && $> != 0;
    my $rc = 0;
    for my $vws (@ARGV) {
	my $idedir = "$vws/.identity";
	if (! -f "$vws/config_spec" || ! -d $idedir) {
	    warn Msg('W', "not a view storage area: $vws");
	    $rc = 1;
	    next;
	}
	if (! $opt{force}) {
	    my $prompt = qq(Protect view "$vws"?);
	    require ClearCase::ClearPrompt;
	    next if ClearCase::ClearPrompt::clearprompt(
			    qw(yes_no -def n -type ok -pro), $prompt);
	}
	if (-e "$vws/.pid") {
	    if ($opt{force}) {
		my $tag = $opt{tag};
		$tag ||= ClearCase::Argv->lsview([qw(-s -storage)], $vws)->qx;
		chomp $tag;
		ClearCase::Argv->endview([qw(-server)], $tag)->system;
	    }
	    if (-e "$vws/.pid") {
		warn Msg('W', "cannot protect running view $vws");
		$rc = 1;
		next;
	    }
	}
	if ($opt{chown} || $opt{chgrp} || $opt{chmod}) {
	    my $uid = $opt{chown} || (stat "$idedir/uid")[4];
	    $uid = (getpwnam($uid))[2] unless $uid =~ /^\d+$/;
	    my $gid = $opt{chgrp} || (stat "$idedir/gid")[5];
	    $gid = (getgrnam($gid))[2] unless $gid =~ /^\d+$/;
	    if ($opt{replace}) {
		my $fp = Argv->new('/usr/atria/etc/utils/fix_prot');
		$fp->opts(qw(-root -recurse));
		$fp->opts($fp->opts, '-force')  if $opt{force};
		$fp->opts($fp->opts, '-chown', $uid);
		$fp->opts($fp->opts, '-chgrp', $gid);
		$fp->opts($fp->opts, '-chmod', $opt{chmod}) if $opt{chmod};
		$fp->args($vws);
		if ($fp->system) {
		    $rc = 1;
		    next;
		}
	    } else {
		if ($opt{chown} || $opt{chgrp}) {
		    unlink("$idedir/group.$gid") if $opt{chgrp};
		    if (Argv->chown([qw(-R -h)], "$uid:$gid", $vws)->system) {
			$rc = 1;
			next;
		    }
		}
		if ($opt{chmod}) {
		    if (Argv->chmod(['-R'], $opt{chmod}, $vws)->system) {
			$rc = 1;
			next;
		    }
		    for my $grp (glob("$idedir/group.*")) {
			chmod(0102410, $grp) || warn Msg('W', "$grp: $!");
		    }
		}
		chmod(0104400, "$idedir/uid") ||
					    warn Msg('W', "$idedir/uid: $!");
		chmod(0102410, "$idedir/gid") ||
					    warn Msg('W', "$idedir/gid: $!");
	    }
	}
	if ($opt{delete_group}) {
	    for (split ',', $opt{delete_group}) {
		my $gid = /^\d+$/ ? $_ : (getgrnam($_))[2];
		if (! $gid) {
		    warn Msg('W', "no such group: $_");
		    $rc = 1;
		    next;
		}
		my $grp = "$idedir/group.$gid";
		unlink($grp);
	    }
	}
	if ($opt{add_group}) {
	    for (split ',', $opt{add_group}) {
		my $gid = /^\d+$/ ? $_ : (getgrnam($_))[2];
		if (! $gid) {
		    warn Msg('W', "no such group: $_");
		    $rc = 1;
		    next;
		}
		my $grp = "$idedir/group.$gid";
		unlink($grp);
		if (! open(GID, ">$grp")) {
		    warn Msg('W', "$vws: unable to add group $_");
		    $rc = 1;
		    next;
		}
		close(GID);
		if (! chown(-1, $gid, $grp) || ! chmod(0102410, $grp)) {
		    warn Msg('W', "$vws: unable to add group $_: $!");
		    $rc = 1;
		    next;
		}
	    }
	}
    }
    exit($rc);
}

=item * RECO/RECHECKOUT

Redoes a checkout without the database operations by simply copying the
contents of the existing checkout's predecessor over the view-private
checkout file. The previous contents are moved aside to "<element>.reco".
The B<-keep> and B<-rm> options are honored by analogy with I<uncheckout>.

=cut

sub recheckout {
    my %opt;
    GetOptions(\%opt, qw(keep rm));
    shift @ARGV;
    require File::Copy;
    for (@ARGV) {
	$_ = readlink if -l && defined readlink;
	if (! -w $_) {
	    warn Msg('W', "$_: not checked out");
	    next;
	}
	my $pred = Pred($_, 1);
	my $keep = "$_.reco";
	unlink $keep;
	if (rename($_, $keep)) {
	    if (File::Copy::copy($pred, $_)) {
		my $mode = (stat $keep)[2];
		chmod $mode, $_;
	    } else {
		die Msg('E', (-r $_ ? $keep : $_) . ": $!");
	    }
	} else {
	    die Msg('E', "cannot rename $_ to $keep: $!");
	}
	unlink $keep if $opt{rm};
    }
    exit 0;
}

=item * RMELEM

It appears that when elements are removed with I<rmelem> they often
remain visible for quite a while due to some kind of view cache,
though attempts to actually open them result in an I/O error. Running
I<cleartool setcs -current> clears this up. Thus I<rmelem> is
overridden here to add an automatic view refresh when done.

=cut

sub rmelem {
    my $rc = ClearCase::Argv->new(@ARGV)->system;
    ClearCase::Argv->setcs(['-current'])->system unless $rc;
    exit($rc >> 8);
}

=item * SETCS

Adds a B<-clone> flag which lets you specify another view from which to copy
the config spec.

Adds a B<-sync> flag. This is similar to B<-current> except that it
analyzes the CS dependencies and only flushes the view cache if the
I<compiled_spec> file is out of date with respect to the I<config_spec>
source file or any file it includes. In other words: B<setcs -sync> is
to B<setcs -current> as B<make foo.o> is to B<cc -c foo.c>.

Adds a B<-needed> flag. This is similar to B<-sync> above but it
doesn't recompile the config spec. Instead, it simply indicates with
its return code whether a recompile is in order.

Adds a B<-expand> flag, which "flattens out" the config spec by
inlining the contents of any include files.

=cut

sub setcs {
    my %opt;
    GetOptions(\%opt, qw(clone=s expand needed sync));
    die Msg('E', "-expand and -sync are mutually exclusive")
					    if $opt{expand} && $opt{sync};
    die Msg('E', "-expand and -needed are mutually exclusive")
					    if $opt{expand} && $opt{needed};
    my $tag = ViewTag(@ARGV) if grep /^(expand|sync|needed|clone)$/, keys %opt;
    if ($opt{expand}) {
	my $ct = Argv->new([$^X, '-S', $0]);
	my $settmp = ".$::prog.setcs.$$";
	open(EXP, ">$settmp") || die Msg('E', "$settmp: $!");
	print EXP $ct->opts(qw(catcs -expand -tag), $tag)->qx;
	close(EXP);
	$ct->opts('setcs', $settmp)->system;
	unlink $settmp;
	exit $?;
    } elsif ($opt{sync} || $opt{needed}) {
	chomp(my @srcs = qx($^X -S $0 catcs -sources -tag $tag));
	exit 2 if $?;
	(my $obj = $srcs[0]) =~ s/config_spec/.compiled_spec/;
	die Msg('E', "$obj: no such file") if ! -f $obj;
	die Msg('E', "no permission to update $tag's config spec") if ! -w $obj;
	my $otime = (stat $obj)[9];
	my $needed = grep { (stat $_)[9] > $otime } @srcs;
	if ($opt{sync}) {
	    if ($needed) {
		ClearCase::Argv->setcs(qw(-current -tag), $tag)->exec;
	    } else {
		exit 0;
	    }
	} else {
	    exit $needed;
	}
    } elsif ($opt{clone}) {
	my $ct = ClearCase::Argv->new;
	my $ctx = $ct->find_cleartool;
	my $cstmp = ".$ARGV[0].$$.cs.$tag";
	Argv->autofail(1);
	Argv->new("$ctx catcs -tag $opt{clone} > $cstmp")->system;
	$ct->setcs('-tag', $tag, $cstmp)->system;
	unlink($cstmp);
	exit 0;
    }
}

=item * SETVIEW

ClearCase 4.0 for Windows completely removed I<setview> functionality,
but this wrapper emulates it by attaching the view to a drive letter
and cd-ing to that drive. It supports all the flags I<setview> for
CC 3.2.1/Windows supported (B<-drive>, B<-exec>, etc.) and adds two
new ones: B<-persistent> and B<-window>.

If the view is already mapped to a drive letter that drive is used.
If not, the first available drive working backwards from Z: is used.
Without B<-persistent> a drive mapped by setview will be unmapped
when the setview process is exited.

With the B<-window> flag, a new window is created for the setview. A
beneficial side effect of this is that Ctrl-C handling within this new
window is cleaner.

The setview emulation sets I<CLEARCASE_ROOT> for compatibility and adds
a new EV I<CLEARCASE_VIEWDRIVE>.

UNIX setview functionality is left alone.

=cut

sub setview {
    # Clean up whatever EV's we might have used to communicate from
    # parent (pre-setview) to child (in-setview) processes.
    $ENV{CLEARCASE_PROFILE} = $ENV{_CLEARCASE_WRAPPER_PROFILE}
				if defined($ENV{_CLEARCASE_WRAPPER_PROFILE});
    delete $ENV{_CLEARCASE_WRAPPER_PROFILE};
    delete $ENV{_CLEARCASE_PROFILE};
    for (grep /^(CLEARCASE_)?ARGV_/, keys %ENV) { delete $ENV{$_} }

    if (!MSWIN) {
	ClearCase::Argv->mustexec(1);	# CtCmd setview doesn't work right
	return 0;
    }

    my %opt;
    GetOptions(\%opt, qw(exec=s drive=s login ndrive persistent window));
    my $child = $opt{'exec'};
    if ($ENV{SHELL}) {
	$child ||= $ENV{SHELL};
    } else {
	delete $ENV{LOGNAME};
    }
    $child ||= $ENV{ComSpec} || $ENV{COMSPEC} || 'cmd.exe';
    my $vtag = $ARGV[-1];
    my @net_use = grep /\s[A-Z]:\s/i, Argv->new(qw(net use))->qx;
    my $drive = $opt{drive} || (map {/(\w:)/ && uc($1)}
				grep /\s+\\\\view\\$vtag\b/,
				grep !/unavailable/i, @net_use)[0];
    my $mounted = 0;
    my $pers = $opt{persistent} ? '/persistent:yes' : '/persistent:no';
    if (!$drive) {
	ClearCase::Argv->startview($vtag)->autofail(1)->system
						    if ! -d "//view/$vtag";
	$mounted = 1;
	my %taken = map { /\s([A-Z]:)\s/i; $1 => 1 } @net_use;
	for (reverse 'G'..'Z') {
	    next if $_ eq 'X';	# X: is reserved (for CDROM?) on Citrix
	    $drive = $_ . ':';
	    if (!$taken{$drive}) {
		local $| = 1;
		print "Connecting $drive to \\\\view\\$vtag ... "
							    if !$opt{'exec'};
		my $netuse = Argv->new(qw(net use),
					    $drive, "\\\\view\\$vtag", $pers);
		$netuse->stdout(0) if $opt{'exec'};
		last if !$netuse->system;
	    }
	}
    } elsif ($opt{drive}) {
	$drive .= ':' if $drive !~ /:$/;
	$drive = uc($drive);
	if (! -d $drive) {
	    $mounted = 1;
	    local $| = 1;
	    print "Connecting $drive to \\\\view\\$vtag ... ";
	    Argv->new(qw(net use), $drive, "\\\\view\\$vtag", $pers)->system;
	    exit $?>>8 if $?;
	}
    }
    chdir "$drive/" || die Msg('E', "chdir $drive $!");
    $ENV{CLEARCASE_ROOT} = "\\\\view\\$vtag";
    $ENV{CLEARCASE_VIEWDRIVE} = $ENV{VD} = $drive;
    my $sv = Argv->new($child);
    $sv->prog(qw(start /wait), $sv->prog) if $opt{window};
    if ($mounted && !$opt{persistent}) {
	my $rc = $sv->system;
	my $netuse = Argv->new(qw(net use), $drive, '/delete');
	$netuse->stdout(0) if $opt{'exec'};
	$netuse->system;
	exit $rc;
    } else {
	$sv->exec;
    }
}

=item * UPDATE

Adds a B<-quiet> option to strip out all those annoying
C<Processing dir ...> and C<End dir ...> messages so you can see what
files actually changed. It also suppresses logging by redirecting the
log file to /dev/null.

=cut

sub update {
    my %opt;
    GetOptions(\%opt, qw(quiet));
    return 0 if !$opt{quiet};
    if (!grep m%^-log%, @ARGV) {
	splice(@ARGV, 1, 0, '-log', MSWIN ? 'NUL' : '/dev/null');
    }
    my $ct = ClearCase::Argv->find_cleartool;
    open(CMD, "$ct @ARGV |") || exit(2);
    while(<CMD>) {
	next if m%^(?:Processing|End)\s%;
	next if m%^[.]+$%;
	next if m%, copied 0 %;
	print;
    }
    exit(close(CMD));
}

=item * WINKIN

The B<-tag> flag allows you specify a local file path plus another view;
the named DO in the named view will be winked into the current view, e.g.:

    <cmd-context> winkin -tag otherview /vobs_myvob/dir1/dir2/file

The B<-vp> flag, when used with B<-tag>, causes the "remote" file to be
converted into a DO if required before winkin is attempted. See the
B<winkout> extension for details. I<Note: this feature depends on
C<setview> and thus will not work on Windows where setview has been
removed. However, it would be possible to re-code it to use the setview
emulation provided in this same package if you really want the
feature on Windows.>

=cut

sub winkin {
    my %opt;
    local $Getopt::Long::autoabbrev = 0; # so -rm and -r/ecurse don't collide
    GetOptions(\%opt, qw(rm tag=s vp));
    return 0 if !$opt{tag};
    my $wk = ClearCase::Argv->new(@ARGV);
    $wk->parse(qw(print|noverwrite|siblings|adirs|recurse|ci out|select=s));
    $wk->quote;
    my @files = $wk->args;
    unlink @files if $opt{rm};
    if ($opt{vp}) {
	my @winkout = ($^X, '-S', $0, 'winkout', '-pro');
	ClearCase::Argv->new(qw(setview -exe), "@winkout @files",
					    $opt{tag})->autofail(1)->system;
    }
    my $rc = 0;
    for my $file (@files) {
	if ($wk->flag('recurse') || $wk->flag('out')) {
	    $wk->args;
	} else {
	    $wk->args('-out', $file);
	}
	$rc ||= $wk->args($wk->args, "/view/$opt{tag}$file")->system;
    }
    exit $rc;
}

=item * WINKOUT

The B<winkout> pseudo-cmd takes a set of view-private files as
arguments and, using clearaudit, turns them into derived objects. The
config records generated are meaningless but the mere fact of being a
DO makes a file eligible for forced winkin from another view.

If the B<-promote> flag is given, the view scrubber will be run on
these new DO's. This has the effect of promoting them to the VOB and
winking them back into the current view.

If a meta-DO filename is specified with B<-meta>, this file is created
as a DO and caused to reference all the other new DO's, thus defining a
B<DO set> and allowing the entire set to be winked in using the meta-DO
as a hook. E.g. assuming view-private files X, Y, and Z already exist:

	ct winkout -meta .WINKSET X Y Z

will make them into derived objects and create a 4th DO ".WINKSET"
containing references to the others. A subsequent

	ct winkin -recurse -adirs /view/extended/path/to/.WINKSET

from a different view will wink all four files into the current view.

The list of files to convert may be derived via
B<-dir/-rec/-all/-avobs>, provided in a file containing a list of files
with B<-flist>, or specified as a literal list of view-private files.
When using B<-dir/-rec/-all/-avobs> to derive the file list only the
output of C<lsprivate -other> is considered unless B<-do> is used;
B<-do> causes existing DO's to be re-converted. Use B<-do> with care as
it may convert a useful CR to a meaningless one.

The B<"-flist -"> flag can be used to read the file list from stdin,
which may be useful in a script.

=cut

sub winkout {
    warn Msg('E', "this may work on &%@# Windows but I haven't tried") if MSWIN;
    my %opt;
    GetOptions(\%opt, qw(directory recurse all avobs flist=s
					do meta=s print promote));
    my $ct = ClearCase::Argv->new({-autochomp=>1, -syfail=>1});

    my $dbg = Argv->dbglevel;

    my $cmd = shift @ARGV;
    my @list;
    if (my @scope = grep /^(dir|rec|all|avo|f)/, keys %opt) {
	die Msg('E', "mutually exclusive flags: @scope") if @scope > 1;
	if ($opt{flist}) {
	    open(LIST, $opt{flist}) || die Msg('E', "$opt{flist}: $!");
	    @list = <LIST>;
	    close(LIST);
	} else {
	    my @type = $opt{'do'} ? qw(-other -do) : qw(-other);
	    @list = Argv->new([$^X, '-S', $0, 'lsp'],
		    ['-s', @type, "-$scope[0]"])->qx;
	}
    } else {
	@list = @ARGV;
    }
    chomp @list;
    my %set = map {$_ => 1} grep {-f}
		    grep {!m%\.(?:mvfs|nfs)\d+|cmake\.state%} @list;
    exit 0 if ! %set;
    if ($opt{'print'}) {
	for (keys %set) {
	    print $_, "\n";
	}
	print $opt{meta}, "\n" if $opt{meta};
	exit 0;
    }
    # Shared DO's should be g+w!
    (my $egid = $)) =~ s%\s.*%%;
    for (keys %set) {
	my($mode, $uid, $gid) = (stat($_))[2,4,5];
	if (!defined($mode)) {
	    warn Msg('W', "no such file: $_");
	    delete $set{$_};
	    next;
	}
	next if $uid != $> || ($mode & 0222) || ($mode & 0220 && $gid == $egid);
	chmod(($mode & 07777) | 0220, $_);
    }
    my @dolist = sort keys %set;
    # Add the -meta file to the list of DO's if specified.
    if ($opt{meta}) {
	if ($dbg) {
	    my $num = @dolist;
	    print STDERR "+ associating $num files with $opt{meta} ...\n";
	}
	open(META, ">$opt{meta}") || die Msg('E', "$opt{meta}: $!");
	for (@dolist) { print META $_, "\n" }
	close(META);
	push(@dolist, $opt{meta});
    }
    # Convert regular view-privates into DO's by opening them
    # under clearaudit control.
    {
	my $clearaudit = MSWIN ? 'clearaudit' : '/usr/atria/bin/clearaudit';
	local $ENV{CLEARAUDIT_SHELL} = $^X;
	my $ecmd = 'chomp; open(DO, ">>$_") || warn "Error: $_: $!\n"';
	my $cmd = qq($clearaudit -n -e '$ecmd');
	$cmd = "set -x; $cmd" if $dbg && !MSWIN;
	open(AUDIT, "| $cmd") || die Msg('E', "$cmd: $!");
	for (@dolist) {
	    print AUDIT $_, "\n";
	    print STDERR $_, "\n" if $dbg;
	}
	close(AUDIT) || die Msg('E', $! ?
				"Error closing clearaudit pipe: $!" :
				"Exit status @{[$?>>8]} from clearaudit");
    }
    if ($opt{promote}) {
	my $scrubber = MSWIN ? 'view_scrubber' : '/usr/atria/etc/view_scrubber';
	my $cmd = "$scrubber -p";
	$cmd = "set -x; $cmd" if $dbg && !MSWIN;
	open(SCRUBBER, "| $cmd") || die Msg('E', "$scrubber: $!");
	for (@dolist) { print SCRUBBER $_, "\n" }
	close(SCRUBBER) || die Msg('E', $! ?
				"Error closing $scrubber pipe: $!" :
				"Exit status $? from $scrubber");
    }
    exit 0;
}

=item * WORKON

New command, similar to I<setview> but provides hooks to cd to a
preferred I<initial working directory> within the view and to set
up any required environment variables. The I<initial working directory>
is defined as the output of B<ct catcs -start> (see).

If a file called I<.viewenv.pl> exists in the I<initial working
directory>, it's read before starting the user's shell. This file uses
Perl syntax and must end with a "1;" like any C<require-d> file.  Any
unrecognized arguments given to I<workon> following the view name will
be passed on to C<.viewenv.pl> in C<@ARGV>. Environment variables
required for builds within the setview may be set here.

=cut

sub workon {
    shift @ARGV;	# get rid of pseudo-cmd
    my(%opt, @sv_argv);
    # Strip flags intended for 'setview' out of @ARGV, hold them in @sv_argv.
    GetOptions(\%opt, qw(drive=s exec=s login ndrive persistent window));
    push(@sv_argv, '-drive', $opt{drive}) if $opt{drive};
    push(@sv_argv, map {"-$_"} grep !/^(drive|exec)/, keys %opt);
    # Now dig the tag out of @ARGV, wherever it might happen to be.
    # Assume it's the last entry in ARGV matching a legal view-tag pattern.
    my $tag;
    for (my $i=$#ARGV; $i >= 0; $i--) {
	if ($ARGV[$i] !~ /^-|^\w+=.+/) {
	    $tag = splice(@ARGV, $i, 1);
	    last;
	}
    }
    Assert($tag);
    # If anything left in @ARGV has whitespace, quote it against its
    # journey through the "setview -exec" shell.
    for (@ARGV) {
	if (/\s/ && !/^(["']).*\1$/) {
	    $_ = qq('$_');
	}
    }
    # Last, run the setview cmd we've so laboriously constructed.
    unshift(@ARGV, '_inview');
    if ($opt{'exec'}) {
	push(@ARGV, '-_exec', qq("$opt{'exec'}"));
    }
    my $vwcmd = "$^X -S $0 @ARGV";
    # This next line is required because 5.004 and 5.6 do something
    # different with quoting on Windows, no idea exactly why or what.
    $vwcmd = qq("$vwcmd") if MSWIN && $] > 5.005;
    push(@sv_argv, '-exec', $vwcmd, $tag);
    # Prevent \'s from getting lost in subsequent interpolation.
    for (@sv_argv) { s%\\%/%g }
    # Hack - assume presence of $ENV{_} means we came from a UNIX-style
    # shell (e.g. MKS on Windows) so set quoting accordingly.
    my $cmd_exe = (MSWIN && !$ENV{_});
    Argv->new($^X, '-S', $0, 'setview', @sv_argv)->autoquote($cmd_exe)->exec;
}

## undocumented helper function for B<workon>
sub _inview {
    my $tag = (split(m%[/\\]%, $ENV{CLEARCASE_ROOT}))[-1];
    #Argv->new([$^X, '-S', $0, 'setcs'], [qw(-sync -tag), $tag])->system;

    # If -exec foo was passed to workon it'll show up as -_exec foo here.
    my %opt;
    GetOptions(\%opt, qw(_exec=s)) if grep /^-_/, @ARGV;

    my @cs = Argv->new([$^X, '-S', $0, 'catcs'], [qw(--expand -tag), $tag])->qx;
    chomp @cs;
    my($iwd, $venv, @viewenv_argv);
    for (@cs) {
	if (/^##:Start:\s+(\S+)/) {
	    $iwd = $1;
	} elsif (/^##:ViewEnv:\s+(\S+)/) {
	    $venv = $1;
	} elsif (/^##:([A-Z]+=.+)/) {
	    push(@viewenv_argv, $1);
	}
    }

    # If an initial working dir is supplied cd to it, then check for
    # a viewenv file and require it if so.
    if ($iwd) {
	print "+ cd $iwd\n";
	# ensure $PWD is set to $iwd within req'd file
	require Cwd;
	Cwd::chdir($iwd) || warn "$iwd: $!\n";
	my($cli) = grep /^viewenv=/, @ARGV;
	$venv = (split /=/, $cli)[1] if $cli;
	$venv ||= '.viewenv.pl';
	if (-f $venv) {
	    local @ARGV = grep /^\w+=/, @ARGV;
	    push(@ARGV, @viewenv_argv) if @viewenv_argv;
	    print "+ reading $venv ...\n";
	    eval { require $venv };
	    warn Msg('W', $@) if $@;
	}
    }

    # A reasonable default for everybody.
    $ENV{CLEARCASE_MAKE_COMPAT} ||= 'gnu';

    for (grep /^(CLEARCASE_)?ARGV_/, keys %ENV) { delete $ENV{$_} }

    # Exec the default shell or the value of the -_exec flag.
    my $final = Argv->new;
    if (! $opt{_exec}) {
	if (MSWIN) {
	    $opt{_exec} = $ENV{SHELL} || $ENV{ComSpec} || $ENV{COMSPEC}
				|| (-x '/bin/sh.exe' ? '/bin/sh' : 'cmd');
	} else {
	    $opt{_exec} = $ENV{SHELL} || (-x '/bin/sh' ? '/bin/sh' : 'sh');
	}
    }
    #system("title workon $tag") if MSWIN;
    $final->prog($opt{_exec})->exec;
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1997-2002 David Boyce (dsbperl AT boyski.com). All rights
reserved.  This Perl program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), ClearCase::Wrapper

=cut
