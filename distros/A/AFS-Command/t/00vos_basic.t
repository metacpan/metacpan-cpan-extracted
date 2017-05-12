#
# $Id: 00vos_basic.t,v 11.1 2004/11/18 13:31:27 wpm Exp $
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
	$TestTotal = 77;
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

my @servers 		= ();
my @partitions		= ();
my $server_primary 	= "";
my $partition_primary 	= "";

#
# In order to have a predictable number of tests, we only use the
# first 2 server:/vicep* you specify.
#
foreach my $serverpart ( (split(/\s+/,$partition_list))[0..1] ) {

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
my $volname_readonly = $volname . ".readonly";

$Volnames{$volname}++;

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
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to create volume '$volname' on server '$server_primary:$partition_primary' " .
	"in cell '$cell'\n" . "Errors from vos command:\n" . $vos->errors());
}

#
# Examine it.
#
$result = $vos->examine
  (
   id			=> $volname,
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::Volume") ) {

    print "ok $TestCounter\n";
    $TestCounter++;
    my $errors = 0;

    #
    # First, sanity check the volume header.  There should be ONE of them only.
    #
    my @headers = $result->getVolumeHeaders();

    if ( $#headers == 0 ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn "Incorrect number of headers returned by getVolumeHeaders()\n";
	$errors++;
    }
    $TestCounter++;

    my $header = $headers[0];

    my $rwrite = 0;

    if ( ref $header && $header->isa("AFS::Object::VolumeHeader") ) {

	print "ok $TestCounter\n";
	$TestCounter++;

	#
	# This had better be on the server and partition we created
	# it on, and have the same name/id, obviously.
	#
	if ( $header->name() eq $volname ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Volume header 'name' is '" .
		 $header->name() . "', should be '$volname'\n");
	    $errors++;
	}
	$TestCounter++;

	if ( $header->partition() eq $partition_primary ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header 'partition' is '" .
		 $header->partition() . "', should be '$partition_primary'\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	if ( $header->server() eq $server_primary ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header 'server' is '" .
		 $header->server() . "', should be '$server_primary'\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	#
	# The volume has to be RW
	#
	if ( $header->type() eq 'RW' ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header 'type' is '" .
		 $header->type() . "', should be 'RW'\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	#
	# Check the volume IDs.  rwrite shold be numeric, ronly and
	# backup should b e 0.
	#
	$rwrite = $header->rwrite();

	if ( $rwrite =~ /^\d+$/ ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header 'rwrite' is '$rwrite', should be a numeric value\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	if ( $header->ronly() == 0 ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header 'ronly' is '" .
		 $header->ronly() . "', should be zero\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	if ( $header->backup() == 0 ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header 'backup' is '" .
		 $header->backup() . "', should be zero\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	#
	# This is a new volume, so access should be 0, and size 2
	#
	if ( $header->accesses() == 0 ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header 'accesses' is '" .
		 $header->access() . "', should be zero\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	if ( $header->size() == 2 ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header 'size' is '" .
		 $header->size() . "', should be 2\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	#
	# Both the update and creation times should be ctime values.
	# NOTE: This test may very well break if LANG is set, and
	# affects vos output syntax.  Note that in that case, we'll
	# need code in VOS.pm to deal with more generic time strings.
 	#
	foreach my $method ( qw( update creation ) ) {
	    if ( $header->$method() =~ /^\S+\s+\S+\s+\d+\s+\d{2}:\d{2}:\d{2}\s+\d{4}$/ ) {
		print "ok $TestCounter\n";
	    } else {
		warn("Volume header '$method' is '" .
		    $header->$method() . "', should be a ctime date value\n");
		print "not ok $TestCounter\n";
		$errors++;
	    }
	    $TestCounter++;
	}

	#
	# Finally, maxauota must be numeric, and status should be
	# 'online'
	#
	if ( $header->maxquota() =~ /^\d+$/ ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header 'maxquota' is '" .
		 $header->maxquota() . "', should be numeric\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	if ( $header->status() eq 'online' ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header 'status' is '" .
		 $header->status() . "', should be 'online'\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

    } else {
	warn("Invalid object -- getVolumeHeaders() did not return an " .
	     "AFS::Object::VolumeHeader object\n");
	print "not ok $TestCounter\n";
	$errors++;
    }

    #
    # Second, we check the VLDB entry for this volume.
    #
    my $vldbentry = $result->getVLDBEntry();

    if ( ref $vldbentry && $vldbentry->isa("AFS::Object::VLDBEntry") ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Invalid object type: getVLDBEntry() method call returned bogus data\n" .
	    Data::Dumper->Dump([$result],['result']));
    }
    $TestCounter++;

    if ( $vldbentry->rwrite() =~ /^\d+$/ ) {
	print "ok $TestCounter\n";
    } else {
	warn("VLDB Entry 'rwrite' is '" .
	     $vldbentry->rwrite() . "', should be a numeric value\n");
	print "not ok $TestCounter\n";
	$errors++;
    }
    $TestCounter++;

    #
    # This should match the rwrite ID found in the volume headers,
    # too.
    #
    if ( $vldbentry->rwrite() == $rwrite ) {
	print "ok $TestCounter\n";
    } else {
	warn("VLDB entry rwrite id (" . $vldbentry->rwrite() .
	     "), does not match volume header rwrite id ($rwrite)\n");
	print "not ok $TestCounter\n";
	$errors++;
    }
    $TestCounter++;

    my @vldbsites = $vldbentry->getVLDBSites();

    if ( $#vldbsites == 0 ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn "Incorrect number of sites returned by getVLDBSites()\n";
	$errors++;
    }
    $TestCounter++;

    my $vldbsite = $vldbsites[0];

    if ( ref $vldbsite && $vldbsite->isa("AFS::Object::VLDBSite") ) {

	print "ok $TestCounter\n";
	$TestCounter++;

	if ( $vldbsite->partition() eq $partition_primary ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("VLDB Site 'partition' is '" .
		 $vldbsite->partition() . "', should be '$partition_primary'\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	if ( $vldbsite->server() eq $server_primary ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume VLDB Site 'server' is '" .
		 $vldbsite->server() . "', should be '$server_primary'\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

    } else {
	warn("Invalid object -- getVLDBSites() did not return an " .
	     "AFS::Object::VLDBSite object\n");
	print "not ok $TestCounter..$TestTotal\n";
	$errors++;
    }

    die Data::Dumper->Dump([$result],['result']) if $errors;

} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to examine volume '$volname' in cell '$cell':\n" .
	$vos->errors());
}

#
# Create a backup, an verify that the changes in the examine output.
#
$result = $vos->backup
  (
   id			=> $volname,
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to backup volume '$volname' in cell '$cell':\n" .
	$vos->errors());
}

$result = $vos->examine
  (
   id			=> $volname,
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::Volume") ) {

    print "ok $TestCounter\n";
    $TestCounter++;
    my $errors = 0;

    my @headers = $result->getVolumeHeaders();

    if ( $#headers == 0 ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn "Incorrect number of headers returned by getVolumeHeaders()\n";
	$errors++;
    }
    $TestCounter++;

    my $header = $headers[0];

    my $rwrite = 0;

    if ( ref $header && $header->isa("AFS::Object::VolumeHeader") ) {

	print "ok $TestCounter\n";
	$TestCounter++;

	#
	# This time through, we're looking for just the things we
	# expect a vos backup to change, and nothing else.
	#
	if ( $header->backup() =~ /^\d+/ ) {

	    print "ok $TestCounter\n";
	    $TestCounter++;

	    if ( $header->backup() > 0 ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("Volume header 'backup' is '" .
		     $header->backup() . "', should be non-zero\n");
	    }

	} else {

	    print "not ok $TestCounter\n";
	    $TestCounter++;
	    print "not ok $TestCounter\n";
	    warn("Volume header 'backup' is '" .
		 $header->backup() . "', should be numeric\n");
	    $errors++;

	}
	$TestCounter++;

    } else {
	warn("Invalid object -- getVolumeHeaders() did not return an " .
	     "AFS::Object::VolumeHeader object\n");
	print "not ok $TestCounter\n";
	$errors++;
    }

    die Data::Dumper->Dump([$result],['result']) if $errors;

} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to examine volume '$volname' in cell '$cell':\n" .
	$vos->errors());
}

#
# Now let's add the other replica sites, and release the volume.
#
for ( my $index = 0 ; $index <= $#servers ; $index++ ) {

    my $server = $servers[$index];
    my $partition = $partitions[$index];

    $result = $vos->addsite
      (
       id			=> $volname,
       server			=> $server,
       partition		=> $partition,
       cell			=> $cell,
      );
    if ( $result ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to addsite '$server:$partition' to volume '$volname' in cell '$cell':\n" .
	    $vos->errors());
    }

}

