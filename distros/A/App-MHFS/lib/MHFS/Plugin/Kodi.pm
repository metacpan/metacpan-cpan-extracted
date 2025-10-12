package MHFS::Plugin::Kodi v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use File::Basename qw(basename);
use Cwd qw(abs_path getcwd);
use URI::Escape qw(uri_escape);
use Encode qw(decode encode_utf8);
use File::Path qw(make_path);
use Data::Dumper qw(Dumper);
use Scalar::Util qw(weaken);
use MIME::Base64 qw(encode_base64url decode_base64url);
use Devel::Peek qw(Dump);
use MHFS::Kodi::TVShows;
use MHFS::Kodi::Movie;
use MHFS::Kodi::MovieEdition;
use MHFS::Kodi::MovieEditions;
use MHFS::Kodi::MoviePart;
use MHFS::Kodi::Movies;
use MHFS::Kodi::MovieSubtitle;
use MHFS::Kodi::Season;
use MHFS::Process;
use MHFS::Promise;
use MHFS::Util qw(base64url_to_str str_to_base64url uri_escape_path_utf8 read_text_file_lossy write_text_file_lossy decode_utf_8 escape_html_noquote fold_case write_file read_file);
use Feature::Compat::Try;
BEGIN {
    if( ! (eval "use JSON; 1")) {
        eval "use JSON::PP; 1" or die "No implementation of JSON available";
        warn __PACKAGE__.": Using PurePerl version of JSON (JSON::PP)";
    }
}

