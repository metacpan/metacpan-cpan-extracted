# Test the sample program "bin/dlmup".

# ------ pragmas
use Date::Format;
use File::Spec;
use File::stat;
use Test::More;
use strict;
use warnings;


# ------ define variables
my $date      = "";         # formatted date/time string
my @date_time = ();         # date/time array
my $stat      = "";         # output object of stat()
my $output    = "";         # dlmup output lines as one string
my $tmpdir                  # temp dir for test files
 = File::Spec->tmpdir() . "/Date-LastModified";


# ------- create test file with specified name
sub create_test_file {
    my $file = shift;       # test filename

    unlink($file);
    open(OFH, ">$file")
     || die "can't create '$file' because: $!\n";
    print OFH <<endPRINT;
<html><head><title>"dlmup" Test File"</title></head>
<body>
<h1>"dlmup" Test File"</h1>
<p>Some text.</p>
<p>Last updated January 1, 1970.</p>
</body>
</html>
endPRINT
    close(OFH)
     || die "can't close '$file' because: $!\n";
}


# ------ grep(1) a file
sub grep_file {
    my $pattern = shift;    # regex to grep for
    my $file    = shift;    # file to grep

    open(IFH, $file)
     || die "can't open '$file' because: $!\n";
    while (<IFH>) {
        if (m/$pattern/) {
            return 1;
        }
    }
    close(IFH);

    return 0;
}


# ------ use local copy of Date::LastModified
$ENV{"PERLLIB"} = "./blib/lib";


# ------ set # of tests
plan(tests => 15);


# ------ no arguments
$output = join(" ", `bin/dlmup 2>&1`);
like($output, qr/usage: dlmup/, "no arguments");


# ------ bad config file from env
$output = join(" ", `DLMUPCFG=never-exist.cfg;export DLMUPCFG;bin/dlmup x 2>&1`);
like($output, qr/can't read 'never-exist.cfg'/, "bad config file from env");


# ------ bad config file direct
$output = join(" ", `bin/dlmup -fnot-exists.cfg x 2>&1`);
like($output, qr/can't read 'not-exists.cfg'/, "bad config file direct");


# ------ standard output
$stat      = stat("$tmpdir/dir-new/file-new");
@date_time = localtime($stat->mtime);
$date      = strftime("%Y-%M-%d %H:%m:%S", @date_time);
$output = join(" ", `bin/dlmup -f$tmpdir/datelastmod-1file.cfg "%Y-%M-%d %H:%m:%S" 2>&1`);
like($output, qr/$date/, "standard output");


# ------ standard output, friendly+different format
$date      = strftime("%B %e, %Y", @date_time);
$output = join(" ", `bin/dlmup -f$tmpdir/datelastmod-1file.cfg "%B %e, %Y" 2>&1`);
like($output, qr/$date/, "standard output, friendly+different format");


# ------ verbose (first arg)
$output = join(" ", `bin/dlmup -v -f$tmpdir/datelastmod-1file.cfg "%B %e, %Y" 2>&1`);
like($output, qr#$tmpdir/dir-new/file-new#,
 "verbose (first arg)");


# ------ verbose (last arg)
$output = join(" ", `bin/dlmup -f$tmpdir/datelastmod-1file.cfg -v "%B %e, %Y" 2>&1`);
like($output, qr#$tmpdir/dir-new/file-new#,
 "verbose (last arg)");


# ------ ignore arguments
$output = join(" ", `bin/dlmup -v -ignoreme -f$tmpdir/datelastmod-1file.cfg "%B %e, %Y" 2>&1`);
like($output, qr#$tmpdir/dir-new/file-new#,
 "ignore arguments");


# ------ missing input file
$output = join(" ", `bin/dlmup -f$tmpdir/datelastmod-1file.cfg "Last updated \\w+ \\d+, \\d+" "%B %e, %Y" never-exist.zed 2>&1`);
like($output, qr/can't open 'never-exist.zed' because/,
 "missing input file");


# ------ can't create output file
create_test_file("unwritable.html.dlmup");
chmod(0400, "unwritable.html.dlmup")
 || die "can't chmod 0400 unwritable.html.dlmup because: $!\n";
$output = join(" ", `bin/dlmup -f$tmpdir/datelastmod-1file.cfg "Last updated \\w+ \\d+, \\d+" "%B %e, %Y" unwritable.html 2>&1`);
like($output, qr/can't create 'unwritable.html.dlmup' because/,
 "can't create output file");


# ------ fail on first of multiple files
$output = join(" ", `bin/dlmup -f$tmpdir/datelastmod-1file.cfg "Last updated \\w+ \\d+, \\d+" "%B %e, %Y" unwritable.html never-exist.zed 2>&1`);
like($output, qr/can't create 'unwritable.html.dlmup' because/,
 "fail on first of multiple files (part 1)");
unlike($output, qr/can't open 'never-exist.zed'/,
 "fail on first of multiple files (part 2)");


# ------ fail on last of multiple files
create_test_file("first.txt");
$output = join(" ", `bin/dlmup -f$tmpdir/datelastmod-1file.cfg "Last updated \\w+ \\d+, \\d+" "%B %e, %Y" first.txt unwritable.html 2>&1`);
like($output, qr/can't create 'unwritable.html.dlmup' because/,
 "fail on last of multiple files");


# ------ changed one file
create_test_file("one-file.txt");
$output = join(" ", `bin/dlmup -f$tmpdir/datelastmod-1file.cfg "Last updated \\w+ \\d+, \\d+" "Last updated %B %e, %Y" one-file.txt 2>&1`);
ok(grep_file("Last updated $date", "one-file.txt"),
 "changed one file");


# ------ changed multiple files
create_test_file("two-file-1.txt");
create_test_file("two-file-2.txt");
$output = join(" ", `bin/dlmup -f$tmpdir/datelastmod-1file.cfg "Last updated \\w+ \\d+, \\d+" "Last updated %B %e, %Y" two-file-1.txt two-file-2.txt 2>&1`);
ok( grep_file("Last updated $date", "two-file-1.txt")
 && grep_file("Last updated $date", "two-file-2.txt"),
 "changed multiple files");
