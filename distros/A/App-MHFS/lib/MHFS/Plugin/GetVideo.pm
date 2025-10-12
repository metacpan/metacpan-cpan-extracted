package MHFS::Plugin::GetVideo v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Data::Dumper qw (Dumper);
use Fcntl qw(:seek);
use Feature::Compat::Try;
use Scalar::Util qw(weaken);
use URI::Escape qw (uri_escape);
use Devel::Peek qw(Dump);
no warnings "portable";
use Config;
use MHFS::Process;
use MHFS::Util qw(space2us LOCK_WRITE round shellcmd_unlock ASYNC pid_running read_text_file write_text_file ceil_div);

sub new {
    my ($class, $settings) = @_;

    if($Config{ivsize} < 8) {
        warn("Integers are too small!");
        return undef;
    }

    my $self =  {};
    bless $self, $class;

    $self->{'VIDEOFORMATS'} = {
        'hls' => {'lock' => 0, 'create_cmd' => sub {
            my ($video) = @_;
            return ['ffmpeg', '-i', $video->{"src_file"}{"filepath"}, '-codec:v', 'libx264', '-strict', 'experimental', '-codec:a', 'aac', '-ac', '2', '-f', 'hls', '-hls_base_url', $video->{"out_location_url"}, '-hls_time', '5', '-hls_list_size', '0',  '-hls_segment_filename', $video->{"out_location"} . "/" . $video->{"out_base"} . "%04d.ts", '-master_pl_name', $video->{"out_base"} . ".m3u8", $video->{"out_filepath"} . "_v"]
        }, 'ext' => 'm3u8', 'desired_audio' => 'aac',
        'player_html' => $settings->{'DOCUMENTROOT'} . '/static/hls_player.html'},

        'jsmpeg' => {'lock' => 0, 'create_cmd' => sub {
            my ($video) = @_;
            return ['ffmpeg', '-i', $video->{"src_file"}{"filepath"}, '-f', 'mpegts', '-codec:v', 'mpeg1video', '-codec:a', 'mp2', '-b', '0',  $video->{"out_filepath"}];
        }, 'ext' => 'ts', 'player_html' => $settings->{'DOCUMENTROOT'} . '/static/jsmpeg_player.html', 'minsize' => '1048576'},

        'mp4' => {'lock' => 1, 'create_cmd' => sub {
            my ($video) = @_;
            return ['ffmpeg', '-i', $video->{"src_file"}{"filepath"}, '-c:v', 'copy', '-c:a', 'aac', '-f', 'mp4', '-movflags', 'frag_keyframe+empty_moov', $video->{"out_filepath"}];
        }, 'ext' => 'mp4', 'player_html' => $settings->{'DOCUMENTROOT'} . '/static/mp4_player.html', 'minsize' => '1048576'},

        'noconv' => {'lock' => 0, 'ext' => '', 'player_html' => $settings->{'DOCUMENTROOT'} . '/static/noconv_player.html', },

        'mkvinfo' => {'lock' => 0, 'ext' => ''},
        'fmp4' => {'lock' => 0, 'ext' => ''},
    };

    $self->{'routes'} = [
        [
            '/get_video', \&get_video
        ],
    ];

    return $self;
}

sub get_video {
    my ($request) = @_;
    say "/get_video ---------------------------------------";
    my $packagename = __PACKAGE__;
    my $server = $request->{'client'}{'server'};
    my $self = $server->{'loaded_plugins'}{$packagename};
    my $settings = $server->{'settings'};
    my $videoformats = $self->{VIDEOFORMATS};
    $request->{'responseopt'}{'cd_file'} = 'inline';
    my $qs = $request->{'qs'};
    $qs->{'fmt'} //= 'noconv';
    my %video = ('out_fmt' => $self->video_get_format($qs->{'fmt'}));
    if(defined($qs->{'name'})) {
        if(defined($qs->{'sid'})) {
            $video{'src_file'} = $server->{'fs'}->lookup($qs->{'name'}, $qs->{'sid'});
            if( ! $video{'src_file'} ) {
                $request->Send404;
                return undef;
            }
        }
        else {
            $request->Send404;
            return undef;
        }
        print Dumper($video{'src_file'});
        # no conversion necessary, just SEND IT
        if($video{'out_fmt'} eq 'noconv') {
            say "NOCONV: SEND IT";
            $request->SendFile($video{'src_file'}{'filepath'});
            return 1;
        }
        elsif($video{'out_fmt'} eq 'mkvinfo') {
            get_video_mkvinfo($request, $video{'src_file'}{'filepath'});
            return 1;
        }
        elsif($video{'out_fmt'} eq 'fmp4') {
            get_video_fmp4($request, $video{'src_file'}{'filepath'});
            return;
        }

        if(! -e $video{'src_file'}{'filepath'}) {
            $request->Send404;
            return undef;
        }

        $video{'out_base'} = $video{'src_file'}{'name'};

        # soon https://github.com/video-dev/hls.js/pull/1899
        $video{'out_base'} = space2us($video{'out_base'}) if ($video{'out_fmt'} eq 'hls');
    }
    elsif($videoformats->{$video{'out_fmt'}}{'plugin'}) {
        $video{'plugin'} = $videoformats->{$video{'out_fmt'}}{'plugin'};
        if(!($video{'out_base'} = $video{'plugin'}->getOutBase($qs))) {
            $request->Send404;
            return undef;
        }
    }
    else {
        $request->Send404;
        return undef;
    }

    # Determine the full path to the desired file
    my $fmt = $video{'out_fmt'};
    $video{'out_location'} = $settings->{'VIDEO_TMPDIR'} . '/' . $video{'out_base'};
    $video{'out_filepath'} = $video{'out_location'} . '/' . $video{'out_base'} . '.' . $videoformats->{$video{'out_fmt'}}{'ext'};
    $video{'out_location_url'} = 'get_video?'.$settings->{VIDEO_TMPDIR_QS}.'&fmt=noconv&name='.$video{'out_base'}.'%2F';

    # Serve it up if it has been created
    if(-e $video{'out_filepath'}) {
        say $video{'out_filepath'} . " already exists";
        $request->SendFile($video{'out_filepath'});
        return 1;
    }
    # otherwise create it
    mkdir($video{'out_location'});
    if(($videoformats->{$fmt}{'lock'} == 1) && (LOCK_WRITE($video{'out_filepath'}) != 1)) {
        say "FAILED to LOCK";
        # we should do something here
    }
    if($video{'plugin'}) {
        $video{'plugin'}->downloadAndServe($request, \%video);
        return 1;
    }
    elsif(defined($videoformats->{$fmt}{'create_cmd'})) {
        my @cmd = @{$videoformats->{$fmt}{'create_cmd'}->(\%video)};
        print "$_ " foreach @cmd;
        print "\n";

        video_on_streams(\%video, $request, sub {
        #say "there should be no pids around";
        #$request->Send404;
        #return undef;

        if($fmt eq 'hls') {
            $video{'on_exists'} = \&video_hls_write_master_playlist;
        }

        # deprecated
        $video{'pid'} = ASYNC(\&shellcmd_unlock, \@cmd, $video{'out_filepath'});

        # our file isn't ready yet, so create a timer to check the progress and act
        weaken($request); # the only one who should be keeping $request alive is the client
        $request->{'client'}{'server'}{'evp'}->add_timer(0, 0, sub {
            if(! defined $request) {
                say "\$request undef, ignoring CB";
                return undef;
            }
            # test if its ready to send
            while(1) {
                    my $filename = $video{'out_filepath'};
                    if(! -e $filename) {
                        last;
                    }
                    my $minsize = $videoformats->{$fmt}{'minsize'};
                    if(defined($minsize) && ((-s $filename) < $minsize)) {
                        last;
                    }
                    if(defined $video{'on_exists'}) {
                        last if (! $video{'on_exists'}->($settings, \%video));
                    }
                    say "get_video_timer is destructing";
                    $request->SendLocalFile($filename);
                    return undef;
            }
            # 404, if we didn't send yet the process is not running
            if(pid_running($video{'pid'})) {
                return 1;
            }
            say "pid not running: " . $video{'pid'} . " get_video_timer done with 404";
            $request->Send404;
            return undef;
        });
        say "get_video: added timer " . $video{'out_filepath'};
        });
    }
    else {
        say "out_fmt: " . $video{'out_fmt'};
        $request->Send404;
        return undef;
    }
    return 1;
}

