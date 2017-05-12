package Chipcard::CTAPI;

use 5.005;
use strict;
use warnings;
use Carp;
use Fcntl;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	CT
	CTBCS_CLA
	CTBCS_DATA_STATUS_CARD
	CTBCS_DATA_STATUS_CARD_CONNECT
	CTBCS_DATA_STATUS_NOCARD
	CTBCS_INS_EJECT
	CTBCS_INS_REQUEST
	CTBCS_INS_RESET
	CTBCS_INS_STATUS
	CTBCS_MIN_COMMAND_SIZE
	CTBCS_MIN_RESPONSE_SIZE
	CTBCS_P1_CT_KERNEL
	CTBCS_P1_DISPLAY
	CTBCS_P1_INTERFACE1
	CTBCS_P1_INTERFACE10
	CTBCS_P1_INTERFACE11
	CTBCS_P1_INTERFACE12
	CTBCS_P1_INTERFACE13
	CTBCS_P1_INTERFACE14
	CTBCS_P1_INTERFACE2
	CTBCS_P1_INTERFACE3
	CTBCS_P1_INTERFACE4
	CTBCS_P1_INTERFACE5
	CTBCS_P1_INTERFACE6
	CTBCS_P1_INTERFACE7
	CTBCS_P1_INTERFACE8
	CTBCS_P1_INTERFACE9
	CTBCS_P1_KEYPAD
	CTBCS_P2_REQUEST_GET_ATR
	CTBCS_P2_REQUEST_GET_HIST
	CTBCS_P2_REQUEST_NO_RESP
	CTBCS_P2_RESET_GET_ATR
	CTBCS_P2_RESET_GET_HIST
	CTBCS_P2_RESET_NO_RESP
	CTBCS_P2_STATUS_ICC
	CTBCS_P2_STATUS_MANUFACTURER
	CTBCS_SW1_COMMAND_NOT_ALLOWED
	CTBCS_SW1_EJECT_NOT_REMOVED
	CTBCS_SW1_EJECT_OK
	CTBCS_SW1_EJECT_REMOVED
	CTBCS_SW1_ICC_ERROR
	CTBCS_SW1_OK
	CTBCS_SW1_REQUEST_ASYNC_OK
	CTBCS_SW1_REQUEST_CARD_PRESENT
	CTBCS_SW1_REQUEST_ERROR
	CTBCS_SW1_REQUEST_NO_CARD
	CTBCS_SW1_REQUEST_SYNC_OK
	CTBCS_SW1_REQUEST_TIMER_ERROR
	CTBCS_SW1_RESET_ASYNC_OK
	CTBCS_SW1_RESET_CT_OK
	CTBCS_SW1_RESET_ERROR
	CTBCS_SW1_RESET_SYNC_OK
	CTBCS_SW1_WRONG_CLA
	CTBCS_SW1_WRONG_INS
	CTBCS_SW1_WRONG_LENGTH
	CTBCS_SW1_WRONG_PARAM
	CTBCS_SW2_COMMAND_NOT_ALLOWED
	CTBCS_SW2_EJECT_NOT_REMOVED
	CTBCS_SW2_EJECT_OK
	CTBCS_SW2_EJECT_REMOVED
	CTBCS_SW2_ICC_ERROR
	CTBCS_SW2_OK
	CTBCS_SW2_REQUEST_ASYNC_OK
	CTBCS_SW2_REQUEST_CARD_PRESENT
	CTBCS_SW2_REQUEST_ERROR
	CTBCS_SW2_REQUEST_NO_CARD
	CTBCS_SW2_REQUEST_SYNC_OK
	CTBCS_SW2_REQUEST_TIMER_ERROR
	CTBCS_SW2_RESET_ASYNC_OK
	CTBCS_SW2_RESET_CT_OK
	CTBCS_SW2_RESET_ERROR
	CTBCS_SW2_RESET_SYNC_OK
	CTBCS_SW2_WRONG_CLA
	CTBCS_SW2_WRONG_INS
	CTBCS_SW2_WRONG_LENGTH
	CTBCS_SW2_WRONG_PARAM
	ERR_CT
	ERR_HTSI
	ERR_INVALID
	ERR_MEMORY
	ERR_TRANS
	HOST
	MAX_APDULEN
	OK
	PORT_COM1
	PORT_COM2
	PORT_COM3
	PORT_COM4
	PORT_LPT1
	PORT_LPT2
	PORT_Modem
	PORT_Printer
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#=for full_export
#our @EXPORT = qw(
#	CT
#	CTBCS_CLA
#	CTBCS_DATA_STATUS_CARD
#	CTBCS_DATA_STATUS_CARD_CONNECT
#	CTBCS_DATA_STATUS_NOCARD
#	CTBCS_INS_EJECT
#	CTBCS_INS_REQUEST
#	CTBCS_INS_RESET
#	CTBCS_INS_STATUS
#	CTBCS_MIN_COMMAND_SIZE
#	CTBCS_MIN_RESPONSE_SIZE
#	CTBCS_P1_CT_KERNEL
#	CTBCS_P1_DISPLAY
#	CTBCS_P1_INTERFACE1
#	CTBCS_P1_INTERFACE10
#	CTBCS_P1_INTERFACE11
#	CTBCS_P1_INTERFACE12
#	CTBCS_P1_INTERFACE13
#	CTBCS_P1_INTERFACE14
#	CTBCS_P1_INTERFACE2
#	CTBCS_P1_INTERFACE3
#	CTBCS_P1_INTERFACE4
#	CTBCS_P1_INTERFACE5
#	CTBCS_P1_INTERFACE6
#	CTBCS_P1_INTERFACE7
#	CTBCS_P1_INTERFACE8
#	CTBCS_P1_INTERFACE9
#	CTBCS_P1_KEYPAD
#	CTBCS_P2_REQUEST_GET_ATR
#	CTBCS_P2_REQUEST_GET_HIST
#	CTBCS_P2_REQUEST_NO_RESP
#	CTBCS_P2_RESET_GET_ATR
#	CTBCS_P2_RESET_GET_HIST
#	CTBCS_P2_RESET_NO_RESP
#	CTBCS_P2_STATUS_ICC
#	CTBCS_P2_STATUS_MANUFACTURER
#	CTBCS_SW1_COMMAND_NOT_ALLOWED
#	CTBCS_SW1_EJECT_NOT_REMOVED
#	CTBCS_SW1_EJECT_OK
#	CTBCS_SW1_EJECT_REMOVED
#	CTBCS_SW1_ICC_ERROR
#	CTBCS_SW1_OK
#	CTBCS_SW1_REQUEST_ASYNC_OK
#	CTBCS_SW1_REQUEST_CARD_PRESENT
#	CTBCS_SW1_REQUEST_ERROR
#	CTBCS_SW1_REQUEST_NO_CARD
#	CTBCS_SW1_REQUEST_SYNC_OK
#	CTBCS_SW1_REQUEST_TIMER_ERROR
#	CTBCS_SW1_RESET_ASYNC_OK
#	CTBCS_SW1_RESET_CT_OK
#	CTBCS_SW1_RESET_ERROR
#	CTBCS_SW1_RESET_SYNC_OK
#	CTBCS_SW1_WRONG_CLA
#	CTBCS_SW1_WRONG_INS
#	CTBCS_SW1_WRONG_LENGTH
#	CTBCS_SW1_WRONG_PARAM
#	CTBCS_SW2_COMMAND_NOT_ALLOWED
#	CTBCS_SW2_EJECT_NOT_REMOVED
#	CTBCS_SW2_EJECT_OK
#	CTBCS_SW2_EJECT_REMOVED
#	CTBCS_SW2_ICC_ERROR
#	CTBCS_SW2_OK
#	CTBCS_SW2_REQUEST_ASYNC_OK
#	CTBCS_SW2_REQUEST_CARD_PRESENT
#	CTBCS_SW2_REQUEST_ERROR
#	CTBCS_SW2_REQUEST_NO_CARD
#	CTBCS_SW2_REQUEST_SYNC_OK
#	CTBCS_SW2_REQUEST_TIMER_ERROR
#	CTBCS_SW2_RESET_ASYNC_OK
#	CTBCS_SW2_RESET_CT_OK
#	CTBCS_SW2_RESET_ERROR
#	CTBCS_SW2_RESET_SYNC_OK
#	CTBCS_SW2_WRONG_CLA
#	CTBCS_SW2_WRONG_INS
#	CTBCS_SW2_WRONG_LENGTH
#	CTBCS_SW2_WRONG_PARAM
#	ERR_CT
#	ERR_HTSI
#	ERR_INVALID
#	ERR_MEMORY
#	ERR_TRANS
#	HOST
#	MAX_APDULEN
#	OK
#	PORT_COM1
#	PORT_COM2
#	PORT_COM3
#	PORT_COM4
#	PORT_LPT1
#	PORT_LPT2
#	PORT_Modem
#	PORT_Printer
#);
#=cut

