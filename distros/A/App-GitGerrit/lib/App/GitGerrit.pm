use utf8;
use 5.010;
use strict;
use warnings;
use locale ':not_characters';

# The following incantation is here to avoid this bug:
# https://rt.perl.org/rt3/Public/Bug/Display.html?id=63402
my $encoding;
BEGIN {
    if ($^O eq 'MSWin32') {
	require Win32;
	my $cp = Win32::GetConsoleCP();
	$encoding = ":encoding(cp$cp)";
    } else {
	$encoding = ':locale';
    }
}
use open ':std', $encoding;

package App::GitGerrit;
{
  $App::GitGerrit::VERSION = '0.022';
}
# ABSTRACT: A container for functions for the git-gerrit program

use Pod::Usage;
use Getopt::Long qw(:config auto_version auto_help);
use URI;
use URI::Escape;

# App::GitGerrit was converted from a script into a module following this:
# http://elliotlovesperl.com/2009/11/23/how-to-structure-perl-programs/
use Exporter 'import';
our @EXPORT_OK = qw/run/;

# The $Command variable holds the name of the git-gerrit sub-command
# that's been invoked. It's defined in the 'run' routine below.

our $Command;

# The %Options hash is used to hold the command line options passed to
# all git-gerrit subcommands. The --debug option is common to all of
# them. Each subcommand supports a specific set of options which are
# grokked by the get_options routine below.

my %Options = ( debug => 0, help => 0 );

sub debug {
    my ($msg) = @_;
    warn 'git-gerrit[DEBUG]: ', $msg, "\n" if $Options{debug};
}

sub info {
    my ($msg) = @_;
    warn 'git-gerrit[INFO]: ', $msg, "\n";
}

sub error {
    my ($msg) = @_;
    die 'git-gerrit[ERROR]: ', $msg, "\n";
}

sub syntax_error {
    my ($msg) = @_;
    pod2usage "git-gerrit[SYNTAX]: $msg\n";
}

sub get_options {
    my (@opt_specs) = @_;

    # Get defaults from configuration
    foreach my $cmd ($Command, 'all') {
        if (my $options = config("options.$cmd")) {
            debug "$cmd: unshift default options: $options";
            unshift @ARGV, split(' ', $options);
        }
    }

    GetOptions(\%Options, 'debug', 'help', @opt_specs) or pod2usage(2);
    pod2usage({-exitval => 1, -verbose => 2}) if $Options{help};
}

# The cmd routine is used to invoke shell commands, usually git. It
# prints out the command before invoking it in debug operation.

sub cmd {
    my ($cmd) = @_;
    debug $cmd;
    return system($cmd) == 0;
}

# The grok_config routine returns a hash-ref mapping every Git
# configuration variable under the 'git-gerrit' section to its list of
# values.

sub grok_config {
    state $config;

    unless ($config) {
        debug "git config --list";
        {
            open my $pipe, '-|', 'git config --list';
            while (<$pipe>) {
                if (/^(.+?)\.(\S+)=(.*)/) {
                    push @{$config->{$1}{$2}}, $3;
                } else {
                    info "Strange git-config output: $_";
                }
            }
        }

        # Now we must assume some configuration by default

        $config->{'git-gerrit'}{remote} //= ['origin'];

        my $remote_url = sub {
            state $url;
            unless ($url) {
                my $remote = $config->{'git-gerrit'}{remote}[-1];
                $url = $config->{remote}{"$remote.url"}[-1]
                    or error "The remote '$remote' isn't configured because there's no remote.$remote.url configuration";
                $url = URI->new($url);
            }
            return $url;
        };

        unless ($config->{'git-gerrit'}{baseurl}) {
            my $url = $remote_url->();
            $config->{'git-gerrit'}{baseurl} = [$url->scheme . '://' . $url->authority];
        }
        $config->{'git-gerrit'}{baseurl}[-1] =~ s:/+$::; # strip trailing slashes

        unless ($config->{'git-gerrit'}{project}) {
            my $prefix = URI->new($config->{'git-gerrit'}{baseurl}[-1])->path;
            my $path   = $remote_url->()->path;
            if (length $prefix) {
                $prefix eq substr($path, 0, length($prefix))
                    or error <<EOF;
I can't grok git-gerrit.project because git-gerrit.baseurl's path
doesn't match git-gerrit.remote's path:

* baseurl: 
EOF
                $config->{'git-gerrit'}{project} = [substr($path, length($prefix))];
            } else {
                $config->{'git-gerrit'}{project} = [$path];
            }
        }
        $config->{'git-gerrit'}{project}[-1] =~ s:^/+::; # strip leading slashes
    }

    return $config;
}

