#ifndef XRT3D_H
#define XRT3D_H

struct xrt3d_info {
    char *filename;
    int argc;
    char **argv;
    int x_min;
    int y_min;
    int x_step;
    int y_step;
    int x_cnt;
    int y_cnt;
    double **data;
    char **header;
    char **footer;
    char *x_title;
    char *y_title;
    char *z_title;
    char **x_labels;
    char **y_labels;
};

int graph_xrt3d(const struct xrt3d_info* config);

#endif
