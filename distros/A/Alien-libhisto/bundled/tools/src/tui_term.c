/*
 * Low-level terminal raw mode handling, mouse tracking, and screen drawing.
 */

#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE
#define _XOPEN_SOURCE 700

#include "tui_term.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdbool.h>
#include <ctype.h>
#include <unistd.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <poll.h>

#if !defined(_WIN32)
#include <termios.h>
#include <fcntl.h>

static struct termios orig_termios;
static bool term_is_raw = false;
static volatile sig_atomic_t g_resized = 0;
static int g_tty_fd = -1;
static bool g_tty_is_dev_tty = false;

static void sigwinch_handler(int sig) {
    (void)sig;
    g_resized = 1;
}

static void sigint_handler(int sig) {
    (void)sig;
    tui_term_restore();
    _exit(0);
}
#endif

int tui_term_get_tty_fd(void) {
#if !defined(_WIN32)
    if (g_tty_fd >= 0) return g_tty_fd;
    if (isatty(STDIN_FILENO)) {
        g_tty_fd = STDIN_FILENO;
    } else {
        g_tty_fd = open("/dev/tty", O_RDWR | O_NOCTTY);
        if (g_tty_fd >= 0) {
            g_tty_is_dev_tty = true;
        } else if (isatty(STDOUT_FILENO)) {
            g_tty_fd = STDOUT_FILENO;
        }
    }
    return g_tty_fd;
#else
    return 0;
#endif
}

bool tui_term_init(void) {
#if !defined(_WIN32)
    int fd = tui_term_get_tty_fd();
    if (fd < 0) {
        return false;
    }
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = sigwinch_handler;
    sigaction(SIGWINCH, &sa, NULL);

    struct sigaction sa_int;
    memset(&sa_int, 0, sizeof(sa_int));
    sa_int.sa_handler = sigint_handler;
    sigaction(SIGINT, &sa_int, NULL);
    sigaction(SIGTERM, &sa_int, NULL);
#endif
    return true;
}

bool tui_term_raw_enter(void) {
#if !defined(_WIN32)
    if (term_is_raw) return true;
    int fd = tui_term_get_tty_fd();
    if (fd < 0) return false;

    if (tcgetattr(fd, &orig_termios) == -1) {
        return false;
    }

    struct termios raw = orig_termios;
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    raw.c_oflag |= (OPOST | ONLCR);
    raw.c_cflag |= (CS8);
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 0;

    if (tcsetattr(fd, TCSAFLUSH, &raw) == -1) {
        return false;
    }
    term_is_raw = true;

    /* Enter alternate screen, hide cursor, and enable SGR 1006 mouse tracking */
    printf("\033[?1049h\033[?25l\033[?1000h\033[?1006h");
    fflush(stdout);
#endif
    return true;
}

void tui_term_raw_leave(void) {
#if !defined(_WIN32)
    if (!term_is_raw) return;
    int fd = tui_term_get_tty_fd();
    if (fd >= 0) {
        tcsetattr(fd, TCSAFLUSH, &orig_termios);
    }
    /* Disable mouse tracking, show cursor, and exit alternate screen */
    printf("\033[?1006l\033[?1000l\033[?25h\033[?1049l");
    fflush(stdout);
    term_is_raw = false;
#endif
}

void tui_term_restore(void) {
#if !defined(_WIN32)
    tui_term_raw_leave();
    if (g_tty_is_dev_tty && g_tty_fd >= 0) {
        close(g_tty_fd);
        g_tty_fd = -1;
        g_tty_is_dev_tty = false;
    }
#endif
}

void tui_term_get_size(int *out_cols, int *out_rows) {
    int cols = 80, rows = 24;
#if !defined(_WIN32)
    struct winsize ws;
    int fd = tui_term_get_tty_fd();
    if (fd >= 0 && ioctl(fd, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0 && ws.ws_row > 0) {
        cols = ws.ws_col;
        rows = ws.ws_row;
    } else if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0 && ws.ws_row > 0) {
        cols = ws.ws_col;
        rows = ws.ws_row;
    } else {
        const char *c_env = getenv("COLUMNS");
        const char *l_env = getenv("LINES");
        if (c_env) cols = atoi(c_env);
        if (l_env) rows = atoi(l_env);
    }
#endif
    if (cols < 20) cols = 20;
    if (rows < 5) rows = 5;
    if (out_cols) *out_cols = cols;
    if (out_rows) *out_rows = rows;
}

