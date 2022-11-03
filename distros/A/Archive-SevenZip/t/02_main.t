#!/usr/bin/perl

# Main testing for Archive::Zip

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Archive::SevenZip qw( :ERROR_CODES :CONSTANTS );
use FileHandle;
use File::Path;
use File::Spec;

use Test::More;

our $testZipDoesntWork;
our $status;

use lib '.';
BEGIN {
if( ! eval {
    push @INC, '.';
    require t::common;
    t::common->import;
    1
}) {
    diag $@;
    plan skip_all => "Archive::Zip not installed, skipping compatibility tests", 83;
    exit;
   } else {
       plan tests => 83;
   }
}

#####################################################################
# Testing Utility Functions

#--------- check CRC
is(TESTSTRINGCRC(), 0xac373f32, 'Testing CRC matches expected');

# Bad times die
SCOPE: {
    my @errors = ();
    local $Archive::Zip::ErrorHandler = sub { push @errors, @_ };
    eval { Archive::Zip::Member::_unixToDosTime(0) };
    ok($errors[0] =~ /Tried to add member with zero or undef/,
        'Got expected _unixToDosTime error');
}

#--------- check time conversion

foreach my $unix_time (
    315576062,  315576064,  315580000,  315600000,
    316000000,  320000000,  400000000,  500000000,
    600000000,  700000000,  800000000,  900000000,
    1000000000, 1100000000, 1200000000, int(time() / 2) * 2,
  ) {
    my $dos_time   = Archive::Zip::Member::_unixToDosTime($unix_time);
    my $round_trip = Archive::Zip::Member::_dosToUnixTime($dos_time);
    is($unix_time, $round_trip, 'Got expected DOS DateTime value');
}

#####################################################################
# Testing Archives

my $version = Archive::SevenZip->find_7z_executable();
if( ! $version ) {
    SKIP: { skip "7z binary not found (not installed?)", 65; }
    exit;
};
diag "7-zip version $version";
if( $version <= 9.20) {
  SKIP: {
    skip "7z version $version does not support renaming", 65;
  }
    exit
};

#--------- empty file
# new	# Archive::Zip
# new	# Archive::Zip::Archive
my $zip = Archive::SevenZip->archiveZipApi();
$zip->{sevenZip}->{verbose} = $ENV{TEST_ARCHIVE_7Z_VERBOSE};

isa_ok($zip, 'Archive::SevenZip::API::ArchiveZip');

# members	# Archive::Zip::Archive
my @members = $zip->members;
is(scalar(@members), 0, '->members is 0');

# numberOfMembers	# Archive::Zip::Archive
my $numberOfMembers = $zip->numberOfMembers();
is($numberOfMembers, 0, '->numberofMembers is 0');

# writeToFileNamed	# Archive::Zip::Archive
   $status = $zip->writeToFileNamed(OUTPUTZIP());
is($status, AZ_OK, '->writeToFileNames ok');

my $zipout;
SKIP: {
    skip("No 'unzip' program to test against", 1) unless HAVEUNZIP();
    if ($^O eq 'MSWin32') {
        print STDERR
          "\n# You might see an expected 'zipfile is empty' warning now.\n";
    }
    ($status, $zipout) = testZip();

    # STDERR->print("status= $status, out=$zipout\n");

    skip("test zip doesn't work", 1) if $testZipDoesntWork;

    skip("freebsd's unzip doesn't care about empty zips", 1)
        if $^O eq 'freebsd';

    ok($status != 0);
}

# unzip -t returns error code=1 for warning on empty

#--------- add a directory
my $memberName = TESTDIR() . '/';
my $dirName    = TESTDIR();

# addDirectory	# Archive::Zip::Archive
# new	# Archive::Zip::Member
my $member = $zip->addDirectory($memberName);
ok(defined($member));
is($member->fileName(), $memberName);

# On some (Windows systems) the modification time is
# corrupted. Save this to check late.
my $dir_time = $member->lastModFileDateTime();
note "Time is $dir_time";

# members	# Archive::Zip::Archive
@members = $zip->members();
is(scalar(@members), 1, "We have one member");
is($members[0]->fileName,      $member->fileName, "... with the correct filename");

# numberOfMembers	# Archive::Zip::Archive
$numberOfMembers = $zip->numberOfMembers();
is($numberOfMembers, 1);

# writeToFileNamed	# Archive::Zip::Archive
$status = $zip->writeToFileNamed(OUTPUTZIP());
is($status, AZ_OK);

