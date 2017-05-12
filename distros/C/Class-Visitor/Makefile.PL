#
# Copyright (C) 1997 Ken MacLeod
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Makefile.PL,v 1.2 1997/10/18 16:23:51 ken Exp $
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Class::Visitor',
    'VERSION_FROM' => 'Visitor.pm',
    dist        => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
);