# The config routine returns the last value associated with Git's
# git-gerrit.$var configuration variable, as output by the 'git config
# -l' command, or undef if the variable isn't defined.

sub config {
    my ($var) = @_;
    state $config = grok_config;
    return exists $config->{'git-gerrit'}{$var} ? $config->{'git-gerrit'}{$var}[-1] : undef;
}

# The configs routine returns all values associated with Git's
# git-gerrit.$var configuration variable or the empty list if the
# variable isn't defined.

sub configs {
    my ($var) = @_;
    state $config = grok_config;
    return exists $config->{'git-gerrit'}{$var} ? @{$config->{'git-gerrit'}{$var}}  : ();
}

# The install_commit_msg_hook routine is invoked by a few of
# git-gerrit subcommands. It checks if the current repository already
# has a commit-msg hook installed. If not, it tries to download and
# install Gerrit's default commit-msg hook, which inserts Change-Ids
# in commits messages.

sub install_commit_msg_hook {
    require File::Spec;

    chomp(my $git_dir = qx/git rev-parse --git-dir/);

    # Do nothing if it already exists
    my $commit_msg = File::Spec->catfile($git_dir, 'hooks', 'commit-msg');
    return if -e $commit_msg;

    # Otherwise, check if we need to mkdir the hooks directory
    my $hooks_dir = File::Spec->catdir($git_dir, 'hooks');
    mkdir $hooks_dir unless -e $hooks_dir;

    # Try to download and install the hook.
    eval { require LWP::Simple };
    if ($@) {
        info "Cannot install $commit_msg hook because you don't have LWP::Simple installed";
    } else {
        info "Installing $commit_msg hook";
        if (LWP::Simple::is_success(LWP::Simple::getstore(config('baseurl') . "/tools/hooks/commit-msg", $commit_msg))) {
            chmod 0755, $commit_msg;
        }
    }
}

# The credential_* routines below use the git-credential command to
# get and set credentials for git commands and also for Gerrit REST
# interactions.

sub url_userinfo {
    my ($url) = @_;
    if (my $userinfo = $url->userinfo) {
        return split /:/, $userinfo, 2;
    } else {
        return (undef, undef);
    }
}

sub credential_description_file {
    my ($baseurl, $password) = @_;

    my %credential = (
        protocol => $baseurl->scheme,
        host     => $baseurl->host,
        path     => $baseurl->path,
        password => $password,
    );

    # Try to get the username from the baseurl
    my ($username) = url_userinfo($baseurl);
    $credential{username} = $username if $username;

    require File::Temp;
    my $fh = File::Temp->new();

    while (my ($key, $value) = each %credential) {
        $fh->print("$key=$value\n") if $value;
    }

    $fh->print("\n\n");
    $fh->close();

    return ($fh, $fh->filename);
}

my $git_credential_supported = 1;
sub get_credentials {
    my $baseurl = URI->new(config('baseurl'));
    my ($fh, $credfile) = credential_description_file($baseurl);

    my %credentials;
    debug "Get credentials from git-credential";
    open my $pipe, '-|', "git credential fill <$credfile"
        or error "Can't open pipe to git-credential: $!";
    while (<$pipe>) {
        chomp;
        $credentials{$1} = $2 if /^([^=]+)=(.*)/;
    }
    unless (close $pipe) {
        error "Can't close pipe to git-credential: $!" if $!;

        # If we get here it is because the shell invoked by open
        # above couldn't exec git-credential, which most probably
        # means that we're using a pre-1.8 Git, which doesn't
        # support git-credential yet.
        $git_credential_supported = 0;
    }

    my ($username, $password) = @credentials{qw/username password/};

    unless (defined $username && defined $password) {
        debug "Get credentials from git-gerrit.baseurl";
        ($username, $password) = url_userinfo(config('baseurl'));
    }

    unless (defined $username && defined $password) {
        debug "Get credentials from a .netrc file";
        if (eval {require Net::Netrc}) {
            if (my $mach = Net::Netrc->lookup(URI->new(config('baseurl'))->host, $username)) {
                ($username, $password) = ($mach->login, $mach->password);
            }
        } else {
            debug "Failed to require Net::Netrc";
        }
    }

    unless (defined $username && defined $password) {
        debug "Prompt the user for the credentials";
        if (eval {require Term::Prompt}) {
            $username = Term::Prompt::prompt('x', 'Gerrit username: ', '', $ENV{USER});
            $password = Term::Prompt::prompt('p', 'Gerrit password: ', '');
            print "\n";
        } else {
            debug "Failed to require Term::Prompt";
        }
    }

    defined $username or error "Couldn't get credential's username";
    defined $password or error "Couldn't get credential's password";

    return ($username, $password);
}

