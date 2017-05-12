package Asterisk::config::syntax::highlight;
use strict "vars";
use Syntax::Highlight::Engine::Simple;
our $strict;
our $VERSION = '0.5';

use Class::Std::Utils;
{
    my %global;

    sub new {
        my ($class) = @_;
        my $self = bless \do { my $anon_scalar }, $class;
        return $self;
    }

    sub load_file {
        my ( $self, %options ) = @_;
        $strict = $options{strict} || 0;

        my $highlight = Syntax::Highlight::Engine::Simple->new();
        $highlight->setSyntax(
            syntax => [
                {
                    class  => 'identifier',
                    regexp => "\[(.*)\]",
                },
				{
                    class  => 'exten',
                    regexp => qr!\\;!,
                },
                {
                    class  => 'value',
                    regexp => "\[{.*}\]",
                },
                {
                    class  => 'comment',
                    regexp => "\;(.*)",
                },
                {
                    class  => 'exten',
                    regexp => q!(\s*)\[(.*)\]!,
                },
                {
                    class  => 'exten',
                    regexp => q!include(\s*)(=|=>)(.*)!,
                },
                {
                    class  => 'exten',
                    regexp => $highlight->array2regexp( exten() ),
                },
                {
                    class  => 'keyword',
                    regexp => $highlight->array2regexp( commands() ),

                },
                {
                    class  => 'function',
                    regexp => $highlight->array2regexp( functions() ),

                },
            ]
        );

        open my $in, '<', $options{file} or die 'not that file?';
        my $datas = do { local $/; <$in> };
        close $in;
        $/ = "\n";

        my @data =
          map { $highlight->doStr( str => $_ ) }
          split( /\n/, $datas );
        $global{ ident $self}{datas} = \@data;

    }

    #only return array references now
    sub return_html_array_ref {
        my ( $self, %options ) = @_;
        return $global{ ident $self}{datas};
    }

    sub return_ubb_array_ref {
        my ( $self, %options ) = @_;
        my @data =
          map { $self->_html2ubb($_); } @{ $global{ ident $self}{datas} };
        return \@data;

    }

    sub return_wiki_array_ref {
        my ( $self, %options ) = @_;
        my @data =
          map { $self->_html2wiki($_); } @{ $global{ ident $self}{datas} };
        return \@data;
    }

    sub _html2ubb {
        my ( $self, $text ) = @_;
        $text =~ s/<span(\s)class='keyword'>/[color=blue]/ig;
        $text =~ s/<span(\s)class='function'>/[color=olive]/ig;
        $text =~ s/<span(\s)class='comment'>/[color=seagreen]/ig;
        $text =~ s/<span(\s)class='value'>/[color=purple]/ig;
        $text =~ s/<span(\s)class='identifier'>/[color=magenta]/ig;
        $text =~ s/<span(\s)class='exten'>/[color=red]/ig;
        $text =~ s/<\/span>/[\/color]/ig;
        return $text;
    }

    sub _html2wiki {
        my ( $self, $text ) = @_;
        $text =~ s/<span(\s)class='keyword'>/~~blue:/ig;
        $text =~ s/<span(\s)class='function'>/~~olive:/ig;
        $text =~ s/<span(\s)class='comment'>/~~seagreen:/ig;
        $text =~ s/<span(\s)class='value'>/~~purple:/ig;
        $text =~ s/<span(\s)class='identifier'>/~~magenta:/ig;
        $text =~ s/<span(\s)class='exten'>/~~red:/ig;
        $text =~ s/<\/span>/~~/ig;
        $text =~ s/\[/\[\[/ig;
        return $text;
    }

    sub DESTROY {
        my ($self) = @_;
        delete $global{ ident $self};
        return;
    }

    sub commands {
        return qw/
          AbsoluteTimeout
          AddQueueMember
          ADSIProg
          AgentCallbackLogin
          AgentLogin
          AgentMonitorOutgoing
          AGI
          AlarmReceiver
          ALSAMonitor
          AMD
          Answer
          AppendCDRUserField
          Authenticate
          BackGround
          BackgroundDetect
          Bridge
          Busy
          CallingPres
          ChangeMonitor
          ChanIsAvail
          ChannelRedirect
          ChanSpy
          CheckGroup
          ClearHash
          Congestion
          ContinueWhile
          ControlPlayback
          DAHDIBarge
          DAHDIRAS
          DAHDIScan
          DAHDISendKeypadFacility
          DBdel
          DBdeltree
          DBQuery
          DBRewrite
          DeadAGI
          Dial
          Dictate
          DigitTimeout
          Directory
          DISA
          DTMFToText
          DUNDiLookup
          EAGI
          Echo
          EndWhile
          EnumLookup
          Exec
          ExecIf
          ExecIfTime
          ExitWhile
          ExtenSpy
          ExternIVR
          Festival
          Flash
          Flite
          ForkCDR
          GetCPEID
          GetGroupCount
          GetGroupMatchCount
          Gosub
          GosubIf
          Goto
          GotoIf
          GotoIfTime
          Hangup
          HasNewVoicemail
          HasVoicemail
          ICES
          ImportVar
          JabberSend
          JabberStatus
          KeepAlive
          Log
          LookupBlacklist
          LookupCIDName
          Macro
          MacroExclusive
          MacroExit
          MailboxExists
          MeetMe
          MeetMeAdmin
          MeetMeChannelAdmin
          MeetMeCount
          Milliwatt
          MiniVM
          MixMonitor
          Monitor
          MP3Player
          MSet
          MusicOnHold
          MYSQL
          Asterisk cmg NBScat
          NoCDR
          NoOp
          ODBCFinish
          Page
          Park
          ParkAndAnnounce
          ParkedCall
          PauseQueueMember
          Perl
          Pickup
          PickUP
          PickupChan
          Playback
          Playtones
          PPPD
          PrivacyManager
          Proceeding
          Progress
          Queue
          Random
          Read
          ReadExten
          ReadFile
          RealTime
          Record
          RemoveQueueMember
          ResetCDR
          ResponseTimeout
          RetryDial
          Return
          Ringing
          Rpt
          SayAlpha
          SayDigits
          SayNumber
          SayPhonetic
          SayUnixTime
          SendDTMF
          SendImage
          SendText
          SendURL
          Set
          SetAccount
          SetAMAflags
          SetCallerID
          SetCallerPres
          SetCDRUserField
          SetGlobalVar
          SetMusicOnHold
          SIPAddHeader
          SIPCallPickup
          SIPGetHeader
          SIPdtmfMode
          SMS
          SoftHangup
          SrxEchoCan
          SrxDeflect
          SrxMWI
          StackPop
          Steal
          StopMonitor
          StopMixMonitor
          StopPlaytones
          System
          TestClient
          TestServer
          Transfer
          TrySystem
          TXTCIDName
          UnpauseQueueMember
          UserEvent
          VMAuthenticate
          VoiceMail
          VoiceMailMain
          Wait
          WaitExten
          WaitForRing
          WaitMusicOnHold
          WaitUntil
          While
          Zapateller
          /;
    }

    sub functions {
        return qw/
          AGENT
          ARRAY
          BASE64_DECODE
          BASE64_ENCODE
          CALLERID
          CDR
          CHANNEL
          CHECKSIPDOMAIN
          CHECK_MD5
          clearhash
          CURL
          CUT
          device_State
          DB
          DB_DELETE
          DB_EXISTS
          DIALGROUP
          dialplan_exists
          DUNDILOOKUP
          ENUMLOOKUP
          ENV
          EVAL
          EXISTS
          extension_state
          FIELDQTY
          FILTER
          GROUP
          GROUP_COUNT
          GROUP_LIST
          GROUP_MATCH_COUNT
          HASH
          hashkeys
          hint
          IAXPEER
          iaxvar
          IF
          IFTIME
          ISNULL
          KEYPADHASH
          LANGUAGE
          LEN
          MATH
          MD5
          MUSICCLASS
          ODBC
          QUEUEAGENTCOUNT
          QUEUE_MEMBER_COUNT
          QUEUE_MEMBER_LIST
          QUOTE
          RAND
          REALTIME
          REGEX
          SET
          SHA1
          SHARED
          SIPCHANINFO
          SIPPEER
          SIPAddHeader
          SIP_HEADER
          SORT
          SQL_ESC
          STAT
          STRFTIME
          STRPTIME
          sysinfo
          TIMEOUT
          toupper
          tolower
          TXTCIDNAME
          URIDECODE
          URIENCODE
          VOLUME
          VMCOUNT
          /;
    }

    sub exten {
        return qw/
          exten
          /;
    }

    no warnings;

    #reload
    sub Syntax::Highlight::Engine::Simple::_make_map {

        my $self = shift;
        my %args = ( str => '', pos => 0, index => undef, @_ );

        my $map_ref = $self->{_markup_map};
        my @scraps;
        if ($strict) {
            @scraps =
              split( /$self->{syntax}->[$args{index}]->{regexp}/,
                $args{str}, 2 );
        }
        else {
            @scraps =
              split( /$self->{syntax}->[$args{index}]->{regexp}/i,
                $args{str}, 2 );
        }

        if ( ( scalar @scraps ) >= 2 ) {

            my $rest     = pop(@scraps);
            my $ins_pos0 = $args{pos} + length( $scraps[0] );
            my $ins_pos1 =
              $args{pos} + ( length( $args{str} ) - length($rest) );

            ### Add markup position
            push( @$map_ref, [ $ins_pos0, $ins_pos1, $args{index}, ] );

            ### Recurseion for rest
            $self->_make_map( %args, str => $rest, pos => $ins_pos1 );
        }

        ### Follow up process
        elsif (@$map_ref) {

            @$map_ref =
              sort {
                     $$a[0] <=> $$b[0]
                  or $$b[1] <=> $$a[1]
                  or $$a[2] <=> $$b[2]
              } @$map_ref;
        }

        return;
    }

}

1;

__END__

=head1 NAME

Asterisk::config::syntax::highlight - highlight Asterisk config syntax

=head1 SYNOPSIS

    use strict;
    use Asterisk::config::syntax::highlight;

    my $config = Asterisk::config::syntax::highlight->new();
       $config->load_file(file=>file name);
    print join '<br />', @{$config->return_html_array_ref()};
    print join "\n", @{$config->return_ubb_array_ref()};
    print join "\n", @{$config->return_wiki_array_ref()};
    exit;

=head1 DESCRIPTION

This module highlighting Asterisk config syntax into
HTML .It's simple to used.

=head1 CONSTRUCTOR

=head2 C<new>

    my $config = Asterisk::config::syntax::highlight->new();


Constructs and returns a brand new Asterisk::config::syntax::highlight object ready
to be exploited.


=head1 METHODS

=head2 C<load_file>

    load_file(file=>file name);

Takes one mandatory argument which is a asterisk config file that you want to highlight.


=head2 C<return_html_array_ref>

    return_html_array_ref;

Returns the highlighted code as HTML by array references.

=head2 C<return_ubb_array_ref>

    return_ubb_array_ref;

Returns the highlighted code as UBB by array references.

=head2 C<return_wiki_array_ref>

    return_wiki_array_ref;

Returns the highlighted code as WIKITEXT by array references.

=head1 COLORING YOUR HIGHLIGHTED CSS

To actually set any colors on your "highlighted" CSS code returned
from the C<return_html_array_ref()> method you need to style all the generated C<< <spans>
>> with CSS; a sample CSS code to do that is shown in the section below.
Each C<< <span> >> will have the following class names/meanings:

=over 6

=item *

C<css-code> - this is actually the class name that will be set on the
C<< <pre>> >> element if you have that option turned on.

=item *

C<keyword> - Asterisk's keywords

=item *

C<function> - Asterisk's  function

=item *

C<comment> - Comment

=item *

C<value> - Values

=item *

C<identifier> - Identifier

=item *

C<exten> -  like  keyword

=back


=head2 SAMPLE STYLE SHEET FOR COLORING HIGHLIGHTED CODE

 span.keyword  {color: #00f}

 span.function {color: #808}

 span.comment   {color: #080}

 span.value     {color: #f80}

 span.identifier {color: #a66}

 span.exten     {color: red}

=head1 SEE ALSO

L<Syntax::Highlight::Engine::Simple>

=head1 AUTHOR

XuHao, C<< <loveme1314 at gamil.com> >>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009, http://blog.sakuras.cn. All Rights Reserved.

This script is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
