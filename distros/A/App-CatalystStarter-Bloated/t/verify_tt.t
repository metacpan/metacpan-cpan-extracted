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
    $view_with_wrong_extension,
    $view_with_missing_wrapper,
    $view_where_all_is_ok
);

local %ARGV = test_argv( "--TT" => "HTML" );

## Need to import these or there will be trouble when the perl module
## code doesn't load
use Catalyst::View;
use Catalyst::View::TT;

$ARGV{'--name'} = "Foo";

my $f1 = Path::Tiny->tempfile;
$f1->spew( $view_with_syntax_error );
stderr_like(
    sub { App::CatalystStarter::Bloated::_verify_TT_view($f1) },
    qr/ contains errors and must be edited by hand\./,
    "view with syntax error handled correctly"
);

$ARGV{'--name'} = "Bar";

my $f2 = Path::Tiny->tempfile;
$f2->spew( $view_with_wrong_extension );
stderr_like(
    sub { App::CatalystStarter::Bloated::_verify_TT_view($f2) },
    qr/ didn't get TEMPLATE_EXTENSION properly configured, must be fixed manually\./,
    "view with wrong extension handled correctly"
);

$ARGV{'--name'} = "Baz";
my $f3 = Path::Tiny->tempfile;
$f3->spew( $view_with_missing_wrapper );
stderr_like(
    sub { App::CatalystStarter::Bloated::_verify_TT_view($f3) },
    qr/ didn't get WRAPPER properly configured, must be fixed manually\./,
    "view with wrapper not set handled correctly"
);

$ARGV{'--name'} = "Test";
my $f4 = Path::Tiny->tempfile;
$f4->spew( $view_where_all_is_ok );
stderr_is(
    sub { App::CatalystStarter::Bloated::_verify_TT_view($f4) },
    "", "view where all is ok gives no error"
);

done_testing;

BEGIN {

    $view_with_syntax_error = <<'EOV';
package Foo::View::HTML;

use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
syntax error
    WRAPPER => 'wrapper.tt2',
    TEMPLATE_EXTENSION => '.tt2',
    render_die => 1,
);

1;
EOV

    $view_with_wrong_extension = <<'EOV';
package Bar::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    WRAPPER => 'wrapper.tt2',
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

1;
EOV

    $view_with_missing_wrapper = <<'EOV';
package Baz::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt2',
    render_die => 1,
);

1;
EOV

    $view_where_all_is_ok = <<'EOV';
package Test::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    WRAPPER => 'wrapper.tt2',
    TEMPLATE_EXTENSION => '.tt2',
    render_die => 1,
);

1;
EOV


}
