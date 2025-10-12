package MHFS::Plugin::MusicLibrary v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Cwd qw(abs_path getcwd);
use File::Find;
use Data::Dumper;
use Devel::Peek;
use Fcntl ':mode';
use File::stat;
use File::Basename;
use File::Path qw(make_path);
use Scalar::Util qw(looks_like_number);
use MHFS::Util qw(get_printable_utf8 escape_html_noquote LOCK_GET_LOCKDATA LOCK_WRITE UNLOCK_WRITE);
BEGIN {
    if( ! (eval "use JSON; 1")) {
        eval "use JSON::PP; 1" or die "No implementation of JSON available";
        warn __PACKAGE__.": Using PurePerl version of JSON (JSON::PP)";
    }
}
use Encode qw(decode encode);
use URI::Escape;
use Storable qw(dclone);
use Fcntl ':mode';
use Time::HiRes qw( usleep clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC);
use Scalar::Util qw(looks_like_number weaken);
use POSIX qw/ceil/;
use Storable qw( freeze thaw);
#use ExtUtils::testlib;
use FindBin;
use File::Spec;
use List::Util qw[min max];
use HTML::Template;
use MHFS::Process;

# Optional dependency, MHFS::XS
BEGIN {
    use constant HAS_MHFS_XS => (eval "use MHFS::XS; 1");
    if(! HAS_MHFS_XS) {
        warn __PACKAGE__.": XS not available";
    }
}

# read the directory tree from desk and store
# this assumes filenames are UTF-8ish, the octlets will be the actual filename, but the printable filename is created by decoding it as UTF-8
sub BuildLibrary {
    my ($path) = @_;
    my $statinfo = stat($path);
    return undef if(! $statinfo);
    my $basepath = basename($path);
    my $utf8name = get_printable_utf8($basepath);

    if(!S_ISDIR($statinfo->mode)){
    return undef if($path !~ /\.(flac|mp3|m4a|wav|ogg|webm)$/);
        return [$basepath, $statinfo->size, undef, $utf8name];
    }
    else {
        my $dir;
        if(! opendir($dir, $path)) {
            warn "outputdir: Cannot open directory: $path $!";
            return undef;
        }
        my @files = sort { uc($a) cmp uc($b)} (readdir $dir);
        closedir($dir);
        my @tree;
        my $size = 0;
        foreach my $file (@files) {
            next if(($file eq '.') || ($file eq '..'));
            if(my $file = BuildLibrary("$path/$file")) {
                    push @tree, $file;
                    $size += $file->[1];
            }
        }
        return undef if( $size eq 0);
        return [$basepath, $size, \@tree, $utf8name];
    }
}

sub ToHTML {
    my ($files, $where) = @_;
    $where //= '';
    my $buf = '';
    my $name_unencoded = $files->[3];
    my $name = ${escape_html_noquote($name_unencoded)};
    if($files->[2]) {
        my $dir = $files->[0];
        $buf .= '<tr>';
        $buf .= '<td>';
        $buf .= '<table border="1" class="tbl_track">';
        $buf .= '<tbody>';
        $buf .= '<tr class="track">';
        $buf .= '<th>' . $name . '</th>';
        $buf .= '<th><a href="#">Play</a></th><th><a href="#">Queue</a></th><th><a href="music_dl?action=dl&name=' . uri_escape_utf8($where.$name_unencoded) . '">DL</a></th>';
        $buf .= '</tr>';
        $where .= $name_unencoded . '/';
        foreach my $file (@{$files->[2]}) {
            $buf .= ToHTML($file, $where) ;
        }
        $buf .= '</tbody></table>';
        $buf .= '</td>';

    }
    else {
        if($where eq '') {
                $buf .= '<table border="1" class="tbl_track">';
                $buf .= '<tbody>';
        }
        $buf .= '<tr class="track">';
        $buf .= '<td>' . $name . '</td>';
        $buf .= '<td><a href="#">Play</a></td><td><a href="#">Queue</a></td><td><a href="music_dl?action=dl&name=' . uri_escape_utf8($where.$name_unencoded).'">DL</a></td>';
        if($where eq '') {
                $buf .= '</tr>';
                $buf .= '</tbody></table>';
                return $buf;
        }
    }
    $buf .= '</tr>';
    return $buf;
}

