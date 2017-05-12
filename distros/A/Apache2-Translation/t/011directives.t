# -*- mode: cperl; cperl-indent-level: 2; cperl-continued-statement-offset: 2; indent-tabs-mode: nil -*-
use strict;
use warnings FATAL => 'all';

use Apache::Test ();            # just load it to get the version
use version;
use Apache::Test (version->parse(Apache::Test->VERSION)>=version->parse('1.35')
                  ? '-withtestmore' : ':withtestmore');
use Apache::TestUtil;
use Apache::TestUtil qw/t_write_shell_script t_write_perl_script/;
use Apache::TestRequest qw{GET_BODY GET GET_RC};
use DBI;
use File::Basename 'dirname';

plan tests=>36;
#plan 'no_plan';

{
  my $f;
  sub t_start_error_log_watch {
    my $name=File::Spec->catfile( Apache::Test::vars->{t_logs}, 'error_log' );
    open $f, "$name" or die "ERROR: Cannot open $name: $!\n";
    seek $f, 0, 2;
  }

  sub t_finish_error_log_watch {
    local $/="\n";
    my @lines=<$f>;
    undef $f;
    return @lines;
  }
}

my $serverroot=Apache::Test::vars->{serverroot};
my $documentroot=Apache::Test::vars->{documentroot};
my ($db,$user,$pw)=@ENV{qw/DB USER PW/};
$user='' unless defined $user;
$pw='' unless defined $pw;
my $dbinit='';
unless( defined $db and length $db ) {
  ($db,$user,$pw)=("dbi:SQLite:dbname=$serverroot/test.sqlite", '', '');
  $dbinit="PRAGMA synchronous = OFF";
}
t_debug "Using DB=$db USER=$user";
my $dbh;

my $data;

sub update_db {
  $dbh->do('DELETE FROM trans');

  my $stmt=$dbh->prepare( <<'SQL' );
INSERT INTO trans (id, xkey, xuri, xblock, xorder, xaction) VALUES (?,?,?,?,?,?)
SQL

  my $header=<<'EOD';
#id	xkey	xuri	xblock	xorder	xaction
1	default	:PRE:	0	1	Config: 'ErrorDocument 404 /error'
2	default	:PRE:	0	2	Key: 'k'
EOD

  foreach my $l (grep !/^\s*#/, split /\n+/, $header) {
    $stmt->execute(split /\t+/, $l);
  }

  if( defined $data and length $data ) {
    foreach my $l (grep !/^\s*#/, split /\n+/, $data) {
      $stmt->execute(split /\t+/, $l);
    }
  }

  $dbh->do('UPDATE cache SET v=v+1');
}

sub prepare_db {
  $dbh=DBI->connect( $db, $user, $pw,
		     {AutoCommit=>1, PrintError=>0, RaiseError=>1} )
    or die "ERROR: Cannot connect to $db: $DBI::errstr\n";

  $dbh->do($dbinit) if( length $dbinit );
  $dbh->do('DELETE FROM sequences');
  $dbh->do('DELETE FROM trans');

  update_db
}

prepare_db;
sub n {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}

Apache::TestRequest::user_agent(reset => 1, requests_redirectable => 0);

######################################################################
## the real tests begin here                                        ##
######################################################################

$data=<<'EOD';
#id	xkey	xuri	xblock	xorder	xaction
#                                       a subsequent mod_alias handler maps /ALIAS do DOC_ROOT/alias

10	k	/alias	0	0	Uri: '/ALIAS'.$MATCHED_PATH_INFO

11	k	/file	0	0	Do: $CTX{R}=$r->document_root
110	k	/file	0	1	File: $ctx->{R}.$MATCHED_PATH_INFO

12	k	/cgi	0	0	Cgiscript
13	k	/cgi	0	1	File: $r->document_root.$MATCHED_PATH_INFO

14	k	/perl	0	0	Perlscript
15	k	/perl	0	1	File: $r->document_root.$MATCHED_PATH_INFO

16	k	/tsthnd	0	0	Perlhandler: 'TestHandler'

17	k	/tstp	0	0	Perlhandler: 'TestHandler::pathinfo'

18	k	/tstm	0	0	Perlhandler: 'TestModule'

19	k	/tstsub	0	0	Perlhandler: sub {use TestModule; TestModule->handler(@_)}

20	k	/conf	0	0	Perlhandler: 'TestConfig'

21	k	/conf/1	0	0	Config: 'TestHandlerConfig 1'

22	k	/conf/2	0	0	Config: ['TestHandlerConfig 2']

23	k	/conf/3	0	0	Config: ['TestHandlerConfig 3', '/path']

24	k	/proxy	0	0	Proxy: 'http://'.join(':', $r->get_server_name, $r->get_server_port).'/tstp'.$MATCHED_PATH_INFO

25	k	/cgi2	0	0	Config: 'AllowOverride AuthConfig', 'Options FollowSymLinks'
26	k	/cgi2	0	1	Config: 'SetHandler cgi-script'
27	k	/cgi2	0	2	File: $r->document_root.$MATCHED_PATH_INFO

