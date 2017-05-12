use strict;
#use warnings FATAL => 'all';

use Apache::Test ();            # just load it to get the version
use version;
use Apache::Test (version->parse(Apache::Test->VERSION)>=version->parse('1.35')
                  ? '-withtestmore' : ':withtestmore');
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

sub ssl_loaded {
  open my $f, "t/conf/httpd.conf" or die "ERROR: Cannot read t/conf/httpd.conf: $!";
  return grep(/^\s*LoadModule\s+ssl_module\b/, <$f>) ? 1 : 0;
}

sub test {
  my $conf=shift;
  my $addr=shift;

  my ($hostport, $res);

  Apache::TestRequest::module($conf);

  # send request
  $hostport = Apache::TestRequest::hostport() || '';
  t_debug("connecting to $hostport");

  return GET_BODY "http".($conf=~'SSL'?'s':'')."://$hostport/TestSSL/".$addr;
}

Apache::TestRequest::user_agent
  (reset=>1,
   ssl_opts=>{
              SSL_ca_file=>undef,
              SSL_verify_mode=>0,
             });

if( ssl_loaded ) {
  plan tests => 9;

  ok t_cmp( test( 'default', 'lookup?HTTPS' ), "off\n", "HTTPS off" );
  ok t_cmp( test( 'SSL', 'lookup?HTTPS' ), "on\n", "HTTPS on" );
  ok t_cmp( test( 'SSL', 'lookup?SSL_PROTOCOL' ), qr/.+/, "SSL_PROTOCOL" );
  ok t_cmp( test( 'SSL', 'lookup?SSL_SERVER_S_DN' ), '/C=DE/ST=Baden-Wuertemberg/L=Gaiberg/O=Foertsch Consulting/CN=localhost/emailAddress=torsten.foertsch@gmx.net'."\n", "SSL_SERVER_S_DN" );
  ok t_cmp( test( 'SSL', 'lookup?SSL_SERVER_I_DN' ), '/C=DE/ST=Baden-Wuertemberg/L=Gaiberg/O=Foertsch Consulting/OU=CA/CN=Foertsch Consulting CA/emailAddress=torsten.foertsch@gmx.net'."\n", "SSL_SERVER_S_DN" );
  ok t_cmp( test( 'SSL', 'lookup?DUMMY' ), "\n", "DUMMY" );
  ok t_cmp( test( 'SSL', 'lookup/ext?2.16.840.1.113730.1.13' ), "Mail to torsten.foertsch\@gmx.net\n", "nsComment" );
  ok t_cmp( test( 'SSL', 'lookup/ext?2.5.29.35' ), <<'EOT', "authorityKeyIdentifier" );
keyid:4A:3A:1F:65:22:A1:67:11:A7:7E:22:E7:D4:0D:D0:11:4A:4F:6D:82
DirName:/C=DE/ST=Baden-Wuertemberg/L=Gaiberg/O=Foertsch Consulting/OU=CA/CN=Foertsch Consulting CA/emailAddress=torsten.foertsch@gmx.net
serial:00

EOT
  ok t_cmp( test( 'SSL', 'lookup/ext?2.5.29.19' ), "CA:FALSE\n", "basicConstraints" );
} else {
  plan tests => 2;

  ok t_cmp( test( 'default', 'lookup?HTTPS' ), "UNDEF\n", "no ssl" );
  ok t_cmp( test( 'default', 'lookup?DUMMY' ), "UNDEF\n", "DUMMY" );
}

# Local Variables: #
# mode: cperl #
# End: #
