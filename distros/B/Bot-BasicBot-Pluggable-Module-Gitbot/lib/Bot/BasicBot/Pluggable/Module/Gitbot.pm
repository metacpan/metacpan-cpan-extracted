use 5.008;

use MooseX::Declare;

class Bot::BasicBot::Pluggable::Module::Gitbot
    extends Bot::BasicBot::Pluggable::Module
{
    our $VERSION = '1.00.01';

    use File::Fu   qw();
    use File::Spec qw();
    use Git        qw();

    use File::Basename  qw( basename  );
    use List::MoreUtils qw( natatime  );
    use Text::Pluralize qw( pluralize );

    has _repos => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'ArrayRef[Git]',
        default => sub { [] },
        lazy    => 1,
        handles => {
            _count_repos => 'count',
            _first_repo  => 'first',
        },
    );

    method init()
    {
        $self->set(git_repo_root => File::Spec->rel2abs('repositories'))
            unless $self->get('git_repo_root');

        $self->set(git_gitweb_url => 'http://localhost/')
            unless $self->get('git_gitweb_url');

        $self->_recache_repos();
    }

    method help($message)
    {
        return pluralize("I {don't |}know about {any|%d} Git repositor(y|ies).", $self->_count_repos()) . '  I respond to the pattern /([0-9a-f]{7,})(?::(\S+))?/i with a GitWeb URL.';
    }

    method told($message)
    {
        my @matches;
        push @matches, $self->_get_sha_text($message->{body});
        push @matches, $self->_get_repo_text($message->{body});
        return unless @matches;

        return join "\n", map {
            my $ref = defined $_->{sha}
                ? substr($_->{sha}, 0, 7)
                : $_->{branch};

            my $blob = '';

            if (defined $_->{filename}) {
                $ref .= ':' . $_->{filename};
                $blob = ' [blob]';
            }

            my $commit_message = defined $_->{commit_message}
                ? $_->{commit_message} . ' - '
                : '';

            "[@{[ $_->{repo} ]} $ref] $commit_message@{[ $_->{gitweb_url} ]}$blob"
        } @matches;
    }

    method _get_sha_text($message)
    {
        my @matches = $message =~ /(([0-9a-f]{7,})(?::(\S+))?)/gi;
        return unless @matches;

        my @results;
        my $iterator = natatime(3, @matches);
        while (my ($match, $sha, $filename) = $iterator->()) {
            my %match_info = $self->_get_info_for_sha($sha, $filename);
            next unless %match_info;

            push(
                @results,
                {
                    match          => $match,
                    sha            => $sha,
                    filename       => $filename,
                    gitweb_url     => $match_info{gitweb_url},
                    repo           => $match_info{repo},
                    commit_message => $match_info{commit_message},
                },
            );
        }

        return @results;
    }

    method _get_repo_text($message)
    {
        my @matches = $message =~ m|(([^/ ]+)/([^: ]+)(?::(\S+))?)|g;
        return unless @matches;

        my @results;
        my $iterator = natatime(4, @matches);
        while (my ($match, $repo_name, $branch, $filename) = $iterator->()) {
            my %match_info = $self->_get_info_for_repo($repo_name, $branch, $filename);
            next unless %match_info;
            push(
                @results,
                {
                    match          => $match,
                    branch         => $branch,
                    filename       => $filename,
                    gitweb_url     => $match_info{gitweb_url},
                    repo           => $match_info{repo},
                    commit_message => $match_info{commit_message},
                },
            );
        }

        return @results;
    }

    method _get_info_for_sha($sha, $filename?)
    {
        my $repo = $self->_first_repo(sub {
            return eval {
                $_->command_oneline(
                    [ 'cat-file', '-t', $sha, ],
                    { STDERR => 0 },
                )
            } ? 1 : 0;
        });
        return unless $repo;

        my $type           = $self->_obj_type_for_repo_and_sha($repo, $sha);
        my $commit_message = $self->_commit_message_for_repo_and_committish($repo, $sha);
        my $project        = $self->_project_name_from_repo($repo);

        my $gitweb_url = $self->_get_gitweb_url({
            project  => $project,
            type     => $type,
            commit   => $sha,
            filename => $filename,
        });

        return (
            gitweb_url     => $gitweb_url,
            repo           => $project,
            commit_message => $commit_message,
        );
    }

    method _get_info_for_repo($repo_name, $branch, $filename?)
    {
        my $repo = $self->_first_repo(sub {
                my $name = basename(
                    $_->wc_path()
                        ? $_->wc_path()
                        : $_->repo_path()
                );

                my ($base_repo_name)   = $name      =~ m/(.*)(?:\.git)?$/i;
                my ($base_search_name) = $repo_name =~ m/(.*)(?:\.git)?$/i;

                return 0 unless $base_repo_name =~ m/$base_search_name/i;

                return eval {
                    $_->command_oneline(
                        [ 'rev-parse', $branch, ],
                        { STDERR => 0 },
                    )
                } ? 1 : 0;
        });
        return unless $repo;

        my $commit_message = $self->_commit_message_for_repo_and_committish($repo, $branch);
        my $project        = $self->_project_name_from_repo($repo);

        my $gitweb_url = $self->_get_gitweb_url({
            type     => 'log',
            commit   => $branch,
            project  => $project,
            filename => $filename,
        });

        return (
            gitweb_url     => $gitweb_url,
            repo           => $project,
            commit_message => $commit_message,
        );
    }

    method _project_name_from_repo($repo)
    {
        return basename(
            $repo->wc_path()
                ? $repo->wc_path()
                : $repo->repo_path()
        );
    }

    method _obj_type_for_repo_and_sha($repo, $sha)
    {
        return eval {
            $repo->command_oneline(
                [ 'cat-file', '-t', $sha, ],
                { STDERR => 0 },
            )
        };
    }

    method _project_name_from_repo($repo)
    {
        return basename(
            $repo->wc_path()
                ? $repo->wc_path()
                : $repo->repo_path()
        );
    }

    method _commit_message_for_repo_and_committish($repo, $committish)
    {
        my $type = $self->_obj_type_for_repo_and_sha($repo, $committish);
        return undef unless defined $type && $type eq 'commit';

        return eval {
            $repo->command_oneline(
                [ 'log', '-1', '--pretty=format:%s', $committish, ],
                { STDERR => 0 },
            )
        };
    }

    method _obj_type_for_repo_and_sha($repo, $sha)
    {
        return eval {
            $repo->command_oneline(
                [ 'cat-file', '-t', $sha, ],
                { STDERR => 0 },
            )
        };
    }

    method admin($message)
    {
        return unless $message->{body} =~ /^!git /i;
        $message->{body} =~ s/^!git\s+//;

        if (my ($new_repo_root) = $message->{body} =~ /^repo_root(?:\s+(.*))?/i) {
            if ($new_repo_root) {
                $self->set(git_repo_root => File::Spec->rel2abs($new_repo_root));
                $self->_recache_repos();
                return "repo_root is now: '@{[ $self->get('git_repo_root') ]}'";
            } else {
                return "repo_root is: '@{[ $self->get('git_repo_root') ]}'";
            }
        } elsif (my ($new_gitweb_url) = $message->{body} =~ /^gitweb_url(?:\s+(.*))?/i) {
            if ($new_gitweb_url) {
                $self->set(git_gitweb_url => $new_gitweb_url);
                return "gitweb_url is now: '@{[ $self->get('git_gitweb_url') ]}'";
            } else {
                return "gitweb_url is: '@{[ $self->get('git_gitweb_url') ]}'";
            }
        } elsif ($message->{body} =~ /^refresh_repos$/i) {
            $self->_recache_repos();
            return pluralize("I {no longer|now} know about {any|%d} Git repositor(y|ies).", $self->_count_repos());
        } else {
            return "Buh? Wha?";
        }
    }

    method _recache_repos()
    {
        my @repos = ();
        my $repo_root = File::Fu->dir($self->get('git_repo_root'));

        return unless $repo_root->d();

        foreach my $dir ($repo_root->list()) {
            next unless $dir->d();

            my $repo = Git->repository(Directory => $dir->stringify());
            next unless $repo;

            push @repos, $repo;
        }
        $self->_repos([@repos]);
    }

    method _get_gitweb_url($options)
    {
        return unless defined $options->{commit} && defined $options->{project};

        my $base         = $self->get('git_gitweb_url');
        my $type         = $options->{type};
        my $commit       = $options->{commit};
        my $project      = $options->{project};
        my $extra_params = '';

        if ($type eq 'commit') {
            $type = 'commitdiff';
        }

        if (defined $options->{filename}) {
            $extra_params .= ";f=@{[ $options->{filename} ]}";
            $type = 'blob';
        }

        return "$base?p=$project;a=$type;hb=$commit$extra_params";
    }

