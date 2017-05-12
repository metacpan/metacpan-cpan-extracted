# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration
# Copyright © 2009,2013 Damyan Ivanov
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

package App::KGB::Client::Git;

use strict;
use warnings;

our $VERSION = 1.28;

use base 'App::KGB::Client';
use Git;
use Carp qw(confess);
__PACKAGE__->mk_accessors(
    qw( changesets old_rev new_rev refname git_dir _git _commits reflog
        squash_threshold squash_msg_template
        branch_ff_msg_template
        enable_branch_ff_notification
        tag_squash_threshold tag_squash_msg_template
    ));

use App::KGB::Change;
use App::KGB::Commit;
use App::KGB::Commit::Tag;
use IPC::Run;

=head1 NAME

App::KGB::Client::Git - Git support for KGB client

=head1 SYNOPSIS

my $c = App::KGB::Client::Git->new({
    ...
    git_dir => '/some/where',   # defaults to $ENV{GIT_DIR}
    old_rev     => 'a7c42f58',
    new_rev     => '8b37ed8a',
});

=head1 DESCRIPTION

App::KGB::Client::Git provides KGB client with knowledge about Git
repositories. Its L<|describe_commit> method returns a series of
L<App::KGB::Commit> objects, each corresponding to the next commit of the
received series.

=head1 CONSTRUCTION

=head2 App::KGB::Client::Git->new( { parameters... } )

Input data can be given in any of the following ways:

=over

=item as parameters to the constructor

    # a single commit
    my $c = App::KGB::Client::Git->new({
        old_rev => '9ae45bc',
        new_rev => 'a04d3ef',
        refname => 'master',
    });

=item as a list of revisions/refnames

    # several commits
    my $c = App::KGB::Client::Git->new({
        changesets  => [
            [ '4b3d756', '62a7c8f', 'master' ],
            [ '7a2fedc', '0d68c3a', 'my'     ],
            ...
        ],
    });

All the other ways to supply the changes data is converted internally to this
one.

=item in a file whose name is in the B<reflog> parameter

A file name of C<-> means standard input, which is the normal way for Git
post-receive hooks to get the data.

The file must contain three words separated by spaces on each line. The first
one is taken to be the old revision, the second is the new revision and the
third is the refname.

=item on the command line

Useful when testing the KGB client from the command line. If neither
B<old_rev>, B<new_rev>, B<refname> nor B<changesets> is given to the
constructor, and if @ARGV has exactly three elements, they are taken to be old
revision, new revision and refname respectively. Only one commit can be
represented on the command line.

=back

In all of the above methods, the location of the F<.git> directory can be given
in the B<git_dir> parameter, or it will be taken from the environment variable
B<GIT_DIR>.

=head2 B<git-config> parameters

The following parameters can be set in the C<[kgb]> section of
L<git-config(1)>. If present, they override the settings in the configuration
file and these given on the command line.

=over

=item project-id

The project ID.

See L<App::KGB::Client/project-id> for details.

=item web-link

See L<App::KGB::Client/web-link> for details.

=item squash-threshold I<number>

Unique to Git KGB client. Sets a threshold of the notifications produced for a
given branch update. If there are more commits in the update, instead of
producing huge amounts of notifications, the commits are "squashed" into one
notification per branch with a summary of the changes.

The default value is C<20>.

=item squash-message-template I<string>

A template for construction of squashed messages. See
L<App::KGB::Client/message-template> for details.

The default is C<${{author-name}}${ {branch}}${ {commit}}${ {module}}${ {log}}>.

=item tag-squash-threshold I<number>

Unique to Git KGB client. Sets a threshold of the notifications produced
for tag creations. If there are more tags created in the push, instead
of producing huge amounts of notifications, the tags are "squashed" into
one notification summarizing the information.

The default value is C<5>.

=item tag-squash-message-template I<string>

A template for construction of squashed tags messages. See
L<App::KGB::Client/message-template> for details.

The default is C<${{author-name}}${ {module}}${ {log}}>.

=item enable-branch-ff-notification I<bool>

Enables notifications about branch updates whose commits have already been
reported. Normally this causes a notification like C<fast forward> to appear.
If you don't like this, set it to false.

The default is C<true>.

