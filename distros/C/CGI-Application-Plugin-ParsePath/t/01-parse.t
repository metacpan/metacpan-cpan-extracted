#!perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use MyTestApp;
use Test::More tests => 6;
use Data::Dumper;
use Storable qw/thaw/;

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = 'GET';

use CGI;

sub app {
    my $q = new CGI;
    my $app = new MyTestApp->new(
        QUERY=>$q,
        PARAMS => {
            'table' => [
                ''                         => {rm => 'recent'},
                '/posts/:category'          => {rm => 'posts' },
                '/date/:year/:month?/:day?' => {
                    rm          => 'by_date',
                },
                '/:rm/:id'             => { },
            ]
        }
    );
    return $app;
}
    
my @tests = (
    ['default','/', {'rm' => 'recent'}],
    ['none','', {'rm' => 'recent'}],
    ['posts','/posts/3', {'rm' => 'posts', 'category' => '3'}],
    ['date','/date/2004', {'rm' => 'by_date','month' => '','day' => '','year' => '2004'}],
    ['freeform','/edit/1234',{'rm' => 'edit','id' => '1234'}],
    ['extra_param', '/posts/12/13', {}],
);

foreach my $test (@tests) {
    my $testname = $test->[0];
    local $ENV{PATH_INFO} = $test->[1];
    
    my $t = app->run;
    my $expected = $test->[2];
    is_deeply (thaw($t), $expected, $testname);
}
    
