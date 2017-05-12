#!/usr/bin/perl

use strict;
use warnings;

# Originally: 9
use Test::More tests => 11;

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::TestPaths;

my ($en, $ini, $success);

# test 1
# print "Empty list when no groups ........ ";
$en = Config::IniFiles->new( -file => t_file('en.ini') );
# TEST
is ( scalar($en->Groups), 0, "Empty list when no groups" );

# test 2
# print "Creating new object, no file ..... ";
$ini = Config::IniFiles->new;
# TEST
ok ($ini, "Creating new object");

# test 3
# print "Setting new file name .............";
# TEST
ok ($ini->SetFileName(t_file('test06.ini')), "Setting new file name");

# test 4
# print "Saving under new file name ........";
# TEST
ok ($ini->RewriteConfig() && (-f t_file('test06.ini')),
    "Saving under new file name ........"
);

# test 5
# print "SetSectionComment .................";
$ini->newval("Section1", "Parameter1", "Value1");
my @section_comment = ("Line 1 of section comment.", "Line 2 of section comment", "Line 3 of section comment");

# TEST
ok(
    $ini->SetSectionComment("Section1", @section_comment),
    "SetSectionComment() was successful."
);

# test 6
# print "GetSectionComment .................";
{
    my @comment = $ini->GetSectionComment("Section1");

    # TEST
    is_deeply(
        \@comment,
        [
            "# Line 1 of section comment.",
            "# Line 2 of section comment",
            "# Line 3 of section comment",
        ],
        "multi-line GetSectionComment",
        );
}

# test 7
# print "DeleteSectionComment ..............";
$ini->DeleteSectionComment("Section1");
# TEST
ok(!defined($ini->GetSectionComment("Section1")),
    "DeleteSectionComment was successful.");

# test 8
# CopySection
$ini->CopySection( 'Section1', 'Section2' );
# TEST
ok( $ini->Parameters( 'Section2' ), "CopySection was successful." );

# test 9
# DeleteSection
$ini->DeleteSection( 'Section1' );
# TEST
ok( ! $ini->Parameters( 'Section1' ), "DeleteSection was successful." );

# test 10
# RenameSection
$ini->RenameSection( 'Section2', 'Section1' );
# TEST
ok( ! $ini->Parameters( 'Section2' ) && $ini->Parameters( 'Section1' ) && $ini->val('Section1','Parameter1') eq 'Value1'  , "RenameSection was successful." );

# test 11
# Delete entire config
$ini->Delete();
# TEST
ok( ! $ini->Sections(), "Delete entire config");

# Clean up when we're done
t_unlink("test06.ini");

