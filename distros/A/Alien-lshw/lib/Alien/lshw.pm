use strict;
use warnings;
package Alien::lshw;

# ABSTRACT: Perl distribution for lshw
our $VERSION = '0.001'; # VERSION

use parent 'Alien::Base';

=pod

=encoding utf8

=head1 NAME

Alien::lshw - Perl distribution for GNU lshw

=head1 USAGE

    use Alien::lshw;
    use Env qw( @PATH );

    unshift @PATH, Alien::lshw->bin_dir;
    system lshw, '-version';

=head1 DESCRIPTION
    
lshw is a small tool to provide detailed information on the hardware configuration of the machine. It can report exact memory configuration, firmware version, mainboard configuration, CPU version and speed, cache configuration, bus speed, etc. on DMI-capable x86 or EFI (IA-64) systems and on some ARM and PowerPC machines (PowerMac G4 is known to work).

Information can be output in plain text, XML or HTML.

It currently supports DMI (x86 and EFI only), OpenFirmware device tree (PowerPC only), PCI/AGP, ISA PnP (x86), CPUID (x86), IDE/ATA/ATAPI, PCMCIA (only tested on x86), USB and SCSI.

=cut

1;
__END__


=head1 GIT REPOSITORY

L<http://github.com/athreef/Alien-lshw>

=head1 SEE ALSO

L<lshw Project home|http://lshw.ezix.org/>
L<lshw Git repository|https://github.com/lyonel/lshw>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
