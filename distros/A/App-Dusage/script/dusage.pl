#!/usr/bin/perl -w

# dusage.pl -- gather disk usage statistics
# Author          : Johan Vromans
# Created On      : Sun Jul  1 21:49:37 1990
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jan  4 11:43:38 2021
# Update Count    : 206
# Status          : OK
#
# This program requires Perl version 5.10.1, or higher.

################ Common stuff ################

use strict;

my $my_name = qw( dusage );
our $VERSION = "2.01";

################ Command line parameters ################

use Getopt::Long 2.13;

my $verbose = 0;                # verbose processing
my $noupdate = 1;		# do not update the control file
my $retain = 0;			# retain emtpy entries
my $gather = 0;			# gather new data
my $follow = 0;			# follow symlinks
my $allfiles = 0;		# also report file stats
my $allstats = 0;		# provide all stats

my $root;			# root of all eveil
my $prefix;			# root prefix for reporting
my $data;			# the data, or how to get it
my $table;

our $runtype;			# file or directory

# Development options (not shown with -help).
my $debug = 0;                  # debugging
my $trace = 0;                  # trace (show process)
my $test = 0;                   # test (no actual processing)

unless ( caller ) {
    app_options();

    # Options post-processing.
    $trace |= ($debug || $test);
}

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || '/usr/tmp';

################ The Process ################

my @targets = ();		# directories to process, and more
my %newblocks = ();		# du values
my %oldblocks = ();		# previous values
my @excludes = ();		# excluded entries
my %testglob;

unless ( caller ) {
    parse_ctl();			# read the control file
    gather();				# gather new info
    report_and_update();		# write report and update control file
}

################ Subroutines ################

sub parse_ctl {

    # Parsing the control file.
    #
    # This file contains the names of the (sub)directories to tally,
    # and the values dereived from previous runs.
    # The names of the directories are relative to the $root.
    # The name may contain '*' or '?' characters, and will be globbed if so.
    # An entry starting with ! is excluded.
    #
    # To add a new dir, just add the name. The special name '.' may 
    # be used to denote the $root directory. If used, '-p' must be
    # specified.
    #
    # Upon completion:
    #  - %oldblocks is filled with the previous values,
    #    colon separated, for each directory.
    #  - @targets contains a list of names to be looked for. These include
    #    break indications and globs info, which will be stripped from
    #    the actual search list.

    my $tb;			# ctl file entry

    open( my $ctl, "<", $table )
      or die ("Cannot open control file $table: $!\n");

    while ( $tb = <$ctl> ) {

	# For testing. Please ignore.
	if ( $tb =~ /^# glob\s+(.*?)\s+->\s+(.+)/ ) {
	    $testglob{$1} = $2;
	}

	next if $tb =~ /^#/;
	next unless $tb =~ /\S/;

	# syntax:    <dir><TAB><size>:<size>:....
	# possible   <dir>

	if ( $tb =~ /^-(?!\t)(.*)/ ) { # break
	    push (@targets, "-$1");
	    print STDERR ("tb: *break* $1\n") if $debug;
	    next;
	}

	if ( $tb =~ /^!(.*)/ ) { # exclude
	    push (@excludes, $1);
	    push (@targets, "!".$1);
	    print STDERR ("tb: *excl* $1\n") if $debug;
	    next;
	}

	my @blocks;
	my $name;
	if ( $tb =~ /^(.+)\t([\d:]+)/ ) {
	    $name = $1;
	    @blocks = split (/:/, $2 . "::::::::", -1);
	    $#blocks = 7;
	}
	else {
	    chomp ($name = $tb);
	    @blocks = ("") x 8;
	}

	if ( $name eq "." ) {
	    if ( $root eq "" ) {
		warn ("Warning: \".\" in control file w/o \"-p path\" - ignored\n");
		next;
	    }
	    $name = $root;
	}
	else {
	    $name = $prefix . $name unless ord($name) == ord ("/");
	}

	# Check for globs ...
#	if ( ($gather|$debug|%testglob) && $name =~ /\*|\?/ ) {
	if ( $name =~ /\*|\?/ ) {
	    print STDERR ("glob: $name\n") if $debug;
	    my @glob = $testglob{$name}
	      ? split( ' ', $testglob{$name} )
	      : glob($name);
	    foreach my $n ( @glob ) {
		next unless $allfiles || -d $n;
		# Globs never overwrite existing entries
		unless ( defined $oldblocks{$n} ) {
		    $oldblocks{$n} = ":::::::";
		    push (@targets, " $n");
		}
		print STDERR ("glob: -> $n\n") if $debug;
	    }
	    # Put on the globs list, and terminate this entry
	    push (@targets, "*$name");
	    next;
	}

	push (@targets, " $name");

	# Entry may be rewritten (in case of globs)
	$oldblocks{$name} = join (":", @blocks[0..7]);

	print STDERR ("tb: $name\t$oldblocks{$name}\n") if $debug;
    }

    if ( @excludes ) {
	foreach my $excl ( @excludes ) {
	    my $try = ord($excl) == ord("/") ? " $excl" : " $prefix$excl";
	    @targets = grep ($_ ne $try, @targets);
	}
	print STDERR ("targets after exclusion: @targets\n") if $debug;
    }

    close ($ctl);
}

