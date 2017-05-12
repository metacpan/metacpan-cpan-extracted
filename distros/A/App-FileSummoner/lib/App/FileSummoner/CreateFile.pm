package App::FileSummoner::CreateFile;
BEGIN {
  $App::FileSummoner::CreateFile::VERSION = '0.005';
}

use Moose;
use Template;
use File::Spec;
use File::Basename qw/ fileparse /;

use App::FileSummoner::SkeletonDirsFinder;
use App::FileSummoner::Register qw(chooseSkeleton registerSkeleton);
use App::FileSummoner::Register::Rules;

=head1 NAME

App::FileSummoner::CreateFile - The great new App::FileSummoner::CreateFile!

=head1 SYNOPSIS

    my $summoner = App::FileSummoner::CreateFile->new();
    $summoner->summonFile('some/path/file.ext');

=head1 METHODS

=head2 summonFile

Create file using best possible skeleton.

=cut

sub summonFile {
    my ($self, $fileName) = @_;
    return $self->summonFileTo($fileName, $fileName);
}

=head2 summonFileToStdout

Print best possible skeleton for a given file to STDOUT.

=cut

sub summonFileToStdout {
    my ($self, $fileName) = @_;

    my $buffer;
    $self->summonFileTo($fileName, \$buffer);
    print $buffer;
}

# TODO: refactor this beast
sub summonFileTo {
    my ($self, $fileName, $target) = @_;

    $fileName = File::Spec->rel2abs( $fileName );
    my @skeletonDirs =
      App::FileSummoner::SkeletonDirsFinder->new->findForFile( $fileName );

    $self->loadRules(@skeletonDirs);

    my $template = Template->new(
        INCLUDE_PATH => [@skeletonDirs],
        TRIM         => 1,
    );

    my $skeleton = chooseSkeleton( $fileName )
      || die "Couldn't find suitable skeleton for " . $fileName;
    print STDERR "Skeleton: " . $skeleton . "\n";
    $template->process( $skeleton, $self->templateVarsForFile($fileName),
        $target )
        || die $template->error . "\n";
}

=head2 templateVarsForFile

Return template variables for given filename.

  {
      name => 'file name without extension',
  }

=cut

sub templateVarsForFile {
    my ($self, $fileName) = @_;

    my ($name) = fileparse($fileName, qr/\.[^.]*/);
    return { name => $name };
}

=head2 loadRules

Load rules from I<rules.pl> files located in skeleton directories.

=cut

sub loadRules {
    my ( $self, @skeletonDirs ) = @_;

    foreach my $dir (@skeletonDirs) {
        my $rules = $dir . "/rules.pl";
        if ( -e $rules ) {
            do $rules || die $@;
        }
    }
}

=head1 AUTHOR

Marian Schubert, C<< <marian.schubert at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-skeleton at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Skeleton>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::FileSummoner::CreateFile


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Skeleton>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Skeleton>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Skeleton>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Skeleton/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Marian Schubert.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of App::FileSummoner::CreateFile
