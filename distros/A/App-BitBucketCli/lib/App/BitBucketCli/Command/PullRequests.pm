package App::BitBucketCli::Command::PullRequests;

# Created on: 2018-06-07 08:23:20
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Tiny;

extends 'App::BitBucketCli';

our $VERSION = 0.009;

sub options {
    return [qw/
        colors|c=s%
        create|C
        force|f!
        author|a=s
        emails|e=s
        to_branch|to-branch|t=s
        from_branch|from-branch|f=s
        title|T=s
        state|S=s
        long|l
        project|p=s
        participant|P=s
        regexp|R
        remote|m=s
        repository|r=s
        sleep|s=i
    /]
}

sub pull_requests {
    my ($self) = @_;

    my $author      = $self->opt->author();
    my $to_branch   = $self->opt->to_branch();
    my $from_branch = $self->opt->from_branch();
    my $title       = $self->opt->title();
    my $emails      = $self->opt->emails();
    my $participant = $self->opt->participant();

    if ( $self->opt->create() ) {
        #https://stash.ext.springdigital-devisland.com.au/projects/SD/repos/onlinestyleguide/pull-requests
        #    ?create
        #    &targetBranch=refs%2Fheads%2Fproject_shop_performance
        #    &sourceBranch=refs%2Fheads%2Fbugfix%2FALM-48995_hidden-scroll-bar3
        #    &targetRepoId=12
        if ( ! $self->opt->{from_branch} ) {
            my $dir = `git rev-parse --show-toplevel`;
            chomp $dir;
            my $head = path($dir, '.git', 'HEAD');

            if ( -s $head ) {
                $head = $head->slurp;
                chomp $head;
                $head =~ s{^ref: refs/heads/}{};
                $self->opt->{from_branch} = $head;
            }
        }

        my $url = $self->core->url;
        $url =~ s{^(https?://)([^/]+?@)}{$1};
        $url =~ s{/rest/.*}{};
        $url .= '/projects/' . $self->opt->{project} . '/repos/'
            . $self->opt->{repository} . '/pull-requests?create';

        $url .= '&sourceBranch=refs/heads/' . $self->opt->{from_branch} if $self->opt->{from_branch};
        $url .= '&targetBranch=' . ( $self->opt->{to_branch} ? 'refs/heads/' . $self->opt->{to_branch} : '' );
        print "$url\n";
        return;
    }

    my @pull_requests = sort {
            lc $a->id cmp lc $b->id;
        }
        $self->core->pull_requests($self->opt->{project}, $self->opt->{repository}, $self->opt->{state} || 'OPEN');

    my @prs;
    my %max;

    for my $pull_request (@pull_requests) {
        next if $author && $pull_request->author->{user}{displayName} !~ /$author/;
        next if $to_branch && $pull_request->toRef->{displayId} !~ /$to_branch/;
        next if $from_branch && $pull_request->fromRef->{displayId} !~ /$from_branch/;
        next if $title && $pull_request->title !~ /$title/;
        next if $emails && ! grep { /$emails/ } @{ $pull_request->emails };
        next if $participant && ! grep { $_->{user}{displayName} =~ /$participant/ } @{ $pull_request->participants };

        my $tasks = eval { $pull_request->{openTasks}->[0] } || 0;
        push @prs, {
            id     => $pull_request->id,
            title  => $pull_request->title,
            author => $pull_request->author->{user}{displayName},
            from   => $pull_request->fromRef->{displayId},
            to     => $pull_request->toRef->{displayId},
            emails => $pull_request->emails,
            tasks  => $tasks,
        };
        chomp $prs[-1]{title};
        for my $key (keys %{ $prs[-1] }) {
            $max{$key} = length $prs[-1]{$key} if ! $max{$key} || $max{$key} < length $prs[-1]{$key};
        }
    }

    for my $pr (@prs) {
        printf "%-$max{id}s ", $pr->{id};
        printf "%-$max{author}s ", $pr->{author};
        printf "%-$max{tasks}s ", $pr->{tasks};
        print "$pr->{title}\n";
        if ( $self->opt->long ) {
            print '  ', ( join ', ', @{ $pr->{emails} } ), "\n";
        }
    }
}

1;

__END__

=head1 NAME

App::BitBucketCli::Command::PullRequests - Show the pull requests of a repository

=head1 VERSION

This documentation refers to App::BitBucketCli::Command::PullRequests version 0.009

=head1 SYNOPSIS

   bb-cli pull-requests [options]

 OPTIONS:
  -c --colors[=]str Change colours used specified as key=value
                    eg --colors disabled=grey22
                    current colour names aborted, disabled and notbuilt
  -C --create       Construct the url to create a pull request using --from-branch
                    (or the current branch) and --to-branch.
  -f --force        Force action
  -l --long         Show long form data if possible
  -p --project[=]str
                    For commands that need a project name this is the name to use
  -R --recipient[=]str
                    ??
  -R --regexp[=]str ??
  -m --remote[=]str ??
  -r --repository[=]str
                    For commands that work on repositories this contains the repository
  -s --sleep[=]seconds
                    ??
  -t --test         ??
  -a --author[=]regex
                    Show only pull requests by this author
  -e --emails[=]regex
                    Show only pull requests involving anyone with an email
                    matching matching this regex.
  -P --participant[=]regex
                    Show only pull requests with participants matching this regex
  -t --to-branch[=](regex|branch)
                    Show only pull requests to this branch
  -f --from-branch[=](regex|branch)
                    Show only pull requests from this branchx
  -T --title[=]regex
                    Show only pull requests matching this title
  -S --state[=](OPEN|MERGED|DECLINED|ALL)
                    Show pull requests of this type (Default OPEN)

 CONFIGURATION:
  -h --host[=]str   Specify the Stash/Bitbucket Servier host name
  -P --password[=]str
                    The password to connect to the server as
  -u --username[=]str
                    The username to connect to the server as

  -v --verbose       Show more detailed option
     --version       Prints the version information
     --help          Prints this help information
     --man           Prints the full documentation for bb-cli

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<options ()>

Returns the command line options

=head2 C<pull_requests ()>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
