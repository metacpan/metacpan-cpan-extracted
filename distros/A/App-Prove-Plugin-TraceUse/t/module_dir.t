#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;# tests => 2;
use File::Temp qw/tempdir/;
use File::Spec;
use Carp;

use App::Prove::Plugin::TraceUse;

cmp_deeply( [App::Prove::Plugin::TraceUse::_module_dir("Test::Most")],
            subbagof(@INC),
            "module dir Test::Most is ok" );

cmp_deeply( [App::Prove::Plugin::TraceUse::_module_dir("App::Prove")],
            subbagof(@INC),
            "module dir of App::Prove is ok" );

{

    local %ENV;

    my $td = tempdir( CLEANUP => 1 );
    my $d = File::Spec->catdir( $td, "App" );
    mkdir $d or confess $!;

    ok( -d $d, "temp pm directory ($d) is valid" );

    my $pm_file = File::Spec->catfile( $d, "Prove.pm" );
    open my $fh, ">", $pm_file or confess $!;

    print $fh <<EOT;
package App::Prove;

1;

=head1 NAME
EOT

    close $fh;

    ok( -s $pm_file, "temp pm has content, " . (-s $pm_file) . " bytes" );

    $ENV{PERL5LIB} = $td;

    my @inc = App::Prove::Plugin::TraceUse::_system_inc;
    my @noninc = App::Prove::Plugin::TraceUse::_system_inc(1);

    cmp_bag( \@noninc, [$td, "."], "tmp dir correctly set up" );

    my $mdir = App::Prove::Plugin::TraceUse::_module_dir("App::Prove");
    my $mdir_n = App::Prove::Plugin::TraceUse::_module_dir("App::Prove", 1);

    ok( -d $mdir, "App::Prove found as normal in \@INC");

    ok( -d $mdir_n, "fake App::Prove module found in custom PERL5LIB" );

}

done_testing();
