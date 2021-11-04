#+##############################################################################
#                                                                              #
# File: Config/Generator/File.pm                                               #
#                                                                              #
# Description: Config::Generator file support                                  #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Generator::File;
use strict;
use warnings;
our $VERSION  = "1.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.21 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use No::Worries::Dir qw(dir_ensure dir_parent);
use No::Worries::Export qw(export_control);
use No::Worries::File qw(file_read file_write);
use No::Worries::Log qw(log_debug);
use No::Worries::Proc qw(proc_run);
use No::Worries::Stat qw(ST_MODE ST_UID ST_GID);
use No::Worries::String qw(string_quantify);
use No::Worries::Warn qw(warnf);
use Params::Validate qw(validate_pos :types);
use POSIX qw(:errno_h);
use Config::Generator qw($NoAction $Verbosity $RootDir);

#
# global variables
#

our(%_Registered);

#
# printing helpers
#

sub _printf1 (@) { printf(@_) if $Verbosity >= 1 }
sub _printf2 (@) { printf(@_) if $Verbosity >= 2 }

#
# path absence helper
#

sub _ensure_absent ($) {
    my($path) = @_;
    my($what);

    lstat($path) or return;
    if (-f _) {
        $what = sprintf("file %s", $path);
        if ($NoAction) {
            _printf1("would have removed %s\n", $what);
        } elsif (unlink($path)) {
            _printf1("removed %s\n", $what);
        } else {
            warnf("did not remove %s: %s", $what, $!);
        }
    } elsif (-d _) {
        $what = sprintf("directory %s", $path);
        if ($NoAction) {
            _printf1("would have removed %s\n", $what);
        } elsif (rmdir($path)) {
            _printf1("removed %s\n", $what);
        } else {
            warnf("did not remove %s: %s", $what, $!);
        }
    } else {
        warnf("skipped alien file: %s", $path);
    }
}

#
# directory parent helper
#

sub _ensure_parent ($) {
    my($path) = @_;
    my($parent);

    $parent = $path = dir_parent($path);
    return if -d $parent;
    while (not -d $path) {
        last if $_Registered{$path};
        last if $path eq $RootDir;
        $_Registered{$path} = { type => "parent" };
        $path = dir_parent($path);
    }
    log_debug("making directory %s", $parent);
    dir_ensure($parent);
}

#
# (almost) atomic file write helper
#

sub _atomic_write ($$) {
    my($path, $data) = @_;
    my(@stat, $tmpath);

    $tmpath = $path . ".tmp";
    _unlink($tmpath) if -e $tmpath;
    file_write($tmpath, data => $data);
    @stat = stat($path);
    if (@stat) {
        _chmod($stat[ST_MODE] & oct(7777), $tmpath);
        _chown($stat[ST_UID], $stat[ST_GID], $tmpath);
        _unlink($path);
    }
    rename($tmpath, $path)
        or dief("cannot rename(%s, %s): %s", $tmpath, $path, $!);
}

#
# file contents helper
#

sub _ensure_contents ($$) {
    my($path, $contents) = @_;
    my($what);

    log_debug("checking file %s", $path);
    $what = sprintf("file %s", $path);
    if (-e $path) {
        dief("path exists already and is not a file: %s", $path)
            unless -f _;
        if (file_read($path) eq $contents) {
            _printf2("checked %s\n", $what);
        } else {
            proc_run(
                command => [ "diff", "-u", $path, "-" ],
                stdin   => \$contents,
            ) if $Verbosity;
            if ($NoAction) {
                _printf1("would have updated %s\n", $what);
            } else {
                _atomic_write($path, \$contents);
                _printf1("updated %s\n", $what);
            }
        }
    } else {
        if ($NoAction) {
            _printf1("would have created %s\n", $what);
        } else {
            _ensure_parent($path);
            _atomic_write($path, \$contents);
            _printf1("created %s\n", $what);
        }
    }
}

#
# fatal helpers
#

sub _chmod ($$) {
    my($mode, $path) = @_;

    chmod($mode, $path)
        or dief("cannot chmod(%04o, %s): %s", $mode, $path, $!);
}

