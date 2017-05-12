#
# $Id: 20fs_basic.t,v 11.1 2004/11/18 13:31:37 wpm Exp $
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
	   );

BEGIN {
    require "./util/lib/parse_config";
}

BEGIN {
    $| = 1;
    if ( $AFS::Command::Tests::Config{AFS_COMMAND_DISABLE_TESTS} =~ /\bfs\b/ ) {
	$TestTotal = 0;
    } elsif ( $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} eq 'your.cell.name' ) {
	$TestTotal = 0;
    } else {
	$TestTotal = 124;
    }
    print "1..$TestTotal\n";
}

END {print "not ok 1\n" unless $Loaded;}
use AFS::Command::FS 1.99;
$Loaded = 1;
$TestCounter = 1;
print "ok $TestCounter\n";
$TestCounter++;

exit 0 unless $TestTotal;

my $cell = $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_CELLNAME\n";
};

my $pathafs = $AFS::Command::Tests::Config{AFS_COMMAND_PATHNAME_AFS} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_PATHNAME_AFS\n";
};

my $pathnotafs = "/var/tmp";

my $pathbogus = "/this/does/not/exist";

my $binary = $AFS::Command::Tests::Config{AFS_COMMAND_BINARY_FS} || 'fs';

#
# If the constructor fails, we're doomed.
#
my $fs = AFS::Command::FS->new
  (
   command		=> $binary,
  );
if ( ref $fs && $fs->isa("AFS::Command::FS") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to instantiate AFS::Command::FS object\n";
}

#
# fs checkservers
#
my $result = $fs->checkservers();
if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call checkservers:\n" . $fs->errors();
}

my $servers = $result->servers();
if ( ref $servers eq 'ARRAY' ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter\n";
    warn("Not an ARRAY ref: fs->checkservers->servers()\n");
}
$TestCounter++;

$result = $fs->checkservers
  (
   interval		=> 0,
  );
if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call checkservers:\n" . $fs->errors();
}

if ( $result->interval() =~ /^\d+$/ ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter\n";
    warn("Not an integer: fs->checkservers->interval()\n");
}
$TestCounter++;

#
# All the common _paths_method methods
#
my $paths = [ $pathafs, $pathnotafs, $pathbogus ];

my %pathops =
  (
   diskfree			=> [qw( volname total used avail percent )],
   examine			=> [qw( volname total avail id quota )],
   listquota			=> [qw( volname quota used percent partition )],
   quota			=> [qw( percent )],
   storebehind			=> [qw( asynchrony )],
   whereis			=> [qw( hosts )],
   whichcell			=> [qw( cell )],
  );

foreach my $pathop ( keys %pathops ) {

    unless ( $fs->supportsOperation($pathop) ) {
	my $total = scalar(@{$pathops{$pathop}}) + 2;
	$total++ if $pathop eq 'storebehind';
	for ( my $count = 1 ; $count <= $total ; $count++ ) {
	    print "ok $TestCounter # skipping...  fs->$pathop() is unsupported \n";
	    $TestCounter++;
	}
	next;
    }

    $result = $fs->$pathop
      (
       ( $pathop eq 'storebehind' ? 'files' : 'path' ) => $paths,
      );
    if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to call fs->$pathop:\n" . $fs->errors() .
	    Data::Dumper->Dump([$fs],['fs']));
    }

    if ( $pathop eq 'storebehind' ) {
	if ( defined($result->asynchrony()) ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Result object for fs->storebehind() has no attr 'asynchrony'\n");
	}
    } else {
	print "ok $TestCounter\n";
    }
    $TestCounter++;

    foreach my $pathname ( @$paths ) {

	my $path = $result->getPath($pathname);
	if ( ref $path && $path->isa("AFS::Object::Path") ) {

	    print "ok $TestCounter\n";
	    $TestCounter++;

	    if ( $pathname eq $pathafs ) {
		foreach my $attr ( @{$pathops{$pathop}} ) {
		    if ( defined($path->$attr()) ) {
			print "ok $TestCounter\n";
		    } else {
			print "not ok $TestCounter\n";
			warn("Path object for '$pathname' has no attr '$attr'\n");
		    }
		    $TestCounter++;
		}
	    } else {
		my $ok = 'ok';
		unless ( $path->error() ) {
		    warn("Pathname '$pathname' should have given an error()\n");
		    $ok = 'not ok';
		}
		for ( my $count = 1 ; $count <= scalar(@{$pathops{$pathop}}) ; $count++ ) {
		    print "$ok $TestCounter\n";
		    $TestCounter++;
		}
	    }

	} else {
	    warn("Unable to retreive path object for '$pathname' from fs->$pathop()\n");
	    for ( my $count = 1 ; $count <= (scalar(@{$pathops{$pathop}})+1) ; $count++ ) {
		print "not ok $TestCounter\n";
		$TestCounter++;
	    }
	}

    }

}

#
# fs exportafs -- this one is hard to really test, since we can't
# verify all the parsing unless it is actually supported and enabled,
# so fake it.
#
$result = $fs->exportafs
  (
   type			=> 'nfs',
  );