our $VERSION = '0.2';

our $TRANSFER_BLOCK_SIZE = 128;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Chipcard::CTAPI::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Chipcard::CTAPI', $VERSION);

# Preloaded methods go here.

# Automatically increased context for multiple connections to card terminals
my $context = 0;

# Standard constructor
sub new {
    my $classname = shift;
    my $self = {};
    bless($self, $classname);
    $self->_init(@_);
    return $self->open;
}

# Store additional key/value pairs
sub _init {
    my $self = shift;
    if (@_) {
        my %extra = @_;
        @$self{keys %extra} = values %extra;
    }
}

sub setContext {
    my ($self, $context) = @_;
    $self->{'context'} = $context;
}

sub getContext {
    my ($self) = @_;
    return $self->{'context'};
}

sub setInterface {
    my ($self, $interface) = @_;
    $self->{'interface'} = $interface;
}

sub getInterface {
    my ($self) = @_;
    return $self->{'interface'} ? # defaults to COM1
           $self->{'interface'} : $self->setInterface(&PORT_COM1);
}

# Initialize the connection to the card terminal
sub open {
    my $self = shift;

    my $result = CT_init($context, $self->getInterface());
    unless ($result == &OK) {
        return; # returns undef if CT_init failed
    }
    $self->setContext($context);
    $context++;

    # Request card terminal information
    $self->requestTerminalStatus();
    
    # Reset the card terminal
    $self->reset;
    
    return $self;
}

sub reset {
    my ($self) = @_;
   
    $self->saveATRandMemorySize();
    $self->setMemorySize(0);
    
    $self->ejectICC();    
    $self->requestICC();
    return $self->checkNinetyZero();
}

sub setResult {
    my ($self, $result) = @_;
    $self->{'result'} = $result;
}

sub getResult {
    my ($self) = @_;
    return $self->{'result'};
}

sub setResponseLength {
    my ($self, $l) = @_;
    $self->{'response_length'} = $l;
}

sub getResponseLength {
    my ($self) = @_;
    return $self->{'response_length'};
}

sub setResponse {
    my ($self, $l) = @_;
    $self->{'response'} = $l;
}

