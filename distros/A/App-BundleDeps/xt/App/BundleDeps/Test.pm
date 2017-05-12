package xt::App::BundleDeps::Test;
use strict;
use warnings;
use base qw(Exporter);
use App::BundleDeps;
use File::Path;
use File::Spec;
use Test::More;

our @EXPORT = qw(test_bundle);

sub test_bundle ($) {
    my $module = shift;
    my $file = (caller())[1];
    my $extlib = File::Spec->catfile($file . join("-", "", "extlib", time(), $$, rand() ) );
    my $app = App::BundleDeps->new(
        extlib => $extlib,
        notest => 1,
    );

    $app->setup_deps( $module );
    $app->bundle();

    my $ok = 
        ok( system($^X, "-Mlocal::lib=$extlib", "-M$module", '-e', "'print 1'") == 0,
        "$module is installed in $extlib" );
    if ($ok) {
        rmtree($extlib);
    }
}

1;