sub readtvdir {
    my ($self, $tvshows, $source, $b_tvdir) = @_;
    my $dh;
    if (! opendir ( $dh, $b_tvdir )) {
        warn "Error in opening dir $b_tvdir\n";
        return;
    }
    my @diritems;
    while (my $b_filename = readdir($dh)) {
        next if(($b_filename eq '.') || ($b_filename eq '..'));
        next if(!(-s "$b_tvdir/$b_filename"));
        my $filename = decode('UTF-8', $b_filename, Encode::FB_DEFAULT | Encode::LEAVE_SRC);
        next if (! -d _ && $filename !~ /\.(?:avi|mkv|mp4|m4v)$/);
        if ($filename !~ /^(.+?)(?:[\.\s]+(\d{4}))?[\.\s]+S(?:eason\s)?0*(\d+)/) {
            say "suspicious: $filename";
        }
        if ($filename =~ /S(?:eason\s)?0*(\d+)\-S(?:eason\s)?0*(\d+)/) {
            $self->readtvdir($tvshows, $source, "$b_tvdir/$b_filename");
            next;
        }
        my $showname = $1 || $filename;
        my $year = $2;
        my $season = $3 // 0;
        next if (! $showname);
        $showname =~ s/\./ /g;
        my $showid = fold_case($showname);
        if (! $tvshows->{$showid}) {
            my %show = (name => $showname, seasons => {});
            my $plot = $self->{tvmeta}."/$showid/plot.txt";
            try { $show{plot} = read_text_file_lossy($plot); }
            catch($e) {}
            $tvshows->{$showid} = \%show;
        }
        $tvshows->{$showid}{seasons}{$season} //= {};
        $tvshows->{$showid}{seasons}{$season}{"$source/$b_filename"} = {name => $filename, isdir => (-d _ // 0)+0};
    }
    closedir($dh);
}

sub _build_tv_library {
    my ($self, $sources) = @_;
    my %tvshows;
    foreach my $source (@$sources) {
        if ($self->{server}{settings}{SOURCES}{$source}{type} ne 'local') {
            warn "skipping source $source, only local implemented";
            next;
        }
        my $b_tvdir = $self->{server}{settings}{SOURCES}{$source}{folder};
        $self->readtvdir(\%tvshows, $source, $b_tvdir);
    }
    # load the season metadata, maybe remove this if we allow querying a show without a season
    while (my ($showid, $show) = each %tvshows) {
        while (my ($seasonid, $season) = each %{$show->{seasons}}) {
            my $meta;
            try {
                my $bytes = read_file($self->{tvmeta}."/$showid/$seasonid/season.json");
                $meta = decode_json($bytes);
            } catch($e) {}
            $meta or next;
            # HACK: modifies each season item as there isn't a season object
            foreach my $value (values %$season) {
                $value->{plot} = $meta->{overview};
            }
        }
    }
    \%tvshows
}

sub _get_tv_item {
    my ($self, $tvshows, $showid, $seasonid, $source, $b64_item) = @_;
    exists $tvshows->{$showid} or die "showid $showid does not exist";
    exists $tvshows->{$showid}{seasons}{$seasonid} or die "season $seasonid does not exist";
    my $seasonitem = $tvshows->{$showid}{seasons}{$seasonid};
    my $sourcemap = $self->{server}{settings}{SOURCES};
    my $meta;
    try {
        my $bytes = read_file($self->{tvmeta}."/$showid/$seasonid/season.json");
        $meta = decode_json($bytes);
    } catch($e) {}
    $source or return bless {season => $seasonitem, id => $seasonid, sourcemap => $sourcemap, ($meta ? (meta => $meta) : ())}, 'MHFS::Kodi::Season';
    $b64_item or die "b64_item not provided";
    my $path = abs_path($self->{server}{settings}{SOURCES}{$source}{folder} .'/' . decode_base64url($b64_item));
    if (!$path || rindex($path, $self->{server}{settings}{SOURCES}{$source}{folder}, 0) != 0, ! -f $path) {
        die "item not found";
    }
    {b_path => $path}
}

# format tv library for kodi http
sub route_tv {
    my ($self, $request, $sources, $kodidir) = @_;
    my $request_path = do {
        try { decode_utf_8($request->{path}{unsafepath}) }
        catch($e) {
            warn "$request->{path}{unsafepath} is not, UTF-8, 404";
            $request->Send404;
            return;
        }
    };
    # build the tv show library
    if(! exists $self->{tvshows} || $request_path eq $kodidir) {
        $self->{tvshows} = $self->_build_tv_library($sources);
    }
    my $tvshows = $self->{tvshows};
    my $tvitem;
    if ($request_path ne $kodidir) {
        my $fulltvpath = substr($request_path, length($kodidir)+1);
        say "fulltvpath $fulltvpath";
        my ($showid, $season, $source, $b64_item, $slurp) = split('/', $fulltvpath, 5);
        if ($slurp) {
            say "too many parts";
            $request->Send400;
            return;
        }
        $showid = fold_case($showid);
        $season // do {
            say "no season provided";
            $request->Send400;
            return;
        };
        try {
            $tvitem = $self->_get_tv_item($tvshows, $showid, $season, $source, $b64_item);
        } catch($e) {
            say "exception $e";
            $request->Send404;
            return;
        }
        if (substr($request->{'path'}{'unescapepath'}, -1) ne '/') {
            # redirect if we aren't accessing a file
            if (!exists $tvitem->{b_path}) {
                $request->SendRedirect(301, substr($request->{'path'}{'unescapepath'}, rindex($request->{'path'}{'unescapepath'}, '/')+1).'/');
            } else {
                $request->SendFile($tvitem->{b_path});
            }
            return;
        }
    } else {
        $tvitem = bless {tvshows => $tvshows}, 'MHFS::Kodi::TVShows';
    }
    if(exists $request->{qs}{fmt} && $request->{qs}{fmt} eq 'html') {
        my $buf = $tvitem->TO_HTML;
        $request->SendHTML($buf);
    } else {
        my $diritems = $tvitem->TO_JSON;
        $request->SendAsJSON($diritems);
    }
}

sub readsubdir{
    my ($subtitles, $source, $b_path) = @_;
    opendir( my $dh, $b_path ) or return;
    while(my $b_filename = readdir($dh)) {
        next if(($b_filename eq '.') || ($b_filename eq '..'));
        my $filename = do {
            try { decode_utf_8($b_filename) }
            catch($e) {
                warn "$b_filename is not, UTF-8, skipping";
                next;
            }
        };
        my $b_nextpath = "$b_path/$b_filename";
        my $nextsource = "$source/$filename";
        if(-f $b_nextpath && $filename =~ /\.(?:srt|sub|idx)$/) {
            push @$subtitles, $nextsource;
            next;
        } elsif (-d _) {
            readsubdir($subtitles, $nextsource, $b_nextpath);
        }
    }
}

sub readmoviedir {
    my ($self, $movies, $source, $b_moviedir) = @_;
    opendir(my $dh, $b_moviedir ) or do {
        warn "Error in opening dir $b_moviedir\n";
        return;
    };
    while(my $b_edition = readdir($dh)) {
        next if(($b_edition eq '.') || ($b_edition eq '..'));
        my $edition = do {
            try { decode_utf_8($b_edition) }
            catch($e) {
                warn "$b_edition is not, UTF-8, skipping";
                next;
            }
        };
        my $b_path = "$b_moviedir/$b_edition";
        # recurse on collections
        if ($edition =~ /(?:Duology|Trilogy|Quadrilogy)/) {
            next if ($edition =~ /\.nfo$/);
            $self->readmoviedir($movies, "$source/$edition", $b_path);
            next;
        }
        -s $b_path or next;
        my $isdir = -d _;
        $isdir || -f _ or next;
        $isdir ||= 0;
        my %edition;
        if (!$isdir) {
            if ($edition !~ /\.(?:avi|mkv|mp4|m4v)$/) {
                warn "Skipping $edition, not a movie file" if ($edition !~ /\.(?:txt)$/);
                next;
            }
            $edition{''} = {};
        } else {
            my @videos;
            my @subtitles;
            my @subtitledirs;
            opendir(my $dh, $b_path) or do {
                warn 'failed to open dir';
                next;
            };
            while(my $b_editionitem = readdir($dh)) {
                next if(($b_editionitem eq '.') || ($b_editionitem eq '..'));
                my $editionitem = do {
                    try { decode_utf_8($b_editionitem) }
                    catch($e) {
                        warn "$b_editionitem is not, UTF-8, skipping";
                        next;
                    }
                };
                my $type;
                if ($editionitem =~ /\.(?:avi|mkv|mp4|m4v)$/) {
                    $type = 'video' if ($editionitem !~ /sample(?:\-[a-z]+)?\.(?:avi|mkv|mp4|m4v)$/);
                } elsif ($editionitem =~ /\.(?:srt|sub|idx)$/) {
                    $type = 'subtitle';
                } elsif ($editionitem =~ /^Subs$/i) {
                    $type = 'subtitledir';
                }
                $type or next;
                if (-f "$b_path/$b_editionitem") {
                    push @videos, $editionitem if($type eq 'video');
                    push @subtitles, $editionitem if($type eq 'subtitle');
                } elsif (-d _ && $type eq 'subtitledir') {
                    push @subtitledirs, $editionitem;
                }
            }
            closedir($dh);
            if (!@videos) {
                warn "not adding edition $edition, no videos found";
                next;
            }
            foreach my $subdir (@subtitledirs) {
                readsubdir(\@subtitles, $subdir, "$b_path/$subdir");
            }
            foreach my $videofile (@videos) {
                my ($withoutext) = $videofile =~ /^(.+)\.[^\.]+$/;
                my %relevantsubs;
                for my $i (reverse 0 .. $#subtitles) {
                    if (basename($subtitles[$i]) =~ /^\Q$withoutext\E/i) {
                        $relevantsubs{splice(@subtitles, $i, 1)} = undef;
                    }
                }
                $edition{"/$videofile"} = scalar %relevantsubs ? {subs => \%relevantsubs} : {};
            }
            if(@subtitles) {
                warn "$edition: unmatched subtitle $_" foreach @subtitles;
            }
        }
        my $showname;
        my $withoutyear;
        my $year;
        if($edition =~ /^(.+)[\.\s]+\(?(\d{4})([^p]|$)/) {
            $showname = "$1 ($2)";
            $withoutyear = $1;
            $year = $2;
            $withoutyear =~ s/\./ /g;
        }
        elsif ($edition =~ /(.+)\s?\[(\d{4})\]/) {
            $showname = "$1 ($2)";
            $withoutyear = $1;
            $year = $2;
            $withoutyear =~ s/\./ /g;
        }
        elsif($edition =~ /^(.+)[\.\s](?i:DVDRip)[\.\s]./) {
            $showname = $1;
        }
        elsif($edition =~ /^(.+)[\.\s](?:DVD|RERIP|BRrip)/) {
            $showname = $1;
        }
        elsif($edition =~ /^(.+)\s\(PSP.+\)/) {
            $showname = $1;
        }
        elsif($edition =~ /^(.+)\.VHS/) {
            $showname = $1;
        }
        elsif($edition =~ /^(.+)[\.\s]+\d{3,4}p\./) {
            $showname = $1;
        }
        elsif($edition =~ /^(.+)\.[a-zA-Z\d]{3,4}$/) {
            $showname = $1;
        }
        else{
            $showname = $edition;
        }
        $showname =~ s/\./ /g;
        if(! $movies->{$showname}) {
            my %diritem;
            if(defined $year) {
                $diritem{name} = $withoutyear;
                $diritem{year} = $year;
            }
            my $b_showname = encode_utf8($showname);
            my $plot = $self->{moviemeta}."/$b_showname/plot.txt";
            try { $diritem{plot} = read_text_file_lossy($plot); }
            catch($e) {}
            $movies->{$showname} = \%diritem;
        }
        $movies->{$showname}{editions}{"$source/$edition"} = \%edition;
    }
    closedir($dh);
}

sub _build_movie_library {
    my ($self, $sources) = @_;
    my %movies;
    foreach my $source (@$sources) {
        if ($self->{server}{settings}{SOURCES}{$source}{type} ne 'local') {
            warn "skipping source $source, only local implemented";
            next;
        }
        my $b_moviedir = $self->{server}{settings}{SOURCES}{$source}{folder};
        $self->readmoviedir(\%movies, $source, $b_moviedir);
    }
    \%movies
}

# dies on not found/error
sub _search_movie_library {
    my ($self, $movies, $movieid, $source, $editionname, $partname, $subfile) = @_;
    unless(exists $movies->{$movieid}) {
        die "movie not found";
    }
    $movies = $movies->{$movieid};
    if (!$source) {
        return bless {movie => $movies}, 'MHFS::Kodi::Movie';
    }
    $movies = $movies->{editions};
    if(!$editionname) {
        my %editions = map { $_ =~ /^$source/ ? ($_ => $movies->{$_}) : () } keys %$movies;
        return bless {editions => \%editions}, 'MHFS::Kodi::MovieEditions';
    }
    unless(exists $movies->{"$source/$editionname"}) {
        die "movie source not found";
    }
    $movies = $movies->{"$source/$editionname"};
    unless(defined $partname) {
        return bless {source => $source, editionname => $editionname, edition => $movies}, 'MHFS::Kodi::MovieEdition';
    }
    unless(exists $movies->{$partname}) {
        die "movie part not found";
    }
    my $b_moviedir = $self->{server}{settings}{SOURCES}{$source}{folder};
    my $b_editionname = encode_utf8($editionname);
    my $b_editiondir = "$b_moviedir/$b_editionname";
    $movies = $movies->{$partname};
    if (!$subfile) {
        my $b_partname = encode_utf8($partname);
        return bless {b_path => "$b_editiondir$b_partname", editionname => $editionname, partname => $partname, part => $movies}, 'MHFS::Kodi::MoviePart';
    }
    unless(exists $movies->{subs} && exists $movies->{subs}{$subfile}) {
        die "subtitle file not found";
    }
    my $b_subfile = encode_utf8($subfile);
    return bless {b_path => "$b_editiondir/$b_subfile", subtitle => $subfile}, 'MHFS::Kodi::MovieSubtitle';
}

# format movies library for kodi http
sub route_movies {
    my ($self, $request, $sources, $kodidir) = @_;
    my $request_path = do {
        try { decode_utf_8($request->{path}{unsafepath}) }
        catch($e) {
            warn "$request->{path}{unsafepath} is not, UTF-8, 404";
            $request->Send404;
            return;
        }
    };
    # build the movie library
    if(! exists $self->{movies} || $request_path eq $kodidir) {
        $self->{movies} = $self->_build_movie_library($sources);
    }
    my $movies = $self->{movies};
    # find the movie item
    my $movieitem;
    if($request_path ne $kodidir) {
        my $fullmoviepath = substr($request_path, length($kodidir)+1);
        say "fullmoviepath $fullmoviepath";
        my ($movieid, $source, $b64_editionname, $b64_partname, $b64_subpath, $subname, $slurp) = split('/', $fullmoviepath, 7);
        if ($slurp) {
            say "too many parts";
            $request->Send404;
            return;
        }
        say "movieid $movieid";
        my $editionname;
        my $partname;
        my $subfile;
        try {
            if ($source) {
                say "source $source";
                if ($b64_editionname) {
                    $editionname = base64url_to_str($b64_editionname);
                    say "editionname $editionname";
                    if ($b64_partname) {
                        if (length($b64_partname) < 3) {
                            warn "$b64_partname has invalid format";
                            $request->Send404;
                            return;
                        }
                        $b64_partname = substr($b64_partname, 0, -3);
                        $partname = base64url_to_str($b64_partname);
                        say "partname $partname";
                        if ($b64_subpath && $subname) {
                            if (length($b64_subpath) < 3) {
                                warn "$b64_subpath has invalid format";
                                $request->Send404;
                                return;
                            }
                            $b64_subpath = substr($b64_subpath, 0, -3);
                            my $subpath = base64url_to_str($b64_subpath);
                            $subfile = "$subpath$subname";
                            say "subfile $subfile";
                        }
                    }
                }
            }
            $movieitem = $self->_search_movie_library($movies, $movieid, $source, $editionname, $partname, $subfile);
        } catch ($e) {
            $request->Send404;
            return;
        }
        if (substr($request->{'path'}{'unescapepath'}, -1) ne '/') {
            # redirect if we aren't accessing a file
            if (!exists $movieitem->{b_path}) {
                $request->SendRedirect(301, substr($request->{'path'}{'unescapepath'}, rindex($request->{'path'}{'unescapepath'}, '/')+1).'/');
            } else {
                $request->SendFile($movieitem->{b_path});
            }
            return;
        }
    } else {
        $movieitem = bless {movies => $movies}, 'MHFS::Kodi::Movies';
    }
    # render
    if(exists $request->{qs}{fmt} && $request->{qs}{fmt} eq 'html') {
        my $buf = $movieitem->TO_HTML;
        $request->SendHTML($buf);
    } else {
        my $diritems = $movieitem->TO_JSON;
        $request->SendAsJSON($diritems);
    }
}

sub route_kodi {
    my ($self, $request, $kodidir) = @_;
    my $request_path = do {
        try { decode_utf_8($request->{path}{unsafepath}) }
        catch($e) {
            warn "$request->{path}{unsafepath} is not, UTF-8, 404";
            $request->Send404;
            return;
        }
    };
    my $baseurl = $request->getAbsoluteURL;
    my $repo_addon_version = '0.1.0';
    my $repo_addon_name = "repository.mhfs-$repo_addon_version.zip";
    if ($request_path eq $kodidir) {
        my $html = <<"END_HTML";
<style>ul{list-style: none;} li{margin: 10px 0;}</style>
<h1>MHFS Kodi Setup Instructions</h1>
<ol>
<li>Open Kodi</li>
<li>Go to <b>Settings->File manager</b>, <b>Add source</b> (you may have to double-click), and add <b>$baseurl$kodidir</b> (the URL of this page) as a source.</li>
<li>Go to <b>Settings->Add-ons->Install from zip file</b>, open the source you just added, and select <b>$repo_addon_name</b>. The repository add-on should install.</li>
<li>From <b>Settings->Add-ons</b> (you should still be on that page), <b>Install from repository->MHFS Repository->Video add-ons->MHFS Video</b> and click <b>Install</b>. The plugin addon should install.</li>
<li>Click <b>Configure</b> (or open the MHFS Video settings) and fill in <b>$baseurl</b> (the URL of the MHFS server you want to connect to).</li>
<li>MHFS Video should now be installed, you should be able to access it from <b>Add-ons->Video add-ons->MHFS Video</b> on the main menu</li>
</ol>
<ul>
<a href="$repo_addon_name">$repo_addon_name</a>
</ul>
END_HTML
        $request->SendHTML($html);
        return;
    } elsif (substr($request_path, length($kodidir)+1) ne $repo_addon_name ||
                substr($request->{'path'}{'unescapepath'}, -1) eq '/') {
        $request->Send404;
        return;
    }
    my $xml = <<"END_XML";
<?xml version="1.0" encoding="UTF-8"?>
<addon id="repository.mhfs"
    name="MHFS Repository"
    version="$repo_addon_name"
    provider-name="G4Vi">
<extension point="xbmc.addon.repository" name="MHFS Repository">
<dir>
    <info>$baseurl/static/kodi/addons.xml</info>
    <checksum>$baseurl/static/kodi/addons.xml.md5</checksum>
    <datadir zip="true">$baseurl/static/kodi</datadir>
</dir>
</extension>
<extension point="xbmc.addon.metadata">
<summary lang="en_GB">MHFS Repository</summary>
<description lang="en_GB">TODO</description>
<disclaimer></disclaimer>
<platform>all</platform>
<language></language>
<license>GPL-2.0-or-later</license>
<forum>https://github.com/G4Vi/MHFS/issues</forum>
<website>computoid.com</website>
<source>https://github.com/G4Vi/MHFS</source>
</extension>
</addon>
END_XML
    my $tmpdir = $request->{client}{server}{settings}{GENERIC_TMPDIR};
    say "tmpdir $tmpdir";
    my $addondir = "$tmpdir/repository.mhfs";
    make_path($addondir);
    open(my $fh, '>', "$addondir/addon.xml") or do {
        warn "failed to open $addondir/addon.xml";
        $request->Send404;
        return;
    };
    print $fh $xml;
    close($fh) or do {
        warn "failed to close";
        $request->Send404;
        return;
    };
    _zip_Promise($request->{client}{server}, $tmpdir, ['repository.mhfs'])->then(sub {
        $request->SendBytes('application/zip', $_[0]);
    }, sub {
        warn $_[0];
        $request->Send404;
    });
}

sub _zip {
    my ($server, $start_in, $params, $on_success, $on_failure) = @_;
    MHFS::Process->new_output_child($server->{evp}, sub {
        # done in child
        my ($datachannel) = @_;
        chdir($start_in);
        open(STDOUT, ">&", $datachannel) or die("Can't dup \$datachannel to STDOUT");
        exec('zip', '-r', '-', @$params);
        #exec('zip', '-r', 'repository.mhfs.zip', 'repository.mhfs');
        die "failed to run zip";
    }, sub {
        my ($out, $err, $status) = @_;
        if ($status != 0) {
            $on_failure->('failed to zip');
            return;
        }
        $on_success->($out);
    }) // $on_failure->('failed to fork');
}

sub _zip_Promise {
    my ($server, $start_in, $params) = @_;
    return MHFS::Promise->new($server->{evp}, sub {
        my ($resolve, $reject) = @_;
        _zip($server, $start_in, $params, sub {
            $resolve->($_[0]);
        }, sub {
            $reject->($_[0]);
        });
    });
}

sub _curl {
    my ($server, $params, $cb) = @_;
    my $process;
    my @cmd = ('curl', @$params);
    print "$_ " foreach @cmd;
    print "\n";
    $process = MHFS::Process->new_io_process($server->{evp}, \@cmd, sub {
        my ($output, $error) = @_;
        $cb->($output);
    });

    if(! $process) {
        $cb->(undef);
    }

    return $process;
}

sub _TMDB_api {
    my ($server, $route, $qs, $cb) = @_;
    my $url = 'https://api.themoviedb.org/3/' . $route;
    $url .= '?api_key=' . $server->{settings}{TMDB} . '&';
    if($qs){
        foreach my $key (keys %{$qs}) {
            my @values;
            if(ref($qs->{$key}) ne 'ARRAY') {
                push @values, $qs->{$key};
            }
            else {
                @values = @{$qs->{$key}};
            }
            foreach my $value (@values) {
                $url .= uri_escape($key).'='.uri_escape($value) . '&';
            }
        }
    }
    chop $url;
    return _curl($server, [encode_utf8($url)], sub {
        $cb->(decode_json($_[0]));
    });
}

sub _TMDB_api_promise {
    my ($server, $route, $qs) = @_;
    return MHFS::Promise->new($server->{evp}, sub {
        my ($resolve, $reject) = @_;
        _TMDB_api($server, $route, $qs, sub {
            $resolve->($_[0]);
        });
    });
}

sub _DownloadFile {
    my ($server, $url, $dest, $cb) = @_;
    return _curl($server, ['-k', $url, '-o', $dest], $cb);
}

sub _DownloadFile_promise {
    my ($server, $url, $dest) = @_;
    return MHFS::Promise->new($server->{evp}, sub {
        my ($resolve, $reject) = @_;
        _DownloadFile($server, $url, $dest, sub {
            $resolve->();
        });
    });
}

sub DirectoryRoute {
    my ($path_without_end_slash, $cb) = @_;
    return ([
        $path_without_end_slash, sub {
            my ($request) = @_;
            $request->SendRedirect(301, substr($path_without_end_slash, rindex($path_without_end_slash, '/')+1).'/');
        }
    ], [
        "$path_without_end_slash/*", $cb
    ]);
}

sub route_metadata {
    my ($self, $request) = @_;
    my $request_path = do {
        try { decode_utf_8($request->{path}{unsafepath}) }
        catch($e) {
            warn "$request->{path}{unsafepath} is not, UTF-8, 400";
            $request->Send400;
            return;
        }
    };
    my ($mediatype, $metadatatype, $medianame, $season, $episode) = $request_path =~ m!^/kodi/metadata/(movies|tv)/(thumb|fanart|plot)/([^/]+)(?:/0*(\d+)(?:/0*(\d+))?)?$! or do {
        say "no match";
        $request->Send400;
        return;
    };
    if ($medianame =~ /^.(.)?$/ || ($mediatype eq 'movies' && defined $season)) {
        say "no match";
        $request->Send400;
        return;
    }
    if ($metadatatype eq 'fanart') {
        ($season, $episode) = (undef, undef);
    }
    $medianame = fold_case($medianame);
    say "mt $mediatype mmt $metadatatype mn $medianame". (defined $season ? " season $season". (defined $episode ? " episode $episode" : '') : '');
    my %allmediaparams  = ( 'movies' => {
        'meta' => $self->{moviemeta},
        'search' => 'movie',
    }, 'tv' => {
        'meta' => $self->{tvmeta},
        'search' => 'tv'
    });
    my $params = $allmediaparams{$mediatype};
    my $b_metadir = $params->{meta} . '/' . encode_utf8($medianame) . (defined $season ? '/'.encode_utf8($season). (defined $episode ? '/'.encode_utf8($episode) : '') : '');
    my $b_plotfile =  $params->{meta} . '/' . encode_utf8($medianame) . '/'. (defined $season ? encode_utf8($season).'/season.json' : 'plot.txt');
    # fast path, check disk
    if (defined $season && $metadatatype eq 'plot') {
        try {
            my $bytes = read_file($b_plotfile);
            my $json = decode_json($bytes);
            if (defined $episode) {
                $json = MHFS::Kodi::Season::_get_season_episode($json, $episode);
            }
            $request->SendText('text/plain; charset=utf-8', $json->{overview});
            return;
        } catch ($e){}
    } elsif (-d $b_metadir) {
        my %acceptable = ( 'thumb' => ['png', 'jpg'], 'fanart' => ['png', 'jpg'], 'plot' => ['txt']);
        if(exists $acceptable{$metadatatype}) {
            foreach my $totry (@{$acceptable{$metadatatype}}) {
                my $path = $b_metadir.'/'.$metadatatype.".$totry";
                if(-f $path) {
                    $request->SendLocalFile($path);
                    return;
                }
            }
        }
    }
    # slow path, download it
    $request->{client}{server}{settings}{TMDB} or do {
        $request->Send404;
        return;
    };
    # find the movie or tv show
    my $searchname = $medianame;
    $searchname =~ s/\s\(\d\d\d\d\)// if($mediatype eq 'movies');
    say "searchname $searchname";
    weaken($request);
    _TMDB_api_promise($request->{client}{server}, 'search/'.$params->{search}, {'query' => $searchname})->then(sub {
        my $json = $_[0]->{results}[0];
        $json or die "Failed to find item";
        $season // return $json;
        # find the season and then the episode if applicable
        my $showid = $json->{id} // die "showid not available";
        _TMDB_api_promise($request->{client}{server}, "tv/$showid/season/$season")->then(sub {
            if ($metadatatype eq 'plot' || ! -f $b_plotfile) {
                make_path($b_metadir);
                my $bytes = encode_json($_[0]);
                try { write_file($b_plotfile, $bytes) }
                catch ($e) { say "wierd, creating file failed?"; }
            }
            $episode // return $_[0];
            MHFS::Kodi::Season::_get_season_episode($_[0], $episode)
        })
    })->then(sub {
        # get the metadata
        if (! defined $season && ($metadatatype eq 'plot' || ! -f "$b_metadir/plot.txt")) {
            make_path($b_metadir);
            try { write_text_file_lossy("$b_metadir/plot.txt", $_[0]->{overview}) }
            catch ($e) { say "wierd, creating file failed?"; }
        }
        if($metadatatype eq 'plot') {
            $request->SendText('text/plain; charset=utf-8', $_[0]->{overview});
            return;
        }
        # thumb or fanart
        my $imagepartial = ($metadatatype eq 'thumb') ? (! defined $episode ? $_[0]->{poster_path} : $_[0]->{still_path}) : $_[0]->{backdrop_path};
        if (!$imagepartial || $imagepartial !~ /(\.[^\.]+)$/) {
            die 'path not matched '.$imagepartial;
        }
        my $ext = $1;
        make_path($b_metadir);
        return MHFS::Promise->new($request->{client}{server}{evp}, sub {
            my ($resolve, $reject) = @_;
            if(! defined $self->{tmdbconfig}) {
                $resolve->(_TMDB_api_promise($request->{client}{server}, 'configuration')->then( sub {
                    $self->{tmdbconfig} = $_[0];
                    return $_[0];
                }));
            } else {
                $resolve->();
            }
        })->then( sub {
            return _DownloadFile_promise($request->{client}{server}, $self->{tmdbconfig}{images}{secure_base_url}.'original'.$imagepartial, "$b_metadir/$metadatatype$ext")->then(sub {
                $request->SendLocalFile("$b_metadir/$metadatatype$ext");
                return;
            });
        });
    })->then(undef, sub {
        print $_[0];
        $request->Send404;
        return;
    });
    return;
}

sub new {
    my ($class, $settings) = @_;
    my $self =  {};
    bless $self, $class;

    my @subsystems = ('video');
    $self->{moviemeta} = $settings->{'DATADIR'}.'/movies';
    $self->{tvmeta} = $settings->{'DATADIR'}.'/tv';
    make_path($self->{moviemeta}, $self->{tvmeta});

    $self->{'routes'} = [
        DirectoryRoute('/kodi/movies', sub {
            my ($request) = @_;
            route_movies($self, $request, $settings->{'MEDIASOURCES'}{'movies'}, '/kodi/movies');
        }),
        DirectoryRoute('/kodi/tv', sub {
            my ($request) = @_;
            route_tv($self, $request, $settings->{'MEDIASOURCES'}{'tv'}, '/kodi/tv');
        }),
        ['/kodi/metadata/*', sub {
            my ($request) = @_;
            route_metadata($self, $request);
        }],
        DirectoryRoute('/kodi', sub {
            my ($request) = @_;
            route_kodi($self, $request, '/kodi');
        }),
    ];

    return $self;
}


1;
