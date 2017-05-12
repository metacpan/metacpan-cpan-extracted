package OCV;

# Ingenico Online Credit Verification Server interface
######################################################################
# 
# UNSW Online Payment System (OPS) Server
#  (c) 1999/2000 University of NSW
# 
# Written by Benjamin Low <ben@snrc.uow.edu.au>
#
#
# OVERVIEW OF THE OCV "PROTOCOL"
#
#  The OCV 'protocol' is generally a command-response message exchange, 
# initiated by the client.  That is, a request message is sent to the
# server and the server returns an appropriate response message, after
# some delay.
#
#  An exception to the command-response sequence is for certain message
# types where a "polled mode" is available. When in "polled mode" the
# server does not send a response and the client must poll the server to
# ascertain the transaction status. Note that this "polled mode" does not
# mean the socket is non-blocking, just the application (i.e. "polled mode"
# simply determines whether the client should expect a response). Whenever
# a response is expected, this client waits for the response up to a
# given timeout period before returning an error to the application. When
# such an error occurs, the communications channel is in an undefined state 
# and should be reset (see the OCV::reset method).
#
#  The OCV 'protocol' is stateless, that is all messages contain
# sufficient information to fully determine the request. Thus you may
# connect and disconnect to the OCV server at will. For a given client
# (account), some of the required information will be constant (e.g.
# account number, client id). This module is intended to be used as one
# OCV object instance per client/acount: it "wraps" the protocol such
# that the client ID, account number (and transaction ID as required) are
# automatically supplied for each request and the application only need 
# supply the 'per-transaction' date (e.g. card details, amount).
#
#  The OCV protocol is STREAM based (i.e. TCP/IP). Thus this client 
# conceivably may not send nor receive messages atomically - messages 
# may be fragmented across reads (and writes). At present, this is not 
# accounted for, and will result in an error.
# TODO There is some guarantee regarding minimum block sizes, around 8k
# as I recall. I need to check this. The implications are that under
# high load (when buffers back up), we may start getting incomplete
# messages.
#
# Future Work:
#  - determine message fragmentation issue
#  - split out networking into a separate object, so objects for 
#    multiple clients/accounts can share connections to the server
#
# THIS OCV MODULE
# 
#  This module provides an object-oriented means of transacting with the
# OCV server. An 'OCV' object is used to converse with the server, it
# provides a method corresponding to each of the OCV message types.
# Transaction results (RESPONSEs) are returned as OCV::Message objects.
# The OCV::Message object is simply a blessed array reference, so you can
# use it as you would a simple array ref (e.g. $m->[3] to get the fourth
# element).  However, the OCV::Message object provides by-name access to
# its contents so you can say $m->Result without concerning yourself with
# which array element is the Result field.
#
# [There is a small performance penalty for using the OCV::Message
# interface - benchmarking a simplified version of the ::Message object
# shows it takes approx. ~60-70% longer than using a plain array
# (reference) (a bit over half of that seems to be in the method call to 
# the constructor). There may also be a memory usage penalty, but I've
# no easy way of checking that... Given that we're talking on the order
# of milliseconds (and perhaps bytes/kb), I've chosen to ignore this
# overhead - internally, all messages are contained in OCV::Message
# objects.]
#
#  Transaction messages (i.e. purchase, refund, etc - those messages 
# involving the bank) carry all required information in the message. In 
# particular, each Transaction message contains the Account number to use, 
# which in turn maps within the OCV to a given Merchant ID. This module 
# is designed to have one OCV object instance for each 'client', and thus 
# the Account number and Client ID are required in the constructor and 
# automatically supplied with each message. (They can be overridden per
# request if required).
#
#  BTW, most of the terminology used herein is based on that contained in 
# the OCV Developer's Specification. Personally, I find some of the terms 
# less than clear, however for the sake of consistancy I have followed the 
# spec, attempting to clarify any ambiguities in my own terms.
#
# LOGGING
#
#  An log of each 'transaction' message exchange with the OCV server is 
# written to a file given in the object constructor ("TxnLog" parameter). 
# The fields in this log are separated by a configurable character, the 
# default is ',' (warning: there is no 'safe' character guaranteed to not be 
# contained in an OCV message, so keep an eye out for "extra" fields :-).
# In addition to this transaction log, there is a server debug log ("DebugLog").
# The debug log is used to dump pretty well all the 'raw' data sent and
# receieved to/from the OCV server, plus other odds and sods. Debugging is
# turned off and on via the 'debug' constructor argument and debug() method, 
# and is off by default. NOTE that the debug flag also controls general 
# program debugging via carp (to recap, the debug log is for OCV interactions, 
# STDERR (via carp) is used for general program debugging).
#
#  The logreopen() method will reopen the log file/s, which you might
# want to do in response to a signal (also see reset()).
#
#  WARNING: when debugging is turned on sensitive data could potentially 
# be disclosed (e.g. card data within a purchase transaction message). 
# To prevent such data being logged, the logdebug message filters it's 
# output for strings which are contained in a 'debugfilter' list (only the 
# card number at present). See the comments in logdebug() for more info. 
# NOTE that this broad filtering is only done on the debug log (the card
# data written to the transaction log is separately "filtered").
#
# Totals and the Transaction Logs
#
#  The beancounters want daily transaction summaries for the OPS to
# reconcile with the bank. [An aside: the OCV server provides a Totals 
# request message, however the Ingenico documentation notes not to rely on 
# it and "it is recommended that the client ... maintain its own totals". I
# found out why this might be when the OCV server crashed during testing
# and couldn't be restarted without deleting the "journal" files (and
# associated NT registry keys). It is these journal files which the OCV
# server uses to generate the totals, so when they are toasted you lose
# all the transaction records too.]
#
#  The totals information can be gleaned from this module's transaction 
# logs (in particular, the amounts, card types and settlement dates). Note 
# though that the information is in pairs of log entries: the PURCHASE or 
# REFUND message (type, amount); and the RESPONSE or STATUS message (status,
# settlement date). Further, note that if disaster strikes one (or both) of 
# the pair may be missing, in which case the totals post-processor will 
# have to raise an error notice for manual intervention (though I expect it 
# will be difficult to detect if *both* messages are missing!).
# 
#
# USAGE
#  [note: usage has changed from below, though the gist is the same - I'll 
#   update this real-soon-now]
#
#  There is only one exported constructor: OCV::new
#  The required parameters are: server address, client ID, account number
# e.g. my $ocv = new OCV ('192.1.2.3:53005', 'MyClient', '2');
#
#  There is one OCV method provided for each message type. Each message 
# method constructs and sends an appropriate OCV message and, if 'polled
# mode' is off (i.e. blocking mode, the default), will wait to receive a 
# response from the server. It will then either timeout and return an error,
# or return the server response in the form of an array or OCV::Message 
# object. In polled mode it simply returns an empty message (empty list / 
# undef).
#
#  Note that due to the nature of the OCV protocol, if a timeout occurs
# (or any error, for that matter) the message exchange sequence will likely 
# be out of synchronisation. The server connection should be terminated and 
# reestablished, a reset() method is provided to do so.
# 
# Error Conditions
#
#  Generally, all methods return a true value/list on success, or 
# undef/empty list on failure. An error message should be in $@.
# If a 'warning' is raised, a successful return value is given with 
# $@ set to the warning message. i.e. if $@ is set, the result warrants
# closer inspection.
#  e.g.
#  if (my @m|$m = $ocv->purchase(...))
#  {
#    warn "Warning: $@" if $@;
# 	 < ok, process @m|$m >
#  }
#  else
#  {
# 	 warn "Error: $@";
#  }
#
#  If you want to do a sequence of commands (e.g. using polling), try 
# wrapping the whole lot in an eval to save a lot of result testing:
#
#  eval    # try
#  {
# 	  my $m = $ocv->purchase(..., PolledMode => POLL_NONBLOCK) or die "$@\n";
#
# 	  my $n = 60;	# don't keep trying forever
# 	  do
# 	  {
# 		  sleep 2;
# 		  # get the status of the last transaction
# 		  # - status always "blocks" and returns a response
# 		  $m = $ocv->status() or die "$@\n";
# 	  } while ($m and $m->Result == TRANS_INPROGRESS and $n--);
# 
#     warn "Warning: $@" if $@;
#
# 	  if ($m and defined($m->Result))
# 	  {
# 		  $m->Result == TRANS_APPROVED and print "Result: APPROVED\n";
# 		  $m->Result == TRANS_INPROGRESS and print "Result: INPROGRESS\n";
# 		  $m->Result == TRANS_DECLINED and print "Result: DECLINED: " . 
# 			  $m->ResponseText . ($m->Retry ? " RETRY":"") . "\n";
# 	  }
# 
# 	  defined($m);
#  }
#  or do     # catch
#  {
# 	  print "Error: $@\n";
# 	  undef;
#  };
#
#  Any number of communications failures may occur between this client and 
# the OCV server. Some of these error conditions could cause the command-
# response sequence to become missynchronised, thus it is advised that the 
# connection be closed and re-opened upon error. A flush() method is 
# provided if you wish to attempt to "manually" resynchronise. A
# reset() method is also provided: it closes the OCV connection,
# reopens the log file/s, and reopens the OCV connection. This should
# reset things to a virgin state. A reset() may also be in order in 
# response to a HUP signal.
#
# 
# NOTES/CLARIFICATIONS ON THE OCV SERVER DOCUMENTATION
#
# - Pre-authorisations and Completions
#  These transactions are handled completely by the bank - that is, the 
# OCV server doesn't do anything special with them. Moreover, they're 
# apparently treated as disparate transactions - the OCV server (at least,
# possibly also the bank) does nothing to ensure pre-auths and completions 
# match (card data, amount, etc). For example, it is apparently possible 
# for a completion with a given preauth number to 'succeed' even when the 
# card data does not match that of the pre-auth transaction. It appears 
# that behaviour in these situations is undefined - it is up to the client 
# to make sure the data match.
#
#  Generally, a completion is equivalent to a purchase.
#
# - Accounts
#  Each transaction to the bank must provide a merchant ID (to identify
# the merchant (e.g. bank account details)), and terminal ID (to identify 
# the hardware). OCV "accounts" are used to abstract these details, and 
# more importantly to allow concurrent transactions (requires multiple
# VPPs, which in turn requires both a multiple-VPP license from Ingenico and
# multiple merchant IDs and/or terminal IDs from the bank). The client (us) 
# simply specifies which account to use and the server allocates the first 
# available VPP allocated to that account. It returns the MerchantID and
# TerminalID as part of the RESPONSE message, if the client is interested.
#
#  The account number 0 is the 'Default' account and cannot be removed.
# The Default account is for the OCV Server's internal use and must not be 
# used by clients. Note that the Default account must have a VPP assigned to 
# it (which is why you get 6 accounts when you purchase a 5 account license). 
# Further, when processing concurrent transactions, if an account is busy 
# you'll get a SERVER BUSY response so it pays to allocate as many VPPs to 
# an account as possible (and make sure to retry BUSY responses).
#
# OCV DEVELOPMENT SERVER BUGS
#
#  The OCV 'Development Server' supplied by Ingenico for testing and 
# development purposes has a few bugs which mean it's not an entirely
# reliable means of testing your code. As of v.1.15, it:
#  - often locks up and/or crashes with dud messages
#  - does not respond well to polled requests. It 'locks' the account after 
#    serving some polled requests (i.e. subsequent transactions on the 
#    account return SERVER BUSY or RECORD NOT FOUND). In addition, on 
#    subsequent connections it erroneously sends a response to the polled 
#    request which mis-synchronises the rest of the communications.
#  - does not return full details for status requests (for example, it omits 
#    the settlement date, card info, merchant + terminal IDs)
#
# OCV LIVE SERVER BUGS
#
#  Unfortunately the Ingenico 'live' server (v2.08) has also shown problems,
# with one issue of a complete lockup after a totals requests (the NT registry
# had to be edited to restore service). Additionally, the server is found to
# issue unsolicted 'logon responses' around once per week. Ingenico have 
# advised this is an "undocumented feature". 
#  To work around this, LOGON responses to non-LOGON requests are 
# transparently discarded (the event is logged).
#
#
# MISCELLANEOUS NOTES ON THE CODE
#
#  As is discussed below in "Message Format Specifications", each OCV 
# message is described via a table of field name => data type pairs.
# Internally these are manipulated via hashes (see notes in the code 
# for the details). The use of hashes has required a bit of mucking
# about due to a hash's unpredictable ordering, though at the time
# of writing there was mention of "pseduo-hashes", i.e. arrays which
# support string indices, with perl automatically managing the mapping
# from string to index. Perhaps if/when perl's pseudo-hashes become
# standard the code can be simplified and performance probably improved,
# for what it's worth :-).
#
#
######################################################################
# 
# RCS Identifier:
# $Id:$
# 
# Change Log:
# $Log:$
#
# 
######################################################################
# 

