package App::instopt;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-25'; # DATE
our $DIST = 'App-instopt'; # DIST
our $VERSION = '0.020'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use App::swcat ();
use File::chdir;
use File::MoreUtil qw(dir_has_non_dot_files);
use Perinci::Object;
use PerlX::Maybe;
use Sah::Schema::software::arch;

our %Config;
our %SPEC;

our @all_known_archs = @{ $Sah::Schema::software::arch::schema->[1]{in} };

our %args_common = (
    download_dir => {
        schema => 'dirname*',
        tags => ['common'],
    },
    install_dir => {
        schema => 'dirname*',
        tags => ['common'],
    },
    program_dir => {
        schema => 'dirname*',
        tags => ['common'],
    },
);

our %argopt_arch = (
    arch => {
        schema => ['software::arch*'],
    },
);

our %argopt_detail = (
    detail => {
        schema => ['true*'],
        cmdline_aliases => {l=>{}},
    },
);

our %argopt_download = (
    download => {
        summary => 'Whether to download latest version from URL'.
            'or just find from download dir',
        'summary.alt.bool.not' => 'Do not download latest version from URL, '.
            'just find from download dir',
        schema => 'bool*',
        default => 1,
        cmdline_aliases => {
            D => {is_flag=>1, summary => 'Shortcut for --no-download', code=>sub {$_[0]{download} = 0}},
        },
    },
);

our %argopt_quiet = (
    quiet => {
        schema => 'bool*',
        cmdline_aliases => {q=>{}},
    },
);

sub _set_args_default {
    require Software::Catalog::Util;

    my ($args, $opts) = @_;

    if ($opts->{set_default_arch}) {
        if (!$args->{arch}) {
            $args->{arch} = Software::Catalog::Util::detect_arch();
        }
    }
    if (!$args->{download_dir}) {
        require PERLANCAR::File::HomeDir;
        $args->{download_dir} = PERLANCAR::File::HomeDir::get_my_home_dir() .
            '/software';
    }
    if (!$args->{install_dir}) {
        $args->{install_dir} = "/opt";
    }
    if (!$args->{program_dir}) {
        $args->{program_dir} = "/usr/local/bin";
    }
}

my $_ua;
sub _ua {
    unless ($_ua) {
        require LWP::UserAgent;
        $_ua = LWP::UserAgent->new;
    }
    $_ua;
}

# try to resolve redirect
sub _real_url {
    require HTTP::Request;

    my $url = shift;

    my $ua = _ua();
    while (1) {
        my $res = $ua->simple_request(HTTP::Request->new(HEAD => $url));
        if ($res->code =~ /^3/) {
            if ($res->header("Location")) {
                $url = $res->header("Location");
                next;
            } else {
                die "URL '$url' redirects without Location";
            }
        } elsif ($res->code !~ /^2/) {
            warn "Can't HEAD URL '$url': ".$res->code." - ".$res->message;
            # give up
            return undef;
        } else {
            return $url;
        }
    }
}

sub _convert_download_urls_to_filenames {
    require URI::Escape;

    my %args = @_;
    my $res = $args{res};

    my @urls = ref($res->[2]) eq 'ARRAY' ? @{$res->[2]} : ($res->[2]);
    my @metanames = $res->[3]{'func.filename'} ?
        (ref($res->[3]{'func.filename'}) eq 'ARRAY' ? @{ $res->[3]{'func.filename'} } : ($res->[3]{'func.filename'})) : ();

    my @filenames;
    for my $i (0..$#urls) {
        my $filename;
        if ($#metanames >= $i) {
            $filename = $metanames[$i];
        } elsif (my $rurl = _real_url($urls[$i])) {
            ($filename = $rurl) =~ s!.+/!!;
            $filename = URI::Escape::uri_unescape($filename);
        } else {
            $filename = "$args{software}-$args{version}";
        }

        # strip query string
        $filename =~ s/(?=.)\?.+//;

        push @filenames, $filename;
    }
    @filenames;
}

sub _init {
    my ($args, $opts) = @_;

    $opts //= {};
    $opts->{set_default_arch} //= 1;

    unless ($App::instopt::state) {
        _set_args_default($args, $opts);
        my $state = {
        };
        $App::instopt::state = $state;
    }
    $App::instopt::state;
}

# if $dir has a single entry inside it, which is another dir ($wrapper), move
# the content of entries inside $wrapper to inside $dir directly.
sub _unwrap {
    my $dir = shift;

    opendir my $dh, $dir or die "Can't read dir '$dir': $!";
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;

    return unless @entries == 1 && (-d "$dir/$entries[0]");

    my $rand = sprintf("%08d", rand()*100_000_000);
    rename "$dir/$entries[0]", "$dir/$entries[0].$rand";

    opendir my $dh2, "$dir/$entries[0].$rand" or die "Can't read dir '$dir/$entries[0].$rand': $!";
    my @subentries = grep { $_ ne '.' && $_ ne '..' } readdir $dh2;
    closedir $dh2;

    for (@subentries) {
        rename "$dir/$entries[0].$rand/$_", "$dir/$_" or die "Can't move $dir/$entries[0].$rand/$_ to $dir/$_: $!";
    }
    rmdir "$dir/$entries[0].$rand" or die "Can't rmdir $dir/$entries[0].$rand: $!";
}