sub set_credentials {
    my ($username, $password, $what) = @_;

    return 1 unless $git_credential_supported;

    $what =~ /^(?:approve|reject)$/
        or error "set_credentials \$what argument ($what) must be either 'approve' or 'reject'";

    my $baseurl = URI->new(config('baseurl'));
    my ($fh, $credfile) = credential_description_file($baseurl, $password);

    return system("git credential $what <$credfile") == 0;
}

# The get_message routine returns the message argument to the
# --message option. If the option is not present it invokes the git
# editor to let the user compose a message and returns it.

sub get_message {
    return $Options{message} if exists $Options{message};

    chomp(my $editor = qx/git var GIT_EDITOR/);

    error "Please, read 'git help var' to know how to set up an editor for git messages."
        unless $editor;

    require File::Temp;
    my $tmp = File::Temp->new();
    my $filename = $tmp->filename;

    {
        open my $fh, '>', $filename
            or error "Can't open file for writing ($filename): $!\n";
        print $fh <<'EOF';

# Please enter the review message for this change. Lines starting
# with '#' will be ignored, and an empty message aborts the review.
EOF
        close $fh;
    }

    cmd "$editor $filename"
        or error "Aborting because I couldn't invoke '$editor $filename'.";

    my $message;
    {
        open my $fh, '<', $filename
            or error "Can't open file for reading ($filename): $!\n";
        local $/ = undef;       # slurp mode
        $message = <$fh>;
        close $fh;
    }
    $message =~ s/(?<=\n)#.*?\n//gs; # remove all lines starting with '#'
    return $message;
}

# The gerrit routine keeps a cached Gerrit::REST object to which it
# relays REST calls.

sub gerrit {
    my $method = shift;

    state $gerrit;
    unless ($gerrit) {
        my ($username, $password) = get_credentials;
        require Gerrit::REST;
        $gerrit = Gerrit::REST->new(config('baseurl'), $username, $password);
        eval { $gerrit->GET("/projects/" . uri_escape_utf8(config('project'))) };
        if (my $error = $@) {
            set_credentials($username, $password, 'reject') if $error->{code} == 401;
            die $error;
        } else {
            set_credentials($username, $password, 'approve');
        }
    }

    if ($Options{debug}) {
        my ($endpoint, @args) = @_;
        debug "GERRIT->$method($endpoint)";
        if (@args) {
            require Data::Dumper;
            warn Data::Dumper::Dumper(@args);
        }
    }

    return $gerrit->$method(@_);
}

# The gerrit_or_die routine relays its arguments to the gerrit routine
# but catches any exception and dies with a formatted message. It
# should be called instead of gerrit whenever the caller doesn't want
# to treat exceptions.

sub gerrit_or_die {
    my $result = eval { gerrit(@_) };
    die $@->as_text if $@;
    return $result;
}

# The normalize_date routine removes the trailing zeroes from a $date.

sub normalize_date {
    my ($date) = @_;
    $date =~ s/\.0+$//;
    return $date;
}

# The query_changes routine receives a list of strings to query the
# Gerrit server. It returns an array-ref containing a list of
# array-refs, each containing a list of change descriptions.

sub query_changes {
    my @queries = @_;

    return [] unless @queries;

    # If we're inside a git repository, restrict the query to the
    # current project's reviews.
    if (my $project = config('project')) {
        $project = uri_escape_utf8($project);
        @queries = map "q=project:$project+$_", @queries;
    }

    push @queries, "n=$Options{limit}" if $Options{limit};

    push @queries, "o=LABELS";

    my $changes = gerrit_or_die(GET => "/changes/?" . join('&', @queries));
    $changes = [$changes] if ref $changes->[0] eq 'HASH';

    return $changes;
}

