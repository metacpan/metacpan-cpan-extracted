#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw( ./lib );

use Data::Dumper;

our $ONLINE;

BEGIN {
    #$ENV{auth_user}   = 'restest';
    #$ENV{auth_passwd} = '123';
    #$ENV{host}        = '192.168.123.1';
    $ONLINE = $ENV{auth_user} && $ENV{auth_passwd} && $ENV{host};
}

my $manipulate_user = 'zsezse';

use Test::More tests => $ONLINE ? 61 : 61;

my $test_host = $ENV{host} || '127.0.0.1';

ok(1, 'Test OK');
use_ok('API::CPanel');

$a = 'refs';

is( refs( undef ),   '',       $a);
is( refs( {} ),      'HASH',   $a );
is( refs( [] ),      'ARRAY',  $a );
is( refs( sub {} ),  'CODE',   $a );
is( refs( \$a ),     'SCALAR', $a );

$a = 'is_success';

ok(! is_success(), $a);
ok(! is_success( { error => {}, data => {} } ), $a);
ok(! is_success( { data  => {} } ), $a);
ok(! is_success( { } ), $a);
ok(  is_success( { status => 1 } ), $a);

$a = 'filter_hash';
is_deeply( API::CPanel::filter_hash( {  }, [ ]), {}, $a );
is_deeply( API::CPanel::filter_hash( { aaa => 555, bbb => 111 }, [ 'aaa' ]), { aaa => 555 }, $a );
is_deeply( API::CPanel::filter_hash( { aaa => 555, bbb => 111 }, [ ]), { }, $a );
is_deeply( API::CPanel::filter_hash( { }, [ 'aaa' ]), { }, $a );

$a = 'mk_query_string';
is( API::CPanel::mk_query_string( {  }  ), '', $a );
is( API::CPanel::mk_query_string( ''    ), '', $a );
is( API::CPanel::mk_query_string( undef ), '', $a );
is( API::CPanel::mk_query_string( { aaa => 111, bbb => 222 } ), 'aaa=111&bbb=222', $a );
is( API::CPanel::mk_query_string( { bbb => 222, aaa => 111 } ), 'aaa=111&bbb=222', $a );
is( API::CPanel::mk_query_string( [ ] ), '', $a );
is( API::CPanel::mk_query_string( { dddd => 'dfdf' } ), 'dddd=dfdf', $a );

my $kill_start_end_slashes_test = {
    '////aaa////' => 'aaa',
    'bbb////'     => 'bbb',
    '////ccc'     => 'ccc', 
    ''            => '',
};

for (keys %$kill_start_end_slashes_test) {
    is(
        API::CPanel::kill_start_end_slashes ($_),
        $kill_start_end_slashes_test->{$_},
        'kill_start_end_slashes'
    );
}

$a = 'mk_full_query_string';
is( API::CPanel::mk_full_query_string( {
        host => $test_host, 
    } ), 
    '',
    $a
);

is( API::CPanel::mk_full_query_string( {
        host       => $test_host,
        allow_http => 1,
        path       => 'xml-api',
    } ), 
    '',
    $a
);

is(  API::CPanel::mk_full_query_string( {
        host       => $test_host,
        allow_http => 1,
        param1     => 'val1',
        param2     => 'val2',
        func       => 'test',
    } ), 
    "http://$test_host:2087/xml-api/test?param1=val1&param2=val2",
    $a
);

is(  API::CPanel::mk_full_query_string( {
        host       => $test_host,
        param1     => 'val1',
        param2     => 'val2',
        func       => 'test',
    } ), 
    "https://$test_host:2087/xml-api/test?param1=val1&param2=val2",
    $a
);


$a = 'mk_query_to_server';
is( API::CPanel::mk_query_to_server( '' ), '', $a );

my %correct_params = (
    auth_user   => $ENV{auth_user}   || 'fake',
    auth_passwd => $ENV{auth_passwd} || 'fake_pass',
    host        => $test_host,

);




$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<listips>
  <result>
    <active>1</active>
    <dedicated>0</dedicated>
    <if>eth0</if>
    <ip>192.168.123.208</ip>
    <mainaddr>1</mainaddr>
    <netmask>255.255.255.0</netmask>
    <network>192.168.123.0</network>
    <removable>0</removable>
    <used>1</used>
  </result>
  <result>
    <active>1</active>
    <dedicated>1</dedicated>
    <if>eth0:1</if>
    <ip>192.168.123.222</ip>
    <mainaddr>0</mainaddr>
    <netmask>255.255.255.0</netmask>
    <network>192.168.123.0</network>
    <removable>1</removable>
    <used>0</used>
  </result>
  <result>
    <active>1</active>
    <dedicated>1</dedicated>
    <if>virbr0</if>
    <ip>192.168.122.1</ip>
    <mainaddr>0</mainaddr>
    <netmask>255.255.255.0</netmask>
    <network>192.168.122.0</network>
    <removable>1</removable>
    <used>0</used>
  </result>
