#
# $Id: 01vos_dumprestore.t,v 11.1 2004/11/18 13:31:30 wpm Exp $
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

# print STDERR Data::Dumper->Dump([$vos],['vos']);

use strict;
use English;
use Data::Dumper;

use vars qw(
	    $TestCounter
	    $TestTotal
	    $Loaded
	    %Volnames
	   );

BEGIN {
    require "./util/lib/parse_config";
}

BEGIN {
    $| = 1;
    if ( $AFS::Command::Tests::Config{AFS_COMMAND_DISABLE_TESTS} =~ /\bvos\b/ ) {
	$TestTotal = 0;
    } elsif ( $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} eq 'your.cell.name' ) {
	$TestTotal = 0;
    } else {
	$TestTotal = 19;
    }
    print "1..$TestTotal\n";
}

END {print "not ok 1\n" unless $Loaded;}
use AFS::Command::VOS 1.99;
$Loaded = 1;
$TestCounter = 1;
print "ok $TestCounter\n";
$TestCounter++;

exit 0 unless $TestTotal;

#
# First, let's get all the config data we need.
#
my $volname_prefix = $AFS::Command::Tests::Config{AFS_COMMAND_VOLNAME_PREFIX} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_VOLNAME_PREFIX\n";
};

my $cell = $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_CELLNAME\n";
};

my $partition_list = $AFS::Command::Tests::Config{AFS_COMMAND_PARTITION_LIST} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_PARTITION_LIST\n";
};

my $binary = $AFS::Command::Tests::Config{AFS_COMMAND_BINARY_VOS} || 'vos';

my %enabled =
  (
   gzip		=> $AFS::Command::Tests::Config{AFS_COMMAND_GZIP_ENABLED},
   bzip2	=> $AFS::Command::Tests::Config{AFS_COMMAND_BZIP2_ENABLED},
  );
$enabled{gunzip} = $enabled{gzip};
$enabled{bunzip2} = $enabled{bzip2};

my $dumpfilter = $AFS::Command::Tests::Config{AFS_COMMAND_DUMP_FILTER};
my $restorefilter = $AFS::Command::Tests::Config{AFS_COMMAND_RESTORE_FILTER};

my $tmproot = $AFS::Command::Tests::Config{AFS_COMMAND_TMP_ROOT};

my @servers 		= ();
my @partitions		= ();
my $server_primary 	= "";
my $partition_primary 	= "";

foreach my $serverpart ( split(/\s+/,$partition_list) ) {

    my ($server,$partition) = split(/:/,$serverpart);

    unless ( $server && $partition ) {
	print "not ok $TestCounter..$TestTotal\n";
	die "Invalid server:/partition specification: '$serverpart'\n";
    }

    $server_primary = $server unless $server_primary;
    $partition_primary = $partition unless $partition_primary;

    push(@servers,$server);
    push(@partitions,$partition);

}

#
# If the constructor fails, we're doomed.
#
my $vos = AFS::Command::VOS->new
  (
   command		=> $binary,
  );
if ( ref $vos && $vos->isa("AFS::Command::VOS") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to instantiate AFS::Command::VOS object\n";
}

#
# Create a volume.
#
my $volname = $volname_prefix . $PID;

my $result = $vos->create
  (
   server		=> $server_primary,
   partition		=> $partition_primary,
   name			=> $volname,
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
    $Volnames{$volname}++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to create volume '$volname' on server '$server_primary:$partition_primary'" .
	"in cell '$cell'\n" . "Errors from vos command:\n" . $vos->errors());
}

#
# OK, let's create a few dump files, in different ways.
#
# First, a vanilla dump, nothing special.
#
my %files =
  (
   raw			=> "$tmproot/$volname.dump",
   gzip			=> "$tmproot/$volname.dump.gz",
   bzip2		=> "$tmproot/$volname.dump.bz2",
  );
$files{gunzip} = $files{gzip};
$files{bunzip2} = $files{bzip2};

$result = $vos->dump
  (
   id			=> $volname,
   time			=> 0,
   file			=> $files{raw},
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter\n";
    warn("Unable to dump volume '$volname' in cell '$cell' to file '$files{raw}':\n" .
	 $vos->errors());
}
$TestCounter++;

foreach my $ctype ( qw(gzip bzip2) ) {

    unless ( $enabled{$ctype} ) {
	for ( my $count = 0 ; $count < 3 ; $count++ ) {
	    print "ok $TestCounter # skip Compression support for $ctype disabled\n";
	    $TestCounter++;
	}
	next;
    }

    #
    # Now, with *implicit* use of gzip (via the filename)
    #
    $result = $vos->dump
      (
       id			=> $volname,
       time			=> 0,
       file			=> $files{$ctype},
       cell			=> $cell,
      );
    if ( $result ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to dump volume '$volname' in cell '$cell' to file '$files{$ctype}':\n" .
	     $vos->errors());
    }
    $TestCounter++;

    #
    # Next, explicitly, using the gzip/bzip2 argument
    #
    $result = $vos->dump
      (
       id			=> $volname,
       time			=> 0,
       file			=> $files{raw},
       cell			=> $cell,
       $ctype			=> 4,
      );
    if ( $result ) {
	if ( -f $files{$ctype} ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Unexpected result: dump method did not produce an output file\n");
	}
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to dump volume '$volname' in cell '$cell' to file '$files{$ctype}':\n" .
	     $vos->errors());
    }
    $TestCounter++;

    #
    # Finally, when both are given.
    #
    $result = $vos->dump
      (
       id			=> $volname,
       time			=> 0,
       file			=> $files{$ctype},
       cell			=> $cell,
       $ctype			=> 4,
      );
    if ( $result ) {
	if ( -f $files{$ctype} ) {
	    print "ok $TestCounter\n";
	} elsif ( -f $files{raw} ) {
	    print "not ok $TestCounter\n";
	    warn("Unexpected result: dump method created file '$files{raw}', " .
		 "should have been '$files{$ctype}'\n" .
		 "(Both -file $files{$ctype}, and -$ctype specified)\n");
	} else {
	    print "not ok $TestCounter\n";
	    warn("Unexpected result: dump method did not produce an output file\n");
	}
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to dump volume '$volname' in cell '$cell' to file '$files{$ctype}':\n" .
	     $vos->errors());
	die Data::Dumper->Dump([$vos],['vos']);
    }
    $TestCounter++;

}

