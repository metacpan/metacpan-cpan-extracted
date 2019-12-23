#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Path::Tiny qw(path);
use lib path( $FindBin::Bin, 'lib' )->stringify;

use Test2::V0;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use AWS::Lambda::Quick::CreateZip ();
use TestHelper::CreateTestFiles qw(populated_tempdir);

my $tempdir      = populated_tempdir();
my $zip_filename = path( $tempdir, 'handler.zip' );

AWS::Lambda::Quick::CreateZip->new(
    src_filename => path( $tempdir, 'src', 'handler.pl' ),
    zip_filename => $zip_filename,

    extra_files => ['lib'],
)->create_zip;

ok( -e $zip_filename, 'zip exists' );

my $z = Archive::Zip->new();
ok( $z->read( $zip_filename->stringify ) == AZ_OK, 'read zip okay' );

is( $z->contents('handler.pl'), <<'PERL', 'hander.pl was stored ok' );
BEGIN{$INC{'AWS/Lambda/Quick.pm'}=1} use AWS::Lambda::Quick (
    name => 'whatever',
    extra_files => 'lib',
);

use lib qw(lib);
use Greeting;
use JSON::PP qw( encode_json );

sub handler {
    my $data = shift;

    return {
        statusCode => 200,
        headers => {
            'Content-Type' => 'text/plain',
        },
        body => Greeting->greeting( $data->{queryStringParameters}{who} ),
    };
}
1;
PERL

is( $z->contents('lib/Greeting.pm'), <<'PERL', 'Greeting.pm was stored ok' );
package Greeting;
sub greeting {
    my $class = shift;
    my $name  = shift;

    return "Hello, $name";
}
1;
PERL

done_testing;
