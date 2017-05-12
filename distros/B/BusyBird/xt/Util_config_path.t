use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok "BusyBird::Util", qw(config_file_path config_directory);
}

is config_directory, "$ENV{HOME}/.busybird", "config directory OK";
is config_file_path("foo", "bar.pl"), "$ENV{HOME}/.busybird/foo/bar.pl", "config file OK";

done_testing;

