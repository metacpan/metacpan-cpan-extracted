#!/usr/bin/perl
#
# Example script showing how to use Term::VT102 with Net::Telnet. Telnets to
# localhost and dumps what Term::VT102 thinks should be on the screen.
#

use strict;
use Net::Telnet qw(TELOPT_TTYPE);
use Term::VT102;
use HTML::FromANSI;
use Continuity;
use Time::HiRes qw(usleep);

$| = 1;

Continuity->new( port => 8080 )->loop;

sub main {
my $r = shift;

my ($host, $port) = ('localhost', 23);

my $t = new Net::Telnet (
  'Host' => $host,
  'Port' => $port,
  'Errmode' => 'return',
  'Timeout' => 1,
  'Output_record_separator' => '',
);

die "failed to connect to $host:$port" if (not defined $t);

$t->option_callback (\&opt_callback);
$t->option_accept ('Do' => TELOPT_TTYPE);
$t->suboption_callback (\&subopt_callback);
$t->timeout(undef);

my $vt = Term::VT102->new (
  'cols' => 80,
  'rows' => 23,
);

$vt->option_set ('LFTOCRLF', 1);
$vt->option_set ('LINEWRAP', 1);
$vt->callback_set ('OUTPUT', \&vt_output, $t);

my ($telnetbuf, $io, $stdinbuf);

my $html_vt = HTML::FromANSI->new(
  terminal_object => $vt
);

  $r->print(q|
    <html>
      <head>
        <style>
          body {
            background-color: black;
          }
        </style>
        <script type="text/javascript" src="jquery.js"></script>
        <script type="text/javascript">
          function listenLoop() {
            $.getScript('/', function(){ listenLoop(); });
          }
          var keychar;
          var keycode;
          $(function(){
            $('#f').submit(function() {
              return false;
            });
            $('#cmd').focus();
            $('#cmd').keypress(function(event){
              keychar = String.fromCharCode(
                event.charCode ? event.charCode : event.keyCode
              );
            });

            $('#cmd').keyup(function(event){
               keycode = event.keyCode;
               $('#term').load('/',{keycode: keycode, keychar: keychar});
               keycode = '';
               keychar = '';
            });
            $('#term').load('/');
            setInterval(function(){ $('#term').load('/'); }, 500);
          });
        </script>
      </head>
      <body>
        <div id="term"></div>
        <form id="f">
          <input id=cmd type=text name=cmd length=80>
        </form>
        <br><br>
        KEY: <span id="key"></span>
      </body>
    </html>
  |);
  $r->next;

while (1) {

    print STDERR "Getting telnet buffer.\n";
	#$telnetbuf = $t->get ('Timeout' => undef);
	$telnetbuf = $t->get ('Timeout' => 0);
    print STDERR "Got telnet buffer ($telnetbuf).\n";
	#$telnetbuf = $t->get ();
	last if ($t->eof ());
    print STDERR "Sending buffer to VT.\n";
	$vt->process($telnetbuf);# if (defined $telnetbuf);
    print STDERR "Buffer sent to VT.\n";

   $r->print($html_vt->html);
   $r->next;
   my $keycode = $r->param('keycode');
   my $keychar = $r->param('keychar');
   if($keycode || $keychar) {
       print STDERR "Keycode: $keycode\n";
       print STDERR "Keychar: $keychar\n";
       $keychar = undef if $keychar eq 'undefined';
       my $v = $keychar || ($keycode ? chr($keycode) : '');

       print STDERR "Sending '$v' to telnet\n";
        $t->print($v);
       print STDERR "Sent '$v' to telnet\n";
      #  usleep(10);
   }
}

$t->close ();
print "\n";


# Callback for "DO" handling - for Net::Telnet.
#
sub opt_callback {
	my ($obj,$opt,$is_remote,$is_enabled,$was_enabled,$buf_position) = @_;

	if ($opt == TELOPT_TTYPE and $is_enabled and !$is_remote) {
		#
		# Perhaps do something if we get TELOPT_TTYPE switched on?
		#
	}

	return 1;
}


# Callback for sub-option handling - for Net::Telnet.
#
sub subopt_callback {
	my ($obj, $opt, $parameters) = @_;
	my ($ors_old, $otm_old);

	# Respond to TELOPT_TTYPE with "I'm a VT102".
	#
	if ($opt == TELOPT_TTYPE) {
		$ors_old = $obj->output_record_separator ('');
		$otm_old = $obj->telnetmode (0);
		$obj->print (
		  "\xff\xfa",
		  pack ('CC', $opt, 0),
		  'vt102',
		  "\xff\xf0"
		);
		$obj->telnetmode ($otm_old);
		$obj->output_record_separator ($ors_old);
	}

	return 1;
}


# Callback for OUTPUT events - for Term::VT102.
#
sub vt_output {
	my ($vtobject, $type, $arg1, $arg2, $private) = @_;

	if ($type eq 'OUTPUT') {
		$private->print ($arg1);
	}
}

}

# EOF
