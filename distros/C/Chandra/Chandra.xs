/*
 * Chandra.xs — Root XS file
 *
 * Thin wrapper: includes shared header (which provides all static
 * C functions when WEBVIEW_IMPLEMENTATION is defined), then pulls
 * in per-module XS fragments via INCLUDE:.
 */

#define WEBVIEW_IMPLEMENTATION
#define CHANDRA_XS_IMPLEMENTATION
#define CHANDRA_WINDOW_IMPLEMENTATION
#include "include/chandra/chandra.h"
#include "include/chandra/chandra_error.h"
#include "include/chandra/chandra_bind.h"
#include "include/chandra/chandra_element.h"
#include "include/chandra/chandra_devtools.h"
#include "include/chandra/chandra_internal.h"
#include "include/chandra/chandra_socket_common.h"
#include "include/chandra/chandra_socket_token.h"
#include "include/chandra/chandra_socket_hub.h"
#include "include/chandra/chandra_socket_client.h"
#include "include/chandra/chandra_notify.h"
#include "include/chandra/chandra_store.h"
#include "include/chandra/chandra_log.h"
#include "include/chandra/chandra_assets.h"
#include "include/chandra/chandra_clipboard.h"
#include "include/chandra/chandra_contextmenu.h"
#include "include/chandra/chandra_window.h"
#include "include/chandra/chandra_splash.h"
#include "include/chandra/chandra_form.h"

/* Window registry - maps native wid to Perl SV* objects */
static HV *_window_registry = NULL;
static IV _window_id_counter = 0;

static void _ensure_registry(pTHX) {
    if (!_window_registry) {
        _window_registry = newHV();
    }
}

static void _register_window(pTHX_ IV wid, SV *obj) {
    _ensure_registry(aTHX);
    hv_store(_window_registry, (char*)&wid, sizeof(wid), SvREFCNT_inc(obj), 0);
}

static void _unregister_window(pTHX_ IV wid) {
    _ensure_registry(aTHX);
    hv_delete(_window_registry, (char*)&wid, sizeof(wid), G_DISCARD);
}

static SV *_get_window(pTHX_ IV wid) {
    SV **svp;
    _ensure_registry(aTHX);
    svp = hv_fetch(_window_registry, (char*)&wid, sizeof(wid), 0);
    return svp ? *svp : NULL;
}

static IV _get_window_count(pTHX) {
    _ensure_registry(aTHX);
    return HvKEYS(_window_registry);
}

/* Macros to call the static functions with aTHX */
#define ENSURE_REGISTRY() _ensure_registry(aTHX)
#define REGISTER_WINDOW(wid, obj) _register_window(aTHX_ wid, obj)
#define UNREGISTER_WINDOW(wid) _unregister_window(aTHX_ wid)
#define GET_WINDOW(wid) _get_window(aTHX_ wid)
#define GET_WINDOW_COUNT() _get_window_count(aTHX)

MODULE = Chandra    PACKAGE = Chandra

INCLUDE: xs/core.xs
INCLUDE: xs/tray.xs
INCLUDE: xs/error.xs
INCLUDE: xs/event.xs
INCLUDE: xs/bridge.xs
INCLUDE: xs/bind.xs
INCLUDE: xs/element.xs
INCLUDE: xs/dialog.xs
INCLUDE: xs/devtools.xs
INCLUDE: xs/hotreload.xs
INCLUDE: xs/notify.xs

INCLUDE: xs/protocol.xs

INCLUDE: xs/shortcut.xs

INCLUDE: xs/socket_connection.xs
INCLUDE: xs/socket_token.xs
INCLUDE: xs/socket_hub.xs
INCLUDE: xs/socket_client.xs

INCLUDE: xs/app.xs

INCLUDE: xs/assets.xs
INCLUDE: xs/clipboard.xs
INCLUDE: xs/dragdrop.xs
INCLUDE: xs/contextmenu.xs
INCLUDE: xs/store.xs
INCLUDE: xs/log.xs
INCLUDE: xs/window.xs
INCLUDE: xs/splash.xs
INCLUDE: xs/form.xs
