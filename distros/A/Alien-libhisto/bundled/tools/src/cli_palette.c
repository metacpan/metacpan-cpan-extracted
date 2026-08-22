/*
 * Color palette mapping routines for terminal ANSI 256 and truecolor output.
 */

#include "cli_palette.h"
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <math.h>

typedef struct {
    double r, g, b;
} rgb_point_t;

/* --- Accurate Multi-Point Colormap Node Tables --- */

static const rgb_point_t PALETTE_VIRIDIS_NODES[] = {
    { 68.0,   1.0,  84.0},
    { 72.0,  35.0, 116.0},
    { 64.0,  67.0, 135.0},
    { 52.0,  94.0, 141.0},
    { 41.0, 120.0, 142.0},
    { 32.0, 144.0, 140.0},
    { 34.0, 168.0, 132.0},
    { 68.0, 190.0, 112.0},
    {121.0, 209.0,  81.0},
    {189.0, 223.0,  38.0},
    {253.0, 231.0,  37.0}
};

static const rgb_point_t PALETTE_PLASMA_NODES[] = {
    { 13.0,   8.0, 135.0},
    { 70.0,   3.0, 159.0},
    {114.0,   1.0, 168.0},
    {156.0,  23.0, 158.0},
    {189.0,  55.0, 134.0},
    {216.0,  87.0, 107.0},
    {237.0, 121.0,  83.0},
    {251.0, 159.0,  58.0},
    {253.0, 202.0,  38.0},
    {240.0, 249.0,  33.0}
};

static const rgb_point_t PALETTE_INFERNO_NODES[] = {
    {  0.0,   0.0,   4.0},
    { 31.0,  12.0,  72.0},
    { 85.0,  15.0, 109.0},
    {136.0,  34.0, 106.0},
    {186.0,  54.0,  85.0},
    {227.0,  89.0,  51.0},
    {249.0, 140.0,  10.0},
    {252.0, 197.0,  46.0},
    {245.0, 246.0, 109.0},
    {252.0, 255.0, 164.0}
};

static const rgb_point_t PALETTE_MAGMA_NODES[] = {
    {  0.0,   0.0,   4.0},
    { 28.0,  16.0,  68.0},
    { 79.0,  18.0, 123.0},
    {129.0,  37.0, 129.0},
    {181.0,  54.0, 122.0},
    {227.0,  89.0, 106.0},
    {251.0, 136.0,  97.0},
    {254.0, 189.0, 130.0},
    {252.0, 233.0, 178.0},
    {251.0, 252.0, 191.0}
};

static const rgb_point_t PALETTE_TURBO_NODES[] = {
    { 48.0,  18.0,  59.0},
    { 70.0, 134.0, 251.0},
    { 27.0, 208.0, 213.0},
    { 99.0, 247.0,  97.0},
    {196.0, 240.0,  43.0},
    {253.0, 175.0,  39.0},
    {243.0,  89.0,  27.0},
    {194.0,  36.0,  11.0},
    {122.0,   4.0,   3.0}
};

static const rgb_point_t PALETTE_CIVIDIS_NODES[] = {
    {  0.0,  32.0,  77.0},
    { 28.0,  54.0, 101.0},
    { 63.0,  75.0, 114.0},
    {100.0,  96.0, 121.0},
    {138.0, 119.0, 124.0},
    {178.0, 145.0, 121.0},
    {217.0, 175.0, 107.0},
    {245.0, 210.0,  83.0},
    {255.0, 234.0,  70.0}
};

static const rgb_point_t PALETTE_RAINBOW_NODES[] = {
    {  0.0,   0.0, 255.0}, /* Blue */
    {  0.0, 255.0, 255.0}, /* Cyan */
    {  0.0, 255.0,   0.0}, /* Green */
    {255.0, 255.0,   0.0}, /* Yellow */
    {255.0,   0.0,   0.0}  /* Red */
};

static void interpolate_nodes(const rgb_point_t *nodes, size_t count, double t, int *r, int *g, int *b) {
    if (count == 0) {
        *r = *g = *b = 0;
        return;
    }
    if (count == 1 || t <= 0.0) {
        *r = (int)nodes[0].r;
        *g = (int)nodes[0].g;
        *b = (int)nodes[0].b;
        return;
    }
    if (t >= 1.0) {
        *r = (int)nodes[count - 1].r;
        *g = (int)nodes[count - 1].g;
        *b = (int)nodes[count - 1].b;
        return;
    }

    double pos = t * (double)(count - 1);
    size_t i0 = (size_t)pos;
    size_t i1 = i0 + 1;
    if (i1 >= count) i1 = count - 1;
    double frac = pos - (double)i0;

    *r = (int)(nodes[i0].r * (1.0 - frac) + nodes[i1].r * frac + 0.5);
    *g = (int)(nodes[i0].g * (1.0 - frac) + nodes[i1].g * frac + 0.5);
    *b = (int)(nodes[i0].b * (1.0 - frac) + nodes[i1].b * frac + 0.5);

    if (*r < 0) *r = 0; else if (*r > 255) *r = 255;
    if (*g < 0) *g = 0; else if (*g > 255) *g = 255;
    if (*b < 0) *b = 0; else if (*b > 255) *b = 255;
}

