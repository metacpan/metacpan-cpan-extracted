#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "markdown.h"
#include "html.h"
#include "buffer.h"

#define OUTPUT_UNIT	1024

MODULE = DR::SunDown PACKAGE = DR::SunDown
PROTOTYPES: ENABLE

SV * markdown2html(mdata)
    SV * mdata

    PREINIT:
	struct buf *ob;
	STRLEN len;
	const char * ptr;
	struct sd_callbacks callbacks;
	struct html_renderopt options;
	struct sd_markdown *markdown;
	int input_is_utf8;


    CODE:
	if (!SvOK(mdata)) {
		RETVAL = mdata;
		return;
	}

	input_is_utf8 = SvUTF8(mdata);

	ptr = SvPV(mdata, len);
	ob = bufnew(OUTPUT_UNIT);

	sdhtml_renderer(&callbacks, &options, 0);
	markdown = sd_markdown_new(0, 16, &callbacks, &options);
	sd_markdown_render(ob, (uint8_t *)ptr, len, markdown);
	sd_markdown_free(markdown);

	if (!ob->size) {
		RETVAL = newSVpvn("", 0);
	} else {
                RETVAL = newSVpvn((char *)ob->data, ob->size);
                if ( input_is_utf8 && !SvUTF8(RETVAL) )
                    SvUTF8_on(RETVAL);
	}
	bufrelease(ob);

    OUTPUT:
        RETVAL