</listips>
THEEND

#$API::CPanel::DEBUG=1;
my $ip_list = API::CPanel::Ip::list(
    {
	%correct_params,
    }
);

my $main_shared_ip = $ip_list->[0];
#diag "Get ips from panel: " . Dumper( $ip_list ) . scalar @$ip_list;
ok($ip_list && ref $ip_list eq 'ARRAY' && scalar @$ip_list, 'API::CPanel::Ip::list');
#$API::CPanel::DEBUG=0;

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<createacct>
  <result>
    <options>
      <ip>192.168.123.208</ip>
      <nameserver>ns1.centostest.ru</nameserver>
      <nameserver2>ns2.centostest.ru</nameserver2>
      <nameserver3></nameserver3>
      <nameserver4></nameserver4>
      <nameservera></nameservera>
      <nameservera2></nameservera2>
      <nameservera3></nameservera3>
      <nameservera4></nameservera4>
      <nameserverentry></nameserverentry>
      <nameserverentry2></nameserverentry2>
      <nameserverentry3></nameserverentry3>
      <nameserverentry4></nameserverentry4>
      <package>default</package>
    </options>
    <rawout>
    </rawout>
    <status>1</status>
    <statusmsg>Account Creation Ok</statusmsg>
  </result>
</createacct>
THEEND

my $result = API::CPanel::User::create(
    {
	%correct_params,
	username    => $manipulate_user,
	domain      => 'zse1.ru',
	password    => 'sdfdsGdhd',
	maxsql      => 11,
    }
);
is( $result, 1, 'API::CPanel::User::create' );

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<createacct>
  <result>
    <options></options>
    <rawout></rawout>
    <status>0</status>
    <statusmsg>Sorry, a group for that username already exists.</statusmsg>
  </result>
</createacct>
THEEND

$result = API::CPanel::User::create(
    {
	%correct_params,
	username    => $manipulate_user,
	password    => 'sdfdsGdhd',
	domain      => 'zse1.ru',
    }
);
is( $result, '', 'API::CPanel::User::create repeat');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<passwd>
  <passwd>
    <rawout>Changing password for zsezse
Password for zsezse has been changed
Updating ftp passwords for zsezse
Ftp password files updated.
Ftp vhost passwords synced
</rawout>
    <services>
      <app>system</app>
    </services>
    <services>
      <app>ftp</app>
    </services>
    <services>
      <app>mail</app>
    </services>
    <services>
      <app>mySQL</app>
    </services>
    <status>1</status>
    <statusmsg>Password changed for user zsezse</statusmsg>
  </passwd>
</passwd>
THEEND


$result = API::CPanel::User::change_account_password(
    {
	%correct_params,
	user => $manipulate_user,
	pass => 'sdfdsfsdfhsdfj',
    }
);
is( $result, 1, 'API::CPanel::User::change_account_password');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<modifyacct>
  <result>
    <newcfg>
      <cpuser>
        <BWLIMIT>unlimited</BWLIMIT>
        <CONTACTEMAIL></CONTACTEMAIL>
        <CONTACTEMAIL2></CONTACTEMAIL2>
        <DEMO>0</DEMO>
        <DOMAIN>zse1.ru</DOMAIN>
        <FEATURELIST>default</FEATURELIST>
        <HASCGI>1</HASCGI>
        <IP>192.168.123.208</IP>
        <LANG>russian</LANG>
        <LOCALE>ru</LOCALE>
        <MAXADDON>0</MAXADDON>
        <MAXFTP>unlimited</MAXFTP>
        <MAXLST>unlimited</MAXLST>
        <MAXPARK>0</MAXPARK>
        <MAXPOP>unlimited</MAXPOP>
        <MAXSQL>14</MAXSQL>
        <MAXSUB>unlimited</MAXSUB>
        <MTIME>1269406519</MTIME>
        <MXCHECK-zse1.ru>0</MXCHECK-zse1.ru>
        <OWNER>root</OWNER>
        <PLAN>default</PLAN>
        <RS>x</RS>
        <STARTDATE>1269406518</STARTDATE>
        <USER>zseasd</USER>
      </cpuser>
      <domain>zse1.ru</domain>
      <setshell>unmodified</setshell>
      <user>zseasd</user>
    </newcfg>
    <status>1</status>
    <statusmsg>Account Modified</statusmsg>
  </result>