tui_key_event_t tui_term_read_key(int tty_fd, int timeout_ms) {
    tui_key_event_t ev = { .type = TUI_KEY_NONE, .ch = 0, .mouse_x = 0, .mouse_y = 0, .mouse_btn = 0 };

#if !defined(_WIN32)
    if (g_resized) {
        g_resized = 0;
        ev.type = TUI_KEY_RESIZE;
        return ev;
    }

    struct pollfd pfd = { .fd = tty_fd, .events = POLLIN, .revents = 0 };
    int ret = poll(&pfd, 1, timeout_ms);
    if (ret <= 0 || !(pfd.revents & POLLIN)) {
        return ev;
    }

    char c = 0;
    if (read(tty_fd, &c, 1) != 1) {
        return ev;
    }

    if (c == '\033') {
        char seq[64];
        memset(seq, 0, sizeof(seq));
        seq[0] = '\033';
        int n = 1;
        while (n < 63) {
            struct pollfd pfd_seq = { .fd = tty_fd, .events = POLLIN, .revents = 0 };
            if (poll(&pfd_seq, 1, 10) > 0 && (pfd_seq.revents & POLLIN)) {
                if (read(tty_fd, &seq[n], 1) == 1) {
                    char last_ch = seq[n];
                    n++;
                    if (n >= 3 && seq[1] == '[' && seq[2] == '<' && (last_ch == 'M' || last_ch == 'm')) break;
                    if (n >= 4 && (last_ch == '~' || isalpha((unsigned char)last_ch))) break;
                } else break;
            } else break;
        }
        seq[n] = '\0';

        if (n == 1) {
            ev.type = TUI_KEY_ESC;
            ev.ch = '\033';
            return ev;
        }

        if (seq[1] == '[') {
            if (seq[2] == '<') {
                /* SGR 1006 mouse event: \033[<btn;x;y(M|m) */
                int btn = 0, mx = 0, my = 0;
                char act = 0;
                if (sscanf(seq + 3, "%d;%d;%d%c", &btn, &mx, &my, &act) >= 3) {
                    if (btn == 64) {
                        ev.type = TUI_KEY_MOUSE_SCROLL_UP;
                        ev.mouse_x = mx;
                        ev.mouse_y = my;
                        return ev;
                    } else if (btn == 65) {
                        ev.type = TUI_KEY_MOUSE_SCROLL_DOWN;
                        ev.mouse_x = mx;
                        ev.mouse_y = my;
                        return ev;
                    } else if (act == 'M' || act == 0) {
                        ev.type = TUI_KEY_MOUSE_CLICK;
                        ev.mouse_btn = btn;
                        ev.mouse_x = mx;
                        ev.mouse_y = my;
                        return ev;
                    }
                }
            } else if (seq[2] == 'Z') {
                /* Shift-Tab (back-tab) */
                ev.type = TUI_KEY_TAB;
                ev.ch = -1;
                return ev;
            } else if (seq[2] >= '0' && seq[2] <= '9') {
                if (seq[3] == '~') {
                    switch (seq[2]) {
                        case '1': ev.type = TUI_KEY_HOME; break;
                        case '3': ev.type = TUI_KEY_BACKSPACE; break;
                        case '4': ev.type = TUI_KEY_END; break;
                        case '5': ev.type = TUI_KEY_PAGE_UP; break;
                        case '6': ev.type = TUI_KEY_PAGE_DOWN; break;
                        case '7': ev.type = TUI_KEY_HOME; break;
                        case '8': ev.type = TUI_KEY_END; break;
                        default: break;
                    }
                }
            } else {
                switch (seq[2]) {
                    case 'A': ev.type = TUI_KEY_UP; break;
                    case 'B': ev.type = TUI_KEY_DOWN; break;
                    case 'C': ev.type = TUI_KEY_RIGHT; break;
                    case 'D': ev.type = TUI_KEY_LEFT; break;
                    case 'H': ev.type = TUI_KEY_HOME; break;
                    case 'F': ev.type = TUI_KEY_END; break;
                    default: break;
                }
            }
        } else if (seq[1] == 'O') {
            switch (seq[2]) {
                case 'H': ev.type = TUI_KEY_HOME; break;
                case 'F': ev.type = TUI_KEY_END; break;
                default: break;
            }
        }
        return ev;
    }

    if (c == 3) {
        ev.type = TUI_KEY_CTRL_C;
        ev.ch = 3;
        return ev;
    }
    if (c == 13 || c == 10) {
        ev.type = TUI_KEY_ENTER;
        ev.ch = '\n';
        return ev;
    }
    if (c == 9) {
        ev.type = TUI_KEY_TAB;
        ev.ch = '\t';
        return ev;
    }
    if (c == 127 || c == 8) {
        ev.type = TUI_KEY_BACKSPACE;
        ev.ch = '\b';
        return ev;
    }

    ev.type = TUI_KEY_CHAR;
    ev.ch = (unsigned char)c;
#endif
    return ev;
}

