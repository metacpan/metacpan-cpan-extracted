use strict;
use warnings;
package App::FilterUtils;
# ABSTRACT: Command-line filter utilities
our $VERSION = '0.002'; # VERSION

=pod

=encoding utf8

=head1 NAME

App::FilterUtils - Command-line filter utilities

=head1 SYNOPSIS

    $ 2base 16 16
    10
    $ 2u 👨‍🎓
    MAN <👨>  128104, Hex 1f468, Octal 372150
    ZERO WIDTH JOINER <>  8205, Hex 200d, Octal 20015
    GRADUATION CAP <🎓>  127891, Hex 1f393, Octal 371623

    $ echo "مِــكَــرٍّ مِــفَــرٍّ مُــقْــبِــلٍ مُــدْبِــرٍ مَــعــاً" | artype
    ٍّرــَﻜــِﻣ ٍّرــَﻔــِﻣ ٍﻠــِﺒــْﻘــُﻣ ٍرــِﺒْدــُﻣ ًاــﻌــَﻣ
    $ ascii café
    caf
    $ byte 66062639
    64M
    $ hz 10000
    100us
    $ NFC é | xxd
    00000000: c3a9 0a                                  ...
    $ NFD é | xxd
    00000000: 65cc 810a                                e...
    $ unac café
    cafe
    $ echo "خوخ" | unpt
    حوح
    $ echo "مِــكَــرٍّ مِــفَــرٍّ مُــقْــبِــلٍ مُــدْبِــرٍ مَــعــاً" | untashkeel
    مــكــر مــفــر مــقــبــل مــدبــر مــعــا

=head1 USAGE

All utilities answer to C<--version> and C<--help>. If arguments are provided, they are filtered.
If there are no arguments, C<STDIN> is read.

=head1 UTILITIES

=over

=item L<App::FilterUtils::2base>
=item L<App::FilterUtils::2u>
=item L<App::FilterUtils::artype>
=item L<App::FilterUtils::ascii>
=item L<App::FilterUtils::byte>
=item L<App::FilterUtils::hz>
=item L<App::FilterUtils::NFC>
=item L<App::FilterUtils::NFD>
=item L<App::FilterUtils::unac>
=item L<App::FilterUtils::unpt>
=item L<App::FilterUtils::untashkeel>

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/App-FilterUtils>

=head1 SEE ALSO

Migrated out of my L<.dotfiles repository|http://github.com/a3f/.dotfiles>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