$SPEC{list} = {
    v => 1.1,
    summary => 'List software',
    args => {
        %args_common,
        %argopt_detail,
        installed => {
            summary => 'If true, will only list installed software',
            schema =>  'bool*',
            tags => ['category:filtering'],
        },
        latest_installed => {
            summary => 'If true, will only list software which have their latest version installed',
            schema =>  'bool*',
            tags => ['category:filtering'],
            description => <<'_',

If set to true, a software which is not installed, or installed but does not
have the latest version installed, will not be included.

If set to false, a software which is not installed, or does not have the latest
version installed, will be included.

_
        },
        downloaded => {
            summary => 'If true, will only list downloaded software',
            schema =>  'bool*',
            tags => ['category:filtering'],
        },
        latest_downloaded => {
            summary => 'If true, will only list software which have their latest version downloaded',
            schema =>  'bool*',
            tags => ['category:filtering'],
            description => <<'_',

If set to true, a software which is not downloaded, or downloaded but does not
have the latest version downloaded, will not be included.

If set to false, a software which has no downloaded versions, or does not have
the latest version downloaded, will be included.

_
        },
    },
    examples => [
        {
            summary => 'List software that are installed but out-of-date',
            argv => [qw/--installed --nolatest-installed/],
            test => 0,
            'x.dow.show_result' => 0,
        },
        {
            summary => 'List software that have been downloaded but out-of-date',
            argv => [qw/--downloaded --nolatest-downloaded/],
            test => 0,
            'x.dow.show_result' => 0,
        },
        {
            summary => 'List software that have their latest version downloaded but not installed',
            argv => [qw/--latest-downloaded --nolatest-installed/],
            test => 0,
            'x.dow.show_result' => 0,
        },
    ],
};
sub list {
    require File::Slurper;

    my %args = @_;
    my $state = _init(\%args);

    my $res = App::swcat::list();
    return [500, "Can't list known software: $res->[0] - $res->[1]"] if $res->[0] != 200;
    my $known = $res->[2];

    my $swlist;
    if ($args{_software}) {
        return [412, "Unknown software '$args{_software}'"] unless
            grep { $_ eq $args{_software} } @$known;
        $swlist = [$args{_software}];
    } else {
        $swlist = $known;
    }

    my %installed_active_versions;
    my %installed_versions;
  CHECK_INSTALLED:
    {
        local $CWD = $args{install_dir};
        log_trace "Listing installed software in $args{install_dir} ...";
        for my $e (glob "*") {
            if (-l $e) {
                unless (grep { $e eq $_ } @$swlist) {
                    log_trace "Skipping symlink $e: name not in software list";
                    next;
                }
                my $v = readlink($e);
                unless ($v =~ s/\A\Q$e\E-//) {
                    log_trace "Skipping symlink $e: does not point to software in software list";
                    next;
                }
                $installed_active_versions{$e} = $v;
            } elsif ((-d $e) && (-f "$e/instopt.version")) {
                unless (grep { $e eq $_ } @$swlist) {
                    log_trace "Skipping directory $e: name not in software list even though it has instopt.version file";
                    next;
                }
                chomp($installed_active_versions{$e} =
                          File::Slurper::read_text("$e/instopt.version"));
            } elsif (-d $e) {
                my ($n, $v) = $e =~ /(.+)-(.+)/ or do {
                    log_trace "Skipping directory $e: name does not contain dash (for NAME-VERSION)";
                    next;
                };
                unless (grep { $n eq $_ } @$swlist) {
                    log_trace "Skipping directory $e: name '$n' is not in software list";
                    next;
                }
                $installed_versions{$n} //= [];
                push @{ $installed_versions{$n} }, $v;
            }
        }
    } # CHECK_INSTALLED

    my %downloaded_latest_versions;
    my %downloaded_versions;
    my %downloaded_archs;
  CHECK_DOWNLOADED:
    {
        local $CWD = $args{download_dir};
      SW:
        for my $sw (@$swlist) {
            my $dir = sprintf "%s/%s", substr($sw, 0, 1), $sw;
            unless (-d $dir) {
                log_trace "Skipping software '$sw': directory '$CWD/$dir' doesn't exist";
                next SW;
            }
            local $CWD = $dir;
            my $mod = App::swcat::_load_swcat_mod($sw);
            my %arch_vers; # key = arch, val = [ver1, ...]
            my @archs = defined($args{arch}) ? ($args{arch}) : @all_known_archs;
          VER:
            for my $e (glob "*") {
                unless ($mod->is_valid_version($e)) {
                    log_trace "Skipping invalid version '$e' of software '$sw'";
                    next;
                }
                for my $arch (@archs) {
                    #log_trace "Searching software '$sw' version '$e' arch '$arch'";
                    unless (dir_has_non_dot_files("$e/$arch")) {
                        #log_trace "Skipping software '$sw' version '$e' arch '$arch': no files found";
                        next;
                    }
                    push @{ $arch_vers{$arch} }, $e;
                }
            }

            my @vers;
            for my $arch (@archs) {
                next unless $arch_vers{$arch};
                log_trace "Found downloaded versions %s for software '%s' arch '$arch'",
                    $arch_vers{$arch}, $sw, $arch;
                for my $ver (@{ $arch_vers{$arch} }) {
                    push @vers, $ver unless grep { $ver eq $_ } @vers;
                }
            }
            @vers = sort { $mod->cmp_version($a, $b) } @vers;
            unless (@vers) {
                log_trace "Skipping software '$sw': no downloaded versions found";
                next;
            }
            $downloaded_latest_versions{$sw} = $vers[-1];
            $downloaded_versions{$sw} = \%arch_vers;
            };
        } # CHECK_DOWNLOADED

    my @all_rows;
    for my $sw (@$swlist) {
        push @all_rows, {
            software => $sw,
            (arch => $args{arch}) x !!defined($args{arch}),
            downloaded_versions => $downloaded_versions{$sw},
            downloaded_latest_version => $downloaded_latest_versions{$sw},
            installed_versions => $installed_versions{$sw},
            installed_active_version => $installed_active_versions{$sw},
            installed_inactive_versions => join(", ", grep { !defined($installed_active_versions{$sw}) || $_ ne $installed_active_versions{$sw} } @{ $installed_versions{$sw} }),
        };
    }

    my @rows;
  FILTER:
    for my $row (@all_rows) {
        my $latest_v;
        if (defined $args{installed}) {
            next FILTER if (defined $row->{installed_active_version}) xor $args{installed};
        }
        if (defined $args{downloaded}) {
            next FILTER if (defined $row->{downloaded_latest_version}) xor $args{downloaded};
        }
        if (defined $args{latest_installed} || defined $args{latest_downloaded} || $args{_check_latest_version}) {
            my $res = App::swcat::latest_version(%args, softwares_or_patterns=>[$row->{software}]);
            my $latest_v;
            if ($res->[0] == 200) {
                $latest_v = $res->[2];
                $row->{latest_version} = $latest_v;
            } else {
                log_error "Can't check latest version of $row->{software}: $res->[0] - $res->[1], skipping software";
                next FILTER;
            }
            if (defined $args{latest_installed}) {
                my $latest_installed = defined $row->{installed_active_version} && $row->{installed_active_version} eq $latest_v;
                next FILTER if $args{latest_installed} xor $latest_installed;
            }
            if (defined $args{latest_downloaded}) {
                my $latest_downloaded = defined $row->{downloaded_latest_version} && $row->{downloaded_latest_version} eq $latest_v;
                next FILTER if $args{latest_downloaded} xor $latest_downloaded;
            }
        }
        push @rows, $row;
    } # FILTER

    my $resmeta = {};
    if ($args{detail}) {
        $resmeta->{'table.fields'} = [qw/software downloaded_versions installed_versions installed_active_versions installed_inactive_versions/];
    } else {
        @rows = map { $_->{software} } @rows;
    }

    [200, "OK", \@rows, $resmeta];
}

