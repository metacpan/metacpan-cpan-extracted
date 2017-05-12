package CDR::Parser::SI3000;

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use IO::File ();

=head1 NAME

CDR::Parser::SI3000 - parser for binary CDR files (*.ama) produced by Iskratel SI3000 MSCN telephony product

CDR = Call Detail Records

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';

our $VERBOSE = 0;

=head1 SYNOPSIS

Whis module parses the binary file format and returns it as Perl data.

Usage example

    use CDR::Parser::SI3000;

    my ($cdr_list, $num_failed) = CDR::Parser::SI3000->parse_file('somefile.ama');

There
    $cdr_list is a array-reference containing individual records as hash-ref.
    $num_failed is a number of unparseable records


=head1 SUBROUTINES/METHODS

=head2 parse_file

Get filename as input, open it, read it, returns the parsed result

=cut


#--

# $| = 1;

sub _log {
    my($format, @args) = @_;
    return if(! $VERBOSE);
    printf $format."\n", @args;
}

# public
sub parse_file {
    my($class, $filename) = @_;
    die "No filename argument" if(! $filename);
    _log('Parsing file %s', $filename);

    my $fh = IO::File->new($filename) || die "Failed to open $filename - $!";
    binmode($fh, ':bytes');

    my @records = ();

    my $rows = 0;
    my $failed = 0;

    while(1) {
        my $call = parse_record($fh);
        if($call) {
            push @records, $call;
        }
        else {
            last if($call == 0);
            $failed++;
        }
    }

    $fh->close;

    return (\@records, $failed);
}

#------ private implementation ------

# 100. Called number
sub block_100 {
    my($call,$variable) = @_;

    _log('100. Called number');
    my $cld_len;
    ($cld_len, $$variable) = unpack('C a*', $$variable);
    my $cut = $cld_len;
    $cut++ if($cld_len % 2 == 1);
    my $cld;
    ($cld, $$variable) = unpack("H$cut a*", $$variable);
    if($cut > $cld_len) {
        $cld = substr($cld, 0, -1);
    }
    _log('  CLD: %s', $cld);
    $call->{cld} = $cld;
}

