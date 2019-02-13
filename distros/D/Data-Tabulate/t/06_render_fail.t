#!/usr/bin/env perl

use Data::Tabulate;
use Test::More;

use File::Basename;

use lib dirname(__FILE__);

my @array = (1..20);
my $obj   = Data::Tabulate->new();

$obj->min_columns(4);

{
    my $error = '';
    eval {
        $obj->render( 'Test', { } );
    } or $error = $@;

    like $error, qr/no data given/;
}

{
    my $error = '';
    eval {
        $obj->render( 'Test', undef );
    } or $error = $@;

    like $error, qr/no data given/;
}

{
    my $error = '';
    eval {
        $obj->render( 'Test', { data => {} } );
    } or $error = $@;

    like $error, qr/no data given/;
}

{
    my $error = '';
    eval {
        $obj->render( 'Test', [] );
    } or $error = $@;

    like $error, qr/no data given/;
}

{
    my $error = '';
    eval {
        $obj->render( undef, { data => [] } );
    } or $error = $@;

    like $error, qr/no renderer module given/;
}

{
    my $error = '';
    eval {
        $obj->render( 'ThisPluginWillHopefullyNeverExist', { data => [] } );
    } or $error = $@;

    like $error, qr/could not load/;
}

{
    my $error = '';
    eval {
        $obj->render( 'Fail', { data => [1,2] } );
    } or $error = $@;

    like $error, qr/renderer Data::Tabulate::Plugin::Fail does not have an output method/;
}

{
    my $error = '';

    $obj->do_func( 'Fail', 'order', 'asc' );

    eval {
        $obj->render( 'Fail', { data => [] } );
    } or $error = $@;

    like $error, qr/renderer does not know order/;
}

done_testing();
