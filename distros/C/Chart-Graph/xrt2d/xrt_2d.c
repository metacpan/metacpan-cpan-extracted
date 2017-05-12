#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <Xm/Form.h>
#include <Xm/RowColumn.h>
#include <Xm/ToggleB.h>
#include <Xm/Separator.h>
#include <Xm/XrtGraph.h>
#include "xrt_2d.h"

static char *fallback_resources[] = {
    "*xrtType: TYPEBAR",
    "*xrtXAnnotationMethod: ANNOPOINTLABELS",
    NULL,
};

#define ERROR()		do { result = 0; goto cleanup; } while (0)

static void dump_output(const char * dump_file, Widget graph)
{
    FILE *fp;
	
    fp = fopen(dump_file, "w");
    if (fp) {
	if (strstr(dump_file, ".ps")) {
	    XrtDrawPS(graph, fp, NULL, True, 8.5, 11.0, 0.25, True, 0, 0, 0,
		0, NULL, 0, NULL, 0, NULL, 0, NULL, 0, True,
		XRT_PS_COLOR_AUTO, True);
	} else {
	    if (!strstr(dump_file, ".xwd")) {
		puts("Warning, unknown file extension, outputting XWD format.");
	    }
	    XrtOutputXwd(graph, fp, NULL);
	}
	fclose(fp);
    }
}

int graph_xrt_bar(const struct xrt_bar_info* config)
{
    XrtDataHandle *grid = NULL;
    Widget top = NULL;
    XtAppContext app;
    Widget graph = NULL;
    int result = 0;
    int set, point, label;
    XrtTextHandle text_obj;
    char *text_strings[2];

    grid = XrtDataCreate(XRT_DATA_ARRAY, config->set_cnt, config->pnt_cnt);

    if (!grid) ERROR();

    for (point = 0; point < config->pnt_cnt; point++) {
	if (config->points_numeric) {
	    XrtDataSetXElement(grid, 0, point, atof(config->pnt_labels[point]));
	}
	for (set = 0; set < config->set_cnt; set++) {
	    /* The ordering of the array is backwards for ease of text
	     * parsing. */
            XrtDataSetYElement(grid, set, point, (config->data)[set][point]);
        }
    }

    /* create top level widget */
    top = XtVaAppInitialize(&app, "Simple", NULL, 0,
			    &config->argc, config->argv, fallback_resources,
			    NULL);

    if (!top) ERROR();

    graph = XtVaCreateManagedWidget("graph",
				xtXrtGraphWidgetClass,	top,
				XtNxrtData,		grid,
                                XtNxrtHeaderStrings,    config->header,
                                XtNxrtFooterStrings,    config->footer,
                                XtNxrtPointLabels,      config->pnt_labels,
                                XtNxrtSetLabels,        config->set_labels,
                                XtNxrtXTitle,		config->x_title,
				XtNxrtYTitle,		config->y_title,
				XtNxrtYTitleRotation,	XRT_ROTATE_90,
                                XmNwidth,               640,
                                XmNheight,              480,

                                NULL);

    for (label = 0; config->misc_labels[label]; label++) {
	text_strings[0] = config->misc_labels[label]->label;
	text_strings[1] = NULL;
	text_obj = XrtTextAreaCreate(graph);
	XrtTextAreaSetValues(text_obj,
		    XRT_TEXT_ATTACH_TYPE, XRT_TEXT_ATTACH_DATA,
		    XRT_TEXT_ATTACH_SET, config->misc_labels[label]->set,
		    XRT_TEXT_ATTACH_POINT, config->misc_labels[label]->point,
		    XRT_TEXT_STRINGS, text_strings,
		    XRT_TEXT_IS_CONNECTED, FALSE,
		    NULL);
    }

    if (!graph) ERROR();
    

    /* Throw everything up, don't map the window for batch mode. */
    if (config->filename) {
	XtVaSetValues(top, XtNmappedWhenManaged, FALSE, NULL);
    }
    XtRealizeWidget(top);

    /* either write the file or enter into interactive command loop. */
    if (config->filename) {
	dump_output(config->filename, graph);
    } else {
	XtAppMainLoop(app);
    }


    result = 1;

 cleanup:
    if (grid) {
	/* unalloc grid */
    }

    if (top) {
    }

    if (graph) {
    }
    
    
    return result;
}

#undef ERROR
