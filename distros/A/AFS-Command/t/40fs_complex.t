#
# $Id: 40fs_complex.t,v 11.1 2004/11/18 13:31:41 wpm Exp $
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
    if ( $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} eq 'your.cell.name' ) {
	$TestTotal = 0;
    } else {
	$TestTotal = 44;	
    }
    print "1..$TestTotal\n";
}

END {print "not ok 1\n" unless $Loaded;}
use AFS::Command::PTS 1.99;
use AFS::Command::FS 1.99;
use AFS::Command::VOS 1.99;
$Loaded = 1;
$TestCounter = 1;
print "ok $TestCounter\n";
$TestCounter++;

exit 0 unless $TestTotal;

my $cell = $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_CELLNAME\n";
};

my $ptsgroup = $AFS::Command::Tests::Config{AFS_COMMAND_PTS_GROUP} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_PTS_GROUP\n";
};

my $ptsuser = $AFS::Command::Tests::Config{AFS_COMMAND_PTS_USER} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_PTS_USER\n";
};

my $ptsexisting = $AFS::Command::Tests::Config{AFS_COMMAND_PTS_EXISTING} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_PTS_EXISTING\n";
};

my $volname_prefix = $AFS::Command::Tests::Config{AFS_COMMAND_VOLNAME_PREFIX} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_VOLNAME_PREFIX\n";
};

my $partition_list = $AFS::Command::Tests::Config{AFS_COMMAND_PARTITION_LIST} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_PARTITION_LIST\n";
};

my $pathafs = $AFS::Command::Tests::Config{AFS_COMMAND_PATHNAME_AFS} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_PATHNAME_AFS\n";
};

my $pathnotafs = "/var/tmp";

my $pathbogus = "/this/does/not/exist";

my ($server,$partition) = split(/:/,(split(/\s+/,$partition_list))[0]);
unless ( $server && $partition ) {
    print "not ok $TestCounter..$TestTotal\n";
    die "Invalid server:/partition specification: '$partition_list'\n";
}

my %binary =
  (
   pts	=> ($AFS::Command::Tests::Config{AFS_COMMAND_BINARY_PTS} || 'pts'),
   vos	=> ($AFS::Command::Tests::Config{AFS_COMMAND_BINARY_VOS} || 'vos'),
   fs	=> ($AFS::Command::Tests::Config{AFS_COMMAND_BINARY_FS} || 'fs'),
  );

my $pts = AFS::Command::PTS->new
  (
   command		=> $binary{pts},
  );
if ( ref $pts && $pts->isa("AFS::Command::PTS") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to instantiate AFS::Command::PTS object\n";
}

my $vos = AFS::Command::VOS->new
  (
   command		=> $binary{vos},
  );
if ( ref $vos && $vos->isa("AFS::Command::VOS") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to instantiate AFS::Command::VOS object\n";
}

my $fs = AFS::Command::FS->new
  (
   command		=> $binary{fs},
  );
if ( ref $fs && $fs->isa("AFS::Command::FS") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to instantiate AFS::Command::FS object\n";
}

#
# Create a sample volume
#
my $volname = $volname_prefix . $PID;

$Volnames{$volname}++;

my $result = $vos->create
  (
   server		=> $server,
   partition		=> $partition,
   name			=> $volname,
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to create volume '$volname' on server '$server:$partition'" .
	"in cell '$cell'\n" . "Errors from vos command:\n" . $vos->errors());
}

#
# Mount it (several different ways)
#
my %mtpath =
  (
   rw			=> "$pathafs/$volname-rw",
   cell			=> "$pathafs/$volname-cell",
   plain		=> "$pathafs/$volname-plain",
  );

foreach my $type ( keys %mtpath ) {

    $result = $fs->mkmount
      (
       dir			=> $mtpath{$type},
       vol			=> $volname,
       (
	$type eq 'cell' ?
	( cell			=> $cell ) : ()
       ),
       (
	$type eq 'rw' ?
	( rw			=> 1 ) : ()
       ),
      );
    if ( $result ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to create mount point for $volname in $cell on $mtpath{$type}:" .
	    $fs->errors() .
	    Data::Dumper->Dump([$fs],['fs']));
    }

}

$result = $fs->lsmount
  (
   dir			=> [values %mtpath],
  );
if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to lsmount dirs:" .
	$fs->errors() .
	Data::Dumper->Dump([$fs],['fs']));
}

foreach my $type ( keys %mtpath ) {

    my $mtpath = $mtpath{$type};

    my $path = $result->getPath($mtpath);
    if ( ref $path && $path->isa("AFS::Object::Path") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to get Path object from result of fs->lsmount:\n" .
	    Data::Dumper->Dump([$result],['result']));
    }

    if ( defined($path->volname()) && $path->volname() eq $volname ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Volname in mtpt for $mtpath doesn't match '$volname':\n" .
	     Data::Dumper->Dump([$path],['path']));
    }
    $TestCounter++;

    if ( $type eq 'cell' ) {
	if ( defined($path->cell() && $path->cell() eq $cell ) ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Cell in mtpt for $mtpath doesn't match '$cell':\n" .
		 Data::Dumper->Dump([$path],['path']));
	}
    } else {
	print "ok $TestCounter\n";
    }
    $TestCounter++;

    if ( $type eq 'rw' ) {
	if ( defined($path->readwrite()) ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Mount point $mtpath{$type} doesn't appear to be rw:\n" .
		 Data::Dumper->Dump([$path],['path']));
	}
    } else {
	print "ok $TestCounter\n";
    }
    $TestCounter++;

}

