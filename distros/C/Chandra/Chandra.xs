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
#include "include/chandra/chandra_bridge_ext.h"
#include "include/chandra/chandra_canvas.h"

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

/* Toast state */
static int _toast_id = 0;
static int _toast_injected = 0;

/* Modal state */
static int _modal_id = 0;
static int _modal_injected = 0;

static const char *CHANDRA_TOAST_JS =
"(function(){"
"if(window.__chandraToast)return;"
"var c=document.createElement('div');"
"c.id='__chandra_toast_container';"
"c.style.cssText='position:fixed;top:16px;right:16px;z-index:99999;display:flex;flex-direction:column;gap:8px;pointer-events:none;max-width:380px;';"
"document.body.appendChild(c);"
"var t={};"
"var tc={"
"success:{bg:'var(--chandra-success,#4CAF50)',icon:'\\u2713'},"
"error:{bg:'var(--chandra-danger,#f44336)',icon:'\\u2717'},"
"warning:{bg:'var(--chandra-warning,#ff9800)',icon:'\\u26A0'},"
"info:{bg:'var(--chandra-info,#2196F3)',icon:'\\u2139'}"
"};"
"function show(id,msg,type,dur,act){"
"var o=tc[type]||tc.info;"
"var el=document.createElement('div');"
"el.id=id;el.className='chandra-toast chandra-toast-'+type;"
"el.style.cssText='pointer-events:auto;display:flex;align-items:center;gap:10px;padding:12px 16px;border-radius:var(--chandra-radius,6px);background:var(--chandra-surface,#1e1e1e);color:var(--chandra-text,#e0e0e0);box-shadow:var(--chandra-shadow,0 2px 8px rgba(0,0,0,0.3));border-left:4px solid '+o.bg+';opacity:0;transform:translateX(100%);transition:opacity 0.3s,transform 0.3s;font-size:0.9em;max-width:100%;';"
"var ic=document.createElement('span');"
"ic.style.cssText='font-size:1.2em;flex-shrink:0;';"
"ic.textContent=o.icon;el.appendChild(ic);"
"var bd=document.createElement('div');"
"bd.style.cssText='flex:1;min-width:0;';"
"bd.textContent=msg;el.appendChild(bd);"
"if(act&&act.label){"
"var btn=document.createElement('button');"
"btn.textContent=act.label;"
"btn.style.cssText='padding:4px 12px;border:1px solid var(--chandra-border,#333);border-radius:var(--chandra-radius,4px);background:transparent;color:var(--chandra-primary,#64B5F6);cursor:pointer;font-size:0.85em;flex-shrink:0;';"
"btn.onclick=function(e){e.stopPropagation();if(act.handler)window.chandra.invoke(act.handler,[]);dismiss(id);};"
"el.appendChild(btn);}"
"var cl=document.createElement('span');"
"cl.textContent='\\u00D7';"
"cl.style.cssText='cursor:pointer;opacity:0.5;font-size:1.2em;flex-shrink:0;padding:0 2px;';"
"cl.onclick=function(e){e.stopPropagation();dismiss(id);};"
"el.appendChild(cl);"
"el.onclick=function(){dismiss(id);};"
"while(c.children.length>=5){var ol=c.firstChild;if(ol)dismiss(ol.id);}"
"c.appendChild(el);t[id]=el;"
"requestAnimationFrame(function(){el.style.opacity='1';el.style.transform='translateX(0)';});"
"if(dur>0)setTimeout(function(){dismiss(id);},dur);}"
"function dismiss(id){"
"var el=t[id];if(!el)return;"
"el.style.opacity='0';el.style.transform='translateX(100%)';"
"setTimeout(function(){if(el.parentNode)el.parentNode.removeChild(el);delete t[id];},300);}"
"window.__chandraToast={show:show,dismiss:dismiss};"
"})();";

