package TestApp;
use strict;
use warnings;

use Catalyst::Runtime '5.70';

use Catalyst qw/
    -Debug
    Mode
/;

our $VERSION = '0.01';

my $config = {
    'Catalyst::Plugin::Mode' => {
        keys => [qw/any another/],
        mode => 'test'
    },
    any => {
        dev => {
            one_url => 'http://dev_one_url',
            two_url => 'http://dev_two_url'
        },    
        test => {
            one_url => 'http://test_one_url',
            two_url => 'http://test_two_url'
        },   
        prod => {
            one_url => 'http://prod_one_url',
            two_url => 'http://prod_two_url'
        },
    },    
    another => {
        dev => {
            one_url => 'http://another_dev_one_url',
            two_url => 'http://another_dev_two_url'
        },    
        test => {
            one_url => 'http://another_test_one_url',
            two_url => 'http://another_test_two_url'
        },    
        prod => {
            one_url => 'http://another_prod_one_url',
            two_url => 'http://another_prod_two_url'
        },
    }
};

__PACKAGE__->config($config);

# Start the application
__PACKAGE__->setup;

package TestApp::Controller::Root;
use strict;
use warnings;
use base 'Catalyst::Controller';
use Data::Dumper;

sub index : Private {
    my($self,$c) = @_;
    $c->res->content_type('text/plain');
    $c->res->output(Dumper $c->config);
    return;
}

package main;
use Test::More qw/no_plan/;
use FindBin qw($Bin);
use lib $Bin.'/../lib';
BEGIN { use_ok('Catalyst::Plugin::Mode') };
use Data::Dumper;

my $conf = TestApp->config;
is($conf->{any}->{one_url},'http://test_one_url',"Check url from config: ".$conf->{any}->{one_url});
is($conf->{any}->{two_url},'http://test_two_url',"Check url from config: ".$conf->{any}->{one_url});
is($conf->{another}->{one_url},'http://another_test_one_url',"Check url from config: ".$conf->{any}->{one_url});
is($conf->{another}->{two_url},'http://another_test_two_url',"Check url from config: ".$conf->{any}->{two_url});
isnt($conf->{another}->{test}->{one_url},'',"No such url in config: ".Dumper $conf->{another}->{test});
isnt($conf->{another}->{test}->{two_url},'',"No such url in config: ".Dumper $conf->{another}->{test});
isnt($conf->{any}->{test}->{one_url},'',"No such url in config: ".Dumper $conf->{any}->{test});
isnt($conf->{any}->{test}->{two_url},'',"No such url in config: ".Dumper $conf->{any}->{test});

1;
