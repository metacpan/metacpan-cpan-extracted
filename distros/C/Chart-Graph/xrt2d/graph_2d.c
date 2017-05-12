#include "xrt_2d.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#define GRABLINE(LINE,SIZE) { \
    fgets(LINE,SIZE,stdin); \
    line_len = strlen(LINE); \
    if (LINE[line_len-1] == '\n') { \
	LINE[line_len-1] = '\0'; \
    } \
    while (LINE[0] == '#') { \
	fgets(LINE,SIZE,stdin); \
	line_len = strlen(LINE); \
	if (LINE[line_len-1] == '\n') { \
	    LINE[line_len-1] = '\0'; \
	} \
    } \
}

int main(int argc, char ** argv)
{
    int i,j;
    int line_len;
    struct xrt_bar_info graph_cfg;
    int line_size = 1000; /* XXX Hardcoded limits, yuck */
    int num_labels;
    char * label_chunk;
    char * row_chunk;
    int num_headers, num_footers;
    char * text_line = malloc(line_size * sizeof(char));

    graph_cfg.argc = argc;
    graph_cfg.argv = argv;
    GRABLINE(text_line, line_size);
    graph_cfg.filename = strdup(text_line);
    GRABLINE(text_line, line_size);
    graph_cfg.points_numeric = atoi(text_line);
    GRABLINE(text_line, line_size);
    graph_cfg.pnt_cnt = atoi(text_line);
    GRABLINE(text_line, line_size);
    graph_cfg.set_cnt = atoi(text_line);

    graph_cfg.set_labels = malloc((graph_cfg.set_cnt+1) * sizeof(char*));
    for (i =0; i < graph_cfg.set_cnt; i++) {
        GRABLINE(text_line, line_size);
        graph_cfg.set_labels[i] = strdup(text_line);
    }
    graph_cfg.set_labels[i] = NULL;

    graph_cfg.pnt_labels = malloc((graph_cfg.pnt_cnt+1) * sizeof(char*));
    for (i =0; i < graph_cfg.pnt_cnt; i++) {
        GRABLINE(text_line, line_size);
        graph_cfg.pnt_labels[i] = strdup(text_line);
    }
    graph_cfg.pnt_labels[i] = NULL;

    graph_cfg.data = malloc(graph_cfg.set_cnt * sizeof(double*));

    free(text_line);
    line_size = graph_cfg.pnt_cnt * 30; /* Make sure to have enough room.  */
    text_line = malloc(line_size * sizeof(char));

    for (i = 0; i < graph_cfg.set_cnt; i++) {
        graph_cfg.data[i] = malloc(graph_cfg.pnt_cnt * sizeof(double));
        GRABLINE(text_line, line_size);
	j = 0;
	row_chunk = strtok(text_line, "\t");
	while (row_chunk) {
	    if (j >= graph_cfg.pnt_cnt) {
		break;
	    }
	    graph_cfg.data[i][j++] = atof(row_chunk);
	    row_chunk = strtok(NULL, "\t");
	}
    }

    free(text_line);
    line_size = 1000; /* XXX Hardcoded limits, yuck */
    text_line = malloc(line_size * sizeof(char));

    GRABLINE(text_line, line_size);
    num_headers = atoi(text_line);
    graph_cfg.header = malloc((num_headers+1) * sizeof(char*));
    for (i = 0; i < num_headers; i++) {
        GRABLINE(text_line, line_size);
        graph_cfg.header[i] = strdup(text_line);
    }
    graph_cfg.header[i] = NULL;

    GRABLINE(text_line, line_size);
    num_footers = atoi(text_line);
    graph_cfg.footer = malloc((num_footers+1) * sizeof(char*));
    for (i = 0; i < num_footers; i++) {
        GRABLINE(text_line, line_size);
        graph_cfg.footer[i] = strdup(text_line);
    }
    graph_cfg.footer[i] = NULL;

    GRABLINE(text_line, line_size);
    graph_cfg.x_title = strdup(text_line);
    GRABLINE(text_line, line_size);
    graph_cfg.y_title = strdup(text_line);

    GRABLINE(text_line, line_size);
    num_labels = atoi(text_line);
    graph_cfg.misc_labels = malloc(num_labels * sizeof(label_info*));
    for (i = 0; i < num_labels; i++) {
        GRABLINE(text_line, line_size);
	graph_cfg.misc_labels[i] = malloc(sizeof(label_info));
	label_chunk = strtok(text_line, "\t");
        graph_cfg.misc_labels[i]->label = strdup(label_chunk);
	label_chunk = strtok(NULL, "\t");
	graph_cfg.misc_labels[i]->point = atoi(label_chunk);
	label_chunk = strtok(NULL, "\t");
	graph_cfg.misc_labels[i]->set = atoi(label_chunk);
    }
    graph_cfg.misc_labels[i] = NULL;

    graph_xrt_bar(&graph_cfg);
    free(text_line);

    return 0;
}
