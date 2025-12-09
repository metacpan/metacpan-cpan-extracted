package App::DistSync;
use strict;
use warnings;
use utf8;
use feature qw/say/;

=encoding utf-8

=head1 NAME

App::DistSync - Utility for synchronizing distribution mirrors

=head1 SYNOPSIS

    use App::DistSync;

    my $ds = App::DistSync->new(
            dir => "/var/www/www.example.com/dist",
            pid => $$,
            timeout => 60,
            proxy => 'http://http.example.com:8001/',
        );

    $ds->init or die "Initialization error";

    $ds->sync or die "Sync error";

=head1 DESCRIPTION

Utility for synchronizing distribution mirrors

=head1 METHODS

This module implements the following methods

=head2 new

    my $ds = new App::DistSync(
            dir => "/var/www/www.example.com/dist",
            pid => $$,
            timeout => 60,
            proxy => 'http://http.example.com:8001/',
        );

Returns the object

=head2 dir

    my $abs_dir = $ds->dir;

Returns absolute pathname of working directory

=head2 fetch

    my $struct = $self->fetch( $URI_STRING, "path/to/file.txt", "/tmp/file.txt" );

Fetching file from remote resource by URI and filename.
The result will be written to the specified file. For example: "/tmp/file.txt"

Returns structure, contains:

    {
        status  => 1,         # Status. 0 - Errors; 1 - OK
        mtime   => 123456789, # Last-Modified in ctime format or 0 in case of errors
        size    => 123,       # Content-length
        code    => 200,       # HTTP Status code
    };

=head2 init

    $ds->init or die ("Initialization error");

Initializing the mirror in the specified directory

=head2 mkmani

    $ds->mkmani;

Generation the new MANIFEST file

=head2 pid

    my $pid = $ds->pid;

Returns the pid of current process

=head2 status

    $ds->status;

Show statistic information

=head2 sync

    $ds->sync or die ("Sync error");

Synchronization of the specified directory with the remote resources (mirrors)

=head2 ua

    my $ua = $ds->ua;

Returns the UserAgent instance (LWP::UserAgent)

=head2 verbose

    warn "Error details\n" if $ds->verbose;

This method returns verbose flag

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<LWP::Simple>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.10';

our $DEBUG //= !!$ENV{DISTSYNC_DEBUG};

use Carp;
use Cwd qw/abs_path getcwd/;
use FindBin qw($Script);
use File::Basename qw/dirname/;
use File::Copy qw/mv/;
use File::Spec;
use File::Path qw/mkpath/;
use Sys::Hostname;
use URI;
use LWP::UserAgent qw//;
use HTTP::Request qw//;
use HTTP::Date qw//;
use HTTP::Status qw//;

use App::DistSync::Util qw/
        debug qrreconstruct touch spew slurp
        fdelete read_yaml write_yaml
        maniread manifind maniwrite
    /;

use constant {
    TEMPFILE    => sprintf("distsync_%s.tmp", $$),
    TIMEOUT     => 30,
    METAFILE    => 'META',
    MANIFEST    => 'MANIFEST',
    MANISKIP    => 'MANIFEST.SKIP',
    MANITEMP    => 'MANIFEST.TEMP',
    MANILOCK    => 'MANIFEST.LOCK',
    MANIDEL     => 'MANIFEST.DEL',
    MIRRORS     => 'MIRRORS',
    README      => 'README',
    SKIPFILES   => [qw/
        META MANIFEST MIRRORS README
        MANIFEST.SKIP MANIFEST.LOCK MANIFEST.TEMP MANIFEST.DEL
    /],
    SKIPMODE    => 1,
    LIMIT       => '+1m', # '+1m' Limit gt and lt
    EXPIRE      => '+3d', # '+3d' For deleting
    FREEZE      => '+1d', # '+1d' For META test
};

