/*
 * Terminal control, raw mode, ANSI escape parsing, and double-buffered render.
 */

#ifndef HISTO_TUI_TERM_H
#define HISTO_TUI_TERM_H

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    TUI_KEY_NONE = 0,
    TUI_KEY_CHAR,
    TUI_KEY_UP,
    TUI_KEY_DOWN,
    TUI_KEY_LEFT,
    TUI_KEY_RIGHT,
    TUI_KEY_ENTER,
    TUI_KEY_ESC,
    TUI_KEY_TAB,
    TUI_KEY_BACKSPACE,
    TUI_KEY_PAGE_UP,
    TUI_KEY_PAGE_DOWN,
    TUI_KEY_HOME,
    TUI_KEY_END,
    TUI_KEY_CTRL_C,
    TUI_KEY_RESIZE,
    TUI_KEY_MOUSE_CLICK,
    TUI_KEY_MOUSE_SCROLL_UP,
    TUI_KEY_MOUSE_SCROLL_DOWN
} tui_key_type_t;

typedef struct {
    tui_key_type_t type;
    int ch;
    int mouse_x;
    int mouse_y;
    int mouse_btn;
} tui_key_event_t;

/* Double-buffered frame buffer */
typedef struct {
    char *buf;
    size_t len;
    size_t cap;
} tui_frame_t;

/* Terminal state lifecycle */
bool tui_term_init(void);
void tui_term_restore(void);
bool tui_term_raw_enter(void);
void tui_term_raw_leave(void);
void tui_term_get_size(int *out_cols, int *out_rows);
int  tui_term_get_tty_fd(void);

/* Non-blocking key event reader from tty */
tui_key_event_t tui_term_read_key(int tty_fd, int timeout_ms);

/* Frame buffer methods */
void tui_frame_init(tui_frame_t *f, size_t initial_cap);
void tui_frame_clear(tui_frame_t *f);
void tui_frame_append(tui_frame_t *f, const char *str, size_t len);
void tui_frame_puts(tui_frame_t *f, const char *str);
void tui_frame_printf(tui_frame_t *f, const char *fmt, ...);
void tui_frame_flush(tui_frame_t *f, FILE *out_fp);
void tui_frame_free(tui_frame_t *f);

/* Color & style helpers */
void tui_term_get_color(double fraction, bool monochrome, char *out_ansi, size_t max_len);
int  tui_visual_width(const char *str);
void tui_render_row(tui_frame_t *f, const char *content, int width, bool newline);

#ifdef __cplusplus
}
#endif

#endif /* HISTO_TUI_TERM_H */
