#include "champlain-perl.h"


MODULE = Champlain::Tile  PACKAGE = Champlain::Tile  PREFIX = champlain_tile_


ChamplainTile*
champlain_tile_new (class)
	C_ARGS: /* No args */


ChamplainTile*
champlain_tile_new_full (class, gint x, gint y, guint size, gint zoom_level)
	C_ARGS: x, y, size, zoom_level


gint
champlain_tile_get_x (ChamplainTile *self)


gint
champlain_tile_get_y (ChamplainTile *self)


gint
champlain_tile_get_zoom_level (ChamplainTile *self)


guint
champlain_tile_get_size (ChamplainTile *self)


ChamplainState
champlain_tile_get_state (ChamplainTile *self)


void
champlain_tile_set_x (ChamplainTile *self, gint x)


void
champlain_tile_set_y (ChamplainTile *self, gint y)


void
champlain_tile_set_zoom_level (ChamplainTile *self, gint zoom_level)


void
champlain_tile_set_size (ChamplainTile *self, guint size)


void
champlain_tile_set_state (ChamplainTile *self, ChamplainState state)


ClutterActor *
champlain_tile_get_content (ChamplainTile *self)


const gchar*
champlain_tile_get_etag (ChamplainTile *self)


void
champlain_tile_get_modified_time (ChamplainTile *self)
	PREINIT:
		const GTimeVal *modified_time = NULL;

	PPCODE:
		modified_time = champlain_tile_get_modified_time(self);

		if (modified_time) {
			EXTEND(SP, 2);
			PUSHs(sv_2mortal(newSViv(modified_time->tv_sec)));
			PUSHs(sv_2mortal(newSViv(modified_time->tv_usec)));
		}
		else {
			EXTEND(SP, 2);
			PUSHs(sv_2mortal(&PL_sv_undef));
			PUSHs(sv_2mortal(&PL_sv_undef));
		}


void
champlain_tile_set_content (ChamplainTile *self, ClutterActor* actor)


void
champlain_tile_set_etag (ChamplainTile *self, const gchar *etag)


void
champlain_tile_set_modified_time (ChamplainTile *self, ...)
	PREINIT:
		GTimeVal modified_time = {0, };

	CODE:

		if (items == 1) {
			/* Use the current time */
			g_get_current_time(&modified_time);
		}
		else if (items == 3) {
			SV *sv_seconds = ST(1);
			SV *sv_microseconds = ST(2);

			if (! (sv_seconds && SvOK(sv_seconds))) {
				croak("$tile->set_modified_time() called with invalid seconds");
			}

			if (! (sv_microseconds && SvOK(sv_microseconds))) {
				croak("$tile->set_modified_time() called with invalid microseconds");
			}

			modified_time.tv_sec = SvIV(sv_seconds);
			modified_time.tv_usec = SvIV(sv_microseconds);
		}
		else {
			croak("Usage: $tile->set_modified_time() or $tile->set_modified_time($seconds, $microseconds)");
		}

		champlain_tile_set_modified_time(self, &modified_time);


void
champlain_tile_set_fade_in (ChamplainTile *self, gboolean fade_in)


gboolean
champlain_tile_get_fade_in (ChamplainTile *self)
