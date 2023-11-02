package App::KGB::Client;
use utf8;
require v5.10.0;

use feature 'switch';
use strict;
use warnings;

our $VERSION = '1.34';

# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration
# Copyright © 2008 Martina Ferrari
# Copyright © 2009,2010,2011,2012,2013 Damyan Ivanov
# Copyright © 2018 Colin Finck <colin@reactos.org>
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

=head1 NAME

App::KGB::Client - relay commits to KGB servers

=head1 SYNOPSIS

    use App::KGB::Client;
    my $client = App::KGB::Client( <parameters> );
    $client->run;

=head1 DESCRIPTION

B<App::KGB::Client> is the backend behind L<kgb-client(1)>. It handles
the repository-independent parts of sending the notifications to the KGB server,
L<kgb-bot(1)>. Details about extracting change from commits, branches and
modules is done by sub-classes specific to the version control system in use.

=head1 CONFIGURATION

The following parameters are accepted in the constructor:

=over

=item B<repo_id> I<repository name>

Short repository identifier. Will be used for identifying the repository to the
KGB daemon, which will also use this for IRC notifications. B<Mandatory>.

=item B<uri> I<URI>

URI of the KGB server. Something like C<http://some.server:port>. B<Mandatory>
either as a top-level parameter or as a sub-parameter of B<servers> array.

=item B<proxy> I<URI>

URI of the SOAP proxy. If not given, it is the value of the B<uri> option, with
C<?session=KGB> added.

=item B<password> I<password>

Password for authentication to the KGB server. B<Mandatory> either as a
top-level parameter or as a sub-parameter of B<servers> array.

=item B<timeout> I<seconds>

Timeout for server communication. Default is 15 seconds, as we want instant IRC
and commit response.

=item B<servers>

An array of servers, each an instance of L<App::KGB::Client::ServerRef> class.

When several servers are configured, the list is shuffled and then the servers
are tried one after another until a successful request is done, or the list is
exhausted, in which case an exception is thrown.

When shuffling, preference is added to the last server used by the client, or
by other clients (given C<status_dir> is configured).

=item B<batch_messages>

If true, the notifications are sent as a batch in one request to the server.
Useful with VCS that send many changes a time (e.g. Git).

Defaults to false, but will be changed later after some grace period for server
upgrade.

=item B<br_mod_re>

A list of regular expressions (simple strings, not L<qr> objects) that serve
for detection of branch and module of commits. Each item from the list is tried
in turn, until an item is found that matches all the paths that were modified
by the commit. Regular expressions must have two captures: the first one giving
the branch name, and the second one giving the module name.

All the paths that were modified by the commit must resolve to the same branch
and module in order for the branch and module to be transmitted to the KGB
server.

    Example: ^/(trunk)/([^/]+)/
             # /trunk/module/file
             ^/branches/([^/]+)/([^/]+)/
             # /branches/test/module/file

=item B<mod_br_re>

Same as B<br_mod_re>, but captures module name first and branch name second.

    Example: ^/branches/([^/]+)/([^/]+)/
             # /branches/test/module/file

=item B<ignore_branch>

When most of the development is in one branch, transmitting it to the KGB
server and seeing it on IRC all the time can be annoying. Therefore, if you
define B<ignore_branch>, and a given commit is in a branch with that name, the
branch name is not transmitted to the server. Module name is still transmitted.

=item B<module>

Forces explicit module name, overriding the branch and module detection. Useful
in Git-hosted sub-projects that want to share single configuration file, but
still want module indication in notifications.

=item B<single_line_commits> I<off|forced|auto>

Request different modes of commit message processing:

=over

=item I<off>

No processing is done. The commit message is printed as was given, with each
line in a separate IRC message, blank lines omitted. This is the only possible
behaviour in versions before 1.14.

=item I<forced>

Only the first line is sent to IRC, regardless of whether it is followed by a
blank line or not.

