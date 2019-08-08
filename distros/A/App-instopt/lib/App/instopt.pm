package App::instopt;

our $DATE = '2019-08-07'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use App::swcat ();
use File::chdir;
use File::MoreUtil qw(dir_has_non_dot_files);
use Perinci::Object;
use PerlX::Maybe;

use vars '%Config';
our %SPEC;

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
        schema => 'bool*',
        default => 1,
        cmdline_aliases => {
            D => {is_flag=>1, summary => 'Shortcut for --no-download', code=>sub {$_[0]{download} = 0}},
        },
    },
);

sub _set_args_default {
    my $args = shift;
    if (!$args->{arch}) {
        $args->{arch} = App::swcat::_detect_arch();
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
    my ($args) = @_;

    unless ($App::instopt::state) {
        _set_args_default($args);
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

    my %active_versions;
    my %all_versions;
    {
        local $CWD = $args{install_dir};
        for my $e (glob "*") {
            if (-l $e) {
                next unless grep { $e eq $_ } @$swlist;
                my $v = readlink($e);
                next unless $v =~ s/\A\Q$e\E-//;
                $active_versions{$e} = $v;
            } elsif (-d $e) {
                my ($n, $v) = $e =~ /(.+)-(.+)/ or next;
                next unless grep { $n eq $_ } @$swlist;
                $all_versions{$n} //= [];
                push @{ $all_versions{$n} }, $v;
            }
        }
    }

    my @rows;
    for my $sw (sort keys %all_versions) {
        push @rows, {
            software => $sw,
            #version => $active_versions{$sw},
            active_version => $active_versions{$sw},
            inactive_versions => join(", ", grep { !defined($active_versions{$sw}) || $_ ne $active_versions{$sw} } @{ $all_versions{$sw} }),
        };
    }

    my $resmeta = {};

    if ($args{detail}) {
        $resmeta->{'table.fields'} = [qw/software active_version inactive_versions/];
    } else {
        @rows = map { $_->{software} } @rows;
    }

    [200, "OK", \@rows, $resmeta];
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

    my $res = list_installed(%args, _software=>$args{software}, detail=>1);
    return $res unless $res->[0] == 200;
    my $row = $res->[2][0];
    return [200, "OK (none installed)"] unless $row;
    return [200, "OK", [map {(split /, /, $_)} grep {defined} ($row->{active_version}, $row->{inactive_versions})]];
}

$SPEC{list_downloaded} = {
    v => 1.1,
    summary => 'List all downloaded software',
    args => {
        %args_common,
        detail => {
            schema => ['bool*', is=>1],
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_downloaded {
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

    my @rows;
    {
        local $CWD = $args{download_dir};
      SW:
        for my $sw (@$swlist) {
            my $dir = sprintf "%s/%s", substr($sw, 0, 1), $sw;
            unless (-d $dir) {
                log_trace "Skipping software '$sw': directory doesn't exist";
                next SW;
            }
            local $CWD = $dir;
            my $mod = App::swcat::_load_swcat_mod($sw);
            my @vers;
          VER:
            for my $e (glob "*") {
                if ($args{_arch}) {
                    next unless dir_has_non_dot_files("$e/$args{_arch}");
                } else {
                    next unless -d $e;
                }
                next unless $mod->is_valid_version($e);
                push @vers, $e;
            }
            unless (@vers) {
                log_trace "Skipping software '$sw': no downloaded versions found";
            }
            @vers = sort { $mod->cmp_version($a, $b) } @vers;
            log_trace "Found downloaded versions %s for software '%s'", \@vers, $sw;
            push @rows, {
                software => $sw,
                latest_version => $vers[-1],
                all_versions => join(", ", @vers),
            };
        }
    }

    my $resmeta = {};

    if ($args{detail}) {
        $resmeta->{'table.fields'} = [qw/software latest_version all_versions/];
    } else {
        @rows = map { $_->{software} } @rows;
    }

    [200, "OK", \@rows, $resmeta];
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

    my $res = list_downloaded(%args, _software=>$args{software}, _arch=>$args{arch}, detail=>1);
    return $res unless $res->[0] == 200;
    my $row = $res->[2][0];
    return [200, "OK (none downloaded)"] unless $row;
    return [200, "OK", [map {(split /, /, $_)} grep {defined} $row->{all_versions}]];
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

    $res = list_installed(%args, detail=>1);
    return $res unless $res->[0] == 200;
    my $installed = $res->[2];

    for my $row (@$installed) {
        my $sw = $row->{software};
        my $mod = App::swcat::_load_swcat_mod($sw);

        $row->{installed} = delete $row->{active_version};
        $row->{installed_inactive} = delete $row->{inactive_versions};

        my $downloaded_vv;
        $res = list_downloaded_versions(%args, software=>$sw);
        if ($res->[0] == 200) {
            $downloaded_vv = join ", ", @{$res->[2]};
        } else {
            log_error "Can't check downloaded versions of $sw: $res->[0] - $res->[1]";
        }
        $row->{downloaded} = $downloaded_vv;

        my $latest_v;
        $res = App::swcat::latest_version(%args, softwares_or_patterns=>[$sw]);
        if ($res->[0] == 200) {
            $latest_v = $res->[2];
        } else {
            log_error "Can't check latest version of $sw: $res->[0] - $res->[1]";
        }
        $row->{latest} = $latest_v;

        my @vv;
        push @vv, split(/,\s*/, $downloaded_vv) if defined $downloaded_vv;
        push @vv, $latest_v if defined $latest_v;
        @vv = sort { $mod->cmp_version($a, $b) } @vv;

        $row->{status} = '';
        if (@vv) {
            my $cmp = $mod->cmp_version($row->{installed}, $vv[-1]);
            if ($cmp >= 0) {
                $row->{status} = 'up to date';
            } else {
                $row->{status} = "updatable to $vv[-1]";
            }
        }
    }
    my $resmeta = {
        'table.fields' => [qw/software installed installed_inactive downloaded latest status/],
    };
    [200, "OK", $installed, $resmeta];
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
        my $v0 = $res->[2] ? $res->[2][-1] : undef;

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
            my $dlurlres = $mod->get_download_url(
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
            unless defined $row->{active_version};
        next unless defined $row->{inactive_versions};
        #log_trace "Cleaning up software $sw ...";
        for my $v (split /, /, $row->{inactive_versions}) {
            my $dir = "$sw-$v";
            unless (-d $dir) {
                log_trace "Skipping version $v of software $sw (directory does not exist)";
                next;
            }
            if ($args{-dry_run}) {
                log_trace "[DRY-RUN] Removing $dir ...";
            } else {
                log_trace "Removing $dir ...";
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
    my $state = _init(\%args);

    local $CWD = $args{download_dir};
    my $res = list_downloaded(%args, detail=>1);
    return $res unless $res->[0] == 200;
  SW:
    for my $row (@{ $res->[2] }) {
        my $sw = $row->{software};
        next unless $row->{all_versions};
        my @vers = split /, /, $row->{all_versions};
        unless (@vers > 1) {
            log_trace "Skipping software $sw (<2 versions)";
            next SW;
        }
        pop @vers; # remove latest version
        my $dir = sprintf "%s/%s", substr($sw, 0, 1), $sw;
        local $CWD = $dir;
      VER:
        for my $v (@vers) {
            if ($args{-dry_run}) {
                log_trace "[DRY-RUN] Cleaning up $sw-$v ...";
            } else {
                log_trace "Cleaning up software $sw-$v ...";
                File::Path::remove_tree($v);
            }
        }
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
                $v = $res->[2] ? $res->[2][-1] : undef;
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

        my $cafres = Filename::Archive::check_archive_filename(
            filename => $filename);
        unless ($cafres) {
            my $errmsg = "Can't install $sw: Currently cannot handle software that has downloaded file that is not an archive";
            log_error $errmsg;
            $envres->add_result(412, $errmsg, {item_id=>$sw});
            next SW;
        }

        my $target_name = join(
            "",
            $sw, "-", $v,
        );
        my $target_dir = join(
            "",
            $args{install_dir},
            "/", $target_name,
        );

        my $aires = $mod->get_archive_info(%args, version => $v);
        unless ($aires->[0] == 200) {
            my $errmsg = "Can't install $sw: Can't get archive info: $aires->[0] - $aires->[1]";
            log_error $errmsg;
            $envres->add_result(500, $errmsg, {item_id=>$sw});
            next SW;
        }

      EXTRACT: {
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
        } # EXTRACT

      SYMLINK_DIR: {
            local $CWD = $args{install_dir};
            log_trace "Creating/updating directory symlink to latest version ...";
            if (File::MoreUtil::file_exists($sw)) {
                unlink $sw or die "Can't unlink $args{install_dir}/$sw: $!";
            }
            symlink $target_name, $sw or die "Can't symlink $sw -> $target_name: $!";
        }

      SYMLINK_PROGRAMS: {
            local $CWD = $args{program_dir};
            log_trace "Creating/updating program symlinks ...";
            my $programs = $aires->[2]{programs} // [];
            for my $e (@$programs) {
                if ((-l $e->{name}) || !File::MoreUtil::file_exists($e->{name})) {
                    unlink $e->{name};
                    my $target = "$args{install_dir}/$sw$e->{path}/$e->{name}";
                    $target =~ s!//!/!g;
                    log_trace "Creating symlink $args{program_dir}/$e->{name} -> $target ...";
                    symlink $target, $e->{name} or die "Can't symlink $e->{name} -> $target: $!";
                } else {
                    log_warn "%s/%s is not a symlink, skipping", $args{program_dir}, $e->{name};
                    next;
                }
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

This document describes version 0.010 of App::instopt (from Perl distribution App-instopt), released on 2019-08-07.

=head1 SYNOPSIS

See L<instopt> script.

=head1 FUNCTIONS


=head2 cleanup_download_dir

Usage:

 cleanup_download_dir(%args) -> [status, msg, payload, meta]

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

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cleanup_install_dir

Usage:

 cleanup_install_dir(%args) -> [status, msg, payload, meta]

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

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 compare_versions

Usage:

 compare_versions(%args) -> [status, msg, payload, meta]

Compare installed vs downloaded vs latest versions of installed software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 download

Usage:

 download(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 download_all

Usage:

 download_all(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_downloaded

Usage:

 list_downloaded(%args) -> [status, msg, payload, meta]

List all downloaded software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_downloaded_versions

Usage:

 list_downloaded_versions(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_installed

Usage:

 list_installed(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_installed_versions

Usage:

 list_installed_versions(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 update

Usage:

 update(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 update_all

Usage:

 update_all(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
