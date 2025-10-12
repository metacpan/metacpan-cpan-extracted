package MHFS::Plugin::Youtube v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Data::Dumper;
use feature 'state';
use Encode;
use URI::Escape;
use Scalar::Util qw(looks_like_number weaken);
use File::stat;
use MHFS::Process;
use MHFS::Util qw(escape_html LOCK_WRITE UNLOCK_WRITE);
BEGIN {
    if( ! (eval "use JSON; 1")) {
        eval "use JSON::PP; 1" or die "No implementation of JSON available";
        warn __PACKAGE__.": Using PurePerl version of JSON (JSON::PP)";
    }
}
sub searchbox {
    my ($self, $request) = @_;
    #my $html = '<form  name="searchbox" action="' . $request->{'path'}{'basename'} . '">';
    my $html = '<form  name="searchbox" action="yt">';
    $html .= '<input type="text" width="50%" name="q" ';
    my $query = $request->{'qs'}{'q'};
    if($query) {
        $query =~ s/\+/ /g;
        my $escaped = escape_html($query);
        $html .= 'value="' . $$escaped . '"';
    }
    $html .=  '>';
    if($request->{'qs'}{'media'}) {
        $html .= '<input type="hidden" name="media" value="' . $request->{'qs'}{'media'} . '">';
    }
    $html .= '<input type="submit" value="Search">';
    $html .= '</form>';
    return $html;
}
sub ytplayer {
    my ($self, $request) = @_;
    my $html = '<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0" /><iframe src="static/250ms_silence.mp3" allow="autoplay" id="audio" style="display:none"></iframe>';
    my $url = 'get_video?fmt=yt&id=' . uri_escape($request->{'qs'}{'id'});
    $url .= '&media=' . uri_escape($request->{'qs'}{'media'}) if($request->{'qs'}{'media'});
    if($request->{'qs'}{'media'} && ($request->{'qs'}{'media'} eq 'music')) {
        $request->{'path'}{'basename'} = 'ytaudio';
        $html .= '<audio controls autoplay src="' . $url . '">Great Browser</audio>';
    }
    else {
        $request->{'path'}{'basename'} = 'yt';
        $html .= '<video controls autoplay src="' . $url . '">Great Browser</video>';
    }
    return $html;
}
sub sendAsHTML {
    my ($self, $request, $response) = @_;
    my $json = decode_json($response);
    if(! $json){
        $request->Send404;
        return;
    }
    my $html = $self->searchbox($request);
    $html .= '<div id="vidlist">';
    foreach my $item (@{$json->{'items'}}) {
        my $id = $item->{'id'}{'videoId'};
        next if (! defined $id);
        $html .= '<div>';
        my $mediaurl = 'ytplayer?fmt=yt&id=' . $id;
        my $media =  $request->{'qs'}{'media'};
        $mediaurl .= '&media=' . uri_escape($media) if(defined $media);
        $html .= '<a href="' . $mediaurl . '">' . $item->{'snippet'}{'title'} . '</a>';
        $html .= '<br>';
        $html .= '<a href="' . $mediaurl . '"><img src="' . $item->{'snippet'}{'thumbnails'}{'default'}{'url'} . '" alt="Excellent image loading"></a>';
        $html .= ' <a href="https://youtube.com/channel/' . $item->{'snippet'}{'channelId'} . '">' .  $item->{'snippet'}{'channelTitle'} . '</a>';
        $html .= '<p>' . $item->{'snippet'}{'description'} . '</p>';
        $html .= '<br>-----------------------------------------------';
        $html .= '</div>'
    }
    $html .= '</div>';
    $html .= '<script>
    var vidlist = document.getElementById("vidlist");
    vidlist.addEventListener("click", function(e) {
        console.log(e);
        let target = e.target.pathname ? e.target : e.target.parentElement;
        if(target.pathname && target.pathname.endsWith("ytplayer")) {
            e.preventDefault();
            console.log(target.href);
            let newtarget = target.href.replace("ytplayer", "ytembedplayer");
            fetch(newtarget).then( response => response.text()).then(function(data) {
                if(data) {
                    window.history.replaceState(vidlist.innerHTML, null);
                    window.history.pushState(data, null, target.href);
                    vidlist.innerHTML = data;
                }
            });
        }
    });
    window.onpopstate = function(event) {
        console.log(event.state);
        vidlist.innerHTML = event.state;
    }
    </script>';
    $request->SendHTML($html);
}
sub onYoutube {
    my ($self, $request) = @_;
    my $evp = $request->{'client'}{'server'}{'evp'};
    my $youtubequery = 'q=' . (uri_escape($request->{'qs'}{'q'}) // '') . '&maxResults=' . ($request->{'qs'}{'maxResults'} // '25') . '&part=snippet&key=' . $self->{'settings'}{'Youtube'}{'key'};
    $youtubequery .= '&type=video'; # playlists not supported yet
    my $tosend = '';
    my @curlcmd = ('curl', '-G', '-d', $youtubequery, 'https://www.googleapis.com/youtube/v3/search');
    print "$_ " foreach @curlcmd;
    print "\n";
    state $tprocess;
    $tprocess = MHFS::Process->new(\@curlcmd, $evp, {
        'SIGCHLD' => sub {
            my $stdout = $tprocess->{'fd'}{'stdout'}{'fd'};
            my $buf;
            while(length($tosend) == 0) {
                while(read($stdout, $buf, 24000)) {
                    say "did read sigchld";
                    $tosend .= $buf;
                }
            }
            undef $tprocess;
            $request->{'qs'}{'fmt'} //= 'html';
            if($request->{'qs'}{'fmt'} eq 'json'){
                $request->SendBytes('application/json', $tosend);
            }
            else {
                $self->sendAsHTML($request, $tosend);
            }
        },
    });
    $request->{'process'} = $tprocess;
    return -1;
}
sub downloadAndServe {
    my ($self, $request, $video) = @_;
    weaken($request);
    my $filename = $video->{'out_filepath'};
    my $sendit = sub {
        # we can send the file
        if(! $request) {
            return;
        }
        say "sending!!!!";
        $request->SendLocalFile($filename);
    };
    my $qs = $request->{'qs'};
    my @cmd = ($self->{'youtube-dl'}, '--no-part', '--print-traffic', '-f', $self->{'fmts'}{$qs->{"media"} // "video"} // "best", '-o', $video->{"out_filepath"}, '--', $qs->{"id"});
    $request->{'process'} = MHFS::Process->new_cmd_process($request->{'client'}{'server'}{'evp'}, \@cmd, {
        'on_stdout_data' => sub {
            my ($context) = @_;
            # determine the size of the file
            # relies on receiving content-length header last
            my ($cl) = $context->{'stdout'} =~ /^.*Content\-Length:\s(\d+)/s;
            return 1 if(! $cl);
            my ($cr) = $context->{'stdout'} =~ /^.*Content\-Range:\sbytes\s\d+\-\d+\/(\d+)/s;
            if($cr) {
                say "cr $cr";
                $cl = $cr if($cr > $cl);
            }
            say "cl is $cl";
            UNLOCK_WRITE($filename);
            LOCK_WRITE($filename, $cl);
            # make sure the file exists and within our parameters
            my $st = stat($filename);
            $st or return;
            my $minsize = 16384;
            $minsize = $cl if($cl < $minsize);
            return if($st->size < $minsize);
            say "sending, currentsize " . $st->size . ' totalsize ' . $cl;
            # dont need to check the new data anymore
            $context->{'on_stdout_data'} = undef;
            $sendit->();
            $request = undef;
        },
        'at_exit' => sub {
            my ($context) = @_;
            UNLOCK_WRITE($filename);
            # last ditch effort, try to send it if we haven't
            $sendit->();
        }
    });
    return 1;
}
sub getOutBase {
    my ($self, $qs) = @_;
    return undef if(! $qs->{'id'});
    my $media;
    if(defined $qs->{'media'} && (defined $self->{'fmts'}{$qs->{'media'}})) {
        $media = $qs->{'media'};
    }
    else  {
        $media = 'video';
    }
    return $qs->{'id'} . '_' . $media;
}
sub new {
    my ($class, $settings, $server) = @_;
    my $self =  {'settings' => $settings};
    bless $self, $class;
    $self->{'routes'} = [
    ['/youtube', sub {
        my ($request) = @_;
        $self->onYoutube($request);
    }],
    ['/yt', sub {
        my ($request) = @_;
        $self->onYoutube($request);
    }],
    ['/ytmusic', sub {
        my ($request) = @_;
        $request->{'qs'}{'media'} //= 'music';
        $self->onYoutube($request);
    }],
    ['/ytaudio', sub {
        my ($request) = @_;
        $request->{'qs'}{'media'} //= 'music';
        $self->onYoutube($request);
    }],
    ['/ytplayer', sub {
        my ($request) = @_;
        my $html = $self->searchbox($request);
        $html .= $self->ytplayer($request);
        $request->SendHTML($html);
    }],
    ['/ytembedplayer', sub {
        my ($request) = @_;
        $request->SendHTML($self->ytplayer($request));
    }],
    ];
    $self->{'fmts'} = {'music' => 'bestaudio', 'video' => 'best'};
    $self->{'minsize'} = '1048576';
    say __PACKAGE__.': adding video format yt';
    $server->{'loaded_plugins'}{'MHFS::Plugin::GetVideo'}{'VIDEOFORMATS'}{yt} = {'lock' => 1, 'ext' => 'yt', 'plugin' => $self};
    my $pstart = __PACKAGE__.": ";
    # check for youtube-dl and install if not specified
    my $youtubedl = $settings->{'Youtube'}{'youtube-dl'};
    my $installed;
    if(!$youtubedl) {
        my $mhfsytdl = $settings->{'GENERIC_TMPDIR'}.'/youtube-dl';
        if(! -e $mhfsytdl) {
            say $pstart."Attempting to download youtube-dl";
            if(system('curl', '-L', 'https://yt-dl.org/downloads/latest/youtube-dl', '-o', $mhfsytdl) != 0) {
                say $pstart . "Failed to download youtube-dl. plugin load failed";
                return undef;
            }
            if(system('chmod', 'a+rx', $mhfsytdl) != 0) {
                say $pstart . "Failed to set youtube-dl permissions. plugin load failed";
                return undef;
            }
            $installed = 1;
            say $pstart."youtube-dl successfully installed!";
        }
        $youtubedl = $mhfsytdl;
    }
    elsif( ! -e $youtubedl) {
        say $pstart . "youtube-dl not found. plugin load failed";
        return undef;
    }
    $self->{'youtube-dl'} = $youtubedl;
    # update if we didn't just install
    if(! $installed) {
        say  $pstart . "Attempting to update youtube-dl";
        if(fork() == 0)
        {
            system "$youtubedl", "-U";
            exit 0;
        }
    }
    return $self;
}
1;
