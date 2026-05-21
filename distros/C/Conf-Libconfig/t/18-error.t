#!perl -T
use strict;
use warnings;
use Test::More;

use Conf::Libconfig;

my $conf = Conf::Libconfig->new;

my $ver = $conf->getversion();
$ver =~ s/\.//g;
if ($ver < 140) {
    plan skip_all => "libconfig $ver is too old for error_type/error_file test (need >= 1.4)";
}

# Test error functions on a fresh config (no error)
is($conf->error_type(), 0, "error_type - no error");

# Trigger a parse error by reading a non-config file
my $ret = $conf->read_file("./t/00-load.t");
ok(!$ret, "read_file non-config - parse error expected");

my $err_type = $conf->error_type();
cmp_ok($err_type, '>', 0, "error_type - has error after bad read");
my $err_text = $conf->error_text();
ok(defined($err_text), "error_text - defined");
my $err_file = $conf->error_file();
ok(defined($err_file), "error_file - defined");
my $err_line = $conf->error_line();
cmp_ok($err_line, '>', 0, "error_line - positive after error");

done_testing();