$result = $vos->listvldb
  (
   name				=> $volname,
   cell				=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::VLDB") ) {

    print "ok $TestCounter\n";
    $TestCounter++;
    my $errors = 0;

    my @volnames = $result->getVolumeNames();

    if ( $#volnames == 0 ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn "Incorrect number of volnames returned by getVolumeNames()\n";
	$errors++;
    }
    $TestCounter++;

    my $volname_queried = $volnames[0];

    if ( $volname eq $volname_queried ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn "Volname returned by query ($volname_queried) does not match that specified ($volname)\n";
	$errors++;
    }
    $TestCounter++;

    #
    # If either of the above failed, we can't go on...
    #
    die Data::Dumper->Dump([$result],['result']) if $errors;

    my $vldbentry = $result->getVLDBEntryByName($volname);

    if ( ref $vldbentry && $vldbentry->isa("AFS::Object::VLDBEntry") ) {

	print "ok $TestCounter\n";
	$TestCounter++;

	my $rwrite = $vldbentry->rwrite();
	my $altentry = $result->getVLDBEntryById($rwrite);
	if ( ref $altentry && $altentry->isa("AFS::Object::VLDBEntry") &&
	     $altentry->rwrite() == $rwrite &&
	     $altentry->name() eq $volname ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	}
	$TestCounter++;

	my @vldbsites = $vldbentry->getVLDBSites();

	if ( $#vldbsites == ($#servers+1) ) {
	    print "ok $TestCounter\n";
	    $TestCounter++;
	} else {
	    print "not ok $TestCounter..$TestTotal\n";
	    die("Incorrect number of vldbsites returned by getVLDBSites\n" .
		"Should be " . ($#servers+1) . ", but is " . $#vldbsites . "\n");
	}

	for ( my $index = 0 ; $index <= $#vldbsites ; $index++ ) {

	    my $vldbsite = $vldbsites[$index];

	    my $serverindex = $index - 1;
	    $serverindex = 0 if $serverindex == -1;

	    if ( $vldbsite->server() eq $servers[$serverindex] ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("VLDB Site [$index] server is '" . $vldbsite->server() . "'\n" .
		     "Should be '" . $servers[$serverindex] . "'\n");
		$errors++;
	    }
	    $TestCounter++;

	    if ( $vldbsite->partition() eq $partitions[$serverindex] ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("VLDB Site [$index] partition is '" . $vldbsite->partition() . "'\n" .
		     "Should be '" . $partitions[$serverindex] . "'\n");
		$errors++;
	    }
	    $TestCounter++;

	    my $typeshould = $index == 0 ? "RW" : "RO";

	    if ( $vldbsite->type() eq $typeshould ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("VLDB Site [$index] type is '" . $vldbsite->type() . "'\n" .
		     "Should be '$typeshould'\n");
		$errors++;
	    }
	    $TestCounter++;

	    my $statusshould = $index == 0 ? "" : "Not released";

	    if ( $vldbsite->status() eq $statusshould ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("VLDB Site [$index] status is '" . $vldbsite->status() . "'\n" .
		     "Should be '$statusshould'\n");
		$errors++;
	    }
	    $TestCounter++;

	}

	die Data::Dumper->Dump([$vldbentry],['vldbentry']) if $errors;

    } else {
	warn("Invalid object -- getVLDBEntry() did not return an " .
	     "AFS::Object::VLDBEntry object\n");
	print "not ok $TestCounter\n";
	$errors++;
    }

    die Data::Dumper->Dump([$result],['result']) if $errors;

} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to listvldb volume '$volname' in cell '$cell':\n" .
	$vos->errors());
}

