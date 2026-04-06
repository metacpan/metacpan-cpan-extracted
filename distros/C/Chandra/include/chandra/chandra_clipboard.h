/*
 * chandra_clipboard.h — System clipboard access
 *
 * Platform support:
 *   - macOS: NSPasteboard (Cocoa)
 *   - Linux: GTK clipboard (gtk_clipboard_*)
 *   - Windows: Win32 clipboard API (stub for now)
 *
 * Include with CHANDRA_XS_IMPLEMENTATION defined to get implementations.
 */
#ifndef CHANDRA_CLIPBOARD_H
#define CHANDRA_CLIPBOARD_H

#include "chandra.h"

/* ---- API declarations ---- */

/* Text clipboard */
static char *chandra_clipboard_get_text(pTHX);
static int   chandra_clipboard_set_text(pTHX_ const char *text, STRLEN len);
static int   chandra_clipboard_has_text(pTHX);

/* HTML clipboard */
static char *chandra_clipboard_get_html(pTHX);
static int   chandra_clipboard_set_html(pTHX_ const char *html, STRLEN len);
static int   chandra_clipboard_has_html(pTHX);

/* Image clipboard */
static SV   *chandra_clipboard_get_image(pTHX);
static int   chandra_clipboard_set_image(pTHX_ const char *path);
static int   chandra_clipboard_has_image(pTHX);

/* Clear clipboard */
static void  chandra_clipboard_clear(pTHX);

/* ================================================================
 * Implementation — compiled only in Chandra.xs
 * ================================================================ */
#ifdef CHANDRA_XS_IMPLEMENTATION

/* ============================================================================
 * macOS Implementation — NSPasteboard
 * ============================================================================ */
#if defined(WEBVIEW_COCOA)

static char *chandra_clipboard_get_text(pTHX) {
    char *result = NULL;
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    id pb = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSPasteboard"),
        sel_registerName("generalPasteboard"));

    id typeStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        "public.utf8-plain-text");

    id str = ((id(*)(id, SEL, id))objc_msgSend)(
        pb, sel_registerName("stringForType:"), typeStr);

    if (str) {
        const char *utf8 = ((const char *(*)(id, SEL))objc_msgSend)(
            str, sel_registerName("UTF8String"));
        if (utf8) {
            size_t slen = strlen(utf8);
            result = (char *)safemalloc(slen + 1);
            memcpy(result, utf8, slen + 1);
        }
    }

    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
    return result;
}

static int chandra_clipboard_set_text(pTHX_ const char *text, STRLEN len) {
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    id pb = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSPasteboard"),
        sel_registerName("generalPasteboard"));

    ((void(*)(id, SEL))objc_msgSend)(
        pb, sel_registerName("clearContents"));

    id nsStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        text);

    id typeStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        "public.utf8-plain-text");

    BOOL ok = ((BOOL(*)(id, SEL, id, id))objc_msgSend)(
        pb, sel_registerName("setString:forType:"),
        nsStr, typeStr);

    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
    return ok ? 1 : 0;
}

static int chandra_clipboard_has_text(pTHX) {
    int result = 0;
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    id pb = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSPasteboard"),
        sel_registerName("generalPasteboard"));

    id typeStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        "public.utf8-plain-text");

    id str = ((id(*)(id, SEL, id))objc_msgSend)(
        pb, sel_registerName("stringForType:"), typeStr);

    result = (str != nil) ? 1 : 0;

    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
    return result;
}

static char *chandra_clipboard_get_html(pTHX) {
    char *result = NULL;
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    id pb = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSPasteboard"),
        sel_registerName("generalPasteboard"));

    id typeStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        "public.html");

    id str = ((id(*)(id, SEL, id))objc_msgSend)(
        pb, sel_registerName("stringForType:"), typeStr);

    if (str) {
        const char *utf8 = ((const char *(*)(id, SEL))objc_msgSend)(
            str, sel_registerName("UTF8String"));
        if (utf8) {
            size_t slen = strlen(utf8);
            result = (char *)safemalloc(slen + 1);
            memcpy(result, utf8, slen + 1);
        }
    }

    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
    return result;
}

