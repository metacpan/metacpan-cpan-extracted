package BBS::Universal 0.023;

# Pragmas
use 5.010;
use strict;
no strict 'subs';
no warnings;
use English qw( -no_match_vars );
use Config;
use utf8;
use constant {
    TRUE        =>  1,
    FALSE       =>  0,
    YES         =>  1,
    NO          =>  0,
    BLOCKING    =>  1,
    NONBLOCKING =>  0,
    PASSWORD    => -1,
    SILENT      =>  0,
    ECHO        =>  1,
    STRING      =>  1,
    NUMERIC     =>  2,
    RADIO       =>  3,
    BOOLEAN     =>  4,
    HOST        =>  5,
    DATE        =>  6,
    FILENAME    =>  7,
    EMAIL       =>  8,

    ASCII       => 0,
    ATASCII     => 1,
    PETSCII     => 2,
    ANSI        => 3,

    XMODEM      => 0,
    YMODEM      => 1,
    ZMODEM      => 2,

    SOH         => chr(0x01),
    STX         => chr(0x02),
    EOT         => chr(0x04),
    ACK         => chr(0x06),
    NAK         => chr(0x15),
    CAN         => chr(0x18),
    C_CHAR      => 'C',

    SUPPRESS_GO_AHEAD => 3,
    LINEMODE          => 34,
    SE                => 240,
    NOP               => 214,
    DATA_MARK         => 242,
    BREAK             => 243,
    INTERRUPT_PROCESS => 244,
    ABORT_OUTPUT      => 245,
    ARE_YOU_THERE     => 246,
    ERASE_CHARACTER   => 247,
    ERASE_LINE        => 248,
    GO_AHEAD          => 249,
    SB                => 250,
    WILL              => 251,
    WONT              => 252,
    DO                => 253,
    DONT              => 254,
    IAC               => 255,

    PI           => (4 * atan2(1, 1)),
    MENU_CHOICES => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', '1', '2', '3', '4', '5', '6', '7', '8', '9', '=', '-', '+', '*', '!', '@', '#', '$', '%', '^', '&'],

    SPEEDS       => {    # This depends on the granularity of Time::HiRes
        'FULL'   => 0,
        '300'    => 1 / (300 / 8),
        '600'    => 1 / (600 / 8),
        '1200'   => 1 / (1200 / 8),
        '2400'   => 1 / (2400 / 8),
        '4800'   => 1 / (4800 / 8),
        '9600'   => 1 / (9600 / 8),
        '19200'  => 1 / (19200 / 8),
        '38400'  => 1 / (38400 / 8),
        '57600'  => 1 / (57600 / 8),
        '115200' => 1 / (115200 / 8),
    },
};
use open qw(:std :utf8);

# Modules
use Exporter 'import';
use threads (
    'yield',
    'exit' => 'threads_only',
    'stringify',
);
use Debug::Easy;
use DateTime;
use DBI;
use DBD::mysql;
use File::Basename;
use Time::HiRes qw(time sleep);
use Term::ReadKey;
use Term::ANSIScreen qw( :cursor :screen );
use Term::ANSIColor;
use Text::Format;
use Text::SimpleTable;
use List::Util qw(min max);
use IO::Socket qw(AF_INET SOCK_STREAM SHUT_WR SHUT_RDWR SHUT_RD);
use Cache::Memcached::Fast;
use Number::Format 'format_number';
use XML::RSS::LibXML;
use File::Path;
use File::Which;
use Fcntl qw(:DEFAULT :flock);
use IO::Select;
use POSIX qw(:sys_wait_h);
# use Carp::Always;

BEGIN {
    our @ISA    = qw(Exporter);
    our @EXPORT = qw(
      TRUE
      FALSE
      YES
      NO
      BLOCKING
      NONBLOCKING
      PASSWORD
      ECHO
      SILENT
      NUMERIC

      ANSI
      ASCII
      ATASCII
      PETSCII

      SUPPRESS_GO_AHEAD
      SE
      LINEMODE
      NOP
      DATA_MARK
      BREAK
      INTERRUPT_PROCESS
      ABORT_OUTPUT
      ARE_YOU_THERE
      ERASE_CHARACTER
      ERASE_LINE
      GO_AHEAD
      SB
      WILL
      WONT
      DO
      DONT
      IAC
    );
    our @EXPORT_OK = qw();
    binmode(STDOUT, ":encoding(UTF-8)");

        our $ANSI_VERSION = '0.008';
    our $ASCII_VERSION = '0.003';
    our $ATASCII_VERSION = '0.007';
    our $BBS_LIST_VERSION = '0.002';
    our $CPU_VERSION = '0.002';
    our $COMMANDS_VERSION = '0.001';
    our $DB_VERSION = '0.002';
    our $FILETRANSFER_VERSION = '0.008';
    our $MESSAGES_VERSION = '0.003';
    our $NEWS_VERSION = '0.004';
    our $PETSCII_VERSION = '0.005';
    our $SYSOP_VERSION = '0.020';
    our $TOKENS_VERSION = '0.001';
    our $USERS_VERSION = '0.004';
} ## end BEGIN

sub DESTROY { # Disconnects from the database
    my $self = shift;

    $self->{'dbh'}->disconnect();
}

sub small_new {
    my $class = shift;
    my $self  = shift;

    bless($self, $class);
    $self->{'debug'}->DEBUG(['Start Small New']);
    $self->populate_common();

    $self->{'CACHE'} = Cache::Memcached::Fast->new(
        {
            'servers' => [
                {
                    'address' => $self->{'CONF'}->{'MEMCACHED HOST'} . ':' . $self->{'CONF'}->{'MEMCACHED PORT'},
                },
            ],
            'namespace' => $self->{'CONF'}->{'MEMCACHED NAMESPACE'},
            'utf8'      => TRUE,
        }
    );
    $self->{'sysop'}      = TRUE;
    $self->{'local_mode'} = TRUE;
    $self->{'debug'}->DEBUG(['End Small New']);
    return ($self);
} ## end sub small_new

sub new {    # Always call with the socket as a parameter
    my $class = shift;

    my $params    = shift;
    my $socket    = (exists($params->{'socket'}))        ? $params->{'socket'}        : undef;
    my $cl_socket = (exists($params->{'client_socket'})) ? $params->{'client_socket'} : undef;
    my $lmode     = (exists($params->{'local_mode'}))    ? $params->{'local_mode'}    : FALSE;

    $params->{'debug'}->DEBUG(['Start New']);
    chomp(my $os   = `/usr/bin/uname -a`);
    my $self = {
        'thread_name'     => $params->{'thread_name'},
        'thread_number'   => $params->{'thread_number'},
        'local_mode'      => $lmode,
        'debuglevel'      => $params->{'debuglevel'},
        'debug'           => $params->{'debug'},
        'socket'          => $socket,
        'cl_socket'       => $cl_socket,
        'peerhost'        => (defined($cl_socket)) ? $cl_socket->peerhost() : undef,
        'peerport'        => (defined($cl_socket)) ? $cl_socket->peerport() : undef,
        'os'              => $os,
        'suffixes'        => [qw( ASCII ATASCII PETSCII ANSI )],
        'text_modes'      => {
            'ASCII'   => 0,
            'ATASCII' => 1,
            'PETSCII' => 2,
            'ANSI'    => 3,
        },
        'host'          => undef,
        'port'          => undef,
        'access_levels' => {
            'USER'         => 0,
            'VETERAN'      => 1,
            'JUNIOR SYSOP' => 2,
            'SYSOP'        => 65535,
        },
###
        'telnet_commands' => [
            'SE (Subnegotiation end)',
            'NOP (No operation)',
            'Data Mark',
            'Break',
            'Interrupt Process',
            'Abort output',
            'Are you there?',
            'Erase character',
            'Erase Line',
            'Go ahead',
            'SB (Subnegotiation begin)',
            'WILL',
            "WON'T",
            'DO',
            "DON'T",
            'IAC',
        ],
        'telnet_options'  => [
            'Binary Transmission',
            'Echo',
            'Reconnection',
            'Suppress Go Ahead',
            'Approx Message Size Negotiation',
            'Status',
            'Timing Mark',
            'Remote Controlled Trans and Echo',
            'Output Line Width',
            'Output Page Size',
            'Output Carriage-Return Disposition',
            'Output Horizontal Tab Stops',
            'Output Horizontal Tab Disposition',
            'Output Formfeed Disposition',
            'Output Vertical Tabstops',
            'Output Vertical Tab Disposition',
            'Output Linefeed Disposition',
            'Extended ASCII',
            'Logout',
            'Byte Macro',
            'Data Entry Terminal',
            'RFC 1043',
            'RFC 732',
            'SUPDUP',
            'RFC 736',
            'RFC 734',
            'SUPDUP Output',
            'Send Location',
            'Terminal Type',
            'End of Record',
            'TACACS User Identification',
            'Output Marking',
            'Terminal Location Number',
            'Telnet 3270 Regime',
            '30X.3 PAD',
            'Negotiate About Window Size',
            'Terminal Speed',
            'Remote Flow Control',
            'Linemode',
            'X Display Location',
            'Environment Option',
            'Authentication Option',
            'Encryption Option',
            'New Environment Option',
            'TN3270E',
            'XAUTH',
            'CHARSET',
            'Telnet Remote Serial Port (RSP)',
            'Com Port Control Option',
            'Telnet Suppress Local Echo',
            'Telnet Start TLS',
            'KERMIT',
            'SEND-URL',
            'FORWARD_',
        ],
###
    };

    bless($self, $class);
    $self->populate_common();
    $self->{'CACHE'} = Cache::Memcached::Fast->new(
        {
            'servers' => [
                {
                    'address' => $self->{'CONF'}->{'MEMCACHED HOST'} . ':' . $self->{'CONF'}->{'MEMCACHED PORT'},
                },
            ],
            'namespace' => $self->{'CONF'}->{'MEMCACHED NAMESPACE'},
            'utf8'      => TRUE,
        }
    );
    $self->{'debug'}->DEBUG(['End New']);
    return ($self);
} ## end sub new

sub populate_common {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Populate Common']);
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    if (exists($ENV{'EDITOR'})) {
        $self->{'EDITOR'} = $ENV{'EDITOR'};
    } else {
        my @candidates = qw(jed nano vim ed);
        for my $e (@candidates) {
            my $path = File::Which::which($e);
            if ($path) { $self->{'EDITOR'} = $path; last }
        }
    } ## end else [ if (exists($ENV{'EDITOR'...}))]
    $self->{'debug'}->DEBUGMAX(['EDITOR: ' . $self->{'EDITOR'}]);
    $self->{'CONF'} ||= $self->configuration();
    $self->configuration('EDITOR', $self->{'EDITOR'}) unless exists $self->{'CONF'}->{'EDITOR'};
    $self->{'CPU'}  ||= $self->cpu_info();
    $self->{'VERSIONS'} ||= $self->parse_versions();
    $self->{'USER'}     = {
        'text_mode'   => $self->{'CONF'}->{'DEFAULT TEXT MODE'},
        'max_columns' => $wsize,
        'max_rows'    => $hsize - 7,
    };
    $self->{'debug'}->DEBUG(['Initializing all libraries']);

    $self->db_initialize();
    $self->ascii_initialize();
    $self->atascii_initialize();
    $self->petscii_initialize();
    $self->ansi_initialize();
    $self->filetransfer_initialize();
    $self->messages_initialize();
    $self->users_initialize();
    $self->sysop_initialize();
    $self->cpu_initialize();
    $self->news_initialize();
    $self->bbs_list_initialize();
    $self->tokens_initialize();
    $self->commands_initialize();

    $self->{'debug'}->DEBUG(['Libraries initialized']);

    $self->{'SPEEDS'} ||= SPEEDS;
    $self->{'MENU CHOICES'} = MENU_CHOICES;

    $self->{'FORTUNE'} = (-e '/usr/bin/fortune' || -e '/usr/local/bin/fortune') ? TRUE : FALSE;

    $self->{'debug'}->DEBUG(['End Populate Common']);
} ## end sub populate_common

sub run {
    my $self  = shift;
    my $sysop = shift;

    $self->{'debug'}->DEBUG(['Start Run']);
    $self->{'sysop'} = $sysop;
    $self->{'ERROR'} = undef;

    unless ($self->{'sysop'} || $self->{'local_mode'}) {
        my $handle = $self->{'cl_socket'};
        print $handle chr(IAC) . chr(WONT) . chr(LINEMODE);
    }
    $| = 1;
    $self->greeting();
    if ($self->login()) {
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET login_time=NOW() WHERE id=?');
        $sth->execute($self->{'USER'}->{'id'});
        $sth->finish();
        $self->main_menu('files/main/menu');
    } ## end if ($self->login())
    $self->disconnect();
    $self->{'debug'}->DEBUG(['End Run']);
    return (defined($self->{'ERROR'}));
} ## end sub run

sub greeting {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Greeting']);

    # Load and print greetings message here
    $self->output("\n\n");
    my $text = $self->files_load_file('files/main/greeting');
    $self->output($text);
    $self->{'debug'}->DEBUG(['End Greeting']);
    return (TRUE);    # Login will also create new users
} ## end sub greeting

sub now {
    my $self = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $now = sprintf('%04d-%02d-%02d', (1900 + $year), $mday, ($mon + 1));
    return($now);
}

sub is_birthday {
    my $self     = shift;
    my $birthday = $self->{'USER'}->{'birthday'};
    if (length($birthday) > 5) {
        my ($y,$m,$d) = split(/-/,$birthday);
        $birthday     = sprintf('%02d-%02d', $m, $d);
    }
    if ($birthday eq $self->now()) {
        return(TRUE);
    }
    return(FALSE);
}

sub login {
    my $self = shift;

    my $valid = FALSE;

    $self->{'debug'}->DEBUG(['Start Login']);
    my $username;
    if ($self->{'sysop'}) {
        $self->{'debug'}->DEBUG(['  Login as SysOp']);
        $username = 'sysop';
        $self->output("\n\nAuto-login of $username successful\n\n");
        $valid = $self->users_load($username, '');
        if ($self->{'sysop'} || $self->{'local_mode'}) {    # override DB values
            my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
            $self->{'USER'}->{'columns'} = $wsize;
        }
    } else {
        $self->{'debug'}->DEBUG(['  Login as User']);
        my $tries = $self->{'CONF'}->{'LOGIN TRIES'} + 0;
        do {
            do {
                $self->output("\n" . 'Please enter your username ("NEW" if you are a new user) > ');
                $username = $self->get_line({ 'type' => STRING, 'max' => 132, 'default' => '' });
                $tries-- if ($username eq '');
                last     if ($tries <= 0 || !$self->is_connected());
            } until ($username ne '');
            $self->{'debug'}->debug(["User = $username"]);
            if ($self->is_connected()) {
                if (uc($username) eq 'NEW') {
                    $self->{'debug'}->DEBUG(['    New user']);
                    $valid = $self->create_account();
                } elsif ($username eq 'sysop' && !$self->{'local_mode'}) {
                    $self->{'debug'}->WARNING(['    Login as SysOp attempted!']);
                    $self->output("\n\nSysOp cannot connect remotely\n");
                } else {
                    $self->{'debug'}->DEBUG(['    Asking for password']);
                    $self->output("Please enter your password > ");
                    my $password = $self->get_line({ 'type' => PASSWORD, 'max' => 32, 'default' => '' });
                    $valid = $self->users_load($username, $password);
                    if ($self->{'USER'}->{'banned'}) {
                        $valid = FALSE;
                    }
                } ## end else [ if (uc($username) eq 'NEW')]
                if ($valid) {
                    $self->{'debug'}->DEBUG(['  Password valid']);
                    $self->output("\nWelcome " . $self->{'USER'}->{'fullname'} . ' (' . $self->{'USER'}->{'username'} . ")\n");
                    $self->output("You last logged out on [% LAST LOGOUT %]\n");
                    $self->output("HAPPY BIRTHDAY!!\n") if ($self->is_birthday());
                    sleep 2;
                } else {
                    $self->{'debug'}->WARNING(['  Password incorrect, try ' . $tries]);
                    $self->output("\n\nLogin incorrect\n\n");
                    $tries--;
                }
            } ## end if ($self->is_connected...)
            last unless ($self->{'CACHE'}->get('RUNNING') && $self->is_connected());
        } until ($valid || $tries <= 0);
    } ## end else [ if ($self->{'sysop'}) ]
    $self->{'debug'}->DEBUG(['End Login']);
    return ($valid);
} ## end sub login

sub username_match {
    my $self     = shift;
    my $username = shift;

    my $sth = $self->{'dbh'}->prepare('SELECT username FROM users WHERE username=?');
    $sth->execute($username);
    if ($sth->rows() || $username =~ /sysop/i || length($username) < 4 || length($username) > 32) {
        $sth->finish();
        $self->output("\nUsername $username unavailable!  Try another one.\n\n");
        return(TRUE);
    } else {
        $sth->finish();
        return(FALSE);
    }
}

sub create_account {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Create account']);
    my $heading = '[% CLS %]CREATE ACCOUNT' . "\n\nLeaving a field blank will abort\naccount creation\n\n";
    $self->output($heading);

    my $username        = '';
    my $given           = '';
    my $family          = '';
    my $nickname        = '';
    my $max_columns     = 32;
    my $max_rows        = 25;
    my $text_mode       = '';
    my $birthday        = '';
    my $location        = '';
    my $date_format     = '';
    my $accomplishments = '';
    my $email           = '';
    my $baud_rate       = '';
    my $password        = '';
    my $password2       = '';

    if ($self->is_connected()) {
        while ($self->is_connected() && length($username) < 4) {
            $self->output('Desired username:  ');
            $username = $self->get_line({ 'type' => HOST, 'max' => 32, 'default' => '' });
            return(FALSE) if (! defined($username) || $username eq '');
            last unless ($self->username_match($username));
        }
        $self->{'debug'}->DEBUG(["  New username:  $username"]);

        while($self->is_connected() && length($given) < 2) {
            $self->output("\nFirst (given) name:  ");
            $given = $self->get_line({ 'type' => STRING, 'max' => 132, 'default' => '' });
            return(FALSE) if (! defined($given) || $given eq '');
            $self->{'debug'}->DEBUG(["  New First Name:  $given"]);
        }

        while($self->is_connected() && length($family) < 3) {
            $self->output("\nLast (family) name:  ");
            $family = $self->get_line({ 'type' => STRING, 'max' => 132, 'default' => '' });
            return(FALSE) if (! defined($family) || $family eq '');
            $self->{'debug'}->DEBUG(["  New Last Name:  $family"]);
        }

        $self->output("\nWould you like to use a nickname/alias (Y/N)?  ");
        if ($self->is_connected() && $self->decision()) {
            $self->output("\nNickname:  ");
            $nickname = $self->get_line({ 'type' => STRING, 'max' => 132, 'default' => '' });
            $self->{'debug'}->DEBUG(["  New Nickname:  $nickname"]);
        }

        while($self->is_connected() && $max_columns < 32) {
            $self->output("\nScreen width (in columns):  ");
            $max_columns = $self->get_line({ 'type' => NUMERIC, 'max' => 3, 'default' => $max_columns });
            return(FALSE) if (! defined($max_columns) || $max_columns eq '');
            $self->{'debug'}->DEBUG(["  New Screen Width:  $max_columns"]);
        }

        while($self->is_connected() && $max_rows < 4) {
            $self->output("\nScreen height (in rows):  ");
            $max_rows = $self->get_line({ 'type' => NUMERIC, 'max' => 3, 'default' => $max_rows });
            return(FALSE) if (! defined($max_rows) || $max_rows eq '');
            $self->{'debug'}->DEBUG(["  New Screen Height:  $max_rows"]);
        }

        while($self->is_connected() && $text_mode < 32) {
            $self->output("\nTerminal emulations available:\n\n* ASCII\n* ANSI\n* ATASCII\n* PETSCII\n\nWhich one (type it as you see it?  ");
            $text_mode = $self->get_line({ 'type' => RADIO, 'max' => 7, 'choices' => ['ASCII', 'ANSI', 'ATASCII', 'PETSCII'], 'default' => 'ASCII' });
            return(FALSE) if (! defined($text_mode) || $text_mode eq '');
            $self->{'debug'}->DEBUG(["  New Text Mode:  $text_mode"]);
        }

        if ($self->is_connected()) {
            $self->output("\nBirthdays can be with the year or use\n0000 for the year if you wish the year\nto be anonymous, but please enter the\nmonth and day (YEAR/MM/DD):  ");
            $birthday = $self->get_line({ 'type' => DATE, 'max' => 10, 'default' => '' });
            $self->{'debug'}->DEBUG(["  New Birthday:  $birthday"]);
        }

        if ($self->is_connected()) {
            $self->output("\nPlease describe your location (you can\nbe as vague or specific as you want, or\nleave blank:  ");
            $location = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });
            $self->{'debug'}->DEBUG(["  New Location:  $location"]);
        }

        if ($self->is_connected()) {
            $self->output("\nDate formats:\n\n* YEAR/MONTH/DAY\n* DAY/MONTH/YEAR\n* MONTH/DAY/YEAR\n\nWhich date format do you prefer?  ");
            $date_format = $self->get_line({ 'type' => RADIO, 'max' => 15, 'choices' => ['YEAR/MONTH/DAY', 'MONTH/DAY/YEAR', 'DAY/MONTH/YEAR'], 'default' => 'YEAR/MONTH/DAY' });
            return(FALSE) if (! defined($date_format) || $date_format eq '');
            $self->{'debug'}->DEBUG(["  New Date Format:  $date_format"]);
        }

        if ($self->is_connected()) {
            $self->output("\nYou can have a simulated baud rate for\nnostalgia.  Rates available:\n\n* 300\n* 600\n* 1200\n* 2400\n* 4800\n* 9600\n* 19200\n* FULL\n\nWhich one (FULL=full speed)?  ");
            $baud_rate = $self->get_line({ 'type' => RADIO, 'max' => 5, 'choices' => ['300', '600', '1200', '2400', '4800', '9600', '19200', '38400', '57600', '115200', 'FULL'], 'default' => 'FULL' });
            return(FALSE) if (! defined($baud_rate) || $baud_rate eq '');
            $self->{'debug'}->DEBUG(["  New Baud Rate:  $baud_rate"]);
        }

        my $tries = 3;
        do {
            $self->output("\nPlease enter your password:  ");
            $password = $self->get_line({ 'type' => PASSWORD, 'max' => 64, 'default' => '' });
            $self->{'debug'}->DEBUG(['  New Password']);
            return(FALSE) unless ($self->is_connected() && defined($password));

            $self->output("\nEnter it again:  ");
            $password2 = $self->get_line({ 'type' => PASSWORD, 'max' => 64, 'default' => '' });
            $self->{'debug'}->DEBUG(['  New Password2']);
            return(FALSE) unless ($self->is_connected() && defined($password2));

            $self->output("\nPasswords do not match!  Try again\n");
            $tries--;
        } until (($password eq $password2) || $tries <= 0);
        if ($self->is_connected() && $password eq $password2) {
            my $tree = {
                'username'    => $username,
                'given'       => $given,
                'family'      => $family,
                'nickname'    => $nickname . '',
                'max_columns' => $max_columns,
                'max_rows'    => $max_rows,
                'text_mode'   => $text_mode,
                'birthday'    => $birthday,
                'location'    => $location,
                'date_format' => $date_format,
                'baud_rate'   => $baud_rate,
                'password'    => $password,
            };
            $self->{'debug'}->DEBUGMAX([$tree]);
            if ($self->users_add($tree)) {
                return ($self->users_load($username, $password));
            }
        } ## end if ($self->is_connected...)
    } ## end if ($self->is_connected...)
    $self->{'debug'}->DEBUG(['End Create Account']);
    return (FALSE);
} ## end sub create_account

sub is_connected {
    my $self = shift;

    if ($self->{'sysop'} || $self->{'local_mode'}) {
        return (TRUE);
    } elsif ($self->{'CACHE'}->get('RUNNING') && defined($self->{'cl_socket'})) {
        $self->{'CACHE'}->set(sprintf('SERVER_%02d', $self->{'thread_number'}), 'CONNECTED');
        $self->{'CACHE'}->set('UPDATE',                                         TRUE);
        return (TRUE);
    } else {
        $self->{'debug'}->WARNING(['User disconnected']);
        $self->{'CACHE'}->set(sprintf('SERVER_%02d', $self->{'thread_number'}), 'IDLE');
        $self->{'CACHE'}->set('UPDATE',                                         TRUE);
        return (FALSE);
    } ## end else [ if ($self->{'sysop'} ||...)]
} ## end sub is_connected

sub decision {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Decision']);
    my $response = uc($self->get_key(SILENT, BLOCKING));
    if ($response eq 'Y') {
        $self->output("YES\n");
        $self->{'debug'}->DEBUG(['  Decision YES']);
        return (TRUE);
    }
    $self->{'debug'}->DEBUG(['  Decision NO']);
    $self->output("NO\n");
    $self->{'debug'}->DEBUG(['End Decision']);
    return (FALSE);
} ## end sub decision

sub prompt {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start Prompt', "  Prompt > $text"]);
    my $response = "\n";
    if ($self->{'USER'}->{'text_mode'} eq 'ATASCII') {
        $response .= '(' . colored(['bright_yellow'], $self->{'USER'}->{'username'}) . ') ' . $text . chr(31) . ' ';
    } elsif ($self->{'USER'}->{'text_mode'} eq 'PETSCII') {
        $response .= '(' . $self->{'USER'}->{'username'} . ') ' . "$text > ";
    } elsif ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
        $response .= '(' . colored(['bright_yellow'], $self->{'USER'}->{'username'}) . ') ' . $text . ' [% BLACK RIGHT-POINTING TRIANGLE %] ';
    } else {
        $response .= '(' . $self->{'USER'}->{'username'} . ') ' . "$text > ";
    }
    $self->output($response);
    $self->{'debug'}->DEBUG(['End Prompt']);
    return (TRUE);
} ## end sub prompt

sub menu_choice {
    my $self   = shift;
    my $choice = shift;
    my $color  = shift;
    my $desc   = shift;

    $self->{'debug'}->DEBUG(['Start Menu Choice']);
    if ($self->{'USER'}->{'text_mode'} eq 'ATASCII') {
        $self->output(" $choice " . chr(31) . " $desc");
    } elsif ($self->{'USER'}->{'text_mode'} eq 'PETSCII') {
        $self->output(" $choice > $desc");
    } elsif ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
        $self->output(charnames::string_vianame('BOX DRAWINGS LIGHT VERTICAL') . '[% ' . $color . ' %]' . $choice . '[% RESET %]' . charnames::string_vianame('BOX DRAWINGS LIGHT VERTICAL') . '[% ' . $color . ' %]' . charnames::string_vianame('BLACK RIGHT-POINTING TRIANGLE') . '[% RESET %]' . " $desc");
    } else {
        $self->output(" $choice > $desc");
    }
    $self->{'debug'}->DEBUG(['End Menu Choice']);
} ## end sub menu_choice

sub show_choices {
    my $self    = shift;
    my $mapping = shift;

    $self->{'debug'}->DEBUG(['Start Show Choices']);
    my @list = grep(!/TEXT/, (sort(keys %{$mapping})));
    my $twin = FALSE;
    $twin = TRUE if (scalar(@list) > 1 && $self->{'USER'}->{'max_columns'} > 40);
    my $max = 0;
    foreach my $name (@list) {
        $max = max(length($mapping->{$name}->{'text'}), $max);
    }
    if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
        if ($twin) {
            $max += 3;
            $self->output(sprintf("%s%s%s%-${max}s %s%s%s\t", '[% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC DOWN AND LEFT %]', ' ' x $max, '[% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC DOWN AND LEFT %]') . "\n");
        } else {
            $self->output('[% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT %][% BOX DRAWINGS LIGHT HORIZONTAL %][% BOX DRAWINGS LIGHT ARC DOWN AND LEFT %]' . "\n");
        }
    } ## end if ($self->{'USER'}->{...})
    while (scalar(@list)) {
        my $kmenu = shift(@list);
        if ($self->{'access_level'}->{ $mapping->{$kmenu}->{'access_level'} } <= $self->{'access_level'}->{ $self->{'USER'}->{'access_level'} }) {
            if ($twin) {
                $self->menu_choice($kmenu, $mapping->{$kmenu}->{'color'}, $mapping->{$kmenu}->{'text'} . ' ' x (($max - 1) - length($mapping->{$kmenu}->{'text'})));
                if (scalar(@list)) {
                    $kmenu = shift(@list);
                    $self->menu_choice($kmenu, $mapping->{$kmenu}->{'color'}, $mapping->{$kmenu}->{'text'});
                } elsif ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
                    $self->output(sprintf('%s%s%s', '[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC UP AND LEFT %]'));
                    $twin = FALSE;
                }
            } else {
                $self->menu_choice($kmenu, $mapping->{$kmenu}->{'color'}, $mapping->{$kmenu}->{'text'});
            }
            $self->output("\n");
        } ## end if ($self->{'access_level'...})
    } ## end while (scalar(@list))
    if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
        if ($twin) {
            $self->output(sprintf("%s%s%s%-${max}s %s%s%s", '[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC UP AND LEFT %]', ' ' x $max, '[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC UP AND LEFT %]'));
        } else {
            $self->output('[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %][% BOX DRAWINGS LIGHT HORIZONTAL %][% BOX DRAWINGS LIGHT ARC UP AND LEFT %]');
        }
    } ## end if ($self->{'USER'}->{...})
    $self->{'debug'}->DEBUG(['End Show Choices']);
} ## end sub show_choices

sub header {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Header']);
    my $width = $self->{'USER'}->{'max_columns'};
    my $name  = ' ' . $self->{'CONF'}->{'BBS NAME'} . ' ';

    my $text = '#' x int(($width - length($name)) / 2);
    $text .= $name;
    $text .= '#' x ($width - length($text));
    if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
        my $char = '[% BOX DRAWINGS HEAVY HORIZONTAL %]';
        $text =~ s/\#/$char/g;
    }
    $self->{'debug'}->DEBUG(['End Header']);
    return ($self->detokenize_text('[% CLS %]' . $text));
} ## end sub header

sub load_menu {
    my $self = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start Load Menu', "  Load Menu $file"]);
    my $orig    = $self->files_load_file($file);
    my @Text    = split(/\n/, $orig);
    my $mapping = { 'TEXT' => '' };
    my $mode    = TRUE;
    my $text    = '';
    $self->{'debug'}->DEBUG(['  Parse Menu']);
    foreach my $line (@Text) {
        if ($mode) {
            next if ($line =~ /^\#/);
            if ($line !~ /^---/) {
                my ($k, $cmd, $color, $access, $t) = split(/\|/, $line);
                $k     = uc($k);
                $cmd   = uc($cmd);
                $color = uc($color);
                if (exists($self->{'COMMANDS'}->{$cmd})) {
                    $mapping->{$k} = {
                        'command'      => $cmd,
                        'color'        => $color,
                        'access_level' => $access,
                        'text'         => $t,
                    };
                } else {
                    $self->{'debug'}->ERROR(["Command Missing!  $cmd"]);
                }
            } else {
                $mode = FALSE;
            }
        } else {
            $mapping->{'TEXT'} .= $self->detokenize_text($line) . "\n";
        }
    } ## end foreach my $line (@Text)
    $mapping->{'TEXT'} = $self->header() . "\n" . $mapping->{'TEXT'};
    $self->{'debug'}->DEBUG(['End Load Menu']);
    return ($mapping);
} ## end sub load_menu

sub main_menu {
    my $self = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start Main Menu']);
    my $connected = TRUE;
    my $command   = '';
    my $mapping   = $self->load_menu($file);
    while ($connected && $self->is_connected()) {
        $self->output($mapping->{'TEXT'});
        $self->show_choices($mapping);
        $self->prompt('Choose');
        my $key;
        do {
            $key = uc($self->get_key(SILENT, FALSE));
        } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
        $self->output($mapping->{$key}->{'command'} . "\n");
        if ($key eq chr(3)) {
            $command = 'DISCONNECT';
        } else {
            $command = $mapping->{$key}->{'command'};
        }
        $mapping = $self->{'COMMANDS'}->{$command}->($self);
        if (ref($mapping) ne 'HASH' || !$self->is_connected()) {
            $connected = FALSE;
        }
    } ## end while ($connected && $self...)
    $self->{'debug'}->DEBUG(['End Main Menu']);
} ## end sub main_menu

sub disconnect {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Disconnect']);

    # Load and print disconnect message here
    my $text = $self->files_load_file('files/main/disconnect');
    $self->output($text);
    my $sth = $self->{'dbh'}->prepare('UPDATE users SET logout_time=NOW() WHERE id=?');
    $sth->execute($self->{'USER'}->{'id'});
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Disconnect']);
    return (TRUE);
} ## end sub disconnect

sub parse_telnet_escape {
    my $self    = shift;
    my $command = shift;
    my $option  = shift;
    my $handle  = $self->{'cl_socket'};

    $self->{'debug'}->DEBUG(['Start Parse Telnet Escape']);
    if ($command == WILL) {
        if ($option == ECHO) {    # WON'T ECHO
            print $handle chr(IAC) . chr(WONT) . chr(ECHO);
        } elsif ($option == LINEMODE) {
            print $handle chr(IAC) . chr(WONT) . chr(LINEMODE);
        }
    } elsif ($command == DO) {
        if ($option == ECHO) {    # DON'T ECHO
            print $handle chr(IAC) . chr(DONT) . chr(ECHO);
        } elsif ($option == LINEMODE) {
            print $handle chr(IAC) . chr(DONT) . chr(LINEMODE);
        }
    } else {
        $self->{'debug'}->DEBUG(['Recreived IAC Request - ' . $self->{'telnet_commands'}->[$command - 240] . ' : ' . $self->{'telnet_options'}->[$option]]);
    }
    $self->{'debug'}->DEBUG(['End Parse Telnet Escape']);
    return (TRUE);
} ## end sub parse_telnet_escape

sub flush_input {
    my $self = shift;

    my $key;
    unless ($self->{'sysop'} || $self->{'local_mode'}) {
        my $handle = $self->{'cl_socket'};
        ReadMode 'noecho', $handle;
        do {
            $key = ReadKey(-1, $handle);
        } until (!defined($key) || $key eq '');
        ReadMode 'restore', $handle;
    } else {
        ReadMode 'ultra-raw';
        do {
            $key = ReadKey(-1);
        } until (!defined($key) || $key eq '');
        ReadMode 'restore';
    } ## end else
    return (TRUE);
} ## end sub flush_input

sub get_key {
    my $self     = shift;
    my $echo     = shift;
    my $blocking = shift;

    my $key     = undef;
    my $mode    = $self->{'USER'}->{'text_mode'};
    my $timeout = $self->{'USER'}->{'timeout'} * 60;
    local $/ = "\x{00}";
    if ($self->{'sysop'} || $self->{'local_mode'}) {
        ReadMode 'ultra-raw';
        $key = ($blocking) ? ReadKey($timeout) : ReadKey(-1);
        ReadMode 'restore';
        threads->yield;
    } elsif ($self->is_connected()) {
        my $handle = $self->{'cl_socket'};
        ReadMode 'ultra-raw', $self->{'cl_socket'};
        my $escape;
        do {
            $escape = FALSE;
            $key    = ($blocking) ? ReadKey($timeout, $handle) : ReadKey(-1, $handle);
            if ($key eq chr(255)) {    # IAC sequence
                my $command = ReadKey($timeout, $handle);
                my $option  = ReadKey($timeout, $handle);
                $self->parse_telnet_escape(ord($command), ord($option));
                $escape = TRUE;
            } ## end if ($key eq chr(255))
        } until (!$escape || $self->is_connected());
        ReadMode 'restore', $self->{'cl_socket'};
        threads->yield;
    } ## end elsif ($self->is_connected...)
    return ($key) if ($key eq chr(13));
    if ($key eq chr(127) or $key eq chr(7)) {
        if ($mode eq 'ANSI') {
            $key = $self->{'ansi_meta'}->{'cursor'}->{'BACKSPACE'}->{'out'};
        } elsif ($mode eq 'ATASCII') {
            $key = $self->{'atascii_meta'}->{'BACKSPACE'}->{'out'};
        } elsif ($mode eq 'PETSCII') {
            $key = $self->{'petscii_meta'}->{'BACKSPACE'}->{'out'};
        } else {
            $key = $self->{'ascii_meta'}->{'BACKSPACE'}->{'out'};
        }
        $self->output("$key $key") if ($echo);
    } ## end if ($key eq chr(127) or...)
    threads->yield;
    return ($key);
} ## end sub get_key

sub get_line {
    my $self = shift;
    my $type = shift;
    my $line = shift;

    my $echo    = $type->{'type'};
    my $limit   = $type->{'max'};
    my $choices = $type->{'choices'} if (exists($type->{'choices'}));
    if (exists($type->{'default'})) {
        $line = $type->{'default'};
    }

    $self->{'debug'}->DEBUG(['Start Get Line']);
    $self->flush_input();

    my $key;

    $self->output($line) if ($line ne '');
    my $mode = $self->{'USER'}->{'text_mode'};
    my $backspace;
    if ($mode eq 'ANSI') {
        $backspace = $self->{'ansi_meta'}->{'cursor'}->{'BACKSPACE'}->{'out'};
    } elsif ($mode eq 'ATASCII') {
        $backspace = $self->{'atascii_meta'}->{'BACKSPACE'}->{'out'};
    } elsif ($mode eq 'PETSCII') {
        $backspace = $self->{'petscii_meta'}->{'BACKSPACE'}->{'out'};
    } else {
        $backspace = $self->{'ascii_meta'}->{'BACKSPACE'}->{'out'};
    }

    if ($echo == PASSWORD) {
        $self->{'debug'}->DEBUG(['  Mode:  PASSWORD']);
        while (($self->is_connected() || $self->{'local_mode'}) && $key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $backspace) {
                        my $len = length($line);
                        if ($len > 0) {
                            $self->output("$key $key");
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && ord($key) > 31 && ord($key) < 127) {
                        $self->output('*');
                        $line .= $key;
                    } else {
                        $self->output('[% RING BELL %]');
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $backspace)) {
                    $key = $backspace;
                    $self->output("$key $key");
                    chop($line);
                } else {
                    $self->output('[% RING BELL %]');
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while (($self->is_connected...))
    } elsif ($echo == RADIO) {
        $self->{'debug'}->DEBUG(['  Mode:  RADIO']);

        my $mapping;
        my @menu_choices = @{$self->{'MENU CHOICES'}};

        foreach my $choice (@{$choices}) {
            $mapping->{ shift(@menu_choices) } = {
                'command'      => $choice,
                'color'        => 'WHITE',
                'access_level' => 'USER',
                'text'         => $choice,
            }
        }
        $self->output("\n\n");
        $self->show_choices($mapping);
        $self->prompt('Choose');
        my $key;
        do {
            $key = uc($self->get_key(SILENT, BLOCKING));
        } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
        if ($key eq chr(3)) {
            $line = '';
        } else {
            $line = $mapping->{$key}->{'command'};
        }
    } elsif ($echo == NUMERIC) {
        $self->{'debug'}->DEBUG(['  Mode:  NUMERIC']);
        while (($self->is_connected() || $self->{'local_mode'}) && $key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $backspace || $key eq chr(127)) {
                        my $len = length($line);
                        if ($len > 0) {
                            $self->output("$key $key");
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && $key =~ /[0-9]/) {
                        $self->output($key);
                        $line .= $key;
                    } else {
                        $self->output('[% RING BELL %]');
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $backspace || $key eq chr(127))) {
                    $key = $backspace;
                    $self->output("$key $key");
                    chop($line);
                } else {
                    $self->output('[% RING BELL %]');
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while (($self->is_connected...))
    } elsif ($echo == DATE) {
        $self->{'debug'}->DEBUG(['  Mode:  DATE']);
        while (($self->is_connected() || $self->{'local_mode'}) && $key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $backspace || $key eq chr(127)) {
                        my $len = length($line);
                        if ($len > 0) {
                            $self->output("$key $key");
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && $key =~ /[0-9]|\//) {
                        $self->output($key);
                        $line .= $key;
                    } else {
                        $self->output('[% RING BELL %]');
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $backspace || $key eq chr(127))) {
                    $key = $backspace;
                    $self->output("$key $key");
                    chop($line);
                } else {
                    $self->output('[% RING BELL %]');
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while (($self->is_connected...))
    } elsif ($echo == HOST) {
        $self->{'debug'}->DEBUG(['  Mode:  HOST']);
        while (($self->is_connected() || $self->{'local_mode'}) && $key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $backspace || $key eq chr(127)) {
                        my $len = length($line);
                        if ($len > 0) {
                            $self->output("$key $key");
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && $key =~ /[a-z]|[0-9]|\./) {
                        $self->output(lc($key));
                        $line .= lc($key);
                    } else {
                        $self->output('[% RING BELL %]');
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $backspace || $key eq chr(127))) {
                    $key = $backspace;
                    $self->output("$key $key");
                    chop($line);
                } else {
                    $self->output('[% RING BELL %]');
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while (($self->is_connected...))
    } elsif ($echo == FILENAME) {
        $self->{'debug'}->DEBUG(['  Mode:  FILENAME']);

        # /^[a-zA-Z0-9](?:[a-zA-Z0-9 ._-]*[a-zA-Z0-9])?\.[a-zA-Z0-9_-]+$/
        while (($self->is_connected() || $self->{'local_mode'}) && $key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $backspace || $key eq chr(127)) {
                        my $len = length($line);
                        if ($len > 0) {
                            $self->output("$key $key");
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && $key =~ /[a-zA-Z0-9]|\.|_|-/) {
                        if ($line eq '' && $key !~ /^[a-zA-Z0-9]/) {
                            $self->output('[% RING BELL %]');
                        } else {
                            $self->output($key);
                            $line .= $key;
                        }
                    } else {
                        $self->output('[% RING BELL %]');
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $backspace || $key eq chr(127))) {
                    $key = $backspace;
                    $self->output("$key $key");
                    chop($line);
                } else {
                    $self->output('[% RING BELL %]');
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while (($self->is_connected...))
    } elsif ($echo == EMAIL) {
        $self->{'debug'}->DEBUG(['  Mode:  EMAIL']);

        while (($self->is_connected() || $self->{'local_mode'}) && $key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $backspace || $key eq chr(127)) {
                        my $len = length($line);
                        if ($len > 0) {
                            $self->output("$key $key");
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && $key =~ /[a-zA-Z0-9]|\.|-|\+|\@/) {
                        if ($line eq '' && $key !~ /^[a-zA-Z0-9]/) {
                            $self->output('[% RING BELL %]');
                        } else {
                            $self->output($key);
                            $line .= $key;
                        }
                    } else {
                        $self->output('[% RING BELL %]');
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $backspace || $key eq chr(127))) {
                    $key = $backspace;
                    $self->output("$key $key");
                    chop($line);
                } else {
                    $self->output('[% RING BELL %]');
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while (($self->is_connected...))
    } else {
        $self->{'debug'}->DEBUG(['  Mode:  NORMAL']);
        while (($self->is_connected() || $self->{'local_mode'}) && $key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $backspace) {
                        my $len = length($line);
                        if ($len > 0) {
                            $self->output("$key $key");
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && ord($key) > 31 && ord($key) < 127) {
                        $self->output($key);
                        $line .= $key;
                    } else {
                        $self->output('[% RING BELL %]');
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $backspace)) {
                    $key = $backspace;
                    $self->output("$key $key");
                    chop($line);
                } else {
                    $self->output('[% RING BELL %]');
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while (($self->is_connected...))
    } ## end else [ if ($type == PASSWORD)]
    threads->yield();
    $line = '' if ($key eq chr(3));
    $self->output("\n");
    $self->{'debug'}->DEBUG(['End Get Line']);
    return ($line);
} ## end sub get_line

sub detokenize_text {    # Detokenize text markup
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start Detokenize Text']);
    if (defined($text) && length($text) > 1) {
        foreach my $key (keys %{ $self->{'TOKENS'} }) {
            if ($key eq 'VERSIONS' && $text =~ /\[\%\s+$key\s+\%\]/i) {
                my $versions = '';
                foreach my $names (keys %{ $self->{'VERSIONS'} }) {
                    $versions .= sprintf('%-28s %.03f', $names, $self->{'VERSIONS'}->{$names}) . "\n";
                }
                $text =~ s/\[\%\s+$key\s+\%\]/$versions/g;
            } elsif (ref($self->{'TOKENS'}->{$key}) eq 'CODE' && $text =~ /\[\%\s+$key\s+\%\]/) {
                my $ch = $self->{'TOKENS'}->{$key}->($self);    # Code call
                $text =~ s/\[\%\s+$key\s+\%\]/$ch/g;
            } else {
                $text =~ s/\[\%\s+$key\s+\%\]/$self->{'TOKENS'}->{$key}/g;
            }
        } ## end foreach my $key (keys %{ $self...})
    } ## end if (defined($text) && ...)
    $self->{'debug'}->DEBUG(['End Detokenize Text']);
    return ($text);
} ## end sub detokenize_text

sub output {
    my $self = shift;
    $| = 1;
    $self->{'debug'}->DEBUG(['Start Output']);
    my $text = $self->detokenize_text(shift);

    my $response = TRUE;
    if (defined($text) && $text ne '') {
        while ($text =~ /\[\%\s+WRAP\s+\%\](.*?)\[\%\s+ENDWRAP\s+\%\]/si) {
            my $wrapped = $1;
            my $format  = Text::Format->new(
                'columns'     => $self->{'USER'}->{'max_columns'} - 1,
                'tabstop'     => 4,
                'extraSpace'  => TRUE,
                'firstIndent' => 0,
            );
            $wrapped = $format->format($wrapped);
            chomp($wrapped);
            $text =~ s/\[\%\s+WRAP\s+\%\].*?\[\%\s+ENDWRAP\s+\%\]/$wrapped/s;
        } ## end while ($text =~ /\[\%\s+WRAP\s+\%\](.*?)\[\%\s+ENDWRAP\s+\%\]/si)
        while ($text =~ /\[\%\s+JUSTIFIED\s+\%\](.*?)\[\%\s+ENDJUSTIFIED\s+\%\]/si) {
            my $wrapped = $1;
            my $format  = Text::Format->new(
                'columns'     => $self->{'USER'}->{'max_columns'} - 1,
                'tabstop'     => 4,
                'extraSpace'  => TRUE,
                'firstIndent' => 0,
                'justify'     => TRUE,
            );
            $wrapped = $format->format($wrapped);
            chomp($wrapped);
            $text =~ s/\[\%\s+JUSTIFIED\s+\%\].*?\[\%\s+ENDJUSTIFIED\s+\%\]/$wrapped/s;
        } ## end while ($text =~ /\[\%\s+JUSTIFIED\s+\%\](.*?)\[\%\s+ENDJUSTIFIED\s+\%\]/si)
        my $mode = $self->{'USER'}->{'text_mode'};
        if ($mode eq 'ATASCII') {
            $self->atascii_output($text);
        } elsif ($mode eq 'PETSCII') {
            $self->petscii_output($text);
        } elsif ($mode eq 'ANSI') {
            $self->ansi_output($text);
        } else {    # ASCII (always the default)
            $self->ascii_output($text);
        }
    } else {
        $response = FALSE;
    }
    $self->{'debug'}->DEBUG(['End Output']);
    return ($response);
} ## end sub output

sub send_char {
    my $self = shift;
    my $char = shift;

    # This sends one character at a time to the socket to simulate a retro BBS
    if ($self->{'local_mode'} || !defined($self->{'cl_socket'})) {
        print STDOUT $char;
    } else {
        my $handle = $self->{'cl_socket'};
        print $handle $char;
    }

    # Send at the chosen baud rate by delaying the output by a fraction of a second
    # Only delay if the baud_rate is not FULL
    sleep $self->{'SPEEDS'}->{ $self->{'USER'}->{'baud_rate'} } if ($self->{'USER'}->{'baud_rate'} ne 'FULL');
    return (TRUE);
} ## end sub send_char

sub scroll {
    my $self = shift;
    my $nl   = shift;

    $self->{'debug'}->DEBUG(['Start Scroll']);
    my $string;
    $string = "$nl" . 'Scroll?  ';
    $self->output($string);
    if ($self->get_key(ECHO, BLOCKIMG) =~ /N|Q/i) {
        $self->output("\n");
        return (FALSE);
    }
    $self->output('[% BACKSPACE %] [% BACKSPACE %]' x 10);
    $self->{'debug'}->DEBUG(['End Scroll']);
    return (TRUE);
} ## end sub scroll

sub static_configuration {
    my $self = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start Static Configuration']);
    $self->{'CONF'}->{'STATIC'}->{'AUTHOR NAME'}     = 'Richard Kelsch';
    $self->{'CONF'}->{'STATIC'}->{'AUTHOR EMAIL'}    = 'Richard Kelsch <rich@rk-internet.com>';
    $self->{'CONF'}->{'STATIC'}->{'AUTHOR LOCATION'} = 'Central Utah - USA';
    if (-e $file) {
        open(my $CFG, '<', $file) or die "$file missing!";
        chomp(my @lines = <$CFG>);
        close($CFG);
        foreach my $line (@lines) {
            next if ($line eq '' || $line =~ /^\#/);
            my ($name, $val) = split(/\s+=\s+/, $line);
            $self->{'CONF'}->{'STATIC'}->{$name} = $val;
        }
    } ## end if (-e $file)
    $self->{'debug'}->DEBUG(['End Static Configuration']);
} ## end sub static_configuration

sub choose_file_category {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Choose File Category']);
    my $table;
    my $choices = $self->{'MENU CHOICES'};
    my $hchoice = {};
    my @categories;
    if ($self->{'USER'}->{'max_columns'} <= 40) {
        $table = Text::SimpleTable->new(6, 20, 15);
    } else {
        $table = Text::SimpleTable->new(6, 30, 43);
    }
    $table->row('CHOICE', 'TITLE', 'DESCRIPTION');
    $table->hr();
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM file_categories ORDER BY description');
    $sth->execute();
    my $index = 0;
    if ($sth->rows > 0) {
        while (my $row = $sth->fetchrow_hashref()) {
            $table->row($choices->[$index], $row->{'title'}, $row->{'description'});
            $hchoice->{ $choices->[$index] } = $row->{'id'};
            push(@categories, $row->{'title'});
            $index++;
        }
        $sth->finish();
        if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
            $self->output($table->boxes('CYAN')->draw());
        } else {
            $self->output($table->draw());
        }
        $self->prompt('Choose Category (Z = Nevermind)');
        my $response;
        do {
            $response = uc($self->get_key(SILENT, BLOCKING));
        } until (exists($hchoice->{$response}) || $response =~ /^\<|Z$/ || !$self->is_connected());
        if ($response !~ /\<|Z/) {
            $self->{'USER'}->{'file_category'} = $hchoice->{$response};
            $self->output($categories[$hchoice->{$response} - 1] . "\n");
            $sth = $self->{'dbh'}->prepare('UPDATE users SET file_category=? WHERE id=?');
            $sth->execute($hchoice->{$response}, $self->{'USER'}->{'id'});
            $sth->finish();
        } else {
            $self->output("Nevermind\n");
        }
    } ## end if ($sth->rows > 0)
    $self->{'debug'}->DEBUG(['End Choose File Category']);
} ## end sub choose_file_category

sub configuration {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Configuration']);
    unless (exists($self->{'CONF'}->{'STATIC'})) {
        my @static_file = ('./conf/bbs.rc', '~/.bbs_universal/bbs.rc', '/etc/bbs.rc');
        my $found       = FALSE;
        foreach my $file (@static_file) {
            if (-e $file) {
                $found = TRUE;
                $self->static_configuration($file);
                last;
            } else {
                $self->{'debug'}->WARNING(["$file not found, trying the next file in the list"]);
            }
        } ## end foreach my $file (@static_file)
        unless ($found) {
            $self->{'debug'}->ERROR(['BBS Static Configuration file not found', join("\n", @static_file)]);
            exit(1);
        }
        $self->db_connect();
    } ## end unless (exists($self->{'CONF'...}))
    #######################################################
    my $count = scalar(@_);
    if ($count == 1) {    # Get single value
        my $name = shift;

        $self->{'debug'}->DEBUG(['  Get Single Value']);
        my $sth = $self->{'dbh'}->prepare('SELECT config_value FROM config WHERE config_name=?');
        $sth->execute($name);
        my ($fval) = $sth->fetchrow_array();
        $sth->finish();
        if ($name eq 'BBS ROOT') {
            $fval =~ s/\~/$ENV{HOME}/;
        } elsif ($fval =~ /^(PORT|DEFAULT BAUD RATE|THREAD MULTIPLIER|DEFAULT TIMEOUT|LOGIN TRIES|MEMCACHED PORT)$/) {
            $fval = 0 + $fval;
        } else {
            if ($fval =~ /^(TRUE|ON|YES)$/) {
                $fval = TRUE;
            } elsif ($fval =~ /^(FALSE|OFF|NO)$/) {
                $fval = FALSE;
            }
        }
        return ($fval);
    } elsif ($count == 2) {    # Set a single value
        my $name = shift;
        my $fval = shift;
        if ($name eq 'BBS ROOT') {
            $fval =~ s/\~/$ENV{HOME}/;
        }
        $self->{'debug'}->DEBUG(['  Set a Single Value']);
        my $sth = $self->{'dbh'}->prepare('REPLACE INTO config (config_value, config_name) VALUES (?,?)');
        $sth->execute("$fval", $name);
        $sth->finish();
        $self->{'CONF'}->{$name} = $fval;
        return (TRUE);
    } elsif ($count == 0) {    # Get entire configuration forces a reload into CONF
        $self->{'debug'}->DEBUG(['  Get Entire Configuration']);
        $self->db_connect() unless (exists($self->{'dbh'}));
        my $sth     = $self->{'dbh'}->prepare('SELECT config_name,config_value FROM config');
        my $results = {};
        $sth->execute();
        while (my @row = $sth->fetchrow_array()) {
            my $name = $row[0];
            my $fval = $row[1];
            if ($name eq 'BBS ROOT') {
                $fval =~ s/\~/$ENV{HOME}/;
            } elsif ($fval =~ /^(PORT|DEFAULT BAUD RATE|THREAD MULTIPLIER|DEFAULT TIMEOUT|LOGIN TRIES|MEMCACHED PORT)$/) {
                $fval = 0 + $fval;
            } else {
                if ($fval =~ /^(TRUE|ON|YES)$/) {
                    $fval = TRUE;
                } elsif ($fval =~ /^(FALSE|OFF|NO)$/) {
                    $fval = FALSE;
                }
            }
            $results->{$name} = $fval;
            $self->{'CONF'}->{$name} = $fval;
        } ## end while (my @row = $sth->fetchrow_array...)
        $sth->finish();
        return ($self->{'CONF'});
    } ## end elsif ($count == 0)
    $self->{'debug'}->DEBUG(['End Configuration']);
} ## end sub configuration

sub parse_versions {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Parse Versions']);
###
    my $versions = {
        'Perl'                         => $OLD_PERL_VERSION,
        'BBS Executable'               => $main::VERSION,
        'BBS::Universal'               => $BBS::Universal::VERSION,
        'BBS::Universal::ASCII'        => $BBS::Universal::ASCII_VERSION,
        'BBS::Universal::ATASCII'      => $BBS::Universal::ATASCII_VERSION,
        'BBS::Universal::PETSCII'      => $BBS::Universal::PETSCII_VERSION,
        'BBS::Universal::ANSI'         => $BBS::Universal::ANSI_VERSION,
        'BBS::Universal::BBS_List'     => $BBS::Universal::BBS_LIST_VERSION,
        'BBS::Universal::CPU'          => $BBS::Universal::CPU_VERSION,
        'BBS::Universal::Messages'     => $BBS::Universal::MESSAGES_VERSION,
        'BBS::Universal::News'         => $BBS::Universal::NEWS_VERSION,
        'BBS::Universal::SysOp'        => $BBS::Universal::SYSOP_VERSION,
        'BBS::Universal::FileTransfer' => $BBS::Universal::FILETRANSFER_VERSION,
        'BBS::Universal::Users'        => $BBS::Universal::USERS_VERSION,
        'BBS::Universal::DB'           => $BBS::Universal::DB_VERSION,
        'BBS::Universal::Tokens'       => $BBS::Universal::TOKENS_VERSION,
        'BBS::Universal::Commands'     => $BBS::Universal::COMMANDS_VERSION,
        'DBI'                          => $DBI::VERSION,
        'DBD::mysql'                   => $DBD::mysql::VERSION,
        'DateTime'                     => $DateTime::VERSION,
        'Debug::Easy'                  => $Debug::Easy::VERSION,
        'File::Basename'               => $File::Basename::VERSION,
        'Time::HiRes'                  => $Time::HiRes::VERSION,
        'Term::ReadKey'                => $Term::ReadKey::VERSION,
        'Term::ANSIScreen'             => $Term::ANSIScreen::VERSION,
        'Text::Format'                 => $Text::Format::VERSION,
        'Text::SimpleTable'            => $Text::SimpleTable::VERSION,
        'IO::Socket'                   => $IO::Socket::VERSION,
    };
###
    $self->{'debug'}->DEBUG(['End Parse Versions']);
    return ($versions);
} ## end sub parse_versions

sub yes_no {
    my $self  = shift;
    my $bool  = 0 + shift;
    my $color = shift;

    my $response;
    $self->{'debug'}->DEBUG(['Start Yes No']);
    if ($color && $self->{'USER'}->{'text_mode'} eq 'ANSI') {
        if ($bool) {
            $response = '[% GREEN %]YES[% RESET %]';
        } else {
            $response = '[% RED %]NO[% RESET %]';
        }
    } else {
        if ($bool) {
            $response = 'YES';
        } else {
            $response = 'NO';
        }
    } ## end else [ if ($color && $self->{...})]
    $self->{'debug'}->DEBUG(['End Yes No']);
    return ($response);
} ## end sub yes_no

sub pad_center {
    my $self  = shift;
    my $text  = shift;
    my $width = shift;

    $self->{'debug'}->DEBUG(['Start Pad Center']);
    if (defined($text) && $text ne '') {
        my $size    = length($text);
        my $padding = int(($width - $size) / 2);
        if ($padding > 0) {
            $text = ' ' x $padding . $text;
        }
    } ## end if (defined($text) && ...)
    $self->{'debug'}->DEBUG(['End Pad Center']);
    return ($text);
} ## end sub pad_center

sub center {
    my $self  = shift;
    my $text  = shift;
    my $width = shift;

    $self->{'debug'}->DEBUG(['Start Center']);
    my $response;
    unless (defined($text) && $text ne '') {
        return ($text);
    }
    if ($text =~ /\n/s) {
        chomp(my @lines = split(/\n$/, $text));
        $text = '';
        foreach my $line (@lines) {
            $text .= $self->pad_center($line, $width) . "\n";
        }
        $response = $text;
    } else {
        $response = $self->pad_center($text, $width);
    }
    $self->{'debug'}->DEBUG(['End Center']);
    return ($response);
} ## end sub center

sub trim {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start Trim']);
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    $self->{'debug'}->DEBUG(['End Trim']);
    return ($text);
} ## end sub trim

sub get_fortune {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Get Fortune']);
    $self->{'debug'}->DEBUG(['Get Fortune']);
    $self->{'debug'}->DEBUG(['End Get Fortune']);

    my $fortune = `fortune -s -u`;
    chomp($fortune);

    return (($self->{'USER'}->{'play_fortunes'}) ? $fortune : '');
} ## end sub get_fortune

sub playit {
    my $self = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start Playit']);
    unless ($self->{'nosound'}) {
        $self->{'debug'}->DEBUG(["  Play Sound $file"]);
        if ((-e '/usr/bin/mplayer' || -e '/usr/local/bin/mplayer') && $self->configuration('PLAY SYSOP SOUNDS') =~ /TRUE|1/i) {
            my $path = $self->{'CONF'}->{'BBS ROOT'} . "/sysop_sounds/$file";
            system("mplayer -really-quiet $path 1>/dev/null 2>&1 &");
        }
    } ## end unless ($self->{'nosound'})
    $self->{'debug'}->DEBUG(['End Playit']);
} ## end sub playit

sub check_access_level {
    my $self   = shift;
    my $access = shift;

    if ($self->{'access_levels'}->{$access} <= $self->{'access_levels'}->{ $self->{'USER'}->{'access_level'} }) {
        return (TRUE);
    }
    return (FALSE);
} ## end sub check_access_level

sub color_border {
    my $self  = shift;
    my $tbl   = shift;
    my $color = shift;

    $self->{'debug'}->DEBUG(['Start Color Border']);
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $tbl =~ s/\n/[% NEWLINE %]/gs;
        if ($tbl =~ /(─+?)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %]' . $ch . '[% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(│)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %]' . $ch . '[% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┌)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(└)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% BOX DRAWINGS LIGHT ARC UP AND RIGHT %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┬)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %]' . $ch . '[% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┐)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% BOX DRAWINGS LIGHT ARC DOWN AND LEFT %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(├)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %]' . $ch . '[% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┘)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% BOX DRAWINGS LIGHT ARC UP AND LEFT %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┼)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %]' . $ch . '[% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┤)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %]' . $ch . '[% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┴)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %]' . $ch . '[% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
    } elsif ($mode eq 'ATASCII') {
        if ($tbl =~ /(─)/) {
            my $ch  = $1;
            my $new = '[% HORIZONTAL BAR %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(│)/) {
            my $ch  = $1;
            my $new = '[% MIDDLE VERTICAL BAR %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┌)/) {
            my $ch  = $1;
            my $new = '[% TOP LEFT CORNER %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(└)/) {
            my $ch  = $1;
            my $new = '[% BOTTOM LEFT CORNER %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┬)/) {
            my $ch  = $1;
            my $new = '[% HORIZONTAL BAR MIDDLE TOP %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┐)/) {
            my $ch  = $1;
            my $new = '[% TOP RIGHT CORNER %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(├)/) {
            my $ch  = $1;
            my $new = '[% VERTICAL BAR MIDDLE RIGHT %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┘)/) {
            my $ch  = $1;
            my $new = '[% BOTTOM RIGHT CORNER %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┼)/) {
            my $ch  = $1;
            my $new = '[% CROSS BAR %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┤)/) {
            my $ch  = $1;
            my $new = '[% VERTICAL BAR MIDDLE RIGHT %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┴)/) {
            my $ch  = $1;
            my $new = '[% HORIZONTAL BAR MIDDLE BOTTOM %]';
            $tbl =~ s/$ch/$new/gs;
        }
    } elsif ($mode eq 'PETSCII') {
        $color = 'BROWN' if ($color eq 'ORANGE');
        if ($tbl =~ /(─)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% HORIZONTAL BAR %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(│)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% VERTICAL BAR %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┌)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% TOP LEFT CORNER %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(└)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% BOTTOM LEFT CORNER %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┬)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% HORIZONTAL BAR MIDDLE TOP %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┐)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% TOP RIGHT CORNER %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(├)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% VERTICAL BAR MIDDLE LEFT %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┘)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% BOTTOM RIGHT CORNER %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┼)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% CROSS BAR %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┤)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% HORIZONTAL BAR MIDDLE RIGHT %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
        if ($tbl =~ /(┴)/) {
            my $ch  = $1;
            my $new = '[% ' . $color . ' %][% HORIZONTAL BAR MIDDLE BOTTOM %][% RESET %]';
            $tbl =~ s/$ch/$new/gs;
        }
    } ## end elsif ($mode eq 'PETSCII')
    $self->{'debug'}->DEBUG(['End Color Border']);
    return ($tbl);
} ## end sub color_border

sub html_to_text {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start HTML To Text']);
    $text =~ s/(\n\n\n)+/\n/gs;
    my %entity = (
        lt   => '<',    #a less-than
        gt   => '>',    #a greater-than
        amp  => '&',    #a nampersand
        quot => '"',    #a (verticle) double-quote

        nbsp   => chr 160,    # no-break space
        iexcl  => chr 161,    # inverted exclamation mark
        cent   => chr 162,    # cent sign
        pound  => chr 163,    # pound sterling sign CURRENCY NOT WEIGHT
        curren => chr 164,    # general currency sign
        yen    => chr 165,    # yen sign
        brvbar => chr 166,    # broken (vertical) bar
        sect   => chr 167,    # section sign
        uml    => chr 168,    # umlaut (dieresis)
        copy   => chr 169,    # copyright sign
        ordf   => chr 170,    # ordinal indicator, feminine
        laquo  => chr 171,    # angle quotation mark, left
        not    => chr 172,    # not sign
        shy    => chr 173,    # soft hyphen
        reg    => chr 174,    # registered sign
        macr   => chr 175,    # macron
        deg    => chr 176,    # degree sign
        plusmn => chr 177,    # plus-or-minus sign
        sup2   => chr 178,    # superscript two
        sup3   => chr 179,    # superscript three
        acute  => chr 180,    # acute accent
        micro  => chr 181,    # micro sign
        para   => chr 182,    # pilcrow (paragraph sign)
        middot => chr 183,    # middle dot
        cedil  => chr 184,    # cedilla
        sup1   => chr 185,    # superscript one
        ordm   => chr 186,    # ordinal indicator, masculine
        raquo  => chr 187,    # angle quotation mark, right
        frac14 => chr 188,    # fraction one-quarter
        frac12 => chr 189,    # fraction one-half
        frac34 => chr 190,    # fraction three-quarters
        iquest => chr 191,    # inverted question mark
        Agrave => chr 192,    # capital A, grave accent
        Aacute => chr 193,    # capital A, acute accent
        Acirc  => chr 194,    # capital A, circumflex accent
        Atilde => chr 195,    # capital A, tilde
        Auml   => chr 196,    # capital A, dieresis or umlaut mark
        Aring  => chr 197,    # capital A, ring
        AElig  => chr 198,    # capital AE diphthong (ligature)
        Ccedil => chr 199,    # capital C, cedilla
        Egrave => chr 200,    # capital E, grave accent
        Eacute => chr 201,    # capital E, acute accent
        Ecirc  => chr 202,    # capital E, circumflex accent
        Euml   => chr 203,    # capital E, dieresis or umlaut mark
        Igrave => chr 204,    # capital I, grave accent
        Iacute => chr 205,    # capital I, acute accent
        Icirc  => chr 206,    # capital I, circumflex accent
        Iuml   => chr 207,    # capital I, dieresis or umlaut mark
        ETH    => chr 208,    # capital Eth, Icelandic
        Ntilde => chr 209,    # capital N, tilde
        Ograve => chr 210,    # capital O, grave accent
        Oacute => chr 211,    # capital O, acute accent
        Ocirc  => chr 212,    # capital O, circumflex accent
        Otilde => chr 213,    # capital O, tilde
        Ouml   => chr 214,    # capital O, dieresis or umlaut mark
        times  => chr 215,    # multiply sign
        Oslash => chr 216,    # capital O, slash
        Ugrave => chr 217,    # capital U, grave accent
        Uacute => chr 218,    # capital U, acute accent
        Ucirc  => chr 219,    # capital U, circumflex accent
        Uuml   => chr 220,    # capital U, dieresis or umlaut mark
        Yacute => chr 221,    # capital Y, acute accent
        THORN  => chr 222,    # capital THORN, Icelandic
        szlig  => chr 223,    # small sharp s, German (sz ligature)
        agrave => chr 224,    # small a, grave accent
        aacute => chr 225,    # small a, acute accent
        acirc  => chr 226,    # small a, circumflex accent
        atilde => chr 227,    # small a, tilde
        auml   => chr 228,    # small a, dieresis or umlaut mark
        aring  => chr 229,    # small a, ring
        aelig  => chr 230,    # small ae diphthong (ligature)
        ccedil => chr 231,    # small c, cedilla
        egrave => chr 232,    # small e, grave accent
        eacute => chr 233,    # small e, acute accent
        ecirc  => chr 234,    # small e, circumflex accent
        euml   => chr 235,    # small e, dieresis or umlaut mark
        igrave => chr 236,    # small i, grave accent
        iacute => chr 237,    # small i, acute accent
        icirc  => chr 238,    # small i, circumflex accent
        iuml   => chr 239,    # small i, dieresis or umlaut mark
        eth    => chr 240,    # small eth, Icelandic
        ntilde => chr 241,    # small n, tilde
        ograve => chr 242,    # small o, grave accent
        oacute => chr 243,    # small o, acute accent
        ocirc  => chr 244,    # small o, circumflex accent
        otilde => chr 245,    # small o, tilde
        ouml   => chr 246,    # small o, dieresis or umlaut mark
        divide => chr 247,    # divide sign
        oslash => chr 248,    # small o, slash
        ugrave => chr 249,    # small u, grave accent
        uacute => chr 250,    # small u, acute accent
        ucirc  => chr 251,    # small u, circumflex accent
        uuml   => chr 252,    # small u, dieresis or umlaut mark
        yacute => chr 253,    # small y, acute accent
        thorn  => chr 254,    # small thorn, Icelandic
        yuml   => chr 255,    # small y, dieresis or umlaut mark
    );

    for my $chr (0 .. 255) {
        $entity{ '#' . $chr } = chr $chr;
    }
###
    $text =~ s{ <!               # comments begin with a `<!'
          # followed by 0 or more comments;

        (.*?)        # this is actually to eat up comments in non
          # random places

        (                  # not suppose to have any white space here

            # just a quick start;
            --                # each comment starts with a `--'
            .*?             # and includes all text up to and including
            --                # the *next* occurrence of `--'
            \s*             # and may have trailing while space
            #   (albeit not leading white space XXX)
        )+                 # repetire ad libitum  XXX should be * not +
          (.*?)        # trailing non comment text
          >                    # up to a `>'
    }{
        if ($1 || $3) {    # this silliness for embedded comments in tags
            "<!$1 $3>";
        }
    }gesx;    # mutate into nada, nothing, and niente

    $text =~ s{ <                    # opening angle bracket

        (?:                 # Non-backreffing grouping paren
            [^>'"] *       # 0 or more things that are neither > nor ' nor "
                |           #    or else
             ".*?"          # a section between double quotes (stingy match)
                |           #    or else
             '.*?'          # a section between single quotes (stingy match)
        ) +                 # repetire ad libitum
                            #  hm.... are null tags <> legal? XXX
       >                    # closing angle bracket
     }{}gsx;    # mutate into nada, nothing, and niente

    $text =~ s{ (
             &              # an entity starts with a semicolon
             (
                 \x23\d+    # and is either a pound (#) and numbers
                |           #   or else
                 \w+        # has alphanumunders up to a semi
             )
             ;?             # a semi terminates AS DOES ANYTHING ELSE (XXX)
       )
    } {

         $entity{$2}        # if it's a known entity use that
             ||             #   but otherwise
             $1             # leave what we'd found; NO WARNINGS (XXX)

    }gex;    # execute replacement -- that's code not a string
###
    $self->{'debug'}->DEBUG(['End HTML To Text']);
    return ($text);
} ## end sub html_to_text

sub Text::SimpleTable::round {
    my $self  = shift;
    my $color = shift;
    $self->{'chs'} = {
        # Top
        'TOP_LEFT'      => '[% ' . $color . ' %]╭─',
        'TOP_BORDER'    => '─',
        'TOP_SEPARATOR' => '─┬─',
        'TOP_RIGHT'     => '─╮[% RESET %]',

        # Middle
        'MIDDLE_LEFT'      => '[% ' . $color . ' %]├─',
        'MIDDLE_BORDER'    => '─',
        'MIDDLE_SEPARATOR' => '─┼─',
        'MIDDLE_RIGHT'     => '─┤[% RESET %]',

        # Left
        'LEFT_BORDER'  => '[% ' . $color . ' %]│[% RESET %] ',
        'SEPARATOR'    => ' [% ' . $color . ' %]│[% RESET %] ',
        'RIGHT_BORDER' => ' [% ' . $color . ' %]│[% RESET %]',

        # Bottom
        'BOTTOM_LEFT'      => '[% ' . $color . ' %]╰─',
        'BOTTOM_SEPARATOR' => '─┴─',
        'BOTTOM_BORDER'    => '─',
        'BOTTOM_RIGHT'     => '─╯[% RESET %]',

        # Wrapper
        'WRAP' => '-',
    };
    return ($self);
} ## end sub Text::SimpleTable::round

sub Text::SimpleTable::twin {
    my $self  = shift;
    my $color = shift;
    $self->{'chs'} = {
        # Top
        'TOP_LEFT'      => '[% ' . $color . ' %]╔═',
        'TOP_BORDER'    => '═',
        'TOP_SEPARATOR' => '═╦═',
        'TOP_RIGHT'     => '═╗[% RESET %]',

        # Middle
        'MIDDLE_LEFT'      => '[% ' . $color . ' %]╠═',
        'MIDDLE_BORDER'    => '═',
        'MIDDLE_SEPARATOR' => '═╬═',
        'MIDDLE_RIGHT'     => '═╣[% RESET %]',

        # Left
        'LEFT_BORDER'  => '[% ' . $color . ' %]║[% RESET %] ',
        'SEPARATOR'    => ' [% ' . $color . ' %]║[% RESET %] ',
        'RIGHT_BORDER' => ' [% ' . $color . ' %]║[% RESET %]',

        # Bottom
        'BOTTOM_LEFT'      => '[% ' . $color . ' %]╚═',
        'BOTTOM_SEPARATOR' => '═╩═',
        'BOTTOM_BORDER'    => '═',
        'BOTTOM_RIGHT'     => '═╝[% RESET %]',

        # Wrapper
        'WRAP' => '-',
    };
    return ($self);
} ## end sub Text::SimpleTable::twin

sub Text::SimpleTable::thick {
    my $self  = shift;
    my $color = shift;
    $self->{'chs'} = {
        # Top
        'TOP_LEFT'      => '[% ' . $color . ' %]┏━',
        'TOP_BORDER'    => '━',
        'TOP_SEPARATOR' => '━┳━',
        'TOP_RIGHT'     => '━┓[% RESET %]',

        # Middle
        'MIDDLE_LEFT'      => '[% ' . $color . ' %]┣━',
        'MIDDLE_BORDER'    => '━',
        'MIDDLE_SEPARATOR' => '━╋━',
        'MIDDLE_RIGHT'     => '━┫[% RESET %]',

        # Left
        'LEFT_BORDER'  => '[% ' . $color . ' %]┃[% RESET %] ',
        'SEPARATOR'    => ' [% ' . $color . ' %]┃[% RESET %] ',
        'RIGHT_BORDER' => ' [% ' . $color . ' %]┃[% RESET %]',

        # Bottom
        'BOTTOM_LEFT'      => '[% ' . $color . ' %]┗━',
        'BOTTOM_SEPARATOR' => '━┻━',
        'BOTTOM_BORDER'    => '━',
        'BOTTOM_RIGHT'     => '━┛[% RESET %]',

        # Wrapper
        'WRAP' => '-',
    };
    return ($self);
} ## end sub Text::SimpleTable::thick

sub Text::SimpleTable::boxes2 {
    my $self  = shift;
    my $color = shift || 'WHITE';
    $self->{'chs'} = {
        # Top
        'TOP_LEFT'      => '[% ' . $color . ' %]┌─',
        'TOP_BORDER'    => '─',
        'TOP_SEPARATOR' => '─┬─',
        'TOP_RIGHT'     => '─┐[% RESET %]',

        # Middle
        'MIDDLE_LEFT'      => '[% ' . $color . ' %]├─',
        'MIDDLE_BORDER'    => '─',
        'MIDDLE_SEPARATOR' => '─┼─',
        'MIDDLE_RIGHT'     => '─┤[% RESET %]',

        # Left
        'LEFT_BORDER'  => '[% ' . $color . ' %]│[% RESET %] ',
        'SEPARATOR'    => ' [% ' . $color . ' %]│[% RESET %] ',
        'RIGHT_BORDER' => ' [% ' . $color . ' %]│[% RESET %]',

        # Bottom
        'BOTTOM_LEFT'      => '[% ' . $color . ' %]└─',
        'BOTTOM_SEPARATOR' => '─┴─',
        'BOTTOM_BORDER'    => '─',
        'BOTTOM_RIGHT'     => '─┘[% RESET %]',

        # Wrapper
        'WRAP' => '-',
    };
    return ($self);
} ## end sub Text::SimpleTable::boxes2

sub Text::SimpleTable::wedge {
    my $self  = shift;
    my $color = shift || 'WHITE';
    $self->{'chs'} = {
        # Top
        'TOP_LEFT'      => '[% ' . $color . ' %]◢█',
        'TOP_BORDER'    => '█',
        'TOP_SEPARATOR' => '███',
        'TOP_RIGHT'     => '█◣[% RESET %]',

        # Middle
        'MIDDLE_LEFT'      => '[% ' . $color . ' %]██',
        'MIDDLE_BORDER'    => '█',
        'MIDDLE_SEPARATOR' => '███',
        'MIDDLE_RIGHT'     => '██[% RESET %]',

        # Left
        'LEFT_BORDER'  => '[% ' . $color . ' %]█[% RESET %] ',
        'SEPARATOR'    => ' [% ' . $color . ' %]█[% RESET %] ',
        'RIGHT_BORDER' => ' [% ' . $color . ' %]█[% RESET %]',

        # Bottom
        'BOTTOM_LEFT'      => '[% ' . $color . ' %]◥█',
        'BOTTOM_SEPARATOR' => '███',
        'BOTTOM_BORDER'    => '█',
        'BOTTOM_RIGHT'     => '█◤[% RESET %]',

        # Wrapper
        'WRAP' => '-',
    };
    return ($self);
} ## end sub Text::SimpleTable::wedge

# ╭─────────┬───────────────────────╮
# │ Unicode │ Character Token Names │
# ├─────────┼───────────────────────┤
# │ U+1FBF0 │  SEGMENTED DIGIT ZERO │ 🯰
# │ U+1FBF1 │   SEGMENTED DIGIT ONE │ 🯱
# │ U+1FBF2 │   SEGMENTED DIGIT TWO │ 🯲
# │ U+1FBF3 │ SEGMENTED DIGIT THREE │ 🯳
# │ U+1FBF4 │  SEGMENTED DIGIT FOUR │ 🯴
# │ U+1FBF5 │  SEGMENTED DIGIT FIVE │ 🯵
# │ U+1FBF6 │   SEGMENTED DIGIT SIX │ 🯶
# │ U+1FBF7 │ SEGMENTED DIGIT SEVEN │ 🯷
# │ U+1FBF8 │ SEGMENTED DIGIT EIGHT │ 🯸
# │ U+1FBF9 │  SEGMENTED DIGIT NINE │ 🯹
# ╰─────────┴───────────────────────╯

sub clock {
    my $self = shift;

    my @clock = ('🯰','🯱','🯲','🯳','🯴','🯵','🯶','🯷','🯸','🯹');
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $hour -= 12 if ($hour > 12);
    my $now = sprintf('%02d:%02d:%02d', $hour, $min, $sec);
    for (my $digit = 0; $digit < 10; $digit++) {
        $now =~ s/$digit/$clock[$digit] /g;
    }
    return($now);
}

=head2 COPYRIGHT

Copyright 2023-2026 Richard Kelsch
All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

L<https://perlfoundation.org/artistic-license-20.html>

Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

# package BBS::Universal::ANSI;

# Returns a description of a token using the meta data.
sub ansi_description {
    my ($self, $code, $name) = @_;

    return ($self->{'ansi_meta'}->{$code}->{$name}->{'desc'});
}

sub ansi_type {
    my $self = shift;
    my $text = substr(shift, 2);
    if ($text =~ /^38;2;\d+;\d+;\d+m/) {
        return ('ANSI 24 BIT');
    } elsif ($text =~ /^38;5;\d+m/) {
        return ('ANSI 8 BIT');
    } elsif ($text =~ /^(\d+)m/) {
		my $color = $1 + 0;
		if (($color >= 30 && $color <= 37) || ($color >= 40 && $color <= 47) || $color == 39 || $color == 49) {
			return('ANSI 3 BIT');
		} elsif (($color >= 90 && $color <= 97) || ($color >= 100 && $color <= 107)) {
			return('ANSI 4 BIT');
		}
    }
} ## end sub ansi_type

sub ansi_decode {
    my ($self, $text) = @_;

    # Nothing to do for very short strings
    return ($text) unless ((defined $text && length($text) > 1) || $text !~ /\[\%/);

    # If a literal screen reset token exists, remove it and run reset once.
    if ($text =~ /\[\%\s*SCREEN\s+RESET\s*\%\]/i) {
        $text =~ s/\[\%\s*SCREEN\s+RESET\s*\%\]//gis;
        system('reset');
    }

    # Convenience CSI
    my $am  = $self->{'ansi_meta'}->{'foreground'};
    my $csi = $self->{'ansi_meta'}->{'special'}->{'CSI'}->{'out'};

    #
    # Targeted parameterized tokens (single-pass). These are simple Regex -> CSI conversions.
    #
    $text =~ s/\[\%\s*LOCATE\s+(\d+)\s*,\s*(\d+)\s*\%\]/ $csi . "$2;$1" . 'H' /eigs;
    $text =~ s/\[\%\s*SCROLL\s+UP\s+(\d+)\s*\%\]/     $csi . $1 . 'S'           /eigs;
    $text =~ s/\[\%\s*SCROLL\s+DOWN\s+(\d+)\s*\%\]/   $csi . $1 . 'T'           /eigs;

    # HORIZONTAL RULE expands into a sequence of meta-tokens (resolved later).
    $text =~ s/\[\%\s*HORIZONTAL\s+RULE\s+(.*?)\s*\%\]/
      do {
          my $color = defined $1 && $1 ne '' ? uc $1 : 'DEFAULT';
          '[% RETURN %][% B_' . $color . ' %][% CLEAR LINE %][% RESET %]';
      }/eigs;

    # 24-bit RGB underline/foreground/background
	$text =~ s/\[\%\s+UNDERLINE\s+COLOR\s+RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s+\%\]/
	  do { my ($red, $green, $blue) = ($1&255, $2&255, $3&255); "\e[58;2;$red;$green;${blue}m" }/eigs;
    $text =~ s/\[\%\s+RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s+\%\]/
      do { my ($red, $green, $blue) = ($1&255,$2&255,$3&255); "\e[38;2;$red;$green;${blue}m" }/eigs;
    $text =~ s/\[\%\s+B_RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s+\%\]/
      do { my ($red, $green, $blue) = ($1&255,$2&255,$3&255); "\e[48;2;$red;$green;${blue}m" }/eigs;

    #
    # Flatten the ansi_meta lookup to a simple, case-insensitive hash for a single-pass
    # substitution of tokens like [% RED %], [% RESET %], etc.
    #
    if ($text =~ /CLS/i && $self->{'local_mode'}) {
        my $ch = locate(($self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST')), 1) . cldown;
        $text =~ s/\[\%\s+CLS\s+\%\]/$ch/gsi;
    }

    my %lookup;
    for my $code (qw(foreground background special clear cursor attributes)) {
        my $map = $self->{'ansi_meta'}->{$code} or next;
        while (my ($name, $info) = each %{$map}) {
            next unless (defined($info->{out}));
            $lookup{ lc $name } = $info->{out};
        }
    } ## end for my $code (qw(foreground background special clear cursor attributes))

    # Final single-pass replacement for remaining [% ... %] tokens.
    # If token matches a lookup entry, substitute; otherwise if it's a named char use charnames;
    # else leave token visible.
###
    $text =~ s/\[\%\s*(.+?)\s*\%\]/
      do {
          my $tok = $1;
          my $key = lc $tok;
          if ( exists $lookup{$key} ) {
              $lookup{$key};
          } elsif ( defined( my $char = charnames::string_vianame($tok) ) ) {
              $char;
          } else {
              $&;    # leave the original token intact
          }
      }/egis;
###
    return $text;
} ## end sub ansi_decode

sub ansi_output {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start ANSI Output']);
    my $mlines = (exists($self->{'USER'}->{'max_rows'})) ? $self->{'USER'}->{'max_rows'} - 3 : 21;
    my $lines  = $mlines;
    $text = $self->ansi_decode($text);
    my $s_len = length($text);
    my $nl    = $self->{'ansi_meta'}->{'cursor'}->{'NEWLINE'}->{'out'};

    foreach my $count (0 .. $s_len) {
        my $char = substr($text, $count, 1);
        if ($char eq "\n") {
            if ($text !~ /$nl/ && !$self->{'local_mode'}) {    # translate only if the file doesn't have ASCII newlines
                $char = $nl;
            }
            $lines--;
            if ($lines <= 0) {
                $lines = $mlines;
                last unless ($self->scroll($nl));
                next;
            }
        } ## end if ($char eq "\n")
        $self->send_char($char);
    } ## end foreach my $count (0 .. $s_len)
    $self->{'debug'}->DEBUG(['End ANSI Output']);
    return (TRUE);
} ## end sub ansi_output

sub ansi_initialize {
	my $self = shift;

	$self->{'debug'}->DEBUG(['Start ANSI Initialize']);

	# Helper builders to compact the meta spec
	my $pairs_to_map = sub {                                      # [name, out, desc] -> { name => { out, desc } }
		my (@defs) = @_;
		return { map { $_->[0] => { out => $_->[1], desc => $_->[2] } } @defs };
	};
###
	# Special sequences
	my $special = $pairs_to_map->(
		['APC', "\e_",   'Application Program Command'],
		['SS2', "\eN",   'Single Shift 2'],
		['SS3', "\eO",   'Single Shift 3'],
		['CSI', "\e[",   'Control Sequence Introducer'],
		['OSC', "\e]",   'Operating System Command'],
		['SOS', "\eX",   'Start Of String'],
		['ST',  "\e\\",  'String Terminator'],
		['DCS', "\eP",   'Device Control String'],
	);

	# Clear controls
	my $clear = $pairs_to_map->(
		['CLS',        "\e[2J\e[H",           'Clear screen and place cursor at the top of the screen'],
		['CLEAR',      "\e[2J",               'Clear screen and keep cursor location'],
		['CLEAR LINE', "\e[0K",               'Clear the current line from cursor'],
		['CLEAR DOWN', "\e[0J",               'Clear from cursor position to bottom of the screen'],
		['CLEAR UP',   "\e[1J",               'Clear to the top of the screen from cursor position'],
	);

	# Cursor movement and control
	my $cursor = $pairs_to_map->(
		['BACKSPACE',     chr(8),            'Backspace'],
		['RETURN',        chr(13),           'Carriage Return (ASCII 13)'],
		['LINEFEED',      chr(10),           'Line feed (ASCII 10)'],
		['NEWLINE',       chr(13) . chr(10), 'New line (ASCII 13 and ASCII 10)'],
		['HOME',          "\e[H",            'Place cursor at top left of the screen'],
		['UP',            "\e[A",            'Move cursor up one line'],
		['DOWN',          "\e[B",            'Move cursor down one line'],
		['RIGHT',         "\e[C",            'Move cursor right one space non-destructively'],
		['LEFT',          "\e[D",            'Move cursor left one space non-destructively'],
		['NEXT LINE',     "\e[E",            'Place the cursor at the beginning of the next line'],
		['PREVIOUS LINE', "\e[F",            'Place the cursor at the beginning of the previous line'],
		['SAVE',          "\e[s",            'Save cureent cursor position'],
		['RESTORE',       "\e[u",            'Restore the cursor to the saved position'],
		['CURSOR ON',     "\e[?25h",         'Turn the cursor on'],
		['CURSOR OFF',    "\e[?25l",         'Turn the cursor off'],
		['SCREEN 1',      "\e[?1049l",       'Set display to screen 1'],
		['SCREEN 2',      "\e[?1049h",       'Set display to screen 2'],
	);

	# Text attributes
	my $attributes = $pairs_to_map->(
		['FONT 1',                    "\e[1m",  'ANSI FONT 1'],
		['FONT 2',                    "\e[2m",  'ANSI FONT 2'],
		['FONT 3',                    "\e[3m",  'ANSI FONT 3'],
		['FONT 4',                    "\e[4m",  'ANSI FONT 4'],
		['FONT 5',                    "\e[5m",  'ANSI FONT 5'],
		['FONT 6',                    "\e[6m",  'ANSI FONT 6'],
		['FONT 7',                    "\e[7m",  'ANSI FONT 7'],
		['FONT 8',                    "\e[8m",  'ANSI FONT 8'],
		['FONT 9',                    "\e[9m",  'ANSI FONT 9'],
		['FONT DOUBLE-HEIGHT TOP',    "\e#3",   'Double-Height Font Top Portion'],
		['FONT DOUBLE-HEIGHT BOTTOM', "\e#4",   'Double-Height Font Bottom Portion'],
		['FONT DOUBLE-WIDTH',         "\e#6",   'Double-Width Font'],
		['FONT DEFAULT SIZE',         "\e#5",   'Default Font Size'],
		['RESET',                     "\e[0m",  'Restore all attributes and colors to their defaults'],
		['BOLD',                      "\e[1m",  'Set to bold text'],
		['NORMAL',                    "\e[22m", 'Turn off all attributes'],
		['FAINT',                     "\e[2m",  'Set to faint (light) text'],
		['ITALIC',                    "\e[3m",  'Set to italic text'],
		['UNDERLINE',                 "\e[4m",  'Set to underlined text'],
		['DEFAULT UNDERLINE COLOR',   "\e[59m", 'Set underline color to the default'],
		['FRAMED',                    "\e[51m", 'Turn on framed text'],
		['FRAMED OFF',                "\e[54m", 'Turn off framed text'],
		['ENCIRCLED',                 "\e[52m", 'Turn on encircled letters'],
		['ENCIRCLED OFF',             "\e[54m", 'Turn off encircled letters'],
		['OVERLINED',                 "\e[53m", 'Turn on overlined text'],
		['OVERLINED OFF',             "\e[55m", 'Turn off overlined text'],
		['SUPERSCRIPT',               "\e[73m", 'Turn on superscript'],
		['SUBSCRIPT',                 "\e[74m", 'Turn on superscript'],
		['SUPERSCRIPT OFF',           "\e[75m", 'Turn off superscript'],
		['SUBSCRIPT OFF',             "\e[75m", 'Turn off subscript'],
		['SLOW BLINK',                "\e[5m",  'Set slow blink'],
		['RAPID BLINK',               "\e[6m",  'Set rapid blink'],
		['INVERT',                    "\e[7m",  'Invert text'],
		['REVERSE',                   "\e[7m",  'Invert text'],
		['HIDE',                      "\e[8m",  'Hide enclosed text'],
		['REVEAL',                    "\e[28m", 'Reveal hidden text'],
		['CROSSED OUT',               "\e[9m",  'Crossed out text'],
		['FONT DEFAULT',              "\e[10m", 'Set default font'],
		['PROPORTIONAL ON',           "\e[26m", 'Turn on proportional text'],
		['PROPORTIONAL OFF',          "\e[50m", 'Turn off proportional text'],
		['RING BELL',                 chr(7),   'Console bell'],
	);

	# Foreground (base 16 + bright variants)
	my @fg16 = (
		['DEFAULT',        "\e[39m", 'Default foreground color'],
		['BLACK',          "\e[30m", 'Black'],
		['RED',            "\e[31m", 'Red'],
		['GREEN',          "\e[32m", 'Green'],
		['YELLOW',         "\e[33m", 'Yellow'],
		['BLUE',           "\e[34m", 'Blue'],
		['MAGENTA',        "\e[35m", 'Magenta'],
		['CYAN',           "\e[36m", 'Cyan'],
		['WHITE',          "\e[37m", 'White'],
		['BRIGHT BLACK',   "\e[90m", 'Bright black'],
		['BRIGHT RED',     "\e[91m", 'Bright red'],
		['BRIGHT GREEN',   "\e[92m", 'Bright green'],
		['BRIGHT YELLOW',  "\e[93m", 'Bright yellow'],
		['BRIGHT BLUE',    "\e[94m", 'Bright blue'],
		['BRIGHT MAGENTA', "\e[95m", 'Bright magenta'],
		['BRIGHT CYAN',    "\e[96m", 'Bright cyan'],
		['BRIGHT WHITE',   "\e[97m", 'Bright white'],
	);

	# Foreground extensions: all named 256-color and truecolor entries

    # Foreground extensions: all named 256-color and truecolor entries
	my @fg_extra = (
		['NAVY',                          "\e[38;5;17m",           'Navy'],
		['PINK',                          "\e[38;5;198m",          'Pink'],
		['AIR FORCE BLUE',                "\e[38;2;93;138;168m",   'Air Force blue'],
		['ALICE BLUE',                    "\e[38;2;240;248;255m",  'Alice blue'],
		['ALIZARIN CRIMSON',              "\e[38;2;227;38;54m",    'Alizarin crimson'],
		['ALMOND',                        "\e[38;2;239;222;205m",  'Almond'],
		['AMARANTH',                      "\e[38;2;229;43;80m",    'Amaranth'],
		['AMBER',                         "\e[38;2;255;191;0m",    'Amber'],
		['AMERICAN ROSE',                 "\e[38;2;255;3;62m",     'American rose'],
		['AMETHYST',                      "\e[38;2;153;102;204m",  'Amethyst'],
		['ANDROID GREEN',                 "\e[38;2;164;198;57m",   'Android Green'],
		['ANTI-FLASH WHITE',              "\e[38;2;242;243;244m",  'Anti-flash white'],
		['ANTIQUE BRASS',                 "\e[38;2;205;149;117m",  'Antique brass'],
		['ANTIQUE FUCHSIA',               "\e[38;2;145;92;131m",   'Antique fuchsia'],
		['ANTIQUE WHITE',                 "\e[38;2;250;235;215m",  'Antique white'],
		['AO',                            "\e[38;2;0;128;0m",      'Ao'],
		['APPLE GREEN',                   "\e[38;2;141;182;0m",    'Apple green'],
		['APRICOT',                       "\e[38;2;251;206;177m",  'Apricot'],
		['AQUA',                          "\e[38;2;0;255;255m",    'Aqua'],
		['AQUAMARINE',                    "\e[38;2;127;255;212m",  'Aquamarine'],
		['ARMY GREEN',                    "\e[38;2;75;83;32m",     'Army green'],
		['ARYLIDE YELLOW',                "\e[38;2;233;214;107m",  'Arylide yellow'],
		['ASH GREY',                      "\e[38;2;178;190;181m",  'Ash grey'],
		['ASPARAGUS',                     "\e[38;2;135;169;107m",  'Asparagus'],
		['ATOMIC TANGERINE',              "\e[38;2;255;153;102m",  'Atomic tangerine'],
		['AUBURN',                        "\e[38;2;165;42;42m",    'Auburn'],
		['AUREOLIN',                      "\e[38;2;253;238;0m",    'Aureolin'],
		['AUROMETALSAURUS',               "\e[38;2;110;127;128m",  'AuroMetalSaurus'],
		['AWESOME',                       "\e[38;2;255;32;82m",    'Awesome'],
		['AZURE',                         "\e[38;2;0;127;255m",    'Azure'],
		['AZURE MIST/WEB',                "\e[38;2;240;255;255m",  'Azure mist/web'],
		['BABY BLUE',                     "\e[38;2;137;207;240m",  'Baby blue'],
		['BABY BLUE EYES',                "\e[38;2;161;202;241m",  'Baby blue eyes'],
		['BABY PINK',                     "\e[38;2;244;194;194m",  'Baby pink'],
		['BALL BLUE',                     "\e[38;2;33;171;205m",   'Ball Blue'],
		['BANANA MANIA',                  "\e[38;2;250;231;181m",  'Banana Mania'],
		['BANANA YELLOW',                 "\e[38;2;255;225;53m",   'Banana yellow'],
		['BATTLESHIP GREY',               "\e[38;2;132;132;130m",  'Battleship grey'],
		['BAZAAR',                        "\e[38;2;152;119;123m",  'Bazaar'],
		['BEAU BLUE',                     "\e[38;2;188;212;230m",  'Beau blue'],
		['BEAVER',                        "\e[38;2;159;129;112m",  'Beaver'],
		['BEIGE',                         "\e[38;2;245;245;220m",  'Beige'],
		['BISQUE',                        "\e[38;2;255;228;196m",  'Bisque'],
		['BISTRE',                        "\e[38;2;61;43;31m",     'Bistre'],
		['BITTERSWEET',                   "\e[38;2;254;111;94m",   'Bittersweet'],
		['BLANCHED ALMOND',               "\e[38;2;255;235;205m",  'Blanched Almond'],
		['BLEU DE FRANCE',                "\e[38;2;49;140;231m",   'Bleu de France'],
		['BLIZZARD BLUE',                 "\e[38;2;172;229;238m",  'Blizzard Blue'],
		['BLOND',                         "\e[38;2;250;240;190m",  'Blond'],
		['BLUE BELL',                     "\e[38;2;162;162;208m",  'Blue Bell'],
		['BLUE GRAY',                     "\e[38;2;102;153;204m",  'Blue Gray'],
		['BLUE GREEN',                    "\e[38;2;13;152;186m",   'Blue green'],
		['BLUE PURPLE',                   "\e[38;2;138;43;226m",   'Blue purple'],
		['BLUE VIOLET',                   "\e[38;2;138;43;226m",   'Blue violet'],
		['BLUSH',                         "\e[38;2;222;93;131m",   'Blush'],
		['BOLE',                          "\e[38;2;121;68;59m",    'Bole'],
		['BONDI BLUE',                    "\e[38;2;0;149;182m",    'Bondi blue'],
		['BONE',                          "\e[38;2;227;218;201m",  'Bone'],
		['BOSTON UNIVERSITY RED',         "\e[38;2;204;0;0m",      'Boston University Red'],
		['BOTTLE GREEN',                  "\e[38;2;0;106;78m",     'Bottle green'],
		['BOYSENBERRY',                   "\e[38;2;135;50;96m",    'Boysenberry'],
		['BRANDEIS BLUE',                 "\e[38;2;0;112;255m",    'Brandeis blue'],
		['BRASS',                         "\e[38;2;181;166;66m",   'Brass'],
		['BRICK RED',                     "\e[38;2;203;65;84m",    'Brick red'],
		['BRIGHT CERULEAN',               "\e[38;2;29;172;214m",   'Bright cerulean'],
		['BRIGHT GREEN',                  "\e[38;2;102;255;0m",    'Bright green'],
		['BRIGHT LAVENDER',               "\e[38;2;191;148;228m",  'Bright lavender'],
		['BRIGHT MAROON',                 "\e[38;2;195;33;72m",    'Bright maroon'],
		['BRIGHT PINK',                   "\e[38;2;255;0;127m",    'Bright pink'],
		['BRIGHT TURQUOISE',              "\e[38;2;8;232;222m",    'Bright turquoise'],
		['BRIGHT UBE',                    "\e[38;2;209;159;232m",  'Bright ube'],
		['BRILLIANT LAVENDER',            "\e[38;2;244;187;255m",  'Brilliant lavender'],
		['BRILLIANT ROSE',                "\e[38;2;255;85;163m",   'Brilliant rose'],
		['BRINK PINK',                    "\e[38;2;251;96;127m",   'Brink pink'],
		['BRITISH RACING GREEN',          "\e[38;2;0;66;37m",      'British racing green'],
		['BRONZE',                        "\e[38;2;205;127;50m",   'Bronze'],
		['BROWN',                         "\e[38;2;165;42;42m",    'Brown'],
		['BUBBLE GUM',                    "\e[38;2;255;193;204m",  'Bubble gum'],
		['BUBBLES',                       "\e[38;2;231;254;255m",  'Bubbles'],
		['BUFF',                          "\e[38;2;240;220;130m",  'Buff'],
		['BULGARIAN ROSE',                "\e[38;2;72;6;7m",       'Bulgarian rose'],
		['BURGUNDY',                      "\e[38;2;128;0;32m",     'Burgundy'],
		['BURLYWOOD',                     "\e[38;2;222;184;135m",  'Burlywood'],
		['BURNT ORANGE',                  "\e[38;2;204;85;0m",     'Burnt orange'],
		['BURNT SIENNA',                  "\e[38;2;233;116;81m",   'Burnt sienna'],
		['BURNT UMBER',                   "\e[38;2;138;51;36m",    'Burnt umber'],
		['BYZANTINE',                     "\e[38;2;189;51;164m",   'Byzantine'],
		['BYZANTIUM',                     "\e[38;2;112;41;99m",    'Byzantium'],
		['CG BLUE',                       "\e[38;2;0;122;165m",    'CG Blue'],
		['CG RED',                        "\e[38;2;224;60;49m",    'CG Red'],
		['CADET',                         "\e[38;2;83;104;114m",   'Cadet'],
		['CADET BLUE',                    "\e[38;2;95;158;160m",   'Cadet blue'],
		['CADET GREY',                    "\e[38;2;145;163;176m",  'Cadet grey'],
		['CADMIUM GREEN',                 "\e[38;2;0;107;60m",     'Cadmium green'],
		['CADMIUM ORANGE',                "\e[38;2;237;135;45m",   'Cadmium orange'],
		['CADMIUM RED',                   "\e[38;2;227;0;34m",     'Cadmium red'],
		['CADMIUM YELLOW',                "\e[38;2;255;246;0m",    'Cadmium yellow'],
		['CAFé AU LAIT',                  "\e[38;2;166;123;91m",   'Café au lait'],
		['CAFé NOIR',                     "\e[38;2;75;54;33m",     'Café noir'],
		['CAL POLY POMONA GREEN',         "\e[38;2;30;77;43m",     'Cal Poly Pomona green'],
		['CAMBRIDGE BLUE',                "\e[38;2;163;193;173m",  'Cambridge Blue'],
		['CAMEL',                         "\e[38;2;193;154;107m",  'Camel'],
		['CAMOUFLAGE GREEN',              "\e[38;2;120;134;107m",  'Camouflage green'],
		['CANARY',                        "\e[38;2;255;255;153m",  'Canary'],
		['CANARY YELLOW',                 "\e[38;2;255;239;0m",    'Canary yellow'],
		['CANDY APPLE RED',               "\e[38;2;255;8;0m",      'Candy apple red'],
		['CANDY PINK',                    "\e[38;2;228;113;122m",  'Candy pink'],
		['CAPRI',                         "\e[38;2;0;191;255m",    'Capri'],
		['CAPUT MORTUUM',                 "\e[38;2;89;39;32m",     'Caput mortuum'],
		['CARDINAL',                      "\e[38;2;196;30;58m",    'Cardinal'],
		['CARIBBEAN GREEN',               "\e[38;2;0;204;153m",    'Caribbean green'],
		['CARMINE',                       "\e[38;2;255;0;64m",     'Carmine'],
		['CARMINE PINK',                  "\e[38;2;235;76;66m",    'Carmine pink'],
		['CARMINE RED',                   "\e[38;2;255;0;56m",     'Carmine red'],
		['CARNATION PINK',                "\e[38;2;255;166;201m",  'Carnation pink'],
		['CARNELIAN',                     "\e[38;2;179;27;27m",    'Carnelian'],
		['CAROLINA BLUE',                 "\e[38;2;153;186;221m",  'Carolina blue'],
		['CARROT ORANGE',                 "\e[38;2;237;145;33m",   'Carrot orange'],
		['CELADON',                       "\e[38;2;172;225;175m",  'Celadon'],
		['CELESTE',                       "\e[38;2;178;255;255m",  'Celeste'],
		['CELESTIAL BLUE',                "\e[38;2;73;151;208m",   'Celestial blue'],
		['CERISE',                        "\e[38;2;222;49;99m",    'Cerise'],
		['CERISE PINK',                   "\e[38;2;236;59;131m",   'Cerise pink'],
		['CERULEAN',                      "\e[38;2;0;123;167m",    'Cerulean'],
		['CERULEAN BLUE',                 "\e[38;2;42;82;190m",    'Cerulean blue'],
		['CHAMOISEE',                     "\e[38;2;160;120;90m",   'Chamoisee'],
		['CHAMPAGNE',                     "\e[38;2;250;214;165m",  'Champagne'],
		['CHARCOAL',                      "\e[38;2;54;69;79m",     'Charcoal'],
		['CHARTREUSE',                    "\e[38;2;127;255;0m",    'Chartreuse'],
		['CHERRY',                        "\e[38;2;222;49;99m",    'Cherry'],
		['CHERRY BLOSSOM PINK',           "\e[38;2;255;183;197m",  'Cherry blossom pink'],
		['CHESTNUT',                      "\e[38;2;205;92;92m",    'Chestnut'],
		['CHOCOLATE',                     "\e[38;2;210;105;30m",   'Chocolate'],
		['CHROME YELLOW',                 "\e[38;2;255;167;0m",    'Chrome yellow'],
		['CINEREOUS',                     "\e[38;2;152;129;123m",  'Cinereous'],
		['CINNABAR',                      "\e[38;2;227;66;52m",    'Cinnabar'],
		['CINNAMON',                      "\e[38;2;210;105;30m",   'Cinnamon'],
		['CITRINE',                       "\e[38;2;228;208;10m",   'Citrine'],
		['CLASSIC ROSE',                  "\e[38;2;251;204;231m",  'Classic rose'],
		['COBALT',                        "\e[38;2;0;71;171m",     'Cobalt'],
		['COCOA BROWN',                   "\e[38;2;210;105;30m",   'Cocoa brown'],
		['COFFEE',                        "\e[38;2;111;78;55m",    'Coffee'],
		['COLUMBIA BLUE',                 "\e[38;2;155;221;255m",  'Columbia blue'],
		['COOL BLACK',                    "\e[38;2;0;46;99m",      'Cool black'],
		['COOL GREY',                     "\e[38;2;140;146;172m",  'Cool grey'],
		['COPPER',                        "\e[38;2;184;115;51m",   'Copper'],
		['COPPER ROSE',                   "\e[38;2;153;102;102m",  'Copper rose'],
		['COQUELICOT',                    "\e[38;2;255;56;0m",     'Coquelicot'],
		['CORAL',                         "\e[38;2;255;127;80m",   'Coral'],
		['CORAL PINK',                    "\e[38;2;248;131;121m",  'Coral pink'],
		['CORAL RED',                     "\e[38;2;255;64;64m",    'Coral red'],
		['CORDOVAN',                      "\e[38;2;137;63;69m",    'Cordovan'],
		['CORN',                          "\e[38;2;251;236;93m",   'Corn'],
		['CORNELL RED',                   "\e[38;2;179;27;27m",    'Cornell Red'],
		['CORNFLOWER',                    "\e[38;2;154;206;235m",  'Cornflower'],
		['CORNFLOWER BLUE',               "\e[38;2;100;149;237m",  'Cornflower blue'],
		['CORNSILK',                      "\e[38;2;255;248;220m",  'Cornsilk'],
		['COSMIC LATTE',                  "\e[38;2;255;248;231m",  'Cosmic latte'],
		['COTTON CANDY',                  "\e[38;2;255;188;217m",  'Cotton candy'],
		['CREAM',                         "\e[38;2;255;253;208m",  'Cream'],
		['CRIMSON',                       "\e[38;2;220;20;60m",    'Crimson'],
		['CRIMSON RED',                   "\e[38;2;153;0;0m",      'Crimson Red'],
		['CRIMSON GLORY',                 "\e[38;2;190;0;50m",     'Crimson glory'],
		['DAFFODIL',                      "\e[38;2;255;255;49m",   'Daffodil'],
		['DANDELION',                     "\e[38;2;240;225;48m",   'Dandelion'],
		['DARK BLUE',                     "\e[38;2;0;0;139m",      'Dark blue'],
		['DARK BROWN',                    "\e[38;2;101;67;33m",    'Dark brown'],
		['DARK BYZANTIUM',                "\e[38;2;93;57;84m",     'Dark byzantium'],
		['DARK CANDY APPLE RED',          "\e[38;2;164;0;0m",      'Dark candy apple red'],
		['DARK CERULEAN',                 "\e[38;2;8;69;126m",     'Dark cerulean'],
		['DARK CHESTNUT',                 "\e[38;2;152;105;96m",   'Dark chestnut'],
		['DARK CORAL',                    "\e[38;2;205;91;69m",    'Dark coral'],
		['DARK CYAN',                     "\e[38;2;0;139;139m",    'Dark cyan'],
		['DARK ELECTRIC BLUE',            "\e[38;2;83;104;120m",   'Dark electric blue'],
		['DARK GOLDENROD',                "\e[38;2;184;134;11m",   'Dark goldenrod'],
		['DARK GRAY',                     "\e[38;2;169;169;169m",  'Dark gray'],
		['DARK GREEN',                    "\e[38;2;1;50;32m",      'Dark green'],
		['DARK JUNGLE GREEN',             "\e[38;2;26;36;33m",     'Dark jungle green'],
		['DARK KHAKI',                    "\e[38;2;189;183;107m",  'Dark khaki'],
		['DARK LAVA',                     "\e[38;2;72;60;50m",     'Dark lava'],
		['DARK LAVENDER',                 "\e[38;2;115;79;150m",   'Dark lavender'],
		['DARK MAGENTA',                  "\e[38;2;139;0;139m",    'Dark magenta'],
		['DARK MIDNIGHT BLUE',            "\e[38;2;0;51;102m",     'Dark midnight blue'],
		['DARK OLIVE GREEN',              "\e[38;2;85;107;47m",    'Dark olive green'],
		['DARK ORANGE',                   "\e[38;2;255;140;0m",    'Dark orange'],
		['DARK ORCHID',                   "\e[38;2;153;50;204m",   'Dark orchid'],
		['DARK PASTEL BLUE',              "\e[38;2;119;158;203m",  'Dark pastel blue'],
		['DARK PASTEL GREEN',             "\e[38;2;3;192;60m",     'Dark pastel green'],
		['DARK PASTEL PURPLE',            "\e[38;2;150;111;214m",  'Dark pastel purple'],
		['DARK PASTEL RED',               "\e[38;2;194;59;34m",    'Dark pastel red'],
		['DARK PINK',                     "\e[38;2;231;84;128m",   'Dark pink'],
		['DARK POWDER BLUE',              "\e[38;2;0;51;153m",     'Dark powder blue'],
		['DARK RASPBERRY',                "\e[38;2;135;38;87m",    'Dark raspberry'],
		['DARK RED',                      "\e[38;2;139;0;0m",      'Dark red'],
		['DARK SALMON',                   "\e[38;2;233;150;122m",  'Dark salmon'],
		['DARK SCARLET',                  "\e[38;2;86;3;25m",      'Dark scarlet'],
		['DARK SEA GREEN',                "\e[38;2;143;188;143m",  'Dark sea green'],
		['DARK SIENNA',                   "\e[38;2;60;20;20m",     'Dark sienna'],
		['DARK SLATE BLUE',               "\e[38;2;72;61;139m",    'Dark slate blue'],
		['DARK SLATE GRAY',               "\e[38;2;47;79;79m",     'Dark slate gray'],
		['DARK SPRING GREEN',             "\e[38;2;23;114;69m",    'Dark spring green'],
		['DARK TAN',                      "\e[38;2;145;129;81m",   'Dark tan'],
		['DARK TANGERINE',                "\e[38;2;255;168;18m",   'Dark tangerine'],
		['DARK TAUPE',                    "\e[38;2;72;60;50m",     'Dark taupe'],
		['DARK TERRA COTTA',              "\e[38;2;204;78;92m",    'Dark terra cotta'],
		['DARK TURQUOISE',                "\e[38;2;0;206;209m",    'Dark turquoise'],
		['DARK VIOLET',                   "\e[38;2;148;0;211m",    'Dark violet'],
		['DARTMOUTH GREEN',               "\e[38;2;0;105;62m",     'Dartmouth green'],
		['DAVY GREY',                     "\e[38;2;85;85;85m",     'Davy grey'],
		['DEBIAN RED',                    "\e[38;2;215;10;83m",    'Debian red'],
		['DEEP CARMINE',                  "\e[38;2;169;32;62m",    'Deep carmine'],
		['DEEP CARMINE PINK',             "\e[38;2;239;48;56m",    'Deep carmine pink'],
		['DEEP CARROT ORANGE',            "\e[38;2;233;105;44m",   'Deep carrot orange'],
		['DEEP CERISE',                   "\e[38;2;218;50;135m",   'Deep cerise'],
		['DEEP CHAMPAGNE',                "\e[38;2;250;214;165m",  'Deep champagne'],
		['DEEP CHESTNUT',                 "\e[38;2;185;78;72m",    'Deep chestnut'],
		['DEEP COFFEE',                   "\e[38;2;112;66;65m",    'Deep coffee'],
		['DEEP FUCHSIA',                  "\e[38;2;193;84;193m",   'Deep fuchsia'],
		['DEEP JUNGLE GREEN',             "\e[38;2;0;75;73m",      'Deep jungle green'],
		['DEEP LILAC',                    "\e[38;2;153;85;187m",   'Deep lilac'],
		['DEEP MAGENTA',                  "\e[38;2;204;0;204m",    'Deep magenta'],
		['DEEP PEACH',                    "\e[38;2;255;203;164m",  'Deep peach'],
		['DEEP PINK',                     "\e[38;2;255;20;147m",   'Deep pink'],
		['DEEP SAFFRON',                  "\e[38;2;255;153;51m",   'Deep saffron'],
		['DEEP SKY BLUE',                 "\e[38;2;0;191;255m",    'Deep sky blue'],
		['DENIM',                         "\e[38;2;21;96;189m",    'Denim'],
		['DESERT',                        "\e[38;2;193;154;107m",  'Desert'],
		['DESERT SAND',                   "\e[38;2;237;201;175m",  'Desert sand'],
		['DIM GRAY',                      "\e[38;2;105;105;105m",  'Dim gray'],
		['DODGER BLUE',                   "\e[38;2;30;144;255m",   'Dodger blue'],
		['DOGWOOD ROSE',                  "\e[38;2;215;24;104m",   'Dogwood rose'],
		['DOLLAR BILL',                   "\e[38;2;133;187;101m",  'Dollar bill'],
		['DRAB',                          "\e[38;2;150;113;23m",   'Drab'],
		['DUKE BLUE',                     "\e[38;2;0;0;156m",      'Duke blue'],
		['EARTH YELLOW',                  "\e[38;2;225;169;95m",   'Earth yellow'],
		['ECRU',                          "\e[38;2;194;178;128m",  'Ecru'],
		['EGGPLANT',                      "\e[38;2;97;64;81m",     'Eggplant'],
		['EGGSHELL',                      "\e[38;2;240;234;214m",  'Eggshell'],
		['EGYPTIAN BLUE',                 "\e[38;2;16;52;166m",    'Egyptian blue'],
		['ELECTRIC BLUE',                 "\e[38;2;125;249;255m",  'Electric blue'],
		['ELECTRIC CRIMSON',              "\e[38;2;255;0;63m",     'Electric crimson'],
		['ELECTRIC CYAN',                 "\e[38;2;0;255;255m",    'Electric cyan'],
		['ELECTRIC GREEN',                "\e[38;2;0;255;0m",      'Electric green'],
		['ELECTRIC INDIGO',               "\e[38;2;111;0;255m",    'Electric indigo'],
		['ELECTRIC LAVENDER',             "\e[38;2;244;187;255m",  'Electric lavender'],
		['ELECTRIC LIME',                 "\e[38;2;204;255;0m",    'Electric lime'],
		['ELECTRIC PURPLE',               "\e[38;2;191;0;255m",    'Electric purple'],
		['ELECTRIC ULTRAMARINE',          "\e[38;2;63;0;255m",     'Electric ultramarine'],
		['ELECTRIC VIOLET',               "\e[38;2;143;0;255m",    'Electric violet'],
		['ELECTRIC YELLOW',               "\e[38;2;255;255;0m",    'Electric yellow'],
		['EMERALD',                       "\e[38;2;80;200;120m",   'Emerald'],
		['ETON BLUE',                     "\e[38;2;150;200;162m",  'Eton blue'],
		['FALLOW',                        "\e[38;2;193;154;107m",  'Fallow'],
		['FALU RED',                      "\e[38;2;128;24;24m",    'Falu red'],
		['FAMOUS',                        "\e[38;2;255;0;255m",    'Famous'],
		['FANDANGO',                      "\e[38;2;181;51;137m",   'Fandango'],
		['FASHION FUCHSIA',               "\e[38;2;244;0;161m",    'Fashion fuchsia'],
		['FAWN',                          "\e[38;2;229;170;112m",  'Fawn'],
		['FELDGRAU',                      "\e[38;2;77;93;83m",     'Feldgrau'],
		['FERN',                          "\e[38;2;113;188;120m",  'Fern'],
		['FERN GREEN',                    "\e[38;2;79;121;66m",    'Fern green'],
		['FERRARI RED',                   "\e[38;2;255;40;0m",     'Ferrari Red'],
		['FIELD DRAB',                    "\e[38;2;108;84;30m",    'Field drab'],
		['FIRE ENGINE RED',               "\e[38;2;206;32;41m",    'Fire engine red'],
		['FIREBRICK',                     "\e[38;2;178;34;34m",    'Firebrick'],
		['FLAME',                         "\e[38;2;226;88;34m",    'Flame'],
		['FLAMINGO PINK',                 "\e[38;2;252;142;172m",  'Flamingo pink'],
		['FLAVESCENT',                    "\e[38;2;247;233;142m",  'Flavescent'],
		['FLAX',                          "\e[38;2;238;220;130m",  'Flax'],
		['FLORAL WHITE',                  "\e[38;2;255;250;240m",  'Floral white'],
		['FLUORESCENT ORANGE',            "\e[38;2;255;191;0m",    'Fluorescent orange'],
		['FLUORESCENT PINK',              "\e[38;2;255;20;147m",   'Fluorescent pink'],
		['FLUORESCENT YELLOW',            "\e[38;2;204;255;0m",    'Fluorescent yellow'],
		['FOLLY',                         "\e[38;2;255;0;79m",     'Folly'],
		['FOREST GREEN',                  "\e[38;2;34;139;34m",    'Forest green'],
		['FRENCH BEIGE',                  "\e[38;2;166;123;91m",   'French beige'],
		['FRENCH BLUE',                   "\e[38;2;0;114;187m",    'French blue'],
		['FRENCH LILAC',                  "\e[38;2;134;96;142m",   'French lilac'],
		['FRENCH ROSE',                   "\e[38;2;246;74;138m",   'French rose'],
		['FUCHSIA',                       "\e[38;2;255;0;255m",    'Fuchsia'],
		['FUCHSIA PINK',                  "\e[38;2;255;119;255m",  'Fuchsia pink'],
		['FULVOUS',                       "\e[38;2;228;132;0m",    'Fulvous'],
		['FUZZY WUZZY',                   "\e[38;2;204;102;102m",  'Fuzzy Wuzzy'],
		['GAINSBORO',                     "\e[38;2;220;220;220m",  'Gainsboro'],
		['GAMBOGE',                       "\e[38;2;228;155;15m",   'Gamboge'],
		['GHOST WHITE',                   "\e[38;2;248;248;255m",  'Ghost white'],
		['GINGER',                        "\e[38;2;176;101;0m",    'Ginger'],
		['GLAUCOUS',                      "\e[38;2;96;130;182m",   'Glaucous'],
		['GLITTER',                       "\e[38;2;230;232;250m",  'Glitter'],
		['GOLD',                          "\e[38;2;255;215;0m",    'Gold'],
		['GOLDEN BROWN',                  "\e[38;2;153;101;21m",   'Golden brown'],
		['GOLDEN POPPY',                  "\e[38;2;252;194;0m",    'Golden poppy'],
		['GOLDEN YELLOW',                 "\e[38;2;255;223;0m",    'Golden yellow'],
		['GOLDENROD',                     "\e[38;2;218;165;32m",   'Goldenrod'],
		['GRANNY SMITH APPLE',            "\e[38;2;168;228;160m",  'Granny Smith Apple'],
		['GRAY',                          "\e[38;2;128;128;128m",  'Gray'],
		['GRAY ASPARAGUS',                "\e[38;2;70;89;69m",     'Gray asparagus'],
		['GREEN BLUE',                    "\e[38;2;17;100;180m",   'Green Blue'],
		['GREEN YELLOW',                  "\e[38;2;173;255;47m",   'Green yellow'],
		['GRULLO',                        "\e[38;2;169;154;134m",  'Grullo'],
		['GUPPIE GREEN',                  "\e[38;2;0;255;127m",    'Guppie green'],
		['HALAYà úBE',                    "\e[38;2;102;56;84m",    'Halayà úbe'],
		['HAN BLUE',                      "\e[38;2;68;108;207m",   'Han blue'],
		['HAN PURPLE',                    "\e[38;2;82;24;250m",    'Han purple'],
		['HANSA YELLOW',                  "\e[38;2;233;214;107m",  'Hansa yellow'],
		['HARLEQUIN',                     "\e[38;2;63;255;0m",     'Harlequin'],
		['HARVARD CRIMSON',               "\e[38;2;201;0;22m",     'Harvard crimson'],
		['HARVEST GOLD',                  "\e[38;2;218;145;0m",    'Harvest Gold'],
		['HEART GOLD',                    "\e[38;2;128;128;0m",    'Heart Gold'],
		['HELIOTROPE',                    "\e[38;2;223;115;255m",  'Heliotrope'],
		['HOLLYWOOD CERISE',              "\e[38;2;244;0;161m",    'Hollywood cerise'],
		['HONEYDEW',                      "\e[38;2;240;255;240m",  'Honeydew'],
		['HOOKER GREEN',                  "\e[38;2;73;121;107m",   'Hooker green'],
		['HOT MAGENTA',                   "\e[38;2;255;29;206m",   'Hot magenta'],
		['HOT PINK',                      "\e[38;2;255;105;180m",  'Hot pink'],
		['HUNTER GREEN',                  "\e[38;2;53;94;59m",     'Hunter green'],
		['ICTERINE',                      "\e[38;2;252;247;94m",   'Icterine'],
		['INCHWORM',                      "\e[38;2;178;236;93m",   'Inchworm'],
		['INDIA GREEN',                   "\e[38;2;19;136;8m",     'India green'],
		['INDIAN RED',                    "\e[38;2;205;92;92m",    'Indian red'],
		['INDIAN YELLOW',                 "\e[38;2;227;168;87m",   'Indian yellow'],
		['INDIGO',                        "\e[38;2;75;0;130m",     'Indigo'],
		['INTERNATIONAL KLEIN BLUE',      "\e[38;2;0;47;167m",     'International Klein Blue'],
		['INTERNATIONAL ORANGE',          "\e[38;2;255;79;0m",     'International orange'],
		['IRIS',                          "\e[38;2;90;79;207m",    'Iris'],
		['ISABELLINE',                    "\e[38;2;244;240;236m",  'Isabelline'],
		['ISLAMIC GREEN',                 "\e[38;2;0;144;0m",      'Islamic green'],
		['IVORY',                         "\e[38;2;255;255;240m",  'Ivory'],
		['JADE',                          "\e[38;2;0;168;107m",    'Jade'],
		['JASMINE',                       "\e[38;2;248;222;126m",  'Jasmine'],
		['JASPER',                        "\e[38;2;215;59;62m",    'Jasper'],
		['JAZZBERRY JAM',                 "\e[38;2;165;11;94m",    'Jazzberry jam'],
		['JONQUIL',                       "\e[38;2;250;218;94m",   'Jonquil'],
		['JUNE BUD',                      "\e[38;2;189;218;87m",   'June bud'],
		['JUNGLE GREEN',                  "\e[38;2;41;171;135m",   'Jungle green'],
		['KU CRIMSON',                    "\e[38;2;232;0;13m",     'KU Crimson'],
		['KELLY GREEN',                   "\e[38;2;76;187;23m",    'Kelly green'],
		['KHAKI',                         "\e[38;2;195;176;145m",  'Khaki'],
		['LA SALLE GREEN',                "\e[38;2;8;120;48m",     'La Salle Green'],
		['LANGUID LAVENDER',              "\e[38;2;214;202;221m",  'Languid lavender'],
		['LAPIS LAZULI',                  "\e[38;2;38;97;156m",    'Lapis lazuli'],
		['LASER LEMON',                   "\e[38;2;254;254;34m",   'Laser Lemon'],
		['LAUREL GREEN',                  "\e[38;2;169;186;157m",  'Laurel green'],
		['LAVA',                          "\e[38;2;207;16;32m",    'Lava'],
		['LAVENDER',                      "\e[38;2;230;230;250m",  'Lavender'],
		['LAVENDER BLUE',                 "\e[38;2;204;204;255m",  'Lavender blue'],
		['LAVENDER BLUSH',                "\e[38;2;255;240;245m",  'Lavender blush'],
		['LAVENDER GRAY',                 "\e[38;2;196;195;208m",  'Lavender gray'],
		['LAVENDER INDIGO',               "\e[38;2;148;87;235m",   'Lavender indigo'],
		['LAVENDER MAGENTA',              "\e[38;2;238;130;238m",  'Lavender magenta'],
		['LAVENDER MIST',                 "\e[38;2;230;230;250m",  'Lavender mist'],
		['LAVENDER PINK',                 "\e[38;2;251;174;210m",  'Lavender pink'],
		['LAVENDER PURPLE',               "\e[38;2;150;123;182m",  'Lavender purple'],
		['LAVENDER ROSE',                 "\e[38;2;251;160;227m",  'Lavender rose'],
		['LAWN GREEN',                    "\e[38;2;124;252;0m",    'Lawn green'],
		['LEMON',                         "\e[38;2;255;247;0m",    'Lemon'],
		['LEMON YELLOW',                  "\e[38;2;255;244;79m",   'Lemon Yellow'],
		['LEMON CHIFFON',                 "\e[38;2;255;250;205m",  'Lemon chiffon'],
		['LEMON LIME',                    "\e[38;2;191;255;0m",    'Lemon lime'],
		['LIGHT CRIMSON',                 "\e[38;2;245;105;145m",  'Light Crimson'],
		['LIGHT THULIAN PINK',            "\e[38;2;230;143;172m",  'Light Thulian pink'],
		['LIGHT APRICOT',                 "\e[38;2;253;213;177m",  'Light apricot'],
		['LIGHT BLUE',                    "\e[38;2;173;216;230m",  'Light blue'],
		['LIGHT BROWN',                   "\e[38;2;181;101;29m",   'Light brown'],
		['LIGHT CARMINE PINK',            "\e[38;2;230;103;113m",  'Light carmine pink'],
		['LIGHT CORAL',                   "\e[38;2;240;128;128m",  'Light coral'],
		['LIGHT CORNFLOWER BLUE',         "\e[38;2;147;204;234m",  'Light cornflower blue'],
		['LIGHT CYAN',                    "\e[38;2;224;255;255m",  'Light cyan'],
		['LIGHT FUCHSIA PINK',            "\e[38;2;249;132;239m",  'Light fuchsia pink'],
		['LIGHT GOLDENROD YELLOW',        "\e[38;2;250;250;210m",  'Light goldenrod yellow'],
		['LIGHT GRAY',                    "\e[38;2;211;211;211m",  'Light gray'],
		['LIGHT GREEN',                   "\e[38;2;144;238;144m",  'Light green'],
		['LIGHT KHAKI',                   "\e[38;2;240;230;140m",  'Light khaki'],
		['LIGHT PASTEL PURPLE',           "\e[38;2;177;156;217m",  'Light pastel purple'],
		['LIGHT PINK',                    "\e[38;2;255;182;193m",  'Light pink'],
		['LIGHT SALMON',                  "\e[38;2;255;160;122m",  'Light salmon'],
		['LIGHT SALMON PINK',             "\e[38;2;255;153;153m",  'Light salmon pink'],
		['LIGHT SEA GREEN',               "\e[38;2;32;178;170m",   'Light sea green'],
		['LIGHT SKY BLUE',                "\e[38;2;135;206;250m",  'Light sky blue'],
		['LIGHT SLATE GRAY',              "\e[38;2;119;136;153m",  'Light slate gray'],
		['LIGHT TAUPE',                   "\e[38;2;179;139;109m",  'Light taupe'],
		['LIGHT YELLOW',                  "\e[38;2;255;255;237m",  'Light yellow'],
		['LILAC',                         "\e[38;2;200;162;200m",  'Lilac'],
		['LIME',                          "\e[38;2;191;255;0m",    'Lime'],
		['LIME GREEN',                    "\e[38;2;50;205;50m",    'Lime green'],
		['LINCOLN GREEN',                 "\e[38;2;25;89;5m",      'Lincoln green'],
		['LINEN',                         "\e[38;2;250;240;230m",  'Linen'],
		['LION',                          "\e[38;2;193;154;107m",  'Lion'],
		['LIVER',                         "\e[38;2;83;75;79m",     'Liver'],
		['LUST',                          "\e[38;2;230;32;32m",    'Lust'],
		['MSU GREEN',                     "\e[38;2;24;69;59m",     'MSU Green'],
		['MACARONI AND CHEESE',           "\e[38;2;255;189;136m",  'Macaroni and Cheese'],
		['MAGIC MINT',                    "\e[38;2;170;240;209m",  'Magic mint'],
		['MAGNOLIA',                      "\e[38;2;248;244;255m",  'Magnolia'],
		['MAHOGANY',                      "\e[38;2;192;64;0m",     'Mahogany'],
		['MAIZE',                         "\e[38;2;251;236;93m",   'Maize'],
		['MAJORELLE BLUE',                "\e[38;2;96;80;220m",    'Majorelle Blue'],
		['MALACHITE',                     "\e[38;2;11;218;81m",    'Malachite'],
		['MANATEE',                       "\e[38;2;151;154;170m",  'Manatee'],
		['MANGO TANGO',                   "\e[38;2;255;130;67m",   'Mango Tango'],
		['MANTIS',                        "\e[38;2;116;195;101m",  'Mantis'],
		['MAROON',                        "\e[38;2;128;0;0m",      'Maroon'],
		['MAUVE',                         "\e[38;2;224;176;255m",  'Mauve'],
		['MAUVE TAUPE',                   "\e[38;2;145;95;109m",   'Mauve taupe'],
		['MAUVELOUS',                     "\e[38;2;239;152;170m",  'Mauvelous'],
		['MAYA BLUE',                     "\e[38;2;115;194;251m",  'Maya blue'],
		['MEAT BROWN',                    "\e[38;2;229;183;59m",   'Meat brown'],
		['MEDIUM PERSIAN BLUE',           "\e[38;2;0;103;165m",    'Medium Persian blue'],
		['MEDIUM AQUAMARINE',             "\e[38;2;102;221;170m",  'Medium aquamarine'],
		['MEDIUM BLUE',                   "\e[38;2;0;0;205m",      'Medium blue'],
		['MEDIUM CANDY APPLE RED',        "\e[38;2;226;6;44m",     'Medium candy apple red'],
		['MEDIUM CARMINE',                "\e[38;2;175;64;53m",    'Medium carmine'],
		['MEDIUM CHAMPAGNE',              "\e[38;2;243;229;171m",  'Medium champagne'],
		['MEDIUM ELECTRIC BLUE',          "\e[38;2;3;80;150m",     'Medium electric blue'],
		['MEDIUM JUNGLE GREEN',           "\e[38;2;28;53;45m",     'Medium jungle green'],
		['MEDIUM LAVENDER MAGENTA',       "\e[38;2;221;160;221m",  'Medium lavender magenta'],
		['MEDIUM ORCHID',                 "\e[38;2;186;85;211m",   'Medium orchid'],
		['MEDIUM PURPLE',                 "\e[38;2;147;112;219m",  'Medium purple'],
		['MEDIUM RED VIOLET',             "\e[38;2;187;51;133m",   'Medium red violet'],
		['MEDIUM SEA GREEN',              "\e[38;2;60;179;113m",   'Medium sea green'],
		['MEDIUM SLATE BLUE',             "\e[38;2;123;104;238m",  'Medium slate blue'],
		['MEDIUM SPRING BUD',             "\e[38;2;201;220;135m",  'Medium spring bud'],
		['MEDIUM SPRING GREEN',           "\e[38;2;0;250;154m",    'Medium spring green'],
		['MEDIUM TAUPE',                  "\e[38;2;103;76;71m",    'Medium taupe'],
		['MEDIUM TEAL BLUE',              "\e[38;2;0;84;180m",     'Medium teal blue'],
		['MEDIUM TURQUOISE',              "\e[38;2;72;209;204m",   'Medium turquoise'],
		['MEDIUM VIOLET RED',             "\e[38;2;199;21;133m",   'Medium violet red'],
		['MELON',                         "\e[38;2;253;188;180m",  'Melon'],
		['MIDNIGHT BLUE',                 "\e[38;2;25;25;112m",    'Midnight blue'],
		['MIDNIGHT GREEN',                "\e[38;2;0;73;83m",      'Midnight green'],
		['MIKADO YELLOW',                 "\e[38;2;255;196;12m",   'Mikado yellow'],
		['MINT',                          "\e[38;2;62;180;137m",   'Mint'],
		['MINT CREAM',                    "\e[38;2;245;255;250m",  'Mint cream'],
		['MINT GREEN',                    "\e[38;2;152;255;152m",  'Mint green'],
		['MISTY ROSE',                    "\e[38;2;255;228;225m",  'Misty rose'],
		['MOCCASIN',                      "\e[38;2;250;235;215m",  'Moccasin'],
		['MODE BEIGE',                    "\e[38;2;150;113;23m",   'Mode beige'],
		['MOONSTONE BLUE',                "\e[38;2;115;169;194m",  'Moonstone blue'],
		['MORDANT RED 19',                "\e[38;2;174;12;0m",     'Mordant red 19'],
		['MOSS GREEN',                    "\e[38;2;173;223;173m",  'Moss green'],
		['MOUNTAIN MEADOW',               "\e[38;2;48;186;143m",   'Mountain Meadow'],
		['MOUNTBATTEN PINK',              "\e[38;2;153;122;141m",  'Mountbatten pink'],
		['MULBERRY',                      "\e[38;2;197;75;140m",   'Mulberry'],
		['MUNSELL',                       "\e[38;2;242;243;244m",  'Munsell'],
		['MUSTARD',                       "\e[38;2;255;219;88m",   'Mustard'],
		['MYRTLE',                        "\e[38;2;33;66;30m",     'Myrtle'],
		['NADESHIKO PINK',                "\e[38;2;246;173;198m",  'Nadeshiko pink'],
		['NAPIER GREEN',                  "\e[38;2;42;128;0m",     'Napier green'],
		['NAPLES YELLOW',                 "\e[38;2;250;218;94m",   'Naples yellow'],
		['NAVAJO WHITE',                  "\e[38;2;255;222;173m",  'Navajo white'],
		['NAVY BLUE',                     "\e[38;2;0;0;128m",      'Navy blue'],
		['NEON CARROT',                   "\e[38;2;255;163;67m",   'Neon Carrot'],
		['NEON FUCHSIA',                  "\e[38;2;254;89;194m",   'Neon fuchsia'],
		['NEON GREEN',                    "\e[38;2;57;255;20m",    'Neon green'],
		['NON-PHOTO BLUE',                "\e[38;2;164;221;237m",  'Non-photo blue'],
		['NORTH TEXAS GREEN',             "\e[38;2;5;144;51m",     'North Texas Green'],
		['OCEAN BOAT BLUE',               "\e[38;2;0;119;190m",    'Ocean Boat Blue'],
		['OCHRE',                         "\e[38;2;204;119;34m",   'Ochre'],
		['OFFICE GREEN',                  "\e[38;2;0;128;0m",      'Office green'],
		['OLD GOLD',                      "\e[38;2;207;181;59m",   'Old gold'],
		['OLD LACE',                      "\e[38;2;253;245;230m",  'Old lace'],
		['OLD LAVENDER',                  "\e[38;2;121;104;120m",  'Old lavender'],
		['OLD MAUVE',                     "\e[38;2;103;49;71m",    'Old mauve'],
		['OLD ROSE',                      "\e[38;2;192;128;129m",  'Old rose'],
		['OLIVE',                         "\e[38;2;128;128;0m",    'Olive'],
		['OLIVE DRAB',                    "\e[38;2;107;142;35m",   'Olive Drab'],
		['OLIVE GREEN',                   "\e[38;2;186;184;108m",  'Olive Green'],
		['OLIVINE',                       "\e[38;2;154;185;115m",  'Olivine'],
		['ONYX',                          "\e[38;2;15;15;15m",     'Onyx'],
		['OPERA MAUVE',                   "\e[38;2;183;132;167m",  'Opera mauve'],
		['ORANGE',                        "\e[38;2;255;165;0m",    'Orange'],
		['ORANGE YELLOW',                 "\e[38;2;248;213;104m",  'Orange Yellow'],
		['ORANGE PEEL',                   "\e[38;2;255;159;0m",    'Orange peel'],
		['ORANGE RED',                    "\e[38;2;255;69;0m",     'Orange red'],
		['ORCHID',                        "\e[38;2;218;112;214m",  'Orchid'],
		['OTTER BROWN',                   "\e[38;2;101;67;33m",    'Otter brown'],
		['OUTER SPACE',                   "\e[38;2;65;74;76m",     'Outer Space'],
		['OUTRAGEOUS ORANGE',             "\e[38;2;255;110;74m",   'Outrageous Orange'],
		['OXFORD BLUE',                   "\e[38;2;0;33;71m",      'Oxford Blue'],
		['PACIFIC BLUE',                  "\e[38;2;28;169;201m",   'Pacific Blue'],
		['PAKISTAN GREEN',                "\e[38;2;0;102;0m",      'Pakistan green'],
		['PALATINATE BLUE',               "\e[38;2;39;59;226m",    'Palatinate blue'],
		['PALATINATE PURPLE',             "\e[38;2;104;40;96m",    'Palatinate purple'],
		['PALE AQUA',                     "\e[38;2;188;212;230m",  'Pale aqua'],
		['PALE BLUE',                     "\e[38;2;175;238;238m",  'Pale blue'],
		['PALE BROWN',                    "\e[38;2;152;118;84m",   'Pale brown'],
		['PALE CARMINE',                  "\e[38;2;175;64;53m",    'Pale carmine'],
		['PALE CERULEAN',                 "\e[38;2;155;196;226m",  'Pale cerulean'],
		['PALE CHESTNUT',                 "\e[38;2;221;173;175m",  'Pale chestnut'],
		['PALE COPPER',                   "\e[38;2;218;138;103m",  'Pale copper'],
		['PALE CORNFLOWER BLUE',          "\e[38;2;171;205;239m",  'Pale cornflower blue'],
		['PALE GOLD',                     "\e[38;2;230;190;138m",  'Pale gold'],
		['PALE GOLDENROD',                "\e[38;2;238;232;170m",  'Pale goldenrod'],
		['PALE GREEN',                    "\e[38;2;152;251;152m",  'Pale green'],
		['PALE LAVENDER',                 "\e[38;2;220;208;255m",  'Pale lavender'],
		['PALE MAGENTA',                  "\e[38;2;249;132;229m",  'Pale magenta'],
		['PALE PINK',                     "\e[38;2;250;218;221m",  'Pale pink'],
		['PALE PLUM',                     "\e[38;2;221;160;221m",  'Pale plum'],
		['PALE RED VIOLET',               "\e[38;2;219;112;147m",  'Pale red violet'],
		['PALE ROBIN EGG BLUE',           "\e[38;2;150;222;209m",  'Pale robin egg blue'],
		['PALE SILVER',                   "\e[38;2;201;192;187m",  'Pale silver'],
		['PALE SPRING BUD',               "\e[38;2;236;235;189m",  'Pale spring bud'],
		['PALE TAUPE',                    "\e[38;2;188;152;126m",  'Pale taupe'],
		['PALE VIOLET RED',               "\e[38;2;219;112;147m",  'Pale violet red'],
		['PANSY PURPLE',                  "\e[38;2;120;24;74m",    'Pansy purple'],
		['PAPAYA WHIP',                   "\e[38;2;255;239;213m",  'Papaya whip'],
		['PARIS GREEN',                   "\e[38;2;80;200;120m",   'Paris Green'],
		['PASTEL BLUE',                   "\e[38;2;174;198;207m",  'Pastel blue'],
		['PASTEL BROWN',                  "\e[38;2;131;105;83m",   'Pastel brown'],
		['PASTEL GRAY',                   "\e[38;2;207;207;196m",  'Pastel gray'],
		['PASTEL GREEN',                  "\e[38;2;119;221;119m",  'Pastel green'],
		['PASTEL MAGENTA',                "\e[38;2;244;154;194m",  'Pastel magenta'],
		['PASTEL ORANGE',                 "\e[38;2;255;179;71m",   'Pastel orange'],
		['PASTEL PINK',                   "\e[38;2;255;209;220m",  'Pastel pink'],
		['PASTEL PURPLE',                 "\e[38;2;179;158;181m",  'Pastel purple'],
		['PASTEL RED',                    "\e[38;2;255;105;97m",   'Pastel red'],
		['PASTEL VIOLET',                 "\e[38;2;203;153;201m",  'Pastel violet'],
		['PASTEL YELLOW',                 "\e[38;2;253;253;150m",  'Pastel yellow'],
		['PATRIARCH',                     "\e[38;2;128;0;128m",    'Patriarch'],
		['PAYNE GREY',                    "\e[38;2;83;104;120m",   'Payne grey'],
		['PEACH',                         "\e[38;2;255;229;180m",  'Peach'],
		['PEACH PUFF',                    "\e[38;2;255;218;185m",  'Peach puff'],
		['PEACH YELLOW',                  "\e[38;2;250;223;173m",  'Peach yellow'],
		['PEAR',                          "\e[38;2;209;226;49m",   'Pear'],
		['PEARL',                         "\e[38;2;234;224;200m",  'Pearl'],
		['PEARL AQUA',                    "\e[38;2;136;216;192m",  'Pearl Aqua'],
		['PERIDOT',                       "\e[38;2;230;226;0m",    'Peridot'],
		['PERIWINKLE',                    "\e[38;2;204;204;255m",  'Periwinkle'],
		['PERSIAN BLUE',                  "\e[38;2;28;57;187m",    'Persian blue'],
		['PERSIAN INDIGO',                "\e[38;2;50;18;122m",    'Persian indigo'],
		['PERSIAN ORANGE',                "\e[38;2;217;144;88m",   'Persian orange'],
		['PERSIAN PINK',                  "\e[38;2;247;127;190m",  'Persian pink'],
		['PERSIAN PLUM',                  "\e[38;2;112;28;28m",    'Persian plum'],
		['PERSIAN RED',                   "\e[38;2;204;51;51m",    'Persian red'],
		['PERSIAN ROSE',                  "\e[38;2;254;40;162m",   'Persian rose'],
		['PHLOX',                         "\e[38;2;223;0;255m",    'Phlox'],
		['PHTHALO BLUE',                  "\e[38;2;0;15;137m",     'Phthalo blue'],
		['PHTHALO GREEN',                 "\e[38;2;18;53;36m",     'Phthalo green'],
		['PIGGY PINK',                    "\e[38;2;253;221;230m",  'Piggy pink'],
		['PINE GREEN',                    "\e[38;2;1;121;111m",    'Pine green'],
		['PINK FLAMINGO',                 "\e[38;2;252;116;253m",  'Pink Flamingo'],
		['PINK SHERBET',                  "\e[38;2;247;143;167m",  'Pink Sherbet'],
		['PINK PEARL',                    "\e[38;2;231;172;207m",  'Pink pearl'],
		['PISTACHIO',                     "\e[38;2;147;197;114m",  'Pistachio'],
		['PLATINUM',                      "\e[38;2;229;228;226m",  'Platinum'],
		['PLUM',                          "\e[38;2;221;160;221m",  'Plum'],
		['PORTLAND ORANGE',               "\e[38;2;255;90;54m",    'Portland Orange'],
		['POWDER BLUE',                   "\e[38;2;176;224;230m",  'Powder blue'],
		['PRINCETON ORANGE',              "\e[38;2;255;143;0m",    'Princeton orange'],
		['PRUSSIAN BLUE',                 "\e[38;2;0;49;83m",      'Prussian blue'],
		['PSYCHEDELIC PURPLE',            "\e[38;2;223;0;255m",    'Psychedelic purple'],
		['PUCE',                          "\e[38;2;204;136;153m",  'Puce'],
		['PUMPKIN',                       "\e[38;2;255;117;24m",   'Pumpkin'],
		['PURPLE',                        "\e[38;2;128;0;128m",    'Purple'],
		['PURPLE HEART',                  "\e[38;2;105;53;156m",   'Purple Heart'],
		['PURPLE MOUNTAIN\'S MAJESTY',    "\e[38;2;157;129;186m",  'Purple Mountain\'s Majesty'],
		['PURPLE MOUNTAIN MAJESTY',       "\e[38;2;150;120;182m",  'Purple mountain majesty'],
		['PURPLE PIZZAZZ',                "\e[38;2;254;78;218m",   'Purple pizzazz'],
		['PURPLE TAUPE',                  "\e[38;2;80;64;77m",     'Purple taupe'],
		['RACKLEY',                       "\e[38;2;93;138;168m",   'Rackley'],
		['RADICAL RED',                   "\e[38;2;255;53;94m",    'Radical Red'],
		['RASPBERRY',                     "\e[38;2;227;11;93m",    'Raspberry'],
		['RASPBERRY GLACE',               "\e[38;2;145;95;109m",   'Raspberry glace'],
		['RASPBERRY PINK',                "\e[38;2;226;80;152m",   'Raspberry pink'],
		['RASPBERRY ROSE',                "\e[38;2;179;68;108m",   'Raspberry rose'],
		['RAW SIENNA',                    "\e[38;2;214;138;89m",   'Raw Sienna'],
		['RAZZLE DAZZLE ROSE',            "\e[38;2;255;51;204m",   'Razzle dazzle rose'],
		['RAZZMATAZZ',                    "\e[38;2;227;37;107m",   'Razzmatazz'],
		['RED ORANGE',                    "\e[38;2;255;83;73m",    'Red Orange'],
		['RED BROWN',                     "\e[38;2;165;42;42m",    'Red brown'],
		['RED VIOLET',                    "\e[38;2;199;21;133m",   'Red violet'],
		['RICH BLACK',                    "\e[38;2;0;64;64m",      'Rich black'],
		['RICH CARMINE',                  "\e[38;2;215;0;64m",     'Rich carmine'],
		['RICH ELECTRIC BLUE',            "\e[38;2;8;146;208m",    'Rich electric blue'],
		['RICH LILAC',                    "\e[38;2;182;102;210m",  'Rich lilac'],
		['RICH MAROON',                   "\e[38;2;176;48;96m",    'Rich maroon'],
		['RIFLE GREEN',                   "\e[38;2;65;72;51m",     'Rifle green'],
		['ROBIN\'S EGG BLUE',             "\e[38;2;31;206;203m",   'Robin\'s Egg Blue'],
		['ROSE',                          "\e[38;2;255;0;127m",    'Rose'],
		['ROSE BONBON',                   "\e[38;2;249;66;158m",   'Rose bonbon'],
		['ROSE EBONY',                    "\e[38;2;103;72;70m",    'Rose ebony'],
		['ROSE GOLD',                     "\e[38;2;183;110;121m",  'Rose gold'],
		['ROSE MADDER',                   "\e[38;2;227;38;54m",    'Rose madder'],
		['ROSE PINK',                     "\e[38;2;255;102;204m",  'Rose pink'],
		['ROSE QUARTZ',                   "\e[38;2;170;152;169m",  'Rose quartz'],
		['ROSE TAUPE',                    "\e[38;2;144;93;93m",    'Rose taupe'],
		['ROSE VALE',                     "\e[38;2;171;78;82m",    'Rose vale'],
		['ROSEWOOD',                      "\e[38;2;101;0;11m",     'Rosewood'],
		['ROSSO CORSA',                   "\e[38;2;212;0;0m",      'Rosso corsa'],
		['ROSY BROWN',                    "\e[38;2;188;143;143m",  'Rosy brown'],
		['ROYAL AZURE',                   "\e[38;2;0;56;168m",     'Royal azure'],
		['ROYAL BLUE',                    "\e[38;2;65;105;225m",   'Royal blue'],
		['ROYAL FUCHSIA',                 "\e[38;2;202;44;146m",   'Royal fuchsia'],
		['ROYAL PURPLE',                  "\e[38;2;120;81;169m",   'Royal purple'],
		['RUBY',                          "\e[38;2;224;17;95m",    'Ruby'],
		['RUDDY',                         "\e[38;2;255;0;40m",     'Ruddy'],
		['RUDDY BROWN',                   "\e[38;2;187;101;40m",   'Ruddy brown'],
		['RUDDY PINK',                    "\e[38;2;225;142;150m",  'Ruddy pink'],
		['RUFOUS',                        "\e[38;2;168;28;7m",     'Rufous'],
		['RUSSET',                        "\e[38;2;128;70;27m",    'Russet'],
		['RUST',                          "\e[38;2;183;65;14m",    'Rust'],
		['SACRAMENTO STATE GREEN',        "\e[38;2;0;86;63m",      'Sacramento State green'],
		['SADDLE BROWN',                  "\e[38;2;139;69;19m",    'Saddle brown'],
		['SAFETY ORANGE',                 "\e[38;2;255;103;0m",    'Safety orange'],
		['SAFFRON',                       "\e[38;2;244;196;48m",   'Saffron'],
		['SAINT PATRICK BLUE',            "\e[38;2;35;41;122m",    'Saint Patrick Blue'],
		['SALMON',                        "\e[38;2;255;140;105m",  'Salmon'],
		['SALMON PINK',                   "\e[38;2;255;145;164m",  'Salmon pink'],
		['SAND',                          "\e[38;2;194;178;128m",  'Sand'],
		['SAND DUNE',                     "\e[38;2;150;113;23m",   'Sand dune'],
		['SANDSTORM',                     "\e[38;2;236;213;64m",   'Sandstorm'],
		['SANDY BROWN',                   "\e[38;2;244;164;96m",   'Sandy brown'],
		['SANDY TAUPE',                   "\e[38;2;150;113;23m",   'Sandy taupe'],
		['SAP GREEN',                     "\e[38;2;80;125;42m",    'Sap green'],
		['SAPPHIRE',                      "\e[38;2;15;82;186m",    'Sapphire'],
		['SATIN SHEEN GOLD',              "\e[38;2;203;161;53m",   'Satin sheen gold'],
		['SCARLET',                       "\e[38;2;255;36;0m",     'Scarlet'],
		['SCHOOL BUS YELLOW',             "\e[38;2;255;216;0m",    'School bus yellow'],
		['SCREAMIN GREEN',                "\e[38;2;118;255;122m",  'Screamin Green'],
		['SEA BLUE',                      "\e[38;2;0;105;148m",    'Sea blue'],
		['SEA GREEN',                     "\e[38;2;46;139;87m",    'Sea green'],
		['SEAL BROWN',                    "\e[38;2;50;20;20m",     'Seal brown'],
		['SEASHELL',                      "\e[38;2;255;245;238m",  'Seashell'],
		['SELECTIVE YELLOW',              "\e[38;2;255;186;0m",    'Selective yellow'],
		['SEPIA',                         "\e[38;2;112;66;20m",    'Sepia'],
		['SHADOW',                        "\e[38;2;138;121;93m",   'Shadow'],
		['SHAMROCK',                      "\e[38;2;69;206;162m",   'Shamrock'],
		['SHAMROCK GREEN',                "\e[38;2;0;158;96m",     'Shamrock green'],
		['SHOCKING PINK',                 "\e[38;2;252;15;192m",   'Shocking pink'],
		['SIENNA',                        "\e[38;2;136;45;23m",    'Sienna'],
		['SILVER',                        "\e[38;2;192;192;192m",  'Silver'],
		['SINOPIA',                       "\e[38;2;203;65;11m",    'Sinopia'],
		['SKOBELOFF',                     "\e[38;2;0;116;116m",    'Skobeloff'],
		['SKY BLUE',                      "\e[38;2;135;206;235m",  'Sky blue'],
		['SKY MAGENTA',                   "\e[38;2;207;113;175m",  'Sky magenta'],
		['SLATE BLUE',                    "\e[38;2;106;90;205m",   'Slate blue'],
		['SLATE GRAY',                    "\e[38;2;112;128;144m",  'Slate gray'],
		['SMALT',                         "\e[38;2;0;51;153m",     'Smalt'],
		['SMOKEY TOPAZ',                  "\e[38;2;147;61;65m",    'Smokey topaz'],
		['SMOKY BLACK',                   "\e[38;2;16;12;8m",      'Smoky black'],
		['SNOW',                          "\e[38;2;255;250;250m",  'Snow'],
		['SPIRO DISCO BALL',              "\e[38;2;15;192;252m",   'Spiro Disco Ball'],
		['SPRING BUD',                    "\e[38;2;167;252;0m",    'Spring bud'],
		['SPRING GREEN',                  "\e[38;2;0;255;127m",    'Spring green'],
		['STEEL BLUE',                    "\e[38;2;70;130;180m",   'Steel blue'],
		['STIL DE GRAIN YELLOW',          "\e[38;2;250;218;94m",   'Stil de grain yellow'],
		['STIZZA',                        "\e[38;2;153;0;0m",      'Stizza'],
		['STORMCLOUD',                    "\e[38;2;0;128;128m",    'Stormcloud'],
		['STRAW',                         "\e[38;2;228;217;111m",  'Straw'],
		['SUNGLOW',                       "\e[38;2;255;204;51m",   'Sunglow'],
		['SUNSET',                        "\e[38;2;250;214;165m",  'Sunset'],
		['SUNSET ORANGE',                 "\e[38;2;253;94;83m",    'Sunset Orange'],
		['TAN',                           "\e[38;2;210;180;140m",  'Tan'],
		['TANGELO',                       "\e[38;2;249;77;0m",     'Tangelo'],
		['TANGERINE',                     "\e[38;2;242;133;0m",    'Tangerine'],
		['TANGERINE YELLOW',              "\e[38;2;255;204;0m",    'Tangerine yellow'],
		['TAUPE',                         "\e[38;2;72;60;50m",     'Taupe'],
		['TAUPE GRAY',                    "\e[38;2;139;133;137m",  'Taupe gray'],
		['TAWNY',                         "\e[38;2;205;87;0m",     'Tawny'],
		['TEA GREEN',                     "\e[38;2;208;240;192m",  'Tea green'],
		['TEA ROSE',                      "\e[38;2;244;194;194m",  'Tea rose'],
		['TEAL',                          "\e[38;2;0;128;128m",    'Teal'],
		['TEAL BLUE',                     "\e[38;2;54;117;136m",   'Teal blue'],
		['TEAL GREEN',                    "\e[38;2;0;109;91m",     'Teal green'],
		['TERRA COTTA',                   "\e[38;2;226;114;91m",   'Terra cotta'],
		['THISTLE',                       "\e[38;2;216;191;216m",  'Thistle'],
		['THULIAN PINK',                  "\e[38;2;222;111;161m",  'Thulian pink'],
		['TICKLE ME PINK',                "\e[38;2;252;137;172m",  'Tickle Me Pink'],
		['TIFFANY BLUE',                  "\e[38;2;10;186;181m",   'Tiffany Blue'],
		['TIGER EYE',                     "\e[38;2;224;141;60m",   'Tiger eye'],
		['TIMBERWOLF',                    "\e[38;2;219;215;210m",  'Timberwolf'],
		['TITANIUM YELLOW',               "\e[38;2;238;230;0m",    'Titanium yellow'],
		['TOMATO',                        "\e[38;2;255;99;71m",    'Tomato'],
		['TOOLBOX',                       "\e[38;2;116;108;192m",  'Toolbox'],
		['TOPAZ',                         "\e[38;2;255;200;124m",  'Topaz'],
		['TRACTOR RED',                   "\e[38;2;253;14;53m",    'Tractor red'],
		['TROLLEY GREY',                  "\e[38;2;128;128;128m",  'Trolley Grey'],
		['TROPICAL RAIN FOREST',          "\e[38;2;0;117;94m",     'Tropical rain forest'],
		['TRUE BLUE',                     "\e[38;2;0;115;207m",    'True Blue'],
		['TUFTS BLUE',                    "\e[38;2;65;125;193m",   'Tufts Blue'],
		['TUMBLEWEED',                    "\e[38;2;222;170;136m",  'Tumbleweed'],
		['TURKISH ROSE',                  "\e[38;2;181;114;129m",  'Turkish rose'],
		['TURQUOISE',                     "\e[38;2;48;213;200m",   'Turquoise'],
		['TURQUOISE BLUE',                "\e[38;2;0;255;239m",    'Turquoise blue'],
		['TURQUOISE GREEN',               "\e[38;2;160;214;180m",  'Turquoise green'],
		['TUSCAN RED',                    "\e[38;2;102;66;77m",    'Tuscan red'],
		['TWILIGHT LAVENDER',             "\e[38;2;138;73;107m",   'Twilight lavender'],
		['TYRIAN PURPLE',                 "\e[38;2;102;2;60m",     'Tyrian purple'],
		['UA BLUE',                       "\e[38;2;0;51;170m",     'UA blue'],
		['UA RED',                        "\e[38;2;217;0;76m",     'UA red'],
		['UCLA BLUE',                     "\e[38;2;83;104;149m",   'UCLA Blue'],
		['UCLA GOLD',                     "\e[38;2;255;179;0m",    'UCLA Gold'],
		['UFO GREEN',                     "\e[38;2;60;208;112m",   'UFO Green'],
		['UP FOREST GREEN',               "\e[38;2;1;68;33m",      'UP Forest green'],
		['UP MAROON',                     "\e[38;2;123;17;19m",    'UP Maroon'],
		['USC CARDINAL',                  "\e[38;2;153;0;0m",      'USC Cardinal'],
		['USC GOLD',                      "\e[38;2;255;204;0m",    'USC Gold'],
		['UBE',                           "\e[38;2;136;120;195m",  'Ube'],
		['ULTRA PINK',                    "\e[38;2;255;111;255m",  'Ultra pink'],
		['ULTRAMARINE',                   "\e[38;2;18;10;143m",    'Ultramarine'],
		['ULTRAMARINE BLUE',              "\e[38;2;65;102;245m",   'Ultramarine blue'],
		['UMBER',                         "\e[38;2;99;81;71m",     'Umber'],
		['UNITED NATIONS BLUE',           "\e[38;2;91;146;229m",   'United Nations blue'],
		['UNIVERSITY OF CALIFORNIA GOLD', "\e[38;2;183;135;39m",   'University of California Gold'],
		['UNMELLOW YELLOW',               "\e[38;2;255;255;102m",  'Unmellow Yellow'],
		['UPSDELL RED',                   "\e[38;2;174;32;41m",    'Upsdell red'],
		['UROBILIN',                      "\e[38;2;225;173;33m",   'Urobilin'],
		['UTAH CRIMSON',                  "\e[38;2;211;0;63m",     'Utah Crimson'],
		['VANILLA',                       "\e[38;2;243;229;171m",  'Vanilla'],
		['VEGAS GOLD',                    "\e[38;2;197;179;88m",   'Vegas gold'],
		['VENETIAN RED',                  "\e[38;2;200;8;21m",     'Venetian red'],
		['VERDIGRIS',                     "\e[38;2;67;179;174m",   'Verdigris'],
		['VERMILION',                     "\e[38;2;227;66;52m",    'Vermilion'],
		['VERONICA',                      "\e[38;2;160;32;240m",   'Veronica'],
		['VIOLET',                        "\e[38;2;238;130;238m",  'Violet'],
		['VIOLET BLUE',                   "\e[38;2;50;74;178m",    'Violet Blue'],
		['VIOLET RED',                    "\e[38;2;247;83;148m",   'Violet Red'],
		['VIRIDIAN',                      "\e[38;2;64;130;109m",   'Viridian'],
		['VIVID AUBURN',                  "\e[38;2;146;39;36m",    'Vivid auburn'],
		['VIVID BURGUNDY',                "\e[38;2;159;29;53m",    'Vivid burgundy'],
		['VIVID CERISE',                  "\e[38;2;218;29;129m",   'Vivid cerise'],
		['VIVID TANGERINE',               "\e[38;2;255;160;137m",  'Vivid tangerine'],
		['VIVID VIOLET',                  "\e[38;2;159;0;255m",    'Vivid violet'],
		['WARM BLACK',                    "\e[38;2;0;66;66m",      'Warm black'],
		['WATERSPOUT',                    "\e[38;2;0;255;255m",    'Waterspout'],
		['WENGE',                         "\e[38;2;100;84;82m",    'Wenge'],
		['WHEAT',                         "\e[38;2;245;222;179m",  'Wheat'],
		['WHITE SMOKE',                   "\e[38;2;245;245;245m",  'White smoke'],
		['WILD STRAWBERRY',               "\e[38;2;255;67;164m",   'Wild Strawberry'],
		['WILD WATERMELON',               "\e[38;2;252;108;133m",  'Wild Watermelon'],
		['WILD BLUE YONDER',              "\e[38;2;162;173;208m",  'Wild blue yonder'],
		['WINE',                          "\e[38;2;114;47;55m",    'Wine'],
		['WISTERIA',                      "\e[38;2;201;160;220m",  'Wisteria'],
		['XANADU',                        "\e[38;2;115;134;120m",  'Xanadu'],
		['YALE BLUE',                     "\e[38;2;15;77;146m",    'Yale Blue'],
		['YELLOW ORANGE',                 "\e[38;2;255;174;66m",   'Yellow Orange'],
		['YELLOW GREEN',                  "\e[38;2;154;205;50m",   'Yellow green'],
		['ZAFFRE',                        "\e[38;2;0;20;168m",     'Zaffre'],
		['ZINNWALDITE BROWN',             "\e[38;2;44;22;8m",      'Zinnwaldite brown'],
	);

	foreach my $count (16 .. 231) {
		push(@fg_extra, ["COLOR $count", "\e[38;5;${count}m", "ANSI 8 bit color $count"]);
	}
	foreach my $gray (232 .. 255) {
		push(@fg_extra, ['GRAY ' . ($gray - 232), "\e[38;5;${gray}m", 'ANSI gray level ' . ($gray - 232)]);
	}

	my $foreground = $pairs_to_map->(
		map { [ $_->[0], $_->[1], $_->[2] ] } @fg16,
		map { [ $_->[0], $_->[1], $_->[2] ] } @fg_extra,
	);

	# Background (base 16 + bright variants)
	my @bg16 = (
		['B_BLACK',          "\e[40m",  'Black'],
		['B_BLUE',           "\e[44m",  'Blue'],
		['B_BRIGHT BLACK',   "\e[100m", 'Bright black'],
		['B_BRIGHT BLUE',    "\e[104m", 'Bright blue'],
		['B_BRIGHT CYAN',    "\e[106m", 'Bright cyan'],
		['B_BRIGHT GREEN',   "\e[102m", 'Bright green'],
		['B_BRIGHT MAGENTA', "\e[105m", 'Bright magenta'],
		['B_BRIGHT RED',     "\e[101m", 'Bright red'],
		['B_BRIGHT WHITE',   "\e[107m", 'Bright white'],
		['B_BRIGHT YELLOW',  "\e[103m", 'Bright yellow'],
		['B_CYAN',           "\e[46m",  'Cyan'],
		['B_DEFAULT',        "\e[49m",  'Default background color'],
		['B_GREEN',          "\e[42m",  'Green'],
		['B_MAGENTA',        "\e[45m",  'Magenta'],
		['B_RED',            "\e[41m",  'Red'],
		['B_WHITE',          "\e[47m",  'White'],
		['B_YELLOW',         "\e[43m",  'Yellow'],
	);
###
	# Derive full background extras from foreground extras by swapping 38 -> 48 in SGR
	my @bg_extra = map {
		my ($name, $code, $desc) = @$_;
		my $bg_code = $code;
		$bg_code =~ s/\[38;/[48;/;
			[ "B_${name}", $bg_code, $desc ]
		} @fg_extra;

		my $background = $pairs_to_map->(
			map { [ $_->[0], $_->[1], $_->[2] ] } @bg16,
			map { [ $_->[0], $_->[1], $_->[2] ] } @bg_extra,
		);

		$self->{'ansi_meta'} = {
			special    => $special,
			clear      => $clear,
			cursor     => $cursor,
			attributes => $attributes,
			foreground => $foreground,
			background => $background,
		};

	$self->{'debug'}->DEBUG(['End ANSI Initialize']);
	return($self);
} ## end sub ansi_initialize

 

# package BBS::Universal::ASCII;

sub ascii_initialize {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start ASCII Initialize']);
    $self->{'ascii_meta'} = {
        'RETURN'    => { 'out' => chr(13),           'unicode' => ' ', 'desc' => 'Carriage Return' },
        'LINEFEED'  => { 'out' => chr(10),           'unicode' => ' ', 'desc' => 'Linefeed' },
        'NEWLINE'   => { 'out' => chr(13) . chr(10), 'unicode' => ' ', 'desc' => 'Newline' },
        'BACKSPACE' => { 'out' => chr(8),            'unicode' => ' ', 'desc' => 'Backspace' },
        'TAB'       => { 'out' => chr(9),            'unicode' => ' ', 'desc' => 'Tab' },
        'DELETE'    => { 'out' => chr(127),          'unicode' => ' ', 'desc' => 'Delete' },
        'CLS'       => { 'out' => chr(12),           'unicode' => ' ', 'desc' => 'Clear Screen (Formfeed)' },
        'CLEAR'     => { 'out' => chr(12),           'unicode' => ' ', 'desc' => 'Clear Screen (Formfeed)' },
        'RING BELL' => { 'out' => chr(7),            'unicode' => ' ', 'desc' => 'Console Bell' },
    };
    $self->{'debug'}->DEBUG(['End ACSII Initialize']);
    return ($self);
} ## end sub ascii_initialize

sub ascii_output {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start ASCII Output']);
    my $mlines = (exists($self->{'USER'}->{'max_rows'})) ? $self->{'USER'}->{'max_rows'} - 3 : 21;
    my $lines  = $mlines;
    if (length($text) > 1) {
        foreach my $string (keys %{ $self->{'ascii_meta'} }) {
            if ($string =~ /CLEAR|CLS/i && ($self->{'sysop'} || $self->{'local_mode'})) {
                my $ch = locate(($self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST')), 1) . cldown;
                $text =~ s/\[\%\s+$string\s+\%\]/$ch/gi;
            } else {
                $text =~ s/\[\%\s+$string\s+\%\]/$self->{'ascii_meta'}->{$string}->{'out'}/gi;
            }
        } ## end foreach my $string (keys %{...})
        while ($text =~ /\[\%\s+HORIZONTAL RULE\s+\%\]/) {
            my $rule = '=' x $self->{'USER'}->{'max_columns'};
            $text =~ s/\[\%\s+HORIZONTAL RULE\s+\%\]/$rule/gs;
        }
    } ## end if (length($text) > 1)
    my $s_len = length($text);
    my $nl    = $self->{'ascii_meta'}->{'NEWLINE'}->{'out'};
    foreach my $count (0 .. $s_len) {
        my $char = substr($text, $count, 1);
        if ($char eq "\n") {
            if ($text !~ /$nl/ && !$self->{'local_mode'}) {    # translate only if the file doesn't have ASCII newlines
                $char = $nl;
            }
            $lines--;
            if ($lines <= 0) {
                $lines = $mlines;
                last unless ($self->scroll($nl));
            }
        } ## end if ($char eq "\n")
        $self->send_char($char);
    } ## end foreach my $count (0 .. $s_len)
    $self->{'debug'}->DEBUG(['End ASCII Output']);
    return (TRUE);
} ## end sub ascii_output

 

# package BBS::Universal::ATASCII;

sub atascii_initialize {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start ATASCII Initialize']);
    $self->{'atascii_meta'} = {
        # Control
        'ESC'                          => { 'out' => chr(27),  'unicode' => '␛', 'desc' => 'Escape', },
        'UP'                           => { 'out' => chr(28),  'unicode' => ' ', 'desc' => 'Move Cursor Up', },
        'DOWN'                         => { 'out' => chr(29),  'unicode' => ' ', 'desc' => 'Move Cursor Down', },
        'LEFT'                         => { 'out' => chr(30),  'unicode' => ' ', 'desc' => 'Move Cursor Left', },
        'RIGHT'                        => { 'out' => chr(31),  'unicode' => ' ', 'desc' => 'Move Cursor Right', },
        'CLEAR'                        => { 'out' => chr(125), 'unicode' => ' ', 'desc' => 'Clear Screen', },
        'BACKSPACE'                    => { 'out' => chr(126), 'unicode' => ' ', 'desc' => 'Backspace', },
        'TAB'                          => { 'out' => chr(127), 'unicode' => ' ', 'desc' => 'Tab', },
        'RETURN'                       => { 'out' => chr(155), 'unicode' => ' ', 'desc' => 'Carriage Return', },
        'DELETE LINE'                  => { 'out' => chr(156), 'unicode' => ' ', 'desc' => 'Delete Line', },
        'INSERT LINE'                  => { 'out' => chr(157), 'unicode' => ' ', 'desc' => 'Insert Line', },
        'CLEAR TAB STOP'               => { 'out' => chr(158), 'unicode' => ' ', 'desc' => 'Clear Tab Stop', },
        'SET TAB STOP'                 => { 'out' => chr(159), 'unicode' => ' ', 'desc' => 'Set Tab Stop', },
        'BUZZER'                       => { 'out' => chr(253), 'unicode' => ' ', 'desc' => 'Console Bell', },
        'RING BELL'                    => { 'out' => chr(253), 'unicode' => ' ', 'desc' => 'Console Bell', },
        'DELETE'                       => { 'out' => chr(254), 'unicode' => ' ', 'desc' => 'Delete', },
        'INSERT'                       => { 'out' => chr(255), 'unicode' => ' ', 'desc' => 'Insert', },

        # Normal

        'HEART'                        => { 'out' => chr(0),   'unicode' => '♥', 'desc' => 'Heart', },
        'VERTICAL BAR MIDDLE LEFT'     => { 'out' => chr(1),   'unicode' => '┣', 'desc' => 'Vertical Bar Middle Left', },
        'RIGHT VERTICAL BAR'           => { 'out' => chr(2),   'unicode' => '🮇', 'desc' => 'Right Vertical Bar', },
        'BOTTOM RIGHT CORNER'          => { 'out' => chr(3),   'unicode' => '┛', 'desc' => 'Bottom Right Corner', },
        'VERTICAL BAR MIDDLE RIGHT'    => { 'out' => chr(4),   'unicode' => '┫', 'desc' => 'Vertical Bar Middle Right', },
        'TOP RIGHT CORNER'             => { 'out' => chr(5),   'unicode' => '┓', 'desc' => 'Top Right Corner', },
        'LARGE FORWARD SLASH'          => { 'out' => chr(6),   'unicode' => '╱', 'desc' => 'Large Forward Slash', },
        'LARGE BACKSLASH'              => { 'out' => chr(7),   'unicode' => '╲', 'desc' => 'Large Backslash', },
        'TOP LEFT WEDGE'               => { 'out' => chr(8),   'unicode' => '◢', 'desc' => 'Top Left Wedge', },
        'BOTTOM RIGHT BOX'             => { 'out' => chr(9),   'unicode' => '▗', 'desc' => 'Bottom Right Box', },
        'TOP RIGHT WEDGE'              => { 'out' => chr(10),  'unicode' => '◣', 'desc' => 'Top Right Wedge', },
        'TOP RIGHT BOX'                => { 'out' => chr(11),  'unicode' => '▝', 'desc' => 'Top Right Box', },
        'TOP LEFT BOX'                 => { 'out' => chr(12),  'unicode' => '▘', 'desc' => 'Top Left Box', },
        'TOP HORIZONTAL BAR'           => { 'out' => chr(13),  'unicode' => '🮂', 'desc' => 'Top Horizontal Bar', },
        'BOTTOM HORIZONTAL BAR'        => { 'out' => chr(14),  'unicode' => '▂', 'desc' => 'Bottom Horizontal Bar', },
        'BOTTOM LEFT BOX'              => { 'out' => chr(15),  'unicode' => '▖', 'desc' => 'Bottom Left Box', },
        'CLUB'                         => { 'out' => chr(16),  'unicode' => '♣', 'desc' => 'Club', },
        'TOP LEFT CORNER'              => { 'out' => chr(17),  'unicode' => '┏', 'desc' => 'Top Left Corner', },
        'HORIZONTAL BAR'               => { 'out' => chr(18),  'unicode' => '━', 'desc' => 'Horizontal Bar', },
        'CROSS BAR'                    => { 'out' => chr(19),  'unicode' => '╋', 'desc' => 'Cross Bar', },
        'CENTER DOT'                   => { 'out' => chr(20),  'unicode' => '⏺', 'desc' => 'Center Dot', },
        'BOTTOM BOX'                   => { 'out' => chr(21),  'unicode' => '▄', 'desc' => 'Bottom Box', },
        'LEFT VERTICAL BAR'            => { 'out' => chr(22),  'unicode' => '▎', 'desc' => 'Left Vertical Bar', },
        'HORIZONTAL BAR MIDDLE TOP'    => { 'out' => chr(23),  'unicode' => '┳', 'desc' => 'Horizontal Bar Middle Top', },
        'HORIZONTAL BAR MIDDLE BOTTOM' => { 'out' => chr(24),  'unicode' => '┻', 'desc' => 'Horizontal Bar Middle Bottom', },
        'LEFT VERTICAL BAR'            => { 'out' => chr(25),  'unicode' => '▌', 'desc' => 'Left Vertical Bar', },
        'BOTTOM LEFT CORNER'           => { 'out' => chr(26),  'unicode' => '┗', 'desc' => 'Botom Left Corner', },
        'UP ARROW'                     => { 'out' => chr(28),  'unicode' => '🡹', 'desc' => 'Up Arrow', },
        'DOWN ARROW'                   => { 'out' => chr(29),  'unicode' => '🡻', 'desc' => 'Down Arrow', },
        'LEFT ARROW'                   => { 'out' => chr(30),  'unicode' => '🡸', 'desc' => 'Left Arrow', },
        'RIGHT ARROW'                  => { 'out' => chr(31),  'unicode' => '🡺', 'desc' => 'Right Arrow', },
        'DIAMOND'                      => { 'out' => chr(96),  'unicode' => '♦', 'desc' => 'Diamond', },
        'SPADE'                        => { 'out' => chr(123), 'unicode' => '♠', 'desc' => 'Spade', },
        'MIDDLE VERTICAL BAR'          => { 'out' => chr(124), 'unicode' => '|', 'desc' => 'Middle Vertical Bar', },
        'BACK ARROW'                   => { 'out' => chr(125), 'unicode' => '🢰', 'desc' => 'Back Arrow', },
        'LEFT TRIANGLE'                => { 'out' => chr(126), 'unicode' => '◀', 'desc' => 'Left Triangle', },
        'RIGHT TRIANGLE'               => { 'out' => chr(127), 'unicode' => '▶', 'desc' => 'Right Triangle', },
    };

    my $inv = "\e[7m";
    my $ni  = "\e[27m";

	my @list = keys %{ $self->{'atascii_meta'} };
    foreach my $name (@list) {
		next if ($name =~ /^(ESC|UP|DOWN|LEFT|RIGHT|CLEAR|BACKSPACE|TAB|RETURN|NEWLINE|DELETE LINE|INSERT LINE|CLEAR TAB STOP|BUZZER|RING BELL|DELETE|INSERT)$/);
		$self->{'atascii_meta'}->{"REVERSED $name"}->{'unicode'} = $inv . $self->{'atascii_meta'}->{$name}->{'unicode'} . $ni;
        $self->{'atascii_meta'}->{"REVERSED $name"}->{'out'}     = chr(128 + ord($self->{'atascii_meta'}->{$name}->{'out'}));
        $self->{'atascii_meta'}->{"REVERSED $name"}->{'desc'}    = 'Reversed ' . $self->{'atascii_meta'}->{$name}->{'desc'};
    }

    $self->{'atascii_table'} = [
        # Normal
        '♥', '┣', '🮇', '┛', '┫', '┓', '╱', '╲', '◢', '▗', '◣', '🬁', '🬀', '▔', '▂', '▖', '♣', '┏', '━', '╋', '⏺', '▄', '▎', '┳', '┻', '▌', '┗', '␛', '🡹', '🡻', '🡸', '🡺',
        ' ', '!', '"', '#', '$', '%', '&', "'", '(', ')', '*', '+', ',', '-', '.', '/', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=', '>', '?',
        '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[', "\\", ']', '^', '_',
        '♦', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '♠', '|', '🢰', '◀', '▶',
    ];
    foreach my $count (0 .. 127) { # Add inverts for table
        $self->{'atascii_table'}->[$count + 128] = $inv . $self->{'atascii_table'}->[$count] . $ni;
    }
    $self->{'debug'}->DEBUG(['End ATASCII Initialize']);
    return ($self);
} ## end sub atascii_initialize

sub atascii_output {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start ATASCII Output']);
    my $mlines = (exists($self->{'USER'}->{'max_rows'})) ? $self->{'USER'}->{'max_rows'} - 3 : 21;
    my $lines  = $mlines;

    if (length($text) > 1) {
        while ($text =~ /\[\%\s+HORIZONTAL RULE\s+\%\]/) {
            my $rule = '[% TOP HORIZONTAL BAR %]' x $self->{'USER'}->{'max_columns'};
            $text =~ s/\[\%\s+HORIZONTAL RULE\s+\%\]/$rule/gs;
        }
        foreach my $string (keys %{ $self->{'atascii_meta'} }) {
            if ($string eq $self->{'atascii_meta'}->{'CLEAR'}->{'out'} && ($self->{'sysop'} || $self->{'local_mode'})) {
                my $ch = locate(($self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST')), 1) . cldown;
                $text =~ s/\[\%\s+$string\s+\%\]/$ch/gi;
            } else {
                $text =~ s/\[\% $string \%\]/$self->{'atascii_meta'}->{$string}->{'out'}/gi;
            }
        } ## end foreach my $string (keys %{...})
    } ## end if (length($text) > 1)
    my $s_len = length($text);
    my $nl    = $self->{'atascii_meta'}->{'NEWLINE'}->{'out'};
    foreach my $count (0 .. $s_len) {
        my $char = substr($text, $count, 1);
        if ($char eq "\n") {
            if ($text !~ /$nl/ && !$self->{'local_mode'}) {    # translate only if the file doesn't have ASCII newlines
                $char = $nl;
            }
            $lines--;
            if ($lines <= 0) {
                $lines = $mlines;
                last unless ($self->scroll($nl));
            }
        } ## end if ($char eq "\n")
        $self->send_char($char);
    } ## end foreach my $count (0 .. $s_len)
    $self->{'debug'}->DEBUG(['End ATASCII Output']);
    return (TRUE);
} ## end sub atascii_output

 

# package BBS::Universal::BBS_List;

sub bbs_list_initialize {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start BBS List Initialize']);
    $self->{'debug'}->DEBUG(['End BBS List Initialize']);
    return ($self);
} ## end sub bbs_list_initialize

sub bbs_list_add {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start BBS List Add']);

    my $index    = 0;
    my $response = TRUE;
    $self->prompt('What is the BBS Name');
    my $bbs_name = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });
    $self->{'debug'}->DEBUG(["  BBS NAme:  $bbs_name"]);
    $self->output("\n");
    if ($bbs_name ne '' && length($bbs_name) > 3) {
        $self->prompt('What is the Hostname');
        my $bbs_hostname = $self->get_line({ 'type' => HOST, 'max' => 255, 'default' => '' });
        $self->{'debug'}->DEBUG(["  BBS Hostname:  $bbs_hostname"]);
        $self->output("\n");
        if ($bbs_hostname ne '' && length($bbs_hostname) > 5) {
            $self->prompt('What is the Port number');
            my $bbs_port = $self->get_line({ 'type' => NUMERIC, 'max' => 5, 'default' => '' });
            $self->{'debug'}->DEBUG(["  BBS Port:  $bbs_port"]);
            $self->output("\n");
            if ($bbs_port ne '' && $bbs_port =~ /^\d+$/) {
                $self->{'debug'}->DEBUG(["  Adding BBS Entry"]);
                $self->output('Adding BBS Entry...');
                my $sth = $self->{'dbh'}->prepare('INSERT INTO bbs_listing (bbs_name,bbs_hostname,bbs_port,bbs_poster_id) VALUES (?,?,?,1)');
                $sth->execute($bbs_name, $bbs_hostname, $bbs_port);
                $sth->finish();
            } else {
                $response = FALSE;
            }
        } else {
            $response = FALSE;
        }
    } else {
        $response = FALSE;
    }
    $self->{'debug'}->DEBUG(['End BBS List Add']);
    return ($response);
} ## end sub bbs_list_add

sub bbs_list {
    my $self   = shift;
    my $search = shift;

    $self->{'debug'}->DEBUG(['Start BBS List']);
    my $sth;
    my $string;
    my $mode = $self->{'USER'}->{'text_mode'};
    my $ch;
    if ($search) {
        $self->{'debug'}->DEBUG(['  Search BBS List']);
        $self->prompt('Please Enter The BBS To Search For');
        $string = $self->get_line({ 'type' => HOST, 'max' => 255, 'default' => '' });
        $self->{'debug'}->DEBUG(["  Search String:  $string"]);
        return (FALSE) unless (defined($string) && $string ne '');
        $sth = $self->{'dbh'}->prepare('SELECT * FROM bbs_listing_view WHERE bbs_name LIKE ? ORDER BY bbs_name');
        $sth->execute('%' . $string . '%');
        $self->output("\n\n");

        if ($mode eq 'ANSI') {
            $ch = '[% GREEN %]' . $string . '[% RESET %]';
            $self->output("[% B_BRIGHT YELLOW %][% BLACK %] Search BBS listing for [% RESET %] $ch\n\n");
        } elsif ($mode eq 'ATASCII') {
            $ch = $string;
            $self->output("Search BBS listing for $ch\n\n");
        } elsif ($mode eq 'PETSCII') {
            $ch = '[% GREEN %]' . $string . '[% RESET %]';
            $self->output("[% YELLOW %]Search BBS listing for[% RESET %] $ch\n\n");
        } else {
            $ch = $string;
            $self->output("Search BBS listing for '$string'\n\n");
        }
    } else {
        $self->{'debug'}->DEBUG(['  BBS List Full']);
        $sth = $self->{'dbh'}->prepare('SELECT * FROM bbs_listing_view ORDER BY bbs_name');
        $sth->execute();
        $self->output("\n\nShow full BBS list\n\n");
    } ## end else [ if ($search) ]
    $self->{'debug'}->DEBUG(['  BBS Listing - DB query complete']);
    my @listing;
    my ($name_size, $hostname_size, $poster_size) = (4, 14, 6);
    while (my $row = $sth->fetchrow_hashref()) {
        push(@listing, $row);
        $name_size     = max(length($row->{'bbs_name'}),     $name_size);
        $hostname_size = max(length($row->{'bbs_hostname'}), $hostname_size);
        $poster_size   = max(length($row->{'bbs_poster'}),   $poster_size);
    } ## end while (my $row = $sth->fetchrow_hashref...)
    $self->{'debug'}->DEBUGMAX(\@listing);
    if (scalar(@listing)) {
        my $table;
        if ($self->{'USER'}->{'max_columns'} > 40) {
            $table = Text::SimpleTable->new($name_size, $hostname_size, 5, $poster_size);
            $table->row('NAME', 'HOSTNAME/PHONE', 'PORT', 'POSTER');
            $table->hr();
            foreach my $line (@listing) {
                $table->row($line->{'bbs_name'}, $line->{'bbs_hostname'}, $line->{'bbs_port'}, $line->{'bbs_poster'});
            }
        } else {
            $table = Text::SimpleTable->new($name_size, $hostname_size);
            $table->row('NAME', 'HOSTNAME/PHONE');
            $table->hr();
            foreach my $line (@listing) {
                $table->row($line->{'bbs_name'}, $line->{'bbs_hostname'} . ':' . $line->{'bbs_port'});
            }
        } ## end else [ if ($self->{'USER'}->{...})]
        my $response;
        if ($mode eq 'ANSI') {
            $response = $table->boxes2('BRIGHT BLUE')->draw();
            while ($response =~ / (NAME|HOSTNAME.PHONE|PORT|POSTER) /) {
                my $ch  = $1;
                my $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
                $response =~ s/ $ch / $new /gs;
            }
        } elsif ($mode eq 'ATASCII') {
            $response = $self->color_border($table->boxes->draw(), '');
        } elsif ($mode eq 'PETSCII') {
            $response = $table->boxes->draw();
            while ($response =~ / (NAME|HOSTNAME.PHONE|PORT|POSTER) /) {
                my $ch  = $1;
                my $new = '[% YELLOW %]' . $ch . '[% WHITE %]';
                $response =~ s/ $ch / $new /gs;
            }
            $response = $self->color_border($response, 'BRIGHT BLUE');
        } else {
            $response = $table->draw();
        }
        $response =~ s/$string/$ch/gs if ($search);
        $self->output($response);
    } ## end if (scalar(@listing))
    $self->output("\n\nPress any key to continue\n");
    $self->get_key(SILENT, BLOCKING);
    $self->{'debug'}->DEBUG(['End BBS List']);
    return (TRUE);
} ## end sub bbs_list

 

# package BBS::Universal::CPU;

sub cpu_initialize {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start CPU Initialize']);
    $self->{'debug'}->DEBUG(['END CPU Initialize']);
    return ($self);
} ## end sub cpu_initialize

sub cpu_info {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start CPU Info']);
    my $cpu         = $self->cpu_identify();
    my $cpu_cores   = scalar(@{ $cpu->{'CPU'} });
    my $cpu_threads = (exists($cpu->{'CPU'}->[0]->{'logical processors'})) ? $cpu->{'CPU'}->[0]->{'logical processors'} : 'No Hyperthreading';
    my $cpu_bits    = $cpu->{'HARDWARE'}->{'Bits'} + 0;
    my $identity    = $cpu->{'CPU'}->[0]->{'model name'};

    chomp(my $load_average = `cat /proc/loadavg`);

    my $speed = $cpu->{'CPU'}->[0]->{'cpu MHz'} if (exists($cpu->{'CPU'}->[0]->{'cpu MHz'}));

    unless (defined($speed)) {
        chomp($speed = `cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq`);
        $speed /= 1000;
    }

    if ($speed > 999.999) {    # GHz
        $speed = sprintf('%.02f GHz', ($speed / 1000));
    } elsif ($speed > 0) {     # MHz
        $speed = sprintf('%.02f MHz', $speed);
    } else {
        $speed = 'Unknown';
    }
    my $response = {
        'CPU IDENTITY' => $identity,
        'CPU SPEED'    => $speed,
        'CPU CORES'    => $cpu_cores,
        'CPU THREADS'  => $cpu_threads,
        'CPU BITS'     => $cpu_bits,
        'CPU LOAD'     => $load_average,
        'HARDWARE'     => $cpu->{'HARDWARE'}->{'Hardware'},
    };
    $self->{'debug'}->DEBUGMAX([$response]);
    $self->{'debug'}->DEBUG(['End CPU Info']);
    return ($response);
} ## end sub cpu_info

sub cpu_identify {
    my $self = shift;

    return ($self->{'CPUINFO'}) if (exists($self->{'CPUINFO'}));
    $self->{'debug'}->DEBUG(['Start CPU Identity']);
    open(my $CPU, '<', '/proc/cpuinfo');
    chomp(my @cpuinfo = <$CPU>);
    close($CPU);
    $self->{'CPUINFO'} = \@cpuinfo;

    my $cpu_identity;
    my $index = 0;
    chomp(my $bits = `getconf LONG_BIT`);
    my $hardware = { 'Hardware' => 'Unknown', 'Bits' => $bits };
    foreach my $line (@cpuinfo) {
        if ($line ne '') {
            my ($name, $val) = split(/: /, $line);
            $name = $self->trim($name);
            if ($name =~ /^(Hardware|Revision|Serial)/i) {
                $hardware->{$name} = $val;
            } else {
                if ($name eq 'processor') {
                    $index = $val;
                } else {
                    $cpu_identity->[$index]->{$name} = $val;
                }
            } ## end else [ if ($name =~ /^(Hardware|Revision|Serial)/i)]
        } ## end if ($line ne '')
    } ## end foreach my $line (@cpuinfo)
    my $response = {
        'CPU'      => $cpu_identity,
        'HARDWARE' => $hardware,
    };
    if (-e '/usr/bin/lscpu' || -e 'usr/local/bin/lscpu') {
        my $lscpu_short = `lscpu --extended=cpu,core,online,minmhz,maxmhz`;
        chomp(my $lscpu_version = `lscpu -V`);
        $lscpu_version =~ s/^lscpu from util-linux (\d+)\.(\d+)\.(\d+)/$1.$2/;
        my $lscpu_long = ($lscpu_version >= 2.38) ? `lscpu --hierarchic` : `lscpu`;
        $response->{'lscpu'}->{'short'} = $lscpu_short;
        $response->{'lscpu'}->{'long'}  = $lscpu_long;
    } ## end if (-e '/usr/bin/lscpu'...)
    $self->{'CPUINFO'} = $response;    # Cache this stuff
    $self->{'debug'}->DEBUGMAX([$response]);
    $self->{'debug'}->DEBUG(['End CPU Identity']);
    return ($response);
} ## end sub cpu_identify

 

# package BBS::Universal::Commands.pm;

sub commands_initialize {
	my $self = shift;

	$self->{'debug'}->DEBUG(['Begin Commands initialize']);
	$self->{'COMMANDS'} = {
        'SHOW FULL BBS LIST' => sub {
            my $self = shift;
            $self->bbs_list(FALSE);
            return ($self->load_menu('files/main/bbs_listing'));
        },
        'SEARCH BBS LIST' => sub {
            my $self = shift;
            $self->bbs_list(TRUE);
            return ($self->load_menu('files/main/bbs_listing'));
        },
        'RSS FEEDS' => sub {
            my $self = shift;
            $self->news_rss_feeds();
            return ($self->load_menu('files/main/news'));
        },
        'UPDATE ACCOMPLISHMENTS' => sub {
            my $self = shift;
            $self->users_update_accomplishments();
            return ($self->load_menu('files/main/account'));
        },
        'RSS CATEGORIES' => sub {
            my $self = shift;
            $self->news_rss_categories();
            return ($self->load_menu('files/main/news'));
        },
        'FORUM CATEGORIES' => sub {
            my $self = shift;
            $self->messages_forum_categories();
            return ($self->load_menu('files/main/forums'));
        },
        'FORUM MESSAGES LIST' => sub {
            my $self = shift;
            $self->messages_list_messages();
            return ($self->load_menu('files/main/forums'));
        },
        'FORUM MESSAGES READ' => sub {
            my $self = shift;
            $self->messages_read_message();
            return ($self->load_menu('files/main/forums'));
        },
        'FORUM MESSAGES EDIT' => sub {
            my $self = shift;
            $self->messages_edit_message('EDIT');
            return ($self->load_menu('files/main/forums'));
        },
        'FORUM MESSAGES ADD' => sub {
            my $self = shift;
            $self->messages_edit_message('ADD');
            return ($self->load_menu('files/main/forums'));
        },
        'FORUM MESSAGES DELETE' => sub {
            my $self = shift;
            $self->messages_delete_message();
            return ($self->load_menu('files/main/forums'));
        },
        'UPDATE LOCATION' => sub {
            my $self = shift;
            $self->users_update_location();
            return ($self->load_menu('files/main/account'));
        },
        'UPDATE EMAIL' => sub {
            my $self = shift;
            $self->users_update_email();
            return ($self->load_menu('files/main/account'));
        },
        'UPDATE RETRO SYSTEMS' => sub {
            my $self = shift;
            $self->users_update_retro_systems();
            return ($self->load_menu('files/main/account'));
        },
        'CHANGE ACCESS LEVEL' => sub {
            my $self = shift;
            $self->users_change_access_level();
            return ($self->load_menu('files/main/account'));
        },
        'CHANGE BAUD RATE' => sub {
            my $self = shift;
            $self->users_change_baud_rate();
            return ($self->load_menu('files/main/account'));
        },
        'CHANGE DATE FORMAT' => sub {
            my $self = shift;
            $self->users_change_date_format();
            return ($self->load_menu('files/main/account'));
        },
        'CHANGE SCREEN SIZE' => sub {
            my $self = shift;
            $self->users_change_screen_size();
            return ($self->load_menu('files/main/account'));
        },
        'CHOOSE TEXT MODE' => sub {
            my $self = shift;
            $self->users_update_text_mode();
            return ($self->load_menu('files/main/account'));
        },
        'TOGGLE SHOW EMAIL' => sub {
            my $self = shift;
            $self->users_toggle_permission('show_email');
            return ($self->load_menu('files/main/account'));
        },
        'TOGGLE PREFER NICKNAME' => sub {
            my $self = shift;
            $self->users_toggle_permission('prefer_nickname');
            return ($self->load_menu('files/main/account'));
        },
        'TOGGLE PLAY FORTUNES' => sub {
            my $self = shift;
            $self->users_toggle_permission('play_fortunes');
            return ($self->load_menu('files/main/account'));
        },
        'BBS LIST ADD' => sub {
            my $self = shift;
            $self->bbs_list_add();
            return ($self->load_menu('files/main/bbs_listing'));
        },
        'BBS LISTING' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/bbs_listing'));
        },
        'LIST USERS' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/list_users'));
        },
        'ACCOUNT MANAGER' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/account'));
        },
        'BACK' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/menu'));
        },
        'DISCONNECT' => sub {
            my $self = shift;
            $self->output("\nDisconnect, are you sure (y|N)?  ");
            unless ($self->decision()) {
                return ($self->load_menu('files/main/menu'));
            }
            $self->output("\n");
        },
        'FILE CATEGORY' => sub {
            my $self = shift;
            $self->choose_file_category();
            return ($self->load_menu('files/main/files_menu'));
        },
        'FILES' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/files_menu'));
        },
        'LIST FILES SUMMARY' => sub {
            my $self = shift;
            $self->files_list_summary(FALSE);
            return ($self->load_menu('files/main/files_menu'));
        },
        'UPLOAD FILE' => sub {
            my $self = shift;
            $self->files_upload_choices();
            return ($self->load_menu('files/main/files_menu'));
        },
        'LIST FILES DETAILED' => sub {
            my $self = shift;
            $self->files_list_detailed(FALSE);
            return ($self->load_menu('files/main/files_menu'));
        },
        'SEARCH FILES SUMMARY' => sub {
            my $self = shift;
            $self->files_list_summary(TRUE);
            return ($self->load_menu('files/main/files_menu'));
        },
        'SEARCH FILES DETAILED' => sub {
            my $self = shift;
            $self->files_list_detailed(TRUE);
            return ($self->load_menu('files/main/files_menu'));
        },
        'NEWS' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/news'));
        },
        'NEWS SUMMARY' => sub {
            my $self = shift;
            $self->news_summary();
            return ($self->load_menu('files/main/news'));
        },
        'NEWS DISPLAY' => sub {
            my $self = shift;
            $self->news_display();
            return ($self->load_menu('files/main/news'));
        },
        'FORUMS' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/forums'));
        },
        'ABOUT' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/about'));
        },
	};
	$self->{'debug'}->DEBUG(['End Commands initialize']);
}

 

# package BBS::Universal::DB;

sub db_initialize {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start DB Initialize']);
    $self->{'debug'}->DEBUG(['End DB Initialize']);
    return ($self);
} ## end sub db_initialize

sub db_connect {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start DB Connect']);
    my @dbhosts = split(/\s*,\s*/, $self->{'CONF'}->{'STATIC'}->{'DATABASE HOSTNAME'});
    my $errors  = '';
    foreach my $host (@dbhosts) {
        $errors = '';

        # This is for the brave that want to try SSL connections.
        #
        #    $self->{'dsn'} = sprintf('dbi:%s:database=%s;' .
        #        'host=%s;' .
        #        'port=%s;' .
        #        'mysql_ssl=%d;' .
        #        'mysql_ssl_client_key=%s;' .
        #        'mysql_ssl_client_cert=%s;' .
        #        'mysql_ssl_ca_file=%s',
        #        $self->{'CONF'}->{'STATIC'}->{'DATABASE TYPE'},
        #        $self->{'CONF'}->{'STATIC'}->{'DATABASE NAME'},
        #        $self->{'CONF'}->{'STATIC'}->{'DATABASE HOSTNAME'},
        #        $self->{'CONF'}->{'STATIC'}->{'DATABASE PORT'},
        #        TRUE,
        #        '/etc/mysql/certs/client-key.pem',
        #        '/etc/mysql/certs/client-cert.pem',
        #        '/etc/mysql/certs/ca-cert.pem'
        #    );
        $self->{'dsn'} = sprintf('dbi:%s:database=%s;' . 'host=%s;' . 'port=%s;', $self->{'CONF'}->{'STATIC'}->{'DATABASE TYPE'}, $self->{'CONF'}->{'STATIC'}->{'DATABASE NAME'}, $host, $self->{'CONF'}->{'STATIC'}->{'DATABASE PORT'},);
        $self->{'dbh'} = DBI->connect(
            $self->{'dsn'},
            $self->{'CONF'}->{'STATIC'}->{'DATABASE USERNAME'},
            $self->{'CONF'}->{'STATIC'}->{'DATABASE PASSWORD'},
            {
                'PrintError' => FALSE,
                'RaiseError' => TRUE,
                'AutoCommit' => TRUE,
            },
        ) or $errors = $DBI::errstr;
        last if ($errors eq '');
    } ## end foreach my $host (@dbhosts)
    if ($errors ne '') {
        $self->{'debug'}->ERROR(["Database Host not found!\n$errors"]);
        exit(1);
    }
    $self->{'debug'}->DEBUG(['End DB Connect']);
    return (TRUE);
} ## end sub db_connect

sub db_count_users {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start DB Count Users']);
    unless (exists($self->{'dbh'})) {
        $self->db_connect();
    }
    my $response = $self->{'dbh'}->do('SELECT COUNT(id) FROM users');
    $self->{'debug'}->DEBUG(['End DB Count Users']);
    return ($response);
} ## end sub db_count_users

sub db_disconnect {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start DB Disconnect']);
    $self->{'dbh'}->disconnect() if (defined($self->{'dbh'}));
    $self->{'debug'}->DEBUG(['End DB Disconnect']);
    return (TRUE);
} ## end sub db_disconnect

 

# package BBS::Universal::FileTransfer;

sub filetransfer_initialize {
    my ($self) = @_;
    $self->{'debug'}->DEBUG(['Start FileTransfer Initialize']);
    $self->{'debug'}->DEBUG(['End FileTransfer Initialize']);
    return ($self);
} ## end sub filetransfer_initialize

sub files_type {
    my ($self, $file) = @_;

    $self->{'debug'}->DEBUG(['Start File Type']);
    my @tmp = split(/\./, $file);
    my $ext = uc(pop(@tmp));
    my $sth = $self->{'dbh'}->prepare('SELECT type FROM file_types WHERE extension=?');
    $sth->execute($ext);
    my $name;
    if ($sth->rows > 0) {
        $name = $sth->fetchrow_array();
    }
    $sth->finish();
    $self->{'debug'}->DEBUG(['End File Type']);
    return ($ext, $name);
} ## end sub files_type

sub files_load_file {
    my ($self, $file) = @_;

    $self->{'debug'}->DEBUG(['Start Files Load File']);
    my $filename = sprintf('%s.%s', $file, $self->{'USER'}->{'text_mode'});
    $self->{'CACHE'}->set(sprintf('SERVER %02d %s', $self->{'thread_number'}, 'CURRENT MENU FILE'), $filename);
    open(my $FILE, '<', $filename);
    my @text = <$FILE>;
    close($FILE);
    chomp(@text);
    $self->{'debug'}->DEBUG(['End Files Load File']);
    return (join("\n", @text));
} ## end sub files_load_file

sub files_list_summary {
    my ($self, $search) = @_;

    $self->{'debug'}->DEBUG(['Start Files List Summary']);
    my $sth;
    my $filter;
    if ($search) {
        $self->prompt('Search for (blank for all)');
        $filter = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });
        $sth    = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE (filename LIKE ? OR title LIKE ?) AND category_id=? ORDER BY uploaded DESC');
        $sth->execute('%' . $filter . '%', '%' . $filter . '%', $self->{'USER'}->{'file_category'});
    } else {
        $sth = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE category_id=? ORDER BY uploaded DESC');
        $sth->execute($self->{'USER'}->{'file_category'});
    }
    my @files;
    my $max_filename = 10;
    my $max_title    = 20;
    if ($sth->rows > 0) {
        while (my $row = $sth->fetchrow_hashref()) {
            push(@files, $row);
            $max_filename = max(length($row->{'filename'}), $max_filename);
            $max_title    = max(length($row->{'title'}),    $max_title);
        }
        my $table = Text::SimpleTable->new($max_filename, $max_title);
        $table->row('FILENAME', 'TITLE');
        $table->hr();
        foreach my $record (@files) {
            $table->row($record->{'filename'}, $record->{'title'});
        }
        my $mode = $self->{'USER'}->{'text_mode'};
        if ($mode eq 'ANSI') {
            my $text = $table->boxes2('MAGENTA')->draw();
            while ($text =~ / (FILENAME|TITLE) /s) {
                my $ch  = $1;
                my $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
                $text =~ s/ $ch / $new /gs;
            }
            $self->output("\n$text");
        } elsif ($mode eq 'ATASCII') {
            $self->output("\n" . $self->color_border($table->boxes->draw(), 'MAGENTA'));
        } elsif ($mode eq 'PETSCII') {
            my $text = $table->boxes->draw();
            while ($text =~ / (FILENAME|TITLE) /s) {
                my $ch  = $1;
                my $new = '[% YELLOW %]' . $ch . '[% RESET %]';
                $text =~ s/ $ch / $new /gs;
            }
            $self->output("\n" . $self->color_border($text, 'PURPLE'));
        } else {
            $self->output("\n" . $table->draw());
        }
    } elsif ($search) {
        $self->output("\nSorry '$filter' not found");
    } else {
        $self->output("\nSorry, this file category is empty\n");
    }
    $self->output("\nPress a key to continue ...");
    $self->get_key(ECHO, BLOCKING);
    $self->{'debug'}->DEBUG(['End Files List Summary']);
    return (TRUE);
} ## end sub files_list_summary

sub files_choices {
    my ($self, $record) = @_;

    while ($self->is_connected()) {
        my $view    = FALSE;
        my $mapping = {
            'TEXT' => '',
            'Z'    => { 'command' => 'BACK',        'color' => 'WHITE', 'access_level' => 'USER',         'text' => 'Return to File Menu' },
            'N'    => { 'command' => 'NEXT',        'color' => 'BLUE',  'access_level' => 'USER',         'text' => 'Next file' },
            'D'    => { 'command' => 'DOWNLOAD',    'color' => 'CYAN',  'access_level' => 'VETERAN',      'text' => 'Download file' },
            'R'    => { 'command' => 'REMOVE FILE', 'color' => 'RED',   'access_level' => 'JUNIOR SYSOP', 'text' => 'Remove file' },
        };
        if ($record->{'extension'} =~ /^(TXT|ASC|ATA|PET|VT|ANS|MD|INF|CDF|PL|PM|PY|C|CPP|H|SH|CSS|HTM|HTML|SHTML|JS|JAVA|XML|BAT)$/ && $self->check_access_level('VETERAN')) {
            $view = TRUE;
            $mapping->{'V'} = { 'command' => 'VIEW FILE', 'color' => 'CYAN', 'access_level' => 'VETERAN', 'text' => 'View file' };
        } ## end if ($record->{'extension'...})
        $self->show_choices($mapping);
        $self->prompt('Choose');
        my $key;
        do {
            $key = uc($self->get_key());
        } until ($key =~ /D|N|Z/ || ($key eq 'V' && $view) || ($key eq 'R' && $self->check_access_level('JUNION SYSOP')));
        $self->output($mapping->{$key}->{'command'} . "\n");
        if ($mapping->{$key}->{'command'} eq 'DOWNLOAD') {
            my $file = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $record->{'filename'};
            $mapping = {
                'B' => { 'command' => 'BACK',   'color' => 'WHITE',       'access_level' => 'USER',    'text' => 'Return to File Menu' },
                'Y' => { 'command' => 'YMODEM', 'color' => 'YELLOW',      'access_level' => 'VETERAN', 'text' => 'Download with the Ymodem protocol' },
                'X' => { 'command' => 'XMODEM', 'color' => 'BRIGHT BLUE', 'access_level' => 'VETERAN', 'text' => 'Download with the Xmodem protocol' },
                'Z' => { 'command' => 'ZMODEM', 'color' => 'GREEN',       'access_level' => 'VETERAN', 'text' => 'Download with the Zmodem protocol' },
            };
            $self->show_choices($mapping);
            $self->prompt('Choose');
            do {
                $key = uc($self->get_key());
            } until ($key =~ /B|X|Y|Z/);
            $self->output($mapping->{$key}->{'command'});
            if ($mapping->{$key}->{'command'} eq 'XMODEM') {
                system('sz', '--xmodem', '--quiet', '--binary', $file);
            } elsif ($mapping->{$key}->{'command'} eq 'YMODEM') {
                system('sz', '--ymodem', '--quiet', '--binary', $file);
            } elsif ($mapping->{$key}->{'command'} eq 'ZMODEM') {
                system('sz', '--zmodem', '--quiet', '--binary', '--resume', $file);
            } else {
                return (FALSE);
            }
            return (TRUE);
        } elsif ($mapping->{$key}->{'command'} eq 'VIEW FILE' && $self->check_access_level($mapping->{$key}->{'access_level'})) {
            my $file = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $record->{'filename'};
            open(my $VIEW, '<', $file);
            binmode($VIEW, ":encoding(UTF-8)");
            my $data;
            read($VIEW, $data, $record->{'file_size'}, 0);
            close($VIEW);
            $self->output('[% CLS %]' . $data . '[% RESET %]');
        } elsif ($mapping->{$key}->{'command'} eq 'REMOVE FILE' && $self->check_access_level($mapping->{$key}->{'access_level'})) {
            return (TRUE);
        } elsif ($mapping->{$key}->{'command'} eq 'NEXT') {
            return (TRUE);
        } elsif ($mapping->{$key}->{'command'} eq 'BACK') {
            return (FALSE);
        }
    } ## end while ($self->is_connected...)
} ## end sub files_choices

sub files_upload_choices {
    my ($self) = @_;
    my $ckey;

    $self->prompt('File Name? ');
    my $file = $self->get_line({ 'type' => FILENAME, 'max' => 255, 'default' => '' });
    my $ext  = uc($file =~ /\.(.*?)$/);

    $self->prompt('Title (Fiendly name)? ');
    my $title = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });

    $self->prompt('Description? ');
    my $description = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });

    my $file_category = $self->{'USER'}->{'file_category'};

    my $mapping = {
        'B' => { 'command' => 'BACK',   'color' => 'WHITE',       'access_level' => 'USER',    'text' => 'Return to File Menu' },
        'Y' => { 'command' => 'YMODEM', 'color' => 'YELLOW',      'access_level' => 'VETERAN', 'text' => 'Upload with the Ymodem protocol' },
        'X' => { 'command' => 'XMODEM', 'color' => 'BRIGHT BLUE', 'access_level' => 'VETERAN', 'text' => 'Upload with the Xmodem protocol' },
        'Z' => { 'command' => 'ZMODEM', 'color' => 'GREEN',       'access_level' => 'VETERAN', 'text' => 'Upload with the Zmodem protocol' },
    };
    $self->show_choices($mapping);
    $self->prompt('Choose');
    do {
        $ckey = uc($self->get_key());
    } until ($ckey =~ /B|X|Y|Z/);
    $self->output($mapping->{$ckey}->{'command'});
    if ($mapping->{$ckey}->{'command'} eq 'XMODEM') {
        if ($self->files_receive_file($file, XMODEM)) {
            my $filename = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file;
            my $size     = (-s $filename);
            my $sth      = $self->{'dbh'}->prepare('INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES (?,?,?,(SELECT id FROM file_types WHERE extension=?),?,?');
            $sth->execute($file_category, $file, $title, $ext, $description, $size);
            $sth->finish();
        } ## end if ($self->files_receive_file...)
    } elsif ($mapping->{$ckey}->{'command'} eq 'YMODEM') {
        if ($self->files_receive_file($file, YMODEM)) {
            my $filename = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file;
            my $size     = (-s $filename);
            my $sth      = $self->{'dbh'}->prepare('INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES (?,?,?,(SELECT id FROM file_types WHERE extension=?),?,?');
            $sth->execute($file_category, $file, $title, $ext, $description, $size);
            $sth->finish();
        } ## end if ($self->files_receive_file...)
    } elsif ($mapping->{$ckey}->{'command'} eq 'ZMODEM') {
        if ($self->files_receive_file($file, ZMODEM)) {
            my $filename = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file;
            my $size     = (-s $filename);
            my $sth      = $self->{'dbh'}->prepare('INSERT INTO files (category,filename,title,file_type,description,file_size) VALUES (?,?,?,(SELECT id FROM file_types WHERE extension=?),?,?');
            $sth->execute($file_category, $file, $title, $ext, $description, $size);
            $sth->finish();
        } ## end if ($self->files_receive_file...)
    } else {
        return (FALSE);
    }
    if ($? == -1) {
        $self->{'debug'}->ERROR(["Could not execute rz:  $!"]);
    } elsif ($? & 127) {
        $self->{'debug'}->ERROR(["File Transfer Aborted:  $!"]);
    } else {
        $self->{'debug'}->DEBUG(['File Transfer Successful']);
    }
    return (TRUE);
} ## end sub files_upload_choices

sub files_list_detailed {
    my ($self, $search) = @_;

    $self->{'debug'}->DEBUG(['Start Files List Detailed']);
    my $sth;
    my $filter;
    my $columns = $self->{'USER'}->{'max_columns'};
    if ($search) {
        $self->prompt('Search for');
        $filter = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });
        $sth    = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE (filename LIKE ? OR title LIKE ?) AND category_id=? ORDER BY uploaded DESC');
        $sth->execute('%' . $filter . '%', '%' . $filter . '%', $self->{'USER'}->{'file_category'});
    } else {
        $sth = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE category_id=? ORDER BY uploaded DESC');
        $sth->execute($self->{'USER'}->{'file_category'});
    }
    my @files;
    if ($sth->rows > 0) {
        $self->{'debug'}->DEBUGMAX(\@files);
        my $table;
        my $mode = $self->{'USER'}->{'text_mode'};
        while (my $row = $sth->fetchrow_hashref()) {
            push(@files, $row);
        }
        $sth->finish();
        foreach my $record (@files) {
            if ($mode eq 'ANSI') {
                $self->output("\n" . '[% HORIZONTAL RULE GREEN %]' . "\n");
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]       TITLE [% RESET %] ' . $record->{'title'} . "\n");
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]    FILENAME [% RESET %] ' . $record->{'filename'} . "\n");
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]   FILE SIZE [% RESET %] ' . format_number($record->{'file_size'}) . "\n");
                if ($record->{'prefer_nickname'}) {
                    $self->output('[% B_BLUE %][% BRIGHT WHITE %]    UPLOADER [% RESET %] ' . $record->{'nickname'} . "\n");
                } else {
                    $self->output('[% B_BLUE %][% BRIGHT WHITE %]    UPLOADER [% RESET %] ' . $record->{'fullname'} . "\n");
                }
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]   FILE TYPE [% RESET %] ' . $record->{'type'} . "\n");
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]    UPLOADED [% RESET %] ' . $record->{'uploaded'} . "\n");
                $self->output('[% B_BLUE %][% BRIGHT WHITE %]      THUMBS [% RESET %] [% THUMBS UP SIGN %] ' . (0 + $record->{'thumbs_up'}) . '   [% THUMBS DOWN SIGN %] ' . (0 + $record->{'tumbs_down'}) . "\n");
                $self->output('[% HORIZONTAL RULE GREEN %]' . "\n");
            } else {
                $self->output("\n      TITLE: " . $record->{'title'} . "\n");
                $self->output('   FILENAME: ' . $record->{'filename'} . "\n");
                $self->output('  FILE SIZE: ' . format_number($record->{'file_size'}) . "\n");
                if ($record->{'prefer_nickname'}) {
                    $self->output('   UPLOADER: ' . $record->{'nickname'} . "\n");
                } else {
                    $self->output('   UPLOADER: ' . $record->{'fullname'} . "\n");
                }
                $self->output('  FILE TYPE: ' . $record->{'type'} . "\n");
                $self->output('   UPLOADED: ' . $record->{'uploaded'} . "\n");
                $self->output('  THUMBS UP: ' . (0 + $record->{'thumbs_up'}) . "\n");
                $self->output('THUMBS DOWN: ' . (0 + $record->{'thumbs_down'}) . "\n");
            } ## end else [ if ($mode eq 'ANSI') ]
            last unless ($self->files_choices($record));
        } ## end foreach my $record (@files)
    } elsif ($search) {
        $self->output("\nSorry '$filter' not found");
    } else {
        $self->output("\nSorry, this file category is empty\n");
    }
    $self->output("\nPress a key to continue ...");
    $self->get_key(ECHO, BLOCKING);
    $self->{'debug'}->DEBUG(['End Files List Detailed']);
    return (TRUE);
} ## end sub files_list_detailed

sub files_save_file {
    my ($self) = @_;
    $self->{'debug'}->DEBUG(['Start Save File']);
    $self->{'debug'}->DEBUG(['End Save File']);
    return (TRUE);
} ## end sub files_save_file

sub files_receive_file {
    my ($self, $file, $protocol) = @_;

    my $success = TRUE;
    $self->{'debug'}->DEBUG(['Start Receive File']);
    unless ($self->{'local_mode'}) {
        if ($protocol == YMODEM) {
            $self->{'debug'}->DEBUG(["Send file $file with Ymodem"]);
            $success = $self->files_receive_file_ymodem($self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file);
        } elsif ($protocol == ZMODEM) {
            $self->{'debug'}->DEBUG(["Send file $file with Zmodem"]);
            $success = $self->files_receive_file_zmodem($self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file);
        } else {    # Xmodem
            $success = $self->files_receive_file_xmodem($self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file);
            $self->{'debug'}->DEBUG(["Send file $file with Xmodem"]);
        }
    } else {
        $self->output("Upload not allowed in local mode\n");
    }
    $self->{'debug'}->DEBUG(['End Receive File']);
    return ($success);
} ## end sub files_receive_file

sub files_receive_file_xmodem {
    my ($self, $file) = @_;

    $self->{'debug'}->DEBUG(['Start files_receive_file_xmodem']);
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for XMODEM receive"]);
        return 0;
    }

    $self->output("\nStart sending your file via Xmodem\n");
    my $path = $file;
    my $FH;

    # Ensure directory exists
    if ($path =~ m{^(.+)/[^/]+$}) {
        my $dir = $1;
        unless (-d $dir) {
            File::Path::mkpath($dir);
        }
    } ## end if ($path =~ m{^(.+)/[^/]+$})

    unless (open $FH, '>:raw', $path) {
        $self->{'debug'}->ERROR(["Cannot open file for writing $path: $!"]);
        return 0;
    }

    my $expected_blk   = 1;
    my $max_init_tries = 10;
    my $init_sent      = 0;

    # Request CRC mode by sending 'C' until sender responds with SOH/STX/EOT
    for (1 .. $max_init_tries) {
        last unless $self->is_connected();
        syswrite($sock, C_CHAR);
        $init_sent++;
        my $b = $self->_read_byte_timeout($sock, 10);
        if (defined $b && ($b eq SOH || $b eq STX || $b eq EOT || $b eq CAN)) {

            # put back the byte into variable for main loop
            $self->{'_xmodem_first'} = $b;
            last;
        } ## end if (defined $b && ($b ...))
    } ## end for (1 .. $max_init_tries)
    unless ($init_sent) {
        $self->{'debug'}->ERROR(["No response from sender to XMODEM init"]);
        close $FH;
        return 0;
    }

    my $success = 1;
  FILE_LOOP:
    while ($self->is_connected()) {

        # read first header byte
        my $hdr;
        if (defined $self->{'_xmodem_first'}) {
            $hdr = delete $self->{'_xmodem_first'};
        } else {
            $hdr = $self->_read_byte_timeout($sock, 60);
        }
        unless (defined $hdr) {
            $self->{'debug'}->ERROR(["Timeout waiting for XMODEM block header"]);
            $success = 0;
            last;
        }
        if ($hdr eq EOT) {
            # End of transmission
            syswrite($sock, ACK);
            last FILE_LOOP;
        } elsif ($hdr eq CAN) {
            $self->{'debug'}->ERROR(["Sender cancelled XMODEM transfer (CAN)"]);
            $success = 0;
            last FILE_LOOP;
        } elsif ($hdr eq SOH || $hdr eq STX) {
            my $block_size = ($hdr eq STX) ? 1024 : 128;

            # read blocknum and its complement
            my $blknum = $self->_read_byte_timeout($sock, 10);
            my $nblk   = $self->_read_byte_timeout($sock, 10);
            unless (defined $blknum && defined $nblk) {
                $self->{'debug'}->ERROR(["Timeout reading block number for XMODEM"]);
                $success = 0;
                last FILE_LOOP;
            }
            my $blknum_val = ord($blknum);
            my $nblk_val   = ord($nblk);

            # read data
            my $data = '';
            for (1 .. $block_size) {
                my $b = $self->_read_byte_timeout($sock, 10);
                unless (defined $b) {
                    $self->{'debug'}->ERROR(["Timeout reading XMODEM data block"]);
                    $success = 0;
                    last FILE_LOOP;
                }
                $data .= $b;
            } ## end for (1 .. $block_size)

            # read CRC16 (2 bytes)
            my $crc_hi = $self->_read_byte_timeout($sock, 10);
            my $crc_lo = $self->_read_byte_timeout($sock, 10);
            unless (defined $crc_hi && defined $crc_lo) {
                $self->{'debug'}->ERROR(["Timeout reading XMODEM CRC"]);
                $success = 0;
                last FILE_LOOP;
            }
            my $recv_crc = $crc_hi . $crc_lo;

            # validate block number
            if ((($blknum_val + ord($nblk)) & 0xFF) != 0xFF) {
                # invalid complement
                $self->{'debug'}->ERROR(["Invalid block number complement in XMODEM block"]);
                syswrite($sock, NAK);
                next;
            } ## end if ((($blknum_val + ord...)))
            if ($blknum_val == ($expected_blk & 0xFF)) {
                # verify CRC
                my $calc_crc = _crc16_bytes($data);
                if ($calc_crc eq $recv_crc) {
                    # write data (for XMODEM we don't have exact file size; write all and later trim if needed)
                    # strip trailing SUB (0x1A) only when they appear at the end if sender padded
                    # We'll write raw data; caller may handle size if needed.
                    print $FH $data;
                    syswrite($sock, ACK);
                    $expected_blk = ($expected_blk + 1) & 0xFF;
                } else {
                    $self->{'debug'}->ERROR(["CRC mismatch on XMODEM block $blknum_val"]);
                    syswrite($sock, NAK);
                    next;
                }
            } elsif ($blknum_val == (($expected_blk - 1) & 0xFF)) {
                # duplicate block (sender retransmitted) - ACK and ignore
                syswrite($sock, ACK);
                next;
            } else {
                # out of sequence
                $self->{'debug'}->ERROR(["Unexpected XMODEM block number $blknum_val (expected $expected_blk)"]);
                syswrite($sock, CAN x 2);
                $success = 0;
                last FILE_LOOP;
            } ## end else [ if ($blknum_val == ($expected_blk...))]
        } else {
            # unexpected byte - ignore/continue
            $self->{'debug'}->DEBUG(["Received unexpected byte during XMODEM receive: " . ord($hdr)]);
            next;
        } ## end else [ if ($hdr eq EOT) ]
    } ## end FILE_LOOP: while ($self->is_connected...)

    close $FH;
    $self->output("\nFile receive complete\n");
    $self->{'debug'}->DEBUG(['End files_receive_file_xmodem']);
    return $success;
} ## end sub files_receive_file_xmodem

sub files_receive_file_ymodem {
    my ($self, $file) = @_;

    $self->{'debug'}->DEBUG(['Start files_receive_file_ymodem']);
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for YMODEM receive"]);
        return 0;
    }

    $self->output("\nStart sending your file via Ymodem\n");
    my $path = $file;

    # Ensure directory exists
    if ($path =~ m{^(.+)/[^/]+$}) {
        my $dir = $1;
        unless (-d $dir) {
            File::Path::mkpath($dir);
        }
    } ## end if ($path =~ m{^(.+)/[^/]+$})

    my $FH;
    unless (open $FH, '>:raw', $path) {
        $self->{'debug'}->ERROR(["Cannot open file for writing $path: $!"]);
        return 0;
    }

    # Request CRC for YMODEM by sending 'C' to start
    my $tries   = 0;
    my $init_ok = 0;
    for (1 .. 10) {
        last unless $self->is_connected();
        syswrite($sock, C_CHAR);
        my $b = $self->_read_byte_timeout($sock, 10);
        if (defined $b) {
            # If we immediately get SOH/STX as response, proceed (put it back)
            if ($b eq SOH || $b eq STX || $b eq CAN) {
                $self->{'_ymodem_first'} = $b;
                $init_ok = 1;
                last;
            } else {
                # continue waiting for block 0
                $init_ok = 1;
                last;
            } ## end else [ if ($b eq SOH || $b eq...)]
        } ## end if (defined $b)
        $tries++;
    } ## end for (1 .. 10)
    unless ($init_ok) {
        $self->{'debug'}->ERROR(["No response from sender to YMODEM init"]);
        close $FH;
        return 0;
    }

    my $expected_blk  = 0;       # header block is block 0
    my $filesize      = undef;
    my $success       = 1;
    my $writing       = 0;
    my $bytes_written = 0;

  HEADER_LOOP:
    while ($self->is_connected()) {
        # read header/block
        my $hdr;
        if (defined $self->{'_ymodem_first'}) {
            $hdr = delete $self->{'_ymodem_first'};
        } else {
            $hdr = $self->_read_byte_timeout($sock, 60);
        }
        unless (defined $hdr) {
            $self->{'debug'}->ERROR(["Timeout waiting for YMODEM block header"]);
            $success = 0;
            last HEADER_LOOP;
        }
        if ($hdr eq CAN) {
            $self->{'debug'}->ERROR(["Sender cancelled YMODEM transfer (CAN)"]);
            $success = 0;
            last HEADER_LOOP;
        } elsif ($hdr eq EOT) {
            # Should not occur before data; but handle: ack and finish
            syswrite($sock, ACK);
            last HEADER_LOOP;
        } elsif ($hdr eq SOH || $hdr eq STX) {
            my $block_size = ($hdr eq STX) ? 1024 : 128;
            my $blknum     = $self->_read_byte_timeout($sock, 10);
            my $nblk       = $self->_read_byte_timeout($sock, 10);
            unless (defined $blknum && defined $nblk) {
                $self->{'debug'}->ERROR(["Timeout reading block number for YMODEM"]);
                $success = 0;
                last HEADER_LOOP;
            }
            my $blknum_val = ord($blknum);

            # read data
            my $data = '';
            for (1 .. $block_size) {
                my $b = $self->_read_byte_timeout($sock, 10);
                unless (defined $b) {
                    $self->{'debug'}->ERROR(["Timeout reading YMODEM data block"]);
                    $success = 0;
                    last HEADER_LOOP;
                }
                $data .= $b;
            } ## end for (1 .. $block_size)

            # read CRC16
            my $crc_hi = $self->_read_byte_timeout($sock, 10);
            my $crc_lo = $self->_read_byte_timeout($sock, 10);
            unless (defined $crc_hi && defined $crc_lo) {
                $self->{'debug'}->ERROR(["Timeout reading YMODEM CRC"]);
                $success = 0;
                last HEADER_LOOP;
            }
            my $recv_crc = $crc_hi . $crc_lo;
            my $calc_crc = _crc16_bytes($data);
            if ($calc_crc ne $recv_crc) {
                $self->{'debug'}->ERROR(["CRC mismatch on YMODEM block $blknum_val"]);
                syswrite($sock, NAK);
                next;
            }
            if ($blknum_val == $expected_blk) {
                if ($expected_blk == 0) {
                    # header block: filename\0size\0
                    my ($fname, $size_str) = split(/\0/, $data, 3);
                    if (defined $fname && $fname ne '') {
                        # parse size
                        if (defined $size_str && $size_str =~ /(\d+)/) {
                            $filesize = $1 + 0;
                        }

                        # we will use the provided $path (from caller). If needed, one could use $fname instead.
                        $writing = 1;

                        # ack header and request CRC for data blocks
                        syswrite($sock, ACK);
                        syswrite($sock, C_CHAR);
                        $expected_blk = 1;
                        next;
                    } else {
                        # empty filename => end of batch
                        syswrite($sock, ACK);
                        last HEADER_LOOP;
                    } ## end else [ if (defined $fname && ...)]
                } else {
                    # data block
                    if ($writing) {
                        # if filesize known, write only up to remaining bytes
                        if (defined $filesize) {
                            my $remaining = $filesize - $bytes_written;
                            if ($remaining <= 0) {
                                # already have enough data; ack and ignore
                            } else {
                                my $to_write = $data;
                                if (length($to_write) > $remaining) {
                                    $to_write = substr($to_write, 0, $remaining);
                                }
                                print $FH $to_write;
                                $bytes_written += length($to_write);
                            } ## end else [ if ($remaining <= 0) ]
                        } else {
                            print $FH $data;
                            $bytes_written += length($data);
                        }
                    } ## end if ($writing)
                    syswrite($sock, ACK);
                    $expected_blk = ($expected_blk + 1) & 0xFF;
                    next;
                } ## end else [ if ($expected_blk == 0)]
            } elsif ($blknum_val == (($expected_blk - 1) & 0xFF)) {
                # duplicate block - ack and continue
                syswrite($sock, ACK);
                next;
            } else {
                $self->{'debug'}->ERROR(["Unexpected YMODEM block number $blknum_val (expected $expected_blk)"]);
                syswrite($sock, CAN x 2);
                $success = 0;
                last HEADER_LOOP;
            } ## end else [ if ($blknum_val == $expected_blk)]
        } else {
            # unexpected byte - ignore and continue
            next;
        }
    } ## end HEADER_LOOP: while ($self->is_connected...)

    # After data blocks, expect EOT sequence from sender
    if ($success && $self->is_connected()) {
        my $got_eot = 0;
        for (1 .. 10) {
            my $b = $self->_read_byte_timeout($sock, 10);
            if (defined $b && $b eq EOT) {
                syswrite($sock, NAK);    # some receivers use NAK first; sender may resend EOT
                                         # wait for second EOT
                my $b2 = $self->_read_byte_timeout($sock, 10);
                if (defined $b2 && $b2 eq EOT) {
                    syswrite($sock, ACK);
                    $got_eot = 1;
                    last;
                } elsif (defined $b2 && $b2 eq ACK) {
                    $got_eot = 1;
                    last;
                } else {
                    # keep waiting
                    next;
                }
            } elsif (defined $b && $b eq CAN) {
                $self->{'debug'}->ERROR(["Sender cancelled after data (CAN)"]);
                $success = 0;
                last;
            }
        } ## end for (1 .. 10)
        unless ($got_eot) {
            $self->{'debug'}->ERROR(["No proper EOT sequence received for YMODEM"]);
            $success = 0;
        } else {
            # After EOT and ACK, sender will send an empty header block (block 0 with empty filename) to signal end of batch.
            # Read and ack it
            my $hdr = $self->_read_byte_timeout($sock, 10);
            if (defined $hdr && ($hdr eq SOH || $hdr eq STX)) {
                my $block_size = ($hdr eq STX) ? 1024 : 128;

                # read rest of block similar to above but we only need to ack it
                my $blknum = $self->_read_byte_timeout($sock, 10);
                my $nblk   = $self->_read_byte_timeout($sock, 10);
                for (1 .. $block_size) {
                    $self->_read_byte_timeout($sock, 10);
                }
                $self->_read_byte_timeout($sock, 10);
                $self->_read_byte_timeout($sock, 10);
                syswrite($sock, ACK);
            } ## end if (defined $hdr && ($hdr...))
        } ## end else
    } ## end if ($success && $self->...)

    close $FH;
    $self->output("\nFile receive complete\n");
    $self->{'debug'}->DEBUG(['End files_receive_file_ymodem']);
    return $success;
} ## end sub files_receive_file_ymodem

# CRC16-CCITT (XMODEM) calculation
sub _crc16_bytes {
    my ($data) = @_;
    my $crc = 0x0000;
    foreach my $ch (split //, $data) {
        $crc ^= (ord($ch) << 8);
        for (1 .. 8) {
            if ($crc & 0x8000) {
                $crc = (($crc << 1) & 0xFFFF) ^ 0x1021;
            } else {
                $crc = ($crc << 1) & 0xFFFF;
            }
        } ## end for (1 .. 8)
    } ## end foreach my $ch (split //, $data)
    return chr(($crc >> 8) & 0xFF) . chr($crc & 0xFF);
} ## end sub _crc16_bytes

# Read a single byte from socket with timeout (seconds)
sub _read_byte_timeout {
    my ($self, $sock, $timeout) = @_;
    $timeout ||= 10;
    my $rin = '';
    my $rout;
    my $fileno = fileno($sock);
    return undef unless defined $fileno && $fileno >= 0;
    vec($rin, $fileno, 1) = 1;
    my $nfound = select($rout = $rin, undef, undef, $timeout);

    if ($nfound > 0) {
        my $buf = '';
        my $r   = sysread($sock, $buf, 1);
        return undef unless defined $r && $r == 1;
        return $buf;
    } ## end if ($nfound > 0)
    return undef;
} ## end sub _read_byte_timeout

# Send a single XMODEM/YMODEM block (128 or 1024) using CRC16
sub _send_block {
    my ($self, $sock, $blknum, $data, $block_size) = @_;
    $block_size ||= 128;
    my $hdr = ($block_size == 1024) ? STX : SOH;
    $data .= chr(0x1A) x ($block_size - length($data));    # pad with SUB
    my $blk = $hdr . chr($blknum & 0xFF) . chr((~$blknum) & 0xFF) . $data;
    $blk .= _crc16_bytes($data);
    my $written = 0;
    my $len     = length($blk);

    while ($written < $len && $self->is_connected()) {
        my $rv = syswrite($sock, substr($blk, $written), $len - $written);
        unless (defined $rv) {
            return 0;
        }
        $written += $rv;
    } ## end while ($written < $len &&...)
    return 1;
} ## end sub _send_block

# XMODEM send (CRC mode preferred)
# Returns true on success, false on failure
sub files_send_xmodem {
    my ($self, $file) = @_;
    $self->{'debug'}->DEBUG(['Start files_send_xmodem']);
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for XMODEM send"]);
        return 0;
    }
    $self->output("\nStart Xmodem download\n");
    my $path = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file;
    my $FH;
    unless (open $FH, '<:raw', $path) {
        $self->{'debug'}->ERROR(["Cannot open file $path: $!"]);
        return 0;
    }

    # Wait for receiver request: 'C' (CRC) or NAK (checksum)
    my $init_char = _read_byte_timeout($sock, 60);
    unless (defined $init_char) {
        $self->{'debug'}->ERROR(["Timeout waiting for receiver to start XMODEM"]);
        close $FH;
        return 0;
    }

    my $use_crc = ($init_char eq C_CHAR);

    # we will always use CRC16 blocks

    my $blockno        = 1;
    my $success        = 1;
    my $retries_global = 0;
    my $eof            = 0;
    my $max_retries    = 10;

    while ($self->is_connected()) {
        my $data;
        my $n = read($FH, $data, 128);
        if (defined $n && $n > 0) {
            # send block
            my $send_ok  = 0;
            my $attempts = 0;
            while ($attempts < $max_retries && $self->is_connected()) {
                $attempts++;
                unless ($self->_send_block($sock, $blockno, $data, 128)) {
                    $self->{'debug'}->ERROR(["Failed write while sending XMODEM block $blockno"]);
                    $success = 0;
                    last;
                }
                my $resp = $self->_read_byte_timeout($sock, 10);
                unless (defined $resp) {
                    $self->{'debug'}->DEBUG(["No response for block $blockno, retry $attempts"]);
                    next;
                }
                if ($resp eq ACK) {
                    $send_ok = 1;
                    last;
                } elsif ($resp eq NAK) {
                    next;    # retransmit
                } elsif ($resp eq CAN) {
                    $self->{'debug'}->ERROR(["Received CAN during XMODEM send"]);
                    $success = 0;
                    last;
                } else {
                    # unexpected byte, retry
                    next;
                }
            } ## end while ($attempts < $max_retries...)
            unless ($send_ok) { $success = 0; last; }
            $blockno = ($blockno + 1) % 256;
        } else {
            # EOF reached
            $eof = 1;
            last;
        } ## end else [ if (defined $n && $n >...)]
    } ## end while ($self->is_connected...)

    if ($success) {
        # send EOT and wait for ACK
        my $sent = 0;
        for (1 .. 10) {
            syswrite($sock, EOT);
            my $r = $self->_read_byte_timeout($sock, 10);
            if (defined $r && $r eq ACK) { $sent = 1; last; }
        }
        unless ($sent) {
            $self->{'debug'}->ERROR(["No ACK for EOT in XMODEM send"]);
            $success = 0;
        } else {
            $self->{'debug'}->DEBUG(['XMODEM send completed']);
        }
    } ## end if ($success)

    close $FH;
    $self->output("\nFile download complete\n");
    $self->{'debug'}->DEBUG(['End files_send_xmodem']);
    return $success;
} ## end sub files_send_xmodem

# YMODEM send (simple implementation):
# - Send initial 128-byte header block with filename\0size\0
# - Then send data in 1024-byte STX blocks with CRC16
# Returns true on success, false otherwise
sub files_send_ymodem {
    my ($self, $file) = @_;
    $self->{'debug'}->DEBUG(['Start files_send_ymodem']);
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for YMODEM send"]);
        return 0;
    }

    $self->output("\nStart Ymodem download\n");
    my $path = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'} . '/' . $file;
    my $FH;
    unless (open $FH, '<:raw', $path) {
        $self->{'debug'}->ERROR(["Cannot open file $path: $!"]);
        return 0;
    }
    my $size = -s $path;
    $size = 0 unless defined $size;

    # Wait for initial 'C' (CRC) from receiver
    my $init_char = $self->_read_byte_timeout($sock, 60);
    unless (defined $init_char) {
        $self->{'debug'}->ERROR(["Timeout waiting for receiver to start YMODEM"]);
        close $FH;
        return 0;
    }

    # prepare header block (block 0)
    my $header = $file . "\0" . $size . " ";
    $header .= "\0" x (128 - length($header));

    # send header block and expect ACK then 'C'
    unless ($self->_send_block($sock, 0, $header, 128)) {
        $self->{'debug'}->ERROR(["Failed to send YMODEM header block"]);
        close $FH;
        return 0;
    }
    my $r1 = $self->_read_byte_timeout($sock, 10);
    my $r2 = $self->_read_byte_timeout($sock, 10);

    # r1 should be ACK and r2 should be 'C' to begin 1k transfer (some receivers differ)
    unless (defined $r1 && $r1 eq ACK) {
        $self->{'debug'}->ERROR(["No ACK after YMODEM header"]);
        close $FH;
        return 0;
    }

    # Send data blocks in 1K (1024) with STX header
    my $blockno = 1;
    my $success = 1;
    while ($self->is_connected()) {
        my $data;
        my $n = read($FH, $data, 1024);
        if (defined $n && $n > 0) {
            # send 1k block
            my $attempts = 0;
            my $sent_ok  = 0;
            while ($attempts < 10 && $self->is_connected()) {
                $attempts++;
                unless ($self->_send_block($sock, $blockno, $data, 1024)) {
                    $self->{'debug'}->ERROR(["Failed write while sending YMODEM block $blockno"]);
                    $success = 0;
                    last;
                }
                my $resp = $self->_read_byte_timeout($sock, 10);
                if (defined $resp && $resp eq ACK) { $sent_ok = 1; last; }
                if (defined $resp && $resp eq NAK) { next; }
                if (defined $resp && $resp eq CAN) { $self->{'debug'}->ERROR(["Received CAN during YMODEM send"]); $success = 0; last; }

                # else retry
            } ## end while ($attempts < 10 && ...)
            last unless $sent_ok && $success;
            $blockno = ($blockno + 1) % 256;
        } else {
            last;    # EOF
        }
    } ## end while ($self->is_connected...)

    if ($success) {
        # End-of-file sequence: send EOT and expect ACK, then send an empty header block (block 0 with filename "")
        my $sent = 0;
        for (1 .. 10) {
            syswrite($sock, EOT);
            my $r = _read_byte_timeout($sock, 10);
            if (defined $r && $r eq NAK) {
                # some receivers expect NAK then ACK, repeat
                next;
            } elsif (defined $r && $r eq ACK) {
                $sent = 1;
                last;
            }
        } ## end for (1 .. 10)
        unless ($sent) {
            $self->{'debug'}->ERROR(["No ACK for EOT in YMODEM send"]);
            $success = 0;
        } else {
            # Send final empty header (indicates end of batch)
            my $empty_header = "\0" x 128;
            unless (_send_block($sock, 0, $empty_header, 128)) {
                $self->{'debug'}->ERROR(["Failed to send final empty YMODEM header"]);
                $success = 0;
            } else {
                my $r = _read_byte_timeout($sock, 10);    # expect ACK
                unless (defined $r && $r eq ACK) {
                    $self->{'debug'}->ERROR(["No ACK after final YMODEM header"]);
                    $success = 0;
                }
            } ## end else
        } ## end else
    } ## end if ($success)

    close $FH;
    $self->output("\nFile download complete\n");
    $self->{'debug'}->DEBUG(['End files_send_ymodem']);
    return $success;
} ## end sub files_send_ymodem

# files_send_file: route to appropriate pure-perl sender (X/Y) or Z stub
sub files_send_file {
    my ($self, $file, $protocol) = @_;

    my $success = TRUE;
    $self->{'debug'}->DEBUG(['Start Send File']);
    unless ($self->{'local_mode'}) {    # No file transfer in local mode
        if ($protocol == YMODEM) {
            $self->{'debug'}->DEBUG(["Send file $file with Ymodem (Perl)"]);
            $success = $self->files_send_ymodem($file);
        } elsif ($protocol == ZMODEM) {
            $self->{'debug'}->DEBUG(["Send file $file with Zmodem (stub)"]);
            $success = $self->files_send_zmodem($file);
        } else {    # Xmodem assumed
            $self->{'debug'}->DEBUG(["Send file $file with Xmodem (Perl)"]);
            $success = $self->files_send_xmodem($file);
        }
        chdir $self->{'CONF'}->{'BBS ROOT'};
    } else {
        $self->output("Download not allowed in local mode\n");
        $success = 0;
    }
    $self->{'debug'}->DEBUG(['End Send File']);
    return ($success);
} ## end sub files_send_file

sub _run_on_socket {
    my ($self, $cmd, $args, $cwd) = @_;
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket"]);
        return 0;
    }
    my $fileno = fileno($sock);
    unless (defined $fileno && $fileno >= 0) {
        $self->{'debug'}->ERROR(["Invalid client socket fileno"]);
        return 0;
    }

    my $pid = fork();
    if (!defined $pid) {
        $self->{'debug'}->ERROR(["fork failed: $!"]);
        return 0;
    }

    if ($pid == 0) {
        # child: attach socket to STDIN/STDOUT/STDERR and exec the command
        # ensure we don't run any parent cleanup handlers
        local $SIG{CHLD} = 'DEFAULT';

        # Duplicate socket fd onto STDIN/STDOUT/STDERR
        open(STDIN,  '<&', $fileno) or POSIX::_exit(1);
        open(STDOUT, '>&', $fileno) or POSIX::_exit(1);
        open(STDERR, '>&', $fileno) or POSIX::_exit(1);
        binmode(STDIN);
        binmode(STDOUT);
        binmode(STDERR);
        if ($cwd) {
            chdir $cwd or POSIX::_exit(1);
        }

        # exec (this replaces the child)
        exec $cmd, @{ $args // [] };

        # if exec fails
        POSIX::_exit(1);
    } ## end if ($pid == 0)

    # parent: wait for child, return success based on exit status
    waitpid($pid, 0);
    my $status = $?;    # full status
    if ($status == -1) {
        $self->{'debug'}->ERROR(["Failed to waitpid for $cmd: $!"]);
        return 0;
    }
    my $exitcode = ($status >> 8) & 0xFF;
    if ($exitcode != 0) {
        $self->{'debug'}->DEBUG(["$cmd exited with code $exitcode"]);
    }
    return $exitcode == 0 ? 1 : 0;
} ## end sub _run_on_socket

sub files_send_zmodem {
    my ($self, $file) = @_;
    $self->{'debug'}->DEBUG(['Start files_send_zmodem (using lrzsz)']);

    # Require lrzsz (sz) to be installed on the system.
    # sz will write to the socket (which we've dup'd to STDOUT in child).
    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for ZMODEM send"]);
        return 0;
    }

    $self->output("\nStart Zmodem file download\n");

    # full path to file on server
    my $path = $file;
    unless (-e $path) {
        $self->{'debug'}->ERROR(["File not found for ZMODEM send: $path"]);
        return 0;
    }

    # Use sz --zmodem --binary --quiet --resume <file>
    # note: --resume is helpful if client requests resume. Adjust flags per your lrzsz version.
    my @args = ('--zmodem', '--binary', '--quiet', '--resume', $path);

    my $ok = $self->_run_on_socket('sz', \@args);
    $self->output("\nFile download complete\n");
    $self->{'debug'}->DEBUG(['End files_send_zmodem (using lrzsz)']);
    return $ok;
} ## end sub files_send_zmodem

sub files_receive_file_zmodem {
    my ($self, $file) = @_;
    $self->{'debug'}->DEBUG(['Start files_receive_file_zmodem (using lrzsz)']);

    my $sock = $self->{'cl_socket'};
    unless ($sock) {
        $self->{'debug'}->ERROR(["No client socket for ZMODEM receive"]);
        return 0;
    }

    $self->output("\nStart Zmodem file upload\n");

    # When rz receives files it writes them into the current working directory.
    # Use the destination directory from config (same place other uploads are stored).
    my $dest_dir = $self->{'CONF'}->{'BBS ROOT'} . '/' . $self->{'CONF'}->{'FILES PATH'} . '/' . $self->{'USER'}->{'file_category_path'};

    # ensure directory exists
    unless (-d $dest_dir) {
        File::Path::mkpath($dest_dir);
        if ($@) {
            $self->{'debug'}->ERROR(["Failed to create dest dir $dest_dir: $@"]);
            return 0;
        }
    } ## end unless (-d $dest_dir)

    # We will chdir in the child before exec so the received file lands in $dest_dir.
    # Use rz --binary --quiet. Depending on lrzsz version you may want --overwrite or --keep
    my @args = ('--binary', '--overwrite', '--quiet');

    my $ok = $self->_run_on_socket('rz', \@args, $dest_dir);

    $self->output("\nFile upload complete\n");
    $self->{'debug'}->DEBUG(['End files_receive_file_zmodem (using lrzsz)']);
    return $ok;
} ## end sub files_receive_file_zmodem

 

# package BBS::Universal::Messages;

sub messages_initialize {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start Messages Initialize']);
    $self->{'debug'}->DEBUG(['End Messages Initialize']);
    return ($self);
} ## end sub messages_initialize

sub messages_forum_categories {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Messages Forum Categories']);
    my $command = '';
    my $id;
    my $sth      = $self->{'dbh'}->prepare('SELECT * FROM message_categories ORDER BY description');
    my $category = $self->{'USER'}->{'forum_category'};
    $sth->execute();    # $self->{'USER'}->{'forum_category'});
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Return to Forum Menu' },
    };
    my @menu_choices = @{ $self->{'MENU CHOICES'} };

    while (my $result = $sth->fetchrow_hashref()) {
        if ($self->check_access_level($result->{'access_level'})) {
            $mapping->{ shift(@menu_choices) } = {
                'command'      => $result->{'name'},
                'id'           => $result->{'id'},
                'color'        => ($category == $result->{'id'}) ? 'GREEN' : 'WHITE',
                'access_level' => $result->{'access_level'},
                'text'         => $result->{'description'},
            };
        } ## end if ($self->check_access_level...)
    } ## end while (my $result = $sth->...)
    $sth->finish();
    $self->show_choices($mapping);
    $self->prompt('Choose Forum Category');
    my $key;
    do {
        $key = uc($self->get_key(SILENT, BLOCKING));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    if ($key eq chr(3)) {
        $command = 'DISCONNECT';
    } else {
        $id      = $mapping->{$key}->{'id'};
        $command = $mapping->{$key}->{'command'};
    }
    return ($command) if ($key eq 'Z');
    if ($self->is_connected() && $command ne 'DISCONNECT') {
        $self->output($command);
        $sth = $self->{'dbh'}->prepare('UPDATE users SET forum_category=? WHERE id=?');
        $sth->execute($id, $self->{'USER'}->{'id'});
        $sth->finish();
        $self->{'USER'}->{'forum_category'} = $id;
        $command = 'BACK';
    } ## end if ($self->is_connected...)
    $self->{'debug'}->DEBUG(['End Messages Forum Categories']);
    return ($command);
} ## end sub messages_forum_categories

sub messages_list_messages {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Messages List Messages']);
    my $id;
    my $command;
    my $forum_category = $self->{'USER'}->{'forum_category'};
    my $sth            = $self->{'dbh'}->prepare('SELECT id,from_id,category,author_fullname,author_nickname,author_username,title,created FROM messages_view WHERE category=? ORDER BY created DESC');
    my @index;
    $sth->execute($forum_category);
    if ($sth->rows()) {
        while (my $record = $sth->fetchrow_hashref) {
            push(@index, $record);
        }
        $sth->finish();
        my $result;
        my $count = 0;
        do {
            $result = $index[$count];
            $sth    = $self->{'dbh'}->prepare('SELECT message FROM messages_view WHERE id=? ORDER BY created DESC');
            $sth->execute($result->{'id'});
            $result->{'message'} = $sth->fetchrow_array();
            $sth->finish();
            my $mode = $self->{'USER'}->{'text_mode'};
            if ($mode eq 'ANSI') {
                $self->output("[% CLS %][% HORIZONTAL RULE MAGENTA %][% B_MAGENTA %][% BLACK %]" . $self->pad_center('FORUM MESSAGE' . $self->{'USER'}->{'max_columns'}) . "[% RESET %]\n");
                $self->output('[% B_BRIGHT GREEN %][% BLACK %] CATEGORY [% RESET %] [% BOLD %][% GREEN %][% FORUM CATEGORY %][% RESET %]' . "\n");
                $self->output('[% BRIGHT WHITE %][% B_BLUE %]   Author [% RESET %] ');
                $self->output(($result->{'prefer_nickname'}) ? $result->{'author_nickname'} : $result->{'author_fullname'});
                $self->output(' (' . $result->{'author_username'} . ')' . "\n");
                $self->output('[% BRIGHT WHITE %][% B_BLUE %]    Title [% RESET %] ' . $result->{'title'} . "\n");
                $self->output('[% BRIGHT WHITE %][% B_BLUE %]  Created [% RESET %] ' . $self->users_get_date($result->{'created'}) . "\n\n");
                $self->output($result->{'message'}) if ($self->{'USER'}->{'read_message'});
                $self->output("\n[% HORIZONTAL RULE MAGENTA %]\n");
            } elsif ($mode eq 'PETSCII') {
                $self->output("[% CLS %][% GREEN %]== FORUM " . '=' x ($self->{'USER'}->{'max_columns'} - 7) . "[% RESET %]\n");
                $self->output('[% GREEN   %] CATEGORY [% RESET %] [% FORUM CATEGORY %]' . "\n");
                $self->output('[% YELLOW %]   Author [% RESET %] ');
                $self->output(($result->{'prefer_nickname'}) ? $result->{'author_nickname'} : $result->{'author_fullname'});
                $self->output(' (' . $result->{'author_username'} . ')' . "\n");
                $self->output('[% YELLOW %]    Title [% RESET %] ' . $result->{'title'} . "\n");
                $self->output('[% YELLOW %]  Created [% RESET %] ' . $self->users_get_date($result->{'created'}) . "\n\n");
                $self->output($result->{'message'}) if ($self->{'USER'}->{'read_message'});
                $self->output("\n[% GREEN %]" . '=' x $self->{'USER'}->{'max_columns'} . "[% RESET %]\n");
            } else {
                $self->output("[% CLS %]== FORUM " . '=' x ($self->{'USER'}->{'max_columns'} - 7) . "\n");
                $self->output(' CATEGORY > [% FORUM CATEGORY %]' . "\n");
                $self->output('  Author:  ');
                $self->output(($result->{'prefer_nickname'}) ? $result->{'nickname'} : $result->{'author_fullname'});
                $self->output(' (' . $result->{'author_username'} . ')' . "\n");
                $self->output('   Title:  ' . $result->{'title'} . "\n");
                $self->output(' Created:  ' . $self->users_get_date($result->{'created'}) . "\n\n");
                $self->output($result->{'message'}) if ($self->{'USER'}->{'read_message'});
                $self->output("\n" . '=' x $self->{'USER'}->{'max_columns'} . "\n");
            } ## end else [ if ($mode eq 'ANSI') ]
            my $mapping = {
                'Z' => { 'id' => $result->{'id'}, 'command' => 'BACK', 'color' => 'WHITE',       'access_level' => 'USER', 'text' => 'Return to the Forum Menu' },
                'N' => { 'id' => $result->{'id'}, 'command' => 'NEXT', 'color' => 'BRIGHT BLUE', 'access_level' => 'USER', 'text' => 'Next Message' },
            };
            if ($self->{'USER'}->{'post_message'}) {
                $mapping->{'R'} = { 'id' => $result->{'id'}, 'command' => 'REPLY', 'color' => 'BRIGHT GREEN', 'access_level' => 'USER', 'text' => 'Reply' };
            } ## end if ($self->{'USER'}->{...})
            if ($self->{'USER'}->{'remove_message'}) {
                $mapping->{'D'} = { 'id' => $result->{'id'}, 'command' => 'DELETE', 'color' => 'RED', 'access_level' => 'JUNIOR SYSOP', 'text' => 'Delete Message' };
            } ## end if ($self->{'USER'}->{...})
            $self->show_choices($mapping);
            $self->prompt('Choose');
            my $key;
            do {
                $key = uc($self->get_key(SILENT, FALSE));
            } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
            if ($key eq chr(3)) {
                $id      = undef;
                $command = 'DISCONNECT';
            } else {
                $id      = $mapping->{$key}->{'id'};
                $command = $mapping->{$key}->{'command'};
            }
            $self->output($command);
            if ($command eq 'REPLY') {
                my $message = $self->messages_edit_message('REPLY', $result);
                push(@index, $message);
                $count = 0;
            } elsif ($command eq 'DELETE') {
                $self->messages_delete_message($result);
                delete($index[$count]);
            } else {
                $count++;
            }
            unless ($self->{'local_mode'} || $self->{'sysop'} || $self->is_connected()) {
                $command = 'DISCONNECT';
            }
        } until ($count >= scalar(@index) || $command =~ /^(DISCONNECT|BACK)$/);
    } else {
		$self->output("\nNo messages\n\nPress any key\n");
		$self->get_key(SILENT, BLOCKING);
	} # end if ($sth->rows())
    $self->{'debug'}->DEBUG(['End Messages List Messages']);
    return (TRUE);
} ## end sub messages_list_messages

sub messages_edit_message {
    my $self        = shift;
    my $mode        = shift;
    my $old_message = (scalar(@_)) ? shift : undef;

    $self->{'debug'}->DEBUG(['Start Messages Edit Message']);
    my $message;
    if ($mode eq 'ADD') {
        $self->{'debug'}->DEBUG(['  Add Message']);
        $self->output("Add New Message\n");
        $message = $self->messages_text_editor();
        if (defined($message)) {
            $message->{'from_id'}  = $self->{'USER'}->{'id'};
            $message->{'category'} = $self->{'USER'}->{'forum_category'};
            my $sth = $self->{'dbh'}->prepare('INSERT INTO messages (category, from_id, title, message) VALUES (?, ?, ?, ?)');
            $sth->execute($message->{'category'}, $message->{'from_id'}, $message->{'title'}, $message->{'message'});
            $sth->finish();
            if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
                $self->output('[% GREEN %]Message Saved[% RESET %]');
            } else {
                $self->output('Message Saved');
            }
            $message->{'id'} = $sth->last_insert_id();
            sleep 1;
        } ## end if (defined($message))
    } elsif ($mode eq 'REPLY') {
        $self->output("  Edit Message\n");
        unless ($old_message->{'title'} =~ /^Re: /) {
            $old_message->{'title'} = 'Re: ' . $old_message->{'title'};
            $old_message->{'message'} =~ s/^(.*)/\> $1/g;
        }
        $self->output('-' x $self->{'USER'}->{'max_columns'} . "\n");
        $message = $self->messages_text_editor($old_message);
        if (defined($message)) {
            $message->{'from_id'}  = $self->{'USER'}->{'id'};
            $message->{'title'}    = $old_message->{'title'};
            $message->{'category'} = $self->{'USER'}->{'forum_category'};
            my $sth = $self->{'dbh'}->prepare('INSERT INTO messages (category, from_id, title, message) VALUES (?, ?, ?, ?)');
            $sth->execute($message->{'category'}, $message->{'from_id'}, $message->{'title'}, $message->{'message'});
            $sth->finish();
            if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
                $self->output('[% GREEN %]Message Saved[% RESET %]');
            } else {
                $self->output('Message Saved');
            }
            $message->{'id'} = $sth->last_insert_id();
            sleep 1;
        } ## end if (defined($message))
    } else {    # EDIT
        $self->output("  Edit Message\n");
        $self->output('-' x $self->{'USER'}->{'max_columns'} . "\n");
        $message = $self->messages_text_editor($old_message);
        if (defined($message)) {
            my $sth = $self->{'dbh'}->prepare('UPDATE messages SET message=? WHERE id=>');
            $sth->execute($message->{'message'}, $message->{'id'});
            $sth->finish();
            $message->{'id'} = $old_message->{'id'};
            if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
                $self->output('[% GREEN %]Message Saved[% RESET %]');
            } else {
                $self->output('Message Saved');
            }
            sleep 1;
        } ## end if (defined($message))
    } ## end else [ if ($mode eq 'ADD') ]
    $self->{'debug'}->DEBUG(['End Messages Edit Message']);
    return ($message);
} ## end sub messages_edit_message

sub messages_delete_message {
    my $self    = shift;
    my $message = shift;

    $self->{'debug'}->DEBUG(['Start Messages Delete Message']);
    my $response = FALSE;
    $self->output("\n\nReally Delete This Message?  ");
    if ($self->decision() && defined($message)) {
        my $sth = $self->{'dbh'}->prepare('UPDATE messages SET hidden=TRUE WHERE id=?');
        $sth->execute($message->{'id'});
        $sth->finish();
        $response = TRUE;
    } ## end if ($self->decision() ...)
    $self->{'debug'}->DEBUG(['End Messages Delete Message']);
    return ($response);
} ## end sub messages_delete_message

sub messages_text_editor {
    my $self    = shift;
    my $message = (scalar(@_)) ? shift : undef;

    $self->{'debug'}->DEBUG(['Start Messages Text Editor']);
    my $title = '';
    my $text  = '';
    if ($self->{'local_mode'} || $self->is_connected()) {
        if (defined($message)) {
            $title = $message->{'title'};
            $text  = $message->{'message'};
            $self->prompt('Message');
            $text = $self->messages_text_edit($title, $text);
        } else {
            $self->prompt('Title');
            $title = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => '' });
            return (undef) unless (defined($title) && $title ne '');
            $self->prompt('Message');
            $text = $self->messages_text_edit($title);
        } ## end else [ if (defined($message))]
        if (defined($text) && defined($title)) {
            $self->{'debug'}->DEBUG(['End Messages Text Editor']);
            return (
                {
                    'title'   => $title,
                    'message' => $text,
                }
            );
        } ## end if (defined($text) && ...)
    } ## end if ($self->{'local_mode'...})
    $self->{'debug'}->DEBUG(['  Abort', 'End Messages Text Editor']);
    return (undef);
} ## end sub messages_text_editor

sub messages_text_edit {
    my $self  = shift;
    my $title = (scalar(@_)) ? shift : undef;
    my $text  = (scalar(@_)) ? shift : undef;

    $self->{'debug'}->DEBUG(['Start Messages Text Edit']);
    my $columns   = $self->{'USER'}->{'max_columns'};
    my $text_mode = $self->{'USER'}->{'text_mode'};
    my @lines;
    if (defined($text) && $text ne '') {
        @lines = split(/\n$/, $text . "\n");
    }
    my $save   = FALSE;
    my $cancel = FALSE;
    do {
        my $counter = 0;
        if ($text_mode eq 'ANSI') {
            $self->output('[% CLS %][% HORIZONTAL RULE BRIGHT GREEN %][% RESET %]' . "\n");
            $self->output('[% CYAN %]Subject[% RESET %]:  ' . $title . "\n");
            $self->output('[% BRIGHT GREEN %]' . '-' x $columns . '[% RESET %]' . "\n");
            $self->output("Type a command on a line by itself\n");
            $self->output('  :[% YELLOW %]S[% RESET %] = Save and exit' . "\n");
            $self->output('  :[% RED %]Q[% RESET %] = Cancel, do not save' . "\n");
            $self->output('  :[% BRIGHT BLUE %]E[% RESET %] = Edit a specific line number (:E5 edits line 5)' . "\n");
            $self->output('[% HORIZONTAL RULE BRIGHT GREEN %][% RESET %]' . "\n");
        } elsif ($text_mode eq 'PETSCII') {
            $self->output('[% CLEAR %][% LIGHT GREEN %]' . '=' x $columns . "\n");
            $self->output('[% CYAN %]Subject[% WHITE %]:  ' . $title . "\n");
            $self->output('[% LIGHT GREEN %]' . '-' x $columns . "\n");
            $self->output('[% WHITE %]Type a command on a line by itself' . "\n");
            $self->output('  :[% YELLOW %]S[% WHITE %] = Save and exit' . "\n");
            $self->output('  :[% RED %]Q[% WHITE %] = Cancel, do not save' . "\n");
            $self->output('  :[% BLUE %]E[% WHITE %] = Edit a specific line number (:E5 edits line 5)' . "\n");
            $self->output('=' x $columns . "\n");
        } elsif ($text_mode eq 'ATASCII') {
            $self->output('[% CLEAR %]' . '=' x $columns . "\n");
            $self->output("Subject:  $title\n");
            $self->output('-' x $columns . "\n");
            $self->output("Type a command on a line by itself\n");
            $self->output("  :S = Save and exit\n");
            $self->output("  :Q = Cancel, do not save\n");
            $self->output("  :E = Edit a specific line number (:E5 edits line 5)\n");
            $self->output('=' x $columns . "\n");
        } else {    # ASCII
            $self->output('[% CLEAR %]' . '=' x $columns . "\n");
            $self->output("Subject:  $title\n");
            $self->output('-' x $columns . "\n");
            $self->output("Type a command on a line by itself\n");
            $self->output("  :S = Save and exit\n");
            $self->output("  :Q = Cancel, do not save\n");
            $self->output("  :E = Edit a specific line number (:E5 edits line 5)\n");
            $self->output('=' x $columns . "\n");
        } ## end else [ if ($text_mode eq 'ANSI')]

        foreach my $line (@lines) {
            if ($text_mode eq 'ANSI') {
                $self->output(sprintf('%s%03d%s %s', '[% CYAN %]', ($counter + 1), '[% RESET %]', $line) . "\n");
            } else {
                $self->output(sprintf('%03d %s', ($counter + 1), $line) . "\n");
            }
            $counter++;
        } ## end foreach my $line (@lines)
        my $menu = FALSE;
        do {
            if ($text_mode eq 'ANSI') {
                $self->output(sprintf('%s%03d%s ', '[% CYAN %]', ($counter + 1), '[% RESET %]'));
            } elsif ($text_mode eq 'PETSCII') {
                $self->output(sprintf('%s%03d%s ', '[% CYAN %]', ($counter + 1), '[% WHITE %]'));
            } else {
                $self->output(sprintf('%03d ', ($counter + 1)));
            }
            $text = $self->get_line({ 'type' => STRING, 'max' => $self->{'USER'}->{'max_columns'}, 'default' => '' });

            if ($text =~ /^\:(.)(.*)/i) {    # Process command
                my $command = uc($1);
                if ($command eq 'E') {
                    my $line_number = $2;
                    if ($line_number > 0) {
                        if ($text_mode eq 'ANSI') {
                            $self->output("\n" . sprintf('%s%03d%s ', '[% CYAN %]', $line_number, '[% RESET %]'));
                        } elsif ($text_mode eq 'PETSCII') {
                            $self->output(sprintf('%s%03d%s ', '[% CYAN %]', $line_number, '[% WHITE %]'));
                        } else {
                            $self->output("\n" . sprintf('%03d ', $line_number));
                        }
                        my $line = $self->get_line({ 'type' => NUMERIC, 'max' => 3, 'default' => $self->{'USER'}->{'max_columns'}, $lines[$line_number - 1] });
                        $lines[$line_number - 1] = $line;
                    } ## end if ($line_number > 0)
                    $menu = TRUE;
                } elsif ($command eq 'S') {
                    $save = TRUE;
                } elsif ($command eq 'Q') {
                    $cancel = TRUE;
                }
            } else {
                chomp($text);
                push(@lines, $text);
                $counter++;
            }
        } until ($menu || $save || $cancel || !$self->is_connected());
    } until ($save || $cancel || !$self->is_connected());
    if ($save) {
        $text = join("\n", @lines);
    } else {
        undef($text);
    }
    $self->{'debug'}->DEBUG(['End Messages Text Edit']);
    return ($text);
} ## end sub messages_text_edit

 

# package BBS::Universal::News;

sub news_initialize {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start News Initialize']);
    $self->{'rss'} = XML::RSS::LibXML->new();
    $self->{'debug'}->DEBUG(['End News Initialize']);
    return ($self);
} ## end sub news_initialize

sub news_display {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start News Display']);
    my $news   = "\n";
    my $format = Text::Format->new(
        'columns'     => $self->{'USER'}->{'max_columns'} - 1,
        'tabstop'     => 4,
        'extraSpace'  => TRUE,
        'firstIndent' => 2,
    );
    {
        my $dt = DateTime->now;
        if ($dt->month == 7 && $dt->day == 10) {
            my $today;
            if ($self->{'USER'}->{'DATE FORMAT'} eq 'DAY/MONTH/YEAR') {
                $today = $dt->dmy;
            } elsif ($self->{'USER'}->{'DATE FORMAT'} eq 'YEAR/MONTH/DAY') {
                $today = $dt->ymd;
            } else {
                $today = $dt->mdy;
            }
            if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
                $news .= "$today - [% B_GREEN %][% BLACK %] Today is the author's birthday! [% RESET %] " . '[% PARTY POPPER %]' . "\n\n" . $format->format("Great news!  Happy Birthday to Richard Kelsch (the author of BBS::Universal)!");
            } else {
                $news .= "* $today - Today is the author's birthday!\n\n" . $format->format("Great news!  Happy Birthday to Richard Kelsch (the author of BBS::Universal)!");
            }
            $news .= "\n";
        } ## end if ($dt->month == 7 &&...)
    }
    my $df = $self->{'USER'}->{'date_format'};
    $df =~ s/YEAR/\%Y/;
    $df =~ s/MONTH/\%m/;
    $df =~ s/DAY/\%d/;
    my $sql = q{
          SELECT news_id,
                 news_title,
                 news_content,
                 DATE_FORMAT(news_date,?) AS newsdate
            FROM news
        ORDER BY news_date DESC
    };
    my $sth = $self->{'dbh'}->prepare($sql);
    $sth->execute($df);

    if ($sth->rows > 0) {
        while (my $fields = $sth->fetchrow_hashref()) {
            if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
                $news .= $fields->{'newsdate'} . ' - [% B_GREEN %][% BLACK %] ' . $fields->{'news_title'} . " [% RESET %]\n\n" . $format->format($fields->{'news_content'});
            } else {
                $news .= '* ' . $fields->{'newsdate'} . ' - ' . $fields->{'news_title'} . "\n\n" . $format->format($fields->{'news_content'});
            }
            $news .= "\n";
        } ## end while (my $fields = $sth->...)
    } else {
        $news = "No News\n\n";
    }
    $sth->finish();
    $self->output($news);
    $self->output("Press a key to continue ... ");
    $self->get_key(SILENT, BLOCKING);
    $self->{'debug'}->DEBUG(['End News Display']);
    return (TRUE);
} ## end sub news_display

sub news_summary {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start News Summary']);
    my $format = $self->{'USER'}->{'date_format'};
    $format =~ s/YEAR/\%Y/;
    $format =~ s/MONTH/\%m/;
    $format =~ s/DAY/\%d/;
    my $sql = q{
          SELECT news_id,
                 news_title,
                 news_content,
                 DATE_FORMAT(news_date,?) AS newsdate
            FROM news
        ORDER BY news_date DESC};
    my $sth = $self->{'dbh'}->prepare($sql);
    $sth->execute($format);

    if ($sth->rows > 0) {
        my $table = Text::SimpleTable->new(10, $self->{'USER'}->{'max_columns'} - 14);
        $table->row('DATE', 'TITLE');
        $table->hr();
        while (my $row = $sth->fetchrow_hashref()) {
            $table->row($row->{'newsdate'}, $row->{'news_title'});
        }
        my $mode = $self->{'USER'}->{'text_mode'};
        if ($mode eq 'ANSI') {
            my $text = $table->boxes2('BRIGHT BLUE')->draw();
            my $ch   = colored(['bright_yellow'], 'DATE');
            $text =~ s/DATE/$ch/;
            $ch = colored(['bright_yellow'], 'TITLE');
            $text =~ s/TITLE/$ch/;
            $self->output($text);
        } elsif ($mode eq 'ATASCII') {
            my $text = $self->color_border($table->boxes->draw(), 'BLUE');
            $self->output($text);
        } elsif ($mode eq 'PETSCII') {
            my $text = $table->boxes->draw();
            while ($text =~ / (DATE|TITLE) /s) {
                my $ch  = $1;
                my $new = '[% YELLOW %]' . $ch . '[% RESET %]';
                $text =~ s/ $ch / $new /gs;
            }
            $text = $self->color_border($text, 'LIGHT BLUE');
            $self->output($text);
        } else {
            $self->output($table->draw());
        }
    } else {
        $self->output('No News');
    }
    $sth->finish();
    $self->output("\nPress a key to continue ... ");
    $self->get_key(SILENT, BLOCKING);
    $self->{'debug'}->DEBUG(['End News Summary']);
    return (TRUE);
} ## end sub news_summary

sub news_rss_categories {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start News RSS Categories']);
    my $command = '';
    my $id;
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM rss_feed_categories WHERE id<>? ORDER BY description');
    $sth->execute($self->{'USER'}->{'rss_category'});
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Return to News Menu' },
    };
    my @menu_choices = @{$self->{'MENU CHOICES'}};

    while (my $result = $sth->fetchrow_hashref()) {
        if ($self->check_access_level($result->{'access_level'})) {
            $mapping->{ shift(@menu_choices) } = {
                'command'      => $result->{'title'},
                'id'           => $result->{'id'},
                'color'        => 'WHITE',
                'access_level' => $result->{'access_level'},
                'text'         => $result->{'description'},
            };
        } ## end if ($self->check_access_level...)
    } ## end while (my $result = $sth->...)
    $sth->finish();
    $self->show_choices($mapping);
    $self->prompt('Choose World News Feed Category');
    my $key;
    do {
        $key = uc($self->get_key(SILENT, BLOCKING));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    if ($key eq chr(3)) {
        return ('DISCONNECT');
    } else {
        $id      = $mapping->{$key}->{'id'};
        $command = $mapping->{$key}->{'command'};
    }
    if ($self->is_connected() && $command ne 'BACK') {
        $self->output($command);
        $sth = $self->{'dbh'}->prepare('UPDATE users SET rss_category=? WHERE id=?');
        $sth->execute($id, $self->{'USER'}->{'id'});
        if ($sth->err) {
            $self->{'debug'}->ERROR([$sth->errstr]);
        }
        $sth->finish();
        $self->{'USER'}->{'rss_category'} = $id;
        $command = 'BACK';
    } ## end if ($self->is_connected...)
    $self->{'debug'}->DEBUG(['End News RSS Categories']);
    return ($command);
} ## end sub news_rss_categories

sub news_rss_feeds {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start News RSS Feeds']);
    my $mode = $self->{'USER'}->{'text_mode'};
    my $sth  = $self->{'dbh'}->prepare('SELECT * FROM rss_view WHERE category=? ORDER BY title');
    $sth->execute($self->{'USER'}->{'rss_category'});
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Return to News Menu' },
    };
    my @menu_choices = @{$self->{'MENU CHOICES'}};
    while (my $result = $sth->fetchrow_hashref()) {
        if ($self->check_access_level($result->{'access_level'})) {
            $mapping->{ shift(@menu_choices) } = {
                'command'      => $result->{'title'},
                'id'           => $result->{'id'},
                'color'        => 'WHITE',
                'access_level' => $result->{'access_level'},
                'text'         => $result->{'title'},
                'url'          => $result->{'url'},
            };
        } ## end if ($self->check_access_level...)
    } ## end while (my $result = $sth->...)
    $sth->finish();
    $self->show_choices($mapping);
    $self->prompt('Choose World News Feed');
    my $id;
    my $key;
    my $command;
    my $url;
    my $text;
    do {
        $key = uc($self->get_key(SILENT, BLOCKING));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    if ($key eq chr(3)) {
        $command = 'DISCONNECT';
    } else {
        $id      = $mapping->{$key}->{'id'};
        $command = $mapping->{$key}->{'command'};
        $url     = $mapping->{$key}->{'url'};
        $text    = $mapping->{$key}->{'text'};
    } ## end else [ if ($key eq chr(3)) ]
    if ($self->is_connected() && $command ne 'DISCONNECT' && $command ne 'BACK') {
        $self->output($self->news_title_colorize($text));
        my $rss_string = `curl -s $url`;
        my $rss;
        my $list;
        eval {
            $rss = XML::RSS::LibXML->new;
            $rss->parse($rss_string);
            $list = $rss->items;
        };

        if ($@) {
            $self->{'debug'}->ERROR([$@]);
            $self->output("ERROR > $@");
        } else {
            my $text;
            foreach my $item (@{$list}) {
                last unless ($self->is_connected());
                if ($mode eq 'ANSI') {
                    $text .= '[% NAVY %]' . '━' x $self->{'USER'}->{'max_columns'} . "[% RESET %]\n";
                    $text .= '[% BRIGHT WHITE %][% B_TEAL %]       Title [% RESET %] [% GREEN %]' . $self->html_to_text($item->{'title'}) . "[% RESET %]\n";
                    $text .= '[% BRIGHT WHITE %][% B_TEAL %] Description [% RESET %] ' . $self->html_to_text($item->{'description'}) . "\n";
                    $text .= '[% BRIGHT WHITE %][% B_TEAL %]        Link [% RESET %] [% YELLOW %]' . $item->{'link'} . "[% RESET %]\n";
                } elsif ($mode eq 'PETSCII') {
                    $text .= '[% YELLOW %]       Title [% RESET %] [% GREEN %]' . $self->html_to_text($item->{'title'}) . "\n";
                    $text .= '[% YELLOW %] Description [% RESET %] ' . $self->html_to_text($item->{'description'}) . "\n";
                    $text .= '[% YELLOW %]        Link [% RESET %] [% YELLOW %]' . $item->{'link'} . "[% RESET %]\n";
                } else {
                    $text .= '      Title:  ' . $item->{'title'} . "\n";
                    $text .= 'Description:  ' . $self->html_to_text($item->{'description'}) . "\n";
                    $text .= '       Link:  ' . $item->{'link'} . "\n\n";
                }
            } ## end foreach my $item (@{$list})
            $self->output("\n\n" . $text);
            $self->output("\n\nPress any key to continue\n");
            $self->get_key(SILENT, BLOCKING);
        } ## end else [ if ($@) ]
        $command = 'BACK';
    } ## end if ($self->is_connected...)
    $self->{'debug'}->DEBUG(['End News RSS Feeds']);
    return ($command);
} ## end sub news_rss_feeds

sub news_title_colorize {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start News Title Colorize']);
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        if ($text =~ /fox news/i) {
            my $fox = '[% B_BLUE %][% BRIGHT WHITE %]FOX NEW[% B_RED %]S[% RESET %]';
            $text =~ s/fox news/$fox/gsi;
        } elsif ($text =~ /cnn news/i) {
            my $cnn = '[% BRIGHT RED %]CNN News[% RESET %]';
            $text =~ s/cnn/$cnn/gsi;
        } elsif ($text =~ /cbs news/i) {
            my $cbs = '[% BRIGHT BLUE %]CBS News[% RESET %]';
            $text =~ s/cbs/$cbs/gsi;
        } elsif ($text =~ /reuters/i) {
            my $reuters = '[% B_BRIGHT WHITE %][% ORANGE %]✺ [% BLACK %] Reuters[% RESET %]';
            $text =~ s/reuters/$reuters/gsi;
        } elsif ($text =~ /npr/i) {
            my $npr = '[% B_BRIGHT RED %][% BRIGHT WHITE %]n[% B_BLACK %]p[% B_BRIGHT BLUE %]r[% RESET %]';
            $text =~ s/npr/$npr/gsi;
        } elsif ($text =~ /bbc news/i) {
            my $bbc = '[% BRIGHT RED %][% B_BRIGHT WHITE %]BBC NEWS[% RESET %]';
            $text =~ s/bbc news/$bbc/gsi;
        } elsif ($text =~ /wired/i) {
            my $wired = '[% B_BLACK %][% BRIGHT WHITE %]W[% B_BRIGHT WHITE %][% BLACK %]I[% B_BLACK %][% BRIGHT WHITE %]R[% B_BRIGHT WHITE %][% BLACK %]E[% B_BLACK %][% BRIGHT WHITE %]D[% RESET %]';
            $text =~ s/wired/$wired/gsi;
        } elsif ($text =~ /daily wire/i) {
            my $dw = '[% BLACK %][% BRIGHT WHITE %]DAILY WIRE[% RED %]🞤[% RESET %]';
            $text =~ s/daily wire/$dw/gsi;
        } elsif ($text =~ /the blaze/i) {
            my $blaze = '[% B_BRIGHT WHITE %][% BLACK %]the[% RED %]Blaze[% RESET %]';
            $text =~ s/the blaze/$blaze/gsi;
        } elsif ($text =~ /national review/i) {
            my $nr = '[% B_BLACK %][% BRIGHT WHITE %]NR[% RESET %] NATIONAL REVIEW';
            $text =~ s/national review/$nr/gsi;
        } elsif ($text =~ /hot air/i) {
            my $hr = '[% BRIGHT WHITE %]HOT A[% RED %]i[% BRIGHT WHITE %]R[% RESET %]';
            $text =~ s/hot air/$hr/gsi;
        } elsif ($text =~ /gateway pundit/i) {
            my $gp = '[% B_WHITE %][% BRIGHT BLUE %]GP[% GOLD %]🭦[% RESET %] The Gateway Pundit';
            $text =~ s/gateway pundit/$gp/gsi;
        } elsif ($text =~ /daily signal/i) {
            my $ds = '[% B_BRIGHT WHITE %][% BLACK %]ⓢ [% RESET %] Daily Signal';
            $text =~ s/daily signal/$ds/gsi;
        } elsif ($text =~ /newsbusters/i) {
            my $nb = '[% ORANGE %]NewsBusters[% RESET %]';
            $text =~ s/newsbusters/$nb/gsi;
        } elsif ($text =~ /newsmax/i) {
            my $nm = '[% B_BLUE %][% RED %]N[% BRIGHT WHITE %]EWSMAX[% RESET %]';
            $text =~ s/newsmax/$nm/gsi;
        } elsif ($text =~ /american thinker/i) {
            my $at = '[% B_OLIVE %][% BLUE %]American Thinker[% RESET %]';
            $text =~ s/american thinker/$at/gsi;
        } elsif ($text =~ /pj media/i) {
            my $pj = '[% B_TEAL %][% BRIGHT WHITE %]PJ[% RESET %] Media';
            $text =~ s/pj media/$pj/gsi;
        } elsif ($text =~ /breitbart/i) {
            my $b = '[% B_DARK ORANGE %][% BRIGHT WHITE %] B [% RESET %] Breitbart';
            $text =~ s/breitbart/$b/gsi;
        } elsif ($text =~ /Timex\/Sinclair /) {
            my $ts = '[% B_BRIGHT WHITE %][% BLACK %] Timex [% B_BLACK %][% BRIGHT WHITE %] sinclair [% RESET %]';
            $text =~ s/Timex\/Sinclair /$ts/;
        } elsif ($text =~ /Sinclair/) {
            my $ts = '[% B_BLACK %][% BRIGHT WHITE %] sinclair [% RESET %]';
            $text =~ s/Sinclair/$ts/;
        } elsif ($text =~ /MS-DOS/) {
            my $md = '[% BRIGHT WHITE %]MS[% RESET %]-[% RED %]D[% MAGENTA %]O[% YELLOW %]S[% RESET %]';
            $text =~ s/MS-DOS/$md/;
        } elsif ($text =~ /FreeBSD/) {
            my $fb = '[% RED %]FreeBSD[% RESET %]';
            $text =~ s/FreeBSD/$fb/;
        } elsif ($text =~ /Linux/) {
            my $lin = '[% PENGUIN %] Linux[% RESET %]';
            $text =~ s/Linux/$lin/;
        } elsif ($text =~ /Heathkit/) {
            my $h = '[% RGB 55,165,153 %]Heathkit[% RESET %]';
            $text =~ s/Heathkit/$h/;
        } elsif ($text =~ /Atari/) {
            my $a = '[% B_BRIGHT RED %][% BRIGHT WHITE %] ATARI [% RESET %]';
            $text =~ s/Atari/$a/;
        } elsif ($text =~ /Commodore/) {
            my $co = '[% B_WHITE %][% NAVY %] Commodore [% RESET %]';
            $text =~ s/Commodore/$co/;
        } elsif ($text =~ /CP\/M/) {
            my $cpm = '[% B_RGB 145,135,108 %][% MAROON %] CP/M [% RESET %]';
            $text =~ s/CP\/M/$cpm/;
        } elsif ($text =~ /BBC/) {
            my $bbc = '[% B_RED %][% BRIGHT WHITE %] B [% RESET %] [% B_RED %][% BRIGHT WHITE %] B [% RESET %] [% B_RED %][% BRIGHT WHITE %] C [% RESET %]';
            $text =~ s/BBC/$bbc/;
        } elsif ($text =~ /Windows/) {
            my $win = '[% BRIGHT BLUE %]Windows[% RESET %]';
            $text =~ s/Windows/$win/;
        } elsif ($text =~ /Texas Instruments/) {
            my $ti = ' [% B_BRIGHT RED %] [% RESET %] [% B_GRAY 11 %][% BLACK %] TEXAS INSTRUMENTS [% RESET %]';
            $text =~ s/Texas Instruments/$ti/;
        } elsif ($text =~ /TRS-80 Color Computer/) {
            my $tr = '[% BRIGHT WHITE %]🮚 [% B_BRIGHT WHITE %][% BLACK %] [% UNDERLINE %]' . "\e[58;2;255;0;0m" . 'TR' . "\e[58;2;0;255;0m" . 'S-' . "\e[58;2;0;0;255m" . '80[% RESET %][% B_BRIGHT WHITE %][% BLACK %] [% RESET %]';
            $text =~ s/TRS-80/$tr/;
        } elsif ($text =~ /TRS-80/) {
            my $tr = '[% BRIGHT WHITE %]🮚 [% B_BRIGHT WHITE %][% BLACK %] TRS-80 [% RESET %]';
            $text =~ s/TRS-80/$tr/;
        } elsif ($text =~ /MSX/) {
            my $msx = '[% B_NAVY %][% WHITE %] MSX [% RESET %]';
            $text =~ s/MSX/$msx/;
        } elsif ($text =~ /Wang/) {
            my $w = '[% B_BRIGHT WHITE %][% BLACK %][% RIGHT TRIANGULAR ONE QUARTER BLOCK %][% B_BLACK %][% BRIGHT WHITE %] WANG [% B_BRIGHT WHITE %][% BLACK %][% LEFT TRIANGULAR ONE QUARTER BLOCK %][% RESET %]';
            $text =~ s/Wang/$w/;
        } elsif ($text =~ /Oric/) {
            my $oric = "\e[58;2;192;0;0m" . '[% B_BLACK %][% BRIGHT WHITE %] [% UNDERLINE %]ORIC[% RESET %][% B_BLACK %] [% RESET %]';
            $text =~ s/Oric/$oric/;
        }
    } ## end if ($mode eq 'ANSI')
    $self->{'debug'}->DEBUG(['End News Title Colorize']);
    return ($text);
} ## end sub news_title_colorize

 

# package BBS::Universal::PETSCII;

sub petscii_initialize {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start PETSCII Initialize']);

    my $inv = "\e[7m";
    my $ni  = "\e[27m";

    $self->{'petscii_meta'} = {
#       'NULL 0'                                  => { 'out' => chr(0),   'unicode' => ' ', 'desc' => 'NOP 0', },
#       'NULL 1'                                  => { 'out' => chr(1),   'unicode' => ' ', 'desc' => 'NOP 1', },
#       'NULL 2'                                  => { 'out' => chr(2),   'unicode' => ' ', 'desc' => 'NOP 2', },
        'STOP'                                    => { 'out' => chr(3),   'unicode' => ' ', 'desc' => 'PETSCII STOP', },
#       'NULL 4'                                  => { 'out' => chr(4),   'unicode' => ' ', 'desc' => 'NOP 4', },
        'WHITE'                                   => { 'out' => chr(5),   'unicode' => ' ', 'desc' => 'White text', },
        'RESET'                                   => { 'out' => chr(5),   'unicode' => ' ', 'desc' => 'Reset back to white text', },
#       'NULL 6'                                  => { 'out' => chr(6),   'unicode' => ' ', 'desc' => 'NOP 6', },
#       'NULL 7'                                  => { 'out' => chr(7),   'unicode' => ' ', 'desc' => 'NOP 7', },
        'DISABLE SHIFT'                           => { 'out' => chr(8),   'unicode' => ' ', 'desc' => 'Disable shift', },
        'ENABLE SHIFT'                            => { 'out' => chr(9),   'unicode' => ' ', 'desc' => 'Enable shift', },
#       'NULL 10'                                 => { 'out' => chr(10),  'unicode' => ' ', 'desc' => 'NOP 10', },
#       'NULL 11'                                 => { 'out' => chr(11),  'unicode' => ' ', 'desc' => 'NOP 11', },
#       'NULL 12'                                 => { 'out' => chr(12),  'unicode' => ' ', 'desc' => 'NOP 12', },
        'RETURN'                                  => { 'out' => chr(13),  'unicode' => ' ', 'desc' => 'Carriage Return', },
        'LOWERCASE'                               => { 'out' => chr(14),  'unicode' => ' ', 'desc' => 'Lowercase', },
#       'NULL 15'                                 => { 'out' => chr(15),  'unicode' => ' ', 'desc' => 'NOP 15', },
#       'NULL 16'                                 => { 'out' => chr(16),  'unicode' => ' ', 'desc' => 'NOP 16', },
        'DOWN'                                    => { 'out' => chr(17),  'unicode' => ' ', 'desc' => 'Cursor down', },
        'REVERSE ON'                              => { 'out' => chr(18),  'unicode' => ' ', 'desc' => 'Reverse on', },
        'HOME'                                    => { 'out' => chr(19),  'unicode' => ' ', 'desc' => 'Home', },
        'DELETE'                                  => { 'out' => chr(20),  'unicode' => ' ', 'desc' => 'Delete', },
#       'NULL 21'                                 => { 'out' => chr(21),  'unicode' => ' ', 'desc' => 'NOP 21', },
#       'NULL 22'                                 => { 'out' => chr(22),  'unicode' => ' ', 'desc' => 'NOP 22', },
#       'NULL 23'                                 => { 'out' => chr(23),  'unicode' => ' ', 'desc' => 'NOP 23', },
#       'NULL 24'                                 => { 'out' => chr(24),  'unicode' => ' ', 'desc' => 'NOP 24', },
#       'NULL 25'                                 => { 'out' => chr(25),  'unicode' => ' ', 'desc' => 'NOP 25', },
#       'NULL 26'                                 => { 'out' => chr(26),  'unicode' => ' ', 'desc' => 'NOP 26', },
#       'NULL 27'                                 => { 'out' => chr(27),  'unicode' => ' ', 'desc' => 'NOP 27', },
        'RED'                                     => { 'out' => chr(28),  'unicode' => ' ', 'desc' => 'Red', },
        'RIGHT'                                   => { 'out' => chr(29),  'unicode' => ' ', 'desc' => 'Cursor right', },
        'GREEN'                                   => { 'out' => chr(30),  'unicode' => ' ', 'desc' => 'Green', },
        'BLUE'                                    => { 'out' => chr(31),  'unicode' => ' ', 'desc' => 'Blue', },
#       'SPACE'                                   => { 'out' => ' ',      'unicode' => ' ', 'desc' => 'Space', },
#       'EXCLAMATION MARK'                        => { 'out' => '!',      'unicode' => '!', 'desc' => 'Exclamation mark', },
#       'DOUBLE QUOTE'                            => { 'out' => '"',      'unicode' => '"', 'desc' => 'Double quotation mark', },
#       'HASH'                                    => { 'out' => '#',      'unicode' => '#', 'desc' => 'Hash/pound', },
#       'DOLLAR'                                  => { 'out' => '$',      'unicode' => '$', 'desc' => 'Dollar sign', },
#       'PERCENT'                                 => { 'out' => '%',      'unicode' => '%', 'desc' => 'Percent sign', },
#       'AMPERSAND'                               => { 'out' => '&',      'unicode' => '&', 'desc' => 'Ampersand', },
#       'SINGLE QUOTE'                            => { 'out' => "'",      'unicode' => "'", 'desc' => 'Single quotation mark', },
#       'PARENTHESIS LEFT'                        => { 'out' => '(',      'unicode' => '(', 'desc' => 'Left parenthesis', },
#       'PARENTHESIS RIGHT'                       => { 'out' => ')',      'unicode' => ')', 'desc' => 'Right parenthesis', },
#       'ASTERISK'                                => { 'out' => '*',      'unicode' => '*', 'desc' => 'Asterisk', },
#       'PLUS'                                    => { 'out' => '+',      'unicode' => '+', 'desc' => 'Plus sign', },
#       'COMMA'                                   => { 'out' => ',',      'unicode' => ',', 'desc' => 'Comma', },
#       'HYPHEN'                                  => { 'out' => '-',      'unicode' => '-', 'desc' => 'Hyphen', },
#       'PERIOD'                                  => { 'out' => ',',      'unicode' => '.', 'desc' => 'Period', },
#       'FORWARD SLASH'                           => { 'out' => '/',      'unicode' => '/', 'desc' => 'Forward slash', },
#       'ZERO'                                    => { 'out' => '0',      'unicode' => '0', 'desc' => 'Zero', },
#       'ONE'                                     => { 'out' => '1',      'unicode' => '1', 'desc' => 'One', },
#       'TWO'                                     => { 'out' => '2',      'unicode' => '2', 'desc' => 'Two', },
#       'THREE'                                   => { 'out' => '3',      'unicode' => '3', 'desc' => 'Three', },
#       'FOUR'                                    => { 'out' => '4',      'unicode' => '4', 'desc' => 'Four', },
#       'FIVE'                                    => { 'out' => '5',      'unicode' => '5', 'desc' => 'Five', },
#       'SIX'                                     => { 'out' => '6',      'unicode' => '6', 'desc' => 'Six', },
#       'SEVEN'                                   => { 'out' => '7',      'unicode' => '7', 'desc' => 'Seven', },
#       'EIGHT'                                   => { 'out' => '8',      'unicode' => '8', 'desc' => 'Eight', },
#       'NINE'                                    => { 'out' => '9',      'unicode' => '9', 'desc' => 'Nine', },
#       'COLON'                                   => { 'out' => ':',      'unicode' => ':', 'desc' => 'Colon', },
#       'SEMICOLON'                               => { 'out' => ';',      'unicode' => ';', 'desc' => 'Semicolon', },
#       'LESS THAN'                               => { 'out' => '<',      'unicode' => '<', 'desc' => 'Less than', },
#       'EQUAL'                                   => { 'out' => '=',      'unicode' => '=', 'desc' => 'Equal sign', },
#       'GREATER THAN'                            => { 'out' => '>',      'unicode' => '>', 'desc' => 'Greater than', },
#       'QUESTION MARK'                           => { 'out' => '?',      'unicode' => '?', 'desc' => 'Question mark', },
#       'AT'                                      => { 'out' => '@',      'unicode' => '@', 'desc' => 'At symbol', },
#       'CHAR A'                                  => { 'out' => 'A',      'unicode' => 'A', 'desc' => 'A', },
#       'CHAR B'                                  => { 'out' => 'B',      'unicode' => 'B', 'desc' => 'B', },
#       'CHAR C'                                  => { 'out' => 'C',      'unicode' => 'C', 'desc' => 'C', },
#       'CHAR D'                                  => { 'out' => 'D',      'unicode' => 'D', 'desc' => 'D', },
#       'CHAR E'                                  => { 'out' => 'E',      'unicode' => 'E', 'desc' => 'E', },
#       'CHAR F'                                  => { 'out' => 'F',      'unicode' => 'F', 'desc' => 'F', },
#       'CHAR G'                                  => { 'out' => 'G',      'unicode' => 'G', 'desc' => 'G', },
#       'CHAR H'                                  => { 'out' => 'H',      'unicode' => 'H', 'desc' => 'H', },
#       'CHAR I'                                  => { 'out' => 'I',      'unicode' => 'I', 'desc' => 'I', },
#       'CHAR J'                                  => { 'out' => 'J',      'unicode' => 'J', 'desc' => 'J', },
#       'CHAR K'                                  => { 'out' => 'K',      'unicode' => 'K', 'desc' => 'K', },
#       'CHAR L'                                  => { 'out' => 'L',      'unicode' => 'L', 'desc' => 'L', },
#       'CHAR M'                                  => { 'out' => 'M',      'unicode' => 'M', 'desc' => 'M', },
#       'CHAR N'                                  => { 'out' => 'N',      'unicode' => 'N', 'desc' => 'N', },
#       'CHAR O'                                  => { 'out' => 'O',      'unicode' => 'O', 'desc' => 'O', },
#       'CHAR P'                                  => { 'out' => 'P',      'unicode' => 'P', 'desc' => 'P', },
#       'CHAR Q'                                  => { 'out' => 'Q',      'unicode' => 'Q', 'desc' => 'Q', },
#       'CHAR R'                                  => { 'out' => 'R',      'unicode' => 'R', 'desc' => 'R', },
#       'CHAR S'                                  => { 'out' => 'S',      'unicode' => 'S', 'desc' => 'S', },
#       'CHAR T'                                  => { 'out' => 'T',      'unicode' => 'T', 'desc' => 'T', },
#       'CHAR U'                                  => { 'out' => 'U',      'unicode' => 'U', 'desc' => 'U', },
#       'CHAR V'                                  => { 'out' => 'V',      'unicode' => 'V', 'desc' => 'V', },
#       'CHAR W'                                  => { 'out' => 'W',      'unicode' => 'W', 'desc' => 'W', },
#       'CHAR X'                                  => { 'out' => 'X',      'unicode' => 'X', 'desc' => 'X', },
#       'CHAR Y'                                  => { 'out' => 'Y',      'unicode' => 'Y', 'desc' => 'Y', },
#       'CHAR Z'                                  => { 'out' => 'Z',      'unicode' => 'Z', 'desc' => 'Z', },
#       'SQUARE BRACKET LEFT'                     => { 'out' => chr(91),  'unicode' => '[', 'desc' => 'Square left bracket', },
        'BRITISH POUND'                           => { 'out' => chr(92),  'unicode' => '£', 'desc' => 'British Pound', },
#       'SQUARE BRACKET RIGHT'                    => { 'out' => chr(93),  'unicode' => ']', 'desc' => 'Square right bracket', },
        'UP ARROW'                                => { 'out' => chr(94),  'unicode' => '↑', 'desc' => 'Up Arrow', },
        'LEFT ARROW'                              => { 'out' => chr(95),  'unicode' => '←', 'desc' => 'Left Arrow', },
        'HORIZONTAL BAR'                          => { 'out' => chr(96),  'unicode' => '─', 'desc' => 'Horizontal Bar', },
        'SPADE'                                   => { 'out' => chr(97),  'unicode' => '♠', 'desc' => 'Spade', },
        'VERTICAL BAR CENTER'                     => { 'out' => chr(98),  'unicode' => '│', 'desc' => 'Giant Vertical Bar', },
        'HORIZONTAL BAR DUPLICATE'                => { 'out' => chr(99),  'unicode' => '─', 'desc' => 'Horizontal Bar', },
        'HORIZONTAL BAR SMALL UPPER BIAS'         => { 'out' => chr(100), 'unicode' => '🭸', 'desc' => 'Horizontal bar with a slight upper bias', },
        'HORIZONTAL BAR LARGE UPPER BIAS'         => { 'out' => chr(101), 'unicode' => '🭶', 'desc' => 'Horizontal bar with a strong upper bias', },
        'HORIZONTAL BAR SMALL LOWER BIAS'         => { 'out' => chr(102), 'unicode' => '🭺', 'desc' => 'Horizontal bar with a slight lower bias', },
        'VERTICAL BAR SMALL LEFT BIAS'            => { 'out' => chr(103), 'unicode' => ' ', 'desc' => 'Vertical bar with a slight left bias', },
        'VERTICAL BAR SMALL RIGHT BIAS'           => { 'out' => chr(104), 'unicode' => ' ', 'desc' => 'Vertical bar with a slight right bias', },
        'TOP RIGHT ROUNDED CORNER'                => { 'out' => chr(105), 'unicode' => '╮', 'desc' => 'Top Right Rounded Corner', },
        'BOTTOM LEFT ROUNDED CORNER'              => { 'out' => chr(106), 'unicode' => '╰', 'desc' => 'Bottom Left Rounded Corner', },
        'BOTTOM RIGHT ROUNDED CORNER'             => { 'out' => chr(107), 'unicode' => '╯', 'desc' => 'Bottom Right Rounded Corner', },
        'BOTTOM LEFT RIGHT ANGLE'                 => { 'out' => chr(108), 'unicode' => '⎿', 'desc' => 'Bottom left right angle', },
        'GIANT BACKSLASH'                         => { 'out' => chr(109), 'unicode' => '╲', 'desc' => 'Giant Backslash', },
        'GIANT FORWARD SLASH'                     => { 'out' => chr(110), 'unicode' => '╱', 'desc' => 'Giant Forward Slash', },
        'TOP LEFT RIGHT ANGLE'                    => { 'out' => chr(111), 'unicode' => '⎾', 'desc' => 'Top left right angle', },
        'TOP RIGHT RIGHT ANGLE'                   => { 'out' => chr(112), 'unicode' => ' ', 'desc' => 'Top right right angle', },
        'CENTER DOT'                              => { 'out' => chr(113), 'unicode' => '•', 'desc' => 'CENTER DOT', },
        'HORIZONTAL BAR LARGE LOWER BIAS'         => { 'out' => chr(114), 'unicode' => '🭻', 'desc' => 'Horizontal bar with a strong lower bias', },
        'HEART'                                   => { 'out' => chr(115), 'unicode' => '♥', 'desc' => 'Heart', },
        'VERTICAL BAR LARGE LEFT BIAS'            => { 'out' => chr(116), 'unicode' => ' ', 'desc' => 'Vertical bar with a strong left bias', },
        'TOP LEFT ROUNDED CORNER'                 => { 'out' => chr(117), 'unicode' => '╭', 'desc' => 'Top Left Rounded Corner', },
        'GIANT X'                                 => { 'out' => chr(118), 'unicode' => '╳', 'desc' => 'Giant X', },
        'THIN CIRCLE'                             => { 'out' => chr(119), 'unicode' => '○', 'desc' => 'Thin Circle', },
        'CLUB'                                    => { 'out' => chr(120), 'unicode' => '♣', 'desc' => 'Club', },
        'VERTICAL BAR LARGE RIGHT BIAS'           => { 'out' => chr(121), 'unicode' => ' ', 'desc' => 'Vertical bar with a strong right bias', },
        'DIAMOND'                                 => { 'out' => chr(122), 'unicode' => '♦', 'desc' => 'Diamond', },
        'CROSS BAR'                               => { 'out' => chr(123), 'unicode' => '┼', 'desc' => 'Cross Bar', },
        'SHADE LEFT'                              => { 'out' => chr(124), 'unicode' => '🮌', 'desc' => 'Shade left', },
        'VERTICAL BAR'                            => { 'out' => chr(125), 'unicode' => '┃', 'desc' => 'Vertical bar', },
        'PI'                                      => { 'out' => chr(126), 'unicode' => 'π', 'desc' => 'Pi symbol', },
        'BOTTOM LEFT WEDGE'                       => { 'out' => chr(127), 'unicode' => '◥', 'desc' => 'Bottom Left Wedge', },
#       'NULL 128'                                => { 'out' => chr(128), 'unicode' => ' ', 'desc' => 'NOP 128', },
        'ORANGE'                                  => { 'out' => chr(129), 'unicode' => ' ', 'desc' => 'Orange' },
#       'NULL 130'                                => { 'out' => chr(130), 'unicode' => ' ', 'desc' => 'NOP 130', },
        'RUN'                                     => { 'out' => chr(131), 'unicode' => ' ', 'desc' => 'Run key', },
#       'NULL 132'                                => { 'out' => chr(132), 'unicode' => ' ', 'desc' => 'NOP 132', },
#       'F1'                                      => { 'out' => chr(133), 'unicode' => ' ', 'desc' => 'F1', },
#       'F3'                                      => { 'out' => chr(134), 'unicode' => ' ', 'desc' => 'F3', },
#       'F5'                                      => { 'out' => chr(135), 'unicode' => ' ', 'desc' => 'F5', },
#       'F7'                                      => { 'out' => chr(136), 'unicode' => ' ', 'desc' => 'F7', },
#       'F2'                                      => { 'out' => chr(137), 'unicode' => ' ', 'desc' => 'F2', },
#       'F4'                                      => { 'out' => chr(138), 'unicode' => ' ', 'desc' => 'F4', },
#       'F6'                                      => { 'out' => chr(139), 'unicode' => ' ', 'desc' => 'F6', },
#       'F8'                                      => { 'out' => chr(140), 'unicode' => ' ', 'desc' => 'F8', },
        'SHIFT RETURN'                            => { 'out' => chr(141), 'unicode' => ' ', 'desc' => 'Shift-return', },
        'UPPERCASE'                               => { 'out' => chr(142), 'unicode' => ' ', 'desc' => 'Uppercase', },
#       'NULL 143'                                => { 'out' => chr(143), 'unicode' => ' ', 'desc' => 'NOP 143', },
        'BLACK'                                   => { 'out' => chr(144), 'unicode' => ' ', 'desc' => 'Black', },
        'UP'                                      => { 'out' => chr(145), 'unicode' => ' ', 'desc' => 'Cursor up', },
        'REVERSE OFF'                             => { 'out' => chr(146), 'unicode' => ' ', 'desc' => 'Reverse off', },
        'CLEAR'                                   => { 'out' => chr(147), 'unicode' => ' ', 'desc' => 'Clear', },
        'INSERT'                                  => { 'out' => chr(148), 'unicode' => ' ', 'desc' => 'Insert', },
        'BROWN'                                   => { 'out' => chr(149), 'unicode' => ' ', 'desc' => 'Brown', },
        'LIGHT RED'                               => { 'out' => chr(150), 'unicode' => ' ', 'desc' => 'Light/bright red', },
        'DARK GRAY'                               => { 'out' => chr(151), 'unicode' => ' ', 'desc' => 'Dark gray', },
        'MEDIUM GRAY'                             => { 'out' => chr(152), 'unicode' => ' ', 'desc' => 'Medium gray', },
        'LIGHT GREEN'                             => { 'out' => chr(153), 'unicode' => ' ', 'desc' => 'Light/bright green', },
        'LIGHT BLUE'                              => { 'out' => chr(154), 'unicode' => ' ', 'desc' => 'Light/bright blue', },
        'LIGHT GRAY'                              => { 'out' => chr(155), 'unicode' => ' ', 'desc' => 'Light gray', },
        'PURPLE'                                  => { 'out' => chr(156), 'unicode' => ' ', 'desc' => 'Purple', },
        'LEFT'                                    => { 'out' => chr(157), 'unicode' => ' ', 'desc' => 'Cursor left', },
        'YELLOW'                                  => { 'out' => chr(158), 'unicode' => ' ', 'desc' => 'Yellow', },
        'CYAN'                                    => { 'out' => chr(159), 'unicode' => ' ', 'desc' => 'Cyan', },
        'REVERSE SPACE'                           => { 'out' => chr(160), 'unicode' => "$inv $ni", 'desc' => 'Dithered Box Full', },
        'REVERSE LEFT HALF'                       => { 'out' => chr(161), 'unicode' => $inv . '▌' . $ni, 'desc' => 'Reversed Left Half', },
        'REVERSE BOTTOM BOX'                      => { 'out' => chr(162), 'unicode' => $inv . '▄' . $ni, 'desc' => 'Reversed Bottom Box', },
        'REVERSE TOP HORIZONTAL BAR'              => { 'out' => chr(163), 'unicode' => $inv . '▔' . $ni, 'desc' => 'Reversed Top Horizontal Bar', },
        'REVERSE BOTTOM HORIZONTAL BAR'           => { 'out' => chr(164), 'unicode' => $inv . '▁' . $ni, 'desc' => 'Reversed Bottom Horizontal Bar', },
        'REVERSE LEFT VERTICAL BAR'               => { 'out' => chr(165), 'unicode' => $inv . '▎' . $ni, 'desc' => 'Reversed Left Vertical Bar', },
        'REVERSE DITHERED BOX'                    => { 'out' => chr(166), 'unicode' => $inv . '▒' . $ni, 'desc' => 'Reversed Dithered Box', },
        'REVERSE RIGHT VERTICAL BAR'              => { 'out' => chr(167), 'unicode' => $inv . '🮈' . $ni, 'desc' => 'Reversed Right Vertical Bar', },
        'REVERSE DITHERED BOTTOM'                 => { 'out' => chr(168), 'unicode' => $inv . '🮏' . $ni, 'desc' => 'Reversed Dithered Left', },
        'REVERSE BOTTOM RIGHT WEDGE'              => { 'out' => chr(169), 'unicode' => $inv . '◤' . $ni, 'desc' => 'Reversed Bottom Right Wedge', },
        'REVERSE VERTICAL BAR RIGHT'              => { 'out' => chr(170), 'unicode' => $inv . '🮈' . $ni, 'desc' => 'Reversed Vertical bar flushed right', },
        'REVERSE VERTICAL BAR MIDDLE LEFT'        => { 'out' => chr(171), 'unicode' => $inv . '├' . $ni, 'desc' => 'Reversed Vertical Bar Middle Left', },
        'REVERSE BOTTOM RIGHT BOX'                => { 'out' => chr(172), 'unicode' => $inv . '▗' . $ni, 'desc' => 'Reversed Bottom Right Box', },
        'REVERSE BOTTOM LEFT CORNER'              => { 'out' => chr(173), 'unicode' => $inv . '└' . $ni, 'desc' => 'Reversed Bottom Left Corner', },
        'REVERSE TOP RIGHT CORNER'                => { 'out' => chr(174), 'unicode' => $inv . '┐' . $ni, 'desc' => 'Reversed Top Right Corner', },
        'REVERSE HORIZONTAL BAR BOTTOM'           => { 'out' => chr(175), 'unicode' => $inv . '▂' . $ni, 'desc' => 'Reversed Horizontal Bar Bottom', },
        'REVERSE TOP LEFT CORNER'                 => { 'out' => chr(176), 'unicode' => $inv . '┌' . $ni, 'desc' => 'Reversed Top Left Corner', },
        'REVERSE HORIZONTAL BAR MIDDLE BOTTOM'    => { 'out' => chr(177), 'unicode' => $inv . '┴' . $ni, 'desc' => 'Reversed Horizontal Bar Middle Bottom', },
        'REVERSE HORIZONTAL BAR MIDDLE TOP'       => { 'out' => chr(178), 'unicode' => $inv . '┬' . $ni, 'desc' => 'Reversed Horizontal Bar Middle Top', },
        'REVERSE VERTICAL BAR MIDDLE RIGHT'       => { 'out' => chr(179), 'unicode' => $inv . '┤' . $ni, 'desc' => 'Reversed Vertical Bar Middle Right', },
        'REVERSE VERTICAL BOX LEFT'               => { 'out' => chr(180), 'unicode' => $inv . '▍' . $ni, 'desc' => 'Reversed Vertical Box Left', },
        'REVERSE LEFT HALF BOX'                   => { 'out' => chr(181), 'unicode' => $inv . '▌' . $ni, 'desc' => 'Reversed Left Half Box', },
        'REVERSE RIGHT HALF BOX'                  => { 'out' => chr(182), 'unicode' => $inv . '🮈' . $ni, 'desc' => 'Reversed Right half box', },
        'REVERSE HORIZONTAL BAR TOP'              => { 'out' => chr(183), 'unicode' => $inv . '🮂' . $ni, 'desc' => 'Reversed Horizontal bar top', },
        'REVERSE HORIZONTAL BAR THICK TOP'        => { 'out' => chr(184), 'unicode' => $inv . '🮃' . $ni, 'desc' => 'Reversed Horizontal bar thick top', },
        'REVERSE HORIZONTAL BAR THICK BOTTOM'     => { 'out' => chr(185), 'unicode' => $inv . '▃' . $ni, 'desc' => 'Reversed Horizontal bar thick bottom', },
        'REVERSE BOTTOM RIGHT RIGHT ANGLE'        => { 'out' => chr(186), 'unicode' => $inv . '🭿' . $ni, 'desc' => 'Reversed Bottom right right angle', },
        'REVERSE BOTTOM LEFT BOX'                 => { 'out' => chr(187), 'unicode' => $inv . '▖' . $ni, 'desc' => 'Reversed Bottom Left Box', },
        'REVERSE TOP RIGHT BOX'                   => { 'out' => chr(188), 'unicode' => $inv . '▝' . $ni, 'desc' => 'Reversed Top Right Box', },
        'REVERSE BOTTOM RIGHT CORNER'             => { 'out' => chr(189), 'unicode' => $inv . '┘' . $ni, 'desc' => 'Reversed Bottom Right Corner', },
        'REVERSE TOP LEFT BOX'                    => { 'out' => chr(190), 'unicode' => $inv . '▘' . $ni, 'desc' => 'Reversed Top Left Box', },
        'REVERSE TOP LEFT BOTTOM RIGHT BOX'       => { 'out' => chr(191), 'unicode' => $inv . '▚' . $ni, 'desc' => 'Reversed Top Left Bottom Right Box', },
        'REVERSE HORIZONTAL BAR'                  => { 'out' => chr(192), 'unicode' => $inv . '🭹' . $ni, 'desc' => 'Reversed Horizontal bar', },
#       'REVERSE SPADE DUPLICATE'                 => { 'out' => chr(193), 'unicode' => $inv . '♠' . $ni, 'desc' => 'Reversed Spade duplicate', },
#       'REVERSE VERTICAL BAR CENTER DUPLICATE'   => { 'out' => chr(194), 'unicode' => $inv . '│' . $ni, 'desc' => 'Reversed Giant Vertical Bar duplicate', },
        'REVERSE HORIZONTAL BAR DUPLICATE'        => { 'out' => chr(195), 'unicode' => $inv . '─' . $ni, 'desc' => 'Reversed Horizontal Bar duplicate', },
        'REVERSE HORIZONTAL BAR SMALL UPPER BIAS' => { 'out' => chr(196), 'unicode' => $inv . '🭸' . $ni, 'desc' => 'Reversed Horizontal bar with a slight upper bias', },
        'REVERSE HORIZONTAL BAR LARGE UPPER BIAS' => { 'out' => chr(197), 'unicode' => $inv . '🭶' . $ni, 'desc' => 'Reversed Horizontal bar with a strong upper bias', },
        'REVERSE HORIZONTAL BAR SMALL LOWER BIAS' => { 'out' => chr(198), 'unicode' => $inv . '🭺' . $ni, 'desc' => 'Reversed Horizontal bar with a slight lower bias', },
        'REVERSE VERTICAL BAR SMALL LEFT BIAS'    => { 'out' => chr(199), 'unicode' => $inv . ' ' . $ni, 'desc' => 'Reversed Vertical bar with a slight left bias', },
        'REVERSE VERTICAL BAR SMALL RIGHT BIAS'   => { 'out' => chr(200), 'unicode' => $inv . ' ' . $ni, 'desc' => 'Reversed Vertical bar with a slight right bias', },
        'REVERSE TOP RIGHT ROUNDED CORNER'        => { 'out' => chr(201), 'unicode' => $inv . '╮' . $ni, 'desc' => 'Reversed Top Right Rounded Corner', },
        'REVERSE BOTTOM LEFT ROUNDED CORNER'      => { 'out' => chr(202), 'unicode' => $inv . '╰' . $ni, 'desc' => 'Reversed Bottom Left Rounded Corner', },
        'REVERSE BOTTOM RIGHT ROUNDED CORNER'     => { 'out' => chr(203), 'unicode' => $inv . '╯' . $ni, 'desc' => 'Reversed Bottom Right Rounded Corner', },
        'REVERSE BOTTOM LEFT RIGHT ANGLE'         => { 'out' => chr(204), 'unicode' => $inv . '⎿' . $ni, 'desc' => 'Reversed Bottom left right angle', },
        'REVERSE GIANT BACKSLASH'                 => { 'out' => chr(205), 'unicode' => $inv . '╲' . $ni, 'desc' => 'Reversed Giant Backslash', },
        'REVERSE GIANT FORWARD SLASH'             => { 'out' => chr(206), 'unicode' => $inv . '╱' . $ni, 'desc' => 'Reversed Giant Forward Slash', },
        'REVERSE TOP LEFT RIGHT ANGLE'            => { 'out' => chr(207), 'unicode' => $inv . '⎾' . $ni, 'desc' => 'Reversed Top left right angle', },
        'REVERSE TOP RIGHT RIGHT ANGLE'           => { 'out' => chr(208), 'unicode' => $inv . ' ' . $ni, 'desc' => 'Reversed Top right right angle', },
        'REVERSE CENTER DOT'                      => { 'out' => chr(209), 'unicode' => $inv . '•' . $ni, 'desc' => 'Reversed CENTER DOT', },
        'REVERSE HORIZONTAL BAR LARGE LOWER BIAS' => { 'out' => chr(210), 'unicode' => $inv . '🭻' . $ni, 'desc' => 'Reversed Horizontal bar with a strong lower bias', },
        'REVERSE HEART'                           => { 'out' => chr(211), 'unicode' => $inv . '♥' . $ni, 'desc' => 'Reversed Heart', },
        'REVERSE VERTICAL BAR LARGE LEFT BIAS'    => { 'out' => chr(212), 'unicode' => $inv . ' ' . $ni, 'desc' => 'Reversed Vertical bar with a strong left bias', },
        'REVERSE TOP LEFT ROUNDED CORNER'         => { 'out' => chr(213), 'unicode' => $inv . '╭' . $ni, 'desc' => 'Reversed Top Left Rounded Corner', },
        'REVERSE GIANT X'                         => { 'out' => chr(214), 'unicode' => $inv . '╳' . $ni, 'desc' => 'Reversed Giant X', },
        'REVERSE THIN CIRCLE'                     => { 'out' => chr(215), 'unicode' => $inv . '○' . $ni, 'desc' => 'Reversed Thin Circle', },
        'REVERSE CLUB'                            => { 'out' => chr(216), 'unicode' => $inv . '♣' . $ni, 'desc' => 'Reversed Club', },
        'REVERSE VERTICAL BAR LARGE RIGHT BIAS'   => { 'out' => chr(217), 'unicode' => $inv . ' ' . $ni, 'desc' => 'Reversed Vertical bar with a strong right bias', },
        'REVERSE DIAMOND'                         => { 'out' => chr(218), 'unicode' => $inv . '♦' . $ni, 'desc' => 'Reversed Diamond', },
        'REVERSE CROSS BAR'                       => { 'out' => chr(219), 'unicode' => $inv . '┼' . $ni, 'desc' => 'Reversed Cross Bar', },
        'REVERSE SHADE LEFT'                      => { 'out' => chr(220), 'unicode' => $inv . '🮌' . $ni, 'desc' => 'Reversed Shade left', },
        'REVERSE VERTICAL BAR'                    => { 'out' => chr(221), 'unicode' => $inv . '┃' . $ni, 'desc' => 'Reversed Vertical bar', },
        'REVERSE PI'                              => { 'out' => chr(222), 'unicode' => $inv . 'π' . $ni, 'desc' => 'Reversed Pi symbol', },
        'REVERSE BOTTOM LEFT WEDGE'               => { 'out' => chr(223), 'unicode' => $inv . '◥' . $ni, 'desc' => 'Reversed Bottom Left Wedge', },
#       'REVERSE SPACE 2'                         => { 'out' => chr(224), 'unicode' => $inv . ' ' . $ni, 'desc' => 'Reversed Dithered Box Full duplicate', },
#       'REVERSE LEFT HALF 2'                     => { 'out' => chr(225), 'unicode' => $inv . '▌' . $ni, 'desc' => 'Reversed Left Half duplicate', },
#       'REVERSE BOTTOM BOX 2'                    => { 'out' => chr(226), 'unicode' => $inv . '▄' . $ni, 'desc' => 'Reversed Bottom Box duplicate', },
#       'REVERSE TOP HORIZONTAL BAR 2'            => { 'out' => chr(227), 'unicode' => $inv . '▔' . $ni, 'desc' => 'Reversed Top Horizontal Bar duplicate', },
#       'REVERSE BOTTOM HORIZONTAL BAR 2'         => { 'out' => chr(228), 'unicode' => $inv . '▁' . $ni, 'desc' => 'Reversed Bottom Horizontal Bar duplicate', },
#       'REVERSE LEFT VERTICAL BAR 2'             => { 'out' => chr(229), 'unicode' => $inv . '▎' . $ni, 'desc' => 'Reversed Left Vertical Bar duplicate', },
#       'REVERSE DITHERED BOX 2'                  => { 'out' => chr(230), 'unicode' => $inv . '▒' . $ni, 'desc' => 'Reversed Dithered Box duplicate', },
#       'REVERSE RIGHT VERTICAL BAR 2'            => { 'out' => chr(231), 'unicode' => $inv . '🮈' . $ni, 'desc' => 'Reversed Right Vertical Bar duplicate', },
#       'REVERSE DITHERED BOTTOM 2'               => { 'out' => chr(232), 'unicode' => $inv . '🮏' . $ni, 'desc' => 'Reversed Dithered Left duplicate', },
#       'REVERSE BOTTOM RIGHT WEDGE 2'            => { 'out' => chr(233), 'unicode' => $inv . '◤' . $ni, 'desc' => 'Reversed Bottom Right Wedge duplicate', },
#       'REVERSE VERTICAL BAR RIGHT 2'            => { 'out' => chr(234), 'unicode' => $inv . '🮈' . $ni, 'desc' => 'Reversed Vertical bar flushed right duplicate', },
#       'REVERSE VERTICAL BAR MIDDLE LEFT 2'      => { 'out' => chr(235), 'unicode' => $inv . '├' . $ni, 'desc' => 'Reversed Vertical Bar Middle Left duplicate', },
#       'REVERSE BOTTOM RIGHT BOX 2'              => { 'out' => chr(236), 'unicode' => $inv . '▗' . $ni, 'desc' => 'Reversed Bottom Right Box duplicate', },
#       'REVERSE BOTTOM LEFT CORNER 2'            => { 'out' => chr(237), 'unicode' => $inv . '└' . $ni, 'desc' => 'Reversed Bottom Left Corner duplicate', },
#       'REVERSE TOP RIGHT CORNER 2'              => { 'out' => chr(238), 'unicode' => $inv . '┐' . $ni, 'desc' => 'Reversed Top Right Corner duplicate', },
#       'REVERSE HORIZONTAL BAR BOTTOM 2'         => { 'out' => chr(239), 'unicode' => $inv . '▂' . $ni, 'desc' => 'Reversed Horizontal Bar Bottom duplicate', },
#       'REVERSE TOP LEFT CORNER 2'               => { 'out' => chr(240), 'unicode' => $inv . '┌' . $ni, 'desc' => 'Reversed Top Left Corner duplicate', },
#       'REVERSE HORIZONTAL BAR MIDDLE BOTTOM 2'  => { 'out' => chr(241), 'unicode' => $inv . '┴' . $ni, 'desc' => 'Reversed Horizontal Bar Middle Bottom duplicate', },
#       'REVERSE HORIZONTAL BAR MIDDLE TOP 2'     => { 'out' => chr(242), 'unicode' => $inv . '┬' . $ni, 'desc' => 'Reversed Horizontal Bar Middle Top duplicate', },
#       'REVERSE VERTICAL BAR MIDDLE RIGHT 2'     => { 'out' => chr(243), 'unicode' => $inv . '┤' . $ni, 'desc' => 'Reversed Vertical Bar Middle Right duplicate', },
#       'REVERSE VERTICAL BOX LEFT 2'             => { 'out' => chr(244), 'unicode' => $inv . '▍' . $ni, 'desc' => 'Reversed Vertical Box Left duplicate', },
#       'REVERSE LEFT HALF BOX 2'                 => { 'out' => chr(245), 'unicode' => $inv . '▌' . $ni, 'desc' => 'Reversed Left Half Box duplicate', },
#       'REVERSE RIGHT HALF BOX 2'                => { 'out' => chr(246), 'unicode' => $inv . '🮈' . $ni, 'desc' => 'Reversed Right half box duplicate', },
#       'REVERSE HORIZONTAL BAR TOP 2'            => { 'out' => chr(247), 'unicode' => $inv . '🮂' . $ni, 'desc' => 'Reversed Horizontal bar top duplicate', },
#       'REVERSE HORIZONTAL BAR THICK TOP 2'      => { 'out' => chr(248), 'unicode' => $inv . '🮃' . $ni, 'desc' => 'Reversed Horizontal bar thick top duplicate', },
#       'REVERSE HORIZONTAL BAR THICK BOTTOM 2'   => { 'out' => chr(249), 'unicode' => $inv . '▃' . $ni, 'desc' => 'Reversed Horizontal bar thick bottom duplicate', },
#       'REVERSE BOTTOM RIGHT RIGHT ANGLE 2'      => { 'out' => chr(250), 'unicode' => $inv . '🭿' . $ni, 'desc' => 'Reversed Bottom right right angle duplicate', },
#       'REVERSE BOTTOM LEFT BOX 2'               => { 'out' => chr(251), 'unicode' => $inv . '▖' . $ni, 'desc' => 'Reversed Bottom Left Box duplicate', },
#       'REVERSE TOP RIGHT BOX 2'                 => { 'out' => chr(252), 'unicode' => $inv . '▝' . $ni, 'desc' => 'Reversed Top Right Box duplicate', },
#       'REVERSE BOTTOM RIGHT CORNER 2'           => { 'out' => chr(253), 'unicode' => $inv . '┘' . $ni, 'desc' => 'Reversed Bottom Right Corner duplicate', },
#       'REVERSE TOP LEFT BOX 2'                  => { 'out' => chr(254), 'unicode' => $inv . '▘' . $ni, 'desc' => 'Reversed Top Left Box duplicate', },
#       'REVERSE PI 2'                            => { 'out' => chr(255), 'unicode' => $inv . 'π' . $ni, 'desc' => 'Reversed Pi symbol duplicate', },
    };
    $self->{'debug'}->DEBUG(['End PETSCII Initialize']);
    return ($self);
} ## end sub petscii_initialize

sub petscii_output {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start PETSCII Output']);
    my $mlines = (exists($self->{'USER'}->{'max_rows'})) ? $self->{'USER'}->{'max_rows'} - 3 : 21;
    my $lines  = $mlines;

    if (length($text) > 1) {
        while ($text =~ /\[\%\s+HORIZONTAL RULE (.*?)\s+\%\]/) {
            my $rule = "[% $1 %]" . '[% TOP HORIZONTAL BAR %]' x $self->{'USER'}->{'max_columns'} . '[% RESET %]';
            $text =~ s/\[\%\s+HORIZONTAL RULE (.*?)\s+\%\]/$rule/gs;
        }
        foreach my $string (keys %{ $self->{'petscii_meta'} }) {    # Decode macros
            if ($string =~ /CLEAR|CLS/i && ($self->{'sysop'} || $self->{'local_mode'})) {
                my $ch = locate(($self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST')), 1) . cldown;
                $text =~ s/\[\%\s+$string\s+\%\]/$ch/gi;
            } else {
                $text =~ s/\[\%\s+$string\s+\%\]/$self->{'petscii_meta'}->{$string}->{'out'}/gi;
            }
        } ## end foreach my $string (keys %{...})
    } ## end if (length($text) > 1)
    my $s_len = length($text);
    my $nl    = $self->{'petscii_meta'}->{'NEWLINE'}->{'out'};
    foreach my $count (0 .. $s_len) {
        my $char = substr($text, $count, 1);
        if ($char eq "\n") {
            if ($text !~ /$nl/ && !$self->{'local_mode'}) {    # translate only if the file doesn't have ASCII newlines
                $char = $nl;
            }
            $lines--;
            if ($lines <= 0) {
                $lines = $mlines;
                last unless ($self->scroll($nl));
            }
        } ## end if ($char eq "\n")
        $self->send_char($char);
    } ## end foreach my $count (0 .. $s_len)
    $self->{'debug'}->DEBUG(['End PETSCII Output']);
    return (TRUE);
} ## end sub petscii_output

 

# package BBS::Universal::SysOp;

sub sysop_initialize {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Initialize']);

    # Screen size and derived sections for layout
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    $self->{'wsize'} = $wsize;
    $self->{'hsize'} = $hsize;
    $self->{'debug'}->DEBUG(["Screen Size is $wsize x $hsize"]);

    my $sections     = _sections_for_width($wsize);
    my $versions     = $self->sysop_versions_format($sections, FALSE);
    my $bbs_versions = $self->sysop_versions_format($sections, TRUE);

    # Visual config
    $self->{'sysop_menu_colors'} = [91, 93, 92, 95, 94, 96];
    $self->{'sysop_menu_files'}  = ['', '', '', '', ''];

    # Default user capability flags
    $self->{'flags_default'} = {
        'prefer_nickname' => 'ON',
        'view_files'      => 'ON',
        'upload_files'    => 'OFF',
        'download_files'  => 'ON',
        'remove_files'    => 'OFF',
        'read_message'    => 'ON',
        'post_message'    => 'ON',
        'remove_message'  => 'OFF',
        'sysop'           => 'OFF',
        'show_email'      => 'OFF',
    };

    # Tokens (static + dynamic)
    my $static  = _build_static_tokens($self, $versions, $bbs_versions);
    my $dynamic = _build_dynamic_tokens($self);
    $self->{'sysop_tokens'} = { %{$static}, %{$dynamic} };

    # Field orderings
    $self->{'SYSOP ORDER DETAILED'} = [
        qw(
            id
            fullname
            username
            given
            family
            nickname
            email
            birthday
            location
            access_level
            date_format
            baud_rate
            text_mode
            max_columns
            max_rows
            timeout
            retro_systems
            accomplishments
            prefer_nickname
            view_files
            upload_files
            download_files
            remove_files
            play_fortunes
            read_message
            post_message
            remove_message
            sysop
            banned
            login_time
            logout_time
        )
    ];

    $self->{'SYSOP ORDER ABBREVIATED'} = [
        qw(
            id
            fullname
            username
            given
            family
            nickname
            text_mode
        )
    ];

    # Field type definitions
    $self->{'SYSOP FIELD TYPES'} = {
        'id'              => { 'type' => NUMERIC, 'max' => 2,   'min' => 2 },
        'username'        => { 'type' => HOST,    'max' => 32,  'min' => 16 },
        'fullname'        => { 'type' => STRING,  'max' => 20,  'min' => 15 },
        'given'           => { 'type' => STRING,  'max' => 120, 'min' => 32 },
        'family'          => { 'type' => STRING,  'max' => 120, 'min' => 32 },
        'nickname'        => { 'type' => STRING,  'max' => 120, 'min' => 32 },
        'email'           => { 'type' => STRING,  'max' => 120, 'min' => 32 },
        'birthday'        => { 'type' => STRING,  'max' => 10,  'min' => 10 },
        'location'        => { 'type' => STRING,  'max' => 120, 'min' => 40 },
        'date_format'     => { 'type' => RADIO,   'max' => 14,  'min' => 14, 'choices' => ['MONTH/DAY/YEAR', 'DAY/MONTH/YEAR', 'YEAR/MONTH/DAY'], 'default' => 'DAY/MONTH/YEAR', },
        'access_level'    => { 'type' => RADIO,   'max' => 12,  'min' => 12, 'choices' => ['USER', 'VETERAN', 'JUNIOR SYSOP', 'SYSOP'], 'default' => 'USER', },
        'baud_rate'       => { 'type' => RADIO,   'max' => 5,   'min' => 5,  'choices' => ['FULL', '115200', '57600', '38400', '19200', '9600', '4800', '2400', '1200', '600', '300'], 'default' => 'FULL', },
        'login_time'      => { 'type' => STRING,  'max' => 10,  'min' => 10 },
        'logout_time'     => { 'type' => STRING,  'max' => 10,  'min' => 10 },
        'text_mode'       => { 'type' => RADIO,   'max' => 7,   'min' => 9, 'choices' => ['ANSI', 'ASCII', 'ATASCII', 'PETSCII'], 'default' => 'ASCII', },
        'max_rows'        => { 'type' => NUMERIC, 'max' => 3,   'min' => 3, 'default' => 25 },
        'max_columns'     => { 'type' => NUMERIC, 'max' => 3,   'min' => 3, 'default' => 80 },
        'timeout'         => { 'type' => NUMERIC, 'max' => 5,   'min' => 5, 'default' => 10 },
        'retro_systems'   => { 'type' => STRING,  'max' => 120, 'min' => 40 },
        'accomplishments' => { 'type' => STRING,  'max' => 120, 'min' => 40 },
        'prefer_nickname' => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'view_files'      => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'ON' },
        'banned'          => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'upload_files'    => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'download_files'  => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'remove_files'    => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'read_message'    => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'ON' },
        'post_message'    => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'remove_message'  => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'play_fortunes'   => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'ON' },
        'sysop'           => { 'type' => BOOLEAN, 'max' => 5,   'min' => 5, 'choices' => ['ON', 'OFF'], 'default' => 'OFF' },
        'password'        => { 'type' => STRING,  'max' => 64,  'min' => 32 },
    };

    $self->{'debug'}->DEBUG(['End SysOp Initialize']);
    return $self;
} ## end sub sysop_initialize

# Helper: map terminal width to section count
sub _sections_for_width {
    my ($wsize) = @_;
    return 1 if $wsize <= 80;
    return 2 if $wsize <= 120;
    return 3 if $wsize <= 160;
    return 4 if $wsize <= 200;
    return 5 if $wsize <= 240;
    return 6;
} ## end sub _sections_for_width

# Helper: build static token fields from $self
sub _build_static_tokens {
    my ($self, $versions, $bbs_versions) = @_;
    return {
        'HOSTNAME'     => $self->sysop_hostname,
        'IP ADDRESS'   => $self->sysop_ip_address(),
        'CPU BITS'     => $self->{'CPU'}->{'CPU BITS'},
        'CPU CORES'    => $self->{'CPU'}->{'CPU CORES'},
        'CPU SPEED'    => $self->{'CPU'}->{'CPU SPEED'},
        'CPU IDENTITY' => $self->{'CPU'}->{'CPU IDENTITY'},
        'CPU THREADS'  => $self->{'CPU'}->{'CPU THREADS'},
        'HARDWARE'     => $self->{'CPU'}->{'HARDWARE'},
        'VERSIONS'     => $versions,
        'BBS VERSIONS' => $bbs_versions,
        'BBS NAME'     => colored(['green'], $self->{'CONF'}->{'BBS NAME'}),
    };
} ## end sub _build_static_tokens

# Helper: build dynamic token closures (uniform style)
sub _build_dynamic_tokens {
    my ($self) = @_;
    return {
        'THREADS COUNT'   => sub { my $self = shift; return $self->{'CACHE'}->get('THREADS_RUNNING'); },
        'USERS COUNT'     => sub { my $self = shift; return $self->db_count_users(); },
        'UPTIME'          => sub { my $self = shift; my $uptime = `uptime -p`; chomp($uptime); return $uptime; },
        'DISK FREE SPACE' => sub { my $self = shift; return $self->sysop_disk_free(); },
        'MEMORY'          => sub { my $self = shift; return $self->sysop_memory(); },
        'ONLINE'          => sub { my $self = shift; return $self->sysop_online_count(); },
        'CPU LOAD'        => sub { my $self = shift; return $self->cpu_info->{'CPU LOAD'}; },
        'ENVIRONMENT'     => sub { my $self = shift; return $self->sysop_showenv(); },
        'FILE CATEGORY'   => sub {
			my $self = shift;
			my $sth  = $self->{'dbh'}->prepare('SELECT description FROM file_categories WHERE id=?');
			$sth->execute($self->{'USER'}->{'file_category'});
			my ($result) = $sth->fetchrow_array();
			return $self->news_title_colorize($result);
		},
        'SYSOP VIEW CONFIGURATION'   => sub { my $self = shift; return $self->sysop_view_configuration('string'); },
        'COMMANDS REFERENCE'         => sub { my $self = shift; return $self->sysop_list_commands(); },
        'MIDDLE VERTICAL RULE color' => sub { my $self = shift; my $color = shift; return $self->sysop_locate_middle('B_' . $color); },
    };
} ## end sub _build_dynamic_tokens

# Helper: get sorted keys plus optional appended items
sub _collect_names {
    my ($href, @extra) = @_;
    my @k = sort(keys %{$href});
    push @k, @extra if @extra;
    return @k;
} ## end sub _collect_names

# Helper: compute max width from list
sub _compute_max_width {
    my ($list_ref, $min) = @_;
    my $w = $min // 1;
    foreach my $cell (@{$list_ref}) { $w = max(length($cell), $w); }
    return $w;
} ## end sub _compute_max_width

# Helper: standard two-column table render with paging breaks
sub _render_table {
    my ($title_left, $title_right, $left_ref, $right_ref, $wsize, $srow) = @_;
    my $lw    = _compute_max_width($left_ref,  1);
    my $rw    = _compute_max_width($right_ref, 1);
    my $table = Text::SimpleTable->new($lw, $rw);
    $table->row($title_left, $title_right);
    $table->hr();
    my $count = 0;
    while (scalar(@{$left_ref}) || scalar(@{$right_ref})) {
        my $l = scalar(@{$left_ref})  ? shift(@{$left_ref})  : ' ';
        my $r = scalar(@{$right_ref}) ? shift(@{$right_ref}) : ' ';
        $table->row($l, $r);
        $count++;
        if ($count > $srow) {
            $count = 0;
            $table->hr();
            $table->row($title_left, $title_right);
            $table->hr();
        } ## end if ($count > $srow)
    } ## end while (scalar(@{$left_ref...}))
    return $table->twin('ORANGE')->draw();
} ## end sub _render_table

# Helper: substitutions registry
sub _substitutions_for_mode {
    my ($mode) = @_;
    return [
        # Common header highlight
        [qr/ (C|DESCRIPTION|TYPE|SYSOP MENU COMMANDS|SYSOP TOKENS|USER MENU COMMANDS|USER TOKENS|ATASCII TOKENS|PETSCII TOKENS|ASCII TOKENS) /, ' [% BRIGHT YELLOW %]$1[% RESET %] '],

        # USER/SYSOP italicize "color" and "text"
        ($mode =~ /USER|SYSOP/ ? ([qr/color/, '[% ITALIC %][% FAINT %]color[% RESET %]'], [qr/text/, '[% ITALIC %][% FAINT %]text[% RESET %]'],) : ()),

        # PETSCII color names mapped to ANSI
        ($mode eq 'PETSCII' ? ([qr/│ (WHITE)/, '│ [% BRIGHT WHITE %]$1[% RESET %]'], [qr/│ (YELLOW)/, '│ [% YELLOW %]$1[% RESET %]'], [qr/│ (CYAN)/, '│ [% CYAN %]$1[% RESET %]'], [qr/│ (GREEN)/, '│ [% GREEN %]$1[% RESET %]'], [qr/│ (PINK)/, '│ [% PINK %]$1[% RESET %]'], [qr/│ (BLUE)/, '│ [% BLUE %]$1[% RESET %]'], [qr/│ (RED)/, '│ [% RED %]$1[% RESET %]'], [qr/│ (PURPLE)/, '│ [% COLOR 127 %]$1[% RESET %]'], [qr/│ (DARK PURPLE)/, '│ [% COLOR 53 %]$1[% RESET %]'], [qr/│ (GRAY)/, '│ [% GRAY 9 %]$1[% RESET %]'], [qr/│ (BROWN)/, '│ [% COLOR 94 %]$1[% RESET %]'],) : ()),
    ];
} ## end sub _substitutions_for_mode

sub _apply_substitutions {
    my ($text, $rules) = @_;
    for my $rule (@$rules) {
        my ($re, $rep) = @$rule;
        $text =~ s/$re/$rep/g;
    }
    return $text;
} ## end sub _apply_substitutions

# Optional: isolate the very large ANSI catalog builder to its own function (preserving behavior)
sub _render_ansi_catalog {
    my ($self, $wsize) = @_;

    # This preserves the original logic and content, but organizes the huge string building
    # into manageable sections. The content below is copied verbatim from your ANSI branch,
    # with only structural arrangement and minor variable scoping cleanups.

    # Header banner
    my $text .= '[% BRIGHT GREEN %]╭' . '─' x 122 . '╮[% RESET %]' . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                                 _    _   _ ____ ___   _____ ___  _  _______ _   _ ____                                   [% BRIGHT GREEN %]│[% RESET %]} . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                                / \  | \ | / ___|_ _| |_   _/ _ \| |/ / ____| \ | / ___|                                  [% BRIGHT GREEN %]│[% RESET %]} . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                               / _ \ |  \| \___ \| |    | || | | | ' /|  _| |  \| \___ \                                  [% BRIGHT GREEN %]│[% RESET %]} . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                              / ___ \| |\  |___) | |    | || |_| | . \| |___| |\  |___) |                                 [% BRIGHT GREEN %]│[% RESET %]} . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                             /_/   \_\_| \_|____/___|   |_| \___/|_|\_\_____|_| \_|____/                                  [% BRIGHT GREEN %]│[% RESET %]} . "\n";
    $text .= q{[% BRIGHT GREEN %]│[% BRIGHT WHITE %]                                                                                                                          [% BRIGHT GREEN %]│[% RESET %]} . "\n";

    my $bar = '[% BRIGHT GREEN %]│[% RESET %]';
    # CLEAR section
    $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]CLEAR [% RESET %][% BRIGHT GREEN %]' . '═' x 56 . '╤' . '═' x 56 . '╡[% RESET %]' . "\n";
    {
        my @names = (sort(keys %{ $self->{'ansi_meta'}->{'clear'} }));
        while (scalar(@names)) {
            my $name = shift(@names);
            $text .= '[% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-63s', $name) . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', $self->ansi_description('clear', $name)) . ' [% BRIGHT GREEN %]│[% RESET %]' . "\n";
        }
    }

    # CURSOR section
    $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]CURSOR [% RESET %][% BRIGHT GREEN %]' . '═' x 55 . '╪' . '═' x 56 . '╡[% RESET %]' . "\n";
    {
        my @names = (sort(keys %{ $self->{'ansi_meta'}->{'cursor'} }));
        while (scalar(@names)) {
            my $name = shift(@names);
            $text .= "$bar " . sprintf('%-63s', $name) . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', $self->ansi_description('cursor', $name)) . " $bar\n";
        }
        $text .= "$bar " . sprintf('%-63s', 'LOCATE column,row') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Sets the cursor location') . " $bar\n";
        $text .= "$bar " . sprintf('%-63s', 'SCROLL UP count') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Scrolls the screen up by "count" lines') . " $bar\n";
        $text .= "$bar " . sprintf('%-63s', 'SCROLL DOWN count') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Scrolls the screen down by "count" lines') . " $bar\n";
    }

    # ATTRIBUTES section
    $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]ATTRIBUTES [% RESET %][% BRIGHT GREEN %]' . '═' x 51 . '╪' . '═' x 56 . '╡[% RESET %]' . "\n";
    {
        my @names = grep(!/FONT \d/, (sort(keys %{ $self->{'ansi_meta'}->{'attributes'} })));
        foreach my $name (@names) {
            if ($name =~ /FONT|HIDE|RING BELL/) {
                $text .= "$bar " . sprintf('%-63s', $name) . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', $self->ansi_description('attributes', $name)) . " $bar\n";
                $text .= "$bar " . sprintf('%-63s', 'FONT 1-9') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Set specific font (1-9)') . " $bar\n" if ($name eq 'FONT DEFAULT');
            } else {
                $text .= '[% BRIGHT GREEN %]│[% RESET %][% ' . $name . ' %]' . sprintf(' %-63s', $name) . ' [% RESET %][% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', $self->ansi_description('attributes', $name)) . " $bar\n";
            }
        } ## end foreach my $name (@names)
        $text .= "$bar " . sprintf('%-62s', 'UNDERLINE COLOR RGB red,green,blue ') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Set the underline color using RGB') . " $bar\n";
    }

    # Colors
    {
        my $f;
        my $b;
        foreach my $code ('ANSI 3 BIT','ANSI 4 BIT','ANSI 8 BIT','ANSI 24 BIT') {
            if ($code eq 'ANSI 3 BIT') {
                $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]' . sprintf('%-11s',$code) . ' [% RESET %][% BRIGHT GREEN %]════════════════╤═════════════════════════════════╪════════════════════════════════════════════════════════╡[% RESET %]' . "\n";
            } else {
                $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]' . sprintf('%-11s',$code) . ' [% RESET %][% BRIGHT GREEN %]════════════════╪═════════════════════════════════╪════════════════════════════════════════════════════════╡[% RESET %]' . "\n";
            }
            if ($code eq 'ANSI 8 BIT') {
				foreach my $count (16 .. 231) {
					$text .= '[% BRIGHT GREEN %]│[% RESET %][% COLOR ' . $count . ' %]' . sprintf(' %-29s ',"COLOR $count") . '[% RESET %][% BRIGHT GREEN %]│[% RESET %][% BLACK %][% B_COLOR ' . $count . ' %]' . sprintf(' %-31s ', "B_COLOR $count") . '[% RESET %][% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-54s ',$self->ansi_description('foreground',"COLOR $count")) . '[% BRIGHT GREEN %]│[% RESET %]' . "\n";
				}
				foreach my $count (0 .. 23) {
					$text .= '[% BRIGHT GREEN %]│[% RESET %][% GRAY ' . $count . ' %]' . sprintf(' %-29s ', "GRAY $count") . '[% RESET %][% BRIGHT GREEN %]│[% RESET %][% BLACK %][% B_GRAY ' . $count . ' %]' . sprintf(' %-31s ', "B_GRAY $count") . '[% RESET %][% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-54s ',$self->ansi_description('foreground',"GRAY $count")) . '[% BRIGHT GREEN %]│[% RESET %]' . "\n";
				}
            }
            foreach my $name (grep(!/COLOR |GRAY /,sort(keys %{$self->{'ansi_meta'}->{'foreground'}}))) {
                if ($self->ansi_type($self->{'ansi_meta'}->{'foreground'}->{$name}->{'out'}) eq $code) {
					if ($name =~ /^(DEFAULT|NAVY|COLOR 16|BLACK|MEDIUM BLUE|ARMY GREEN|BISTRE|BULGARIAN ROSE|CHARCOAL|COOL BLACK|DARK BLUE|DARK GREEN|DARK JUNGLE GREEN|DARK MIDNIGHT BLUE|DUKE BLUE|EGYPTIAN BLUE|MEDIUM JUNGLE GREEN|MIDNIGHT BLUE|NAVY BLUE|ONYX|OXFORD BLUE|PHTHALO BLUE|PHTHALO GREEN|PRUSSIAN BLUE|SAINT PATRICK BLUE|SEAL BROWN|SMOKEY BLACK|ULTRAMARINE|ZINNWALDITE BROWN)$/) {
						$text .= '[% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-29s ',$name) . '[% RESET %][% BRIGHT GREEN %]│[% RESET %][% B_' . $name . ' %]' . sprintf(' %-31s ', "B_${name}") . '[% RESET %]│' . sprintf(' %-54s ',$self->ansi_description('foreground',$name)) . '[% BRIGHT GREEN %]│[% RESET %]' . "\n";
					} else {
						$text .= '[% BRIGHT GREEN %]│[% RESET %][% ' . $name . ' %]' . sprintf(' %-29s ',$name) . '[% RESET %][% BRIGHT GREEN %]│[% RESET %][% BLACK %][% B_' . $name . ' %]' . sprintf(' %-31s ', "B_${name}") . '[% RESET %][% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-54s ',$self->ansi_description('foreground',$name)) . '[% BRIGHT GREEN %]│[% RESET %]' . "\n";
					}
				}
            }
        }
        $text .= '[% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-29s ','RGB red,green,blue') . '[% RESET %][% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-31s ', 'B_RGB red,green,blue') . '[% RESET %][% BRIGHT GREEN %]│[% RESET %]' . sprintf(' %-54s ','Set color to a value 0-255 per primary color.') . '[% BRIGHT GREEN %]│[% RESET %]' . "\n";
    }

    # Special
    $text .= '[% BRIGHT GREEN %]╞══ [% BOLD %][% BRIGHT YELLOW %]SPECIAL [% RESET %][% BRIGHT GREEN %]════════════════════╧═════════════════════════════════╪════════════════════════════════════════════════════════╡[% RESET %]' . "\n";

    {
        my @names = (sort(keys %{$self->{'ansi_meta'}->{'special'}}));
        while(scalar(@names)) {
            my $name = shift(@names);
            $text .= "$bar " . sprintf('%-63s',$name) . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s',$self->ansi_description('special',$name)) . " $bar\n";
        }
        $text .= '[% BRIGHT GREEN %]│ ─────────────────────────────────────────────────────────────── │ ────────────────────────────────────────────────────── │[% RESET %]' . "\n";
        $text .= "$bar " . sprintf('%-63s', 'HORIZONTAL RULE color') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s','Horizontal rule the width of the screen in the') . " $bar\n";
        $text .= '[% BRIGHT GREEN %]│[% RESET %]                                                                 [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s','specified color.') . " $bar\n";
        $text .= '[% BRIGHT GREEN %]│ ─────────────────────────────────────────────────────────────── │ ────────────────────────────────────────────────────── │[% RESET %]' . "\n";
        $text .= "$bar " . sprintf('%-63s','BOX color,column,row,width,height,type') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Shows framed text box in the selected frame type and') . " $bar\n";
        $text .= "$bar " . sprintf('%-63s',' ') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'color.  Text goes between the BOX and ENDBOX token') . " $bar\n";
        $text .= "$bar " . sprintf('%-63s','    types:') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'See the "frames" option') . " $bar\n";
        $text .= "$bar " . sprintf('%63s','DOUBLE, THIN, THICK, CIRCLE, ROUNDED, BLOCK, WEDGE') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', ' ') . " $bar\n";
        $text .= "$bar " . sprintf('%63s','BIG WEDGE, DOTS, DIAMOND, STAR, SQUARE, DITHERED, NOTES') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', ' ') . " $bar\n";
        $text .= "$bar " . sprintf('%63s','HEARTS, CHRISTIAN, ARROWS, BIG ARROWS, PARALLELOGRAM') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', ' ') . " $bar\n";
        $text .= "$bar " . sprintf('%-63s','ENDBOX') . ' [% BRIGHT GREEN %]│[% RESET %] ' . sprintf('%-54s', 'Ends the BOX token function') . " $bar\n";
    }
    $text .= '[% BRIGHT GREEN %]╰─────────────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────╯[% RESET %]' . "\n";

    # Post processing identical to original
    {
        my $new = 'UNDERLINE COLOR RGB [% UNDERLINE COLOR RGB 255,0,0 %][% UNDERLINE %]red[% RESET %],[% UNDERLINE %][% UNDERLINE COLOR RGB 0,255,0 %]green[% RESET %],[% UNDERLINE %][% UNDERLINE COLOR RGB 0,0,255 %]blue[% RESET %]';
        $text =~ s/UNDERLINE COLOR RGB red,green,blue/$new /gs;

        $new = '[% FAINT %][% ITALIC %] color     [% RESET %]';
        $text =~ s/ color     /$new/gs;

        $new = '[% FAINT %][% ITALIC %] count     [% RESET %]';
        $text =~ s/ count     /$new/gs;

        $new = ' [% RED %][% ITALIC %]red[% RESET %],[% GREEN %][% ITALIC %]green[% RESET %],[% BLUE %][% ITALIC %]blue[% RESET %]';
        $text =~ s/ red,green,blue/$new/gs;

        $new = ' [% FAINT %][% ITALIC %]column[% RESET %],[% FAINT %][% ITALIC %]row[% RESET %] ';
        $text =~ s/ column,row /$new/gs;

        $new = ' [% FAINT %][% ITALIC %]color[% RESET %],[% FAINT %][% ITALIC %]column[% RESET %],[% FAINT %][% ITALIC %]row[% RESET %],[% FAINT %][% ITALIC %]width[% RESET %],[% FAINT %][% ITALIC %]height[% RESET %],[% FAINT %][% ITALIC %]type[% RESET %] ';
        $text =~ s/ color,column,row,width,height,type /$new/gs;
    }

    return $text;
} ## end sub _render_ansi_catalog

sub sysop_list_commands {
    my $self = shift;
    my $mode = shift;

    $self->{'debug'}->DEBUG(['Start SysOp List Commands']);

    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    my $size = ($hsize - ($self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST')));
    my $srow = $size - 5;

    my $text = '';

    if ($mode && $mode eq 'ASCII') {
        my @asctkn = (sort(keys %{ $self->{'ascii_meta'} }), 'HORIZONTAL RULE');
        my $asc    = 12;
        foreach my $cell (@asctkn) { $asc = max(length($cell), $asc); }
        my $table = Text::SimpleTable->new($asc, 25);
        $table->row('ASCII TOKENS', 'DESCRIPTION');
        $table->hr();
        while (scalar(@asctkn)) {
            my $ascii_tokens = shift(@asctkn);
            $table->row($ascii_tokens, $self->{'ascii_meta'}->{$ascii_tokens}->{'desc'});
        }
        $text = $self->center($table->twin('ORANGE')->draw(), $wsize);

    } elsif ($mode && $mode eq 'ANSI') {

        # Use refactored dedicated ANSI builder while preserving original output
        $text = _render_ansi_catalog($self, $wsize);

    } elsif ($mode && $mode eq 'ATASCII') {
        my @atatkn = (sort(keys %{ $self->{'atascii_meta'} }));

        $text  = '[% ORANGE %]╔' . '═' x 86 . '╗[% RESET %]' . "\n";
        $text .= "[% ORANGE %]║[% YELLOW  %]    ## ## ##          [% BRIGHT BLUE %]╔═══╗ ╒═╦═╕ ╔═══╗ ╔═══╗ ╔═══╕ ╒═╦═╕ ╒═╦═╕       [% YELLOW  %]    ## ## ##    [% ORANGE %]║[% RESET %]\n";
        $text .= "[% ORANGE %]║[% GREEN   %]    ## ## ##          [% BRIGHT BLUE %]║   ║   ║   ║   ║ ║   ╜ ║       ║     ║         [% GREEN   %]    ## ## ##    [% ORANGE %]║[% RESET %]\n";
        $text .= "[% ORANGE %]║[% CYAN    %]    ## ## ##          [% BRIGHT BLUE %]╠═══╣   ║   ╠═══╣ ╚═══╗ ║       ║     ║         [% CYAN    %]    ## ## ##    [% ORANGE %]║[% RESET %]\n";
        $text .= "[% ORANGE %]║[% BLUE    %]  ###  ##  ###        [% BRIGHT BLUE %]║   ║   ║   ║   ║ ╓   ║ ║       ║     ║         [% BLUE    %]  ###  ##  ###  [% ORANGE %]║[% RESET %]\n";
        $text .= "[% ORANGE %]║[% MAGENTA %] ###   ##   ###       [% BRIGHT BLUE %]╜   ╙   ╙   ╜   ╙ ╚═══╝ ╚═══╛ ╘═╩═╛ ╘═╩═╛       [% MAGENTA %] ###   ##   ### [% ORANGE %]║[% RESET %]\n";
        $text .= '[% ORANGE %]╠══════╦' . '═' x 39 . '╦' . '═' x 39 . '╣[% RESET %]' . "\n";
        $text .= "[% ORANGE %]║[% BRIGHT YELLOW %] CHAR [% ORANGE %]║[% BRIGHT YELLOW %] ATASCII TOKENS                        [% ORANGE %]║[% BRIGHT YELLOW %] DESCRIPTION                           [% ORANGE %]║[% RESET %]\n";
        $text .= '[% ORANGE %]╠══════╬' . '═' x 39 . '╬' . '═' x 39 . '╣[% RESET %]' . "\n";

        foreach my $name (@atatkn) {
            $text .= '[% ORANGE %]║[% RESET %]  ' . $self->{'atascii_meta'}->{$name}->{'unicode'} . '   [% ORANGE %]║[% RESET %] ' . sprintf('%-37s %s %-37s %s', $name, '[% ORANGE %]║[% RESET %]', $self->{'atascii_meta'}->{$name}->{'desc'}, '[% ORANGE %]║[% RESET %]') . "\n";
        }
		$text .= '[% ORANGE %]║[% RESET %] ' . '[% HORIZONTAL BAR %]' x 4 . ' [% ORANGE %]║[% RESET %] ' . sprintf('%-37s %s %-37s %s', 'HORIZONTAL RULE', '[% ORANGE %]║[% RESET %]', 'Horizontal rule', '[% ORANGE %]║[% RESET %]') . "\n";

        $text .= "[% ORANGE %]╚══════╩═══════════════════════════════════════╩═══════════════════════════════════════╝[% RESET %]\n";

    } elsif ($mode && $mode eq 'PETSCII') {
        # ─ ━ │ ┃ ┄ ┅ ┆ ┇ ┈ ┉ ┊ ┋ ┌ ┍ ┎ ┏ ┐ ┑ ┒ ┓ └ ┕ ┖ ┗ ┘ ┙ ┚ ┛ ├ ┝ ┞ ┟ ┠ ┡ ┢ ┣ ┤ ┥ ┦ ┧ ┨ ┩ ┪ ┫ ┬ ┭ ┮ ┯ ┰ ┱ ┲ ┳ ┴ ┵ ┶ ┷ ┸ ┹ ┺ ┻ ┼ ┽ ┾ ┿ ╀ ╁ ╂ ╃ ╄ ╅ ╆ ╇ ╈ ╉ ╊ ╋ ╌ ╍ ╎ ╏ ═ ║ ╒ ╓ ╔ ╕ ╖ ╗ ╘ ╙ ╚ ╛ ╜ ╝ ╞ ╟ ╠ ╡ ╢ ╣ ╤ ╥ ╦ ╧ ╨ ╩ ╪ ╫ ╬ ╭ ╮ ╯ ╰ ╱ ╲ ╳ ╴ ╵ ╶ ╷ ╸ ╹ ╺ ╻ ╼ ╽ ╾ ╿
		# 🬀 🬁 🬂 🬃 🬄 🬅 🬆 🬇 🬈 🬉 🬊 🬋 🬌 🬍 🬎 🬏 🬐 🬑 🬒 🬓 🬔 🬕 🬖 🬗 🬘 🬙 🬚 🬛 🬜 🬝 🬞 🬟 🬠 🬡 🬢 🬣 🬤 🬥 🬦 🬧 🬨 🬩 🬪 🬫 🬬 🬭 🬮 🬯 🬰 🬱 🬲 🬳 🬴 🬵 🬶 🬷 🬸 🬹 🬺 🬻 🬼 🬽 🬾 🬿 🭀 🭁 🭂 🭃 🭄 🭅 🭆 🭇 🭈 🭉 🭊 🭋 🭌 🭍 🭎 🭏 🭐 🭑 🭒 🭓 🭔 🭕 🭖 🭗 🭘 🭙 🭚 🭛 🭜 🭝 🭞 🭟 🭠 🭡 🭢 🭣 🭤 🭥 🭦 🭧 🭨 🭩 🭪 🭫 🭬 🭭 🭮 🭯
		#  🭰 🭱 🭲 🭳 🭴 🭵 🭶 🭷 🭸 🭹 🭺 🭻 🭼 🭽 🭾 🭿 🮀 🮁 🮂 🮃 🮄 🮅 🮆 🮇 🮈 🮉 🮊 🮋 🮌 🮍 🮎 🮏 🮐 🮑 🮒 🮔 🮕 🮖 🮗 🮘 🮙 🮚 🮛 🮜 🮝 🮞 🮟 🮠 🮡 🮢 🮣 

        my @pettkn = sort(keys %{ $self->{'petscii_meta'} });

        $text  = '[% ORANGE %]╔' . '═' x 108 . '╗[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %] .o88b. [% RESET                                           %][% BRIGHT WHITE %]                          8""""8 8"""" ""8"" 8""""8 8""""8 8  8                        [% BLUE %] .o88b. [% RESET %]    [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %]d8P  Y8 [% RESET                                           %][% BRIGHT WHITE %]                          8    8 8       8   8      8    " 8  8                        [% BLUE %]d8P  Y8 [% RESET %]    [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %]8P     🮅🮅🮅🭚[% RESET                                           %][% BRIGHT WHITE %]                       8eeee8 8eeee   8e  8eeeee 8e     8e 8e                       [% BLUE %]8P     🮅🮅🮅🭚[% RESET %] [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %]8b     [% RED %][% REVERSE %]🮂🮂🮂[% RESET %][% RED %]🬿[% RESET %][% BRIGHT WHITE %]                       88     88      88      88 88     88 88                       [% BLUE %]8b     [% RED %][% REVERSE %]🮂🮂🮂[% RESET %][% RED %]🬿[% RESET %] [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %]Y8b  d8 [% RESET                                           %][% BRIGHT WHITE %]                          88     88      88  e   88 88   e 88 88                       [% BLUE %]Y8b  d8 [% RESET %]    [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% RESET %] [% BLUE %]' . " `Y88P'" . '[% RESET                                 %][% BRIGHT WHITE %]                           88     88eee   88  8eee88 88eee8 88 88                       ' . "[% BLUE %] `Y88P'" . '[% RESET %]     [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]╠══════╦' . '═' x 50 . '╦' . '═' x 50 . '╣[% RESET %]' . "\n";
        $text .= '[% ORANGE %]║[% BRIGHT YELLOW %] CHAR [% ORANGE %]║[% BRIGHT YELLOW %] PETSCII TOKENS                                   [% ORANGE %]║[% BRIGHT YELLOW %] DESCRIPTION                                      [% ORANGE %]║[% RESET %]' . "\n";
        $text .= '[% ORANGE %]╠══════╬' . '═' x 50 . '╬' . '═' x 50 . '╣[% RESET %]' . "\n";

        foreach my $name (@pettkn) {
            $text .= '[% ORANGE %]║[% RESET %]  ' . $self->{'petscii_meta'}->{$name}->{'unicode'} . '   [% ORANGE %]║[% RESET %] ' . sprintf('%-48s %s %-48s %s', $name, '[% ORANGE %]║[% RESET %]', $self->{'petscii_meta'}->{$name}->{'desc'}, '[% ORANGE %]║[% RESET %]') . "\n";
        }
        $text .= '[% ORANGE %]║[% RESET %] ' . '[% HORIZONTAL BAR %]' x 4 . ' [% ORANGE %]║[% RESET %] ' . sprintf('%-48s %s %-48s %s', 'HORIZONTAL RULE color', '[% ORANGE %]║[% RESET %]', 'Horizontal rule in specified color', '[% ORANGE %]║[% RESET %]') . "\n";

        $text .= '[% ORANGE %]╚══════╩' . '═' x 50 . '╩' . '═' x 50 . '╝[% RESET %]' . "\n";

        $text =~ s/│ (WHITE)/│ \[\% BRIGHT WHITE \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (YELLOW)/│ \[\% YELLOW \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (CYAN)/│ \[\% CYAN \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (GREEN)/│ \[\% GREEN \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (PINK)/│ \[\% PINK \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (BLUE)/│ \[\% BLUE \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (RED)/│ \[\% RED \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (PURPLE)/│ \[\% COLOR 127 \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (DARK PURPLE)/│ \[\% COLOR 53 \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (GRAY)/│ \[\% GRAY 9 \%\]$1\[\% RESET \%\]/g;
        $text =~ s/│ (BROWN)/│ \[\% COLOR 94 \%\]$1\[\% RESET \%\]/g;

    } elsif ($mode && $mode eq 'USER') {
        my @usr = (sort(keys %{ $self->{'COMMANDS'} }));
        my @tkn = (sort(keys %{ $self->{'TOKENS'} }, 'JUSTIFIED text ENDJUSTIFIED', 'WRAP text ENDWRAP'));
        my $y   = 1;
        my $z   = 1;
        foreach my $cell (@usr) { $y = max(length($cell), $y); }
        foreach my $cell (@tkn) { $z = max(length($cell), $z); }
        my $table = Text::SimpleTable->new($y, $z);
        $table->row('USER MENU COMMANDS', 'USER TOKENS');
        $table->hr();
        my ($user_names, $token_names);
        my $count = 0;

        while (scalar(@usr) || scalar(@tkn)) {
            $user_names  = scalar(@usr) ? shift(@usr) : ' ';
            $token_names = scalar(@tkn) ? shift(@tkn) : ' ';
            $table->row($user_names, $token_names);
            $count++;
            if ($count > $srow) {
                $count = 0;
                $table->hr();
                $table->row('USER MENU COMMANDS', 'USER TOKENS');
                $table->hr();
            } ## end if ($count > $srow)
        } ## end while (scalar(@usr) || scalar...)
        $text = $self->center($table->twin('ORANGE')->draw(), $wsize);
        foreach my $name (qw(color text)) {
            my $ch = '[% ITALIC %][% FAINT %]' . $name . '[% RESET %]';
            $text =~ s/$name/$ch/gs;
        }

    } elsif ($mode && $mode eq 'SYSOP') {
        my @sys  = (sort(keys %{$main::SYSOP_COMMANDS}));
        my @stkn = (sort(keys %{ $self->{'sysop_tokens'} }, 'JUSTIFIED text ENDJUSTIFIED', 'WRAP text ENDWRAP'));
        my $x    = 1;
        my $xt   = 1;
        foreach my $cell (@sys)  { $x  = max(length($cell), $x); }
        foreach my $cell (@stkn) { $xt = max(length($cell), $xt); }
        my $table = Text::SimpleTable->new($x, $xt);
        $table->row('SYSOP MENU COMMANDS', 'SYSOP TOKENS');
        $table->hr();
        my ($sysop_names, $sysop_tokens);
        my $count = 0;

        while (scalar(@sys) || scalar(@stkn)) {
            $sysop_names  = scalar(@sys)  ? shift(@sys)  : ' ';
            $sysop_tokens = scalar(@stkn) ? shift(@stkn) : ' ';
            $table->row($sysop_names, $sysop_tokens);
            $count++;
            if ($count > $srow) {
                $count = 0;
                $table->hr();
                $table->row('SYSOP MENU COMMANDS', 'SYSOP TOKENS');
                $table->hr();
            } ## end if ($count > $srow)
        } ## end while (scalar(@sys) || scalar...)
        $text = $self->center($table->twin('ORANGE')->draw(), $wsize);
        foreach my $name (qw(color text)) {
            my $ch = '[% ITALIC %][% FAINT %]' . $name . '[% RESET %]';
            $text =~ s/$name/$ch/gs;
        }
    } ## end elsif ($mode && $mode eq ...)

    # Common header highlights (preserving original behavior)
    $text =~ s/ (DESCRIPTION|TYPE|SYSOP MENU COMMANDS|SYSOP TOKENS|USER MENU COMMANDS|USER TOKENS|PETSCII TOKENS|ASCII TOKENS) / \[\% BRIGHT YELLOW \%\]$1\[\% RESET \%\] /g;

    $self->{'debug'}->DEBUG(['End SysOp List Commands']);
    return ($self->ansi_decode($text));
} ## end sub sysop_list_commands

sub sysop_online_count {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Online Count']);
    my $count = $self->{'CACHE'}->get('ONLINE');
    $self->{'debug'}->DEBUG(["  SysOp Online Count $count", 'End SysOp Online Count']);
    return ($count);
} ## end sub sysop_online_count

sub sysop_versions_format {
    my $self     = shift;
    my $sections = shift;
    my $bbs_only = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Versions Format']);
    my $versions = "\n";
    my $heading  = '';          #  = "\t";
    my $counter  = $sections;

    for (my $count = $sections - 1; $count > 0; $count--) {
        $heading .= ' NAME                         VERSION ';
        if ($count) {
            $heading .= "\t";
        } else {
            $heading .= "\n";
        }
    } ## end for (my $count = $sections...)
    $heading = '[% BRIGHT YELLOW %][% B_RED %]' . $heading . '[% RESET %]';
    foreach my $v (sort(keys %{ $self->{'VERSIONS'} })) {
        next if ($bbs_only && $v !~ /^BBS/);
        $versions .= sprintf(' %-28s  %.03f', $v, $self->{'VERSIONS'}->{$v});
        $counter--;
        if ($counter <= 1) {
            $counter = $sections;
            $versions .= "\n";
        } else {
            $versions .= "\t";
        }
    } ## end foreach my $v (sort(keys %{...}))
    chop($versions) if (substr($versions, -1, 1) eq "\t");
    $self->{'debug'}->DEBUG(['End SysOp Versions Format']);
    return ($heading . $versions . "\n");
} ## end sub sysop_versions_format

sub sysop_disk_free {    # Show the Disk Free portion of Statistics
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Disk Free']);
    my $diskfree = '';
    if ((-e '/usr/bin/duf' || -e '/usr/local/bin/duf') && $self->configuration('USE DUF') =~ /^(TRUE|YES|OM)$/) {
        my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
        $diskfree = `duf -theme ansi -width $wsize`;
    } else {
        my @free  = split(/\n/, `nice df -h -T`);    # Get human readable disk free showing type
        my $width = 1;
        foreach my $l (@free) {
            $width = max(length($l), $width);        # find the width of the widest line
        }
        foreach my $line (@free) {
            next if ($line =~ /tmp|boot/);
            if ($line =~ /^Filesystem/) {
                $diskfree .= '[% B_BLUE %][% BRIGHT YELLOW %]' . " $line " . ' ' x ($width - length($line)) . "[% RESET %]\n";    # Make the heading the right width
            } else {
                $diskfree .= " $line\n";
            }
        } ## end foreach my $line (@free)
    } ## end else [ if ((-e '/usr/bin/duf'...))]
    $self->{'debug'}->DEBUG(['End SysOp Disk Free']);
    return ($diskfree);
} ## end sub sysop_disk_free

sub sysop_load_menu {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Load Menu', "  SysOp Load Menu $file"]);
    my $mapping = { 'TEXT' => '' };
    my $mode    = 1;
    my $text    = locate($row, 1) . cldown;
    open(my $FILE, '<', $file);

    shift(@{ $self->{'sysop_menu_files'} });
    push(@{ $self->{'sysop_menu_files'} }, $file);
    for (my $count = 0; $count < 5; $count++) {
        if ($count == 4) {
            print locate(($count + 1), 108), colored(['green', 'on_black'], clline . $self->{'sysop_menu_files'}->[$count]);
        } else {
            print locate(($count + 1), 108), colored(['ansi22', 'on_black'], clline . $self->{'sysop_menu_files'}->[$count]);
        }
    } ## end for (my $count = 0; $count...)
    while (chomp(my $line = <$FILE>)) {
        next if ($line =~ /^\#/);
        if ($mode) {
            if ($line !~ /^---/) {
                my ($k, $cmd, $color, $t) = split(/\|/, $line);
                $k   = uc($k);
                $cmd = uc($cmd);
                $self->{'debug'}->DEBUGMAX([$k, $cmd, $color, $t]);
                $mapping->{$k} = {
                    'command' => $cmd,
                    'color'   => $color,
                    'text'    => $t,
                };
            } else {
                $mode = 0;
            }
        } else {
            $mapping->{'TEXT'} .= $self->sysop_detokenize($line) . "\n";
        }
    } ## end while (chomp(my $line = <$FILE>...))
    close($FILE);
    $self->{'debug'}->DEBUG(['End SysOp Load Menu']);
    return ($mapping);
} ## end sub sysop_load_menu

sub sysop_pager {
    my $self   = shift;
    my $text   = shift;
    my $offset = (scalar(@_)) ? shift : 0;

    $self->{'debug'}->DEBUG(['Start SysOp Pager']);
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    my @lines;
    @lines = split(/\n$/, $text);
    my $size = ($hsize - ($self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST')));
    $size -= $offset;
    my $scroll = TRUE;
    my $count  = 1;

    while (scalar(@lines)) {
        my $line = shift(@lines);
        $self->sysop_output("$line\n");

        #        $self->sysop_ansi_output("$line\n");
        $count++;
        if ($count >= $size) {
            $count  = 1;
            $scroll = $self->sysop_scroll();
            last unless ($scroll);
        }
    } ## end while (scalar(@lines))
    $self->{'debug'}->DEBUG(['End SysOp Pager']);
    return ($scroll);
} ## end sub sysop_pager

sub sysop_parse_menu {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    my $row     = $self->{'CACHE'}->get('START_ROW') + $self->{'CACHE'}->get('ROW_ADJUST');
    my $animate = ($self->{'CONF'}->{'SYSOP ANIMATED MENU'}) ? TRUE : FALSE;
    $self->{'debug'}->DEBUG(['Start SysOp Parse Menu', "  SysOp Parse Menu $file"]);
    my $mapping = $self->sysop_load_menu($row, $file);
    print locate($row, 1), cldown;
    my $scroll = $self->sysop_pager($mapping->{'TEXT'}, 3);
    my $keys   = '';
    print "\r", cldown unless ($scroll);
    $self->sysop_show_choices($mapping);
    $self->sysop_prompt('Choose');
    my $key;
    do {
        $key = uc($self->sysop_keypress($row, $animate));
        threads->yield();
    } until (exists($mapping->{$key}));
    print $mapping->{$key}->{'command'}, "\n";
    $self->{'debug'}->DEBUG(['End SysOp Parse Menu']);
    return ($mapping->{$key}->{'command'});
} ## end sub sysop_parse_menu

sub sysop_decision {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start SysOp Decision']);
    my $response;
    do {
        $response = uc($self->sysop_keypress());
    } until ($response =~ /Y|N/i || $response eq chr(13));
    if ($response eq 'Y') {
        print "YES\n";
        $self->{'debug'}->DEBUG(['  SysOp Decision YES']);
        $self->{'debug'}->DEBUG(['End SysOp Decision']);
        return (TRUE);
    } ## end if ($response eq 'Y')
    $self->{'debug'}->DEBUG(['  SysOp Decision NO']);
    print "NO\n";
    $self->{'debug'}->DEBUG(['End SysOp Decision']);
    return (FALSE);
} ## end sub sysop_decision

sub sysop_keypress {
    my $self = shift;
    my $row;
    my $animate = FALSE;
    if (scalar(@_)) {
        $row     = shift;
        $animate = shift;
    }

    my $key;
    do {
        $self->{'CACHE'}->set('SHOW_STATUS', FALSE);
        ReadMode 'ultra-raw';
        $key = ReadKey(0.25);
        ReadMode 'restore';
        $self->sysop_animate($row) if ($animate);
        threads->yield();
        $self->{'CACHE'}->set('SHOW_STATUS', TRUE);
    } until (defined($key));
    return ($key);
} ## end sub sysop_keypress

sub sysop_animate {
    my $self = shift;
    my $row  = shift;

    my @color = @{ $self->{'sysop_menu_colors'} };

    my $text = "\e[s" . "\e[1;91H\e[48;2;0;0;96m\e[93m " . $self->clock() . " \e[" . $row++ . ";1H\e[" . $color[0] . "m◥\e[" . ($color[0] + 10) . "m \e[0m\e[" . $color[0] . "m\e[7m◥\e[0m" . "\e[" . $row++ . ";2H\e[" . $color[1] . "m◥\e[" . ($color[1] + 10) . "m \e[0m\e[" . $color[1] . "m\e[7m◥\e[0m" . "\e[" . $row++ . ";3H\e[" . $color[2] . "m◥\e[" . ($color[2] + 10) . "m \e[0m\e[" . $color[2] . "m\e[7m◥\e[0m" . "\e[" . $row++ . ";3H\e[" . $color[3] . "m◢\e[" . ($color[3] + 10) . "m \e[0m\e[" . $color[3] . "m\e[7m◢\e[0m" . "\e[" . $row++ . ";2H\e[" . $color[4] . "m◢\e[" . ($color[4] + 10) . "m \e[0m\e[" . $color[4] . "m\e[7m◢\e[0m" . "\e[" . $row++ . ";1H\e[" . $color[5] . "m◢\e[" . ($color[5] + 10) . "m \e[0m\e[" . $color[5] . "m\e[7m◢\e[0m" . "\e[u";

    $self->{'CACHE'}->set('SHOW_STATUS', FALSE);
    print $text;
    $self->{'CACHE'}->set('SHOW_STATUS', TRUE);

    my $l = pop(@color);
    unshift(@color, $l);
    $self->{'sysop_menu_colors'} = \@color;
} ## end sub sysop_animate

sub sysop_ip_address {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp IP Address']);
    chomp(my $ip = `nice hostname -I`);
    $self->{'debug'}->DEBUG(["  SysOp IP Address:  $ip", 'End SysOp IP Address']);
    return ($ip);
} ## end sub sysop_ip_address

sub sysop_hostname {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Hostname']);
    chomp(my $hostname = `nice hostname`);
    $self->{'debug'}->DEBUG(["  SysOp Hostname:  $hostname", 'End SysOp Hostname']);
    return ($hostname);
} ## end sub sysop_hostname

sub sysop_locate_middle {
    my $self  = shift;
    my $color = (scalar(@_)) ? shift : 'B_WHITE';

    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    my $middle = int($wsize / 2);
    my $string;
    if ($color =~ /^B_/) {
        $string = "\r" . $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x $middle . $self->{'ansi_meta'}->{'background'}->{$color}->{'out'} . ' ' . $self->{'ansi_meta'}->{'attributes'}->{'RESET'}->{'out'};
    } else {
        $string = "\r" . $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x $middle . $self->{'ansi_meta'}->{'foreground'}->{$color}->{'out'} . ' ' . $self->{'ansi_meta'}->{'attributes'}->{'RESET'}->{'out'};
    }
    return ($string);
} ## end sub sysop_locate_middle

sub sysop_memory {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Memory']);
    my $memory = `nice free`;
    my @mem    = split(/\n$/, $memory);
    my $output = '[% BLACK %][% B_GREEN %]  ' . shift(@mem) . ' [% RESET %]' . "\n";
    while (scalar(@mem)) {
        $output .= shift(@mem) . "\n";
    }
    if ($output =~ /(Mem\:       )/) {
        my $ch = '[% BLACK %][% B_GREEN %] ' . $1 . ' [% RESET %]';
        $output =~ s/Mem\:       /$ch/;
    }
    if ($output =~ /(Swap\:      )/) {
        my $ch = '[% BLACK %][% B_GREEN %] ' . $1 . ' [% RESET %]';
        $output =~ s/Swap\:      /$ch/;
    }
    $self->{'debug'}->DEBUG(['End SysOp Memory']);
    return ($output);
} ## end sub sysop_memory

sub sysop_true_false {
    my $self    = shift;
    my $boolean = shift;
    my $mode    = shift;

    $boolean = $boolean + 0;
    if ($mode eq 'TF') {
        return (($boolean) ? 'TRUE' : 'FALSE');
    } elsif ($mode eq 'YN') {
        return (($boolean) ? 'YES' : 'NO');
	} elsif ($mode eq 'OO') {
		return(($boolean) ? 'ON' : 'OFF');
    }
    return ($boolean);
} ## end sub sysop_true_false

sub sysop_list_users {
    my $self      = shift;
    my $list_mode = shift;

    $self->{'debug'}->DEBUG(['Start SysOp List Users']);
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    my $table;
    my $date_format = $self->configuration('DATE FORMAT');
    $date_format =~ s/YEAR/\%Y/;
    $date_format =~ s/MONTH/\%m/;
    $date_format =~ s/DAY/\%d/;
    my $name_width  = 15;
    my $value_width = $wsize - 22;
    my $sth;
    my @order;
    my $sql;

    if ($list_mode =~ /DETAILED/) {
        $sql   = q{ SELECT * FROM users_view };
        $sth   = $self->{'dbh'}->prepare($sql);
        @order = @{ $self->{'SYSOP ORDER DETAILED'} };
    } else {
        @order = @{ $self->{'SYSOP ORDER ABBREVIATED'} };
        $sql   = 'SELECT id,username,fullname,given,family,nickname,text_mode FROM users_view';
        $sth   = $self->{'dbh'}->prepare($sql);
    }
    $sth->execute();
    if ($list_mode =~ /VERTICAL/) {
        while (my $row = $sth->fetchrow_hashref()) {
            foreach my $name (@order) {
                next if ($name =~ /retro_systems|accomplishments/);
                if ($name ne 'id' && $row->{$name} =~ /^(0|1)$/) {
                    $row->{$name} = $self->sysop_true_false($row->{$name}, 'YN');
                }
                $value_width = max(length($row->{$name}), $value_width);
            } ## end foreach my $name (@order)
        } ## end while (my $row = $sth->fetchrow_hashref...)
        $sth->finish();
        $sth = $self->{'dbh'}->prepare($sql);
        $sth->execute();
        $table = Text::SimpleTable->new($name_width, $value_width);
        $table->row('NAME', 'VALUE');

        while (my $Row = $sth->fetchrow_hashref()) {
            $table->hr();
            foreach my $name (@order) {
                if ($name !~ /id|time/ && $Row->{$name} =~ /^(0|1)$/) {
                    $Row->{$name} = $self->sysop_true_false($Row->{$name}, 'YN');
                } elsif ($name eq 'timeout') {
                    $Row->{$name} = $Row->{$name} . ' Minutes';
                }
                $self->{'debug'}->DEBUGMAX([$name, $Row->{$name}]);
                $table->row($name . '', $Row->{$name} . '');
            } ## end foreach my $name (@order)
        } ## end while (my $Row = $sth->fetchrow_hashref...)
        $sth->finish();
        my $string = $table->thick('CYAN')->draw();
        my $ch     = colored(['bright_yellow'], 'NAME');
        $string =~ s/ NAME / $ch /;
        $ch = colored(['bright_yellow'], 'VALUE');
        $string =~ s/ VALUE / $ch /;
        $self->sysop_pager("$string\n");
    } else {    # Horizontal
        my @hw;
        foreach my $name (@order) {
            push(@hw, $self->{'SYSOP FIELD TYPES'}->{$name}->{'min'});
        }
        $table = Text::SimpleTable->new(@hw);
        if ($list_mode =~ /ABBREVIATED/) {
            $table->row(@order);
        } else {
            my @title = ();
            foreach my $heading (@order) {
                push(@title, $self->sysop_vertical_heading($heading));
            }
            $table->row(@title);
        } ## end else [ if ($list_mode =~ /ABBREVIATED/)]
        $table->hr();
        while (my $row = $sth->fetchrow_hashref()) {
            my @vals = ();
            foreach my $name (@order) {
                push(@vals, $row->{$name} . '');
                $self->{'debug'}->DEBUGMAX([$name, $row->{$name}]);
            }
            $table->row(@vals);
        } ## end while (my $row = $sth->fetchrow_hashref...)
        $sth->finish();
        my $string = $table->thick('CYAN')->draw();
        $self->sysop_pager("$string\n");
    } ## end else [ if ($list_mode =~ /VERTICAL/)]
    print 'Press a key to continue ... ';
    $self->{'debug'}->DEBUG(['End SysOp List Users']);
    return ($self->sysop_keypress());
} ## end sub sysop_list_users

sub sysop_delete_files { # Placeholder
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Delete Files']);
    $self->{'debug'}->DEBUG(['End SysOp Delete Files']);
    return (TRUE);
} ## end sub sysop_delete_files

sub sysop_list_files {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp List Files']);
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE category_id=?');
    $sth->execute($self->{'USER'}->{'file_category'});
    my $sizes = {};
    while (my $row = $sth->fetchrow_hashref()) {
        foreach my $name (keys %{$row}) {
            if ($name eq 'file_size') {
                my $size = format_number($row->{$name});
                $sizes->{$name} = max(length($size), $sizes->{$name});
            } else {
                $sizes->{$name} = max(length($row->{$name}), $sizes->{$name});
            }
        } ## end foreach my $name (keys %{$row...})
    } ## end while (my $row = $sth->fetchrow_hashref...)
    $sth->finish();
    my $table;
    if ($wsize > 150) {
        $table = Text::SimpleTable->new(max(5, $sizes->{'title'}), max(8, $sizes->{'filename'}), max(4, $sizes->{'type'}), max(11, $sizes->{'description'}), max(8, $sizes->{'username'}), max(4, $sizes->{'file_size'}), max(8, $sizes->{'uploaded'}), max(9, $sizes->{'thumbs_up'}), max(11, $sizes->{'thumbs_down'}));
        $table->row('TITLE', 'FILENAME', 'TYPE', 'DESCRIPTION', 'UPLOADER', 'SIZE', 'UPLOADED', 'THUMBS UP', 'THUMBS DOWN');
    } else {
        $table = Text::SimpleTable->new(max(5, $sizes->{'filename'}), max(8, $sizes->{'title'}), max(4, $sizes->{'extension'}), max(11, $sizes->{'description'}), max(8, $sizes->{'username'}), max(4, $sizes->{'file_size'}), max(9, $sizes->{'thumbs_up'}), max(11, $sizes->{'thumbs_down'}));
        $table->row('TITLE', 'FILENAME', 'TYPE', 'DESCRIPTION', 'UPLOADER', 'SIZE', 'THUMBS UP', 'THUMBS DOWN');
    }
    $table->hr();
    $sth = $self->{'dbh'}->prepare('SELECT * FROM files_view WHERE category_id=?');
    $sth->execute($self->{'USER'}->{'file_category'});
    my $category;

    while (my $row = $sth->fetchrow_hashref()) {
        if ($wsize > 150) {
            $table->row($row->{'title'}, $row->{'filename'}, $row->{'type'}, $row->{'description'}, $row->{'username'}, format_number($row->{'file_size'}), $row->{'uploaded'}, sprintf('%-06u', $row->{'thumbs_up'}), sprintf('%-06u', $row->{'thumbs_down'}));
        } else {
            $table->row($row->{'title'}, $row->{'filename'}, $row->{'extension'}, $row->{'description'}, $row->{'username'}, format_number($row->{'file_size'}), sprintf('%-06u', $row->{'thumbs_up'}), sprintf('%-06u', $row->{'thumbs_down'}));
        }
        $category = $row->{'category'};
    } ## end while (my $row = $sth->fetchrow_hashref...)
    $sth->finish();
    $self->sysop_output("\n" . '[% B_ORANGE %][% BLACK %] Current Category [% RESET %] [% BRIGHT YELLOW %][% BLACK RIGHT-POINTING TRIANGLE %][% RESET %] [% BRIGHT WHITE %][% FILE CATEGORY %][% RESET %]');
    my $tbl = $table->twin('YELLOW')->draw();
    while ($tbl =~ / (TITLE|FILENAME|TYPE|DESCRIPTION|UPLOADER|SIZE|UPLOADED|THUMBS UP|THUMBS DOWN) /) {
        my $ch  = $1;
        my $new = '[% BRIGHT GREEN %]' . $ch . '[% RESET %]';
        $tbl =~ s/ $ch / $new /gs;
    }
    $self->sysop_output("\n$tbl\nPress a Key To Continue ...");
    $self->sysop_keypress();
    print " BACK\n";
    $self->{'debug'}->DEBUG(['End SysOp List Files']);
    return (TRUE);
} ## end sub sysop_list_files

sub sysop_color_border {
    my ($self, $tbl, $color, $type) = @_;

    $self->{'debug'}->DEBUG(['Start SysOp Color Border']);
    $color = '[% ' . $color . ' %]';
    my $new;
    if ($tbl =~ /(─)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/─/\[\% BOX DRAWINGS DOUBLE HORIZONTAL \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/─/\[\% BOX DRAWINGS HEAVY HORIZONTAL \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(─)/)
    if ($tbl =~ /(│)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/│/\[\% BOX DRAWINGS DOUBLE VERTICAL \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/│/\[\% BOX DRAWINGS HEAVY VERTICAL \%\]/gs;
        }
        $new = '[% RESET %]' . $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(│)/)
    if ($tbl =~ /(┌)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'ROUNDED') {
            $new =~ s/┌/\[\% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT \%\]/gs;
        } elsif ($type eq 'DOUBLE') {
            $new =~ s/┌/\[\% BOX DRAWINGS DOUBLE DOWN AND RIGHT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┌/\[\% BOX DRAWINGS HEAVY DOWN AND RIGHT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┌)/)
    if ($tbl =~ /(└)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'ROUNDED') {
            $new =~ s/└/\[\% BOX DRAWINGS LIGHT ARC UP AND RIGHT \%\]/gs;
        } elsif ($type eq 'DOUBLE') {
            $new =~ s/└/\[\% BOX DRAWINGS DOUBLE UP AND RIGHT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/└/\[\% BOX DRAWINGS HEAVY UP AND RIGHT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(└)/)
    if ($tbl =~ /(┬)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/┬/\[\% BOX DRAWINGS DOUBLE DOWN AND HORIZONTAL \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┬/\[\% BOX DRAWINGS HEAVY DOWN AND HORIZONTAL \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┬)/)
    if ($tbl =~ /(┐)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'ROUNDED') {
            $new =~ s/┐/\[\% BOX DRAWINGS LIGHT ARC DOWN AND LEFT \%\]/gs;
        } elsif ($type eq 'DOUBLE') {
            $new =~ s/┐/\[\% BOX DRAWINGS DOUBLE DOWN AND LEFT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┐/\[\% BOX DRAWINGS HEAVY DOWN AND LEFT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┐)/)
    if ($tbl =~ /(├)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/├/\[\% BOX DRAWINGS DOUBLE VERTICAL AND RIGHT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/├/\[\% BOX DRAWINGS HEAVY VERTICAL AND RIGHT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(├)/)
    if ($tbl =~ /(┘)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'ROUNDED') {
            $new =~ s/┘/\[\% BOX DRAWINGS LIGHT ARC UP AND LEFT \%\]/gs;
        } elsif ($type eq 'DOUBLE') {
            $new =~ s/┘/\[\% BOX DRAWINGS DOUBLE UP AND LEFT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┘/\[\% BOX DRAWINGS HEAVY UP AND LEFT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┘)/)
    if ($tbl =~ /(┼)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/┼/\[\% BOX DRAWINGS DOUBLE VERTICAL AND HORIZONTAL \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┼/\[\% BOX DRAWINGS HEAVY VERTICAL AND HORIZONTAL \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┼)/)
    if ($tbl =~ /(┤)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/┤/\[\% BOX DRAWINGS DOUBLE VERTICAL AND LEFT \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┤/\[\% BOX DRAWINGS HEAVY VERTICAL AND LEFT \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┤)/)
    if ($tbl =~ /(┴)/) {
        my $ch = $1;
        $new = $ch;
        if ($type eq 'DOUBLE') {
            $new =~ s/┴/\[\% BOX DRAWINGS DOUBLE UP AND HORIZONTAL \%\]/gs;
        } elsif ($type eq 'HEAVY') {
            $new =~ s/┴/\[\% BOX DRAWINGS HEAVY UP AND HORIZONTAL \%\]/gs;
        }
        $new = $color . $new . '[% RESET %]';
        $tbl =~ s/$ch/$new/gs;
    } ## end if ($tbl =~ /(┴)/)
    $self->{'debug'}->DEBUG(['End SysOp Color Border']);
    return ($tbl);
} ## end sub sysop_color_border

sub sysop_select_file_category {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Select File Category']);
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM file_categories');
    $sth->execute();
    my $table = Text::SimpleTable->new(3, 30, 50);
    $table->row('ID', 'TITLE', 'DESCRIPTION');
    $table->hr();
    my $max_id = 1;
    while (my $row = $sth->fetchrow_hashref()) {
        $table->row($row->{'id'}, $row->{'title'}, $row->{'description'});
        $max_id = $row->{'id'};
    }
    $sth->finish();
    my $text = $table->twin('MAGENTA')->draw();
    while ($text =~ / (ID|TITLE|DESCRIPTION) /) {
        my $ch  = $1;
        my $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
        $text =~ s/ $ch / $new /gs;
    }
    $self->sysop_output($text . "\n");
    $self->sysop_prompt('Choose ID (< = Nevermind)');
    my $line;
    do {
        $line = uc($self->sysop_get_line(ECHO, 3, ''));
    } until ($line =~ /^(\d+|\<)/i);
    my $response = FALSE;
    if ($line >= 1 && $line <= $max_id) {
        $sth = $self->{'dbh'}->prepare('UPDATE users SET file_category=? WHERE id=1');
        $sth->execute($line);
        $sth->finish();
        $self->{'USER'}->{'file_category'} = $line + 0;
        $response = TRUE;
    } ## end if ($line >= 1 && $line...)
    $self->{'debug'}->DEBUG(['End SysOp Select File Category']);
    return ($response);
} ## end sub sysop_select_file_category

sub sysop_edit_file_categories {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Edit File Categories']);
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM file_categories');
    $sth->execute();
    my $table = Text::SimpleTable->new(3, 30, 50);
    $table->row('ID', 'TITLE', 'DESCRIPTION');
    $table->hr();
    while (my $row = $sth->fetchrow_hashref()) {
        $table->row($row->{'id'}, $row->{'title'}, $row->{'description'});
    }
    $sth->finish();
    my $text = $table->boxes->draw();
    while ($text =~ / (ID|TITLE|DESCRIPTION) /) {
        my $ch  = $1;
        my $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
        $text =~ s/ $ch / $new /gs;
    }
    $self->sysop_output("$text\n");
    $self->sysop_prompt('Choose ID (A = Add, < = Nevermind)');
    my $line;
    do {
        $line = uc($self->sysop_get_line(ECHO, 3, ''));
    } until ($line =~ /^(\d+|A|\<)/i);
    if ($line eq 'A') {    # Add
        $self->{'debug'}->DEBUG(['  SysOp Edit File Categories Add']);
        print "\nADD NEW FILE CATEGORY\n";
        $table = Text::SimpleTable->new(11, 80);
        $table->row('TITLE',       "\n" . charnames::string_vianame('OVERLINE') x 80);
        $table->row('DESCRIPTION', "\n" . charnames::string_vianame('OVERLINE') x 80);
        my $text = $table->twin('MAGENTA')->draw();
        while ($text =~ / (TITLE|DESCRIPTION) /) {
            my $ch  = $1;
            my $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
            $text =~ s/ $ch / $new /gs;
        }
        $self->sysop_output("\n$text");
        print $self->{'ansi_meta'}->{'cursor'}->{'UP'}->{'out'} x 5, $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x 16;
        my $title = $self->sysop_get_line(ECHO, 80, '');
        if ($title ne '') {
            print "\r", $self->{'ansi_meta'}->{'cursor'}->{'DOWN'}->{'out'}, $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x 16;
            my $description = $self->sysop_get_line(ECHO, 80, '');
            if ($description ne '') {
                $sth = $self->{'dbh'}->prepare('INSERT INTO file_categories (title,description) VALUES (?,?)');
                $sth->execute($title, $description);
                $sth->finish();
                print "\n\nNew Entry Added\n";
            } else {
                print "\n\nNevermind\n";
            }
        } else {
            print "\n\n\nNevermind\n";
        }
    } elsif ($line =~ /\d+/) {    # Edit
        $self->{'debug'}->DEBUG(['  SysOp Edit File Categories Edit']);
    }
    $self->{'debug'}->DEBUG(['Start SysOp Edit File Categories']);
    return (TRUE);
} ## end sub sysop_edit_file_categories

sub sysop_vertical_heading {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Vertical Heading']);
    my $heading = '';
    for (my $count = 0; $count < length($text); $count++) {
        $heading .= substr($text, $count, 1) . "\n";
    }
    $self->{'debug'}->DEBUG(['End SysOp Vertical Heading']);
    return ($heading);
} ## end sub sysop_vertical_heading

sub sysop_view_configuration {
    my $self = shift;
    my $view = shift;

    $self->{'debug'}->DEBUG(['Start SysOp View Configuration']);

    # Get maximum widths
    my $name_width  = 6;
    my $value_width = 80;
    foreach my $cnf (keys %{ $self->configuration() }) {
        if ($cnf eq 'STATIC') {
            foreach my $static (keys %{ $self->{'CONF'}->{$cnf} }) {
                $name_width  = max(length($static),                            $name_width);
                $value_width = max(length($self->{'CONF'}->{$cnf}->{$static}), $value_width);
            }
        } else {
            $name_width  = max(length($cnf),                    $name_width);
            $value_width = max(length($self->{'CONF'}->{$cnf}), $value_width);
        }
    } ## end foreach my $cnf (keys %{ $self...})

    # Assemble table
    my $table = ($view) ? Text::SimpleTable->new($name_width, $value_width) : Text::SimpleTable->new(6, $name_width, $value_width);
    if ($view) {
        $table->row('STATIC NAME', 'STATIC VALUE');
        $table->hr();
    }
    foreach my $conf (sort(keys %{ $self->{'CONF'}->{'STATIC'} })) {
        next if ($conf eq 'DATABASE PASSWORD');
        if ($view) {
            $table->row($conf, $self->{'CONF'}->{'STATIC'}->{$conf});
        }
    } ## end foreach my $conf (sort(keys...))
    if ($view) {
        $table->hr();
        $table->row('CONFIG NAME', 'CONFIG VALUE');
    } else {
        $table->row('CHOICE', 'CONFIG NAME', 'CONFIG VALUE');
    }
    $table->hr();
    my $count = 0;
    foreach my $conf (sort(keys %{ $self->{'CONF'} })) {
        my $choice = chr(65 + $count);
        next if ($conf eq 'STATIC');
        my $c = $self->{'CONF'}->{$conf};
        if ($conf eq 'DEFAULT TIMEOUT') {
            $c .= ' Minutes';
        } elsif ($conf eq 'DEFAULT BAUD RATE') {
            $c .= ' bps - 300, 600, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, FULL';
        } elsif ($conf eq 'THREAD MULTIPLIER') {
            $c .= ' x CPU Cores';
        } elsif ($conf eq 'DEFAULT TEXT MODE') {
            $c .= ' - ANSI, ASCII, ATASCII, PETSCII';
        }
        if ($view) {
            $table->row($conf, $c);
        } else {
            if ($conf =~ /AUTHOR/) {
                $table->row(' ', $conf, $c);
            } else {
                $table->row($choice, $conf, $c);
                $count++;
            }
        } ## end else [ if ($view) ]
    } ## end foreach my $conf (sort(keys...))
    my $output = $table->thick('RED')->draw();
    foreach my $change ('AUTHOR EMAIL', 'AUTHOR LOCATION', 'AUTHOR NAME', 'DATABASE USERNAME', 'DATABASE NAME', 'DATABASE PORT', 'DATABASE TYPE', 'DATBASE USERNAME', 'DATABASE HOSTNAME', '300, 600, 1200, 2400, 4800, 9600, 19200, FULL', '%d = day, %m = Month, %Y = Year', 'ANSI, ASCII, ATASCII, PETSCII', 'ANSI, ASCII, ATAASCII,PETSCII') {
        if ($output =~ /$change/) {
            my $ch;
            if (/^(AUTHOR|DATABASE)/) {
                $ch = '[% YELLOW %]' . $change . '[% RESET %]';
            } else {
                $ch = '[% GRAY 11 %]' . $change . '[% RESET %]';
            }
            $output =~ s/$change/$ch/gs;
        } ## end if ($output =~ /$change/)
    } ## end foreach my $change ('AUTHOR EMAIL'...)
    {
        my $ch = colored(['cyan'], 'CHOICE');
        $output =~ s/CHOICE/$ch/gs;
        $ch = colored(['bright_yellow'], 'STATIC NAME');
        $output =~ s/STATIC NAME/$ch/gs;
        $ch = colored(['bright_yellow'], 'STATIC VALUE');
        $output =~ s/STATIC VALUE/$ch/gs;
        $ch = colored(['green'], 'CONFIG NAME');
        $output =~ s/CONFIG NAME/$ch/gs;
        $ch = colored(['cyan'], 'CONFIG VALUE');
        $output =~ s/CONFIG VALUE/$ch/gs;
        $ch = colored(['green'], 'TRUE');
        $output =~ s/TRUE/$ch/gs;
        $ch = colored(['red'], 'FALSE');
        $output =~ s/FALSE/$ch/gs;
        $ch = colored(['green'], 'ON');
        $output =~ s/ ON / $ch /gs;
        $ch = colored(['red'], 'OFF');
        $output =~ s/ OFF / $ch /gs;
        $ch = colored(['green'], 'YES');
        $output =~ s/YES/$ch/gs;
        $ch = colored(['red'], 'NO');
        $output =~ s/ NO / $ch /gs;
    }
    my $response;
    if ("$view" eq 'string') {
        $response = $output;
    } elsif ($view == TRUE) {
        print $self->sysop_detokenize($output);
        print 'Press a key to continue ... ';
        $response = $self->sysop_keypress();
    } elsif ($view == FALSE) {
        print $self->sysop_detokenize($output);
        print $self->sysop_menu_choice('TOP',    '',    '');
        print $self->sysop_menu_choice('Z',      'RED', 'Return to Settings Menu');
        print $self->sysop_menu_choice('BOTTOM', '',    '');
        $self->sysop_prompt('Choose');
        $response = TRUE;
    } ## end elsif ($view == FALSE)
    $self->{'debug'}->DEBUG(['End SysOp View Configuration']);
    return ($response);
} ## end sub sysop_view_configuration

sub sysop_edit_configuration {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Edit Configuration']);
    $self->sysop_view_configuration(FALSE);
    my $types = {
        'BBS NAME'            => { 'max' => 50, 'type' => STRING, },
        'BBS ROOT'            => { 'max' => 60, 'type' => STRING, },
        'HOST'                => { 'max' => 20, 'type' => HOST, },
        'THREAD MULTIPLIER'   => { 'max' => 2,  'type' => NUMERIC, },
        'PORT'                => { 'max' => 5,  'type' => NUMERIC, },
        'DEFAULT BAUD RATE'   => { 'max' => 5,  'type' => RADIO, 'choices' => ['300', '600', '1200', '2400', '4800', '9600', '19200', '38400', '57600', '115200', 'FULL'], },
        'DEFAULT TEXT MODE'   => { 'max' => 7,  'type' => RADIO, 'choices' => ['ANSI', 'ASCII', 'ATASCII', 'PETSCII'], },
        'DEFAULT TIMEOUT'     => { 'max' => 3,  'type' => NUMERIC, },
        'FILES PATH'          => { 'max' => 60, 'type' => STRING, },
        'LOGIN TRIES'         => { 'max' => 1,  'type' => NUMERIC, },
        'MEMCACHED HOST'      => { 'max' => 20, 'type' => HOST, },
        'MEMCACHED NAMESPACE' => { 'max' => 32, 'type' => STRING, },
        'MEMCACHED PORT'      => { 'max' => 5,  'type' => NUMERIC, },
        'DATE FORMAT'         => { 'max' => 14, 'type' => RADIO,   'choices' => ['MONTH/DAY/YEAR', 'DAY/MONTH/YEAR', 'YEAR/MONTH/DAY',], },
        'SYSOP ANIMATED MENU' => { 'max' => 5,  'type' => BOOLEAN, 'choices' => ['ON', 'OFF'], },
        'USE DUF'             => { 'max' => 5,  'type' => BOOLEAN, 'choices' => ['ON', 'OFF'], },
        'PLAY SYSOP SOUNDS'   => { 'max' => 5,  'type' => BOOLEAN, 'choices' => ['ON', 'OFF'], },
    };
    my $choice;
    do {
        $choice = uc($self->sysop_keypress());
    } until ($choice =~ /[A-R]|Z/i);
    if ($choice =~ /Z/i) {
        print "BACK\n";
        return (FALSE);
    }

    $choice = ("$choice" =~ /[A-Y]/i) ? $choice = (ord($choice) - 65) : $choice;
    my @conf = grep(!/STATIC|AUTHOR/, sort(keys %{ $self->{'CONF'} }));
    if ($types->{ $conf[$choice] }->{'type'} == RADIO || $types->{ $conf[$choice] }->{'type'} == BOOLEAN) {
        print '(Edit) ', $conf[$choice], ' (' . join(' ', @{ $types->{ $conf[$choice] }->{'choices'} }) . ') ', charnames::string_vianame('BLACK RIGHT-POINTING TRIANGLE'), '  ';
    } else {
        print '(Edit) ', $conf[$choice], ' ', charnames::string_vianame('BLACK RIGHT-POINTING TRIANGLE'), '  ';
    }
    my $string;
    $self->{'debug'}->DEBUGMAX([$self->configuration()]);
    $string = $self->sysop_get_line($types->{ $conf[$choice] }, $self->configuration($conf[$choice]));
    my $response = TRUE;
    if ($string eq '') {
        $response = FALSE;
    } else {
        $self->configuration($conf[$choice], $string);
    }
    $self->{'debug'}->DEBUG(['End SysOp Edit Configuration']);
    return ($response);
} ## end sub sysop_edit_configuration

sub sysop_get_key {
    my $self     = shift;
    my $echo     = shift;
    my $blocking = shift;

    my $key     = undef;
    my $mode    = $self->{'USER'}->{'text_mode'};
    my $timeout = $self->{'USER'}->{'timeout'} * 60;
    local $/ = "\x{00}";
    ReadMode 'ultra-raw';
    $key = ($blocking) ? ReadKey($timeout) : ReadKey(-1);
    ReadMode 'restore';
    threads->yield;
    return ($key) if ($key eq chr(13));

    if ($key eq chr(127)) {
        $key = $self->{'ansi_meta'}->{'cursor'}->{'BACKSPACE'}->{'out'};
    }
    if ($echo == NUMERIC && defined($key)) {
        unless ($key =~ /[0-9]/) {
            $key = '';
        }
    }
    threads->yield;
    return ($key);
} ## end sub sysop_get_key

sub sysop_get_line {
    my $self = shift;
    my $echo = shift;
    my $type = $echo;

    my $line;
    my $limit;
    my $choices;
    my $key;

    $self->{'CACHE'}->set('SHOW_STATUS', FALSE);
    $self->{'debug'}->DEBUG(['Start SysOp Get Line']);
    $self->flush_input();

    if (ref($type) eq 'HASH') {
        $limit = $type->{'max'};
        if (exists($type->{'choices'})) {
            $choices = $type->{'choices'};
            if (exists($type->{'default'})) {
                $line = $type->{'default'};
            } else {
                $line = shift;
            }
        } ## end if (exists($type->{'choices'...}))
        $echo = $type->{'type'};
    } else {
        if ($echo == STRING || $echo == ECHO || $echo == NUMERIC || $echo == HOST) {
            $limit = shift;
        }
        $line = shift;
    } ## end else [ if (ref($type) eq 'HASH')]
    chomp($line);
    $self->{'debug'}->DEBUGMAX([$type, $echo, $line]);
    print $line if ($line ne '');
    my $mode = 'ANSI';
    my $bs   = $self->{'ansi_meta'}->{'cursor'}->{'BACKSPACE'}->{'out'};
    if ($echo == RADIO) {
        $self->{'debug'}->DEBUG(['  SysOp Get Line RADIO']);

        my $mapping;
        my @menu_choices = @{$self->{'MENU CHOICES'}};

        foreach my $choice (@{$choices}) {
            $mapping->{ shift(@menu_choices) } = {
                'command'      => $choice,
                'color'        => 'WHITE',
                'access_level' => 'USER',
                'text'         => $choice,
            }
        }
        print "\n";
        $self->sysop_show_choices($mapping);
        $self->sysop_prompt('Choose');
        my $key;
        do {
            $key = uc($self->sysop_get_key(SILENT, BLOCKING));
        } until (exists($mapping->{$key}) || $key eq chr(3));
        if ($key eq chr(3)) {
            $line = '';
        } else {
            $line = $mapping->{$key}->{'command'};
        }
    } elsif ($echo == BOOLEAN) {
        $self->{'debug'}->DEBUG(['  SysOp Get Line BOOLEAN']);
        do {
            $key = $self->sysop_get_key(SILENT, BLOCKING);
            if (uc($key) eq 'T') {
                $line = 'ON';
                print $self->{'ansi_meta'}->{'cursor'}->{'LEFT'}->{'out'} x 5, 'ON', clline;
            } elsif (uc($key) eq 'F') {
                $line = 'OFF';
                print $self->{'ansi_meta'}->{'cursor'}->{'LEFT'}->{'out'} x 4, 'OFF', clline;
            } elsif ($key ne chr(13) && $key ne chr(3)) {
                print chr(7);
            }
        } until ($key eq chr(13) or $key eq chr(3));
    } elsif ($echo == NUMERIC) {
        $self->{'debug'}->DEBUG(['  SysOp Get Line NUMERIC']);
        while ($key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->sysop_get_key(NUMERIC, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $bs || $key eq chr(127)) {
                        my $len = length($line);
                        if ($len > 0) {
                            print "$key $key";
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && $key =~ /[0-9]/) {
                        print $key;
                        $line .= $key;
                    } else {
                        print chr(7);
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->sysop_get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $bs || $key eq chr(127))) {
                    $key = $bs;
                    print "$key $key";
                    chop($line);
                } else {
                    print chr(7);
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while ($key ne chr(13) &&...)
    } elsif ($echo == HOST) {
        $self->{'debug'}->DEBUG(['  SysOp Get Line HOST']);
        while ($key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->sysop_get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $bs || $key eq chr(127)) {
                        my $len = length($line);
                        if ($len > 0) {
                            $self->sysop_output("$key $key");
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && $key =~ /[a-z]|[0-9]|\./) {
                        print lc($key);
                        $line .= lc($key);
                    } else {
                        print chr(7);
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->sysop_get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $bs || $key eq chr(127))) {
                    $key = $bs;
                    print "$key $key";
                    chop($line);
                } else {
                    print chr(7);
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while ($key ne chr(13) &&...)
    } else {
        $self->{'debug'}->DEBUG(['  SysOp Get Line NORMAL']);
        while ($key ne chr(13) && $key ne chr(3)) {
            if (length($line) <= $limit) {
                $key = $self->sysop_get_key(SILENT, BLOCKING);
                return ('') if (defined($key) && $key eq chr(3));
                if (defined($key) && $key ne '') {
                    if ($key eq $bs) {
                        my $len = length($line);
                        if ($len > 0) {
                            print "$key $key";
                            chop($line);
                        }
                    } elsif ($key ne chr(13) && $key ne chr(3) && $key ne chr(10) && ord($key) > 31 && ord($key) < 127) {
                        print $key;
                        $line .= $key;
                    } else {
                        print chr(7);
                    }
                } ## end if (defined($key) && $key...)
            } else {
                $key = $self->sysop_get_key(SILENT, BLOCKING);
                if (defined($key) && $key eq chr(3)) {
                    return ('');
                }
                if (defined($key) && ($key eq $bs)) {
                    $key = $bs;
                    print "$key $key";
                    chop($line);
                } else {
                    print chr(7);
                }
            } ## end else [ if (length($line) <= $limit)]
        } ## end while ($key ne chr(13) &&...)
    } ## end else [ if ($echo == RADIO) ]
    threads->yield();
    $line = '' if ($key eq chr(3));
    print "\n";
    $self->{'CACHE'}->set('SHOW_STATUS', TRUE);
    $self->{'debug'}->DEBUG(['End SysOp Get Line']);
    return ($line);
} ## end sub sysop_get_line

sub sysop_user_delete {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start SysOp User Delete']);
    my $mapping = $self->sysop_load_menu($row, $file);
    print locate($row, 1), cldown, $mapping->{'TEXT'};
    delete($mapping->{'TEXT'});
    my ($key_exit) = (keys %{$mapping});
    my $key;
    $self->sysop_prompt('Please enter the username or account number');
    my $search = $self->sysop_get_line(ECHO, 20, '');
    return (FALSE) if ($search eq '' || $search eq 'sysop' || $search eq '1');
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM users_view WHERE id=? OR username=?');
    $sth->execute($search, $search);
    my $user_row = $sth->fetchrow_hashref();
    $sth->finish();

    if (defined($user_row)) {
        my $table = Text::SimpleTable->new(16, 60);
        $table->row('FIELD', 'VALUE');
        $table->hr();
        foreach my $field (@{ $self->{'SYSOP ORDER DETAILED'} }) {
            if ($field ne 'id' && $user_row->{$field} =~ /^(0|1)$/) {
                $user_row->{$field} = $self->sysop_true_false($user_row->{$field}, 'YN');
            } elsif ($field eq 'timeout') {
                $user_row->{$field} = $user_row->{$field} . ' Minutes';
            }
            $table->row($field, $user_row->{$field} . '');
        } ## end foreach my $field (@{ $self...})
        if ($self->sysop_pager($table->thick('RED')->draw())) {
            print "Are you sure that you want to delete this user (Y|N)?  ";
            my $answer = $self->sysop_decision();
            if ($answer) {
                print "\n\nDeleting ", $user_row->{'username'}, " ... ";
                $sth = $self->users_delete($user_row->{'id'});
            }
        } ## end if ($self->sysop_pager...)
    } ## end if (defined($user_row))
    $self->{'debug'}->DEBUG(['End SysOp User Delete']);
} ## end sub sysop_user_delete

sub sysop_user_edit {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start SysOp User Edit']);
    my $mapping = $self->sysop_load_menu($row, $file);
    print locate($row, 1), cldown, $mapping->{'TEXT'};
    delete($mapping->{'TEXT'});
    my ($key_exit) = (keys %{$mapping});
    my @choices = qw( 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y );
    my $key;
    $self->sysop_prompt('Please enter the username or account number');
    my $search = $self->sysop_get_line(ECHO, 20, '');
    return (FALSE) if ($search eq '');
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM users_view WHERE id=? OR username=?');
    $sth->execute($search, $search);
    my $user_row = $sth->fetchrow_hashref();
    $sth->finish();

    if (defined($user_row)) {
        my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
        do {
            my $valsize = 1;
            foreach my $fld (keys %{$user_row}) {
                $valsize = max($valsize, length($user_row->{$fld}));
            }
            $valsize = min($valsize, $wsize - 29);
            my $table = Text::SimpleTable->new(6, 16, $valsize);
            $table->row('CHOICE', 'FIELD', 'VALUE');
            $table->hr();
            my $count = 0;
            my %choice;
            foreach my $field (@{ $self->{'SYSOP ORDER DETAILED'} }) {
                if ($field =~ /_time|fullname|_category|id/) {
                    $table->row(' ', uc($field), $user_row->{$field} . '');
                } else {
                    if ($user_row->{$field} =~ /^(0|1)$/) {
                        $table->row($choices[$count], uc($field), $self->sysop_true_false($user_row->{$field}, 'YN'));
                    } elsif ($field eq 'access_level') {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . ' - USER, VETERAN, JUNIOR SYSOP, SYSOP');
                    } elsif ($field eq 'date_format') {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . ' - YEAR/MONTH/DAY, MONTH/DAY/YEAR, DAY/MONTH/YEAR');
                    } elsif ($field eq 'baud_rate') {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . ' - 300, 600, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, FULL');
                    } elsif ($field eq 'text_mode') {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . ' - ASCII, ANSI, ATASCII, PETSCII');
                    } elsif ($field eq 'timeout') {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . ' - Minutes');
                    } else {
                        $table->row($choices[$count], uc($field), $user_row->{$field} . '');
                    }
                    $count++ if ($key_exit eq $choices[$count]);
                    $choice{ $choices[$count] } = $field;
                    $count++;
                } ## end else [ if ($field =~ /_time|fullname|_category|id/)]
            } ## end foreach my $field (@{ $self...})
            my $tbl = $table->round('BRIGHT CYAN')->draw();
            while ($tbl =~ / (CHOICE|FIELD|VALUE|No|Yes|USER. VETERAN. JUNIOR SYSOP. SYSOP|YEAR.MONTH.DAY, MONTH.DAY.YEAR, DAY.MONTH.YEAR|300. 600. 1200. 2400. 4800. 9600. 19200. FULL|ASCII. ANSI. ATASCII. PETSCII|Minutes) /) {
                my $ch = $1;
                my $new;
                if ($ch =~ /Yes/) {
                    $new = '[% GREEN %]' . $ch . '[% RESET %]';
                } elsif ($ch =~ /No/) {
                    $new = '[% RED %]' . $ch . '[% RESET %]';
                } elsif ($ch =~ /CHOICE|FIELD|VALUE/) {
                    $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
                } else {
                    $new = '[% RGB 50,50,150 %]' . $ch . '[% RESET %]';
                }
                $tbl =~ s/$ch/$new/g;
            } ## end while ($tbl =~ / (CHOICE|FIELD|VALUE|No|Yes|USER. VETERAN. JUNIOR SYSOP. SYSOP|YEAR.MONTH.DAY, MONTH.DAY.YEAR, DAY.MONTH.YEAR|300. 600. 1200. 2400. 4800. 9600. 19200. FULL|ASCII. ANSI. ATASCII. PETSCII|Minutes) /)
            $self->sysop_output('[% CLS %]' . $tbl . "\n");
            $self->sysop_show_choices($mapping);
            $self->sysop_prompt('Choose');
            do {
                $key = uc($self->sysop_keypress());
            } until ('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ' =~ /$key/i);
            if ($key !~ /$key_exit/i) {
                print 'Edit > (', $choice{$key}, ' = ', $user_row->{ $choice{$key} }, ') > ';
                if ($choice{$key} =~ /^(play_fortunes|prefer_nickname|view_files|upload_files|download_files|remove_files|read_message|post_message|remove_message|sysop)$/) {
                    $user_row->{ $choice{$key} } = ($user_row->{ $choice{$key} } == 1) ? 0 : 1;
                    my $sth = $self->{'dbh'}->prepare('UPDATE permissions SET ' . $choice{$key} . '= !' . $choice{$key} . '  WHERE id=?');
                    $sth->execute($user_row->{'id'});
                    $sth->finish();
                } elsif($choice{$key} =~ /text_mode/) {
                    my $new = $self->sysop_get_line($self->{'SYSOP FIELD TYPES'}->{ $choice{$key} }, $user_row->{ $choice{$key} });
                    $user_row->{ $choice{$key} } = $new;
                    my $sth = $self->{'dbh'}->prepare('UPDATE users SET ' . $choice{$key} . '=? WHERE id=?');
                    $sth->execute($new, $self->{'text_modes'}->{$user_row->{'id'}});
                    $sth->finish();
                } else {
                    my $new = $self->sysop_get_line($self->{'SYSOP FIELD TYPES'}->{ $choice{$key} }, $user_row->{ $choice{$key} });
                    $user_row->{ $choice{$key} } = $new;
                    my $sth = $self->{'dbh'}->prepare('UPDATE users SET ' . $choice{$key} . '=? WHERE id=?');
                    $sth->execute($new, $user_row->{'id'});
                    $sth->finish();
                } ## end else [ if ($choice{$key} =~ /^(prefer_nickname|view_files|upload_files|download_files|remove_files|read_message|post_message|remove_message|sysop)$/)]
            } else {
                print "BACK\n";
            }
        } until ($key =~ /$key_exit/i);
    } elsif ($search ne '') {
        print "User not found!\n\n";
    }
    $self->{'debug'}->DEBUG(['End SysOp User Edit']);
    return (TRUE);
} ## end sub sysop_user_edit

sub sysop_new_user_edit {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start SysOp User Edit']);
    my $mapping = $self->sysop_load_menu($row, $file);
    print locate($row, 1), cldown, $mapping->{'TEXT'};
    delete($mapping->{'TEXT'});
    my ($key_exit) = (keys %{$mapping});
    my @choices = qw( 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y );
    my $key;
    my @responses;
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM users_view WHERE access_level=?');
    $sth->execute('USER');
    my $user_row;

    while ($user_row = $sth->fetchrow_hashref()) {
        push(@responses, $user_row);
    }
    $sth->finish();

    $self->{'debug'}->DEBUGMAX(\@responses);
    my ($wsize, $hsize, $wpixels, $hpixels) = GetTerminalSize();
    while ($user_row = pop(@responses)) {
        do {
            my $valsize = 1;
            foreach my $fld (keys %{$user_row}) {
                $valsize = max($valsize, length($user_row->{$fld}));
            }
            $valsize = min($valsize, $wsize - 29);
            my $table = Text::SimpleTable->new(6, 16, $valsize);
            $table->row('CHOICE', 'FIELD', 'VALUE');
            $table->hr();
            my $count = 0;
            my %choice;
            foreach my $field (@{ $self->{'SYSOP ORDER DETAILED'} }) {
                if ($field =~ /_time|fullname|_category|id/) {
                    $table->row(' ', $field, $user_row->{$field} . '');
                } else {
                    if ($user_row->{$field} =~ /^(0|1)$/) {
                        $table->row($choices[$count], $field, $self->sysop_true_false($user_row->{$field}, 'YN'));
                    } elsif ($field eq 'access_level') {
                        $table->row($choices[$count], $field, $user_row->{$field} . ' - USER, VETERAN, JUNIOR SYSOP, SYSOP');
                    } elsif ($field eq 'date_format') {
                        $table->row($choices[$count], $field, $user_row->{$field} . ' - YEAR/MONTH/DAY, MONTH/DAY/YEAR, DAY/MONTH/YEAR');
                    } elsif ($field eq 'baud_rate') {
                        $table->row($choices[$count], $field, $user_row->{$field} . ' - 300, 600, 1200, 2400, 4800, 9600, 19200, FULL');
                    } elsif ($field eq 'text_mode') {
                        $table->row($choices[$count], $field, $user_row->{$field} . ' - ASCII, ANSI, ATASCII, PETSCII');
                    } elsif ($field eq 'timeout') {
                        $table->row($choices[$count], $field, $user_row->{$field} . ' - Minutes');
                    } else {
                        $table->row($choices[$count], $field, $user_row->{$field} . '');
                    }
                    $count++ if ($key_exit eq $choices[$count]);
                    $choice{ $choices[$count] } = $field;
                    $count++;
                } ## end else [ if ($field =~ /_time|fullname|_category|id/)]
            } ## end foreach my $field (@{ $self...})
            my $tbl = $table->round('BRIGHT CYAN')->draw();
            while ($tbl =~ / (CHOICE|FIELD|VALUE|No|Yes|USER. VETERAN. JUNIOR SYSOP. SYSOP|YEAR.MONTH.DAY, MONTH.DAY.YEAR, DAY.MONTH.YEAR|300. 600. 1200. 2400. 4800. 9600. 19200. FULL|ASCII. ANSI. ATASCII. PETSCII|Minutes) /) {
                my $ch = $1;
                my $new;
                if ($ch =~ /Yes/) {
                    $new = '[% GREEN %]' . $ch . '[% RESET %]';
                } elsif ($ch =~ /No/) {
                    $new = '[% RED %]' . $ch . '[% RESET %]';
                } elsif ($ch =~ /CHOICE|FIELD|VALUE/) {
                    $new = '[% BRIGHT YELLOW %]' . $ch . '[% RESET %]';
                } else {
                    $new = '[% RGB 50,50,150 %]' . $ch . '[% RESET %]';
                }
                $tbl =~ s/$ch/$new/g;
            } ## end while ($tbl =~ / (CHOICE|FIELD|VALUE|No|Yes|USER. VETERAN. JUNIOR SYSOP. SYSOP|YEAR.MONTH.DAY, MONTH.DAY.YEAR, DAY.MONTH.YEAR|300. 600. 1200. 2400. 4800. 9600. 19200. FULL|ASCII. ANSI. ATASCII. PETSCII|Minutes) /)
            $self->sysop_output('[% CLS %]' . $tbl . "\n");
            $self->sysop_show_choices($mapping);
            $self->sysop_prompt('Choose');
            do {
                $key = uc($self->sysop_keypress());
            } until ('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ' =~ /$key/i);
            if ($key !~ /$key_exit/i) {
                print 'Edit > (', $choice{$key}, ' = ', $user_row->{ $choice{$key} }, ') > ';
                my $new = $self->sysop_get_line(ECHO, 1 + $self->{'SYSOP FIELD TYPES'}->{ $choice{$key} }->{'max'}, $user_row->{ $choice{$key} });
                unless ($new eq '') {
                    $new =~ s/^(Yes|On)$/1/i;
                    $new =~ s/^(No|Off)$/0/i;
                }
                $user_row->{ $choice{$key} } = $new;
                if ($key =~ /prefer_nickname|view_files|upload_files|download_files|remove_files|read_message|post_message|remove_message|sysop/) {
                    my $sth = $self->{'dbh'}->prepare('UPDATE permissions SET ' . choice { $key } . '=? WHERE id=?');
                    $sth->execute($new, $user_row->{'id'});
                    $sth->finish();
                } else {
                    my $sth = $self->{'dbh'}->prepare('UPDATE users SET ' . $choice{$key} . '=? WHERE id=?');
                    $sth->execute($new, $user_row->{'id'});
                    $sth->finish();
                }
            } else {
                print "BACK\n";
            }
        } until ($key =~ /$key_exit/i);
    } ## end while ($user_row = pop(@responses...))
    $self->{'debug'}->DEBUG(['End SysOp User Edit']);
    return (TRUE);
} ## end sub sysop_new_user_edit

sub sysop_user_add {
    my $self = shift;
    my $row  = shift;
    my $file = shift;

    $self->{'debug'}->DEBUG(['Start SysOp User Add']);
    my $flags_default = $self->{'flags_default'};
    my $mapping       = $self->sysop_load_menu($row, $file);
    print locate($row, 1), cldown, $mapping->{'TEXT'};
    my $table = Text::SimpleTable->new(15, 150);
    my $user_template;
    my @tmp = grep(!/id|banned|fullname|_time|max_|_category/, @{ $self->{'SYSOP ORDER DETAILED'} });
    push(@tmp, 'password');

    foreach my $name (@tmp) {
        my $size = max(3, $self->{'SYSOP FIELD TYPES'}->{$name}->{'max'});
        if ($name eq 'timeout') {
            $table->row($name, '_' x $size . ' - Minutes');
        } elsif ($name eq 'baud_rate') {
            $table->row($name, '_' x $size . ' - 300 or 600 or 1200 or 2400 or 4800 or 9600 or 19200 or FULL');
        } elsif ($name =~ /username|given|family|password/) {
            if ($name eq 'given') {
                $table->row("$name (first)", '_' x $size . ' - Cannot be empty');
            } elsif ($name eq 'family') {
                $table->row("$name (last)", '_' x $size . ' - Cannot be empty');
            } else {
                $table->row($name, '_' x $size . ' - Cannot be empty');
            }
        } elsif ($name eq 'date_format') {
            $table->row($name, '_' x $size . ' - YEAR/MONTH/DAY or MONTH/DAY/YEAR or DAY/MONTH/YEAR');
        } elsif ($name eq 'access_level') {
            $table->row($name, '_' x $size . ' - USER or VETERAN or JUNIOR SYSOP or SYSOP');
        } elsif ($name eq 'text_mode') {
            $table->row($name, '_' x $size . ' - ANSI or ASCII or ATASCII or PETSCII');
        } elsif ($name eq 'birthday') {
            $table->row($name, '_' x $size . ' - YEAR-MM-DD');
        } elsif ($name =~ /(prefer_nickname|_files|_message|sysop|fortunes)/) {
            $table->row($name, '_' x $size . ' - Yes/No or True/False or On/Off or 1/0');
        } elsif ($name =~ /location|retro_systems|accomplishments/) {
            $table->row($name, '_' x ($self->{'SYSOP FIELD TYPES'}->{$name}->{'max'}));
        } else {
            $table->row($name, '_' x $size);
        }
        $user_template->{$name} = undef;
    } ## end foreach my $name (@tmp)
    my $string = $table->boxes->draw();
    while ($string =~ / (Cannot be empty|YEAR.MM.DD|USER or VETERAN or JUNIOR SYSOP or SYSOP|YEAR.MONTH.DAY or MONTH.DAY.YEAR or DAY.MONTH.YEAR|300 or 600 or 1200 or 2400 or 4800 or 9600 or 19200 or FULL|ANSI or ASCII or ATASCII or PETSCII|Minutes|Yes.No or True.False or On.Off or 1.0) /) {
        my $ch  = $1;
        my $new = '[% RGB 50,50,150 %]' . $ch . '[% RESET %]';
        $string =~ s/$ch/$new/gs;
    }
    $self->sysop_output($self->sysop_color_border($string, 'PINK', 'DEFAULT'));
    $self->sysop_show_choices($mapping);
    my $column     = 21;
    my $adjustment = $self->{'CACHE'}->get('START_ROW') - 1;
    foreach my $entry (@tmp) {
        do {
            print locate($row + $adjustment, $column), '_' x max(3, $self->{'SYSOP FIELD TYPES'}->{$entry}->{'max'}), locate($row + $adjustment, $column);
            chomp($user_template->{$entry} = $self->sysop_get_line($self->{'SYSOP FIELD TYPES'}->{$entry}));
            return ('BACK') if ($user_template->{$entry} eq '<' || $user_template->{$entry} eq chr(3));
            if ($entry =~ /text_mode|baud_rate|timeout|given|family/) {
                if ($user_template->{$entry} eq '') {
                    if ($entry eq 'text_mode') {
                        $user_template->{$entry} = 'ASCII';
                    } elsif ($entry eq 'baud_rate') {
                        $user_template->{$entry} = 'FULL';
                    } elsif ($entry eq 'timeout') {
                        $user_template->{$entry} = $self->{'CONF'}->{'DEFAULT TIMEOUT'};
                    } elsif ($entry =~ /prefer|_files|_message|sysop|_fortunes/) {
                        $user_template->{$entry} = $flags_default->{$entry};
                    } else {
                        $user_template->{$entry} = uc($user_template->{$entry});
                    }
                } elsif ($entry =~ /given|family/) {
                    my $ucuser = uc($user_template->{$entry});
                    if ($ucuser eq $user_template->{$entry}) {
                        $user_template->{$entry} = ucfirst(lc($user_template->{$entry}));
                    } else {
                        substr($user_template->{$entry}, 0, 1) = uc(substr($user_template->{$entry}, 0, 1));
                    }
                } ## end elsif ($entry =~ /given|family/)
                print locate($row + $adjustment, $column), $user_template->{$entry};
            } elsif ($entry =~ /prefer_|_files|_message|sysop|_fortunes/) {
                $user_template->{$entry} = uc($user_template->{$entry});
                print locate($row + $adjustment, $column), $user_template->{$entry};
            }
        } until ($self->sysop_validate_fields($entry, $user_template->{$entry}, $row + $adjustment, $column));
        if ($user_template->{$entry} =~ /^(yes|on|true|1)$/i) {
            $user_template->{$entry} = TRUE;
        } elsif ($user_template->{$entry} =~ /^(no|off|false|0)$/i) {
            $user_template->{$entry} = FALSE;
        }
        $adjustment++;
    } ## end foreach my $entry (@tmp)
    $self->{'debug'}->DEBUGMAX([$user_template]);
    if ($self->users_add($user_template)) {
        print "\n\n", colored(['green'], 'SUCCESS'), "\n";
        $self->{'debug'}->DEBUG(['sysop_user_add end']);
        return (TRUE);
    }
    $self->{'debug'}->DEBUG(['End SysOp User Add']);
    return (FALSE);
} ## end sub sysop_user_add

sub sysop_show_choices {
    my $self    = shift;
    my $mapping = shift;

    $self->{'debug'}->DEBUG(['SysOp Show Choices']);
    my @list = grep(!/TEXT/, (sort(keys %{$mapping})));
    my $twin = FALSE;
    $twin = TRUE if (scalar(@list) > 1 && $self->{'USER'}->{'max_columns'} > 40);
    my $max = 0;
    if ($twin) {
        foreach my $name (@list) {
            $max = max(length($mapping->{$name}->{'text'}), $max);
        }
        $max += 3;
        $self->output(sprintf("%s%s%s%-${max}s %s%s%s", '[% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC DOWN AND LEFT %]', ' ' x $max, '[% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC DOWN AND LEFT %]') . "\n");
    } else {
        $self->output('[% BOX DRAWINGS LIGHT ARC DOWN AND RIGHT %][% BOX DRAWINGS LIGHT HORIZONTAL %][% BOX DRAWINGS LIGHT ARC DOWN AND LEFT %]' . "\n");
    }
    while (scalar(@list)) {
        my $kmenu = shift(@list);
        if ($twin) {
            $self->menu_choice($kmenu, $mapping->{$kmenu}->{'color'}, sprintf('%-' . ($max - 1) . 's', $mapping->{$kmenu}->{'text'}));
            if (scalar(@list)) {
                $kmenu = shift(@list);
                $self->menu_choice($kmenu, $mapping->{$kmenu}->{'color'}, $mapping->{$kmenu}->{'text'});
            } else {
                $self->output(sprintf('%s%s%s', '[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC UP AND LEFT %]'));
                $twin = FALSE;
            }
        } else {
            $self->menu_choice($kmenu, $mapping->{$kmenu}->{'color'}, $mapping->{$kmenu}->{'text'});
        }
        $self->output("\n");
    } ## end while (scalar(@list))
    if ($twin) {
        $self->output(sprintf("%s%s%s%-${max}s %s%s%s", '[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC UP AND LEFT %]', ' ' x $max, '[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %]', '[% BOX DRAWINGS LIGHT HORIZONTAL %]', '[% BOX DRAWINGS LIGHT ARC UP AND LEFT %]'));
    } else {
        $self->output('[% BOX DRAWINGS LIGHT ARC UP AND RIGHT %][% BOX DRAWINGS LIGHT HORIZONTAL %][% BOX DRAWINGS LIGHT ARC UP AND LEFT %]');
    }
    $self->{'debug'}->DEBUG(['End Show Choices']);
} ## end sub sysop_show_choices

sub sysop_validate_fields {
    my ($self, $name, $val, $row, $column) = @_;

    $self->{'debug'}->DEBUG(['Start SysOp Validate Fields']);
    my $size     = max(3, $self->{'SYSOP FIELD TYPES'}->{$name}->{'max'});
    my $response = TRUE;
    if ($name =~ /(username|given|family|baud_rate|timeout|_files|_message|sysop|prefer|password)/ && $val eq '') {    # cannot be empty
        print locate($row, ($column + $size)), colored(['red'], ' Cannot Be Empty'), locate($row, $column);
        $response = FALSE;
    } elsif ($name eq 'baud_rate' && $val !~ /^(300|600|1200|2400|4800|9600|FULL)$/i) {
        print locate($row, ($column + $size)), colored(['red'], ' Only 300,600,1200,2400,4800,9600,FULL'), locate($row, $column);
        $response = FALSE;
    } elsif ($name =~ /max_/ && $val =~ /\D/i) {
        print locate($row, ($column + $size)), colored(['red'], ' Only Numeric Values'), locate($row, $column);
        $response = FALSE;
    } elsif ($name eq 'timeout' && $val =~ /\D/) {
        print locate($row, ($column + $size)), colored(['red'], ' Must be numeric'), locate($row, $column);
        $response = FALSE;
    } elsif ($name eq 'text_mode' && $val !~ /^(ASCII|ATASCII|PETSCII|ANSI)$/) {
        print locate($row, ($column + $size)), colored(['red'], ' Only ASCII,ATASCII,PETSCII,ANSI'), locate($row, $column);
        $response = FALSE;
    } elsif ($name =~ /(prefer_nickname|_files|_message|sysop)/ && $val !~ /^(yes|no|true|false|on|off|0|1)$/i) {
        print locate($row, ($column + $size)), colored(['red'], ' Only Yes/No or On/Off or 1/0'), locate($row, $column);
        $response = FALSE;
    } elsif ($name eq 'birthday' && $val ne '' && $val !~ /(\d\d\d\d)-(\d\d)-(\d\d)/) {
        print locate($row, ($column + $size)), colored(['red'], ' YEAR-MM-DD'), locate($row, $column);
        $self->{'debug'}->DEBUG(['sysop_validate_fields end']);
        $response = FALSE;
    }
    $self->{'debug'}->DEBUG(['Start SysOp Validate Fields']);
    return ($response);
} ## end sub sysop_validate_fields

sub sysop_prompt {
    my $self = shift;
    my $text = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Prompt']);
    my $response = "\n" . '[% B_BRIGHT MAGENTA %][% BLACK %] SYSOP TOOL [% RESET %] ' . $text . ' [% PINK %][% BLACK RIGHTWARDS ARROWHEAD %][% RESET %] ';
    print $self->sysop_detokenize($response);
    $self->{'debug'}->DEBUG(['End SysOp Prompt']);
    return (TRUE);
} ## end sub sysop_prompt

sub sysop_detokenize {
    my $self = shift;
    my $text = shift;

    # OPERATION TOKENS
    foreach my $key (keys %{ $self->{'sysop_tokens'} }) {
        my $ch = '';
        if ($key eq 'MIDDLE VERTICAL RULE color' && $text =~ /\[\%\s+MIDDLE VERTICAL RULE (.*?)\s+\%\]/) {
            my $color = $1;
            if (ref($self->{'sysop_tokens'}->{$key}) eq 'CODE') {
                $ch = $self->{'sysop_tokens'}->{$key}->($self, $color);
            }
            $text =~ s/\[\%\s+MIDDLE VERTICAL RULE (.*?)\s+\%\]/$ch/gi;
        } elsif ($text =~ /\[\%\s+$key\s+\%\]/) {
            if (ref($self->{'sysop_tokens'}->{$key}) eq 'CODE') {
                $ch = $self->{'sysop_tokens'}->{$key}->($self);
            } else {
                $ch = $self->{'sysop_tokens'}->{$key};
            }
            $text =~ s/\[\%\s+$key\s+\%\]/$ch/gi;
        } ## end elsif ($text =~ /\[\%\s+$key\s+\%\]/)
    } ## end foreach my $key (keys %{ $self...})

    $text = $self->ansi_decode($text);

    return ($text);
} ## end sub sysop_detokenize

sub sysop_menu_choice {
    my $self   = shift;
    my $choice = shift;
    my $color  = shift;
    my $desc   = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Menu Choice']);
    my $response;
    if ($choice eq 'TOP') {
        $response = charnames::string_vianame('BOX DRAWINGS LIGHT ARC DOWN AND RIGHT') . charnames::string_vianame('BOX DRAWINGS LIGHT HORIZONTAL') . charnames::string_vianame('BOX DRAWINGS LIGHT ARC DOWN AND LEFT') . "\n";
    } elsif ($choice eq 'BOTTOM') {
        $response = $self->news_title_colorize(charnames::string_vianame('BOX DRAWINGS LIGHT ARC UP AND RIGHT') . charnames::string_vianame('BOX DRAWINGS LIGHT HORIZONTAL') . charnames::string_vianame('BOX DRAWINGS LIGHT ARC UP AND LEFT')) . "\n";
    } else {
        $response = $self->ansi_decode(charnames::string_vianame('BOX DRAWINGS LIGHT VERTICAL') . '[% BOLD %][% ' . $color . ' %]' . $choice . '[% RESET %]' . charnames::string_vianame('BOX DRAWINGS LIGHT VERTICAL') . ' [% ' . $color . ' %]' . charnames::string_vianame('BLACK RIGHT-POINTING TRIANGLE') . '[% RESET %] ' . $desc . "\n");
    }
    $self->{'debug'}->DEBUG(['End SysOp Menu Choice']);
    return ($response);
} ## end sub sysop_menu_choice

sub sysop_showenv {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp ShowENV']);
    my $MAX  = 0;
    my $text = '';
    foreach my $e (keys %ENV) {
        $MAX = max(length($e), $MAX);
    }

    foreach my $env (sort(keys %ENV)) {
        if ($ENV{$env} =~ /\n/g || $env eq 'WHATISMYIP_INFO') {
            my @in     = split(/\n/, $ENV{$env});
            my $indent = $MAX + 4;
            $text .= '[% BRIGHT WHITE %]' . sprintf("%${MAX}s", $env) . "[% RESET %] = ---\n";
            foreach my $line (@in) {
                if ($line =~ /\:/) {
                    my ($f, $l) = $line =~ /^(.*?):(.*)/;
                    chomp($l);
                    chomp($f);
                    $f = uc($f);
                    if ($f eq 'IP') {
                        $l = colored(['bright_green'], $l);
                        $f = 'IP ADDRESS';
                    }
                    my $le = 11 - length($f);
                    $f .= ' ' x $le;
                    $l = colored(['green'],    uc($l))                                                                         if ($l =~ /^ok/i);
                    $l = colored(['bold red'], 'U') . colored(['bold bright_white'], 'S') . colored(['bold bright_blue'], 'A') if ($l =~ /^us/i);
                    $text .= colored(['bold bright_cyan'], sprintf("%${indent}s", $f)) . " = $l\n";
                } else {
                    $text .= "$line\n";
                }
            } ## end foreach my $line (@in)
        } else {
            my $orig = $ENV{$env};
            my $new;

            if ($orig =~ /(256color)/) {
                $new = colored(['red'], '2') . colored(['green'], '5') . colored(['yellow'], '6') . colored(['cyan'], 'c') . colored(['bright_blue'], 'o') . colored(['magenta'], 'l') . colored(['bright_green'], 'o') . colored(['bright_blue'], 'r');
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(truecolor)/) {
                $new = colored(['red'], 't') . colored(['green'], 'r') . colored(['yellow'], 'u') . colored(['cyan'], 'e') . colored(['bright_blue'], 'c') . colored(['magenta'], 'o') . colored(['bright_green'], 'l') . colored(['bright_blue'], 'o') . colored(['red'], 'r');
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(\d+\.\d+\.\d+\.\d+)/) {
                $new = '[% BRIGHT GREEN %]' . $1 . '[% RESET %]';
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(ubuntu)/i) {
                $new = '[% ORANGE %]' . $1 . '[% RESET %]';
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(redhat)/i) {
                $new = colored(['bright_red'], $1);
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(fedora)/i) {
                $new = colored(['bright_cyan'], $1);
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(mint)/i) {
                $new = colored(['bright_green'], $1);
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(zorin)/i) {
                $new = colored(['bright_white'], $1);
                $orig =~ s/$1/$new/g;
            } elsif ($orig =~ /(wayland)/i) {
                $new = colored(['bright_yellow'], $1);
                $orig =~ s/$1/$new/g;
            }
            $text .= colored(['bold white'], sprintf("%${MAX}s", $env)) . ' = ' . $orig . "\n";
        } ## end else [ if ($ENV{$env} =~ /\n/g...)]
    } ## end foreach my $env (sort(keys ...))
    $self->{'debug'}->DEBUG(['End SysOp ShowENV']);
    return ($text);
} ## end sub sysop_showenv

sub sysop_scroll {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Scroll']);
    my $response = TRUE;
    print $self->{'ansi_meta'}->{'attributes'}->{'RESET'}->{'out'}, "\rScroll?  ";
    if ($self->sysop_keypress(ECHO, BLOCKING) =~ /N/i) {
        $response = FALSE;
    } else {
        print "\r" . clline;
    }
    $self->{'debug'}->DEBUG(['End SysOp Scroll']);
    return (TRUE);
} ## end sub sysop_scroll

sub sysop_list_bbs {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp List BBS']);
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM bbs_listing_view ORDER BY bbs_name');
    $sth->execute();
    my @listing;
    my ($id_size, $name_size, $hostname_size, $poster_size) = (2, 4, 14, 6);
    while (my $row = $sth->fetchrow_hashref()) {
        push(@listing, $row);
        $name_size     = max(length($row->{'bbs_name'}),     $name_size);
        $hostname_size = max(length($row->{'bbs_hostname'}), $hostname_size);
        $id_size       = max(length('' . $row->{'bbs_id'}),  $id_size);
        $poster_size   = max(length($row->{'bbs_poster'}),   $poster_size);
    } ## end while (my $row = $sth->fetchrow_hashref...)
    my $table = Text::SimpleTable->new($id_size, $name_size, $hostname_size, 5, $poster_size);
    $table->row('ID', 'NAME', 'HOSTNAME/PHONE', 'PORT', 'POSTER');
    $table->hr();
    foreach my $line (@listing) {
        $table->row($line->{'bbs_id'}, $line->{'bbs_name'}, $line->{'bbs_hostname'}, $line->{'bbs_port'}, $line->{'bbs_poster'});
    }
    $self->sysop_output($table->round('BRIGHT BLUE')->draw());
    print 'Press a key to continue... ';
    $self->sysop_keypress();
    $self->{'debug'}->DEBUG(['End SysOp List BBS']);
    return (TRUE);
} ## end sub sysop_list_bbs

sub sysop_edit_bbs {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Edit BBS']);
    my @choices = (qw( bbs_id bbs_name bbs_hostname bbs_port ));
    $self->sysop_prompt('Please enter the ID, the hostname/phone, or the BBS name to edit');
    my $search;
    $search = $self->sysop_get_line(ECHO, 50, '');
    return (FALSE) if ($search eq '');
    print "\r", cldown, "\n";
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM bbs_listing_view WHERE bbs_id=? OR bbs_name=? OR bbs_hostname=?');
    $sth->execute($search, $search, $search);

    if ($sth->rows() > 0) {
        my $bbs = $sth->fetchrow_hashref();
        $sth->finish();
        my $table = Text::SimpleTable->new(6, 12, 50);
        my $index = 1;
        $table->row('CHOICE', 'FIELD NAME', 'VALUE');
        $table->hr();
        foreach my $name (qw(bbs_id bbs_poster bbs_name bbs_hostname bbs_port)) {
            if ($name =~ /bbs_id|bbs_poster/) {
                $table->row(' ', $name, $bbs->{$name});
            } else {
                $table->row($index, $name, $bbs->{$name});
                $index++;
            }
        } ## end foreach my $name (qw(bbs_id bbs_poster bbs_name bbs_hostname bbs_port))
        $self->sysop_output($table->round('BRIGHT BLUE')->draw());
        $self->sysop_prompt('Edit which field (Z=Nevermind)');
        my $choice;
        do {
            $choice = $self->sysop_keypress();
        } until ($choice =~ /[1-3]|Z/i);
        if ($choice =~ /\D/) {
            print "BACK\n";
            return (FALSE);
        }
        $self->sysop_prompt($choices[$choice] . ' (' . $bbs->{ $choices[$choice] } . ') ');
        my $width = ($choices[$choice] eq 'bbs_port') ? 5 : 50;
        my $new   = $self->sysop_get_line(ECHO, $width, '');
        if ($new eq '') {
            $self->{'debug'}->DEBUG(['sysop_edit_bbs end']);
            return (FALSE);
        }
        $sth = $self->{'dbh'}->prepare('UPDATE bbs_listing SET ' . $choices[$choice] . '=? WHERE bbs_id=?');
        $sth->execute($new, $bbs->{'bbs_id'});
        $sth->finish();
    } else {
        $sth->finish();
    }
    $self->{'debug'}->DEBUG(['End SysOp Edit BBS']);
    return (TRUE);
} ## end sub sysop_edit_bbs

sub sysop_add_bbs {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Add BBS']);
    my $table = Text::SimpleTable->new(14, 50);
    foreach my $name ('BBS NAME', 'HOSTNAME/PHONE', 'PORT') {
        my $count = ($name eq 'PORT') ? 5 : 50;
        $table->row($name, "\n" . charnames::string_vianame('OVERLINE') x $count);
        $table->hr() unless ($name eq 'PORT');
    }
    my @order = (qw(bbs_name bbs_hostname bbs_port));
    my $bbs   = {
        'bbs_name'     => '',
        'bbs_hostname' => '',
        'bbs_port'     => '',
    };
    my $index    = 0;
    my $response = TRUE;
    $self->sysop_output($table->round('BRIGHT BLUE')->draw());
    print $self->{'ansi_meta'}->{'cursor'}->{'UP'}->{'out'} x 9, $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x 19;
    $bbs->{'bbs_name'} = $self->sysop_get_line(ECHO, 50, '');
    $self->{'debug'}->DEBUG(['  BBS Name:  ' . $bbs->{'bbs_name'}]);

    if ($bbs->{'bbs_name'} ne '' && length($bbs->{'bbs_name'}) > 3) {
        print $self->{'ansi_meta'}->{'cursor'}->{'DOWN'}->{'out'} x 2, "\r", $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x 19;
        $bbs->{'bbs_hostname'} = $self->sysop_get_line(ECHO, 50, '');
        $self->{'debug'}->DEBUG(['  BBS Hostname:  ' . $bbs->{'bbs_hostname'}]);
        if ($bbs->{'bbs_hostname'} ne '' && length($bbs->{'bbs_hostname'}) > 5) {
            print $self->{'ansi_meta'}->{'cursor'}->{'DOWN'}->{'out'} x 2, "\r", $self->{'ansi_meta'}->{'cursor'}->{'RIGHT'}->{'out'} x 19;
            $bbs->{'bbs_port'} = $self->sysop_get_line(ECHO, 5, '');
            $self->{'debug'}->DEBUG(['  BBS Port:  ' . $bbs->{'bbs_port'}]);
            if ($bbs->{'bbs_port'} ne '' && $bbs->{'bbs_port'} =~ /^\d+$/) {
                $self->{'debug'}->DEBUG(['  Add to BBS List']);
                my $sth = $self->{'dbh'}->prepare('INSERT INTO bbs_listing (bbs_name,bbs_hostname,bbs_port,bbs_poster_id) VALUES (?,?,?,1)');
                $sth->execute($bbs->{'bbs_name'}, $bbs->{'bbs_hostname'}, $bbs->{'bbs_port'});
                $sth->finish();
            } else {
                $response = FALSE;
            }
        } else {
            $response = FALSE;
        }
    } else {
        $response = FALSE;
    }
    $self->{'debug'}->DEBUG(['End SysOp Add BBS']);
    return ($response);
} ## end sub sysop_add_bbs

sub sysop_delete_bbs {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Delete BBS']);
    $self->sysop_prompt('Please enter the ID, the hostname, or the BBS name to delete');
    my $search;
    $search = $self->sysop_get_line(ECHO, 50, '');
    if ($search eq '') {
        return (FALSE);
    }
    print "\r", cldown, "\n";
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM bbs_listing_view WHERE bbs_id=? OR bbs_name=? OR bbs_hostname=?');
    $sth->execute($search, $search, $search);

    if ($sth->rows() > 0) {
        my $bbs = $sth->fetchrow_hashref();
        $sth->finish();
        my $table = Text::SimpleTable->new(12, 50);
        $table->row('FIELD NAME', 'VALUE');
        $table->hr();
        foreach my $name (qw(bbs_id bbs_poster bbs_name bbs_hostname bbs_port)) {
            $table->row($name, $bbs->{$name});
        }
        $self->sysop_output($table->round('RED')->draw());
        print 'Are you sure that you want to delete this BBS from the list (Y|N)?  ';
        my $choice = $self->sysop_decision();
        unless ($choice) {
            $self->{'debug'}->DEBUG(['End SysOp Delete BBS']);
            return (FALSE);
        }
        $sth = $self->{'dbh'}->prepare('DELETE FROM bbs_listing WHERE bbs_id=?');
        $sth->execute($bbs->{'bbs_id'});
    } ## end if ($sth->rows() > 0)
    $sth->finish();
    $self->{'debug'}->DEBUG(['End SysOp Delete BBS']);
    return (TRUE);
} ## end sub sysop_delete_bbs

sub sysop_add_file_category {
	my $self = shift;

    my $bar = '[% BRIGHT GREEN %]│[% RESET %]';
	my $max_columns = $self->{'USER'}->{'max_columns'};
	my $table = '[% BRIGHT GREEN %]╭' . '─' x ($max_columns - 2) . '╮[% RESET %]' . "\n";
	$table   .= sprintf('%s %s       TITLE? %s%-' . ($max_columns - 15) . 's %s', $bar, '[% B_GREEN %][% BLACK %]', '[% RESET %]', '', $bar) . "\n";
	$table   .= sprintf('%s %s DESCRIPTION? %s%-' . ($max_columns - 15) . 's %s', $bar, '[% B_YELLOW %][% BLACK %]', '[% RESET %]', '', $bar) . "\n";
	$table   .= sprintf('%s %s   FILE PATH? %s%-' . ($max_columns - 15) . 's %s', $bar, '[% B_MAGENTA %][% BLACK %]', '[% RESET %]', '', $bar) . "\n";
	$table   .= '[% BRIGHT GREEN %]╰' . '─' x ($self->{'USER'}->{'max_columns'} - 2) . '╯[% RESET %]' . "\n";
	$self->output($table);
	$self->output('[% UP %]' x 4 . '[% RIGHT %]' x 17);
	my $title = $self->sysop_get_line({ 'max' => ($max_columns - 17), 'type' => STRING, }, '');
	return(FALSE) if (length($title) < 4);
	$self->output('[% RIGHT %]' x 17);
	my $desc  = $self->sysop_get_line({ 'max' => ($max_columns - 17), 'type' => STRING, }, '');
	return(FALSE) if (length($desc) < 4);
	$self->output('[% RIGHT %]' x 17);
	my $path  = $self->sysop_get_line({ 'max' => ($max_columns - 17), 'type' => STRING, }, lc($title));
	return(FALSE) if (length($path) < 3);
    $self->sysop_prompt('Is this correct [y/n]?');
	if ($self->sysop_decision()) {
		print "YES\n";
		print "Adding category to the database...";
		my $sth = $self->{'dbh'}->prepare('INSERT INTO file_categories (title,description,path) VALUES (?,?,?)');
		$sth->execute($title, $desc, $path);
		$sth->finish();
		print "Done\nAdding ", $self->{'CONF'}->{'FILES PATH'},$path,'...';
		mkdir($self->{'CONF'}->{'FILES PATH'} . $path);
		print "Done\nFile category added\n";
		sleep 1;
		return(TRUE);
	} else {
		print "NO\n";
		return(FALSE);
	}
}

sub sysop_add_file {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp Add File']);
    opendir(my $DIR, 'files/files/');
    my @dir = grep(!/^\.+/, readdir($DIR));
    closedir($DIR);
    my $list;
    my $nw  = 0;
    my $sw  = 4;
    my $tw  = 0;
    my $sth = $self->{'dbh'}->prepare('SELECT id FROM files WHERE filename=?');
    my $search;
    my $root          = $self->configuration('BBS ROOT');
    my $files_path    = $self->configuration('FILES PATH');
    my $file_category = $self->{'USER'}->{'file_category'};

    foreach my $file (@dir) {
        $sth->execute($file);
        my $rows = $sth->rows();
        if ($rows <= 0) {
            $nw = max(length($file), $nw);
            my $raw_size = (-s "$root/$files_path/$file");
            my $size     = format_number($raw_size);
            $sw = max(length("$size"), $sw, 4);
            my ($ext, $type) = $self->files_type($file);
            $tw                          = max(length($type), $tw);
            $list->{$file}->{'raw_size'} = $raw_size;
            $list->{$file}->{'size'}     = $size;
            $list->{$file}->{'type'}     = $type;
            $list->{$file}->{'ext'}      = uc($ext);
        } ## end if ($rows <= 0)
    } ## end foreach my $file (@dir)
    $sth->finish();
    if (defined($list)) {
        my @names = grep(!/^README.md$/, (sort(keys %{$list})));
        if (scalar(@names)) {
            $self->{'debug'}->DEBUGMAX($list);
            my $table = Text::SimpleTable->new($nw, $sw, $tw);
            $table->row('FILE', 'SIZE', 'TYPE');
            $table->hr();
            foreach my $file (sort(keys %{$list})) {
                $table->row($file, $list->{$file}->{'size'}, $list->{$file}->{'type'});
            }
            my $text = $table->twin('GREEN')->draw();
            $self->sysop_pager($text);
            while (scalar(@names)) {
                ($search) = shift(@names);
                $self->sysop_output('[% B_WHITE %][% BLACK %] Current Category [% RESET %] [% BRIGHT YELLOW %][% BLACK RIGHT-POINTING TRIANGLE %][% RESET %] [% BRIGHT WHITE %][% FILE CATEGORY %][% RESET %]' . "\n\n");
                $self->sysop_prompt('Which file would you like to add?  ');
                $search = $self->sysop_get_line(ECHO, $nw, $search);
                my $filename = "$root/$files_path/$search";
                if (-e $filename) {
                    $self->sysop_prompt('               What is the Title?');
                    my $title = $self->sysop_get_line(ECHO, 255, '');
                    if (defined($title) && $title ne '') {
                        $self->sysop_prompt('                Add a description');
                        my $description = $self->sysop_get_line(ECHO, 65535, '');
                        if (defined($description) && $description ne '') {
                            my $head = "\n" . '[% REVERSE %]    Category [% RESET %] [% FILE CATEGORY %]' . "\n" . '[% REVERSE %]   File Name [% RESET %] ' . $search . "\n" . '[% REVERSE %]       Title [% RESET %] ' . $title . "\n" . '[% REVERSE %] Description [% RESET %] ' . $description . "\n\n";
                            print $self->sysop_detokenize($head);
                            $self->sysop_prompt('Is this correct?');
                            if ($self->sysop_decision()) {
                                $sth = $self->{'dbh'}->prepare('INSERT INTO files (filename, title, user_id, category, file_type, description, file_size) VALUES (?,?,1,?,(SELECT id FROM file_types WHERE extension=?),?,?)');
                                $sth->execute($search, $title, $self->{'USER'}->{'file_category'}, $list->{$search}->{'ext'}, $description, $list->{$search}->{'raw_size'});
                                if ($self->{'dbh'}->err) {
                                    $self->{'debug'}->ERROR([$self->{'dbh'}->errstr]);
                                }
                                $sth->finish();
                            } ## end if ($self->sysop_decision...)
                        } ## end if (defined($description...))
                    } ## end if (defined($title) &&...)
                } ## end if (-e $filename)
            } ## end while (scalar(@names))
        } else {
            $self->sysop_output("\n\n" . '[% BRIGHT RED %]NO FILES TO ADD![% RESET %]  ');
            sleep 2;
        }
    } else {
        print colored(['yellow'], 'No unmapped files found'), "\n";
        sleep 2;
    }
    $self->{'debug'}->DEBUG(['End SysOp Add File']);
} ## end sub sysop_add_file

sub sysop_bbs_list_bulk_import {
    my $self = shift;

    my $filename = $self->configuration('BBS ROOT') . "/bbs_list.txt";
    $self->{'debug'}->DEBUG(['Start SysOp BBS List Bulk Import of ' . $filename]);
    if (-e "$filename") {
        $self->sysop_output("\n\nImporting/merging BBS list from bbs_list.txt\n\n");
        $self->sysop_output('[% GREEN %]╭───────────────────────────────────────────────────────────────────┬──────────────────────────────────┬───────╮[% RESET %]' . "\n");
        $self->sysop_output('[% GREEN %]│[% RESET %] NAME                                                              [% GREEN %]│[% RESET %] HOSTNAME/PHONE                   [% GREEN %]│[% RESET %] PORT  [% GREEN %]│[% RESET %]' . "\n");
        $self->sysop_output('[% GREEN %]├───────────────────────────────────────────────────────────────────┼──────────────────────────────────┼───────┤[% RESET %]' . "\n");
        open(my $FILE, '<', $filename);
        chomp(my @bbs = <$FILE>);
        close($FILE);

        my $sth = $self->{'dbh'}->prepare('REPLACE INTO bbs_listing (bbs_name,bbs_hostname,bbs_port,bbs_poster_id) VALUES (?,?,?,?)');
        foreach my $row (@bbs) {
            if ($row =~ /^. \S/ && $row !~ /^\* = NEW/) {
                $row =~ s/^\* /  /;
                my ($name, $url) = (substr($row, 2, 41), substr($row, 43));
                $name =~ s/(.*?)\s+$/$1/;
                my ($address, $port) = split(/:/, $url);
                $port = 23 unless (defined($port));
                $sth->execute($name, $address, $port, $self->{'USER'}->{'id'});
                $self->sysop_output('[% GREEN %]│[% RESET %] ' . sprintf('%-65s', $name) . '[% GREEN %] │[% RESET %] ' . sprintf('%-32s', $address) . ' [% GREEN %]│[% RESET %] ' . sprintf('%5d', $port) . ' [% GREEN %]│[% RESET %]' . "\n");
            } ## end if ($row =~ /^. \S/ &&...)
        } ## end foreach my $row (@bbs)
        $sth->finish();
        $self->sysop_output('[% GREEN %]╰───────────────────────────────────────────────────────────────────┴──────────────────────────────────┴───────╯[% RESET %]' . "\n\nImport Complete\n");
    } else {
        print "\n", chr(7), colored(['red'], 'Cannot find '), $filename, "\n";
        $self->{'debug'}->WARNING(["Cannot find $filename"]);
    }
    print "\nPress any key to continue";
    $self->sysop_get_key(SILENT, BLOCKING);
    $self->{'debug'}->DEBUG(['End SysOp BBS List Bulk Import']);
    return (TRUE);
} ## end sub sysop_bbs_list_bulk_import

sub sysop_ansi_output {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start SysOp ANSI Output']);
    my $mlines = (exists($self->{'USER'}->{'max_rows'})) ? $self->{'USER'}->{'max_rows'} - 3 : 21;
    my $lines  = $mlines;
    my $text   = $self->ansi_decode(shift);
    my $s_len  = length($text);
    my $nl     = $self->{'ansi_meta'}->{'cursor'}->{'NEWLINE'}->{'out'};
    my @lines  = split(/\n/, $text);
    my $size   = $self->{'USER'}->{'max_rows'};

    while (scalar(@lines)) {
        my $line = shift(@lines);
        print $line;
        $size--;
        if ($size <= 0) {
            $size = $self->{'USER'}->{'max_rows'};
            last unless ($self->scroll(("\n")));
        } else {
            print "\n";
        }
    } ## end while (scalar(@lines))
    $self->{'debug'}->DEBUG(['End SysOp ANSI Output']);
    return (TRUE);
} ## end sub sysop_ansi_output

sub sysop_output {
    my $self = shift;
    $| = 1;
    $self->{'debug'}->DEBUG(['Start SysOp Output']);
    my $text = $self->detokenize_text(shift);

    my $response = TRUE;
    if (defined($text) && $text ne '') {
        while ($text =~ /\[\%\s+WRAP\s+\%\](.*?)\[\%\s+ENDWRAP\s+\%\]/si) {
            my $wrapped = $1;
            my $format  = Text::Format->new(
                'columns'     => $self->{'USER'}->{'max_columns'} - 1,
                'tabstop'     => 4,
                'extraSpace'  => TRUE,
                'firstIndent' => 0,
            );
            $wrapped = $format->format($wrapped);
            chomp($wrapped);
            $text =~ s/\[\%\s+WRAP\s+\%\].*?\[\%\s+ENDWRAP\s+\%\]/$wrapped/s;
        } ## end while ($text =~ /\[\%\s+WRAP\s+\%\](.*?)\[\%\s+ENDWRAP\s+\%\]/si)
        while ($text =~ /\[\%\s+JUSTIFIED\s+\%\](.*?)\[\%\s+ENDJUSTIFIED\s+\%\]/si) {
            my $wrapped = $1;
            my $format  = Text::Format->new(
                'columns'     => $self->{'USER'}->{'max_columns'} - 1,
                'tabstop'     => 4,
                'extraSpace'  => TRUE,
                'firstIndent' => 0,
                'justify'     => TRUE,
            );
            $wrapped = $format->format($wrapped);
            chomp($wrapped);
            $text =~ s/\[\%\s+JUSTIFIED\s+\%\].*?\[\%\s+ENDJUSTIFIED\s+\%\]/$wrapped/s;
        } ## end while ($text =~ /\[\%\s+JUSTIFIED\s+\%\](.*?)\[\%\s+ENDJUSTIFIED\s+\%\]/si)
        $self->sysop_ansi_output($text);
    } else {
        $response = FALSE;
    }
    $self->{'debug'}->DEBUG(['End SysOp Output']);
    return ($response);
} ## end sub sysop_output

 

# package BBS::Universal::Tokens;

sub tokens_initialize {
	my $self = shift;

	$self->{'debug'}->DEBUG(['Begin Tokens initialize']);
	$self->{'TOKENS'} = {
        'AUTHOR NAME' => sub {
            my $self = shift;
            return ($self->{'CONF'}->{'STATIC'}->{'AUTHOR NAME'});
        },
        'BANNER' => sub {
            my $self   = shift;
            my $banner = $self->files_load_file('files/main/banner');
            return ($banner);
        },
        'BBS NAME' => sub {
            my $self = shift;
            return ($self->{'CONF'}->{'BBS NAME'});
        },
        'BBS VERSION'  => $self->{'VERSIONS'}->{'BBS Executable'},
        'BIRTHDAY' => sub {
            my $self = shift;
            my $birthday = $self->{'USER'}->{'birthday'};
            if (length($birthday) > 5) {
                $birthday =~ s/\d\d\d\d\-(\d+)\-(\d+)/${1}-${2}/;
            }
            return($birthday);
        },
        'BAUD RATE' => sub {
            my $self = shift;
            return ($self->{'baud_rate'});
        },
        'CPU IDENTITY' => $self->{'CPU'}->{'CPU IDENTITY'},
        'CPU CORES'    => $self->{'CPU'}->{'CPU CORES'},
        'CPU SPEED'    => $self->{'CPU'}->{'CPU SPEED'},
        'CPU THREADS'  => $self->{'CPU'}->{'CPU THREADS'},
        'FORTUNE' => sub {
            my $self = shift;
            return ($self->get_fortune);
        },
        'FILE CATEGORY' => sub {
            my $self = shift;
            return ($self->users_file_category());
        },
        'FORUM CATEGORY' => sub {
            my $self = shift;
            return ($self->news_title_colorize($self->users_forum_category()));
        },
        'LAST LOGIN' => sub {
            my $self = shift;
            return($self->{'USER'}->{'login_time'});
        },
        'LAST LOGOUT' => sub {
            my $self = shift;
            return($self->{'USER'}->{'logout_time'});
        },
        'NOW' => sub {
            my $self = shift;
            return($self->now());
        },
        'ONLINE' => sub {
            my $self = shift;
            return ($self->{'CACHE'}->get('ONLINE'));
        },
        'OS'           => $self->{'os'},
        'PERL VERSION' => $self->{'VERSIONS'}->{'Perl'},
        'RSS CATEGORY' => sub {
            my $self = shift;
            return ($self->news_title_colorize($self->users_rss_category()));
        },
        'SHOW USERS LIST' => sub {
            my $self = shift;
            return ($self->users_list());
        },
        'SYSOP'        => sub {
            my $self = shift;
            if ($self->{'sysop'}) {
                return ('SYSOP CREDENTIALS');
            } else {
                return ('USER CREDENTIALS');
            }
        },
        'THREAD ID' => sub {
            my $self = shift;
            my $tid  = threads->tid();
            if ($tid == 0) {
                $tid = 'LOCAL';
            } else {
                $tid = sprintf('%02d', $tid);
            }
            return ($tid);
        },
        'TIME' => sub {
            my $self = shift;
            return (DateTime->now);
        },
        'USER INFO' => sub {
            my $self = shift;
            return ($self->users_info());
        },
        'USER PERMISSIONS' => sub {
            my $self = shift;
            return ($self->dump_permissions);
        },
        'USER ID' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'id'});
        },
        'USER FULLNAME' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'fullname'});
        },
        'USER USERNAME' => sub {
            my $self = shift;
            if ($self->{'USER'}->{'prefer_nickname'}) {
                return ($self->{'USER'}->{'nickname'});
            } else {
                return ($self->{'USER'}->{'username'});
            }
        },
        'USER NICKNAME' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'nickname'});
        },
        'USER EMAIL' => sub {
            my $self = shift;
            if ($self->{'USER'}->{'show_email'}) {
                return ($self->{'USER'}->{'email'});
            } else {
                return ('[HIDDEN]');
            }
        },
        'USERS COUNT' => sub {
            my $self = shift;
            return ($self->users_count());
        },
        'USER COLUMNS' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'max_columns'});
        },
        'USER ROWS' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'max_rows'});
        },
        'USER SCREEN SIZE' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'max_columns'} . 'x' . $self->{'USER'}->{'max_rows'});
        },
        'USER GIVEN' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'given'});
        },
        'USER FAMILY' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'family'});
        },
        'USER LOCATION' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'location'});
        },
        'USER BIRTHDAY' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'birthday'});
        },
        'USER RETRO SYSTEMS' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'retro_systems'});
        },
        'USER LOGIN TIME' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'login_time'});
        },
        'USER TEXT MODE' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'text_mode'});
        },
        'UPTIME' => sub {
            my $self = shift;
            chomp(my $uptime = `uptime -p`);
            $self->{'debug'}->DEBUG(["Get Uptime $uptime"]);
            return ($uptime);
        },
        'VERSIONS' => 'placeholder',
        'UPTIME'   => 'placeholder',
	};
	$self->{'debug'}->DEBUG(['End Tokens initialize']);
}

 

# package BBS::Universal::Users;

sub users_initialize {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Initialize']);
    $self->{'USER'}->{'mode'} = ASCII;
    $self->{'debug'}->DEBUG(['End Users Initialize']);
    return ($self);
} ## end sub users_initialize

sub users_change_access_level {
    my $self = shift;
    return (FALSE) if ($self->{'USER'}->{'username'} eq 'sysop');
    $self->{'debug'}->DEBUG(['Start Users Change Access Level']);
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Back to Account menu' },
    };
    foreach my $result (keys %{ $self->{'access_levels'} }) {
        if (($self->{'access_levels'}->{$result} < $self->{'access_levels'}->{ $self->{'USER'}->{'access_level'} }) || $self->{'USER'}->{'access_level'} eq 'SYSOP') {
            $mapping->{ chr(65 + $self->{'access_levels'}->{$result}) } = {
                'command'      => $result,
                'color'        => 'WHITE',
                'access_level' => $self->{'USER'}->{'access_level'},
                'text'         => $result,
            };
        } ## end if (($self->{'access_levels'...}))
    } ## end foreach my $result (keys %{...})

    $self->show_choices($mapping);
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $self->prompt('([% BRIGHT YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } elsif ($mode eq 'ATASCII') {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    } elsif ($mode eq 'PETSCII') {
        $self->prompt('([% YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } else {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    }
    my $key;
    do {
        $key = uc($self->get_key(SILENT, FALSE));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    $self->output($mapping->{$key}->{'command'} . "\n");
    unless ($key eq 'Z' || $key eq chr(3)) {
        my $command = $mapping->{$key}->{'command'};
        my $sth     = $self->{'dbh'}->prepare('UPDATE users SET date_format=? WHERE id=?');
        $sth->execute($command, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'USER'}->{'date_format'} = $command;
    } ## end unless ($key eq 'Z' || $key...)
    $self->{'debug'}->DEBUG(['End Users Change Access Level']);
    return (TRUE);
} ## end sub users_change_access_level

sub users_change_date_format {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Change Date Format']);
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Back to Account menu' },
    };
    my $count = 1;
    foreach my $result ('YEAR/MONTH/DAY', 'MONTH/DAY/YEAR', 'DAY/MONTH/YEAR') {
        $mapping->{ chr(64 + $count) } = {
            'command'      => $result,
            'color'        => 'WHITE',
            'access_level' => 'USER',
            'text'         => $result,
        };
        $count++;
    } ## end foreach my $result ('YEAR/MONTH/DAY'...)

    $self->show_choices($mapping);
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $self->prompt('([% BRIGHT YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } elsif ($mode eq 'ATASCII') {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    } elsif ($mode eq 'PETSCII') {
        $self->prompt('([% YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } else {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    }
    my $key;
    do {
        $key = uc($self->get_key(SILENT, FALSE));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    $self->output($mapping->{$key}->{'command'} . "\n");
    unless ($key eq 'Z' || $key eq chr(3)) {
        my $command = $mapping->{$key}->{'command'};
        my $sth     = $self->{'dbh'}->prepare('UPDATE users SET date_format=? WHERE id=?');
        $sth->execute($command, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'USER'}->{'date_format'} = $command;
    } ## end unless ($key eq 'Z' || $key...)
    $self->{'debug'}->DEBUG(['End Users Change Date Format']);
    return (TRUE);
} ## end sub users_change_date_format

sub users_change_baud_rate {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Change Baud Rate']);
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Back to Account menu' },
    };
    my $count = 1;
    foreach my $result (qw(300 1200 2400 4800 9600 19200 FULL)) {
        $mapping->{ chr(64 + $count) } = {
            'command'      => $result,
            'color'        => 'WHITE',
            'access_level' => 'USER',
            'text'         => $result,
        };
        $count++;
    } ## end foreach my $result (qw(300 1200 2400 4800 9600 19200 FULL))

    $self->show_choices($mapping);
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $self->prompt('([% BRIGHT YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } elsif ($mode eq 'ATASCII') {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    } elsif ($mode eq 'PETSCII') {
        $self->prompt('([% YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } else {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    }
    my $key;
    do {
        $key = uc($self->get_key(SILENT, FALSE));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    $self->output($mapping->{$key}->{'command'} . "\n");
    unless ($key eq 'Z' || $key eq chr(3)) {
        my $command = $mapping->{$key}->{'command'};
        my $sth     = $self->{'dbh'}->prepare('UPDATE users SET baud_rate=? WHERE id=?');
        $sth->execute($command, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'USER'}->{'baud_rate'} = $command;
        $self->{'debug'}->DEBUG(["  Baud Rate:  $command"]);
    } ## end unless ($key eq 'Z' || $key...)
    $self->{'debug'}->DEBUG(['End Users Change Baud Rate']);
    return (TRUE);
} ## end sub users_change_baud_rate

sub users_change_screen_size {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Change Screen Size']);
    $self->prompt("\nColumns");
    my $columns = 0 + $self->get_line({ 'type' => NUMERIC, 'max' => 3, 'default' => $self->{'USER'}->{'max_columns'} });
    if ($columns >= 32 && $columns ne $self->{'USER'}->{'max_columns'} && $self->is_connected()) {
        $self->{'USER'}->{'max_columns'} = $columns;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET max_columns=? WHERE id=?');
        $sth->execute($columns, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Columns:  $columns"]);
    } ## end if ($columns >= 32 && ...)
    $self->prompt("\nRows");
    my $rows = 0 + $self->get_line({ 'type' => NUMERIC, 'max' => 3, 'defult' => $self->{'USER'}->{'max_rows'} });
    if ($rows >= 25 && $rows ne $self->{'USER'}->{'max_rows'} && $self->is_connected()) {
        $self->{'USER'}->{'max_rows'} = $rows;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET max_rows=? WHERE id=?');
        $sth->execute($rows, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Rows:  $rows"]);
    } ## end if ($rows >= 25 && $rows...)
    $self->{'debug'}->DEBUG(['Start Users Change Screen Size']);
    return (TRUE);
} ## end sub users_change_screen_size

sub users_update_retro_systems {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Update Retro Systems']);
    $self->prompt("\nName your retro computers");
    my $retro = $self->get_line({ 'type' => STRING, 'max' => 65535, 'default' => $self->{'USER'}->{'retro_systems'} });
    if (length($retro) >= 5 && $retro ne $self->{'USER'}->{'retro_systems'} && $self->is_connected()) {
        $self->{'USER'}->{'retro_systems'} = $retro;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET retro_systems=? WHERE id=?');
        $sth->execute($retro, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Retro Systems:  $retro"]);
    } ## end if (length($retro) >= ...)
    $self->{'debug'}->DEBUG(['End Users Update Retro Systems']);
    return (TRUE);
} ## end sub users_update_retro_systems

sub users_update_email {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Update Email']);
    $self->prompt("\nEnter email address");
    my $email = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => $self->{'USER'}->{'email'} });
    if (length($email) > 5 && $email ne $self->{'USER'}->{'email'} && $self->is_connected()) {
        $self->{'USER'}->{'email'} = $email;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET email=? WHERE id=?');
        $sth->execute($email, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Email:  $email"]);
    } ## end if (length($email) > 5...)
    $self->{'debug'}->DEBUG(['End Users Update Email']);
    return (TRUE);
} ## end sub users_update_email

sub users_toggle_permission {
    my $self  = shift;
    my $field = shift;

    return (FALSE) if ($self->{'USER'}->{'username'} eq 'sysop');

    $self->{'debug'}->DEBUG(['Start Users Toggle Permission']);
    if (0 + $self->{'USER'}->{$field}) {
        $self->{'USER'}->{$field} = FALSE;
    } else {
        $self->{'USER'}->{$field} = TRUE;
    }
    my $sth = $self->{'dbh'}->prepare('UPDATE permissions SET ' . $field . '=? WHERE id=?');
    $sth->execute($self->{'USER'}->{$field}, $self->{'USER'}->{'id'});
    $self->{'dbh'}->commit;
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Users Toggle Permission']);
    return (TRUE);
} ## end sub users_toggle_permission

sub users_update_location {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Update Location']);
    $self->prompt("\nEnter your location");
    my $location = $self->get_line({ 'type' => STRING, 'max' => 255, 'default' => $self->{'USER'}->{'location'} });
    if (length($location) >= 4 && $location ne $self->{'USER'}->{'location'} && $self->is_connected()) {
        $self->{'USER'}->{'location'} = $location;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET location=? WHERE id=?');
        $sth->execute($location, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Location:  $location"]);
    } ## end if (length($location) ...)
    $self->{'debug'}->DEBUG(['End Users Update Location']);
    return (TRUE);
} ## end sub users_update_location

sub users_update_accomplishments {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Update Accomplishments']);
    $self->prompt("\nEnter your accomplishments");
    my $accomplishments = $self->get_line({ 'type' => STRING, 'max' => 65535, 'default' => $self->{'USER'}->{'accomplishments'} });
    if (length($accomplishments) >= 4 && $accomplishments ne $self->{'USER'}->{'accomplishments'} && $self->is_connected()) {
        $self->{'USER'}->{'accomplishments'} = $accomplishments;
        my $sth = $self->{'dbh'}->prepare('UPDATE users SET accomplishments=? WHERE id=?');
        $sth->execute($accomplishments, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'debug'}->DEBUG(["  Accomplishments:  $accomplishments"]);
    } ## end if (length($accomplishments...))
    $self->{'debug'}->DEBUG(['End Users Update Accomplishments']);
    return (TRUE);
} ## end sub users_update_accomplishments

sub users_update_text_mode {
    my $self = shift;

    return (FALSE) if ($self->{'USER'}->{'username'} eq 'sysop');
    $self->{'debug'}->DEBUG(['Start Users Update Text Mode']);
    my $mapping = {
        'TEXT' => '',
        'Z'    => { 'command' => 'BACK', 'color' => 'WHITE', 'access_level' => 'USER', 'text' => 'Back to Account menu' },
    };
    my $sth = $self->{'dbh'}->prepare('SELECT * FROM text_modes ORDER BY text_mode');
    $sth->execute();
    my $count = 1;
    while (my $result = $sth->fetchrow_hashref()) {
        $mapping->{ chr(64 + $count) } = {
            'command'      => $result->{'text_mode'},
            'color'        => 'WHITE',
            'access_level' => 'USER',
            'text'         => $result->{'text_mode'},
        };
        $count++;
    } ## end while (my $result = $sth->...)
    $sth->finish();

    $self->show_choices($mapping);
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $self->prompt('([% BRIGHT YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } elsif ($mode eq 'ATASCII') {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    } elsif ($mode eq 'PETSCII') {
        $self->prompt('([% YELLOW %]' . $self->{'USER'}->{'username'} . '[% RESET %]) ' . 'Choose');
    } else {
        $self->prompt('(' . $self->{'USER'}->{'username'} . ') ' . 'Choose');
    }
    my $key;
    do {
        $key = uc($self->get_key(SILENT, FALSE));
    } until (exists($mapping->{$key}) || $key eq chr(3) || !$self->is_connected());
    $self->output($mapping->{$key}->{'command'} . "\n");
    unless ($key eq 'Z' || $key eq chr(3)) {
        my $command = $mapping->{$key}->{'command'};
        my $sth     = $self->{'dbh'}->prepare('UPDATE users SET text_mode=(SELECT id FROM text_modes WHERE text_mode=?) WHERE id=?');
        $sth->execute($command, $self->{'USER'}->{'id'});
        $sth->finish;
        $self->{'USER'}->{'text_mode'} = $command;
        $self->{'debug'}->DEBUG(["  Text Mode:  $command"]);
    } ## end unless ($key eq 'Z' || $key...)
    $self->{'debug'}->DEBUG(['Start Users Update Text Mode']);
    return (TRUE);
} ## end sub users_update_text_mode

sub users_load {
    my $self     = shift;
    my $username = shift;
    my $password = shift;

    $self->{'debug'}->DEBUG(['Start Users Load']);
    my $sth;
    if ($self->{'sysop'}) {
        $sth = $self->{'dbh'}->prepare('SELECT * FROM users_view WHERE username=?');
        $sth->execute($username);
    } else {
        $sth = $self->{'dbh'}->prepare('SELECT * FROM users_view WHERE username=? AND password=SHA2(?,512)');
        $sth->execute($username, $password);
    }
    my $results  = $sth->fetchrow_hashref();
    my $response = FALSE;
    if (defined($results)) {
        $self->{'USER'} = $results;
        delete($self->{'USER'}->{'password'});
        foreach my $field (    # For numeric values
            qw(
            show_email
            prefer_nickname
            view_files
            upload_files
            download_files
            remove_files
            read_message
            post_message
            remove_message
            play_fortunes
            banned
            sysop
            )
        ) {
            $self->{'USER'}->{$field} = 0 + $self->{'USER'}->{$field};
        } ## end foreach my $field (  qw( show_email...))
        $response = TRUE;
    } ## end if (defined($results))
    $self->{'debug'}->DEBUG(['End Users Load']);
    return ($response);
} ## end sub users_load

sub users_get_date {
    my $self     = shift;
    my $old_date = shift;

    $self->{'debug'}->DEBUG(['Start User Get Date']);
    my $response;
    if ($old_date =~ / /) {
        my $time;
        ($old_date, $time) = split(/ /, $old_date);
        my ($year, $month, $day) = split(/-/, $old_date);
        my $date = $self->{'USER'}->{'date_format'};
        $date =~ s/YEAR/$year/;
        $date =~ s/MONTH/$month/;
        $date =~ s/DAY/$day/;
        $response = "$date $time";
    } else {
        my ($year, $month, $day) = split(/-/, $old_date);
        my $date = $self->{'USER'}->{'date_format'};
        $date =~ s/YEAR/$year/;
        $date =~ s/MONTH/$month/;
        $date =~ s/DAY/$day/;
        $response = $date;
    } ## end else [ if ($old_date =~ / /) ]
    $self->{'debug'}->DEBUG(['End User Get Date']);
    return ($response);
} ## end sub users_get_date

sub users_list {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users List']);
    my $sth = $self->{'dbh'}->prepare(
        q{
              SELECT username,
                     fullname,
                     nickname,
                     accomplishments,
                     retro_systems,
                     birthday,
                     prefer_nickname,
                     location
                FROM users_view
               WHERE banned=FALSE
            ORDER BY username;
        }
    );
    $sth->execute();
    my $columns = $self->{'USER'}->{'max_columns'};
    my $table;
    if ($columns <= 40) {    # Username and Fullname
        $table = Text::SimpleTable->new(10, 36);
        $table->row('USERNAME', 'FULLNAME');
    } elsif ($columns <= 64) {    # Username, Nickname and Fullname
        $table = Text::SimpleTable->new(10, 20, 32);
        $table->row('USERNAME', 'NICKNAME', 'FULLNAME');
    } elsif ($columns <= 80) {    # Username, Nickname, Fullname and Location
        $table = Text::SimpleTable->new(10, 20, 32, 32);
        $table->row('USERNAME', 'NICKNAME', 'FULLNAME', 'LOCATION');
    } elsif ($columns <= 132) {    # Username, Nickname, Fullname, Location, Retro Systems
        $table = Text::SimpleTable->new(10, 20, 30, 30, 40);
        $table->row('USERNAME', 'NICKNAME', 'FULLNAME', 'LOCATION', 'RETRO SYSTEMS');
    } else {                       # Username, Nickname, Fullname, Location, Retro Systems, Birthday and Accomplishments
        $table = Text::SimpleTable->new(10, 20, 32, 32, 40, 5, 100);
        $table->row('USERNAME', 'NICKNAME', 'FULLNAME', 'LOCATION', 'RETRO SYSTEMS', 'BDAY', 'ACCOMPLISHMENTS');
    }
    while (my $results = $sth->fetchrow_hashref()) {
        $table->hr;
        my $preferred = ($results->{'prefer_nickname'}) ? $results->{'nickname'} : $results->{'fullname'};
        if ($columns <= 40) {    # Username and Fullname
            $table->row(sprintf('%-10s', $results->{'username'}), sprintf('%-36s', $preferred));
        } elsif ($columns <= 64) {    # Username, Nickname and Fullname
            $table->row(sprintf('%-10s', $results->{'username'}), sprintf('%-20s', $results->{'nickname'}), sprintf('%-32s', $preferred));
        } elsif ($columns <= 80) {    # Username, Nickname, Fullname and Location
            $table->row(sprintf('%-10s', $results->{'username'}), sprintf('%-20s', $results->{'nickname'}), sprintf('%-32s', $preferred), sprintf('%-32s', $results->{'location'}));
        } elsif ($columns <= 132) {    # Username, Nickname, Fullname, Location, Retro Systems
            $table->row(sprintf('%-10s', $results->{'username'}), sprintf('%-20s', $results->{'nickname'}), sprintf('%-30s', $preferred), sprintf('%-30s', $results->{'location'}), sprintf('%-40s', $results->{'retro_systems'}));
        } else {                       # Username, Nickname, Fullname, Location, Retro Systems, Birthday and Accomplishments
            my ($year, $month, $day) = split('-', $results->{'birthday'});
            $table->row(sprintf('%-10s', $results->{'username'}), sprintf('%-20s', $results->{'nickname'}), sprintf('%-32s', $preferred), sprintf('%-32s', $results->{'location'}), sprintf('%-40s', $results->{'retro_systems'}), sprintf('%02d/%02d', $month, $day), sprintf('%-100s', $results->{'accomplishments'}));
        }
    } ## end while (my $results = $sth...)
    $sth->finish;
    my $text;
    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ANSI') {
        $text = $table->boxes2('GREEN')->draw();
        foreach my $orig ('USERNAME', 'NICKNAME', 'FULLNAME', 'LOCATION', 'RETRO SYSTEMS', 'BDAY', 'ACCOMPLISHMENTS') {
            my $ch = '[% BRIGHT YELLOW %]' . $orig . '[% RESET %]';
            $text =~ s/$orig/$ch/gs;
        }
    } elsif ($mode eq 'ATASCII') {
        $text = $self->color_border($table->boxes->draw(), '');
    } elsif ($mode eq 'PETSCII') {
        $text = $table->boxes->draw();
        foreach my $orig ('USERNAME', 'NICKNAME', 'FULLNAME', 'LOCATION', 'RETRO SYSTEMS', 'BDAY', 'ACCOMPLISHMENTS') {
            my $ch = '[% YELLOW %]' . $orig . '[% RESET %]';
            $text =~ s/$orig/$ch/gs;
        }
        $text = $self->color_border($text, 'GREEN');
    } else {
        $text = $table->draw();
    }
    $self->{'debug'}->DEBUG(['End Users List']);
    return ($text);
} ## end sub users_list

sub users_add {
    my $self          = shift;
    my $user_template = shift;

    $self->{'debug'}->DEBUG(['Start Users Add']);
    $self->{'debug'}->DEBUGMAX([$user_template]);
    $self->{'dbh'}->begin_work;
    my $sth = $self->{'dbh'}->prepare(
        q{
            INSERT INTO users (
                username,
                given,
                family,
                nickname,
                email,
                accomplishments,
                retro_systems,
                birthday,
                location,
                baud_rate,
                text_mode,
                password)
              VALUES (?,?,?,?,?,?,?,DATE(?),?,?,(SELECT text_modes.id FROM text_modes WHERE text_modes.text_mode=?),SHA2(?,512))
        }
    );
    $sth->execute($user_template->{'username'}, $user_template->{'given'}, $user_template->{'family'}, $user_template->{'nickname'}, $user_template->{'email'}, $user_template->{'accomplishments'}, $user_template->{'retro_systems'}, $user_template->{'birthday'}, $user_template->{'location'}, $user_template->{'baud_rate'}, $user_template->{'text_mode'}, $user_template->{'password'},);
    $sth->finish;
    $sth = $self->{'dbh'}->prepare(
        q{
            INSERT INTO permissions (
                id,
                prefer_nickname,
                view_files,
                upload_files,
                download_files,
                remove_files,
                read_message,
                show_email,
                post_message,
                remove_message,
                sysop,
                play_fortunes,
                timeout)
              VALUES (LAST_INSERT_ID(),?,?,?,?,?,?,?,?,?,?,?,?,?);
        }
    );
    $sth->execute($user_template->{'prefer_nickname'}, $user_template->{'view_files'}, $user_template->{'upload_files'}, $user_template->{'download_files'}, $user_template->{'remove_files'}, $user_template->{'read_message'}, $user_template->{'show_email'}, $user_template->{'post_message'}, $user_template->{'remove_message'}, $user_template->{'sysop'}, $user_template->{'play_fortunes'}, $user_template->{'timeout'},);
    my $response;

    if ($self->{'dbh'}->err) {
        $self->{'dbh'}->rollback;
        $sth->finish();
        $response = FALSE;
    } else {
        $self->{'dbh'}->commit;
        $sth->finish();
        $response = TRUE;
    }
    $self->{'debug'}->DEBUG(['End Users Add']);
    return ($response);
} ## end sub users_add

sub users_delete {
    my $self = shift;
    my $id   = shift;

    $self->{'debug'}->DEBUG(['Start Users Delete']);
    if ($id == 1) {
        $self->{'debug'}->ERROR(['  Attempt to delete SysOp user']);
        return (FALSE);
    }
    $self->{'debug'}->WARNING(["  Delete user $id"]);
    $self->{'dbh'}->begin_work();
    my $sth = $self->{'dbh'}->prepare('DELETE FROM permissions WHERE id=?');
    $sth->execute($id);
    if ($self->{'dbh'}->err) {
        $self->{'debug'}->ERROR([$self->{'dbh'}->errstr]);
        $self->{'dbh'}->rollback();
        $sth->finish();
        $self->{'debug'}->DEBUG(['   End Users Delete']);
        return (FALSE);
    } else {
        $sth->finish();
        $sth = $self->{'dbh'}->prepare('DELETE FROM users WHERE id=?');
        $sth->execute($id);
        if ($self->{'dbh'}->err) {
            $self->{'debug'}->ERROR([$self->{'dbh'}->errstr]);
            $self->{'dbh'}->rollback();
            $sth->finish();
            $self->{'debug'}->DEBUG(['   End Users Delete']);
            return (FALSE);
        } else {
            $self->{'dbh'}->commit();
            $sth->finish();
            $self->{'debug'}->DEBUG(['   End Users Delete']);
            return (TRUE);
        } ## end else [ if ($self->{'dbh'}->err)]
    } ## end else [ if ($self->{'dbh'}->err)]
    $self->{'debug'}->DEBUG(['End Users Delete']);
} ## end sub users_delete

sub users_file_category {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users File Category']);
    my $sth = $self->{'dbh'}->prepare('SELECT description FROM file_categories WHERE id=?');
    $sth->execute($self->{'USER'}->{'file_category'});
    my ($category) = ($sth->fetchrow_array());
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Users File Category']);
    if ($self->{'USER'}->{'text_mode'} eq 'ANSI') {
        $category = $self->news_title_colorize($category);
    }
    return ($category);
} ## end sub users_file_category

sub users_forum_category {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Forum Category']);
    my $sth = $self->{'dbh'}->prepare('SELECT description FROM message_categories WHERE id=?');
    $sth->execute($self->{'USER'}->{'forum_category'});
    my ($category) = ($sth->fetchrow_array());
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Users Forum Category']);
    return ($category);
} ## end sub users_forum_category

sub users_rss_category {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users RSS Category']);
    my $sth = $self->{'dbh'}->prepare('SELECT title FROM rss_feed_categories WHERE id=?');
    $sth->execute($self->{'USER'}->{'rss_category'});
    my ($category) = ($sth->fetchrow_array());
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Users RSS Category']);
    return ($category);
} ## end sub users_rss_category

sub users_find {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start Users Find']);
    $self->{'debug'}->DEBUG(['End Users Find']);
    return (TRUE);
} ## end sub users_find

sub users_count {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Count']);
    my $sth = $self->{'dbh'}->prepare('SELECT COUNT(*) FROM users');
    $sth->execute();
    my ($count) = ($sth->fetchrow_array());
    $sth->finish();
    $self->{'debug'}->DEBUG(['End Users Count']);
    return ($count);
} ## end sub users_count

sub users_info {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start Users Info']);
    my $table;
    my $text  = '';
    my $width = 1;

    foreach my $field (keys %{ $self->{'USER'} }) {
        $width = max($width, length($self->{'USER'}->{$field}));
    }

    my $columns = $self->{'USER'}->{'max_columns'};
    $self->{'debug'}->DEBUG(["  $columns Columns"]);
    if ($columns <= 40) {
        $table = sprintf('%-15s=%-25s', 'FIELD', 'VALUE') . "\n";
        $table .= '-' x $self->{'USER'}->{'max_columns'} . "\n";
        $table .= sprintf('%-15s=%-25s', 'ACCOUNT NUMBER',  $self->{'USER'}->{'id'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'USERNAME',        $self->{'USER'}->{'username'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'FULL NAME',       $self->{'USER'}->{'fullname'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'NICKNAME',        $self->{'USER'}->{'nickname'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'EMAIL',           $self->{'USER'}->{'email'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'DATE FORMAT',     $self->{'USER'}->{'date_format'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'SCREEN',          $self->{'USER'}->{'max_columns'} . 'x' . $self->{'USER'}->{'max_rows'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'BIRTHDAY',        $self->users_get_date($self->{'USER'}->{'birthday'})) . "\n";
        $table .= sprintf('%-15s=%-25s', 'LOCATION',        $self->{'USER'}->{'location'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'BAUD RATE',       $self->{'USER'}->{'baud_rate'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'LAST LOGIN',      $self->{'USER'}->{'login_time'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'LAST LOGOUT',     $self->{'USER'}->{'logout_time'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'TEXT MODE',       $self->{'USER'}->{'text_mode'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'IDLE TIMEOUT',    $self->{'USER'}->{'timeout'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'SHOW EMAIL',      $self->yes_no($self->{'USER'}->{'show_email'},      FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'PREFER NICKNAME', $self->yes_no($self->{'USER'}->{'prefer_nickname'}, FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'VIEW FILES',      $self->yes_no($self->{'USER'}->{'view_files'},      FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'UPLOAD FILES',    $self->yes_no($self->{'USER'}->{'upload_files'},    FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'DOWNLOAD FILES',  $self->yes_no($self->{'USER'}->{'download_files'},  FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'REMOVE FILES',    $self->yes_no($self->{'USER'}->{'remove_files'},    FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'READ MESSAGES',   $self->yes_no($self->{'USER'}->{'read_message'},    FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'POST MESSAGES',   $self->yes_no($self->{'USER'}->{'post_message'},    FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'REMOVE MESSAGES', $self->yes_no($self->{'USER'}->{'remove_message'},  FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'PLAY FORTUNES',   $self->yes_no($self->{'USER'}->{'play_fortunes'},   FALSE)) . "\n";
        $table .= sprintf('%-15s=%-25s', 'ACCESS LEVEL',    $self->{'USER'}->{'access_level'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'RETRO SYSTEMS',   $self->{'USER'}->{'retro_systems'}) . "\n";
        $table .= sprintf('%-15s=%-25s', 'ACCOMPLISHMENTS', $self->{'USER'}->{'accomplishments'}) . "\n";
    } elsif ((($width + 22) * 2) <= $columns) {
        $table = Text::SimpleTable->new(15, $width, 15, $width);
        $table->row('FIELD', 'VALUE', 'FIELD', 'VALUE');
        $table->hr();
        $table->row('ACCOUNT NUMBER',  $self->{'USER'}->{'id'},                                    'USERNAME',        $self->{'USER'}->{'username'});
        $table->row('FULLNAME',        $self->{'USER'}->{'fullname'},                              'NICKNAME',        $self->{'USER'}->{'nickname'});
        $table->row('EMAIL',           $self->{'USER'}->{'email'},                                 'SCREEN',          $self->{'USER'}->{'max_columns'} . 'x' . $self->{'USER'}->{'max_rows'});
        $table->row('BIRTHDAY',        $self->users_get_date($self->{'USER'}->{'birthday'}),       'LOCATION',        $self->{'USER'}->{'location'});
        $table->row('BAUD RATE',       $self->{'USER'}->{'baud_rate'},                             'LAST LOGIN',      $self->users_get_date($self->{'USER'}->{'login_time'}));
        $table->row('DATE FORMAT',     $self->{'USER'}->{'date_format'},                           'LAST LOGOUT',     $self->users_get_date($self->{'USER'}->{'logout_time'}));
        $table->row('IDLE TIMEOUT',    $self->{'USER'}->{'timeout'},                               'TEXT MODE',       $self->{'USER'}->{'text_mode'});
        $table->row('PREFER NICKNAME', $self->yes_no($self->{'USER'}->{'prefer_nickname'}, FALSE), 'VIEW FILES',      $self->yes_no($self->{'USER'}->{'view_files'}, FALSE));
        $table->row('UPLOAD FILES',    $self->yes_no($self->{'USER'}->{'upload_files'}, FALSE),    'DOWNLOAD FILES',  $self->yes_no($self->{'USER'}->{'download_files'}, FALSE));
        $table->row('REMOVE FILES',    $self->yes_no($self->{'USER'}->{'remove_files'}, FALSE),    'READ MESSAGES',   $self->yes_no($self->{'USER'}->{'read_message'}, FALSE));
        $table->row('POST MESSAGES',   $self->yes_no($self->{'USER'}->{'post_message'}, FALSE),    'REMOVE MESSAGES', $self->yes_no($self->{'USER'}->{'remove_message'}, FALSE));
        $table->row('SHOW EMAIL',      $self->yes_no($self->{'USER'}->{'show_email'}, FALSE),      'ACCESS LEVEL',    $self->{'USER'}->{'access_level'});
		$table->row('PLAY FORTUNES',   $self->yes_no($self->{'USER'}->{'play_fortunes'}, FALSE),   'ACCOMPLISHMENTS', $self->{'USER'}->{'accomplishments'});
		$table->row('RETRO SYSTEMS',   $self->{'USER'}->{'retro_systems'},'','');
    } else {
        $width = min($width + 7, $self->{'USER'}->{'max_columns'} - 7);
        $table = Text::SimpleTable->new(15, $width);
        $table->row('FIELD', 'VALUE');
        $table->hr();
        $table->row('ACCOUNT NUMBER',  $self->{'USER'}->{'id'});
        $table->row('USERNAME',        $self->{'USER'}->{'username'});
        $table->row('FULLNAME',        $self->{'USER'}->{'fullname'});
        $table->row('NICKNAME',        $self->{'USER'}->{'nickname'});
        $table->row('EMAIL',           $self->{'USER'}->{'email'});
        $table->row('DATE FORMAT',     $self->{'USER'}->{'date_format'});
        $table->row('SCREEN',          $self->{'USER'}->{'max_columns'} . 'x' . $self->{'USER'}->{'max_rows'});
        $table->row('BIRTHDAY',        $self->users_get_date($self->{'USER'}->{'birthday'}));
        $table->row('LOCATION',        $self->{'USER'}->{'location'});
        $table->row('BAUD RATE',       $self->{'USER'}->{'baud_rate'});
        $table->row('LAST LOGIN',      $self->{'USER'}->{'login_time'});
        $table->row('LAST LOGOUT',     $self->{'USER'}->{'logout_time'});
        $table->row('TEXT MODE',       $self->{'USER'}->{'text_mode'});
        $table->row('IDLE TIMEOUT',    $self->{'USER'}->{'timeout'});
        $table->row('SHOW EMAIL',      $self->yes_no($self->{'USER'}->{'show_email'},      FALSE));
        $table->row('PREFER NICKNAME', $self->yes_no($self->{'USER'}->{'prefer_nickname'}, FALSE));
        $table->row('VIEW FILES',      $self->yes_no($self->{'USER'}->{'view_files'},      FALSE));
        $table->row('UPLOAD FILES',    $self->yes_no($self->{'USER'}->{'upload_files'},    FALSE));
        $table->row('DOWNLOAD FILES',  $self->yes_no($self->{'USER'}->{'download_files'},  FALSE));
        $table->row('REMOVE FILES',    $self->yes_no($self->{'USER'}->{'remove_files'},    FALSE));
        $table->row('READ MESSAGES',   $self->yes_no($self->{'USER'}->{'read_message'},    FALSE));
        $table->row('POST MESSAGES',   $self->yes_no($self->{'USER'}->{'post_message'},    FALSE));
        $table->row('REMOVE MESSAGES', $self->yes_no($self->{'USER'}->{'remove_message'},  FALSE));
        $table->row('PLAY FORTUNES',   $self->yes_no($self->{'USER'}->{'play_fortunes'},   FALSE));
        $table->row('ACCESS LEVEL',    $self->{'USER'}->{'access_level'});
        $table->row('RETRO SYSTEMS',   $self->{'USER'}->{'retro_systems'});
        $table->row('ACCOMPLISHMENTS', $self->{'USER'}->{'accomplishments'});
    } ## end else [ if ($columns <= 40) ]

    my $mode = $self->{'USER'}->{'text_mode'};
    if ($mode eq 'ATASCII') {
        $text = $self->color_border($table->boxes->draw(), 'WHITE');
    } elsif ($mode eq 'ANSI') {
        $text = $table->boxes2('RGB 0,90,190')->draw();
        my $no    = colored(['red'],           'NO');
        my $yes   = colored(['green'],         'YES');
        my $field = colored(['bright_yellow'], 'FIELD');
        my $va    = colored(['bright_yellow'], 'VALUE');
        $text =~ s/ FIELD / $field /gs;
        $text =~ s/ VALUE / $va /gs;
        $text =~ s/ NO / $no /gs;
        $text =~ s/ YES / $yes /gs;

        foreach $field ('PLAY FORTUNES', 'ACCESS LEVEL', 'SUFFIX', 'ACCOUNT NUMBER', 'USERNAME', 'FULLNAME', 'SCREEN', 'BIRTHDAY', 'LOCATION', 'BAUD RATE', 'LAST LOGIN', 'LAST LOGOUT', 'TEXT MODE', 'IDLE TIMEOUT', 'RETRO SYSTEMS', 'ACCOMPLISHMENTS', 'SHOW EMAIL', 'PREFER NICKNAME', 'VIEW FILES', 'UPLOAD FILES', 'DOWNLOAD FILES', 'REMOVE FILES', 'READ MESSAGES', 'POST MESSAGES', 'REMOVE MESSAGES', 'EMAIL', 'NICKNAME', 'DATE FORMAT') {
            my $ch = colored(['yellow'], $field);
            $text =~ s/$field/$ch/gs;
        }
    } elsif ($mode eq 'PETSCII') {
        $text = $table->boxes->draw();
        my $no    = '[% RED %]NO[% RESET %]';
        my $yes   = '[% GREEN %]YES[% RESET %]';
        my $field = '[% YELLOW %]FIELD[% RESET %]';
        my $va    = '[% YELLOW %]VALUE[% RESET %]';
        $text =~ s/ FIELD / $field /gs;
        $text =~ s/ VALUE / $va /gs;
        $text =~ s/ NO / $no /gs;
        $text =~ s/ YES / $yes /gs;

        foreach $field ('PLAY FORTUNES', 'ACCESS LEVEL', 'SUFFIX', 'ACCOUNT NUMBER', 'USERNAME', 'FULLNAME', 'SCREEN', 'BIRTHDAY', 'LOCATION', 'BAUD RATE', 'LAST LOGIN', 'LAST LOGOUT', 'TEXT MODE', 'IDLE TIMEOUT', 'RETRO SYSTEMS', 'ACCOMPLISHMENTS', 'SHOW EMAIL', 'PREFER NICKNAME', 'VIEW FILES', 'UPLOAD FILES', 'DOWNLOAD FILES', 'REMOVE FILES', 'READ MESSAGES', 'POST MESSAGES', 'REMOVE MESSAGES', 'EMAIL', 'NICKNAME', 'DATE FORMAT') {
            my $ch = '[% BROWN %]' . $field . '[% RESET %]';
            $text =~ s/$field/$ch/gs;
        }
        $text = $self->color_border($text, 'BLUE');
    } else {
        $text = $table->draw();
    }
    $self->{'debug'}->DEBUG(['End Users Info']);
    return ($text);
} ## end sub users_info

 

# MANUAL IMPORT HERE #

1;
