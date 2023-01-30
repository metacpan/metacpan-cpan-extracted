package Alien::Font::Vera;

use strict;
use warnings;

our $VERSION = '0.013';

use File::ShareDir 'dist_dir';
use File::Spec;

sub path { File::Spec->catfile( dist_dir('Alien-Font-Vera') , 'Vera.ttf') }

1;

__END__

=head1 NAME

Alien::Font::Vera - Access to Vera truetype file

=head1 SYNOPSIS

    use Alien::Font::Vera;
    
    my $path = Alien::Font::Vera::path;

=head1 DESCRIPTION

This module was created as an optional dependency of L<Project2::Gantt>
to have access to a ttf font file.

Thus only the .ttf file is provided since this is what L<Imager> can read.

Distros might redirect to pre-existing resources.

=head1 FONT

Vera font is provided using the Bitstream license (share/License.txt) also present in this
package.

=head1 AUTHOR

Bruno Ramos <bramos@cpan.org>

=head1 ACKNOWLEDGEMENTS

This module is inspired by L<Alien::Font::Uni> from Herbert Breunung

=head1 COPYRIGHT

Copyright(c) 2023 by Bruno Ramos

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The included Vera font is licensed under the Bitstream License (see share/License.txt)