foreach my $force ( qw( none f force ) ) {

    $result = $vos->release
      (
       id				=> $volname,
       cell				=> $cell,
       (
	$force eq 'none' ? () :
	( $force		   	=> 1 )
       ),
      );
    if ( $result ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to release volume '$volname' in cell '$cell':\n" .
	    $vos->errors());
    }
    $TestCounter++;

}

#
# The volume is released, so now, let's examine the readonly, and make
# sure we get the correct volume headers.
#
$result = $vos->examine
  (
   id				=> $volname_readonly,
   cell				=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::Volume") ) {

    print "ok $TestCounter\n";
    $TestCounter++;
    my $errors = 0;

    my @headers = $result->getVolumeHeaders();

    if ( $#headers == $#servers ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Number of headers returned by getVolumeHeaders ($#headers) " .
	     "does not match number of servers ($#servers)\n");
	$errors++;
    }
    $TestCounter++;

    for ( my $index = 0 ; $index <= $#headers ; $index++ ) {

	my $header = $headers[$index];

	if ( $header->name() eq $volname_readonly ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Volume header [$index] 'name' is '" .
		 $header->name() . "', should be '$volname_readonly'\n");
	    $errors++;
	}
	$TestCounter++;

	if ( $header->partition() eq $partitions[$index] ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header [$index] 'partition' is '" .
		 $header->partition() . "', should be '$partitions[$index]'\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	if ( $header->server() eq $servers[$index] ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header [$index] 'server' is '" .
		 $header->server() . "', should be '$servers[$index]'\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

	if ( $header->type() eq 'RO' ) {
	    print "ok $TestCounter\n";
	} else {
	    warn("Volume header [$index] 'type' is '" .
		 $header->type() . "', should be 'RO'\n");
	    print "not ok $TestCounter\n";
	    $errors++;
	}
	$TestCounter++;

    }

    die Data::Dumper->Dump([$result],['result']) if $errors;

} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to examine volume '$volname' in cell '$cell':\n" .
	$vos->errors());
}

