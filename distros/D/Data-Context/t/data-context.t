use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Data::Dumper qw/Dumper/;
use AnyEvent;
use AnyEvent::HTTP;
use Test::Warn;

use Data::Context;

eval { require JSON; require XML::Simple; require YAML::XS; };
plan skip_all => 'This test requires JSON, XML::Simple and YAML::XS to be installed to run' if $@;

my $path = path($0)->parent->child('dc');

test_creation();
test_getting();
test_getting_no_fallback();
test_log();

done_testing;

sub test_creation {
    my $dc = Data::Context->new( path => "$path" );
    isa_ok $dc, 'Data::Context', 'get a new object correctly';

    eval { Data::Context->new };
    like $@, qr/\bpath\b.*is\s+required/, "Requires path";
}

sub test_getting {
    my $dc = Data::Context->new(
        path     => "$path",
        fallback => 1,
    );
    my $data = $dc->get( 'data', { test => { value => [qw/a b/] } } );

    ok $data, "get some data from ( 'data', { test => { value => [qw/a b/] } } )";
    is $data->{hash}{straight_var}, 'b', "Variable set to 'b'"
        or diag explain $data;

    $data = $dc->get( 'data', { test => { value => [qw/a new_val/] } } );

    is $data->{hash}{straight_var}, 'new_val', "Variable set to 'new_val'";
    #diag Dumper $data;

    $data = eval { $dc->get( 'data/with/deep/path', { test => { value => [qw/a b/] } } ) };
    my $error = $@;
    #diag Dumper $data;
    ok $data, "get some data from ( 'data/with/deep/path', { test => { value => [qw/a b/] } } )"
        or diag $error;

    # test getting root index
    $data = eval { $dc->get( '/', { test => { value => [qw/a b/] } } ) };
    $error = $@;
    #diag Dumper $data;
    ok $data, "get some data from ( '/', { test => { value => [qw/a b/] } } )"
        or diag $error;

    # test getting other deep dir
    $data = eval { $dc->get( '/non-existant/', { test => { value => [qw/a b/] } } ) };
    $error = $@;
    #diag Dumper $data;
    ok $data, "get some data from ( '/non-existant/', { test => { value => [qw/a b/] } } )"
        or diag Dumper $error, $data;
}

sub test_getting_no_fallback {
    my $dc = Data::Context->new(
        path     => "$path",
        fallback => 0,
    );

    my $data = eval { $dc->get( 'data/with/deep/path', { test => { value => [qw/a b/] } } ) };
    #diag Dumper $data;
    ok !$data, "get no data";

    $data = eval { $dc->get( 'defaultable', { test => { value => [qw/a b/] } } ) };
    my $e = $@;
    #diag Dumper $data;
    SKIP: {
        eval { require XML::Simple };
        skip "XML::Simple not installed", 1 if $@;
        ok $data, "get default data"
            or diag "Error $e";
    }
}

sub test_log {
    my $dc = Data::Context->new( path => "$path" );
    is $dc->debug, 3, 'default debug level is 3';
    $dc->debug(2);
    is $dc->debug, 2, 'debug level is now 2';

    is ref $dc->log, 'Data::Context::Log', 'Get log object';

    $dc->log($dc);
    $dc->debug(1);
    is $dc->debug, 1, 'debug level is now 1';
}

sub get_data {
    my ($self, $data ) = @_;

    my $cv = AnyEvent->condvar;

    http_get $data->{url}, sub { $cv->send( length $_[0] ); };

    return $cv;
}
