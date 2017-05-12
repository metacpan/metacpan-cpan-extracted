use Test::More tests => 18;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Plugins::WebTransact' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::WebTransact' ) };

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'WebTransact.t',
  _programDescription => 'Testing ASNMTAP::Asnmtap::Plugins::WebTransact',
  _programVersion     => '3.002.003',
  _programGetOptions  => ['environment|e:s', 'proxy:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

isa_ok( $objectPlugins, 'ASNMTAP::Asnmtap::Plugins' );
can_ok( $objectPlugins, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
can_ok( $objectPlugins, qw(appendPerformanceData browseragent SSLversion clientCertificate pluginValue pluginValues proxy timeout setEndTime_and_getResponsTime write_debugfile call_system exit) );
	
use ASNMTAP::Asnmtap::Plugins::WebTransact;

my @URLS = ();
my $objectWebTransact = ASNMTAP::Asnmtap::Plugins::WebTransact->new ( \$objectPlugins, \@URLS );

isa_ok( $objectWebTransact, 'ASNMTAP::Asnmtap::Plugins::WebTransact' );
can_ok( $objectWebTransact, qw(matches get_matches set_matches returns get_returns set_returns urls get_urls set_urls) );


$objectWebTransact->set_returns( { ape => 'lucky' } );
%returns = %{ $objectWebTransact->returns() };
$returnCode = ( exists $returns{ape} and $returns{ape} eq 'lucky' ) ? 1 : 0;
ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::WebTransact::set_returns():');

%returns = %{ $objectWebTransact->get_returns() };
$returnCode = ( exists $returns{ape} and $returns{ape} eq 'lucky' ) ? 1 : 0;
ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::WebTransact::get_returns():');


$objectWebTransact->set_matches( ['AZERTY', 'QWERTY'] );
my $matches = $objectWebTransact->matches();
my $returnCode = ( @$matches[0] eq 'AZERTY' and @$matches[1] eq 'QWERTY' ) ? 1 : 0;
ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::WebTransact::set_matches():');
  
$returnCode = 0;
foreach my $match ( @{ $objectWebTransact->matches() } ) { $returnCode = 1; last; }
ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::WebTransact::get_matches():');


@URLS = (
  { Method => 'GET',  Url => 'http://www.citap.be/', Qs_var => [], Qs_fixed => [], Exp => "Consulting Internet Technology Alex Peeters", Exp_Fault => ">>>NIHIL<<<", Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => 'Label 1' },
);

$objectWebTransact->set_urls( \@URLS );
$returnCode = $objectWebTransact->check ( { } );
ok ($returnCode != 4, 'ASNMTAP::Asnmtap::Plugins::WebTransact::set_urls():');

$returnCode = 0;
foreach ( @{ $objectWebTransact->get_urls() } ) { $returnCode = 1; last; };
ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::WebTransact::urls():');


SKIP: {
  my $ASNMTAP_PROXY = ( exists $ENV{ASNMTAP_PROXY} ) ? $ENV{ASNMTAP_PROXY} : undef;
  skip 'Missing ASNMTAP_PROXY', 5 if ( defined $ASNMTAP_PROXY and ( $ASNMTAP_PROXY eq '0.0.0.0' or $ASNMTAP_PROXY eq '' ) );

  $returnCode = $objectWebTransact->check ( { } );
  ok ($returnCode == 0, 'ASNMTAP::Asnmtap::Plugins::WebTransact::check():');


  skip 'reason: ASNMTAP::Asnmtap::Plugins::WebTransact::check() failed', 4 if ( $returnCode );

  use constant EXP_TITLE_1 => "\Q<TITLE>\E(Consulting Internet Technology Alex Peeters)\Q</TITLE>\E";
  use constant EXP_TITLE_2 => "\Q<TITLE>\E(Consulting) (Internet) (Technology) (Alex Peeters)\Q</TITLE>\E";

  use constant EXP_SUBMAIN => "\Q<FRAME NAME=\"NO_INFO\" SRC=\"\E(submain.htm)\Q\" SCROLLING=\"No\" FRAMEBORDER=\"0\" NORESIZE>\E";
  use constant VAL_SUBMAIN => [0, sub { my %pages = ( 'index.htm' => 'InDeX', 'submain.htm' => 'subMAIN' ); $pages { $_[0] }; } ];

  @URLS = (
    { Method => 'GET',  Url => 'http://www.citap.com/', Qs_var => [], Qs_fixed => [], Exp => [EXP_SUBMAIN, 'Consulting Internet Technology Alex Peeters'], Exp_Fault => ">>>NIHIL<<<", Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => 'Label 2' },
    { Method => 'GET',  Url => 'http://www.citap.com/', Qs_var => [parameter => 0], Qs_fixed => [], Exp => [EXP_SUBMAIN, 'Consulting Internet Technology Alex Peeters'], Exp_Fault => ">>>NIHIL<<<", Exp_Return => { title1 => EXP_TITLE_1 }, Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => 'Label 2' },
    { Method => 'GET',  Url => 'http://www.citap.com/', Qs_var => [parameter => VAL_SUBMAIN], Qs_fixed => [], Exp => 'Consulting Internet Technology Alex Peeters', Exp_Fault => ">>>NIHIL<<<", Exp_Return => { title2 => EXP_TITLE_2, submain => EXP_SUBMAIN }, Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => 'Label 3' },
  );

  $returnCode = $objectWebTransact->check ( { }, custom => \&customWebTransact );
  ok ($returnCode == 0, 'ASNMTAP::Asnmtap::Plugins::WebTransact::check():');


  $returnCode = 0;
  my @matches = @{ $objectWebTransact->matches() };
  foreach my $match ( @{ $objectWebTransact->matches() } ) { $returnCode = 1; last; }
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::WebTransact::matches():');


  my %returns = %{ $objectWebTransact->returns() };
  $returnCode = ( exists $returns {title1} ) and ( exists $returns {submain} ) and ( exists $returns {title2}[0] ) and ( exists $returns {title2}[1] ) and ( exists $returns {title2}[2] ) and ( exists $returns {title2}[3] );
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::WebTransact::returns():');


  $returnCode = 0;
  foreach ( @{ $objectWebTransact->get_urls() } ) { $returnCode = 1; last; };
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::WebTransact::get_urls():');


  no warnings 'deprecated';
  $objectPlugins->{_pluginValues}->{stateValue} = $ERRORS{OK};
  $objectPlugins->{_pluginValues}->{stateError} = $STATE{$ERRORS{OK}};
  $objectPlugins->exit (0);


  sub customWebTransact {
    for ( $_[0] ) {
      /Failure of server APACHE bridge/ &&
        do { return ( $ERRORS{CRITICAL}, 1, 'Failure of server APACHE bridge' ); last; };
      /Message from the NSAPI plugin:/ && /No backend server available for connection:/ &&
        do { return ( $ERRORS{CRITICAL}, 1, "'KBOWI - Message from the NSAPI plugin - No backend server available for connection'" ); last; };
      /\Q<FRAME NAME="NO_INFO" SRC="submain.html" SCROLLING="No" FRAMEBORDER="0" NORESIZE>\E/ &&
        do { return ( $ERRORS{CRITICAL}, 0, '+submain+' ); last; };
      return ( $ERRORS{OK}, 0, undef );
    }
  }
}

