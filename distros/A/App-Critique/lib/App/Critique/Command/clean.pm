package App::Critique::Command::clean;

use strict;
use warnings;

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:STEVAN';

use App::Critique::Session;

use App::Critique -command;

sub opt_spec {
    my ($class) = @_;
    return (
        [ 'dry-run', 'display the pruned list of files, but do not overwrite' ],
        [],
        $class->SUPER::opt_spec,
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $session = $self->cautiously_load_session( $opt, $args );

    info('Session file loaded.');

    my @removed_files;
    my @preserved_files;
    
    my @tracked_files = $session->tracked_files;
    
    info('Reviewing %s file(s).', format_number(scalar @tracked_files));
    
    foreach my $file ( @tracked_files ) {
        if ( -e $file->path ) {
            push @preserved_files => $file;
        }
        else {
            push @removed_files => $file;
        }
    }
    
    if ( @removed_files ) {
        info('Found %s removed file(s).', format_number(scalar @removed_files));
        
        if ( $opt->verbose || $opt->dry_run ) {
            info(HR_LIGHT);
            info($_->path) foreach @removed_files;
            info(HR_LIGHT);
        }
        
        if ( $opt->dry_run ) {
            info('[dry-run] Would have updated list of %s file(s).', format_number(scalar @preserved_files));
        }
        else {
            $session->set_tracked_files( @preserved_files );
            $session->reset_file_idx;
            info('Sucessfully updated list of %s file(s).', format_number(scalar @preserved_files));

            $self->cautiously_store_session( $session, $opt, $args );
            info('Session file stored successfully (%s).', $session->session_file_path);
        }
    }
    else {
        info('Nothing to remove, so nothing to change, so session file is untouched.');
    }

}

1;

=pod

=head1 NAME

App::Critique::Command::clean - Clean up the set of file for the current critique session

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This command will clean up the set of files for the current critique 
session. If a file has been deleted in the filesystem, this will also 
remove that file from the critique session as well.

NOTE: This will reset the current file index, but not any of the 
accumulated statistics. 

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Clean up the set of file for the current critique session