=item I<auto>

If the first line is followed by an empty line, only the first line is sent to
IRC and the rest is ignored. This is the default since version 1.14.

=back

=item B<use_irc_notices>

If true signals the server that it should use IRC notices instead of regular
messages. Use this if regular messages are too distracting for your channel.

=item B<use_color>

If true (the default) signals the server that it should use colors for commit
notifications.

=item B<status_dir>

Specifies a directory to store information about the last server contacted
successfully. The client would touch files in that directory after successful
completion of a notification with remote server.

Later, when asked to do another notification, the client would start from the
most recently contacted server. If that was contacted too far in the past, the
information in the directory is ignored and a random server is picked, as
usual.

=item B<verbose>

Print diagnostic information.

=item B<protocol> I<version>

Use specified protocol version. If C<auto> (the default), the version of the
protocol C<2>, unless B<web_link> is also given, in which case protocol version
C<3> is default;

=item B<web_link> I<template>

A web link template to be sent to the server. The following items are expanded:

=over

=item ${branch}

=item ${module}

=item ${commit}

=item ${project}

=back

=item B<short_url_service> I<service>

A L<WWW::Shorten> service to use for shortening the B<web_link>. See
L<WWW::Shorten> for the list of supported services.

=item B<msg_template> I<string>

Provides a way to customize the notifications' appearance on IRC. When present,
all message construction is done on the client and the prepared messages
(possibly with colors etc) are sent to the server for relaying to IRC.

The following special items are recognized and replaced with the respective
commit elements.

=over

=item ${project_id}

The ID of the project.

=item ${author_login}

The login of the author (e.g. "joe").

=item ${author_name}

The name of the commit author (e.g. "Joe Random")

=item ${author_via}

The name of the commit author, plus the name of the committer if that is
different (e.g. "Joe Random" or "Joe Random (via Max Random)")

=item ${branch}

The branch of the commit.

=item ${module}

The module of the commit.

=item ${commit}
=item ${revision}

The ID of the commit.

=item ${path}

The changed path(s).

=item ${log}

The log message of the commit.

=item ${web}

The web link associated with the commit. Replaced with the empty string unless
the B<web_link> option is also given.

=back

=item B<style> I<hash reference>

Provides a color map for different parts of the message. The following keys are
supported. Defaults are used when keys are missing in the hash. B<use_color>
must be true for this to have any effect. Used only when B<msg_template> is
also given.

=over

=item revision
=item commit_id

Commit ID. Default: none.

=item path

Changed path. Default: teal.

Depending on the action performed to the path, additional coloring is made:

=over

=item addition

Used for added paths. Default: green.

=item modification

Used for modified paths. Default: teal.

=item deletion

Used for deleted paths. Default: bold red.

=item replacement
Used for replaced paths (a Subversion concept). Default: brown.

=item prop_change

Used for paths with changed properties (a Subversion concept), combined with
other colors depending on the action -- addition, modification or replacement.
Default: underline.

=back

=item author

Commit author. Default: green.

=item branch

Commit branch. Default: brown.

=item module

Project module. Default: purple.

=item web

URL to commit information. Default: silver.

=item separator

The separator before the commit log. Default: none.

=back

=back

=cut

require v5.10.0;
use Carp qw(confess);
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use DirHandle ();
use File::Basename qw(dirname);
use SOAP::Lite;
use Getopt::Long;
use List::Util ();
use User::pwent;
use YAML ();
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(
    qw( repo_id servers br_mod_re mod_br_re module ignore_branch
        single_line_commits use_irc_notices use_color status_dir verbose protocol
        web_link short_url_service _last_server
        msg_template
        style colors painter
        batch_messages
        _full_user_name
        )
);

=head1 CONSTRUCTOR

=head2 new ( { I<initial values> } )

Standard constructor with initial values in a hashref.

    my $c = App::KGB::Client->new(
        {   repo_id => 'my-repo',
            servers => \@servers,
            ...
        }
    );

