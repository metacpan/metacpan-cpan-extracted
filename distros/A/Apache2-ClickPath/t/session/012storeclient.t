use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest qw'GET_BODY GET POST';
use File::Spec;

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

sub t_read_file {
  local $/;
  open my $f, '<'.$_[0] or die "ERROR: Cannot open $_[0]: $!\n";
  return scalar <$f>;
}

Apache::TestUtil::t_write_perl_script 't/htdocs/bin/storeclient.pl', <<'EOF';
use lib qw{../../../blib/arch ../../../blib/lib};

use Apache2::ClickPath::StoreClient;

my $ctx=Apache2::ClickPath::StoreClient->new;

if( $ENV{QUERY_STRING} eq 'add' ) {
  my $v=$ctx->get( 'value' );
  $v++;
  $ctx->set( value=>$v );
  print "Content-Type: text/plain\n\n$v";
} else {
  my $v=$ctx->get( 'value' );
  print "Content-Type: text/plain\n\n$v";
}
EOF

plan tests => 16;

my ($res, $session, $store);

Apache::TestRequest::module('UAExceptionsFile');

t_rmtree('t/store');
t_mkdir('t/store');

$session=GET_BODY( "/TestSession__001session_generation?CGI_SESSION" );
$session=~s/CGI_SESSION=//; chomp( $session );

t_debug( "using session $session" );

$res=GET_BODY( "$session/bin/storeclient.pl?add" );
ok t_cmp( $res, '1', 'value initialized' );

$res=GET_BODY( "$session/bin/storeclient.pl?add" );
ok t_cmp( $res, '2', 'value incremented' );

$res=GET_BODY( "$session/bin/storeclient.pl" );
ok t_cmp( $res, '2', 'value read' );

$res=GET_BODY( "$session/TestSession__012storeclient?add" );
ok t_cmp( $res, '3', 'value incremented with modperl handler' );

$res=GET_BODY( "$session/TestSession__012storeclient" );
ok t_cmp( $res, '3', 'value read with modperl handler' );

Apache::TestRequest::user_agent( reset=>1, keep_alive=>0 );

sleep 3;

$res=GET_BODY( "/TestSession__012storeclient" ); # run cleanup
sleep 1;			# and give it time to complete

$res=GET_BODY( "$session/TestSession__012storeclient" );
ok t_cmp( $res, '<UNDEF>', 'value read after timeout' );

$res=GET_BODY( "$session/TestSession__012storeclient?add" );
ok t_cmp( $res, '1', 'value incremented again' );

sleep 1;

$res=GET_BODY( "$session/TestSession__012storeclient?big" );
ok t_cmp( $res, '1', 'set and get a big value' );



Apache::TestRequest::module('Secret');

$session=GET_BODY( "/TestSession__001session_generation?CGI_SESSION" );
$session=~s/CGI_SESSION=//; chomp( $session );

t_debug( "using session $session" );

$res=GET_BODY( "$session/bin/storeclient.pl?add" );
ok t_cmp( $res, '1', 'value initialized (Secret)' );

$res=GET_BODY( "$session/bin/storeclient.pl?add" );
ok t_cmp( $res, '2', 'value incremented (Secret)' );

$res=GET_BODY( "$session/bin/storeclient.pl" );
ok t_cmp( $res, '2', 'value read (Secret)' );

$res=GET_BODY( "$session/TestSession__012storeclient?add" );
ok t_cmp( $res, '3', 'value incremented with modperl handler (Secret)' );

$res=GET_BODY( "$session/TestSession__012storeclient" );
ok t_cmp( $res, '3', 'value read with modperl handler (Secret)' );

Apache::TestRequest::user_agent( reset=>1, keep_alive=>0 );

sleep 3;

$res=GET_BODY( "/TestSession__012storeclient" ); # run cleanup
sleep 1;			# and give it time to complete

$res=GET_BODY( "$session/TestSession__012storeclient" );
ok t_cmp( $res, '<UNDEF>', 'value read after timeout (Secret)' );

$res=GET_BODY( "$session/TestSession__012storeclient?add" );
ok t_cmp( $res, '1', 'value incremented again (Secret)' );

sleep 1;

$res=GET_BODY( "$session/TestSession__012storeclient?big" );
ok t_cmp( $res, '1', 'set and get a big value (Secret)' );

sleep 3;			# give the server time to cleanup and
				# prevent a warning if t/store is removed
				# before the server has finished it's cleanup

# Local Variables: #
# mode: cperl #
# End: #
