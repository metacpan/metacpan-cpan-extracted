#include "champlain-perl.h"


MODULE = Champlain::MapSourceChain  PACKAGE = Champlain::MapSourceChain  PREFIX = champlain_map_source_chain_


ChamplainMapSourceChain*
champlain_map_source_chain_new (class);
	C_ARGS: /* no args */


void
champlain_map_source_chain_push (ChamplainMapSourceChain *source_chain, ChamplainMapSource *map_source)


void
champlain_map_source_chain_pop (ChamplainMapSourceChain *source_chain)