sub gather {

    # Build a targets match string, and an optimized list of
    # directories to search. For example, if /foo and /foo/bar are
    # both in the list, only /foo is used since du will produce the
    # statistics for /foo/bar as well.

    my %targets = ();
    my @list = ();
    # Get all entries, and change the / to nul chars.
    my @a = map { s;/;\0;g ? ($_) : ($_) }
      # Only dirs unless $allfiles
      grep { $allfiles || -d }
	# And only the file/dir info entries
	map { /^ (.*)/ ? $1 : () } @targets;

    my $prev = "\0\0\0";
    foreach my $name ( sort (@a) ) {
	# If $prev is a complete prefix of $name, we've already got a
	# better one in the tables.
	unless ( index ($name, $prev) == 0 ) {
	    # New test arg -- including the trailing nul.
	    $prev = $name . "\0";
	    # Back to normal.
	    $name =~ s;\0;/;g;
	    # Register.
	    push (@list, $name);
	    $targets{$name}++;
	}

    }

    if ( $debug ) {
	print STDERR ("dirs: ", join(" ",sort(keys(%targets))),"\n",
		      "list: @list\n");
    }

    my $fh = do { local(*FH); *FH };
    my $out = do { local(*FH); *FH };
    if ( !$gather && defined $data ) {		# we have a data file
	print STDERR ("Using data from $data\n" ) if $debug;
	open( $fh, "<", $data )
	  or die ("Cannot get data from $data: $!\n");
	undef $data;
	$gather++;
    }
    else {
	my @du = ("du");
	push (@du, "-a") if $allfiles;
	push( @du, "-L" ) if $follow;
	push (@du, "--", @list);
	print STDERR ("Gather data from @du\n" ) if $debug;
	my $ret = open( $fh, "-|" ) || exec @du;
	die ("Cannot get input from -| @du\n") unless $ret;
	if ( defined $data ) {
	    open($out, ">", $data) or die ("Cannot create $data: $!\n");
	}
    }

    # Process the data. If a name is found in the target list,
    # %newblocks will be set to the new blocks value.
    %targets = map { $_ => 1 } @targets;
    my %excludes = map { $prefix.$_ => 1 } @excludes;
    my $du;
    while ( defined ($du = <$fh>) ) {
	print $out $du if defined $data;
	chomp ($du);
	my ($blocks, $name) = split (/\t/, $du);
	if ( exists ($targets{" ".$name}) && !exists ($excludes{$name}) ) {
	    # Tally and remove entry from search list.
	    $newblocks{$name} = $blocks;
	    print STDERR ("du: $name $blocks\n") if $debug;
	    delete ($targets{" ".$name});
	}
    }
    close ($fh);
    close ($out) if defined $data;
}

# Variables used in the formats.
our $date;			# date
our $name;			# name
our $subtitle;			# subtitle
our @a;
our $d_day;			# day delta
our $d_week;			# week delta
our $blocks;