sub video_get_format {
    my ($self, $fmt) = @_;

    if(defined($fmt)) {
        # hack for jsmpeg corrupting the url
        $fmt =~ s/\?.+$//;
        if(defined $self->{VIDEOFORMATS}{$fmt}) {
            return $fmt;
        }
    }

    return 'noconv';
}
sub video_hls_write_master_playlist {
    # Rebuilt the master playlist because reasons; YOU ARE TEARING ME APART, FFMPEG!
    my ($settings, $video) = @_;
    my $requestfile = $video->{'out_filepath'};

    # fix the path to the video playlist to be correct
    my $m3ucontent = do {
        try { read_text_file($requestfile) }
        catch ($e) {
            say "$requestfile does not exist or is not UTF-8";
            ''
        }
    };
    my $subm3u;
    my $newm3ucontent = '';
    foreach my $line (split("\n", $m3ucontent)) {
        # master playlist doesn't get written with base url ...
        if($line =~ /^(.+)\.m3u8_v$/) {
            $subm3u = "get_video?".$settings->{VIDEO_TMPDIR_QS}."&fmt=noconv&name=" . uri_escape("$1/$1");
            $line = $subm3u . '.m3u8_v';
        }
        $newm3ucontent .= $line . "\n";
    }

    # Always start at 0, even if we encoded half of the movie
    #$newm3ucontent .= '#EXT-X-START:TIME-OFFSET=0,PRECISE=YES' . "\n";

    # if ffmpeg created a sub include it in the playlist
    ($requestfile =~ /^(.+)\.m3u8$/);
    my $reqsub = "$1_vtt.m3u8";
    if($subm3u && -e $reqsub) {
        $subm3u .= "_vtt.m3u8";
        say "subm3u $subm3u";
        my $default = 'NO';
        my $forced =  'NO';
        foreach my $sub (@{$video->{'subtitle'}}) {
            $default = 'YES' if($sub->{'is_default'});
            $forced = 'YES' if($sub->{'is_forced'});
        }
        # assume its in english
        $newm3ucontent .= '#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",DEFAULT='.$default.',FORCED='.$forced.',URI="' . $subm3u . '",LANGUAGE="en"' . "\n";
    }
    try { write_text_file($requestfile, $newm3ucontent); }
    catch ($e) { say "writing new m3u failed"; }
    return 1;
}

sub get_video_mkvinfo {
    my ($request, $fileabspath) = @_;
    my $matroska = matroska_open($fileabspath);
    if(! $matroska) {
        $request->Send404;
        return;
    }

    my $obj;
    if(defined $request->{'qs'}{'mkvinfo_time'}) {
        my $track = matroska_get_video_track($matroska);
        if(! $track) {
            $request->Send404;
            return;
        }
        my $gopinfo = matroska_get_gop($matroska, $track, $request->{'qs'}{'mkvinfo_time'});
        if(! $gopinfo) {
            $request->Send404;
            return;
        }
        $obj = $gopinfo;
    }
    else {
        $obj = {};
    }
    $obj->{duration} = $matroska->{'duration'};
    $request->SendAsJSON($obj);
}

sub get_video_fmp4 {
    my ($request, $fileabspath) = @_;
    my @command = ('ffmpeg', '-loglevel', 'fatal');
    if($request->{'qs'}{'fmp4_time'}) {
        my $formattedtime = hls_audio_formattime($request->{'qs'}{'fmp4_time'});
        push @command, ('-ss', $formattedtime);
    }
    push @command, ('-i', $fileabspath, '-c:v', 'copy', '-c:a', 'aac', '-f', 'mp4', '-movflags', 'frag_keyframe+empty_moov', '-');
    my $evp = $request->{'client'}{'server'}{'evp'};
    my $sent;
    print "$_ " foreach @command;
    $request->{'outheaders'}{'Accept-Ranges'} = 'none';

    # avoid bookkeeping, have ffmpeg output straight to the socket
    $request->{'outheaders'}{'Connection'} = 'close';
    $request->{'outheaders'}{'Content-Type'} = 'video/mp4';
    my $sock = $request->{'client'}{'sock'};
    print  $sock  "HTTP/1.0 200 OK\r\n";
    my $headtext = '';
    foreach my $header (keys %{$request->{'outheaders'}}) {
        $headtext .= "$header: " . $request->{'outheaders'}{$header} . "\r\n";
    }
    print $sock $headtext."\r\n";
    $evp->remove($sock);
    $request->{'client'} = undef;
    MHFS::Process->cmd_to_sock(\@command, $sock);
}

