package main;

use 5.010;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

BEGIN {
    eval {
	require Test::Pod::LinkCheck::Lite;
	Test::Pod::LinkCheck::Lite->import( ':const' );
	1;
    } or plan skip_all => 'Unable to load Test::Pod::LinkCheck::Lite';
}

Test::Pod::LinkCheck::Lite->new(
    # TODO - drop when published to GitHub
    ignore_url		=> qr< \A https://github.com/ >smx,
    prohibit_redirect	=> ALLOW_REDIRECT_TO_INDEX,
)->all_pod_files_ok(
    qw{ blib eg },
);

done_testing;

1;

# ex: set textwidth=72 :