if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
    print "ok $TestCounter\n";
    $TestCounter++;

    if ( defined($result->enabled()) ) {
	print "ok $TestCounter\n";
	$TestCounter++;
	foreach my $attr ( qw(convert uidcheck submounts) ) {
	    if ( defined($result->$attr()) ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("No attr '$attr' for fs->exportafs results\n");
	    }
	    $TestCounter++;
	}
    } else {
	warn("Unable to determine if translator is enabled or not\n");
	for ( my $count = 1 ; $count <= 4 ; $count++ ) {
	    print "not ok $TestCounter\n";
	    $TestCounter++;
	}
    }

} elsif ( $fs->errors() =~ /not supported/ ) {
    for ( my $count = 1 ; $count <= 5 ; $count++ ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    }
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call exportafs:\n" . $fs->errors();
}

#
# fs getcacheparms
#
$result = $fs->getcacheparms();
if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call getcacheparms:\n" . $fs->errors();
}

foreach my $attr ( qw(avail used) ) {
    if ( defined($result->$attr()) ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Result object from getcacheparms has no attr '$attr'\n");
    }
    $TestCounter++;
}

#
# fs getcellstatus
#
$result = $fs->getcellstatus
  (
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call getcellstatus:\n" . $fs->errors();
}

my $cellobj = $result->getCell($cell);
if ( ref $cellobj && $cellobj->isa("AFS::Object::Cell") ) {

    print "ok $TestCounter\n";
    $TestCounter++;

    foreach my $attr ( qw(cell status) ) {
	if ( defined($cellobj->$attr()) ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Cell object for cell '$cell' has no attr '$attr'\n");
	}
	$TestCounter++;
    }

} else {
    warn("Unable to get cell object from fs->getcellstatus->getCell()\n");
    for ( my $count = 1 ; $count <= 3 ; $count++ ) {
	print "no ok $TestCounter\n";
	$TestCounter++;
    }
}

#
# fs getclientaddrs
#
if ( $fs->supportsOperation('getclientaddrs') ) {

    $result = $fs->getclientaddrs();
    if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die "Unable to call getclientaddrs:\n" . $fs->errors();
    }

    my $addresses = $result->addresses();
    if ( ref $addresses eq 'ARRAY' ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Result object for fs->getclientaddrs() has no attr 'addresses'\n");
    }
    $TestCounter++;

} else {
    for ( my $count = 1 ; $count <= 2 ; $count++ ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    }
}

#
# fs getcrypt
#
if ( $fs->supportsOperation('getcrypt') ) {

    $result = $fs->getcrypt();
    if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die "Unable to call getcrypt:\n" . $fs->errors();
    }

    if ( defined($result->crypt()) ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Result object for fs->getcrypt() has no attr 'crypt'\n");
    }
    $TestCounter++;

} else {
    for ( my $count = 1 ; $count <= 2 ; $count++ ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    }
}

#
# fs getserverprefs
#
$result = $fs->getserverprefs();
if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call getserverprefs:\n" . $fs->errors();
}

my ($server) = $result->getServers();
if ( ref $server && $server->isa("AFS::Object::Server") ) {

    print "ok $TestCounter\n";
    $TestCounter++;

    foreach my $attr ( qw(server preference) ) {
	if ( defined($server->$attr()) ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Server object from fs->getserverprefs() has no attr '$attr'\n");
	}
	$TestCounter++;
    }

} else {
    warn("Unable to get server object from fs->getserverprefs result\n");
    for ( my $count = 1 ; $count <= 3 ; $count++ ) {
	print "not ok $TestCounter\n";
	$TestCounter++;
    }
}

#
# fs listacl -- tested in 40fs_complex.t
#

#
# fs listaliases -- not tested, but I supposed we could define an
# alias, and then remove it.  Might be kinda intrusive, though.
#

#
# fs listcells
#
$result = $fs->listcells();
if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call listcells:\n" . $fs->errors();
}

$cellobj = $result->getCell($cell);
if ( ref $cellobj && $cellobj->isa("AFS::Object::Cell") ) {

    print "ok $TestCounter\n";
    $TestCounter++;

    if ( $cellobj->cell() eq $cell ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Cell returned by fs->listcells->getCell() doesn't match '$cell'\n");
    }
    $TestCounter++;

    my $servers = $cellobj->servers();
    if ( ref $servers eq 'ARRAY' ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to get list of servers from fs->listcells->getCell()\n");
    }
    $TestCounter++;

} else {
    warn("Unable to get cell objects for cell '$cell' from fs->listcells()\n");
    for ( my $count = 1 ; $count <= 3 ; $count++ ) {
	print "not ok $TestCounter\n";
	$TestCounter++;
    }
}

#
# fs lsmount -- tested in 40fs_complex.t
#

#
# fs sysname
#
$result = $fs->sysname();
if ( ref $result && $result->isa("AFS::Object::CacheManager") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call sysname:\n" . $fs->errors();
}

if ( defined($result->sysname()) ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter\n";
    warn("Result object for fs->sysname() has no attr 'sysname'\n");
}
$TestCounter++;

END {
    #$TestCounter--;
    #warn "Total number of tests == $TestCounter\n";
}
