use strict;
use warnings;
use Test::More;
use B::Deparse;
use FindBin;
use lib "$FindBin::Bin/lib/TestApp/lib";

use Catalyst::Test 'TestApp';

{
	my $c = new TestApp();
	my $features = $c->features;
	ok( ref $features, 'there are features' );

    ok(
        grep( m{/TestApp/root/static/main.js$},
            $c->path_to( 'root', 'static', 'main.js' ) ),
        'normal path_to works'
    );

    ok(
        grep( m{/TestApp/features/FEATURE/root/ff.js$},
            $c->path_to( 'root', 'ff.js' ) ),
        'feature path_to works'
    );

	my @list = $c->features->list;
	is( scalar @list, 5, 'five features' );
}

# not ready yet
#{
#    my $resp = request('/test/init');
#    is($resp->content, 'value: 99', 'feature main module init');
#}

done_testing;