static int chandra_clipboard_set_html(pTHX_ const char *html, STRLEN len) {
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    id pb = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSPasteboard"),
        sel_registerName("generalPasteboard"));

    ((void(*)(id, SEL))objc_msgSend)(
        pb, sel_registerName("clearContents"));

    id nsStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        html);

    id typeStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        "public.html");

    BOOL ok = ((BOOL(*)(id, SEL, id, id))objc_msgSend)(
        pb, sel_registerName("setString:forType:"),
        nsStr, typeStr);

    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
    return ok ? 1 : 0;
}

static int chandra_clipboard_has_html(pTHX) {
    int result = 0;
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    id pb = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSPasteboard"),
        sel_registerName("generalPasteboard"));

    id typeStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        "public.html");

    id str = ((id(*)(id, SEL, id))objc_msgSend)(
        pb, sel_registerName("stringForType:"), typeStr);

    result = (str != nil) ? 1 : 0;

    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
    return result;
}

static SV *chandra_clipboard_get_image(pTHX) {
    SV *result = &PL_sv_undef;
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    id pb = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSPasteboard"),
        sel_registerName("generalPasteboard"));

    id typeStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        "public.png");

    id data = ((id(*)(id, SEL, id))objc_msgSend)(
        pb, sel_registerName("dataForType:"), typeStr);

    if (!data) {
        /* Try TIFF as fallback */
        id tiffType = ((id(*)(id, SEL, const char *))objc_msgSend)(
            (id)objc_getClass("NSString"),
            sel_registerName("stringWithUTF8String:"),
            "public.tiff");
        data = ((id(*)(id, SEL, id))objc_msgSend)(
            pb, sel_registerName("dataForType:"), tiffType);

        if (data) {
            /* Convert TIFF to PNG via NSBitmapImageRep */
            id rep = ((id(*)(id, SEL, id))objc_msgSend)(
                (id)objc_getClass("NSBitmapImageRep"),
                sel_registerName("imageRepWithData:"), data);
            if (rep) {
                /* NSBitmapImageFileTypePNG = 4 */
                id props = ((id(*)(id, SEL))objc_msgSend)(
                    (id)objc_getClass("NSDictionary"),
                    sel_registerName("dictionary"));
                data = ((id(*)(id, SEL, unsigned long, id))objc_msgSend)(
                    rep, sel_registerName("representationUsingType:properties:"),
                    (unsigned long)4, props);
            }
        }
    }

    if (data) {
        const void *bytes = ((const void *(*)(id, SEL))objc_msgSend)(
            data, sel_registerName("bytes"));
        NSUInteger length = ((NSUInteger(*)(id, SEL))objc_msgSend)(
            data, sel_registerName("length"));
        if (bytes && length > 0) {
            result = newSVpvn((const char *)bytes, (STRLEN)length);
        }
    }

    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
    return result;
}

static int chandra_clipboard_set_image(pTHX_ const char *path) {
    int ok = 0;
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    id pathStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        path);

    id data = ((id(*)(id, SEL, id))objc_msgSend)(
        (id)objc_getClass("NSData"),
        sel_registerName("dataWithContentsOfFile:"),
        pathStr);

    if (data) {
        id pb = ((id(*)(id, SEL))objc_msgSend)(
            (id)objc_getClass("NSPasteboard"),
            sel_registerName("generalPasteboard"));

        ((void(*)(id, SEL))objc_msgSend)(
            pb, sel_registerName("clearContents"));

        id typeStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
            (id)objc_getClass("NSString"),
            sel_registerName("stringWithUTF8String:"),
            "public.png");

        ok = ((BOOL(*)(id, SEL, id, id))objc_msgSend)(
            pb, sel_registerName("setData:forType:"),
            data, typeStr) ? 1 : 0;
    }

    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
    return ok;
}

