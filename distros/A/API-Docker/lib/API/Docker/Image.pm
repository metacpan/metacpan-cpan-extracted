package API::Docker::Image;
# ABSTRACT: Docker image entity
our $VERSION = '0.002';
use Moo;
use namespace::clean;


has client => (
  is       => 'ro',
  weak_ref => 1,
);


has Id           => (is => 'ro');


has ParentId     => (is => 'ro');
has RepoTags     => (is => 'ro');


has RepoDigests  => (is => 'ro');
has Created      => (is => 'ro');
has Size         => (is => 'ro');


has SharedSize   => (is => 'ro');
has VirtualSize  => (is => 'ro');
has Labels       => (is => 'ro');
has Containers   => (is => 'ro');

has Architecture => (is => 'ro');
has Os           => (is => 'ro');
has Config       => (is => 'ro');
has RootFS       => (is => 'ro');
has Metadata     => (is => 'ro');

sub inspect {
  my ($self) = @_;
  return $self->client->images->inspect($self->Id);
}


sub history {
  my ($self) = @_;
  return $self->client->images->history($self->Id);
}


sub tag {
  my ($self, %opts) = @_;
  return $self->client->images->tag($self->Id, %opts);
}


sub remove {
  my ($self, %opts) = @_;
  return $self->client->images->remove($self->Id, %opts);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Image - Docker image entity

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $docker = API::Docker->new;
    my $images = $docker->images->list;
    my $image = $images->[0];

    say $image->Id;
    say join ', ', @{$image->RepoTags};
    say $image->Size;

    $image->tag(repo => 'myrepo/app', tag => 'v1');
    $image->remove;

=head1 DESCRIPTION

This class represents a Docker image. Instances are returned by
L<API::Docker::API::Images> methods.

=head2 client

Reference to L<API::Docker> client.

=head2 Id

Image ID (usually sha256:... hash).

=head2 RepoTags

ArrayRef of repository tags (e.g., C<["nginx:latest", "nginx:1.21"]>).

=head2 Size

Image size in bytes.

=head2 inspect

    my $updated = $image->inspect;

Get fresh image information.

=head2 history

    my $history = $image->history;

Get image layer history.

=head2 tag

    $image->tag(repo => 'myrepo/app', tag => 'v1');

Tag the image.

=head2 remove

    $image->remove(force => 1);

Remove the image.

=head1 SEE ALSO

=over

=item * L<API::Docker::API::Images> - Image API operations

=item * L<API::Docker> - Main Docker client

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
