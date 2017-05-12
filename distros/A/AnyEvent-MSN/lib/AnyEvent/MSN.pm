package AnyEvent::MSN;
{ $AnyEvent::MSN::VERSION = 0.002 }
use lib '../../lib';
use 5.012;
use Moose;
use Moose::Util::TypeConstraints;
use AnyEvent qw[];
use AnyEvent::Handle qw[];
use AnyEvent::HTTP qw[];
use Try::Tiny;
use XML::Twig;
use AnyEvent::MSN::Protocol;
use AnyEvent::MSN::Types;
use MIME::Base64 qw[];

#
#use Data::Dump;
#
our $DEBUG = 0;
sub DEBUG {$DEBUG}

# XXX - During dev only
#use Data::Printer;
sub DEMOLISH {
    my $s = shift;
    $s->handle->destroy if $s->_has_handle && $s->handle;
    $s->_clear_soap_requests;
}

# Basic connection info
has host => (is      => 'ro',
             writer  => '_set_host',
             isa     => 'Str',
             default => 'messenger.hotmail.com'
);
has port => (is      => 'ro',
             writer  => '_set_port',
             isa     => 'Int',
             default => 1863
);

# Authentication info from user
has passport => (
    is       => 'ro',
    isa      => 'AnyEvent::MSN::Types::Passport',
    required => 1,
    handles  => {
        username => sub {
            shift->passport =~ m[^(.+)\@.+$];
            $1;
        },
        userhost => sub { shift->passport =~ m[^.+\@(.+)$]; $1 }
    }
);
has password => (is => 'ro', isa => 'Str', required => 1);

# Extra stuff from user
has [qw[friendly_name personal_message]] =>
    (is => 'ro', isa => 'Str', default => '');
has status => (
         is      => 'ro',
         isa     => 'AnyEvent::MSN::Types::OnlineStatus',
         default => 'NLN',
         writer  => 'set_status'                            # exposed publicly
);

# Client info for MSNP21
has protocol_version => (
    is  => 'ro',
    isa => subtype(
        as 'Str' => where {m[^(?:MSNP\d+\s*)+$]} => message {
            'Protocol versions look like: MSNP18 MSNP21';
        }
    ),
    writer  => '_set_protocol_version',
    clearer => '_reset_protocol_version',
    default => 'MSNP21',
    lazy    => 1
);
map { has $_->[0] => (is => 'ro', isa => 'Str', default => $_->[1]) }
    [qw[product_id PROD0120PW!CCV9@]],
    [qw[product_key C1BX{V4W}Q3*10SM]],
    [qw[locale_id 0x0409]],
    [qw[os_type winnt]],
    [qw[os_ver 6.1.1]],
    [qw[arch i386]],
    [qw[client_name MSNMSGR]],
    [qw[client_version 15.4.3508.1109]],
    [qw[client_string MSNMSGR]];
has guid => (
    is     => 'ro',
    => isa => subtype(
        as 'Str' => where {
            my $hex = qr[[\da-f]];
            m[{$hex{8}(?:-$hex{4}){3}-$hex{12}}$];
        } => message {
            'Malformed GUID. Should look like: {12345678-abcd-1234-abcd-123456789abc}';
        }
    ),
    builder => '_build_guid'
);

sub _build_guid {
    state $r //= sub {
        join '', map { ('a' .. 'f', 0 .. 9)[rand 15] } 1 .. shift;
    };
    sprintf '{%8s-%4s-%4s-%4s-%12s}', $r->(8), $r->(4), $r->(4), $r->(4),
        $r->(12);
}
has location => (is => 'ro', isa => 'Str', default => 'Perl/AnyEvent::MSN');

# Internals
has handle => (
    is  => 'ro',
    isa => 'Object',

    # weak_ref  => 1,
    predicate => '_has_handle',
    writer    => '_set_handle',
    clearer   => '_reset_handle',
    handles   => {
        send => sub {
            my $s = shift;
            $s->handle->push_write('AnyEvent::MSN::Protocol' => @_)
                if $s->_has_handle;    # XXX - Else mention it...
            }
    }
);
has tid => (is      => 'ro',
            isa     => 'Int',
            lazy    => 1,
            clearer => '_reset_tid',
            builder => '_build_tid',
            traits  => ['Counter'],
            handles => {'_inc_tid' => 'inc'}
);
sub _build_tid {0}
after tid => sub { shift->_inc_tid };    # Auto inc
has ping_timer => (is     => 'ro',
                   isa    => 'Ref',                     # AE::timer
                   writer => '_set_ping_timer'
);

# Server configuration
has policies => (
    is      => 'bare',
    isa     => 'HashRef',
    clearer => '_reset_policies',
    writer  => '_set_policies',
    traits  => ['Hash'],
    handles => {_add_policy => 'set',
                _del_policy => 'delete',
                policy      => 'get',
                policies    => 'kv'        # XXX - Really?
    }
);

# SOAP
has SSOsites => (
    is      => 'ro',                   # Single Sign On
    isa     => 'ArrayRef[ArrayRef]',
    traits  => ['Array'],
    default => sub {
        [['http://Passport.NET/tb',   ''],
         ['messengerclear.live.com',  'MBI_KEY_OLD'],
         ['messenger.msn.com',        '?id=507'],
         ['messengersecure.live.com', 'MBI_SSL'],
         ['contacts.msn.com',         'MBI'],
         ['storage.msn.com',          'MBI'],
         ['sup.live.com',             'MBI']
        ];
    }
);
has auth_tokens => (is      => 'bare',
                    isa     => 'HashRef',
                    clearer => '_reset_auth_tokens',
                    writer  => '_set_auth_tokens',
                    traits  => ['Hash'],
                    handles => {_add_auth_token => 'set',
                                _del_auth_token => 'delete',
                                auth_token      => 'get',
                                auth_tokens     => 'kv'
                    }
);
has contacts => (is      => 'ro',
                 isa     => 'HashRef',
                 clearer => '_reset_contacts',
                 writer  => '_set_contacts',
                 traits  => ['Hash'],
);

# Simple callbacks
has 'on_' . $_ => (
    traits  => ['Code'],
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        sub {1}
    },
    handles => {'_trigger_' . $_ => 'execute_method'},
    )
    for qw[
    im nudge
    error fatal_error connect
    addressbook_update
    buddylist_update
    user_notification
    create_circle
];
has connected => (
             is      => 'ro',
             isa     => 'Bool',
             traits  => ['Bool'],
             default => 0,
             handles => {_set_connected => 'set', _unset_connected => 'unset'}
);
has redirect => (
         is        => 'ro',
         isa       => 'Str',
         predicate => '_has_redirect',
         writer    => '_set_redirect',
         clearer   => '_reset_redirect'    # XXX - Currently unused internally
);

# Auto connect
sub BUILD {
    my ($s, $p) = @_;
    return if $p->{no_autoconnect};
    $s->connect;
}

