package App::Critique::Command;

use strict;
use warnings;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Tiny ();

use App::Cmd::Setup -command;

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [ 'git-work-tree=s', 'git working tree, defaults to current working directory', { default => Path::Tiny->cwd } ],
        [],
        [ 'verbose|v',       'display additional information', { default => $App::Critique::CONFIG{'VERBOSE'}                     } ],
        [ 'debug|d',         'display debugging information',  { default => $App::Critique::CONFIG{'DEBUG'}, implies => 'verbose' } ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->usage_error('The git-work-tree does not exist (' . $opt->git_work_tree . ')')
        unless -d $opt->git_work_tree;
}

sub cautiously_load_session {
    my ($self, $opt, $args) = @_;

    if ( my $session_file_path = App::Critique::Session->locate_session_file( $opt->git_work_tree ) ) {

        my $session;
        eval {
            $session = App::Critique::Session->load( $session_file_path );
            1;
        } or do {
            my $e = "$@";
            chomp $e;
            if ( $opt->debug ) {
                App::Critique::Plugin::UI::_error("Unable to load session file (%s), because:\n  %s", $session_file_path, $e);
            }
            else {
                App::Critique::Plugin::UI::_error('Unable to load session file (%s), run with --debug|d for more information', $session_file_path);
            }
        };

        return $session;
    }

    error('No session file found, perhaps you forgot to call `init`.');
}

sub cautiously_store_session {
    my ($self, $session, $opt, $args) = @_;

    my $session_file_path = $session->session_file_path;

    eval {
        $session->store;
        1;
    } or do {
        my $e = "$@";
        chomp $e;
        if ( $opt->debug ) {
            App::Critique::Plugin::UI::_error("Unable to store session file (%s), because:\n  %s", $session_file_path, $e);
        }
        else {
            App::Critique::Plugin::UI::_error('Unable to store session file (%s), run with --debug|d for more information', $session_file_path);
        }
    };

    return $session_file_path;
}

1;

=pod

=head1 NAME

App::Critique::Command - Command base class for App::Critique

=head1 VERSION

version 0.04

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Command base class for App::Critique


