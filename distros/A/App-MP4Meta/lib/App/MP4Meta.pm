use 5.010;
use strict;
use warnings;

package App::MP4Meta;
{
  $App::MP4Meta::VERSION = '1.153340';
}

# ABSTRACT: Apply iTunes-like metadata to an mp4 file.

use App::Cmd::Setup -app;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MP4Meta - Apply iTunes-like metadata to an mp4 file.

=head1 VERSION

version 1.153340

=head1 DESCRIPTION

The C<mp4meta> command applies iTunes-like metadata to an mp4 file. The metadata is obtained by parsing the filename and searching the Internet to find its title, description and cover image, amongst others.

=head2 film

The C<film> command parses the filename and searches the OMDB for film metadata. See L<App::MP4Meta::Command::film> for more information.

=head2 tv

The C<tv> command parses the filename and searches the TVDB for TV Series metadata. See L<App::MP4Meta::Command::tv> for more information.

=head2 musicvideo

The C<musicvideo> command parses the filename in order to get the videos artist and song title. See L<App::MP4Meta::Command::musicvideo> for more information.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 CONTRIBUTORS

=over 4

=item *

Andrew Jones <andrew@andrew-jones.com>

=item *

Andrew Jones <andrewjones86@googlemail.com>

=item *

Jim Graham <jim@jim-graham.net>

=item *

andrewrjones <andrewjones86@googlemail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