$SPEC{list_installed} = {
    v => 1.1,
    summary => 'List all installed software',
    args => {
        %args_common,
        %argopt_detail,
    },
};
sub list_installed {
    my %args = @_;
    list(%args, installed=>1);
}

$SPEC{list_installed_versions} = {
    v => 1.1,
    summary => 'List all installed versions of a software',
    args => {
        %args_common,
        %App::swcat::arg0_software,
    },
};
sub list_installed_versions {
    my %args = @_;
    my $state = _init(\%args);

    return [400, "Please specify software"] unless $args{software};

    my $res = list(%args, installed=>1, _software=>$args{software}, detail=>1);
    return $res unless $res->[0] == 200;
    return [200, "OK (none installed)"] unless @{ $res->[2] };
    return [200, "OK", $res->[2][0]{installed_versions}];
}

$SPEC{is_installed_any} = {
    v => 1.1,
    summary => 'Check if any version of a software is installed',
    description => <<'_',

The installed version does not need to be the latest. To check whether the
latest version of a software is installed, use `is-installed-latest`.

_
    args => {
        %args_common,
        %App::swcat::arg0_software,
        %argopt_quiet,
    },
};
sub is_installed_any {
    my %args = @_;
    my $res = list(%args, _software=>$args{software}, installed=>1);
    return $res unless $res->[0] == 200;
    my $is_installed = @{ $res->[2] } ? 1:0;
    [200, "OK", $is_installed, {
        'cmdline.result' => $args{quiet} ? "" : "$args{software} is ".($is_installed ? "":"NOT ")."installed",
        'cmdline.exit_code' => $is_installed ? 0:1,
     }];
}

