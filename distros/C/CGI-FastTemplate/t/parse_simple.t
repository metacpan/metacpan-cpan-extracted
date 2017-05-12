
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

    my $pre  = '$1 and $10,000.00 and $PLAIN${CURLY} $NOEXISTok?';
    my $post = '$1 and $10,000.00 and the value of pi is:3.14 ok?';

    my $tpl = new CGI::FastTemplate();

    $tpl->no_strict;

    $tpl->define_nofile(row_nofile => $pre);

    $tpl->assign(
            PLAIN   => "the value of pi is:",
            CURLY   => "3.14",
            );

    $tpl->parse(CONTENT => "row_nofile");

    my $c = $tpl->fetch("CONTENT");

    if ($$c eq $post)
    {
        print "ok 2\n";
    }
    else
    {
        print "not ok 2\n";
        #print "test: 'assign/define_nofile/parse' failed.\n";
        print STDERR "  pre:      '$pre'\n";
        print STDERR "  post:     '$$c'\n";
        print STDERR "  expected: '$post'\n";
    }    
}