sub getResponse {
    my ($self) = @_;
    return $self->{'response'};
}

sub setDebugLevel {
    my ($self, $dl) = @_;
    $self->{'debug'} = $dl;
}

sub getDebugLevel {
    my ($self) = @_;
    return $self->{'debug'} ?
           $self->{'debug'} : 0;
}

# Set maximum width for dump output in chars
sub setDumpWidth {
    my ($self, $w) = @_;
    $w = (int ($w / 3)) * 3; # round to multiple of 3
    $self->{'dump_width'} = $w;
}

sub getDumpWidth {
    my ($self) = @_;
    return $self->{'dump_width'} ?
           $self->{'dump_width'} : 78;
}

# pretty prints a hexdump of $str's first $len bytes
sub dumpCommunication {
    my ($self, $prefix, $str, $len) = @_;

    my $max_len = $self->getDumpWidth();
    
    if (defined $prefix) {
        print "$prefix";
        $max_len -= (int (((length $prefix) + 2) / 3)) * 3;
    }
    
    my @items = unpack("C" x $len, $str);
    my $format = "%02.02X " x $len;
    my $output = sprintf($format, @items);

    my $line_number = 0;
    while ($output =~ m/(.{1,$max_len})/g) {
        if ($line_number > 0) {
            print "$prefix";
        }
        print $1 . "\n";
        $line_number++;
    }   
    return $line_number;
}

sub sendCommand {
    my ($self, $target, @cmd) = @_;
    my $cmdlen = @cmd;

    my $cmdstring = pack('C' x $cmdlen, @cmd);

    if ($self->getDebugLevel() > 0) {
        $self->dumpCommunication("--> ", $cmdstring, $cmdlen);
    }
    
    my ($result, $rsplen, $response) = CT_data(
        $self->getContext(), # context
        $target,             # destination
        &HOST,               # source
        $cmdlen,             # command length
        $cmdstring,          # command
        255                  # max response length
    );

    $self->setResult($result);
    $self->setResponseLength($rsplen);
    $self->setResponse($response);
    
    if ($self->getDebugLevel() > 0) {
        $self->dumpCommunication("<-- ", $response, $rsplen);
    }
    
    return $result;
}

# Check whether the last two bytes from the most recent card terminal
# response are 0x90 0x00, signalling success.
# Returns: undef on error
#          1 on success
sub checkNinetyZero {
    my ($self) = @_;
    my $lr = $self->getResponse;
    return if ((length $lr) < 2);

    my $status_1 = substr($lr, -2, 1);
    my $status_2 = substr($lr, -1, 1);
    
    return unless ( ((ord $status_1) == 0x90) && 
                    ((ord $status_2) == 0x00) );
    return 1;
}

sub checkSixtyTwoOne {
    my ($self) = @_;
    my $lr = $self->getResponse;
    return if ((length $lr) < 2);

    my $status_1 = substr($lr, -2, 1);
    my $status_2 = substr($lr, -1, 1);
    
    return unless ( ((ord $status_1) == 0x62) && 
                    ((ord $status_2) == 0x01) );
    return 1;
}

sub checkSixtyTwoZero {
    my ($self) = @_;
    my $lr = $self->getResponse;
    return if ((length $lr) < 2);

    my $status_1 = substr($lr, -2, 1);
    my $status_2 = substr($lr, -1, 1);
    
    return unless ( ((ord $status_1) == 0x62) && 
                    ((ord $status_2) == 0x00) );
    return 1;
}

sub close {
    my ($self) = @_;
    return CT_close($self->getContext());
}

sub resetCardTerminal {
    my ($self) = @_;

    my @cmd = (0x20, 0x11, 0x01, 0x01, 0x03, 0xFF, 0x00, 0x00, 0x00);
    my $result = $self->sendCommand(&CT, @cmd);

    if ($result == &OK) {
        $self->setATR();
        $self->calculateMemorySize();
    }

    return $self->checkNinetyZero();
}
    
sub requestCardStatus {
    my $self = shift;

    my @cmd = (&CTBCS_CLA, &CTBCS_INS_STATUS, &CTBCS_P1_CT_KERNEL,
               &CTBCS_P2_STATUS_ICC, 0); 

    $self->sendCommand(&CT, @cmd);
    return $self->checkNinetyZero();
}

sub requestTerminalStatus {
    my $self = shift;

    my @cmd = (&CTBCS_CLA, &CTBCS_INS_STATUS, &CTBCS_P1_CT_KERNEL,
               &CTBCS_P2_STATUS_MANUFACTURER, 0); 

    $self->sendCommand(&CT, @cmd);
    if ($self->checkNinetyZero) {
        $self->extractTerminalInformation($self->getResponse);
    }
    return $self->checkNinetyZero();
}

sub extractTerminalInformation {
    my ($self, $response) = @_;

    $self->{'ct_manufacturer'} = substr($response, 0, 5);
    $self->{'ct_model'} = substr($response, 5, 3);
    $self->{'ct_revision'} = substr($response, 10, 5);
}

sub getTerminalInformation {
    my ($self) = @_;
    return ($self->{'ct_manufacturer'},
            $self->{'ct_model'},
            $self->{'ct_revision'});
}

sub cardInserted {
    my ($self) = @_;
    $self->requestCardStatus();
    my $rsp = $self->getResponse();
    return ((ord $rsp) > 0) ? 1 : 0;
}

sub setOldATRandMemorySize {
    my ($self) = @_;
    $self->setMemorySize($self->{'old_memory_size'});
    $self->{'ATR'} = $self->{'old_ATR'};
}