28	k	/cgi3	0	0	Config: 'AllowOverride Options', 'Options FollowSymLinks'
29	k	/cgi3	0	1	Config: 'SetHandler cgi-script'
30	k	/cgi3	0	2	File: $r->document_root.$MATCHED_PATH_INFO

31	k	/error	0	0	Redirect: '/tsthnd'
32	k	/redr/1	0	0	Redirect: 'otto/1'
33	k	/redr/2	0	0	Redirect: '/otto/2'

34	k	/call	0	0	Call: qw!sub 1!
35	k	/call2	0	0	Key: 'k2'
36	k	/call2	0	1	Call: qw!sub 2!

37	k	/cgi4	0	0	Cgiscript: $r->document_root.$MATCHED_PATH_INFO

38	k	/perl4	0	0	Perlscript: $r->document_root.$MATCHED_PATH_INFO

39	k	/minfo	0	0	Perlhandler: 'TestHandler::meminfo'

40	k	/econf	0	0	Perlhandler: sub {require Apache2::Translation::Config; goto &Apache2::Translation::Config::handler;}

41	k	/fixup	0	0	Perlhandler: sub {my $r=$_[0]; $r->content_type("text/plain"); my @n=$r->notes->get("fixup_add"); $r->print("@n"); 0;}
42	k	/fixup	0	1	Fixup: $r->notes->add("fixup_add", "1")
43	k	/fixup	0	2	Fixup: $r->notes->add("fixup_add", "2")
44	k	/fixup	0	3	Fixup: $r->notes->add("fixup_add", "3")

45	k	/html	0	0	Doc: 'text/html', 'HTML'
46	k	/txt0	0	0	Doc: 'TXT'
47	k	/txt1	0	0	Doc: 'text/plain', 'TXT'

100	k	sub	0	0	Do: $r->notes->{n1}=$ARGV[0]
101	k	sub	0	1	Perlhandler: sub {$_[0]->print($_[0]->notes->{n1}.'/'.$_[0]->notes->{n2}); 0}
102	*	sub	0	0	Do: $r->notes->{n2}=$ARGV[0]
103	*	sub	0	1	Perlhandler: sub {$_[0]->print($_[0]->notes->{n1}.'/'.$_[0]->notes->{n2}); 0}
EOD
update_db;

t_write_file( $documentroot.'/ok.html', 'OK' );
t_write_perl_script( $documentroot.'/script.pl', 'print "Content-Type: text/plain\n\n".($ENV{MOD_PERL}||$ENV{GATEWAY_INTERFACE});' );

ok t_cmp GET_BODY( '/ok.html' ), 'OK', n '/ok.html';

SKIP: {
  skip "Need alias module", 1 unless( need_module( 'alias' ) );
  ok t_cmp GET_BODY( '/alias/ok.html' ), 'OK', n '/alias/ok.html';
}

ok t_cmp GET_BODY( '/file/ok.html' ), 'OK', n '/file/ok.html';

SKIP: {
  skip "Need cgi module", 2 unless( need_module( 'cgi' ) or need_module( 'cgid' ) );
  ok t_cmp GET_BODY( '/cgi/script.pl' ), qr!^CGI/!, n '/cgi/script.pl';
  ok t_cmp GET_BODY( '/cgi4/script.pl' ), qr!^CGI/!, n '/cgi4/script.pl';
}

ok t_cmp GET_BODY( '/perl/script.pl' ), qr!^mod_perl/!, n '/perl/script.pl';
ok t_cmp GET_BODY( '/perl4/script.pl' ), qr!^mod_perl/!, n '/perl4/script.pl';

t_client_log_warn_is_expected();
ok t_cmp GET_BODY( '/tsthnd' ), 'TestHandler', n '/tsthnd';

t_client_log_warn_is_expected(2);
ok t_cmp GET_BODY( '/tstm' ), 'TestModule', n '/tstm';
ok t_cmp GET_BODY( '/tstsub' ), 'TestModule', n '/tstsub';

ok t_cmp GET_BODY( '/tstp/path/info' ), '/path/info', n '/tstp/path/info';

ok t_cmp GET_BODY( '/conf/1' ), '/conf/1', n '/conf/1';
ok t_cmp GET_BODY( '/conf/2' ), '/', n '/conf/2';
ok t_cmp GET_BODY( '/conf/3' ), '/path', n '/conf/3';

SKIP: {
  skip "Need proxy and proxy_http modules", 1 unless( need_module( ['proxy','proxy_http'] ) );
  t_client_log_warn_is_expected();
  ok t_cmp GET_BODY( '/proxy/path/info' ), '/path/info', n '/proxy/path/info';
}

