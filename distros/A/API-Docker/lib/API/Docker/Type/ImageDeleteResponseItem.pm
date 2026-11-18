package API::Docker::Type::ImageDeleteResponseItem;
# ABSTRACT: One entry of the C<200> response to C<DELETE /images/{name}>
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker untagged => Str;


docker deleted => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::ImageDeleteResponseItem - One entry of the C<200> response to C<DELETE /images/{name}>

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<ImageDeleteResponseItem> definition of
C<spec/v1.51.yaml>, which the swagger leaves undescribed. C<paths:> says
what it is: one entry of the C<200> response to C<DELETE /images/{name}> and
the C<ImagesDeleted> field of the C<200> response to C<POST /images/prune>.

=head2 untagged

The image ID of an image that was untagged.

=head2 deleted

The image ID of an image that was deleted.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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