static const char *CHANDRA_MODAL_JS =
"(function(){"
"if(window.__chandraModal)return;"
"var overlay,activeModal;"
"function create(id,opts){"
"overlay=document.createElement('div');"
"overlay.id=id+'_overlay';"
"overlay.style.cssText='position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.5);z-index:99990;display:flex;align-items:center;justify-content:center;';"
"if(opts.backdrop!==false)overlay.onclick=function(e){if(e.target===overlay)close(id);};"
"var modal=document.createElement('div');"
"modal.id=id;"
"modal.style.cssText='background:var(--chandra-bg,#fff);border:1px solid var(--chandra-border,#e0e0e0);border-radius:var(--chandra-radius,6px);box-shadow:var(--chandra-shadow,0 4px 16px rgba(0,0,0,0.2));padding:0;min-width:320px;max-width:'+(opts.width||400)+'px;width:100%;opacity:0;transform:scale(0.95);transition:opacity 0.2s,transform 0.2s;';"
/* Title bar */
"if(opts.title){"
"var hdr=document.createElement('div');"
"hdr.style.cssText='padding:16px 20px 12px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid var(--chandra-border,#e0e0e0);';"
"var t=document.createElement('h3');"
"t.style.cssText='margin:0;font-size:1.1em;';t.textContent=opts.title;"
"hdr.appendChild(t);"
"if(opts.closable!==false){"
"var x=document.createElement('span');"
"x.textContent='\\u00D7';x.style.cssText='cursor:pointer;font-size:1.4em;opacity:0.5;padding:0 4px;';"
"x.onclick=function(){close(id);};hdr.appendChild(x);}"
"modal.appendChild(hdr);}"
/* Body */
"var body=document.createElement('div');"
"body.style.cssText='padding:16px 20px;';body.id=id+'_body';"
"if(opts.content)body.innerHTML=opts.content;"
"if(opts.message){var p=document.createElement('p');p.style.margin='0';p.textContent=opts.message;body.appendChild(p);}"
"if(opts.input){"
"var inp=document.createElement('input');"
"inp.type='text';inp.id=id+'_input';"
"inp.style.cssText='width:100%;margin-top:12px;padding:8px 10px;border:1px solid var(--chandra-input-border,#bdbdbd);border-radius:var(--chandra-radius,4px);background:var(--chandra-input-bg,#fff);color:var(--chandra-text,#212121);font-size:inherit;box-sizing:border-box;';"
"if(opts.input.label){var lb=document.createElement('label');lb.textContent=opts.input.label;lb.style.cssText='display:block;margin-top:12px;font-size:0.9em;color:var(--chandra-text-muted,#757575);';body.appendChild(lb);}"
"if(opts.input.value)inp.value=opts.input.value;"
"body.appendChild(inp);}"
"modal.appendChild(body);"
/* Footer with buttons */
"if(opts.buttons&&opts.buttons.length){"
"var ftr=document.createElement('div');"
"ftr.style.cssText='padding:12px 20px 16px;display:flex;gap:8px;justify-content:flex-end;border-top:1px solid var(--chandra-border,#e0e0e0);';"
"opts.buttons.forEach(function(b){"
"var btn=document.createElement('button');"
"btn.textContent=b.label;"
"var cls='chandra-btn';"
"if(b.cls)cls+=' chandra-btn-'+b.cls;"
"btn.className=cls;"
"btn.onclick=function(){"
"if(b.action==='close')close(id);"
"else if(b.handler){"
"var val=null;var inp=document.getElementById(id+'_input');if(inp)val=inp.value;"
"window.chandra.invoke(b.handler,[val]).then(function(){close(id);});"
"}"
"};"
"ftr.appendChild(btn);});"
"modal.appendChild(ftr);}"
"overlay.appendChild(modal);"
"document.body.appendChild(overlay);"
"activeModal=id;"
"requestAnimationFrame(function(){modal.style.opacity='1';modal.style.transform='scale(1)';});"
"var inp=document.getElementById(id+'_input');if(inp)setTimeout(function(){inp.focus();inp.select();},100);"
"}"
"function close(id){"
"var ov=document.getElementById(id+'_overlay');"
"if(!ov)return;"
"var m=document.getElementById(id);"
"if(m){m.style.opacity='0';m.style.transform='scale(0.95)';}"
"setTimeout(function(){if(ov.parentNode)ov.parentNode.removeChild(ov);},200);"
"activeModal=null;}"
"window.__chandraModal={create:create,close:close};"
"})();";

MODULE = Chandra    PACKAGE = Chandra

INCLUDE: xs/core.xs
INCLUDE: xs/tray.xs
INCLUDE: xs/error.xs
INCLUDE: xs/event.xs
INCLUDE: xs/bridge.xs
INCLUDE: xs/bridge_extension.xs
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
INCLUDE: xs/canvas.xs
INCLUDE: xs/toast.xs
INCLUDE: xs/modal.xs
