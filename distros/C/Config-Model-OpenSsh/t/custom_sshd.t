# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Config::Model ;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Path::Tiny;

use warnings;
use strict;

$::_use_log4perl_to_warn = 1;

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

$root -> load("Port=2222") ;

my $new_dump = $root->dump_tree();

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
print "Second $wr_dir2 dump:",$dump2 if $trace ;

is_deeply([split /\n/,$dump2],[split /\n/, $new_dump], "check if both dumps are consistent") ;

done_testing;

__DATA__

# snatched from Debian config file
# Package generated configuration file
# See the sshd(8) manpage for details

# What ports, IPs and protocols we listen for
Port 221
# Use these options to restrict which interfaces/protocols sshd will bind to
#ListenAddress ::
#ListenAddress 0.0.0.0
Protocol 2
# HostKeys for protocol version 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
#Privilege Separation is turned on for security
UsePrivilegeSeparation yes

# Lifetime and size of ephemeral version 1 server key
KeyRegenerationInterval 3600

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication:
LoginGraceTime 120
PermitRootLogin yes
StrictModes yes

RSAAuthentication yes
PubkeyAuthentication yes
#AuthorizedKeysFile	%h/.ssh/authorized_keys

# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# For this to work you will also need host keys in /etc/ssh_known_hosts
RhostsRSAAuthentication no
# similar for protocol version 2
HostbasedAuthentication no
# Uncomment if you don't trust ~/.ssh/known_hosts for RhostsRSAAuthentication
#IgnoreUserKnownHosts yes

# To enable empty passwords, change to yes (NOT RECOMMENDED)
PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Change to no to disable tunnelled clear text passwords
#PasswordAuthentication yes

# Kerberos options
#KerberosAuthentication no
#KerberosGetAFSToken no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes

X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
#UseLogin no

MaxStartups 10:30:60
#Banner /etc/issue.net

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server

UsePAM yes

AllowUsers foo bar@192.168.0.*

ClientAliveCountMax 5
ClientAliveInterval 300 

