package App::Critique::Command::status;

use strict;
use warnings;

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:STEVAN';

use Term::ANSIColor ':constants';

use App::Critique::Session;

use App::Critique -command;

sub execute {
    my ($self, $opt, $args) = @_;

    local $Term::ANSIColor::AUTORESET = 1;

    my $session = $self->cautiously_load_session( $opt, $args );

    info('Session file loaded.');

    my @tracked_files = $session->tracked_files;
    my $num_files     = scalar @tracked_files;
    my $curr_file_idx = $session->current_file_idx;
    my $git           = $session->git_wrapper;

    my ($violations, $reviewed, $edited, $commited) = (0, 0, 0, 0);
    foreach my $file ( @tracked_files ) {
        $violations += $file->recall('violations') if defined $file->recall('violations');
        $reviewed   += $file->recall('reviewed')   if defined $file->recall('reviewed');
        $edited     += $file->recall('edited')     if defined $file->recall('edited');
        $commited   += $file->recall('commited')   if defined $file->recall('commited');
    }

    if ( $opt->verbose ) {
        info(HR_DARK);
        info('CONFIG:');
        info(HR_LIGHT);
        info('  perl_critic_profile = %s', $session->perl_critic_profile // '[...]');
        info('  perl_critic_theme   = %s', $session->perl_critic_theme   // '[...]');
        info('  perl_critic_policy  = %s', $session->perl_critic_policy  // '[...]');
        info(HR_LIGHT);
        info('  git_work_tree       = %s', $session->git_work_tree      );
        info('  git_work_tree_root  = %s', $session->git_work_tree_root );
        info('  git_branch          = %s', $session->git_branch         );
        info('  git_head_sha        = %s', $session->git_head_sha       );
        
        info(HR_DARK);
        info('FILE CRITERIA:');
        info(HR_LIGHT);
        info('  filter       = %s', $session->file_criteria->{'filter'}       // '[...]');
        info('  match        = %s', $session->file_criteria->{'match'}        // '[...]');
        info('  no-violation = %s', $session->file_criteria->{'no_violation'} // '[...]');
    }

    info(HR_DARK);
    info('FILES: <legend: [v|r|e|c]:(idx) path>');
    if ( $opt->verbose ) {
        info(HR_LIGHT);
        info('CURRENT FILE INDEX: (%d)', $curr_file_idx);
    }
    info(HR_LIGHT);
    if ( $num_files ) {
        foreach my $i ( 0 .. $#tracked_files ) {
            my $file = $tracked_files[$i];
            info('%s [%s|%s|%s|%s]:(%d) %s',
                ($i == $curr_file_idx ? '>' : ' '),
                $file->recall('violations') // '-',
                $file->recall('reviewed')   // '-',
                $file->recall('edited')     // '-',
                $file->recall('commited')   // '-',
                $i,                
                $file->relative_path( $session->git_work_tree_root ),
            );
            if ( $opt->verbose ) {
                foreach my $sha ( @{ $file->recall('shas') || [] } ) {
                    info('           | %s', $git->show($sha, { format => '%h - %s', s => 1 }));
                }
            }
        }
    }
    else {
        info(ITALIC('... no files added.'));
    }
    info(HR_DARK);
    info('TOTAL: %s file(s)',   format_number($num_files) );
    info('  (v)iolations = %s', format_number($violations));
    info('  (r)eviwed    = %s', format_number($reviewed)  );
    info('  (e)dited     = %s', format_number($edited)    );
    info('  (c)ommited   = %s', format_number($commited)  );

    if ( $opt->verbose ) {
        info(HR_LIGHT);
        info('PATH: (%s)', $session->session_file_path);
    }
    info(HR_DARK);

}

1;

=pod

=head1 NAME

App::Critique::Command::status - Display status of the current critique session.

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This command will display information about the current critique session.
Among other things, this will include information about each of the files,
such as how many violations were found, how many of those violations were
reviewed, and how many were edited.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Display status of the current critique session.