sub toJSON {
    my ($self) = @_;
    my $head = {'files' => []};
    my @nodestack = ($head);
    my @files = (@{$self->{'library'}});
    while(@files) {
        my $file = shift @files;
        if( ! $file) {
            pop @nodestack;
            next;
        }
        my $node = $nodestack[@nodestack - 1];
        my $newnode = {'name' =>$file->[3]};
        if($file->[2]) {
            $newnode->{'files'} = [];
            push @nodestack, $newnode;
            @files = (@{$file->[2]}, undef, @files);
        }
        push @{$node->{'files'}}, $newnode;
    }
    # encode json outputs bytes NOT unicode string
    return encode_json($head);
}


sub LibraryHTML {
    my ($self) = @_;
    my $buf = '';
    foreach my $file (@{$self->{'library'}}) {
        $buf .= ToHTML($file);
        $buf .= '<br>';
    }

    my $legacy_template = HTML::Template->new(filename => 'templates/music_legacy.html', path => $self->{'settings'}{'APPDIR'} );
    $legacy_template->param(musicdb => $buf);
    $self->{'html'} = encode('UTF-8', $legacy_template->output, Encode::FB_CROAK);

    $self->{'musicdbhtml'} = encode('UTF-8', $buf, Encode::FB_CROAK);
    $self->{'musicdbjson'} = toJSON($self);
}

sub SendLibrary {
    my ($self, $request) = @_;

    # maybe not allow everyone to do these commands?
    if($request->{'qs'}{'forcerefresh'}) {
        say __PACKAGE__.": forcerefresh";
        $self->BuildLibraries();
    }
    elsif($request->{'qs'}{'refresh'}) {
        say __PACKAGE__.": refresh";
        UpdateLibrariesAsync($self, $request->{'client'}{'server'}{'evp'}, sub {
            say __PACKAGE__.": refresh done";
            $request->{'qs'}{'refresh'} = 0;
            SendLibrary($self, $request);
        });
        return 1;
    }

    # deduce the format if not provided
    my $fmt = $request->{'qs'}{'fmt'};
    if(! $fmt) {
        $fmt = 'worklet';
        my $fallback = 'musicinc';
        if($request->{'header'}{'User-Agent'} =~ /Chrome\/([^\.]+)/) {
            my $ver = $1;
            # SharedArrayBuffer support with spectre/meltdown fixes was added in 68
            # AudioWorklet on linux had awful glitching until somewhere in 92 https://bugs.chromium.org/p/chromium/issues/detail?id=825823
            if($ver < 93) {
                if(($ver < 68) || ($request->{'header'}{'User-Agent'} =~ /Linux/)) {
                    $fmt = $fallback;
                }
            }
        }
        elsif($request->{'header'}{'User-Agent'} =~ /Firefox\/([^\.]+)/) {
            my $ver = $1;
            # SharedArrayBuffer support with spectre/meltdown fixes was added in 79
            if($ver < 79) {
                $fmt = $fallback;
            }
        }
        else {
            # Hope for the best, assume worklet works
        }

        # leave this here for now to not break the segment based players
        if($request->{'qs'}{'segments'}) {
            $fmt = $fallback;
        }
    }

    # route
    my $qs = defined($request->{'qs'}{'ptrack'}) ? {'ptrack' => $request->{'qs'}{'ptrack'}} : undef;
    if($fmt eq 'worklet') {
        return $request->SendRedirect(307, 'static/music_worklet_inprogress/', $qs);
    }
    elsif($fmt eq 'musicdbjson') {
        return $request->SendBytes('application/json', $self->{'musicdbjson'});
    }
    elsif($fmt eq 'musicdbhtml') {
        return $request->SendBytes("text/html; charset=utf-8", $self->{'musicdbhtml'});
    }
    elsif($fmt eq 'gapless') {
        $qs->{fmt} = 'musicinc';
        return $request->SendRedirect(301, "music", $qs);
    }
    elsif($fmt eq 'musicinc') {
        return $request->SendRedirect(307, 'static/music_inc/', $qs);
    }
    elsif($fmt eq 'legacy') {
        say __PACKAGE__.": legacy";
        return $request->SendBytes("text/html; charset=utf-8", $self->{'html'});
    }
    else {
        return $request->Send404;
    }
}