</modifyacct>
THEEND

$result = API::CPanel::User::edit(
    {
	%correct_params,
	user     => $manipulate_user,
	maxsql   => 14,
	locale   => 'ru',
	cptheme  => 'x',
    }
);
is( $result, 1, 'API::CPanel::User::edit');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<listaccts>
  <acct>
    <disklimit>unlimited</disklimit>
    <diskused>0M</diskused>
    <domain>qewqe.ru</domain>
    <email>*unknown*</email>
    <ip>192.168.123.208</ip>
    <maxaddons>*unknown*</maxaddons>
    <maxftp>unlimited</maxftp>
    <maxlst>unlimited</maxlst>
    <maxparked>*unknown*</maxparked>
    <maxpop>unlimited</maxpop>
    <maxsql>unlimited</maxsql>
    <maxsub>unlimited</maxsub>
    <owner>root</owner>
    <partition>home</partition>
    <plan>default</plan>
    <shell>/bin/bash</shell>
    <startdate>10 Mar 22 16:18</startdate>
    <suspended>0</suspended>
    <suspendreason>not suspended</suspendreason>
    <suspendtime></suspendtime>
    <theme>x3</theme>
    <unix_startdate>1269249522</unix_startdate>
    <user>qewqeru</user>
  </acct>
  <acct>
    <disklimit>unlimited</disklimit>
    <diskused>0M</diskused>
    <domain>zse1.ru</domain>
    <email>*unknown*</email>
    <ip>192.168.123.208</ip>
    <maxaddons>*unknown*</maxaddons>
    <maxftp>unlimited</maxftp>
    <maxlst>unlimited</maxlst>
    <maxparked>*unknown*</maxparked>
    <maxpop>unlimited</maxpop>
    <maxsql>14</maxsql>
    <maxsub>unlimited</maxsub>
    <owner>root</owner>
    <partition>home</partition>
    <plan>default</plan>
    <shell>/usr/local/cpanel/bin/noshell</shell>
    <startdate>10 Mar 24 11:55</startdate>
    <suspended>0</suspended>
    <suspendreason>not suspended</suspendreason>
    <suspendtime></suspendtime>
    <theme>x</theme>
    <unix_startdate>1269406518</unix_startdate>
    <user>zseasd</user>
  </acct>
  <acct>
    <disklimit>unlimited</disklimit>
    <diskused>0M</diskused>
    <domain>zse.ru</domain>
    <email>*unknown*</email>
    <ip>192.168.123.208</ip>
    <maxaddons>*unknown*</maxaddons>
    <maxftp>unlimited</maxftp>
    <maxlst>unlimited</maxlst>
    <maxparked>*unknown*</maxparked>
    <maxpop>unlimited</maxpop>
    <maxsql>unlimited</maxsql>
    <maxsub>unlimited</maxsub>
    <owner>root</owner>
    <partition>home</partition>
    <plan>default</plan>
    <shell>/bin/bash</shell>
    <startdate>10 Mar 22 16:21</startdate>
    <suspended>0</suspended>
    <suspendreason>not suspended</suspendreason>
    <suspendtime></suspendtime>
    <theme>x3</theme>
    <unix_startdate>1269249671</unix_startdate>
    <user>zseru</user>
  </acct>
  <status>1</status>
  <statusmsg>Ok</statusmsg>
</listaccts>
THEEND

my $active_count = API::CPanel::User::active_user_count(
    {
	%correct_params,
    }
);
ok( $result =~ /^\d+$/ , 'API::CPanel::User::active_user_count');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<suspendacct>
  <result>
    <status>1</status>
    <statusmsg>&lt;script&gt;if (self[]) { clear_ui_status(); }&lt;/script&gt;
Changing Shell to /bin/false...Changing shell for zseasd.
Warning: &quot;/bin/false&quot; is not listed in /etc/shells
Shell changed.
Done
Locking Password...Locking password for user zseasd.
passwd: Success
Done
Suspending mysql users
Notification =&gt; root\@localhost via EMAIL [level =&gt; 3]
Using Quota v3 Support
Suspended document root /home/zseasd/public_html
Using Quota v3 Support
Suspending FTP accounts...
Updating ftp passwords for zseasd
Ftp password files updated.
Ftp vhost passwords synced
zseasds account has been suspended
</statusmsg>
  </result>
