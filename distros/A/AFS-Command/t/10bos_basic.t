#
# $Id: 10bos_basic.t,v 11.1 2004/11/18 13:31:35 wpm Exp $
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

# print STDERR Data::Dumper->Dump([$bos],['bos']);

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
    if ( $AFS::Command::Tests::Config{AFS_COMMAND_DISABLE_TESTS} =~ /\bbos\b/ ) {
	$TestTotal = 0;
    } elsif ( $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} eq 'your.cell.name' ) {
	$TestTotal = 0;
    } else {
	$TestTotal = 48;
    }
    print "1..$TestTotal\n";
}

END {print "not ok 1\n" unless $Loaded;}
use AFS::Command::BOS 1.99;
$Loaded = 1;
$TestCounter = 1;
print "ok $TestCounter\n";
$TestCounter++;

my $cell = $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_CELLNAME\n";
};

my $dbserver = $AFS::Command::Tests::Config{AFS_COMMAND_DBSERVER} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_PARTITION_LIST\n";
};

my $binary = $AFS::Command::Tests::Config{AFS_COMMAND_BINARY_BOS} || 'bos';

exit 0 unless $TestTotal;

#
# First, test the constructor
#
my $bos = AFS::Command::BOS->new
  (
   command		=> $binary,
  );
if ( ref $bos && $bos->isa("AFS::Command::BOS") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to instantiate AFS::Command::BOS object\n";
}

#
# bos getdate
#
my $result = $bos->getdate
  (
   server		=> $dbserver,
   cell			=> $cell,
   file			=> 'bosserver',
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to getdate for bosserver:\n" . $bos->errors());
}

my @files = $result->getFileNames();
if ( grep($_ eq 'bosserver',@files) ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter\n";
    warn("Didn't find 'bosserver' in results from bos->getdate()");
}
$TestCounter++;

my $file = $result->getFile('bosserver');
if ( ref $file && $file->isa("AFS::Object") ) {

    print "ok $TestCounter\n";
    $TestCounter++;

    my $date = $file->date();
    if ( $date ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("No date found for file 'bosserver' in results from bos->getdate()");
    }
    $TestCounter++;

} else {
    print "not ok $TestCounter\n";
    $TestCounter++;
    print "not ok $TestCounter\n";
    $TestCounter++;
    warn("Didn't find 'bosserver' in results from bos->getdate()");
}

#
# bos getlog
#
$result = $bos->getlog
  (
   server		=> $dbserver,
   cell			=> $cell,
   file			=> '/usr/afs/logs/BosLog',
  );
if ( ref $result && $result->isa("AFS::Object::BosServer") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to getlog for bosserver:\n" . $bos->errors());
}

my $log = $result->log();
if ( $log ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to getlog for bosserver:\n" . $bos->errors());
}

my ($firstline) = split(/\n+/,$log);

my $tmpfile = "/var/tmp/.bos.getlog.results.$$";

$result = $bos->getlog
  (
   server		=> $dbserver,
   cell			=> $cell,
   file			=> '/usr/afs/logs/BosLog',
   redirect		=> $tmpfile,
  );
if ( ref $result && $result->isa("AFS::Object::BosServer") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to getlog for bosserver:\n" . $bos->errors());
}

$log = $result->log();
if ( $log eq $tmpfile ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to getlog for bosserver:\n" . $bos->errors());
}

$file = IO::File->new($tmpfile) || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to read $tmpfile: $ERRNO\n";
};

if ( $file->getline() eq "$firstline\n" ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter..$TestTotal\n";
    warn("Contents of bos->getlog() do not match when fetched\n" .
	 "with and without 'redirect' option\n");
}
$TestCounter++;

#
# bos getrestart
#
$result = $bos->getrestart
  (
   server		=> $dbserver,
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::BosServer") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to getrestart for bosserver:\n" . $bos->errors());
}

foreach my $attr ( qw(restart binaries) ) {
    if ( $result->$attr() ) {
	print "ok $TestCounter\n";
    } else {
	print "not ok $TestCounter\n";
	warn("Unable to get $attr time from bos->getrestart()\n");
    }
    $TestCounter++;
}

#
# bos listhosts
#
$result = $bos->listhosts
  (
   server		=> $dbserver,
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::BosServer") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to listhosts for bosserver:\n" . $bos->errors());
}

if ( $result->cell() eq $cell ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter\n";
    warn("Cell name returned by listhosts '" . $result->cell() .
	 "' does not match '$cell'");
}
$TestCounter++;

