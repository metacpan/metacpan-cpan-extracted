// ==UserScript==
// @name         mcp-webbrowser support
// @namespace    https://dist.schmorp.de/mcp-webbrowser
// @description  AnyEvent::MCP's mcp-webbrowser support script
// @version      1.0.20261022.2
// @updateURL    https://dist.schmorp.de/mcp-webbrowser/1/mcp-webbrowser.user.js
// @downloadURL  https://dist.schmorp.de/mcp-webbrowser/1/mcp-webbrowser.user.js
// @match        *://*/*
// @run-at       document-start
// @inject-into  content
// @sandbox      DOM
// @grant        GM_addElement
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_getTab
// @grant        GM_saveTab
// @grant        GM_registerMenuCommand
// @grant        GM_unregisterMenuCommand
// @noframes
// ==/UserScript==

GM_getTab (stored => {
   const tab = stored || {};
   let menu;

   function allow () {
      menu = GM_registerMenuCommand ("Allow MCP access to this tab", () =>
         start (tab, menu, allow));
   }

   if (tab.mcp_webbrowser?.enabled)
      start (tab, undefined, allow);
   else
      allow ();
});

function start (tab, allow_menu, allow) {
   /////////////////////////////////////////////////////////////////////////////
   // Tab permission and identity are userscript-manager state, not origin state.

   function random_id () {
      return Array.from (crypto.getRandomValues (new Uint8Array (16)),
         byte => byte.toString (16).padStart (2, "0")).join ("");
   }

   let instance_id;

   let broker_url = "";
   let ws;
   let reconnect_timer;
   let active;
   let toggle_menu;
   let indicator_menus = [];
   let indicators;
   let status = "connecting";
   let offline_timer, grace_timer, title_observer, toast, toast_timer;

   const symbols = { connecting: "🟡", connected: "🟢", disconnected: "🔴" };
   const title_symbols = { connecting: "○", connected: "●", disconnected: "⊗" };
   const title_prefix = /^(?:\[(?:○|●|⊗)MCP\]\s*)+/;

   function plain_title (title) {
      return title.replace (title_prefix, "");
   }

   function update_title () {
      if (!document.head)
         return;

      const enabled = tab?.mcp_webbrowser?.enabled && indicators.title;
      if (enabled && !title_observer) {
         title_observer = new MutationObserver (update_title);
         title_observer.observe (document.head, { childList: true, subtree: true, characterData: true });
      } else if (!enabled && title_observer) {
         title_observer.disconnect ();
         title_observer = undefined;
      }

      const base = plain_title (document.title);
      const title = enabled ? `[${title_symbols[status]}MCP]${base ? " " + base : ""}` : base;
      if (document.title !== title)
         document.title = title;
   }

   function hide_toast () {
      clearTimeout (toast_timer);
      toast?.remove ();
      toast = undefined;
   }

   function show_toast () {
      if (!tab?.mcp_webbrowser?.enabled || !indicators.toast ||
          document.visibilityState !== "visible" || !document.documentElement)
         return;

      if (!toast) {
         try {
            toast = GM_addElement (document.documentElement, "div", {});
            if (!toast)
               throw new Error ("GM_addElement returned no element");
            toast.style.cssText = "position:fixed!important;right:12px!important;bottom:12px!important;"
               + "z-index:2147483647!important;background:#202020!important;color:white!important;"
               + "border:1px solid #888!important;border-radius:8px!important;padding:9px 13px!important;"
               + "font:13px sans-serif!important;pointer-events:none!important";
         } catch (err) {
            toast = undefined;
            console.warn ("mcp-webbrowser: cannot show indicator", err);
            return;
         }
      }
      toast.textContent = `${symbols[status]} MCP ${status}`;
      clearTimeout (toast_timer);
      if (status === "connected")
         toast_timer = setTimeout (hide_toast, 3000);
   }

   function set_status (next) {
      if (status === next)
         return;
      status = next;
      update_title ();
      register_menu ();
      if (toast)
         show_toast ();
   }

   function clear_status_timers () {
      clearTimeout (offline_timer);
      clearTimeout (grace_timer);
      offline_timer = grace_timer = undefined;
   }

   function awaiting_connection () {
      if (!tab?.mcp_webbrowser?.enabled)
         return;
      if (!offline_timer && status !== "disconnected")
         offline_timer = setTimeout (() => {
            offline_timer = undefined;
            set_status ("disconnected");
         }, 30000);
      if (status === "connected" && !grace_timer)
         grace_timer = setTimeout (() => {
            grace_timer = undefined;
            set_status ("connecting");
         }, 1500);
   }

   function connected () {
      clear_status_timers ();
      set_status ("connected");
   }

   function webbrowser_url (url, target) {
      const u = new URL (url);

      if (u.protocol === "http:")
         u.protocol = "ws:";
      else if (u.protocol === "https:")
         u.protocol = "wss:";
      else if (u.protocol !== "ws:" && u.protocol !== "wss:")
         throw new Error ("expected an HTTP or WebSocket URL");

      if (u.search || u.hash)
         throw new Error ("broker URL must not contain a query or fragment");

      u.pathname = u.pathname.replace (/\/+$/, "") + "/" + encodeURIComponent (target);

      return u.href;
   }

   function disconnect (revoke = false) {
      clearTimeout (reconnect_timer);
      reconnect_timer = undefined;

      const socket = ws;
      ws = undefined;

      for (const id in pending) {
         pending[id].cancel?.();
         delete pending[id];
      }

      if (socket) {
         if (revoke && socket.readyState === WebSocket.OPEN)
            socket.send (JSON.stringify (["quit"]));

         socket.close ();
      }
   }

   function inject_script (script, inserted, failed) {
      function inject () {
         try {
            GM_addElement (
               document.documentElement, "script", { textContent: script }
            ).remove ();
            inserted ();
         } catch (err) {
            failed (err);
         }
      }

      if (!document.documentElement) {
         document.addEventListener ("DOMContentLoaded", inject, { once: true });
         return () => document.removeEventListener ("DOMContentLoaded", inject);
      }

      inject ();
   }

   const pending = Object.create (null);
   let eval_id = 0;
   let compile_queue;

   // Cross the isolated-world boundary only for evaluation. Never pass the broker
   // URL or socket into page JavaScript. Results are data, not authentication.
   function execute_in_page (code, navigate, max_bytes) {
      const channel = "mcp-eval-" + instance_id + "-" + ++eval_id;
      const stop_channel = channel + "-stop";
      const { promise, resolve } = Promise.withResolvers ();
      const ready = compile_queue;
      const done = Promise.withResolvers ();
      compile_queue = done.promise;

      let compiled = false;
      let finished = false;
      let released = false;
      let startup_timer;
      let cancel_injection;

      function release () {
         if (!released) {
            released = true;
            // A cancelled waiter must not let its successor overtake its predecessor.
            ready.then (() => done.resolve ());
         }
      }

      function cleanup () {
         window.removeEventListener (channel, receive);
         clearTimeout (startup_timer);
         cancel_injection?.();
         window.dispatchEvent (new CustomEvent (stop_channel));
      }

      function finish (success, value) {
         if (finished)
            return;

         finished = true;
         cleanup ();
         release ();
         resolve ([success, value]);
      }

      function receive (ev) {
         let reply;

         try {
            reply = JSON.parse (ev.detail);
         } catch (err) {
            finish (false, "Invalid page evaluation result: " + err);
            return;
         }

         if (reply[0] === "compiled") {
            compiled = true;
            clearTimeout (startup_timer);
            release ();
         } else
            finish (reply[0] === "syntax-error" ? false : reply[0], reply[1]);
      }

      function start () {
         if (finished)
            return;

         window.addEventListener (channel, receive);

         // A separate, known-good page-world script can report parsing failures
         // even when the following source never executes.
         try {
            cancel_injection = inject_script (`
               {
                  const channel = ${JSON.stringify (channel)};
                  const stop_channel = ${JSON.stringify (stop_channel)};

                  const cleanup = () => {
                     window.removeEventListener ("error", on_error, true);
                     window.removeEventListener (channel, on_compiled);
                     window.removeEventListener (stop_channel, cleanup);
                  };
                  const on_compiled = ev => {
                     if (ev.detail === '["compiled"]')
                        cleanup ();
                  };
                  const on_error = ev => {
                     if (ev.error?.name !== "SyntaxError" && !/SyntaxError/.test (ev.message || ""))
                        return;

                     const message = ev.message +
                        (ev.filename ? " (" + ev.filename + ":" + ev.lineno + ":" + ev.colno + ")" : "");
                     cleanup ();
                     window.dispatchEvent (new CustomEvent (channel, {
                        detail: JSON.stringify (["syntax-error", message]),
                     }));
                  };

                  window.addEventListener ("error", on_error, true);
                  window.addEventListener (channel, on_compiled);
                  window.addEventListener (stop_channel, cleanup);
               }
            `, () => {
               // Inject only after the error listener is installed.
               Promise.resolve ().then (() => {
                  if (finished)
                     return;

                  try {
                     cancel_injection = inject_script (`
                        {
                           let navigate_cb;
                           const report = (success, value) => {
                              window.navigation?.removeEventListener ("navigatesuccess", navigate_cb);

                              let detail;
                              try {
                                 detail = JSON.stringify ([success, value]);
                                 const bytes = new TextEncoder ().encode (detail).length;
                                 if (bytes > ${max_bytes})
                                    detail = JSON.stringify ([false,
                                       "Browser result too large (" + bytes + " bytes; max " + ${max_bytes} + ")"]);
                              } catch (err) {
                                 detail = JSON.stringify ([false, "Cannot serialize result: " + err]);
                              }

                              window.dispatchEvent (new CustomEvent (${JSON.stringify (channel)}, { detail }));
                           };

                           const fn = async () =>
${code}
                           ;

                           if (${navigate} && window.navigation) {
                              navigate_cb = () => report (true, { url: location.href, title: document.title });
                              navigation.addEventListener ("navigatesuccess", navigate_cb);
                              window.addEventListener (${JSON.stringify (stop_channel)},
                                 () => navigation.removeEventListener ("navigatesuccess", navigate_cb),
                                 { once: true });
                           }

                           window.dispatchEvent (new CustomEvent (${JSON.stringify (channel)}, {
                              detail: '["compiled"]',
                           }));

                           Promise.resolve ().then (fn).then (
                              value => {
                                 if (!${navigate}) {
                                    if (typeof value === "function")
                                       report (false, "Cannot return function; pass CODE, not async () => CODE");
                                    else if (typeof value === "symbol")
                                       report (false, "Cannot return symbol; expected JSON value");
                                    else
                                       report (true, value === undefined ? null : value);
                                 }
                              },
                              err => report (false, String (err))
                           );
                        }
                        //# sourceURL=mcp-webbrowser-eval-${eval_id}
                     `, () => {
                        if (!compiled && !finished)
                           startup_timer = setTimeout (() => finish (false,
                              "Page code did not start (syntax error or blocked injection)"), 200);
                     }, err => finish (false, "Cannot inject page code: " + err));
                  } catch (err) {
                     finish (false, "Cannot inject page code: " + err);
                  }
               });
            }, err => finish (false, "Cannot install page error listener: " + err));
         } catch (err) {
            finish (false, "Cannot install page error listener: " + err);
         }
      }

      ready.then (start);

      return {
         promise,
         cancel: () => finish (false, "Browser execution cancelled"),
      };
   }

   function start_execution (socket, id, code, navigate, max_bytes = 16 * 1024) {
      console.log ("mcp-webbrowser " + (navigate ? "navigate" : "execute") + " #" + id + ":", code);
      const call = execute_in_page (code, navigate, max_bytes);
      pending[id] = call;

      call.promise.then (([success, value]) => {
         if (pending[id] !== call || ws !== socket)
            return;

         delete pending[id];

         if (success && navigate)
            value.title = plain_title (value.title);
         const reply = success && navigate
            ? ["navigated", id, value] : ["reply", id, success, value];
         let message = JSON.stringify (reply);
         const bytes = new TextEncoder ().encode (message).length;
         if (bytes > max_bytes)
            message = JSON.stringify (["reply", id, false,
               "Browser result too large (" + bytes + " bytes; max " + max_bytes + ")"]);
         socket.send (message);
      });
   }

   function add_element (socket, id, args) {
      try {
         const parent = args.parent
            ? document.querySelector (args.parent) : document.documentElement;
         if (!parent)
            throw new Error ("Element parent not found: " + (args.parent || "document root"));

         // GM_addElement applies initial properties before insertion, important
         // for CSP-sensitive style/script elements.
         const element = GM_addElement (parent, args.tag, {
            ...args.attributes, ...args.properties,
         });
         if (!element)
            throw new Error ("GM_addElement returned no element");
         for (const [name, value] of Object.entries (args.attributes || {}))
            element.setAttribute (name, value);

         socket.send (JSON.stringify (["reply", id, true,
            { tag: element.localName, id: element.getAttribute ("id") }]));
      } catch (err) {
         socket.send (JSON.stringify (["reply", id, false, String (err)]));
      }
   }

   function connect () {
      if (ws || !tab?.mcp_webbrowser?.enabled || !broker_url)
         return;

      awaiting_connection ();

      clearTimeout (reconnect_timer);
      reconnect_timer = undefined;

      let url;

      try {
         url = webbrowser_url (broker_url, tab.mcp_webbrowser.id);
      } catch (err) {
         console.warn ("mcp-webbrowser: invalid broker URL", err);
         return;
      }

      let socket;
      try {
         socket = new WebSocket (url);
      } catch (err) {
         console.warn ("mcp-webbrowser: cannot open WebSocket", err);
         reconnect_timer = setTimeout (connect, 5000);
         return;
      }
      ws = socket;

      socket.onopen = () => {
         if (socket !== ws)
            return;

         socket.send (JSON.stringify ([
            "mcp-webbrowser", 1, 0, instance_id,
            { url: location.href, title: plain_title (document.title) },
         ]));
      };

      socket.onmessage = ev => {
         if (socket !== ws)
            return;

         let msg;

         try {
            msg = JSON.parse (ev.data);
         } catch {
            socket.close (4002, "Invalid browser protocol");
            return;
         }


         if (!Array.isArray (msg)) {
            socket.close (4002, "Invalid browser protocol");
         } else if (msg[0] === "welcome") {
            if (msg[2] !== instance_id)
               socket.close (4002, "Wrong document instance");
            else
               connected ();
         } else if (msg[0] === "call" && (msg[2] === "execute" || msg[2] === "navigate")
                    && typeof msg[3]?.code === "string") {
            if (msg[2] === "navigate") {
               pending[msg[1]] = { code: msg[3].code, max_bytes: msg[3].max_bytes, phase: "ready" };
               socket.send (JSON.stringify (["ready", msg[1]]));
            } else {
               start_execution (socket, msg[1], msg[3].code, false, msg[3].max_bytes);
            }
         } else if (msg[0] === "call" && msg[2] === "add_element") {
            add_element (socket, msg[1], msg[3]);
         } else if (msg[0] === "proceed") {
            const call = pending[msg[1]];

            if (!call || call.phase !== "ready") {
               socket.close (4002, "Unexpected navigation proceed");
            } else {
               delete pending[msg[1]];
               start_execution (socket, msg[1], call.code, true, call.max_bytes);
            }
         } else if (msg[0] === "cancel") {
            pending[msg[1]]?.cancel?.();
            delete pending[msg[1]];
         } else {
            socket.close (4002, "Unknown browser message");
         }
      };

      socket.onclose = () => {
         if (socket !== ws)
            return;

         for (const id in pending) {
            pending[id].cancel?.();
            delete pending[id];
         }
         ws = undefined;

         if (tab?.mcp_webbrowser?.enabled) {
            awaiting_connection ();
            reconnect_timer = setTimeout (connect, 5000);
         }
      };
   }

   function configure_broker () {
      const value = prompt ("mcp-webbrowser --print-url (empty to disable):", broker_url);

      if (value === null)
         return false;

      const url = value.trim ();

      try {
         if (url)
            webbrowser_url (url, "test");
      } catch (err) {
         alert (err.message);
         return false;
      }

      broker_url = url;
      GM_setValue ("mcp-webbrowser-url", broker_url);
      disconnect ();
      if (tab?.mcp_webbrowser?.enabled) {
         clear_status_timers ();
         set_status (broker_url ? "connecting" : "disconnected");
      }
      connect ();

      return !!broker_url;
   }

   function register_menu () {
      if (toggle_menu !== undefined)
         GM_unregisterMenuCommand (toggle_menu);
      for (const id of indicator_menus)
         GM_unregisterMenuCommand (id);
      indicator_menus = [];

      toggle_menu = GM_registerMenuCommand (
         `Disconnect MCP access to this tab (${status})`,
         () => {
            tab.mcp_webbrowser.enabled = false;
            GM_saveTab (tab);
            deactivate (true);
            GM_unregisterMenuCommand (toggle_menu);
            for (const id of indicator_menus)
               GM_unregisterMenuCommand (id);
            GM_unregisterMenuCommand (configure_menu);
            allow ();
         }
      );

      for (const [key, label] of [["title", "Tab title"], ["toast", "Toast on tab activation"]])
         indicator_menus.push (GM_registerMenuCommand (
            (indicators[key] ? "✓ " : "  ") + "MCP indicator: " + label,
            () => {
               GM_setValue ("mcp-webbrowser-indicator-" + key, indicators[key] = !indicators[key]);
               update_title ();
               if (!indicators.toast) hide_toast ();
               register_menu ();
            }
         ));
   }

   function send_state () {
      if (ws?.readyState === WebSocket.OPEN)
         ws.send (JSON.stringify (["state", { url: location.href, title: plain_title (document.title) }]));
   }

   function on_dom_ready () {
      update_title ();
      show_toast ();
      send_state ();
   }

   function on_visibilitychange () {
      if (document.visibilityState === "visible")
         show_toast ();
      else
         hide_toast ();
   }

   function on_pagehide () {
      disconnect ();
      awaiting_connection ();
   }

   function activate () {
      if (active)
         return;
      active = true;
      instance_id ??= random_id ();
      compile_queue ??= Promise.resolve ();

      document.addEventListener ("DOMContentLoaded", on_dom_ready);
      document.addEventListener ("visibilitychange", on_visibilitychange);
      window.addEventListener ("popstate", send_state);
      window.addEventListener ("hashchange", send_state);
      window.navigation?.addEventListener ("navigatesuccess", send_state);
      window.addEventListener ("pagehide", on_pagehide);
      window.addEventListener ("pageshow", connect);

      connect ();
      update_title ();
      if (document.readyState !== "loading")
         show_toast ();
   }

   function deactivate (revoke = false) {
      if (active) {
         active = false;
         document.removeEventListener ("DOMContentLoaded", on_dom_ready);
         document.removeEventListener ("visibilitychange", on_visibilitychange);
         window.removeEventListener ("popstate", send_state);
         window.removeEventListener ("hashchange", send_state);
         window.navigation?.removeEventListener ("navigatesuccess", send_state);
         window.removeEventListener ("pagehide", on_pagehide);
         window.removeEventListener ("pageshow", connect);
      }
      clear_status_timers ();
      hide_toast ();
      disconnect (revoke);
      update_title ();
   }

   broker_url = GM_getValue ("mcp-webbrowser-url", "");
   indicators = {
      title: GM_getValue ("mcp-webbrowser-indicator-title", true),
      toast: GM_getValue ("mcp-webbrowser-indicator-toast", true),
   };

   if (!tab.mcp_webbrowser?.enabled) {
      if (!broker_url && !configure_broker ())
         return;

      tab.mcp_webbrowser ??= { id: random_id () };
      tab.mcp_webbrowser.enabled = true;
      GM_saveTab (tab);
   }

   if (allow_menu !== undefined)
      GM_unregisterMenuCommand (allow_menu);

   const configure_menu = GM_registerMenuCommand ("Configure MCP broker URL", configure_broker);
   register_menu ();
   activate ();
}

