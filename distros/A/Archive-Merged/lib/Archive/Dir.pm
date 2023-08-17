package Archive::Dir;
use strict;
use Carp qw(croak);
use Path::Class;
our $VERSION = '0.03';

=head1 NAME

Archive::Dir - a directory with an API like an Archive::Tar

=head1 SYNOPSIS

    my $ar = Archive::Dir->new('foo');

=head1 METHODS

=cut

sub new {
    my ($class, $directory) = @_;
    my $self = {
        directory => dir($directory),
    };
    bless $self => $class;
    $self
};

sub directory {
    $_[0]->{directory}
};

sub contains_file {
    -f $_[0]->directory->file($_[1])
};

sub get_content {
    my( $self, $file, %options ) = @_;
    $options{ binmode } ||= ':raw';
    $options{ binmode } = "<$options{binmode}";
    $self->directory->file($file)->slurp(iomode => $options{ binmode });
};

sub list_files {
    my ($self,$properties) = @_;
    croak "Listing properties is not (yet) implemented"
        if $properties;
    my @files;
    $self->directory->recurse(callback => sub { push @files, $_[0] if !$_[0]->is_dir});
    map { $_->relative( $self->directory ) } @files
}

sub extract_file {
    my ($self,$file,$target) = @_;
    if ($self->contains_file( $file )) {
        open my $fh, '>', $target
            or croak "Couldn't create '$target': $!";
        binmode $fh;
        print {$fh} $self->get_content($file);
    } else {
        croak "'$file' is not contained in '" . $self->directory . "'";
    };
};

1;

=head1 CAUTION

This module does not implement any encoding/decoding for file names in
the file system. It completely relies on L<Path::Class> to handle this issue.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/archive-merged>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Archive-Merged>
or via mail to L<archive-merged-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015-2023 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

=head1 SEE ALSO

L<Archive::Tar>

L<Archive::SevenZip::API::ArchiveTar>

=cut
