package App::Gitc::Util;
use strict;
use warnings;

# ABSTRACT: The workhorse of gitc
our $VERSION = '0.60'; # VERSION

use base qw( Exporter );
use YAML::Syck;
use Hash::Merge::Simple qw( merge );

# To help gitc load quickly, only use modules here which
# must be loaded at compile time.  Otherwise, use "require Foo"
# in the implementation below.  That way, the module can be
# lazily loaded at run time, if it's actually needed.
use List::Util qw( first max );
use List::MoreUtils qw( first_index any );

use Class::MOP;

use constant GITC_CONFIG => '/etc/gitc/gitc.config';

BEGIN {
    our @EXPORT = qw(
        current_branch
        eventum
        eventum_transition_status
        fetch_tags
        get_user_name
        get_user_email
        git
        git_config
        guarantee_a_clean_working_directory
        let_user_edit
        meta_data_add
        meta_data_rm
        meta_data_rm_all
        project_config
        its
        its_for_changeset
    );
    our @EXPORT_OK = qw(
        add_current_user
        archived_tags
        branch_basis
        branch_point
        cache_meta_data
        changeset_group
        changeset_merged_to
        changesets_in
        changesets_promoted_between
        command_name
        commit_decorations
        confirm
        current_branch_version
        environment_preceding
        full_changeset_name
        git_fetch_and_clean_up
        git_dir
        git_tag
        highest_quickfix_number
        history
        history_owner
        history_reviewer
        history_status
        history_submitter
        is_auto_fetch
        is_merge_commit
        is_suspendable
        is_valid_ref
        meta_data_rm_project
        new_branch_version
        new_version_tag
        open_packed_refs
        parse_changeset_spec
        project_name
        project_root
        remote_branch_exists
        restore_meta_data
        sendmail
        short_ref_name
        sort_changesets_by_name
        toplevel
        traverse_commits
        unmerged_changesets
        unpromoted
        user_lookup_class
        version_tag_prefix
        state_blocked
    );
}


sub confirm {
    my ($message) = @_;
    die "No message given to 'confirm'" if not defined $message;

    require Term::ReadLine;
    my $term   = Term::ReadLine->new('gitc');
    my $prompt = "$message ";
    my $response;

    # prompt the user
    while ( defined( $response = $term->readline($prompt) ) ) {
        return 1 if $response eq 'y';
        return   if $response eq 'n';
        $prompt = "$message ('y' or 'n') ";
    }
}


# If this ever needs to be faster, it can be implemented by opening
# .git/HEAD and parsing the one line contents.  It would take a bit
# more effort to get it right, but it would avoid the fork+exec overhead
sub current_branch {
    my ($name) = grep /^[*]/, qx{ git branch --no-color };
    chomp $name;
    $name =~ s/^[*] //;
    return $name;
}


sub its_config {
    my $name = lc its()->label_service;

    return project_config()->{ "${name}_statuses" };
}

# Eventum is the name of our internal ticketing system.
sub eventum {
    return its()->get_issue( @_ );
}

sub eventum_transition_status {
    return its()->transition_state( @_ );
}


sub eventum_statuses {
    my ( $self, $command, $target ) = @_;

    my $statuses = project_config()->{'jira_statuses'}{$command}
        or die "No JIRA statuses for $command";

    # handle the common case
    if ( not $target ) {
        die "No initial status" unless $statuses->{from};
        die "No final status" unless $statuses->{to};
        return ( $statuses );
    }

    # promotions need another level of dereference
        die "No initial status for target $target" unless $statuses->{$target}{from};
        die "No final status for target $target" unless $statuses->{$target}{to};
        return $statuses->{$target};

}


sub _package_its {
    my $its_type = shift;

    return 'App::Gitc::Its::'.ucfirst $its_type; 
}

sub its {
    my $its = shift || project_config()->{'default_its'};
    
    # They don't have to use an ITS if they don't want.
    return undef unless $its;

    # But if one's specified, it has to work.
    Class::MOP::load_class(_package_its($its))
        or die "I can't load $its: $!.\n";

    return _package_its($its)
}

sub user_lookup_class {
    my $lookup_class = project_config()->{ user_lookup_method }
                    // 'LocalGroup';

    my $pkg = "App::Gitc::UserLookup::$lookup_class";

    Class::MOP::load_class( $pkg );

    return $pkg;
}


sub its_for_changeset {
    my ( $changeset ) = @_;

    my $its = its();

    return $its->can( 'its_for_changeset' )
        ? $its->its_for_changeset( $changeset )
        : $its;
}


sub git {
    my ($command_line) = @_;

    require Cwd;

    my $start = Cwd::cwd();
    my $base  = ( $command_line =~ /^clone / ? $start : toplevel() );

    unless ( $start eq $base ) {
        chdir $base || warn "Could not cd to $base";
    }

    if ( not defined wantarray ) {  # void context
        warn "> git $command_line\n" if $ENV{DEBUG};
        system("git $command_line") == 0 and return;

        # uh oh, something went wrong
        my $msg = '';
        if ( $? == -1 ) {
            $msg = "failed to execute: $!";
        }
        elsif ( $? & 127 ) {
            $msg = sprintf "died with signal %d", ( $? & 127 );
        }
        else {
            $msg = sprintf "exited with value %d", ( $? >> 8 );
        }
        require Carp;
        Carp::croak("git $command_line failed: $msg");
    }
    elsif ( wantarray ) {  # list context
        warn "> git $command_line\n" if $ENV{DEBUG};
        my @output = qx{git $command_line};
        # there's no reliable way to check if this failed
        chomp @output;
        return @output;
    }

    # scalar context
    warn "> git $command_line\n" if $ENV{DEBUG};
    my $output = qx{git $command_line};
    if ( not defined $output ) {
        require Carp;
        Carp::croak("git $command_line failed: $!");
    }

    chdir $start unless $start eq $base;

    chomp $output;
    return $output;
}


