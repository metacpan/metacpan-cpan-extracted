#!perl

=head1 NAME

pod-source.t - Tests that the POD in the I<source files> is clean
enough to display on CPAN

Just delete this test if you don't plan on publishing your module.

=cut

use strict;
use Test::More;
use File::Spec::Functions;
use File::Slurp qw(read_file);
use File::Find;

plan(skip_all => "Test::Pod 1.14 required for testing POD"), exit unless
    eval "use Test::Pod 1.14; 1";
plan(skip_all => "Pod::Text required for testing POD"), exit unless
    eval "use Pod::Text; 1";

my @files = Test::Pod::all_pod_files("lib");
plan(skip_all => "no POD (yet?)"), exit if ! @files;

plan( tests => 3 * scalar (@files) );

my $out = catfile(qw(t pod-out.tmp));

foreach my $file ( @files ) {
    pod_file_ok( $file, $file );

=pod

We also check that the internal and test suite documentations are
B<not> visible in the POD (coz this just looks funny on CPAN)

=cut

    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file($file, $out);
    my $result = read_file($out);
    unlike($result, qr/^TEST SUITE/m,
           "Test suite documentation is podded out");
    unlike($result, qr/^INTERNAL/,
           "Internal documentation is podded out");
}

unlink($out);

