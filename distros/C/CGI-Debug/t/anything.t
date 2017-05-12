# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# util
sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

require 5.004_05;
use Config; $perl = $Config{'perlpath'};

test(2, `$perl t/anything/working_html.cgi` eq <<EOT);
Content-type: text/html

a1
<hr><h2>t/anything/working_html.cgi</h2>
<plaintext>

<EOF>
EOT
    ;


test(3, `$perl t/anything/working_text.cgi` eq <<EOT);
Content-type: something/else

a1


------------------------------------------------------------

	t/anything/working_text.cgi



<EOF>
EOT
    ;


