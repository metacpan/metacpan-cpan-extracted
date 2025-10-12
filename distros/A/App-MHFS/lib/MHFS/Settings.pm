package MHFS::Settings v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Scalar::Util qw(reftype);
use MIME::Base64 qw(encode_base64url);
use File::Basename;
use Digest::MD5 qw(md5);
use Storable qw(freeze);
use Cwd qw(abs_path);
use File::ShareDir qw(dist_dir);
use File::Path qw(make_path);
use File::Spec::Functions qw(rel2abs);
use MHFS::Util qw(write_text_file parse_ipv4);

sub write_settings_file {
    my ($SETTINGS, $filepath) = @_;
    my $indentcnst = 4;
    my $indentspace = '';
    my $settingscontents = "#!/usr/bin/perl\nuse strict; use warnings;\n\nmy \$SETTINGS = ";

    # we only encode SCALARS. Loop through expanding HASH and ARRAY refs into SCALARS
    my @values = ($SETTINGS);
    while(@values) {
        my $value = shift @values;
        my $type = reftype($value);
        say "value: $value type: " . ($type // 'undef');
        my $raw;
        my $noindent;
        if(! defined $type) {
            if(defined $value) {
                # process lead control code if provided
                $raw = ($value eq '__raw');
                $noindent = ($value eq '__noindent');
                if($raw || $noindent) {
                    $value = shift @values;
                }
            }

            if(! defined $value) {
                $raw = 1;
                $value = 'undef';
                $type = 'SCALAR';
            }
            elsif($value eq '__indent-') {
                substr($indentspace, -4, 4, '');
                # don't actually encode anything
                $value = '';
                $type = 'NOP';
            }
            else {
                $type = reftype($value) // 'SCALAR';
            }
        }

        say "v2: $value type $type";
        if($type eq 'NOP') {
            next;
        }

        $settingscontents .= $indentspace if(! $noindent);
        if($type eq 'SCALAR') {
            # encode the value
            if(! $raw) {
                $value =~ s/'/\\'/g;
                $value = "'".$value."'";
            }

            # add the value to the buffer
            $settingscontents .= $value;
            $settingscontents .= ",\n" if(! $raw);
        }
        elsif($type eq 'HASH') {
            $settingscontents .= "{\n";
            $indentspace .= (' ' x $indentcnst);
            my @toprepend;
            foreach my $key (keys %{$value}) {
                push @toprepend, '__raw', "'$key' => ", '__noindent', $value->{$key};
            }
            push @toprepend, '__indent-', '__raw', "},\n";
            unshift(@values, @toprepend);
        }
        elsif($type eq 'ARRAY') {
            $settingscontents .= "[\n";
            $indentspace .= (' ' x $indentcnst);
            my @toprepend = @{$value};
            push @toprepend, '__indent-', '__raw', "],\n";
            unshift(@values, @toprepend);
        }
        else {
            die("Unknown type: $type");
        }
    }
    chop $settingscontents;
    chop $settingscontents;
    $settingscontents .= ";\n\n\$SETTINGS;\n";
    say "making settings folder $filepath";
    make_path(dirname($filepath));
    write_text_file($filepath,  $settingscontents);
}

sub calc_source_id {
    my ($source) = @_;
    if($source->{'type'} ne 'local') {
        say "only local sources supported right now";
        return undef;
    }
    return encode_base64url(md5('local:'.$source->{folder}));
}

sub add_source {
    my ($sources, $source) = @_;
    my $id = calc_source_id($source);
    my $len = 6;
    my $shortid = substr($id, 0, $len);
    if (exists $sources->{$shortid}) {
        my $oldid = calc_source_id($sources->{$shortid});
        while(1) {
            $len++;
            substr($oldid, 0, $len) eq substr($id, 0, $len) or last;
            length($id) > $len or die "matching hash";
        }
        $sources->{substr($oldid, 0, $len)} = $sources->{$shortid};
        delete $sources->{$shortid};
        $shortid = substr($id, 0, $len);
    }
    $sources->{$shortid} = $source;
    return $shortid;
}

sub load {
    my ($launchsettings) = @_;
    my $scriptpath = abs_path(__FILE__);

    # settings are loaded with the following precedence
    # $launchsettings (@ARGV) > settings.pl > General environment vars
    # Directory preference goes from declared to defaults and specific to general:
    # For example $CFGDIR > $XDG_CONFIG_HOME > $XDG_CONFIG_DIRS > $FALLBACK_DATA_ROOT

    # load in the launchsettings
    my ($CFGDIR, $APPDIR, $FALLBACK_DATA_ROOT);
    if(exists $launchsettings->{CFGDIR}) {
        make_path($launchsettings->{CFGDIR});
        $CFGDIR = $launchsettings->{CFGDIR};
    }
    if(exists $launchsettings->{APPDIR}) {
        -d $launchsettings->{APPDIR} or die("Bad APPDIR provided");
        $APPDIR = $launchsettings->{APPDIR};
    }
    if(exists $launchsettings->{FALLBACK_DATA_ROOT}) {
        make_path($launchsettings->{FALLBACK_DATA_ROOT});
        $FALLBACK_DATA_ROOT = $launchsettings->{FALLBACK_DATA_ROOT};
    }

    # determine the settings dir
    if(! $CFGDIR){
        my $cfg_fallback = $FALLBACK_DATA_ROOT // $ENV{'HOME'};
        $cfg_fallback //= ($ENV{APPDATA}.'/mhfs') if($ENV{APPDATA}); # Windows
        # set the settings dir to the first that exists of $XDG_CONFIG_HOME and $XDG_CONFIG_DIRS
        # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
        my $XDG_CONFIG_HOME = $ENV{'XDG_CONFIG_HOME'};
        $XDG_CONFIG_HOME //= ($cfg_fallback . '/.config') if($cfg_fallback);
        my @configdirs;
        push @configdirs, $XDG_CONFIG_HOME if($XDG_CONFIG_HOME);
        my $XDG_CONFIG_DIRS = $ENV{'XDG_CONFIG_DIRS'} || '/etc/xdg';
        push @configdirs, split(':', $XDG_CONFIG_DIRS);
        foreach my $cfgdir (@configdirs) {
            if(-d "$cfgdir/mhfs") {
                $CFGDIR = "$cfgdir/mhfs";
                last;
            }
        }
        $CFGDIR //= ($XDG_CONFIG_HOME.'/mhfs') if($XDG_CONFIG_HOME);
        defined($CFGDIR) or die("Failed to find valid candidate for \$CFGDIR");
    }
    $CFGDIR = rel2abs($CFGDIR);

    # load from the settings file
    my $SETTINGS_FILE = rel2abs($CFGDIR . '/settings.pl');
    my $SETTINGS = do ($SETTINGS_FILE);
    if(! $SETTINGS) {
        die "Error parsing settingsfile: $@" if($@);
        die "Cannot read settingsfile: $!" if(-e $SETTINGS_FILE);
        warn("No settings file found, using default settings");
        $SETTINGS = {};
    }

    # load defaults for unset values
    $SETTINGS->{'HOST'} ||= "127.0.0.1";
    $SETTINGS->{'PORT'} ||= 8000;

    $SETTINGS->{'ALLOWED_REMOTEIP_HOSTS'} ||= [
        ['127.0.0.1'],
    ];

    # write the default settings
    if(! -f $SETTINGS_FILE) {
        write_settings_file($SETTINGS, $SETTINGS_FILE);
    }
    $SETTINGS->{'CFGDIR'} = $CFGDIR;
    $SETTINGS->{flush} = $launchsettings->{flush} if(exists $launchsettings->{flush});

    # locate files based on appdir
    $APPDIR ||= $SETTINGS->{'APPDIR'} || dist_dir('App-MHFS');
    $APPDIR = abs_path($APPDIR);
    say __PACKAGE__.": using APPDIR " . $APPDIR;
    $SETTINGS->{'APPDIR'} = $APPDIR;

    # determine the fallback data root
    $FALLBACK_DATA_ROOT ||= $SETTINGS->{'FALLBACK_DATA_ROOT'} || $ENV{'HOME'};
    $FALLBACK_DATA_ROOT ||= ($ENV{APPDATA}.'/mhfs') if($ENV{APPDATA}); # Windows
    if($FALLBACK_DATA_ROOT) {
        $FALLBACK_DATA_ROOT = abs_path($FALLBACK_DATA_ROOT);
    }
    # determine the allowed remoteip host combos. only ipv4 now sorry
    $SETTINGS->{'ARIPHOSTS_PARSED'} = [];
    foreach my $rule (@{$SETTINGS->{'ALLOWED_REMOTEIP_HOSTS'}}) {
        # parse IPv4 with optional CIDR
        $rule->[0] =~ /^([^\/]+)(?:\/(\d{1,2}))?$/ or die("Invalid rule: " . $rule->[0]);
        my $ipstr = $1; my $cidr = $2 // 32;
        my $ip = parse_ipv4($ipstr);
        $cidr >= 0 && $cidr <= 32  or die("Invalid rule: " . $rule->[0]);
        my $mask = (0xFFFFFFFF << (32-$cidr)) & 0xFFFFFFFF;
        my %ariphost = (
            'ip' => $ip,
            'subnetmask' => $mask
        );
        # store the server hostname if verification is required for this rule
        $ariphost{'hostname'} = $rule->[1] if($rule->[1]);
        # store overriding absurl from this host if provided
        if($rule->[2]) {
            my $absurl = $rule->[2];
            chop $absurl if(index($absurl, '/', length($absurl)-1) != -1);
            $ariphost{'absurl'} = $absurl;
        }
        # store whether to trust connections with this host
        if($rule->[3]) {
            $ariphost{'X-MHFS-PROXY-KEY'} = $rule->[3];
        }
        push @{ $SETTINGS->{'ARIPHOSTS_PARSED'}}, \%ariphost;
    }

    if( ! $SETTINGS->{'DOCUMENTROOT'}) {
        $SETTINGS->{'DOCUMENTROOT'} = "$APPDIR/public_html";
    }
    $SETTINGS->{'XSEND'} //= 0;
    my $tmpdir = $SETTINGS->{'TMPDIR'};
    $tmpdir ||= ($ENV{'XDG_CACHE_HOME'}.'/mhfs') if($ENV{'XDG_CACHE_HOME'});
    $tmpdir ||= "$FALLBACK_DATA_ROOT/.cache/mhfs" if($FALLBACK_DATA_ROOT);
    defined($tmpdir) or die("Failed to find valid candidate for \$tmpdir");
    delete $SETTINGS->{'TMPDIR'}; # Use specific temp dir instead
    if(!$SETTINGS->{'RUNTIME_DIR'} ) {
        my $RUNTIMEDIR = $ENV{'XDG_RUNTIME_DIR'};
        if(! $RUNTIMEDIR ) {
            $RUNTIMEDIR = $tmpdir;
            warn("XDG_RUNTIME_DIR not defined!, using $RUNTIMEDIR instead");
        }
        $SETTINGS->{'RUNTIME_DIR'} = $RUNTIMEDIR.'/mhfs';
    }
    my $datadir = $SETTINGS->{'DATADIR'};
    $datadir ||= ($ENV{'XDG_DATA_HOME'}.'/mhfs') if($ENV{'XDG_DATA_HOME'});
    $datadir ||= "$FALLBACK_DATA_ROOT/.local/share/mhfs" if($FALLBACK_DATA_ROOT);
    defined($datadir) or die("Failed to find valid candidate for \$datadir");
    $SETTINGS->{'DATADIR'} = $datadir;
    $SETTINGS->{'MHFS_TRACKER_TORRENT_DIR'} ||= $SETTINGS->{'DATADIR'}.'/torrent';
    $SETTINGS->{'VIDEO_TMPDIR'} ||= $tmpdir.'/video';
    $SETTINGS->{'MUSIC_TMPDIR'} ||= $tmpdir.'/music';
    $SETTINGS->{'GENERIC_TMPDIR'} ||= $tmpdir.'/tmp';
    $SETTINGS->{'SECRET_TMPDIR'} ||= $tmpdir.'/secret';
    $SETTINGS->{'MEDIALIBRARIES'}{'movies'} ||= $SETTINGS->{'DOCUMENTROOT'} . "/media/movies",
    $SETTINGS->{'MEDIALIBRARIES'}{'tv'} ||= $SETTINGS->{'DOCUMENTROOT'} . "/media/tv",
    $SETTINGS->{'MEDIALIBRARIES'}{'music'} ||= $SETTINGS->{'DOCUMENTROOT'} . "/media/music",
    my %sources;
    my %mediasources;
    foreach my $lib ('movies', 'tv', 'music') {
        my $srcs = $SETTINGS->{'MEDIALIBRARIES'}{$lib};
        if(ref($srcs) ne 'ARRAY') {
            $srcs = [$srcs];
        }
        my @subsrcs;
        foreach my $source (@$srcs) {
            my $stype = ref($source);
            my $tohash = $source;
            if($stype ne 'HASH') {
                if($stype ne '') {
                    say __PACKAGE__.": skipping source";
                    next;
                }
                $tohash = {type => 'local',  folder => $source};
            }
            if ($tohash->{type} eq 'local') {
                my $absfolder = abs_path($tohash->{folder});
                $absfolder // do {
                    say __PACKAGE__.": skipping source $tohash->{folder} - abs_path failed";
                    next;
                };
                $tohash->{folder} = $absfolder;
            }
            my $sid = add_source(\%sources, $tohash);
            push @subsrcs, $sid;
        }
        $mediasources{$lib} = \@subsrcs;
    }
    $SETTINGS->{'MEDIASOURCES'} = \%mediasources;

    my $videotmpdirsrc = {type => 'local',  folder => $SETTINGS->{'VIDEO_TMPDIR'}};
    my $vtempsrcid = add_source(\%sources, $videotmpdirsrc);
    $SETTINGS->{'VIDEO_TMPDIR_QS'} = 'sid='.$vtempsrcid;
    $SETTINGS->{'SOURCES'} = \%sources;

    $SETTINGS->{'BINDIR'} ||= $APPDIR . '/bin';
    $SETTINGS->{'DOCDIR'} ||= $APPDIR . '/doc';

    # specify timeouts in seconds
    $SETTINGS->{'TIMEOUT'} ||= 75;
    # time to recieve the requestline and headers before closing the conn
    $SETTINGS->{'recvrequestimeout'} ||= 10;
    # maximum time allowed between sends
    $SETTINGS->{'sendresponsetimeout'} ||= $SETTINGS->{'TIMEOUT'};

    $SETTINGS->{'Torrent'}{'pyroscope'} ||= $FALLBACK_DATA_ROOT .'/.local/pyroscope' if($FALLBACK_DATA_ROOT);

    return $SETTINGS;
}

1;
