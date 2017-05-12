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
#if( need_module 'ssl' ) {
  plan tests => 2;

  ok t_cmp( test( 'default', 'is_https' ), "HAVE_SSL=1 is_https: 0\n", "no ssl" );
  ok t_cmp( test( 'SSL', 'is_https' ), "HAVE_SSL=1 is_https: 1\n", "ssl" );
} else {
  plan tests => 1;

  ok t_cmp( test( 'default', 'is_https' ), "HAVE_SSL= is_https: UNDEF\n", "no ssl" );
}

# Local Variables: #
# mode: cperl #
# End: #