my $SEGMENT_DURATION = 5;
my %TRACKDURATION;
my %TRACKINFO;
sub SendTrack {
    my ($request, $tosend) = @_;
    if(defined $request->{'qs'}{'part'}) {
        if(! HAS_MHFS_XS) {
            say __PACKAGE__.": route not available without XS";
            $request->Send503();
            return;
        }

        if(! $TRACKDURATION{$tosend}) {
            say __PACKAGE__.": failed to get track duration";
            $request->Send503();
            return;
        }

        say "no proc, duration cached";
        my $pv = MHFS::XS::new($tosend);
        $request->{'outheaders'}{'X-MHFS-NUMSEGMENTS'} = ceil($TRACKDURATION{$tosend} / $SEGMENT_DURATION);
        $request->{'outheaders'}{'X-MHFS-TRACKDURATION'} = $TRACKDURATION{$tosend};
        $request->{'outheaders'}{'X-MHFS-MAXSEGDURATION'} = $SEGMENT_DURATION;
        my $samples_per_seg = $TRACKINFO{$tosend}{'SAMPLERATE'} * $SEGMENT_DURATION;
        my $spos = $samples_per_seg * ($request->{'qs'}{'part'} - 1);
        my $samples_left = $TRACKINFO{$tosend}{'TOTALSAMPLES'} - $spos;
        my $res = MHFS::XS::get_flac($pv, $spos, $samples_per_seg < $samples_left ? $samples_per_seg : $samples_left);
        $request->SendBytes('audio/flac', $res);
    }
    elsif(defined $request->{'qs'}{'fmt'} && ($request->{'qs'}{'fmt'}  eq 'wav')) {
        if(! HAS_MHFS_XS) {
            say __PACKAGE__.": route not available without XS";
            $request->Send503();
            return;
        }

        my $pv = MHFS::XS::new($tosend);
        my $outbuf = '';
        my $wavsize = (44+ $TRACKINFO{$tosend}{'TOTALSAMPLES'} * ($TRACKINFO{$tosend}{'BITSPERSAMPLE'}/8) * $TRACKINFO{$tosend}{'NUMCHANNELS'});
        my $startbyte = $request->{'header'}{'_RangeStart'} || 0;
        my $endbyte = $request->{'header'}{'_RangeEnd'} // $wavsize-1;
        say "start byte" . $startbyte;
        say "end byte " . $endbyte;
        say "MHFS::XS::wavvfs_read_range " . $startbyte . ' ' . $endbyte;
        my $maxsendsize;
        $maxsendsize = 1048576/2;
        say "maxsendsize $maxsendsize " . ' bytespersample ' . ($TRACKINFO{$tosend}{'BITSPERSAMPLE'}/8) . ' numchannels ' . $TRACKINFO{$tosend}{'NUMCHANNELS'};
        $request->SendCallback(sub{
            my ($fileitem) = @_;
            my $actual_endbyte = $startbyte + $maxsendsize - 1;
            if($actual_endbyte >= $endbyte) {
                $actual_endbyte = $endbyte;
                $fileitem->{'cb'} = undef;
                say "SendCallback last send";
            }
            my $actual_startbyte = $startbyte;
            $startbyte = $actual_endbyte+1;
            say "SendCallback wavvfs_read_range " . $actual_startbyte . ' ' . $actual_endbyte;
            return MHFS::XS::wavvfs_read_range($pv, $actual_startbyte, $actual_endbyte);
        }, {
            'mime' => 'audio/wav',
            'size' => $wavsize,
        });

    }
    else {
        if($request->{'qs'}{'action'} && ($request->{'qs'}{'action'} eq 'dl')) {
            $request->{'responseopt'}{'cd_file'} = 'attachment';
        }
        # Send the total pcm frame count for mp3
        elsif(lc(substr($tosend, -4)) eq '.mp3') {
            if(HAS_MHFS_XS) {
                if(! $TRACKINFO{$tosend}) {
                    $TRACKINFO{$tosend} = { 'TOTALSAMPLES' => MHFS::XS::get_totalPCMFrameCount($tosend) };
                    say "mp3 totalPCMFrames: " . $TRACKINFO{$tosend}{'TOTALSAMPLES'};
                }
                $request->{'outheaders'}{'X-MHFS-totalPCMFrameCount'} = $TRACKINFO{$tosend}{'TOTALSAMPLES'};
            }
        }
        $request->SendLocalFile($tosend);
    }
}

