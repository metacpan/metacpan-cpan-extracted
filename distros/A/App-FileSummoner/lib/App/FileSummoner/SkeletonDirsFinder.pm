package App::FileSummoner::SkeletonDirsFinder;
BEGIN {
  $App::FileSummoner::SkeletonDirsFinder::VERSION = '0.005';
}

use 5.006;
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;

use Moose;

has 'skeletonsDir' => ( is => 'rw', default => '.skeletons' );

=head1 NAME

App::FileSummoner::SkeletonDirsFinder - The great new App::FileSummoner::SkeletonDirsFinder!

=head1 METHODS

=head2 findForFile

Find skeleton directories for a given file.

=cut

sub findForFile {
    my ($self, $path) = @_;

    return map {
        File::Spec->join($_, $self->skeletonsDir)
    } $self->skeletonsParentDirs(dirname($path));
}

=head2 skeletonsParentDirs

TODO

=cut

sub skeletonsParentDirs {
    my ($self, $path) = @_;

    return $self->findSkeletonsParentDirs(File::Spec->rel2abs($path));
}

=head2 findSkeletonsParentDirs

TODO

=cut

sub findSkeletonsParentDirs {
    my ($self, $path, @paths) = @_;

    return (@paths, $path) if $path eq '/';
    return $self->findSkeletonsParentDirs(dirname($path), (@paths, $path));
}

=head1 AUTHOR

Marian Schubert, C<< <marian.schubert at gmail.com> >>

=cut

1; # End of App::FileSummoner::SkeletonDirsFinder
