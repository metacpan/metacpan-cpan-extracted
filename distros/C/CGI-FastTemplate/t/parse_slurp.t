
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use CGI::FastTemplate;
$loaded = 1;
print "ok 1\n";

## 
## assign/define_nofile/parse
## - note: strict is off, so unknown vars are converted to empty strings.
##
{

    my $expected = "<ALL>\n<ROW>1:1</ROW>\n<ROW>2:4</ROW>\n</ALL>\n";

    my $tpl = new CGI::FastTemplate("templates");

    $tpl->no_strict;

    $tpl->define(row => "row.tpl", all => "all.tpl");

    for (1..2)
    {
        $tpl->assign(
            NUMBER  => $_,
            SQUARE  => $_**2,
            );
        $tpl->parse(ROWS => ".row");
    }

    $tpl->parse(CONTENT => "all");
    my $c = $tpl->fetch("CONTENT");

    if ($$c eq $expected)
    {
        print "ok 2\n";
    }
    else
    {
        print "not ok 2\n";
        print STDERR "  got:      '$$c' - " . length($$c) . "\n";
        print STDERR "  expected: '$expected' - " . length($expected) . "\n";

        # open(OUT, ">test1.out"); print OUT $$c; close(OUT);
        # open(OUT, ">test2.out"); print OUT $expected; close(OUT);

    }    
}