my $hosts = $result->hosts();
if ( ref $hosts eq 'ARRAY' ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter\n";
    warn("Not an ARRAY ref: bos->listhosts->hosts()\n");
}
$TestCounter++;

#
# bos listkeys
#
$result = $bos->listkeys
  (
   server		=> $dbserver,
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::BosServer") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to listkeys for bosserver:\n" . $bos->errors());
}

my @indexes = $result->getKeyIndexes();
if ( @indexes ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to get indexes from listkeys for bosserver\n");
}

foreach my $index ( @indexes ) {

    my $key = $result->getKey($index);

    if ( ref $result && $result->isa("AFS::Object") ) {
	print "ok $TestCounter\n";
	$TestCounter++;
	if ( $key->cksum() ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Key for index '$index' has no cksum\n");
	}
	$TestCounter++;
    } else {
	print "not ok $TestCounter\n";
	$TestCounter++;
	print "not ok $TestCounter\n";
	$TestCounter++;
	warn("Unable to get key for index '$index' from listkeys result\n");
    }

}

#
# bos listusers
#
$result = $bos->listusers
  (
   server		=> $dbserver,
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::BosServer") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to listusers for bosserver:\n" . $bos->errors());
}

my $susers = $result->susers();
if ( ref $susers eq 'ARRAY' ) {
    print "ok $TestCounter\n";
} else {
    print "not ok $TestCounter\n";
    warn("Not an ARRAY ref: bos->listusers->susers()\n");
}
$TestCounter++;

#
# bos status
#
$result = $bos->status
  (
   server		=> $dbserver,
   cell			=> $cell,
  );
if ( ref $result && $result->isa("AFS::Object::BosServer") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to get status from bosserver:\n" . $bos->errors());
}

my @instancenames = $result->getInstanceNames();
if ( @instancenames ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to get instance names from bos->status->getInstanceNames()\n");
}

foreach my $name ( qw(vlserver ptserver) ) {

    if ( grep($_ eq $name,@instancenames) ) {
	print "ok $TestCounter\n";
	$TestCounter++;
	my $instance = $result->getInstance($name);
	if ( ref $instance && $instance->isa("AFS::Object::Instance") ) {
	    print "ok $TestCounter\n";
	    $TestCounter++;
	    if ( $instance->status() ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("No status attribute for instance '$name' from getInstance()\n");
	    }
	    $TestCounter++;
	} else {
	    print "not ok $TestCounter\n";
	    $TestCounter++;
	    warn("Unable to get instance '$name' from getInstance()\n");
	}
    } else {
	print "not ok $TestCounter.." . ($TestCounter+3) ."\n";
	$TestCounter += 3;
	warn("Did not find instance '$name' in bos status output\n");
    }

}

$result = $bos->status
  (
   server		=> $dbserver,
   cell			=> $cell,
   long			=> 1,
  );
if ( ref $result && $result->isa("AFS::Object::BosServer") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to get status from bosserver:\n" . $bos->errors());
}

foreach my $name ( qw(vlserver ptserver) ) {

    my $instance = $result->getInstance($name);
    if ( ref $instance && $instance->isa("AFS::Object::Instance") ) {

	print "ok $TestCounter\n";
	$TestCounter++;

	foreach my $attr ( qw(status type startdate startcount) ) {
	    if ( $instance->$attr() ) {
		print "ok $TestCounter\n";
	    } else {
		print "not ok $TestCounter\n";
		warn("No attribute '$attr' for instance '$name' from getInstance()\n");
	    }
	    $TestCounter++;
	}

	my @commands = $instance->getCommands();
	if ( $#commands == 0 ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Instance '$name' has more than one command\n");
	}
	$TestCounter++;

	my $command = $commands[0];

	if ( $command->index() == 1 ) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Command should have index == 1, but has index == " .
		 $command->index() . "\n");
	}
	$TestCounter++;

	if ( $command->command() =~ /$name/) {
	    print "ok $TestCounter\n";
	} else {
	    print "not ok $TestCounter\n";
	    warn("Command should have command attr matching '/$name/', but is " .
		 $command->command() . "\n");
	}
	$TestCounter++;

    } else {
	print "not ok $TestCounter.." . ($TestCounter+7) . "\n";
	$TestCounter += 7;
	warn("Unable to get instance '$name' from getInstance()\n");
    }

}

exit 0;

END {
    #$TestCounter--;
    #warn "Total number of tests == $TestCounter\n";
}