$result = $fs->rmmount
  (
   dir			=> [ $mtpath{rw}, $mtpath{plain} ],
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to remove mount points for $volname in $cell:\n" .
	"[ $mtpath{rw}, $mtpath{plain} ]\n" .
	$fs->errors() .
	Data::Dumper->Dump([$fs],['fs']));
}

#
# This is the one mtpt we know will work.  The AFS pasth you gave me
# might NOT be in the same cell you specified, so using the
# cell-specific mount is necessary.
#
my $mtpath = $mtpath{cell};

#
# Set and test the ACL (several different ways)
#
my $paths = [ $mtpath, $pathnotafs, $pathbogus ];

$result = $fs->listacl
  (
   path			=> $paths,
  );
if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to listacl dirs:" .
	$fs->errors() .
	Data::Dumper->Dump([$fs],['fs']));
}

my %acl = ();

foreach my $pathname ( @$paths ) {

    my $path = $result->getPath($pathname);
    if ( ref $path && $path->isa("AFS::Object::Path") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to get Path object from result of fs->listacl:\n" .
	    Data::Dumper->Dump([$result],['result']));
    }

    if ( $pathname eq $mtpath ) {

	my $normal = $path->getACL();
	if ( ref $normal && $normal->isa("AFS::Object::ACL") ) {
	    print "ok $TestCounter\n";
	    $TestCounter++;
	} else {
	    print "not ok $TestCounter..$TestTotal\n";
	    die("Unable to get normal ACL object from Path object:\n" .
		Data::Dumper->Dump([$path],['path']));
	}

	my $negative = $path->getACL('negative');
	if ( ref $negative && $negative->isa("AFS::Object::ACL") ) {
	    print "ok $TestCounter\n";
	    $TestCounter++;
	} else {
	    print "not ok $TestCounter..$TestTotal\n";
	    die("Unable to get negative ACL object from Path object:\n" .
		Data::Dumper->Dump([$path],['path']));
	}

	%acl =
	  (
	   normal		=> $normal,
	   negative		=> $negative,
	  );

    } else {
	
	my $ok = 'ok';
	unless ( $path->error() ) {
	    warn("Pathname '$pathname' should have given an error()\n");
	    $ok = 'not ok';
	}
	for ( my $count = 1 ; $count <= 2 ; $count++ ) {
	    print "$ok $TestCounter\n";
	    $TestCounter++;
	}

    }

}

#
# Sadly, if the localhost is not in the same AFS cell as that being
# tested, the setacl command is guaranteed to fail, because the test
# pts entries will not be defined.
#
# Thus, we use a different, existing pts entry for these tests, and
# not the ones we created above.
#
my %entries =
  (
   $ptsexisting			=> 'rlidwk',
  );

foreach my $type ( qw(normal negative) ) {

    $result = $fs->setacl
      (
       dir			=> $mtpath,
       acl			=> \%entries,
       (
	$type eq 'negative' ?
	( negative		=> 1 ) : ()
       ),
      );
    if ( $result ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to setacl dirs:" .
	    $fs->errors() .
	    Data::Dumper->Dump([$fs],['fs']));
    }

    $result = $fs->listacl
      (
       path			=> $mtpath,
      );
    if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to listacl dirs:" .
	    $fs->errors() .
	    Data::Dumper->Dump([$fs],['fs']));
    }

    my $path = $result->getPath($mtpath);
    if ( ref $path && $path->isa("AFS::Object::Path") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to get Path object from result of fs->listacl:\n" .
	    Data::Dumper->Dump([$result],['result']));
    }

    my $acl = $path->getACL($type);
    if ( ref $acl && $acl->isa("AFS::Object::ACL") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to get ACL object from Path object:\n" .
	    Data::Dumper->Dump([$path],['path']));
    }

    foreach my $principal ( keys %entries ) {

	if ( $acl->getRights($principal) eq $entries{$principal} ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Unable to verify ACL entry for $principal:\n" .
		 Data::Dumper->Dump([$acl],['acl']));
	}
	$TestCounter++;

    }

}

#
# Unmount it
#
$result = $fs->rmmount
  (
   dir			=> $mtpath,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to remove mount points for $volname in $cell:\n" .
	$fs->errors() .
	Data::Dumper->Dump([$fs],['fs']));
}

#
# Blow away the volume
#
$result = $vos->remove
  (
   server		=> $server,
   partition		=> $partition,
   id			=> $volname,
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to remove volume '$volname' from server '$server:$partition'" .
	"in cell '$cell'\n" . "Errors from vos command:\n" . $vos->errors());
}
delete $Volnames{$volname};

END {

    #$TestCounter--;
    #warn "Total number of tests == $TestCounter\n";

    if ( %Volnames ) {
	warn("The following temporary volumes were created, and may be left over:\n\t" .
	     join("\n\t",sort keys %Volnames) . "\n");
    }

}
