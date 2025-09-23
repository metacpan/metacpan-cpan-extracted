package App::GitUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Cwd qw(getcwd abs_path);
use File::chdir;
use IPC::System::Options 'system', -log=>1, -die=>1;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-09-23'; # DATE
our $DIST = 'App-GitUtils'; # DIST
our $VERSION = '0.089'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Some additional command-line utilities for git',
};

our %argspecopt_dir = (
    dir => {
        summary => 'A directory inside git repo',
        schema => 'dirname*',
        description => <<'MARKDOWN',

If not specified, will assume current directory is inside git repository and
will search `.git` upwards.

MARKDOWN
    },
);

our %argspec_target_dir = (
    target_dir => {
        summary => 'Target repo directory',
        schema => 'dirname*',
        description => <<'MARKDOWN',

If not specified, defaults to `$repodir.bare/`.

MARKDOWN
    },
);

our $_complete_hook = sub {
    my %args = @_;

    my $word = $args{word} // '';
    my $res = list_hooks();
    return [] unless $res->[0] == 200;
    return $res->[2];
};

sub _search_git_dir {
    my $args = shift;

    my $orig_wd = getcwd;

    my $cwd;
    if (defined $args->{dir}) {
        $cwd = $args->{dir};
    } else {
        $cwd = $orig_wd;
    }

    my $res;
    while (1) {
        log_trace "Checking for .git/ in $cwd ..." if $ENV{GITUTILS_TRACE};
        do { $res = "$cwd/.git"; last } if -d "$cwd/.git";
        chdir ".." or goto EXIT;
        $cwd =~ s!(.+)/.+!$1! or last;
    }

  EXIT:
    chdir $orig_wd;
    return $res;
}

