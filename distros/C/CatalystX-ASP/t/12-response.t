#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 24;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

use Moose;
use Path::Tiny;
use Mock::CatalystX::ASP;

BEGIN { use_ok 'CatalystX::ASP'; }
BEGIN { use_ok 'CatalystX::ASP::Response'; }

my ( $script, $htmlref );

my $root = path( $FindBin::Bin, '../t/lib/TestApp/root' )->realpath;

my $asp = CatalystX::ASP->new(
    c             => mock_c,
    GlobalPackage => mock_asp->GlobalPackage,
    Global        => $root,
);
my $Response = $asp->Response;

tie local *STDOUT, 'CatalystX::ASP::Response';

$Response->AddHeader( 'X-Foo', 'bar' );
is( mock_c->response->headers->header( 'X-Foo' ),
    'bar',
    '$Response successfully set X-Foo header'
);
print "THIS GOES TO THE CLIENT\n";
like( $Response->Body,
    qr/THIS GOES TO THE CLIENT/,
    'print STDOUT goes to $Response->Body'
);
printf "THIS ALSO GOES TO THE CLIENT\n";
like( $Response->Body,
    qr/THIS ALSO GOES TO THE CLIENT/,
    'printf STDOUT goes to $Response->Body'
);
$Response->AppendToLog( 'a debug message' );
ok( grep( /a debug message/, @{ mock_c->log->_get_logs( 'debug' ) } ),
    '$Response->AppendToLog added to proper debug log'
);
$Response->BinaryWrite( "THIS ALSO ALSO GOES TO THE CLIENT\n" );
like( $Response->Body,
    qr/THIS ALSO ALSO GOES TO THE CLIENT/,
    '$Response->BinaryWrite goes to $Response->Body'
);
$Response->WriteRef( \"THIS ALSO ALSO ALSO GOES TO THE CLIENT\n" );
like( $Response->Body,
    qr/THIS ALSO ALSO ALSO GOES TO THE CLIENT/,
    '$Response->WriteRef goes to $Response->Body'
);
$Response->Flush;
like( $Response->Body,
    qr/THIS ALSO ALSO ALSO GOES TO THE CLIENT/,
    '$Response->Body contains expected output after $Response->Flush'
);
$Response->Write( "THIS SHOULD NOT GO TO THE CLIENT\n" );
$Response->Clear;
like( $Response->Body,
    qr/THIS ALSO ALSO ALSO GOES TO THE CLIENT/,
    '$Response->Body contains expected output after $Response->Flush and $Response->Clear'
);
unlike( $Response->Body,
    qr/THIS SHOULD NOT GO TO THE CLIENT/,
    '$Response->Body doesn\'t contain unexpected output after $Response->Clear'
);
$Response->Cookies( 'foo', 'bar' );
$Response->_flush_Cookies( mock_c );
is( mock_c->response->cookies->{foo}{value},
    'bar',
    '$Response->Cookies wrote out simple cookie'
);
$Response->Cookies( 'foofoo', 'baz', 'bar' );
$Response->_flush_Cookies( mock_c );
is_deeply( mock_c->response->cookies->{foofoo}{value},
    ['baz=bar'],
    '$Response->Cookies wrote out correct hash cookie'
);
$Response->Cookies( 'foofoo', 'bar', 'baz' );
$Response->_flush_Cookies( mock_c );

# Using grep because order doesn't matter
is( grep( /baz=bar|bar=baz/, @{ mock_c->response->cookies->{foofoo}{value} } ),
    2,    # Obscure, but 2 means 2 elements matched a regex with two possibilities
    '$Response->Cookies wrote out correct more complex hash cookie'
);

# This is for code coverage, not really going to check it
$Response->Debug( { foo => 'bar', bar => 'foo' } );
throws_ok( sub { $Response->End },
    'CatalystX::ASP::Exception::End',
    '$Response->End threw an End exception'
);
is( $Response->ErrorDocument,
    undef,
    'Unimplemented method $Response->ErrorDocument'
);
$Response->Include( 'templates/some_other_template.inc' ),
    like( $Response->Body,
    qr|<p>I've been included!</p>|,
    '$Response->Include wrote out template into $Response->Body'
    );
$script = "<%= q(I've also been included!) %>";
$Response->Include( \$script );
like( $Response->Body,
    qr|I've also been included!|,
    '$Response->Include wrote out script ref into $Response->Body'
);
is( $Response->IsClientConnected,
    1,
    '$Response->IsClientConnected will always return 1'
);
throws_ok( sub { $Response->Redirect( '/hello_world.asp' ) },
    'Catalyst::Exception::Detach',
    '$Response->Redirect threw a Detach exception'
);
is( mock_c->response->location,
    '/hello_world.asp',
    '$Response->Redirect set location in response'
);
is( mock_c->response->status,
    302,
    '$Response->Redirect set status to 302 in response'
);
$script  = "<%= q(I've also also been included!) %>";
$htmlref = $Response->TrapInclude( \$script );
unlike( $Response->Body,
    qr|I've also also been included!|,
    '$Response->TrapInclude didn\'t write to $Response->Body'
);
like( $$htmlref,
    qr|I've also also been included!|,
    '$Response->TrapInclude returned correct captured output in ref'
);
