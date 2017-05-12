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
use strict;
use warnings;

my $root_dir = tempdir_simple('Code-TidyAll-XXXX');

sub make {
    my ( $file, $content ) = @_;
    $file = "$root_dir/$file";
    mkpath( dirname($file), 0, 0775 );
    write_file( $file, $content );
}

sub make_foo {
    make(
        "lib/Foo.pm",
        'package Foo;
  use strict;

method foo   {
 print "hi\n";
}

method bar   ( $x )   {
 print "$x\n";
}


method baz   (  $y, $z)   {
 print "$y, $z\n";
}

method foo2  
{
 print "hi\n";
}

method bar2   ($x  )  
{
 print "$x\n";
}


method baz2   ($y, $z)
{
 print "$y, $z\n";
}

1;
'
    );
}

make_foo();
my $ct = Code::TidyAll->new(
    root_dir => $root_dir,
    plugins  => {
        PerlTidy                             => { select => '**/*.{pl,pm}' },
        'Perl::IgnoreMethodSignaturesSimple' => { select => '**/*.{pl,pm}' },
    }
);
my $output = capture_merged { $ct->process_all() };
is( $output, "[tidied]  lib/Foo.pm\n", "tidied msg" );
is(
    read_file("$root_dir/lib/Foo.pm"),
    'package Foo;
use strict;

method foo () {
    print "hi\n";
}

method bar ($x) {
    print "$x\n";
}

method baz ($y, $z) {
    print "$y, $z\n";
}

method foo2 () {
    print "hi\n";
}

method bar2 ($x) {
    print "$x\n";
}

method baz2 ($y, $z) {
    print "$y, $z\n";
}

1;
',
    "tidied content"
);

make_foo();
$ct = Code::TidyAll->new(
    root_dir => $root_dir,
    plugins  => {
        PerlTidy => { select => '**/*.{pl,pm}', argv => '-bl' },
        'Perl::IgnoreMethodSignaturesSimple' => { select => '**/*.{pl,pm}' },
    }
);

$output = capture_merged { $ct->process_all() };
is( $output, "[tidied]  lib/Foo.pm\n", "tidied msg - -bl" );
is(
    read_file("$root_dir/lib/Foo.pm"),
    'package Foo;
use strict;

method foo ()
{
    print "hi\n";
}

method bar ($x)
{
    print "$x\n";
}

method baz ($y, $z)
{
    print "$y, $z\n";
}

method foo2 ()
{
    print "hi\n";
}

method bar2 ($x)
{
    print "$x\n";
}

method baz2 ($y, $z)
{
    print "$y, $z\n";
}

1;
',
    'tidied content - -bl'
);

done_testing();
