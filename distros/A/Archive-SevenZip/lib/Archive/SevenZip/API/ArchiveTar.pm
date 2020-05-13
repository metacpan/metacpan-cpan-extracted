package Archive::SevenZip::API::ArchiveTar;
use strict;
use Archive::SevenZip;
use Carp 'croak';

our $VERSION= '0.12';

=head1 NAME

Archive::SevenZip::API::ArchiveTar - Archive::Tar-compatibility API

=head1 SYNOPSIS

  my $ar = Archive::SevenZip->archiveTarApi(
      find => 1,
      archivename => $archivename,
      verbose => $verbose,
  );
  print "$_\n" for $ar->list_files;

This module implements just enough of the L<Archive::Tar>
API to make extracting work. Ideally
use this API to enable a script that uses Archive::Tar
to also read other archive files supported by 7z.

=head1 METHODS

=cut

sub new {
    my( $class, %options )= @_;
    $options{ sevenZip } = Archive::SevenZip->new();
    bless \%options => $class;
};

sub sevenZip { $_[0]->{sevenZip} }

=head2 C<< ->contains_file >>

=cut

sub contains_file {
    my( $self, $name ) = @_;
    $self->sevenZip->memmberNamed( $name )
};

=head2 C<< ->get_content >>

=cut

sub get_content {
    my( $self, $name ) = @_;
    $self->sevenZip->content( $name );
};

=head2 C<< ->list_files >>

=cut

sub list_files {
    my ($self,$properties) = @_;
    croak "Listing properties is not (yet) implemented"
        if $properties;
    my @files = $self->sevenZip->list;
    map { $_->fileName } @files
}

=head2 C<< ->extract_file >>

=cut

sub extract_file {
    my ($self,$file,$target) = @_;
    $self->sevenZip->extractMember( $file => $target );
};

1;

=head1 REPOSITORY

The public repository of this module is 
L<https://github.com/Corion/archive-sevenzip>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Archive-SevenZip>
or via mail to L<archive-sevenzip-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015-2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