</suspendacct>
THEEND

$result = API::CPanel::User::disable(
    {
	%correct_params,
	user   => $manipulate_user,
	reason => 'test reason1',
    }
);
is( $result, 1, 'API::CPanel::User::disable');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<listaccts>
  <acct>
    <disklimit>unlimited</disklimit>
    <diskused>0M</diskused>
    <domain>qewqe.ru</domain>
    <email>*unknown*</email>
    <ip>192.168.123.208</ip>
    <maxaddons>*unknown*</maxaddons>
    <maxftp>unlimited</maxftp>
    <maxlst>unlimited</maxlst>
    <maxparked>*unknown*</maxparked>
    <maxpop>unlimited</maxpop>
    <maxsql>unlimited</maxsql>
    <maxsub>unlimited</maxsub>
    <owner>root</owner>
    <partition>home</partition>
    <plan>default</plan>
    <shell>/bin/bash</shell>
    <startdate>10 Mar 22 16:18</startdate>
    <suspended>0</suspended>
    <suspendreason>not suspended</suspendreason>
    <suspendtime></suspendtime>
    <theme>x3</theme>
    <unix_startdate>1269249522</unix_startdate>
    <user>qewqeru</user>
  </acct>
  <acct>
    <disklimit>unlimited</disklimit>
    <diskused>0M</diskused>
    <domain>zse1.ru</domain>
    <email>*unknown*</email>
    <ip>192.168.123.208</ip>
    <maxaddons>*unknown*</maxaddons>
    <maxftp>unlimited</maxftp>
    <maxlst>unlimited</maxlst>
    <maxparked>*unknown*</maxparked>
    <maxpop>unlimited</maxpop>
    <maxsql>14</maxsql>
    <maxsub>unlimited</maxsub>
    <owner>root</owner>
    <partition>home</partition>
    <plan>default</plan>
    <shell>/bin/false</shell>
    <startdate>10 Mar 24 11:55</startdate>
    <suspended>1</suspended>
    <suspendreason>test reason1</suspendreason>
    <suspendtime>1269406521</suspendtime>
    <theme>x</theme>
    <unix_startdate>1269406518</unix_startdate>
    <user>zseasd</user>
  </acct>
  <acct>
    <disklimit>unlimited</disklimit>
    <diskused>0M</diskused>
    <domain>zse.ru</domain>
    <email>*unknown*</email>
    <ip>192.168.123.208</ip>
    <maxaddons>*unknown*</maxaddons>
    <maxftp>unlimited</maxftp>
    <maxlst>unlimited</maxlst>
    <maxparked>*unknown*</maxparked>
    <maxpop>unlimited</maxpop>
    <maxsql>unlimited</maxsql>
    <maxsub>unlimited</maxsub>
    <owner>root</owner>
    <partition>home</partition>
    <plan>default</plan>
    <shell>/bin/bash</shell>
    <startdate>10 Mar 22 16:21</startdate>
    <suspended>0</suspended>
    <suspendreason>not suspended</suspendreason>
    <suspendtime></suspendtime>
    <theme>x3</theme>
    <unix_startdate>1269249671</unix_startdate>
    <user>zseru</user>
  </acct>
  <status>1</status>
  <statusmsg>Ok</statusmsg>
</listaccts>
THEEND

$result = API::CPanel::User::active_user_count(
    {
	%correct_params,
    }
);
is( $result, $active_count - 1, 'API::CPanel::User::active_user_count');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<suspendacct>
  <result>
    <status>1</status>
    <statusmsg>&lt;script&gt;if (self['clear_ui_status']) { clear_ui_status(); }&lt;/script&gt;
Changing Shell to /bin/false...Changing shell for zseasd.
Warning: &quot;/bin/false&quot; is not listed in /etc/shells
Shell not changed.
Done
Locking Password...Locking password for user zseasd.
passwd: Success
Done
Suspending mysql users
Notification =&gt; root\@localhost via EMAIL [level =&gt; 3]
Account Already Suspended
</statusmsg>
  </result>
</suspendacct>
THEEND

$result = API::CPanel::User::disable(
    {
	%correct_params,
	user   => $manipulate_user,
	reason => 'test reason2',
    }
);
is( $result, 1, 'API::CPanel::User::disable repeat');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<unsuspendacct>
  <result>
    <status>1</status>
    <statusmsg>&lt;script&gt;if (self['clear_ui_status']) { clear_ui_status(); }&lt;/script&gt;
