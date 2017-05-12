#
# $Id: 30pts_basic.t,v 11.1 2004/11/18 13:31:39 wpm Exp $
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
    if ( $AFS::Command::Tests::Config{AFS_COMMAND_DISABLE_TESTS} =~ /\bpts\b/ ) {
	$TestTotal = 0;
    } elsif ( $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} eq 'your.cell.name' ) {
	$TestTotal = 0;
    } else {
	$TestTotal = 59;
    }
    print "1..$TestTotal\n";
}

END {print "not ok 1\n" unless $Loaded;}
use AFS::Command::PTS 1.99;
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

my $binary = $AFS::Command::Tests::Config{AFS_COMMAND_BINARY_PTS} || 'pts';

#
# If the constructor fails, we're doomed.
#
my $pts = AFS::Command::PTS->new
  (
   command		=> $binary,
  );
if ( ref $pts && $pts->isa("AFS::Command::PTS") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to instantiate AFS::Command::PTS object\n";
}

#
# pts listmax
#
my $result = $pts->listmax
  (
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::PTServer") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call listmax:\n" . $pts->errors();
}

foreach my $attr ( qw( maxuserid maxgroupid ) ) {
    if ( defined($result->$attr()) ) {
	my $id = $result->$attr();
	my $ok ='not ok';
	if ( $attr eq 'maxuserid' ) {
	    $ok = 'ok' if $id > 0;
	} else {
	    $ok = 'ok' if $id < 0;
	}
	print "$ok $TestCounter\n";
	if ( $ok eq 'not ok' ) {
	    warn("pts->listmax attr '$attr' has the wrong sign (+/-)\n");
	}
    } else {
	print "not ok $TestCounter\n";
	warn("pts->listmax result has no attr '$attr'\n");
    }
    $TestCounter++;
}

#
# pts creategroup, createuser, examine
#
foreach my $name ( $ptsgroup, $ptsuser ) {

    #
    # First, let's make sure our test IDs aren't defined, so we can
    # redefine them.
    #
    my $result = $pts->delete
      (
       nameorid		=> $name,
       cell		=> $cell,
      );
    if ( $result ) {
	print "ok $TestCounter\n";
    } elsif ( defined($pts->errors()) && $pts->errors() =~ /unable to find entry/ ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to delete the test pts id ($name), or verify it doesn't exist\n" .
	    Data::Dumper->Dump([$pts],['pts']));
    }
    $TestCounter++;

    my $method 	= $name eq $ptsgroup ? 'creategroup' : 'createuser';
    my $type	= $name eq $ptsgroup ? 'Group' : 'User';
    my $class 	= 'AFS::Object::' . ( $name eq $ptsgroup ? 'Group' : 'User' );

    $result = $pts->$method
      (
       name			=> $name,
       cell			=> $cell,
      );
    if ( ref $result && $result->isa("AFS::Object::PTServer") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die "Unable to call $method:\n" . $pts->errors();
    }

    my $byname 	= $name eq $ptsgroup ? 'getGroupByName' : 'getUserByName';
    my $byid	= $name eq $ptsgroup ? 'getGroupById' : 'getUserById';
    my $getall	= $name eq $ptsgroup ? 'getGroups' : 'getUsers';

    my $entry = $result->$byname($name);
    if ( ref $entry && $entry->isa($class) ) {

	print "ok $TestCounter\n";
	$TestCounter++;

	my $id = $entry->id();
	if ( $name eq $ptsgroup ) {
	    if ( $id < 0 ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("Group $name doesn't have a negative id as expected\n");
	    }
	} else {
	    if ( $id > 0 ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("User $name doesn't have a positive id as expected\n");
	    }
	}

	$TestCounter++;

	$entry = $result->$byid($id);
	if ( ref $entry && $entry->isa($class) ) {

	    print "ok $TestCounter\n";
	    $TestCounter++;

	    my $othername = $entry->name();
	    if ( $name eq $othername ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("PTS entry '$name' doesn't match '$othername'\n");
	    }
	    $TestCounter++;

	} else {

	    warn("Unable to retreive pts entry using $byid\n");
	    for ( my $count = 1 ; $count <= 2 ; $count++ ) {
		print "not ok $TestCounter\n";
		$TestCounter++;
	    }

	}

    } else {

	warn("Unable to retreive pts entry using $byname\n");
	for ( my $count = 1 ; $count <= 4 ; $count++ ) {
	    print "not ok $TestCounter\n";
	    $TestCounter++;
	}

    }

    ($entry) = $result->$getall();
    if ( ref $entry && $entry->isa($class) ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to retreive pts entry from pts->$method using $getall\n");
    }
    $TestCounter++;

    $result = $pts->examine
      (
       nameorid			=> $name,
       cell			=> $cell,
      );
    if ( ref $result && $result->isa("AFS::Object::PTServer") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die "Unable to call examine:\n" . $pts->errors();
    }

    ($entry) = $result->$getall();
    if ( ref $entry && $entry->isa($class) ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to retreive pts entry from pts->examine using $getall\n");
    }
    $TestCounter++;

    foreach my $attr ( qw( name id owner creator membership flags groupquota ) ) {
	if ( defined($entry->$attr()) ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Result from pts->examine of '$name' is missing attr '$attr'\n");
	}
	$TestCounter++;
    }

}

