package Convert::ModHex;

# ABSTRACT: Conversion utilities between Yubico ModHex and hexa/decimal

use strict;
use warnings;
use parent 'Exporter';

our $VERSION = '0.001'; # VERSION
our $AUTHORITY = 'cpan:MELO'; # AUTHORITY

our @EXPORT_OK = qw( modhex2hex modhex2dec hex2modhex dec2modhex );

sub modhex2hex {
  my $m = $_[0];

  $m =~ tr/cbdefghijklnrtuv/0123456789abcdef/;

  return $m;
}

sub modhex2dec {
  return hex(modhex2hex(@_));
}

sub hex2modhex {
  my $m = $_[0];

  $m =~ tr/0123456789abcdef/cbdefghijklnrtuv/;
  $m = "c$m" if length($m) % 2;

  return $m;
}

sub dec2modhex {
  return hex2modhex(sprintf('%x', shift));
}

1;



=pod

=for :stopwords Pedro Melo ACKNOWLEDGEMENTS cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders

=encoding utf-8

=head1 NAME

Convert::ModHex - Conversion utilities between Yubico ModHex and hexa/decimal

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Convert::ModHex qw( modhex2hex modhex2dec hex2modhex dec2modhex );
    
    my $modhex = 'ccbc';
    my $hex = modhex2hex($modhex);
    my $dec = modhex2dec($modhex);
    
    $modhex = hex2modhex($hex);
    $modhex = dec2modhex($dec);

=head1 DESCRIPTION

This module provides utility functions that you can use to convert between
L<ModHex encoding|http://www.yubico.com/modhex-calculator> (as used by the
L<Yubikey tokens|http://www.yubico.com/yubikey>).

=encoding utf8

=head1 FUNCTIONS

=head2 modhex2hex

Accepts a ModHex-encoded scalar, returns a hexadecimal-encoded scalar.

=head2 modhex2dec

Accepts a ModHex-encoded scalar, returns a numeric scalar.

=head2 hex2modhex

Accepts a hexadecimal scalar and returns the ModHex-encoded scalar.

=head2 dec2modhex

Accepts a numeric scalar and returns the ModHex-encoded scalar.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Convert::ModHex

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Convert-ModHex>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

L<http://matrix.cpantesters.org/?dist=Convert-ModHex>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Convert::ModHex>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Convert-ModHex>

=back

=head2 Email

You can email the author of this module at C<MELO at cpan.org> asking for help with any problems you have.

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-convert-modhex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Convert-ModHex>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/melo/Convert-ModHex>

  git clone https://github.com/melo/Convert-ModHex.git

=head1 AUTHOR

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

