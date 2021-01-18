use strict;
use warnings FATAL => 'all';
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_cmp);
use lib 't';
use File::Slurp qw(slurp);

# Test minification with an explicitly specified minifier.
plan tests => 2, need_lwp;

# JavaScript::Minifier
js_minifier: {
    my $body = GET_BODY '/explicit/pp';
    my $min  = slurp('t/htdocs/minified.txt');
    chomp($min);
    chomp($body);

    ok( t_cmp($body, $min) );
}

# JavaScript::Minifier::XS
js_minifier_xs: {
    eval { require JavaScript::Minifier::XS };
    if ($@) {
        skip "JavaScript::Minifier::XS not installed";
    }
    else {
        my $body = GET_BODY '/explicit/xs';
        my $min  = slurp('t/htdocs/minified-xs.txt');
        chomp($min);
        chomp($body);

        ok( t_cmp($body, $min) );
    }
}