# The get_change routine returns the description of a change
# identified by $id. An optional boolean second argument ($allrevs)
# tells if the change description should contain a description of all
# patchsets or just the current one.

sub get_change {
    my ($id, $allrevs) = @_;

    my $revs = $allrevs ? 'ALL_REVISIONS' : 'CURRENT_REVISION';
    return (gerrit_or_die(GET => "/changes/?q=change:$id&o=$revs"))[0][0];
}

# The current_branch routine returns the name of the current branch or
# 'HEAD' in a dettached head state.

sub current_branch {
    chomp(my $branch = qx/git rev-parse --abbrev-ref HEAD/);
    return $branch;
}

# The update_branch routine receives a local $branch name and updates
# it with the homonym branch in the Gerrit remote.

sub update_branch {
    my ($branch) = @_;

    my $remote = config('remote');
    cmd "git fetch $remote $branch:$branch";
}

# The change_branch_info routine receives the name of a branch. If
# it's a change-branch, it returns a two-element list containing it's
# upstream name and its id. Otherwise, it returns the empty list.

sub change_branch_info {
    my ($branch) = @_;
    if ($branch =~ m:^change/(?<upstream>.*)/(?<id>[^/]+):) {
        return ($+{upstream}, $+{id});
    }
    return;
}

# The current_change_id routine returns the id of the change branch
# we're currently in. If we're not in a change branch, it returns
# undef.

sub current_change_id {
    my ($branch, $id) = change_branch_info(current_branch);

    return $id;
}

# This routine receives the hash-ref mapped to the 'Code-Review' label
# in a change's 'labels' key when it's fetched with the option
# LABELS. For more information, please read:
# https://gerrit-review.googlesource.com/Documentation/rest-api-changes.html#label-info

sub code_review {
    my ($cr) = @_;
    if (! defined $cr) {
        return '';
    } elsif (exists $cr->{rejected}) {
        return '-2';
    } elsif (exists $cr->{disliked}) {
        return '-1';
    } elsif (exists $cr->{approved}) {
        return '+2';
    } elsif (exists $cr->{recommended}) {
        return '+1';
    } else {
        return '';
    }
}

# This routine receives a branch name (normally the upstream of a
# change-branch) and returns a list of users matching the
# git-gerrit.reviewers specifications. The list returned is guaranteed
# to have no duplicates.

sub auto_reviewers {
    my ($upstream) = @_;
    my $paths;

    my @reviewers;

  REVIEWERS:
    foreach my $spec (configs('reviewers')) {
        if (my ($users, @conditions) = split ' ', $spec) {
            if (@conditions) {
              CONDITION:
                foreach my $condition (@conditions) {
                    if (my ($what, $op, $match) = ($condition =~ /^(branch|path)([=~])(.+)$/i)) {
                        if ($what eq 'branch') {
                            if ($op eq '=') {
                                next CONDITION if $upstream eq $match;
                            } else {
                                my $regex = eval { qr/$match/ };
                                defined $regex
                                    or info "Warning: skipping git-gerrit.reviewers spec with invalid REGEXP ($match)."
                                        and next REVIEWERS;
                                next CONDITION if $upstream =~ $match;
                            }
                        } else {
                            unless ($paths) {
                                $paths = [qx/git diff --name-only ${upstream}..HEAD/];
                                chomp @$paths;
                            }
                            if ($op eq '=') {
                                foreach my $path (@$paths) {
                                    next CONDITION if $path eq $match;
                                }
                            } else {
                                my $regex = eval { qr/$match/ };
                                defined $regex
                                    or info "Warning: skipping git-gerrit.reviewers spec with invalid REGEXP ($match)."
                                        and next REVIEWERS;
                                foreach my $path (@$paths) {
                                    next CONDITION if $path =~ $regex;
                                }
                            }
                        }
                    } else {
                        info "Warning: skipping git-gerrit.reviewers spec with invalid condition ($condition).";
                    }
                    next REVIEWERS;
                }
            }
            push @reviewers, split(/,/, $users);
        }
    }

    # Use a hash to remove duplicates
    my %reviewers = map {$_ => undef} @reviewers;
    return keys %reviewers;
}

# This routine is used by all sub-commands that accept zero or more
# change ids. If @ARGV is empty it pushes into it the id of the change
# associated with the current change-branch, if any. It returns a
# boolean telling if the push has been made.