sub hls_audio_formattime {
    my ($ttime) = @_;
    my $hours = int($ttime / 3600);
    $ttime -= ($hours * 3600);
    my $minutes = int($ttime / 60);
    $ttime -= ($minutes*60);
    #my $seconds = int($ttime);
    #$ttime -= $seconds;
    #say "ttime $ttime";
    #my $mili = int($ttime * 1000000);
    #say "mili $mili";
    #my $tstring = sprintf "%02d:%02d:%02d.%06d", $hours, $minutes, $seconds, $mili;
    my $tstring = sprintf "%02d:%02d:%f", $hours, $minutes, $ttime;
    return $tstring;
}

sub adts_get_packet_size {
    my ($buf) = @_;
    my ($sync, $stuff, $rest) = unpack('nCN', $buf);
    if(!defined($sync)) {
        say "no pack, len " . length($buf);
        return undef;
    }
    if($sync != 0xFFF1) {
        say "bad sync";
        return undef;
    }

    my $size = ($rest >> 13) & 0x1FFF;
    return $size;
}

sub ebml_read {
    my $ebml = $_[0];
    my $buf = \$_[1];
    my $amount = $_[2];
    my $lastelm = ($ebml->{'elements'} > 0) ? $ebml->{'elements'}[-1] : undef;
    return undef if($lastelm && defined($lastelm->{'size'}) && ($amount > $lastelm->{'size'}));

    my $amtread = read($ebml->{'fh'}, $$buf, $amount);
    if(! $amtread) {
        return $amtread;
    }

    foreach my $elem (@{$ebml->{'elements'}}) {
        if($elem->{'size'}) {
            $elem->{'size'} -= $amtread;
        }
    }
    return $amtread;
}

sub ebml_seek {
    my ($ebml, $position, $whence) = @_;
    ($whence == SEEK_CUR) or die("unsupported seek");
    return undef if(($ebml->{'elements'} > 0) && $ebml->{'elements'}[-1]{'size'} && ($position > $ebml->{'elements'}[-1]{'size'}));
    return undef if(!seek($ebml->{'fh'}, $position, $whence));
    foreach my $elem (@{$ebml->{'elements'}}) {
        if($elem->{'size'}) {
            $elem->{'size'} -= $position;
        }
    }
    return 1;
}

sub read_vint_from_buf {
    my $bufref   = $_[0];
    my $savewidth = $_[1];

    my $width = 1;
    my $value = unpack('C', substr($$bufref, 0, 1, ''));
    for(;;$width++) {
        last if(($value << ($width-1)) & 0x80);
        $width < 9 or return undef;
    }

    length($$bufref) >= ($width-1) or return undef;

    for(my $wcopy = $width; $wcopy > 1; $wcopy--) {
        $value <<= 8;
        $value |= unpack('C', substr($$bufref, 0, 1, ''));
    }

    $$savewidth = $width;
    return $value;
}

sub read_and_parse_vint_from_buf {
    my $bufref = $_[0];
    my $savewidth = $_[1];

    my $width;
    my $value = read_vint_from_buf($bufref, \$width);
    defined($value) or return undef;

    my $andval = 0xFF >> $width;
    for(my $wcopy = $width; $wcopy > 1; $wcopy--) {
        $andval <<= 8;
        $andval |= 0xFF;
    }
    $value &= $andval;
    if(defined $savewidth) {
        $$savewidth = $width;
    }
    return $value;
}

sub read_vint {
    my ($ebml, $val, $savewidth) = @_;
    my $value;
    ebml_read($ebml, $value, 1) or return 0;
    my $width = 1;
    $value = unpack('C', $value);
    for(;;$width++) {
        last if(($value << ($width-1)) & 0x80);
        $width < 9 or return 0;
    }
    $$savewidth = $width;
    my $byte;
    for(; $width > 1; $width--) {
        $value <<= 8;
        ebml_read($ebml, $byte, 1) or return 0;
        $value |= unpack('C', $byte);
    }
    $$val = $value;
    return 1;
}

sub read_and_parse_vint {
    my ($ebml, $val) = @_;
    my $value;
    my $width;
    read_vint($ebml, \$value, \$width) or return 0;
    my $andval = 0xFF >> $width;
    for(;$width > 1; $width--) {
        $andval <<= 8;
        $andval |= 0xFF;
    }
    $value &= $andval;
    $$val = $value;
    return 1;
}

sub ebml_open {
    my ($filename) = @_;
    open(my $fh, "<", $filename) or return 0;
    my $magic;
    read($fh, $magic, 4) or return 0;
    $magic eq "\x1A\x45\xDF\xA3" or return 0;
    my $ebmlheadsize;
    my $ebml = {'fh' => $fh, 'elements' => []};
    read_and_parse_vint($ebml, \$ebmlheadsize) or return 0;
    seek($fh, $ebmlheadsize, SEEK_CUR) or return 0;
    return $ebml;
}

sub ebml_read_element {
    my ($ebml) = @_;
    my $id;
    read_vint($ebml, \$id) or return undef;
    my $size;
    read_and_parse_vint($ebml, \$size) or return undef;
    my $elm = {'id' => $id, 'size' => $size};
    push @{$ebml->{'elements'}}, $elm;
    return $elm;
}

sub ebml_skip {
    my ($ebml) = @_;
    my $elm = $ebml->{'elements'}[-1];
    ebml_seek($ebml, $elm->{'size'}, SEEK_CUR) or return 0;
    pop @{$ebml->{'elements'}};
    return 1;
}

sub ebml_find_id {
    my ($ebml, $id) = @_;
    for(;;) {
        my $elm = ebml_read_element($ebml);
        $elm or return undef;
        if($elm->{'id'} == $id) {
            return $elm;
        }
        #say "id " . $elm->{'id'};
        ebml_skip($ebml) or return undef;
    }
}

