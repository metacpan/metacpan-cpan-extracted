package Alien::libuv;

use strict;
use warnings;
use base qw( Alien::Base );

our $VERSION = '1.014';

1;

__END__

=head1 NAME

Alien::libuv - Interface to the libuv library L<http://libuv.org>

=head1 SYNOPSIS

In your C<Makefile.PL>:

    use strict;
    use warnings;

    use ExtUtils::MakeMaker;
    use Config;
    use Alien::Base::Wrapper ();

    WriteMakefile(
      Alien::Base::Wrapper->new('Alien::libuv')->mm_args2(
        ...
        CONFIGURE_REQUIRES => {
          'Alien::libuv' => '1.000',
        },
        ...
      ),
    );

=head1 DESCRIPTION

This package can be used by other L<CPAN|https://metacpan.org> modules that
require L<libuv|http://libuv.org>.

=head1 AUTHOR

Chase Whitener <F<capoeirab@cpan.org>>

=head1 CONTRIBUTORS

Graham Ollis <F<plicease@cpan.org>>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2017 Chase Whitener. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