histo_palette_t histo_palette_from_name(const char *name) {
    if (!name || !*name) return HISTO_PALETTE_VIRIDIS;

    if (strcasecmp(name, "viridis") == 0) return HISTO_PALETTE_VIRIDIS;
    if (strcasecmp(name, "plasma") == 0) return HISTO_PALETTE_PLASMA;
    if (strcasecmp(name, "inferno") == 0) return HISTO_PALETTE_INFERNO;
    if (strcasecmp(name, "magma") == 0) return HISTO_PALETTE_MAGMA;
    if (strcasecmp(name, "turbo") == 0) return HISTO_PALETTE_TURBO;
    if (strcasecmp(name, "cividis") == 0) return HISTO_PALETTE_CIVIDIS;
    if (strcasecmp(name, "grayscale") == 0 || strcasecmp(name, "gray") == 0 || strcasecmp(name, "grey") == 0 || strcasecmp(name, "mono") == 0) return HISTO_PALETTE_GRAYSCALE;
    if (strcasecmp(name, "rainbow") == 0 || strcasecmp(name, "spectral") == 0) return HISTO_PALETTE_RAINBOW;

    return HISTO_PALETTE_VIRIDIS;
}

const char *histo_palette_name(histo_palette_t pal) {
    switch (pal) {
        case HISTO_PALETTE_VIRIDIS:   return "viridis";
        case HISTO_PALETTE_PLASMA:    return "plasma";
        case HISTO_PALETTE_INFERNO:   return "inferno";
        case HISTO_PALETTE_MAGMA:     return "magma";
        case HISTO_PALETTE_TURBO:     return "turbo";
        case HISTO_PALETTE_CIVIDIS:   return "cividis";
        case HISTO_PALETTE_GRAYSCALE: return "grayscale";
        case HISTO_PALETTE_RAINBOW:   return "rainbow";
        default:                      return "viridis";
    }
}

void histo_palette_sample_rgb(histo_palette_t pal, double fraction, int *out_r, int *out_g, int *out_b) {
    if (!out_r || !out_g || !out_b) return;

    if (fraction < 0.0) fraction = 0.0;
    else if (fraction > 1.0) fraction = 1.0;

    switch (pal) {
        case HISTO_PALETTE_VIRIDIS:
            interpolate_nodes(PALETTE_VIRIDIS_NODES, sizeof(PALETTE_VIRIDIS_NODES) / sizeof(PALETTE_VIRIDIS_NODES[0]), fraction, out_r, out_g, out_b);
            break;
        case HISTO_PALETTE_PLASMA:
            interpolate_nodes(PALETTE_PLASMA_NODES, sizeof(PALETTE_PLASMA_NODES) / sizeof(PALETTE_PLASMA_NODES[0]), fraction, out_r, out_g, out_b);
            break;
        case HISTO_PALETTE_INFERNO:
            interpolate_nodes(PALETTE_INFERNO_NODES, sizeof(PALETTE_INFERNO_NODES) / sizeof(PALETTE_INFERNO_NODES[0]), fraction, out_r, out_g, out_b);
            break;
        case HISTO_PALETTE_MAGMA:
            interpolate_nodes(PALETTE_MAGMA_NODES, sizeof(PALETTE_MAGMA_NODES) / sizeof(PALETTE_MAGMA_NODES[0]), fraction, out_r, out_g, out_b);
            break;
        case HISTO_PALETTE_TURBO:
            interpolate_nodes(PALETTE_TURBO_NODES, sizeof(PALETTE_TURBO_NODES) / sizeof(PALETTE_TURBO_NODES[0]), fraction, out_r, out_g, out_b);
            break;
        case HISTO_PALETTE_CIVIDIS:
            interpolate_nodes(PALETTE_CIVIDIS_NODES, sizeof(PALETTE_CIVIDIS_NODES) / sizeof(PALETTE_CIVIDIS_NODES[0]), fraction, out_r, out_g, out_b);
            break;
        case HISTO_PALETTE_GRAYSCALE: {
            int v = (int)(fraction * 255.0 + 0.5);
            if (v < 0) v = 0; else if (v > 255) v = 255;
            *out_r = *out_g = *out_b = v;
            break;
        }
        case HISTO_PALETTE_RAINBOW:
            interpolate_nodes(PALETTE_RAINBOW_NODES, sizeof(PALETTE_RAINBOW_NODES) / sizeof(PALETTE_RAINBOW_NODES[0]), fraction, out_r, out_g, out_b);
            break;
        default:
            interpolate_nodes(PALETTE_VIRIDIS_NODES, sizeof(PALETTE_VIRIDIS_NODES) / sizeof(PALETTE_VIRIDIS_NODES[0]), fraction, out_r, out_g, out_b);
            break;
    }
}

void histo_palette_sample_ansi_fg(histo_palette_t pal, double fraction, char *buf, size_t max_len) {
    if (!buf || max_len == 0) return;
    int r = 0, g = 0, b = 0;
    histo_palette_sample_rgb(pal, fraction, &r, &g, &b);
    snprintf(buf, max_len, "\033[38;2;%d;%d;%dm", r, g, b);
}

void histo_palette_sample_ansi_bg(histo_palette_t pal, double fraction, char *buf, size_t max_len) {
    if (!buf || max_len == 0) return;
    int r = 0, g = 0, b = 0;
    histo_palette_sample_rgb(pal, fraction, &r, &g, &b);
    snprintf(buf, max_len, "\033[48;2;%d;%d;%dm", r, g, b);
}