sub grok_unspecified_change {
    if (@ARGV) {
        return 0;
    } else {
        my $id = current_change_id()
            or syntax_error "$Command: You have to be in a change-branch or specify at least one CHANGE.";
        $id =~ /^\d+$/
            or error "$Command: The change-branch you're in haven't been pushed yet.";
        @ARGV = ($id);
        return 1;
    }
}

# This routine is used by the sub-commands that, when applied
# successfully to the current change-branch, want to checkout its
# upstream and remove the change-branch.

sub checkout_upstream_and_delete_branch {
    my $branch     = current_branch;
    my ($upstream) = change_branch_info($branch);
    cmd "git checkout $upstream" and cmd "git branch -D $branch";
}

############################################################
# MAIN

# Each git-gerrit subcommand is implemented by an anonymous routine
# associated with one or more names in the %Commands hash.

my %Commands;

$Commands{new} = sub {
    get_options('update');

    my $topic = shift @ARGV
        or syntax_error "$Command: Missing TOPIC.";

    $topic !~ m:/:
        or error "$Command: the topic name ($topic) should not contain slashes.";

    $topic =~ m:\D:
        or error "$Command: the topic name ($topic) should contain at least one non-digit character.";

    my $branch = shift @ARGV || current_branch;

    if (my ($upstream, $id) = change_branch_info($branch)) {
        # If we're on a change-branch the new change-branch is based on the same upstream
        $branch = $upstream;
    }

    my $status = qx/git status --porcelain --untracked-files=no/;

    info "Warning: git-status tells me that your working area is dirty:\n$status\n"
        if length $status;

    if ($Options{update}) {
        update_branch($branch)
            or error "$Command: Non-fast-forward pull. Please, merge or rebase your branch first.";
    }

    cmd "git checkout -b change/$branch/$topic $branch";

    install_commit_msg_hook;

    return;
};

$Commands{push} = sub {
    $Options{rebase} = '';      # false by default
    get_options(
        'keep',
        'force+',
        'rebase!',
        'draft',
        'topic=s',
        'submit',
        'base=s',
        'reviewer=s@',
        'cc=s@'
    );

    my $branch = current_branch;

    my ($upstream, $id) = change_branch_info($branch)
        or error "$Command: You aren't in a change branch. I cannot push it.";

    my $is_clean = qx/git status --porcelain --untracked-files=no/ eq '';

    $is_clean or $Options{force}--
            or error <<EOF;
push: Can't push change because git-status is dirty.
      If this is really what you want to do, please try again with --force.
EOF

    my @commits = qx/git log --decorate=no --first-parent --oneline ${upstream}..HEAD/;
    if (@commits == 0) {
        error "$Command: no changes between $upstream and $branch. Pushing would be pointless.";
    } elsif (@commits > 1) {
        error <<EOF unless $Options{force}--;
push: you have more than one commit that you are about to push.
      The outstanding commits are:

 @commits
      If this is really what you want to do, please try again with --force.
EOF
    }

    # Grok the list of parent commits to see if it's a merge commit.
    my @parents = split / /, qx/git log --pretty='format:%p' -1/;

    # A --noverbose option sets $Options{rebase} to '0'.
    if ($is_clean && (@parents < 2) && ($Options{rebase} || $Options{rebase} eq '' && $id =~ /\D/)) {
        update_branch($upstream)
            or error "$Command: Non-fast-forward pull. Please, merge or rebase your branch first.";
        cmd "git rebase $upstream"
            or error "$Command: please resolve this 'git rebase $upstream' and try again.";
    }

    my $refspec = 'HEAD:refs/' . ($Options{draft} ? 'draft' : 'for') . "/$upstream";

    my @tags;
    if (my $topic = $Options{topic}) {
        push @tags, "topic=$topic";
    } elsif ($id =~ /\D/) {
        push @tags, "topic=$id";
    }

    my @reviewers = auto_reviewers($upstream);
    if (my $reviewers = $Options{reviewer}) {
        push @reviewers, split(/,/, join(',', @$reviewers));
    }
    if (@reviewers) {
        push @tags, map("r=$_", @reviewers);
    }

    if (my $ccs = $Options{cc}) {
        push @tags, map("cc=$_", split(/,/, join(',', @$ccs)));
    }
    if ($Options{submit}) {
        push @tags, 'submit';
    }
    if (my $base = $Options{base}) {
        push @tags, "base=$base";
    }
    if (@tags) {
        $refspec .= '%';
        $refspec .= join(',', @tags);
    }

    my $remote = config('remote');
    cmd "git push $remote $refspec"
        or error "$Command: Error pushing change.";

    if ($is_clean && ! $Options{keep}) {
        cmd "git checkout $upstream" and cmd "git branch -D $branch";
    }

    install_commit_msg_hook;

    return;
};

