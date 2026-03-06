package t::lib::Tools;
use strict;
use warnings;

use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use File::Compare qw(compare);
use Test::Builder::Module;
use Exporter qw(import);
use version;

our @EXPORT_OK = qw(compare_pdf);

sub compare_pdf {
    my ($pdf, $expected_file) = @_;

    my $Test = Test::Builder::Module->builder;

    my $content = $pdf->content;
    $Test->ok($content, "Some PDF content produced");

    # For debugging one can set CLEANUP to 0 and enable the diag to see
    # the name of the temporary folder.
    my $dir = tempdir( CLEANUP => 1 );
    # $Test->diag($dir);

    my $pb_version = version->parse($PDF::Builder::VERSION);
    my $file = catfile($dir, 'out.pdf');

    # To (re) generate the expected sample files, run:
    # GENERATE=1 make test
    if ($ENV{GENERATE}) {
        mkdir "sample/$pb_version";
        open my $out, '>', "sample/$pb_version/$expected_file" or die;
        binmode $out;
        print $out $content;
        close $out;
    }

    open my $out, '>', $file;
    binmode $out;
    print $out $content;
    close $out;

    my $message = "Missing expected sample files for PDF::Builder version $pb_version";
    if (-e "sample/$pb_version") {
        $Test->is_num(compare($file, "sample/$pb_version/$expected_file"), 0, 'File is as expected');
    } else {
        if ($ENV{CI}) {
            # In the CI it will fail
            $Test->ok(0, $message);
        } else {
            # Regular user installation will skip the check but warn the user
            # about the missing verification.
            $Test->diag($message);
        }
    }
}

1;
