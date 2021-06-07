package Alien::libsdl2;
use strict;
use warnings;
use base qw[Alien::Base];
our $VERSION = '1.02';

1;
__END__

=encoding utf8

=head1 NAME

Alien::libsdl2 - Find or download and install libsdl2

=head1 SYNOPSIS

    use strict;
    use warnings;
    use ExtUtils::MakeMaker;
    use Config;
    use Alien::Base::Wrapper ();
    WriteMakefile(
      Alien::Base::Wrapper->new('Alien::libsdl2')->mm_args2(
        ...
        CONFIGURE_REQUIRES => {
          'Alien::libsdl2' => '0'
        },
        ...
      ),
    );

=head1 DESCRIPTION

This package can be used by other L<CPAN|https://metacpan.org> modules that
require L<libsdl2|http://libsdl.org>.

=head1 SEE ALSO

=over

=item L<libsdl2|http://libsdl.com>

=item L<Alien::SDL2> - Ancient Alien for SDL2 (builds w/ SDL2-2.0.0 from 2013)

=back

=head1 Platform Support

This dist has been tested on various modern versions of perl on Windows Server
2019, Ubuntu (20.04.2), and OSX (10.15.7). See
https://github.com/sanko/Alien-libsdl2/actions

On OSX and *nix, libsdl2 is built from source.

On Windows, prebuilt shared libraries are downloaded from libsdl.org and
installed.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
