package TestHelper::CreateTestFiles;

use strict;
use warnings;

use Test::TempDir::Tiny qw( tempdir );
use Path::Tiny qw( path );

use base qw(Exporter);
our @EXPORT_OK = qw( populated_tempdir );

sub populated_tempdir {

    # make a clean temp dir
    my $tempdir = path( tempdir() );
    $tempdir->remove_tree if -e $tempdir;
    $tempdir->mkpath;

    # create the temp files
    my $dir = path( $tempdir, 'src' );
    $dir->mkpath;

    # the main source file
    path( $dir, 'handler.pl' )->spew(<<'PERL');
use AWS::Lambda::Quick (
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

    # an example library
    path( $dir, 'lib' )->mkpath;
    path( $dir, 'lib', 'Greeting.pm' )->spew(<<'PERL');
package Greeting;
sub greeting {
    my $class = shift;
    my $name  = shift;

    return "Hello, $name";
}
1;
PERL

    return $tempdir;
}

1;