SKIP: {
  skip "Need cgi module", 2 unless( need_module( 'cgi' ) or need_module( 'cgid' ) );
  t_write_file( $documentroot.'/.htaccess', "Options ExecCGI\n" );
  t_client_log_error_is_expected();
  ok t_cmp GET_RC( '/cgi2/script.pl' ), 500, n '/cgi2/script.pl';

  t_start_error_log_watch;
  my $body=GET_BODY( '/cgi3/script.pl' );
  my @lines=t_finish_error_log_watch;
  if(grep /\.htaccess: Option ExecCGI not allowed here/, @lines) {
    warn "\n\n# WARNING: Your httpd is buggy.\n# See http://www.gossamer-threads.com/lists/apache/dev/327770#327770\n\n";
    ok 1, n '/cgi3/script.pl';
  } else {
    ok t_cmp $body, qr!^CGI/!, n '/cgi3/script.pl';
  }
}

my $resp=GET( '/error' );
ok t_cmp $resp->code, 302, n '/error: code==302';
ok t_cmp $resp->header('Location'),
         'http://'.Apache::TestRequest::hostport.'/tsthnd',
         n '/error: Location==http://'.Apache::TestRequest::hostport.'/tsthnd';

$resp=GET( '/not_found' );
ok t_cmp $resp->code, 302, n '/not_found: code==302';
ok t_cmp $resp->header('Location'),
         'http://'.Apache::TestRequest::hostport.'/tsthnd',
         n '/not_found: Location==http://'.Apache::TestRequest::hostport.'/tsthnd';

$resp=GET( '/redr/1' );
ok t_cmp $resp->code, 302, n '/redr/1: code==302';
ok t_cmp $resp->header('Location'),
         'http://'.Apache::TestRequest::hostport.'/redr/otto/1',
         n '/redr/1: Location==http://'.Apache::TestRequest::hostport.'/redr/otto/1';

$resp=GET( '/redr/2' );
ok t_cmp $resp->code, 302, n '/redr/2: code==302';
ok t_cmp $resp->header('Location'),
         'http://'.Apache::TestRequest::hostport.'/otto/2',
         n '/redr/2: Location==http://'.Apache::TestRequest::hostport.'/otto/2';

ok t_cmp GET_BODY( '/call' ), '1/', n '/call';
ok t_cmp GET_BODY( '/call2' ), '/2', n '/call2';

ok t_cmp GET_BODY( '/fixup' ), '1 2 3', n '/fixup';

$resp=GET( '/html' );
ok t_cmp $resp->content, 'HTML', n '/html body';
ok t_cmp $resp->header('Content-Type'), 'text/html', n '/html content_type';

$resp=GET( '/txt0' );
ok t_cmp $resp->content, 'TXT', n '/txt0 body';
ok t_cmp $resp->header('Content-Type'), 'text/plain', n '/txt0 content_type';

$resp=GET( '/txt1' );
ok t_cmp $resp->content, 'TXT', n '/txt1 body';
ok t_cmp $resp->header('Content-Type'), 'text/plain', n '/txt1 content_type';

SKIP: {
  skip "Need Linux::Smaps to report meminfo", 0 unless( need_module( 'Linux::Smaps' ) );
  t_debug GET_BODY( '/minfo' );
}

SKIP: {
  skip "Need JSON::XS or YAML to test Apache2::Translation::Config", 1
    unless( need_module( 'JSON::XS' ) or need_module( 'YAML' ) );
  my $text=GET_BODY( '/econf' );

  my $x;
  unless( eval 'require JSON::XS' and
          $x=eval {JSON::XS::decode_json($text)} ) {
    eval 'require YAML' and $x=eval {YAML::Load($text)};
  }

  ok( t_cmp $x,
      {
       TranslationProvider  => [
				'DB',
				database  => $db,
				user      => $user,
				password  => $pw,
				table     => 'trans',
				id        => 'id',
				key       => 'xkey',
				uri       => 'xuri',
				block     => 'xblock',
				order     => 'xorder',
				action    => 'xaction',
				cachetbl  => 'cache',
				cachecol  => 'v',
				singleton => '1'
			       ],
       TranslationKey       => 'default',
       TranslationEvalCache => 'unlimited'
      },
      n 'Apache2::Translation::Config' );
}

SKIP: {
  skip "Need YAML to test Apache2::Translation::Config in YAML mode", 1
    unless( need_module( 'YAML' ) );
  my $text=GET_BODY( '/econf?Yaml' );

  my $x;
  unless( eval 'require JSON::XS' and
          $x=eval {JSON::XS::decode_json($text)} ) {
    eval 'require YAML' and $x=eval {YAML::Load($text)};
  }

  ok( t_cmp $x,
      {
       TranslationProvider  => [
				'DB',
				database  => $db,
				user      => $user,
				password  => $pw,
				table     => 'trans',
				id        => 'id',
				key       => 'xkey',
				uri       => 'xuri',
				block     => 'xblock',
				order     => 'xorder',
				action    => 'xaction',
				cachetbl  => 'cache',
				cachecol  => 'v',
				singleton => '1'
			       ],
       TranslationKey       => 'default',
       TranslationEvalCache => 'unlimited'
      },
      n 'Apache2::Translation::Config' );
}

SKIP: {
  skip "Need Linux::Smaps to report meminfo", 0 unless( need_module( 'Linux::Smaps' ) );
  t_debug GET_BODY( '/minfo' );
}

$dbh->disconnect;