=back

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->git_dir( $ENV{GIT_DIR} )
        unless defined( $self->git_dir );

    defined( $self->git_dir )
        or confess
        "'git_dir' is mandatory; either supply it or define GIT_DIR in the environment";


    $self->_git( Git->repository( Repository => $self->git_dir ) );

    unless ( $self->module ) {
        require Cwd;
        my @dirs = File::Spec->splitdir( Cwd::abs_path( $self->git_dir ) );
        pop @dirs if @dirs and $dirs[-1] eq '.git';
        my $module = $dirs[-1];
        $module =~ s/\.git$// if $module;
        $self->module($module);
    }

    if ( my $pid = $self->_git->config('kgb.project-id') ) {
        $self->repo_id($pid);
    }
    if ( my $wl = $self->_git->config('kgb.web-link') ) {
        $self->web_link($wl);
    }
    if ( my $st = $self->_git->config('kgb.squash-threshold') ) {
        $self->squash_threshold($st);
    }
    $self->squash_threshold(20) unless defined $self->squash_threshold;
    if ( my $tst = $self->_git->config('kgb.tag-squash-threshold') ) {
        $self->tag_squash_threshold($tst);
    }
    $self->tag_squash_threshold(5)
        unless defined $self->tag_squash_threshold;

    if ( my $smt = $self->_git->config('kgb.squash-message-template') ) {
        $self->squash_msg_template($smt);
    }
    $self->squash_msg_template('${{author-name}}${ {branch}}${ {commit}}${ {module}}${ {log}}')
        unless $self->squash_msg_template;
    if ( my $tsmt = $self->_git->config('kgb.tag-squash-message-template') ) {
        $self->tag_squash_msg_template($tsmt);
    }
    $self->tag_squash_msg_template(
        '${{author-name} }${{module}}${ {log}}'
    ) unless $self->tag_squash_msg_template;
    $self->branch_ff_msg_template('${{author-name}}${ {branch}}${ {commit}}${ {module}} fast-forward')
        unless $self->branch_ff_msg_template;

    my $ebfn = $self->_git->config('kgb.enable-branch-ff-notification');
    if ( defined($ebfn) and $ebfn ne '' ) {
        $ebfn = ( $ebfn eq 'false' ) ? 0 : 1;
        $self->enable_branch_ff_notification($ebfn);
    }
    $self->enable_branch_ff_notification(1)
        unless defined $self->enable_branch_ff_notification;

    return $self;
}

