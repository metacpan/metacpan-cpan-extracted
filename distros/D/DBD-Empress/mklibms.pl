#
# perl script to create the Empress libraries
#

use Env;

$EMPRESS_DIR=`pwd`;
chop($EMPRESS_DIR);

$DBVDLIB_DIR=$EMPRESS_DIR . "/lib";
$TMP_DIR=$DBVDLIB_DIR . "/tmp";

$LIBMS=$DBVDLIB_DIR . "/libms.a";

if ( $ENV{'MSPATH'} eq '' )
{
	print ("MSPATH is not set.  You must set MSPATH in your environment to\n");
	print ("point to the directory where Empress is installed.  Then, re-run\n");
	print ("this program.\n");
	exit 1;
}

print ("Using Empress version installed in \'$MSPATH\'.\n");

unless ( -d $DBVDLIB_DIR )
{
	print ("... directory $DBVDLIB_DIR not found.\n");
	exit 1;
}

if ( -d $TMP_DIR )
{
	print ("Removing old temporary directory $TMP_DIR...\n");
	&rmdirall ( $TMP_DIR  );
}

mkdir ($TMP_DIR, 0755) || die ("could not create directory $TMP_DIR");
chdir ( $TMP_DIR ) || die ("could not go into temporary directory $TMP_DIR");

# get the list of .a libraries in Empress and extract the object
# files in each.  

@LIST=split(/ +/, `$MSPATH/bin/empecc -echoline -noglobmain -noshlib x.c`);
@libLIST=grep(/\.a$/, @LIST);

print ("Extracting objects from libraries...");
foreach (@libLIST)
{
	system ("$MSPATH/sys_bin/arlib -extract $_");
}

# get a list of all the object files and put it into @objLIST

@objLIST=();
open (LSPIPE, "ls *.o|");
while (<LSPIPE>)
{
	chop;
	push(@objLIST, $_);
}
close (LSPIPE);
print ("... done.\n");

# remove the existing library if it exists

if ( -f $LIBMS )
{
	print ("Removing existing library file $LIBMS...");
	unlink( ($LIBMS) ) || die ("could not remove existing library file $LIBMS\n");
	print ("...done.\n");
}

# create a new library

print ("Archiving objects into new library...");

$nlist_max = 20;	# arbitary ... but some systems can't handle large lists
while ( $#objLIST >= 0 )
{
	# make list of objects.  we choose to break the entire list up
	# into a smaller list because some systems can't do it all at once.

	$nlist = ( $#objLIST + 1 > $nlist_max ) ? $nlist_max : $#objLIST + 1;
	$objectlist="";
	@objectlist=();

	for (1 .. $nlist)
	{
			$object = shift(@objLIST);
			$objectlist = $objectlist . " " . $object;
			push (@objectlist, $TMP_DIR . "/" . $object);
	}

	if ($#objectlist >= 0)		# -1 indicates no elements
	{
		system ("$MSPATH/sys_bin/arlib -replace $LIBMS $objectlist");
		$nunlink = unlink ( @objectlist );
		if ($nunlink != $#objectlist + 1)
		{
			print ("...only $nunlink of $#objectlist objects unlinked\n");
		}
	}
}

print ("...archive done.\n");

# create the library symbol table as necessary
system ("$MSPATH/sys_bin/ranlib $LIBMS");

chdir ("..");

# get rid of the temporary directory containing the object files...
print ("Removing temporary files & directories...");
&rmdirall( $TMP_DIR );
print ("...done.\n");

exit 0;

# -------------------------------------------------------------------------
# recursive directory and file removal
# -------------------------------------------------------------------------

sub rmdirall{
	my($dirname)=@_;

	my(@dirfilelist);
	my($dh_file);

	# get a list of all files in directory, excluding
	# '.' and '..'.

	opendir(dh_thisdir, $dirname);
	@dirfilelist = grep( !/^\.$|^\.\.$/, readdir(dh_thisdir));

	foreach $dh_file (@dirfilelist)
	{
		my @direlt = split("/", $dh_file);
		my $tmp = pop(@direlt);
		next if $tmp =~ /\.|\.\./;

		if ( -d $dh_file )
		{
# print ("removing directory $dh_file ...\n";
			&rmdirall($dh_file);
		}
		else
		{
# print ("removing file $dh_file ...\n";
			unlink $dh_file;
		}
	}
	rmdir $dirname;
}