use strict;			# try and pick up silly errors at compile time

use vars qw/@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION $OCV_VERSION 
	$AUTOLOAD $debug/;

$VERSION = 0.1;			# this module
$OCV_VERSION = 1.08;	# the OCV spec to which this module applies

use Exporter ();
@ISA       = qw/Exporter/;
@EXPORT    = qw//;
@EXPORT_OK = qw//;

%EXPORT_TAGS = 
(
	'server'		=> [qw/SERVER_PORT POLL_BLOCK POLL_NONBLOCK/],
	'transaction'	=> [qw/TRANS_CLIENTNET TRANS_CLIENTTEL TRANS_CLIENTMAIL 
						TRANS_APPROVED TRANS_DECLINED TRANS_INPROGRESS
						TRANS_BUSY/],
	'statistics'	=> [qw/STATS_CURRENT STATS_PERMANENT/],
	'log'			=> [qw/LOGSEPARATOR parsetxnlog/],
);
# add %EXPORT_TAGS to @EXPORT,_OK
Exporter::export_tags(qw/server transaction statistics log/);
Exporter::export_ok_tags();

use Carp;

use Socket;			# socket symbolic constants (AF_INET, SOCK_, etc)
use IO::Socket;
use IO::Select;
use IO::File;

# IO::Socket 1.20 or so provides the connected method, but it's not critical
# so fake it if we don't have it.
unless (IO::Socket->can('connected'))
{
	warn "your IO::Socket doesn't have the 'connected' method, faking it\n";
	eval '{package IO::Socket; sub connected { 1 } }';
}

use Fcntl qw(:DEFAULT);  # sysopen symbolic constants

# segregate POSIX's EXPORT list (conflicts w/ Fcntl, within IO::)
{ package OCV::POSIX; use POSIX qw//; }

# I've never liked ctime's time format...
sub timestamp {	POSIX::strftime("%Y-%m-%d.%H:%M:%S", localtime()) }

# 
############################################################################
# Constants
#
# - perl 5.004 provides the use constant pragma, but such constants do not
#   work as hash keys (they get stringified). At least with a constant sub 
#   you can force the invocation via CONSTANT().
# - note that for constant subs to be inlined, they must be prototyped as ().

	sub SERVER_PORT (){ 53005 }	# default port

	# see notes above re. "polled mode"
	sub POLL_BLOCK    (){ 0 }	# wait for response
	sub POLL_NONBLOCK (){ 1 }	# don't wait response

# Message "start flag"
	sub START_FLAG    (){ "#" }

# Message "Transaction Types" (TT_)
# - each message type has a unique single-character type code
# - some messages have the same code for both the request and response 
#   (e.g. "totals"), others have one code for the request and a different
#   code for the response.
# - some messages have the same format (e.g. the "transaction" requests), 
#   with some fields being ignored.
# - some messages have multiple formats (e.g. the "statistics" response), 
#   the "sub-types" are differentiated by a SubCode field in the message.

	# Transaction (involves the bank)
	sub TT_TRANS            (){ '!' }	# 'placeholder' for real txn types
	sub TT_TRANS_PURCHASE   (){ '1' }	# purchase request
	sub TT_TRANS_STATUS     (){ '2' }	# status request (for given txn)
	sub TT_TRANS_REFUND     (){ '4' }	# refund request
	sub TT_TRANS_PREAUTH    (){ '7' }	# pre-authorisation
	sub TT_TRANS_COMPLETION (){ '8' }	# pre-authorisation completion
	sub TT_TRANS_RESPONSE	(){ '3' }	# response

	sub istrans
	# returns true if a message is a transaction type
	{
		return grep {$_[0] eq $_} TT_TRANS_PURCHASE, TT_TRANS_STATUS,
			TT_TRANS_REFUND, TT_TRANS_PREAUTH, TT_TRANS_COMPLETION, 
			TT_TRANS_RESPONSE;
	}

	# Totals
	sub TT_TOTALS           (){ '6' }

	# Logons
	sub TT_LOGON			(){ '9' }

	# (Server) Statistics
	sub TT_STATS            (){ 'A' }

	# Virtual PinPad Configuration
	sub TT_VPPCONFIG        (){ 'B' }

	# Virtual PinPad Status
	sub TT_VPPSTATUS        (){ 'C' }

	# OCV Account List
	sub TT_ACCOUNTLIST      (){ 'D' }

	# OCV Configuration
	sub TT_CONFIG           (){ 'E' }

	# Account Modification
	sub TT_ACCOUNTMODIFY    (){ 'F' }

# Message Constants
	# for transaction messages
	# - the OCV Spec v1.07 has an error re. TRANS_INPROGRESS (3 instead of 2)
	sub TRANS_CLIENTNET  (){ '0' }	# 'internet'
	sub TRANS_CLIENTTEL  (){ '1' }	# 'telephone'
	sub TRANS_CLIENTMAIL (){ '2' }	# 'mail order'
	sub TRANS_APPROVED   (){ '0' }	# transaction status result - approved
	sub TRANS_DECLINED   (){ '1' }	# transaction status result - declined
	sub TRANS_INPROGRESS (){ '2' }	# transaction status result - waiting...
	sub TRANS_BUSY       (){ 'A6' }

	# for the statistics message
	sub STATS_CURRENT    (){ '0' }	# server statistics type
	sub STATS_PERMANENT  (){ '1' }
	# for 'type validation'
	my %STATS = map {$_ => 1} (STATS_CURRENT, STATS_PERMANENT);

	# message field lengths - used for runtime checking
	sub CLIENTIDLEN	() {  8 }
	sub TXNREFLEN	() { 16 }

# Logs

	sub LOGSEPARATOR	() { ',' }

#
######################################################################
# Message Format Specifications
# 
#  The OCV "protocol" consists of character-based messages (that is, 
# the data is in string form, not any sort of binary representation). 
# This module represents these message formats with pack() templates. To
# allow simpler specification of the message templates, each message is
# defined by a fieldname => '<template>' list, where <template> is the
# appropriate pack() specification for the field. e.g. The Client ID is
# declared in the OCV specification as being an 8 character string, so
# the message entry is ClientID => 'A8'.
#  Note that the message definitions are 'compiled' into a regular 
# pack() template at run-time. That is, the %Requests and %Responses 
# hash values are re-written with the 'compiled' versions. The compiled 
# version is a list of [ 'message template', message length, [fieldnames] ].
#  Templates: the OCV server only accepts number strings right-justified, 
# which is not directly possible with perl 5.005's pack(). A custom jpack() 
# routine extends pack() to accept justification of ASCII templates of the 
# form "A-n" to right-justify a n-character field, or A-0n to do the same
# but padding with "0"'s (the character zero, not 0x0). Zero-padding is 
# required for some numerical OCV fields.
#  Field Names: are generally abbreviated forms of those given in the 
# OCV Specification Appendix A and/or the test OCV server.
my (%Requests, %Responses);
%Requests =
(
	# all of the TT_TRANS_... messages are the same format, except for Type
	# - TT_TRANS is the master, the others are linked (see compile())
	TT_TRANS_PURCHASE()		=> TT_TRANS,
	TT_TRANS_STATUS()		=> TT_TRANS,
	TT_TRANS_REFUND()		=> TT_TRANS,
	TT_TRANS_PREAUTH()		=> TT_TRANS,
	TT_TRANS_COMPLETION()	=> TT_TRANS,
	TT_TRANS() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',	# right-justify the length
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			TxnRef		=> 'A' . TXNREFLEN,
			PolledMode	=> 'A1', 
			AccountNum	=> 'A4',
			CardData	=> 'A20',
			CardExpiry	=> 'A4',
			Amount		=> 'A-012',	# right-justify, pad w/ zeroes
			ClientType	=> 'A1',
			AuthNum		=> 'A12'
		],

	TT_LOGON() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			PinPadID	=> 'A',
			VPPNum		=> 'A3',
		],

	TT_STATS() => 
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			Reset		=> 'A1',	# true = reset
			SubCode		=> 'A1'		# STATS_PERMANENT | STATS_CURRENT
		],

	TT_VPPCONFIG() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			PinPadID	=> 'A',		# which physical pin pad?
			VPPNum		=> 'A3',	# which virtual pin pad?
			NetworkType	=> 'A',
			NetworkID	=> 'A11',
			MerchantID	=> 'A15',
			TerminalID	=> 'A8',
			AccountNum	=> 'A4',
			ClientType	=> 'A',
			Enable		=> 'A'
		],

	TT_VPPSTATUS() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			PinPadID	=> 'A',		# which physical pin pad?
			VPPNum		=> 'A3',	# which virtual pin pad?
		],

	TT_TOTALS() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			PolledMode	=> 'A1', 
			Day			=> 'A2',	# day offset (0 = today)
			AccountNum	=> 'A4',
		],

	TT_ACCOUNTLIST() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,
			# no arguments for AccountList
		],

);