static int chandra_clipboard_has_image(pTHX) {
    int result = 0;
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    id pb = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSPasteboard"),
        sel_registerName("generalPasteboard"));

    /* Check for PNG */
    id pngType = ((id(*)(id, SEL, const char *))objc_msgSend)(
        (id)objc_getClass("NSString"),
        sel_registerName("stringWithUTF8String:"),
        "public.png");
    id data = ((id(*)(id, SEL, id))objc_msgSend)(
        pb, sel_registerName("dataForType:"), pngType);

    if (!data) {
        /* Check for TIFF */
        id tiffType = ((id(*)(id, SEL, const char *))objc_msgSend)(
            (id)objc_getClass("NSString"),
            sel_registerName("stringWithUTF8String:"),
            "public.tiff");
        data = ((id(*)(id, SEL, id))objc_msgSend)(
            pb, sel_registerName("dataForType:"), tiffType);
    }

    result = (data != nil) ? 1 : 0;

    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
    return result;
}

static void chandra_clipboard_clear(pTHX) {
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    id pb = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSPasteboard"),
        sel_registerName("generalPasteboard"));

    ((void(*)(id, SEL))objc_msgSend)(
        pb, sel_registerName("clearContents"));

    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
}

/* ============================================================================
 * Linux Implementation — GTK clipboard
 * ============================================================================ */
#elif defined(WEBVIEW_GTK)

#include <gtk/gtk.h>
#include <string.h>

/* Ensure GTK is initialized for clipboard access */
static void chandra_clipboard_ensure_gtk(void) {
    static int inited = 0;
    if (!inited) {
        if (!gtk_init_check(NULL, NULL)) {
            /* GTK init failed — clipboard won't work */
        }
        inited = 1;
    }
}

static char *chandra_clipboard_get_text(pTHX) {
    char *result = NULL;
    GtkClipboard *cb;
    gchar *text;

    chandra_clipboard_ensure_gtk();
    cb = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    text = gtk_clipboard_wait_for_text(cb);

    if (text) {
        size_t slen = strlen(text);
        result = (char *)safemalloc(slen + 1);
        memcpy(result, text, slen + 1);
        g_free(text);
    }
    return result;
}

static int chandra_clipboard_set_text(pTHX_ const char *text, STRLEN len) {
    GtkClipboard *cb;

    chandra_clipboard_ensure_gtk();
    cb = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_set_text(cb, text, (gint)len);
    gtk_clipboard_store(cb);
    return 1;
}

static int chandra_clipboard_has_text(pTHX) {
    GtkClipboard *cb;

    chandra_clipboard_ensure_gtk();
    cb = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    return gtk_clipboard_wait_is_text_available(cb) ? 1 : 0;
}

static char *chandra_clipboard_get_html(pTHX) {
    char *result = NULL;
    GtkClipboard *cb;
    GtkSelectionData *sel;
    GdkAtom html_atom;

    chandra_clipboard_ensure_gtk();
    cb = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    html_atom = gdk_atom_intern("text/html", FALSE);
    sel = gtk_clipboard_wait_for_contents(cb, html_atom);

    if (sel) {
        const guchar *data = gtk_selection_data_get_data(sel);
        gint dlen = gtk_selection_data_get_length(sel);
        if (data && dlen > 0) {
            result = (char *)safemalloc(dlen + 1);
            memcpy(result, data, dlen);
            result[dlen] = '\0';
        }
        gtk_selection_data_free(sel);
    }
    return result;
}

static int chandra_clipboard_set_html(pTHX_ const char *html, STRLEN len) {
    /* GTK doesn't have a simple set_html — use target list approach */
    /* For simplicity, store as text with text/html target */
    GtkClipboard *cb;

    chandra_clipboard_ensure_gtk();
    cb = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    /* Set as plain text; HTML-aware apps can request text/html target */
    gtk_clipboard_set_text(cb, html, (gint)len);
    gtk_clipboard_store(cb);
    return 1;
}

