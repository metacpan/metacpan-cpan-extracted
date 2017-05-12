# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Config::Model ;
use Config::Model::BackendMgr; # required for tests
use Log::Log4perl qw(:easy) ;
use File::Path ;
use English;
use Test::Differences ;
use Test::Warn ;

use warnings;
use strict;

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $DEBUG: $ERROR);
}

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_test';

my $testdir = 'ssh_test' ;

my $ssh_path = $^O eq 'darwin' ? '/etc'
               :                 '/etc/ssh' ;

# cleanup before tests
rmtree($wr_root);

my @orig = <DATA> ;

my $wr_dir = $wr_root.'/'.$testdir ;
mkpath($wr_dir.$ssh_path, { mode => 0755 })
  || die "can't mkpath: $!";
open(SSHD,"> $wr_dir$ssh_path/ssh_config")
  || die "can't open file: $!";
print SSHD @orig ;
close SSHD ;

# special global variable used only for tests
my $joe_home = $^O eq 'darwin' ? '/Users/joe'
             :                   '/home/joe' ; ;
Config::Model::BackendMgr::_set_test_home($joe_home) ;

# set up Joe's environment
my $joe_ssh = $wr_dir.$joe_home.'/.ssh';
mkpath($joe_ssh, { mode => 0755 }) || die "can't mkpath $joe_ssh: $!";
open(JOE,"> $joe_ssh/config") || die "can't open file: $!";
print JOE "Host mine.bar\n\nIdentityFile ~/.ssh/mine\n" ;
close JOE ;

