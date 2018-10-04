package App::instopt;

our $DATE = '2018-10-04'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use App::swcat ();
use File::chdir;
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
        if ($#metanames >= $i) {
            push @filenames, $metanames[$i];
        } elsif (my $rurl = _real_url($urls[$i])) {
            (my $filename = $rurl) =~ s!.+/!!;
            $filename = URI::Escape::uri_unescape($filename);
            push @filenames, $filename;
        } else {
            push @filenames, "$args{software}-$args{version}";
        }
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

    if ($args{_software}) {
        return [412, "Unknown software '$args{_software}'"] unless
            grep { $_ eq $args{_software} } @$known;
        $known = [$args{_software}];
    }

    my %active_versions;
    my %all_versions;
    {
        local $CWD = $args{install_dir};
        for my $e (glob "*") {
            if (-l $e) {
                next unless grep { $e eq $_ } @$known;
                my $v = readlink($e);
                next unless $v =~ s/\A\Q$e\E-//;
                $active_versions{$e} = $v;
            } elsif (-d $e) {
                my ($n, $v) = $e =~ /(.+)-(.+)/ or next;
                next unless grep { $n eq $_ } @$known;
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
        %App::swcat::arg0_software,
        detail => {
            schema => ['bool*', is=>1],
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_downloaded {
    [501, "Not yet implemented"];
}

$SPEC{download} = {
    v => 1.1,
    summary => 'Download latest version of software',
    args => {
        %args_common,
        %App::swcat::arg0_software,
        %argopt_arch,
    },
};
sub download {
    require File::Path;

    my %args = @_;
    my $state = _init(\%args);

    my $mod = App::swcat::_load_swcat_mod($args{software});
    my $res;

    $res = App::swcat::latest_version(%args);
    return $res if $res->[0] != 200;
    my $v = $res->[2];

    my $dlurlres = $mod->get_download_url(
        arch => $args{arch},
    );
    return $dlurlres if $dlurlres->[0] != 200;
    my @urls = ref($dlurlres->[2]) eq 'ARRAY' ? @{$dlurlres->[2]} : ($dlurlres->[2]);
    my @filenames = _convert_download_urls_to_filenames(
        res => $dlurlres, software => $args{software}, version => $v);

    my $target_dir = join(
        "",
        $args{download_dir},
        "/", substr($args{software}, 0, 1),
        "/", $args{software},
        "/", $v,
        "/", $args{arch},
    );
    File::Path::make_path($target_dir);

    my $ua = _ua();
    my @files;
    for my $i (0..$#urls) {
        my $url = $urls[$i];
        my $filename = $filenames[$i];
        my $target_path = "$target_dir/$filename";
        push @files, $target_path;
        log_info "Downloading %s to %s ...", $url, $target_path;
        my $lwpres = $ua->mirror($url, $target_path);
        unless ($lwpres->is_success || $lwpres->code =~ /^304/) {
            die "Can't download $url to $target_path: " .
                $lwpres->code." - ".$lwpres->message;
        }
    }
    [200, "OK", undef, {
        'func.version' => $v,
        'func.files' => \@files,
        'func.unwrap_tarball' => $dlurlres->[3]{'func.unwrap_tarball'} // 1,
    }];
}

$SPEC{cleanup} = {
    v => 1.1,
    summary => 'Remove inactive versions',
    args => {
        %args_common,
        #%App::swcat::arg0_software,
    },
    # XXX add dry_run
};
sub cleanup {
    require File::Path;

    my %args = @_;

    local $CWD = $args{install_dir};
    my $res = list_installed(%args, _software=>$args{software}, detail=>1);
    return $res unless $res->[0] == 200;
    for my $row (@{ $res->[2] }) {
        my $sw = $row->{software};
        log_trace "Skipping software $sw because there is no active version"
            unless defined $row->{active_version};
        next unless defined $row->{inactive_versions};
        log_trace "Cleaning up software $sw ...";
        for my $v (split /, /, $row->{inactive_versions}) {
            my $dir = "$sw-$v";
            unless (-d $dir) {
                log_trace "  Skipping version $v (directory does not exist)";
                next;
            }
            log_trace "  Removing $dir ...";
            File::Path::remove_tree($dir);
        }
    }
    [200];
}

$SPEC{update} = {
    v => 1.1,
    summary => 'Update a software to the latest version',
    args => {
        %args_common,
        %App::swcat::arg0_software,
        # XXX --no-download option
    },
};
sub update {
    require Archive::Any;
    require File::MoreUtil;
    require File::Path;
    require Filename::Archive;

    my %args = @_;
    my $state = _init(\%args);

    my $mod = App::swcat::_load_swcat_mod($args{software});

  UPDATE: {
        log_info "Updating software %s ...", $args{software};

        my $dlres = download(%args);
        return $dlres if $dlres->[0] != 200;

        my ($filepath, $filename);
        if (@{ $dlres->[3]{'func.files'} } != 1) {
            return [412, "Currently cannot handle software that has multiple downloaded files"];
        }
        $filepath = $filename = $dlres->[3]{'func.files'}[0];
        $filename =~ s!.+/!!;

        my $cafres = Filename::Archive::check_archive_filename(
            filename => $filename);
        unless ($cafres) {
            return [412, "Currently cannot handle software that has downloaded file that is not an archive"];
        }

        my $target_name = join(
            "",
            $args{software}, "-", $dlres->[3]{'func.version'},
        );
        my $target_dir = join(
            "",
            $args{install_dir},
            "/", $target_name,
        );

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

            _unwrap($target_dir) if $dlres->[3]{'func.unwrap_tarball'};
        } # EXTRACT

      SYMLINK_DIR: {
            local $CWD = $args{install_dir};
            log_trace "Creating/updating directory symlink to latest version ...";
            if (File::MoreUtil::file_exists($args{software})) {
                unlink $args{software} or die "Can't unlink $args{install_dir}/$args{software}: $!";
            }
            symlink $target_name, $args{software} or die "Can't symlink $args{software} -> $target_name: $!";
        }

      SYMLINK_PROGRAMS: {
            local $CWD = $args{program_dir};
            log_trace "Creating/updating program symlinks ...";
            my $res = $mod->get_programs;
            for my $e (@{ $res->[2] }) {
                if ((-l $e->{name}) || !File::MoreUtil::file_exists($e->{name})) {
                    unlink $e->{name};
                    my $target = "$args{install_dir}/$args{software}$e->{path}/$e->{name}";
                    $target =~ s!//!/!g;
                    log_trace "Creating symlink $args{program_dir}/$e->{name} -> $target ...";
                    symlink $target, $e->{name} or die "Can't symlink $e->{name} -> $target: $!";
                } else {
                    log_warn "%s/%s is not a symlink, skipping", $args{program_dir}, $e->{name};
                    next;
                }
            }
        }

    } # UPDATE

    [200, "OK"];
}

$SPEC{update_all} = {
    v => 1.1,
    summary => 'Update all installed software',
    args => {
        %args_common,
    },
};
sub update_all {
    my %args = @_;
    my $state = _init(\%args);

    my $res = list_installed(%args);
    return $res unless $res->[0] == 200;

    my $envresmulti = envresmulti();
    for my $sw (@{ $res->[2] }) {
        $res = update(%args, software=>$sw);
        $envresmulti->add_result($res->[0], $res->[1], {item_id=>$sw});
    }

    $envresmulti->as_struct;
}

1;
# ABSTRACT: Download and install software

__END__

=pod

=encoding UTF-8

=head1 NAME

App::instopt - Download and install software

=head1 VERSION

This document describes version 0.002 of App::instopt (from Perl distribution App-instopt), released on 2018-10-04.

=head1 SYNOPSIS

See L<instopt> script.

=head1 FUNCTIONS


=head2 cleanup

Usage:

 cleanup(%args) -> [status, msg, result, meta]

Remove inactive versions.

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
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 download

Usage:

 download(%args) -> [status, msg, result, meta]

Download latest version of software.

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
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_downloaded

Usage:

 list_downloaded(%args) -> [status, msg, result, meta]

List all downloaded software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<download_dir> => I<dirname>

=item * B<install_dir> => I<dirname>

=item * B<program_dir> => I<dirname>

=item * B<software>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_installed

Usage:

 list_installed(%args) -> [status, msg, result, meta]

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
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_installed_versions

Usage:

 list_installed_versions(%args) -> [status, msg, result, meta]

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
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 update

Usage:

 update(%args) -> [status, msg, result, meta]

Update a software to the latest version.

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
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 update_all

Usage:

 update_all(%args) -> [status, msg, result, meta]

Update all installed software.

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
200. Third element (result) is optional, the actual result. Fourth
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

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