$SPEC{get_git_dir} = {
    v => 1.1,
    summary => 'Get the path to the .git directory',
    description => <<'MARKDOWN',

Basically just the C<git_dir> information from `gu info`. Useful in shell
scripts.

MARKDOWN
    args => {
        %argspecopt_dir,
    },
    deps => {
        prog => {name=>'git', min_version=>'2.22.0'}, # for --show-current option
    },
    tags => [
        'find-dotgit-dir', # we accept 'dir' arg for these
    ],
};
sub get_git_dir {
    my %args = @_;

    my $git_dir = _search_git_dir(\%args);
    return [412, "Can't find .git dir, make sure ".($args{dir} // "the current directory")." is a git repo"]
        unless defined $git_dir;

    [200, "OK", $git_dir];
}

$SPEC{info} = {
    v => 1.1,
    summary => 'Return information about git repository',
    description => <<'MARKDOWN',

Information include:

- Path of the git directory
- Repository name
- Current/active branch

Will return status 412 if working directory is not inside a git repository. Will
return status 500 on errors, e.g. if `git` command cannot recognize the
repository.

MARKDOWN
    args => {
        %argspecopt_dir,
    },
    deps => {
        prog => {name=>'git', min_version=>'2.22.0'}, # for --show-current option
    },
    tags => [
        'find-dotgit-dir', # we accept 'dir' arg for these
    ],
};
sub info {
    my %args = @_;

    my $git_dir = _search_git_dir(\%args);
    return [412, "Can't find .git dir, make sure ".($args{dir} // "the current directory")." is a git repo"]
        unless defined $git_dir;

    my ($repo_name) = $git_dir =~ m!(?:.+/)?([^/]+)/\.git\z!
        or return [500, "Can't extract repo name from git dir '$git_dir'"];

    local $CWD = $git_dir;
    my $current_branch = `git branch --show-current`;
    return [500, "Can't execute git to find out current branch: $!"] if $?;
    chomp $current_branch;

    [200, "OK", {
        git_dir => $git_dir,
        repo_name => $repo_name,
        current_branch => $current_branch,
        # more information in the future
    }];
}

$SPEC{list_hooks} = {
    v => 1.1,
    summary => 'List available hooks for the repository',
    args => {
        %argspecopt_dir,
    },
    deps => {
        prog => 'git',
    },
    tags => [
        'find-dotgit-dir', # we accept 'dir' arg for these
    ],
};
sub list_hooks {
    my %args = @_;

    my $git_dir = _search_git_dir(\%args);
    return [412, "Can't find .git dir, make sure you're inside a git repo"]
        unless defined $git_dir;

    my $hooks_dir = "$git_dir/hooks";
    opendir my($dh), $hooks_dir;
    my @res;
    for (sort readdir $dh) {
        next if /\.sample\z/; # skip sample names
        next unless -f "$hooks_dir/$_" && -x _;
        push @res, $_;
    }
    [200, "OK", \@res];
}

$SPEC{run_hook} = {
    v => 1.1,
    summary => 'Run a hook',
    description => <<'MARKDOWN',

Basically the same as:

    % .git/hooks/<hook-name>

except can be done anywhere inside git repo and provides tab completion.

MARKDOWN
    args => {
        %argspecopt_dir,
        name => {
            summary => 'Hook name, e.g. post-commit',
            schema => ['str*', match => '\A[A-Za-z0-9-]+\z'],
            req => 1,
            pos => 0,
            completion => $_complete_hook,
        },
    },
    deps => {
        prog => 'git',
    },
    tags => [
        'find-dotgit-dir', # we accept 'dir' arg for these
    ],
};
sub run_hook {
    my %args = @_;

    my $git_dir = _search_git_dir(\%args);
    return [412, "Can't find .git dir, make sure you're inside a git repo"]
        unless defined $git_dir;

    my $name = $args{name};

    (-x "$git_dir/hooks/$name") or
        return [400, "Unknown or non-executable git hook: $name"];

    local $CWD = "$git_dir/..";
    exec ".git/hooks/$name";
    #[200]; # unreached
}

$SPEC{post_commit} = {
    v => 1.1,
    summary => 'Run post-commit hook',
    description => <<'MARKDOWN',

Basically the same as:

    % .git/hooks/post-commit

except can be done anywhere inside git repo.

MARKDOWN
    args => {
        %argspecopt_dir,
    },
    tags => [
        'find-dotgit-dir', # we accept 'dir' arg for these
    ],
};
sub post_commit {
    run_hook(name => 'post-commit');
}

$SPEC{pre_commit} = {
    v => 1.1,
    summary => 'Run pre-commit hook',
    description => <<'MARKDOWN',

Basically the same as:

    % .git/hooks/pre-commit

except can be done anywhere inside git repo.

MARKDOWN
    args => {
        %argspecopt_dir,
    },
    tags => [
        'find-dotgit-dir', # we accept 'dir' arg for these
    ],
};
sub pre_commit {
    run_hook(name => 'pre-commit');
}

$SPEC{clone_to_bare} = {
    v => 1.1,
    summary => 'Clone repository to a bare repository',
    args => {
        %argspecopt_dir,
        %argspec_target_dir,
    },
    tags => [
        'find-dotgit-dir', # we accept 'dir' arg for these
    ],
};
sub clone_to_bare {
    require IPC::System::Options;

    my %args = @_;

    my $res = info(%args);
    return $res unless $res->[0] == 200;

    my $src_dir = "$res->[2]{git_dir}/..";
    my $target_dir = abs_path($args{target_dir} // "$src_dir/../$res->[2]{repo_name}.bare");
    (-d $target_dir) and return [412, "Target dir '$target_dir' already exists"];
    (-e $target_dir) and return [412, "Target '$target_dir' already exists but not a dir"];

    mkdir $target_dir, 0755 or return [500, "Can't mkdir target dir '$target_dir': $!"];
    IPC::System::Options::system(
        {log=>1, die=>1},
        "git", "init", "--bare", $target_dir,
    );

    local $CWD = $src_dir;
    IPC::System::Options::system(
        {log=>1, die=>1},
        "git", "push", "--all", $target_dir,
    );
    [200];
}

$SPEC{status} = {
    v => 1.1,
    summary => 'Run `git status` and return information as a data structure',
    description => <<'MARKDOWN',

Currently incomplete!

MARKDOWN
    args => {
    },
};
sub status {
    require IPC::System::Options;

    my %args = @_;

    my $stdout;
    IPC::System::Options::system(
        {log=>1, die=>1, capture_stdout => \$stdout},
        "git", "status",
    );

    my $res = [200, "OK", {}];
    $stdout =~ /^On branch (.+)/ or do {
        log_warn "Can't extract branch name";
    };
    $res->[2]{branch} = $1;
    my @stdout_lines = split /^/m, $stdout;

    LIST_STAGED:
    {
        my $in_staged;
        my (@new_files, @modified, @deleted);
        for my $line (@stdout_lines) {
            if (!$in_staged) {
                if ($line =~ /^Changes to be committed:/) {
                    $in_staged = 1;
                    next;
                }
            } elsif ($in_staged == 1) {
                if ($line =~ /^\S/) {
                    $in_staged = 2;
                    next;
                } elsif (my ($op, $path) = $line =~ /^\s+(new file:|modified:|deleted: )\s\s\s(.+)\R/) {
                    if ($op eq 'new file:') {
                        push @new_files, $path;
                    } elsif ($op eq 'modified:') {
                        push @modified, $path;
                    } elsif ($op eq 'deleted: ') {
                        push @deleted, $path;
                    }
                }
            } else {
                last;
            }
        }
        $res->[2]{staged} = {
            new_files => \@new_files,
            modified => \@modified,
            deleted => \@deleted,
        };
    } # LIST_STAGED

    LIST_UNSTAGED:
    {
        my $in_unstaged;
        my (@new_files, @modified, @deleted);
        for my $line (@stdout_lines) {
            if (!$in_unstaged) {
                if ($line =~ /^Changes not staged for commit:/) {
                    $in_unstaged = 1;
                    next;
                }
            } elsif ($in_unstaged == 1) {
                if ($line =~ /^\S/) {
                    $in_unstaged = 2;
                    next;
                } elsif (my ($op, $path) = $line =~ /^\s+(new file:|modified:|deleted: )\s\s\s(.+)\R/) {
                    if ($op eq 'new file:') {
                        push @new_files, $path;
                    } elsif ($op eq 'modified:') {
                        push @modified, $path;
                    } elsif ($op eq 'deleted: ') {
                        push @deleted, $path;
                    }
                }
            } else {
                last;
            }
        }
        $res->[2]{unstaged} = {
            new_files => \@new_files,
            modified => \@modified,
            deleted => \@deleted,
        };
    } # LIST_UNSTAGED

    LIST_UNTRACKED:
    {
        my $in_untracked;
        my (@paths);
        for my $line (@stdout_lines) {
            if (!$in_untracked) {
                if ($line =~ /^Untracked files:/) {
                    $in_untracked = 1;
                    next;
                }
            } elsif ($in_untracked == 1) {
                if ($line =~ /^\S/) {
                    $in_untracked = 2;
                    next;
                } elsif (my ($path) = $line =~ /^\t(.+)\R/) {
                    push @paths, $path;
                }
            } else {
                last;
            }
        }
        $res->[2]{untracked} = \@paths;
    } # LIST_UNTRACKED

    $res;
}

$SPEC{list_committing_large_files} = {
    v => 1.1,
    summary => 'Check that added/modified files in staged/unstaged do not exceed a certain size',
    description => <<'MARKDOWN',

Will return an enveloped result with payload true containing added/modified
files in staged/unstaged that are larger than a certain specified `max_size`.

To be used in a pre-commit script, for example.

Some applications: Github for example warns when a file is above 50MB and
rejects when a file is above 100MB in size.

MARKDOWN
    args => {
        max_size => {
            schema => 'datasize*',
            default => 100*1024*1024 - 1*1024, # safe margin
            pos => 0,
            cmdline_aliases => {s=>{}},
        },
    },
};
sub list_committing_large_files {
    my %args = @_;
    my $max_size = $args{max_size} or return [400, "Please specify max_size"];

    my $res = status();
    return $res unless $res->[0] == 200;

    my @files;
    for my $file (
        @{ $res->[2]{staged}{new_files} },
        @{ $res->[2]{staged}{modified} },
        @{ $res->[2]{unstaged}{new_files} },
        @{ $res->[2]{unstaged}{modified} },
    ) {
        my $size = -s $file;
        push @files, $file if $size > $max_size;
    }
    [200, "OK", \@files];
}

sub _calc_totsize_recurse {
    require File::Find;

    my $path = shift;
    my $totsize = 0;

    File::Find::find(
        sub {
            unless (-d $_) {
                $totsize += -s $_;
            }
        },
        $path,
    );
    $totsize;
}

$SPEC{calc_untracked_total_size} = {
    v => 1.1,
    summary => 'Check the disk usage of untracked files',
    description => <<'MARKDOWN',

This routine basically just grabs the list of untracked files returned by
`status()` (`gu status`) then checks their disk usage and totals them. CAVEAT:
currently, if an untracked file is a directory, then this routine will just
count the disk usage of the content of the directory recursively /without/
considering ignored files. Correcting this is in the todo list.

MARKDOWN
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub calc_untracked_total_size {
    my %args = @_;

    my $res = status();
    return $res unless $res->[0] == 200;

    my $totsize = 0;
    my @sizes;
    for my $file (@{ $res->[2]{untracked} }) {
        my $size;
        if ($file =~ m!/\z!) {
            $size += _calc_totsize_recurse($file);
        } else {
            $size += -s $file;
        }
        $totsize += $size;
        if ($args{detail}) {
            push @sizes, [$file, $size];
        }
    }

    [200, "OK", $args{detail} ? \@sizes : $totsize];
}

$SPEC{calc_committing_total_size} = {
    v => 1.1,
    summary => 'Calculate the total sizes of files to add/delete/modify',
    description => <<'MARKDOWN',

To be used in pre-commit script, for example.

Some applications: Github limits commit total size to 2GB.

MARKDOWN
    args => {
        include_untracked => {
            schema => 'bool*',
            default => 1,
        },
    },
};
sub calc_committing_total_size {
    my %args = @_;
    my $include_untracked = $args{include_untracked} // 1;

    my $res = status();
    return $res unless $res->[0] == 200;

    # TODO: calculate deleted

    my $totsize = 0;
    for my $file (
        @{ $res->[2]{staged}{new_files} },
        @{ $res->[2]{staged}{modified} },
        @{ $res->[2]{unstaged}{new_files} },
        @{ $res->[2]{unstaged}{modified} },
    ) {
        my $size = -s $file;
        $totsize += $size;
    }

    if ($include_untracked) {
        for my $file (@{ $res->[2]{untracked} }) {
            if ($file =~ m!/\z!) {
                $totsize += _calc_totsize_recurse($file);
            } else {
                $totsize += -s $file;
            }
        }
    }

    [200, "OK", $totsize];
}

$SPEC{split_commit_add_untracked} = {
    v => 1.1,
    summary => 'Commit untracked files, possibly over several commits, keeping commit size under certain limit',
    description => <<'MARKDOWN',


MARKDOWN
    args => {
        max_size => {
            schema => 'datasize*',
            default => 2*1024*1024*1024 - 1*1024*1024, # 1MB safe margin
            pos => 0,
            cmdline_aliases => {s=>{}},
        },
    },
    features => {
        dry_run => 1,
    },
};
sub split_commit_add_untracked {
    my %args = @_;
    my $max_size = $args{max_size} // 2*1024*1024*1024 - 1*1024*1024;

    my $res_status = status();
    return [500, "Can't status(): $res_status->[0] - $res_status->[1]"]
        unless $res_status->[0] == 200;

    return [304, "Nothing to commit"]
        unless @{ $res_status->[2]{untracked} };
    return [409, "Please make we are not committing anything yet"]
        if (
            @{ $res_status->[2]{staged}{deleted} } ||
            @{ $res_status->[2]{staged}{modified} } ||
            @{ $res_status->[2]{staged}{new_files} } ||
            @{ $res_status->[2]{unstaged}{deleted} } ||
            @{ $res_status->[2]{unstaged}{modified} } ||
            @{ $res_status->[2]{unstaged}{new_files} }
        );

    my @items;
    for my $file (@{ $res_status->[2]{untracked} }) {
        my $size;
        if ($file =~ m!/\z!) {
            $size = _calc_totsize_recurse($file);
        } else {
            $size = -s $file;
        }
        if ($size > $max_size) {
            return [412, "One file is larger than max_size ($max_size): $file ($size)"];
        }
        push @items, [$file, $size];
    }

    require App::BinPackUtils;
    my $res_pack = App::BinPackUtils::pack_bins(
        bin_size => $max_size,
        items => \@items,
    );
    return [500, "Can't pack_bins(): $res_pack->[0] - $res_pack->[1]"]
        unless $res_pack->[0] == 200;

    # TODO: split 'git add' if there are many files
    my $i = 0;
    my $num_bins = @{ $res_pack->[2] };
    for my $bin (@{ $res_pack->[2] }) {
        $i++;
        my @files;
        for my $item (@{ $bin->{items} }) {
            push @files, $item->{label};
        }
        system("git", "add", @files);

        # TODO: let user customize commit message
        system("git", "commit", "-m", "Commited by gu split-commit-add-untracked #$i/$num_bins");
    }
    [200, "OK"];
}


1;
# ABSTRACT: Some additional command-line utilities for git

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitUtils - Some additional command-line utilities for git

=head1 VERSION

This document describes version 0.089 of App::GitUtils (from Perl distribution App-GitUtils), released on 2025-09-23.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<gu>

=item * L<this-repo>

=back

These utilities provide some shortcuts and tab completion to make it more
convenient when working with git con the command-line.

=head1 FUNCTIONS


=head2 calc_committing_total_size

Usage:

 calc_committing_total_size(%args) -> [$status_code, $reason, $payload, \%result_meta]

Calculate the total sizes of files to addE<sol>deleteE<sol>modify.

To be used in pre-commit script, for example.

Some applications: Github limits commit total size to 2GB.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<include_untracked> => I<bool> (default: 1)

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 calc_untracked_total_size

Usage:

 calc_untracked_total_size(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check the disk usage of untracked files.

This routine basically just grabs the list of untracked files returned by
C<status()> (C<gu status>) then checks their disk usage and totals them. CAVEAT:
currently, if an untracked file is a directory, then this routine will just
count the disk usage of the content of the directory recursively /without/
considering ignored files. Correcting this is in the todo list.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 clone_to_bare

Usage:

 clone_to_bare(%args) -> [$status_code, $reason, $payload, \%result_meta]

Clone repository to a bare repository.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.

=item * B<target_dir> => I<dirname>

Target repo directory.

If not specified, defaults to C<$repodir.bare/>.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_git_dir

Usage:

 get_git_dir(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get the path to the .git directory.

Basically just the C<git_dir> information from C<gu info>. Useful in shell
scripts.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 info

Usage:

 info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return information about git repository.

Information include:

=over

=item * Path of the git directory

=item * Repository name

=item * Current/active branch

=back

Will return status 412 if working directory is not inside a git repository. Will
return status 500 on errors, e.g. if C<git> command cannot recognize the
repository.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_committing_large_files

Usage:

 list_committing_large_files(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that addedE<sol>modified files in stagedE<sol>unstaged do not exceed a certain size.

Will return an enveloped result with payload true containing added/modified
files in staged/unstaged that are larger than a certain specified C<max_size>.

To be used in a pre-commit script, for example.

Some applications: Github for example warns when a file is above 50MB and
rejects when a file is above 100MB in size.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<max_size> => I<datasize> (default: 104856576)

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_hooks

Usage:

 list_hooks(%args) -> [$status_code, $reason, $payload, \%result_meta]

List available hooks for the repository.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 post_commit

Usage:

 post_commit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Run post-commit hook.

Basically the same as:

 % .git/hooks/post-commit

except can be done anywhere inside git repo.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pre_commit

Usage:

 pre_commit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Run pre-commit hook.

Basically the same as:

 % .git/hooks/pre-commit

except can be done anywhere inside git repo.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 run_hook

Usage:

 run_hook(%args) -> [$status_code, $reason, $payload, \%result_meta]

Run a hook.

Basically the same as:

 % .git/hooks/<hook-name>

except can be done anywhere inside git repo and provides tab completion.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.

=item * B<name>* => I<str>

Hook name, e.g. post-commit.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 split_commit_add_untracked

Usage:

 split_commit_add_untracked(%args) -> [$status_code, $reason, $payload, \%result_meta]

Commit untracked files, possibly over several commits, keeping commit size under certain limit.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<max_size> => I<datasize> (default: 2146435072)

(No description)


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



=head2 status

Usage:

 status() -> [$status_code, $reason, $payload, \%result_meta]

Run `git status` and return information as a data structure.

Currently incomplete!

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 ENVIRONMENT

=head2 GITUTILS_TRACE

Boolean. If set to true, will produce additional log statements using
L<Log::ger> at the trace level.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GitUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GitUtils>.

=head1 SEE ALSO

L<App::GitHubUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GitUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
