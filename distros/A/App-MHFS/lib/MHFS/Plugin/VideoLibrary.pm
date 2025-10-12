package MHFS::Plugin::VideoLibrary v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Feature::Compat::Try;
use Encode qw(decode);
use URI::Escape qw (uri_escape);
use MHFS::Util qw(output_dir_versatile escape_html uri_escape_path);

sub player_video {
    my ($request) = @_;
    my $qs = $request->{'qs'};
    my $server = $request->{'client'}{'server'};
    my $packagename = __PACKAGE__;
    my $settings = $server->{'settings'};
    my $self = $request->{'client'}{'server'}{'loaded_plugins'}{$packagename};

    my $buf =  "<html>";
    $buf .= "<head>";
    $buf .= '<style type="text/css">';
    my $temp = do {
        try { $server->GetTextResource($settings->{'DOCUMENTROOT'} . '/static/' . 'video_style.css') }
        catch ($e) {
            say "video_style.css not found";
            \''
        }
    };
    $buf .= $$temp;
    $buf .= '.searchfield { width: 50%; margin: 30px;}';
    $buf .= '</style>';
    $buf .= "</head>";
    $buf .= "<body>";

    $qs->{'action'} //= 'library';

    # action=library
    $buf .= '<div id="medialist">';
    $qs->{'library'} //= 'all';
    $qs->{'library'} = lc($qs->{'library'});
    my @libraries = ('movies', 'tv', 'other');
    if($qs->{'library'} ne 'all') {
        @libraries = ($qs->{'library'});
    }
    my %libraryprint = ( 'movies' => 'Movies', 'tv' => 'TV', 'other' => 'Other');
    print "plugin $_\n" foreach keys %{$server->{'loaded_plugins'}};
    my $fmt = $server->{'loaded_plugins'}{'MHFS::Plugin::GetVideo'}->video_get_format($qs->{'fmt'});
    foreach my $library (@libraries) {
        exists $settings->{'MEDIASOURCES'}{$library} or next;
        my $lib = $settings->{'MEDIASOURCES'}{$library};
        my $libhtmlcontent;
        foreach my $sid (@$lib) {
            my $sublib = $settings->{'SOURCES'}{$sid};
            next if(! -d $sublib->{'folder'});
            $libhtmlcontent .= ${video_library_html($sublib->{'folder'}, $library, $sid, {'fmt' => $fmt})};
        }
        next if(! $libhtmlcontent);
        $buf .= "<h1>" . $libraryprint{$library} . "</h1><ul>\n";
        $buf .= $libhtmlcontent.'</ul>';
    }
    $buf .= '</div>';

    # add the video player
    $temp = do {
        try { $server->GetTextResource($server->{'loaded_plugins'}{'MHFS::Plugin::GetVideo'}{'VIDEOFORMATS'}{$fmt}->{'player_html'}) }
        catch ($e) {
            say "player_html not found";
            \''
        }
    };
    $buf .= $$temp;
    $buf .= '<script>';
    $temp = do {
        try { $server->GetTextResource($settings->{'DOCUMENTROOT'} . '/static/' . 'setVideo.js'); }
        catch ($e) {
            say "setVideo.js not found";
            \''
        }
    };
    $buf .= $$temp;
    $buf .= '</script>';
    $buf .= "</body>";
    $buf .= "</html>";
    $request->SendHTML($buf);
}

sub video_library_html {
    my ($dir, $lib, $sid, $opt) = @_;
    my $fmt = $opt->{'fmt'};

    my $urlconstant = 'lib='.$lib.'&sid='.$sid;
    my $playlisturl = "playlist/video/$sid/";

    my $buf;
    output_dir_versatile($dir, {
        'root' => $dir,
        'min_file_size' => 100000,
        'on_dir_start' => sub {
            my ($realpath, $unsafe_relpath) = @_;
            my $relpath = uri_escape($unsafe_relpath);
            my $disppath = escape_html(decode('UTF-8', $unsafe_relpath));
            $buf .= '<li><div class="row">';
            $buf .= '<a href="#' . $relpath . '_hide" class="hide" id="' . $$disppath . '_hide">' . "$$disppath</a>";
            $buf .= '<a href="#' . $relpath . '_show" class="show" id="' . $$disppath . '_show">' . "$$disppath</a>";
            $buf .= '    <a href="'.$playlisturl . uri_escape_path($unsafe_relpath) . '?fmt=m3u8">M3U</a>';
            $buf .= '<div class="list"><ul>';
        },
        'on_dir_end' => sub {
            $buf .= '</ul></div></div></li>';
        },
        'on_file' => sub {
            my ($realpath, $unsafe_relpath, $unsafe_name) = @_;
            my $relpath = uri_escape($unsafe_relpath);
            my $filename = escape_html(decode('UTF-8', $unsafe_name));
            $buf .= '<li><a href="video?'.$urlconstant.'&name='.$relpath.'&fmt=' . $fmt . '" class="mediafile">' . $$filename . '</a>    <a href="get_video?'.$urlconstant.'&name=' . $relpath . '&fmt=' . $fmt . '">DL</a>    <a href="'.$playlisturl . uri_escape_path($unsafe_relpath) . '?fmt=m3u8">M3U</a></li>';
        }
    });
    return \$buf;
}

sub new {
    my ($class, $settings) = @_;
    my $self =  {};
    bless $self, $class;

    $self->{'routes'} = [
        [
            '/video', \&player_video
        ],
        [
            '/video/', sub {
                my ($request) = @_;
                $request->SendRedirect(301, '../video');
            }
        ],
    ];
    return $self;
}

1;
