package App::Critique::Command::init;

use strict;
use warnings;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'perl-critic-profile=s', 'path to a Perl::Critic profile to use (default let Perl::Critic decide)' ],
        [ 'perl-critic-theme=s',   'Perl::Critic theme expression to use' ],
        [ 'perl-critic-policy=s',  'singular Perl::Critic policy to use (overrides -theme and -policy)' ],
        [],
        [ 'force',                 'force overwriting of existing session file' ],
        [],
        $class->SUPER::opt_spec,
    )
}

sub execute {
    my ($self, $opt, $args) = @_;

    if ( $opt->verbose ) {
        info(HR_LIGHT);
        info('Attempting to initialize session file using the following options:');
        info(HR_LIGHT);
        info('  --perl-critic-profile = %s', $opt->perl_critic_profile // '[...]');
        info('  --perl-critic-theme   = %s', $opt->perl_critic_theme   // '[...]');
        info('  --perl-critic-policy  = %s', $opt->perl_critic_policy  // '[...]');
    }
    else {
        info('Attempting to initialize session file ...');
    }

    my $session = App::Critique::Session->new(
        perl_critic_profile => $opt->perl_critic_profile,
        perl_critic_theme   => $opt->perl_critic_theme,
        perl_critic_policy  => $opt->perl_critic_policy,
        git_work_tree       => $opt->git_work_tree,
    );

    if ( $opt->verbose ) {
        info(HR_LIGHT);
        info('Successuflly created session with the following configuration:');
        info(HR_LIGHT);
        info('  perl_critic_profile = %s', $session->perl_critic_profile // '[auto]');
        info('  perl_critic_theme   = %s', $session->perl_critic_theme   // '[auto]');
        info('  perl_critic_policy  = %s', $session->perl_critic_policy  // '[auto]');
        info('  git_work_tree       = %s', $session->git_work_tree       // '[auto]');
        info('  git_branch          = %s', $session->git_branch          // '[auto]');
        info(HR_LIGHT);
    }
    else {
        info('Successuflly created session.');
    }

    if ( $session->session_file_exists ) {
        my $session_file_path = $session->session_file_path;
        if ( $opt->force ) {
            warning('Overwriting session file (%s) with --force option.', $session_file_path);
        }
        else {
            error(
                'Unable to overwrite session file (%s) without --force option.',
                $session_file_path
            );
        }
    }

    $self->cautiously_store_session( $session, $opt, $args );

    info('Session file (%s) initialized successfully.', $session->session_file_path);
}

1;

=pod

=head1 NAME

App::Critique::Command::init - Initialize critique session file

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This command will create a critique session file in your F<~/.critique>
directory (including creating the F<~/.critique> directory if needed).
This file will be used to store information about the critque session,
such as the set of files you wish to critique and your progress in
processing the set.

The specific file path for the critique session will be based on the
information provided through the command line options, and will look
something like this:

  ~/.critique/<git-repo>/<git-branch>/session.json

The value of C<git-repo> will be surmised from the C<git-work-tree>
which itself defaults to finding the root of the C<git> working directory
via your current working directory.

The value of C<git-branch> comes directly from the command line option,
or will default itself to the currently active C<git> branch.

You must also supply L<Perl::Critic> informaton must be specified, either
as a L<Perl::Critic> profile config (ex: F<perlcriticrc>) with additional
L<Perl::Critic> 'theme' expression added. Alternatively you can just
specify a single L<Perl::Critic::Policy> to use during the critique
session. If no L<Perl::Critic> specific options are detected, then we will
do whatever is the default for L<Perl::Critic>, which currently is to
use all the available policies with their default configuration.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Initialize critique session file