=head1 NAME

Bot::BasicBot::Pluggable::Module::Gitbot - A Bot::BasicBot::Pluggable Module to give out Gitweb links for commits.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=end readme

=head1 VERSION

1.00.01

=head1 SYNOPSIS

    use Bot::BasicBot::Pluggable;

    my $bot = Bot::BasicBot::Pluggable->new();

    $bot->load('Gitbot');
    ...

or

    !load Gitbot


Once the module is loaded, you'll need to configure the module.  Using admin commands.

    !git gitweb_url http://example.com/
    !git repo_root /path/to/where/your/bare/git/repositories/are/


Any time someone says a SHA1 (full, or abbreviated with a minimum of 7
characters) where the bot can hear it, it will try to find a repository under
C<repo_root>, and provide a GitWeb url to the commitdiff of that SHA1.

    <me> gitbot: 1a2b3c4
    <gitbot> me: [repo.git 1a2b3c4] http://example.com/?p=my_repo.git;a=commitdiff;hb=1a2b3c4


You can also specify things in the form C<< <sha>:<file> >>, and the module will
reply with a link to the blob of that file, in the commit specified by the SHA.

    <me> Hey, you should check out 1a2b3c4:README
    <gitbot> [repo.git 1a2b3c4:README] http://example.com/?p=my_repo.git;a=blob;hb=1a2b3c4;f=README [blob]


If you wish you reference a ref from a specific repository, you can do that,
too.  Just say something in the form of C<< <repo>/<ref> >>, where C<< <repo> >>
is the name of the repository on disk (optionally without the C<.git> at the
end), and C<< <ref> >> is something parsable by C<git rev-parse>.

    <me> Anyone seen the latest commits on gitbot/master ?
    <gitbot> [gitbot.git master] http://example.com/?p=gitbot.git;a=log;hb=master

    <me> Could someone code review project/refs/personal/my-topic-branch ?
    <gitbot> [project.git refs/personal/my-topic-branch] http://example.com/?p=gitbot.git;a=log;hb=refs/personal/my-topic-branch


You can also directly link to a file this way using C<< <repo>/<ref>:<file> >>.

    <me> You should check out project/master:README
    <gitbot> [project.git master:README] http://example.com/?p=project.git;a=blob;hb=master;f=README [blob]


=head1 AUTHOR

Jacob Helwig, C<< <jhelwig at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bot-basicbot-pluggable-module-gitbot at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-Gitbot>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::Gitbot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-Gitbot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-Gitbot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-Gitbot>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-Gitbot>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jacob Helwig, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

    __PACKAGE__->meta->make_immutable(inline_constructor => 0);
}

1;