sub ebml_make_elms {
    my @elms = @_;
    my @bufstack = ('');
    while(@elms) {
        my $elm = $elms[0];
        if(! $elm) {
            shift @elms;
            $elm = $elms[0];
            $elm->{'data'} = pop @bufstack;
        }
        elsif(! $elm->{'data'}) {
            @elms = (@{$elm->{'elms'}}, undef, @elms);
            push @bufstack, '';
            next;
        }
        shift @elms;
        my $elementid = $elm->{'id'};
        if(! $elementid) {
            print Dumper($elm);
            die;
        }
        $elementid < 0xFFFFFFFF or return undef;
        my $data = \$elm->{'data'};

        my $size = length($$data);
        $size < 0xFFFFFFFFFFFFFF or return undef;
        # pack the id
        my $buf;
        if($elementid > 0xFFFFFF) {
            # pack BE uint32_t
            #$buf = pack('CCCC', ($elementid >> 24) & 0xFF, ($elementid >> 16) & 0xFF, ($elementid >> 8) & 0xFF, $elementid & 0xFF);
            $buf = pack('N', $elementid);
        }
        elsif($elementid > 0xFFFF) {
            # pack BE uint24_t
            $buf = pack('CCC', ($elementid >> 16) & 0xFF, ($elementid >> 8) & 0xFF, $elementid & 0xFF);
        }
        elsif($elementid > 0xFF) {
            # pack BE uint16_t
            #$buf = pack('CC', ($elementid >> 8) & 0xFF, $elementid & 0xFF);
            $buf = pack('n', $elementid);
        }
        else {
            # pack BE uint8_t
            $buf = pack('C', $elementid & 0xFF);
        }

        # pack the size
        if($elm->{'infsize'}) {
            $buf .= pack('C', 0xFF);
        }
        else {
            # determine the VINT width and marker value, and the size needed for the vint
            my $sizeflag = 0x80;
            my $bitwidth = 0x8;
            while($size >= $sizeflag) {
                $bitwidth += 0x8;
                $sizeflag <<= 0x7;
            }

            # Apply the VINT marker and pack the vint
            $size |= $sizeflag;
            while($bitwidth) {
                $bitwidth -= 8;
                $buf .= pack('C', ($size >> $bitwidth) & 0xFF);
            }
        }

        # pack the data
        $buf .= $$data;
        $bufstack[-1] .= $buf;
    }

    return \$bufstack[0];
}


use constant {
    'EBMLID_EBMLHead'           => 0x1A45DFA3,
    'EBMLID_EBMLVersion'        => 0x4286,
    'EBMLID_EBMLReadVersion'    => 0x42F7,
    'EBMLID_EBMLMaxIDLength'    => 0x42F2,
    'EBMLID_EBMLMaxSizeLength'  => 0x42F3,
    'EBMLID_EBMLDocType'        => 0x4282,
    'EBMLID_EBMLDocTypeVer'     => 0x4287,
    'EBMLID_EBMLDocTypeReadVer' => 0x4285,
    'EBMLID_Segment'            => 0x18538067,
    'EBMLID_SegmentInfo'        => 0x1549A966,
    'EBMLID_TimestampScale'     => 0x2AD7B1,
    'EBMLID_Duration'           => 0x4489,
    'EBMLID_MuxingApp'          => 0x4D80,
    'EBMLID_WritingApp'         => 0x5741,
    'EBMLID_Tracks'             => 0x1654AE6B,
    'EBMLID_Track'              => 0xAE,
    'EBMLID_TrackNumber'        => 0xD7,
    'EBMLID_TrackUID'           => 0x73C5,
    'EBMLID_TrackType'          => 0x83,
    'EBMLID_DefaulDuration'     => 0x23E383,
    'EBMLID_CodecID'            => 0x86,
    'EBMLID_CodecPrivData',     => 0x63A2,
    'EBMLID_AudioTrack'         => 0xE1,
    'EBMLID_AudioChannels'      => 0x9F,
    'EBMLID_AudioSampleRate'    => 0xB5,
    'EBMLID_AudioBitDepth'      => 0x6264,
    'EBMLID_Cluster'            => 0x1F43B675,
    'EBMLID_ClusterTimestamp'   => 0xE7,
    'EBMLID_SimpleBlock'        => 0xA3,
    'EBMLID_BlockGroup'         => 0xA0,
    'EBMLID_Block'              => 0xA1
};

sub matroska_cluster_parse_simpleblock_or_blockgroup {
    my ($elm) = @_;

    my $data = $elm->{'data'};
    if($elm->{'id'} == EBMLID_BlockGroup) {
        say "blockgroup";
        while(1) {
            my $width;
            my $id = read_vint_from_buf(\$data, \$width);
            defined($id) or return undef;
            my $size = read_and_parse_vint_from_buf(\$data);
            defined($size) or return undef;
            say "blockgroup item: $id $size";
            last if($id == EBMLID_Block);
            substr($data, 0, $size, '');
        }
        say "IS BLOCK";
    }
    elsif($elm->{'id'} == EBMLID_SimpleBlock) {
        #say "IS SIMPLEBLOCK";
    }
    else {
        die "unhandled block type";
    }
    my $trackno = read_and_parse_vint_from_buf(\$data);
    if((!defined $trackno) || (length($data) < 3)) {
        return undef;
    }
    my $rawts = substr($data, 0, 2, '');
    my $rawflag = substr($data, 0, 1, '');

    my $lacing = unpack('C', $rawflag) & 0x6;
    my $framecnt;
    my @sizes;
    # XIPH
    if($lacing == 0x2) {
        $framecnt = unpack('C', substr($data, 0, 1, ''))+1;
        my $firstframessize = 0;
        for(my $i = 0; $i < ($framecnt-1); $i++) {
            my $fsize = 0;
            while(1) {
                my $val = unpack('C', substr($data, 0, 1, ''));
                $fsize += $val;
                last if($val < 255);
            }
            push @sizes, $fsize;
            $firstframessize += $fsize;
        }
        push @sizes, (length($data) - $firstframessize);
    }
    # EBML
    elsif($lacing == 0x6) {
        $framecnt = unpack('C', substr($data, 0, 1, ''))+1;
        my $last = read_and_parse_vint_from_buf(\$data);
        push @sizes, $last;
        my $sum = $last;
        for(my $i = 0; $i < ($framecnt - 2); $i++) {
            my $width;
            my $offset = read_and_parse_vint_from_buf(\$data, \$width);
            # multiple by 2^bitwidth - 1 (with adjusted bitwidth)
            my $desiredbits = (8 * $width) - ($width+1);
            my $subtract = (1 << $desiredbits) - 1;
            my $result = $offset - $subtract;
            $last += $result;
            say "offset $offset width $width factor: " . sprintf("0x%X ", $subtract) . "result $result evaled $last";
            push @sizes, $last;
            $sum += $last;
        }
        my $lastlast = length($data) - $sum;
        say "lastlast $lastlast";
        push @sizes, $lastlast;
    }
    # fixed
    elsif($lacing == 0x4) {
        $framecnt = unpack('C', substr($data, 0, 1, ''))+1;
        my $framesize = length($data) / $framecnt;
        for(my $i = 0; $i < $framecnt; $i++) {
            push @sizes, $framesize;
        }
    }
    # no lacing
    else {
        push @sizes, length($data);
    }

    return {
        'trackno' => $trackno,
        'rawts' => $rawts,
        'rawflag'  => $rawflag,
        'frame_lengths' => \@sizes,
        'data' => $data,
        'ts' => unpack('s>', $rawts)
    };
}

