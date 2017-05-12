#include "champlain-perl.h"


MODULE = Champlain::FileCache  PACKAGE = Champlain::FileCache  PREFIX = champlain_file_cache_


ChamplainFileCache*
champlain_file_cache_new (class)
	C_ARGS: /* no args */


ChamplainFileCache*
champlain_file_cache_new_full (class, guint size_limit, const gchar *cache_dir, gboolean persistent)
	C_ARGS: size_limit, cache_dir, persistent


guint
champlain_file_cache_get_size_limit (ChamplainFileCache *file_cache)


void
champlain_file_cache_set_size_limit (ChamplainFileCache *file_cache, guint size_limit)


const gchar*
champlain_file_cache_get_cache_dir (ChamplainFileCache *file_cache)


void
champlain_file_cache_purge (ChamplainFileCache *file_cache)


void
champlain_file_cache_purge_on_idle (ChamplainFileCache *file_cache)