Changing shell for zseasd.
Shell changed.
Unlocking password for user zseasd.
passwd: Success.
Unsuspending FTP accounts...
Updating ftp passwords for zseasd
Ftp password files updated.
Ftp vhost passwords synced
zseasds account is now active
Unsuspending mysql users
Notification =&gt; root\@localhost via EMAIL [level =&gt; 3]
</statusmsg>
  </result>
</unsuspendacct>
THEEND

$result = API::CPanel::User::enable(
    {
	%correct_params,
	user => $manipulate_user,
    }
);
is( $result, 1, 'API::CPanel::User::enable');

$result = API::CPanel::User::enable(
    {
	%correct_params,
	user   => $manipulate_user,
    }
);
is( $result, 1, 'API::CPanel::User::enable repeat');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<listaccts>
  <acct>
    <disklimit>unlimited</disklimit>
    <diskused>0M</diskused>
    <domain>qewqe.ru</domain>
    <email>*unknown*</email>
    <ip>192.168.123.208</ip>
    <maxaddons>*unknown*</maxaddons>
    <maxftp>unlimited</maxftp>
    <maxlst>unlimited</maxlst>
    <maxparked>*unknown*</maxparked>
    <maxpop>unlimited</maxpop>
    <maxsql>unlimited</maxsql>
    <maxsub>unlimited</maxsub>
    <owner>root</owner>
    <partition>home</partition>
    <plan>default</plan>
    <shell>/bin/bash</shell>
    <startdate>10 Mar 22 16:18</startdate>
    <suspended>0</suspended>
    <suspendreason>not suspended</suspendreason>
    <suspendtime></suspendtime>
    <theme>x3</theme>
    <unix_startdate>1269249522</unix_startdate>
    <user>qewqeru</user>
  </acct>
  <acct>
    <disklimit>unlimited</disklimit>
    <diskused>0M</diskused>
    <domain>zse.ru</domain>
    <email>*unknown*</email>
    <ip>192.168.123.208</ip>
    <maxaddons>*unknown*</maxaddons>
    <maxftp>unlimited</maxftp>
    <maxlst>unlimited</maxlst>
    <maxparked>*unknown*</maxparked>
    <maxpop>unlimited</maxpop>
    <maxsql>unlimited</maxsql>
    <maxsub>unlimited</maxsub>
    <owner>root</owner>
    <partition>home</partition>
    <plan>default</plan>
    <shell>/bin/bash</shell>
    <startdate>10 Mar 22 16:21</startdate>
    <suspended>0</suspended>
    <suspendreason>not suspended</suspendreason>
    <suspendtime></suspendtime>
    <theme>x3</theme>
    <unix_startdate>1269249671</unix_startdate>
    <user>zseru</user>
  </acct>
  <status>1</status>
  <statusmsg>Ok</statusmsg>
</listaccts>
THEEND

$result = API::CPanel::User::list(
    {
	%correct_params,
    }
);
ok( ref $result eq 'HASH' && scalar %$result, 'API::CPanel::User::list');


$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<listaccts>
  <acct>
    <disklimit>unlimited</disklimit>
    <diskused>0M</diskused>
    <domain>qewqe.ru</domain>
    <email>*unknown*</email>
    <ip>192.168.123.208</ip>
    <maxaddons>*unknown*</maxaddons>
    <maxftp>unlimited</maxftp>
    <maxlst>unlimited</maxlst>
    <maxparked>*unknown*</maxparked>
    <maxpop>unlimited</maxpop>
    <maxsql>unlimited</maxsql>
    <maxsub>unlimited</maxsub>
    <owner>root</owner>
    <partition>home</partition>
    <plan>default</plan>
    <shell>/bin/bash</shell>
    <startdate>10 Mar 22 16:18</startdate>
    <suspended>0</suspended>
    <suspendreason>not suspended</suspendreason>
    <suspendtime></suspendtime>
    <theme>x3</theme>
    <unix_startdate>1269249522</unix_startdate>
    <user>qewqeru</user>
  </acct>
  <status>1</status>
  <statusmsg>Ok</statusmsg>
</listaccts>
THEEND

$result = API::CPanel::User::list_simple(
    {
	%correct_params,
    }
);
ok( ref $result eq 'ARRAY' && scalar @$result, 'API::CPanel::User::list_simple');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<restartservice>
  <restart>
      <rawout>Apache successfully restarted.</rawout>
      <result>1</result>
      <service>httpd</service>
      <servicename>Apache Web Server</servicename>
  </restart>
