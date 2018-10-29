package Archive::Merged;
use strict;
use Carp qw(croak);
our $VERSION = '0.02';

=head1 NAME

Archive::Merged - virtually merge two archives

=head1 SYNOPSIS

  my $merged = Archive::Merged->new(
      Archive::Tar->new( 'default_theme.tar' ),
      Archive::SevenZip->archiveTarApi( archivename => 'theme.zip' ),
      Archive::Dir->new( 'customized/' ),
  );

=head1 METHODS

=head2 C<< Archive::Merged->new >>

  my $merged = Archive::Merged->new(
      Archive::Tar->new( 'default_theme.tar' ),
      Archive::Dir->new( 'customized/' ),
  );

Creates a new archive as the merged view of one or more archives
or directories.

=cut

sub new {
    my ($class, @archives) = @_;
    my $self = {
        archives => \@archives,
    };
    bless $self => $class;
    $self
};

=head2 C<< ->directory >>

=cut

sub directory {
    undef
};

=head2 C<< ->archives >>

  my @archives = $merged->archives;

Accessor for the archives that represent this archive.

=cut

sub archives {
    @{ $_[0]->{archives} }
}

=head2 C<< ->contains_file >>

  if( $merged->contains_file( $file ) ) {
      print "Yay!"
  } else {
      print "File '$file' not found";
  };

Returns the underlying archive that contains the file. Returns
undef if the file is not found.

=cut

sub contains_file {
    my( $self, $file ) = @_;
    for my $ar ($self->archives) {
        if( $ar->contains_file( $file ) ) {
            return $ar
        };
    };
};

=head2 C<< ->get_content( $file, %options ) >>

  my $content = $merged->get_content( $file, binmode => ':raw' )

Returns the content of the file, potentially with the encoding.

=cut

sub get_content {
    my( $self, $file, %options ) = @_;
    my $ar = $self->contains_file( $file );
    $ar->get_content( $file, %options )
};

=head2 C<< ->list_files( ) >>

    my @contents = $merged->list_files;

Lists the contained files of the archive. Files that are shadowed
are only listed once.

=cut

sub list_files {
    my ($self,$properties) = @_;
    croak "Listing properties is not (yet) implemented"
        if $properties;
    my %seen;
    my @files;
    for my $ar ($self->archives) {
        for my $file ($ar->list_files) {
            if( ! $seen{ $file }++) {
                push @files, $file;
            };
        };
    };
    @files
}

=head2 C<< ->extract_file( ) >>

    $merged->extract_file( $name => $target );

Extracts the file to the target name.

=cut

sub extract_file {
    my ($self,$file,$target) = @_;
    my $ar = $self->contains_file( $file );
    $ar->extract_file( $file, $target );
};

1;

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/archive-merged>.

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

Copyright 2015-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

=head1 SEE ALSO

L<Archive::Tar>

L<Archive::SevenZip::API::ArchiveTar>

=cut