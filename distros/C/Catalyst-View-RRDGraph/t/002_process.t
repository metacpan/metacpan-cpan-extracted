# -*- perl -*-

# t/002_process.t - check processing

use FindBin qw($Bin);
use lib "$Bin/lib";	# Need for dummy RRDs libs
use RRDs;
use Test::More tests => 9;
use Test::MockObject;
use File::Spec;

SKIP: {
    eval { require RRDs; };
    skip "RRDs not installed", 9 if $@;

    use_ok( 'Catalyst::View::RRDGraph' );
    use_ok( 'Catalyst::Helper::View::RRDGraph');

    my $log = Test::MockObject->new();
    my $c = Test::MockObject->new();
    my $stash = {};
    my $served_filename;
    my $log_error;
    $c->mock( "stash", sub { $stash } );
    $c->mock( "serve_static_file", sub { shift; $served_filename = shift } );
    $c->mock( "log", sub { $log } );
    $c->mock( "error", sub { shift; $log_error = shift } );

    my $object = Catalyst::View::RRDGraph->new($c);
    isa_ok ($object, 'Catalyst::View::RRDGraph');

    eval { $object->process( $c ) };
    like( $@, "/No graph in the stash/", "No graph in stash" );

    $stash->{graph} = "bob";
    eval { $object->process( $c ) };
    like( $@, "/graph must be an ARRAYREF/", "Variable incorrect" );

    $stash->{graph} = [qw(here in barcelona)];
    RRDs->simulate_graph_generation(0);
    eval { $object->process( $c ) };
    like( $@, "/RRDgraph is 0 bytes/", "Picked up 0 byte file" );


    RRDs->simulate_graph_generation(1);
    $object->process($c);
    my $path_regex = quotemeta(File::Spec->catfile(
        File::Spec->rootdir, 'tmp', 'cat_view_rrd_'
    )) . '.*\.png';
    like( $served_filename, qr($path_regex), "Got served file" );
    my $graph_input = RRDs->graph_input;
    shift @$graph_input; 		# This is the temporary filename, so ignore for now
    is_deeply( $graph_input, [
        "--imgformat",
        "PNG",
        "here",
        "in",
        "barcelona",
    ], "graph input correct" );

    RRDs::error("Setting an error");
    eval { $object->process( $c ) };
    like( $@, qr/Setting an error/, "RRD error caught" );
}

