# -*- cperl -*-

use lib 'lib';

use ExtUtils::testlib;
use Test::More;
use Config::Model ;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

use warnings;
use strict;

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir;

my @orig = <DATA> ;

my $approx_dir = $wr_root->child('/etc/approx/');
$approx_dir->mkpath;
my $approx_conf = $approx_dir->child('approx.conf');
$approx_conf->spew(@orig);

my $inst = $model->instance (
    root_class_name   => 'Approx',
    instance_name     => 'approx_instance',
    root_dir          => $wr_root,
);

ok($inst,"Read $approx_conf and created instance") ;

my $cfg = $inst -> config_root ;

my $dump =  $cfg->dump_tree ();
print $dump if $trace ;

my $expect = q(max_rate=100K
verbose=1#"old style parameter (before approx 2.9.0)"
distributions:debian=http://ftp.debian.org/debian
distributions:local=file:///my/local/repo
distributions:security=http://security.debian.org/debian-security#"let's be secure" -
);

is ($dump,$expect,"check data read from approx.conf") ;

$cfg->load("max_rate=200K") ;

$inst->write_back ;

my $approxlines = $approx_conf->slurp;

like($approxlines,qr/200K/,"checked written approx file") ;
like($approxlines,qr/\$verbose/,"new approx file contains new style param") ;

done_testing;

__END__


$max_rate 100K

# old style parameter (before approx 2.9.0)
verbose  1

debian          http://ftp.debian.org/debian
# let's be secure
security        http://security.debian.org/debian-security
local           file:///my/local/repo