sub saveATRandMemorySize {
    my ($self) = @_;
    $self->{'old_memory_size'} = $self->getMemorySize();
    $self->{'old_ATR'} = $self->getATR();
}

sub requestICC {
    my ($self) = @_;

    my @cmd = (&CTBCS_CLA, &CTBCS_INS_REQUEST, &CTBCS_P1_INTERFACE1,
               &CTBCS_P2_REQUEST_GET_ATR, 0); 

    my $result = $self->sendCommand(&CT, @cmd);
    
    if ($result == &OK) {
        # workaround for terminals which return 0x62 0x01 instead of
        # ATR 0x90 0x00 if the same card is still inserted, i.e. if
        # ejectICC() was ignored.
        if ($self->checkSixtyTwoOne) {
            $self->setOldATRandMemorySize;
            return 1;
        }
        $self->setATR();
        $self->calculateMemorySize();
        $self->extractProtocolInformation();
        $self->extractStructureInformation();
    }
    else {
        delete $self->{'ATR'};
        $self->setMemorySize(0);
    }
    
    return $self->checkNinetyZero();
}

sub setATR {
    my ($self) = @_;

    if ($self->getResponseLength() > 2) {
        my $lastResponse = substr($self->getResponse(), 0,
                                  $self->getResponseLength() - 2);
        $self->{'ATR'} = $lastResponse;
    }
    else {
        delete $self->{'ATR'};
    }
}

sub getATR {
    my ($self) = @_;
    return $self->{'ATR'};
}

sub setMemorySize {
    my ($self, $s) = @_;
    $self->{'memory_size'} = $s;
}

sub getMemorySize {
    my ($self) = @_;
    return $self->{'memory_size'} ? 
           $self->{'memory_size'} : 0;
}

sub cardChanged {
    my ($self) = @_;
    $self->requestCardStatus();
    $self->requestICC();
    return 0 if ($self->checkSixtyTwoOne); # still same card
    return if ($self->checkSixtyTwoZero); # no card inserted
    return 1; # new card inserted
}

sub calculateMemorySize {
    my ($self) = @_;

    return unless (defined $self->getATR());
    
    my $atr_1 = substr($self->getATR(), 1, 1);
    $atr_1 = unpack ("C", $atr_1);
   
    # memory size calculation as suggested by Heiko Abraham 2003/06/05
    $self->setMemorySize( 1 << ((($atr_1 & 120) >> 3) + 6 ) * 1 << 
                          ( $atr_1 & 0x07) / 8);
    
    # my $i1 = ($atr_1 >> 3) & 0x07;
    # my $i2 = $atr_1 & 0x07;

    # my ($j1, $j2);
    # if ($i2 == 0) {
    #    $j2 = 0;
    # }
    # elsif ($i2 == 1) {
    #     $j2 = 1;
    # }
    # else {
    #     $j2 = 1 << $i2;
    # }
    
    # if ($i1 == 0) {
    #     $j1 = 0;
    # }
    # else {
    #     $j1 = 64 << $i1;
    # }
    
    # if ($j1 && $j2) {
    #     $self->setMemorySize(($j1 * $j2) / 8);
    # }
    # else {
    #     $self->setMemorySize(0);
    # }
}

sub extractStructureInformation {
    my ($self) = @_;

    return unless (defined $self->getATR());
    
    my $atr_0 = substr($self->getATR(), 0, 1);
    $atr_0 = unpack ("C", $atr_0);

    if (($atr_0 & 3) == 0) {
        $self->setStructureInformation('ISO');
    }
    elsif(($atr_0 & 7) == 2) {
        $self->setStructureInformation('common');
    }
    elsif(($atr_0 & 7) == 6) {
        $self->setStructureInformation('proprietary');
    }
    else {
        $self->setStructureInformation('special');
    }
}
    
sub setStructureInformation {
    my ($self, $s) = @_;
    $self->{'card_structure'} = $s;
}

sub getStructure {
    my ($self) = @_;
    return $self->{'card_structure'};
}

sub extractProtocolInformation {
    my ($self) = @_;

    return unless (defined $self->getATR());
    
    my $atr_0 = substr($self->getATR(), 0, 1);
    $atr_0 = unpack ("C", $atr_0);

    if (($atr_0 & 128) == 0) {
        $self->setProtocol('ISO');
    } 
    elsif (($atr_0 & 240) == 128) {
        $self->setProtocol('I2C');
    } 
    elsif (($atr_0 & 240) == 144) {
        $self->setProtocol('3W');
    } 
    elsif (($atr_0 & 240) == 160) {
        $self->setProtocol('2W');
    }
    else {
        $self->setProtocol('unknown');
    }
}

sub setProtocol {
    my ($self, $proto) = @_;
    $self->{'card_protocol'} = $proto;
}

sub getProtocol {
    my ($self) = @_;
    return $self->{'card_protocol'};
}

sub selectFile {
    my ($self) = @_;
    my @apdu = (0x00, 0xA4, 0x00, 0x00, 0x02, 0x3F, 0x00);
    $self->sendCommand(0, @apdu);
    return $self->checkNinetyZero();
}

sub ejectICC {
    my ($self) = @_;
    my @apdu = (0x20, 0x15, 0x01, 0x00, 0x00);
    $self->sendCommand(&CT, @apdu);
    return $self->checkNinetyZero();    
}

