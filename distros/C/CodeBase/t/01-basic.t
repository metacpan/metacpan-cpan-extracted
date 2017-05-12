#!/usr/bin/perl -w 
#
# $Id: 01-basic.t,v 1.5 1999/08/03 10:47:31 andrew Exp $
#
# Basic file handling tests for Xbase module
# ==========================================
#
# Tests that a file can be created, basic information about the file can
# be retrieved and that the file can be closed (by destroying the file handle) 
# and then reopened.


use strict;
use vars qw($loaded $fh $table @temp $filename);

# Declare our test plan and try to ensure that the module to be tested
# will be found if we are not run from the test harness

BEGIN { 
    local($^W) = 0;
    use Test; plan tests => 9;
    eval "use blib" unless grep /blib/, @INC;
    eval { use lib qw(t); } if (defined -d 't');
}


# Test that the module loads OK

use CodeBase;
use CodeBaseTestsubs;

END { print "not ok 1\n" unless $loaded; }
$loaded = 1;
ok(1);

$table = 'test1';
$filename = table_filename($table);
my $f1val = 'abcdef';
my $f2val = 42;
my $f3val = 'A memo field';


# Test file creation

drop_table($table);
$fh = CodeBase::create($filename,
		       ("F1" => "C10",
			"F2" => "N10.2",
			"F3" => "M"));
ok ($fh and ref $fh eq 'CodeBase::FilePtr');

# Test basic operations

ok (    ($fh->alias eq $table)
    and (abspath($fh->filename) eq abspath("$filename.dbf"))
    and ($fh->fldcount == 3)
    and ($fh->reccount == 0)
    and ($fh->tagcount == 0)
    and ((@temp = $fh->names) == 3)
    and ((@temp = $fh->tags)  == 0));


# Try changing the alias

my $newalias = 'newalias';
ok (    ($fh->alias($newalias) eq $newalias)
    and ($fh->alias eq $newalias)
    and (abspath($fh->filename) eq abspath("$filename.dbf")));


# Add a record

ok ($fh->new_record($f1val, $f2val, $f3val)
    and $fh->flush
    and $fh->reccount == 1);


# Close file - handle is now invalid

undef($fh);


# Reopen file

$fh = CodeBase::open($filename);

ok ($fh 
    and ref $fh eq 'CodeBase::FilePtr'
    and ($fh->fldcount == 3)
    and ($fh->reccount == 1)
    and ($fh->tagcount == 0)
    and ((@temp = $fh->names) == 3)
    and ((@temp = $fh->tags)  == 0));

# Fetch the record

$fh->goto(1);
ok (    $fh->field('F1') eq $f1val . (' ' x 4)
    and $fh->field('F2') eq $f2val
    and $fh->field('F3') eq $f3val);

CodeBase::option('trim');
ok ($fh->field('F1') eq $f1val);

CodeBase::option('notrim');
ok ($fh->field('F1') eq $f1val . (' ' x 4));


exit(0);