#
# Finally, let's clean up after ourselves.
#
for ( my $index = 0 ; $index <= $#servers ; $index++ ) {

    $result = $vos->remove
      (
       id			=> $volname_readonly,
       server			=> $servers[$index],
       partition		=> $partitions[$index],
       cell			=> $cell,
      );
    if ( $result ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to remove volume '$volname_readonly' from server '$servers[$index]', " .
	    "partition '$partitions[$index]', in cell '$cell':\n" .
	    $vos->errors());
    }
    $TestCounter++;

}

#
# Test the vos offline functionality, if supported.
#
if ( $vos->supportsOperation('offline') ) {

    foreach my $method ( qw(offline online) ) {

	$result = $vos->$method
	  (
	   id			=> $volname,
	   server		=> $servers[0],
	   partition		=> $partitions[0],
	   cell			=> $cell,
	  );
	if ( $result ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    die("Unable to $method volume '$volname' from server '$servers[0]', " .
		"partition '$partitions[0]', in cell '$cell':\n" .
		$vos->errors());
	}
	$TestCounter++;

	$result = $vos->examine
	  (
	   id			=> $volname,
	   cell			=> $cell,
	  );
	if ( ref $result ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    die("Unable to examine volume '$volname' on server '$servers[0]', " .
		"partition '$partitions[0]', in cell '$cell':\n" .
		$vos->errors());
	}
	$TestCounter++;

	my ($header) = $result->getVolumeHeaders();

	if ( $header->status() eq $method ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Volume '$volname' on server '$servers[0]', " .
		 "partition '$partitions[0]', in cell '$cell' was not $method");
	}
	$TestCounter++;

	if ( $header->attached() ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Volume '$volname' on server '$servers[0]', " .
		 "partition '$partitions[0]', in cell '$cell' does not appear to be attached");
	}
	$TestCounter++;

    }

} else {

    for ( my $index = 0 ; $index <= 7 ; $index++ ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    }

}

$result = $vos->remove
  (
   id				=> $volname,
   server			=> $servers[0],
   partition			=> $partitions[0],
   cell				=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    delete $Volnames{$volname};
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to remove volume '$volname' from server '$servers[0]', " .
	"partition '$partitions[0]', in cell '$cell':\n" .
	$vos->errors());
}
$TestCounter++;

#
# Finally, one we *expect* to fail...
#
$result = $vos->examine
  (
   id				=> $volname,
   cell				=> $cell,
  );
if ( $result ) {
    print "not ok $TestCounter..$TestTotal\n";
    die("Volume '$volname' in cell '$cell', still exists after a successful vos remove!!\n");
} elsif ( $vos->errors() =~ /VLDB: no such entry/i ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unexpected result from vos examine:\n" . $vos->errors());
}
$TestCounter++;

exit 0;

END {

    #$TestCounter--;
    #warn "Total number of tests == $TestCounter\n";

    if ( %Volnames ) {
	warn("The following temporary volumes were created, and may be left over:\n\t" .
	     join("\n\t",sort keys %Volnames) . "\n");
    }
}
