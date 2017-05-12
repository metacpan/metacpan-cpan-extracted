
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
## - note: any way to redirect STDERR to /dev/null? (there is an expected warning
##         message that is printed in this test that is annoying.)
##
{

    my $pre  = '$1 and $10,000.00 and $PLAIN${CURLY} $NOEXISTok?';
    my $post = '$1 and $10,000.00 and the value of pi is:3.14 $NOEXISTok?';

    my $tpl = new CGI::FastTemplate();

    $tpl->strict;       ## should be on by default, but just to make sure...

    $tpl->define_nofile(row_nofile => $pre);

    $tpl->assign(
            PLAIN   => "the value of pi is:",
            CURLY   => "3.14",
            );

    print STDERR "\n  Note: Warning about 'no value found' is expected\n  ";
    $tpl->parse(CONTENT => "row_nofile");
    print STDERR "                    ";

    my $c = $tpl->fetch("CONTENT");

    if ($$c eq $post)
    {
        print "ok 2\n";
    }
    else
    {
        print "not ok 2\n";
        print STDERR "  pre:      '$pre'\n";
        print STDERR "  post:     '$$c'\n";
        print STDERR "  expected: '$post'\n";
    }    
}


