package App::Codeowners;
# ABSTRACT: A tool for managing CODEOWNERS files

use v5.10.1;    # defined-or
use utf8;
use warnings;
use strict;

use App::Codeowners::Formatter;
use App::Codeowners::Options;
use App::Codeowners::Util qw(find_codeowners_in_directory run_git git_ls_files git_toplevel);
use Color::ANSI::Util 0.03 qw(ansifg);
use File::Codeowners 0.54;
use Path::Tiny;

our $VERSION = '0.51'; # VERSION


sub main {
    my $class = shift;
    my $self  = bless {}, $class;

    my $opts = App::Codeowners::Options->new(@_);

    my $color = $opts->{color};
    local $ENV{NO_COLOR} = 1 if defined $color && !$color;

    my $command = $opts->command;
    my $handler = $self->can("_command_$command")
        or die "Unknown command: $command\n";

    binmode(STDOUT, ':encoding(UTF-8)');
    $self->$handler($opts);

    exit 0;
}

sub _command_show {
    my $self = shift;
    my $opts = shift;

    my $toplevel = git_toplevel('.') or die "Not a git repo\n";

    my $codeowners_path = find_codeowners_in_directory($toplevel)
        or die "No CODEOWNERS file in $toplevel\n";
    local $ENV{GIT_CODEOWNERS_ALIASES} = 1 if $opts->{expand_aliases};
    my $codeowners = $self->_parse_codeowners($codeowners_path);

    my ($proc, $cdup) = run_git(qw{rev-parse --show-cdup});
    $proc->wait and exit 1;

    my $show_projects = $opts->{projects} // scalar @{$codeowners->projects};

    my $formatter = App::Codeowners::Formatter->new(
        format  => $opts->{format} || ' * %-50F %O',
        handle  => *STDOUT,
        columns => [
            'File',
            $opts->{patterns} ? 'Pattern' : (),
            'Owner',
            $show_projects ? 'Project' : (),
        ],
    );

    my %filter_owners   = map { $_ => 1 } @{$opts->{owner}};
    my %filter_projects = map { $_ => 1 } @{$opts->{project}};
    my %filter_patterns = map { $_ => 1 } @{$opts->{pattern}};

    $proc = git_ls_files('.', $opts->args);
    while (my $filepath = $proc->next) {
        my $match = $codeowners->match(path($filepath)->relative($cdup),
            expand => $opts->{expand_aliases});
        if (%filter_owners) {
            for my $owner (@{$match->{owners}}) {
                goto ADD_RESULT if $filter_owners{$owner};
            }
            next;
        }
        if (%filter_patterns) {
            goto ADD_RESULT if $filter_patterns{$match->{pattern} || ''};
            next;
        }
        if (%filter_projects) {
            goto ADD_RESULT if $filter_projects{$match->{project} || ''};
            next;
        }
        ADD_RESULT:
        $formatter->add_result([
            $filepath,
            $opts->{patterns} ? $match->{pattern} : (),
            $match->{owners},
            $show_projects ? $match->{project} : (),
        ]);
    }
    $proc->wait and exit 1;
}

sub _command_owners {
    my $self = shift;
    my $opts = shift;

    my $toplevel = git_toplevel('.') or die "Not a git repo\n";

    my $codeowners_path = find_codeowners_in_directory($toplevel)
        or die "No CODEOWNERS file in $toplevel\n";
    my $codeowners = $self->_parse_codeowners($codeowners_path);

    my $results = $codeowners->owners($opts->{pattern});

    my $formatter = App::Codeowners::Formatter->new(
        format  => $opts->{format} || '%O',
        handle  => *STDOUT,
        columns => [qw(Owner)],
    );
    $formatter->add_result(map { [$_] } @$results);
}

sub _command_patterns {
    my $self = shift;
    my $opts = shift;

    my $toplevel = git_toplevel('.') or die "Not a git repo\n";

    my $codeowners_path = find_codeowners_in_directory($toplevel)
        or die "No CODEOWNERS file in $toplevel\n";
    my $codeowners = $self->_parse_codeowners($codeowners_path);

    my $results = $codeowners->patterns($opts->{owner});

    my $formatter = App::Codeowners::Formatter->new(
        format  => $opts->{format} || '%T',
        handle  => *STDOUT,
        columns => [qw(Pattern)],
    );
    $formatter->add_result(map { [$_] } @$results);
}

sub _command_projects {
    my $self = shift;
    my $opts = shift;

    my $toplevel = git_toplevel('.') or die "Not a git repo\n";

    my $codeowners_path = find_codeowners_in_directory($toplevel)
        or die "No CODEOWNERS file in $toplevel\n";
    my $codeowners = $self->_parse_codeowners($codeowners_path);

    my $results = $codeowners->projects;

    my $formatter = App::Codeowners::Formatter->new(
        format  => $opts->{format} || '%P',
        handle  => *STDOUT,
        columns => [qw(Project)],
    );
    $formatter->add_result(map { [$_] } @$results);
}

sub _command_create { goto &_command_update }
sub _command_update {
    my $self = shift;
    my $opts = shift;

    my ($filepath) = $opts->args;

    my $path = path($filepath || '.');
    my $repopath;

    die "Does not exist: $path\n" if !$path->parent->exists;

    if ($path->is_dir) {
        $repopath = $path;
        $path = find_codeowners_in_directory($path) || $repopath->child('CODEOWNERS');
    }

    my $is_new = !$path->is_file;

    my $codeowners;
    if ($is_new) {
        $codeowners = File::Codeowners->new;
        my $template = <<'END';
 This file shows mappings between subdirs/files and the individuals and
 teams who own them. You can read this file yourself or use tools to query it,
 so you can quickly determine who to speak with or send pull requests to.

 Simply write a gitignore pattern followed by one or more names/emails/groups.
 Examples:
   /project_a/**  @team1
   *.js  @harry @javascript-cabal
END
        for my $line (split(/\n/, $template)) {
            $codeowners->append(comment => $line);
        }
    }
    else {
        $codeowners = $self->_parse_codeowners($path);
    }

    if ($repopath) {
        # if there is a repo we can try to update the list of unowned files
        my ($proc, @filepaths) = git_ls_files($repopath);
        $proc->wait and exit 1;
        $codeowners->clear_unowned;
        $codeowners->add_unowned(grep { !$codeowners->match($_) } @filepaths);
    }

    $codeowners->write_to_filepath($path);
    print STDERR "Wrote $path\n";
}

sub _parse_codeowners {
    my $self = shift;
    my $path = shift;
    return File::Codeowners->parse_from_filepath($path, aliases => $ENV{GIT_CODEOWNERS_ALIASES});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners - A tool for managing CODEOWNERS files

=head1 VERSION

version 0.51

=head1 DESCRIPTION

This is the implementation of the F<git-codeowners> command.

See L<git-codeowners> for documentation.

=head1 METHODS

=head2 main

    App::Codeowners->main(@ARGV);

Run the script and exit; does not return.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/git-codeowners/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
