package MHFS::Plugin::Playlist v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Data::Dumper;
use URI::Escape qw(uri_escape);
use Encode qw(decode);

sub video_get_m3u8 {
    my ($video, $urlstart) = @_;
    my $buf;
    my $m3u8 = <<'M3U8END';
#EXTM3U
#EXTVLCOPT:network-caching=40000'
M3U8END

    my @files;
    if(! -d $video->{'src_file'}{'filepath'}) {
        push @files, $video->{'src_file'}{'fullname'};
    }
    else {
        output_dir_versatile($video->{'src_file'}{'filepath'}, {
            'root' => $video->{'src_file'}{'root'},
            'on_file' => sub {
                my ($path, $shortpath) = @_;
                push @files, $shortpath;
            }
        });
    }

    foreach my $file (@files) {
        $m3u8 .= '#EXTINF:0, ' . decode('UTF-8', $file, Encode::LEAVE_SRC) . "\n";
        $m3u8 .= $urlstart . uri_escape($file) . "\n";
        #$m3u8 .= $urlstart . small_url_encode($file) . "\n";
    }
    return \$m3u8;
}

sub new {
    my ($class, $settings, $server) = @_;
    my $self =  {};
    bless $self, $class;

    my @subsystems = ('video');

    $self->{'routes'} = [
        [
            '/playlist/*', sub {
                my ($request) = @_;
                my $qs = $request->{'qs'};
                my @pathcomponents = split('/', $request->{'path'}{'unsafepath'});
                if(scalar(@pathcomponents) >= 3) {
                    if($pathcomponents[2] eq 'video') {
                        if(scalar(@pathcomponents) >= 5) {
                            my %video = ('out_fmt' => ($request->{'qs'}{'vfmt'} // 'noconv'));
                            my $sid = $pathcomponents[3];
                            splice(@pathcomponents, 0, 4);
                            my $nametolookup = join('/', @pathcomponents);
                            $video{'src_file'} = $server->{'fs'}->lookup($nametolookup, $sid);
                            if( ! $video{'src_file'} ) {
                                $request->Send404;
                                return undef;
                            }
                            $video{'out_base'} = $video{'src_file'}{'name'};
                            my $fmt = $request->{'qs'}{'fmt'} // 'm3u8';
                            if($fmt eq 'm3u8') {
                                my $absurl = $request->getAbsoluteURL;
                                if(! $absurl) {
                                    say 'unable to $request->getAbsoluteURL';
                                    $request->Send404;
                                    return undef;
                                }
                                my $m3u8 = video_get_m3u8(\%video,  $absurl . '/get_video?sid='. $sid . '&name=');
                                $video{'src_file'}{'ext'} = $video{'src_file'}{'ext'} ? '.'. $video{'src_file'}{'ext'} : '';
                                $request->{'responseopt'}{'cd_file'} = 'inline';
                                $request->SendText('application/x-mpegURL', $$m3u8, {'filename' => $video{'src_file'}{'name'} . $video{'src_file'}{'ext'} . '.m3u8'});
                                return 1;
                            }
                        }
                    }
                }
                $request->Send404;
            }
        ],
    ];

    return $self;
}

1;