sub telmval {
    my ($track, $stringid) = @_;
    my $constname = "EBMLID_$stringid";
    my $id = __PACKAGE__->$constname;
    return $track->{$id}{'value'}  // $track->{$id}{'data'};
    #return $track->{"$stringid"}}{'value'} // $track->{$EBMLID->{$stringid}}{'data'};
}

sub trackno_is_audio {
    my ($tracks, $trackno) = @_;
    foreach my $track (@$tracks) {
        if(telmval($track, 'TrackNumber') == $trackno) {
            return telmval($track, 'TrackType') == 0x2;
        }
    }
    return undef;
}

sub flac_read_METADATA_BLOCK {
    my $fh = $_[0];
    my $type = \$_[1];
    my $done = \$_[2];
    my $buf;
    my $headread = read($fh, $buf, 4);
    ($headread && ($headread == 4)) or return undef;
    my ($blocktypelast, $sizehi, $sizemid, $sizelo) = unpack('CCCC',$buf);
    $$done = $blocktypelast & 0x80;
    $$type = $blocktypelast & 0x7F;
    my $size = ($sizehi << 16) | ($sizemid << 8) | ($sizelo);
    #say "islast $$done type $type size $size";
    $$type != 0x7F or return undef;
    my $tbuf;
    my $dataread = read($fh, $tbuf, $size);
    ($dataread && ($dataread == $size)) or return undef;
    $buf .= $tbuf;
    return \$buf;
}

sub flac_parseStreamInfo {
    # https://metacpan.org/source/DANIEL/Audio-FLAC-Header-2.4/Header.pm
    my ($buf) = @_;
    my $metaBinString = unpack('B144', $buf);

    my $x32 = 0 x 32;
    my $info = {};
    $info->{'MINIMUMBLOCKSIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 0, 16), -32)));
    $info->{'MAXIMUMBLOCKSIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 16, 16), -32)));
    $info->{'MINIMUMFRAMESIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 32, 24), -32)));
    $info->{'MAXIMUMFRAMESIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 56, 24), -32)));

    $info->{'SAMPLERATE'}       = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 80, 20), -32)));
    $info->{'NUMCHANNELS'}      = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 100, 3), -32))) + 1;
    $info->{'BITSPERSAMPLE'}    = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 103, 5), -32))) + 1;

    # Calculate total samples in two parts
    my $highBits = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 108, 4), -32)));

    $info->{'TOTALSAMPLES'} = $highBits * 2 ** 32 +
            unpack('N', pack('B32', substr($x32 . substr($metaBinString, 112, 32), -32)));

    # Return the MD5 as a 32-character hexadecimal string
    $info->{'MD5CHECKSUM'} = unpack('H32',substr($buf, 18, 16));
    return $info;
}

sub flac_read_to_audio {
    my ($fh) = @_;
    my $buf;
    my $magic = read($fh, $buf, 4);
    ($magic && ($magic == 4)) or return undef;
    my $streaminfo;
    for(;;) {
        my $type;
        my $done;
        my $bref = flac_read_METADATA_BLOCK($fh, $type, $done);
        $bref or return undef;
        $buf .= $$bref;
        if($type == 0) {
            $streaminfo = flac_parseStreamInfo(substr($$bref, 4));
        }
        last if($done);
    }
    return {'streaminfo' => $streaminfo, 'buf' => \$buf};
}

sub parse_uinteger_str {
    my ($str) = @_;
    my @values = unpack('C'x length($str), $str);
    my $value = 0;
    my $shift = 0;
    while(@values) {
        $value |= ((pop @values) << $shift);
        $shift += 8;
    }
    return $value;
}

sub parse_float_str {
    my ($str) = @_;
    return 0 if(length($str) == 0);

    return unpack('f>', $str) if(length($str) == 4);

    return unpack('d>', $str) if(length($str) == 8);

    return undef;
}

# matroska object needs
# - ebml
# - tsscale
# - tracks
#     - audio track, codec, channels, samplerate
#     - video track, fps
# - duration

