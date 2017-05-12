#ifndef XRT_2D_H
#define XRT_2D_H

typedef struct label_info {
    char *label;
    int set, point; /* Data set position of the label */
} label_info;

typedef struct xrt_bar_info {
    char *filename;
    int argc;
    char **argv;
    int pnt_cnt;
    int set_cnt;
    double **data;
    char **header;
    char **footer;
    char *x_title;
    char *y_title;
    char **pnt_labels;
    char **set_labels;
    struct label_info **misc_labels;
    int points_numeric;
} xrt_bar_info;

int graph_xrt_bar(const struct xrt_bar_info* config);

#endif