$Commands{query} = sub {
    get_options(
        'verbose',
        'limit=i',
    );

    my (@names, @queries);
    foreach my $arg (@ARGV) {
        if ($arg =~ /(?<name>.*?)=(?<query>.*)/) {
            push @names,   $+{name};
            push @queries, $+{query};
        } else {
            push @names,   "QUERY";
            push @queries, $arg;
        }
    }

    my $changes = query_changes(@queries);

    for (my $i=0; $i < @$changes; ++$i) {
        print "[$names[$i]=$queries[$i]]\n";
        next unless @{$changes->[$i]};

        require Text::Table;
        my $table = Text::Table->new("ID\n&num", qw/STATUS CR UPDATED PROJECT BRANCH OWNER SUBJECT/);

        foreach my $change (sort {$b->{updated} cmp $a->{updated}} @{$changes->[$i]}) {
            if ($Options{verbose}) {
                if (my $topic = gerrit_or_die(GET => "/changes/$change->{id}/topic")) {
                    $change->{branch} .= " ($topic)";
                }
            }
            $table->add(
                $change->{_number},
                $change->{status},
                code_review($change->{labels}{'Code-Review'}),
                normalize_date($change->{updated}),
                $change->{project},
                $change->{branch},
                $change->{owner}{name},
                $change->{subject},
            );
        }
        print $table->table(), "\n";
    }

    return;
};

my %StandardQueries = (
    changes => [
        'Outgoing reviews=is:open+owner:self',
        'Incoming reviews=is:open+reviewer:self+-owner:self',
        'Recently closed=is:closed+owner:self+-age:1mon',
    ],
    drafts  => ['Drafts=is:draft'],
    watched => ['Watched changes=is:watched+status:open'],
    starred => ['Starred changes=is:starred'],
);
$Commands{my} = sub {
    if (@ARGV) {
        if (exists $StandardQueries{$ARGV[-1]}) {
            splice @ARGV, -1, 1, @{$StandardQueries{$ARGV[-1]}};
        } elsif ($ARGV[-1] =~ /^-/) {
            # By default we show 'My Changes'
            push @ARGV, @{$StandardQueries{changes}};
        } else {
            syntax_error "$Command: Invalid change specification: '$ARGV[-1]'";
        }
    } else {
        # By default we show 'My Changes'
        push @ARGV, @{$StandardQueries{changes}};
    }

    $Commands{query}();

    return;
};

$Commands{show} = sub {
    get_options();

    grok_unspecified_change;

    foreach my $id (@ARGV) {
        my $change = gerrit_or_die(GET => "/changes/$id/detail");

        print <<EOF;
 Change-Num: $change->{_number}
  Change-Id: $change->{change_id}
    Subject: $change->{subject}
      Owner: $change->{owner}{name}
EOF

        foreach my $date (qw/created updated/) {
            $change->{$date} = normalize_date($change->{$date})
                if exists $change->{$date};
        }

        foreach my $key (qw/project branch topic created updated status reviewed mergeable/) {
            printf "%12s %s\n", "\u$key:", $change->{$key}
                if exists $change->{$key};
        }

        print "\n";
        # We want to produce a table in which the first column lists the
        # reviewer names and the other columns have their votes for each
        # label. However, the change object has this information
        # inverted. So, we have to first collect all votes.
        my @labels = sort keys %{$change->{labels}};
        my %reviewers;
        while (my ($label, $info) = each %{$change->{labels}}) {
            foreach my $vote (@{$info->{all}}) {
                $reviewers{$vote->{name}}{$label} = $vote->{value};
            }
        }

        # And now we can output the vote table
        require Text::Table;
        my $table = Text::Table->new('REVIEWER', map {"$_\n&num"} @labels);

        foreach my $name (sort keys %reviewers) {
            my @votes = map {$_ > 0 ? "+$_" : $_} map {defined $_ ? $_ : '0'} @{$reviewers{$name}}{@labels};
            $table->add($name, @votes);
        }
        print $table->table(), '-' x 60, "\n";
    }

    return;
};

