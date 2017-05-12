package Audio::Metadata::Flac::Block::Padding;
{
  $Audio::Metadata::Flac::Block::Padding::VERSION = '0.16';
}
BEGIN {
  $Audio::Metadata::Flac::Block::Padding::VERSION = '0.15';
}

use strict;
use warnings;

use Any::Moose;


extends 'Audio::Metadata::Flac::Block';


__PACKAGE__->meta->make_immutable;


sub type_code {
    ## Overriden.

    1;
}


no Any::Moose;


1;


__END__

=head1 NAME

Audio::Metadata::Flac::Block::Padding - Representation of PADDING type block of FLAC metadata.

=head1 DESCRIPTION

For internal use only by L<Audio::Metadata::Flac>.

=head1 AUTHOR

Egor Shipovalov, C<< <kogdaugodno at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Egor Shipovalov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
