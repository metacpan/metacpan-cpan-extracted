/*
 * chandra_notify.h — Native OS notifications
 *
 * Platform support:
 *   - macOS: UNUserNotificationCenter (10.14+) / NSUserNotification (legacy)
 *   - Linux: libnotify or notify-send fallback
 *   - Windows: Shell_NotifyIcon balloon / toast (stub for now)
 *
 * Include with CHANDRA_XS_IMPLEMENTATION defined to get implementations.
 */
#ifndef CHANDRA_NOTIFY_H
#define CHANDRA_NOTIFY_H

#include "chandra.h"

/* ---- Notification structure ---- */

typedef struct {
    const char *title;
    const char *body;
    const char *icon;          /* Path to icon file (optional) */
    int         sound;         /* Play default sound (1 = yes) */
    int         timeout_ms;    /* Auto-dismiss timeout in ms (0 = default) */
} ChandraNotification;

/* ---- API declarations ---- */

/* Check if notifications are supported on this platform */
static int chandra_notify_is_supported(void);

/* Send a notification. Returns 1 on success, 0 on failure. */
static int chandra_notify_send(pTHX_ ChandraNotification *notif);

/* ================================================================
 * Implementation-only section — compiled only in Chandra.xs
 * (CHANDRA_XS_IMPLEMENTATION is defined there before including us)
 * ================================================================ */
#ifdef CHANDRA_XS_IMPLEMENTATION

/* ============================================================================
 * macOS Implementation — UNUserNotificationCenter / NSUserNotification
 * ============================================================================ */
#if defined(WEBVIEW_COCOA)

/* Objective-C runtime helpers - already available from webview.h */

static int chandra_notify_is_supported(void) {
    return 1;  /* Always supported on macOS */
}

static int chandra_notify_send(pTHX_ ChandraNotification *notif) {
    id pool = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSAutoreleasePool"),
        sel_registerName("new"));

    /* Try UNUserNotificationCenter first (macOS 10.14+) */
    Class UNClass = objc_getClass("UNUserNotificationCenter");
    
    if (UNClass) {
        /* Modern notification API */
        id center = ((id(*)(id, SEL))objc_msgSend)(
            (id)UNClass,
            sel_registerName("currentNotificationCenter"));
        
        /* Create content */
        id contentClass = objc_getClass("UNMutableNotificationContent");
        id content = ((id(*)(id, SEL))objc_msgSend)(
            ((id(*)(id, SEL))objc_msgSend)(
                (id)contentClass,
                sel_registerName("alloc")),
            sel_registerName("init"));
        
        /* Set title */
        if (notif->title) {
            id titleStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
                (id)objc_getClass("NSString"),
                sel_registerName("stringWithUTF8String:"),
                notif->title);
            ((void(*)(id, SEL, id))objc_msgSend)(
                content, sel_registerName("setTitle:"), titleStr);
        }
        
        /* Set body */
        if (notif->body) {
            id bodyStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
                (id)objc_getClass("NSString"),
                sel_registerName("stringWithUTF8String:"),
                notif->body);
            ((void(*)(id, SEL, id))objc_msgSend)(
                content, sel_registerName("setBody:"), bodyStr);
        }
        
        /* Set sound */
        if (notif->sound) {
            id defaultSound = ((id(*)(id, SEL))objc_msgSend)(
                (id)objc_getClass("UNNotificationSound"),
                sel_registerName("defaultSound"));
            ((void(*)(id, SEL, id))objc_msgSend)(
                content, sel_registerName("setSound:"), defaultSound);
        }
        
        /* Create request with unique identifier */
        id uuidClass = objc_getClass("NSUUID");
        id uuid = ((id(*)(id, SEL))objc_msgSend)(
            ((id(*)(id, SEL))objc_msgSend)(
                (id)uuidClass,
                sel_registerName("alloc")),
            sel_registerName("init"));
        id identifier = ((id(*)(id, SEL))objc_msgSend)(
            uuid, sel_registerName("UUIDString"));
        
        id requestClass = objc_getClass("UNNotificationRequest");
        id request = ((id(*)(id, SEL, id, id, id))objc_msgSend)(
            (id)requestClass,
            sel_registerName("requestWithIdentifier:content:trigger:"),
            identifier, content, nil);
        
        /* Add request to center (async, we don't wait for completion) */
        ((void(*)(id, SEL, id, id))objc_msgSend)(
            center, sel_registerName("addNotificationRequest:withCompletionHandler:"),
            request, nil);
        
    } else {
        /* Legacy NSUserNotification (pre-10.14) */
        id notifClass = objc_getClass("NSUserNotification");
        id notification = ((id(*)(id, SEL))objc_msgSend)(
            ((id(*)(id, SEL))objc_msgSend)(
                (id)notifClass,
                sel_registerName("alloc")),
            sel_registerName("init"));
        
        /* Set title */
        if (notif->title) {
            id titleStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
                (id)objc_getClass("NSString"),
                sel_registerName("stringWithUTF8String:"),
                notif->title);
            ((void(*)(id, SEL, id))objc_msgSend)(
                notification, sel_registerName("setTitle:"), titleStr);
        }
        
        /* Set informative text (body) */
        if (notif->body) {
            id bodyStr = ((id(*)(id, SEL, const char *))objc_msgSend)(
                (id)objc_getClass("NSString"),
                sel_registerName("stringWithUTF8String:"),
                notif->body);
            ((void(*)(id, SEL, id))objc_msgSend)(
                notification, sel_registerName("setInformativeText:"), bodyStr);
        }
        
        /* Set sound */
        if (notif->sound) {
            id soundName = ((id(*)(id, SEL, const char *))objc_msgSend)(
                (id)objc_getClass("NSString"),
                sel_registerName("stringWithUTF8String:"),
                "NSUserNotificationDefaultSoundName");
            ((void(*)(id, SEL, id))objc_msgSend)(
                notification, sel_registerName("setSoundName:"), soundName);
        }
        
        /* Deliver */
        id center = ((id(*)(id, SEL))objc_msgSend)(
            (id)objc_getClass("NSUserNotificationCenter"),
            sel_registerName("defaultUserNotificationCenter"));
        ((void(*)(id, SEL, id))objc_msgSend)(
            center, sel_registerName("deliverNotification:"), notification);
    }
    
    ((void(*)(id, SEL))objc_msgSend)(pool, sel_registerName("drain"));
    return 1;
}