sub connect {
    my $s = shift;
    $s->_unset_connected;
    $s->_set_handle(
        AnyEvent::Handle->new(
            connect    => [$s->host, $s->port],
            on_connect => sub {

                # Get ready to read data from server
                $s->handle->push_read(
                    'AnyEvent::MSN::Protocol' => sub {
                        my ($cmd, $tid, @data) = @_;
                        my $method = $s->can('_handle_packet_' . lc($cmd));
                        $method ||= sub {
                            $s->_trigger_error(
                                            'Unhandled command type: ' . $cmd,
                                            0);
                        };
                        if ($cmd =~ m[^(?:GCF|MSG|NFY|NOT|SDG|UBX|PUT)$])
                        {    # payload types
                            $s->handle->unshift_read(
                                chunk => $data[-1] // $tid,    # GFC:0, MSG:2
                                sub {
                                    my ($_h, $_c) = @_;
                                    $s->$method(
                                        $tid, @data,
                                        $cmd =~ m[GCF] ? $s->_parse_xml($_c)
                                        : $cmd =~ m[(?:MSG|NFY|SDG)] ?
                                            AnyEvent::MSN::Protocol::__parse_msn_headers(
                                                                          $_c)
                                        : $_c
                                    );
                                }
                            );
                        }
                        elsif ($cmd =~ m[^\d+$]) {    # Error!
                            $s->_trigger_error(
                                 AnyEvent::MSN::Protocol::err2str($cmd, @data)
                            );
                        }
                        else {
                            $s->$method($tid, @data);
                        }
                    }
                );

                # Send version negotiation
                $s->send('VER %d %s CVR0', $s->tid, $s->protocol_version);

                # Schedule first PNG in two mins
                $s->_set_ping_timer(AE::timer 120,
                                    180, sub { $s->send('PNG') });
            },
            on_connect_error =>
                sub { shift; $s->_trigger_fatal_error(shift) },
            on_error => sub {
                my $h = shift;
                $s->_trigger_fatal_error(reverse @_);
                $h->destroy;
            },
            on_eof => sub {
                $_[0]->destroy;
                $s->cleanup('connection closed');
            }
        )
    );
}

# Commands from notification server
sub _handle_packet_adl {
    my $s = shift;

    # ACK for outgoing ADL
    # $s->send('BLP %d AL', $s->tid);
}

sub _handle_packet_chl {    # Official client challenge
    my ($s, $tid, @data) = @_;
    my $data =
        AnyEvent::MSN::Protocol::CreateQRYHash($data[0], $s->product_id,
                                               $s->product_key);
    $s->send("QRY %d %s %d\r\n%s",
             $s->tid, $s->product_id, length($data), $data);
}

sub _handle_packet_cvr {    # Client version recommendation
    my ($s, $tid, $r, $min_a, $min_b, $url_dl, $url_info) = @_;

    # We don't do anything with this yet but...
    # The first parameter is a recommended version of
    # the client for you to use, or "1.0.0000" if your
    #   client information is not recognised.
    # The second parameter is identical to the first.
    # The third parameter is the minimum version of the
    #   client it's safe for you to use, or the current
    #   version if your client information is not
    #   recognised.
    # The fourth parameter is a URL you can download the
    #   recommended version of the client from.
    # The fifth parameter is a URL the user can go to to
    #   get more information about the client.
    $s->send('USR %d SSO I %s', $s->tid, $s->passport);
}

sub _handle_packet_gcf {    # Get config
    my ($s, $tid, $len, $r) = @_;
    if ($tid == 0) {        # probably Policy list
        $s->_set_policies($r->{Policy});

        #for (@{$s->policy('SHIELDS')->{config}{block}{regexp}{imtext}}) {
        #    my $regex = MIME::Base64::decode_base64($_);
        #    warn 'Blocking ' . qr[$regex];
        #}
    }
    else {
        ...;
    }
}

sub _handle_packet_msg {
    my ($s, $from, $about, $len, $head, $body) = @_;
    given ($head->{'Content-Type'}) {
        when (m[text/x-msmsgsprofile]) {

     #
     # http://msnpiki.msnfanatic.com/index.php/MSNP8:Messages#Profile_Messages
     # My profile message. Expect no body.
        }
        when (m[text/x-msmsgsinitialmdatanotification]) {    # Expect no body
        }
        when (m[text/x-msmsgsoimnotification]) {

            # Offline Message Waiting.
            # Expect no body
            # XXX - How do I request it?
        }
        when (m[text/x-msmsgsactivemailnotification]) {

            #warn 'You\'ve got mail!/aol'
        }
        when (m[text/x-msmsgsinitialmdatanotification]) {

            #warn 'You\'ve got mail!/aol'
        }
        default { $s->_trigger_error('Unknown message type: ' . $_) }
    }
}

sub _handle_packet_nfy {
    my ($s, $type, $len, $headers, $data) = @_;

=begin comment
        use Data::Printer;
        dd $type, $len, $headers, $data;
        dd $s->_parse_xml($data);
=cut
    given ($headers->{Uri}) {
        when ('/user') {
            given ($type) {
                when ('PUT') {
                    my $xml = $s->_parse_xml($data);
                    if ((!defined $headers->{By})
                        && $headers->{From} eq '1:' . $s->passport)
                    {    # Without guid
                        $s->set_status($s->status)
                            ;    # Not fully logged in until sent
                        $s->_set_connected();
                        $s->_trigger_connect;
                    }
                    else {
                        $s->_trigger_user_notification($headers, $xml);
                    }
                }
                when ('DEL') {

                    # Remove from list
                }
                default {...}
            }
        }
        when ('/circle') {
            my $xml = $s->_parse_xml($data);
            $s->_trigger_create_circle($headers, $xml);
        }
        default {...}
    }
}
sub _handle_packet_not { my $s = shift; }
sub _handle_packet_out { my $s = shift; }

sub _handle_packet_put {
    my $s = shift;

    # ACK for our PUT packets
}

sub _handle_packet_qng {
    my ($s, $next) = @_;

    # PONG in reply to our PNG
    $s->_set_ping_timer(AE::timer $next, $next, sub { $s->send('PNG') });
}