sub report_and_update {
    my $rep = shift || \*STDOUT;
    select($rep);

    my $ctl;

    # Prepare update of the control file
    unless ( $noupdate ) {
	unless ( open( $ctl, ">", $table ) ) {
	    warn ("Warning: cannot update control file $table [$!] - continuing\n");
	    $noupdate = 1;
	}
    }

    # For testing. Please ignore.
    if ( !$noupdate && %testglob ) {
	foreach my $k ( sort keys %testglob ) {
	    print $ctl "# glob $k -> $testglob{$k}\n";
	}
    }

    if ( $allstats ) {
	$^ = "all_hdr";
	$~ = "all_out";
    }
    else {
	$^ = "std_hdr";
	$~ = "std_out";
    }

    $date = localtime;
    $subtitle = "";

    # In one pass the report is generated, and the control file rewritten.

    foreach my $nam ( @targets ) {

	if ( $nam =~ /^-(.*)/ ) {
	    $subtitle = $1;
	    print $ctl ($nam, "\n") unless $noupdate;
	    print STDERR ("tb: $nam\n") if $debug;
	    $- = 0;		# force page feed
	    next;
	}

	if ($nam  =~ /^\*\Q$prefix\E(.*)/o ) {
	    print $ctl ("$1\n") unless $noupdate;
	    print STDERR ("tb: $1\n") if $debug;
	    next;
	}

	if ( $nam =~ /^ (.*)/ ) {
	    $nam = $1
	}
	else {
	    print $ctl $nam, "\n" unless $noupdate;
	    print STDERR ("tb: $nam\n") if $debug;
	    next;
	}

	print STDERR ("Oops1 $nam\n")
	  unless $nam =~ /\*/ || defined $oldblocks{$nam};
	print STDERR ("Oops2 $nam\n")
	  unless $nam =~ /\*/ || defined $newblocks{$nam};

	@a = split (/:/, $oldblocks{$nam} . ":::::::", -1);
	$#a = 7;
	unshift (@a, $newblocks{$nam}) if $gather;
	$nam = "." if $nam eq $root;
	$nam = $1 if $nam =~ /^\Q$prefix\E(.*)/o;
	warn ("Warning: ", scalar(@a), " entries for $nam\n")
	  if $debug && @a != 9;

	# check for valid data
	my $try = join (":", @a[0..7]);
	if ( $try eq ":::::::" ) {
	    if ($retain) {
		@a = ("") x 8;
	    }
	    else {
		# Discard.
		print STDERR ("--: $nam\n") if $debug;
		next;
	    }
	}

	my $line = "$nam\t$try\n";
	print $ctl ($line) unless $noupdate;
	print STDERR ("tb: $line") if $debug;

	$blocks = $a[0];
	unless ( $allstats ) {
	    $d_day = $d_week = "";
	    if ( $blocks ne "" ) {
		if ( $a[1] ne "" ) { # daily delta
		    $d_day = $blocks - $a[1];
		    $d_day = "+" . $d_day if $d_day > 0;
		}
		if ( $a[7] ne "" ) { # weekly delta
		    $d_week = $blocks - $a[7];
		    $d_week = "+" . $d_week if $d_week > 0;
		}
	    }
	}

 	# Using a outer my variable that is aliased in a loop within a
 	# subroutine still doesn't work...
	$name = $nam;
	write($rep);
    }

    # Close control file, if opened
    close ($ctl) unless $noupdate;
}

################ Option Processing ################

sub app_options {
    my $help = 0;               # handled locally
    my $ident = 0;              # handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    Getopt::Long::Configure qw(bundling);
    GetOptions(
	       'allstats|a'	=> \$allstats,
	       'allfiles|f'	=> \$allfiles,
	       'gather|g'	=> \$gather,
	       'follow|L'	=> \$follow,
	       'retain|r'	=> \$retain,
	       'update!'	=> sub { $noupdate = !$_[1] },
	       'u'		=> sub { $noupdate = !$_[1] },
	       'data|i=s'	=> \$data,
	       'dir|p=s'	=> \$root,
	       'verbose|v'	=> \$verbose,
	       'trace'		=> \$trace,
	       'help|h|?'	=> \$help,
	       'man'		=> \$man,
	       'debug'		=> \$debug,
	      ) or $pod2usage->(2);

    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_name $VERSION\n");
    }
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }
    if ( @ARGV > 1 ) {
	$pod2usage->(2);
    }

    if ( defined $root ) {
	$root =~ s;/+$;;;
	$prefix = $root . "/";
	$root = "/" if $root eq "";
    }
    else {
	$prefix = $root = "";
    }

    $table = @ARGV ? shift(@ARGV) : $prefix . ".du.ctl";
    $runtype = $allfiles ? "file" : "directory";
    $noupdate |= !$gather && ! $data && ! -s $data;

    if ( $debug ) {
	print STDERR
	  ("$my_name $VERSION\n",
	   "Options:",
	   $debug     ? " debug"  : ""	 , # silly, isn't it...
	   $noupdate  ? " no"	  : " "	 , "update",
	   $retain    ? " "	  : " no", "retain",
	   $gather    ? " "	  : " no", "gather",
	   $allstats  ? " "	  : " no", "allstats",
	   "\n",
	   "Root = \"$root\", prefix = \"$prefix\"\n",
	   "Control file = \"$table\"\n",
	   $data ? (($gather ? "Output" : "Input") ." data = \"$data\"\n") : "",
	   "Run type = \"$runtype\"\n",
	   "\n");
    }
}

# Formats.

format std_hdr =
Disk usage statistics@<<<<<<<<<<<<<<<<<<<<<@<<<<<<<<<<<<<<<
$subtitle, $date

  blocks    +day     +week  @<<<<<<<<<<<<<<<
$runtype
--------  -------  -------  --------------------------------
.

format std_out =
@>>>>>>> @>>>>>>> @>>>>>>>  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$blocks, $d_day, $d_week, $name
.

format all_hdr =
Disk usage statistics@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<           @<<<<<<<<<<<<<<<
$subtitle, $date

 --0--    --1--    --2--    --3--    --4--    --5--    --6--    --7--   @<<<<<<<<<<<<<<<
$runtype
-------  -------  -------  -------  -------  -------  -------  -------  --------------------------------
.
format all_out =
@>>>>>> @>>>>>>> @>>>>>>> @>>>>>>> @>>>>>>> @>>>>>>> @>>>>>>> @>>>>>>>  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<..
@a, $name
.

1;