sub read_user_ssh {
    my $file = shift ;
    open(IN, $file)||die "can't read $file:$!";
    my @res = grep {/\w/} map { chomp; s/\s+/ /g; $_ ;} grep { not /##/ } <IN> ;
    close (IN);
    return @res ;
}

print "Test from directory $testdir\n" if $trace ;

note "Running test like root (no layered config)" ;

my $root_inst = $model->instance (root_class_name   => 'SystemSsh',
				  instance_name     => 'root_ssh_instance',
				  root_dir          => $wr_dir,
				 );

ok($root_inst,"Read $wr_dir$ssh_path/ssh_config and created instance") ;

my $root_cfg = $root_inst -> config_root ;
$root_cfg->init ;

my $ciphers = $root_cfg->grab('Host:"*" Ciphers') ;

eq_or_diff( [ $ciphers->get_checked_list ],
        [ qw/aes192-cbc aes128-cbc 3des-cbc blowfish-cbc aes256-cbc/],
        "check cipher list");

my $dump =  $root_cfg->dump_tree ();
print $dump if $trace ;

like($dump,qr/^#"ssh global comment"/, "check global comment pattern") ;
like($dump,qr/Ciphers=aes192-cbc,aes128-cbc,3des-cbc,blowfish-cbc,aes256-cbc#"  Protocol 2,1\s+Cipher 3des"/,"check Ciphers comment");
like($dump,qr/SendEnv#"  PermitLocalCommand no"/,"check SendEnv comment");
like($dump,qr/Host:"foo\.\*,\*\.bar"/, "check Host pattern") ;
like($dump,qr/LocalForward:0\s+port=20022/, "check user LocalForward port") ;
like($dump,qr/host=10.3.244.4/, "check user LocalForward host") ;
like($dump,qr/LocalForward:1#"IPv6 example"\s+ipv6=1/, "check user LocalForward ipv6") ;
like($dump,qr/port=22080/, "check user LocalForward port ipv6") ;
like($dump,qr/host=2001:0db8:85a3:0000:0000:8a2e:0370:7334/, 
     "check user LocalForward host ipv6") ;

$root_inst->write_back() ; 

ok(1,"wrote ssh_config data in $wr_dir") ;

my $inst2 = $model->instance (root_class_name   => 'SystemSsh',
			      instance_name     => 'root_ssh_instance2',
			      root_dir          => $wr_dir,
			     );

my $root2 = $inst2 -> config_root ;
my $dump2 = $root2 -> dump_tree ();
print $dump2 if $trace ;

is_deeply([split /\n/,$dump2],[split /\n/,$dump],
	  "check if both root_ssh dumps are identical") ;

SKIP: {
    skip "user tests when test is run as root", 12
       if $EUID == 0 ;

    note "Running test like user with layered config";

    my $user_inst = $model->instance (root_class_name   => 'Ssh',
				      instance_name     => 'user_ssh_instance',
				      root_dir          => $wr_dir,
				     );

    ok($user_inst,"Read user .ssh/config and created instance") ;

    my @joe_orig    = read_user_ssh($wr_dir.$joe_home.'/.ssh/config') ;

    my $user_cfg = $user_inst -> config_root ;

    $dump =  $user_cfg->dump_tree (mode => 'full' );
    print $dump if $trace ;

    like($dump,qr/Host:"foo\.\*,\*\.bar"/,"check root Host pattern") ;
    like($dump,qr/Host:"?mine.bar"?/,"check user Host pattern") ;

    $user_inst->write_back() ;
    my $joe_file = $wr_dir.$joe_home.'/.ssh/config' ;
    ok(1,"wrote user .ssh/config data in $joe_file") ;

    ok(-e $joe_file,"Found $joe_file") ;

    # compare original and written file
    my @joe_written = read_user_ssh($joe_file) ;
    eq_or_diff(\@joe_written,\@joe_orig,"check user .ssh/config files") ;

    # write some data
    $user_cfg->load('EnableSSHKeysign=1') ;
    $user_inst->write_back() ;
    unshift @joe_orig,'EnableSSHKeysign yes';
    @joe_written = read_user_ssh($joe_file) ;
    eq_or_diff(\@joe_written,\@joe_orig,"check user .ssh/config files after modif") ;

    # run test on tricky element
    warning_like {
        $user_inst->load( check => 'skip', step => 'Host:"*" IPQoS="foo bar baz"') ;
    } qr/skipping value/ ,"too many fields warning";
    warning_like {
        $user_inst->load( check => 'skip', step => 'Host:"*" IPQoS="foo"') ;
    } qr/skipping/ ,"bad fields warning";
    ok($user_inst->has_error,"check errors count") ;
    like($user_inst->error_messages,qr/"af11"/,"check error message") ;

    $user_inst->load('Host:"*" IPQoS="af11 af12"') ;

    # fix is pending
    my $expect = $Config::Model::VERSION > 2.046 ? 0 : 1 ;
    is($user_inst->has_error,$expect,"check error count after fix") ;

    # check if config has warnings
    is($user_inst->has_warning,0,"check if warnings are left");
}

done_testing;

__END__
# ssh global comment


Host *
#   ForwardAgent no
#   ForwardX11 no
    Port 1022
#   Protocol 2,1
#   Cipher 3des
    Ciphers aes192-cbc,aes128-cbc,3des-cbc,blowfish-cbc,aes256-cbc
#   PermitLocalCommand no
    SendEnv LANG LC_*
    HashKnownHosts yes
    GSSAPIAuthentication yes
    GSSAPIDelegateCredentials no

# foo bar big
# comment
Host foo.*,*.bar
    # for and bar have X11
    ForwardX11 yes
    SendEnv FOO BAR

Host *.gre.hp.com
ForwardX11           yes
User                 tester

Host picosgw
ForwardAgent         yes
HostName             sshgw.truc.bidule
IdentityFile         ~/.ssh/%r
LocalForward         20022         10.3.244.4:22
# IPv6 example
LocalForward         all.com/22080       2001:0db8:85a3:0000:0000:8a2e:0370:7334/80
User                 k0013

Host picos
ForwardX11           yes
HostName             localhost
Port                 20022
User                 ocad
ControlPersist       YES


