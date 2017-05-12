#
# This file is part of Audio-MPD-Common
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Audio::MPD::Common;
# ABSTRACT: common helper classes for mpd
$Audio::MPD::Common::VERSION = '2.003';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audio::MPD::Common - common helper classes for mpd

=head1 VERSION

version 2.003

=head1 DESCRIPTION

Depending on whether you're using a POE-aware environment or not, people
wanting to tinker with mpd (Music Player Daemon) will use either
L<POE::Component::Client::MPD> or L<Audio::MPD>.

But even if the run-cores of those two modules differ completely, they
are using the exact same common classes to represent the various mpd
states and information.

Therefore, those common classes have been outsourced to
L<Audio::MPD::Common>.

This module does not export any methods, but the dist provides the
following classes that you can query with perldoc:

=over 4

=item * L<Audio::MPD::Common::Item>

=item * L<Audio::MPD::Common::Item::Directory>

=item * L<Audio::MPD::Common::Item::Playlist>

=item * L<Audio::MPD::Common::Item::Song>

=item * L<Audio::MPD::Common::Stats>

=item * L<Audio::MPD::Common::Status>

=item * L<Audio::MPD::Common::Time>

=item * L<Audio::MPD::Common::Types>

=back

Note that those modules should not be of any use outside the two mpd
modules afore-mentioned.

=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Audio-MPD-Common>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Audio-MPD-Common>

=item * Git repository

L<http://github.com/jquelin/audio-mpd-common.git>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audio-MPD-Common>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audio-MPD-Common>

=back

You may want to look at the modules really accessing MPD:

=over 4

=item * L<Audio::MPD>

=item * L<POE::Component::Client::MPD>

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