$SPEC{is_installed_latest} = {
    v => 1.1,
    summary => 'Check if latest version of a software is installed',
    description => <<'_',

To only check whether any version of a software is installed, use
`is-installed-any`.

_
    args => {
        %args_common,
        %App::swcat::arg0_software,
        %argopt_quiet,
    },
};
sub is_installed_latest {
    my %args = @_;
    my $res = list(%args, _software=>$args{software}, latest_installed=>1);
    return $res unless $res->[0] == 200;
    my $is_installed = @{ $res->[2] } ? 1:0;
    [200, "OK", $is_installed, {
        'cmdline.result' => $args{quiet} ? "" : "Latest version of $args{software} is ".($is_installed ? "":"NOT ")."installed",
        'cmdline.exit_code' => $is_installed ? 0:1,
     }];
}

$SPEC{list_downloaded} = {
    v => 1.1,
    summary => 'List all downloaded software',
    args => {
        %args_common,
        %argopt_arch,
        %argopt_detail,
    },
};
sub list_downloaded {
    my %args = @_;
    list(%args, downloaded=>1);
}

$SPEC{is_downloaded_any} = {
    v => 1.1,
    summary => 'Check if any version of a software is downloaded',
    description => <<'_',

The download does not need to be the latest version. To check if the latest
version of a software is downloaded, use `is-downloaded-latest`.

_
    args => {
        %args_common,
        %App::swcat::arg0_software,
        %argopt_quiet,
    },
};
sub is_downloaded_any {
    my %args = @_;
    my $res = list(%args, _software=>$args{software}, downloaded=>1);
    return $res unless $res->[0] == 200;
    my $is_downloaded = @{ $res->[2] } ? 1:0;
    [200, "OK", $is_downloaded, {
        'cmdline.result' => $args{quiet} ? "" : "$args{software} is ".($is_downloaded ? "":"NOT ")."downloaded",
        'cmdline.exit_code' => $is_downloaded ? 0:1,
     }];
}

$SPEC{is_downloaded_latest} = {
    v => 1.1,
    summary => 'Check if latest version of a software has been downloaded',
    description => <<'_',

To only check whether any version of a software has been downloaded, use
`is-downloaded-any`.

_
    args => {
        %args_common,
        %App::swcat::arg0_software,
        %argopt_quiet,
    },
};
sub is_downloaded_latest {
    my %args = @_;
    my $res = list(%args, _software=>$args{software}, latest_downloaded=>1);
    return $res unless $res->[0] == 200;
    my $is_downloaded = @{ $res->[2] } ? 1:0;
    [200, "OK", $is_downloaded, {
        'cmdline.result' => $args{quiet} ? "" : "Latest version of $args{software} is ".($is_downloaded ? "":"NOT ")."downloaded",
        'cmdline.exit_code' => $is_downloaded ? 0:1,
     }];
}

$SPEC{list_downloaded_versions} = {
    v => 1.1,
    summary => 'List all downloaded versions of a software',
    args => {
        %args_common,
        %App::swcat::arg0_software,
        %argopt_arch,
    },
};
sub list_downloaded_versions {
    my %args = @_;
    my $state = _init(\%args);

    return [400, "Please specify software"] unless $args{software};

    my $res = list(%args, downloaded=>1, _software=>$args{software}, arch=>$args{arch}, detail=>1);
    return $res unless $res->[0] == 200;
    return [200, "OK (none downloaded)"] unless @{ $res->[2] };
    return [200, "OK", $res->[2][0]{downloaded_versions}];
}

$SPEC{compare_versions} = {
    v => 1.1,
    summary => 'Compare installed vs downloaded vs latest versions '.
        'of installed software',
    args => {
        %args_common,
    },
};
sub compare_versions {
    my %args = @_;
    my $state = _init(\%args);

    my $res;

    $res = list(%args, installed=>1, detail=>1, _check_latest_version=>1);
    return $res unless $res->[0] == 200;

    for my $row (@{ $res->[2] }) {
        my $mod = App::swcat::_load_swcat_mod($row->{software});
        $row->{status} = '';
        my $cmp = $mod->cmp_version($row->{installed_active_version}, $row->{latest_version});
        if ($cmp >= 0) {
            $row->{status} = 'up to date';
        } else {
            $row->{status} = "updatable to $row->{latest_version}";
        }
        # to keep table rendering simple in CLI
        delete $row->{downloaded_versions};
        delete $row->{installed_versions};
        delete $row->{installed_inactive_versions};
    }
    $res;
}

