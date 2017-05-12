/*
 * Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for
 * the full list)
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at your
 * option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307  USA.
 *
 * $Id: Glib.xs 1077 2009-02-05 14:39:12Z tsch $
 */

#include "pgopogl.h"

=head2 Miscellaneous

Various useful utilities defined in PGOpogl.xs.

=over

=item PGOPOGL_CALL_BOOT(name)

call the boot code of a module by symbol rather than by name.

in a perl extension which uses several xs files but only one pm, you
need to bootstrap the other xs files in order to get their functions
exported to perl.  if the file has MODULE = Foo::Bar, the boot symbol
would be boot_Foo__Bar.

=item void _pgopogl_call_XS (pTHX_ void (*subaddr) (pTHX_ CV *), CV * cv, SV ** mark);

never use this function directly.  see C<PGOPOGLL_CALL_BOOT>.

for the curious, this calls a perl sub by function pointer rather than
by name; call_sv requires that the xsub already be registered, but we
need this to call a function which will register xsubs.  this is an
evil hack and should not be used outside of the PGOPOGL_CALL_BOOT macro.
it's implemented as a function to avoid code size bloat, and exported
so that extension modules can pull the same trick.

=cut
void
_pgopogl_call_XS (pTHX_ void (*subaddr) (pTHX_ CV *), CV * cv, SV ** mark)
{
	dSP;
	PUSHMARK (mark);
	(*subaddr) (aTHX_ cv);
	PUTBACK;	/* forget return values */
}
