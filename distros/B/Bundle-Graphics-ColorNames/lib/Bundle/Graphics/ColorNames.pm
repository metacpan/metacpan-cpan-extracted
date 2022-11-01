
package Bundle::Graphics::ColorNames;

require 5.008;
use strict;
use warnings;

our $VERSION = '1.06';

1;

=head1 NAME

Bundle::Graphics::ColorNames - all color scheme modules with english names 

=head1 SYNOPSIS

This Module contains no code. Its only feature is his dependency list
which contains L<Graphics::ColorNames> as well as all modules that provide
one or more schemas of RGB values. These are:

L<Graphics::ColorNames::Crayola>

L<Graphics::ColorNames::EmergyC>

L<Graphics::ColorNames::GrayScale>

L<Graphics::ColorNames::HTML>

L<Graphics::ColorNames::Mozilla>

L<Graphics::ColorNames::Netscape>

L<Graphics::ColorNames::Pantone>

L<Graphics::ColorNames::VACCC>

L<Graphics::ColorNames::Werner>

L<Graphics::ColorNames::Windows>

L<Graphics::ColorNames::WWW>

=head1 AUTHOR

Herbert Breunung <lichtkind@cpan.org>

=head1 LICENSE

Copyright 2022 Herbert Breunung

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

__END__

our @Modules = qw/
    Graphics::ColorNames 
    Graphics::ColorNames::Crayola
    Graphics::ColorNames::EmergyC
    Graphics::ColorNames::GrayScale
    Graphics::ColorNames::HTML
    Graphics::ColorNames::Mozilla
    Graphics::ColorNames::Netscape
    Graphics::ColorNames::Pantone 
    Graphics::ColorNames::VACCC
    Graphics::ColorNames::Werner 
    Graphics::ColorNames::Windows 
    Graphics::ColorNames::WWW/;

our @Packages = qw/
    Graphics::ColorNames
    Graphics::ColorNames::Crayola 
    Graphics::ColorNames::CSS
    Graphics::ColorNames::EmergyC
    Graphics::ColorNames::GrayScale
    Graphics::ColorNames::HTML
    Graphics::ColorNames::IE
    Graphics::ColorNames::Mozilla
    Graphics::ColorNames::Netscape 
    Graphics::ColorNames::Pantone 
    Graphics::ColorNames::PantoneReport 
    Graphics::ColorNames::SVG
    Graphics::ColorNames::VACCC
    Graphics::ColorNames::Werner 
    Graphics::ColorNames::Windows 
    Graphics::ColorNames::WWW 
    Graphics::ColorNames::X/;

our @Schemes = qw/Crayola CSS EmergyC GrayScale HTML IE Mozilla Netscape
    Pantone PantoneReport SVG VACCC Werner Windows WWW X/;