sub git_config {
    our %config;

    if ( not keys %config ) {
        for my $line ( git "config -l" ) {
            my ($name, $value) = split /=/, $line;
            my @parts = split /[.]/, $name;
            my $here = \%config;
            for my $part ( @parts[ 0 .. $#parts-1 ] ) {
                $here->{$part} = {} if not $here->{$part};
                $here = $here->{$part};
            }
            $here->{ $parts[-1] } = $value;
        }
    }

    return \%config;
}


sub guarantee_a_clean_working_directory {
    my $arguments = "diff -C -M --name-status";
    my $staged    = git "$arguments --cached";
    my $changed   = git $arguments;
    return if not $staged and not $changed;

    # the tree is dirty, verify whether to continue
    warn "It looks like you have uncommitted changes. If this is expected,\n"
       . "type 'y' to continue.  If it's not expected, type 'n'.\n"
       . ( $staged  ? "staged:\n$staged\n"   : '' )
       . ( $changed ? "changed:\n$changed\n" : '' )
       ;
    die "Aborting at the user's request.\n" if not confirm('Continue?');

    # stash the changes to let them be restored later
    my $stash = git "stash create";
    git "reset --hard";
    return $stash;
}


sub let_user_edit {
    my ($filename) = @_;

    my $editor = $ENV{EDITOR} || $ENV{VISUAL} || '/usr/bin/vim';
    system "$editor $filename";
}

sub create_blob {
    my ($data_ref) = @_;

    my $tmp_file = "meta-$$.tmp";

    open my $tmp, ">", $tmp_file;
    print {$tmp} Dump($data_ref);
    print {$tmp} "\n";

    my $blob = git "hash-object -w $tmp_file";

    close $tmp;
    unlink $tmp_file;

    return $blob;
}

sub view_blob {
    my ($ref) = @_;

    my $output = git "show $ref";
    
    return ($output and $output !~ /^fatal:/) ? Load($output) : undef;
}

sub get_user_name {
    my $git_user = git 'config --get user.name';
    my $git_config = git_config();

    return $git_user || $git_config->{user}{name} || getpwuid $>;    
}

sub get_user_email {
    my ($user) = @_;
    return git 'config --get user.email' unless $user;
    fetch_tags();
    my $git_config = git_config();

    my $user_info = view_blob("user/$user") || {};

    return $user_info->{email} || $git_config->{user}{email} || $user; 
}

sub add_current_user {
    my $user  = get_user_name();
    my $email = get_user_email();
    # get user email defaults to returning username if not configured in git
    # die if not configured
    die "You need to configure a git username and email." unless $user ne $email;

    my $user_info = {email => $email};
    my $blob = create_blob($user_info);

    git_tag('-d', "user/$user") if view_blob("user/$user");
    git_tag("user/$user", $blob);
    return git "push --force origin user/$user";
}


sub meta_data_add {
    my ($entries) = @_;
    if (ref($entries) ne 'ARRAY') {
        $entries = $entries ? [ $entries ] : [];
    }

    my @meta_tags = get_meta_tags();
    my %meta_tags;
    ++$meta_tags{$_} for @meta_tags;

    our $tag_buffer;
    initialize_tag_buffer() unless $tag_buffer;
    my @tags;
    my $single_id;

    my $flush = 1;
    for my $data (@$entries) {
        # remember which user performed this action
        $data->{user} = get_user_name() if not exists $data->{user};
        my $changeset = $data->{changeset};

        my $meta_info = $meta_tags{"meta/$changeset"} ? view_blob("meta/$changeset") : [];
        my $id = scalar @$meta_info;
        $single_id = $id if @$entries == 1;

        my $flag = delete $data->{flush};
        $flush = 0 if defined $flag and $flag == 0; 
        $data->{stamp} = time;
        $meta_info->[$id] = $data;

        my $blob = create_blob($meta_info);
        
        my $exists = grep {m|^meta/$changeset|} get_meta_tags();
        git_tag('-d', "meta/$changeset") if $exists;
        git_tag("meta/$changeset", $blob);
        push @tags, "meta/$changeset";
    }

    push @{$tag_buffer->{meta_add}}, @tags;
    
    # this makes sure we dont update the same tag twice(on add and rm)
    # not dangerous to do, just a little bit slower
    if (my @rm_tags = @{$tag_buffer->{meta_rm}}) {
        for my $tag (@tags) {
            my $i = first_index {$_ eq $tag} @rm_tags;
            next unless defined $i;
            splice(@rm_tags, $i, 1);
        }
        $tag_buffer->{meta_rm} = \@rm_tags
    }    

    if ($flush) {
        my @buffered_tags = @{$tag_buffer->{meta_add}};
        git "push --force origin @buffered_tags" if @buffered_tags;
    }

    # the return value only makes sense for single inserts
    return if @$entries > 1;
    return $single_id;
}

sub initialize_tag_buffer {
    our $tag_buffer = {};
    $tag_buffer->{meta_add} = [];
    $tag_buffer->{meta_rm}  = [];

    return;
}


sub meta_data_rm {
    my @args = (ref $_[0] eq 'HASH') ? @_ : @_ ? {@_} : ();
    # force into array of hashrefs

    our $recent_meta_data;
    ++$recent_meta_data and git "fetch origin --tags" if not $recent_meta_data;

    our $tag_buffer;
    initialize_tag_buffer() unless $tag_buffer;

    my @tags;
    my $flush = 1;
    for my $arg (@args) {
        my $meta_info = view_blob("meta/$arg->{changeset}");
        return unless $meta_info;

        splice(@$meta_info, $arg->{id}, 1);
        my $blob = create_blob($meta_info);
        git_tag('-d', "meta/$arg->{changeset}");
        git_tag("meta/$arg->{changeset}", $blob);
        push @tags, "meta/$arg->{changeset}";
        $flush = 0 if exists $arg->{flush} and $arg->{flush} == 0;
    }

    push @{$tag_buffer->{meta_rm}}, @tags;

    # this makes sure we dont update the same tag twice(on add and rm)
    # not dangerous to do, just a little bit slower
    if (my @add_tags = @{$tag_buffer->{meta_add}}) {
        for my $tag (@tags) {
            my $i = first_index {$_ eq $tag} @add_tags;
            next unless defined $i;
            splice(@add_tags, $i, 1);
        }
        $tag_buffer->{meta_rm} = \@add_tags;
    }

    if ($flush) {
        my @buffered_tags = @{$tag_buffer->{meta_rm}};
        git "push --force origin @buffered_tags" if @buffered_tags;
    }

    return;
}


sub meta_data_rm_all {
    my ($changeset) = @_;

    git "fetch origin --tags";
    my $meta_tag = ($changeset =~ m{^meta/}) ? $changeset : 
        "meta/$changeset";

    git_tag('-d', "$meta_tag");
    git "push origin :$meta_tag";
}

sub fetch_tags {
    our $recent_tags;
    ++$recent_tags and git "fetch origin --tags" unless $recent_tags;
}

sub get_meta_tags {
    my (%args) = @_;
    $args{fetch} //= 1;
    fetch_tags() if $args{fetch};

    my $meta_tag_string = git "tag -l 'meta/*'";
    return split "\n", $meta_tag_string;
}


sub meta_data_rm_project {
    my ($project) = @_;

    my @meta_tags = get_meta_tags();
    meta_data_rm_all($_) for @meta_tags;

    return;
}


sub new_branch_version {
    my ($branch, $new_major_version) = @_;

    my $latest  = current_branch_version_details( $branch );
    my $major   = $latest->{major_version};
    my $minor   = $latest->{minor_version} + 1;

    if ($new_major_version) {
        $major += 1;
        $minor = 0;
    }

    return "$major.$minor";
}


sub new_version_tag {
    my ($branch, $new_major_version) = @_;

    my $tag_prefix  = version_tag_prefix( $branch );
    my $version     = new_branch_version( $branch, $new_major_version );

    return "$tag_prefix$version";
}


sub project_config {
    my $project_name = shift;

    my @files = (GITC_CONFIG);
    # we can't pull from the per-project dir if we specify the project_name
    my $project_file;
    unless ($project_name) {
        my $root = project_root();
        $project_file = $root . '/gitc.config';
        push(@files, $project_file);
    }

    push(@files, $ENV{HOME} . '/.gitc/gitc.config');
    # we default to looking up the project name via git if not passed in
    $project_name ||=  project_name();
    if ($ENV{GITC_CONFIG}) {
        push(@files, split(':', $ENV{GITC_CONFIG}));
    }
    
    my $projects;
    local $YAML::Syck::UseCode = 1;
    foreach my $file (@files) {
        next unless -f $file;
        my $data = eval {YAML::Syck::LoadFile($file)};
        # Allow the config file that is in the project_dir to not have to
        # specify itself This will allow that configuration file to be
        # formatted slightly differently but in a way which would make more
        # sense locally to that project
        if ($file eq $project_file) {
            if (!$data->{$project_name} and keys %{$data}) {
                $data = {$project_name => $data};
            }
        }
    
        $projects = merge $projects, $data;
    }

    my $project_config = $projects->{ $project_name } // $projects;
    
    die "No config found!\n" if !keys %{ $project_config // {} };

    return $project_config;
}


sub archived_tags {
    my $tag_portion = shift;
    my $dbh = dbh();
    my $project_name = project_name();

    # sort with 'BINARY' to force case sensitive sorting
    # so that it matches Git's sort order
    my $sql = q{
        SELECT  sha1, tag_name
        FROM    tag_archive
        WHERE   project = ?
    };

    if ($tag_portion) {
        $sql .= 'AND tag_name LIKE ?';
        $tag_portion = '%' . $tag_portion . '%';
    }

    $sql .= q{
        ORDER BY BINARY tag_name
    };
    my $refs = $dbh->selectall_arrayref( $sql, undef, $project_name, $tag_portion || () );
    return $refs;
}


sub branch_basis {
    my $branch_point = shift or return 'unknown';

    my @decorations = commit_decorations($branch_point);
    for (@decorations) {
        return $1 if m{/to-(master|test|stage|prod)$};
        return $1 if m{^refs/remotes/origin/(master|test|stage|prod)$};
        return $1 if m{^refs/tags/cs/(.*)/head$};
        return $1 if m{^refs/tags/(test|stage|prod)/[\dTZ_-]{20}$};
        return $1 if m{^refs/remotes/origin/pu/(.*)$};
    }

    return 'unknown';
}


# Implementation note:
#
# To find the branch point, we traverse the branch's commit history looking
# for the first commit.  The branch point is that commit's parent.  There are
# a few edge cases that need to be handled along the way.
sub branch_point {
    my $ref = shift;
    $ref = current_branch() if not defined $ref;
    my $changeset = short_ref_name($ref)
        or die "You can only find branch points for changeset branches\n";
    my $ref_ptr = is_valid_ref($ref)
        or die "You gave branch_point an invalid ref\n";

    # build the log command
    my %to = map { m{/to-(.*)$} ? ( $1 => 1 ) : () }
        git "tag -l cs/$changeset/*";
    my @excludes = map { $to{$_} ? "^cs/$changeset/to-$_~1" : "^origin/$_" }
        qw( master test stage prod );

    # traverse the commits along this changeset branch
    my $saw_a_commit;
    my $parent;
    my $done;
    traverse_commits( "--first-parent $ref @excludes --", sub {
        my ($args) = @_;
        $saw_a_commit = 1;
        return if $done;
        my @parents = @{ $args->{parents} };
        if ( @parents > 1 ) {  # merge commit
            $done = 1;
            $parent = $parents[1];  # second parent is merge source
            return;
        }
        for my $decoration ( commit_decorations($args->{commit}) ) {
            if ( $decoration =~ m{/cs/(.*)/head$} and $1 ne $changeset ) {
                $done = 1;
                $parent = $args->{commit};
                return;
            }
            elsif( $decoration =~ m{/pu/(.*)$} and $1 ne $changeset ) {
                $done = 1;
                $parent = $args->{commit};
                return;
            }
        }
        ($parent) = @{ $args->{parents} };
    });

    return $ref_ptr if not $saw_a_commit;  # no changeset commits yet
    return if not $parent;
    return $parent;
}


sub changeset_group {
    my ($changeset) = @_;

    # handle the trivial cases
    die "Cannot determine the changeset group for undef"
        if not defined $changeset;
    my ( $prefix, $number ) = $changeset =~ m{
        ^ ([a-zA-Z-]+) # 'e', 'TE-' or 'quickfix' probably
        (\d*)         # the Eventum number
    }xms;

    my $project_name = project_name();

    my @meta_tags = get_meta_tags();
    my @changesets = grep {defined $prefix ? /$prefix$number/ : $_ eq $changeset} 
        map {s{^meta/}{}} @meta_tags;
    my @open_changesets = grep {my $meta_info = view_blob($_); $meta_info->[-1]{action} eq 'open'} @changesets;
    my $changesets = \@open_changesets;

    return $changesets if not defined $prefix;
    return $changesets if $prefix ne 'e';

    # Eventum changesets
    my @peers = grep { /(\d+)/ and $1 == $number } @$changesets;
    sort_changesets_by_name(\@peers);
    return \@peers;
}


sub changeset_merged_to {
    my ($changeset) = @_;

    my @merged_to;
    for my $env (qw( master test stage prod )) {
        push @merged_to, $env if is_valid_ref("cs/$changeset/to-$env");
    }

    return wantarray ? @merged_to : join(', ', @merged_to);
}


use Date::Parse;

sub changesets_promoted_between {
    my ($args) = @_;
    my $project = $args->{project} or die "No project\n";
    my $target  = $args->{target}  or die "No target\n";
    my $start   = $args->{start}   or die "No start time\n";
    my $end     = $args->{end}     or die "No end time\n";

    $start = str2time($start);
    $end   = str2time($end);

    my @meta_tags = get_meta_tags();
    my $changesets = [];
    for my $tag (@meta_tags) {
        my ($cs_name) = $tag =~ m{^meta/(.*)}; 
        my $meta_info = view_blob($tag);
        my ($ok_target, $ok_time);
        for my $entry (@$meta_info) {
            ($ok_target, $ok_time) = ();
            next unless $entry->{action} eq 'promote';
            my $stamp = $entry->{stamp};
            ++$ok_target if $entry->{target} eq $target;
            ++$ok_time if ($stamp > $start and $stamp < $end);
        }
        push @$changesets, $cs_name if ($ok_target and $ok_time); 
    }

    return @$changesets;
}


sub commit_decorations {
    my ($commit) = @_;
    our %decorations;
    our $decorations_populated_from_disk;

    # build the decorations cache
    if ( not $decorations_populated_from_disk ) {
        $decorations_populated_from_disk = 1;
        %decorations = ();  # start fresh
        my %packed_refs;    # map refs to commits (inverse of %decorations)

        # process packed refs (before loose refs)
        if ( -e '.git/packed-refs' ) {
            open my $refs, '<', '.git/packed-refs'
                or die "Unable to open packed refs: $!\n";
            while ( my $line = <$refs> ) {
                chomp $line;
                next if $line =~ m/^#/;  # skip comments
                my ( $commit, $ref ) = split / /, $line, 2;
                next if not $commit;
                next if not $ref;
                $packed_refs{$ref} = $commit;
                $decorations{$commit}{$ref} = 1;
            }
        }

        # process all loose refs
        open my $refs, '-|', 'find .git/refs -type f'
            or die "Unable to run find: $!\n";
        while ( my $ref = <$refs> ) {
            chomp $ref;
            my $commit = do {
                open my $fh, '<', "$ref";
                local $/;
                <$fh>;
            };
            chomp $commit;
            $ref =~ s{\.git/refs/}{};
            if ( my $stale_commit = delete $packed_refs{"refs/$ref"} ) {
                delete $decorations{$stale_commit}{"refs/$ref"};
            }
            $decorations{$commit}{"refs/$ref"} = 1;
        }
    }

    if ( not $decorations{$commit} ) {
        return if wantarray;
        return [];
    }
    my @ds = keys %{ $decorations{$commit} };
    return wantarray ? @ds : \@ds;
}


sub current_branch_version {
    my ($branch) = @_;

    return current_branch_version_details( $branch )->{full_version};
}

sub current_branch_version_details {
    my ($branch) = @_;

    die "Project not setup to support version tagging"
        unless project_config()->{use_version_tags};

    my $tag_prefix = version_tag_prefix( $branch );
    my @versions = git("tag -l $tag_prefix*");
    #XXX Would be nice to support different version # formats
    return {
        major_version   => 1,
        minor_version   => 0,
        full_version    => '1.0',
    } unless @versions;

    # Get rid of tag prefixes so we have numbers to work with...
    @versions = map { s/$tag_prefix//; $_ } @versions;
    @versions = sort { $a <=> $b } @versions;

    my $major_version = $versions[-1];
    # remove the minor version number at the end
    $major_version =~ s/\.\d+$//;

    # Get all tags for the current major version...
    @versions = grep { /^$major_version\./ } @versions;
    # ...then remove the tag major version and sort by minor version
    @versions = map { s/^$major_version\.//; $_ } @versions;
    # ...then sort numerically
    @versions = sort { $a <=> $b } @versions;
    # ...so our latest minor version is the last in the list
    my $minor_version = pop @versions;

    return {
        major_version   => $major_version,
        minor_version   => $minor_version,
        full_version    => "$major_version.$minor_version",
    };
}


sub environment_preceding {
    my ($target) = @_;

    my @environments = qw( master test stage prod );
    my $i = first_index { $target eq $_ } @environments;
    die "Unknown environment name: $target\n" if $i < 0;
    return if $i == 0;
    return $environments[ $i-1 ];
}


sub full_changeset_name {
    my ($name, %params) = @_;
    die "'$name' doesn't look like a changeset name\n" if $name =~ m{/};

    # cache searches since they're slow
    our %cache;
    return $cache{$name} if exists $cache{$name};

    my $full_name
        = is_valid_ref("cs/$name/head")   ? "cs/$name/head"    # merged
        : is_valid_ref("origin/pu/$name") ? "origin/pu/$name"  # pending
        : is_valid_ref($name)             ? $name              # open
        : undef;

    unless (defined $full_name) {
        return if $params{missing_ok};
        die "Cannot determine a full changeset name for '$name'\n";
    }

    return $cache{$name} = $full_name;
}


sub git_dir {

    # perhaps the path is already cached?
    our $git_dir;
    return $git_dir if defined $git_dir;

    # nope, ask Git where .git is
    require Cwd;
    my ($raw) = git "rev-parse --git-dir";
    return $git_dir = Cwd::realpath($raw);
}


sub git_fetch_and_clean_up {
    git "remote update -p origin";
    git "gc --auto";
    return;
}


sub git_tag {
    our %decorations;
    if ( $_[0] eq '-d' ) {  # deleting a tag
        my ( $d, $name ) = @_;
        my $commit = git "rev-parse $name";
        git "tag $d $name";
        delete $decorations{$commit}{"refs/tags/$name"};
    }
    else {
        my ( $f, $name, $commit ) = @_ == 3 ? @_ : ( '', @_ );
        $commit = git "rev-parse $commit" if $commit eq 'HEAD';
        git "tag $f $name $commit";
        $decorations{$commit}{"refs/tags/$name"} = 1;
    }

    return;
}


sub highest_quickfix_number {
    my ($project_name) = @_;

    git 'fetch origin --tags';
    my @quickfixes = grep {m|^meta/quickfix|} get_meta_tags();
    my @numbers = map { /quickfix(\d+)$/ ? $1 : () } @quickfixes;
    return 0 if not @numbers;
    return max @numbers;
}


use Date::Format;

sub history {
    my ( $project_name, $changeset )
        = @_ == 2 ? @_ : ( project_name(), @_ );

    my $changeset_exists = grep {m|^meta/$changeset|} get_meta_tags();
    return [] unless $changeset_exists;

    my $events = view_blob("meta/$changeset");
    for (@$events) {
        my @lt = localtime $_->{stamp};
        $_->{stamp} = strftime("%Y-%m-%d %T", @lt);
    }

    return wantarray ? @$events : $events;
}


sub history_owner {
    my $history = shift;
    my $open = first { $_->{action} eq 'open' } @$history;
    return $open->{user};
}


sub history_reviewer {
    my $history = shift;
    my $last;

    # the most recent person to whom the changeset was submitted
    $last = first { $_->{action} eq 'submit' } reverse @$history;
    return if not $last;
    return $last->{reviewer};
}


sub history_status {
    my $history = shift;
    my $last
        = first { $_->{action} !~ m/^(touch|promote|demote)$/ } reverse @$history;
    my $action = $last->{action};
    return {
        open   => 'open',
        submit => 'submitted',
        review => 'reviewing',
        fail   => 'failed',
        pass   => 'merged',
        edit   => 'open',
    }->{$action};
}


sub history_submitter {
    my ($history) = @_;
    my $last = first { $_->{action} eq 'submit' } reverse @$history;
    return if not $last;
    return $last->{user};
}


sub is_auto_fetch {
    my $config = git_config();
    my $value = $config->{gitc}{fetch} || 'auto';
    return $value eq 'auto';
}


sub is_merge_commit {
    my ($ref)     = @_;
    my ($parents) = git "log -1 --no-color --pretty=format:%P $ref";
    return if not $parents;    # the root commit is not a merge
    my @parents = split / /, $parents;
    return @parents > 1;
}


sub is_suspendable {
    our $suspend_file = '.git/gitc-suspended-process';
    open my $fh, '>', $suspend_file
        or die "Unable to create $suspend_file: $!\n";
    print $fh "$$\n";
    my $command = command_name();
    print $fh "gitc $command is suspended.  Resume it with 'fg'\n";
    our $is_suspendable = 1;
    close $fh;
}
END {
    our $is_suspendable;
    our $suspend_file;
    unlink $suspend_file if $is_suspendable and -e $suspend_file;
}


sub is_valid_ref {
    my ($name) = @_;
    return if not defined $name;
    my $sha1 = eval { git "rev-parse --verify --quiet $name" };
    return $sha1 if $sha1;
    return;
}


sub open_packed_refs {
    my ($prefix) = @_;
    require File::Temp;
    if ( not defined $prefix ) {
        require Carp;
        Carp::croak("open_packed_refs requires a prefix argument");
    }
    my $git_dir = git_dir();
    my $packed_refs = "$git_dir/packed-refs";
    return if not -e $packed_refs;
    open my $old_fh, '<', $packed_refs or die "Can't open $packed_refs: $!";

    # verify that refs were packed with 'peeled'
    my $header = <$old_fh>;
    my ($technique) = $header =~ /^# pack-refs with: (\S+)/;
    $technique ||= '';
    die "Unknown ref packing technique: $technique\n"
        if $technique ne 'peeled';

    # open a temporary file to store the new tags
    my ( $new_fh, $new_filename )
        = File::Temp::tempfile( "$prefix-XXXX", DIR => $git_dir );

    print $new_fh $header;
    return ( $old_fh, $new_fh, $new_filename );
}


sub parse_changeset_spec {
    my ($spec) = @_;

    # no $spec means to infer everything from pwd
    if ( not defined $spec ) {
        my $changeset = current_branch();
        my $project   = project_name();
        return ( $project, $changeset );
    }

    # handle the traditional, full changeset name
    return ( $1, $2 ) if $spec =~ m/^(.*)#(.*)$/;

    my $project = project_name();
    die   "Unable to determine the project for changeset spec '$spec'.\n"
        . "You either need to be inside a gitc repository or specify\n"
        . "the full changeset name like project#changeset\n"
        if not $project;
    return ( $project, $spec );
}


sub project_name {
    our $project_name;
    return $project_name if defined $project_name;
    my ($line) = git "show HEAD:.gitc";
    die "You need to specify a project name in a .gitc file. See the HOWTO for more details." unless $line;
    my ($name) = $line =~ m/^\s*name\s*:\s*(.*)$/;
    return $project_name = $name;
}


sub project_root {
    my $git_dir = git_dir();
    if ( not $git_dir =~ s{/.git$}{} ) {
        require Carp;
        Carp::croak("Bare repositories don't have a meaningful project root");
    }
    return $git_dir;
}


sub remote_branch_exists {
    my ($branch) = @_;
    my @remote_branches = git "branch --no-color -r";
    return scalar grep { $_ eq "  origin/$branch" } @remote_branches
}


sub sendmail {
    my ($args) = @_;
    my $recipient = $args->{to}           || die "No mail recipient";
    my $subject   = $args->{subject}      || die "No mail subject";
    my $content   = $args->{content}      || q{};
    my $link      = $args->{link}         || q{};
    my $project   = $args->{project}      || project_name();
    my $changeset = $args->{changeset}    || die "No mail changeset ID";

    # determine a temporary file name template
    my $command = eval { command_name() } || 'unknown';

    # CONFIGURE (optional)
    # Add any site specific custom headers here
    # TODO this should be pulled from a configuration file
    my $extra_headers = '';

    # create the email template
    require File::Temp;
    my ( $temp_fh, $temp_file )
        = File::Temp::tempfile( "gitc-$command-XXXX", UNLINK => 1 );
    my $name = get_user_name() . ' <' . get_user_email() . '>';
    print $temp_fh <<ENDMAIL;
To: $recipient
From: $name
Subject: [$project#$changeset] $subject
$extra_headers

$link

$content
ENDMAIL
    close $temp_fh or die "Couldn't close temporary file for mail";

    let_user_edit($temp_file) if -t STDOUT;
    die "Aborting at user's request\n" if -s $temp_file <= 10;

    # delay sending the email if necessary
    my $sendmail = find_sendmail();
    my $send_it = sub { system qq($sendmail -t < $temp_file) };
    return $send_it if $args->{lazy};
    $send_it->();
    return;
}


sub find_sendmail {
    # We could cache this, but there's not much point - no single run
    # of gitc ever calls this method more than once.

    # Yanked from MIME::Lite, slightly tweaked
    my $sendmail = '/usr/sbin/sendmail';
    ( -x $sendmail ) or ($sendmail = '/usr/lib/sendmail' );
    ( -x $sendmail ) or ($sendmail = 'sendmail' );
    unless (-x $sendmail) {
        require File::Spec;
        for my $dir (File::Spec->path) {
            if ( -x "$dir/sendmail" ) {
                $sendmail = "$dir/sendmail";
                last;
            }
        }
    }
    unless (-x $sendmail) {
        die "Couldn't find an executable sendmail";
    }
    return $sendmail;
}


sub short_ref_name {
    my ($ref) = @_;
    return if not defined $ref;

    my $name = qr{[^/]+}o;  # a name is anything except slashes
    my @patterns = (
        qr{cs/($name)/head}o,    # merged changeset
        qr{origin/pu/($name)}o,  # pending review
        qr{^($name)$}o,          # already a short name
    );
    for my $pattern (@patterns) {
        return $1 if $ref =~ $pattern;
    }

    # we don't know how to shorten this kind of ref
    return;
}


sub sort_changesets_by_name {
    my ($ids) = @_;
    @$ids =
        map  { $_->[0] }
        sort {
            $a->[1] cmp $b->[1]
                or
            $a->[2] <=> $b->[2]
                or
            $a->[3] cmp $b->[3]
        }
        map {
            m/^(\D+)(\d+)(\D*)$/ ? [ $_, $1, $2, $3 ]
                                 : [ $_, $_, 999_999, '' ]
        } @$ids;

    return;
}


sub split_decorations {
    my ($decorations) = @_;
    return if not defined $decorations;
    return if length($decorations) < 4;
    $decorations = substr $decorations, 2, -1;  # remove " (" and ")"
    return split /, /, $decorations;
}


sub toplevel {
    chomp( my $top = qx{git rev-parse --show-toplevel} );

    unless ( $top ) {
        die 'Not a git repository (or any of the parent directories): .git';
    }

    return $top;
}


# call a coderef for each commit in a "git log" invocation
sub traverse_commits {
    my ( $git_log_arguments, $callback ) = @_;

    open my $git, '-|', "git log --no-color --pretty=raw $git_log_arguments" or die;

    my @commit_lines;
    my @accumulator;
    my $finished = 0;
    COMMIT:
    while ( not $finished ) {

        # collect all information about one commit
        while (1) {
            my $line = <$git>;
            if ( not defined $line ) {
                @commit_lines = @accumulator;
                @accumulator  = ();
                $finished     = 1;
                last;
            }
            chomp $line;
            if ( @accumulator and $line =~ m/^commit / ) {
                @commit_lines = @accumulator;
                @accumulator  = ($line);
                last;
            }
            push @accumulator, $line;
        }
        last if not @commit_lines;

        # extract commit ID and parentage
        my ($commit) = $commit_lines[0] =~ /^commit (\S+)/;
        my @parents  = map { /^parent (.*)$/  ? $1 : () } @commit_lines[2,3];
        die "Unable to locate commit" if not $commit;
        die "Unable to locate parents" if not @parents and not $finished;

        # call the coderef
        $callback->({
            commit  => $commit,
            parents => \@parents,
            message => [ @commit_lines[ 6 .. $#commit_lines ] ],
        });
    }

    return;
}



sub unmerged_changesets {
    my ($project_name) = @_;

    my @meta_tags = get_meta_tags();
    my @unmerged;
    for my $tag (@meta_tags) {
        my $meta_info = view_blob($tag);
        my $passed;
        for my $entry (@$meta_info) {
            ++$passed if $entry->{action} eq 'pass';
        }
        push @unmerged, @$meta_info unless $passed;
    }

    my %result;
    for my $event (sort {$a->{stamp} <=> $b->{stamp}} @unmerged) {
        my @lt = localtime $event->{stamp};
        $event->{stamp} = strftime("%Y-%m-%d %T", @lt);
        push @{ $result{ $event->{changeset} } }, $event;
    }

    return \%result;
}


sub unpromoted {
    my ($from, $to) = @_;
    $from = [ $from ] if not ref $from;
    $to   = [ $to   ] if not ref $to;

    my $backstop = backstop_commit( $from, $to );

    my @source_changes = changesets_in( $from, $backstop );
    my @target_changes = changesets_in( $to,   $backstop );
    return _missing_changesets( \@source_changes, \@target_changes );
}

our $meta_cache;

sub cache_meta_data {
    my (@refs) = @_;
    @refs = get_meta_tags(fetch => 0) unless @refs;
    @refs = map {m|^meta/| ? $_ : "meta/$_"} @refs;

    push @$meta_cache, map { {$_ => git "rev-parse $_"} } @refs;

    return;
}

sub restore_meta_data {
    our $meta_cache;
    die "You cannot restore meta data without caching any data" unless $meta_cache;

    git_tag('-d', $_) for map {keys %$_} @$meta_cache;
    git_tag(%$_) for @$meta_cache;
    git sprintf "push --force origin %s", join ' ', map {keys %$_} @$meta_cache;

    undef $meta_cache;
    return;
}

sub version_tag_prefix {
    my ($branch) = @_;

    return "version/$branch/";
}

# find a commit shared by @$from and @$to beyond which changesets_in
# need not traverse.  This is strictly an optimization to try and make
# changesets_in() faster for large repositories
sub backstop_commit {
    return is_valid_ref('cvs');
}

# returns a list of the changesets that are reachable from a list
# of commits.  In the resulting list, child commits come before their
# parents.
# Takes an optional commit ID ($backstop) beyond which it need not search.
sub changesets_in {
    my ($commits, $backstop) = @_;

    # view all commits in $from that are not in $to
    my @command = qw( git log --no-color --first-parent --topo-order --pretty=format:%H );
    push @command, " ^$backstop" if $backstop;
    open my $log, "-|", @command, @$commits or die;

    # extract the implied changesets (based on their merge points)
    my $env = qr/(?:master|test|stage|prod)/;
    my $cs  = qr{[^/]+};
    my @rxen = (
        # promoted changeset
        qr{^refs/tags/cs/($cs)/to-$env$}o,
        qr{^refs/tags/cs/($cs)/head$}o,    # merged changeset
        qr{^refs/remotes/origin/pu/(.+)$}o,  # pending review
    );
    my @included;
    my %seen;
    while ( my $commit = <$log> ) {
        chomp $commit;
        for my $name ( commit_decorations($commit) ) {
            for my $rx (@rxen) {
                if ( $name =~ $rx ) {
                    my $changeset = $1;
                    next if $seen{$changeset}++;
                    push @included, $changeset;
                }
                elsif ( $name =~ m{^refs/tags/cs/($cs)/rm-$env$}o ) {
                    my $changeset = $1;
                    next if $seen{$changeset}++;
                }
            }
        }
    }

    return @included;
}

# returns a list of changesets that are present in $source_changes but
# missing from $target_changes
sub _missing_changesets {
    my ($source_changes, $target_changes) = @_;

    my %source = map { $_ => 1 } @$source_changes;
    my %target = map { $_ => 1 } @$target_changes;
    delete @source{ keys %target };

    # maintain the same changeset order
    return grep { $source{$_} } @$source_changes;
}



sub command_name {
    my ($command) = $0 =~ m{/gitc-(\w+)$};
    return $command if $command;
    die "Unable to determine the command name from $0\n";
}


sub _states {
    my ( $self, $command, $target ) = @_;

    my $statuses = its_config()->{ $command }
        or die 'No ' . its->label_service . " statuses for $command";

    # handle the common case
    if ( not $target ) {
        die "No initial status" unless $statuses->{from};
        die "No final status" unless $statuses->{to};
        return ( $statuses );
    }

    # promotions need another level of dereference
    die "No initial status for target $target" unless $statuses->{$target}{from};
    die "No final status for target $target" unless $statuses->{$target}{to};

    return $statuses->{$target};
}


sub state_blocked {
    my ( $command, $state ) = @_;

    my $statuses = its_config()->{ $command }
        or die 'No ' . its()->label_service . " statuses for $command";

    # promotions need another level of dereference
    my $block = $statuses->{ block };

    return unless $block;

    return 1 if any { warn " \$_: $_, \$state: $state.\n";$_ eq $state } @{$block};
    
    return;
}

1;

__END__

=pod

=head1 NAME

App::Gitc::Util - The workhorse of gitc

=head1 VERSION

version 0.60

=head1 Exported Subroutines

=head2 confirm($message)

Displays C<$message> and waits for the user to press 'y' or 'n'.  If he enters
'y', a true value is returned.  If he enters 'n', a false value is returned.

=head2 current_branch

Returns the name of the branch that's currently checked out in Git.

=head2 its_config

Returns the config specific to this project's ITS.

=head2 eventum_statuses

Returns the from and to state based on a command provided to GITC.

=head2 its

Returns an ITS pseudo-object

Some day it would be nice to add 'new' to these and return a real instantiated
object... but this fits the bill.

=head2 its_for_changeset

Guesses which ITS object we need based on the changeset name, returns the
object if it supports it, or just the class name.

=head2 git

A wrapper for executing git commands and handling errors.
In void context, the command is executed using C<system>.  In scalar context,
the command's output is captured, chomped and returned.  In list context, a
list of chomped lines is returned.

=head2 git_config

Returns a nested hash data structure representing Git's configuration.

=head2 guarantee_a_clean_working_directory

Make sure that all tracked files match the index and match the commit object.
If the working directory is not clean, ask the user whether to proceed.  If he
wants to proceed, this sub stashes the current changes and returns the stash's
commit ID.  In this case, it's the caller's responsibility to invoke "git
stash apply" with this ID to restore the changes, when appropriate.

If the user does not want to proceed, an exception is thrown.  In most cases,
this will accomplish what the user desired by halting the program.

If the directory is clean, a false value is returned which indicates that
nothing was stashed while guaranteeing cleanliness.

=head2 let_user_edit($filename)

Open's the user's preferred editor so that he can interactively edit
C<$filename>.

=head2 meta_data_add($data)

Appends the contents of the hashref C<$data> to the changeset meta data.
Returns a unique identifier which can be used by L</meta_data_rm>.

=head2 meta_data_rm({id => $id, changeset => $changeset})

Deletes the meta data entry with ID C<$id> in changeset C<$changeset>.

=head2 meta_data_rm_all($changeset)

Deletes all changeset meta data for the changeset named C<$changeset>.  The
project is determined by the current working directory.  Returns the number of
meta data entries that were deleted.

=head2 meta_data_rm_project($project)

Deletes all changeset meta data for the project named C<$project>.  Returns
the number of meta data entries that were deleted.

=head2 new_branch_version($branch, $new_major_version)

Increments and returns the most recent version tagged for the given C<$branch>.
This only applies to projects that have the 'use_version_tags' config set to true.
If $new_major_version is truthy, increment the major version # and make minor 0

=head2 new_version_tag($branch)

Returns a tag name for an updated version of the given C<$branch>.
This only applies to projects that have the 'use_version_tags' config set to true.

=head2 project_config

Returns a hashref with configuration details about this project.

Configuration is loaded from the following sources:
* /etc/gitc/gitc.config
* $PROJECT_ROOT/gitc.config
* $HOME/.gitc/gitc.config

It will then parse all the paths in the GITC_CONFIG environment variable 
(separated by :).

These configuration files are all merged together with the later files
overriding the earlier.  

Finally we merge the default config with the per-project configuration
we found to generate a final fully baked configuration for the project.

=head1 Optionally Exported Subroutines

The following subroutines are only exported when they're asked for.

=head2 archived_tags

Returns an arrayref of arrayrefs representing all tags that have been archived
for the current project.  The internal arrayrefs hold the tag's SHA1 and ref
name, in that order.  The tags are returned in sorted order increasing by ref
name (the same order as F<.git/packed-refs>).

=head2 branch_basis($commit_id)

Determines the base branch for the given C<$commit_id>.  The base branch is
the most specific branch on which this commit lies.  It's typically used for
converting an earlier commit on a branch (such as tag
"test/2009-12-29T12_13_14") into the name of the branch (such as "test").  If
we can't determine the branch name, returns 'unknown'.

=head2 branch_point($ref)

Returns a commit ID indicating the commit on which the branch at C<$ref>
is based.  For example, if we have a topology like this

              o-----A
             /
    o---o---X---o---M

where A is the head of a branch and M is the head of master.  The branch point
of A is commit X.  If A is later merged into M, the branch point remains the
same.

See L</full_changeset_name> for a way to convert a changeset name into
a value suitable for C<$ref>.

=head2 changeset_group($changeset)

Given a C<$changeset> name, returns an arrayref of the changeset names (for
existing changesets) in this same changeset group.  A changeset group is
defined as any changesets that share the same Eventum number or prefix (if the
group is not associated with an Eventum issue).  The resulting list of
changesets is sorted in the traditional order.  See
L</sort_changesets_by_name>.

TODO: This code should be reworked to use logic for each its

=head2 changeset_merged_to($changeset)

Returns a list (or string, depending on context) of environments to which this
changeset has been merged.  If it's not been merged yet, the list is empty (of
course).

=head2 changesets_promoted_between

Given a hashref of named arguments, returns a list of changeset names
indicating which changesets were promoted to C<$target> for C<$project>
between the times C<$start> and C<$end>.  The times should be in the format
'yyyy-mm-ddTHH:MM:SS'

=head2 commit_decorations($commit)

Returns a list (or arrayref, depending on context) of decorations associated
with C<$commit> (a commit ID).  In cases where many Git processes are forked
to obtain decoration info, this function can be substantially faster.

=head2 current_branch_version($branch)

Determines the most recent version tagged for the given C<$branch>.  This only
applies to projects that have the 'use_version_tags' config set to true.

=head2 environment_preceding($environment)

Given an C<$environment> name, returns the name of the environment that
precedes that one in promotion order.  For instance
C<environment_preceding('stage')> produces 'test'.

If there is no such C<$environment>, an exception is thrown.  If no
environment precedes the one given, returns C<undef>.

=head2 full_changeset_name($name)

Given the C<$name> of a changeset, returns a Git ref which correctly addresses
that changeset's head.  It doesn't matter if the changeset is newly opened,
pending review or merged.  The resulting ref points at the head of that
changeset.

See also L<short_ref_name>.

=head2 git_dir

Returns the absolute path of the current .git directory.  Bare repositories
and normal repositories are both handled correctly.

=head2 git_fetch_and_clean_up

Fetches the remote repository and does a little routine maintenance to make
sure that the repository performs optimally.  This is called from commands
which are consistently, but infrequently, run by developers.  It helps to hide
some of the repository maintenace that Git requires.

=head2 git_tag

A wrapper around "git tag" which updates the commit decoration hash (See
L</commit_decorations>.  This should always be used instead of calling "git
tag" directly.

Returns nothing useful.

=head2 highest_quickfix_number($project_name)

Returns the highest number used for any quickfix changeset in
C<$project_name>.  If there have been no quickfix changesets, returns 0.

=head2 history($project_name, $changeset)

Returns a list (or arrayref, depending on context) of hashes.  Each hash
represents the details about a particular event related to the changeset named
C<$changeset> within the project named C<$project_name>.  The events are
returned in chronological order.

If C<$project_name> is omitted, the name of the project in the current working
directory is used instead.

=head2 history_owner($history)

Returns the name of the owner of a changeset based on a changeset's
C<$history>.

=head2 history_reviewer

Returns the name of the most recent reviewer of this changeset.  If this
changeset has never been submitted for review, returns C<undef>.

=head2 history_status

Returns the current status of a changeset based on a changeset's C<$history>.

=head2 history_submitter

Returns the user ID of the most recent submitter.  If there is no submitter in
the history, returns C<undef>.

=head2 is_auto_fetch

Returns a true value if this user wants to automatically fetch from the
origin.

=head2 is_merge_commit($ref)

Returns true if the commit pointed at by C<$ref> is a merge commit. Otherwise,
it returns false.

=head2 is_suspendable

Marks the currently running gitc command as suspendable.  If a command which
is marked as suspendable is currently suspended, calling this function throws
an exception.

Any command which suspends itself should call this function.  It helps avoid
user error when the user tries to run the same command again instead of
resuming the suspended command.

=head2 is_valid_ref($name)

Returns a commit ID if C<$name> is a valid Git "ref".  Otherwise, it returns
false.

=head2 open_packed_refs($prefix)

Opens the current repository's packed refs and returns:

    * a file handle to the opened packed refs
    * a file handle to a temporary file
    * the name of the temporary file

The first line read from the first filehandle is the first packed ref in the
file.  Any header lines are stripped and automatically copied to the new
temporary file.

The mandatory C<$prefix> argument specifies a prefix for the temporary file.
This should usually be the name of the gitc command calling
L</open_packed_refs>.

The temporary file does not automatically delete itself.  The caller is
responsible for that.

=head2 parse_changeset_spec($spec)

C<$spec> is a single command line argument which is supposed to uniquely
identify a changeset and its associated project.  C<undef> means "infer
everything from the repository I'm in".  C<project#changeset> means to use the
specified project and changeset.  C<changeset> means to use the given
changeset within the current directory's project.

Returns a list containing the project name and the changeset name.  If there's
any trouble obtaining those two, an exception is thrown.

=head2 project_name

Returns the name of the project in the current working directory.

=head2 project_root

Returns an absolute path to the current repository's project root.
If called from a bare repository, it throws an exception.

=head2 remote_branch_exists($branch_name)

Returns true if origin has a branch named C<$branch_name>.  Otherwise, it
returns false.

=head2 sendmail($args)

Sends an email with a standard format, allowing the user to edit the template.
C<$args> is a single hashref of named arguments.  The argument C<to> specifies
the username of the recipient.  C<subject> provides the email subject.
C<changeset> is the name of the changeset associated with this email.

The following optional arguments are also accepted.  C<project> is the name of
the project related to this changeset email.  If it's omitted, the project in
the current working directory is used instead.  C<content> specifies the main
body of the email.  If omitted, an empty body template is used.  C<link>
provides a URL which is included at the top of the email.

If the C<lazy> argument is true, the email message is built but not sent.
Instead, L</sendmail> returns a code reference.  When that code reference is
called, the email is sent.  This is particularly useful when you want a user
to compose an email in one context (so he can cancel an operation early, for
example) but delay sending the email until you're certain it should go out.

=head2 find_sendmail()

Returns the full path to the sendmail binary.

=head2 short_ref_name($ref)

Given a Git C<$ref>, returns a shorter name for it.  This is typically the
name of the changeset to which C<$ref> refers.  This function is the inverse
of L</full_changeset_name>.

=head2 sort_changesets_by_name

Sorts a list of changeset names into a sensible order.  Typical usage is:

    sort_changesets_by_name( \@list_of_changesets );
    # @list_of_changesets is now sorted

=head2 split_decorations($decorations)

Converts a string of C<$decorations> as produced by C<git log --decorate> or
C<git log --pretty=format:%d> into a list of full ref names.

=head2 toplevel

Returns the top-level directory for the current branch.

=head2 traverse_commits( $log_string, $callback )

Invokes C<git log $log_string> and calls the code reference C<$callback> for
each commit encountered.  C<$callback> is invoked with the following
arguments in a hashref:

    commit  - this commit's ID
    parents - an arrayref of the commit's parent commit IDs
    message - an arrayref of the commit's message lines

=head2 unmerged_changesets($project_name)

Returns a hashref whose keys are the names of unmerged changesets and whose
values are the respective changeset histories (see L</history>).

=head2 unpromoted($from, $to)

Returns a list of the changesets which are included in C<$from> but not yet
part of C<$to>.  For example, C<unpromoted('origin/master', 'origin/test')>,
returns the changesets that are in C<master> but not in C<test>.

One way to think about it is that if you promoted C<$from> into C<$to>, what
other things would be promoted to C<$to> as a result.  This is the way that
F<gitc-unpromoted> is implemented. This subroutine implements a more
general idea of "not included in" than that command makes available.

C<$from> can also be an arrayref of branches.  In this case it means, "If I
were to promote everything listed in C<@$from>, what all would be promoted.

The order of the returned changesets is significant.  Changesets always appear
in the list before their dependencies.  In Git terms, "child commits are given
before their parents."  Since demotions are not accomodated by Git's data
model, they are placed at the end of the list of unpromoted changesets.

=head1 Private Subroutines

=head2 command_name

Returns the name of the gitc command that started this whole mess.
This is mostly a helper subroutine for eventum_transition_status.
If the command name can't be determined, an exception is thrown.

=head2 _states

Used internally to calculate target for state change.

=head2 state_blocked

Given a C<command> and a specified C<state> this checks the block list in the
project configuration and returns true if the state should block the command
from proceeding.

NOTE: Block list must be an arraref in the project configuration 

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Grant Street Group.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