$SPEC{download} = {
    v => 1.1,
    summary => 'Download latest version of one or more software',
    args => {
        %args_common,
        %App::swcat::arg0_softwares_or_patterns,
        %argopt_arch,
    },
};
sub download {
    require File::Path;

    my %args = @_;
    my $state = _init(\%args);

    my ($sws, $is_single_software) =
        App::swcat::_get_arg_softwares_or_patterns(\%args);

    my $envres = envresmulti();
    my ($v, @files);
  SW:
    for my $sw (@$sws) {
        my $mod = App::swcat::_load_swcat_mod($sw);
        my $res;

        $res = list_downloaded_versions(%args, software=>$sw);
        my $v0 = $res->[2] ? $res->[2]{ $args{arch} }[-1] : undef;

        $res = App::swcat::latest_version(%args, softwares_or_patterns=>[$sw]);
        unless ($res->[0] == 200) {
            $envres->add_result($res->[0], "Can't get latest version: $res->[1]", {item_id=>$sw});
            next SW;
        }
        $v = $res->[2];
        log_trace "v=%s", $v;
        if (defined $v0 && $mod->cmp_version($v0, $v) >= 0) {
            log_trace "Skipped downloading software '$sw': downloaded version ($v0) is already latest ($v)";
            $envres->add_result(304, "OK (installed version same/newer version)", {item_id=>$sw});
            next SW;
        }

        my (@urls, @filenames, $got_arch);
      GET_DOWNLOAD_URL:
        {
            my $dlurlres = $mod->download_url(
                arch => $args{arch},
            );
            unless ($dlurlres->[0] == 200) {
                $envres->add_result($dlurlres->[0], "Can't get download URL: $dlurlres->[1]", {item_id=>$sw});
                next SW;
            }
            @urls = ref($dlurlres->[2]) eq 'ARRAY' ? @{$dlurlres->[2]} : ($dlurlres->[2]);
            @filenames = _convert_download_urls_to_filenames(
                res => $dlurlres, software => $sw, version => $v);
            $got_arch = $dlurlres->[3]{'func.arch'} // $args{arch};
        }

        my $target_dir = join(
            "",
            $args{download_dir},
            "/", substr($sw, 0, 1),
            "/", $sw,
            "/", $v,
            "/", $got_arch,
        );
        File::Path::make_path($target_dir);

        my $ua = _ua();
        @files = ();
        for my $i (0..$#urls) {
            my $url = $urls[$i];
            my $filename = $filenames[$i];
            my $target_path = "$target_dir/$filename";
            push @files, $target_path;
            log_info "Downloading %s to %s ...", $url, $target_path;
            my $lwpres = $ua->mirror($url, $target_path);
            #log_trace "lwpres=%s", $lwpres;
            unless ($lwpres->is_success || $lwpres->code =~ /^304/) {
                my $errmsg = "Can't download $url to $target_path: ".$lwpres->code." - ".$lwpres->message;
                log_error $errmsg;
                $envres->add_result(500, $errmsg, {item_id=>$sw});
            }
        }
        $envres->add_result(200, "OK", {item_id=>$sw});
    } # SW

    my $res = $envres->as_struct;
    if ($is_single_software) {
        $res->[3] = {
            'func.version' => $v,
            'func.files' => \@files,
        };
    }
    $res;
}

$SPEC{download_all} = {
    v => 1.1,
    summary => 'Download latest version of all known software',
    args => {
        %args_common,
        %argopt_arch,
    },
};
sub download_all {
    my %args = @_;
    my $state = _init(\%args);

    my $res = App::swcat::list();
    return [500, "Can't list known software: $res->[0] - $res->[1]"] if $res->[0] != 200;
    my $known = $res->[2];

    download(%args, softwares_or_patterns => $known);
}

$SPEC{cleanup_install_dir} = {
    v => 1.1,
    summary => 'Remove inactive versions of installed software',
    args => {
        %args_common,
    },
    features => { dry_run=>1 },
};
sub cleanup_install_dir {
    require File::Path;

    my %args = @_;
    my $state = _init(\%args);

    local $CWD = $args{install_dir};
    my $res = list_installed(%args, detail=>1);
    return $res unless $res->[0] == 200;
    for my $row (@{ $res->[2] }) {
        my $sw = $row->{software};
        log_trace "Skipping software $sw because there is no active version"
            unless defined $row->{installed_active_version};
        next unless defined $row->{installed_inactive_versions};
        #log_trace "Cleaning up software $sw ...";
        for my $v (split /, /, $row->{installed_inactive_versions}) {
            my $dir = "$sw-$v";
            unless (-d $dir) {
                log_trace "Skipping version $v of software $sw (directory does not exist)";
                next;
            }
            if ($args{-dry_run}) {
                log_info "[DRY-RUN] Removing $dir ...";
            } else {
                log_info "Removing $dir ...";
                File::Path::remove_tree($dir);
            }
        }
    }
    $args{-dry_run} ? [304, "Dry-run"] : [200];
}

$SPEC{cleanup_download_dir} = {
    v => 1.1,
    summary => 'Remove older versions of downloaded software',
    args => {
        %args_common,
    },
    features => { dry_run=>1 },
};
sub cleanup_download_dir {
    require File::Path;

    my %args = @_;
    my $state = _init(\%args, {set_default_arch=>0});

    local $CWD = $args{download_dir};
    my $res = list_downloaded(%args, detail=>1);
    return $res unless $res->[0] == 200;
  SW:
    for my $row (@{ $res->[2] }) {
        my $sw = $row->{software};
        for my $arch (sort keys %{ $row->{downloaded_versions} }) {
            my @vers = @{ $row->{downloaded_versions}{$arch} };
            unless (@vers > 1) {
                log_trace "Skipping software '$sw' arch '$arch' (<2 versions)";
                next SW;
            }
            pop @vers; # remove latest version
            my $dir = sprintf "%s/%s", substr($sw, 0, 1), $sw;
            local $CWD = $dir;
          VER:
            for my $v (@vers) {
                if ($args{-dry_run}) {
                    log_info "[DRY-RUN] Cleaning up $sw-$v arch $arch ...";
                } else {
                    log_info "Cleaning up software $sw-$v arch $arch ...";
                    File::Path::remove_tree("$v/$arch");
                }
            }
        } # for arch
    }
    $args{-dry_run} ? [304, "Dry-run"] : [200];
}

