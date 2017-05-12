# -*- Perl -*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 37;
BEGIN { use_ok('Convert::yEnc::RC') };

#########################

use strict;
use warnings;

my $Dir = "t/RC.d";

my @Gold = split /\n/, <<GOLD;
=ybegin size=20000 name=a.jpg
=yend size=20000
=ybegin size=10000 part=1 name=b.jpg
=ypart begin=1 end=5000
=yend size=5000 part=1
GOLD

my $Gold = GoldRC();

Internal();
External();

sub Internal
{
    my $rc = Creation();

    Single  ($rc);
    Multiple($rc);
    Entry   ($rc);
    Drop    ($rc);
    Total   ($rc);
}

sub Creation
{
    my $rc = new Convert::yEnc::RC;
    isa_ok($rc, "Convert::yEnc::RC", "RC creation");

    my @files = $rc->files;
    ok(eq_set(\@files, []), "no files");

    my @complete = $rc->complete;
    ok(eq_set(\@complete, []), "no complete");

    $rc
}

sub Single
{
    my $rc = shift;

    my $ok = $rc->update("=ybegin size=10000 name=a.jpg");
    ok($ok, "update =ybegin");

    $ok = $rc->update("=yend size=10000");
    ok($ok, "update =yend");

    my $complete = $rc->complete("a.jpg");
    ok($complete, "a.jpg complete");

    $ok = $rc->update("=yend size=10000");
    ok(!$ok, "update =yend out of order");

    my @files = $rc->files;
    ok(eq_set(\@files, [qw(a.jpg)]), "1 file");

    my @complete = $rc->complete;
    ok(eq_set(\@complete, [qw(a.jpg)]), "1 complete");
}

sub Multiple
{
    my $rc = shift;

    my $ok = $rc->update("=ybegin size=10000 part=1 name=b.jpg");
    ok($ok, "update =ybegin");

    $ok = $rc->update("=ypart begin=1 end=5000");
    ok($ok, "update =ypart");

    $ok = $rc->update("=yend size=5000 part=1");
    ok($ok, "update =yend");

    my $complete = $rc->complete("b.jpg");
    ok(!$complete, "b.jpg not complete");

    my @files = $rc->files;
    ok(eq_set(\@files, [qw(a.jpg b.jpg)]), "2 files");

    my @complete = $rc->complete;
    ok(eq_set(\@complete, [qw(a.jpg)]), "1 complete");


    $ok = $rc->update("=ybegin size=10000 part=2 name=b.jpg");
    ok($ok, "update =ybegin");

    $ok = $rc->update("=ypart begin=5001 end=10000");
    ok($ok, "update =ypart");

    $ok = $rc->update("=yend size=5000 part=2");
    ok($ok, "update =yend");
    
    $complete = $rc->complete("b.jpg");
    ok($complete, "b.jpg complete");

    @files = $rc->files;
    ok(eq_set(\@files, [qw(a.jpg b.jpg)]), "2 files");

    @complete = $rc->complete;
    ok(eq_set(\@complete, [qw(a.jpg b.jpg)]), "2 complete");
}

sub Entry
{
    my $rc = shift;

    my $entry = $rc->entry("a.jpg");
    isa_ok($entry, "Convert::yEnc::Entry", 'entry("a.jpg")');

    $entry = $rc->entry("b.jpg");
    isa_ok($entry, "Convert::yEnc::Entry", 'entry("b.jpg")');
}

sub Drop
{
    my $rc = shift;

    my $ok = $rc->drop("a.jpg");
    ok($ok, "drop a.jpg");

    my $entry = $rc->entry("a.jpg");
    ok((not defined $entry), "a.jpg dropped");
}

sub Total
{
    my $rc = shift;
    my $ok;

    	  $rc->update("=ybegin size=10000 part=1 name=b.jpg");
    	  $rc->update("=ypart begin=1 end=5000");
    	  $rc->update("=yend size=5000 part=1");
    $ok = $rc->update("=ybegin size=10000 part=2 total=2 name=b.jpg");
    ok($ok, "missing total");

          $rc->update("=ybegin size=10000 part=1 total=2 name=c.jpg");
          $rc->update("=ypart begin=1 end=5000");
          $rc->update("=yend size=5000 part=1");
    $ok = $rc->update("=ybegin size=10000 part=2 total=2 name=c.jpg");
    ok($ok, "good total");

          $rc->update("=ybegin size=10000 part=1 total=3 name=d.jpg");
          $rc->update("=ypart begin=1 end=5000");
          $rc->update("=yend size=5000 part=1");
    $ok = $rc->update("=ybegin size=10000 part=2 total=2 name=d.jpg");
    is($ok, 0, "bad total");
}


sub External
{
    New ();
    Load();
    Save();
}

sub New
{
    my $rc = new Convert::yEnc::RC;
    eval { $rc->save };
    isnt($@, '', "New: empty");

    my $newrc = "$Dir/newrc";
    unlink $newrc;
    $rc = new Convert::yEnc::RC $newrc;
    $rc->save;
    ok(-e $newrc, "New: save");

    my $loadrc = "$Dir/loadrc";
    $rc = new Convert::yEnc::RC $loadrc;
    ok($Gold eq $rc, "New: load");
}

sub Load
{
    my $rc = new Convert::yEnc::RC;
    my $ok = $rc->load;
    is($ok, undef, "Load: empty");

    my $loadrc = "$Dir/loadrc";
    $rc = new Convert::yEnc::RC;
    $ok = $rc->load($loadrc);
    ok($Gold eq $rc, "Load: load");
}

sub Save
{
    my $empty = "$Dir/empty";
    MakeEmpty($empty);
    my $rc = new Convert::yEnc::RC;
    $rc->load($empty);
    for my $line (@Gold) { $rc->update($line) }
    $rc->save;
    ok(-s $empty, "Save: default save to last loaded file");

    my $full = "$Dir/full";
    unlink $full;
    $rc->save($full);
    ok(-s $full, "Save: save to named file");

    my @full = ReadLines("$full");
    my @gold = ReadLines("$Dir/gold");
    ok(eq_array(\@full, \@gold), "Save: verify saved file contents");
}


sub GoldRC
{
    my $rc = new Convert::yEnc::RC;
    
    for my $line (@Gold)
    {
	$rc->update($line);
    }

    $rc
}

sub MakeEmpty
{
    my $file = shift;
    open FILE, "> $file" or die "Can't open $file: $!\n";
    close FILE;
}


sub ReadLines
{
    my $file = shift;
    open FILE, $file or die "Can't open $file: $!\n";
    grep { /\S/ } <FILE>
}