# Does the modification time get corrupted?
is(($zip->members)[0]->lastModFileDateTime(), $dir_time);

SKIP: {
    skip("No 'unzip' program to test against", 1) unless HAVEUNZIP();
    ($status, $zipout) = testZip();

    # STDERR->print("status= $status, out=$zipout\n");
    skip("test zip doesn't work", 1) if $testZipDoesntWork;
    is($status, 0);
}

#--------- extract the directory by name
rmtree([TESTDIR()], 0, 0);
$status = $zip->extractMember($memberName);
is($status, AZ_OK);
ok(-d $dirName);

#--------- extract the directory by identity
ok(rmdir($dirName));    # it's still empty
$status = $zip->extractMember($member);
is($status, AZ_OK);
ok(-d $dirName);

#--------- add a string member, uncompressed
$memberName = TESTDIR() . '/string.txt';

# addString	# Archive::Zip::Archive
# newFromString	# Archive::Zip::Member
$member = $zip->addString(TESTSTRING(), $memberName);
ok(defined($member));

is($member->fileName(), $memberName);

# members	# Archive::Zip::Archive
@members = $zip->members();
is(scalar(@members), 2);
#is($members[1]->fileName,      $member->fileName);

# numberOfMembers	# Archive::Zip::Archive
$numberOfMembers = $zip->numberOfMembers();
is($numberOfMembers, 2);

# writeToFileNamed	# Archive::Zip::Archive
$status = $zip->writeToFileNamed(OUTPUTZIP());
is($status, AZ_OK);

SKIP: {
    skip("No 'unzip' program to test against", 1) unless HAVEUNZIP();
    ($status, $zipout) = testZip();

    # STDERR->print("status= $status, out=$zipout\n");
    skip("test zip doesn't work", 1) if $testZipDoesntWork;
    is($status, 0);
}

is($member->crc32(), TESTSTRINGCRC());

is($member->crc32String(), sprintf("%08x", TESTSTRINGCRC()));

#--------- extract it by name
$status = $zip->extractMember($memberName);
is($status, AZ_OK);
ok(-f $memberName);
is(fileCRC($memberName), TESTSTRINGCRC());

#--------- now compress it and re-test
#my $oldCompressionMethod =
#  $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
#is($oldCompressionMethod, COMPRESSION_STORED, 'old compression method OK');

# writeToFileNamed	# Archive::Zip::Archive
$status = $zip->writeToFileNamed(OUTPUTZIP());
is($status, AZ_OK, 'writeToFileNamed returns AZ_OK');
is($member->crc32(),            TESTSTRINGCRC());
is($member->uncompressedSize(), TESTSTRINGLENGTH());

SKIP: {
    skip("No 'unzip' program to test against", 1) unless HAVEUNZIP();
    ($status, $zipout) = testZip();

    # STDERR->print("status= $status, out=$zipout\n");
    skip("test zip doesn't work", 1) if $testZipDoesntWork;
    is($status, 0);
}

#--------- extract it by name
$status = $zip->extractMember($memberName);
is($status, AZ_OK);
ok(-f $memberName);
is(fileCRC($memberName), TESTSTRINGCRC());

#--------- add a file member, compressed
ok(rename($memberName, TESTDIR() . '/file.txt'));
$memberName = TESTDIR() . '/file.txt';

# addFile	# Archive::Zip::Archive
# newFromFile	# Archive::Zip::Member
$member = $zip->addFile($memberName);
ok(defined($member));

is($member->desiredCompressionMethod(), COMPRESSION_DEFLATED);

# writeToFileNamed	# Archive::Zip::Archive
$status = $zip->writeToFileNamed(OUTPUTZIP());
is($status,                     AZ_OK);
is($member->crc32(),            TESTSTRINGCRC());
is($member->uncompressedSize(), TESTSTRINGLENGTH());

SKIP: {
    skip("No 'unzip' program to test against", 1) unless HAVEUNZIP();
    ($status, $zipout) = testZip();

    # STDERR->print("status= $status, out=$zipout\n");
    skip("test zip doesn't work", 1) if $testZipDoesntWork;
    is($status, 0);
}

#--------- extract it by name (note we have to rename it first
#--------- or we will clobber the original file
my $newName = $memberName;
$newName =~ s/\.txt/2.txt/;
$status = $zip->extractMember($memberName, $newName);
is($status, AZ_OK);
ok(-f $newName);
is(fileCRC($newName), TESTSTRINGCRC());