%Responses = 
(

	# transaction response (same for all "transactions")
	TT_TRANS_RESPONSE() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',	# right-justify the length
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			TxnRef			=> 'A' . TXNREFLEN, 
			Result			=> 'A1', 
			ResponseCode	=> 'A2',
			ResponseText	=> 'A20',
			AccountNum		=> 'A4',
			STAN			=> 'A6',
			AuthCode		=> 'A6',
			TerminalID		=> 'A8',	# also referred to as CATID
			MerchantID		=> 'A15',	# also referred to as CAID
			Retry			=> 'A1',
			SettleDate		=> 'A8',
			CardBin			=> 'A2',
			CardDesc		=> 'A20',
			PreAuth			=> 'A12',
			AcquirerID		=> 'A1'
		],

	TT_LOGON() => 
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			UnitID			=> 'A1',
			VPPNum			=> 'A3',
			ResponseCode	=> 'A2',
			ResponseText	=> 'A20'
		],

	# the statistics request has one of two possible response messages
	TT_STATS() . STATS_CURRENT() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			SubCode			=> 'A1',
			LinkStatus		=> 'A1',
			LinkText		=> 'A20',
			PinPadStatus	=> 'A1',
			NumPhysPinPads	=> 'A1',
			NumVirtPinPads	=> 'A3',
			NumTransTx		=> 'A8',
			NumTransRx		=> 'A8',
			NumClients		=> 'A3',
			PeakClients		=> 'A3',
			StartTime		=> 'A20',
			ElapsedTime		=> 'A20',
			RejectQTimeout	=> 'A4',
			RejectParameter	=> 'A4',
			RejectOffline	=> 'A4',
			RejectBusy		=> 'A4',
			RejectLink		=> 'A4',
			NumStatusReq	=> 'A4',
			EFTSvrAddress	=> 'A15',
			EFTSvrPort		=> 'A4',
			PinPadPort		=> 'A12',
			PinPadTimeout	=> 'A3',
			NetworkName		=> 'A20',
			VPPsPeak		=> 'A3',
			VPPsCurrent		=> 'A3',
			TPMCurrent		=> 'A3',
			TPMPeak			=> 'A3'
		],

	TT_STATS() . STATS_PERMANENT() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			SubCode		=> 'A1',
			StartCount	=> 'A3',
			TPMPeak		=> 'A30',
			VPPsPeak	=> 'A30',
			PinPadQPeak	=> 'A30',
			ClientPeak	=> 'A30'
		],

	TT_VPPCONFIG() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			PinPadID	=> 'A',		# which physical pin pad?
			VPPNum		=> 'A3',	# which virtual pin pad?
			ResponseCode	=> 'A2',
			ResponseText	=> 'A20'
		],

	TT_VPPSTATUS() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			PinPadID	=> 'A',		# which physical pin pad?
			VPPNum		=> 'A3',	# which virtual pin pad?
			Status		=> 'A',		# current status (see vppstatus()
			NetworkType	=> 'A',
			NetworkID	=> 'A11',
			MerchantID	=> 'A15',
			TerminalID	=> 'A8',
			ClientType	=> 'A',		# unused
			Enabled		=> 'A',
			AccountNum	=> 'A4'
		],

	# the Totals response consists of multiple parts: the main message, 
	# and 16 Totals submessages.
	TT_TOTALS() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,

			ResponseCode	=> 'A2',	# '00' == success, 'XX' == failure
			Date		=> 'A8',		# 'YYYYMMDD'
			AccountNum	=> 'A4',
			Totals		=> ''			# 'attachment point' for list of Totals
		],
	# can say $m->Totals->[3]->CardName or, $m[7][3][0]
	TT_TOTALS() . 'Totals' =>
		[
			CardName		=> 'A20',	# card name ('MagicCard', etc)
			PurchAmt		=> 'A12',	# total purchases (cents)
			PurchNum		=> 'A8',	# total purchases (count)
			RefundAmt		=> 'A12',	# total refunds (cents)
			RefundNum		=> 'A8'		# total refunds (count)
		],


	# the AccountList response consists of multiple parts: the main message, 
	# and a variable number of Accounts submessages.
	TT_ACCOUNTLIST() =>
		[
			StartFlag	=> 'A1',
			Length		=> 'A-4',
			Type		=> 'A1',
			ClientID	=> 'A' . CLIENTIDLEN,
			
			NumAccounts	=> 'A4',	# number of Accounts following
			Accounts	=> ''		# 'attachment point' for list of Accounts
		],
	TT_ACCOUNTLIST().'Accounts' =>
		[
			Num		=> 'A4',
			Name	=> 'A20'
		],


);

my %MessageNames =
(
	TT_ACCOUNTLIST()		=> 'ACCOUNTLIST',
	TT_ACCOUNTMODIFY()		=> 'ACCOUNTMODIFY',
	TT_CONFIG()				=> 'CONFIG',
	TT_STATS()				=> 'STATISTICS',
	TT_TOTALS()				=> 'TOTALS',
	TT_TRANS_PURCHASE()		=> 'PURCHASE',
	TT_TRANS_STATUS()		=> 'STATUS',
	TT_TRANS_REFUND()		=> 'REFUND',
	TT_TRANS_PREAUTH()		=> 'PREAUTH',
	TT_TRANS_COMPLETION()	=> 'COMPLETION',
	TT_TRANS_RESPONSE()		=> 'RESPONSE',
	TT_LOGON()				=> 'LOGON',
	TT_VPPCONFIG()			=> 'VPPCONFIG',
	TT_VPPSTATUS()			=> 'VPPSTATUS',
);



#
######################################################################
# Module Initialisation
# - 'compile' message specifications

sub compile
# Compile pack templates from the message specification of the form:
#   [ fieldname => '<template character>', ... ]
# into an anonymous array containing
#   [ 'template', length, [FieldNames, ...], {fieldname => index, ...} ]
# where template is a complete jpack() template and length is the length of 
# the packed template, in bytes. The 'FieldNames' array and the 'fieldnames' 
# hash are primarily for use in OCV::Message to provide easy access to message 
# contents, and pretty(ier) output. 'FieldNames' is ordered as per the message 
# specification, the 'fieldnames' hash has each key _stripped (case and _ 
# removed).
#  Some messages (in particular, the transaction (TRANS_) messages) are
# of identical format. These are defined in the Requests/Responses message 
# tables as a 'link' to the main definition, in which case they need to be 
# 'dereferenced' by linking the compiled template with the Requests/Responses 
# entry. However there is no guarantee that the master template will have 
# been compiled at that point. Sooo, compilation is done in two passes: all 
# references are saved until after the masters have been compiled.
{
	my $r = shift;	# hash ref

	my @r;	# refences to be post-processed
	while (my ($k, $v) = each(%{$r}))
	{
		if (ref ($v)) { $r->{$k} = _compile($v) }
		else          { push (@r, $k)           }
	}
	for my $k (@r) { $r->{$k} = $r->{$r->{$k}} }
}

