package App::Multigit;

use 5.014;
use strict;
use warnings FATAL => 'all';

use List::UtilsBy qw(sort_by);
use Capture::Tiny qw(capture);
use File::Find::Rule;
use Future::Utils qw(fmap);
use Path::Class;
use Config::INI::Reader;
use Config::INI::Writer;
use IPC::Run;
use Try::Tiny;

use App::Multigit::Future;
use App::Multigit::Repo;
use App::Multigit::Loop qw(loop);

use Exporter 'import';

our @EXPORT_OK = qw/
    mgconfig mg_parent
    all_repositories selected_repositories
    base_branch set_base_branch mg_each
    write_config
/;

=head1 NAME

App::Multigit - Run commands on a bunch of git repositories without having to
deal with git subrepositories.

=cut

our $VERSION = '0.18';

=head1 PACKAGE VARS

=head2 %BEHAVIOUR

This holds configuration set by options passed to the C<mg> script itself.

Observe that C<mg [options] command [command-options]> will pass C<options> to
C<mg>, and C<command-options> to C<mg-command>. It is those C<options> that will
affect C<%BEHAVIOUR>.

Scripts may also therefore change C<%BEHAVIOUR> themselves, but it is probably
badly behaved to do so.

=head3 report_on_no_output

Defaults to true; this should be used by scripts to determine whether to bother
mentioning repositories that gave no output at all for the given task. If you
use C<App::Multigit::Repo::report>, this will be honoured by default.

Controlled by the C<MG_REPORT_ON_NO_OUTPUT> environment variable.

=head3 ignore_stdout

=head3 ignore_stderr

These default to false, and will black-hole these streams wherever we have
control to do so.

Controlled by the C<MG_IGNORE_{STDOUT,STDERR}> environment variables.

=head3 concurrent_processes

Number of processes to run in parallel. Defaults to 20.

Controlled by the C<MG_CONCURRENT_PROCESSES> environment variable.

=head3 skip_readonly

Do nothing to repositories that have C<readonly = 1> set in C<.mgconfig>.

Controlled by the C<MG_SKIP_READONLY> environment variable.

=cut

our %BEHAVIOUR = (
    report_on_no_output => $ENV{MG_REPORT_ON_NO_OUTPUT} // 1,
    ignore_stdout       => !!$ENV{MG_IGNORE_STDOUT},
    ignore_stderr       => !!$ENV{MG_IGNORE_STDERR},
    concurrent          => $ENV{MG_CONCURRENT_PROCESSES} // 20,
    skip_readonly       => !!$ENV{MG_SKIP_READONLY},
    output_only         => !!$ENV{MG_OUTPUT_ONLY},
);

=head2 @SELECTED_REPOS

If this is not empty, it should contain paths to repositories. Relative paths
will be determined relative to L<C<<mg_root>>|/mg_root>.

Instead of using the C<.mgconfig>, the directories in here will be used as the
list of repositories on which to work.

Each repository's C<origin> remote will be interrogated. If this exists in the
C<.mgconfig> then it will be used as normal; otherwise, it will be treated as
though it had the default configuration.

=cut

our @SELECTED_REPOS;

=head1 FUNCTIONS

These are not currently exported.

=head2 mgconfig

Returns C<.mgconfig>. This is a stub to be later configurable, but also
to stop me typoing it all the time.

=cut

sub mgconfig() {
    return '.mgconfig';
}

=head2 mg_parent

Tries to find the closest directory with an C<mgconfig> in it. Dies if there is
no mgconfig here. Optionally accepts the directory to start with.

=cut

sub mg_parent {
    my $pwd;
    if (@_) {
        $pwd = dir(shift);
    }
    else {
        $pwd = dir;
    }
    $pwd = $pwd->absolute;

    PARENT: {
        do {
            return $pwd if -e $pwd->file(mgconfig);
            last PARENT if $pwd eq $pwd->parent;
        }
        while ($pwd = $pwd->parent);
    }

    die "Could not find .mgconfig in any parent directory";
}

=head2 all_repositories

