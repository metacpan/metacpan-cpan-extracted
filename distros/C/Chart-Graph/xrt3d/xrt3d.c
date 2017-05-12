#include <stdio.h>
#include <string.h>
#include <math.h>
#include <Xm/Form.h>
#include <Xm/RowColumn.h>
#include <Xm/ToggleB.h>
#include <Xm/Separator.h>
#include <Xm/Xrt3d.h>
#include "xrt3d.h"

static char *fallback_resources[] = {
    "*xrt3dDrawMesh:		true",
    "*xrt3dDrawShaded:		true",
    "*xrt3dDrawContours:	true",
    "*xrt3dDrawZones:		true",
    "*xrt3dDrawHiddenLines:	false",
    "*xrt3dType:		Bar",
#if 0
    "*xrt3dPerspectiveDepth:	1E300",
#endif
    NULL,
};

#define ERROR()		do { result = 0; goto cleanup; } while (0)

static void dump_output(const char * dump_file, Widget graph)
{
    FILE *fp;
	
    fp = fopen(dump_file, "w");
    if (fp) {
	if (strstr(dump_file, ".ps")) {
	    Xrt3dDrawPS(graph, fp, NULL, True, 8.5, 11.0, 0.25, False, 0, 0, 0,
		0, NULL, NULL, NULL, True, XRT3D_PS_COLOR_AUTO, True);
	} else {
	    if (!strstr(dump_file, ".xwd")) {
		puts("Warning, unknown file extension, outputting XWD format.");
	    }
	    Xrt3dOutputXwd(graph, fp, NULL);
	}
	fclose(fp);
    }
}

int graph_xrt3d(const struct xrt3d_info* config)
{
    Xrt3dData *grid = NULL;
    Widget top = NULL;
    XtAppContext app;
    Widget graph = NULL;
    int result = 0;
    int i, j;

    grid = Xrt3dMakeGridData(config->x_cnt, config->y_cnt, XRT3D_HUGE_VAL,
			     config->x_step, config->y_step, config->x_min,
			     config->y_min, TRUE);

    if (!grid) ERROR();

    for (i = 0; i < config->x_cnt; i++) {
	for (j = 0; j < config->y_cnt; j++) {
	    grid->g.values[i][j] = (config->data)[i][j];
	}
    }

    /* create top level widget */
    top = XtVaAppInitialize(&app, "Simple", NULL, 0,
			    &config->argc, config->argv, fallback_resources,
			    NULL);

    if (!top) ERROR();

    graph = XtVaCreateManagedWidget("graph",
				    xtXrt3dWidgetClass,		top,
#if 0
				    XmNtopAttachment,		XmATTACH_WIDGET,
				    XmNtopWidget,		sep,
				    XmNbottomAttachment,	XmATTACH_FORM,
				    XmNleftAttachment,		XmATTACH_FORM,
				    XmNrightAttachment,		XmATTACH_FORM,
#else
				    XmNwidth,			650,
				    XmNheight,			650,
#endif

				    XtNxrt3dSurfaceData,	grid,

				    XtNxrt3dAxisTitleStrokeFont,    XRT3D_SF_ROMAN_SIMPLEX,
				    XtNxrt3dAxisTitleStrokeSize,    80,
				    XtNxrt3dXAxisTitle,		config->x_title,
				    XtNxrt3dYAxisTitle,		config->y_title,
				    XtNxrt3dZAxisTitle,		config->z_title,

				    XtNxrt3dXAnnoMethod,	XRT3D_ANNO_DATA_LABELS,
				    XtNxrt3dYAnnoMethod,	XRT3D_ANNO_DATA_LABELS,
				    XtNxrt3dAxisStrokeFont,	XRT3D_SF_ROMAN_SIMPLEX,
				    XtNxrt3dAxisStrokeSize,	50,
				    XtNxrt3dXDataLabels,	config->x_labels,
				    XtNxrt3dYDataLabels,	config->y_labels,

				    XtNxrt3dHeaderBorder,	XRT3D_BORDER_PLAIN,
				    XtNxrt3dHeaderStrings,	config->header,
				    XtNxrt3dFooterStrings,	config->footer,

				    NULL);

    if (!graph) ERROR();
    

    /* Throw everything up, don't map the window for batch mode. */
    if (config->filename) {
	XtVaSetValues(top, XtNmappedWhenManaged, FALSE, NULL);
    }
//    CreateWidgets(top);
    XtRealizeWidget(top);

    /* either write the file or enter into interactive command loop. */
    if (config->filename) {
	dump_output(config->filename, graph);
    } else {
//	XtAppMainLoop(app);
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
