# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap::Plugins::Mail Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

# Class name  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
package ASNMTAP::Asnmtap::Plugins::Mail;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(carp cluck);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

no warnings 'deprecated';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(:_HIDDEN %ERRORS %TYPE);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Plugins::Mail::ISA         = qw(Exporter);

  %ASNMTAP::Asnmtap::Plugins::Mail::EXPORT_TAGS = ( ALL => [ qw() ] );

  @ASNMTAP::Asnmtap::Plugins::Mail::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::Mail::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Plugins::Mail::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

# Constructor & initialisation  - - - - - - - - - - - - - - - - - - - - -

sub new (@) {
  my $classname = shift;

  unless ( defined $classname ) { my @c = caller; die "Syntax error: Class name expected after new at $c[1] line $c[2]\n" }
  if ( ref $classname) { my @c = caller; die "Syntax error: Can't construct new ".ref($classname)." from another object at $c[1] line $c[2]\n" }

  my $self = {};

  my @parameters = (_asnmtapInherited   => undef,
                    _SMTP               => 
                      { 
                        smtp            => 'localhost',
                        port            => 25,
                        retries         => 3,
                        delay           => 1,
                        mime            => 0,
                        tz              => undef,
                        debug           => 0
					  },
                    _IMAP4              =>
                      {
                        imap4           => undef,
                        port            => 143,
                        username        => undef,
                        password        => undef,
                        timeout         => 120,
                        debug           => 0
                      },
                    _POP3               =>
                      {
                        pop3            => undef,
                        port            => 110,
                        username        => undef,
                        password        => undef,
                        timeout         => 120,
                        debug           => 0
                      },
                    _mailType           => 0,
                    _text               => 
                      {
                        SUBJECT         => 'uKey=ASNMTAP',
                        from            => 'From:',
                        to              => 'To:',
                        subject         => 'Subject:',
                        status          => 'Status'
                      },
                    _mail               => 
                      {
                        from            => undef,
                        to              => undef,
                        status          => undef,
                        body            => undef
                      }
                    );

  if ( $] < 5.010000 ) {
    eval "use fields";
    $self = fields::phash (@parameters);
  } else {
    use ASNMTAP::PseudoHash;

    $self = do {
      my @array = undef;

      while (my ($k, $v) = splice(@parameters, 0, 2)) {
        $array[$array[0]{$k} = @array] = $v;
      }

      bless(\@array, $classname);
    };
  }

  my %args = @_;

  $self->{_asnmtapInherited}        = $args{_asnmtapInherited}      if ( exists $args{_asnmtapInherited} );

  if ( exists $args{_SMTP} ) {
    $self->{_SMTP}->{smtp}          = $args{_SMTP}->{smtp}          if ( exists $args{_SMTP}->{smtp} );
    $self->{_SMTP}->{port}          = $args{_SMTP}->{port}          if ( exists $args{_SMTP}->{port} );
    $self->{_SMTP}->{retries}       = $args{_SMTP}->{retries}       if ( exists $args{_SMTP}->{retries} );
    $self->{_SMTP}->{delay}         = $args{_SMTP}->{delay}         if ( exists $args{_SMTP}->{delay} );
    $self->{_SMTP}->{mime}          = $args{_SMTP}->{mime}          if ( exists $args{_SMTP}->{mime} );
    $self->{_SMTP}->{tz}            = $args{_SMTP}->{tz}            if ( exists $args{_SMTP}->{tz} );
    $self->{_SMTP}->{debug}         = $args{_SMTP}->{debug}         if ( exists $args{_SMTP}->{debug} );
  }

  if ( exists $args{_IMAP4} ) {
    $self->{_IMAP4}->{imap4}        = $args{_IMAP4}->{imap4}        if ( exists $args{_IMAP4}->{imap4} );
    $self->{_IMAP4}->{port}         = $args{_IMAP4}->{port}         if ( exists $args{_IMAP4}->{port} );
    $self->{_IMAP4}->{username}     = $args{_IMAP4}->{username}     if ( exists $args{_IMAP4}->{username} );
    $self->{_IMAP4}->{password}     = $args{_IMAP4}->{password}     if ( exists $args{_IMAP4}->{password} );
    $self->{_IMAP4}->{timeout}      = $args{_IMAP4}->{timeout}      if ( exists $args{_IMAP4}->{timeout} );
    $self->{_IMAP4}->{debug}        = $args{_IMAP4}->{debug}        if ( exists $args{_IMAP4}->{debug} );
  }

  if ( exists $args{_POP3} ) {
    $self->{_POP3}->{pop3}          = $args{_POP3}->{pop3}          if ( exists $args{_POP3}->{pop3} );
    $self->{_POP3}->{port}          = $args{_POP3}->{port}          if ( exists $args{_POP3}->{port} );
    $self->{_POP3}->{username}      = $args{_POP3}->{username}      if ( exists $args{_POP3}->{username} );
    $self->{_POP3}->{password}      = $args{_POP3}->{password}      if ( exists $args{_POP3}->{password} );
    $self->{_POP3}->{timeout}       = $args{_POP3}->{timeout}       if ( exists $args{_POP3}->{timeout} );
    $self->{_POP3}->{debug}         = $args{_POP3}->{debug}         if ( exists $args{_POP3}->{debug} );
  }

  $self->{_mailType}                = $args{_mailType}              if ( exists $args{_mailType} );

  if ( exists $args{_text} ) {
    $self->{_text}->{SUBJECT}       = $args{_text}->{SUBJECT}       if ( exists $args{_text}->{SUBJECT} );
    $self->{_text}->{from}          = $args{_text}->{from}          if ( exists $args{_text}->{from} );
    $self->{_text}->{to}            = $args{_text}->{to}            if ( exists $args{_text}->{to} );
    $self->{_text}->{subject}       = $args{_text}->{subject}       if ( exists $args{_text}->{subject} );
    $self->{_text}->{status}        = $args{_text}->{status}        if ( exists $args{_text}->{status} );
  }

  if ( exists $args{_mail} ) {
    $self->{_mail}->{from}          = $args{_mail}->{from}          if ( exists $args{_mail}->{from} );
    $self->{_mail}->{to}            = $args{_mail}->{to}            if ( exists $args{_mail}->{to} );
    $self->{_mail}->{status}        = $args{_mail}->{status}        if ( exists $args{_mail}->{status} );
    $self->{_mail}->{body}          = $args{_mail}->{body}          if ( exists $args{_mail}->{body} );
  }

  bless ($self, $classname);
  $self->_init();
  return ($self);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _init {
  my $asnmtapInherited = $_[0]->{_asnmtapInherited};
  unless ( defined $asnmtapInherited ) { cluck ( 'ASNMTAP::Asnmtap::Plugins::Mail: asnmtapInherited missing' ); exit $ERRORS{UNKNOWN} }

  carp ('ASNMTAP::Asnmtap::Pluginw::MAIL: _init') if ( $$asnmtapInherited->{_debug} );

  unless ( defined $$asnmtapInherited->{_programName} and $$asnmtapInherited->{_programName} ne 'NOT DEFINED' ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing parent object attribute mName' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $$asnmtapInherited->{_programDescription} and $$asnmtapInherited->{_programDescription} ne 'NOT DEFINED' ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing parent object attribute mDescription' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $$asnmtapInherited->getOptionsArgv('environment') ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing parent object command line option -e|--environment' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my %environment = ( P => 'PROD', S => 'SIM', A => 'ACC', T => 'TEST', D => 'DEV', L => 'LOCAL' );
  $_[0]->[ $_[0]->[0]{_environment_} = @{$_[0]} ] = $environment { $$asnmtapInherited->getOptionsArgv('environment') };

  if ( $$asnmtapInherited->getOptionsValue ('debug') ) {
    $_[0]->{_SMTP}->{debug}  = $$asnmtapInherited->getOptionsValue ('debug') if ( $_[0]->{_SMTP}->{debug}  < $$asnmtapInherited->getOptionsValue ('debug') );
    $_[0]->{_POP3}->{debug}  = $$asnmtapInherited->getOptionsValue ('debug') if ( $_[0]->{_POP3}->{debug}  < $$asnmtapInherited->getOptionsValue ('debug') );
    $_[0]->{_IMAP4}->{debug} = $$asnmtapInherited->getOptionsValue ('debug') if ( $_[0]->{_IMAP4}->{debug} < $$asnmtapInherited->getOptionsValue ('debug') );
  }

  $_[0]->{_POP3}->{timeout}  = $$asnmtapInherited->timeout() if ( $_[0]->{_POP3}->{timeout} == 120 );

  $_[0]->{_IMAP4}->{timeout} = $$asnmtapInherited->timeout() if ( $_[0]->{_IMAP4}->{timeout} == 120 );

  unless ($_[0]->{_mailType} =~ /^[01]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Parameter _mailType must be 0 or 1' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $_[0]->{_mail}->{from} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing MAIL parameter _mail => {from => ...}' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $_[0]->{_mail}->{to} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing MAIL parameter _mail => {to => ...}' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $_[0]->{_mail}->{status} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing MAIL parameter _mail => {status => ...}' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $_[0]->{_mail}->{body} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing MAIL parameter _mail => {body => ...}' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  $_[0]->[ $_[0]->[0]{_subject_} = @{$_[0]} ] = $_[0]->{_text}->{SUBJECT} .' / '. $_[0]->{_text}->{from} .' '. $_[0]->{_mail}->{from} .' '. $_[0]->{_text}->{to} .' '. $_[0]->{_mail}->{to};

  unless ( $_[0]->{_mailType} ) {
    $_[0]->[ $_[0]->[0]{_branding_}  = @{$_[0]} ] = '<'. $$asnmtapInherited->{_programName} .'> <'. $$asnmtapInherited->{_programDescription} .'>';
    $_[0]->[ $_[0]->[0]{_timestamp_} = @{$_[0]} ] = 'Timestamp <'. $_[0]->{_mail}->{from} .'>:';
    $_[0]->[ $_[0]->[0]{_status_}    = @{$_[0]} ] = $_[0]->{_text}->{status} .' <'. $_[0]->{_mail}->{status} .'>';
  }

  if ( $$asnmtapInherited->{_debug} ) {
    use Data::Dumper;
    print "\n". ref ($_[0]) .": Now we'll dump data\n\n", Dumper ( $_[0] ), "\n\n";
  }
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub sending_fingerprint_mail {
  my $self = shift; &_checkAccObjRef ( $self ); 

  my $asnmtapInherited = $self->{_asnmtapInherited};
  return ( $$asnmtapInherited->pluginValue ('stateValue') ) unless ( exists $self->{_subject_} );

  my %defaults = ( perfdataLabel => undef );
  my %parms = (%defaults, @_);

  $$asnmtapInherited->setEndTime_and_getResponsTime ( $$asnmtapInherited->pluginValue ('endTime') ) if ( defined $parms{perfdataLabel} );

  use Mail::Sendmail qw(sendmail %mailcfg);
  $mailcfg {smtp}    = $self->{_SMTP}->{smtp};
  $mailcfg {port}    = $self->{_SMTP}->{port};
  $mailcfg {retries} = $self->{_SMTP}->{retries};
  $mailcfg {delay}   = $self->{_SMTP}->{delay};
  $mailcfg {mime}    = $self->{_SMTP}->{mime};
  $mailcfg {tz}      = $self->{_SMTP}->{tx} if ( defined $self->{_SMTP}->{tx} );
  $mailcfg {debug}   = $$asnmtapInherited->getOptionsValue ('debug');

  my $message;

  if ( $self->{_mailType} ) {
    use Time::Local;
    my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin, $currentSec) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1,0]);
    my $mailEpochtime = timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);
    $message = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE FingerprintEmail SYSTEM \"dtd/FingerprintEmail-1.0.dtd\"><FingerprintEmail><Schema Value=\"1.0\"/><Fingerprint From=\"". $self->{_mail}->{from} ."\" To=\"". $self->{_mail}->{to} ."\" Destination=\"ASNMTAP\" Plugin=\"". $$asnmtapInherited->{_programName} ."\" Description=\"". $$asnmtapInherited->{_programDescription} ."\" Environment=\"". $self->{_environment_} ."\" Date=\"$currentYear/$currentMonth/$currentDay\" Time=\"$currentHour:$currentMin:$currentSec\" Epochtime=\"$mailEpochtime\" Status=\"". $self->{_mail}->{status} ."\" /></FingerprintEmail>\n";
  } else {
    use ASNMTAP::Time qw(&get_datetimeSignal);
    $message = $self->{_subject_} ."\n". $self->{_branding_} ."\n". $self->{_timestamp_} .' '. get_datetimeSignal() ."\n". $self->{_status_} ."\n";
  }

  $message .= $self->{_mail}->{body} ."\n";
  my %mail = ( To => $self->{_mail}->{to}, From => $self->{_mail}->{from}, Subject => $self->{_subject_}, Message => $message );

  my $returnCode = (sendmail %mail) ? $ERRORS{OK} : $ERRORS{CRITICAL};
  $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => ( defined $parms{perfdataLabel} ? $parms{perfdataLabel} : 'email send' ) . ( $returnCode ? ' failed' : '' ) }, $TYPE{APPEND} );

  if ( defined $parms{perfdataLabel} ) {
    my $responseTime = $$asnmtapInherited->setEndTime_and_getResponsTime ( $$asnmtapInherited->pluginValue ('endTime') );
    $$asnmtapInherited->appendPerformanceData ( "'". $parms{perfdataLabel} ."'=". $responseTime .'ms;;;;' );
  }

  print "\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log, "\n" if ( $$asnmtapInherited->getOptionsValue ('debug') );
  return ( $returnCode );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub receiving_fingerprint_mails {
  my $self = shift; &_checkAccObjRef ( $self ); 

  my $asnmtapInherited = $self->{_asnmtapInherited};
  return ( $$asnmtapInherited->pluginValue ('stateValue') ) unless ( exists $self->{_subject_} );

  my %defaults = ( custom           => undef,
                   customArguments  => undef,
                   checkFingerprint => 1,
                   receivedState    => 0,
                   outOfDate        => undef,
                   perfdataLabel    => undef
                 );
			 
  my %parms = (%defaults, @_);

  if ( $self->{_mailType} ) {
    unless ( defined $parms{outOfDate} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing MAIL receiving_fingerprint_mails parameter {outOfDate => ...}' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  }

  use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);

  $self->[ $self->[0]{defaultArguments} = @{$self} ] = { date => undef, day => undef, month => undef, year => undef, time => undef, hour => undef, min => undef, sec => undef, numberOfMatches => undef, result => undef };

  unless ($parms{checkFingerprint} =~ /^[01]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Parameter checkFingerprint must be 0 or 1' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ($parms{receivedState} =~ /^[01]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Parameter receivedState must be 0 or 1' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my ($numberOfMails, $email);

  if ( defined $self->{_IMAP4}->{imap4} ) {
    unless ( defined $self->{_IMAP4}->{username} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing Mail IMAP4 parameter username' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    unless ( defined $self->{_IMAP4}->{password} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing Mail IMAP4 parameter password' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    use Net::IMAP::Simple;
    $email = Net::IMAP::Simple->new ( $self->{_IMAP4}->{imap4}, port => $self->{_IMAP4}->{port}, timeout => $self->{_IMAP4}->{timeout} );
 
    unless ( defined $email ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Cannot connect to IMAP4 server: $self->{_IMAP4}->{imap4}, $Net::IMAP::Simple::errstr" }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
 
    unless ( $email->login( $self->{_IMAP4}->{username}, $self->{_IMAP4}->{password} ) ){
      my $errstr = $email->errstr; $errstr =~ s/[\n\r]/ /g; $errstr =~ s/ +$//g; 
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Cannot login to IMAP4 server: $self->{_IMAP4}->{imap4}, $errstr" }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    $numberOfMails = $email->select ( 'INBOX' );

    unless ( defined $numberOfMails ) {
      my $errstr = $email->errstr; $errstr =~ s/[\n\r]/ /g; $errstr =~ s/ +$//g; 
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Cannot select my INBOX on IMAP4 server: $self->{_IMAP4}->{imap4}, $errstr" }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  } elsif ( defined $self->{_POP3}->{pop3} ) {
    unless ( defined $self->{_POP3}->{username} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing Mail POP3 parameter username' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    unless ( defined $self->{_POP3}->{password} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing Mail POP3 parameter password' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    use Mail::POP3Client;
    $email = Mail::POP3Client->new ( HOST => $self->{_POP3}->{pop3}, PORT => $self->{_POP3}->{port}, USER => $self->{_POP3}->{username}, PASSWORD => $self->{_POP3}->{password}, TIMEOUT => $self->{_POP3}->{timeout} ); # , DEBUG => ( $self->{_POP3}->{debug} >= 3 ? 1 : 0 ) );

    $numberOfMails = $email->Count();

    unless ( defined $numberOfMails and $numberOfMails != -1 ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Cannot connect/login to POP3 server: $self->{_POP3}->{pop3}" }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  } else {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'NO EMAIL CLIENT SPECIFIED !!!' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }
  
  if ( defined $numberOfMails ) {
    my $returnCode = $ERRORS{DEPENDENT};
    $self->{defaultArguments}->{numberOfMatches} = 0;

    if ( $numberOfMails ) {
      use MIME::Parser;
      my $parser = new MIME::Parser;
      $parser->output_to_core(1);
      $parser->decode_bodies(1);

      use constant HEADER => '<?xml version="1.0" encoding="UTF-8"?>';
      use constant SYSTEM => 'dtd/FingerprintEmail-1.0.dtd';
      use constant FOOTER => '</FingerprintEmail>';
      my $fingerprintXML  = HEADER .'<!DOCTYPE FingerprintEmail SYSTEM "'. SYSTEM .'"><FingerprintEmail>';

      my $debug = $$asnmtapInherited->getOptionsValue ('debug');
      my $label;

      for( my $msgnum = 1; $msgnum <= $numberOfMails; $msgnum++ ) {
        print "\n", ref ($self), "::receiving_fingerprint_mails(): message number $msgnum\n" if ( $debug );
        my ($fromNotFound, $toNotFound, $subjectNotFound, $fingerprintFound) = (1, 1, 1, 3);
        my ($messageNotFound, $brandingNotFound, $timestampNotFound, $statusNotFound, $xmlNotFound) = (0, 0, 0, 0, 0);

        if ( $parms{checkFingerprint} ) {
          $statusNotFound = 1;

          if ( $self->{_mailType} ) {
            ($xmlNotFound, $fingerprintFound) = (1, $fingerprintFound + 2);
          } else {
            ($messageNotFound, $brandingNotFound, $timestampNotFound, $fingerprintFound) = (1, 1, 1, $fingerprintFound + 4);
          }
        }

        $self->{defaultArguments}->{result} = '';

        my $msgbuffer;

        if ( defined $self->{_IMAP4}->{imap4} ) {
          $msgbuffer = $email->top ( $msgnum );
        } elsif ( defined $self->{_POP3}->{pop3} ) {
          $msgbuffer = $email->Head ( $msgnum );
        }

        my $entity = $parser->parse_data( $msgbuffer );
        my $head = $entity->head;
        $head->unfold;

        if ( $debug >= 2 ) {
          print ref ($self), "::receiving_fingerprint_mails(): Header\n", $head->stringify, "\n\n";
          print ref ($self), "::receiving_fingerprint_mails(): MIME-Version: ", $head->get ('MIME-Version'), "\n";
          print ref ($self), "::receiving_fingerprint_mails(): MIME-Type: ", $head->mime_type, "\n";
          print ref ($self), "::receiving_fingerprint_mails(): MIME-Encoding: ", $head->mime_encoding, "\n";
          print ref ($self), "::receiving_fingerprint_mails(): Content-Type Charset: ", $head->mime_attr ('content-type.charset'), "\n"if ( $head->mime_attr('content-type.charset') );
          print ref ($self), "::receiving_fingerprint_mails(): Content-Type Name: ", $head->mime_attr('content-type.name'), "\n" if ( $head->mime_attr('content-type.name') );
          print ref ($self), "::receiving_fingerprint_mails(): Multipart Boundary: ", $head->multipart_boundary, "\n" if ( $head->multipart_boundary );
        }

        print "\n", ref ($self), "::receiving_fingerprint_mails(): HEAD\n" if ($debug);

        foreach my $msgline ( split (/[\n\r]/, $head->stringify) ) {
          next unless ( $msgline );

          if ( $fromNotFound ) {
            if ($msgline =~ /^$self->{_text}->{from}/) {
              print "From .... : $msgline\n" if ($debug);
              $fromNotFound = ( $msgline !~ /^$self->{_text}->{from}\s+$self->{_mail}->{from}/ ? 1 : 0 );
              my $label = $fromNotFound ? '    (?)' : '(match)';
              print "  $label : $self->{_text}->{from} $self->{_mail}->{from}\n" if ($debug);
              unless ( $fromNotFound ) { $fingerprintFound--; next; }
            }
          }

		      if ( $toNotFound ) {
            if ($msgline =~ /^$self->{_text}->{to}/) {
              print "To ...... : $msgline\n" if ($debug);
              $toNotFound = ( $msgline !~ /^$self->{_text}->{to}\s+$self->{_mail}->{to}/ ? 1 : 0  );
              my $label = $toNotFound ? '    (?)' : '(match)';
              print "  $label : $self->{_text}->{to} $self->{_mail}->{to}\n" if ($debug);
              unless ( $toNotFound ) { $fingerprintFound--; next; }
            }
          }

	  	    if ( $subjectNotFound ) {
            if ($msgline =~ /^$self->{_text}->{subject}/) {
              print "Subject . : $msgline\n" if ($debug);
              $subjectNotFound = ( $msgline !~ /^$self->{_text}->{subject}\s+$self->{_subject_}/ ? 1 : 0  );
              my $label = $subjectNotFound ? '    (?)' : '(match)';
              print "  $label : $self->{_text}->{subject} $self->{_subject_}\n" if ($debug);
              unless ( $subjectNotFound ) { $fingerprintFound--; next; }
		        }
          }
        }

        unless ( $fromNotFound or $toNotFound or $subjectNotFound ) {
          print "\n", ref ($self), "::receiving_fingerprint_mails(): BODY\n" if ($debug);

          if ( defined $self->{_IMAP4}->{imap4} ) {
            use Email::Simple;
            my $mail = Email::Simple->new( join ( '', @{ $email->get ( $msgnum ) } ) );
            $msgbuffer = $mail->body;
          } elsif ( defined $self->{_POP3}->{pop3} ) {
            $msgbuffer = $email->Body ( $msgnum );
          }

          use MIME::Decoder;

          unless ( supported MIME::Decoder $head->mime_encoding ) {
            print "MIME .... : '". $head->mime_encoding ."' encoding is not supported!\n" if ($debug );
            $returnCode = $ERRORS{UNKNOWN};
            $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, error => "MIME-Encoding: '". $head->mime_encoding ."' is not supported!" }, $TYPE{APPEND} );
            next;
          }

        # if ( $head->mime_encoding eq 'quoted-printable' or $head->mime_encoding eq '7bit' or $head->mime_encoding eq '8bit' ) { 
          if ( $head->mime_encoding eq '7bit' ) { 
             $msgbuffer = MIME::QuotedPrint::decode($msgbuffer); 
          } else { 
            use IO::String; 
            my $ioIN  = IO::String->new($msgbuffer); 
            my $ioOUT = IO::String->new($msgbuffer); 

            my $decoder = new MIME::Decoder $head->mime_encoding; 
            $decoder->decode($ioIN, $ioOUT); 

            $ioIN->close; 
            $ioOUT->close; 
          }

          if ( $parms{checkFingerprint} ) {
            foreach my $msgline ( split (/[\n\r]/, $msgbuffer) ) {
              next unless ( $msgline );
              last unless ( $self->{_mailType} ? $xmlNotFound : $fingerprintFound );

              if ( $self->{_mailType} ) {
                if ( $msgline =~ /\Q$fingerprintXML\E/ ) {
			      $xmlNotFound = 0; $fingerprintFound--;
  	 	          print "XML ..... : $msgline\n  (match) : $msgline\n" if ( $debug );
                  my ( $returnCode, $xml ) = extract_XML ( asnmtapInherited => $self->{_asnmtapInherited}, resultXML => $msgline, headerXML => HEADER, footerXML => FOOTER, validateDTD => 0, filenameDTD => SYSTEM );

                  unless ( $returnCode ) {
                    if ( $xml->{Fingerprint}{From} =~ /^$self->{_mail}->{from}/ and $xml->{Fingerprint}{To} =~ /^$self->{_mail}->{to}/ and $xml->{Fingerprint}{Destination} eq 'ASNMTAP' and $xml->{Fingerprint}{Plugin} eq $$asnmtapInherited->{_programName} and $xml->{Fingerprint}{Description} eq $$asnmtapInherited->{_programDescription} and $xml->{Fingerprint}{Environment} eq $self->{_environment_} ) {
                      use Date::Calc qw(check_date);

                      $self->{defaultArguments}->{date}  = 0;
                      $self->{defaultArguments}->{year}  = 0;
                      $self->{defaultArguments}->{month} = 0;
                      $self->{defaultArguments}->{day}   = 0;

                      $self->{defaultArguments}->{time}  = 0;
                      $self->{defaultArguments}->{hour}  = 0;
                      $self->{defaultArguments}->{min}   = 0;
                      $self->{defaultArguments}->{sec}   = 0;

                      my $currentTimeslot = timelocal ( (localtime)[0,1,2,3,4,5] );
                      my ($checkEpochtime, $checkDate, $checkTime) = ($xml->{Fingerprint}{Epochtime}, $xml->{Fingerprint}{Date}, $xml->{Fingerprint}{Time});
                      my ($checkYear, $checkMonth, $checkDay) = split (/\/|-/, $checkDate);
                      my ($checkHour, $checkMin, $checkSec) = split (/:/, $checkTime);
                      my $xmlEpochtime = timelocal ( $checkSec, $checkMin, $checkHour, $checkDay, ($checkMonth-1), ($checkYear-1900) );
                      print "$checkEpochtime, $xmlEpochtime ($checkDate, $checkTime), $currentTimeslot - $checkEpochtime = ". ($currentTimeslot - $checkEpochtime) ." > ". $parms{outOfDate} ."\n" if ( $debug );

                      unless ( check_date ( $checkYear, $checkMonth, $checkDay) or check_time($checkHour, $checkMin, $checkSec ) ) {
                        $returnCode = $ERRORS{CRITICAL};
                        $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => "Date or Time into Fingerprint XML are wrong: $checkDate $checkTime" }, $TYPE{APPEND} );
                      } elsif ( $checkEpochtime != $xmlEpochtime ) {
                        $returnCode = $ERRORS{CRITICAL};
                        $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => "Epochtime difference from Date and Time into Fingerprint XML are wrong: $checkEpochtime != $xmlEpochtime ($checkDate $checkTime)" }, $TYPE{APPEND} );
                      } elsif ( $currentTimeslot - $checkEpochtime > $parms{outOfDate} * 2 ) {
                        $returnCode = $ERRORS{CRITICAL};
                        $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => "Result into Fingerprint XML are out of date: $checkDate $checkTime" }, $TYPE{APPEND} );
                      } elsif ( $currentTimeslot - $checkEpochtime > $parms{outOfDate} ) {
                        $returnCode = $ERRORS{WARNING};
                        $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => "Result into Fingerprint XML are out of date: $checkDate $checkTime" }, $TYPE{APPEND} );
                      } else {
 				        ($self->{defaultArguments}->{date}, $self->{defaultArguments}->{time}) = ($checkDate, $checkTime);
                        ($self->{defaultArguments}->{day}, $self->{defaultArguments}->{month}, $self->{defaultArguments}->{year}) = split(/[\/|-]/, $checkDate);
                        ($self->{defaultArguments}->{hour}, $self->{defaultArguments}->{min}, $self->{defaultArguments}->{sec}) = split(/:/, $checkTime);
                      }

                      $statusNotFound = ( $xml->{Fingerprint}{Status} ne $self->{_mail}->{status} );
                      my $label = $statusNotFound ? '    (?)' : '(match)';
                      print "  $label : $self->{_text}->{status} < $self->{_mail}->{status} >\n" if ( $debug );
                      unless ( $statusNotFound ) { $fingerprintFound--; last; }
                    } else {
                      if ( $debug ) {
                        my $label = ( $xml->{Fingerprint}{From} =~ /^$self->{_mail}->{from}/ ? '(match)' : '    (?)' );
                        print "  $label : $self->{_text}->{status} < $self->{_mail}->{status} >\n";
                        $label = ( $xml->{Fingerprint}{From} =~ /^$self->{_mail}->{from}/ ? '(match)' : '    (?)' );
                        print "  $label : From ". $xml->{Fingerprint}{From} ."\n";
                        $label = ( $xml->{Fingerprint}{To} =~ /^$self->{_mail}->{to}/ ? '(match)' : '    (?)' );
                        print "  $label : To ". $xml->{Fingerprint}{To} ."\n";
                        $label = ( $xml->{Fingerprint}{Destination} eq 'ASNMTAP' ? '(match)' : '    (?)' );
                        print "  $label : Destination ". $xml->{Fingerprint}{Destination} ."\n";
                        $label = ( $xml->{Fingerprint}{Plugin} eq $$asnmtapInherited->{_programName} ? '(match)' : '    (?)' );
                        print "  $label : Plugin ". $xml->{Fingerprint}{Plugin} ."\n";
                        $label = ( $xml->{Fingerprint}{Description} eq $$asnmtapInherited->{_programDescription} ? '(match)' : '    (?)' );
                        print "  $label : Description ". $xml->{Fingerprint}{Description} ."\n";
                        $label = ( $xml->{Fingerprint}{Environment} =~ /^$self->{_environment_}/i ? '(match)' : '    (?)' );
                        print "  $label : Environment ". $xml->{Fingerprint}{Environment} ."\n";
                      }

                      last;
                    }
                  }
          
                  next;
                }
              } else {
       		    if ( $messageNotFound ) {
                  if ($msgline =~ /^$self->{_subject_}/) {
      	 	        print "Header .. : $msgline\n  (match) : $msgline\n" if ($debug);
      			    $messageNotFound = 0; $fingerprintFound--; next;
    		      }
                }

    		    if ( $brandingNotFound ) {
                  if ( $msgline =~ /$$asnmtapInherited->{_programName}/ ) {
                    if ( $debug ) {
                      my $msglineDebug = $msgline; $msglineDebug =~ s/</< /g; $msglineDebug =~ s/>/ >/g;
       	              print "Branding  : $msglineDebug\n";
                    }

                    $brandingNotFound = ( $msgline !~ /^$self->{_branding_}/ );
                    my $label = $brandingNotFound ? '    (?)' : '(match)';

                    if ( $debug ) {
                      my $msglineDebug = $msgline; $msglineDebug =~ s/</< /g; $msglineDebug =~ s/>/ >/g;
		              print "  $label : $msglineDebug\n";
                    }

                    unless ( $brandingNotFound ) { $fingerprintFound--; next; }
		          }
                }

	    	    if ( $timestampNotFound ) {
		          if ( $msgline =~ /^$self->{_timestamp_}/ ) {
                    print "Timestamp : $msgline\n" if ( $debug );
                    (undef, $msgline) = split(/:\s+/, $msgline, 2);
                    ($self->{defaultArguments}->{date}, $self->{defaultArguments}->{time}) = split(/\s+/, $msgline);
                    ($self->{defaultArguments}->{year}, $self->{defaultArguments}->{month}, $self->{defaultArguments}->{day}) = split(/[\/-]/, $self->{defaultArguments}->{date});
                    ($self->{defaultArguments}->{hour}, $self->{defaultArguments}->{min}, $self->{defaultArguments}->{sec}) = split(/:/, $self->{defaultArguments}->{time});
                    print '  (match) : ', $self->{_timestamp_}, ' ', $self->{defaultArguments}->{year}, '/', $self->{defaultArguments}->{month}, '/', $self->{defaultArguments}->{day}, ' ', $self->{defaultArguments}->{hour}, ':', $self->{defaultArguments}->{min}, ':', $self->{defaultArguments}->{sec}, "\n"  if ( $debug );
                    $timestampNotFound = 0; $fingerprintFound--; next;
                  }
                }

	    	    if ( $fingerprintFound == 1 and $statusNotFound ) {
      		      if ( $msgline =~ /^$self->{_text}->{status}/ ) {
                    if ( $debug ) {
                      my $msglineDebug = $msgline; $msglineDebug =~ s/</< /g; $msglineDebug =~ s/>/ >/g;
                      print "Status .. : $msglineDebug\n";
                    }

                    $statusNotFound = ( $msgline !~ /^$self->{_text}->{status}\s*<$self->{_mail}->{status}>/ );
                    my $label = $statusNotFound ? '    (?)' : '(match)';
                    print "  $label : $self->{_text}->{status} < $self->{_mail}->{status} >\n" if ($debug);
                    unless ( $statusNotFound ) { $fingerprintFound--; last; }
                  }
                }
              }

              unless ( $fingerprintFound ) {
                $self->{defaultArguments}->{result} .= "$msgline\n";
                print "- - - - - : $msgline\n" if ($debug);
                last;
              }

	           print ". . . . . : $msgline\n" if ($debug >= 2);
            }
          }
        }

        if ( $fingerprintFound == 0 ) {
          if ( $parms{checkFingerprint} ) {
            my $regexp = ( $self->{_mailType} ? "\Q$fingerprintXML\E" .'.+'. "\Q<\/FingerprintEmail>\E" : $self->{_text}->{status} .'\s+<'. $self->{_mail}->{status} .'>' );
            $msgbuffer =~ /$regexp/;
            $self->{defaultArguments}->{result} = ( $' ) ? $' : '';
          } else {
            $self->{defaultArguments}->{result} = $msgbuffer;
          }

          print "\n", ref ($self), "::receiving_fingerprint_mails(): BODY MESSAGE\n". $self->{defaultArguments}->{result}. "\n" if ($debug >= 2);

          if ( defined $parms{custom} ) {
            $returnCode = ( defined $parms{customArguments} ) ? $parms{custom}->($self, $self->{_asnmtapInherited}, $email, $msgnum, $parms{customArguments}) : $parms{custom}->($self, $self->{_asnmtapInherited}, $email, $msgnum);
          } else {
            $self->{defaultArguments}->{numberOfMatches}++;

            unless ( $debug or $$asnmtapInherited->getOptionsValue ('onDemand') ) {
              if ( defined $self->{_IMAP4}->{imap4} ) {
                $email->delete ( $msgnum );
              } elsif ( defined $self->{_POP3}->{pop3} ) {
                $email->Delete( $msgnum );
              }
            }
          }
        }

        $self->{defaultArguments}->{date}  = undef;
        $self->{defaultArguments}->{day}   = undef;
        $self->{defaultArguments}->{month} = undef;
        $self->{defaultArguments}->{year}  = undef;
        $self->{defaultArguments}->{time}  = undef;
        $self->{defaultArguments}->{hour}  = undef;
        $self->{defaultArguments}->{min}   = undef;
        $self->{defaultArguments}->{sec}   = undef;

        undef $head;
        $entity->purge;
        undef $entity;
      }

      undef $parser;
    }

    if ( defined $self->{defaultArguments}->{numberOfMatches} and $self->{defaultArguments}->{numberOfMatches} ) {
      $$asnmtapInherited->pluginValues ( { alert => $self->{defaultArguments}->{numberOfMatches} .' '. ( defined $parms{perfdataLabel} ? $parms{perfdataLabel} : 'email(s) received' ) }, $TYPE{APPEND} );
    } else {
      $returnCode = $parms{receivedState} ? $ERRORS{OK} : $ERRORS{CRITICAL};
      $$asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => 'No '. ( defined $parms{perfdataLabel} ? $parms{perfdataLabel} : 'email(s) received' ) }, $TYPE{APPEND} );
    }

    if ( defined $self->{_IMAP4}->{imap4} ) {
      $email->quit;
    } elsif ( defined $self->{_POP3}->{pop3} ) {
      $email->Close;
    }

    $$asnmtapInherited->appendPerformanceData ( "'". $parms{perfdataLabel} ."'=". $self->{defaultArguments}->{numberOfMatches} .';;;;' ) if ( defined $parms{perfdataLabel} );
    return ( $returnCode, $self->{defaultArguments}->{numberOfMatches} );
  }
}

# Destructor  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub DESTROY { print (ref ($_[0]), "::DESTROY: ()\n") if ( exists $$_[0]->{_asnmtapInherited} and $$_[0]->{_asnmtapInherited}->{_debug} ); }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Mail is a Perl module that provides Mail functions used by ASNMTAP-based plugins.

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Plugins

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

ASNMTAP is based on 'Process System daemons v1.60.17-01', Alex Peeters [alex.peeters@citap.be]

 Purpose: CronTab (CT, sysdCT),
          Disk Filesystem monitoring (DF, sysdDF),
          Intrusion Detection for FW-1 (ID, sysdID)
          Process System daemons (PS, sysdPS),
          Reachability of Remote Hosts on a network (RH, sysdRH),
          Rotate Logfiles (system activity files) (RL),
          Remote Socket monitoring (RS, sysdRS),
          System Activity monitoring (SA, sysdSA).

'Process System daemons' is based on 'sysdaemon 1.60' written by Trans-Euro I.T Ltd

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut
