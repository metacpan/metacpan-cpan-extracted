#!perl

# test !path and !paths encodings

use 5.010;
use strict;
use warnings;

use Config::IOD;
#use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use Test::More 0.98;

sub _create_file { open my($fh), ">", $_[0] }

my $tempdir = tempdir(CLEANUP => 1);
_create_file("$tempdir/f1", "");
_create_file("$tempdir/f2", "");
_create_file("$tempdir/g1", "");

my @pw = getpwuid($>);

# the rest of the test is performed in Config-IOD-Reader dist

my $doc = Config::IOD->new->read_string(<<EOF);
[without_encoding]
home_dir  = ~
dirs  = $tempdir

[with_encoding]
home_dir  = !path ~
dirs      = !paths $tempdir/f*
dirs2     = !paths $tempdir/g*
dirs3     = !paths $tempdir/h*
EOF

is($doc->get_value("without_encoding", "home_dir" ), "~");

{
    my $path = $doc->get_value("with_encoding"   , "home_dir" );
    ok($path eq $pw[7] || $ENV{HOME} && $path eq $ENV{HOME});
}

is_deeply($doc->get_value("with_encoding"   , "dirs"     ), ["$tempdir/f1", "$tempdir/f2"]);
is_deeply($doc->get_value("with_encoding"   , "dirs2"    ), ["$tempdir/g1"]);
is_deeply($doc->get_value("with_encoding"   , "dirs3"    ), []);

DONE_TESTING:
done_testing;
