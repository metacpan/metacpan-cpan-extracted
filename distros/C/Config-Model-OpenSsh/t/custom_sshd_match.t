# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Differences;
use Config::Model ;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Path::Tiny;

use warnings;
use strict;

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir;

my $wr_dir1 = $wr_root->child('a');
my $ssh_subdir = $^O eq 'darwin' ? '/etc'
               :                 '/etc/ssh' ;
my $ssh_path1 = $wr_dir1->child($ssh_subdir);

my @orig = <DATA> ;

$ssh_path1->mkpath;
my $ssh_file1 = $ssh_path1->child('sshd_config');
$ssh_file1->spew(@orig);

my $inst = $model->instance (
    root_class_name   => 'Sshd',
    instance_name     => 'sshd_instance',
    root_dir          => $wr_dir1,
    backend => 'OpenSsh::Sshd',
);

ok($inst,"Read $ssh_file1 and created instance") ;

my $root = $inst -> config_root ;

my $dump =  $root->dump_tree ();
print "First $wr_dir1 dump:\n",$dump if $trace ;

#like($dump,qr/Match:0/, "check Match section") if $testdir =~ /match/;

$root -> load("Port=2222 HostbasedAuthentication=yes"
                  . " Subsystem:ddftp=/home/dd/bin/ddftp Match:1 Condition Host=elysee.* ") ;

$inst->write_back() ;
ok(1,"wrote data in $wr_dir1") ;


# copy data in wr_dir2
my $wr_dir2 = $wr_root->child('b') ;
my $ssh_dir2 = $wr_dir2->child($ssh_subdir);
$ssh_dir2->mkpath;
my $ssh_file2 = $ssh_dir2->child('sshd_config');
$ssh_file1->copy($ssh_dir2) ;

my $inst2 = $model->instance (
    root_class_name   => 'Sshd',
    instance_name     => 'sshd_instance2',
    root_dir          => $wr_dir2,
    backend => 'OpenSsh::Sshd',
);

ok($inst2,"Read $ssh_file2 and created instance") ;

my $root2 = $inst2 -> config_root ;
my $dump2 = $root2 -> dump_tree ();
print "Second $wr_dir2 dump:\n",$dump2 if $trace ;

my @mod = split /\n/,$dump ;
unshift @mod, 'HostbasedAuthentication=yes', 'Port=2222';
splice @mod,2,0,'Subsystem:ddftp=/home/dd/bin/ddftp';
splice @mod,12,1,'    Group="pres.*"','    Host="elysee.*" -';
eq_or_diff([split /\n/,$dump2],\@mod, "check if both dumps are consistent") ;

done_testing;


__DATA__

X11Forwarding        yes

Match  User domi
AllowTcpForwarding   yes
PasswordAuthentication yes
RhostsRSAAuthentication no
RSAAuthentication    yes
X11DisplayOffset     10
X11Forwarding        yes

# sarkomment
Match User sarko Group pres.*
Banner /etc/bienvenue.txt
X11Forwarding no

# some comment
Match User bush Group pres.* Host white.house.*
Banner /etc/welcome.txt