sub _parse_reflog {
    my $self = shift;

    # read changeset data from a file
    $self->changesets( [] );
    my $fh;
    open( $fh, $self->reflog // '-' )
        or die "open(" . $self->reflog // '-' . "): $!";
        # in order for '-' to open STDIN, we must use two-argument form of
        # open(). see 'perldoc -f open'
    while (<$fh>) {
        chomp;
        my @cs = split( /\s+/, $_ );
        @cs == 3
            or confess
            "Invalid data on row $.. Must contain three space-separated words";
        push @{ $self->changesets }, \@cs;
    }
    close $fh;

    die "Reflog was empty. Broken git post-receive hook?\n"
        unless @{ $self->{changesets} };
}

=head1 METHODS

=over

=item describe_commit

Returns an instance of L<App::KGB::Change> class for each commit. Returns
B<undef> when all commits were processed.

=cut

sub describe_commit {
    my $self = shift;

    $self->_detect_commits unless defined( $self->_commits );

    return shift @{ $self->_commits };
}

sub _reset {
    my $self = shift;

    $self->_commits(undef);
    $self->changesets(undef);
}

sub _detect_commits {
    my $self = shift;

    if ( defined( $self->old_rev // $self->new_rev // $self->refname ) ) {

        # single commit
        defined( $self->old_rev )
            and defined( $self->new_rev )
            and defined( $self->refname )
            or confess
            "either all of old_rev, new_rev and refname shall be present or neither";

        defined $self->changesets
            and confess
            "You can't supply both old_rev, new_rev and ref_name and changesets";

        defined $self->reflog
            and confess
            "You can't supply both old_rev, new_rev and ref_name and reflog";

        $self->changesets(
            [ [ $self->old_rev, $self->new_rev, $self->refname ] ] );
    }
    elsif ( defined( $self->changesets ) ) {

        # ready changesets
        ref( $self->changesets ) and ref( $self->changesets ) eq 'ARRAY'
            or confess "'changesets' must be an arrayref";

        for( @{ $self->changesets } ) {
            defined($_) and ref($_) and ref($_) eq 'ARRAY'
                or confess "Each changeset must be an arrayref";

            @$_ == 3 or confess "Each changeset must contain three elements";
        }

        defined $self->reflog
            and confess "You can't supply both changesets  and reflog";
    }
    elsif ( @ARGV == 3 ) {

        # a single changeset on the command line
        $self->changesets( [ [@ARGV] ] );
    }
    else {
        $self->_parse_reflog;
    }

    $self->_commits([]);

    $self->_describe_branch_updates;

    for my $next ( @{ $self->changesets } ) {
        my ( $old_rev, $new_rev, $refname ) = @$next;

        $self->_process_changeset_simple( $old_rev, $new_rev, $refname );
    }

    my @tags;
    for ( @{ $self->_commits } ) {
        push @tags, $_ if eval { $_->isa('App::KGB::Commit::Tag') };
    }

    if ( scalar(@tags) > $self->tag_squash_threshold ) {
        # remove tags from the commit stream
        @{ $self->_commits } = grep {
            not eval { $_->isa('App::KGB::Commit::Tag') }
        } @{ $self->_commits };

        $self->init_painter;
        # add a synthetic tag summary
        push @{ $self->_commits },
            $self->format_message(
            $self->tag_squash_msg_template,
            log => sprintf(
                'Pushed %s, %s, %d other tags and %s',
                $self->colorize( branch => $tags[0]->tag_name ),
                $self->colorize( branch => $tags[1]->tag_name ),
                scalar(@tags) - 3,
                $self->colorize( branch => $tags[-1]->tag_name ),
            ),
            author_login => $ENV{USER},
            author_name  => $self->_get_full_user_name,
            );
    }
}

sub _exists {
    my ( $self, $obj ) = @_;

    # we resort to running 'git cat-file' ourselves as the Git wrapper doesn't
    # provide an easy way to do so without polluting STDERR in case the object
    # doesn't exist
    #
    # Sad but true
    my ( $in, $out, $err );
    # this will exit with status 128 if the object does not exist
    IPC::Run::run [ 'git', "--git-dir=" . $self->git_dir, 'cat-file', '-e',
        $obj ], \$in, \$out, \$err;

    # success means the object exists
    if ( $? == 0 ) {
        #warn "$obj exists";
        return 1;
    }

    my $res = $? >> 8;

    # exit code of 128 means the object doesn't exist
    if ( $res == 128 ) {
        #warn "$obj doesn't exist";
        return 0
    };

    die
        "Command 'git cat-file -e $obj' exited with code $res and said '$err'";
}

sub _describe_ref {
    my( $self, $new ) = @_;

    # raw commit looks like this:
    #commit cc746cf3f6b8937c059cf6311a8903dba9936749
    #tree 76bcae9bdbcfab304c8265d2c2cc245048c9f0f3
    #parent 7e99c8b051169e43189c822c8db77bcad5956734
    #author Damyan Ivanov <dmn@debian.org> 1257538837 +0200
    #committer Damyan Ivanov <dmn@debian.org> 1257538837 +0200
    #
    #    update README.debian with regard to repackaging
    #
    #:100644 100644 603d70d... b81e344... M  debian/README.debian
    #:100644 100644 f1511af... 573335e... M  debian/changelog

    my ( $fh, $ctx )
        = $self->_git->command_output_pipe( 'show', '--pretty=raw',
        '--no-abbrev', '--raw', $new );
    my @log;
    my @changes;
    my @parents;
    my $author_login;
    my $author_name;
    while (<$fh>) {
        if ( /^author (.+) <([^>]+)@[^>]+>/ ) {
            utf8::decode( $author_name  = $1 );
            utf8::decode( $author_login = $2 );
            next;
        }
        push( @parents, substr( $1, 0, 7 ) ), next if /^parent\s+(\S+)/;
        push( @log, $1 ), next if /^    (.*)/;
        if (s/^::?//) {     # a merge commit
            chomp;
            my @old_modes;
            while ( s/^(\d{6,6})\s+// ) {
                push @old_modes, $1;
            }
            my $new_mode = pop @old_modes;

            my @old_shas;
            while (s/^([0-9a-f]{40,40})\s+//) {
                push @old_shas, $1;
            }
            my $new_sha = pop @old_shas;

            my $flag = '';
            s/^(\S+)\s+// and $flag = $1;

            my $file = $_;

            # maybe deleted?
            if ( $new_sha =~ /^0+$/ or $flag =~ /D/ ) {
                push @changes, App::KGB::Change->new("(D)$file");
            }
            # maybe created?
            elsif ( not @parents or grep {/^0+$/} @old_shas or $flag =~ /A/ ) {
                push @changes, App::KGB::Change->new("(A)$file");
            }
            else {
                my $mode_change
                    = ( grep { $_ ne $new_mode } @old_modes ) ? '+' : '';
                push @changes, App::KGB::Change->new("(M$mode_change)$file");
            }
        }
    }

    $self->_git->command_close_pipe( $fh, $ctx );

    return {
        id     => substr( $new, 0, 7 ),
        author => $author_login,
        author_name => $author_name,
        log     => join( "\n", @log ),
        changes => \@changes,
        parents => \@parents,
    };
}

sub _describe_annotated_tag {
    my( $self, $ref ) = @_;

    my ( $fh, $ctx )
        = $self->_git->command_output_pipe( 'show', '--stat', '--format=raw', $ref );
    my @log;
    my $author_login;
    my $author_name;
    my $tag;
    my $signed;
    my $commit;

    # annotated tags are listed as
    #  tag <tag name>
    #  Tagger: Some One <sone@swhere.nev>
    #
    #  Tag message
    #
    #  commit <ref>
    #  Author: .....
    #  .... <tag description>
    my $in_header = 1;
    while (<$fh>) {
        chomp;

        $commit = substr( $1, 0, 7 ), last if /^commit (.+)/;
        if (/^-----BEGIN PGP SIGNATURE/) {
            $signed = 1;
            do {
                defined($_ = <$fh>) or last;
            } until (/^-----END PGP SIGNATURE/);

            next;
        }

        if ($in_header) {
            $tag = $1, next if /^tag (.+)/;

            if ( /^Tagger: (.+) <([^>@]+)@[^>]+>/ ) {
                utf8::decode( $author_name  = $1 );
                utf8::decode( $author_login = $2 );
                next;
            }

            $in_header = 0 if /^$/;
        }
        else {
            push( @log, $_ );
        }
    }

    $self->_git->command_close_pipe( $fh, $ctx );

    pop @log if $log[$#log] eq '';
    if ($commit) {
        push @log, "tagged commit: $commit";
        if ( scalar(@log) == 2 ) {
            # spare an extra line
            $log[0] .= " ($log[1])";
            $#log = 0;
        }
    }

    return App::KGB::Commit::Tag->new(
        {   id     => substr( $ref, 0, 7 ),
            author => $author_login,
            author_name => $author_name,
            log    => join( "\n", @log ),
            branch  => $signed ? 'signed tags' : 'tags',
            changes => [ App::KGB::Change->new("(A)$tag") ],
            tag_name => $tag,
        }
    );
}

=item format_git_stat I<text>

returns a colored version of I<text>, which is expected to be the result
of C<git diff --shortstat>.

=cut

sub format_git_stat {
    my ( $self, $text ) = @_;

    my $result = '';

    $self->init_painter;

    while ( length($text) ) {
        warn "$text" if 0;
        if ( $text =~ s/(.*?)(\d+ files? changed)// ) {
            $result .= $1 . $self->colorize( modification => $2 );
            next;
        }
        if ( $text =~ s/(.*?)(\d+) insertions?\(\++\)// ) {
            $result .= $1 . $self->colorize( addition => "$2(+)" );
            next;
        }
        if ( $text =~ s/(.*?)(\d+) deletions?\(-+\)// ) {
            $result .= $1 . $self->colorize( deletion => "$2(-)" );
            next;
        }

        # nothing matched
        $result .= $text;
        last;
    }

    return $result;
}

sub _describe_branch_updates {
    my ( $self ) = @_;
    my %ref_branch;
    my %ref_parent;
    my @new_branches;
    my %new_branches;
    my @updated_branches;
    my %branch_updates;
    my %branch_head;
    my %updated_heads;
    my @old_revs;
    # keys are sha1s, values are hashrefs with keys branch names
    my %branch_tips;

    warn "# ======== processing changesets" if 0;
    my @params = qw(--topo-order --parents --first-parent);
    my @updated;
    my %branch_has_commits;
    for my $cs ( @{ $self->changesets } ) {
        my ( $old, $new, $ref ) = @$cs;
        warn "# considering $old $new $ref" if 0;

        next unless $ref =~ m{^refs/heads/(.+)}; # not interested in tags
        my $branch = $1;
        next if $new =~ /^0+$/;                 # nor dropped branches

        $ref_branch{$new} = $branch;
        warn "# $new is on $branch" if 0;

        warn "$branch head is $new" if 0;
        $branch_head{$branch} = $new;
        $branch_tips{$new}{$branch} = 1;
        $updated_heads{$branch} = 1;

        if ( $old =~ /^0+$/ ) {
            push @new_branches, $branch;
            $new_branches{$branch} = 1;
        }
        else {
            push @updated, "$new", "^$old";
            push @old_revs, $old;
            push @updated_branches, $branch;
            $branch_updates{$branch} = [ $old => $new ];
        }
    }

    my @existing_branches;
    my @old_branches;
    my @lines
        = $self->_git->command( 'branch', '-v', '--no-abbrev' );
    for my $l (@lines) {
        $l =~ s/^[ *]+//;
        my ( $ref, $sha, $ignore ) = split( ' ', $l );
        $branch_head{$ref} = $sha;
        $branch_tips{$sha}{$ref} = 1;
        $ref_branch{$sha} //= $ref;
        push @existing_branches, $ref unless $new_branches{$ref};
        push @old_branches, $ref
            unless $new_branches{$ref}
            or $branch_updates{$ref};
    }
    warn "existing branches: @existing_branches" if 0;
    warn "old branches: @old_branches" if 0;

    my @commits;
    my %reported;

    if (@updated) {
        push @params, map( "^$_", @old_branches );
        warn "# git rev-list @params @updated" if 0;
        my @lines = $self->_git->command( 'rev-list', @params, @updated);
        do { warn $_ for @lines } if 0;

        if ( $self->squash_threshold
            and scalar(@lines) > $self->squash_threshold )
        {
            for my $branch (@updated_branches) {
                my ($old,$new) = @{ $branch_updates{$branch} };
                my $stat = $self->_git->command( 'diff', '--shortstat',
                    "$old..$new" );
                my @commit_lines
                    = $self->_git->command( 'rev-list', '--topo-order', $new,
                    "^$old" );
                push @commits,
                    $self->format_message(
                    $self->squash_msg_template,
                    branch       => $branch,
                    commit_id    => substr( $new, 0, 7 ),
                    author_login => $ENV{USER},
                    author_name  => $self->_get_full_user_name,
                    log          => sprintf(
                        '%d commits pushed, %s',
                        scalar(@commit_lines), $self->format_git_stat($stat),
                    ),
                    );
                warn "# $commits[-1]" if 0;
                $branch_has_commits{$branch} = 1;
            }
        }
        else {
            my @refs;
            for (@lines) {
                my ( $ref, @parents ) = split(/\s+/);

                push @refs, $ref;

                if ( @parents and not $ref_branch{ $parents[0] } ) {
                    $ref_branch{ $parents[0] } = $ref_branch{$ref}
                        or confess
                        "Ref $ref with parent $parents[0] is of unknown branch";
                    warn
                        "# $parents[0] determined to be on branch $ref_branch{$ref}"
                        if 0;
                }
            }

            warn "# revisions to describe: " . join( ' ', @refs ) if 0;

            for my $ref (@refs) {
                if ( $reported{$ref} ) {
                    warn "$ref already reported" if 0;
                    next;
                }
                my $cmt = App::KGB::Commit->new( $self->_describe_ref($ref) );
                warn "# putting $ref on $ref_branch{$ref}" if 0;
                $cmt->branch( $ref_branch{$ref} );
                unshift @commits, $cmt;
                $reported{$ref} = 1;
                $branch_has_commits{ $ref_branch{$ref} } = 1;
            }
        }

        # see if some updated branch was without any reported commits
        # if this case put a fast-forward notification
        if ( $self->enable_branch_ff_notification ) {
            for ( @updated_branches ) {
                next if $branch_has_commits{$_};

                push @commits,
                    App::KGB::Commit->new(
                    {   branch      => $_,
                        id          => substr( $branch_updates{$_}[1], 0, 7 ),
                        author      => $ENV{USER},
                        author_name => $self->_get_full_user_name,
                        log         => 'fast forward',
                    }
                    );
            }
        }
    }

    # walk the branch until it is exhausted or a revision with multiple
    # children (branch point) is reached
    # when walking skip all commits already reported
    # terminate walk on old revs
    if ( @new_branches ) {
        # exclude commits in all branches that aren't part of this push
        my @exclude;
        for ( @existing_branches ) {
            push @exclude, $branch_head{$_} unless $updated_heads{$_};
        };
        push @exclude, @old_revs;
        $_ = "^$_" for @exclude;

        for my $b (@new_branches) {
            warn "# Looking into new branch $b" if 0;

            warn "# git rev-list --topo-order --first-parent --parents $b @exclude" if 0;
            my @lines = $self->_git->command( 'rev-list', '--topo-order',
                '--first-parent', '--parents', $b, @exclude );

            my @br_commits;
            my $branch_point;

            my $last_rev;
            for my $line (@lines) {
                warn "# $line" if 0;
                my ( $rev, $parent, @other_parents ) = split( /\s+/, $line );
                $last_rev = $rev;
                if ( $reported{$rev} ) {
                    warn "$rev is already reported" if 0;
                    next;
                }

                my $pipe = $self->_git->command_output_pipe( 'rev-list',
                    '--children', $rev );

                my $in = <$pipe>;
                $self->_git->command_close_pipe($pipe);
                my @children;
                if ($in) {
                    chomp($in);
                    warn "# Children of $rev: @children" if 0;
                    @children = split(/\s+/, $in);
                    shift @children;
                }

                # a branch point is:
                #  * a commit with more than one child
                #  * a tip of another branch
                if (@children > 1
                    or ( exists $branch_tips{$rev}
                        and not exists $branch_tips{$rev}{$b} )
                    )
                {
                    unshift @br_commits,
                        App::KGB::Commit->new(
                        {   log    => "Branch '$b' created",
                            id     => substr( $rev, 0, 7 ),
                            branch => $b,
                        }
                        );
                    $branch_point = $rev;
                    warn "$b branched at $rev" if 0;
                    last;
                }
                if ($parent) {
                    $ref_branch{$parent} //= $ref_branch{$rev};
                    $ref_parent{$rev} = $parent;
                }

                my $cmt = App::KGB::Commit->new( $self->_describe_ref($rev) );
                warn "# putting $rev on $ref_branch{$rev}" if 0;
                $cmt->branch( $ref_branch{$rev} );
                unshift @br_commits, $cmt;
                $reported{$rev} = 1;
            }

            if ( not $branch_point and $last_rev and $ref_parent{$last_rev} )
            {
                $branch_point = $ref_parent{$last_rev};
                warn "$b branched at $branch_point" if 0 and $branch_point;
            }

            if ( $self->squash_threshold
                and scalar(@br_commits) > $self->squash_threshold )
            {
                my $log = sprintf( 'New branch with %d commits pushed',
                    scalar(@br_commits) );
                if ($branch_point) {
                    $log .= ', '
                        . $self->format_git_stat(
                        $self->_git->command(
                            'diff', '--shortstat', "$branch_point..$b"
                        )
                        );
                    $log .= " since ";
                    $log .= "$ref_branch{$branch_point}/"
                        if $ref_branch{$branch_point};
                    $log .= substr( $branch_point, 0, 7 );
                }
                push @commits,
                    $self->format_message(
                    $self->squash_msg_template,
                    branch       => $b,
                    author_login => $ENV{USER},
                    author_name  => $self->_get_full_user_name,
                    log          => $log,
                    commit_id    => substr( $branch_head{$b}, 0, 7 ),
                    );
            }
            else {
                push @commits, @br_commits;
                push @commits,
                    App::KGB::Commit->new(
                    {   id      => substr( $branch_head{$b}, 0, 7 ),
                        log     => "branch created",
                        branch  => $b,
                        changes => [],
                    }
                    ) unless @br_commits;
            }
        }
    }

    warn '# ' . scalar(@commits) . ' commits queued' if 0;

    push @{ $self->_commits }, @commits;
}

sub _process_changeset_simple {
    my ( $self, $old_rev, $new_rev, $refname ) = @_;

    $_ = $self->_git->command_oneline( 'rev-parse', $_ )
        for ( $old_rev, $new_rev );

    # see what kind of commit is this
    my $ref_update_type;
    if ( $old_rev =~ /^0+$/ ) {

        # 0000000 -> 1234567
        $ref_update_type = 'create';
    }
    elsif ( $new_rev =~ /^0+$/ ) {

        # 7654321 -> 0000000
        $ref_update_type = 'delete';
    }
    else {

        # 2345678 -> 3456789
        $ref_update_type = 'update';
    }

    my ( $rev, $rev_type );
    if ( $ref_update_type eq 'delete' ) {
        $rev      = $old_rev;
        $rev_type = $self->_git->command_oneline( 'cat-file', '-t', $old_rev );
    }
    else {    # create or update
        $rev      = $new_rev;
        $rev_type = $self->_git->command_oneline( 'cat-file', '-t', $new_rev );
    }

    my ( $refname_type, $short_refname, $branch, $tag, $remote );

    # revision type and location tell us if this is
    #  - working branch
    #  - tracking branch
    #  - unannoted tag
    #  - annotated tag
    if ( $refname =~ m{refs/tags/.+} and $rev_type eq 'commit' ) {

        # un-annotated tag
        $refname_type = "tag";
        ( $tag = $refname ) =~ s,refs/tags/,,;
    }
    elsif ( $refname =~ m{refs/tags/.+} and $rev_type eq 'tag' ) {

        # annotated tag
        $refname_type = "annotated tag";
        ( $tag = $refname ) =~ s,refs/tags/,,;
    }
    elsif ( $refname =~ m{refs/heads/.+} and $rev_type eq 'commit' ) {

        # branch
        $refname_type = "branch";
        ( $branch = $refname ) =~ s,refs/heads/,,;
    }
    elsif ( $refname =~ m{refs/remotes/.+} and $rev_type eq 'commit' ) {

        # tracking branch
        $refname_type = "tracking branch";
        ( $remote = $refname ) =~ s,refs/remotes/,,;
        warn <<"EOF";
*** Push-update of tracking branch, $refname
*** no notification sent.
EOF
        return undef;
    }
    else {

        # Anything else (is there anything else?)
        warn "*** Unknown type of update to $refname ($rev_type) ignored";
        return;
    }

    if ( $ref_update_type eq 'create' ) {
        if ( $refname_type eq 'tag' ) {
            push @{ $self->_commits },
                App::KGB::Commit::Tag->new(
                {   id     => substr( $new_rev, 0, 7 ),
                    #author => $cmt->author,
                    log => "tag '$tag' created",
                    branch => 'tags',
                    changes => [ App::KGB::Change->new("(A)$tag") ],
                    tag_name => $tag,
                }
                );
        }
        elsif ( $refname_type eq 'annotated tag' ) {
            push @{ $self->_commits }, $self->_describe_annotated_tag($new_rev);
        }
        else {
            # branch creations would be picked by _describe_branch_updates
            return;
        }
    }
    elsif ( $ref_update_type eq 'delete' ) {
        push @{ $self->_commits }, App::KGB::Commit->new(
            {   id     => substr( $old_rev, 0, 7 ),
                author => 'TODO: deletor',
                log    => ( $branch ? 'branch' : 'tag' ) . ' deleted',
                branch => $branch || 'tags',
                changes => [
                    App::KGB::Change->new(
                        { action => 'D', path => ( $branch ? '.' : $tag ) }
                    )
                    ],
            }
        );
    }
    else {    # update
        # should be processed by _describe_branch_updates
        return;
    }
}

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009, 2013 Damyan Ivanov

Based on the shell post-receive hook by Andy Parkins

This file is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51
Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=cut

1;