sub matroska_open {
    my ($filename) = @_;
    my $ebml = ebml_open($filename);
    if(! $ebml) {
        return undef;
    }

    # find segment
    my $foundsegment = ebml_find_id($ebml, EBMLID_Segment);
    if(!$foundsegment) {
        return undef;
    }
    say "Found segment";
    my %segment = (id => EBMLID_Segment, 'infsize' => 1, 'elms' => []);

    # find segment info
    my $foundsegmentinfo = ebml_find_id($ebml, EBMLID_SegmentInfo);
    if(!$foundsegmentinfo) {
        return undef;
    }
    say "Found segment info";
    my %segmentinfo = (id => EBMLID_SegmentInfo, elms => []);

    # find TimestampScale
    my $tselm = ebml_find_id($ebml, EBMLID_TimestampScale);
    if(!$tselm) {
        return undef;
    }
    say "Found ts elm";
    my $tsbinary;
    if(!ebml_read($ebml, $tsbinary, $tselm->{'size'})) {
        return undef;
    }

    Dump($tsbinary);
    my $tsval = parse_uinteger_str($tsbinary);
    defined($tsval) or return undef;
    say "tsval: $tsval";

    if(!ebml_skip($ebml)) {
        return undef;
    }
    push @{$segmentinfo{'elms'}}, {id => EBMLID_TimestampScale, data => $tsbinary};

    # find Duration
    my $durationelm = ebml_find_id($ebml, EBMLID_Duration);
    if(!$durationelm) {
        return undef;
    }
    say "Found duration elm";
    my $durbin;
    if(!ebml_read($ebml, $durbin, $durationelm->{'size'})) {
        return undef;
    }
    Dump($durbin);
    my $scaledduration = parse_float_str($durbin);

    say "scaledduration $scaledduration";

    my $duration = ($tsval * $scaledduration)/1000000000;
    say "duration: $duration";

    # exit duration
    if(!ebml_skip($ebml)) {
        return undef;
    }

    # exit segment informations
    if(!ebml_skip($ebml)) {
        return undef;
    }

    # find tracks
    my $in_tracks = ebml_find_id($ebml, EBMLID_Tracks);
    if(!$in_tracks) {
        return undef;
    }
    # loop through the Tracks
    my %CodecPCMFrameLength = ( 'AAC' => 1024, 'EAC3' => 1536, 'AC3' => 1536, 'PCM' => 1);
    my %CodecGetSegment = ('AAC' => sub {
        my ($seginfo, $dataref) = @_;
        my $targetpackets = $seginfo->{'expected'} / $CodecPCMFrameLength{'AAC'};
        my $start = 0;
        my $packetsread = 0;
        while(1) {
            my $packetsize = adts_get_packet_size(substr($$dataref, $start, 7));
            $packetsize or return undef;
            say "packet size $packetsize";
            $start += $packetsize;
            $packetsread++;
            if($packetsread == $targetpackets) {
                return {'mime' => 'audio/aac', 'data' => hls_audio_get_id3($seginfo->{'stime'}).substr($$dataref, 0, $start, '')};
            }
        }
        return undef;
    }, 'PCM' => sub {
        my ($seginfo, $dataref) = @_;
        my $targetsize = 2 * $seginfo->{'channels'}* $seginfo->{'expected'};
        if(length($$dataref) >= $targetsize) {
            return {'mime' => 'application/octet-stream', 'data' => substr($$dataref, 0, $targetsize, '')};
        }
        return undef;
    });
    my @tracks;
    for(;;) {
        my $in_track = ebml_find_id($ebml, EBMLID_Track);
        if(! $in_track) {
            ebml_skip($ebml);
            last;
        }
        my %track = ('id' => EBMLID_Track);
        for(;;) {
            my $telm = ebml_read_element($ebml);
            if(!$telm) {
                ebml_skip($ebml);
                last;
            }

            # save the element into tracks
            my %elm = ('id' => $telm->{'id'}, 'data' => '');
            ebml_read($ebml, $elm{'data'}, $telm->{'size'});
            if($elm{'id'} == EBMLID_TrackNumber) {
                say "trackno";
                $elm{'value'} = unpack('C', $elm{'data'});
                $track{$elm{'id'}} = \%elm;
            }
            elsif($elm{'id'} == EBMLID_CodecID) {
                say "codec " . $elm{'data'};
                if($elm{'data'} =~ /^([A-Z]+_)([A-Z0-9]+)(?:\/([A-Z0-9_\/]+))?$/) {
                    $track{'CodecID_Prefix'} = $1;
                    $track{'CodecID_Major'} = $2;
                    if($3) {
                        $track{'CodecID_Minor'} = $3;
                    }
                    $track{'PCMFrameLength'} = $CodecPCMFrameLength{$track{'CodecID_Major'}} if($track{'CodecID_Prefix'} eq 'A_');
                }
                $track{$elm{'id'}} = \%elm;
            }
            elsif($elm{'id'} == EBMLID_TrackType) {
                say "tracktype";
                $elm{'value'} = unpack('C', $elm{'data'});
                $track{$elm{'id'}} = \%elm;
            }
            elsif($elm{'id'} == EBMLID_TrackUID) {
                say "trackuid";
                $track{$elm{'id'}} = \%elm;
            }
            elsif($elm{'id'} == EBMLID_DefaulDuration) {
                say "defaultduration";
                $elm{'value'} = parse_uinteger_str($elm{'data'});
                $track{$elm{'id'}} = \%elm;
                $track{'fps'} = int(((1/($elm{'value'} / 1000000000)) * 1000) + 0.5)/1000;
            }
            elsif($elm{'id'} == EBMLID_AudioTrack) {
                say "audiotrack";
                my $buf = $elm{'data'};
                while(length($buf)) {
                    # read the id, size, and data
                    my $vintwidth;
                    my $id = read_vint_from_buf(\$buf, \$vintwidth);
                    if(!$id) {
                        last;
                    }
                    say "elmid $id width $vintwidth";
                    say sprintf("0x%X 0x%X", ord(substr($buf, 0, 1)), ord(substr($buf, 1, 1)));
                    my $size = read_and_parse_vint_from_buf(\$buf);
                    if(!$size) {
                        last;
                    }
                    say "size $size";
                    my $data = substr($buf, 0, $size, '');

                    # save metadata
                    if($id == EBMLID_AudioSampleRate) {
                        $track{$id} = parse_float_str($data);
                        say "samplerate " . $track{$id};
                    }
                    elsif($id == EBMLID_AudioChannels) {
                        $track{$id} = parse_uinteger_str($data);
                        say "channels " . $track{$id};
                    }
                }
            }

            ebml_skip($ebml);
        }
        # add the fake track
        if(($track{'CodecID_Major'} eq 'EAC3') || ($track{'CodecID_Major'} eq 'AC3')) {
            $track{'faketrack'} = {
                'PCMFrameLength' => $CodecPCMFrameLength{'AAC'},
                &EBMLID_AudioSampleRate => $track{&EBMLID_AudioSampleRate},
                &EBMLID_AudioChannels => $track{&EBMLID_AudioChannels}
            };
            #$track{'outfmt'} = 'PCM';
            #$track{'outChannels'} = $track{&EBMLID_AudioChannels};
            $track{'outfmt'} = 'AAC';
            $track{'outChannels'} = 2;

            $track{'outPCMFrameLength'} = $CodecPCMFrameLength{$track{'outfmt'}};
            $track{'outGetSegment'} = $CodecGetSegment{$track{'outfmt'}};

        }
        push @tracks, \%track;
    }
    if(scalar(@tracks) == 0) {
        return undef;
    }

    my $segmentelm = $ebml->{'elements'}[0];
    my %matroska = ('ebml' => $ebml, 'tsscale' => $tsval, 'rawduration' => $scaledduration, 'duration' => $duration, 'tracks' => \@tracks, 'segment_data_start' => {'size' => $segmentelm->{'size'}, 'id' => $segmentelm->{'id'}, 'fileoffset' => tell($ebml->{'fh'})}, 'curframe' => -1, 'curpaks' => []);
    return \%matroska;
}

sub matroska_get_audio_track {
    my ($matroska) = @_;
    foreach my $track (@{$matroska->{'tracks'}}) {
        my $tt = $track->{&EBMLID_TrackType};
        if(defined $tt && ($tt->{'value'} == 2)) {
            return $track;
        }
    }
    return undef;
}

sub matroska_get_video_track {
    my ($matroska) = @_;
    foreach my $track (@{$matroska->{'tracks'}}) {
        my $tt = $track->{&EBMLID_TrackType};
        if(defined $tt && ($tt->{'value'} == 1)) {
            return $track;
        }
    }
    return undef;
}

sub matroska_read_cluster_metadata {
    my ($matroska) = @_;
    my $ebml = $matroska->{'ebml'};

    # find a cluster
    my $custer = ebml_find_id($ebml, EBMLID_Cluster);
    return undef if(! $custer);
    my %cluster = ( 'fileoffset' => tell($ebml->{'fh'}), 'size' => $custer->{'size'}, 'Segment_sizeleft' => $ebml->{'elements'}[0]{'size'});

    # find the cluster timestamp
    for(;;) {
        my $belm = ebml_read_element($ebml);
        if(!$belm) {
            ebml_skip($ebml);
            last;
        }
        my %elm = ('id' => $belm->{'id'}, 'data' => '');
        #say "elm size " . $belm->{'size'};
        ebml_read($ebml, $elm{'data'}, $belm->{'size'});
        if($elm{'id'} == EBMLID_ClusterTimestamp) {
            $cluster{'rawts'} = parse_uinteger_str($elm{'data'});
            $cluster{'ts'} = $cluster{'rawts'} * $matroska->{'tsscale'};
            # exit ClusterTimestamp
            ebml_skip($ebml);
            # exit cluster
            ebml_skip($ebml);
            return \%cluster;
        }

        ebml_skip($ebml);
    }
    return undef;
}