$Commands{fetch} = sub {
    get_options();

    grok_unspecified_change;

    my $branch;
    my $project = config('project');
    my @change_branches;
    foreach my $id (@ARGV) {
        my $change = get_change($id);

        $change->{project} eq $project
            or error "$Command: Change $id belongs to a different project ($change->{project}), not $project";

        my ($revision) = values %{$change->{revisions}};

        my ($url, $ref) = @{$revision->{fetch}{http}}{qw/url ref/};

        $branch = "change/$change->{branch}/$change->{_number}";

        cmd "git fetch $url $ref:$branch"
            or error "$Command: Can't fetch $url";

        push @change_branches, $branch;
    }

    return @change_branches;
};

$Commands{checkout} = $Commands{co} = sub {
    my $last_change_branch = do {
        local $Command = 'fetch';
        my @change_branches = $Commands{fetch}->();
        $change_branches[-1];
    };

    cmd "git checkout $last_change_branch";

    return;
};

$Commands{upstream} = $Commands{up} = sub {
    get_options(
        'keep',
        'delete',
    );

    my $branch = current_branch;

    if (my ($upstream, $id) = change_branch_info($branch)) {
        if (cmd "git checkout $upstream") {
            if ($Options{keep} || ! $Options{delete} && $id =~ /\D/) {
                info "Keeping $branch";
            } else {
                cmd "git branch -D $branch";
            }
        }
    } else {
        error "$Command: You aren't in a change branch. There is no upstream to go to.";
    }

    return;
};

$Commands{'cherry-pick'} = $Commands{cp} = sub {
    get_options(
        'edit',
        'no-commit',
    );

    my @args;
    push @args, '--edit'      if $Options{edit};
    push @args, '--no-commit' if $Options{'no-commit'};

    @ARGV or syntax_error "$Command: Missing CHANGE.";

    my @change_branches = do {
        local $Command = 'fetch';
        $Commands{fetch}->();
    };

    cmd join(' ', 'git cherry-pick', @args, @change_branches);

    return;
};

$Commands{rebase} = sub {
    get_options();

    my ($upstream, $id) = change_branch_info(current_branch)
        or error "$Command: You must be in a change branch to invoke rebase.";

    cmd "git rebase $upstream"
        or error "$Command: please resolve this 'git rebase $upstream' and try again.";
};

$Commands{reviewer} = sub {
    get_options(
        'add=s@',
        'confirm',
        'delete=s@',
    );

    grok_unspecified_change;

    foreach my $id (@ARGV) {
        # First try to make all deletions
        if (my $users = $Options{delete}) {
            foreach my $user (split(/,/, join(',', @$users))) {
                $user = uri_escape_utf8($user);
                gerrit_or_die(DELETE => "/changes/$id/reviewers/$user");
            }
        }

        # Second try to make all additions
        if (my $users = $Options{add}) {
            my $confirm = $Options{confirm} ? 'true' : 'false';
            foreach my $user (split(/,/, join(',', @$users))) {
                gerrit_or_die(POST => "/changes/$id/reviewers", { reviewer => $user, confirm => $confirm});
            }
        }

        # Finally, list current reviewers
        my $reviewers = gerrit_or_die(GET => "/changes/$id/reviewers");

        print "[$id]\n";
        require Text::Table;
        my %labels = map {$_ => undef} map {keys %{$_->{approvals}}} @$reviewers;
        my @labels = sort keys %labels;
        my $table = Text::Table->new('REVIEWER', map {"$_\n&num"} @labels);
        $table->add($_->{name}, @{$_->{approvals}}{@labels})
            foreach sort {$a->{name} cmp $b->{name}} @$reviewers;
        print $table->table(), '-' x 60, "\n";
    }

    return;
};

$Commands{review} = sub {
    get_options(
        'message=s',
        'keep',
    );

    my %review;

    if (my $message = get_message) {
        $review{message} = $message;
    }

    # Set all votes
    while (@ARGV && $ARGV[0] =~ /(?<label>.*)=(?<vote>.*)/) {
        shift @ARGV;
        $review{labels}{$+{label} || 'Code-Review'} = $+{vote};
        $+{vote} =~ /^[+-]?\d$/
            or syntax_error "$Command: Invalid vote ($+{vote}). It must be a single digit optionally prefixed by a [-+] sign.";
    }

    error "$Command: Invalid vote $ARGV[0]." if @ARGV > 1;

    error "$Command: You must specify a message or a vote to review."
        unless keys %review;

    my $local_change = grok_unspecified_change;

    foreach my $id (@ARGV) {
        gerrit_or_die(POST => "/changes/$id/revisions/current/review", \%review);
    }

    checkout_upstream_and_delete_branch
        if $local_change && ! $Options{keep};

    return;
};