# Methods
sub new {
    my $class = shift;
    my %props = @_;

    # Check directory
    my $dir = $props{dir} // getcwd();
    croak("Directory '$dir' not exists") unless length($dir) && (-d $dir or -l $dir);
    $props{dir} = $dir = abs_path($dir);

    # General
    $props{started} = $props{stamp} = time;
    $props{pid} ||= $$;
    $props{timeout} //= TIMEOUT;
    $props{verbose} ||= 0;
    $props{insecure} ||= 0;
    $props{proxy} //= '';
    $props{url} = '';
    $props{hostname} = hostname();

    # Files
    $props{file_meta}       = File::Spec->catfile($dir, METAFILE);
    $props{file_manifest}   = File::Spec->catfile($dir, MANIFEST);
    $props{file_maniskip}   = File::Spec->catfile($dir, MANISKIP);
    $props{file_manilock}   = File::Spec->catfile($dir, MANILOCK);
    $props{file_manitemp}   = File::Spec->catfile($dir, MANITEMP);
    $props{file_manidel}    = File::Spec->catfile($dir, MANIDEL);
    $props{file_mirrors}    = File::Spec->catfile($dir, MIRRORS);
    $props{file_readme}     = File::Spec->catfile($dir, README);
    $props{file_temp}       = File::Spec->catfile(File::Spec->tmpdir(), TEMPFILE);

    # Read META file as YAML
    my $meta = read_yaml($props{file_meta});
    $props{meta} = $meta;

    # Create current static dates
    $props{mtime_manifest} = (-e $props{file_manifest}) && -s $props{file_manifest}
        ? (stat($props{file_manifest}))[9]
        : 0;
    $props{mtime_manidel}  = (-e $props{file_manidel}) && -s $props{file_manidel}
        ? (stat($props{file_manidel}))[9]
        : 0;
    $props{mtime_mirrors}  = (-e $props{file_mirrors}) && -s $props{file_mirrors}
        ? (stat($props{file_mirrors}))[9]
        : 0;

    # Set TimeOut
    my $to = _expire($props{timeout} // TIMEOUT);
    croak("Can't use specified timeout") unless $to =~ /^[0-9]{1,11}$/;

    # Instance
    my $self = bless({%props}, $class);

    # User Agent
    my $ua = $self->{ua} = LWP::UserAgent->new();
    $ua->timeout($to) if $to;
    $ua->agent(sprintf("%s/%s", __PACKAGE__, $VERSION));
    $ua->env_proxy;
    $ua->proxy(['http', 'https'] => $props{proxy}) if $props{proxy};
    $ua->ssl_opts(
        verify_hostname => 0,
        SSL_verify_mode => 0x00
    ) if $props{insecure};

    return $self;
}
sub verbose { !!shift->{verbose} }
sub dir { shift->{dir} }
sub pid { shift->{pid} }
sub ua { shift->{ua} }
sub init { # Initialization
    my $self = shift;
    my $stamp = scalar(localtime($self->{started}));
    my $status = 1;

    # MANIFEST.SKIP
    printf "%s... ", $self->{file_maniskip};
    if (touch($self->{file_maniskip}) && (-e $self->{file_maniskip}) && -z $self->{file_maniskip}) {
        my @content = (
            "# Generated on $stamp",
            "# List of files that should not be synchronized",
            "#",
            "# Format of file:",
            "#",
            "# dir1/dir2/.../dirn/foo.txt        any comment, for example blah-blah-blah",
            "# bar.txt                           any comment, for example blah-blah-blah",
            "# baz.txt",
            "# 'spaced dir1/foo.txt'             any comment, for example blah-blah-blah",
            "# 'spaced dir1/foo.txt'             any comment, for example blah-blah-blah",
            "# !!perl/regexp (?i-xsm:\\.bak\$)     avoid all bak files",
            "#",
            "# See also MANIFEST.SKIP file of ExtUtils::Manifest v1.68 or later",
            "#",
            "",
            "# Avoid version control files.",
            "!!perl/regexp (?i-xsm:\\bRCS\\b)",
            "!!perl/regexp (?i-xsm:\\bCVS\\b)",
            "!!perl/regexp (?i-xsm:\\bSCCS\\b)",
            "!!perl/regexp (?i-xsm:,v\$)",
            "!!perl/regexp (?i-xsm:\\B\\.svn\\b)",
            "!!perl/regexp (?i-xsm:\\B\\.git\\b)",
            "!!perl/regexp (?i-xsm:\\B\\.gitignore\\b)",
            "!!perl/regexp (?i-xsm:\\b_darcs\\b)",
            "!!perl/regexp (?i-xsm:\\B\\.cvsignore\$)",
            "",
            "# Avoid temp and backup files.",
            "!!perl/regexp (?i-xsm:~\$)",
            "!!perl/regexp (?i-xsm:\\.(old|bak|back|tmp|temp|rej)\$)",
            "!!perl/regexp (?i-xsm:\\#\$)",
            "!!perl/regexp (?i-xsm:\\b\\.#)",
            "!!perl/regexp (?i-xsm:\\.#)",
            "!!perl/regexp (?i-xsm:\\..*\\.sw.?\$)",
            "",
            "# Avoid prove files",
            "!!perl/regexp (?i-xsm:\\B\\.prove\$)",
            "",
            "# Avoid MYMETA files",
            "!!perl/regexp (?i-xsm:^MYMETA\\.)",
            "",
            "# Avoid Apache and building files",
            "!!perl/regexp (?i-xsm:\\B\\.ht.+\$)",
            "!!perl/regexp (?i-xsm:\\B\\.exists\$)",
            "",
            "# Skip TEMP files",
            "!!perl/regexp (?i-xsm:\\.TEMP\\-\\d+\$)",
            "\n",
        );
        if (spew($self->{file_maniskip}, join("\n", @content))) {
            say "ok";
        } else {
            say "fail";
            $status = 0;
        }
    } else {
        say "skip";
    }

    # MANIFEST.DEL
    printf "%s... ", $self->{file_manidel};
    if (touch($self->{file_manidel}) && (-e $self->{file_manidel}) && -z $self->{file_manidel}) {
        my @content = (
            "# Generated on $stamp",
            "# List of files that must be deleted. By default, the files will be",
            "# deleted after 3 days.",
            "#",
            "# Format of file:",
            "#",
            "# dir1/dir2/.../dirn/foo.txt        1d",
            "# bar.txt                           2M",
            "# baz.txt",
            "# 'spaced dir1/foo.txt'             1m",
            "# 'spaced dir1/foo.txt'             2y",
            "#",
            "\n",
        );
        if (spew($self->{file_manidel}, join("\n", @content))) {
            say "ok";
        } else {
            say "fail";
            $status = 0;
        }
    } else {
        say "skip";
    }

    # MIRRORS
    printf "%s... ", $self->{file_mirrors};
    if (touch($self->{file_mirrors}) && (-e $self->{file_mirrors}) && -z $self->{file_mirrors}) {
        my @content = (
            "# Generated on $stamp",
            "# List of addresses (URIs) of remote storage (mirrors).",
            "# Must be specified at least two mirrors",
            "#",
            "# Format of file:",
            "#",
            "# http://www.example.com/dir1       any comment, for example blah-blah-blah",
            "# http://www.example.com/dir2       any comment, for example blah-blah-blah",
            "# 'http://www.example.com/dir2'     any comment, for example blah-blah-blah",
            "#",
            "\n",
        );
        if (spew($self->{file_mirrors}, join("\n", @content))) {
            say "ok";
        } else {
            say "fail";
            $status = 0;
        }
    } else {
        say "skip";
    }

    # README
    printf "%s... ", $self->{file_readme};
    if (touch($self->{file_readme}) && (-e $self->{file_readme}) && -z $self->{file_readme}) {
        my @content = (
            "# This file contains information about the resource (mirror) in the free form.",
            "#",
            "# Initialization date  : $stamp",
            "# Resource's directory : " . $self->dir,
            "#",
            "\n",
        );
        if (spew($self->{file_readme}, join("\n", @content))) {
            say "ok";
        } else {
            say "fail";
            $status = 0;
        }
    } else {
        say "skip";
    }

    return $status;
}
sub sync { # Synchronization. Main proccess
    my $self = shift;
    my $status = 0;
    my %skips; # { file => /regexp/|file } List of skipped files
    my $manifest = maniread($self->{file_manifest}) // {}; # {file => [epoch, size, wday, month, day, time, year]}
    my %sync_list;      # {file => [{url, mtime, size}]} List of files to sync
    my %delete_list;    # {file => count} List of files to delete

    # Filling the list of exclusion files using the MANIFEST.SKIP file and
    # the list of system files from the SKIPFILES constant
    {
        debug("Getting the list of skipped files");
        my @skip_keys = @{(SKIPFILES)};
        my $maniskip = maniread($self->{file_maniskip}, SKIPMODE); # MANIFEST.SKIP
        push @skip_keys, keys %$maniskip if ref($maniskip) eq 'HASH';
        for (@skip_keys) {$skips{$_} = qrreconstruct($_)}
        debug("Found %d keys in the list of skipped files", scalar(keys %skips));
        #debug(Data::Dumper::Dumper(\%skips)) && return 0;
    }

    # Deleting files listed in the MANIFEST.DEL file but not in the exclusion list
    {
        debug("Deleting files from list: %s", MANIDEL);
        my $delfile = $self->{file_manidel};  # MANIFEST.DEL
        my $deltime = $self->{mtime_manidel}; # Modify time in seconds
        my $dellist = maniread($delfile) // {}; # { file => expire };
        my $expire = 0;
        foreach (values %$dellist) {
            my $dt = _expire($_->[0] || 0);
            $_ = [$dt];
            $expire = $dt if $dt > $expire;
        }
        $expire = _expire(EXPIRE) unless $expire > 0;
        debug("The file '$delfile' will expire on %s", scalar(localtime($deltime + $expire)))
            if $deltime;
        #debug(Data::Dumper::Dumper($dellist)) && return 0;
        if ($deltime && (time - $deltime) > $expire) { # MANIFEST.DEL is expired!
            # Delete files physically if they exist physically and are not on the exclusion list!
            foreach my $k (keys %$dellist) {
                if (_skipcheck(\%skips, $k)) { # The file is in the exclusion list.
                    debug("> [SKIPPED] %s", $k);
                    next;
                }
                my $f = File::Spec->canonpath(File::Spec->catfile($self->dir, $k));
                if (-e $f) {
                    fdelete($f);
                    debug("> [DELETED] %s", $k);
                } else {
                    debug("> [SKIPPED] %s (%s)", $k, $f);
                }
            }

            # Deleting the MANIFEST.DEL file and immediately creating a new one
            fdelete($delfile);
            touch($delfile);
        } else {
            if ($deltime) {
                debug("Skipped. Deletion is not required yet because the scheduled time has not arrived");
                if ($self->verbose) {
                    debug("  File    : %s", MANIDEL);
                    debug("  Created : %s", scalar(localtime($deltime)));
                    debug("  Expires : %s", scalar(localtime($deltime + $expire)));
                }
            } else {
                debug("Skipped. File %s not exists",  MANIDEL);
            }
        }

        # Adding files listed in MANIFEST.DEL to the exclusion list
        for (keys %$dellist) {$skips{$_} = qrreconstruct($_)}
    }

    # Reading the MIRRORS file and deciding whether to synchronize or not
    debug("Synchronization");
    my $mirrors_mani = maniread($self->{file_mirrors}) // {}; # MIRRORS
    my @mirrors = sort {$a cmp $b} keys %$mirrors_mani;
    if (scalar(@mirrors)) {
        foreach my $url (@mirrors) {
            debug("RESOURCE \"%s\"", $url);

            # Downloading the MANIFEST.LOCK file, skipping the mirror resource if this
            # file was successfully downloaded from the resource
            {
                debug("Fetching %s", MANILOCK);
                my $fetch_lock = $self->fetch($url, MANILOCK, $self->{file_manitemp});
                if ($fetch_lock->{status}) { # Ok
                    if ($self->_check_lockfile($self->{file_manitemp})) {
                        $self->{url} = $url;
                        debug("> [SKIPPED] Current resource SHOULD NOT update itself");
                    } else {
                        debug("> [SKIPPED] Remote resource is in a state of updating. Please wait");
                    }
                    next;
                }
            }

            # Downloading the META file and analyzing the resource (checking the resource
            # status and update date). If the check fails, the resource is skipped.
            {
                debug("Fetching %s", METAFILE);
                my $fetch_meta = $self->fetch($url, METAFILE, $self->{file_manitemp});
                if ($fetch_meta->{status}) { # Ok
                    my $remote_meta = read_yaml($self->{file_manitemp}) // '';
                    if (((ref($remote_meta) eq 'ARRAY') || ref($remote_meta) eq 'YAML::Tiny')) {
                        $remote_meta = $remote_meta->[0] || {};
                    }
                    unless ($remote_meta && ref($remote_meta) eq 'HASH') {
                        debug("> [SKIPPED] Remote resource is unreadable. Please contact the administrator of this resource");
                        next;
                    }
                    if ($remote_meta->{status}) {
                        my $remote_url  = $remote_meta->{url} || $remote_meta->{uri} || '';
                        my $remote_date = $fetch_meta->{mtime} || 0;
                        my $remote_datef = $remote_date ? scalar(localtime($remote_date)) : 'UNKNOWN';
                        my $remote_ok = (time - $remote_date) > _expire(FREEZE) ? 0 : 1;
                        if ($self->verbose) {
                            debug("RESOURCE INFORMATION:");
                            debug("  Resource URL : %s", $remote_url);
                            debug("  Date         : %s", $remote_meta->{date} // 'UNKNOWN');
                            debug("  Modified     : %s", $remote_datef);
                            debug("  Hostname     : %s", $remote_meta->{hostname} // '');
                            debug("  Directory    : %s", $remote_meta->{directory} // '');
                            debug("  Project      : %s v%s",
                                $remote_meta->{project} || ref($self), $remote_meta->{version} // '0.01');
                            debug("  Script       : %s", $remote_meta->{script} // '');
                            debug("  Status       : %s", $remote_ok ? "OK" : "EXPIRED");
                            debug("  Time         : %d sec", $remote_meta->{'time'} || 0);
                        }
                        unless ($remote_ok) {
                            debug("> [SKIPPED] Remote resource is expired. Last updated: %s", $remote_datef);
                            next
                        }
                    } else {
                        debug("> [SKIPPED] Remote resource is broken. Please contact the administrator of this resource");
                        next;
                    }
                } else {
                    printf STDERR "Can't download \"%s\": %s\n", $fetch_meta->{url}, $fetch_meta->{message};
                }
            }

            # Downloading the MANIFEST file
            {
                debug("Fetching %s", MANIFEST);
                my $fetch_mani = $self->fetch($url, MANIFEST, $self->{file_manitemp});
                if ($fetch_mani->{status}) {
                    my $remote_manifest = maniread($self->{file_manitemp}) // {};
                    my %mtmp; # {file => count} Temporary work structure

                    # Two manifest lists - local and remote - are merged into a temporary structure
                    # {file => [epoch, size, wday, month, day, time, year]}
                    foreach my $k (keys(%$manifest), keys(%$remote_manifest)) {
                        unless (exists $mtmp{$k}) {
                            $mtmp{$k} = 1;
                            next;
                        }
                        my $mt_l = $manifest->{$k}[0] || 0; # Modified time (local, left)
                        my $mt_r = $remote_manifest->{$k}[0] || 0;  # Modified time (remote, right)
                        $mtmp{$k}++ if $mt_l && $mt_r && $mt_l == $mt_r; # =2 if the files are identical
                    }
                    #debug(Data::Dumper::Dumper(\%mtmp));

                    # Getting the difference between the lists of local and remote files
                    #
                    # [=] The files do not differ; they are identical in both lists
                    # [<] The file exists in the local (left) file list
                    # [>] The file exists in the remote (right) file list
                    # [{] The "newer" file is the one in the local list
                    # [}] The "newer" file is the one in the remote list
                    # [~] The file sizes differ between the lists. This is only reported as information,
                    #     since modification times and file presence have higher priority than sizes
                    # [!] A conflict situation. An almost impossible edge case
                    #
                    # The comparison works as follows:
                    # We iterate through the entries of the manifest structures (the left and right lists)
                    # and analyze where the counter value is 1 and where it is 2.
                    # A value of 1 means that the file exists in only one of the file lists - but in which one?
                    # If it's the left list, the line is marked with "<", as described in the legend above;
                    # if it's the right list, the line is marked with ">".
                    my $lim = _expire(LIMIT); # 1 min
                    foreach my $k (keys %mtmp) {
                        next unless $mtmp{$k}; # Skip broken records
                        next unless $mtmp{$k} == 1; # Files are NOT idential
                        if ($manifest->{$k} && $remote_manifest->{$k}) { # Both sides: left and right
                            my $mt_l = $manifest->{$k}[0] || 0;
                            my $mt_r = $remote_manifest->{$k}[0] || 0;
                            if (($mt_l > $mt_r) && ($mt_l - $mt_r) > $lim) {
                                # Skip! The left (local) file is more than one minute newer than the right one
                                # debug("# [{] %s", $k) if $self->verbose;
                            } if (($mt_l < $mt_r) && ($mt_r - $mt_l) > $lim) {
                                # The right (remote) file is more than one minute newer than the left one
                                debug("# [}] %s (LOCAL [%s] < REMOTE [%s])", $k,
                                    scalar(localtime($mt_l)), scalar(localtime($mt_r))) if $self->verbose;
                                # Add to sync list for downloading
                                unless (_skipcheck(\%skips, $k)) {
                                    my $ar = $sync_list{$k} //= [];
                                    push @$ar, {
                                        url     => $url,
                                        mtime   => $remote_manifest->{$k}[0],
                                        size    => $remote_manifest->{$k}[1],
                                    };
                                }
                            } else {
                                # Skip! Files are idential
                                #debug("# [=] %s", $k) if $self->verbose;
                            }
                        } elsif ($manifest->{$k}) { # Left side
                            # Skip! No download requiered
                            # debug("# [<] %s", $k) if $self->verbose;
                        } elsif ($remote_manifest->{$k}) { # Right (remote) side
                            # Download required
                            debug("# [>] %s", $k) if $self->verbose;
                            unless (_skipcheck(\%skips, $k)) {
                                my $ar = $sync_list{$k} //= [];
                                push @$ar, {
                                    url     => $url,
                                    mtime   => $remote_manifest->{$k}[0],
                                    size    => $remote_manifest->{$k}[1],
                                };
                            }
                        } else {
                            debug(sprintf("# [!] %s", $k)) if $self->verbose;
                        }
                    }

                    # Ok
                    $status = 1;
                } else {
                    debug("> [SKIPPED] Can't download \"%s\"", $fetch_mani->{url});
                    printf STDERR "Can't download \"%s\": %s\n", $fetch_mani->{url}, $fetch_mani->{message};
                    next;
                }
            }

            # Download the MIRRORS file and add it to the sync list if it is up to date
            {
                debug("Fetching %s", MIRRORS);
                my $fetch_mirr = $self->fetch($url, MIRRORS, $self->{file_manitemp});
                if ($fetch_mirr->{status} && ((-z $self->{file_mirrors}) || $fetch_mirr->{mtime} > $self->{mtime_mirrors})) {
                    my $remote_mirr = maniread($self->{file_manitemp}) // {};
                    my $mcnt = scalar(keys %$remote_mirr) || 0; # Resources count in remote mirror file
                    if ($mcnt && $mcnt > 1) { # 2 and more resources
                        my $ar = $sync_list{(MIRRORS)} //= [];
                        push @$ar, {
                            url     => $url,
                            mtime   => $fetch_mirr->{mtime},
                            size    => $fetch_mirr->{size},
                        };
                    } else {
                        debug("> [SKIPPED] File %s on %s contains too few mirrors", MIRRORS, $url);
                    }
                } else {
                    printf STDERR "Can't download \"%s\": %s\n", $fetch_mirr->{url}, $fetch_mirr->{message}
                        unless $fetch_mirr->{status};
                }
            }

            # Download MANIFEST.DEL and fill the list to delete the files listed in it
            {
                debug("Fetching %s", MANIDEL);
                my $fetch_dir = $self->fetch($url, MANIDEL, $self->{file_manitemp});
                if ($fetch_dir->{status}) {
                    my $remote_manidel = maniread($self->{file_manitemp}) // {};
                    foreach my $k (keys %$remote_manidel) {
                        unless (_skipcheck(\%skips, $k)) {
                            $delete_list{$k} //= 0;
                            $delete_list{$k}++;
                        }
                    }
                } else {
                    printf STDERR "Can't download \"%s\": %s\n", $fetch_dir->{url}, $fetch_dir->{message}
                }
            }
        } continue {
            fdelete($self->{file_manitemp});
        }
    } else {
        $status = 1;
        debug("Skipped. File %s is empty", MIRRORS);
    }

    # Deleting files according to the generated list of files to be deleted
    {
        debug("Deleting files");
        foreach my $k (keys %delete_list) {
            my $f = File::Spec->canonpath(File::Spec->catfile($self->dir, $k));
            if (-e $f) {
                fdelete($f);
                debug("> [DELETED] %s", $k);
            } else {
                debug("> [SKIPPED] %s (%s)", $k, $f);
            }
        }
    }
    #debug(Data::Dumper::Dumper(\%delete_list));

    # Iterate through the synchronization list and download all files that
    # are NOT present in the previously generated deletion list.
    #debug(Data::Dumper::Dumper(\%sync_list));
    {
        debug("Downloading files");
        my $total = 0; # Size
        my $cnt = 0; # File number
        my $all = scalar(keys %sync_list);
        my $af = '[%0' . length("$all") . 'd/%0' . length("$all") . 'd] %s';
        foreach my $k (sort {lc($a) cmp lc($b)} keys %sync_list) { $cnt++;
            debug($af, $cnt, $all, $k);
            my $list = $sync_list{$k} // []; # Get list of urls
            unless (scalar(@$list)) {
                debug("> [SKIPPED] Nothing to do for %s", $k) if $self->verbose;
                next;
            }

            # Try to download by list of urls
            my $mt_l = $manifest->{$k}[0] || 0; # Modify time of local file
            my $is_downloaded = 0;
            foreach my $job (sort {($b->{mtime} || 0)  <=> ($a->{mtime} || 0)} @$list) {
                last if $is_downloaded;
                my $mt_r = $job->{mtime}; # Modify time of remote file
                my $url  = $job->{url}; # URL of remote file
                my $size = $job->{size}; # Size of remote file

                # Check URL
                unless ($url) {
                    debug("> [SKIPPED] No URL") if $self->verbose;
                    next;
                }

                # Check size
                unless ($size) {
                    debug("> [SKIPPED] No file size: %s", $url) if $self->verbose;;
                    next;
                }

                # Check modify time
                unless ($mt_r || !$mt_l) {
                    debug("> [SKIPPED] The remote file have undefined modified time: %s", $url) if $self->verbose;
                    next;
                }
                if ($mt_l >= $mt_r) {
                    debug("> [SKIPPED] File is up to date: %s", $url) if $self->verbose;
                    next;
                }

                # Download
                my $fetch_file = $self->fetch($url, $k, $self->{file_temp});
                if ($fetch_file->{status}) {
                    my $size_fact = $fetch_file->{size} || 0;
                    if ($size_fact && $size_fact == $size) {
                        debug("> [  OK   ] Received %d bytes: %s", $size_fact, $url) if $self->verbose;
                        $total += $size_fact;
                        $is_downloaded = 1;
                        next;
                    }
                } else {
                    printf STDERR "Can't download \"%s\": %s\n", $fetch_file->{url}, $fetch_file->{message};
                }
                debug("> [ ERROR ] Can't fetch %s", $url) if $self->verbose;
            }
            unless ($is_downloaded) {
                debug(("> [FAILED ] Can't download file %s", $k));
                next;
            }

            # The file has been downloaded successfully and is already in a temporary file,
            # ready to be move to the target directory under its own name.
            {
                my $src = $self->{file_temp}; # From $self->{file_temp}
                my $dst = File::Spec->canonpath(File::Spec->catfile($self->dir, $k)); # To $k

                # Create target directory
                my $dir = dirname($dst); # See File::Basename
                my $mkerr;
                mkpath($dir, {verbose => 1, mode => 0777, error => \$mkerr});
                if ($mkerr && (ref($mkerr) eq 'ARRAY') && scalar(@$mkerr)) {
                    foreach my $e (@$mkerr) {
                        next unless $e && ref($e) eq 'HASH';
                        while (my ($_k, $_v) = each %$e) {
                            printf STDERR "%s: %s\n", $_k, $_v;
                        }
                    }
                }

                # Move file to target directory
                fdelete($dst);
                unless (mv($src, $dst)) {
                    printf STDERR "Can't move file %s to %s: $!\n", $src, $dst;
                }
            }
        }

        # Ok
        debug("Received %d bytes", $total);
    }

    # Cteating MANIFEST file
    debug("Generating new manifest");
    my $new_manifest = manifind($self->dir);

    # We select files excluding files listed in the exclusion list
    foreach my $k (keys %$new_manifest) {
        my $nskip = _skipcheck(\%skips, $k);
        delete $new_manifest->{$k} if $nskip;
        debug("> [%s] %s", $nskip ? "SKIPPED" : " ADDED ", $k);
    }
    #debug(Data::Dumper::Dumper($new_manifest));

    # Save the created file
    debug("Saving manifest to %s", MANIFEST);
    return 0 unless maniwrite($self->{file_manifest}, $new_manifest);

    # Creating new META file
    debug("Generating new META file");
    # NOTE! The status in the META file is set only after the final directory structure
    # has been successfully generated. This change distinguishes already "working"
    # resources from those that have just been initialized.
    my $now = time;
    my $new_meta = {
            project     => ref($self),
            version     => $self->VERSION,
            hostname    => $self->{hostname},
            directory   => $self->dir,
            script      => $Script,
            start       => $self->{stamp},
            finish      => $now,
            pid         => $self->pid,
            uri         => $self->{url} || 'localhost',
            url         => $self->{url} || 'localhost',
            date        => scalar(localtime(time)),
            'time'      => $now - $self->{stamp},
            status      => 1,
        };
    return 0 unless write_yaml($self->{file_meta}, $new_meta);

    # Return
    return $status;
}
sub fetch { # Returns structire {status, mtime, size, code, url}
    my $self = shift;
    my $url = shift; # Base url
    my $obj = shift; # The tail of path
    my $file = shift // ''; # File to download
    my $ua = $self->ua;

    # Empty response
    my $ret = {
            status  => 0, # Status
            mtime   => 0, # Last-Modified in ctime format or 0
            size    => 0, # Content-length
            code    => 0, # Status code
            message => '',
            url     => '',
        };

    # Check file
    unless (length($file)) {
        carp "File path to download is not specified";
        return $ret;
    }

    # Make new URI
    my $uri = URI->new($url);
    my $curpath = $uri->path();
    my $newpath = $curpath . (defined $obj ? "/$obj" : '');
       $newpath =~ s/\/{2,}/\//;
    $uri->path($newpath);
    $ret->{url} = $uri->as_string;

    # First request: get HEAD information
    my $request = HTTP::Request->new(HEAD => $uri);
    my $response = $ua->request($request);
    my $content_type = scalar $response->header('Content-Type');
    my $document_length = scalar $response->header('Content-Length');
    my $modified_time = HTTP::Date::str2time($response->header('Last-Modified'));
    my $expires = HTTP::Date::str2time($response->header('Expires'));
    my $server = scalar $response->header('Server');
    $ret->{code} = $response->code;
    $ret->{message} = $response->message;
    if ($self->verbose) {
        if (!$DEBUG && !$response->is_success) {
            say sprintf "> HEAD %s", $uri->as_string;
            say sprintf "< %s", $response->status_line;
        }
        debug("> HEAD %s", $uri->as_string);
        debug("< %s", $response->status_line);
        if ($response->is_success) {
            debug("< Content-Type   : %s", $content_type // '');
            debug("< Content-Length : %s", $document_length || 0);
            debug("< Last-Modified  : %s", $modified_time ? scalar(localtime($modified_time)) : '');
            debug("< Expires        : %s", $expires ? scalar(localtime($expires)) : '');
            debug("< Server         : %s", $server // '');
        } else {
            debug("< Empty response");
        }
    }

    # Status
    unless ($response->is_success) {
        debug("Can't fetch %s. %s", $uri->as_string, $response->status_line);
        return $ret;
    }

    # Size
    $ret->{size} = $document_length || 0;

    # Modified time
    $ret->{mtime} = $modified_time // 0;
    unless ($ret->{mtime}) {
        debug("Can't fetch %s. Header 'Last-Modified' not received", $uri->as_string);
        return $ret;
    }

    # Safe file mirroring
    my $temp = sprintf "%s.tmp", $file;
    if (-e $file) {
        unless (mv($file, $temp)) {
            printf STDERR "Can't move file \"%s\" to \"%s\": %s\n", $file, $temp, $!;
            return $ret;
        }
    }

    # Request
    $response = $ua->mirror($uri, $file);
    $ret->{code} = $response->code;;
    $ret->{message} = $response->message;
    if ($self->verbose) {
        debug("> GET %s", $uri->as_string) or say sprintf "> GET %s", $uri->as_string;
        debug("< %s", $response->status_line) or say sprintf "< %s", $response->status_line;
    }
    if ($response->is_success) {
        if (-e $file && (-s $file) == $ret->{size}) {
            $ret->{status} = 1;
            fdelete($temp);
        }
    } else {
        debug("Can't fetch %s. %s", $uri->as_string, $response->status_line);
        return $ret;
    }

    # Move temp file to original name
    if (!$ret->{status} && -e $temp) {
        unless (mv($temp, $file)) {
            printf "Can't move file \"%s\" to \"%s\": %s", $temp, $file, $!;
        }
    }

    return $ret;
}
sub status { # Show statistic information
    my $self = shift;

    # Read MIRRORS file
    my $mirrors_mani = maniread($self->{file_mirrors}) // {}; # MIRRORS
    my @mirrors = sort {$a cmp $b} keys %$mirrors_mani;
    unless (scalar(@mirrors)) {
        say STDERR sprintf "File %s is empty", MIRRORS;
        return;
    }

    # Go!
    foreach my $url (@mirrors) {
        say sprintf "RESOURCE \"%s\"", $url;
        my $self_mode = 0;

        # Downloading the MANIFEST.LOCK file, skipping the mirror resource if this
        # file was successfully downloaded from the resource
        {
            debug("Fetching %s", MANILOCK);
            my $fetch_lock = $self->fetch($url, MANILOCK, $self->{file_manitemp});
            if ($fetch_lock->{status}) { # Ok
                if ($self->_check_lockfile($self->{file_manitemp})) {
                    $self->{url} = $url;
                    $self_mode = 1;
                } else {
                    say STDERR "Remote resource is in a state of updating. Please wait";
                    next;
                }
            }
        }

        # Downloading the META file and analyzing the resource (checking the resource
        # status and update date). If the check fails, the resource is skipped.
        {
            debug("Fetching %s", METAFILE);
            my $meta = $self->fetch($url, METAFILE, $self->{file_manitemp});
            if ($meta->{status}) { # Ok
                my $remote_meta = read_yaml($self->{file_manitemp}) // '';
                if (((ref($remote_meta) eq 'ARRAY') || ref($remote_meta) eq 'YAML::Tiny')) {
                    $remote_meta = $remote_meta->[0] || {};
                }
                unless ($remote_meta && ref($remote_meta) eq 'HASH') {
                    say STDERR "Remote resource is unreadable. Please contact the administrator of this resource";
                    next;
                }
                unless ($remote_meta->{status}) {
                    say STDERR "Remote resource is broken. Please contact the administrator of this resource";
                    next;
                }

                # Show information
                my $remote_url  = $remote_meta->{url} || $remote_meta->{uri} || '';
                my $remote_date = $meta->{mtime} || 0;
                my $remote_datef = $remote_date ? scalar(localtime($remote_date)) : 'UNKNOWN';
                my $remote_ok = (time - $remote_date) > _expire(FREEZE) ? 0 : 1;
                say sprintf "  Resource URL  : %s%s", $remote_url, $self_mode ? " (LOCAL RESOURCE)" : '';
                say sprintf "  Status        : %s", $remote_ok ? "OK" : "EXPIRED";
                say sprintf "  Date          : %s", $remote_meta->{date} // 'UNKNOWN';
                say sprintf "  Modified      : %s", $remote_datef;
                say sprintf "  Hostname      : %s", $remote_meta->{hostname} // '';
                say sprintf "  Directory     : %s", $remote_meta->{directory} // '';
                say sprintf "  Project       : %s v%s", $remote_meta->{project} || ref($self), $remote_meta->{version} // '';
                say sprintf "  Script        : %s", $remote_meta->{script} // $Script;
                say sprintf "  Time          : %d sec", $remote_meta->{'time'} || 0;
                unless ($remote_ok) {
                    say STDERR sprintf "NOTE! The resource is expired. Last updated: %s", $remote_datef;
                    next
                }
            } else {
                printf STDERR "Can't download \"%s\": %s\n", $meta->{url}, $meta->{message};
            }
        }
    }

    return 1;
}
sub mkmani {
    my $self = shift;
    my %skips; # { file => /regexp/|file } List of skipped files

    # Filling the list of exclusion files using the MANIFEST.SKIP file and
    # the list of system files from the SKIPFILES constant
    {
        debug("Getting the list of skipped files");
        my @skip_keys = @{(SKIPFILES)};
        my $maniskip = maniread($self->{file_maniskip}, SKIPMODE); # MANIFEST.SKIP
        push @skip_keys, keys %$maniskip if ref($maniskip) eq 'HASH';
        for (@skip_keys) {$skips{$_} = qrreconstruct($_)}
        debug("Found %d keys in the list of skipped files", scalar(keys %skips));
    }

    # Getting list files from MANIFEST.DEL file but not in the exclusion list
    {
        debug("Getting list files from: %s", MANIDEL);
        my $delfile = $self->{file_manidel};  # MANIFEST.DEL
        my $dellist = maniread($delfile) // {}; # { file => expire };
        #debug(Data::Dumper::Dumper($dellist));

        # Check by exclusion list
        foreach my $k (keys %$dellist) {
            if (_skipcheck(\%skips, $k)) { # The file is in the exclusion list.
                debug("> [SKIPPED] %s", $k);
                next;
            }

            # Adding files listed in MANIFEST.DEL to the exclusion list
            $skips{$k} = qrreconstruct($k);
        }
        #debug(Data::Dumper::Dumper(\%skips));
    }

    # Cteating MANIFEST file
    debug("Generating new manifest");
    my $new_manifest = manifind($self->dir);

    # We select files excluding files listed in the exclusion list
    foreach my $k (keys %$new_manifest) {
        my $nskip = _skipcheck(\%skips, $k);
        delete $new_manifest->{$k} if $nskip;
        debug("> [%s] %s", $nskip ? "SKIPPED" : " ADDED ", $k);
    }
    #debug(Data::Dumper::Dumper($new_manifest));

    # Save the created file
    debug("Saving manifest to %s", MANIFEST);
    return 0 unless maniwrite($self->{file_manifest}, $new_manifest);

    # Ok
    return 1;
}

sub _check_lockfile { # Checking if a file is private
    my $self = shift;
    my $file = shift;
    my $pid = $self->pid;
    return 0 unless $file && -e $file;

    my $fh;
    unless (open($fh, "<", $file)) {
        debug("Can't open file %s to read: %s", $file, $!);
        return 0;
    }

    my $l;
    chomp($l = <$fh>); $l //= "";
    unless (close $fh) {
        debug("Can't close file %s: %s", $file, $!);
        return 0;
    }

    my ($r_pid, $r_stamp, $r_name) = split(/#/, $l);
    return 0 unless $r_pid && ($r_pid =~ /^[0-9]{1,11}$/);
    return 1 if kill(0, $r_pid) && $pid == $r_pid;
    return 0;
}
sub _show_summary {
    my $self = shift;
    my $now = time;
    say "SHORT SUMMARY";
    printf "  Local URL     : %s\n", $self->{url} // 'undefined';
    printf "  Hostname      : %s\n", $self->{hostname};
    printf "  Directory     : %s\n", $self->dir;
    printf "  Insecure mode : %s\n", $self->{insecure} ? 'Yes' : 'No';
    printf "  Proxy         : %s\n", $self->{proxy} || 'none';
    printf "  Started       : %s\n", scalar(localtime($self->{started}));
    printf "  Finished      : %s\n", scalar(localtime($now));
    printf "  Time          : %d sec\n", $now - $self->{started};
    return 1;
}

# Functions
sub _expire { # Parse expiration time
    my $str = shift || 0;

    return 0 unless defined $str;
    return $1 if $str =~ m/^[-+]?(\d+)$/;

    my %_map = (
        s       => 1,
        m       => 60,
        h       => 3600,
        d       => 86400,
        w       => 604800,
        M       => 2592000,
        y       => 31536000
    );

    my ($koef, $d) = $str =~ m/^([+-]?\d+)([smhdwMy])$/;
    unless ( defined($koef) && defined($d) ) {
        carp "expire(): couldn't parse '$str' into \$koef and \$d parts. Possible invalid syntax";
        return 0;
    }
    return $koef * $_map{ $d };
}
sub _skipcheck {
    my $sl = shift; # Link to %skip
    my $st = shift; # Test string
    return 0 unless $sl && defined($st) && ref($sl) eq 'HASH';
    return 1 if exists $sl->{$st} && defined $sl->{$st}; # Catched! - Because a direct match was found

    # Let's run through all the values and look for only regular expressions among them.
    if (grep {(ref($_) eq 'Regexp') && $st =~ $_} values %$sl) {
        # Performance optimization. Such tests would be redundant for the next check.
        $sl->{$st} = 1;

        # Catched!
        return 1;
    }

    return 0; # Not Found
}

1;

__END__
