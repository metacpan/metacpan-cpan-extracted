use strict;
use warnings;
package Alien::libvas;

# ABSTRACT: Perl distribution for libvas
our $VERSION = '0.216'; # VERSION

use parent 'Alien::Base';


=pod

=encoding utf8

=head1 NAME

Alien::libvas - Perl distribution for libvas

=head1 VERSION

version 0.216

=head1 INSTALL

    cpan Alien::libvas

=head1 DESCRIPTION

See L<Proc::Memory> for a Perl wrapper that makes use of this distribution.

=head1 PLATFORMS

libvas claims compatiblity with WinAPI's ReadProcessMemory/WriteProcessMeory, macOS/GNU Hurd Mach API, Linux procfs /proc/pid/mem, ptrace (2), and process_vm_readv/process_vm_writev, SunOS procfs /proc/pid/as and finally BSD with ptrace (2) or procfs.

I don't have all these systems to verify this. So please report bugs you might run into, preferably on Github. :-)

=cut


1;
__END__


=head1 GIT REPOSITORY

L<http://github.com/athreef/Alien-libvas>

=head1 SEE ALSO

L<libvas|http://github.com/a3f/libvas>

L<Proc::Memory>

L<Alien>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
