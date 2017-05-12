package Bundle::Graphics::ColorNames

use 5.005;
use strict;

our $VERSION = '1.04';

1;

__END__

=head1 NAME

Bundle::Graphics::ColorNames - bundle of schemas for Graphics::ColorNames

=head1 SYNOPSIS

  perl -MCPAN -e 'install Bundle::Graphics::ColorNames'

=head1 CONTENTS

Module::Load - used for dynamic module loading

Graphics::ColorNames - base module and schemas for Graphics::ColorNames

Graphics::ColorNames::X - default X-Windows schema

Graphics::ColorNames::HTML - HTML schema

Graphics::ColorNames::Windows - Microsoft Windows schema

Graphics::ColorNames::Netscape - deprecated Netscape 1.1 schema

Graphics::ColorNames::SVG - SVG-related colors

Graphics::ColorNames::WWW - subset of SVG

Graphics::ColorNames::IE - Microsoft Internet Explorer colors

Graphics::ColorNames::Mozilla - Mozilla colors

Graphics::ColorNames::GrayScale - grayscale schema

Graphics::ColorNames::VACCC - VisiBone Anglo-Centric Color Codes

Graphics::ColorNames::EmergyC - Eco-friendly web-design color palette

Graphics::ColorNames::Crayola - the original 48 crayola crayon colors

=head1 DESCRIPTION

This bundle provides a way to load L<Graphics::ColorNames> along with
additional color schemes.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head1 LICENSE

Copyright (c) 2004-2007 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
