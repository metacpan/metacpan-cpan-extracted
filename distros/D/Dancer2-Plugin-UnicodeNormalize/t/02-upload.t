use strict;
use warnings;

use utf8;
use autodie;

use Test::More tests => 2;
use t::lib::TestApp;

use FindBin;
use Plack::Test;
use HTTP::Request::Common;

my $files = "$FindBin::Bin/files";

open my $f1, '<:utf8', "${files}/1.txt";
open my $f2, '<:utf8', "${files}/2.txt";
chomp(my $string1 = <$f1>);
chomp(my $string2 = <$f2>);
close ($f1);
close ($f2);

isnt ($string1,  $string2, "Initial conditions: strings in files not equal");

test_psgi( t::lib::TestApp::dance, sub {
    my ($app) = @_;

    my $response = $app->( POST '/upload',
        Content_Type => 'form-data',
        Content => [
            file1 => [ "${files}/1.txt" ],
            file2 => [ "${files}/2.txt" ],
        ],
    );

    is $response->content => 'ne', 'Content in uploaded files should not be normalized';
} );

