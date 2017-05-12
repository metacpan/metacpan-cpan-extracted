#
# $Id: 02vos_volserver.t,v 11.2 2004/11/18 16:49:00 wpm Exp $
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
	$TestTotal = 17;
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

my @servers		= ();
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
    print "# AFS::Command::VOS->new()\n";
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to instantiate AFS::Command::VOS object\n";
}

#
# Thi test is kinda boring...  Just verifying that partinfo and
# listpart are consistent.
#
my $listpart = $vos->listpart
  (
   server		=> $server_primary,
   cell			=> $cell,
  );
if ( ref $listpart && $listpart->isa("AFS::Object::FileServer") ) {
    print "# AFS::Command::VOS->listpart()\n";
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to query partinfo on server '$server_primary', in cell '$cell':\n" .
	$vos->errors());
}

my $partinfo = $vos->partinfo
  (
   server		=> $server_primary,
   cell			=> $cell,
  );
if ( ref $partinfo && $partinfo->isa("AFS::Object::FileServer") ) {
    print "# AFS::Command::VOS->partinfo()\n";
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to query partinfo on server '$server_primary', in cell '$cell':\n" .
	$vos->errors());
}

foreach my $objectpair ( [ $partinfo, $listpart ], [ $listpart, $partinfo ] ) {

    my ($src,$dst) = @$objectpair;

    my @partitions = $src->getPartitionNames();
    if ( @partitions ) {
	print "# AFS::Command::VOS->getPartitionNames()\n";
	print "ok $TestCounter\n";
	$TestCounter++;
    } else {
	print "not ok $TestCounter..$TestTotal\n";
	die("Unable to get list of partition names for server '$server_primary', in cell '$cell':\n");
    }

    my $attribute_test = 1;

    foreach my $partname ( @partitions ) {

	my $partition = $dst->getPartition($partname);

	unless ( ref $partition && $partition->isa("AFS::Object::Partition") ) {
	    print "not ok $TestCounter..$TestTotal\n";
	    die("Inconsistent data in listpart and partinfo output\n" .
		"Found partname '$partname' in one, but not the other");
	}

	if ( $partition->hasAttribute('available') ) {

	    my $available 	= $partition->available();
	    my $total		= $partition->total();

	    unless ( $available =~ /^\d+$/ && $total =~ /^\d+$/ && $available < $total ) {
		$attribute_test = 0;
		warn("Invalid attributes for partition '$partname'\n" .
		     "Available is '$available', total is '$total'\n" .
		     "both must be numeric, and available less than total\n");
	    }

	}

    }

    print "# AFS::Command::VOS->hasAttribute()\n";
    print "not " unless $attribute_test;
    print "ok $TestCounter\n";

    $TestCounter++;

}

#
# Now that we can trust listpart and partinfo, let's see if we can
# trust listvol.
#

#
# First, let's make sure the partition lists are consisent.
#
my $listvol = $vos->listvol
  (
   server		=> $server_primary,
   cell			=> $cell,
   fast			=> 1,
  );
unless ( ref $listvol && $listvol->isa("AFS::Object::VolServer") ) {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to query listvol for server '$server_primary', in cell '$cell':\n" .
	Data::Dumper->Dump([$vos],['vos']));
}

print "# AFS::Command::VOS->listvol()\n";
print "ok $TestCounter\n";
$TestCounter++;

my $listpart_names 	= { map { $_ => 1 } $listpart->getPartitionNames() };
my $listvol_names 	= { map { $_ => 1 } $listvol->getPartitionNames() };

my $partname_errors = 0;

foreach my $hashpair ( [ $listpart_names, $listvol_names ],
		       [ $listvol_names, $listpart_names ] ) {

    my ($src,$dst) = @$hashpair;

    foreach my $partname ( keys %$src ) {
	$partname_errors++ unless $dst->{$partname};
    }

}

if ( $partname_errors ) {
    print "not ok $TestCounter\n";
    warn("Partition lists from listpart and listvol are inconsistent:\n" .
	 Data::Dumper->Dump([$listpart_names,$listvol_names],['listpart','listvol']));
} else {
    print "# AFS::Command::VOS, listpart vs. listvol comparison\n";
    print "ok $TestCounter\n";
}
$TestCounter++;

#
# Now, let's get more verbose output, for just one partition.
#
$listvol = $vos->listvol
  (
   server		=> $server_primary,
   partition		=> $partition_primary,
   cell			=> $cell,
  );
unless ( ref $listvol && $listvol->isa("AFS::Object::VolServer") ) {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to query listvol for server '$server_primary', " .
	"partition '$partition_primary', in cell '$cell':\n" .
	Data::Dumper->Dump([$vos],['vos']));
}

print "# AFS::Command::VOS->listvol()\n";
print "ok $TestCounter\n";
$TestCounter++;

my $partition = $listvol->getPartition($partition_primary);
unless ( ref $partition && $partition->isa("AFS::Object::Partition") ) {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to query listvol for server '$server_primary', " .
	"partition '$partition_primary', in cell '$cell':\n" .
	Data::Dumper->Dump([$listvol],['listvol']));
}

print "# AFS::Command::VOS->getPartition()\n";
print "ok $TestCounter\n";
$TestCounter++;