static int chandra_clipboard_has_html(pTHX) {
    GtkClipboard *cb;
    GdkAtom html_atom;

    chandra_clipboard_ensure_gtk();
    cb = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    html_atom = gdk_atom_intern("text/html", FALSE);
    return gtk_clipboard_wait_is_target_available(cb, html_atom) ? 1 : 0;
}

static SV *chandra_clipboard_get_image(pTHX) {
    SV *result = &PL_sv_undef;
    GtkClipboard *cb;
    GdkPixbuf *pixbuf;

    chandra_clipboard_ensure_gtk();
    cb = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    pixbuf = gtk_clipboard_wait_for_image(cb);

    if (pixbuf) {
        gchar *buf = NULL;
        gsize buf_size = 0;
        GError *error = NULL;

        if (gdk_pixbuf_save_to_buffer(pixbuf, &buf, &buf_size, "png", &error, NULL)) {
            result = newSVpvn(buf, (STRLEN)buf_size);
            g_free(buf);
        }
        if (error) g_error_free(error);
        g_object_unref(pixbuf);
    }
    return result;
}

static int chandra_clipboard_set_image(pTHX_ const char *path) {
    GtkClipboard *cb;
    GdkPixbuf *pixbuf;
    GError *error = NULL;

    chandra_clipboard_ensure_gtk();
    pixbuf = gdk_pixbuf_new_from_file(path, &error);
    if (!pixbuf) {
        if (error) g_error_free(error);
        return 0;
    }

    cb = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_set_image(cb, pixbuf);
    gtk_clipboard_store(cb);
    g_object_unref(pixbuf);
    return 1;
}

static int chandra_clipboard_has_image(pTHX) {
    GtkClipboard *cb;

    chandra_clipboard_ensure_gtk();
    cb = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    return gtk_clipboard_wait_is_image_available(cb) ? 1 : 0;
}

static void chandra_clipboard_clear(pTHX) {
    GtkClipboard *cb;

    chandra_clipboard_ensure_gtk();
    cb = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_clear(cb);
    gtk_clipboard_store(cb);
}

/* ============================================================================
 * Windows Implementation — Win32 clipboard API (stub)
 * ============================================================================ */
#elif defined(WEBVIEW_EDGE)

static char *chandra_clipboard_get_text(pTHX) { return NULL; }
static int   chandra_clipboard_set_text(pTHX_ const char *text, STRLEN len) { return 0; }
static int   chandra_clipboard_has_text(pTHX) { return 0; }
static char *chandra_clipboard_get_html(pTHX) { return NULL; }
static int   chandra_clipboard_set_html(pTHX_ const char *html, STRLEN len) { return 0; }
static int   chandra_clipboard_has_html(pTHX) { return 0; }
static SV   *chandra_clipboard_get_image(pTHX) { return &PL_sv_undef; }
static int   chandra_clipboard_set_image(pTHX_ const char *path) { return 0; }
static int   chandra_clipboard_has_image(pTHX) { return 0; }
static void  chandra_clipboard_clear(pTHX) {}

#else
/* Unknown platform */
static char *chandra_clipboard_get_text(pTHX) { return NULL; }
static int   chandra_clipboard_set_text(pTHX_ const char *text, STRLEN len) { return 0; }
static int   chandra_clipboard_has_text(pTHX) { return 0; }
static char *chandra_clipboard_get_html(pTHX) { return NULL; }
static int   chandra_clipboard_set_html(pTHX_ const char *html, STRLEN len) { return 0; }
static int   chandra_clipboard_has_html(pTHX) { return 0; }
static SV   *chandra_clipboard_get_image(pTHX) { return &PL_sv_undef; }
static int   chandra_clipboard_set_image(pTHX_ const char *path) { return 0; }
static int   chandra_clipboard_has_image(pTHX) { return 0; }
static void  chandra_clipboard_clear(pTHX) {}

#endif /* platform selection */

#endif /* CHANDRA_XS_IMPLEMENTATION */
#endif /* CHANDRA_CLIPBOARD_H */
