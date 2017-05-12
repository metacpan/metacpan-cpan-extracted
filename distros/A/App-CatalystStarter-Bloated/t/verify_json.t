#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
use Test::FailWarnings;
use Test::Output;

use Path::Tiny;

use lib 't/lib';
use TestUtils;

use_ok "App::CatalystStarter::Bloated";

my(
    $view_with_syntax_error,
    $view_with_missing_config,
);

local %ARGV = test_argv( "--JSON" => "JSON" );

## Need to import these or there will be trouble when the perl module
## code doesn't load
use Catalyst::View;
use Catalyst::View::JSON;

$ARGV{'--name'} = "Foo";

my $f1 = Path::Tiny->tempfile;
$f1->spew( $view_with_syntax_error );
stderr_like(
    sub { App::CatalystStarter::Bloated::_verify_JSON_view($f1) },
    qr/ contains errors and must be edited by hand\./,
    "view with syntax error handled correctly"
);

$ARGV{'--name'} = "Bar";

my $f2 = Path::Tiny->tempfile;
$f2->spew( $view_with_missing_config );
stderr_like(
    sub { App::CatalystStarter::Bloated::_verify_JSON_view($f2) },
    qr/\Q didn't get expose_stash properly configured, must be fixed manually, expected to be ['json']./,
    "view with missing export_stash handled"
);

done_testing;

BEGIN {

    $view_with_syntax_error = <<'EOV';
package Foo::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

__PACKAGE__->config(
syntax error
    # expose only the json key in stash
    expose_stash => [ qw(json) ],
);

1;
EOV

    $view_with_missing_config = <<'EOV';
package Bar::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

1;
EOV

}
