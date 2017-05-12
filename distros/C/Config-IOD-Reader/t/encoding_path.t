#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

BEGIN {
    plan skip_all => "getting user's home dir not yet implemented on Windows"
        if $^O eq 'MSWin32';
    plan skip_all => "HOME not defined"
        unless $ENV{HOME};
}

use Config::IOD::Reader;
#use File::Slurper qw(write_text);
use File::Temp qw(tempdir);

sub _create_file { open my($fh), ">", $_[0] }

my $tempdir = tempdir(CLEANUP => 1);
_create_file("$tempdir/f1", "");
_create_file("$tempdir/f2", "");
_create_file("$tempdir/g1", "");

my $username = Config::IOD::Base::_get_my_user_name();
my $homedir  = Config::IOD::Base::_get_my_home_dir();

my $res = Config::IOD::Reader->new->read_string(<<EOF);
[without_path_encoding]
home_dir  = "~"
home_dir2 = !none ~$username/
param3 = foo~

dirs      = $tempdir/f*
dirs2     = $tempdir/g*
dirs3     = $tempdir/h*

[with_path_encoding]
home_dir  = ~
home_dir2 = !path ~$username/
param3 = foo~

dirs      = !paths $tempdir/f*
dirs2     = !paths $tempdir/g*
dirs3     = !paths $tempdir/h*
EOF

is_deeply($res, {
    without_path_encoding => {
        home_dir  => "~",
        home_dir2 => "~$username/",
        param3    => 'foo~',
        dirs      => "$tempdir/f*",
        dirs2     => "$tempdir/g*",
        dirs3     => "$tempdir/h*",
    },
    with_path_encoding => {
        home_dir  => "$homedir",
        home_dir2 => "$homedir",
        param3    => 'foo~',
        dirs      => ["$tempdir/f1", "$tempdir/f2"],
        dirs2     => ["$tempdir/g1"],
        dirs3     => [],
    },
}) or diag explain $res;

# XXX check unknown user -> dies

DONE_TESTING:
done_testing;
