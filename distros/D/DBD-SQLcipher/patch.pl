#!/usr/bin/perl
use 5.006;
use strict;

######################################################
# This file is used to patch the DBI.pm in order to  #
# reserve the SQLcipher namespace in the DBI module  #
######################################################

# Because DBI generates a postamble at configure-time, we need
# the required version of DBI very early.
my $DBI_required = 1.57;
eval {
	require DBI;
};
if ( $@ or DBI->VERSION < $DBI_required ) {
	print "DBI $DBI_required is required to configure this module; please install it or upgrade your CPAN/CPANPLUS shell.\n";
	exit(1);
}

# rudimentary file copy, in order to reduce dependencies on extra modules...
sub fileCopy {
    my ($srcFile, $dstFile) = @_;
    open (FILE_IN, "<$srcFile") or die "Could not open $srcFile for reading";
    open (FILE_OUT,">$dstFile") or die "Could not open $dstFile for writing";
    print FILE_OUT while (<FILE_IN>);
    close(FILE_OUT);
    close(FILE_IN);
}

# Here we try to patch the DBI module to support SQLcipher namespace
my $DBI_ModulePath = (grep /auto\/DBI/, keys %::)[0];
$DBI_ModulePath =~ s/^_<//;
$DBI_ModulePath =~ s{auto/DBI/.*}{DBI.pm};
if ( !(-f $DBI_ModulePath) ){
    print "ERROR: Could not find DBI.pm\n";
    exit(1);
}

my $flagHasSQLcipher = 0;
if ( -w $DBI_ModulePath ){
    print "DBI Module: found at location $DBI_ModulePath\n";
    my $flagFound = 0;
    my $lineNum   = 0;
    open DBI_FILE, "<$DBI_ModulePath";
    while (my $line = <DBI_FILE>) {
	$lineNum++          if (0==$flagFound);
	$flagHasSQLcipher=1 if ($line =~ /sqlitecipher_/);
	$flagFound=1        if ($line =~ /sqlite_/);
    }
    close (DBI_FILE);
    if (0==$flagHasSQLcipher) {
	print "Patching DBI Module...\n";
	fileCopy $DBI_ModulePath, $DBI_ModulePath.".old";
	my $curLine = 0;
        open DBI_FILE_IN,  "<$DBI_ModulePath.old";
        open DBI_FILE_OUT, ">$DBI_ModulePath";
        while (<DBI_FILE_IN>) {
	    $curLine++;
	    if ($lineNum==$curLine) {
		my $line = $_;
		my $lNew = $line;
		$lNew =~ s/sqlite/sqlitecipher/;
		$lNew =~ s/DBD::SQLite/DBD::SQLcipher/;
		print DBI_FILE_OUT $lNew;
		print DBI_FILE_OUT $line;
	    } else {
		print DBI_FILE_OUT $_;
	    }
        }
        close (DBI_FILE_OUT);
        close (DBI_FILE_IN);
	print "Success.\n";
    } else {
	print "DBI Module was already patched.\n";
	print "Continuing...\n";
    }
} else {
    print "ERROR: No permissions to change DBI.pm\n";
    exit(1);
}

exit(0);