sub _handle_packet_qry {
    my ($s, $tid) = @_;

    #
    my $token = $s->auth_token('contacts.msn.com')
        ->{'wst:RequestedSecurityToken'}{'wsse:BinarySecurityToken'}{content};
    $token =~ s/&/&amp;/sg;
    $token =~ s/</&lt;/sg;
    $token =~ s/>/&gt;/sg;
    $token =~ s/"/&quot;/sg;

    # Reply to good challenge. Expect no body.
    $s->_soap_request(
        'https://local-bay.contacts.msn.com/abservice/SharingService.asmx',
        {   'content-type' => 'text/xml; charset=utf-8',
            SOAPAction =>
                '"http://www.msn.com/webservices/AddressBook/FindMembership"'
        },
        sprintf(<<'XML', $token),
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Header>
        <ABApplicationHeader xmlns="http://www.msn.com/webservices/AddressBook">
            <ApplicationId>CFE80F9D-180F-4399-82AB-413F33A1FA11</ApplicationId>
            <IsMigration>false</IsMigration>
            <PartnerScenario>Initial</PartnerScenario>
        </ABApplicationHeader>
        <ABAuthHeader xmlns="http://www.msn.com/webservices/AddressBook">
            <TicketToken>%s</TicketToken>
            <ManagedGroupRequest>false</ManagedGroupRequest>
        </ABAuthHeader>
    </soap:Header>
    <soap:Body>
        <FindMembership xmlns="http://www.msn.com/webservices/AddressBook">
            <ServiceFilter>
                <Types>
                    <Space></Space>
                    <SocialNetwork></SocialNetwork>
                    <Profile></Profile>
                    <Invitation></Invitation>
                    <Messenger></Messenger>
                </Types>
            </ServiceFilter>
        </FindMembership>
    </soap:Body>
</soap:Envelope>
XML
        sub {
            my $contacts = shift;

            # XXX - Do something with these contacts
            #...
        }
    );
    $s->_soap_request(
        'https://local-bay.contacts.msn.com/abservice/abservice.asmx',
        {   'content-type' => 'text/xml; charset=utf-8',
            SOAPAction =>
                '"http://www.msn.com/webservices/AddressBook/ABFindContactsPaged"'
        },
        sprintf(<<'XML', $token),
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Header>
        <ABApplicationHeader xmlns="http://www.msn.com/webservices/AddressBook">
            <ApplicationId>3794391A-4816-4BAC-B34B-6EC7FB5046C6</ApplicationId>
            <IsMigration>false</IsMigration>
            <PartnerScenario>Initial</PartnerScenario>
        </ABApplicationHeader>
        <ABAuthHeader xmlns="http://www.msn.com/webservices/AddressBook">
            <TicketToken>%s</TicketToken>
            <ManagedGroupRequest>false</ManagedGroupRequest>
        </ABAuthHeader>
    </soap:Header>
    <soap:Body>
        <ABFindall xmlns="http://www.msn.com/webservices/AddressBook">
            <abID>00000000-0000-0000-0000-000000000000</abID>
        </ABFindall>
        <ABFindContactsPaged xmlns="http://www.msn.com/webservices/AddressBook">
            <extendedContent>AB AllGroups CircleResult</extendedContent>
            <abView>MessengerClient8</abView>
            <filterOptions>
                <DeltasOnly>false</DeltasOnly>
                <ContactFilter>
                    <IncludeShellContacts>true</IncludeShellContacts>
                    <IncludeHiddenContacts>true</IncludeHiddenContacts>
                </ContactFilter>
                <LastChanged>0001-01-01T00:00:00.00-08:00</LastChanged>
            </filterOptions>
            <pageContext>
                <PageSize>1500</PageSize>
                <Direction>Forward</Direction>
            </pageContext>
        </ABFindContactsPaged>
    </soap:Body>
</soap:Envelope>
XML
        sub {
            my $contacts = shift;

            # XXX - Do something with these contacts
            $s->_set_contacts($contacts);
            my $ticket
                = __html_unescape(
                    $s->contacts->{'soap:Body'}{'ABFindContactsPagedResponse'}
                        {'ABFindContactsPagedResult'}{'CircleResult'}
                        {'CircleTicket'});
            $s->send('USR %d SHA A %s',
                     $s->tid, MIME::Base64::encode_base64($ticket, ''));

            #
            my $x =    # XML modules get it wrong if we only have 1 buddy
                $s->contacts->{'soap:Body'}{'ABFindContactsPagedResponse'}
                {'ABFindContactsPagedResult'}{'Contacts'}{'Contact'};
            $x = [$x] if ref $x ne 'ARRAY';
            $s->add_temporary_contact(map { $_->{contactInfo}{passportName} }
                                      @$x);
        }
    );
}

sub _handle_packet_rml {
    my ($s, $tid, $ok) = @_;

=begin comment
        use Data::Printer;
        dd @_;
=cut
    ...;
}

sub _handle_packet_sbs {
    my $s = shift;

    # No one seems to know what this is. Official client ignores it?
}

