package App::Critique::Command::process;

use strict;
use warnings;

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Tiny      ();
use List::Util      ();
use Term::ANSIColor ':constants';

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'reset',  'resets the file index to 0',            { default => 0 } ],
        [ 'back',   'back up and re-process the last file',  { default => 0 } ],
        [ 'next',   'skip over processing the current file', { default => 0 } ],
        [ 'goto=i', 'goto to file at given index' ],
        [],
        [ 'blame', 'show the `git blame` block for each violation', { default => 0 } ],
        [],
        $class->SUPER::opt_spec
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    error('No acceptable value found for EDITOR in the critique config, please set one.')
        unless $App::Critique::CONFIG{EDITOR};

    local $Term::ANSIColor::AUTORESET = 1;

    my $session = $self->cautiously_load_session( $opt, $args );

    info('Session file loaded.');

    # TODO:
    # check to see if there are changes in the
    # working directory, if so, exit with an
    # error.

    # TODO:
    # add a new flag that will look at the last
    # commit and assuming it included the current
    # file, add the SHA to the session data (with a
    # special note saying it was commited manually)

    my @tracked_files = $session->tracked_files;

    # TODO:
    # not all these options can be given together, so
    # we should do some validation for that.
    # - SL

    if ( $opt->back ) {
        $session->dec_file_idx;
        $tracked_files[ $session->current_file_idx ]->forget_all;
    }

    if ( $opt->next ) {
        $session->inc_file_idx;
    }

    if ( $opt->reset ) {
        $session->reset_file_idx;
        $_->forget_all foreach @tracked_files;
    }

    if ( my $idx = $opt->goto ) {
        $session->set_file_idx( $idx );
    }

    if ( $session->current_file_idx == scalar @tracked_files ) {
        info(HR_DARK);
        info('All files have already been processed.');
        info(HR_LIGHT);
        info('- run `critique status` to see more information');
        info('- run `critique process --reset` to review all files again');
        info(HR_DARK);
        return;
    }

    my ($idx, $file);

MAIN:
    while (1) {

        info(HR_DARK);

        $idx  = $session->current_file_idx;
        $file = $tracked_files[ $idx ];

        my $path = $file->relative_path( $session->git_work_tree_root );

        info('Running Perl::Critic against (%s)', $path);
        info(HR_LIGHT);

        # perlcritic can fail, so lets guard against it and let the user
        # decide if they want to carry on
        my @violations;
        eval {
            @violations = $self->discover_violations( $session, $file, $opt );
            1;
        } or do {
            info(HR_ERROR);
            warn($@);
            info(HR_LIGHT);
            my $should_review = prompt_yn(
                BOLD(sprintf 'A error has occurred do you want to continue?'),
                { default => 'y' }
            );
            unless ( $should_review ) { exit }
            next;
        };

        # remember it the first time we use it
        # but do not update it for each re-process
        # which we do after each edit
        $file->remember('violations' => scalar @violations)
            unless $file->recall('violations');

        if ( @violations == 0 ) {
            info(ITALIC('No violations found, proceeding to next file.'));
            next MAIN;
        }
        else {
            my $should_review = prompt_yn(
                BOLD(sprintf 'Found %d violations, would you like to review them?', (scalar @violations)),
                { default => 'y' }
            );

            if ( $should_review ) {

                my ($reviewed, $edited) = (
                    $file->recall('reviewed') // 0,
                    $file->recall('edited')   // 0,
                );

                foreach my $violation ( @violations ) {

                    $self->display_violation( $session, $file, $violation, $opt );
                    $reviewed++;

                    my $should_edit = prompt_yn(
                        BOLD('Would you like to fix this violation?'),
                        { default => 'y' }
                    );

                    my $did_commit = 0;

                    if ( $should_edit ) {
                        $did_commit = $self->edit_violation( $session, $file, $violation );
                        $edited++ if $did_commit;
                    }

                    # keep state on disc ...
                    $file->remember('reviewed', $reviewed);
                    $file->remember('edited',   $edited);
                    $self->cautiously_store_session( $session, $opt, $args );

                    if ( $did_commit ) {
                        info(HR_LIGHT);
                        info('File was edited, re-processing is required');
                        redo MAIN;
                    }
                }
            }
        }

    } continue {

        $session->inc_file_idx;
        $self->cautiously_store_session( $session, $opt, $args );

        if ( ($idx + 1) == scalar @tracked_files ) {
            info(HR_LIGHT);
            info('Processing complete, run `status` to see results.');
            last MAIN;
        }

    }

}

sub discover_violations {
    my ($self, $session, $file, $opt) = @_;

    my @violations = $session->perl_critic->critique( $file->path->stringify );

    return @violations;
}


sub display_violation {
    my ($self, $session, $file, $violation, $opt) = @_;

    my $rel_filename = Path::Tiny::path( $violation->filename )->relative( $session->git_work_tree_root );

    info(HR_DARK);
    info(BOLD('Violation: %s'), $violation->description);
    info(HR_DARK);
    info('%s', $violation->explanation);
    #if ( $opt->verbose ) {
    #    info(HR_LIGHT);
    #    info('%s', $violation->diagnostics);
    #}
    info(HR_LIGHT);
    info('  policy   : %s'           => $violation->policy);
    info('  severity : %d'           => $violation->severity);
    info('  location : %s @ <%d:%d>' => (
        $rel_filename,
        $violation->line_number,
        $violation->column_number
    ));
    info(HR_LIGHT);
    info(ITALIC('%s'), $violation->source);

    if ( $opt->blame ) {
        info(HR_DARK);
        info('%s', $self->blame_violation(
            $session,
            $rel_filename,
            $violation->line_number
        ));
    }

    info(HR_LIGHT);
}