# 101. Call accepting party number
# 102. Start Date and Time
sub block_102 {
    my($call, $var) = @_;
    _log("102. Start Date and Time");
    my($year,$month,$day,$hour,$min,$sec,$msec,$reserved);
    ($year,$month,$day,$hour,$min,$sec,$msec,$reserved,$$var) = unpack('CCCCCCC H2 a*', $$var);
    $year += 2000;
    my $start_time = sprintf "%04d-%02d-%02d %02d:%02d:%02d.%02d", $year,$month,$day,$hour,$min,$sec,$msec;
    _log('  Start Time: %s', $start_time);
    $call->{start_time} = $start_time;
}
# 103. End Date and Time
sub block_103 {
    my($call, $var) = @_;
    _log("103. End Date and Time");
    my($year,$month,$day,$hour,$min,$sec,$msec,$reliable);
    ($year,$month,$day,$hour,$min,$sec,$msec,$reliable,$$var) = unpack('CCCCCCC H2 a*', $$var);
    $year += 2000;
    my $end_time = sprintf "%04d-%02d-%02d %02d:%02d:%02d.%02d", $year,$month,$day,$hour,$min,$sec,$msec;
    _log('  End Time: %s', $end_time);
    $call->{end_time} = $end_time;
}
# 104. Number of charging units
sub block_104 {
    my($call, $var) = @_;
    _log("104. Number of charging units");
    my($unit1,$unit2,$unit3);
    ($unit1,$unit2,$unit3,$$var) = unpack('CCC a*', $$var);
    my $units = ($unit1 << 16) + ($unit2 << 8) + $unit3;
    _log('  Units: %d', $units);
    $call->{charging_units} = $units;
}
# 105. Basic service
sub block_105 {
    my($call, $var) = @_;
    _log("105. Basic service");
    my %bearer_label = (
        0 => '64 kbit/s for speech information transfer',
        8 => '64 kbit/s unrestricted',
        16 => '64 kbit/s for 3.1kHz audio information transfer',
    );
    my %service_label = (
        1 => 'Telephony',
        # .... TODO
    );
    my($bearer,$service);
    ($bearer,$service,$$var) = unpack('C C a*', $$var);
    _log("  Bearer: %d / %s", $bearer, $bearer_label{ $bearer } // 'UNKNOWN');
    _log("  Service: %d / %s", $service, $service_label{ $service } // 'UNKNOWN');
    $call->{bearer} = $bearer_label{ $bearer } // 'UNKNOWN';
    $call->{bearer_code} = $bearer;
    $call->{service} = $service_label{ $service } // 'UNKNOWN';
    $call->{service_code} = $service;
}
# 106. Supplementary service used by calling subscriber
sub block_106 {
    my($call, $var) = @_;
    _log('106. Supplementary service used by calling subscriber');
    my($sup_service);
    ($sup_service, $$var) = unpack('C a*', $$var);
    _log('  Supplementary calling service: %d', $sup_service);
    $call->{supplementary_calling_service} = $sup_service;
}
# 107. Supplementary service used by called subscriber
sub block_107 {
    my($call, $var) = @_;
    _log('106. Supplementary service used by called subscriber');
    my($sup_service);
    ($sup_service, $$var) = unpack('C a*', $$var);
    _log('  Supplementary called service: %d', $sup_service);
    $call->{supplementary_called_service} = $sup_service;
}
# 108. Subscriber controlled input
# 109. Dialed digits
# 110. Origin category
sub block_110 {
    my($call, $var) = @_;
    _log("110. Origin category");
    my($origin);
    ($origin,$$var) = unpack('C a*', $$var);
    _log("  Origin category: %d", $origin);
    $call->{origin_category} = $origin;
}
# 111.  Tariff direction
sub block_111 {
    my($call, $var) = @_;
    _log("111. Tariff direction");
    my($tariff);
    ($tariff,$$var) = unpack('C a*', $$var);
    _log("  Tariff direction: %d", $tariff);
    $call->{tariff_direction} = $tariff;
}
# 112. Call failure cause
# 113. Incoming trunk data
sub block_113 {
    my($call, $var) = @_;
    _log("113. Incoming trunk data");
    my($group,$id,$shelf,$port,$channel);
    ($group,$id,$shelf,$port,$channel,$$var) = unpack('n n C n C a*', $$var);
    _log("  Trunk group: %d\n  Trunk identification: %d\n  Shelf identification: %d\n  Port identification: %d\n  Channel identification: %d",
            $group,$id,$shelf,$port,$channel);
    $call->{incoming_trunk_group} = $group;
    $call->{incoming_trunk} = $id;
    $call->{incoming_shelf} = $shelf;
    $call->{incoming_port} = $port;
    $call->{incoming_channel} = $channel;
}
# 114. Outgoing trunk data
sub block_114 {
    my($call, $var) = @_;
    _log("114. Outgoing trunk data");
    my($group,$id,$shelf,$port,$channel);
    ($group,$id,$shelf,$port,$channel,$$var) = unpack('n n C n C a*', $$var);
    _log("  Trunk group: %d\n  Trunk identification: %d\n  Shelf identification: %d\n  Port identification: %d\n  Channel identification: %d",
            $group,$id,$shelf,$port,$channel);
    $call->{outgoing_trunk_group} = $group;
    $call->{outgoing_trunk} = $id;
    $call->{outgoing_shelf} = $shelf;
    $call->{outgoing_port} = $port;
    $call->{outgoing_channel} = $channel;
}
# 115. Call duration
sub block_115 {
    my($call, $var) = @_;
    _log("115. Call duration");
    my($duration);
    ($duration,$$var) = unpack('N a*', $$var);
    _log("  Call duration: %d msec / %.5f sec", $duration, $duration / 1000.0);
    $call->{call_duration} = sprintf '%.5f', $duration / 1000.0;
    $call->{call_duration_ms} = $duration;
}
# 116. Checksum
sub block_116 {
    my($call, $var) = @_;
    _log("116. Checksum");
    my($len,$checksum);
    ($len,$checksum,$$var) = unpack('C a2 a*', $$var);
    _log("  Checksum: 0x%s", unpack('H*', $checksum));;
    $call->{checksum} = unpack('H*', $checksum);
}
# 117. Business and Centrex group ID
sub block_117 {
    my($call, $var) = @_;
    _log("117. Business and Centrex group ID");
    my($len,$business,$centrex);
    ($len,$business,$centrex,$$var) = unpack('C N N a*', $$var);
    _log("  Business group ID: %d", $business);
    _log("  Centrex group ID: %d", $centrex);
    $call->{business_group} = $business;
    $call->{centrex_group} = $centrex;
}
# 118. Carrier access code
# 119. Original calling party number
sub block_119 {
    my($call, $var) = @_;
    _log("119. Original calling party number");
    my($len,$num_len);
    ($len,$num_len,$$var) = unpack('C C a*', $$var);
    my $cut = $num_len;
    $cut++ if($num_len %2 == 1);
    my $num;
    ($num,$$var) = unpack("H$cut a*", $$var);
    if($cut > $num_len) {
        $num = substr($num, 0, -1);
    }
    _log("  Original CLI: %s", $num);
    $call->{original_cli} = $num;
}
# 120. Prepaid account recharge data
# 121. Call release cause
sub block_121 {
    my($call, $var) = @_;
    _log("121. Call release cause");
    my %cause_label = (
        16 => 'normal call clearing',
        41 => 'temporary failure',
    );
    my %coding_label = (
        0 => 'ITU-T standard',
    );
    my %location_label = (
        0  => 'user',
        1  => 'private network serving the local user',
        2  => 'public network serving the local user',
        3  => 'transit network',
        4  => 'public network serving the remote user',
        5  => 'private network serving the remote user',
        7  => 'international network',
        10 => 'network beyond interworking point',
    );
    my($len,$cause,$flag);
    ($len,$cause,$flag,$$var) = unpack('C n C a*', $$var);
    my $coding = (($flag & 0xF0) >> 4);
    my $location = ($flag & 0x0F);
    _log("  Cause: %d / %s", $cause, $cause_label{ $cause } // 'UNKNOWN');;
    _log("  Coding standard: %d / %s", $coding, $coding_label{ $coding } // 'UNKNOWN');
    _log("  Location: %d / %s", $location, $location_label{ $location } // 'UNKNOWN');
    $call->{call_release_cause} = $cause_label{ $cause } // 'UNKNOWN';
    $call->{call_release_cause_code} = $cause;
    $call->{call_coding_standard} = $coding_label{ $coding } // 'UNKNOWN';
    $call->{call_coding_standard_code} = $coding;
    $call->{call_location} = $location_label{ $location } // 'UNKNOWN';
    $call->{call_location_code} = $location;
}
# 122. CBNO (Charge Band Number)
# 123. Common call ID
# 124. Durations before answer
# 125. VoIP Info (old)
# 126. Amount of Transferred Data (old)
# 127. IP Address
sub block_127 {
    my($call, $var) = @_;
    _log("127. IP Address");
    my($len,$ip_data);
    ($len,$$var) = unpack('C a*', $$var);
    $len -= 2;
    ($ip_data,$$var) = unpack("a$len a*", $$var);
    my($flag,$reserved,@ip);
    ($flag,$reserved,@ip) = unpack('C C N*', $ip_data);
    @ip = map { join '.', unpack 'C4', pack 'N', $_ } @ip;
    if($flag & 0x1) {
        my $ip = shift(@ip);
        _log("  Origin side remote RTP IP: %s", $ip);
        $call->{origin_remote_rtp} = $ip;
    }
    if($flag & 0x2) {
        my $ip = shift(@ip);
        _log("  Origin side local RTP IP: %s", $ip);
        $call->{origin_local_rtp} = $ip;
    }
    if($flag & 0x4) {
        my $ip = shift(@ip);
        _log("  Terminating side remote RTP IP: %s", $ip);
        $call->{terminating_remote_rtp} = $ip;
    }
    if($flag & 0x8) {
        my $ip = shift(@ip);
        _log("  Terminating side local RTP IP: %s", $ip);
        $call->{terminating_local_rtp} = $ip;
    }
    if($flag & 0x10) {
        my $ip = shift(@ip);
        _log('  Origin side remote signaling IP: %s', $ip);
        $call->{origin_remote_signaling} = $ip;
    }
    if($flag & 0x20) {
        my $ip = shift(@ip);
        _log('  Origin side local signaling IP: %s', $ip);
        $call->{origin_local_signaling} = $ip;
    }
    if($flag & 0x40) {
        my $ip = shift(@ip);
        _log('  Terminating side remote signaling IP: %s', $ip);
        $call->{terminating_remote_signaling} = $ip;
    }
    if($flag & 0x80) {
        my $ip = shift(@ip);
        _log('  Terminating side local signaling IP: %s', $ip);
        $call->{terminating_local_signaling} = $ip;
    }
}
# 128. VoIP info
sub block_128 {
    my($call, $var) = @_;
    _log("128. VoIP info");
    my($len,$rx_codec,$tx_codec,$rx_period,$tx_period,$rx_bandwidth,$tx_bandwidth,$max_jitter,$flag);
    ($len,$rx_codec,$tx_codec,$rx_period,$tx_period,$rx_bandwidth,$tx_bandwidth,$max_jitter,$flag,$$var) = unpack('CCCCCnnnC a*', $$var);
    my %codec_label = (
         0   => 'Undefined',
         8   => 'G711Alaw64k',
         9   => 'G711Ulaw64k',
         66  => 'G728',
         67  => 'G729',
         68  => 'G729annexA',
         70  => 'G729wAnnexB',
         71  => 'G729AnnexAwAnnexB',
         72  => 'GsmFullRate',
         80  => 'G7231A5_3k',
         81  => 'G7231A6_3k',
         129 => 'FaxT38',
    );
    my %side_label = ( 0 => 'origin side', 1 => 'terminating side');
    my %type_label = (
        0 => 'Undefined',
        1 => 'Audio',
        2 => 'Data',
        3 => 'Fax',
    );

    _log("  Rx codec: %d / %s", $rx_codec, $codec_label{ $rx_codec } // 'UNKNOWN');
    _log("  Tx codec: %d / %s", $tx_codec, $codec_label{ $tx_codec } // 'UNKNOWN');
    _log("  Rx packetization period: %d ms", $rx_period);
    _log("  Tx packetization period: %d ms", $tx_period);
    _log("  Rx bandwidth: %d kbit/s", $rx_bandwidth);
    _log("  Tx bandwidth: %d kbit/s", $tx_bandwidth);
    _log("  Max. jitter buffer size: %d ms", $max_jitter);
    my $call_side = ($flag & 0x80) >> 7;
    my $call_type = $flag & 0x7F;
    _log("  Call side: %d / %s", $call_side, $side_label{ $call_side } // 'UNKNOWN');
    _log("  VoIP call type: %d / %s", $call_type, $type_label{ $call_type } // 'UNKNOWN');

    $call->{voip_rx_codec} = $codec_label{ $rx_codec } // 'UNKNOWN';
    $call->{voip_rx_codec_code} = $rx_codec;
    $call->{voip_tx_codec} = $codec_label{ $tx_codec } // 'UNKNOWN';
    $call->{voip_tx_codec_code} = $tx_codec;
    $call->{voip_rx_packetization} = $rx_period;
    $call->{voip_tx_packetization} = $tx_period;
    $call->{voip_rx_bandwidth} = $rx_bandwidth;
    $call->{voip_tx_bandwidth} = $tx_bandwidth;
    $call->{voip_max_jitter} = $max_jitter;
    $call->{voip_call_side} = $side_label{ $call_side } // 'UNKNOWN';
    $call->{voip_call_side_code} = $call_side;
    $call->{voip_call_type} = $type_label{ $call_type } // 'UNKNOWN';
    $call->{voip_call_type_code} = $call_type;
}
# 129. Amount of transferred data
sub block_129 {
    my($call, $var) = @_;
    _log("129. Amount of transferred data");
    my($len,$side,$rx_packets,$tx_packets,$rx_octets,$tx_octets,$lost,$jitter,$latency);
    ($len,$side,$rx_packets,$tx_packets,$rx_octets,$tx_octets,$lost,$jitter,$latency,$$var) = unpack('CCNNNNNCC a*', $$var);
    my %side_label = ( 0 => 'origin side', 1 => 'terminating side');
    _log("  Call side: %d / %s", $side, $side_label{ $side } // 'UNKNOWN');
    _log("  Rx packets: %d", $rx_packets);
    _log("  Tx packets: %d", $tx_packets);
    _log("  Rx octets: %d", $rx_octets);
    _log("  Tx octets: %d", $tx_octets);
    _log("  Packets lost: %d", $lost);
    _log("  Average jitter: %d ms", $jitter);
    _log("  Average latency: %d ms", $latency);
    $call->{call_side} = $side_label{ $side } // 'UNKNOWN';
    $call->{rx_packets} = $rx_packets;
    $call->{tx_packets} = $tx_packets;
    $call->{rx_octets} = $rx_octets;
    $call->{tx_octets} = $tx_octets;
    $call->{packets_lost} = $lost;
    $call->{average_jitter} = $jitter;
    $call->{everage_latency} = $latency;
}
# 130. Service control data
# 131. New destination number
# 132. VoIP Quality of Service data (QoS VoIP Data)
# 133. Additional Centrex data
# 134. Additional statistics data
sub block_134 {
    my($call, $var) = @_;
    _log("134. Additional statistics data");
    my($len,$stats);
    ($len,$$var) = unpack('C a*', $$var);
    $len -= 2;
    ($stats,$$var) = unpack("a$len a*", $$var);
    _log("  Stats: 0x%s (len %d)", unpack('H*', $stats), $len);
    # no useful info?
}
# TODO NOT IMPLEMENTED YET:
# 135. IMS charging identifier
# 136. Inter Operator Identifiers – IOI)
# 137. Supplementary service additional info
# 138. Calling Party Number
# 139. Additional calling number
# 140. Called party number
# 141. Sent called party number
# 142. Third party number
# 143. Redirecting party number
# 144. Incoming trunk data - Name
# 145. Outgoing trunk data - name
# 146. Node info
# 147. Global call reference
# 148. MLPP Data
# 149. Customer Data
# 150. Received Called Party Number
# 151. Call Type
# 152. IN Service Data
# 153. URI (Universal Resource Identification)
# 154. Free Format Operator Specific Data
# 155. -----
# 156. Additional Numbers

sub dump_var {
    my $var = shift;
    _log("---- Variable data (%d) ----", length($var));
    _log('%s', unpack('H*', $var));
}

# Parse individual record
#
# Each record has fixed part 16+(2..19) bytes
# and optional set of additional blocks
sub parse_record {
    my $fh = shift;

    my $type_id;
    sysread($fh, $type_id, 1) || return 0;
    my $code = unpack('H2', $type_id);

    # Recort type:
    #  d2 -- Record at date and time changes (parsed but ignored)
    #  d3 -- Record of the loss of a certain amount of records
    #  d4 -- Restart record
    #  c8 -- Call record
    if($code eq 'd2') {
        # record of date and time changes
        parse_time_change_record($fh, $code);
        return parse_record($fh);
    }
    elsif($code eq 'd3'){
        # record of the loss of a certain amount of records
        parse_loss_record($fh, $code);
        return parse_record($fh);
    }
    elsif($code eq 'd4') {
        # restart/reboot
        parse_reboot_record($fh, $code);
        return parse_record($fh);
    }
    elsif($code ne 'c8') {
        die "Unknown record type: $code";
    }
    _log('Found Call Record marker %s', $code);

    my %call = ();

    # Statis header
    #  1 - c8
    #  2 - record length
    #  4 - record index (in file?)
    #  4 - call identifier (sequentially incremented number, unique -
    #                       but incomplete calls can have call-id repeated again in later file)
    #  3 - flags
    #  1 - Sequence (4bits) / Charge status (4bits)
    #  1 - Area code length (3bits) / Subscriber number length  (5bits)
    #  ... - Area code and subscriber number of record owner
    my $len;
    sysread($fh, $len, 2) || die $!;
    $len = unpack('n', $len);
    #printf "Record lengh: %d bytes\n", $len;

    my $data;
    sysread($fh, $data, $len - 3) || die $!;
    #print unpack('H*', $data), "\n";

    my($rec_index,$call_id,$flags,$seq,$area,$variable) = unpack('N N H6 H2 C a*', $data);
    _log("Header");
    _log("  Record index: %d", $rec_index);
    _log("  Call ID: %d / %s", $call_id, unpack('H*', pack('N', $call_id)));
    _log("  Flags: 0x%s", unpack('H6', pack('H6', $flags)));
    _log("  Record sequence: %d", (($seq & 0xF0) >> 4));
    _log("  Charge status: %d", ($seq & 0x0F));

    $call{record_index} = $rec_index;
    $call{call_id} = $call_id;
    $call{flags} = $flags;
    $call{record_sequence} = (($seq & 0xF0) >> 4);
    $call{charge_status} = ($seq & 0x0F);

    my($area_len) = ($area & 0xE0) >> 5;
    my($subscriber_len) = ($area & 0x1F);
    _log("  Area code length: %d", $area_len);
    _log("  Subscriber num len: %d", $subscriber_len);
    #my($subscriber_len) = ($area & 0x07);
    #printf "Area/Subscriber: %s / %d . %d\n", $area, $area_len, $subscriber_len;
    #printf "  Area code length: %d\n", $area_len;
    #printf "  Subscriber number length: %d\n", $subscriber_len;

    #printf "---- Variable data (%d) ----\n", length($variable);
    #print unpack('H*', $variable), "\n";

    my $cli_len = $area_len + $subscriber_len;
    if($cli_len % 2 == 1) {
        # padding, each octet for cli contains 2 digits
        $cli_len++;
    }
    my $cli;
    ($cli, $variable) = unpack("H$cli_len a*", $variable);
    if($cli_len > ($area_len + $subscriber_len)) {
        $cli = substr($cli, 0, -1);
    }
    _log("  CLI: %s", $cli);
    $call{cli} = $cli;

    # dynamic part:
    my $block_marker;
    while( length($variable) > 0) {
        # each block has type marker + variable data, which depends on type
        ($block_marker, $variable) = unpack('C a*', $variable);
        #_log('Found block marker: %s', $block_marker);
        {
            no strict 'refs';
            my $sub = 'block_' . $block_marker;
            $sub->(\%call, \$variable);
        }
        #dump_var($variable);
    }

    _log('');
    return \%call;
}

# d2 - time change event
sub parse_time_change_record {
    my ($fh, $code) = @_;

    _log('Found Date Time Change marker %s', $code);

    my $data;
    # 7 - old date and time
    # 7 - new date and time
    # 1 - cause of change
    sysread($fh, $data, 15) || die $!;
    my($year,$month,$day,$hour,$min,$sec,$msec,$reason);
    ($year,$month,$day,$hour,$min,$sec,$msec,$data) = unpack('CCCCCCC a*', $data);
    $year += 2000;
    my $dtime = sprintf "%04d-%02d-%02d %02d:%02d:%02d.%02d", $year,$month,$day,$hour,$min,$sec,$msec;
    _log('  Old Time: %s', $dtime);

    ($year,$month,$day,$hour,$min,$sec,$msec,$reason) = unpack('CCCCCCC C', $data);
    $year += 2000;
    $dtime = sprintf "%04d-%02d-%02d %02d:%02d:%02d.%02d", $year,$month,$day,$hour,$min,$sec,$msec;
    _log('  New Time: %s', $dtime);

    # 1 - The real-time clock correction
    # 2 - Summer / winter time changes
    _log('  Change reason: %s', $reason);
}

# d3 - loss record
sub parse_loss_record {
    my ($fh, $code) = @_;

    _log('Found Loss marker %s', $code);

    my $data;
    # 7 - start date and time
    # 7 - end date and time
    # 4 - number of records lost
    sysread($fh, $data, 18) || die $!;
    my($year,$month,$day,$hour,$min,$sec,$msec,$amount);
    ($year,$month,$day,$hour,$min,$sec,$msec,$data) = unpack('CCCCCCC a*', $data);
    $year += 2000;
    my $dtime = sprintf "%04d-%02d-%02d %02d:%02d:%02d.%02d", $year,$month,$day,$hour,$min,$sec,$msec;
    _log('  Start Time: %s', $dtime);

    ($year,$month,$day,$hour,$min,$sec,$msec,$amount) = unpack('CCCCCCC L', $data);
    $year += 2000;
    $dtime = sprintf "%04d-%02d-%02d %02d:%02d:%02d.%02d", $year,$month,$day,$hour,$min,$sec,$msec;
    _log('  End Time: %s', $dtime);

    _log('  Amount of record loss: %s', $amount);
}

# d4 - System was rebooted
sub parse_reboot_record {
    my ($fh, $code) = @_;
    _log('Found Restart marker %s', $code);

    my $data;
    # 7 - restart date and time
    # 4 - reserved
    sysread($fh, $data, 7) || die $!;
    my($year,$month,$day,$hour,$min,$sec,$msec);
    ($year,$month,$day,$hour,$min,$sec,$msec) = unpack('CCCCCCC', $data);
    $year += 2000;
    my $reboot_time = sprintf "%04d-%02d-%02d %02d:%02d:%02d.%02d", $year,$month,$day,$hour,$min,$sec,$msec;
    _log('  Restart time: %s', $reboot_time);

    # ignored...
    sysread($fh, $data, 4) || die $!;
}

1;
#--

=head1 AUTHOR

Sergey Leschenko, C<< <sergle.ua at gmail.com> >>

=head1 BUGS

Please note that some blocks are not implemented, as I haven't seen them in real data files.

Please report any bugs or feature requests to C<bug-cdr-parser-si3000 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CDR-Parser-SI3000>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CDR::Parser::SI3000


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CDR-Parser-SI3000>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CDR-Parser-SI3000>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CDR-Parser-SI3000>

=item * Search CPAN

L<http://search.cpan.org/dist/CDR-Parser-SI3000/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Sergey Leschenko.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of CDR::Parser::SI3000