sub _handle_packet_sdg {
    my ($s, $tid, $size, $head, $body) = @_;

    #dd [$head, $body];
    given ($head->{'Message-Type'}) {
        when ('Text') {
            given ($head->{'Service-Channel'}) {
                $s->_trigger_im($head, $body) when 'IM/Online';
                $s->_trigger_im($head, $body) when undef;
                warn 'Offline Msg!' when 'IM/Offline';
                default {
                    warn 'unknown IM!!!!!'
                }
            }
        }
        $s->_trigger_nudge($head) when 'Nudge';
        when ('Wink')           { warn 'Wink' }
        when ('CustomEmoticon') { warn 'Custom Emoticon' }
        when ('Control/Typing') { warn 'Typing!' }
        when ('Data') {
            my ($header, $packet, $footer);
            if ($head->{To} !~ m[{.+}]) {

# 0                   1                   2                   3                   4                   5
# 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |  SID  |  ID   | Data Offset   | Total Size    |Length | Flags | AckID |AckUID | Ack Data Size |DATA....
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#
# The 48-byte binary header consists of 6 DWORDs and 3 QWORDS, which are all in little endian (little end first) order, where a DWORD is a 32-bit (4 byte) unsigned integer and QWORD is 64 bits (8 bytes).
#
# 1	 0	 DWORD   SessionID                  The SessionID, which is zero when the Clients are negotiating about the session.
# 2	 4	 DWORD   Identifier                 The first message you receive from the other client is the BaseIndentifier, the other messages contains a number near the BaseIdentifier.
# 3	 8	 QWORD   Data offset                Explained under Splitting big messages. Most often the messages are not split, and this value is 0.
# 4	 16	 QWORD   Total data size	        Case 1: The byte size of all data sent between the header and footer of all of the message parts. This is the same independent of how many pieces the message is split in. Case 2: If this is an acknowledgement, this field is a copy of the same field in the message acknowledged. Sending acknowledgements
# 5	 24	 DWORD   Message length	            The byte size of the data between the header and footer of this particular message.
# 6	 28	 DWORD   Flag	                    Identifies the message type. See the flags section
# 7	 32	 DWORD   Acknowledged identifier    In case the message is an acknowledgement, this is a copy of the Identifier of the acknowledged message. Else this is some random generated number.
# 8	 36	 DWORD   Acknowledged unique ID     In case the message is an acknowledgement, this is a copy of the previous field of the acknowledged message. Else this is 0.
# 9	 40	 QWORD   Acknowledged data size     In case the message is an acknowledgement, this is a copy of the Total data size field of the acknowledged message. Else this is 0.
                sub _quad {
                    state $little//= unpack 'C', pack 'S', 1;
                    my $str = shift;
                    my $big;
                    if (!eval { $big = unpack('Q', $str); 1; }) {
                        my ($lo, $hi) = unpack 'LL', $str;
                        ($hi, $lo) = ($lo, $hi) if !$little;
                        $big = $lo + $hi * (1 + ~0);
                        if ($big + 1 == $big) {
                            warn 'A-pprox-i-mate!';
                        }
                    }
                    return $big;
                }
                (my ($sessionid,  $identifier, $offset,
                     $total_size, $msg_len,    $flag,
                     $ack_id,     $ack_uid,    $ack_data_size
                 ),
                 $packet
                ) = unpack 'NNa8a8NNNNa8a*', $body;
                ($packet, $footer)
                    = unpack 'a' . (_quad($total_size)) . ' a',
                    $packet;
                $header = {sessionid     => $sessionid,
                           identifier    => $identifier,
                           offset        => _quad($offset),
                           total_size    => _quad($total_size),
                           msg_len       => $msg_len,
                           flag          => $flag,
                           ack_id        => $ack_id,
                           ack_uid       => $ack_uid,
                           ack_data_size => _quad($ack_data_size)
                };
            }
            else {

# 0                   1                   2                   3
# 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# |L|O|Len|Base ID|if L>8 then TLVs = read(L - 8) else skip  ....
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# | if Len > 0 then Payload = (DH and D) else skip           ....
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#
# For all of them - (DWORD is a 32-bit, 4 byte, unsigned integer and QWORD is 64 bits, 8 bytes.)
#
# 1	 BYTE	HL	Length of header.
# 2	 BYTE	OP	Operation code. 0: None, 2: Ack, 3: Init session.
# 3	 WORD	ML	 Message length without header length. (but included the header's message length)
# 4	 DWORD	BaseID	 Initially random (?) To get the next one add the payload length.
# TLVs BYTE[HL-8]	TLV Data	 TLV list consists of TLV-encoded pairs (type, length, value). A whole TLV list is padded with zeros to fit 4-byte boundary. TLVs: T=0x1(1) L=0xc(12): IPv6 address of sender/receiver. T=0x2(2) L=0x4(4): ACK identifier.
# DH	 DHL	Data Header
# BYTE    DHL: Data header length
# BYTE    TFCombination: 0x1=First, 0x4=Msn object (display picture, emoticon etc), 0x6=File transfer
# WORD    PackageNumber: Package number
# DWORD   SessionID: Session Identifier
# BYTE[DHL-8] Data packets TLVs: if (DHL>8) then read bytes(DHL - 8). T=0x1(1) L=0x8(8): Data remaining.
# D	 ML-DHL	Data Packet	 SLP messsage or data packet
# F	 DWORD	Footer	 The footer.
                p $body;
                my ($hl, $op, $ml, $baseid, $etc) = unpack 'CCnNa*', $body;

                #warn sprintf 'HL     = %d',      $hl;
                #warn sprintf 'OP     = %d (%s)', $op,
                #    (  $op == 0 ? 'None'
                #     : $op == 2 ? 'Ack'
                #     : $op == 3 ? 'Init'
                #     : 'BROKEN'
                #    );
                #warn sprintf 'ML     = %d', $ml;
                #warn sprintf 'BaseID = %s', $baseid;
                #
                my $_tlv_len = $hl - 8;
                $_tlv_len += $_tlv_len % 8;
                my ($tlv, $moar) = unpack "a$_tlv_len a*", $etc;

                #warn sprintf 'TLV    = %s', $tlv;
                sub _tlv {
                    my ($t, $v, $m) = unpack 'CC/a', shift;
                    { shift // (), t => $t, v => $v, $m ? _tlv($m) : () }
                }
                my ($dhlen, $tf_combo, $pac, $ses, $XXX)
                    = unpack 'CCnNa*',
                    $moar;
                warn length($moar);
                ($packet, $footer) = unpack 'a' . ($ml - $dhlen) . 'a*', $XXX
                    if $XXX;
                $header = {tlv => ($tlv ? _tlv($tlv) : ()),
                           header_len => $hl,
                           operation  => $op,
                           (  $op == 0 ? 'None'
                            : $op == 2 ? 'Ack'
                            : $op == 3 ? 'Init'
                            : 'BROKEN'
                           ),
                           base_id => $baseid,
                           msg_len => $ml
                };

                #
            }

            #dd $header;
            #p($packet =~ m[^(.+?)\r\n(.+)\r\n\r\n(.)$]s);
            my ($p2p_action, $p2p_head, $p2p_body)
                = ($packet =~ m[^(.+?)\r\n(.+)\r\n\r\n(.)$]s);

            #dd $head, $p2p_action,
            #    AnyEvent::MSN::Protocol::__parse_msn_headers($p2p_head),
            #    $p2p_body;
            #warn 'Data'
            # XXX - trigger a callback of some sort
        }
        when ('Signal/P2P')              { warn 'P2P' }
        when ('Signal/ForceAbchSync')    { }
        when ('Signal/CloseIMWindow')    { }
        when ('Signal/MarkIMWindowRead') { }
        when ('Signal/Turn')             { };
        when ('Signal/AudioMeta')        { }
        when ('Signal/AudioTunnel')      { }
        default                          {...}
    }
}

sub _handle_packet_usr {
    my ($s, $tid, $subtype, $_s, $policy, $nonce) = @_;
    if ($subtype eq 'OK') {

        # Sent after we send ADL command. Lastcommand in the logon?
    }
    elsif ($subtype eq 'SSO') {
        my $x      = 1;
        my @tokens = map {
            sprintf <<'TOKEN', $x++, $_->[0], $_->[1] } @{$s->SSOsites};
            <wst:RequestSecurityToken Id="RST%d">
                <wst:RequestType>http://schemas.xmlsoap.org/ws/2004/04/security/trust/Issue</wst:RequestType>
                <wsp:AppliesTo>
                    <wsa:EndpointReference>
                        <wsa:Address>%s</wsa:Address>
                    </wsa:EndpointReference>
                </wsp:AppliesTo>
                <wsse:PolicyReference URI="%s"></wsse:PolicyReference>
            </wst:RequestSecurityToken>
TOKEN
        $s->_soap_request(
            ($s->passport =~ m[\@msn.com$]i
             ?
                 'https://msnia.login.live.com/pp550/RST.srf'
             : 'https://login.live.com/RST.srf'
            ),
            {},    # headers
            sprintf(<<'XML', $s->password, $s->passport, join '', @tokens),
<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsse="http://schemas.xmlsoap.org/ws/2003/06/secext" xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" xmlns:wsp="http://schemas.xmlsoap.org/ws/2002/12/policy" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/03/addressing" xmlns:wssc="http://schemas.xmlsoap.org/ws/2004/04/sc" xmlns:wst="http://schemas.xmlsoap.org/ws/2004/04/trust">
    <Header>
        <wsse:Security>
            <wsse:UsernameToken Id="user">
                <wsse:Password>%s</wsse:Password>
                <wsse:Username>%s</wsse:Username>
            </wsse:UsernameToken>
        </wsse:Security>
        <ps:AuthInfo Id="PPAuthInfo" xmlns:ps="http://schemas.microsoft.com/Passport/SoapServices/PPCRL">
            <ps:Cookies></ps:Cookies>
            <ps:UIVersion>1</ps:UIVersion>
            <ps:HostingApp>{7108E71A-9926-4FCB-BCC9-9A9D3F32E423}</ps:HostingApp>
            <ps:BinaryVersion>4</ps:BinaryVersion>
            <ps:RequestParams>AQAAAAIAAABsYwQAAAAxMDMz</ps:RequestParams>
        </ps:AuthInfo>
    </Header>
    <Body>
        <ps:RequestMultipleSecurityTokens Id="RSTS" xmlns:ps="http://schemas.microsoft.com/Passport/SoapServices/PPCRL">
%s        </ps:RequestMultipleSecurityTokens>
    </Body>
</Envelope>
XML
            sub {
                my $d = shift;
                for my $token (
                        @{  $d->{'S:Body'}
                                {'wst:RequestSecurityTokenResponseCollection'}
                                {'wst:RequestSecurityTokenResponse'}
                        }
                    )
                {   $s->_add_auth_token(
                            $token->{'wsp:AppliesTo'}{'wsa:EndpointReference'}
                                {'wsa:Address'},
                            $token
                    );
                }

                #
                if ($policy =~ m[MBI]) {
                    my $token = $s->auth_token('messengerclear.live.com')
                        ;    # or http://Passport.NET/tb
                    my $token_
                        = __html_escape($token->{'wst:RequestedSecurityToken'}
                                     {'wsse:BinarySecurityToken'}{'content'});
                    $s->send('USR %d SSO S %s %s %s',
                             $s->tid,
                             $token->{'wst:RequestedSecurityToken'}
                                 {'wsse:BinarySecurityToken'}{'content'},
                             AnyEvent::MSN::Protocol::SSO(
                                           $nonce,
                                           $token->{'wst:RequestedProofToken'}
                                               {'wst:BinarySecret'}
                             ),
                             $s->guid
                    );
                }
                elsif ($policy =~ m[^\?]) {
                    ...;
                }
            }
        );
    }
    elsif ($subtype eq 'OK') {

        # XXX - logged in okay. What now?
    }
    else {
        ...;
    }
}

sub _handle_packet_ubx {    # Buddy has changed something
    my ($s, $passport, $len, $payload) = @_;
    my $xml = $s->_parse_xml($payload);
    if ($len == 0 && $passport eq '1:' . $s->passport) {
    }
    else {

        #dd $xml;
        my ($user) = ($passport =~ m[:(.+)$]);
        $s->_add_temporary_contact($user, $xml);
    }
}

sub _handle_packet_uux {    # ACK for UUX
}

sub _handle_packet_ver {    # Negotiated protocol version
    my ($s, $tid, $r) = @_;
    $s->_set_protocol_version($r);

    # Send basic client info
    $s->send('CVR %d %s %s %s %s %s %s %s %s%s',
             $s->tid,
             $s->locale_id,
             $s->os_type,
             $s->os_ver,
             $s->arch,
             $s->client_name,
             $s->client_version,
             $s->client_string,
             $s->passport,
             (' ' . ($s->_has_redirect ? $s->redirect : ' 0'))
    );
}

sub _handle_packet_xfr {    # Transver to another switchboard
    my $s = shift;
    my ($tid, $type, $addr, $u, $d, $redirect) = @_;
    $s->send('OUT');
    $s->handle->destroy;
    my ($host, $port) = ($addr =~ m[^(.+):(\d+)$]);
    $s->_set_host($host);
    $s->_set_port($port);
    $s->_set_redirect($redirect);
    $s->connect;
}

# SOAP client
has soap_requests => (isa     => 'HashRef[AnyEvent::Util::guard]',
                      traits  => ['Hash'],
                      handles => {_add_soap_request    => 'set',
                                  _del_soap_request    => 'delete',
                                  _clear_soap_requests => 'clear'
                      }
);

sub _soap_request {
    my ($s, $uri, $headers, $content, $cb) = @_;
    my %headers = (
           'user-agent'   => 'MSNPM 1.0',
           'content-type' => 'application/soap+xml; charset=utf-8; action=""',
           'Expect'       => '100-continue',
           'connection'   => 'Keep-Alive'
    );

    #warn $content;
    @headers{keys %$headers} = values %$headers;
    $s->_add_soap_request(
        $uri,
        AnyEvent::HTTP::http_request(
            POST       => $uri,
            headers    => \%headers,
            timeout    => 15,
            persistent => 1,
            body       => $content,
            sub {
                my ($body, $hdr) = @_;
                my $xml = $s->_parse_xml($body);
                $s->_del_soap_request($uri);
                return $cb->($xml)
                    if $hdr->{Status} =~ /^2/
                        && !defined $xml->{'S:Fault'};

                #dd $hdr;
                #dd $xml;
                $s->_trigger_error(
                       $xml->{'soap:Body'}{'soap:Fault'}{'soap:Reason'}
                           {'soap:Text'}{'content'}
                           // $xml->{'soap:Body'}{'soap:Fault'}{'faultstring'}
                           // $hdr->{Reason});
            }
        )
    );
}

# Methods exposed publicly
sub disconnect {    # cleanly disconnect from switchboard
    my $s = shift;
    $s->send('OUT');
    $s->handle->on_drain(
        sub {
            $s->handle->destroy;
        }
    );
    $s->_clear_redirect;    # Start from scratch next time
}

sub send_message {
    my ($s, $to, $msg, $format) = @_;
    $to = '1:' . $to if $to !~ m[^\d+:];
    $format //= 'FN=Segoe%20UI; EF=; CO=0; CS=1; PF=0';

    # FN: Font name (url safe)
    # EF: String containing...
    # - B for Bold
    # - U for Underline
    # - I for Italics
    #　- S for Strikethrough
    # CO: Color (hex without #)
    my $data
        = sprintf
        qq[Routing: 1.0\r\nTo: %s\r\nFrom: 1:%s;epid=%s\r\n\r\nReliability: 1.0\r\n\r\nMessaging: 2.0\r\nMessage-Type: Text\r\nContent-Type: text/plain; charset=UTF-8\r\nContent-Length: %d\r\nX-MMS-IM-Format: %s\r\n\r\n%s],
        $to, $s->passport, $s->guid, length($msg), $format, $msg;
    $s->send(qq'SDG 0 %d\r\n%s', length($data), $data);
}

sub nudge {
    my ($s, $to) = @_;
    $to = '1:' . $to if $to !~ m[^\d+:];
    my $data
        = sprintf
        qq[Routing: 1.0\r\nTo: %s\r\nFrom: 1:%s;epid=%s\r\n\r\nReliability: 1.0\r\n\r\nMessaging: 2.0\r\nMessage-Type: Nudge\r\nService-Channel: IM/Online\r\nContent-Type: text/plain; charset=UTF-8\r\nContent-Length: 0\r\n\r\n],
        $to, $s->passport, $s->guid;
    $s->send("SDG 0 %d\r\n%s", length($data), $data);
}

sub add_contact {
    my ($s, $contact) = @_;

    #
    my $token = $s->auth_token('contacts.msn.com')
        ->{'wst:RequestedSecurityToken'}{'wsse:BinarySecurityToken'}{content};
    $token =~ s/&/&amp;/sg;
    $token =~ s/</&lt;/sg;
    $token =~ s/>/&gt;/sg;
    $token =~ s/"/&quot;/sg;

    #
    $s->_soap_request(
        'https://local-bay.contacts.msn.com/abservice/abservice.asmx',
        {   'content-type' => 'text/xml; charset=utf-8',
            SOAPAction =>
                '"http://www.msn.com/webservices/AddressBook/ABContactAdd"'
        },
        sprintf(<<'XML', $token, $contact),
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
   xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/">
     <soap:Header>
        <ABApplicationHeader xmlns="http://www.msn.com/webservices/AddressBook">
            <ApplicationId>CFE80F9D-180F-4399-82AB-413F33A1FA11</ApplicationId>
            <IsMigration>false</IsMigration>
            <PartnerScenario>ContactSave</PartnerScenario>
        </ABApplicationHeader>
        <ABAuthHeader xmlns="http://www.msn.com/webservices/AddressBook">
            <TicketToken>%s</TicketToken>
            <ManagedGroupRequest>false</ManagedGroupRequest>
        </ABAuthHeader>
    </soap:Header>
 <soap:Body>
 <ABContactAdd xmlns="http://www.msn.com/webservices/AddressBook">
            <abId>
                00000000-0000-0000-0000-000000000000
            </abId>
            <contacts>
                <Contact xmlns="http://www.msn.com/webservices/AddressBook">
                    <contactInfo>
                        <contactType>LivePending</contactType>
                        <passportName>%s</passportName>
                        <isMessengerUser>true</isMessengerUser>
                        <MessengerMemberInfo>
                        <DisplayName>minimum clorpvfgt</DisplayName>
                        </MessengerMemberInfo>
                    </contactInfo>
                </Contact>
            </contacts>
            <options>
                <EnableAllowListManagement>
                    true
                </EnableAllowListManagement>
            </options>
        </ABContactAdd>

 </soap:Body>
</soap:Envelope>
XML
        sub {

            #dd @_;
            $s->add_temporary_contact($contact);
        }
    );
}

sub remove_contact {
    my ($s, $contact) = @_;

    #
    my $token = $s->auth_token('contacts.msn.com')
        ->{'wst:RequestedSecurityToken'}{'wsse:BinarySecurityToken'}{content};
    $token =~ s/&/&amp;/sg;
    $token =~ s/</&lt;/sg;
    $token =~ s/>/&gt;/sg;
    $token =~ s/"/&quot;/sg;

    #
    $s->_soap_request(
        'https://contacts.msn.com/abservice/abservice.asmx',
        {'content-type' => 'text/xml; charset=utf-8',
         SOAPAction =>
             '"http://www.msn.com/webservices/AddressBook/ABContactDelete"'
        },
        sprintf(<<'XML', $token, $contact),
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
   xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/">
     <soap:Header>
        <ABApplicationHeader xmlns="http://www.msn.com/webservices/AddressBook">
            <ApplicationId>CFE80F9D-180F-4399-82AB-413F33A1FA11</ApplicationId>
            <IsMigration>false</IsMigration>
            <PartnerScenario>ContactSave</PartnerScenario>
        </ABApplicationHeader>
        <ABAuthHeader xmlns="http://www.msn.com/webservices/AddressBook">
            <TicketToken>%s</TicketToken>
            <ManagedGroupRequest>false</ManagedGroupRequest>
        </ABAuthHeader>
    </soap:Header>
 <soap:Body>
 <ABContactAdd xmlns="http://www.msn.com/webservices/AddressBook">
            <abId>
                00000000-0000-0000-0000-000000000000
            </abId>
            <contacts>
                <Contact xmlns="http://www.msn.com/webservices/AddressBook">
                    <contactInfo>
                        <contactType>LivePending</contactType>
                        <passportName>%s</passportName>
                        <isMessengerUser>true</isMessengerUser>
                        <MessengerMemberInfo>
                        <DisplayName>minimum clorpvfgt</DisplayName>
                        </MessengerMemberInfo>
                    </contactInfo>
                </Contact>
            </contacts>
            <options>
                <EnableAllowListManagement>
                    true
                </EnableAllowListManagement>
            </options>
        </ABContactAdd>
 </soap:Body>
</soap:Envelope>
XML
        sub {

            #dd @_;
            $s->remove_temporary_contact($contact);
            ...;
        }
    );
}

# Remove a contact:
# RML 12 112\r\n
# <ml><d n="penilecolada.com"><c n="junk" t="1"><s l="3" n="IM" /><s l="3" n="PE" /><s l="3" n="PF"/></c></d></ml>
sub add_temporary_contact {
    my $s = shift;
    my %contacts;
    for my $contact (@_) {
        my ($user, $domain) = split /\@/, $contact, 2;
        push @{$contacts{$domain}}, $user;
    }
    my $data = sprintf '<ml%s>%s</ml>', ($s->connected ? '' : ' l="1"'),
        join '', map {
        sprintf '<d n="%s">%s</d>', $_, join '', map {
            sprintf '<c n="%s" t="1">%s</c>', $_, join '',
                map {"<s l='3' n='$_' />"}
                qw[IM PE PF]
            } sort @{$contacts{$_}}
        } sort keys %contacts;
    my $tid = $s->tid;
    $s->send("ADL %d %d\r\n%s", $tid, length($data), $data);
    $tid;
}

sub remove_buddy {
    my $s = shift;
    my $data = sprintf <<'', reverse split '@', shift, 2;
<ml>
    <d n="%s">
        <c n="%s" t="1">
            <s l="3" n="IM" />
            <s l="3" n="PE" />
            <s l="3" n="PF" />
        </c>
    </d>
</ml>

    my $tid = $s->tid;
    $s->send("RML %d %d\r\n%s", $tid, length($data), $data);
    $tid;
}
after set_status => sub {
    my ($s, $status) = @_;
    my $body = sprintf '<user>' . '<s n="PE">
            <UserTileLocation>0</UserTileLocation><FriendlyName>%s</FriendlyName><PSM>%s</PSM><RUM></RUM><RLT>0</RLT></s>'
        . '<s n="IM"><Status>%s</Status><CurrentMedia></CurrentMedia></s>'
        . '<sep n="PD"><ClientType>1</ClientType><EpName>%s</EpName><Idle>false</Idle><State>%s</State></sep>'
        . '<sep n="PE" epid="%s"><VER>MSNMSGR:15.4.3508.1109</VER><TYP>1</TYP><Capabilities>2952790016:557056</Capabilities></sep>'
        . '<sep n="IM"><Capabilities>2953838624:132096</Capabilities></sep>'
        . '</user>', __html_escape($s->friendly_name),
        __html_escape($s->personal_message),
        $status,
        __html_escape($s->location), $status, $s->guid;
    my $out
        = sprintf
        qq[To: 1:%s\r\nRouting: 1.0\r\nFrom: 1:%s;epid=%s\r\n\r\nStream: 1\r\nFlags: ACK\r\nReliability: 1.0\r\n\r\nContent-Length: %d\r\nContent-Type: application/user+xml\r\nPublication: 1.0\r\nUri: /user\r\n\r\n%s],
        $s->passport,
        $s->passport, $s->guid, length($body), $body;
    $s->send("PUT %d %d\r\n%s", $s->tid, length($out), $out);
};

# Testing/Incomplete stuff
sub create_group_chat {
    my $s    = shift;
    my $body = '';      # For now.
    my $out
        = sprintf
        qq[To: 10:00000000-0000-0000-0000-000000000000\@live.com\r\nRouting: 1.0\r\nFrom: 1:%s;epid=%s\r\n\r\nStream: 1\r\nFlags: ACK\r\nReliability: 1.0\r\n\r\nContent-Length: %d\r\nContent-Type: application/multiparty+xml\r\nPublication: 1.0\r\nUri: /circle\r\n\r\n%s],
        $s->passport, $s->guid, length($body), $body;
    $s->send("PUT %d %d\r\n%s", $s->tid, length($out), $out);
}

# Random private methods
sub _parse_xml {
    my ($s, $data) = @_;
    state $xml_twig //= XML::Twig->new();
    my $xml = {};
    use Carp;

=begin comment Carp::confess('...') if ! length $data ;
=cut
    try {
        $xml_twig->parse($data);
        $xml = $xml_twig->simplify(keyattr => [qw[type id value]]);
    }
    catch { $s->_trigger_fatal_error(qq[parsing XML: $_]) };
    $xml;
}

# Non-OOP utility functions
sub __html_escape {
    my $x = shift;
    $x =~ s[&][&amp;]sg;
    $x =~ s[<][&lt;]sg;
    $x =~ s[>][&gt;]sg;
    $x =~ s["][&quot;]sg;
    $x;
}

sub __html_unescape {
    my $x = shift;
    $x =~ s[&lt;][<]sg;
    $x =~ s[&gt;][>]sg;
    $x =~ s[&quot;]["]sg;
    $x =~ s[&amp;][&]sg;
    $x;
}

#
__PACKAGE__->meta->make_immutable();
no Moose;
1;

=pod

=head1 NAME

AnyEvent::MSN - Simple, Less Annoying Client for Microsoft's Windows Live Messenger Network

=head1 Synopsis

    use AnyEvent::MSN;
    my $msn = AnyEvent::MSN->new(
        passport => 'you@hotmail.com',
        password => 'sekrit',
        on_im => sub { # Simiple echo bot
            my ($msn, $head, $body) = @_;
            $msn->im($head->{From}, $body)
        }
    );
    AnyEvent->condvar->recv;

=head1 Description

TODO

=head1 Methods

Well, the public bits anyway...

=over

=item new

    my $msn = AnyEvent::MSN->new(passport => 'you@hotmail.com', password => 'password');

This constructs a new L<AnyEvent::MSN> object. Required parameters are:

=over

=item C<passport>

This is an email address.

Microsoft calls them C<passport>s in some documentation, C<username> and plain
ol' C<address> in other places. For future versions of the API (think 1.0),
I'm leaning towards the least awkward: C<username>. Just... keep that in mind.

=item C<password>

It's... your... password.

=back

Optional parameters to C<new> include...

=over

=item C<status>

This will be used as your initial online status. Please see the section
entitled L<Online Status|/"Online Status"> for more information.

=item C<friendly_name>

This sets the display or friendly name for the client. This is what your
friends see on their buddylists.

=item C<personal_message>

This is the short message typically shown below the friendly name.

=item C<no_autoconnect>

Normally, L<AnyEvent::MSN-E<gt>new( ... )|/new> automatically initiates the
L<client login|/connect> stage. If this is set to a true value, that doesn't
happen and you'll need to call L<connect|/connect> yourself.

=item C<on_connect>

This is callback is triggered when we have completed the login stage but
before we set our initial status.

=item C<on_im>

This callback is triggered when we receive an instant message. It is passed
the raw headers (which contain a 'From' value) and the actual message.

=item C<on_nudge>

This callback is triggered when we recieve a nudge. The callback is passed the
raw headers (which contain a 'From' value).

=item C<on_error>

This callback is triggered when we meet any sort of non-fatal error. This
callback is passed a texual message for display.

=item C<on_fatal_error>

This callback is triggered when we meet an error which prevents normal client
operations. This could be a major SOAP error or even an unexpected disconnect.
This callback is passed a textual message for display.

=item C<on_user_notification>

    ...
    on_user_notification => sub { my ($s, $head, $presence) = @_; ... }
    ...

This callback is triggered when a contact updates their public information.
Simple Online/Offline status changes are included in this as well as friendly
name changes and current media (now playing) status.

=back

=item connect

Initiates the logon process. You should only need to call this if you passed
C<no_autoconnect =E<gt> 1> to L<the constructor|/new>.

=item im

    $msn->send_message('buddy@hotmail.com', 'oh hai!');

This sends an instant message.

C<send_message( ... )> supports a third parameter, a string to indicate how
the message shoud be displayed. The default is
C<FN=Segoe%20UI; EF=; CO=0; CS=1; PF=0>. Uh, we break that down a little in
L<the notes|/"Text Format"> below.

=item nudge

    $msn->nudge('buddy@hotmail.com');

This sends a nudge to the other person. It's called nudge in the protocol
itself and in pidgin but in the the official client it's called 'Attention'
and may (depending on the buddy's settings) make the IM window jiggle on
screen for a second. ...which, I suppose, won the contest for the most
annoying behaviour they could come up with.

=item add_contact

    $msn->add_contact('silas@live.com');   # Temporary
    $msn->add_contact('mark@hotmail.com'); # Persistant

This adds a buddy to your temporary list of contacts.

'Add List' command, uses XML to identify each contact, and works as a payload
message. Each ADL command may contain up to 150 contacts (a payload of roughly
7500 bytes). The format of the payload looks like this:
<ml l="1">
    <d n="domain">
        <c n="email" l="3" t="1" />
    </d>
</ml>
Elements:
ml: the meaning of l is unknown (thought to mean initial listing due to the
    fact that it is only sent in the initial ADL)
d (domain): contacts are grouped by domain, where n is the domain name (the
    part after the @ symbol in the email address)
c (contact): n is the name or the part before the @ symbol in the email
    address, l is the list bit flag (i.e. 1 for FL, 2 for AL, 4 for BL) and t
    is the contact type (1 for a Passport, 4 for a mobile phone, other values
    are still unknown)
Note: you can send all your contacts in just one ADL command by putting
    multiple 'd' elements (with the sub-elements of course) for each contact
    e.g.:
<ml l="1">
    <d n="domain1">
        <c n="email1" l="3" t="1" />
    </d>
    <d n="domain2">
        <c n="email2" l="5" t="4" />
    </d>
</ml>
Sending ADL to the server:
>>> ADL (TrId) (PayloadLength)\r\n
Then send your payload:
>>> <ml l="1"><d n="domain"><c n="email" l="3" t="1" /></d></ml>
The payload must not contain any 'whitespace' characters (i.e. returns, tabs or spaces) between tags or at the beginning or end, or the server will reply with error 240 or 241.
The server responds to a successful ADL command with:
ADL (TrId) OK
Initial ADL listing
Once the client has retrieved the contact list with a new set of SOAP requests (see MSNP13:Contact_List), it will send the information about the contacts on the list to the server with an ADL command. In this ADL, the <ml> node often seems to contain the attribute l, set to 1. However, the client does not always appear to send this attribute in the official listing!
You must include everyone on your Forward List (FL), Allow List (AL) and Block List (BL). If you don't, anyone you fail to include will be removed from their respective lists. Also note that the official client does not include contacts on the RL and PL in the initial listing. In fact, if you send the RL and PL bits in the ADL, the server will reject your ADL command, and possibly disconnect you.
You MUST send your privacy settings (BLP command), then ADL and finally your display name (PRP command) in that order or the server will ignore your ADL. These are retrieved using the ABFindAll SOAP request.
After receiving ADL (TrId) OK, you must set your initial presence (CHG command). If you send CHG before ADL, the servers will not dispatch your presence to other clients.

=item remove_buddy

    $msn->remove_buddy('buddy@hotmail.com');

The remove contacts from your lists. Note that you may only remove people from
the FL, AL and BL using this command (which makes sense, seeing as you can
also only add people to the FL, AL and BL with the L<add_contact|/add_contact>
command). Also note that the contact will not be removed from your server-side
address book - for this, you will have to use the ABContactDelete SOAP
request. ...which we don't support yet.

=back

=head1 Notes

This is where random stuff will go. The sorts of things which may make life
somewhat easier for you but are easily skipped.

=head2 Online Status

Your online status not only affects your appearance on other's buddylists, but
can change how your buddies are shown.

=over

=item NLN

Make the client appear Online (after logging in) and send and receive
notifications about buddies.

This is the default.

=item FLN

Make the client Offline. If the client is already online, offline
notifications will be sent to users on the RL. No message activity is allowed.
In this state, the client can only synchronize the lists as described above.

=item HDN

Make the client appear Hidden/Invisible. If the client is already
online, offline notifications will be sent to users on the RL. The client will
appear as Offline to others but can receive online/offline notifications from
other users, and can also synchronize the lists. Clients cannot receive any
instant messages in this state.

=item BSY

Make the client appear Busy. This is a sub-state of NLN.

=item IDL

Make the client appear Idle. This is a sub-state of NLN.

=item BRB

Make the client say they'll Be Right Back. This is a sub-state of NLN.

=item AWY

Make the client appear to be Away from their computer. This is a sub-state of
NLN.

=item PHN

Makes the client appear to be on the Phone. This is a sub-state of NLN.

=item LUN

Makes the client appear to be out to Lunch. This is a sub-state of NLN.

=back

=back

=head1 Notes

Get by with a little help...

=head2 Text Format

Messages sent and recieved may contain a special parameter defining how the
message should be displayed. The message format specifies the font (FN),
effect (EF), color (CO), character set (CS) and pitch and family (PF) used for
rendering the text message. The value of the Format element is a string of the
following key/value pairs:

=for url http://msdn.microsoft.com/en-us/library/bb969558(v=office.12).aspx

=over

=item FN

Specifies a font name. The font name must be URL-encoded. For example, to have
a font of "MS Sans Serif", you would have to specify C<FN=MS%20Sans%20Serif>.
Font names are not case-sensitive and only spaces should be URL-encoded.
URL-encoding other characters such as numbers and letters cause unpredictable
results in other clients.

According to MS, if the receiving client does not have the specified font, it
should make judgment based on the PF and CS parameters. Basically, the client
should select whichever available font supports the character set specified in
CS and is closest to the category specified in PF. If those parameters are not
present, the client should just use a default font.

=item EF

Specifies optional style effects. Possible effects are bold, italic,
underline, and strikethrough. Each effect is referred to by its first letter.
For example, to make bold-italic text, include the parameter C<EF=IB> or
C<EF=BI>. The order does not matter. Any unknown effects are to be ignored.
If there are no effects, just leave the parameter value blank.

=item CO

Specifies a font color. The value of the CO field is a six-character
hex BGR (Note that this is I<blue-green-red>, the I<reverse> of the standard
RGB order seen in HTML) string. The first two characters represent a hex
number from C<00> to C<ff> for the intensity of blue, the second two are for
green, and the third two are for red. For example, to make a full red color,
send C<CO=0000ff>.

Again, this should be in BGR; the I<reverse> of the standard RGB order seen in
HTML.

=item CS

Character sets are identified in the CS parameter with one or two hexadecimal
digits (leading zeros are dropped by the official client and are ignored if
present), representing the numerical value Windows uses for the character set.
The following table shows the full list of the predefined character sets that
are included with the Microsoft® Windows® operating system.

    Val Description
    -------------------------------------------------------------------------
    00  ANSI characters
    01  Font is chosen based solely on name and size. If the described font is
        not available on the system, you should substitute another font.
    02  Standard symbol set
    4d  Macintosh characters
    80  Japanese shift-JIS characters
    81  Korean characters (Wansung)
    82  Korean characters (Johab)
    86  Simplified Chinese characters (China)
    88  Traditional Chinese characters (Taiwan)
    a1  Greek characters
    a2  Turkish characters
    a3  Vietnamese characters
    b1  Hebrew characters
    b2  Arabic characters
    ba  Baltic characters
    cc  Cyrillic characters
    de  Thai characters
    ee  Sometimes called the "Central European" character set, this includes
        diacritical marks for Eastern European countries
    ff  Depends on the codepage of the operating system

You should not assume that clients receiving your messages understand all
character sets. This character set is arbitrary, but it is advisable to make
it the one that causes the most characters to be displayed correctly.

=item PF

The PF family defines the category that the font specified in the FN parameter
falls into. This parameter is used by the receiving client if it does not have
the specified font installed. The value is a two-digit hexadecimal number.
If you're familiar with the Windows APIs, this value is the PitchAndFamily
value in RichEdit and LOGFONT.

The first digit of the value represents the font family. Below is a list of
numbers for the first digit and the font families they represent.

    First Digit     Description
    -------------------------------------------------------------------------
    0_              Specifies a generic family name. This name is used when
                    information about a font does not exist or does not
                    matter. The default font is used.
    1_              Specifies a proportional (variable-width) font with
                    serifs. An example is Times New Roman.
    2_              Specifies a proportional (variable-width) font without
                    serifs. An example is Arial.
    3_              Specifies a Monospace font with or without serifs.
                    Monospace fonts are usually modern; examples include Pica,
                    Elite, and Courier New.
    4_              Specifies a font that is designed to look like
                    handwriting; examples include Script and Cursive.
    5_              Specifies a novelty font. An example is Old English.

The second digit represents the pitch of the font — in other words, whether it
is monospace or variable-width.

    Second Digit    Description
    -------------------------------------------------------------------------
    _0              Specifies a generic font pitch. This name is used when
                    information about a font does not exist or does not
                    matter. The default font pitch is used.
    _1              Specifies a fixed-width (Monospace) font. Examples are
                    Courier New and Bitstream Vera Sans Mono.
    _2              Specifies a variable-width (proportional) font. Examples
                    are Times New Roman and Arial.

Below are some PF values and example fonts that fit the category.

    Examples of PF Value    Description
    -------------------------------------------------------------------------
    12                      Times New Roman, MS Serif, Bitstream Vera Serif
    22                      Arial, Verdana, MS Sans Serif, Bitstream Vera Sans
    31                      Courier New, Courier
    42                      Comic Sans MS

=head1 TODO

These are things I have plans to do with L<AnyEvent::MSN> but haven't found
the time to complete them. If you'd like to help or have a suggestion for new
feature, see the project pages on
L<GitHub|http://github.com/sanko/anyevent-msn>.

=over

=item P2P Transfers

MSNP supports simple file transfers, handwritten IMs, voice chat, and even
webcam sessions through the P2P protocol. The protocol changed between MSNP18
and MSNP21 and I'll need to implement both. ...I'll get to it eventually.

=item Group Chat

MSNP21 redefinied the switchboard concept including how group chat sessions
are initiated and handled.

=item Internal State Cleanup

Things like the address book are very difficult to use because (for now) I
simply store the parsed XML Microsoft sends me.

=item Correct Client Capabilities

They (and a few other properties) are all hardcoded values taken from MSN 2011
right now.

=back

=head1 See Also

=over

=item L<Net::MSN|Net::MSN>

=item L<MSN::PersonalMessage|MSN::PersonalMessage>

=item L<POE::Component::Client::MSN|POE::Component::Client::MSN>

=item L<Net::Msmgr::Session|Net::Msmgr::Session>

=back

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2011-2012 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Some protocol descriptions taken from text Copyright 2011, Microsoft.

Neither this module nor the L<Author|/Author> is affiliated with Microsoft.

=cut
