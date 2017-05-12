#!/usr/bin/perl
#
# Comment preservation
#

use strict;
use warnings;

use Test::More tests => 17;

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::TestPaths;
use Config::IniFiles::Slurp qw( slurp );

my $ors = $\ || "\n";
my $irs = $/ || "\n";
my ($ini, $value);

# Load ini file and write as new file
$ini = Config::IniFiles->new( -file => t_file("test.ini"));
$ini->SetFileName(t_file("test03.ini"));
$ini->SetWriteMode("0666");
t_unlink("test03.ini");
$ini->RewriteConfig;
$ini->ReadConfig;
# TEST
ok($ini, "ini is still initialised");

sub t_slurp
{
    return slurp(t_file(@_));
}

# Section comments preserved
my $contents = t_slurp("test03.ini");
# TEST
ok (
    scalar($contents =~ /\# This is a section comment[$ors]\[test1\]/),
    "Found section comment."
);

# Parameter comments preserved
# TEST
ok(
    scalar($contents =~ /\# This is a parm comment[$ors]five=value5/),
    "Contains Parm comment.",
);

# Setting Section Comment
$ini->setval('foo','bar','qux');
# TEST
ok ($ini->SetSectionComment('foo', 'This is a section comment', 'This comment takes two lines!'),
    "SetSectionComment returns a true value.",
);

# Getting Section Comment
my @comment = $ini->GetSectionComment('foo');
# TEST
is_deeply(
    \@comment,
    ['# This is a section comment', '# This comment takes two lines!',],
    "Section comments are OK.",
);

# This is a test for: https://rt.cpan.org/Ticket/Display.html?id=8612
# TEST
is(
    scalar($ini->GetSectionComment('foo')),
    "# This is a section comment$irs# This comment takes two lines!",
    "GetSectionComment in scalar context returns a joined one.",
);

# Deleting Section Comment
$ini->DeleteSectionComment('foo');
# Should not exist!
# TEST
ok(
    !defined($ini->GetSectionComment('foo')),
    "foo section comment does not exist",
);

# Setting Parameter Comment
# TEST
ok (
    $ini->SetParameterComment(
        'foo', 'bar', 'This is a parameter comment',
        'This comment takes two lines!'
    ),
    "SetParameterCount was successful",
);

# Getting Parameter Comment
@comment = $ini->GetParameterComment('foo', 'bar');
# TEST
is_deeply(
    \@comment,
    ['# This is a parameter comment', '# This comment takes two lines!'],
    "GetParameterComment returns the correct result.",
);

# TEST
is(
    scalar($ini->GetParameterComment('foo', 'bar')),
    "# This is a parameter comment$irs# This comment takes two lines!",
    "GetParameterComment returns comments separated by newlines",
);

# Deleting Parameter Comment
$ini->DeleteParameterComment('foo', 'bar');
# Should not exist!
# TEST
ok(
    !defined($ini->GetSectionComment('foo','bar')),
    "GetSectionComment for foo/bar should not exist"
);

# Reading a section comment from the file
@comment = $ini->GetSectionComment('test1');
# TEST
is_deeply(
    \@comment,
    ['# This is a section comment'],
    "A single section comment for test1",
);

# Reading a parameter comment from the file
@comment = $ini->GetParameterComment('test2', 'five');
# TEST
is_deeply(
    \@comment,
    [ '# This is a parm comment'],
    "Reading a parameter comment from the file",
);

# Reading a comment that starts with ';'
@comment = $ini->GetSectionComment('MixedCaseSect');
# TEST
is_deeply(
    \@comment,
    [ '; This is a semi-colon comment' ],
    "Singled Section Comment for MixedCaseSect. Reading a comment that starts with ;",
);

# Test 13
# Loading from a file with alternate comment characters
# and also test continuation characters (in one file)
$ini = Config::IniFiles->new(
  -file => t_file("cmt.ini"),
  -commentchar => '@',
  -allowcontinue => 1
);

# TEST
ok($ini, "cmt.ini instance was properly initialised.");

$value = $ini->GetParameterComment('Library', 'addmultf_lib');

# TEST
ok (
    scalar($value =~ /\@#\@CF Automatically created by 'config_project' at Thu Mar 21 08:46:54 2002/),
    "Contains Parameter Comment starting with an at-sign.",
);

# Test 15
$value = $ini->val('turbo_library', 'TurboLibPaths');

# TEST
ok (
    scalar($value =~ m{\$WORKAREA/resources/c11_test_flow/vhdl_rtl\s+\$WORKAREA/resources/cstarlib_reg_1v5/vhdl_rtl}),
    "value is OK."
);

# Clean up when we're done
t_unlink("test03.ini");

