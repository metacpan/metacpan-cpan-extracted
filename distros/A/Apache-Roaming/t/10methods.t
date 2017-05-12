# -*- perl -*-

require File::Spec;
require Symbol;


my $test_num = 0;
my($cfg, $pid, $lwp);
sub Test ($;$) {
    my $result = shift; my $msg = shift;
    $msg = '' unless defined($msg);
    ++$test_num;
    print "not " unless $result;
    print "ok $test_num$msg\n";
    $result;
}

sub Request ($$$;$$@) {
    my($ua, $method, $url, $type, $contents, @headers) = @_;
    $url = 'http://127.0.0.1:' . $cfg->{'httpd_port'} . $url;
    my $req = HTTP::Request->new($method => $url);
    Test($req);
    $req->content_type($type) if defined($type);
    $req->content($contents) if defined($contents);
    $req->authorization_basic('foo bar', 'eoj');
    while (@headers) {
	my $key = shift @headers;
	my $val = shift @headers;
	$req->header($key => $val);
    }
    my $res = $ua->request($req);
    Test($res->is_success())
	or print("Error:", $res->error_as_HTML(), "\n");
    $res;
}


sub TestContents ($$) {
    my $file = shift; my $expected = shift;
    Test(-f $file)
	or print "File $file doesn't exist.\n";
    my $fh = Symbol::gensym();
    Test(open($fh, "<$file"))
	or print "Cannot open file $file: $!\n";
    local $/ = undef;
    my $got = <$fh>;
    Test(defined($got))
	or print "Failed to read file $file: $!\n";
    Test($got eq $expected)
	or print "File $file doesn't match expected contents.\n";
}


eval {
    $cfg = require ".status";
    mkdir $cfg->{'t_dir'}, 0755 unless -d $cfg->{'t_dir'};
    mkdir $cfg->{'output_dir'}, 0755 unless -d $cfg->{'output_dir'};
    mkdir $cfg->{'roaming_dir'}, 0755 unless -d $cfg->{'roaming_dir'};
    mkdir $cfg->{'log_dir'}, 0755 unless -d $cfg->{'log_dir'};
    unlink $cfg->{'pid_file'} if -f $cfg->{'pid_file'};
    open(USER, ">$cfg->{'user_file'}")
	or die "Error while creating user file: $!";
    printf USER ("%s:%s\n", "foo bar", crypt("eoj", "foo bar"))
	or die "Error while writing user file: $!";
    close(USER)
	or die "Error while closing user file: $!";
    $pid = fork ();
    $lwp = require LWP::UserAgent;
};

if ($@  or  !defined($pid)  or  !$cfg  or  !$lwp) {
    print "1..0\n";
    exit 0;
}

sub KillHttpd { system "kill $pid" if $pid };

$SIG{'CHLD'} = sub { my $p = wait; undef $pid if $pid = $p };
$SIG{'ALRM'} = sub { KillHttpd() };


if (!open(CONF, ">$cfg->{'httpd_conf'}")  ||
    !(print CONF <<"EOF")  ||  !close(CONF)) {
$cfg->{'dynamic_module_list'}
ServerRoot $cfg->{'t_dir'}
User $cfg->{'httpd_user'}
Group $cfg->{'httpd_group'}
Port $cfg->{'httpd_port'}
ServerName localhost
DocumentRoot $cfg->{'output_dir'}
PidFile $cfg->{'pid_file'}
ErrorLog $cfg->{'error_log'}
TransferLog $cfg->{'access_log'}
LockFile $cfg->{'lock_file'}
ResourceConfig $cfg->{'srm_conf'}
AccessConfig $cfg->{'access_conf'}
TypesConfig $cfg->{'types_conf'}

PerlModule Apache::Roaming
<Directory $cfg->{'roaming_dir'}>
PerlHandler Apache::Roaming->handler
PerlTypeHandler Apache::Roaming->handler_type
AuthType Basic
AuthName "Roaming User"
AuthUserFile $cfg->{'user_file'}
require valid-user
PerlSetVar BaseDir $cfg->{'roaming_dir'}
</Directory>
EOF
    die "Error while writing $cfg->{'httpd_conf'}: $!";
}


if (!$pid) {
    # This is the child
    $ENV{'PERL5LIB'} = 'blib/arch:blib/lib';
    my @opts = ($cfg->{'httpd_path'}, '-d', $cfg->{'t_dir'}, '-f',
		$cfg->{'httpd_conf'}, '-X');
    print "Starting httpd: ", join(" ", @opts), "\n";
    exec @opts;
}


print "1..37\n";
alarm 120;

print "Creating a user agent.\n";
my $ua = LWP::UserAgent->new();
Test($ua);

sleep 5;
my $contents = 'abcdef';
my $testfile = File::Spec->catdir($cfg->{'roaming_dir'}, "foo bar", "test");
unlink $testfile;
Request($ua, 'PUT', '/roaming/foo bar/test', 'text/plain', $contents);
TestContents($testfile, $contents);

my $block = '';
for (my $i = 0;  $i < 256;  $i++) {
    $block .= chr($i);
}
my $contents2 = $block x 40;
my $testfile2 = File::Spec->catdir($cfg->{'roaming_dir'}, "foo bar", "test2");
unlink $testfile2;
Request($ua, 'PUT', '/roaming/foo bar/test2', 'text/plain', $contents2);
TestContents($testfile2, $contents2);

my $res = Request($ua, 'GET', '/roaming/foo bar/test');
Test($res->content()  and  ($res->content() eq $contents));
$res = Request($ua, 'GET', '/roaming/foo bar/test2');
Test($res->content()  and  ($res->content() eq $contents2));


my $testfile3 = File::Spec->catdir($cfg->{'roaming_dir'}, "foo bar", "test3");
unlink $testfile3;
Request($ua, 'MOVE', '/roaming/foo bar/test', undef, undef,
	'New-uri' => '/roaming/foo bar/test3');
$res = Request($ua, 'GET', '/roaming/foo bar/test3');
Test($res->content()  and  ($res->content() eq $contents));
Test(!-f $testfile);
my $testfile4 = File::Spec->catdir($cfg->{'roaming_dir'}, "foo bar", "test3");
unlink $testfile4;
Request($ua, 'MOVE', '/roaming/foo bar/test2', undef, undef,
 	'New-uri' => '/roaming/foo bar/test4');
$res = Request($ua, 'GET', '/roaming/foo bar/test4');
Test($res->content()  and  ($res->content() eq $contents2));
Test(!-f $testfile2);

Request($ua, 'DELETE', '/roaming/foo bar/test3');
Test(!-f $testfile3);
Request($ua, 'DELETE', '/roaming/foo bar/test4');
Test(!-f $testfile4);

sleep 5;


END {
    my $status = $?;
    KillHttpd();
    $? = $status;
}
