package Audio::TinySoundFont::XS;

use v5.14;
use warnings;
our $VERSION = '0.12';

require XSLoader;
XSLoader::load( 'Audio::TinySoundFont', $VERSION );

use parent qw/Exporter/;

1;
__END__

=encoding utf-8

=head1 NAME

Audio::TinySoundFont::XS - XS interface to TinySoundFont.

=head1 DESCRIPTION

No user-serviceable parts, see L<Audio::TinySoundFont>

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2020- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

L<Audio::TinySoundFont>, L<TinySoundFont|https://github.com/schellingb/TinySoundFont>

=cut
