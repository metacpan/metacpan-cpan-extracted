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

    # VERSIONS #
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

# MANUAL IMPORT HERE #

1;
