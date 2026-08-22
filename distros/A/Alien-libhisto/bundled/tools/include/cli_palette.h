/*
 * Color palette definitions, RGB gradients, and terminal escape formatters.
 */

#ifndef HISTO_CLI_PALETTE_H
#define HISTO_CLI_PALETTE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Supported scientific and analytical colormap presets.
 */
typedef enum {
    HISTO_PALETTE_VIRIDIS = 0, /**< Perceptually uniform blue -> teal -> green -> yellow (Default) */
    HISTO_PALETTE_PLASMA,      /**< Perceptually uniform purple -> magenta -> orange -> yellow */
    HISTO_PALETTE_INFERNO,     /**< High-contrast black -> red -> orange -> yellow */
    HISTO_PALETTE_MAGMA,       /**< Deep purple -> rose -> peach -> white */
    HISTO_PALETTE_TURBO,       /**< Smooth perceptual rainbow */
    HISTO_PALETTE_CIVIDIS,     /**< Colorblind-safe blue -> gray -> yellow */
    HISTO_PALETTE_GRAYSCALE,   /**< Linear monochrome luminance ramp */
    HISTO_PALETTE_RAINBOW,     /**< Classic spectral rainbow */
    HISTO_PALETTE_COUNT
} histo_palette_t;

/**
 * @brief Parses a palette preset by name (case-insensitive).
 *
 * @param name Palette name string (e.g. "viridis", "plasma", "inferno", "magma", "turbo", "cividis", "grayscale", "gray", "rainbow").
 * @return Recognized `histo_palette_t` preset, or `HISTO_PALETTE_VIRIDIS` if unrecognized.
 */
histo_palette_t histo_palette_from_name(const char *name);

/**
 * @brief Returns the canonical display name for a palette preset.
 *
 * @param pal Palette preset enum.
 * @return Static string containing the lowercase palette name.
 */
const char *histo_palette_name(histo_palette_t pal);

/**
 * @brief Samples RGB color components (0-255) for a normalized fraction [0.0, 1.0].
 *
 * @param pal Palette preset enum.
 * @param fraction Normalized value in [0.0, 1.0] (clamped if outside).
 * @param[out] out_r Red component (0-255).
 * @param[out] out_g Green component (0-255).
 * @param[out] out_b Blue component (0-255).
 */
void histo_palette_sample_rgb(histo_palette_t pal, double fraction, int *out_r, int *out_g, int *out_b);

/**
 * @brief Formats an ANSI 24-bit TrueColor foreground color sequence.
 *
 * @param pal Palette preset enum.
 * @param fraction Normalized value in [0.0, 1.0].
 * @param[out] buf Output buffer.
 * @param max_len Maximum buffer length.
 */
void histo_palette_sample_ansi_fg(histo_palette_t pal, double fraction, char *buf, size_t max_len);

/**
 * @brief Formats an ANSI 24-bit TrueColor background color sequence.
 *
 * @param pal Palette preset enum.
 * @param fraction Normalized value in [0.0, 1.0].
 * @param[out] buf Output buffer.
 * @param max_len Maximum buffer length.
 */
void histo_palette_sample_ansi_bg(histo_palette_t pal, double fraction, char *buf, size_t max_len);

#ifdef __cplusplus
}
#endif

#endif /* HISTO_CLI_PALETTE_H */