See L<|FIELDS> above.

=cut

sub new {
    my ( $class, $init ) = @_;

    my $self = $class->SUPER::new(
        {   use_color => 1,
            %$init,
        }
    );

    print "Configuration: " . YAML::Dump(@_) if $self->verbose;

    defined( $self->repo_id )
        or confess "'repo_id' is mandatory";
    $self->br_mod_re( [ $self->br_mod_re // () ] )
        if not ref( $self->br_mod_re );
    $self->mod_br_re( [ $self->mod_br_re // () ] )
        if not ref( $self->mod_br_re );

    $self->servers( [] ) unless defined( $self->servers );

    ref( $self->servers ) and ref( $self->servers ) eq 'ARRAY'
        or confess "'servers' must be an arrayref";

    @{ $self->servers } or confess "No 'servers' specified";

    if ( $self->status_dir ) {
        if ( not -e $self->status_dir ) {
            warn "Status directory ".$self->status_dir." doesn't exist.\n";
            $self->status_dir(undef);
        }
        elsif ( not -d $self->status_dir ) {
            warn $self->status_dir." is not a directory\n";
            $self->status_dir(undef);
        }
    }

    $self->protocol('auto') unless defined( $self->protocol );

    return $self;
}

=head1 METHODS

=over

=item detect_branch_and_module ( $changes )

Given a set of changes (an arrayref of L<App::KGB::Change> objects), runs all
the regular expressions as listed in B<br_mod_re> and B<mod_br_re> and if a
regular expression that matches all the changed paths and returns the branch
and module.

    ( $branch, $module ) = $client->detect_branch_and_module($changes);

=cut

sub _run_matches {
    my ( $safe, $changes, $res, $swap ) = @_;

    for my $re (@$res) {
        $re =~ s{,}{\\,}g;    # escape commas
        my $matching = "m,$re,; " . ( $swap ? '($2,$1)' : '($1,$2)' );

        local $_ = $changes->path;
        my ( $branch, $module ) = $safe->reval($matching);
        die "Error while evaluating `$re': $@" if $@;

        if ( defined($branch) and defined($module) ) {
            return ( $re, $branch, $module );
        }
    }
    return ( undef, undef, undef );
}

sub detect_branch_and_module {
    my ( $self, $changes ) = @_;
    return () unless $self->br_mod_re;

    require Safe;
    my $safe = Safe->new;
    $safe->permit_only(
        qw(padany lineseq match const leaveeval
            rv2gv rv2sv pushmark list warn)
    );

    my ( $branch, $module, $matched_re );

    # for a successful branch/module extraction, we require that all the
    # changes share the same branch/module
    for my $c (@$changes) {
        my ( $change_branch, $change_module );

        ( $matched_re, $change_branch, $change_module )
            = _run_matches( $safe, $c, $self->br_mod_re, 0 );
        ( $matched_re, $change_branch, $change_module )
            = _run_matches( $safe, $c, $self->mod_br_re, 1 )
            unless $matched_re
            and defined($change_branch)
            and defined($change_module);

        # some change cannot be tied to a branch and a module?
        if ( !defined( $change_branch // $change_module ) ) {
            $branch = $module = $matched_re = undef;
            last;
        }

        if ( defined($branch) ) {

            # this change is for a different branch/module?
            if ( $branch ne $change_branch or $module ne $change_module ) {
                $branch = $module = $matched_re = undef;
                last;
            }
        }
        else {

            # first change, store branch and module
            $branch = $change_branch;
            $module = $change_module;
        }
    }

    # remove the part that have matched as it contains information about the
    # branch and module that we provide otherwise
    if ($matched_re) {

        #warn "Branch: ".($branch||"NONE");
        #warn "Module: ".($module||"NONE");
        $safe->permit(qw(subst));
        for my $c (@$changes) {

            #warn "FROM ".$c->{path};
            $_ = $c->path;
            $safe->reval("s,.*$matched_re,,");
            die "Eror while evaluating s/.*$matched_re//: $@" if $@;
            $c->path($_);

            #warn "  TO $_";
        }
    }

    if ( $self->verbose and $branch ) {
        print "Detected branch '$branch' and module '"
            . ( $module // 'NONE' ) . "'\n";
    }

    return ( $branch, $module );
}

=item shuffle_servers

Returns a shuffled variant of C<< $self-E<gt>servers >>. It considers the last
successfully used server by this client instance and puts it first. If there is
no such server, it considers the state in C<status_dir> and picks the last
server noted there, if it was used in the last 5 minutes.

=cut

sub shuffle_servers {
    my $self = shift;

    my @servers = List::Util::shuffle( @{ $self->servers } );

    if ( $self->_last_server ) {
        # just put the last server first in the list
        @servers = sort {
            return -1 if $a->uri eq $self->_last_server->uri;
            return +1 if $b->uri eq $self->_last_server->uri;
            return 0;
        } @servers;
    }
    elsif ( $self->status_dir ) {
        # pick a server from the status directory
        my %hashes;
        do {
            my $i = 0;
            for (@servers) {
                $hashes{ md5_hex( $_->uri ) } = $i++;
            }
        };
        my $d = DirHandle->new( $self->status_dir );
        my $latest_stamp;
        my $latest_hash;
        if ( defined $d ) {
            my $now = time;
            while( defined( my $f = $d->read ) ) {
                next
                    unless $f =~ /^kgb-client.([0-9a-f]+)$/
                        and exists( $hashes{$1} );

                my $file = File::Spec->catdir($self->status_dir, $f);

                my $stamp = (stat $file)[9];

                if ( $latest_stamp ) {
                    if( $latest_stamp < $stamp ) {
                        $latest_stamp = $stamp;
                        $latest_hash = $1;
                    }
                }
                elsif ( $stamp >= ( $now - 300 ) ) {
                    # accessed in the last 5 minutes, consider it
                    $latest_stamp = $stamp;
                    $latest_hash  = $1;
                }
            }

            if ( $latest_stamp ) {
                my $winner = splice( @servers, $hashes{$latest_hash}, 1 );
                unshift @servers, $winner;
            }
        }
        else {
            warn "Unable to read directory ".$self->status_dir."\n";
            $self->status_dir(undef);
        }
    }

    return @servers;
}

=item expand_link ($string, \%data)

Expands items in the form I<${item}> in I<$string>, using the data in the
supplied hash reference.

Passing

 "http://git/${module}.git?commit=${commit}",
 { module => 'dh-make-perl', commit => '225ceca' }

would result in C<http://git/dh-make-perl.git?commit=225ceca>.

=cut

sub expand_link {
    my ( $self, $input, $data ) = @_;

    my $output = '';
    my $re = qr/\$\{([^{}]+)\}/p;

    while ( $input =~ $re ) {
        my $f = $1;
        my $v;
        if ( exists $data->{$f} ) {
            $v = $data->{$f} // '';
        }
        else {
            $v = '';
            warn "Unknown substitution '$f'\n";
        }

        $output .= ${^PREMATCH} . $v;
        $input = ${^POSTMATCH};
    }

    warn "Web link expanded to $output\n" if $self->verbose;

    return $output;
}

=item shorten_url (url)

Uses the configured I<short_url_service> to shorten the given URL. If no
shortening service is configured, the original URL is returned.

=cut

sub shorten_url {
    my ( $self, $url ) = @_;
    return $url unless my $service = $self->short_url_service;

    my $ok = eval {
        require WWW::Shorten;
        WWW::Shorten->import( $service, ':short' );
        1;
    };

    unless ($ok) {
        warn "Unable to load URL shortening service '$service': $@";
        warn "Sending plain URL.\n";
        return $url;
    }

    my $short_url = short_link($url);

    return $short_url if defined($short_url);

    warn "URL shortening service '$service' failed.\n";
    warn "Sending plain URL.\n";
    return $url;
}

=item note_last_server($srv)

If C<status_dir> is configured, notes $srv as the last used server to be used
in subsequent requests.

=cut

sub note_last_server {
    my ( $self, $srv ) = @_;

    return unless $self->status_dir;

    require File::Touch;
    File::Touch::touch(
        File::Spec->catfile(
            $self->status_dir,
            sprintf( "kgb-client.%s", md5_hex( $srv->uri ) )
        )
    );
}

use constant rev_prefix => '';

=item init_painter

Creates an internal instance of L<App::KGB::Painter> used to color message
elements.

Does nothing if I<use_color> is false or if painter has been already created.

=cut

sub init_painter {
    my $self = shift;

    return unless $self->use_color;
    return if $self->painter;

    require App::KGB::Painter;
    $self->painter(
        App::KGB::Painter->new( { item_colors => $self->colors } ) );
}

=item colorize I<category> =E<gt> I<text>

Returns a colored version of I<text>. If there is no painter, returns just
I<text>.

=cut

sub colorize {
    my ( $self, $category, $text ) = @_;

    return $text unless $self->painter;

    return $self->painter->colorize( $category => $text );
}

our %action_styles = (
    A => 'addition',
    M => 'modification',
    D => 'deletion',
    R => 'replacement',
);

=item colorize_change I<change>

returns a colorized string representing a single change

=cut

sub colorize_change {
    my ( $self, $c ) = @_;

    my $action_style = $action_styles{ $c->action };

    my $text = $self->colorize( $action_style => $c->path );

    $text = $self->colorize( 'prop_change' => $text ) if $c->prop_change;

    return $text;
}

our $MAGIC_MAX_FILES = 4;

=item colorize_changes \@changes

returns a colorized string of all commit's changes

=cut

sub colorize_changes {
    my ( $self, $changes ) = @_;

    my @info;

    my $changed_files = scalar @$changes;

    my $common_dir = App::KGB::Change->detect_common_dir($changes) // '';

    push @info, $self->colorize( path => "$common_dir/" ) if $common_dir ne '';

    if ( $changed_files > $MAGIC_MAX_FILES ) {
        my %dirs;
        for my $c (@$changes) {
            my $dir = dirname( $c->path );
            $dirs{$dir}++;
        }

        my $dirs = scalar( keys %dirs );

        my $path_string = join( ' ',
            ( $dirs > 1 )
            ? sprintf( "(%d files in %d dirs)", $changed_files, $dirs )
            : sprintf( "(%d files)",            $changed_files ) );

        push @info, $self->colorize( path => $path_string );
    }
    else {
        push @info, join( ' ', map { $self->colorize_change($_) } @$changes )
            if @$changes;
    }

    return join( ' ', @info );
}

=item format_message $template %details

Returns a formatted message, ready to be sent to the servers. The message is
formatted according to the B<message_format> configuration parameter, honouring
B<colors> and B<use_color>.

=cut

sub format_message {
    my ( $self, $msg, %p ) = @_;

    my $commit = $p{commit};

    $self->init_painter;

    my $result = '';
    warn "# msg = '$msg'" if 0;

    if ($commit) {
        $p{author_login} = $commit->author if ($commit->author);
        $p{author_name} = $commit->author_name if ($commit->author_name);
        $p{author_via} = $commit->author_via if ($commit->author_via);
        $p{branch} = $commit->branch if ($commit->branch);
        $p{commit_id} = $commit->id if ($commit->id);
        $p{log} = $commit->log if ($commit->log);
    }
    $p{author_name} ||= $p{author_login};
    $p{author_login} ||= $p{author_name};
    $p{author_via} ||= $p{author_name};
    if (defined($self->module)) {
        $p{module} = $self->module;
    } elsif ($commit and defined($commit->module)) {
        $p{module} = $commit->module;
    }

    while ( $msg =~ /\$\{([^{}]+)?\{([^{}]+)\}([^{}]+)?\}/ps ) {
        my ( $pre, $token, $post ) = ( $1, $2, $3 );
        warn "# pre = '$pre' token = '$token' post = '$post'" if 0;
        $result .= ${^PREMATCH};
        $msg = ${^POSTMATCH};
        warn "# msg is now '$msg'" if 0;
        my @r;

        if ( $token eq 'project' ) {
            push @r, project => $self->repo_id;
        }
        elsif ( $token eq 'author-login' ) {
            push @r, author => $p{author_login};
        }
        elsif ( $token eq 'author-name' ) {
            push @r, author => $p{author_name};
        }
        elsif ( $token eq 'author-via' ) {
            push @r, author => $p{author_via};
        }
        elsif ( $token eq 'branch' ) {
            push @r, branch => $p{branch};
        }
        elsif ( $token eq 'module' ) {
            push @r, module => $p{module};
        }
        elsif ( $token eq 'web-link' ) {
            push @r, web => $p{web_link};
        }
        elsif ( $token eq 'commit' ) {
            push @r, commit_id => $p{commit_id};
        }
        elsif ( $token eq 'log' ) {
            push @r, log => $p{log};
        }
        elsif ( $token eq 'log-first-line' ) {
            push @r, log => ( split( /\n/, $p{log} ) )[0];
        }
        elsif ( $token eq 'changes' ) {
            push @r, '' => $self->colorize_changes( $commit->changes )
                if $commit and $commit->changes;
        }
        else {
            push @r, '' => "Unknown item '$_'";
        }

        my ( $category, $item ) = @r;

        warn "# item = '$item'" if 0;
        next unless defined($item) and $item ne '';

        if ( defined($pre) ) {
            # avoid adding multi-spaces or spaces at the beginning
            $pre =~ s/^\s+// if $result =~ /\s$/ or $result eq '';
            $result .= $pre;
        }
        $result .=
            ( $category eq '' )
            ? $item
            : $self->colorize( $category => $item );
        $result .= $post // '';
    }
    $result .= $msg;

    return $result;
}

=item process_commit ($commit)

Processes a single commit, returning something for sending to the remote
server. I<Something> is either a reference to array of arguments to be passed
to L<App::KGB::ServerRef>'s send_changes method, or, in message-relay mode, a
plain scalar string representing the commit.

If $commit is a plain scalar (not a reference), then it is assumed to be an
already processed string and is returned directly.

=cut

sub process_commit {
    my ( $self, $commit ) = @_;

    # plain strings are already processed by the VCS-specific module
    return $commit unless ref($commit);

    my $module = $self->module // $commit->module;
    my $branch = $commit->branch;

    if ( not defined($module) or not defined($branch) ) {
        my ( $det_branch, $det_module )
            = $self->detect_branch_and_module( $commit->changes );

        $branch //= $det_branch;
        $module //= $det_module;
    }

    my $web_link = $self->web_link;
    if ( defined($web_link) ) {
        $web_link = $self->expand_link(
            $web_link,
            {   branch  => $branch,
                module  => $module,
                commit  => $commit->id,
                project => $self->repo_id
            }
        );
        $web_link = $self->shorten_url($web_link);
    }

    $branch = undef
        if $branch and $branch eq ( $self->ignore_branch // '' );

    # All data prepared. Now, how do we represent this commit?

    # A pre-formatted, pre-coloured string, if msg_template is configured
    return $self->format_message(
        $self->msg_template,
        commit   => $commit,
        branch   => $branch,
        module   => $module,
        web_link => $web_link
    ) if $self->msg_template;

    # otherwise, prepare things for send_changes()
    my @args = ( $commit, $branch, $module );
    my %extra;
    $extra{web_link} = $web_link if defined($web_link);
    $extra{use_irc_notices} = $self->use_irc_notices
        if $self->use_irc_notices;
    $extra{use_color} = $self->use_color;
    push @args, \%extra if %extra;

    return \@args;
}

=item process

The main processing method. Calls B<describe_commit> and while it returns true
values, gives them to B<process_commit> and send the result to the server.

If B<batch_messages> flag is true, relays accumulated messages after
processing.

=cut

sub process {
    my $self = shift;

    my @messages;

    while ( my $commit = $self->describe_commit ) {
        my $data = $self->process_commit($commit);

        if (ref($data)) {
            # a structure to be interpreted by the server
            $self->send_changes($data);
        }
        else {
            # a plain string
            if ( $self->batch_messages ) {
                # batch it, will send the whole batch in one transaction below
                push @messages, $data;
            }
            else {
                # relay immediately
                $self->relay_message($data);
            }
        }
    }

    $self->relay_message( \@messages ) if $self->batch_messages and @messages;
}

=item send_changes \@args

Tries to send the changes described in the given array reference to all
configured servers.

=cut

sub send_changes {
    my ( $self, $args ) = @_;

    my @servers = $self->shuffle_servers;

    # try all servers in turn until someone succeeds
    my $failure;
    for my $srv (@servers) {
        $failure = eval {
            $srv->send_changes( $self, $self->protocol, @$args );
            $self->_last_server($srv);

            $self->note_last_server($srv);
            0;
        } // 1;

        warn $@ if $failure;

        last unless $failure;
    }

    die "Unable to complete notification. All servers failed\n"
        if $failure;
}

=item relay_message I<message>

Send a simple message to servers for relaying. Implements the --relay-msg
command line option.

=cut

sub relay_message {
    my $self = shift;
    my $msg = shift // die "Syntax: \$client->relay_message(msg)";

    my @servers = $self->shuffle_servers;

    # try all servers in turn until someone succeeds
    my $failure;
    for my $srv (@servers) {
        $failure = eval {
            $srv->relay_message( $self, $msg,
                { use_irc_notices => $self->use_irc_notices } );
            $self->_last_server($srv);

            $self->note_last_server($srv);
            0;
        } // 1;

        warn $@ if $failure;

        last unless $failure;
    }

    die "Unable to relay message. All servers failed\n"
        if $failure;
}

sub _get_full_user_name {
    my $self = shift;
    my $login = shift // $ENV{USER};

    return $self->_full_user_name if $self->_full_user_name;

    my $user = getpwnam($login);
    my $full_name = $login;
    ( $full_name = $user->gecos ) =~ s/,.*// if defined $user;

    utf8::decode($full_name);

    $self->_full_user_name($full_name);

    return $full_name;
}

1;

__END__

=back

=head1 PROVIDING REPOSITORY-SPECIFIC FUNCTIONALITY

L<App::KGB::Client> is a generic class providing repository-agnostic
functionality. All repository-specific methods are to be provided by classes,
inheriting from L<App::KGB::Client>. See L<App::KGB::Client::Subversion> and
L<App::KGB::Client::Git>.

Repository classes must provide the following method:

=over

=item B<dsescribe_commit>

This method returns an L<App::KGB::Commit> object that
represents a single commit of the repository.

B<describe_commit> is called several times, until it returns C<undef>. The idea
is that a single L<App::KGB::Client> run can be used to process several commits
(for example if the repository is L<git(1)>). If this is the case each call to
B<describe_commit> shall return information about the next commit in the
series. For L<svn(1)>, this module is expected to return only one commit,
subsequent calls shall return C<undef>.

=back

=head1 SEE ALSO

=over

=item L<App::KGB::Client::Subversion>

=item L<App::KGB::Client::Git>

=back

=cut

