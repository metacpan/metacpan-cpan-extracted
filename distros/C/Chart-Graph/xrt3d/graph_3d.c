#include "xrt3d.h"
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
    struct xrt3d_info graph_cfg;
    int num_headers, num_footers;
    int line_size = 1000; /* XXX Hardcoded limits, yuck */
    char * text_line = malloc((line_size) * sizeof(char));
    char * row_chunk;

    graph_cfg.argc = argc;
    graph_cfg.argv = argv;
    GRABLINE(text_line, line_size);
    graph_cfg.filename = strdup(text_line);
    GRABLINE(text_line, line_size);
    graph_cfg.x_min = atoi(text_line);
    GRABLINE(text_line, line_size);
    graph_cfg.y_min = atoi(text_line);
    GRABLINE(text_line, line_size);
    graph_cfg.x_step = atoi(text_line);
    GRABLINE(text_line, line_size);
    graph_cfg.y_step = atoi(text_line);
    GRABLINE(text_line, line_size);
    graph_cfg.x_cnt = atoi(text_line);
    GRABLINE(text_line, line_size);
    graph_cfg.y_cnt = atoi(text_line);

    free(text_line);
    line_size = graph_cfg.y_cnt * 30; /* Make sure to have enough room.  */
    text_line = malloc(line_size * sizeof(char));

    graph_cfg.data = malloc(graph_cfg.x_cnt * sizeof(double*));

    for (i = 0; i < graph_cfg.x_cnt; i++) {
        graph_cfg.data[i] = malloc(graph_cfg.y_cnt * sizeof(double));
        GRABLINE(text_line, line_size);
	j = 0;
	row_chunk = strtok(text_line, "\t");
	while (row_chunk) {
	    if (j >= graph_cfg.y_cnt) {
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
    graph_cfg.z_title = strdup(text_line);

    graph_cfg.x_labels = malloc((graph_cfg.x_cnt+1) * sizeof(char*));
    for (i = 0; i < graph_cfg.x_cnt; i++) {
        GRABLINE(text_line, line_size);
        graph_cfg.x_labels[i] = strdup(text_line);
    }
    graph_cfg.x_labels[i] = NULL;

    graph_cfg.y_labels = malloc((graph_cfg.y_cnt+1) * sizeof(char*));
    for (i = 0; i < graph_cfg.y_cnt; i++) {
        GRABLINE(text_line, line_size);
        graph_cfg.y_labels[i] = strdup(text_line);
    }
    graph_cfg.y_labels[i] = NULL;

    graph_xrt3d(&graph_cfg);

    return 0;
}