#
# pts chown, listowned
#
$result = $pts->chown
  (
   name			=> $ptsgroup,
   owner		=> $ptsuser,
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter\n";
    die("Unable to chown $ptsgroup to $ptsuser:" . $pts->errors());
}

$result = $pts->listowned
  (
   nameorid		=> $ptsuser,
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::PTServer") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call listowned:\n" . $pts->errors();
}

my ($user) = $result->getUsers();
if ( ref $user && $user->isa("AFS::Object::User") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to get User object from pts->listowned result\n");
}

my @owned = $user->getOwned();
if ( $#owned == 0 && $owned[0] eq $ptsgroup ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter\n";
    warn("User $ptsuser doesn't appear to own $ptsgroup\n");
}
$TestCounter++;

#
# pts adduser, membership
#
$result = $pts->adduser
  (
   user			=> $ptsuser,
   group		=> $ptsgroup,
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to call adduser:\n" . $pts->errors();
}

foreach my $name ( $ptsgroup, $ptsuser ) {

    $result = $pts->membership
      (
       nameorid		=> $name,
       cell		=> $cell,
      );
    if ( ref $result && $result->isa("AFS::Object::PTServer") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die "Unable to call membership:\n" . $pts->errors();
    }

    my $type	= $name eq $ptsgroup ? 'Group' : 'User';
    my $class 	= 'AFS::Object::' . ( $name eq $ptsgroup ? 'Group' : 'User' );
    my $getall	= $name eq $ptsgroup ? 'getGroups' : 'getUsers';

    my ($entry) = $result->$getall();
    if ( ref $entry && $entry->isa($class) ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to retreive pts entry from pts->membership using $getall\n");
    }
    $TestCounter++;

    my @membership = $entry->getMembership();
    if ( $#membership == 0 ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("The entry $name should only have a membership of 1, but has " . ($#membership+1) . "\n");
    }
    $TestCounter++;

    if ( $name eq $ptsgroup ) {
	if ( $membership[0] eq $ptsuser ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Group $ptsgroup should have $ptsuser as a member, but doesn't\n");
	}
    } else {
	if ( $membership[0] eq $ptsgroup ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("User $ptsuser should be a member of group $ptsgroup, but isn't\n");
	}
    }
    $TestCounter++;

}

#
# pts listentries
#
if ( $pts->supportsOperation('listentries') ) {

    foreach my $name ( $ptsgroup, $ptsuser ) {

	my $flag	= $name eq $ptsgroup ? 'groups' : 'users';
	my $type	= $name eq $ptsgroup ? 'Group' : 'User';
	my $class 	= 'AFS::Object::' . ( $name eq $ptsgroup ? 'Group' : 'User' );
	my $getentry	= $name eq $ptsgroup ? 'getGroupByName' : 'getUserByName';

	my $result = $pts->listentries
	  (
	   cell			=> $cell,
	   $flag 		=> 1,
	  );
	if ( ref $result && $result->isa("AFS::Object::PTServer") ) {
	    print "ok $TestCounter\n";
	    $TestCounter++;
	} else {
	    print "not ok $TestCounter..$TestTotal\n";
	    die "Unable to call listentries:\n" . $pts->errors();
	}

	my $entry = $result->$getentry($name);
	if ( ref $entry && $entry->isa($class) ) {

	    foreach my $attr ( qw(id owner creator) ) {
		if ( defined($entry->$attr()) ) {
		    print "ok $TestCounter\n";
		} else {
		    print "not ok $TestCounter\n";
		    warn("$type $name is missing the attr '$attr'\n");
		}
		$TestCounter++;
	    }

	} else {

	    warn("Unable to retreive pts entry from pts->listentries using $getentry\n");
	    for ( my $count = 1 ; $count <= 3 ; $count++ ) {
		print "not ok $TestCounter\n";
		$TestCounter++;
	    }

	}

    }

} else {
    for ( my $count = 1 ; $count <= 8 ; $count++ ) {
	print "ok $TestCounter\n";
	$TestCounter++;
    }
}

#
# Test membership error checking
#
$result = $pts->membership
  (
   nameorid		=> "ThisSurelyDoesNotExist",
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::PTServer") ) {
    print "not ok $TestCounter\n";
    warn("membership should have failed, not succeeded for 'ThisSurelyDoesNotExist'");
} else {
    print "ok $TestCounter\n";
}
$TestCounter++;

exit 0;

# END {
#     $TestCounter--;
#     warn "Total number of tests == $TestCounter\n";
# }
