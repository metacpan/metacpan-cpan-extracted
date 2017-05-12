#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use Code::TidyAll::Util qw(dirname mkpath read_file tempdir_simple write_file);
use Code::TidyAll;
use Test::More;
use Capture::Tiny qw(capture_merged);

my $root_dir = tempdir_simple('Code-TidyAll-XXXX');

sub make {
    my ( $file, $content ) = @_;
    $file = "$root_dir/$file";
    mkpath( dirname($file), 0, 0775 );
    write_file( $file, $content );
}

make(
    "lib/Foo.pm",
    "package Foo;
  use Moose;

has  'driver_class'  => ( is => 'ro' );
has   'constructor_params' =>   ( is => 'ro', init_arg => undef );
has 'compress_threshold' => ( is => 'ro', isa => 'Int' );
has 'expires_at'              => ( is => 'rw', default => CHI_Max_Time );
has 'chi_root_class'     => ( is => 'ro' );
1;
"
);

my $ct = Code::TidyAll->new(
    root_dir => $root_dir,
    plugins  => {
        PerlTidy                     => { select => '**/*.{pl,pm}' },
        'Perl::AlignMooseAttributes' => { select => '**/*.{pl,pm}' },
    }
);

my $output;
$output = capture_merged { $ct->process_all() };
is( $output, "[tidied]  lib/Foo.pm\n" );
is (scalar(read_file("$root_dir/lib/Foo.pm")),
    "package Foo;
use Moose;

has 'chi_root_class'     => ( is => 'ro' );
has 'compress_threshold' => ( is => 'ro', isa => 'Int' );
has 'constructor_params' => ( is => 'ro', init_arg => undef );
has 'driver_class'       => ( is => 'ro' );
has 'expires_at'         => ( is => 'rw', default => CHI_Max_Time );

1;
", "tidied");

done_testing();
