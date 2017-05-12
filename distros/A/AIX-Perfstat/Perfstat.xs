/* Copyright (C) 2006 by Richard Holden

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

*/ 

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "ppport.h"

MODULE = AIX::Perfstat		PACKAGE = AIX::Perfstat

PROTOTYPES: ENABLE

INCLUDE: cpu/cpu_xs

INCLUDE: memory/memory_xs

INCLUDE: netinterface/netinterface_xs

INCLUDE: disk/disk_xs
