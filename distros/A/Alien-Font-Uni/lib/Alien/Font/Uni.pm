use strict;

package Alien::Font::Uni;
our $VERSION = '0.3';

use File::ShareDir 'dist_dir';
use File::Spec;
 
sub get_path { File::Spec->catfile( dist_dir('Alien-Font-Uni') , 'unifont-'.font_version().'.ttf') }

sub font_version { '15.0.01' }
sub font_vstring { v15.0.01  }

1;

__END__

=pod

=head1 NAME

Alien::Font::Uni - access to Unifont truetype file

=head1 SYNOPSIS 

    use Alien::Font::Uni;
    
    my $path = Alien::Font::Uni::get_path();
    my $vstring = Alien::Font::Uni::font_vstring();
    my $string  = Alien::Font::Uni::font_version();

=head1 DESCRIPTION

This module was created as an optional dependency of L<Chart>
to have access to an unicode complete scaleable font file. 
Thus only the .ttf file is provided since this is what L<GD> can read.
Distros might redirect to pre-existing resources.

=head1 FONT

Unifont 15, Copyright(c) 1998 - 2022 by Roman Czyborra, Paul Hardy
and contributors - Licensed under OFL 1.1

=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2022 by Herbert Breunung

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl 
itself.

=cut

