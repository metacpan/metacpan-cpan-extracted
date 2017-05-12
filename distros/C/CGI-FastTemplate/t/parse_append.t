

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
## parse rows (append)
##

{
    my $tpl = new CGI::FastTemplate;
    $tpl->strict;

    $tpl->define_nofile(    all => '<ALL>$ROWS</ALL>',
                            row => '<ROW>$NUMBER:${SQUARE}</ROW>',
                            );

    my $n;
    for $n (1..3)
    {
        $tpl->assign(   NUMBER  => $n,  
                        SQUARE  => $n*$n,
                        );
        $tpl->parse(ROWS => ".row");
    }

    $tpl->parse(CONTENT    => "all");
    my $c = $tpl->fetch("CONTENT");

    if ($$c eq '<ALL><ROW>1:1</ROW><ROW>2:4</ROW><ROW>3:9</ROW></ALL>')
    {
        print "ok 2\n";
    }
    else
    {
        print "not ok 2\n";
    }    
}