</restartservice>
THEEND

$result = API::CPanel::Misc::reload(
    {
	%correct_params,
	service     => 'httpd',
    }
);
is( $result, 1, 'API::CPanel::Misc::reload');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<addpkg>
  <result>
    <pkg>Host-3</pkg>
    <status>1</status>
    <statusmsg>Created the package Host-343</statusmsg>
  </result>
</addpkg>
THEEND

$result = API::CPanel::Package::add(
    {
	%correct_params,
	name      => 'Host-343',
	quota     => 110,
	frontpage => 1,
	maxlsts   => 15,
	maxsql    => 99,
    }
);

is( $result, 1, 'API::CPanel::Package::add');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<changepackage>
  <result>
    <rawout>&lt;pre&gt;
Changing bwlimit to unlimited Meg
Changing Feature List to default
Changing max pop accounts from unlimited to unlimited
Changing max sql accounts from 14 to 99
Changing max ftp accounts from unlimited to unlimited
Changing max lists from unlimited to unlimited
Changing max sub domains from unlimited to unlimited
Changing language from ru to en
Changing max parked domains from 0 to 0
Changing max addon domains from 0 to 0
Shell Access Set Correctly (noshell)
Changing cPanel theme from x to
Changing plan from default to Host-343
Resetting QUOTA....
Using Quota v3 Support
Bandwidth limit (0) is lower than (unlimited) (all limits removed)&lt;br /&gt;&lt;blockquote&gt;&lt;div style='float:left;'&gt;Enabling...&lt;/div&gt;&lt;div style='float:left;'&gt;...zse1.ru...&lt;/div&gt;&lt;div style='float:left;'&gt;Done&lt;/div&gt;&lt;/blockquote&gt;&lt;br /&gt;&lt;div class='clearit' style='clear:both; width:80%;'&gt;&amp;nbsp;&lt;/div&gt;&lt;span class=&quot;b2&quot;&gt;Warning, this will not cause ip-less accounts to become ip access, or the reverse.&lt;/span&gt;
</rawout>
    <status>1</status>
    <statusmsg>Account Upgrade/Downgrade Complete for zsezse</statusmsg>
  </result>
</changepackage>
THEEND

$result = API::CPanel::User::change_package(
    {
	%correct_params,
	user        => $manipulate_user,
	pkg         => 'Host-343',
    }
);

is( $result, 1, 'API::CPanel::User::change_package');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<editpkg>
  <result>
    <pkg>Host-3</pkg>
    <status>1</status>
    <statusmsg>Modified the package Host-343</statusmsg>
  </result>
</editpkg>
THEEND

$result = API::CPanel::Package::edit(
    {
	%correct_params,
	name        => 'Host-343',
	quota       => 100,
	frontpage   => 0,
	maxlsts     => 45,
    }
);

