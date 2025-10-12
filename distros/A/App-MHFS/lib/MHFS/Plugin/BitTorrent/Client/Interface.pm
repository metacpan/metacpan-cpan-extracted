package MHFS::Plugin::BitTorrent::Client::Interface v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use MHFS::BitTorrent::Client;
use MHFS::Util qw(escape_html do_multiples get_SI_size);
use URI::Escape qw(uri_escape);

sub is_video {
    my ($name) = @_;
    my ($ext) = $name =~ /\.(mkv|avi|mp4|webm|flv|ts|mpeg|mpg|m2t|m2ts|wmv)$/i;
    return $ext;
}

sub is_mhfs_music_playable {
    my ($name) = @_;
    return $name =~ /\.(?:flac|mp3|wav)$/i;
}

sub play_in_browser_link {
    my ($file, $urlfile) = @_;
    return '<a href="video?name=' . $urlfile . '&fmt=hls">HLS (Watch in browser)</a>' if(is_video($file));
    return '<a href="music?ptrack=' . $urlfile . '">Play in MHFS Music</a>' if(is_mhfs_music_playable($file));
    return 'N/A';
}

sub torrentview {
    my ($request) = @_;
    my $qs = $request->{'qs'};
    my $server = $request->{'client'}{'server'};
    my $evp = $server->{'evp'};
    # dump out the status, if the torrent's infohash is provided
    if(defined $qs->{'infohash'}) {
        my $hash = $qs->{'infohash'};
        do_multiples({
        'bytes_done' => sub { MHFS::BitTorrent::Client::torrent_d_bytes_done($server, $hash, @_); },
        'size_bytes' => sub { MHFS::BitTorrent::Client::torrent_d_size_bytes($server, $hash, @_); },
        'name'       => sub { MHFS::BitTorrent::Client::torrent_d_name($server, $hash, @_); },
        }, sub {
        if( ! defined $_[0]) { $request->Send404; return;}
        my ($data) = @_;
        my $torrent_raw = $data->{'name'};
        my $bytes_done  = $data->{'bytes_done'};
        my $size_bytes  = $data->{'size_bytes'};
        # print out the current torrent status
        my $torrent_name = ${escape_html($torrent_raw)};
        my $size_print = get_SI_size($size_bytes);
        my $done_print = get_SI_size($bytes_done);
        my $percent_print = (sprintf "%u%%", ($bytes_done/$size_bytes)*100);
        my $buf = '<h1>Torrent</h1>';
        $buf  .=  '<h3><a href="../video">Video</a> | <a href="../music">Music</a></h3>';
        $buf   .= '<table border="1" >';
        $buf   .= '<thead><tr><th>Name</th><th>Size</th><th>Done</th><th>Downloaded</th></tr></thead>';
        $buf   .= "<tbody><tr><td>$torrent_name</td><td>$size_print</td><td>$percent_print</td><td>$done_print</td></tr></tbody>";
        $buf   .= '</table>';

        # Assume we are downloading, if the bytes don't match
        if($bytes_done < $size_bytes) {
            $buf   .= '<meta http-equiv="refresh" content="3">';
            $request->SendHTML($buf);
        }
        else {
            # print out the files with usage options
            MHFS::BitTorrent::Client::torrent_file_information($server, $qs->{'infohash'}, $torrent_raw, sub {
            if(! defined $_[0]){ $request->Send404; return; };
            my ($tfi) = @_;
            my @files = sort (keys %$tfi);
            $buf .= '<br>';
            $buf .= '<table border="1" >';
            $buf .= '<thead><tr><th>File</th><th>Size</th><th>DL</th><th>Play in browser</th></tr></thead>';
            $buf .= '<tbody';
            foreach my $file (@files) {
                my $htmlfile = ${escape_html($file)};
                my $urlfile = uri_escape($file);
                my $link = '<a href="get_video?name=' . $urlfile . '&fmt=noconv">DL</a>';
                my $playlink = play_in_browser_link($file, $urlfile);
                $buf .= "<tr><td>$htmlfile</td><td>" . get_SI_size($tfi->{$file}{'size'}) . "</td><td>$link</td>";
                $buf .= "<td>$playlink</td>" if(!defined($qs->{'playinbrowser'}) || ($qs->{'playinbrowser'} == 1));
                $buf .= "</tr>";
            }
            $buf .= '</tbody';
            $buf .= '</table>';

            $request->SendHTML($buf);
            });
        }

        });
    }
    else {
        MHFS::BitTorrent::Client::torrent_list_torrents($server, sub{
            if(! defined $_[0]){ $request->Send404; return; };
            my ($rtresponse) = @_;
            my @lines = split( /\n/, $rtresponse);
            my $buf = '<h1>Torrents</h1>';
            $buf  .=  '<h3><a href="video?action=browsemovies">Browse Movies</a> | <a href="video">Video</a> | <a href="music">Music</a></h3>';
            $buf   .= '<table border="1" >';
            $buf   .= '<thead><tr><th>Name</th><th>Hash</th><th>Size</th><th>Done</th><th>Private</th></tr></thead>';
            $buf   .= "<tbody>";
            my $curtor = '';
            while(1) {
                if($curtor =~ /^\[(u?)['"](.+)['"],\s'(.+)',\s([0-9]+),\s([0-9]+),\s([0-9]+)\]$/) {
                    my %torrent;
                    my $is_unicode = $1;
                    $torrent{'name'} = $2;
                    $torrent{'hash'} = $3;
                    $torrent{'size_bytes'} = $4;
                    $torrent{'bytes_done'} = $5;
                    $torrent{'private'} = $6;
                    if($is_unicode) {
                        my $escaped_unicode = $torrent{'name'};
                        $torrent{'name'} =~ s/\\u(.{4})/chr(hex($1))/eg;
                        $torrent{'name'} =~ s/\\x(.{2})/chr(hex($1))/eg;
                        my $decoded_as = $torrent{'name'};
                        $torrent{'name'} = ${escape_html($torrent{'name'})};
                        if($qs->{'logunicode'}) {
                            say 'unicode escaped: ' . $escaped_unicode;
                            say 'decoded as: ' . $decoded_as;
                            say 'html escaped ' . $torrent{'name'};
                        }
                    }
                    $buf .= '<tr><td>' . $torrent{'name'} . '</td><td>' . $torrent{'hash'} . '</td><td>' . $torrent{'size_bytes'} . '</td><td>' . $torrent{'bytes_done'} . '</td><td>' . $torrent{'private'} . '</td></tr>';
                    $curtor = '';
                }
                else {
                    my $line = shift @lines;
                    if(! $line) {
                        last;
                    }
                    $curtor .= $line;
                }
            }
            $buf   .= '</tbody></table>';
            $request->SendHTML($buf);
        });
    }
}

sub torrentload {
    my ($request) = @_;
    my $packagename = __PACKAGE__;
    my $self = $request->{'client'}{server}{'loaded_plugins'}{$packagename};

    if((exists $request->{'qs'}{'dlsubsystem'}) && (exists $request->{'qs'}{'privdata'}) ) {
        my $subsystem = $request->{'qs'}{'dlsubsystem'};
        if(exists $self->{'dlsubsystems'}{$subsystem}) {
            my $server = $request->{'client'}{'server'};
            $self->{'dlsubsystems'}{$subsystem}->dl($server, $request->{'qs'}{'privdata'}, sub {
                my ($result, $destdir) = @_;
                if(! $result) {
                    say "failed to dl torrent";
                    $request->Send404;
                    return;
                }
                MHFS::BitTorrent::Client::torrent_start($server, \$result, $destdir, {
                    'on_success' => sub {
                        my ($hexhash) = @_;
                        $request->SendRedirectRawURL(301, 'view?infohash=' . $hexhash);
                    },
                    'on_failure' => sub {
                        $request->Send404;
                    }
                });
            });
            return;
        }
    }
    $request->Send404;
}

sub new {
    my ($class, $settings) = @_;
    my $self =  { 'dlsubsystems' => {}};
    bless $self, $class;

    $self->{'routes'} = [
        [ '/torrent/view', \&torrentview ],
        [ '/torrent/load', \&torrentload ]
    ];

    return $self;
}

1;
