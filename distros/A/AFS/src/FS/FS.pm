package AFS::FS;
#------------------------------------------------------------------------------
# RCS-Id: "@(#)$RCS-Id: src/FS/FS.pm 7a64d4d Wed May 1 22:05:49 2013 +0200 Norbert E Gruener$"
#
# © 2001-2010 Norbert E. Gruener <nog@MPA-Garching.MPG.de>
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#------------------------------------------------------------------------------

use AFS;

use vars qw(@ISA $VERSION @EXPORT_OK);

require Exporter;

@EXPORT_OK = qw(
                getquota
                isafs
                lsmount
                mkmount
                rmmount
                setquota
                whereis
               );
@ISA     = qw(Exporter AFS);
$VERSION = 'v2.6.4';

1;