/* ============================================================================
 * Linux Implementation — libnotify or notify-send fallback
 * ============================================================================ */
#elif defined(WEBVIEW_GTK)

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dlfcn.h>

/* libnotify function pointers */
static void *libnotify_handle = NULL;
static int (*notify_init_fn)(const char *) = NULL;
static void *(*notify_notification_new_fn)(const char *, const char *, const char *) = NULL;
static int (*notify_notification_show_fn)(void *, void **) = NULL;
static void (*g_object_unref_fn)(void *) = NULL;

static int libnotify_loaded = 0;
static int libnotify_available = -1;  /* -1 = not checked, 0 = no, 1 = yes */

static int chandra_notify_load_libnotify(void) {
    if (libnotify_loaded) return libnotify_available;
    libnotify_loaded = 1;
    
    libnotify_handle = dlopen("libnotify.so.4", RTLD_LAZY);
    if (!libnotify_handle) {
        libnotify_handle = dlopen("libnotify.so", RTLD_LAZY);
    }
    
    if (!libnotify_handle) {
        libnotify_available = 0;
        return 0;
    }
    
    notify_init_fn = dlsym(libnotify_handle, "notify_init");
    notify_notification_new_fn = dlsym(libnotify_handle, "notify_notification_new");
    notify_notification_show_fn = dlsym(libnotify_handle, "notify_notification_show");
    g_object_unref_fn = dlsym(libnotify_handle, "g_object_unref");
    
    if (!notify_init_fn || !notify_notification_new_fn || !notify_notification_show_fn) {
        dlclose(libnotify_handle);
        libnotify_handle = NULL;
        libnotify_available = 0;
        return 0;
    }
    
    /* Initialize libnotify */
    if (!notify_init_fn("Chandra")) {
        dlclose(libnotify_handle);
        libnotify_handle = NULL;
        libnotify_available = 0;
        return 0;
    }
    
    libnotify_available = 1;
    return 1;
}

/* Shell-escape a string for use inside single quotes.
 * Replaces ' with '\'' (end quote, escaped quote, start quote). */