sub ebml_set_cluster {
    my ($ebml, $cluster) = @_;
    seek($ebml->{'fh'}, $cluster->{'fileoffset'}, SEEK_SET);
    $ebml->{'elements'} = [
        {
            'id' => EBMLID_Segment,
            'size' => $cluster->{'Segment_sizeleft'}
        },
        {
            'id' => EBMLID_Cluster,
            'size' => $cluster->{'size'}
        }
    ];
}

sub matroska_get_track_block {
    my ($matroska, $tid) = @_;
    my $ebml = $matroska->{'ebml'};
    for(;;) {
        my $belm = ebml_read_element($ebml);
        if(!$belm) {
            ebml_skip($ebml); # leave cluster
            my $cluster = matroska_read_cluster_metadata($matroska);
            if($cluster) {
                say "advancing cluster";
                $matroska->{'dc'} = $cluster;
                ebml_set_cluster($ebml, $matroska->{'dc'});
                next;
            }
            last;
        }
        my %elm = ('id' => $belm->{'id'}, 'data' => '');
        #say "elm size " . $belm->{'size'};

        ebml_read($ebml, $elm{'data'}, $belm->{'size'});
        if(($elm{'id'} == EBMLID_SimpleBlock) || ($elm{'id'} == EBMLID_BlockGroup)) {
            my $block = matroska_cluster_parse_simpleblock_or_blockgroup(\%elm);
            if($block && ($block->{'trackno'} == $tid)) {
                ebml_skip($ebml);
                return $block;
            }
        }
        ebml_skip($ebml);
    }
    return undef;
}

sub matroska_ts_to_sample  {
    my ($matroska, $samplerate, $ts) = @_;
    my $curframe = int(($ts * $samplerate / 1000000000)+ 0.5);
    return $curframe;
}

sub matroska_get_gop {
    my ($matroska, $track, $timeinseconds) = @_;
    my $tid = $track->{&EBMLID_TrackNumber}{'value'};

    my $prevcluster;
    my $desiredcluster;
    while(1) {
        my $cluster = matroska_read_cluster_metadata($matroska);
        last if(!$cluster);

        my $ctime = $cluster->{'ts'} / 1000000000;

        # this cluster could have our GOP, save it's info
        if($ctime <= $timeinseconds) {
            $prevcluster = $desiredcluster;
            $desiredcluster = $cluster;
            if($prevcluster) {
                $prevcluster->{'prevcluster'} = undef;
                $desiredcluster->{'prevcluster'} = $prevcluster;
            }
        }

        if($ctime >= $timeinseconds) {
            last;
        }
    }
    say "before dc check";
    return undef if(! $desiredcluster);

    say "cur rawts " . $desiredcluster->{'rawts'};
    say "last rawts " . $desiredcluster->{'prevcluster'}{'rawts'} if($desiredcluster->{'prevcluster'});

    # restore to the the cluster that probably has the GOP
    my $ebml = $matroska->{'ebml'};
    ebml_set_cluster($ebml, $desiredcluster);
    $matroska->{'dc'} = $desiredcluster;

    # find a valid track block that includes pcmFrameIndex;
    my $block;
    my $blocktime;
    while(1) {
        $block = matroska_get_track_block($matroska, $tid);
        if($block) {
            $blocktime = matroska_calc_block_fullts($matroska, $block);
            if($blocktime > $timeinseconds) {
                $block = undef;
            }
            if(! $matroska->{'dc'}{'firstblk'}) {
                $matroska->{'dc'}{'firstblk'} = $blocktime;
            }
        }
        if(! $block) {
            if(! $prevcluster) {
                return undef;
            }
            say "revert cluster";
            $matroska->{'dc'} = $prevcluster;
            ebml_set_cluster($ebml, $matroska->{'dc'});
            next;
        }

        $prevcluster = undef;

        my $blockduration = ((1/24) * scalar(@{$block->{'frame_lengths'}}));
        if($timeinseconds < ($blocktime +  $blockduration)) {
            say 'got GOP at ' . $matroska->{'dc'}{'firstblk'};
            return {'goptime' => $matroska->{'dc'}{'firstblk'}};
            last;
        }
    }

}

sub matroska_seek_track {
    my ($matroska, $track, $pcmFrameIndex) = @_;
    my $tid = $track->{&EBMLID_TrackNumber}{'value'};
    $matroska->{'curframe'} = 0;
    $matroska->{'curpaks'} = [];
    my $samplerate = $track->{&EBMLID_AudioSampleRate};
    my $pcmFrameLen = $track->{'PCMFrameLength'};
    if(!$pcmFrameLen) {
        warn("Unknown codec");
        return undef;
    }
    my $prevcluster;
    my $desiredcluster;
    while(1) {
        my $cluster = matroska_read_cluster_metadata($matroska);
        last if(!$cluster);
        my $curframe = matroska_ts_to_sample($matroska, $samplerate, $cluster->{'ts'});
        #$curframe = int(($curframe/$pcmFrameLen)+0.5)*$pcmFrameLen; # requires revert cluster
        $curframe = ceil_div($curframe, $pcmFrameLen) * $pcmFrameLen;

        # this cluster could contain our frame, save it's info
        if($curframe <= $pcmFrameIndex) {
            $prevcluster = $desiredcluster;
            $desiredcluster = $cluster;
            $desiredcluster->{'frameIndex'} = $curframe;
            if($prevcluster) {
                $prevcluster->{'prevcluster'} = undef;
                $desiredcluster->{'prevcluster'} = $prevcluster;
            }
        }
        # this cluster is at or past the frame, breakout
        if($curframe >= $pcmFrameIndex){
            last;
        }
    }
    say "before dc check";
    return undef if(! $desiredcluster);

    say "cur rawts " . $desiredcluster->{'rawts'};
    say "last rawts " . $desiredcluster->{'prevcluster'}{'rawts'} if($desiredcluster->{'prevcluster'});

    # restore to the the cluster that probably has our audio
    my $ebml = $matroska->{'ebml'};
    ebml_set_cluster($ebml, $desiredcluster);
    $matroska->{'dc'} = $desiredcluster;

    # find a valid track block that includes pcmFrameIndex;
    my $block;
    my $blockframe;
    while(1) {
        $block = matroska_get_track_block($matroska, $tid);
        if($block) {
            $blockframe = matroska_block_calc_frame($matroska, $block, $samplerate, $pcmFrameLen);
            if($blockframe > $pcmFrameIndex) {
                $block = undef;
            }
        }
        if(! $block) {
            if(! $prevcluster) {
                return undef;
            }
            say "revert cluster";
            $matroska->{'dc'} = $prevcluster;
            ebml_set_cluster($ebml, $matroska->{'dc'});
            next;
        }

        $prevcluster = undef;

        my $pcmSampleCount = ($pcmFrameLen * scalar(@{$block->{'frame_lengths'}}));
        if($pcmFrameIndex < ($blockframe +  $pcmSampleCount)) {
            if((($pcmFrameIndex - $blockframe) % $pcmFrameLen) != 0) {
                say "Frame index does not align with block!";
                return undef;
            }
            last;
        }
    }

    # add the data to packs
    my $offset = 0;
    while($blockframe < $pcmFrameIndex) {
        my $len = shift @{$block->{'frame_lengths'}};
        $offset += $len;
        $blockframe += $pcmFrameLen;
    }
    $matroska->{'curframe'} = $pcmFrameIndex;
    foreach my $len (@{$block->{'frame_lengths'}}) {
        push @{$matroska->{'curpaks'}}, substr($block->{'data'}, $offset, $len);
        $offset += $len;
    }
    return 1;
}

