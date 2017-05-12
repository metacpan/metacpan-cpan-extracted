package App::Critique::Command::remove;

use strict;
use warnings;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'dry-run', 'display list of files to be removed, but do not remove them' ],
        [],
        $class->SUPER::opt_spec,
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $session_file = App::Critique::Session->locate_session_file( $opt->git_work_tree );

    if (not -e $session_file) {
        if ( $opt->verbose ) {
            warning(
                'Unable to locate session file, looking for (%s)',
                $session_file // 'undef'
            );
        }
        error('No session file found, nothing removed.');
    }

    info('Attempting to remove session file ...');

    if ( $opt->dry_run ) {
        info('[dry-run] Found session file (%s), not removing.', $session_file);
    }
    else {
        if ( $session_file->remove ) {
            info('Successfully removed session file (%s).', $session_file);
        }
        else {
            if ( $opt->verbose ) {
                warning(
                    'Could not remove session file (%s) because: %s',
                    $session_file,
                    $!
                );
            }
            error('Unable to remove session file.');
        }

        info('Attempting to clean up session directory ...');

        my $branch = $session_file->parent;
        if ( my @children = $branch->children ) {
            info('Branch directory (%s) is not empty, it will not be removed', $branch);
            if ( $opt->verbose ) {
                info('Branch directory (%s) contains:', $branch);
                info('  %s', $_) foreach @children;
            }
        }
        else {
            info('Attempting to remove empty branch directory ...');
            if ( $branch->remove_tree ) {
                info('Successfully removed empty branch directory (%s).', $branch);
            }
            else {
                if ( $opt->verbose ) {
                    warning(
                        'Could not remove empty branch directory (%s) because: %s',
                        $branch,
                        $!
                    );
                }
                error('Unable to remove empty branch directory file.');
            }
        }

        my $repo = $branch->parent;
        if ( my @children = $repo->children ) {
            info('Branch directory (%s) is not empty, it will not be removed', $repo);
            if ( $opt->verbose ) {
                info('Repo directory (%s) contains:', $repo);
                info('  %s', $_) foreach @children;
            }
        }
        else {
            info('Attempting to remove empty repo directory ...');
            if ( $repo->remove_tree ) {
                info('Successfully removed empty repo directory (%s).', $repo);
            }
            else {
                if ( $opt->verbose ) {
                    warning(
                        'Could not remove empty repo directory (%s) because: %s',
                        $branch,
                        $!
                    );
                }
                error('Unable to remove empty repo directory file.');
            }
        }
    }

}

1;

=pod

=head1 NAME

App::Critique::Command::remove - Remove critique session files

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This command will remove the current session file, after which
it will attempt to delete the branch (../) directory and the
repository (../../) directory if they are empty.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Remove critique session files