if ( $dumpfilter ) {

    $result = $vos->dump
      (
       id			=> $volname,
       time			=> 0,
       file			=> $files{raw},
       cell			=> $cell,
       filterout		=> [$dumpfilter],
      );
    if ( $result ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to dump volume '$volname' in cell '$cell' to file '$files{raw}':\n" .
	     $vos->errors());
    }
    $TestCounter++;

    my ($ctype) = ( $enabled{gzip} ? 'gzip' :
		    $enabled{bzip2} ? 'bzip2' : '' );

    if ( $ctype ) {

	$result = $vos->dump
	  (
	   id			=> $volname,
	   time			=> 0,
	   file			=> $files{$ctype},
	   cell			=> $cell,
	   filterout		=> [$dumpfilter],
	  );
	if ( $result ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Unable to dump volume '$volname' in cell '$cell' to file '$files{raw}':\n" .
		 "(Testing dump filter with compression)\n" .
		 $vos->errors());
	}

    } else {
	print "ok $TestCounter # skip Compression support disabled\n";
    }
    $TestCounter++;

} else {

    for ( my $count = 0 ; $count < 2 ; $count++ ) {
	print "ok $TestCounter # skip Dump filter tests disabled\n";
	$TestCounter++;
    }

}

#
# Finally, let's remove that volume, so we can reuse the name for the
# restore tests.
#
$result = $vos->remove
  (
   server		=> $server_primary,
   partition		=> $partition_primary,
   id			=> $volname,
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to remove volume '$volname' from server '$server_primary', " .
	"partition '$partition_primary', in cell '$cell':\n" .
	$vos->errors());
}



#
# If we made it this far, dump works fine.  Now let's test restore...
#
$result = $vos->restore
  (
   server		=> $server_primary,
   partition		=> $partition_primary,
   name			=> $volname,
   file			=> $files{raw},
   overwrite		=> 'full',
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $Volnames{$volname}++;
} else {
    print "not ok $TestCounter\n";
    warn("Unable to restore volume '$volname' from file '$files{raw}',\n" .
	 "to server '$server_primary', partition '$partition_primary', name '$volname':\n" .
	 $vos->errors());
}
$TestCounter++;

foreach my $ctype ( qw(gunzip bunzip2) ) {

    unless ( $enabled{$ctype} ) {
	for ( my $count = 0 ; $count < 1 ; $count++ ) {
	    print "ok $TestCounter # skip Compression support for $ctype disabled\n";
	    $TestCounter++;
	}
	next;
    }

    $result = $vos->restore
      (
       server			=> $server_primary,
       partition		=> $partition_primary,
       name			=> $volname,
       file			=> $files{$ctype},
       overwrite		=> 'full',
       cell			=> $cell,
      );
    if ( $result ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to restore volume '$volname' from file '$files{$ctype}',\n" .
	     "to server '$server_primary', partition '$partition_primary', name '$volname':\n" .
	     $vos->errors());
    }
    $TestCounter++;

}

if ( $restorefilter ) {

    $result = $vos->restore
      (
       server			=> $server_primary,
       partition		=> $partition_primary,
       name			=> $volname,
       file			=> $files{raw},
       overwrite		=> 'full',
       cell			=> $cell,
       filterin			=> [$restorefilter],
      );
    if ( $result ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to restore volume '$volname' from file '$files{raw}',\n" .
	     "using restore filter '$restorefilter', " .
	     "to server '$server_primary', partition '$partition_primary', name '$volname':\n" .
	     $vos->errors());
    }
    $TestCounter++;

    my ($ctype) = ( $enabled{gunzip} ? 'gunzip' :
		    $enabled{bunzip2} ? 'bunzip2' : '' );

    if ( $ctype ) {

	$result = $vos->restore
	  (
	   server		=> $server_primary,
	   partition		=> $partition_primary,
	   name			=> $volname,
	   file			=> $files{$ctype},
	   overwrite		=> 'full',
	   cell			=> $cell,
	   filterin		=> [$restorefilter],
	  );
	if ( $result ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Unable to restore volume '$volname' from file '$files{$ctype}',\n" .
		 "using restore filter '$restorefilter', " .
		 "to server '$server_primary', partition '$partition_primary', name '$volname':\n" .
		 $vos->errors());
	}

    } else {
	print "ok $TestCounter # skip Compression support disabled\n";
    }
    $TestCounter++;

} else {

    for ( my $count = 0 ; $count < 2 ; $count++ ) {
	print "ok $TestCounter # skip Restoreg filter tests disabled\n";
	$TestCounter++;
    }

}

$result = $vos->remove
  (
   server		=> $server_primary,
   partition		=> $partition_primary,
   id			=> $volname,
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
    delete $Volnames{$volname};
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to remove volume '$volname' from server '$server_primary', " .
	"partition '$partition_primary', in cell '$cell':\n" .
	$vos->errors());
}

exit 0;

END {

    #$TestCounter--;
    #warn "Total number of tests == $TestCounter\n";

    if ( %Volnames ) {
	warn("The following temporary volumes were created, and may be left over:\n\t" .
	     join("\n\t",sort keys %Volnames) . "\n");
    }
}