sub matroska_calc_block_fullts {
    my ($matroska, $block) = @_;
    say 'clusterts ' . ($matroska->{'dc'}->{'ts'}/1000000000);
    say 'blockts ' . $block->{'ts'};
    my $time = ($matroska->{'dc'}->{'rawts'} + $block->{'ts'}) * $matroska->{'tsscale'};
    return ($time/1000000000);
}

sub matroska_block_calc_frame {
    my ($matroska, $block, $samplerate, $pcmFrameLen) = @_;
    say 'clusterts ' . ($matroska->{'dc'}->{'ts'}/1000000000);
    say 'blockts ' . $block->{'ts'};
    my $time = ($matroska->{'dc'}->{'rawts'} + $block->{'ts'}) * $matroska->{'tsscale'};
    say 'blocktime ' . ($time/1000000000);
    my $calcframe = matroska_ts_to_sample($matroska, $samplerate, $time);
    return round($calcframe/$pcmFrameLen)*$pcmFrameLen;
}

sub matroska_read_track {
    my ($matroska, $track, $pcmFrameIndex, $numsamples, $formatpacket) = @_;
    my $tid = $track->{&EBMLID_TrackNumber}{'value'};
    my $samplerate = $track->{&EBMLID_AudioSampleRate};
    my $pcmFrameLen = $track->{'PCMFrameLength'};
    if(!$pcmFrameLen) {
        warn("Unknown codec");
        return undef;
    }

    # find the cluster that might have the start of our audio
    if($matroska->{'curframe'} != $pcmFrameIndex) {
        say "do seek";
        if(!matroska_seek_track($matroska, $track, $pcmFrameIndex)) {
            return undef;
        }
    }

    my $outdata;
    my $destframe = $matroska->{'curframe'} + $numsamples;

    while(1) {
        # add read audio
        while(@{$matroska->{'curpaks'}}) {
            my $pak = shift @{$matroska->{'curpaks'}};
            $outdata .= $formatpacket->($pak, $samplerate);
            $matroska->{'curframe'} += $pcmFrameLen;
            if($matroska->{'curframe'} == $destframe) {
                say "done, read enough";
                return $outdata;
            }
        }

        # load a block
        my $block = matroska_get_track_block($matroska, $tid);
        if(! $block) {
            if(($matroska->{'ebml'}{'elements'}[0]{'id'} == EBMLID_Segment) && ($matroska->{'ebml'}{'elements'}[0]{'size'} == 0)) {
                say "done, EOF";
            }
            else {
                say "done, Error";
            }
            return $outdata;
        }

        # add the data to paks
        my $offset = 0;
        foreach my $len (@{$block->{'frame_lengths'}}) {
            push @{$matroska->{'curpaks'}}, substr($block->{'data'}, $offset, $len);
            $offset += $len;
        }
    }
}

sub video_on_streams {
    my ($video, $request, $continue) = @_;
    $video->{'audio'} = [];
    $video->{'video'} = [];
    $video->{'subtitle'} = [];
    my $input_file = $video->{'src_file'}{'filepath'};
    my @command = ('ffmpeg', '-i', $input_file);
    my $evp = $request->{'client'}{'server'}{'evp'};
    MHFS::Process->new_output_process($evp, \@command, sub {
        my ($output, $error) = @_;
        my @lines = split(/\n/, $error);
        my $current_stream;
        my $current_element;
        foreach my $eline (@lines) {
            if($eline =~ /^\s*Stream\s#0:(\d+)(?:\((.+)\)){0,1}:\s(.+):\s(.+)(.*)$/) {
                my $type = $3;
                $current_stream = $1;
                $current_element = { 'sindex' => $current_stream, 'lang' => $2, 'fmt' => $4, 'additional' => $5, 'metadata' => '' };
                $current_element->{'is_default'} = 1 if($current_element->{'fmt'} =~ /\(default\)$/i);
                $current_element->{'is_forced'} = 1 if($current_element->{'fmt'} =~ /FORCED/i);
                if($type =~ /audio/i) {
                    push @{$video->{'audio'}} , $current_element;
                }
                elsif($type =~ /video/i) {
                    push @{$video->{'video'}} , $current_element;
                }
                elsif($type =~ /subtitle/i) {
                    push @{$video->{'subtitle'}} , $current_element;
                }
                say $eline;
            }
            elsif($eline =~ /^\s+Duration:\s+(\d\d):(\d\d):(\d\d)\.(\d\d)/) {
                #TODO add support for over day long video
                $video->{'duration'} //= "PT$1H$2M$3.$4S";
                try { write_text_file($video->{'out_location'} . '/duration',  $video->{'duration'}); }
                catch ($e) { say "writing new duration file failed"; }
            }
            elsif(defined $current_stream) {
                if($eline !~ /^\s\s+/) {
                    $current_stream = undef;
                    $current_element = undef;
                    next;
                }
                $current_element->{'metadata'} .= $eline;
                if($eline =~ /\s+title\s*:\s*(.+)$/) {
                    $current_element->{'title'} = $1;
                }
            }
        }
        print Dumper($video);
        $continue->();
    });
}

1;