$Commands{abandon} = sub {
    get_options(
        'message=s',
        'keep',
    );

    my @args;

    if (my $message = get_message) {
        push @args, { message => $message };
    }

    my $local_change = grok_unspecified_change;

    foreach my $id (@ARGV) {
        gerrit_or_die(POST => "/changes/$id/abandon", @args);
    }

    checkout_upstream_and_delete_branch
        if $local_change && ! $Options{keep};

    return;
};

$Commands{restore} = sub {
    get_options('message=s');

    my @args;

    if (my $message = get_message) {
        push @args, { message => $message };
    }

    grok_unspecified_change;

    foreach my $id (@ARGV) {
        gerrit_or_die(POST => "/changes/$id/restore", @args);
    }

    return;
};

$Commands{revert} = sub {
    get_options('message=s');

    my @args;

    if (my $message = get_message) {
        push @args, { message => $message };
    }

    grok_unspecified_change;

    foreach my $id (@ARGV) {
        gerrit_or_die(POST => "/changes/$id/revert", @args);
    }

    return;
};

$Commands{submit} = sub {
    get_options(
        'no-wait-for-merge',
        'keep',
    );

    my @args;
    push @args, { wait_for_merge => 'true' } unless $Options{'no-wait-for-merge'};

    my $local_change = grok_unspecified_change;

    foreach my $id (@ARGV) {
        gerrit_or_die(POST => "/changes/$id/submit", @args);
    }

    checkout_upstream_and_delete_branch
        if $local_change && ! $Options{keep};

    return;
};

$Commands{web} = sub {
    # The 'gerrit web' sub-command passes all of its options,
    # but --debug, to 'git web--browse'.
    Getopt::Long::Configure('pass_through');
    get_options();

    # If the user is passing any option we require that it mark where
    # they end with a '--' so that we know where the CHANGEs arguments
    # start.
    my @options;
    for (my $i = 0; $i < @ARGV; ++$i) {
        if ($ARGV[$i] eq '--') {
            # We found a mark. Let's move all the options from @ARGV
            # to @options and get rid of the mark.
            @options = splice @ARGV, 0, $i;
            shift @ARGV;
            last;
        }
    }

    grok_unspecified_change;

    # Grok the URLs of each change
    my @urls;
    my $baseurl = config('baseurl');
    foreach my $id (@ARGV) {
        my $change = get_change($id);
        push @urls, "$baseurl/#/c/$change->{_number}";
    }

    cmd join(' ', qw/git web--browse/, @options, @urls);
};

$Commands{config} = sub {
    my $config = grok_config;
    my $git_gerrit = $config->{'git-gerrit'}
        or return;
    require Text::Table;
    my $table = Text::Table->new();
    foreach my $var (sort keys %$git_gerrit) {
        foreach my $value (@{$git_gerrit->{$var}}) {
            $table->add("git-gerrit.$var", $value);
        }
    }
    print $table->table(), "\n";

    return;
};

$Commands{version} = sub {
    print "Perl version $^V\n";
    print "git-gerrit version $App::GitGerrit::VERSION\n";
    cmd "git version";
    my $baseurl = config('baseurl'); # die unless configured
    my $version = eval { gerrit(GET => '/config/server/version') };
    $version //= "pre-2.7 (Because it doesn't support the 'Get Version' REST Endpoint.)";
    print "Gerrit version $version\n";
    return;
};

# MAIN

sub run {
    $Command = shift @ARGV
        or syntax_error "Missing command name.";

    exists $Commands{$Command}
        or syntax_error "Invalid command: $Command.";

    $Commands{$Command}->();

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGerrit - A container for functions for the git-gerrit program

=head1 VERSION

version 0.022

=head1 SYNOPSIS

    use App::GitGerrit qw/run/;
    return 1 if caller;
    exit run();

=head1 DESCRIPTION

You're not supposed to use this module directly!

It's used by the C<git-gerrit> script which comes in the same CPAN
distribution. All the documentation that exists can be read via

    perldoc git-gerrit

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
