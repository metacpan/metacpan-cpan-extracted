# -*- mode: cperl; cperl-indent-level: 2; cperl-continued-statement-offset: 2; indent-tabs-mode: nil -*-
use strict;
use warnings FATAL => 'all';

use Apache::Test ();            # just load it to get the version
use version;
use Apache::Test (version->parse(Apache::Test->VERSION)>=version->parse('1.35')
                  ? '-withtestmore' : ':withtestmore');
use Apache::TestUtil;
use Apache::TestUtil qw/t_catfile t_rmtree/;
use Apache::TestRequest qw{GET_BODY};
use Apache2::Translation::BDB;
use Apache2::Translation::File;

plan tests=>3;
#plan 'no_plan';

# this test exercises 3 things:
# 1) BDB provider used inside apache
# 2) using a different provider in a VHost
# 3) a bug that has subrequests prevented to work properly. The original
#    problem was this. I had a SSL connection without SSLVerifyClient.
#    Now I wanted for one url to require a client certificate and check
#    that certificates DN. So I tried to issue a subrequest via lookup_uri
#    to /require-client-cert. Then in MapToStorage of the subrequest
#    I added an SSLVerifyClient directive to trigger an SSL renegotiation.
#    After that I could check the DN:
#
# Cond: $r->connection->is_https and
#       do {use Apache2::SubRequest;
#         my $subr=$r->lookup_uri('/require-client-cert');
#         $subr->status==Apache2::Const::HTTP_OK;
#       } and
#       $r->connection->ssl_var_lookup('SSL_CLIENT_S_DN') eq
#         '...required_dn...'
#
# for the /require-client-cert URI this Config block was configured:
#
# Config: 'SSLVerifyClient optional',
#         'SSLVerifyDepth 3'
#
# and it didn't work because Translation.pm used 3 global variables: $cf,
# $r and $ctx, that were undef'ed each time the $scope object went out of
# scope. Since the subrequest went through all the request phases there were
# plenty of occasions to undef these 3 variables. Now they are stacked via
# "local".

Apache::TestRequest::module('recursion');
my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

my $fprov=Apache2::Translation::File->new(configfile=>\*DATA);

my $bdbenv=t_catfile(Apache::Test::vars->{t_conf}, 'BDBENV');
t_debug "using BDBENV $bdbenv";
t_rmtree $bdbenv;
my $prov=Apache2::Translation::BDB->new(bdbenv=>$bdbenv);

$prov->start;
$prov->begin;
$prov->clear;
$fprov->start;
$prov->append($fprov);
$fprov->stop;
$prov->commit;
$prov->stop;

sub n {my @c=caller; $c[1].'('.$c[2].'): '.$_[0];}

Apache::TestRequest::user_agent(reset => 1, requests_redirectable => 0);

######################################################################
## the real tests begin here                                        ##
######################################################################

ok t_cmp GET_BODY( '/main/PI' ),
         '[/subr/pi ] [/subr/pi /pi] [/main/PI ] [/main/PI /PI]',
   n '/main';

ok t_cmp GET_BODY( '/main/PI?1' ),
         '[/subr/subr ] [/subr/subr /subr] [/main/PI ] [/main/PI /PI]',
   n '/main?1';

ok t_cmp GET_BODY( '/main/PI?2' ),
         '[LOOKUPFILE M2S] [LOOKUPFILE FIXUP] [/main/PI ] [/main/PI /PI]',
   n '/main?2';

__DATA__

>>> 1 default /subr 0 0
PerlHandler: sub {
  my $r=shift;

  $r->content_type( 'text/plain' );
  $r->print( "subr\n" );
  return 0;
}

>>> 2 default :PRE: 0 0
Fixup:
$r->notes->add(fixupnote=>"[$URI $PATH_INFO]");

>>> 3 default /main 0 0
Do:
use Apache2::SubRequest;
my $method=$r->args?'lookup_file':'lookup_uri';
$r->filename('/');              # necessary for lookup_file.
                                # It dumps core if not set.
my $subr=$r->$method('/subr/pi');
$r->notes->add(subrtnote=>join( ':', $subr->notes->get('transnote') ));
$r->notes->add(subrfnote=>join( ':', $subr->notes->get('fixupnote') ));

>>> 4 default /main 0 1
PerlHandler: sub {
  my $r=shift;

  $r->content_type( 'text/plain' );
  $r->print( join( ' ', map {
    $r->notes->get($_);
  } qw/subrtnote subrfnote transnote fixupnote/ ) );
  return 0;
}

>>> 5 default :PRE: 0 1
Do:
$r->notes->add(transnote=>"[$URI $PATH_INFO]");

>>> 6 default :LOOKUPFILE: 0 0
Cond: $r->main->args==1

>>> 7 default :LOOKUPFILE: 0 1
Restart: '/subr/subr'

>>> 9 default :LOOKUPFILE: 1 0
Do: $MATCHED_URI='/subr/subr'

>>> 10 default :LOOKUPFILE: 1 1
Fixup:
$r->notes->add(fixupnote=>"[LOOKUPFILE FIXUP]");

>>> 11 default :LOOKUPFILE: 1 2
Do:
$r->notes->add(transnote=>"[LOOKUPFILE M2S]");

