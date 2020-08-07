package Alien::Sodium;

use strict;
use warnings;
use utf8;
use parent 'Alien::Base';

our $VERSION = '2.000';

1;

__END__

=encoding utf8

=head1 NAME

Alien::Sodium - Interface to the libsodium library L<http://libsodium.org>

=head1 SYNOPSIS

    use strict;
    use warnings;

    use ExtUtils::MakeMaker;
    use Config;
    use Alien::Base::Wrapper ();

    WriteMakefile(
      Alien::Base::Wrapper->new('Alien::Sodium')->mm_args2(
        ...
        CONFIGURE_REQUIRES => {
          'Alien::Sodium' => '2.000',
        },
        ...
      ),
    );

=head1 DESCRIPTION

This package can be used by other L<CPAN|https://metacpan.org> modules that
require L<libsodium|http://libsodium.org>.

=head1 SEE ALSO

=over 4

=item * L<libsodium|http://libsodium.org>

=back

=head1 AUTHOR

Alex J. G. Burzyński <F<ajgb@cpan.org>>

=head1 CONTRIBUTORS

Graham Ollis <F<plicease@cpan.org>>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2015 Alex J. G. Burzyński. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