sub parseStreamInfo {
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

sub GetTrackInfo {
    my ($file) = @_;
    open(my $fh, '<', $file) or die "open failed";
    my $buf = '';
    seek($fh, 8, 0) or die "seek failed";
    (read($fh, $buf, 34) == 34) or die "short read";
    my $info = parseStreamInfo($buf);
    $info->{'duration'} = $info->{'TOTALSAMPLES'}/$info->{'SAMPLERATE'};
    print Dumper($info);
    return $info;
}

sub SendLocalTrack {
    my ($request, $file) = @_;

    # fast path, just send the file
    my $justsendfile = (!defined($request->{'qs'}{'fmt'})) && (!defined($request->{'qs'}{'max_sample_rate'})) && (!defined($request->{'qs'}{'bitdepth'})) && (!defined($request->{'qs'}{'part'}));
    if($justsendfile) {
        SendTrack($request, $file);
        return;
    }

    my $evp = $request->{'client'}{'server'}{'evp'};
    my $tmpfileloc = $request->{'client'}{'server'}{'settings'}{'MUSIC_TMPDIR'} . '/';
    my $nameloc = $request->{'localtrack'}{'nameloc'};
    $tmpfileloc .= $nameloc if($nameloc);
    my $filebase = $request->{'localtrack'}{'basename'};

    # convert to lossy flac if necessary
    my $is_flac = lc(substr($file, -5)) eq '.flac';
    if(!$is_flac) {
        $filebase =~ s/\.[^.]+$/.lossy.flac/;
        $request->{'localtrack'}{'basename'} = $filebase;
        my $tlossy = $tmpfileloc . $filebase;
        if(-e $tlossy ) {
            $is_flac = 1;
            $file = $tlossy;

            if(defined LOCK_GET_LOCKDATA($tlossy)) {
                    # unlikely
                say "SendLocalTrack: lossy flac exists and is locked 503";
                $request->Send503;
                return;
            }
        }
        else {
            make_path($tmpfileloc, {chmod => 0755});
            my @cmd = ('ffmpeg', '-i', $file, '-c:a', 'flac', '-sample_fmt', 's16', $tlossy);
            my $buf;
            if(LOCK_WRITE($tlossy)) {
                $request->{'process'} = MHFS::Process->new(\@cmd, $evp, {
                'SIGCHLD' => sub {
                    UNLOCK_WRITE($tlossy);
                    SendLocalTrack($request,$tlossy);
                },
                'STDERR' => sub {
                    my ($terr) = @_;
                    read($terr, $buf, 4096);
                }});
            }
            else {
                # unlikely
                say "SendLocalTrack: lossy flac is locked 503";
                $request->Send503;
            }

            return;
        }
    }

    # everything should be flac now, grab the track info
    if(!defined($TRACKINFO{$file}))
    {
        $TRACKINFO{$file} = GetTrackInfo($file);
        $TRACKDURATION{$file} = $TRACKINFO{$file}{'duration'};
    }

    my $max_sample_rate = $request->{'qs'}{'max_sample_rate'} // 192000;
    my $bitdepth = $request->{'qs'}{'bitdepth'} // ($max_sample_rate > 48000 ? 24 : 16);

    # check to see if the raw file fullfills the requirements
    my $samplerate = $TRACKINFO{$file}{'SAMPLERATE'};
    my $inbitdepth = $TRACKINFO{$file}{'BITSPERSAMPLE'};
    say "input: samplerate $samplerate inbitdepth $inbitdepth";
    say "maxsamplerate $max_sample_rate bitdepth $bitdepth";
    if(($samplerate <= $max_sample_rate) && ($inbitdepth <= $bitdepth)) {
        say "samplerate is <= max_sample_rate, not resampling";
        SendTrack($request, $file);
        return;
    }

    # determine the acceptable samplerate, bitdepth combinations to send
    my %rates = (
        '48000' => [192000, 96000, 48000],
        '44100' => [176400, 88200, 44100]
    );
    my @acceptable_settings = ( [24, 192000], [24, 96000], [24, 48000], [24, 176400],  [24, 88200], [16, 48000], [16, 44100]);
    my @desired = ([$bitdepth, $max_sample_rate]);
    foreach my $setting (@acceptable_settings) {
        if(($setting->[0] <= $bitdepth) && ($setting->[1] <= $max_sample_rate)) {
            push @desired, $setting;
        }
    }

    # if we already transcoded/resampled, don't waste time doing it again
    foreach my $setting (@desired) {
        my $tmpfile = $tmpfileloc . $setting->[0] . '_' . $setting->[1] . '_' . $filebase;
        if(-e $tmpfile) {
            say "No need to resample $tmpfile exists";
            SendTrack($request, $tmpfile);
            return;
        }
    }
    make_path($tmpfileloc, {chmod => 0755});

    # resampling
    my $desiredrate;
    RATE_FACTOR: foreach my $key (keys %rates) {
        if(($samplerate % $key) == 0) {
            foreach my $rate (@{$rates{$key}}) {
                if(($rate <= $samplerate) && ($rate <= $max_sample_rate)) {
                    $desiredrate = $rate;
                    last RATE_FACTOR;
                }
            }
        }
    }
    $desiredrate //= $max_sample_rate;
    say "desired rate: $desiredrate";
    # build the command
    my $outfile = $tmpfileloc . $bitdepth . '_' . $desiredrate . '_' . $filebase;
    my @cmd = ('sox', $file, '-G', '-b', $bitdepth, $outfile, 'rate', '-v', '-L', $desiredrate, 'dither');
    say "cmd: " . join(' ', @cmd);

    if(LOCK_WRITE($outfile)) {
        $request->{'process'} = MHFS::Process->new(\@cmd, $evp, {
        'SIGCHLD' => sub {
            UNLOCK_WRITE($outfile);
            # BUG? files isn't necessarily flushed to disk on SIGCHLD. filesize can be wrong
            SendTrack($request, $outfile);
        },
        'STDERR' => sub {
            my ($terr) = @_;
            my $buf;
            read($terr, $buf, 4096);
        }});
    }
    else {
        # unlikely
        say "SendLocalTrack: sox is locked 503";
        $request->Send503;
    }
    return;
}


sub BuildLibraries {
    my ($self) = @_;
    my @wholeLibrary;

    $self->{'sources'} = [];

    foreach my $sid (@{$self->{'settings'}{'MEDIASOURCES'}{'music'}}) {
        my $source = $self->{'settings'}{'SOURCES'}{$sid};
        my $lib;
        if($source->{'type'} eq 'local') {
            say __PACKAGE__.": building music " . clock_gettime(CLOCK_MONOTONIC);
            $lib = BuildLibrary($source->{'folder'});
            say __PACKAGE__.": done building music " . clock_gettime(CLOCK_MONOTONIC);
        }
        elsif($source->{'type'} eq 'ssh') {
        }
        elsif($source->{'type'} eq 'mhfs') {
        }

        if(!$lib) {
            warn "invalid source: " . $source->{'type'};
            warn 'folder: '. $source->{'folder'} if($source->{'type'} eq 'local');
            next;
        }
        push @{$self->{'sources'}}, [$sid, $lib];
        OUTER: foreach my $item (@{$lib->[2]}) {
            foreach my $already (@wholeLibrary) {
                next OUTER if($already->[0] eq $item->[0]);
            }
            push @wholeLibrary, $item;
        }
    }
    $self->{'library'} = \@wholeLibrary;
    $self->LibraryHTML;
    return \@wholeLibrary;
}

sub FindInLibrary {
    my ($self, $msource, $name) = @_;
    my @namearr = split('/', $name);
    my $finalstring = $self->{'settings'}{'SOURCES'}{$msource->[0]}{'folder'};
    my $lib = $msource->[1];
    FindInLibrary_Outer: foreach my $component (@namearr) {
        foreach my $libcomponent (@{$lib->[2]}) {
            if($libcomponent->[3] eq $component) {
                    $finalstring .= "/".$libcomponent->[0];
                $lib = $libcomponent;
                next FindInLibrary_Outer;
            }
        }
        return undef;
    }
    return {
        'node' => $lib,
        'path' => $finalstring
    };
}

# Define source types here
my %sendFiles = (
    'local' => sub {
        my ($request, $file, $node, $source, $nameloc) = @_;
        return undef if(! -e $file);
        if( ! -d $file) {
            $request->{'localtrack'} = { 'nameloc' => $nameloc, 'basename' => $node->[0]};
            SendLocalTrack($request, $file);
        }
        else {
            $request->SendAsTar($file);
        }
        return 1;
    },
    'mhfs' => sub {
        my ($request, $file, $node, $source) = @_;
        return $request->Proxy($source, $node);
    },
    'ssh' => sub {
        my ($request, $file, $node, $source) = @_;
        return $request->SendFromSSH($source, $file, $node);
    },
);

sub SendFromLibrary {
    my ($self, $request) = @_;
    my $utf8name = decode('UTF-8', $request->{'qs'}{'name'});
    foreach my $msource (@{$self->{'sources'}}) {
        my $node = $self->FindInLibrary($msource, $utf8name);
        next if ! $node;

        my $nameloc;
        if($utf8name =~ /(.+\/).+$/) {
            $nameloc  = $1;
        }
        my $source = $self->{'settings'}{'SOURCES'}{$msource->[0]};
        if($sendFiles{$source->{'type'}}->($request, $node->{'path'}, $node->{'node'}, $source, $nameloc)) {
            return 1;
        }
    }
    say "SendFromLibrary: did not find in library, 404ing";
    say "name: " . $request->{'qs'}{'name'};
    $request->Send404;
}

sub SendResources {
    my ($self, $request) = @_;

    if(! HAS_MHFS_XS) {
        say __PACKAGE__.": route not available without XS";
        $request->Send503();
        return;
    }

    my $utf8name = decode('UTF-8', $request->{'qs'}{'name'});
    foreach my $msource (@{$self->{'sources'}}) {
        my $node = $self->FindInLibrary($msource, $utf8name);
        next if ! $node;
        my $comments = MHFS::XS::get_vorbis_comments($node->{'path'});
        my $commenthash = {};
        foreach my $comment (@{$comments}) {
            $comment = decode('UTF-8', $comment);
            my ($key, $value) = split('=', $comment);
            $commenthash->{$key} = $value;
        }
        $request->SendAsJSON($commenthash);
        return 1;
    }
    say "SendFromLibrary: did not find in library, 404ing";
    say "name: " . $request->{'qs'}{'name'};
    $request->Send404;
}

sub SendArt {
    my ($self, $request) = @_;

    my $utf8name = decode('UTF-8', $request->{'qs'}{'name'});
    foreach my $msource (@{$self->{'sources'}}) {
        my $node = $self->FindInLibrary($msource, $utf8name);
        next if ! $node;

        my $dname = $node->{'path'};
        my $dh;
        if(! opendir($dh, $dname)) {
            $dname = dirname($node->{'path'});
            if(! opendir($dh, $dname)) {
                $request->Send404;
                return 1;
            }
        }

        # scan dir for art
        my @files;
        while(my $fname = readdir($dh)) {
            my $last = lc(substr($fname, -4));
            push @files, $fname if(($last eq '.png') || ($last eq '.jpg') || ($last eq 'jpeg'));
        }
        closedir($dh);
        if( ! @files) {
            $request->Send404;
            return 1;
        }
        my $tosend = "$dname/" . $files[0];
        foreach my $file (@files) {
            foreach my $expname ('cover', 'front', 'album') {
                if(substr($file, 0, length($expname)) eq $expname) {
                    $tosend = "$dname/$file";
                    last;
                }
            }
        }
        say "tosend $tosend";
        $request->SendLocalFile($tosend);
        return 1;
    }
}

sub UpdateLibrariesAsync {
    my ($self, $evp, $onUpdateEnd) = @_;
    MHFS::Process->new_output_child($evp, sub {
        # done in child
        my ($datachannel) = @_;

        # save references to before
        my @potentialupdates = ('html', 'musicdbhtml', 'musicdbjson');
        my %before;
        foreach my $pupdate (@potentialupdates) {
            $before{$pupdate} = $self->{$pupdate};
        }

        # build the new libraries
        $self->BuildLibraries();

        # determine what needs to be updated
        my @updates = (['sources', $self->{'sources'}]);
        foreach my $pupdate(@potentialupdates) {
            if($before{$pupdate} ne $self->{$pupdate}) {
                push @updates, [$pupdate, $self->{$pupdate}];
            }
        }

        # serialize and output
        my $pipedata = freeze(\@updates);
        print $datachannel $pipedata;
        exit 0;
    }, sub {
        my ($out, $err) = @_;
        say "BEGIN_FROM_CHILD---------";
        print $err;
        say "END_FROM_CHILD-----------";
        my $unthawed;
        {
            local $@;
            unless (eval {
                $unthawed = thaw($out);
                return 1;
            }) {
                warn("thaw threw exception");
            }
        }
        if($unthawed){
            foreach my $update (@$unthawed) {
                say "Updating " . $update->[0];
                $self->{$update->[0]} = $update->[1];
            }
        }
        else {
            say "failed to thaw, library not updated.";
        }
        $onUpdateEnd->();
    });
}

sub new {
    my ($class, $settings) = @_;
    my $self =  {'settings' => $settings};
    bless $self, $class;
    my $pstart = __PACKAGE__.":";

    # no sources until loaded
    $self->{'sources'} = [];
    $self->{'html'} = __PACKAGE__.' not loaded';
    $self->{'musicdbhtml'} = __PACKAGE__.' not loaded';
    $self->{'musicdbjson'} = '{}';

    my $musicpageroute = sub {
        my ($request) = @_;
        return $self->SendLibrary($request);
    };

    my $musicdlroute = sub {
        my ($request) = @_;
        return $self->SendFromLibrary($request);
    };

    my $musicresourcesroute = sub {
        my ($request) = @_;
        return $self->SendResources($request);
    };

    $self->{'routes'} = [
        ['/music', $musicpageroute],
        ['/music_dl', $musicdlroute],
        ['/music_resources', $musicresourcesroute],
        ['/music_art', sub {
            my ($request) = @_;
            return $self->SendArt($request);
        }]
    ];

    $self->{'timers'} = [
        # update the library at start and periodically
        [0, 300, sub {
            my ($timer, $current_time, $evp) = @_;
            say "$pstart library timer";
            UpdateLibrariesAsync($self, $evp, sub {
                say "$pstart library timer done";
            });
            return 1;
        }],
    ];

    return $self;
}

1;