sub readChunk {
    my ($self, $address, $size, $offset) = @_;

    $self->selectFile() or return;
    $size &= 0xFF; # sanity check

    my @cmd = (0x00, 0xB0, ($address >> 8), ($address & 0xFF), $size);
    $self->sendCommand(0, @cmd);

    $self->extractData($offset);
    return $self->checkNinetyZero();
}

sub setData {
    my ($self, $d) = @_;
    $self->{'data'} = $d;
}

sub getData {
    my ($self) = @_;
    return defined $self->{'data'} ? $self->{'data'} : '';
}

sub getDataLength {
    my ($self) = @_;
    return length $self->getData();
}

sub extractData {
    my ($self, $offset) = @_;

    my $data = substr($self->getResponse, 0,
                      $self->getResponseLength - 2);
    my $data_length = length $data;
    my $olddata = $self->getData();
    
    my $prefix = substr($olddata, 0, $offset);
    my $suffix;
    $suffix = substr($olddata, $offset + $data_length)
        if (length $olddata > $offset + $data_length);
    
    my $newdata;
    $newdata .= $prefix if (defined $prefix);
    $newdata .= $data   if (defined $data);
    $newdata .= $suffix if (defined $suffix);
    
    $self->setData($newdata);
}

sub read {
    my ($self, $address, $size) = @_;
    my $offset = 0;

    $self->setData('');
    
    if ($size > $self->getMemorySize) {
        $size = $self->getMemorySize;
    }
    return unless ($size);
    
    while ($size > $TRANSFER_BLOCK_SIZE) {
        $self->readChunk($address + $offset, $TRANSFER_BLOCK_SIZE, $offset)
            or return;
        $offset += $TRANSFER_BLOCK_SIZE;
        $size   -= $TRANSFER_BLOCK_SIZE;
    }
    if ($size > 0) {
        $self->readChunk($address + $offset, $size, $offset)
            or return;
    }
    
    return $self->getDataLength;
}

# returns the index of the first occurence of $needle in our data
# returns -1 if not found at all
sub getIndex {
    my ($self, $needle) = @_;
    my $haystack = $self->getData;
    my $pos = 0;
    while ($haystack =~ m/(.)/g) {
        return $pos if ((ord $1) == $needle);
        $pos++;
    }
    return -1;
}

sub download {
    my ($self, $filename, $ascii_mode) = @_;

    $ascii_mode = 0 unless (defined $ascii_mode);
    sysopen(F, $filename, O_WRONLY|O_TRUNC|O_CREAT, 0600) or return;

    $self->read(0, $self->getMemorySize);

    unless($ascii_mode) {
        syswrite(F, $self->getData, $self->getMemorySize);
    }
    else {
        my $pos = $self->getIndex(0);
        syswrite(F, $self->getData, $pos) unless ($pos == -1);
    }

    CORE::close(F) or return;
    return 1;
}

# returns a single byte from the data storage
sub getDataByte {
    my ($self, $index) = @_;
    return chr(0) unless (defined $self->{'data'});
    my $c = length $self->{'data'} > $index ? 
            substr($self->{'data'}, $index, 1) : chr(0);
    return $c;
}

sub writeChunk {
    my ($self, $address, $size, $offset) = @_;
    $self->selectFile or return;
    $size &= 0xFF; # sanity check for ctapi
    
    my @cmd = (0x00, 0xD6, $address >> 8, $address & 0xFF, $size);

    for (my $i=0; $i<$size; $i++) {
        push @cmd, ord $self->getDataByte($i + $offset);
    }
    
    $self->sendCommand(0, @cmd);
    $self->checkNinetyZero();
}

sub write {
    my ($self, $address, $size) = @_;
    my $offset = 0;

    $size = $self->getMemorySize
        if ($size > $self->getMemorySize);

    return unless ($size);
        
    while ($size > $TRANSFER_BLOCK_SIZE) {
        $self->writeChunk($address + $offset, $TRANSFER_BLOCK_SIZE, $offset)
            or return;
        $offset += $TRANSFER_BLOCK_SIZE;
        $size   -= $TRANSFER_BLOCK_SIZE;
    }
    if ($size > 0) {
        $self->writeChunk($address + $offset, $size, $offset)
            or return;
    }
    $self->checkNinetyZero();
}

sub upload {
    my ($self, $filename) = @_;
    sysopen(F, $filename, O_RDONLY) or return 0;

    my $buf;
    my $num_read = sysread(F, $buf, $self->getMemorySize);
    return 0 unless ($num_read);
    CORE::close(F) or return 0;
    $self->setData(substr($buf, 0, $num_read));
    $self->write(0, $num_read);
    return $self->checkNinetyZero();
}

sub submitPIN {
    my ($self, $pin) = @_;
    
    my @cmd = (0x00, 0x20, 0x00, 0x00, length $pin);

    my @pin = split //, $pin;
    foreach my $p (@pin) {
        push @cmd, $p;
    }
    $self->sendCommand(0, @cmd);
    return $self->checkNinetyZero();
}