is( $result, 1, 'API::CPanel::Package::edit');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<listpkgs>
  <package>
    <name>Host-1</name>
    <BWLIMIT>100</BWLIMIT>
    <CGI>y</CGI>
    <CPMOD>x3</CPMOD>
    <FEATURELIST>default</FEATURELIST>
    <FRONTPAGE>n</FRONTPAGE>
    <HASSHELL>y</HASSHELL>
    <IP>n</IP>
    <LANG>ru</LANG>
    <MAXADDON>0</MAXADDON>
    <MAXFTP>10</MAXFTP>
    <MAXLST>30</MAXLST>
    <MAXPARK>0</MAXPARK>
    <MAXPOP>20</MAXPOP>
    <MAXSQL>40</MAXSQL>
    <MAXSUB>50</MAXSUB>
    <QUOTA>1000</QUOTA>
  </package>
  <package>
    <name>Host-2</name>
    <BWLIMIT>unlimited</BWLIMIT>
    <CGI>y</CGI>
    <CPMOD>x3</CPMOD>
    <FEATURELIST>default</FEATURELIST>
    <FRONTPAGE>n</FRONTPAGE>
    <HASSHELL>y</HASSHELL>
    <IP>n</IP>
    <LANG>en</LANG>
    <MAXADDON>0</MAXADDON>
    <MAXFTP>unlimited</MAXFTP>
    <MAXLST>unlimited</MAXLST>
    <MAXPARK>0</MAXPARK>
    <MAXPOP>unlimited</MAXPOP>
    <MAXSQL>unlimited</MAXSQL>
    <MAXSUB>unlimited</MAXSUB>
    <QUOTA>unlimited</QUOTA>
  </package>
  <package>
    <name>Host-3</name>
    <BWLIMIT>unlimited</BWLIMIT>
    <CGI>n</CGI>
    <CPMOD></CPMOD>
    <FEATURELIST>default</FEATURELIST>
    <FRONTPAGE>n</FRONTPAGE>
    <HASSHELL>n</HASSHELL>
    <IP>n</IP>
    <LANG>en</LANG>
    <MAXADDON>0</MAXADDON>
    <MAXFTP>unlimited</MAXFTP>
    <MAXLST>unlimited</MAXLST>
    <MAXPARK>0</MAXPARK>
    <MAXPOP>unlimited</MAXPOP>
    <MAXSQL>unlimited</MAXSQL>
    <MAXSUB>unlimited</MAXSUB>
    <QUOTA>100</QUOTA>
  </package>
  <package>
    <name>Host-343</name>
    <BWLIMIT>unlimited</BWLIMIT>
    <CGI>n</CGI>
    <CPMOD></CPMOD>
    <FEATURELIST>default</FEATURELIST>
    <FRONTPAGE>n</FRONTPAGE>
    <HASSHELL>n</HASSHELL>
    <IP>n</IP>
    <LANG>en</LANG>
    <MAXADDON>0</MAXADDON>
    <MAXFTP>unlimited</MAXFTP>
    <MAXLST>unlimited</MAXLST>
    <MAXPARK>0</MAXPARK>
    <MAXPOP>unlimited</MAXPOP>
    <MAXSQL>unlimited</MAXSQL>
    <MAXSUB>unlimited</MAXSUB>
    <QUOTA>100</QUOTA>
  </package>
</listpkgs>
THEEND

#$API::CPanel::DEBUG=1;

$result = API::CPanel::Package::list(
    {
	%correct_params,
    }
);

ok( $result && ref $result eq 'HASH' , 'API::CPanel::Package::list');

#warn Dumper $result;

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<killpkg>
  <result>
    <status>1</status>
    <statusmsg>The package was successfully deleted.</statusmsg>
  </result>
</killpkg>
THEEND

$result = API::CPanel::Package::remove(
    {
	%correct_params,
	pkg         => 'Host-343',
    }
);

is( $result, 1, 'API::CPanel::Package::remove');

# тест добавления IP и смены осн. IP сайта

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<addip>
  <addip>
      <msgs>eth0:4 is now up.  192.168.123.150/255.255.255.0 broadcast 192.168.123.255 has been added
      System has 1 free ip.</msgs>
      <status>1</status>
      <statusmsg>Success</statusmsg>
  </addip>
</addip>
THEEND


$result = API::CPanel::Ip::add(
    {
	%correct_params,
	ip      => '192.168.123.150',
	netmask => '255.255.255.0',
    }
);
is( $result, 1, 'API::CPanel::Ip::add');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<setsiteip>
  <result>
      <status>1</status>
      <statusmsg></statusmsg>
  </result>
</setsiteip>
THEEND

$result = API::CPanel::Domain::change_site_ip(
    {
        %correct_params,
        ip      => '192.168.123.150',
        user    => $manipulate_user,
    }
);
is( $result, 1, 'API::CPanel::Domain::change_site_ip');


$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<setsiteip>
  <result>
      <status>1</status>
      <statusmsg></statusmsg>
  </result>
</setsiteip>
THEEND

$result = API::CPanel::Domain::change_site_ip(
    {
        %correct_params,
        ip      => $main_shared_ip,
        user    => $manipulate_user,
    }
);
is( $result, 1, 'API::CPanel::Domain::change_site_ip to main_shared_ip');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<delip>
  <delip>
      <status>1</status>
      <statusmsg>eth0:4 is now down, 192.168.123.150 has been removed</statusmsg>
  </delip>
</delip>
THEEND

$result = API::CPanel::Ip::remove(
    {
	%correct_params,
	ip => '192.168.123.150',
    }
);
is( $result, 1, 'API::CPanel::Ip::remove');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<removeacct>
  <result>
    <rawout>Running pre removal script (/scripts/prekillacct)......DoneCollecting Domain Name and IP...User: zseasd
