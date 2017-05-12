#include "champlain-perl.h"


MODULE = Champlain::MapSourceDesc  PACKAGE = Champlain::MapSourceDesc  PREFIX = champlain_map_source_desc_


ChamplainMapSourceDesc*
champlain_map_source_desc_new (class)
	C_ARGS: /* No args */


ChamplainMapSourceDesc*
champlain_map_source_desc_copy (const ChamplainMapSourceDesc* desc)


void
champlain_map_source_desc_free (ChamplainMapSourceDesc* desc)


#
# Provide nice accessors and modifiers to the data members of the struct.
#
SV*
id (ChamplainMapSourceDesc *desc, ...)
	ALIAS:
		name = 1
		license = 2
		license_uri = 3
		min_zoom_level = 4
		max_zoom_level = 5
		projection = 6
		constructor = 7
		uri_format = 8

	CODE:
		switch (ix) {
			case 0:
				RETVAL = newSVGChar(desc->id);
				if (items > 1) desc->id = g_strdup(SvGChar(ST(1)));
			break;
			
			case 1:
				RETVAL = newSVGChar(desc->name);
				if (items > 1) desc->name = g_strdup(SvGChar(ST(1)));
			break;
			
			case 2:
				RETVAL = newSVGChar(desc->license);
				if (items > 1) desc->license = g_strdup(SvGChar(ST(1)));
			break;
			
			case 3:
				RETVAL = newSVGChar(desc->license_uri);
				if (items > 1) desc->license_uri = g_strdup(SvGChar(ST(1)));
			break;
			
			case 4:
				RETVAL = newSViv(desc->min_zoom_level);
				if (items > 1) desc->min_zoom_level = (gint)SvIV(ST(1));
			break;
			
			case 5:
				RETVAL = newSViv(desc->max_zoom_level);
				if (items > 1) desc->max_zoom_level = (gint)SvIV(ST(1));
			break;
			
			case 6:
				RETVAL = newSVChamplainMapProjection(desc->projection);
				if (items > 1) desc->projection = SvChamplainMapProjection(ST(1));
			break;
			
			case 7:
				/* This is tricky as we have to wrap the C callback into a Perl sub. */
				if (items == 1) {
					croak("$desc->constructor() isn't implemented yet");
				}
				else {
					croak("$desc->constructor(\\&code_ref) isn't implemented yet");
				}
			break;
			
			case 8:
				RETVAL = newSVGChar(desc->uri_format);
				if (items > 1) desc->uri_format = g_strdup(SvGChar(ST(1)));
			break;
			
			default:
				RETVAL = &PL_sv_undef;
				g_assert_not_reached();
			break;
		}

	OUTPUT:
		RETVAL