#--------- now make it uncompressed and re-test
#$oldCompressionMethod = $member->desiredCompressionMethod(COMPRESSION_STORED);

#is($oldCompressionMethod, COMPRESSION_DEFLATED);

# writeToFileNamed	# Archive::Zip::Archive
$status = $zip->writeToFileNamed(OUTPUTZIP());
is($status,                     AZ_OK);
is($member->crc32(),            TESTSTRINGCRC());
is($member->uncompressedSize(), TESTSTRINGLENGTH());

SKIP: {
    skip("No 'unzip' program to test against", 1) unless HAVEUNZIP();
    ($status, $zipout) = testZip();

    # STDERR->print("status= $status, out=$zipout\n");
    skip("test zip doesn't work", 1) if $testZipDoesntWork;
    is($status, 0);
}

#--------- extract it by name
$status = $zip->extractMember($memberName, $newName);
is($status, AZ_OK);
ok(-f $newName);
is(fileCRC($newName), TESTSTRINGCRC());

# Now, the contents of OUTPUTZIP() are:
# Length   Method    Size  Ratio   Date   Time   CRC-32    Name
#--------  ------  ------- -----   ----   ----   ------    ----
#       0  Stored        0   0%  03-17-00 11:16  00000000  TESTDIR/
#     300  Defl:N      146  51%  03-17-00 11:16  ac373f32  TESTDIR/string.txt
#     300  Stored      300   0%  03-17-00 11:16  ac373f32  TESTDIR/file.txt
#--------          -------  ---                            -------
#     600              446  26%                            3 files

# members	# Archive::Zip::Archive
@members = $zip->members();
is(scalar(@members), 3);
is_deeply([map {$_->fileName}
           grep { $_->fileName eq $member->fileName } @members ],
           [$member->fileName])
  or do { diag "Have: " . $_->fileName for @members };

# memberNames	# Archive::Zip::Archive
my @memberNames = $zip->memberNames();
is(scalar(@memberNames), 3);
is_deeply([ grep { $_ eq $member->fileName } @memberNames ],
          [ $member->fileName ])
or do { diag sprintf "[%s]", $member->fileName ; diag sprintf "[%s]", $_->fileName for @members };

# memberNamed	# Archive::Zip::Archive
is($zip->memberNamed($memberName)->fileName, $member->fileName);

# membersMatching	# Archive::Zip::Archive
@members = $zip->membersMatching('file');
is(scalar(@members), 1);
is($members[0]->fileName,      $member->fileName);

@members = sort { $a->fileName cmp $b->fileName } $zip->membersMatching('.txt$');
is(scalar(@members), 2);
is($members[0]->fileName,      $member->fileName);

#--------- remove the string member and test the file
# removeMember	# Archive::Zip::Archive
diag "Removing " . $members[0]->fileName;
$member = $zip->removeMember($members[0]);
is($member, $members[0]);

$status = $zip->writeToFileNamed(OUTPUTZIP());
is($status, AZ_OK);

SKIP: {
    skip("No 'unzip' program to test against", 1) unless HAVEUNZIP();
    ($status, $zipout) = testZip();

    # STDERR->print("status= $status, out=$zipout\n");
    skip("test zip doesn't work", 1) if $testZipDoesntWork;
    is($status, 0);
}

#--------- add the string member at the end and test the file
# addMember	# Archive::Zip::Archive
# This will never work in Archive::SevenZip, transplanting
# zip entries in-memory
# This also ruins all of the subsequent tests due to the weirdo
# approach of not setting up a common baseline for each test
# and the insistence on that the implementation maintains the
# order on archive members
#
#$zip->addMember($member);
#@members = $zip->members();

#is(scalar(@members), 3);
#is($members[2],      $member);

# memberNames	# Archive::Zip::Archive
#@memberNames = $zip->memberNames();
#is(scalar(@memberNames), 3);
#is($memberNames[1],      $memberName);

#$status = $zip->writeToFileNamed(OUTPUTZIP());
#is($status, AZ_OK);

#SKIP: {
#    skip("No 'unzip' program to test against", 1) unless HAVEUNZIP();
#    ($status, $zipout) = testZip();

#    # STDERR->print("status= $status, out=$zipout\n");
#    skip("test zip doesn't work", 1) if $testZipDoesntWork;
#    is($status, 0);
#}