Domain: zse1.ru
...DoneKilling all processes owned by user......DoneCleaning passwd,shadow,group......DoneRemoving User from Group..........DoneRemoving Web Logs......DoneRemoving Bandwidth Files......DoneRemoving Crontab......DoneRemoving Virtual Hosts...Removed zse1.ru Server at line: 566.
Removed Entry from httpd.conf
...DoneRemoving MySQL databases and users......DoneRemoving PostgreSQL databases and users......DoneRemoving System User......DoneRemoving Group......DoneRemoving DNS Entries...zse1.ru =&gt; deleted from www. 
...DoneRemoving Email Setup...Removing /etc/valiases/zse1.ru
...DoneRemoving mailman lists......DoneUpdating Databases......DoneRemoving Counter Data......DoneAdding ip back to the ip address pool...System has 2 free ips.
...DoneRemoving users cPanel Databases &amp; Updating......DoneReloading Services......DoneRemoving mail and service configs...
...DoneSending Contacts......DoneUpdating internal databases...Updating ftp passwords for zseasd
Purging ftp user zseasd
Ftp password files updated.
Ftp vhost passwords synced
...DoneRunning post removal scripts (/scripts/legacypostkillacct, /scripts/postkillacct)......DoneAccount Removal Complete!!!...zseasd account removed...Done</rawout>
    <status>1</status>
    <statusmsg>zseasd account removed</statusmsg>
  </result>
</removeacct>
THEEND

$result = API::CPanel::User::delete(
    {
	%correct_params,
	user => $manipulate_user,
    }
);
is( $result, 1, 'API::CPanel::User::delete');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<removeacct>
  <result>
    <rawout></rawout>
    <status>0</status>
    <statusmsg>Warning!.. system user zseasd does not exist!
</statusmsg>
  </result>
</removeacct>
THEEND

$result = API::CPanel::User::delete(
    {
	%correct_params,
	user => $manipulate_user,
    }
);
is( $result, '', 'API::CPanel::User::delete repeat');


#diag Dumper( $result );

# Mysql тесты

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<?xml version="1.0" ?>
<cpanelresult>
    <module>Mysql</module>
    <func>adduser</func>
    <type>event</type>
    <source>internal</source>
    <apiversion>1</apiversion>
    <data>
        <result></result>
    </data>
    <event>
        <result>1</result>
     </event>
</cpanelresult>
THEEND

$result = API::CPanel::Mysql::adduser(
    {
        %correct_params,
        do_as_user => 'zsezse5',
        username   => 'test13',
        password   => 'test13pass',
    }
);
is( $result, 1, 'API::CPanel::Mysql::adduser');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<?xml version="1.0" ?>
<cpanelresult>
    <module>Mysql</module>
    <func>adddb</func>
    <type>event</type>
    <source>internal</source>
    <apiversion>1</apiversion>
    <data>
        <result></result>
    </data>
    <event>
        <result>1</result>
    </event>
</cpanelresult>
THEEND

$result = API::CPanel::Mysql::adddb(
    {
        %correct_params,
        do_as_user => 'zsezse5',
        dbname     => 'default',
    }
);
is( $result, 1, 'API::CPanel::Mysql::adddb');


$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<?xml version="1.0" ?>
<cpanelresult>
    <module>Mysql</module>
    <func>adduserdb</func>
    <type>event</type>
    <source>internal</source>
    <apiversion>1</apiversion>
    <data>
        <result></result>
    </data>
    <event>
        <result>1</result>
    </event>
</cpanelresult>
THEEND

$result = API::CPanel::Mysql::grant_perms(
    {
        %correct_params,
        do_as_user => 'zsezse5',
        dbname     => 'zsezse5_default',
        dbuser     => 'zsezse5_test13',
        perms_list => 'all',
    }
);
is( $result, 1, 'API::CPanel::Mysql::grant_perms');

$API::CPanel::FAKE_ANSWER = ! $ONLINE ? <<THEEND : undef;
<?xml version="1.0" ?>
<cpanelresult>
  <apiversion>2</apiversion>
  <data>
    <reason>
         aaaaa.asdasd.ru was successfully parked on top of aaaaa.x
    </reason>
    <result>1</result>
  </data>
  <event>
    <result>1</result>
  </event>
  <func>addaddondomain</func>
  <module>AddonDomain</module>
</cpanelresult>
THEEND

my $addondomain = 'ssssss.ru';
my $subdomain = 'ssssss';
$result = API::CPanel::Domain::add_addon_domain(
    {
        %correct_params,
        do_as_user      => 'zsezse5',
        dir             => "public_html/$addondomain",
        newdomain       => $addondomain,
        pass            => 'asdsadasdsad',
        subdomain       => $subdomain,
    }
);
is( $result->{data}->{result}, 1 , 'API::CPanel::Domain::add_addon_domain');