sub blame_violation {
    my ($self, $session, $rel_filename, $line_num) = @_;

    my $line_count = scalar Path::Tiny::path($rel_filename)->lines;
    my $start_line = $line_num - 5;
    my $end_line   = $line_num + 5;
    $end_line = $line_count if $end_line > $line_count;

    my @lines = $session->git_wrapper->blame(
        $rel_filename, {
            L => (join ',' => $start_line, $end_line )
        }
    );
    $lines[5] = BOLD($lines[5]);
    return join "\n" => @lines;
}

sub edit_violation {
    my ($self, $session, $file, $violation) = @_;

    my $git          = $session->git_wrapper;
    my $rel_filename = $violation->filename;
    my $abs_filename = Path::Tiny::path( $violation->filename )->relative( $session->git_work_tree_root );
    my $policy       = $violation->policy;
    my $rewriter     = $policy->can('rewriter') ? $policy->rewriter( $violation ) : undef;

    my $cmd_fmt  = $App::Critique::CONFIG{EDITOR};
    my @cmd_args = (
        $rel_filename,
        $violation->line_number,
        $violation->column_number
    );

    my $cmd = sprintf $cmd_fmt => @cmd_args;

EDIT:
    if ( $rewriter && $rewriter->can_rewrite ) {
        info(HR_LIGHT);
        info('... attempting to re-write violation.');
        my $document;
        eval {
            $document = $rewriter->rewrite;
            1;
        } or do {
            error('Unable to re-write violation(%s) because (%s)', $violation, $@);
        };
        info(BOLD('Violation re-written successfully!'));
        info('... attempting to save file(%s)', $abs_filename);
        eval {
            $document->save( $abs_filename );
            1;
        } or do {
            error('Unable to save file(%s) because (%s)', $abs_filename, $@);
        };
        info(BOLD('File(%s) saved successfully!'), $abs_filename);
    }
    else {
        system $cmd;
    }

    my $statuses = $git->status;
    my @changed  = $statuses->get('changed');
    my $did_edit = scalar grep { my $from = $_->from; $abs_filename =~ /$from/ } @changed;

    if ( $did_edit ) {
        info(HR_DARK);
        info('Changes detected, generating diff.');
        info(HR_LIGHT);
        info('%s', join "\n" => $git->RUN('diff', { 'color' => $App::Critique::CONFIG{COLOR} }));
        my $policy_name = $violation->policy;
        $policy_name =~ s/^Perl\:\:Critic\:\:Policy\:\://;

        my $commit_msg = sprintf "%s - critique(%s)" => $violation->description, $policy_name;

    CHOOSE:

        info(HR_LIGHT);
        my $commit_this_change = prompt_str(
            (
                BOLD('Commit Message:').
                "\n\n    ".(join "\n    " => split /\n/ => $commit_msg)."\n\n".
                BOLD("Press ENTER to accept this message, enter text to be appended to the commit message, or (n)o for more options.\n")
            ),
        );

        if ( !$commit_this_change ) {
            info(HR_DARK);
            info('Adding and commiting file (%s) to git', $abs_filename);
            info(HR_LIGHT);
            info('%s', join "\n" => $git->add($rel_filename, { v => 1 }));
            info('%s', join "\n" => $git->commit({ v => 1, message => $commit_msg }));

            my ($sha) = $git->rev_parse('HEAD');

            $file->remember('shas'     => [ @{ $file->recall('shas') || [] }, $sha ]);
            $file->remember('commited' => ($file->recall('commited') || 0) + 1);

            return 1;
        }
        elsif ( lc($commit_this_change) eq 'n' ) {
            info(HR_LIGHT);
            my $what_now = prompt_str(
                BOLD('What would you like to do? edit the (f)ile, edit the (c)ommit message or (a)ppend the commit message'),
                { valid => sub { $_[0] =~ m/[fca]{1}/ } }
            );

            if ( $what_now eq 'c' ) {
                info(HR_LIGHT);
                $commit_msg = prompt_str( BOLD('Please write a commit message') );
                $commit_msg =~ s/\\n/\n/g; # un-escape any newlines ...
                goto CHOOSE;
            }
            elsif ( $what_now eq 'a' ) {
                info(HR_LIGHT);
                $commit_msg .= "\n\n" . prompt_str( BOLD('Please append the commit message') );
                goto CHOOSE;
            }
            elsif ( $what_now eq 'f' ) {
                goto EDIT;
            }
        }
        else {
            $commit_msg .= "\n\n" . $commit_this_change;
            goto CHOOSE;
        }
    }
    else {
    RETRY:
        info(HR_LIGHT);
        my $what_now = prompt_str(
            BOLD('No edits found, would like to (e)dit again, (s)kip this violation or (b)lame the file?'),
            { valid => sub { $_[0] =~ m/[esb]{1}/ } }
        );

        if ( $what_now eq 'e' ) {
            goto EDIT;
        }
        elsif ( $what_now eq 's' ) {
            return 0;
        }
        elsif ( $what_now eq 'b' ) {
            info(HR_LIGHT);
            info('%s', $self->blame_violation(
                $session,
                $rel_filename,
                $violation->line_number
            ));
            goto RETRY;
        }
    }

    return 0;
}

1;

=pod

=head1 NAME

App::Critique::Command::process - Critique all the files.

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This command will start or resume the critique session, allowing you to
step through the files and critique them. This current state of this
processing will be stored in the critique session file and so can be
stopped and resumed at any time.

Note, this is an interactive command, so ...

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Critique all the files.