/* Frame buffer methods */
void tui_frame_init(tui_frame_t *f, size_t initial_cap) {
    if (!f) return;
    if (initial_cap < 4096) initial_cap = 65536;
    f->buf = (char *)malloc(initial_cap);
    f->len = 0;
    f->cap = initial_cap;
    if (f->buf) f->buf[0] = '\0';
}

void tui_frame_clear(tui_frame_t *f) {
    if (!f) return;
    f->len = 0;
    if (f->buf) f->buf[0] = '\0';
}

void tui_frame_append(tui_frame_t *f, const char *str, size_t len) {
    if (!f || !str || len == 0) return;
    if (f->len + len + 1 > f->cap) {
        size_t new_cap = (f->cap * 2 > f->len + len + 1) ? f->cap * 2 : f->len + len + 4096;
        char *new_buf = (char *)realloc(f->buf, new_cap);
        if (!new_buf) return;
        f->buf = new_buf;
        f->cap = new_cap;
    }
    memcpy(f->buf + f->len, str, len);
    f->len += len;
    f->buf[f->len] = '\0';
}

void tui_frame_puts(tui_frame_t *f, const char *str) {
    if (!f || !str) return;
    tui_frame_append(f, str, strlen(str));
}

void tui_frame_printf(tui_frame_t *f, const char *fmt, ...) {
    if (!f || !fmt) return;
    char stack_buf[1024];
    va_list args;
    va_start(args, fmt);
    int written = vsnprintf(stack_buf, sizeof(stack_buf), fmt, args);
    va_end(args);

    if (written < 0) return;
    if ((size_t)written < sizeof(stack_buf)) {
        tui_frame_append(f, stack_buf, (size_t)written);
    } else {
        char *heap_buf = (char *)malloc((size_t)written + 1);
        if (heap_buf) {
            va_start(args, fmt);
            vsnprintf(heap_buf, (size_t)written + 1, fmt, args);
            va_end(args);
            tui_frame_append(f, heap_buf, (size_t)written);
            free(heap_buf);
        }
    }
}

void tui_frame_flush(tui_frame_t *f, FILE *out_fp) {
    if (!f || !f->buf || f->len == 0) return;
    if (!out_fp) out_fp = stdout;
    fwrite(f->buf, 1, f->len, out_fp);
    fflush(out_fp);
    tui_frame_clear(f);
}

void tui_frame_free(tui_frame_t *f) {
    if (!f) return;
    if (f->buf) {
        free(f->buf);
        f->buf = NULL;
    }
    f->len = 0;
    f->cap = 0;
}

