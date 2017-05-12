use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp t_write_perl_script);
use File::Spec::Functions qw(catfile);
use lib 't';
use MY::slurp;

# Test filtered mod_cgi output
plan tests => 4, (need_lwp && need_cgi);

# Get test config
my $svrroot = Apache::Test::vars('serverroot');
my $docroot = Apache::Test::vars('documentroot');


# CGI, plain text should be un-altered
cgi_unaltered: {
    # create CGI script
    t_write_perl_script(
        catfile($svrroot, qw(cgi-bin plain.cgi)),
        qq{ use lib "$svrroot";
            use MY::slurp;
            print "Content-Type: text/plain\\n\\n";
            print slurp("$docroot/test.css");
        } );

    # test script
    my $res  = GET '/cgi-bin/plain.cgi';
    my $body = $res->content;
    my $orig = slurp('t/htdocs/test.txt');

    ok( $res->content_type eq 'text/plain' );
    ok( t_cmp($body, $orig) );
}

# CGI, CSS should be minified: {
cgi_minified: {
    # create CGI script
    t_write_perl_script(
        catfile($svrroot, qw(cgi-bin css.cgi)),
        qq{ use lib "$svrroot";
            use MY::slurp;
            print "Content-Type: text/css\\n\\n";
            print slurp("$docroot/test.css");
        } );

    # test script
    my $res  = GET '/cgi-bin/css.cgi';
    my $body = $res->content;
    my $min  = slurp('t/htdocs/minified.txt');
    chomp($min);

    ok( $res->content_type eq 'text/css' );
    ok( t_cmp($body, $min) );
}