sub _compile
{
	my ($s) = @_;	# specification

	my $p = '';	# pack template
	my @f = ();	# fieldnames as per the message specification
	my %f = ();	# fieldnames: name => index

	# the template specification is an array pretending to be a ordered hash.
	# - i.e. even elements are keys, odd elements are values
	for (my $i = 0; $i <= $#{$s}; $i+=2)
	{
		$p .= $s->[$i+1];

		push(@f, $s->[$i]);

		$f{_strip($s->[$i])} = $#f;
	}
	return [$p, length(jpack($p)), \@f, \%f];
}

compile(\%Requests);
compile(\%Responses);

warn "\nRequests:\n", "---------\n",
	map {"\t$_ => $Requests{$_}->[1], '$Requests{$_}->[0]', [" . 
		join(", ", @{$Requests{$_}->[2]}) . "]\n"} keys(%Requests)
		if $debug;

warn "\nResponses:\n", "----------\n", 
	map {"\t$_ => $Responses{$_}->[1], '$Responses{$_}->[0]', [" . 
		join(", ", @{$Responses{$_}->[2]}) . "]\n"} keys(%Responses)
		if $debug;


######################################################################
# Support routines

# the OCV server only accepts numbers right-justified, unfortunately 
# pack left-justifies, sooooo...
sub jpack
# Extends perl's built-in pack() to accept justification of ASCII templates.
# i.e. a template of "A-4" is the same as "A4", with the string argument right 
# justified (that is, padded with spaces on the left).
# - when using the right-justified 'A' format, padding can be with spaces or 
#   zeroes ("A-6" => "   123", "A-06" => "000123")
# - this is about an order of magnitude slower than the builtin pack :-)
{
	my $template = shift;
	# @args  == @_
	my @pack_t = ();
	my @pack_a = ();

	local $SIG{__WARN__} = sub { chomp($#_); carp "@_"; };

	return pack($template, @_) unless $template =~ /-/;

	{
		local $^W = 0;	# avoid undef warnings

		# don't discard any part of the template, to ensure consistancy 
		# wrt. specification and arguments (also let pack show any errors)
		my @sequences = $template =~ /(\s*.-?(?:\d+|\*)?\s*)/g;

		#warn "sequence: ", (map "[$_]", @sequences), "\n";
		#warn "args: [", join('][', @_), "]\n";

		while (my $t = shift(@sequences))
		{
			my $a = shift @_;

			if ($t =~ /(\s*[aA])-(0?)((?:\d+|\*)?\s*)/)
			{
				$t = "$1$3";
				my $p = defined($2) ? '0' : ' ';	# pad w/ spaces or zeroes?
				$a = ($1 eq 'a' ? "\000" : $p) x ($3 - length($a)) . $a 
					if defined $a;
			}

			push(@pack_t, $t);
			push(@pack_a, $a) if defined $a;

			#$a =~ s/\000/./g; warn "$t => [$a]\n";
		}

		#warn "rebuilt sequence: [", join('', @pack_t), "]\n";
		#warn "rebuilt args: [", join('][', @pack_a), "]\n";

	}

	return pack(join('', @pack_t), @pack_a);
}

sub junpack
# As per jpack, but for unpack. As perl's inbuilt string handling 
# tricks handle justified/padded numbers, there is no special fiddling 
# required here. Thus, junpack simply strips the '-' from the template 
# and calls unpack.
{
	my ($template, $s) = @_;

	local $SIG{__WARN__} = sub { chomp($#_); carp "@_"; };

	$template =~ s/([aA])-(\d+|\*)/$1$2/g;

	return unpack($template, $s);
}

sub _strip
# Strip the supplied scalar/s of case, whitespace and _ characters.
# - Used to equate any of OptionName, optionname, option_name, Option_Name, 
# "Option Name", etc
# - if passed a list and return context is scalar, returns a ref to the list
{
# 	my $s = lc(shift);
# 	$s =~ s/[_\s]//g;
# 	return $s;
	my @s = map {lc($_)} @_;
	map {s/[_\s]//g} @s;
	return wantarray ? @s : (@s > 1 ? \@s : $s[0]);
}

sub _args
# Process an argument list of the form (name => value, ...) into a hash.
# Order is significant, in that the last of multiple "keys" is used.
# Argument names are stripped using _strip().  Returns an anonymous hash ref.
{
	my $r;
	my $args = {};

	return {} unless @_;	# no arguments

	$@ = "odd number of elements in arg list", return undef if (@_ % 2);

	while (defined(my $k = shift @_)) { $args->{_strip($k)} = shift @_; }

	return $args;
}


######################################################################
# The OCV Object

sub new
# Create an OCV object.
# Required Arguments: 
#  Server		=> 'host[:port]' (default port is SERVER_PORT)
#  ClientID		=> Client ID (funnily enough)
# Selected Optional Arguments (see the instance data for the rest):
#  AccountNum	=> Default Account Number to use for Transactions and Totals
#
{
	my ($class, @args) = @_;
	my $args;	# -> %args

	return undef unless $args = _args(@args);

	# instance data
	my $self = 
	{
		server		=> '',		# '' => avoid undef warnings below
		port		=> '',
		clientid	=> '',

		accountnum	=> undef,
		
		timeout		=> 120,	# socket timeout (2 mins, from OCV spec)
		debug		=> 0,	# log debugging messages if set
		txnref		=> time() * 100,# seed default transaction reference no.
		polledmode	=> POLL_BLOCK,	# default polling mode

		logdir		=> '',		# base log directory
		txnlog		=> undef,	# server transaction log filename (def. STDOUT)
		logseparator	=> LOGSEPARATOR,	# field separator for txn log
		debuglog	=> undef,	# OCV 'debug' log filename (default STDERR)

		minamount	=>    100,	# minimum accepted amount (cents)
		maxamount	=> 100000,	# maximum accepted amount (cents)

		# list of strings to censor from the debug log
		# - generally intended to filter 'dynamic' data (i.e. card numbers),
		#   but can be initialised with a static list of strings
		# - card numbers are added with each transaction in _transaction()
		debugfilter	=> [],

		# parameters for dealing with SERVER BUSY
		busywait		=> 6,	# average time between attempts t = (T/2,3T/2)
		busyattempts	=> 15,	# maximum number of attempts
	};

	# merge arguments
	while (my ($k, $v) = each %{$args})
	{
		$self->{$k} = $v;
	}

	bless ($self, $class);

	# break apart server:port
	#  - accept "server", "server:", "server:port"
	$self->{'server'} =~ /^(.*?)(?::(\d*))?$/;
	$self->{'server'} = $1;
	$self->{'port'}   = $2 || SERVER_PORT unless $self->{'port'};

	# check required arguments
	$@ = "invalid Server[:Port]", return undef 
		unless ($self->{'server'} and $self->{'port'});
	$@ = "invalid ClientID: [$self->{clientid}] too long", return undef
		if length($self->{clientid}) > CLIENTIDLEN;
	$@ = "invalid ClientID: [$self->{clientid}] invalid chars", return undef
		unless $self->{clientid} =~ /^[\w\.\-]+$/;

	$@ = "invalid DebugFilter: not an array ref", return undef
		unless ref($self->{debugfilter}) eq 'ARRAY';

	# initialise logging, defaulting to copies of STD(OUT|ERR)
	$self->{'txnlog'}    = '&STDOUT' unless $self->{'txnlog'};
	$self->{'debuglog'}  = '&STDERR' unless $self->{'debuglog'};

	return undef unless $self->logreopen();	# open the logs

	# create a socket with which to communicate to the OCV server
	# convert the supplied server address into packed form
	#  - will fail for invalid addresses
	my $inet_n;
	$@ = "cannot determine server address from [$self->{'server'}]", 
		return undef unless $inet_n = inet_aton($self->{'server'});
	$self->{'serveraddr'} = inet_ntoa($inet_n);	# and back again, for reference

	$self->{'sockaddr'} = sockaddr_in($self->{'port'}, $inet_n);

	# create socket and connect
	return undef unless $self->connect();

	return $self;
}

sub reset
# close everything and reopen
# - first flush any pending input to the debug log, some of it may be useful...
{
	my ($self) = @_;
	$self->flush();
	$self->close and
		$self->logreopen and 
		$self->open;
}

my %_ssort;	# 'cache'
sub _ssort
# return a message hash as a list of its values, sorted in order of the 
# message specification
# - fieldnames are expected to be _stripped
# - used in printing a concise version of a message in a consistant order
#   - hashes make the programmers life easier, but aren't predictable when 
#     it comes time to iterate over them for printing and such... (the newer 
#     perls (as of 5.005, I believe) support pseudo-hashes w/ arrays, this'd 
#     be perfect in this situation)
# - not all fields have to be present in the hash, any that aren't return '-'
{
	my ($self, $spec, $h) = @_;

	# the message spec has a FieldNames array, unfortunately in unstripped
	# form (e.g. ClientID, rather than clientid)
	# - otherwise could do: map {exists $h->{$_} ? $h->{$_} : '-'} @{$s->[2]};
	# - so, I could use the _stripped 'fieldnames' spec hash (element [3]), 
	#   and sort by the fieldname indices; or just strip the already ordered 
	#   'FieldNames'.

	#warn "spec: @{$spec->[2]} (cache = " . ($_ssort{$spec} || '-') . ")\n";
	return map {exists $h->{$_} ? $h->{$_} : '-'} 
		@{$_ssort{$spec} ||= _strip(@{$spec->[2]})};
}

sub _lopen
# open a log file
{
	my ($self, $name) = @_;
	my $f = $name;			# filename = $self->{'<name>'} e.g. 'debuglog'
	my $fh = $name.'fh';	# filehandle = $self->{'<name>fh'} e.g. 'debuglogfh'

	if ($self->{$f})	# filename is set, (try to) open it
	{
		# open file
		$f = $self->{$f};	# filename
		$f = "$self->{'logdir'}/$f" unless $f =~ /^&/;
		#warn "opening $name -> [$f]\n";
		carp($@ = "failed to create logfile [$f]: $!"), return undef 
			unless defined($self->{$fh} = new IO::File(">>$f"));
		$self->{$fh}->autoflush(1);
		#warn "opened  [$name]->[$f] $self->{$fh}, ".fileno($self->{$fh})."\n";
	}
	return 1;
}

sub _lclose
# close a log file
{
	my ($self, $name) = @_;
	my $fh = $name.'fh';	# filehandle = $self->{'<name>fh'} e.g. 'debuglogfh'

	# close old fh
	if (defined($self->{$fh}) and defined(fileno($self->{$fh})))
	{
		#warn "closing [$name] $self->{$fh}, ".fileno($self->{$fh})."\n";
		carp ($@ = "error closing [$name] ($self->{$fh}): $!"), return undef
			unless close (delete $self->{$fh});
	}
	return 1;
}


sub logreopen
# Close and reopen debug and log files.
# - if you want to open a different filename, change the $self->{<name>}
#   key before calling logreopen.
# - filehandles can be opened via the standard '&FH' form (e.g. '&STDERR')
#   - ditto for '&=n' (though I haven't tested that... )
{
	my $self = shift;
	my @f = @_ ? @_ : qw/txnlog debuglog/;

	my @err;
	for my $fname (@f)
	{
		# close old fh
		push(@err, $@) unless $self->_lclose($fname);

		# open new file
		push(@err, $@) unless $self->_lopen($fname);
	}
	$@ = join("\n ", 'error/s occurred in opening logfile/s:', @err) if @err;
	return @err ? undef : 1;
}

sub logopen
{
	shift->logreopen(@_);
}

sub logclose
{
	my $self = shift;
	my @f = @_ ? @_ : qw/txnlog debuglog/;

	for my $fname (@f) { $self->_lclose($fname); }
	return 1;
}

sub logtxn
# log transaction summaries
# - meant for logging all transactions (successful or not), incl. auths
# - to avoid consistancy issues, this sub takes the request/response message 
#   itself as an argument.
# - doesn't log the 'header' of a message (i.e. first 2 fields: start flag 
#   and length)
{
	my ($self, $m) = @_;	# m = array ref to message
	carp($@="txnlog not open!"),return undef unless defined $self->{'txnlogfh'};
	carp($@="usage: logtxn(<OCV::Message>)"), return undef
		unless (ref $m eq 'ARRAY' or UNIVERSAL::isa($m, 'OCV::Message'));
	#print {$self->{'txnlogfh'}} join(" ", scalar(timestamp()), @_), "\n";
	my ($f, $l, @m) = @{$m};	# skip first two fields (start flag, length)
	print {$self->{'txnlogfh'}} join(' ', timestamp(), $MessageNames{$m->[2]}, 
		join($self->{'logseparator'}, @m)), "\n";
}

sub parsetxnlog
# the complement of logtxn: given a line from a txnlog, splits the record 
# and returns the 'prefix' (timestamp and message type) as an array ref, 
# and the message as an OCV::Message object (which is a blessed array ref).
# - class method, meant to be used by 'post processors' (e.g. totals)
{
	my ($l, $s) = @_;	# log record, separator

	local $^W = 0;		# prevent 'uninitialised value' warnings

	chomp($l);
	$s ||= LOGSEPARATOR;

	# first extract timestamp and message type
	my ($d, $t);
	($d, $t, $l) = split(/[ \t]/, $l, 3);
	$@ = "could not parse log entry", return () unless ($d and $t and $l);

	my @d = (START_FLAG, undef, split(/$s/, $l, -1));	# -1 = get all fields

	# determine message (transaction) type
	# - first double check the message type in the record prefix matches 
	#   that of the message data
	$@ = "could not determine message type", return ()
		unless ($d[2] and $d[2] =~ /^\w+$/);
	$@ = "message type mismatch: [$t] vs. [$d[2]]", return () 
		unless ($MessageNames{$d[2]} and $MessageNames{$d[2]} eq $t);
	# bail if this isn't a transaction message
	$@ = "not a transaction: [$t]", return () unless istrans($d[2]);

	# the transaction message types are unique for both requests and
	# responses, but check anyway
	$@ = "unknown or ambiguous message type: [$t]", return () 
		unless (exists $Requests{$d[2]} xor exists $Responses{$d[2]});

	# look up message spec
	my $r = exists $Requests{$d[2]} ? $Requests{$d[2]} : $Responses{$d[2]};

	# check data has expected number of fields
	$@="invalid message data, expected ".@{$r->[2]}." fields: got [".@d."]\n", 
		return () unless (@d == @{$r->[2]});

	# fill in the message length, for completeness' sake
	$d[1] = $r->[1];

	# seems ok so far, create a Message object
	my $m = OCV::Message->new(\@d, $r);

	$@ = "couldn't create Message object: [$@]", return () unless $m;

	return ([$d, $t], $m);	
}

sub logdebug
# log everything else
# - to prevent sensitive data being logged, the message to be written is
#   filtered, blacking out all incidences of strings in the debugfilter list
#   - the comparison is case-insensitive
# - scalar, array & hash refs are dereferenced (one level only)
{
	my $self = shift;
	local $^W = 0;

	return unless $self->{'debuglogfh'};

	my $msg = join(" ", map 
	 {
		 if    (ref($_) eq 'SCALAR') { '\\' . ${$_} }
		 elsif (ref($_) eq 'ARRAY')	{ ('[', join(', ', map {$_} @{$_}), ']') }
		 elsif (ref($_) eq 'HASH')	{ my $h = $_; ('{', 
			 join(', ', map {"$_ => ".$h->{$_}} keys(%{$h})), '}') }
		 else  { $_ }
	 } @_
	);

	# iterate over the debugfilter list, censoring matches
	for my $naughty (@{$self->{'debugfilter'}})
	{
		my $nice = '.' x length($naughty);
		$msg =~ s/$naughty/$nice/gi;
	}

	print {$self->{'debuglogfh'}} timestamp()." ".$msg."\n";
}

sub AUTOLOAD
# provide a by-name interface to OCV instance data
#  e.g. $ocv->debug
# Returns undef if the field is not found. Note you could also get an undef 
# if the data value is undef. (Perhap I need an "exists" operator?).
# If an argument is provided, the field is set to the new value, and the 
# old value is returned.
#  e.g. $ocv->debug(1)
# NOTE: no validity checking is done when setting values.
# - any typos will likely end up here (e.g. OCV::blah(); $ocv->logdebg(...)), 
#   so it's important to check that a) the supplied object is indeed an OCV
#   object; and b) the field exists.
{
	my ($self, $newval) = @_;
	my $oldval;

	# strip the package name from the autoloaded name
	(my $name = $AUTOLOAD) =~ s/.*:://;
	return if $name eq 'DESTROY';	# throw 'im back

	# if self isn't an OCV object, then it's probably intended as an argument
	# to a static (class) method $name
	$@ = "[$name]: not an OCV object/method", return undef 
		unless (UNIVERSAL::isa($self, 'OCV'));

	$name = _strip($name);

	$@ = "[$name]: no such field", return undef unless exists $self->{$name};

	$oldval = $self->{$name};						# get old value
	$self->{$name} = $newval if defined($newval);	# set new value

	return $oldval;
}

sub _open
# create the socket, but don't connect()
{
	my ($self) = @_;

	unless (defined($self->{'io'}))
	{
		$@ = "could not create IO object: $!", return undef
			unless ($self->{'io'} = new IO::Socket);

		# propagate timeout to IO::Socket object (for connect, etc)
		$self->{'io'}->timeout($self->{'timeout'}) if exists $self->{'timeout'};
	}
	unless (defined($self->{'io'}->fileno))
	{
		$@ = "could not create socket: $!", return undef
			unless $self->{'io'}->socket(PF_INET, SOCK_STREAM, 0);
	}
	unless (defined($self->{'sel'}))
	{
		$self->{'sel'} = new IO::Select();
		$@ = "could not create IO::Select object: $!", return undef
			unless $self->{'sel'};
	}

	# may have gotten a new file number
	$self->{'sel'}->add($self->{'io'}) 
		unless $self->{'sel'}->exists($self->{'io'});

	return 1;
}

sub connect
# Open the connection to the server.
{
	my ($self) = @_;

	$self->_open;

	# IO::Socket dies (inside an eval) if the connect fails, which triggers
	# any 'external' __DIE__ handler.
	local $SIG{__DIE__} = 'IGNORE';
	if ($self->{'io'}->connect($self->{'sockaddr'}))
	{
		$self->logdebug("Connected to $self->{'server'}" . 
			"($self->{'serveraddr'}):$self->{'port'}");
		return 1;
	}
	else
	{
		$self->logdebug("Connect failed $self->{'serveraddr'}:$self->{'port'}". 
			": $!");
		$@ = "could not connect to [$self->{'serveraddr'}:$self->{'port'}]: $!";
		return undef;
	}
}

sub disconnect
# Close the connection to the server.
{
	my ($self) = @_;

	$self->logdebug('Closing connection');

	$@ = "no IO object", return undef
		unless $self->{'io'};

	$self->{'sel'}->remove($self->{'io'});	# remove handle from IO::Select

	$@ = "could not close connection: $!", return undef
		unless $self->{'io'}->close();

	$self->{'disconnected'} = 1;

	return 1;
}

sub ping
# try and confirm the server connection is alive
{
	my $self = shift;

	$@ = "not connected", return undef unless $self->{'io'}->connected;

	# there isn't an OCV 'noop' command, use a simple stats request
	# - result should be a statistics array, or error
	return ($self->statistics(SubCode => STATS_PERMANENT));
}

sub DESTROY
{
	my $self = shift;
	# sometimes the IO and other 'sub-objects' seem to have been cleaned up
	# TODO - figure out why
	#warn "$self = \n", 
	#	map {my $s = $self->{$_} || '-'; $s =~ s/[\x00-\x1f\x7f-\xff]/?/g; 
	#	"\t$_ => $s\n"} keys %{$self};
	{
	local $^W = 0;	# ignore IO::Socket warnings
	$self->disconnect(@_) if (!$self->{'disconnected'} and 
		$self->{'io'} and $self->{'io'}->connected);
	}
}

sub open  { shift->   connect(@_); }
sub close { shift->disconnect(@_); }

sub flush
# try and resynchronise the connection by dumping all pending input
# - probably better to close and (re-)open (see reset method)
{
	my $self = shift;
	my $buf;
	while ($self->{'sel'}->can_read(0) and $self->{'io'}->sysread($buf, 8192))
	{
		$self->logdebug("flush: discarding [$buf]");
	}
	"\000";	# true, but "silent" (mainly for the ocv command line util)
}

sub _send
# assumes data is not fragmented
{
	my $self = shift;

	$@ = "send: not connected", return undef unless $self->{'io'}->connected;

	$@ = "send: timeout", return undef 
		unless $self->{'sel'}->can_write($self->{'timeout'});

	# see logdebug() re. logging of sensitive data
	$self->logdebug(sprintf("send:     %3d [%s]", length($_[0]), $_[0]));

	my $r;
	eval
	{
		local $SIG{__WARN__} = 'IGNORE';
		local $SIG{ALRM} = sub { die "timeout\n" };
		alarm ($self->{'timeout'});
		$r = $self->{'io'}->syswrite($_[0], length($_[0]));
		alarm (0);
	};
	chomp ($@), $@ = "send: syswrite: $@", return undef if $@;


	$@ = "send: error: $!", return undef unless defined($r);

	return $r;
}

sub _recv
# arguments (buf, len): reads len bytes into buf
# assumes data is not fragmented - i.e. if we ask for N bytes, we get N bytes,
# or an error
# - I don't do a dual-read (i.e. read header, extract message length, read
#   the rest of the message). I couldn't see the point: once the message
#   exchange sequence is messed up, I can no longer trust it.
{
	my $self = shift;

	$@ = "recv: not connected", return undef unless $self->{'io'}->connected;

	$@ = "recv: timeout", return undef 
		unless $self->{'sel'}->can_read($self->{'timeout'});

	my $r;
	eval
	{
		# why do I always feel queasy when it comes to signals under perl :-)
		local $SIG{__WARN__} = 'IGNORE';
		local $SIG{ALRM} = sub { die "timeout\n" };
		alarm ($self->{'timeout'});
		$r = $self->{'io'}->sysread($_[0], $_[1]);
		alarm (0);
	};
	chomp ($@), $@ = "recv: sysread: $@", return undef if $@;

	$self->logdebug(sprintf("recv: %3d/%3d [%s]", length($_[0]), $_[1], 
		$_[0]));

	$@ = "recv: error: $!", return undef unless defined($r);

	# if I listened for something, it's because I was expecting something
	# - fail on EOF
	#$@ = "recv: end of file", return undef unless length($_[0]);
	$@ = "recv: end of file", return undef unless $r;

	$@ = "recv: short read: wanted [$_[1]], got [$r]", return undef 
		unless $r == $_[1];

	return $r;
}

sub _message
# send a message, and receive a response if required
# - returns the message response as an OCV::Message object
# - if the Request(Response) message is undef, no data is sent (received)
#   - this is useful for "partial" messages (see totals() for example)
#   - if no response is required, simply returns true on success
# - consistancy check: if $check is != 0, the ClientID of the recieved 
#   message is compared against the args ->{ClientID} and any mismatch
#   flagged as an error
#   - the default is to check all tx/rx sequences, but not to check
#     if we're just receiving (i.e. partial receives)
# - returns undef on error
{
	my ($self, $args, $mtx, $mrx, $check) = @_;
	# consistancy check: nothing to check if we're just receiving
	$check = defined($mtx) unless defined $check;

	$@ = "unknown Request message [$mtx]", return undef
		if (defined($mtx) and not exists $Requests{$mtx});
	$@ = "unknown Response message [$mrx]", return undef
		if (defined($mrx) and not exists $Responses{$mrx});

	my $r;

	# default/fixed arguments for both Requests and Responses
	$args->{'polledmode'} = $self->{'polledmode'} unless 
		defined $args->{'polledmode'};
	$args->{'clientid'}  = $self->{'clientid'};	# can't be overridden

	if (defined($mtx))	# something to transmit?
	{
		$r = $Requests{$mtx};			# request message spec

		# "required" arguments
		$args->{'startflag'} = START_FLAG;
		$args->{'type'}      = $mtx;
		$args->{'length'}    = $r->[1];

		my @m;	# message arguments, formed from $args
		$#m = $#{$r->[2]};	# presize, supposedly a bit faster
		while (my ($k, $v) = each %{$r->[3]})
		{
			carp($@="argument [$k] not supplied"), return undef 
				if (!defined $args->{$k} and $self->{'debug'});
			$m[$r->[3]{$k}] = $args->{$k};
		}

		my $m = jpack($r->[0], @m);
		return undef unless $self->_send($m);
	}

	if (defined($mrx))	# something to receive?
	{
		$r = $Responses{$mrx};	# response message spec

		my @m;	# message arguments, formed from $args

		# want the response?
		if ($args->{'polledmode'} and $args->{'polledmode'} == POLL_NONBLOCK)
		{
			# don't want a response
			# - return an "empty" message of the appropriate size
			# - by-name field access requires the message array to be complete
			# - also want to differentiate bet. an error and "no result"
			@m = ();
			$#m = $#{$r->[2]};	# size the array as per the expected response
		}
		else
		{
			# do want a response, get it
			my $m = '';
			RETRY:
			unless ($self->_recv($m, $r->[1]))
			{
				# see if the dud response looks like a message
				# - in particular, look for errant LOGONs
				if ($mtx and $mtx ne substr(TT_LOGON, 0, 1) and
					 length($m) == $Responses{TT_LOGON()}->[1])
				{
					# it looks like a LOGON, does it feel like one...
					@m = junpack($Responses{TT_LOGON()}->[0], $m);
					if ($m[2] eq substr(TT_LOGON, 0, 1))
					{
					  $self->logdebug("_message: errant LOGON discarded [$m]");
						goto RETRY;
					}
				}
				$@ = "invalid message: [$@] [$m]";
				carp($@);
				return undef;
			}

			@m = junpack($r->[0], $m);	# unpack the response

			# confirm we got an appropriate response type (except for partial
			# receives)
			# - only the first character is relevant with regard to the OCV
			#   message type (I use multi-character 'subtypes' internally to 
			#   disambiguate some message types e.g. TT_STATS)
			if ($check and $m[2] ne substr($mrx, 0, 1))
			{
				my ($t, $s) = ($mrx =~ /(.)(.*)/);
				$s = '' unless defined $s; # most messages don't have a subtype
				$@ = "invalid message type: wanted [$t]$s, got [$m[2]]";
				carp($@);
				return undef;
			}

			# confirm consistant ClientID (as per Ingenico guidelines)
			if ($check and $args->{'clientid'} ne $m[3])
			{
				$@ = "inconsistant ClientID: sent [$args->{'clientid'}], " . 
					"got [$m[3]]";
				carp($@);
				return undef;
			}
		}

		# construct and return a ::Message object
		# - provide the (unpacked) message and the message field names
		return OCV::Message->new(\@m, $r);
	}
	# will only get here if no response message was provided, in which case
	# just return true to indicate nothing failed
	return 1;
}

sub gettxnref
# Returns the last transaction reference number (string, actually).
# - required for when a transaction fails, as the application needs to  
#   send the txn ref to the OCV to query the fate of the failed transaction.
# - note that the $self->{'txnref'} key can be a code reference which 
#   generates a new ref each time it's called, hence the need for 
#   this "reminder".
# - you ordinarily wouldn't need this method, as by default a status
#   transaction without am explicit TxnRef will use the last value.
#   (see _transaction).
{
	shift->{'lasttxnref'};
}
sub _transaction
# Generic transaction (purchase, refund, preauth, completion, status)
# - when an error occurs when using 'auto' Transaction Reference numbering, 
# 	the application will not know the Transaction Reference (TxnRef) so as 
# 	to query the OCV for the transaction status. For this reason the
# 	last transaction reference used is saved and is the default for any 
# 	subsequent status request. This TxnRef is also available via gettxnref().
# 	So, after a transaction fails, you should immediately call status,
# 	without arguments, to determine the fate of the transaction, or call
# 	gettxnref() and save the reference for future reconciliaton.
# - returns the message on success, an empty list / undef on error
{
	my ($self, $type, @args) = @_;
	my $args;

	$@ = '';

	my $lasttxnref = $self->{'lasttxnref'};
	$self->{'lasttxnref'} = undef;	# avoid stale results

	return undef unless $args = _args(@args);

	# required transaction arguments
	$args->{'type'} = $type;
	$args->{'accountnum'} = $self->{'accountnum'} 
		unless defined $args->{'accountnum'};
	$args->{'clienttype'} = TRANS_CLIENTNET;
	$args->{'polledmode'} = $self->{'polledmode'} 
		unless defined $args->{'polledmode'};

	# WARNING
	# - make sure to filter all sensitive data from the logs!
	# - see comments in logdebug()
	# - local = changes made here will be undone at end of sub
	#   - self->{'dbfl'} points to a array ref, which is the data struct we 
	#     want to localise (i.e. not the hash key {'dbfl'}). You can't 
	#     localise anonymous structs, so instead we create a local hash key 
	#     and copy the array to it. This new copy will disappear when the 
	#     local copy of the hash key goes out of scope and is destroyed.
	local $self->{'debugfilter'} = [@{$self->{'debugfilter'}}];	# copy the array

	# add card number to the filter list
	push(@{$self->{'debugfilter'}}, $args->{'carddata'}) if $args->{'carddata'};

	$self->logdebug("_transaction", $args);

	{	# local warning override
	local $^W = 0;

	if ($type == TT_TRANS_STATUS)	# check parameters if required
	{
		# if the application didn't provide a txn ref to get the status
		# on, use the last one
		$args->{'txnref'} = $lasttxnref unless defined($args->{'txnref'});
		$@ = 'empty TxnRef', return undef unless $args->{'txnref'};
	}
	else	# purchase/refund/pre-auth
	{
		# I don't want to hard-code any card validation criteria here, 
		# so the card number (card data) and expiry are passed unadulterated 
		# to the OCV. However, given that users are likely to (at the 
		# least :-) put spaces and other punctuation in the card field, 
		# the card number should be prefiltered by the application (e.g. 
		# $ccnum =~ s/\s+//g). I suggest no further "validation" 
		# should be done, leave the OCV to reject dud card data.
		# However, a sanity check is applied to the amount field: 1) fail 
		# if the amount is not a natural number (recall the amount is in 
		# cents); 2) fail if the amount is less than $self->{'minamount'} 
		# or greater than $self->{'maxamount'}.

		$@ = '';
		my $a = $args->{'amount'};
		$@ = "invalid amount [$a]" unless $a =~ /^\d+$/;
		$@ = "amount too small [$a]" if (defined($self->{'minamount'}) 
				and $a < $self->{'minamount'});
		$@ = "amount too large [$a]" if (defined($self->{'maxamount'}) 
				and $a > $self->{'maxamount'});

		$@ = 'no card data' unless $args->{'carddata'};
		$@ = 'no card expiry' unless $args->{'cardexpiry'};

		# an excessively long TxnRef, if used, will be truncated - given that
		# this truncation may cause duplicate IDs, it's probably better to 
		# fail here
		$@ = 'no/null TxnRef' unless $args->{'txnref'};
		$@ = "TxnRef too long: [$args->{'txnref'}] > " . TXNREFLEN
			if (length($args->{'txnref'}) > TXNREFLEN);

		return undef if $@;
	}
	} # end local warning override

	# save the txn ref for future reference
	$self->{'lasttxnref'} = $args->{'txnref'};


	# log the transaction request
	{
		# for the sake of completeness, add the clientid to the args, even
		# though it will be forced in _message
		$args->{'clientid'} = $self->{'clientid'};

		# log only the first and last four characters of the supplied card no.
		# - don't use \d, as a user may provide garbage input
		# - using {,} and *? doesn't make for the most efficient regexp, but is 
		#   the only way I could think of getting at most the first & last 4 
		#   characters of an arbitrary string.
		# - (MINOR) SECURITY NOTE: I initially (arbitrarily) chose to log the 
		#	first + last four digits of the card number, however I discovered 
		#   the Ingenico OCV server logs (in their so-called journal files)
		#   the first 6 and last 3 digits. That is, between the two of us
		#   you could get 10 digits... Sure, you've still got 6 or more to 
		#   go, but there's no real reason to not err on the side of caution. 
		#   Thus, I now only log the first four and last three.
		$args->{'carddata'} =~ /^(.{0,4})(.*?)(.{0,3})$/;
		local $args->{'carddata'} = $1 . ('.' x length($2)) . $3;

		# write the message data sorted in order of the message specification
		my @m = $self->_ssort($Requests{$type}, $args);
		$self->logtxn(\@m);
	}

	# send a Transaction message (and receive a response as required) 
	# - confirm that the TxnRef is consistant (as per Ingenico guidelines)
	#   - I guess it is possible for transactions requests/responses to get 
	#     mixed up if someone misses a beat.

	# send a request of $type, receive the TT_TRANS_RESPONSE message
	my $m = $self->_message($args, $type, TT_TRANS_RESPONSE);

	return undef unless $m;

	# log and check the response, unless polled
	unless ($args->{polledmode} and $args->{polledmode} == POLL_NONBLOCK)
	{
		# log the transaction response
		$self->logtxn($m);

		unless ($args->{txnref} eq $m->[4])
		{
			$@ = "inconsistant TxnRef: sent [$args->{txnref}], " . 
				"got [$m->[4]]";
			carp($@);
			return undef;
		}
	}

	return $m;
}

############################################
# The following are wrappers around _transaction, one for each "transaction"
# type. Note that due to the way the arguments are parsed, arguments listed 
# before the @_ can be overridden by the caller (@_); arguments listed after 
# @_ can't be overridden by the caller.
# - the 'nb' subroutines are 'non busy' (or 'non blocking', take your pick),
#   that is they'll simply return when SERVER BUSY responses are encountered
#   The non-'nb' subs will attempt to retry BUSY responses, up to a point.
# - all transactions need a unique Transaction Reference ID, except for status
# - note that new transaction references should be generated for each attempt, 
#   successful or not, busy or not.
sub nbpurchase
{
	my $self = shift;
	my $n = ref($self->{'txnref'}) eq 'CODE' ? &{$self->{'txnref'}} : 
		$self->{'txnref'}++;

	$self->_transaction(TT_TRANS_PURCHASE, TxnRef => $n, @_, AuthNum => '');
}

sub nbrefund
{
	my $self = shift;
	my $n = ref($self->{'txnref'}) eq 'CODE' ? &{$self->{'txnref'}} : 
		$self->{'txnref'}++;

	$self->_transaction(TT_TRANS_REFUND, TxnRef => $n, @_, AuthNum => '');
}

sub nbpreauth
{
	my $self = shift;
	my $n = ref($self->{'txnref'}) eq 'CODE' ? &{$self->{'txnref'}} : 
		$self->{'txnref'}++;
	$self->_transaction(TT_TRANS_PREAUTH, TxnRef => $n, @_, AuthNum => '');
}

sub nbcompletion
{
	my $self = shift;
	my $n = ref($self->{'txnref'}) eq 'CODE' ? &{$self->{'txnref'}} : 
		$self->{'txnref'}++;
	$self->_transaction(TT_TRANS_COMPLETION, TxnRef => $n, @_);
}

sub nbstatus
# Get the status of a given transaction, specified by its Transaction 
# reference number (string), TxnRef. If TxnRef is not provided, 
# _transaction will default to the last one.
{
	shift->_transaction(TT_TRANS_STATUS, 
		CardData => '', CardExpiry => '', Amount => '', AuthNum => '', 
		@_,
		PolledMode => POLL_BLOCK);
}

# the following set of subroutines will transparently retry the transaction
# in the face of SERVER BUSY responses (up to a limit)
sub _busy
{
	my ($s, $self, @a) = @_;
	my $m;
	my $n = $self->{'busyattempts'};	# maximum no. of attempts
	$m = $s->($self, @a);
	while ($m and $m->ResponseCode eq TRANS_BUSY and $n-- > 0)
	{
		select(undef, undef, undef, $self->{'busywait'} * (0.5 + rand));
		$m = $s->($self, @a);
	}

	return $m;
}

sub purchase   { _busy(\&nbpurchase,   @_) }
sub refund     { _busy(\&nbrefund,     @_) }
sub preauth    { _busy(\&nbpreauth,    @_) }
sub completion { _busy(\&nbcompletion, @_) }
sub status     { _busy(\&nbstatus,     @_) }


############################################
# now the 'miscellaneous' requests

sub statistics
# Server statistics
# - sends a Statistics request, receives one of two response
# Arguments:
#  Reset - set to 1 to reset statistics.
#  SubCode - statistics type, STATS_PERMANENT | STATS_CURRENT 
#            (default STATS_CURRENT)
{
	my ($self, @args) = @_;
	my $args;

	return undef unless $args = _args(@args);

	$args->{'subcode'} = STATS_CURRENT unless defined $args->{'subcode'};
	$args->{'reset'}   = 0 unless defined $args->{'reset'};

	# sanity check - the type of response message must be valid
	$@ = "invalid statistics subcode [$args->{'subcode'}]", return undef 
		unless exists($Responses{TT_STATS().$args->{'subcode'}});
	$self->logdebug("statistics", $args );

	# process the message - send Statistics request, receive 
	#  Statistics.SubCode
	# - note this 'Statistics.SubCode' representation used solely within 
	#   this module to disambiguate the various responses
	$self->_message($args, TT_STATS(), TT_STATS().$args->{'subcode'});
}

sub vppconfig
# Virtual pinpad configuration.
# - used to associate an Account with a VPP, and the VPP to a physical pinpad.
# - note that one Account can have multiple VPPs, which would allow concurrent 
#   transactions for that account.
# - vppstatus should be used to confirm the configuration
# Required Arguments: (see Ingenico docs for more information)
#  VPPNum - Virtual pinpad to query
#  NetworkType - '0' = AIIC, '1' = NII
#  NetworkID
#  MerchantID
#  TerminalID
#  AccountNum
#  Enable - '1' = enable the pinpad, '0' = disable
# Optional Arguments:
#  PinPadID - ID of physical pinpad unit (default 1)
{
	my ($self, @args) = @_;
	my $args;

	return undef unless $args = _args(@args);

	$args->{'pinpadid'} = 1 unless defined $args->{'pinpadid'};
	$args->{'accountnum'} = $self->{'accountnum'} 
		unless defined $args->{'accountnum'};

	$args->{'clienttype'} = 0;	# unused

	$self->logdebug("vppconfig", $args);

	# process the message
	$self->_message($args, TT_VPPCONFIG(), TT_VPPCONFIG());
}

sub vppstatus
# Virtual pinpad status.
# Required Arguments:
#  VPPNum - Virtual pinpad to query
# Optional Arguments:
#  PinPadID - ID of physical pinpad unit (default 1)
{
	my ($self, @args) = @_;
	my $args;

	return undef unless $args = _args(@args);

	$args->{'pinpadid'} = 1 unless defined $args->{'pinpadid'};

	$@ = "missing VPPNum", return undef unless defined $args->{'vppnum'};

	$self->logdebug("vppstatus", $args );

	# process the message
	$self->_message($args, TT_VPPSTATUS(), TT_VPPSTATUS());
}

sub totals
# Get list of totals for a given day offset
# Arguments:
#  Day - offset from current/most recent day
#      - note that days without any transactions recorded are skipped
# - the totals function is not "supported" by Ingenico, though it's unclear 
#   as to why
{
	my ($self, @args) = @_;
	my $args;

	return undef unless $args = _args(@args);

	$args->{'day'}        = 0 unless defined $args->{'day'};	# 0 == current
	$args->{'accountnum'} = $self->{'accountnum'} 
		unless defined $args->{'accountnum'};

	$self->logdebug("totals", $args );

	# the TOTALS message is received in multiple parts, which are then
	# massaged into one return result

	# process the main part of the message
	my $m = $self->_message($args, TT_TOTALS(), TT_TOTALS());

	return undef unless $m;

	$self->logdebug("\ttotals: getting 16 totals structures");

	# now get the 16 card totals structures (receive only)
	# - each struct is an OCV::Message
	my @d;		# to hold each record of data
	$#d = 16-1;	# presize (indices 0-15)
	my @err;	# accumulate any error messages 
	for my $d (@d)
	{
		$d = $self->_message($args, undef, TT_TOTALS().'Totals');
		push @err, $@ unless $d;
	}
	$m->[7] = \@d;	# merge into main message

	$@ = "error/s occurred in receiving totals structures:\n\t" . 
		join ("\n\t", @err) if @err;

	return $m;
}


sub accountlist
# Get Account numbers => names
# Arguments: None
{
	my ($self, @args) = @_;
	my $args;

	return undef unless $args = _args(@args);

	$self->logdebug("accountlist", $args );

	# the ACCOUNTLIST message is received in multiple parts, which are then
	# massaged into one return result

	# process the main part of the message
	my $m = $self->_message($args, TT_ACCOUNTLIST(), TT_ACCOUNTLIST());

	return undef unless $m;

	$self->logdebug("\taccountlist: getting " . ($m->[4] + 0) . 
		" account structures");

	# now get the account structures (receive only)
	# - each struct is an OCV::Message
	my @d;				# to hold each record of data
	$#d = $m->[4]-1;	# presize
	my @err;			# accumulate any error messages 
	for my $d (@d)
	{
		$d = $self->_message($args, undef, TT_ACCOUNTLIST().'Accounts');
		push @err, $@ unless $d;
	}
	$m->[5] = \@d;

	$@ = "error/s occurred in receiving accounts structures:\n\t" . 
		join ("\n\t", @err) if @err;

	return $m;
}

######################################################################
# The OCV::Message object

{
 package OCV::Message;

 use strict;

 use Carp;

 use vars qw/$AUTOLOAD/;

 # The ::Message object encapsulates OCV messages and provides 
 # some "high-level" methods to access message fields and print 
 # messages with field names.
 #  The returned object is a (blessed) reference to an array of 
 # message values, and can be used as a normal array (e.g. $m->[3]
 # will return the fourth element, typically the ClientID). In 
 # addition, named field methods may be used (e.g. $m->ClientID). 
 # Also, a print method is provided to dump the whole message, both 
 # with and without field names.

 # The (Somewhat) Gory Details
 #  As the message object is an array, I can't use it to store 
 # so-called "instance" data (i.e. the field names). Thus, I 
 # use a (package) global hash to store the field name arrays for 
 # each object. Note these records must be DESTROYed as message 
 # objects are destroyed, or you'll leak. Interestingly, using the 
 # standard Tie::RefHash will bite you here, as such a tied hash will 
 # end up with the keys being kind of self-referential and the
 # reference count never gets to zero - and DESTROY is not called. As 
 # I don't need the hash key for dereferencing, and all I really care about 
 # is a "unique identifier" for the message, I don't need nor use RefHash.
 # (Though later versions of perl will/do allow refs to be stored 'correctly' 
 # as hash keys, but hopefully in a such a fashion to avoid 'leaks' via 
 # self-references). Got that? Good.

 # BTW, be careful calling routines within this package: a call to 
 # an otherwise unknown sub will end up invoking AUTOLOAD, which will
 # try and look up the given name as a hash key from %_messages.
 # e.g. Attempting to call junpack() of the main OCV module will
 # fail (silently) - the call must be fully qualified as OCV::junpack()

 # Individual messages (anon. arrays holding the contents of a message) 
 # are associated with their message specification. That is, given an array 
 # ref, the _messages hash provides the appropriate message spec to use to 
 # interpret the array.
 my %_messages;

 sub new
 {
	my ($class, $v, $m) = @_;

	$@ = "usage: " . __PACKAGE__ . "->new(\@values, \@messagespec)",
		return undef unless (ref($v) eq 'ARRAY' and ref($m) eq 'ARRAY');

	# anoint the message value array
	bless ($v, $class);

	# hang on to the field names, AFTER the array has been blessed into 
	# it's new class (namespace). i.e. "$v" starts as "ARRAY(0x1ce9e4)" 
	# and becomes "OCV::Message=ARRAY(0x1ce9e4)" once blessed.
	# - note that the _messages{} key is simply a string used to uniquely 
	#   identify each Message object, and can't be (simply) dereferenced
	#warn "adding [$v] to _messages\n";
	$_messages{$v} = $m;

	return $v;
 }

 sub array
 # return the complete message as a plain array.
 # - this sub is provided for symmetry with hash() - in practise you'd be 
 #   better off dereferencing the message directly, of course
 {
	return @{(shift)};
 }

 sub hash
 # return the complete message as a hash of name => value pairs
 {
	my $self = shift;

	return undef unless exists($_messages{$self});

	#warn "array [$self] found\n";
	#warn "fields are\n", map {"\t$_ => $_messages{$self}->[3]{$_}\n"} 
	#	keys(%{$_messages{$self}->[3]});

	# now, there is a fieldname => index hash kept for use in the 
	# AUTOLOADed by-name interface, however the fieldnames are 
	# massaged into a lowercase, stripped format (i.e. "clientid"). 
	# So, use the original fieldnames (e.g. "ClientID") which are 
	# kept as a separate array in the message spec.
	my %h;
	for (my $i = 0; $i <= $#{$self}; $i++)
	{
		$h{$_messages{$self}->[2][$i]} = $self->[$i];
	}
	return %h;
 }

 sub fields
 # return the message fields in order as per the message specification.
 {
 	my $self = shift;

 	return () unless exists($_messages{$self});

	return @{$_messages{$self}->[2]};
 }
 sub fieldnames { shift->fields(@_) }

 sub fieldwidths
 # return the message field widths in order as per the message specification.
 {
 	my $self = shift;

 	return () unless exists($_messages{$self});

	return map {length($_)} 
		OCV::junpack($_messages{$self}->[0], '0' x $_messages{$self}->[1]);
 }

 sub DESTROY
 # remove this object's entry in the field names hash
 {
	my $self = shift;

	carp __PACKAGE__ . "::DESTROY: could not find entry for [$self]" 
		unless exists $_messages{$self};
	delete $_messages{$self};
 }

 sub AUTOLOAD
 # provide a by-name interface to message fields
 #  e.g. $m->ClientId, $m->PinPadStatus
 # if an argument is provided, the field is set to the new value
 #  e.g. $m->ClientId("blah")
 # NOTE: no validity checking is done when setting values.
 {
	my ($self, $newval) = @_;
	my $oldval;

	# strip the package name from the autoloaded name
	(my $name = $AUTOLOAD) =~ s/.*:://;
	return if $name eq 'DESTROY';	# throw 'im back

	$name = OCV::_strip($name);

	# lookup this message in the 'cache' of message specifications
	return undef unless exists($_messages{$self});

	if (exists $_messages{$self}->[3]{$name})
	{
		$oldval = $self->[$_messages{$self}->[3]{$name}];
		$self->[$_messages{$self}->[3]{$name}] = $newval if defined($newval);
		return $oldval;
	}
	else
	{
		$@ = "unknown message name [$name]";
		return undef;
	}
 }

}	# we now return you to your regularly scheduled programming...


1;