void tui_term_get_color(double fraction, bool monochrome, char *out_ansi, size_t max_len) {
    if (!out_ansi || max_len == 0) return;
    out_ansi[0] = '\0';
    if (monochrome) return;

    if (fraction < 0.0) fraction = 0.0;
    if (fraction > 1.0) fraction = 1.0;

    int r = 0, g = 0, b = 0;
    if (fraction < 0.25) {
        double t = fraction / 0.25;
        r = 0;
        g = (int)(t * 255.0);
        b = 255;
    } else if (fraction < 0.5) {
        double t = (fraction - 0.25) / 0.25;
        r = 0;
        g = 255;
        b = (int)((1.0 - t) * 255.0);
    } else if (fraction < 0.75) {
        double t = (fraction - 0.5) / 0.25;
        r = (int)(t * 255.0);
        g = 255;
        b = 0;
    } else {
        double t = (fraction - 0.75) / 0.25;
        r = 255;
        g = (int)((1.0 - t) * 255.0);
        b = 0;
    }
    snprintf(out_ansi, max_len, "\033[38;2;%d;%d;%dm", r, g, b);
}

int tui_visual_width(const char *str) {
    if (!str) return 0;
    int cols = 0;
    const unsigned char *p = (const unsigned char *)str;
    while (*p) {
        if (*p == '\033') {
            p++;
            if (*p == '[') {
                p++;
                while (*p && (*p < 0x40 || *p > 0x7E)) p++;
                if (*p) p++;
            }
        } else if (*p < 0x80) {
            if (*p >= 32 && *p <= 126) cols++;
            p++;
        } else if ((*p & 0xE0) == 0xC0) {
            cols++;
            p += (*(p + 1)) ? 2 : 1;
        } else if ((*p & 0xF0) == 0xE0) {
            cols++;
            p += (*(p + 1) && *(p + 2)) ? 3 : 1;
        } else if ((*p & 0xF8) == 0xF0) {
            cols += 2;
            p += (*(p + 1) && *(p + 2) && *(p + 3)) ? 4 : 1;
        } else {
            p++;
        }
    }
    return cols;
}

void tui_render_row(tui_frame_t *f, const char *content, int width, bool newline) {
    if (!f) return;
    tui_frame_puts(f, "│ ");
    int vis = tui_visual_width(content);
    int inner_width = width - 4;
    if (inner_width < 1) inner_width = 1;

    if (vis <= inner_width) {
        tui_frame_puts(f, content ? content : "");
        int pad = inner_width - vis;
        for (int i = 0; i < pad; ++i) tui_frame_puts(f, " ");
    } else {
        const unsigned char *p = (const unsigned char *)(content ? content : "");
        int cur_cols = 0;
        while (*p && cur_cols < inner_width) {
            if (*p == '\033') {
                const unsigned char *start = p++;
                if (*p == '[') {
                    p++;
                    while (*p && (*p < 0x40 || *p > 0x7E)) p++;
                    if (*p) p++;
                }
                tui_frame_append(f, (const char *)start, (size_t)(p - start));
            } else if (*p < 0x80) {
                if (*p >= 32 && *p <= 126) cur_cols++;
                tui_frame_append(f, (const char *)p, 1);
                p++;
            } else if ((*p & 0xE0) == 0xC0) {
                cur_cols++;
                size_t len = (*(p + 1)) ? 2 : 1;
                tui_frame_append(f, (const char *)p, len);
                p += len;
            } else if ((*p & 0xF0) == 0xE0) {
                cur_cols++;
                size_t len = (*(p + 1) && *(p + 2)) ? 3 : 1;
                tui_frame_append(f, (const char *)p, len);
                p += len;
            } else if ((*p & 0xF8) == 0xF0) {
                if (cur_cols + 2 <= inner_width) {
                    cur_cols += 2;
                    size_t len = (*(p + 1) && *(p + 2) && *(p + 3)) ? 4 : 1;
                    tui_frame_append(f, (const char *)p, len);
                    p += len;
                } else break;
            } else {
                p++;
            }
        }
        int pad = inner_width - cur_cols;
        for (int i = 0; i < pad; ++i) tui_frame_puts(f, " ");
    }

    tui_frame_puts(f, "\033[0m │");
    if (newline) tui_frame_puts(f, "\r\n");
}