$SPEC{update} = {
    v => 1.1,
    summary => 'Update a software to the latest version',
    args => {
        %args_common,
        %App::swcat::arg0_softwares_or_patterns,
        %argopt_download,
    },
};
sub update {
    require Archive::Any;
    require File::MoreUtil;
    require File::Path;
    require Filename::Archive;
    require Filename::Executable;
    require IPC::System::Options;

    my %args = @_;
    my $state = _init(\%args);

    my ($sws, $is_single_software) =
        App::swcat::_get_arg_softwares_or_patterns(\%args);

    my $envres = envresmulti();
  SW:
    for my $sw (@$sws) {
        my $mod = App::swcat::_load_swcat_mod($sw);
        my $res = list_installed_versions(%args, software=>$sw);
        my $v0 = $res->[2] ? $res->[2][-1] : undef;

        my $v;
        my ($filepath, $filename);
      DOWNLOAD_OR_GET_DOWNLOADED: {
            if ($args{download}) {
              DOWNLOAD: {
                    my $dlres = download(%args, softwares_or_patterns=>[$sw]);
                    if ($dlres->[0] == 304) {
                        goto GET_DOWNLOADED;
                    }
                    unless ($dlres->[0] == 200) {
                        my $errmsg ="Can't download $sw: $dlres->[0] - $dlres->[1]";
                        log_error $errmsg;
                        $envres->add_result(500, $errmsg, {item_id=>$sw});
                        next SW;
                    }
                    $v = $dlres->[3]{'func.version'};
                    if (@{ $dlres->[3]{'func.files'} } != 1) {
                        my $errmsg = "Can't install $sw: Currently cannot handle software that has multiple downloaded files";
                        log_error $errmsg;
                        $envres->add_result(412, $errmsg, {item_id=>$sw});
                        next SW;
                    }
                    $filepath = $filename = $dlres->[3]{'func.files'}[0];
                    $filename =~ s!.+/!!;
                }
                last DOWNLOAD_OR_GET_DOWNLOADED;
            }
          GET_DOWNLOADED: {
                my $res = list_downloaded_versions(%args, software=>$sw);
                $v = $res->[2] ? $res->[2]{ $args{arch} }[-1] : undef;
                if (!defined $v) {
                    my $errmsg = "Can't install $sw: No downloaded version available";
                    log_error $errmsg;
                    $envres->add_result(412, $errmsg, {item_id=>$sw});
                    next SW;
                }
                {
                    local $CWD = sprintf(
                        "%s/%s/%s/%s/%s",
                        $args{download_dir},
                        substr($sw, 0, 1),
                        $sw,
                        $v,
                        $args{arch});
                    my @filenames = glob "*";
                    if (!@filenames) {
                        my $errmsg ="Can't install $sw: There are no files in download dir $CWD";
                        log_error $errmsg;
                        $envres->add_result(412, $errmsg, {item_id=>$sw});
                        next SW;
                    } elsif (@filenames != 1) {
                        my $errmsg = "Can't install sw: Currently cannot handle software that has multiple downloaded files: ".join(", ", @filenames);
                        log_error $errmsg;
                        $envres->add_result(412, $errmsg, {item_id=>$sw});
                        next SW;
                    }
                    $filename = $filenames[0];
                    $filepath = "$CWD/$filename";
                }
            }
        } # DOWNLOAD_OR_GET_DOWNLOADED

        if (defined $v0 && $mod->cmp_version($v0, $v) >= 0) {
            log_trace "Skipped updating software '$sw': installed version ($v0) is already latest ($v)";
            $envres->add_result(304, "OK", {item_id=>$sw});
            next SW;
        }

        log_info "Updating software %s to version %s ...", $sw, $v;

        my $target_name = join(
            "",
            $sw, "-", $v,
        );
        my $target_dir = join(
            "",
            $args{install_dir},
            "/", $target_name,
        );

        my $fileformat;
      CHECK_SW_TYPE: {
            my $cafres = Filename::Archive::check_archive_filename(
                filename => $filename);
            if ($cafres) {
                log_trace "$filename is an archive";
                $fileformat = "archive";
                last;
            }
            my $cefres = Filename::Executable::check_executable_filename(
                filename => $filename);
            if ($cefres) {
                log_trace "$filename is an executable";
                $fileformat = "executable";
                last;
            }
            my $errmsg = "Can't install $sw: filename $filename is not an archive nor an executable, cannot handle";
            log_error $errmsg;
            $envres->add_result(412, $errmsg, {item_id=>$sw});
            next SW;
        }

        my $aires;
      EXTRACT_ARCHIVE: {
            last unless $fileformat eq 'archive';
            $aires = $mod->archive_info(%args, version => $v);
            unless ($aires->[0] == 200) {
                my $errmsg = "Can't install $sw: Can't get archive info: $aires->[0] - $aires->[1]";
                log_error $errmsg;
                $envres->add_result(500, $errmsg, {item_id=>$sw});
                next SW;
            }

            if (-d $target_dir) {
                log_debug "Target dir '$target_dir' already exists, skipping extract";
                last EXTRACT;
            }
            log_trace "Creating %s ...", $target_dir;
            File::Path::make_path($target_dir);

            log_trace "Extracting %s to %s ...", $filepath, $target_dir;
            my $ar = Archive::Any->new($filepath);
            $ar->extract($target_dir);

            _unwrap($target_dir) unless
                defined($aires->[2]{unwrap}) && !$aires->[2]{unwrap};
        } # EXTRACT_ARCHIVE

      MAKE_EXEC_DIR: {
            last unless $fileformat eq 'executable';
            if (-d $target_dir) {
                log_debug "Target dir '$target_dir' already exists, skipping mkdir";
                last MKDIR;
            }
            mkdir $target_dir, 0755 or do {
                $envres->add_result(500, "Can't install $sw: can't mkdir $target_dir: $!", {item_id=>$sw});
                next SW;
            };

            if ($mod->is_dedicated_profile) {
                require File::Copy;
                File::Copy::copy($filepath, "$target_dir/$filename") or do {
                    $envres->add_result(500, "Can't install $sw: can't copy $filepath -> $target_dir/$filename: $!", {item_id=>$sw});
                    next SW;
                };
            } else {
                log_trace "Symlink $filepath -> $target_dir/$filename ...";
                symlink $filepath, "$target_dir/$filename" or do {
                    $envres->add_result(500, "Can't install $sw: can't symlink $filepath -> $target_dir/$filename: $!", {item_id=>$sw});
                    next SW;
                };
            }
        }

      SYMLINK_OR_HARDLINK_DIR: {
            log_trace "Creating/updating directory symlink/hardlink to latest version ...";
            local $CWD = $args{install_dir};
            if (File::MoreUtil::file_exists($sw)) {
                File::Path::remove_tree($sw);
            }
            my $use_symlink = !$mod->is_dedicated_profile;
            if ($use_symlink) {
                symlink $target_name, $sw or do {
                    $envres->add_result(500, "Can't install $sw: Can't symlink $sw -> $target_name: $!", {item_id=>$sw});
                    next SW;
                };
            } else {
                IPC::System::Options::system(
                    {log=>1, die=>1},
                    "cp", "-la", $target_name, $sw,
                );
                File::Slurper::write_text("$sw/instopt.version", $v);
            }
        }

      SYMLINK_ARCHIVE_PROGRAMS: {
            last unless $fileformat eq 'archive';
            local $CWD = $args{program_dir};
            log_trace "Creating/updating program symlinks ...";
            my $programs = $aires->[2]{programs} // [];
            for my $e (@$programs) {
                if ((-l $e->{name}) || !File::MoreUtil::file_exists($e->{name})) {
                    unlink $e->{name};
                    my $target = "$args{install_dir}/$sw$e->{path}/$e->{name}";
                    $target =~ s!//!/!g;
                    log_trace "Creating symlink $args{program_dir}/$e->{name} -> $target ...";
                    symlink $target, $e->{name} or do {
                        $envres->add_result(500, "Can't install $sw: Can't symlink $e->{name} -> $target: $!", {item_id=>$sw});
                        next SW;
                    };
                } else {
                    log_warn "%s/%s is not a symlink, skipping", $args{program_dir}, $e->{name};
                    next;
                }
            }
        }

      SYMLINK_EXEC_IN_PROGRAM_DIR: {
            last unless $fileformat eq 'executable';
            local $CWD = $args{program_dir};
            log_trace "Creating/updating program symlink ...";
            if ((-l $sw) || !File::MoreUtil::file_exists($sw)) {
                unlink $sw;
                my $target = "$args{install_dir}/$sw/$filename";
                $target =~ s!//!/!g;
                log_trace "Creating symlink $args{program_dir}/$sw -> $target ...";
                symlink $target, $sw or do {
                    $envres->add_result(500, "Can't install $sw: Can't symlink $sw -> $target: $!", {item_id=>$sw});
                    next SW;
                };
            }
        }

        $envres->add_result(200, "OK", {item_id=>$sw});
    } # SW

    $envres->as_struct;
}