my $id_errors = 0;

my @ids = $partition->getVolumeIds();
unless ( @ids ) {
    warn "Empty volume id list returned by getVolumeIds()\n";
    $id_errors++;
}

foreach my $id ( @ids ) {

    my $errors_thisid = 0;

    unless ( $id =~ /^\d+$/ ) {
	warn("Non-numeric volume id '$id' returned by getVolumeIds()\n");
	$id_errors++;
	next;
    }

    my $volume_byid = $partition->getVolumeHeaderById($id);
    unless ( ref $volume_byid && $volume_byid->isa("AFS::Object::VolumeHeader") ) {
	warn("Object returned for id '$id' is not an AFS::Object::VolumeHeader\n");
	$errors_thisid++;
	$id_errors++;
    }

    my $volume_generic = $partition->getVolumeHeader( id => $id );
    unless ( ref $volume_generic && $volume_generic->isa("AFS::Object::VolumeHeader") ) {
	warn("Object returned for id '$id' is not an AFS::Object::VolumeHeader\n");
	$errors_thisid++;
	$id_errors++;
    }

    next if $errors_thisid;

    unless ( $volume_byid->id() == $volume_generic->id() ) {
	warn("Objects returned by getVolumeHeaderById and getVolumeHeader do not match:\n" .
	     Data::Dumper->Dump([$volume_byid,$volume_generic],
				['getVolumeHeaderById','getVolumeHeader']));
	$id_errors++;
    }

}

print "not " if $id_errors;
print "# AFS::Command::VOS->getPartition id check\n";
print "ok $TestCounter\n";
$TestCounter++;

my $name_errors = 0;
my @names = $partition->getVolumeNames();
unless ( @names ) {
    warn "Empty volume name list returned by get VolumeNames()\n";
    $name_errors++;
}

my $volume_online = "";

foreach my $name ( sort @names ) {

    my $errors_thisname = 0;

    my $volume_byname = $partition->getVolumeHeaderByName($name);
    unless ( ref $volume_byname && $volume_byname->isa("AFS::Object::VolumeHeader") ) {
	warn("Object returned for name '$name' is not an AFS::Object::VolumeHeader\n");
	$errors_thisname++;
	$name_errors++;
    }

    my $volume_generic = $partition->getVolumeHeader( name => $name );
    unless ( ref $volume_generic && $volume_generic->isa("AFS::Object::VolumeHeader") ) {
	warn("Object returned for name '$name' is not an AFS::Object::VolumeHeader\n");
	$errors_thisname++;
	$name_errors++;
    }

    next if $errors_thisname;

    unless ( $volume_byname->name() eq $volume_generic->name() ) {
	warn("Objects returned by getVolumeHeaderByName and getVolumeHeader do not match:\n" .
	     Data::Dumper->Dump([$volume_byname,$volume_generic],
				['getVolumeHeaderByName','getVolumeHeader']));
	$id_errors++;
	next;
    }

    if ( $volume_byname->status() eq 'online' && not ref $volume_online ) {
	$volume_online = $volume_byname;
    }

}

print "not " if $name_errors;
print "# AFS::Command::VOS->getPartition name check\n";
print "ok $TestCounter\n";
$TestCounter++;

#
# Since we trust examine by this point, we can examine the one online
# volume we kept track of, and make sure the headers match.
#
my $volname = $volume_online->name();

my $examine = $vos->examine
  (
   id			=> $volname,
   cell			=> $cell,
  );
unless ( ref $examine && $examine->isa("AFS::Object::Volume") ) {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to exmine volume '$volname' in cell '$cell':\n" .
	Data::Dumper->Dump([$vos],['vos']));
}
print "# AFS::Command::VOS->examine()\n";
print "ok $TestCounter\n";
$TestCounter++;

my @headers = $examine->getVolumeHeaders();
unless ( @headers ) {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to get volume headers from examine call:\n" .
	Data::Dumper->Dump([$examine],['examine']));
}

print "# AFS::Command::VOS->getVolumeHeaders()\n";
print "ok $TestCounter\n";
$TestCounter++;

my $volume_header = "";

foreach my $header ( @headers ) {

    unless ( ref $header && $header->isa("AFS::Object::VolumeHeader") ) {
	print "not ok $TestCounter..$TestTotal\n";
	die("Objects returned by getVolumeHeaders are not AFS::Object::VolumeHeader:\n" .
	    Data::Dumper->Dump([$examine],['examine']));
    }

    if ( $header->server() 	eq $server_primary &&
	 $header->partition()	eq $partition_primary ) {
	$volume_header = $header;
	last;
    }

}

unless ( ref $volume_header && $volume_header->isa("AFS::Object::VolumeHeader") ) {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to locate matching volume header in examine output:\n" .
	Data::Dumper->Dump([$examine],['examine']));
}

print "# AFS::Command::VOS->getVolumeHeaders header check\n";
print "ok $TestCounter\n";
$TestCounter++;

exit 0;

END {

#     $TestCounter--;
#     warn "Total number of tests == $TestCounter\n";

    if ( %Volnames ) {
	warn("The following temporary volumes were created, and may be left over:\n\t" .
	     join("\n\t",sort keys %Volnames) . "\n");
    }
}








