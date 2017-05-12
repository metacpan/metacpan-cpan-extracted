#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 15;

use FindBin;
use lib "$FindBin::Bin/lib";

use Moose;
use Path::Tiny;
use Mock::CatalystX::ASP;

BEGIN { use_ok 'CatalystX::ASP'; }
BEGIN { use_ok 'CatalystX::ASP::Request'; }

my $root = path( $FindBin::Bin, '../t/lib/TestApp/root' )->realpath;

my $asp = CatalystX::ASP->new(
    c             => mock_c,
    GlobalPackage => mock_asp->GlobalPackage,
    Global        => $root,
);
my $Request = $asp->Request;

is( $Request->BinaryRead( 26 ),
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    '$Request->BinaryRead got correct data back'
);
is( $Request->ClientCertificate,
    undef,
    'Unimplemented method $Request->ClientCertificate'
);
is( $Request->Cookies( 'foo' ),
    'bar',
    '$Request->Cookies returned simple cookie'
);
is( $Request->Cookies( 'foofoo', 'baz' ),
    'bar',
    '$Request->Cookies returned correct hash cookie'
);
is( $Request->Cookies( 'foofoo', 'bar' ),
    'baz',
    '$Request->Cookies returned correct hash cookie'
);
is( $Request->FileUpload( 'foofile', 'ContentType' ),
    'plain/text',
    '$Request->FileUpload returned correct Content-Type'
);
is( $Request->FileUpload( 'foofile', 'BrowserFile' ),
    'foo.txt',
    '$Request->FileUpload returned correct uploaded filename'
);
is( $Request->Form( 'foo' ),
    'bar',
    '$Request->Form returned correct form value'
);
my %form = %{ $Request->Form };
is( $form{foo},
    'bar',
    '$Request->Form hash returned correct form value'
);
is( $Request->Params( 'foobar' ),
    'baz',
    '$Request->Params returned correct parameter value'
);
is( $Request->Params( 'bar' ),
    'foo',
    '$Request->Params returned correct parameter value'
);
is( $Request->QueryString( 'foobar' ),
    'baz',
    '$Request->QueryString returned correct query string value'
);
like( $Request->ServerVariables( 'PATH' ),
    qr|.|,
    '$Request->ServerVariables contains environment variables'
);