sub changePIN {
    my ($self, $old_pin, $new_pin) = @_;
    my $both_pins = $old_pin . $new_pin;

    my @cmd = (0x00, 0x24, 0x00, 0x00, length $both_pins);

    my @pin = split //, $both_pins;
    foreach my $p (@pin) {
        push @cmd, $p;
    }
    $self->sendCommand(0, @cmd);
    return $self->checkNinetyZero();
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=pod

=head1 NAME

Chipcard::CTAPI - Perl module for communication with chipcard terminals

=head1 SYNOPSIS

 use Chipcard::CTAPI;

 my $ct = new Chipcard::CTAPI('interface' => &Chipcard::CTAPI::PORT_COM1)
     or die "Can't communicate with card terminal";
           
 my $memory_size = $ct->getMemorySize();
  
 $ct->read(0, $memory_size) 
     or die "Can't read data from card.\n";
 $ct->dumpCommunication("Content: ", $ct->getData, $ct->getDataLength);

 my $content = "Hello, world!\n";
 $ct->setData($content);
 $ct->write(0, $ct->getDataLength)
     or die "Can't write new content to card.\n";
    
 $ct->close;

=head1 ABSTRACT

Chipcard::CTAPI enables Perl programs to communicate with chipcard
terminals based on the low-level CTAPI driver.

=head1 DESCRIPTION

Using the CTAPI (card terminal application programming interface) is a
simple yet powerful way to communicate with chipcard terminals. There
are more advanced APIs available, like PC/SC, but in general they are 
not as easy and fast to set up as CTAPI. Especially when an application 
is not all about chipcards but just includes some features which can 
make use of them, CTAPI is often the best way to go as it implies less 
overhead for the end user.

Chipcard::CTAPI is a Perl module which provides direct access to the
low-level CTAPI functions (which are, in fact, only three), but focusses 
on a couple of convenience methods for reading and writing memory cards.

=head1 METHODS

This description of methods is sorted in the order you probably will 
want to use them.

=over 4

=item B<new> 

Creates a new Chipcard::CTAPI object. You must pass at least the
I<interface> option which specifies the physical port your card
terminal is attached to.

Example:
    my $ct = new Chipcard::CTAPI('interface' => &Chipcard::CTAPI::PORT_COM1);

A list of all possible PORT-constants can be looked up in CTAPI.pm or
your local ctapi.h . Note that there's no port numbers defined for USB 
card drivers; these are likely to use port numbers greater then 32768. 
See your card terminal's CTAPI documentation for details.

B<new> returns B<undef> if the communication with the card terminal
can't be established. If you can't get it to work, please try other
programs based on CTAPI to check whether you've got a hardware problem.

=item B<cardInserted>

Checks whether there's currently a card inserted into the reader.
Returns 1 if a card is available, 0 otherwise.

=item B<getMemorySize>

Returns the memory size of the currently inserted card in bytes or 0 if 
there is no card inserted. The size is actually calculated from the second 
byte of the card's ATR string which is automatically fetched when using 
B<new> or B<reset>.

Example:
    my $memory_size = $ct->getMemorySize();

=item B<read> (address, size)

Reads I<size> bytes from the currently inserted card's memory, starting
at I<address>. Returns the number of bytes actually read. The fetched
data can be accessed using the B<getData> method.

Example how to read you card's whole memory at once:

    my $num_bytes_read = $ct->read(0, $ct->getMemorySize);

=item B<getData>

Returns the card memory retrieved by the last B<read> method call as
string. This also works for binary data.

Example:
    my $data = $ct->getData();

An empty string is returned if there is no data available.

=item B<getDataLength>

Returns the length of the most recently set or fetched data in bytes.

=item B<setData> (string)

Stores data in the object's internal data buffer; this is required
before data can be written to the card.

Example:
    $ct->setData("Hello, world!\n");

Be aware that no size checks are done here. If the length of the data 
you set exceeds the card's memory, it will be truncated when writing it
onto the card.

=item B<write> (address, size)

Writes B<size> bytes from the currently buffered data, which for example 
was set using B<setData>, onto the card, starting at B<address>.

Returns 1 if the write access was successful, B<undef> otherwise.

Notes:
If the the sum of B<address> and B<size> is greater than your card's memory,
the data will be truncated. If B<size> is greater than the length of the
currently buffered data, the trailing (B<size> - B<getDataLength()>) bytes
will be filled up with null-bytes (chr(0)).

Example:
    $ct->write(0, $ct->getMemorySize);

=item B<download> (filename, [ascii-mode])

Fetches the currently inserted card's whole memory and stores it in a file
called B<filename>. If the optionally given second parameter is a true value,
only the first I<X> bytes of the card's memory will be stored in the
file, where I<X> is the index of the first null-byte.

Returns 1 on success, B<undef> otherwise.

Example 1:
    $ct->download("dump.bin") or die "Can't dump the card.\n";

Example 2:
    $ct->setData("Hello, world!\n\000");
    $ct->write(0, $ct->getDataLength);
    $ct->download("message.txt", 1);

=item B<upload> (filename)

Stores the content of the given file in the card's memory. If the file is
larger than the card's memory, it will be truncated. If it is smaller,
the last (getMemorySize - filesize) bytes of the card's memory will be
left untouched.

Example:
    $ct->upload("card_memory_image.bin");

Returns 1 on success, B<undef> otherwise.
    
=item B<reset>

Resets the chipcard. Use this whenever you expect a different card to be
inserted in the terminal meanwhile.

Returns 1 if there is a card inserted, B<undef> otherwise.

Notes:
This internally calls B<ejectICC> and B<requestICC> and evaluates the
currently inserted card's ATR string (see B<getATR>), if present. It thus
is required that you call B<reset> whenever the user has inserted a new
chipcard in order to get correct data from methods like B<getMemorySize>.
If you want to auto-detect card changes, please see B<checkSixtyTwoOne>.

=item B<cardChanged>

Checks whether the user has exchanged the card in the reader.

Returns 1 if there's a new card in the reader meanwhile.
Returns 0 if still the same card is inserted.
Returns B<undef> if there's no card inserted now.

Note: if the user removes his card and inserts the same card again,
the result is the same as with a new card.

=item B<resetCardTerminal>

Reset the card terminal. CTBCS specs say that applications should use this
only after a communication error between the application and the card
terminal. Avoid using it; B<reset> will suffice in most cases.

Returns 1 if successful, B<undef> otherwise.

=item B<getTerminalInformation>

Returns a triple with information about the card terminal hardware:

 my ($manufacturer, $model, $revision) = $ct->getTerminalInformation();

=item B<close>

Closes the communication with the card terminal. Returns B<OK> if
successful.

=back

Methods for direct communication with the card terminal:

=over 4

=item B<sendCommand> ($destination, @command)

Sends the command consisting of the sequence of bytes given in B<command>
to the given B<destination>. The B<destination> usually is either the 
constant B<CT> for commands to the card terminal itself or B<0> for reading
and writing the card's memory.

Returns the result of the underlying call to B<CT_data>, which should
be 0 on success.

=item B<getResponse>

Returns the card terminal's response to the latest command sent by
B<sendCommand>. This usually consist of any requested data, followed
by two status bytes. Very often, the status bytes 0x90 0x00 signal
success, see B<checkNinetyZero>.

=item B<getResponseLength>

Returns the length of the card terminal's response to the latest
command in bytes.

=item B<checkNinetyZero>

Verifies that the last response from the card terminal ended with 0x90 0x00,
which signals the success of the most recent operation.

Returns 1 if the last response ended in 0x90 0x00, B<undef> otherwise.

=item B<checkSixtyTwoOne>

Checks whether the last response from the card terminal ended with 0x62 0x01.
That's the response one usually gets after a call to B<requestICC> if the
same card is still inserted.

Thus, if you want to check whether still the same card is inserted, you
could use something like this:

 $ct->requestCardStatus();
 $ct->requestICC();
 my $is_same_card = $ct->checkSixtyTwoOne();
 die "You didn't insert a new card!\n" if ($is_same_card);

Comparable functionality is implemented by B<cardChanged>.

B<checkSixtyTwoOne> returns 1 if the last response ended in 0x62 0x01, 
B<undef> otherwise.

=item B<selectFile>

Sends the "select file" command. This is automatically done by the
various read/write methods provided by Chipcard::CTAPI, so you should
only need to use it if you send read/write requests manually.

Returns 1 on success, B<undef> otherwise.

=item B<requestICC>

Sends the "request ICC" command. Fetches the card's ATR (answer to reset) 
string and calculates the card's memory based on it.

Returns 1 on success, B<undef> otherwise.

=item B<ejectICC>

Sends the "eject ICC" command. Disconnects the currently inserted card
from the card terminal. If the hardware supports it, the card is also
ejected.

Returns 1 on success, B<undef> otherwise.

=item B<requestCardStatus>

Sends the "get status" command to the terminal, requesting information
about whether currently a card is inserted and connected or not. The
method B<cardInserted> is a more convenient way of figuring that out.

Returns 1 on success, B<undef> otherwise.

=item B<requestTerminalStatus>

Sends the "get status" command to the terminal, this time requesting 
information about the card terminal itself. This command is automatically
issued on initialization and its result is available through 
B<getTerminalInformation>.

Returns 1 on success, B<undef> otherwise.

=item B<getATR>

Returns the currently inserted card's ATR string which can be used to identify
the card. Returns B<undef> if there's no card inserted or if there is a new 
card inserted but B<reset> has not been called yet.

=item B<getProtocol>

Returns the protocol used by the currently inserted card. Possible
values: "ISO", "I2C", "3W", "2W", "unknown". Returns B<undef> if there is
no card inserted or a new card is inserted but B<reset> has not been called
yet.

=item B<getStructure>

Returns the card's structure ident. Possible values: "ISO", "common", 
"proprietary", "special". Returns B<undef> if there is no card inserted or a 
new card is inserted but B<reset> has not been called yet.

=back

Methods useful for debugging:

=over 4

=item B<dumpCommunication> (prefix, data, length)

Pretty-prints a hexdump of the first I<length> bytes of I<data> on STDOUT. 
Each line of output is prefixed with I<prefix>.

If the debugging mode is turned on, all communication with the card 
terminal will be dumped.

Returns the number of lines printed.

=item B<setDumpWidth>

Sets the maximum line width for B<dumpCommunication> output. Defaults
to 78. As each byte is printed as a hexadecimal value, followed by a
blank (0x20), the should be a multiple of 3. Rounding to a multiple
of 3 is automatically done.

=item B<getIndex> (ascii-value)

Returns the first position in the currently buffered data matching the
given value. Returns -1 if there's no match at all.

Examples:
    my $pos = $ct->getIndex(ord "\n"); # Returns position of first \n
    my $first_line = substr($self->getData, 0, $ct->getIndex(ord "\n"));

=item B<setDebugLevel> (level)

Sets the debug level. Currently only used to turn debugging on/off. When
turned on (i.e., the level is a true value), all bytes sent to and received
from the card terminal via B<sendCommand> will be pretty-printed to STDOUT
using B<dumpCommunication>.

=back

Chipcard::CTAPI also provides direct access to the low-level CTAPI
functions:

=over 4

=item B<CT_init> (context, port)

Initializes the communication with the card terminal. B<context> is a
unique short integer (0-255) which must be used on all subsequent calls
to B<CT_data> and B<CT_close>. B<port> defines the physical interface
on which the card reader is attached to.

Returns the constant B<OK> on success.

=item B<CT_data> (context, dest, src, cmd_len, cmd, max_rsp_len)

Sends the B<cmd>, which is B<cmd_len> bytes long, over the communication
channel identified by B<context> from B<src> to B<dest> and expects an answer
which is at most B<max_rsp_len> bytes long.

The source usually is set to the constant B<HOST>, whereas the destination
is either the card terminal (constant B<CT>) or 0. 

A call to CT_data returns a triple:

my ($result, $response_length, $response) = CT_data(...)

B<result> is the numerical return value from the underlying CT_data() call
and should be B<OK> in case of success. 

The last two bytes of B<response> represent status information. Often, the
sequence 0x90 0x00 signals successful completion of the last requested
operation. The B<checkNinetyZero> method can be used to verify whether
the last response has ended with that sequence.

=item B<CT_close> (context)

Closes the connection identified by B<context>. Returns B<OK> on success.

=back

Please consult the CTAPI documentation for more details.

The following methods are B<EXPERIMENTAL>. Use them strictly at your own
risc. They are believed to work, if at all, only with B<3W> cards (see
B<getProtocol>).

=over 4

=item B<submitPIN> (pin)

Tries to unlock a PIN-protected card with the given PIN. WARNING: submitting
a wrong PIN or the right PIN in a wrong way multiple times will render your
card useless! As the way PIN verification is implemented in Chipcard::CTAPI
might be wrong for your hardware, B<DO NOT> try again if your first attempt
fails!

Example:
    $ct->submitPIN("000") or die "Sorry, wrong PIN!\n";

=item B<changePIN> (oldpin, newpin)

Tries to change the PIN of a PIN-protected card. Both the old and the new
PIN must be passed (in this order). Same warnings as for B<submitPIN> apply
here, too.

Example:
    $ct->changePIN("123", "456") or die "Changing PIN failed!\n";

=back

=head1 OPTIONS

The following options can be passed when creating a new Chipcard::CTAPI
object using the method B<new()>:

=over 4

=item B<interface>

Specifies the physical port your card terminal is attached to. The following
constants can be used: PORT_COM1 .. PORT_COM4, PORT_LPT1 and PORT_LPT2. For
USB devices, your driver probably has assigned numbers greater than 32768.
Please consult its documentation.

=item B<debug>

Used to turn on/off debugging. If set to a true value, each read and write
access to the card terminal for which B<sendCommand> is used will be printed
on STDOUT using B<dumpCommunication>.

=back

=head1 EXAMPLES

The Chipcard::CTAPI distribution archive comes with a couple of demo 
applications which you should have a look at. Some simple quick-start
examples follow.

Establish communication with a card terminal on COM2:
    my $ct = new Chipcard::CTAPI(interface => &Chipcard::CTAPI::PORT_COM2)
             or die "Can't initialize card terminal on COM2!\n";

Wait till the user has inserted a card with at least 2kb memory:
    my $try = 1;
    while($ct->getMemorySize < 2048) {
        if ($try == 1) {
            print "Please insert a memory card with at least 2k capacity.";
        }
        elsif ($try < 10) {
            print ".";
        }
        else {
            die "Timeout.\n";
        }

        sleep 1;
        $ct->reset;
        $try++;
    }
 
Read the first 512 byte from the card's memory:
    $ct->read(0, 512);
    if ($ct->getDataLength == 512) {
        # do something with the data
        my $data = $ct->getData;
        # ...
    }
    else {
        # error treatment
    }

Read the bytes 1500 - 2000 from the card's memory:
    $ct->read(1500, 500); # read 500 bytes, starting at address 1500

Read the whole memory:
    $ct->read(0, $ct->getMemorySize);

Read the whole memory and store it in a file named card.bin :
    $ct->download("card.bin");

Store "Hello, world" at the beginning of the card's memory:
    $ct->setData("Hello, world");
    $ct->write(0, $ct->getDataLength);

Store "Hello, world" at the card's memory address 1000:
    $ct->setData("Hello, world");
    $ct->write(1000, $ct->getDataLength);

Erase a card's memory by overwriting it with null-bytes:
    $ct->setData('');
    $ct->write(0, $ct->getMemorySize);

Erase a card's memory by overwriting each byte with a '?':
    my $mem_size = $ct->getMemorySize;
    $ct->setData('?' x $mem_size);
    $ct->write(0, $ct->getMemorySize);

Check whether there's a card inserted at the moment:
    die "No card, no fun.\n" unless ($ct->cardInserted);

Handling card changes:
    print "Please insert another card...\n";
    sleep 10; # wait for the user to do so ...
    $ct->reset; # this initializes the new card
    print "New card's capacity: " . $ct->getMemorySize . "bytes.\n";

Checking whether the card has been exchanged:
    my $change = $ct->cardChanged();
    if (!defined $change) {
        print "No card inserted now!\n";
    }
    elsif ($change == 0) {
        print "Still same card inserted!\n";
    }
    else {
        print "New card inserted!\n";
        $ct->reset(); # must do!
        print "Capacity of new card: " . $ct->getMemorySize . "\n";
    }

=head1 BUGS

Chipcard::CTAPI has currently only been tested with Towitoko card terminals.
Please report problems with other terminals and ideas for solving them.
    
=head1 TODO
    
Provide convenience methods for handling processor cards (real smartcards).
    
=head1 SEE ALSO

=over 4

=item PCSC::Lite 

A Perl module to communicate with card terminals using PC/SC-Lite. Requires
a running PCSC daemon on your system.

=item ctapi(3)

Vendor-specific CTAPI library documentation.

=back

=head1 AUTHOR

Wolfgang Hommel (wolf (at) code-wizards.com)

=head1 COPYRIGHT AND LICENSE

Copyright 2003 Wolfgang Hommel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

