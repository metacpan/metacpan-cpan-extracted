# -*- cperl -*-

# test augeas backend 

use ExtUtils::testlib;
use Test::More ;
use Config::Model 2.116;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Path::Tiny;
use version 0.77 ;

use lib 't/lib';
use LoadTest;

use warnings;
use strict;

# workaround Augeas locale bug
if (not defined $ENV{LC_ALL} or $ENV{LC_ALL} ne 'C' or $ENV{LANG} ne 'C') {
  $ENV{LC_ALL} = $ENV{LANG} = 'C';
  # use the Perl interpreter that ran this script. See RT #116750
  exec("$^X $0 @ARGV");
}

eval { require Config::Augeas ;} ;
if ( $@ ) {
    plan skip_all => 'Config::Augeas is not installed';
}
else {
    plan tests => 4;
}

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir;

# cleanup before tests
$wr_root->child('etc/ssh')->mkpath;

# set_up data
load_test_model($model);

my $have_pkg_config = `pkg-config --version` || '';
chomp $have_pkg_config ;

my $aug_version = $have_pkg_config ? `pkg-config --modversion augeas` : '' ;
chomp $aug_version ;

my $skip =  (not $have_pkg_config)  ? 'pkgconfig is not installed'
         :  version->parse($aug_version) le version->parse('0.3.1') ? 'Need Augeas library > 0.3.1'
         :                            '';

SKIP: {
    skip $skip , 3 if $skip ;

    my $i_sshd = $model->instance(
        instance_name    => 'sshd_inst',
        root_class_name  => 'Sshd',
        root_dir         => $wr_root ,
    );

    ok( $i_sshd, "Created instance for sshd" );

    ok( $i_sshd, "Created instance for /etc/ssh/sshd_config" );

    my $sshd_root = $i_sshd->config_root ;
    $sshd_root->init ;

    my $ssh_augeas_obj = $sshd_root->backend_mgr->backend_obj->_augeas_object ;

    $ssh_augeas_obj->print('/files/etc/ssh/sshd_config/*') if $trace;

    # change data content, '~' is like a splice, 'record~0' like a "shift"
    $sshd_root->load("HostbasedAuthentication=yes 
                  Subsystem:ddftp=/home/dd/bin/ddftp
                  ") ;

    my $dump = $sshd_root->dump_tree ;
    print $dump if $trace ;

    $i_sshd->write_back ;

    my @mod = ("HostbasedAuthentication yes\n",
               "Protocol 1,2\n",
               "Subsystem ddftp /home/dd/bin/ddftp\n"
           );

    my $aug_sshd_file = $wr_root->child('etc/ssh/sshd_config');
    is_deeply([$aug_sshd_file->lines],\@mod,"check content of $aug_sshd_file") ;

} # end SKIP section