static void _chandra_shell_escape(const char *src, char *dst, size_t dst_size) {
    size_t j = 0;
    for (size_t i = 0; src[i] && j < dst_size - 5; i++) {
        if (src[i] == '\'') {
            dst[j++] = '\''; dst[j++] = '\\';
            dst[j++] = '\''; dst[j++] = '\'';
        } else {
            dst[j++] = src[i];
        }
    }
    dst[j] = '\0';
}

static int chandra_notify_is_supported(void) {
    /* Try libnotify first */
    if (chandra_notify_load_libnotify()) return 1;
    
    /* Check for notify-send as fallback */
    return (system("which notify-send >/dev/null 2>&1") == 0) ? 1 : 0;
}

static int chandra_notify_send(pTHX_ ChandraNotification *notif) {
    /* Try libnotify first */
    if (chandra_notify_load_libnotify()) {
        void *n = notify_notification_new_fn(
            notif->title ? notif->title : "",
            notif->body ? notif->body : "",
            notif->icon ? notif->icon : NULL
        );
        
        if (n) {
            int result = notify_notification_show_fn(n, NULL);
            if (g_object_unref_fn) g_object_unref_fn(n);
            return result ? 1 : 0;
        }
        return 0;
    }
    
    /* Fallback to notify-send */
    {
        char cmd[4096];
        int len = 0;
        
        len = snprintf(cmd, sizeof(cmd), "notify-send");
        
        if (notif->icon) {
            len += snprintf(cmd + len, sizeof(cmd) - len, " -i '%s'", notif->icon);
        }
        
        if (notif->timeout_ms > 0) {
            len += snprintf(cmd + len, sizeof(cmd) - len, " -t %d", notif->timeout_ms);
        }
        
        /* Title and body — shell-escape single quotes */
        {
            const char *title = notif->title ? notif->title : "";
            const char *body = notif->body;
            char escaped_title[512];
            char escaped_body[512];

            _chandra_shell_escape(title, escaped_title, sizeof(escaped_title));
            len += snprintf(cmd + len, sizeof(cmd) - len, " '%s'", escaped_title);

            if (body) {
                _chandra_shell_escape(body, escaped_body, sizeof(escaped_body));
                len += snprintf(cmd + len, sizeof(cmd) - len, " '%s'", escaped_body);
            }
        }
        
        len += snprintf(cmd + len, sizeof(cmd) - len, " >/dev/null 2>&1 &");
        
        return (system(cmd) == 0) ? 1 : 0;
    }
}

/* ============================================================================
 * Windows Implementation — Toast / Balloon notifications (stub)
 * ============================================================================ */
#elif defined(WEBVIEW_WINAPI)

static int chandra_notify_is_supported(void) {
    return 1;  /* Windows always has some form of notification support */
}

static int chandra_notify_send(pTHX_ ChandraNotification *notif) {
    /* Use Shell_NotifyIcon balloon tip (Windows 7+).
     * Full WinRT toast requires COM + IToastNotificationManager
     * which is deferred to a future phase. */
    NOTIFYICONDATAA nid;
    memset(&nid, 0, sizeof(nid));
    nid.cbSize = sizeof(NOTIFYICONDATAA);
    nid.uID = 9999;
    nid.uFlags = NIF_INFO | NIF_ICON;
    nid.dwInfoFlags = NIIF_INFO;
    nid.hIcon = LoadIcon(NULL, IDI_APPLICATION);

    if (notif->title)
        strncpy(nid.szInfoTitle, notif->title, sizeof(nid.szInfoTitle) - 1);
    if (notif->body)
        strncpy(nid.szInfo, notif->body, sizeof(nid.szInfo) - 1);

    Shell_NotifyIconA(NIM_ADD, &nid);
    nid.uFlags = NIF_INFO;
    Shell_NotifyIconA(NIM_MODIFY, &nid);
    return 1;
}

#else
/* Unsupported platform */

static int chandra_notify_is_supported(void) {
    return 0;
}

static int chandra_notify_send(pTHX_ ChandraNotification *notif) {
    (void)notif;
    return 0;
}

#endif /* Platform selection */

#endif /* CHANDRA_XS_IMPLEMENTATION */

#endif /* CHANDRA_NOTIFY_H */