$SPEC{update_all} = {
    v => 1.1,
    summary => 'Update all installed software',
    args => {
        %args_common,
        %argopt_download,
    },
};
sub update_all {
    my %args = @_;
    my $state = _init(\%args);

    my $res = list_installed(%args);
    return $res unless $res->[0] == 200;

    update(%args, softwares_or_patterns=>$res->[2]);
}

1;
# ABSTRACT: Download and install software

__END__

=pod

=encoding UTF-8

=head1 NAME

App::instopt - Download and install software

=head1 VERSION

This document describes version 0.020 of App::instopt (from Perl distribution App-instopt), released on 2021-07-25.

=head1 SYNOPSIS

See L<instopt> script.

=head1 FUNCTIONS


=head2 cleanup_download_dir

Usage:

 cleanup_download_dir(%args) -> [$status_code, $reason, $payload, \%result_meta]

Remove older versions of downloaded software.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 cleanup_install_dir

Usage:

 cleanup_install_dir(%args) -> [$status_code, $reason, $payload, \%result_meta]

Remove inactive versions of installed software.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 compare_versions

Usage:

 compare_versions(%args) -> [$status_code, $reason, $payload, \%result_meta]

Compare installed vs downloaded vs latest versions of installed software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 download

Usage:

 download(%args) -> [$status_code, $reason, $payload, \%result_meta]