Returns a hashref of all repositories under C<mg_parent>.

The keys are the repository directories relative to C<mg_parent>, and the values
are the hashrefs from the config, if any.

=cut

sub all_repositories {
    my $pwd = shift // dir->absolute;
    my $mg_parent = mg_parent $pwd;

    my $cfg = Config::INI::Reader->read_file($mg_parent->file(mgconfig));

    for (keys %$cfg) {
        $cfg->{$_}->{dir} //= dir($_)->basename =~ s/\.git$//r;
        $cfg->{$_}->{url} //= $_;
    }

    return $cfg;
}

=head2 selected_repositories

This returns the repository configuration as determined by
L<C<<@SELECTED_REPOS>>|/@SELECTED_REPOS>. Directories that exist in the main
config (L<all_repositories>) will have their configuration honoured, but unknown
directories will have default configuration.

=cut

sub selected_repositories {
    my $all_repositories = all_repositories;

    return $all_repositories unless @SELECTED_REPOS;

    my $bydir = +{ map {$_->{dir} => $_} values %$all_repositories };

    my $selected_repos = {};

    my $parent = mg_parent;

    for my $dir (@SELECTED_REPOS) {
        # Allow people to not have to worry about extracting blanks
        next if not $dir;

        $dir = dir($dir)->relative($parent);
        if (exists $bydir->{$dir}) {
            $selected_repos->{ $bydir->{$dir}->{url} } = $bydir->{$dir};
        }
        else {
            my $url =
                try {
                    _sensible_remote_url($dir);
                }
                catch {
                    warn $_;
                }
            or next;

            $selected_repos->{ $url } = {
                url => $url,
                dir => $dir,
            }
        }
    }

    return $selected_repos;
}

=head2 each($command[, $ia_config])

For each configured repository, C<$command> will be run. Each command is run in
a separate process which C<chdir>s into the repository first. Optionally, the
C<$ia_config> hashref may be provided; this will be passed to
L<App::Multigit::Repo/run>.

It returns a convergent L<App::Multigit::Future> that represents all tasks. When
this Future completes, all tasks are complete.

=head4 Subref form

The most useful form is the subref form. The subref must return a Future; when
this Future completes, that repository's operations are done.

The convergent Future (C<$future> below) completes when all component Futures
(the return value of C<then>, below) have completed. Thus the script blocks at
the C<< $future->get >> until all repositories have reported completion.

    use curry;
    my $future = App::Multigit::each(sub {
        my $repo = shift;
        $repo
            ->run(\&do_a_thing)
            ->then($repo->curry::run(\&do_another_thing))
        ;
    });

    my @results = $future->get;

See C<examples/mg-branch> for a simple implementation of this.

The Future can complete with whatever you like, but be aware that C<run> returns
a hash-shaped list; see the docs for
L<run|App::Multigit::Repo/"run($command, [%data])">. This means it is often
useful for the very last thing in your subref to be a transformation - something
that extracts data from the C<%data> hash and turns it into a usefully-shaped
list.

The example C<examples/mg-closes> does this, whereas C<examples/mg-branch> uses
C<report>.

L<report|App::Multigit::Repo/"report(%data)"> in App::Multigit::Repo implements
a sensible directory-plus-output transformation for common usage.

    use curry;
    my $future = App::Multigit::each(sub {
        my $repo = shift;
        $repo
            ->run(\&do_a_thing)
            ->then($repo->curry::run(\&do_another_thing))
            ->then($repo->curry::report)
        ;
    });

The subref given to C<run> is passed the C<%data> hash from the previous
command. C<%data> is pre-prepared with blank values, so you don't have to check
for definedness to avoid warnings, keeping your subrefs nice and clean.

    sub do_a_thing {
        my ($repo_obj, %data) = @_;
        ...
    }

Thus you can chain them in any order.

    use curry;
    my $future = App::Multigit::each(sub {
        my $repo = shift;
        $repo
            ->run(\&do_another_thing)
            ->then($repo->curry::run(\&do_a_thing))
            ->then($repo->curry::report)
        ;
    });

