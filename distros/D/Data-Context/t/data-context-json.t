use strict;
use warnings;
use Test::More;
use Path::Tiny;
use AnyEvent;
use AnyEvent::HTTP;
use Test::Warn;

use Data::Context;

my $json = eval { require JSON::XS };
plan skip_all => 'This test requires JSON::XS, XML::Simple to be installed to run' if !$json || $@;

my $path = path($0)->parent->child('dc-json');

eval {
    test_creation();
    test_getting();
    test_getting_no_fallback();
};

ok !$@, 'No errors' or diag explain $@;
done_testing;

sub test_creation {
    my $dc = Data::Context->new( path => "$path" );
    isa_ok $dc, 'Data::Context', 'get a new object correctly';

    eval { Data::Context->new };
    ok $@, "Requires path";
}

sub test_getting {
    my $dc = Data::Context->new(
        path     => "$path",
        fallback => 1,
    );
    my $data = $dc->get( 'data', { test => { value => [qw/a b/] } } );

    ok $data, "get some data from ( 'data', { test => { value => [qw/a b/] } } )";
    is $data->{hash}{straight_var}, 'b', "Variable set to 'b'";

    $data = $dc->get( 'data', { test => { value => [qw/a new_val/] } } );

    is $data->{hash}{straight_var}, 'new_val', "Variable set to 'new_val'"
        or diag explain $data;

    $data = eval { $dc->get( 'data/with/deep/path', { test => { value => [qw/a b/] } } ) };
    my $error = $@;
    ok $data, "get some data from ( 'data/with/deep/path', { test => { value => [qw/a b/] } } )"
        or diag $error, $data;

    # test getting root index
    $data = eval { $dc->get( '/', { test => { value => [qw/a b/] } } ) };
    $error = $@;
    ok $data, "get some data from ( '/', { test => { value => [qw/a b/] } } )"
        or diag $error, $data;

    # test getting other deep dir
    $data = eval { $dc->get( '/non-existant/', { test => { value => [qw/a b/] } } ) };
    $error = $@;
    ok $data, "get some data from ( '/non-existant/', { test => { value => [qw/a b/] } } )"
        or diag explain $error, $data;
}

sub test_getting_no_fallback {
    my $dc = Data::Context->new(
        path     => "$path",
        fallback => 0,
    );

    my $data = eval { $dc->get( 'data/with/deep/path', { test => { value => [qw/a b/] } } ) };
    ok !$data, "get no data"
        or diag explain $data;

    $data = eval { $dc->get( 'defaultable', { test => { value => [qw/a b/] } } ) };
    my $e = $@;
    SKIP: {
        eval { require XML::Simple };
        skip "XML::Simple not installed", 1 if $@;
        ok $data, "get default data"
            or diag explain $e, $data;
    }
}

sub get_data {
    my ($self, $data ) = @_;

    my $cv = AnyEvent->condvar;

    http_get $data->{url}, sub { $cv->send( length $_[0] ); };

    return $cv;
}
