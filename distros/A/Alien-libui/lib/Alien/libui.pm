package Alien::libui 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use base qw[Alien::Base];
}
1;
__END__

=encoding utf-8

=head1 NAME

Alien::libui - Build and Install libui: A portable GUI library

=head1 SYNOPSIS

    use Alien::libui;

=head1 DESCRIPTION

libui is a simple and portable (but not inflexible) GUI library in C that uses
the native GUI technologies of each platform it supports.

=head1 Runtime Requirements

The library is built with C<meson> and C<ninja> both of which may, in turn, be
provided by Aliens.

In addition to those, platform requirements include:

=over

=item Windows - Windows Vista SP2 with Platform Update or newer

=item *nix - GTK+ 3.10 or newer (you must install this according to your platform)

=item OS X - OS X 10.8 or newer

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

libui

=end stopwords

=cut