Observe also that the interface to C<run> allows for the arrayref form as well:

    use curry;
    my $future = App::Multigit::each(sub {
        my $repo = shift;
        $repo
            ->run([qw/git checkout master/])
            ->then($repo->curry::run(\&do_another_thing))
        ;
    });

A command may fail. In this case, the Future will fail, and if not handled, the
script will die - which is the default behaviour of Future. You can use
L<else|Future/else> to catch this and continue.

    use curry;
    my $future = App::Multigit::each(sub {
        my $repo = shift;
        $repo
            ->run([qw{git rebase origin/master}])
            ->else([qw{git rebase --abort])
            ->then($repo->curry::report)
        ;
    });

The failure is thrown in a manner that conforms to the expected Future fail
interface, i.e. there is an error message and an error code in there. Following
these is the C<%data> hash that is consistent to all invocations of C<run>. That
means that when you do C<else>, you should be aware that there will be two extra
parameters at the start of the argument list.

    use curry;
    my $future = App::Multigit::each(sub {
        my $repo = shift;
        $repo
            ->run([qw{git rebase origin/master}])
            ->else(sub {
                my ($message, $error, %data) = @_;
                ...
            })
            ->then($repo->curry::report)
        ;
    });

In the case that you don't care whether the command succeeds or fails, you can
use L<finally|App::Multigit::Repo/finally> to catch the failure and pretend it
wasn't actually a failure.

    use curry;
    my $future = App::Multigit::each(sub {
        my $repo = shift;
        $repo
            ->run([qw{git rebase origin/master}])
            ->finally($repo->curry::report)
        ;
    });

Despite the name, C<finally> does not have to be the final thing. Think
"finally" as in "try/catch/finally". In the following code, C<finally> simply
returns the C<%data> hash, because C<finally> transforms a failure into a
success and discards the error information.

    use curry;
    my $future = App::Multigit::each(sub {
        my $repo = shift;
        $repo
            ->run([qw{git rebase origin/master}])
            ->finally(sub { @_ })
            ->then(\&carry_on_camping)
            ->then($repo->curry::report)
        ;
    });

=head4 Arrayref form

In the arrayref form, the C<$command> is passed directly to C<run> in
L<App::Multigit::Repo|App::Multigit::Repo/"run($command, [%data])">.  The
Futures returned thus are collated and the list of return values is thus
collated.

Because L<run|App::Multigit::Repo/"run($command, [%data])"> completes a Future
with a hash-shaped list, the convergent Future that C<each> returns will be a
useless list of all flattened hashes. For this reason it is not actually very
much use to do this - but it is not completely useless, because all hashes are
the same size:

    my $future = App::Multigit::each([qw/git reset --hard HEAD/]);
    my @result = $future->get;

    my $natatime = List::MoreUtils::natatime(10, @result);

    while (my %data = $natatime->()) {
        say $data{stdout};
    }

However, the C<%data> hashes do not contain repository information; just the
output. It is expected that if repository information is required, the closure
form is used.

=cut

sub each {
    my $command = shift;
    my $ia_config = shift;
    my $repos = selected_repositories;

    my $f = fmap { _run_in_repo($command, $_[0], $repos->{$_[0]}, $ia_config) }
        foreach => [ keys %$repos ],
        concurrent => $BEHAVIOUR{concurrent_processes},
    ;

    bless $f, 'App::Multigit::Future';
}

=head2 mg_each

This is the exported name of C<each>

    use App::Multigit qw/mg_each/;

=cut

*mg_each = \&each;

sub _run_in_repo {
    my ($cmd, $repo, $config, $ia_config) = @_;

    return App::Multigit::Future->done
        if $BEHAVIOUR{skip_readonly} and $config->{readonly};

    if (ref $cmd eq 'ARRAY') {
        App::Multigit::Repo->new(
            name => $repo,
            config => $config
        )->run($cmd, ia_config => $ia_config);
    }
    else {
        App::Multigit::Repo->new(
            name => $repo,
            config => $config
        )->$cmd;
    }
}

=head2 mkconfig($workdir)

Scans C<$workdir> for git directories and registers each in C<.mgconfig>. If the
config file already exists it will be appended to; existing config will be
preserved where possible.

=cut

sub mkconfig {
    my $workdir = shift // mg_parent;
    my @dirs = File::Find::Rule
        ->relative
        ->directory
        ->not_name('.git')
        ->maxdepth(1)
        ->mindepth(1)
        ->in($workdir);

    my %config;

    # If it's already inited, we'll keep the config
    %config = try {
        %{ all_repositories($workdir) }
    } catch {};

    for my $dir (@dirs) {
        my $url = try {
                _sensible_remote_url($dir);
            }
            catch {
                warn $_;
                0;
            }
        or next;
        $config{$url}->{dir} = $dir;
    }

    write_config(\%config, $workdir);
}

=head2 write_config

Write a .mgconfig configuration file.

=cut

sub write_config
{
    my $config = shift;
    my $workdir = shift // mg_parent;
    my $config_filename = dir($workdir)->file(mgconfig);
    Config::INI::Writer->write_file($config, $config_filename);
}

=head2 clean_config

Checks the C<.mgconfig> for directories that don't exist and removes the associated repo section.

=cut

sub clean_config {
    my $config = all_repositories;
    my $workdir = shift // mg_parent;

    for my $url (keys %$config) {
        my $conf = $config->{$url};
        my $dir = dir($conf->{dir});

        if ($dir->is_relative) {
            $dir = $dir->absolute($workdir);
        }

        unless (-e $dir) {
            delete $config->{$url};
        }
    }

    my $config_filename = $workdir->file(mgconfig);
    Config::INI::Writer->write_file($config, $config_filename);
}

# Fetch either origin URL, or any URL. Dies if none.
sub _sensible_remote_url {
    my $dir = shift;
    my ($remotes, $stderr, $exitcode) = capture {
        system qw(git -C), $dir, qw(remote -v)
            and return;
    };

    die $stderr if $exitcode;

    if (not $remotes) {
        die "No remotes configured for $dir\n";
    }

    my @remotes = split /\n/, $remotes;
    my %remotes = map {split ' '} @remotes;

    return $remotes{origin} // $remotes{ (keys %remotes)[0] }
}

=head2 base_branch

Returns the branch that the base repository is on -the repository that contains
the C<.mgconfig> or equivalent.

The purpose of this is to switch the entire project onto a feature branch;
scripts can use this as the cue to work against a branch other than master.

This will die if the base repository is not on a branch, because if you've asked
for it, giving you a default will more likely be a hindrance than a help.

=cut

sub base_branch() {
    my $dir = mg_parent;

    my ($stdout) = capture {
        system qw(git -C), $dir, qw(branch)
    };

    my ($branch) = $stdout =~ /\* (.+)/;
    return $branch if $branch;

    die "The base repository is not on a branch!";
}

=head2 set_base_branch($branch)

Checks out the provided branch name on the parent repository. Beware of using a
branch name that already exists, because this will switch to that branch if it
does.

=cut

sub set_base_branch {
    my $base_branch = shift;

    my ($stdout, $stderr) = capture {
        system qw(git -C), mg_parent, qw(checkout -B), $base_branch
    };
}

1;

__END__

=head1 AUTHOR

Alastair McGowan-Douglas, C<< <altreus at perl.org> >>

=head1 ACKNOWLEDGEMENTS

This module could have been a lot simpler but I wanted it to be a foray into the
world of Futures.  Shout outs go to those cats in irc.freenode.net#perl who
basically architectured this for me.

=over

=item tm604 (TEAM) - for actually understanding Future architecture, and not
being mad at me.

=item LeoNerd (PEVANS) - also for not being irritated by my inane questions
about IO::Async and Future.

=back

=head1 BUGS

Please report bugs on the github repository L<https://github.com/Altreus/App-Multigit>.

=head1 LICENSE

Copyright 2015 Alastair McGowan-Douglas.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

