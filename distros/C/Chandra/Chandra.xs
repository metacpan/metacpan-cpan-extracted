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
#include "include/chandra/chandra_socket_hub.h"
#include "include/chandra/chandra_socket_client.h"
#include "include/chandra/chandra_notify.h"
#include "include/chandra/chandra_store.h"
#include "include/chandra/chandra_window.h"

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
INCLUDE: xs/socket_hub.xs
INCLUDE: xs/socket_client.xs

INCLUDE: xs/app.xs

INCLUDE: xs/store.xs