sub _chown ($$$) {
    my($uid, $gid, $path) = @_;

    chown($uid, $gid, $path)
        or dief("cannot chown(%d, %d, %s): %s", $uid, $gid, $path, $!);
}

sub _symlink ($$) {
    my($target, $path) = @_;

    symlink($target, $path)
        or dief("cannot symlink(%s, %s): %s", $target, $path, $!);
}

sub _unlink ($) {
    my($path) = @_;

    unlink($path)
        or dief("cannot unlink(%s): %s", $path, $!);
}

#
# ensure directory existence
#

my @ensure_directory_options = (
    { type => SCALAR, regex => qr/^\// },
);

sub ensure_directory ($) {
    my($path) = validate_pos(@_, @ensure_directory_options);
    my($rpath, $what);

    $rpath = $RootDir . $path;
    log_debug("checking directory %s", $rpath);
    dief("duplicate directory: %s", $path) if $_Registered{$path};
    $_Registered{$path} = { type => "directory" };
    $what = sprintf("directory %s", $rpath);
    if (-d $rpath) {
        _printf2("checked %s\n", $what);
    } else {
        dief("path exists already and is not a directory: %s", $rpath)
            if -e _;
        if ($NoAction) {
            _printf1("would have created %s\n", $what);
        } else {
            _ensure_parent($rpath);
            dir_ensure($rpath);
            _printf1("created %s\n", $what);
        }
    }
}

#
# ensure file contents
#

my @ensure_file_options = (
    $ensure_directory_options[0],
    { type => SCALAR },
);

sub ensure_file ($$) {
    my($path, $contents) = validate_pos(@_, @ensure_file_options);

    dief("duplicate file: %s", $path) if $_Registered{$path};
    $_Registered{$path} = { type => "file" };
    _ensure_contents($RootDir . $path, $contents);
}

#
# ensure symlink target
#

my @ensure_symlink_options = (
    $ensure_directory_options[0],
    { type => SCALAR },
);

sub ensure_symlink ($$) {
    my($path, $target) = validate_pos(@_, @ensure_symlink_options);
    my($rpath, $what, @stat, $actual);

    $rpath = $RootDir . $path;
    log_debug("checking symlink %s", $rpath);
    dief("duplicate symlink: %s", $path) if $_Registered{$path};
    $_Registered{$path} = { type => "symlink" };
    $what = sprintf("symlink %s -> %s", $rpath, $target);
    @stat = lstat($rpath);
    if (-e _) {
        dief("path exists already and is not a symlink: %s", $rpath)
            unless -l _;
        $actual = readlink($rpath);
        dief("cannot readlink(%s): %s", $rpath, $!)
            unless defined($actual);
        if ($target eq $actual) {
            _printf2("checked %s\n", $what);
        } else {
            if ($NoAction) {
                _printf1("would have updated %s\n", $what);
            } else {
                _unlink($rpath);
                _symlink($target, $rpath);
                _printf1("updated %s\n", $what);
            }
        }
    } else {
        if ($NoAction) {
            _printf1("would have created %s\n", $what);
        } else {
            _ensure_parent($rpath);
            _symlink($target, $rpath);
            _printf1("created %s\n", $what);
        }
    }
}

#
# ensure file mode
#

my @ensure_mode_options = (
    $ensure_directory_options[0],
    { type => SCALAR, regex => qr/^\d+$/ },
);

sub ensure_mode ($$) {
    my($path, $mode) = validate_pos(@_, @ensure_mode_options);
    my($rpath, $what, @stat);

    $rpath = $RootDir . $path;
    log_debug("checking mode %s", $rpath);
    dief("not a registered file or directory: %s", $path)
        unless $_Registered{$path}
           and $_Registered{$path}{type} =~ /^(file|directory)$/;
    dief("duplicate mode: %s", $path) if $_Registered{$path}{mode};
    $_Registered{$path}{mode} = sprintf("%04o", $mode);
    dief("invalid mode: %s", $_Registered{$path}{mode})
        unless 0 < $mode and $mode <= oct(7777);
    $what = sprintf("the mode of %s: %s", $rpath, $_Registered{$path}{mode});
    @stat = stat($rpath);
    unless (@stat) {
        dief("cannot stat(%s): %s", $rpath, $!)
            unless $NoAction and $! == ENOENT;
        _printf2("would have checked %s (but it does no exist yet)\n", $what);
        return;
    }
    if (($stat[ST_MODE] & oct(7777)) == $mode) {
        _printf2("checked %s\n", $what);
    } elsif ($> and $_Registered{$path}{type} eq "directory") {
        # we should not change a directory mode if we are not root
        # (we could shoot ourself in the foot with a read-only directory)
        _printf2("would have changed %s (but we are not root)\n", $what);
    } else {
        if ($NoAction) {
            _printf1("would have changed %s\n", $what);
        } else {
            _chmod($mode, $rpath);
            _printf1("changed %s\n", $what);
        }
    }
}

#
# ensure file user
#

my @ensure_user_options = (
    $ensure_directory_options[0],
    { type => SCALAR },
);

sub ensure_user ($$) {
    my($path, $user) = validate_pos(@_, @ensure_user_options);
    my($rpath, $what, $uid, @stat);

    $rpath = $RootDir . $path;
    log_debug("checking user %s", $rpath);
    dief("not a registered file or directory: %s", $path)
        unless $_Registered{$path}
           and $_Registered{$path}{type} =~ /^(file|directory)$/;
    dief("duplicate user: %s", $path) if $_Registered{$path}{user};
    $_Registered{$path}{user} = $user;
    $what = sprintf("the user of %s: %s", $rpath, $_Registered{$path}{user});
    if ($>) {
        # we do not change the user if we are not root
        # (and we stop immediately since the user may not even exist)
        _printf2("would have checked %s (but we are not root)\n", $what);
        return;
    }
    $uid = getpwnam($user);
    dief("unknown user: %s", $user) unless defined($uid);
    @stat = stat($rpath);
    unless (@stat) {
        dief("cannot stat(%s): %s", $rpath, $!)
            unless $NoAction and $! == ENOENT;
        _printf2("would have checked %s (but it does no exist yet)\n", $what);
        return;
    }
    if ($stat[ST_UID] == $uid) {
        _printf2("checked %s\n", $what);
    } else {
        if ($NoAction) {
            _printf1("would have changed %s\n", $what);
        } else {
            _chown($uid, $stat[ST_GID], $rpath);
            _printf1("changed %s\n", $what);
        }
    }
}

#
# ensure file group
#

my @ensure_group_options = (
    $ensure_directory_options[0],
    { type => SCALAR },
);

sub ensure_group ($$) {
    my($path, $group) = validate_pos(@_, @ensure_group_options);
    my($rpath, $what, $gid, @stat);

    $rpath = $RootDir . $path;
    log_debug("checking group %s", $rpath);
    dief("not a registered file or directory: %s", $path)
        unless $_Registered{$path}
           and $_Registered{$path}{type} =~ /^(file|directory)$/;
    dief("duplicate group: %s", $path) if $_Registered{$path}{group};
    $_Registered{$path}{group} = $group;
    $what = sprintf("the group of %s: %s", $rpath, $_Registered{$path}{group});
    if ($>) {
        # we do not change the group if we are not root
        # (and we stop immediately since the group may not even exist)
        _printf2("would have checked %s (but we are not root)\n", $what);
        return;
    }
    $gid = getgrnam($group);
    dief("unknown group: %s", $group) unless defined($gid);
    @stat = stat($rpath);
    unless (@stat) {
        dief("cannot stat(%s): %s", $rpath, $!)
            unless $NoAction and $! == ENOENT;
        _printf2("would have checked %s (but it does no exist yet)\n", $what);
        return;
    }
    if ($stat[ST_GID] == $gid) {
        _printf2("checked %s\n", $what);
    } else {
        if ($NoAction) {
            _printf1("would have changed %s\n", $what);
        } else {
            _chown($stat[ST_UID], $gid, $rpath);
            _printf1("changed %s\n", $what);
        }
    }
}

#
# return the list of registered files (paths only)
#

sub files_manifest () {
    my(@lines);

    @lines = sort(keys(%_Registered));
    return(@lines) if wantarray();
    return(join("", map("$_\n", @lines)));
}

#
# return the list of registered files (rpm spec %files format)
#
# note: this assumes an initial "%defattr(-,root,root,-)" line
#

sub files_spec () {
    my(%defattr, @lines, @list, $mode, $user, $group);

    %defattr = (
        mode  => "-",
        user  => "root",
        group => "root",
    );
    foreach my $path (sort(keys(%_Registered))) {
        @list = ();
        $mode  = $_Registered{$path}{mode}  || $defattr{mode};
        $user  = $_Registered{$path}{user}  || $defattr{user};
        $group = $_Registered{$path}{group} || $defattr{group};
        push(@list, "%attr($mode, $user, $group)")
            if $mode  ne $defattr{mode}
            or $user  ne $defattr{user}
            or $group ne $defattr{group};
        push(@list, "%dir") if $_Registered{$path}{type} eq "directory";
        push(@list, $path);
        push(@lines, "@list");
    }
    return(@lines) if wantarray();
    return(join("", map("$_\n", @lines)));
}

#
# handle a manifest file
#

my @handle_manifest_options = (
    { type => SCALAR },
    { type => BOOLEAN },
);

sub handle_manifest ($$) {
    my($manifest, $clean) = validate_pos(@_, @handle_manifest_options);
    my($keep, %tokeep, %toclean, @list);

    if ($clean) {
        if (-e $manifest) {
            # we keep from the old manifest registered files and their parents
            foreach my $path (keys(%_Registered)) {
                $keep = $path;
                while ($keep ne "/") {
                    $tokeep{$keep}++;
                    $keep = dir_parent($keep);
                }
            }
            log_debug("loading manifest %s...", $manifest);
            foreach my $path (split(/\n/, file_read($manifest))) {
                $_Registered{$path} = { type => "parent" }
                    if $tokeep{$path} and not $_Registered{$path};
                $toclean{$path}++ unless $tokeep{$path};
            }
        }
        @list = sort({ length($b) <=> length($a) } keys(%toclean));
        log_debug("found %s to clean", string_quantify(scalar(@list), "path"));
        foreach my $path (@list) {
            _ensure_absent($RootDir . $path);
        }
    }
    _ensure_contents($manifest, scalar(files_manifest()));
}

#
# handle a spec file
#

my @handle_spec_options = (
    { type => SCALAR },
);

sub handle_spec ($) {
    my($spec) = validate_pos(@_, @handle_spec_options);

    _ensure_contents($spec, scalar(files_spec()));
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{"ensure_${_}"}++,
         qw(directory file symlink mode user group));
    grep($exported{"files_${_}"}++, qw(manifest spec));
    grep($exported{"handle_${_}"}++, qw(manifest spec));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

Config::Generator::File - Config::Generator file support

=head1 DESCRIPTION

This module eases the manipulation of files, directories and symbolic links.

The goal is to perform B<all> the file related operations through this module
so that there is a consistent handling of the L<Config::Generator> variables:
C<$NoAction>, C<$RootDir> and C<$Verbosity>.

In addition, rpm compatible spec files snippets can be generated and the
B<yacg> command can use a "manifest" file to record which files it did
create. This is required in order to be able to "clean out the junk", see
B<yacg>'s B<--clean> option.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item ensure_directory(PATH)

make sure the given PATH is a directory

=item ensure_file(PATH, CONTENTS)

make sure the given PATH is a file with the given CONTENTS

=item ensure_symlink(PATH, TARGET)

make sure the given PATH is a symbolic link with the given TARGET

=item ensure_mode(PATH, MODE)

make sure the given PATH has the given numerical MODE

=item ensure_user(PATH, USER)

make sure the given PATH is owned by the given USER

=item ensure_group(PATH, GROUP)

make sure the given PATH is owned by the given GROUP

=item files_manifest()

return the list of all the files that have been manipulated by this module

=item files_spec()

return the list of all the files that have been manipulated by this module, in
a format compatible with rpm's spec %files

=item handle_manifest(PATH, CLEAN)

write the list of all the files that have been manipulated by this module in a
"manifest" file at the given PATH; if CLEAN is true, also remove all the files
and directories that were in the previous manifest and are not present anymore

=item handle_spec(PATH)

write the list of all the files that have been manipulated by this module in a
"spec" file at the given PATH

=back

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2013-2016