Download latest version of one or more software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arch> => I<software::arch>

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=item * B<softwares_or_patterns>* => I<array[str]>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 download_all

Usage:

 download_all(%args) -> [$status_code, $reason, $payload, \%result_meta]

Download latest version of all known software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arch> => I<software::arch>

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_downloaded_any

Usage:

 is_downloaded_any(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check if any version of a software is downloaded.

The download does not need to be the latest version. To check if the latest
version of a software is downloaded, use C<is-downloaded-latest>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=item * B<quiet> => I<bool>

=item * B<software>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_downloaded_latest

Usage:

 is_downloaded_latest(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check if latest version of a software has been downloaded.

To only check whether any version of a software has been downloaded, use
C<is-downloaded-any>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=item * B<quiet> => I<bool>

=item * B<software>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_installed_any

Usage:

 is_installed_any(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check if any version of a software is installed.

The installed version does not need to be the latest. To check whether the
latest version of a software is installed, use C<is-installed-latest>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=item * B<quiet> => I<bool>

=item * B<software>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_installed_latest

Usage:

 is_installed_latest(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check if latest version of a software is installed.

To only check whether any version of a software is installed, use
C<is-installed-any>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=item * B<quiet> => I<bool>

=item * B<software>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list

Usage:

 list(%args) -> [$status_code, $reason, $payload, \%result_meta]

List software.

Examples:

=over

=item * List software that are installed but out-of-date:

 list(installed => 1, latest_installed => 0);

Result:

 [
   500,
   "Function died: Failed to change directory to '/home/s1/software': No such file or directory at lib/App/instopt.pm line 331.\n",
   undef,
   {
     logs => [
       {
         file    => "/home/s1/perl5/perlbrew/perls/perl-5.30.2/lib/site_perl/5.30.2/Perinci/Access/Schemeless.pm",
         func    => "Perinci::Access::Schemeless::action_call",
         line    => 501,
         package => "Perinci::Access::Schemeless",
         time    => 1627177634,
         type    => "create",
       },
     ],
   },
 ]

=item * List software that have been downloaded but out-of-date:

 list(downloaded => 1, latest_downloaded => 0); # -> [200, "OK", [], {}]

=item * List software that have their latest version downloaded but not installed:

 list(latest_downloaded => 1, latest_installed => 0); # -> [200, "OK", [], {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

=item * B<download_dir> => I<dirname>

=item * B<downloaded> => I<bool>

If true, will only list downloaded software.

=item * B<install_dir> => I<dirname>

=item * B<installed> => I<bool>

If true, will only list installed software.

=item * B<latest_downloaded> => I<bool>

If true, will only list software which have their latest version downloaded.

If set to true, a software which is not downloaded, or downloaded but does not
have the latest version downloaded, will not be included.

If set to false, a software which has no downloaded versions, or does not have
the latest version downloaded, will be included.

=item * B<latest_installed> => I<bool>

If true, will only list software which have their latest version installed.

If set to true, a software which is not installed, or installed but does not
have the latest version installed, will not be included.

If set to false, a software which is not installed, or does not have the latest
version installed, will be included.

=item * B<program_dir> => I<dirname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_downloaded

Usage:

 list_downloaded(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all downloaded software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arch> => I<software::arch>

=item * B<detail> => I<true>

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_downloaded_versions

Usage:

 list_downloaded_versions(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all downloaded versions of a software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arch> => I<software::arch>

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=item * B<software>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_installed

Usage:

 list_installed(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all installed software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_installed_versions

Usage:

 list_installed_versions(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all installed versions of a software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=item * B<software>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 update

Usage:

 update(%args) -> [$status_code, $reason, $payload, \%result_meta]

Update a software to the latest version.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<download> => I<bool> (default: 1)

Whether to download latest version from URLor just find from download dir.

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=item * B<softwares_or_patterns>* => I<array[str]>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 update_all

Usage:

 update_all(%args) -> [$status_code, $reason, $payload, \%result_meta]

Update all installed software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<download> => I<bool> (default: 1)

Whether to download latest version from URLor just find from download dir.

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-instopt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-instopt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-instopt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTORS

=for stopwords James Raspass liana (on netbook-dell-xps13) perlancar pc-office)

=over 4

=item *

James Raspass <jraspass@gmail.com>

=item *

liana (on netbook-dell-xps13) <lianamelati88@gmail.com>

=item *

perlancar (on pc-office) <perlancar@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
