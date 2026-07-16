/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü

************************************************************************ */

/**
 * JSON-RPC 2.0 client for the CallBackery backend. Wraps
 * {@link qx.io.jsonrpc.Client} while preserving the historic callback-style
 * API (callAsync/callAsyncSmart/callAsyncSmartBusy with a (ret, exc, id)
 * handler) so existing call sites keep working unchanged.
 *
 * @use(qx.io.transport.Xhr)
 */
qx.Class.define("callbackery.data.Server", {
    extend: qx.core.Object,
    type: "singleton",

    properties: {
        sessionCookie: {
            init: null,
            nullable: true
        },
        url: {
            init: 'QX-JSON-RPC/',
            check: 'String'
        },
        timeout: {
            init: 180000,
            check: 'Integer'
        }
    },

    members: {
        __client: null,
        __sessionExpiredHandled: false,
        __commsErrorHandled: false,

        // Bounded silent retry for transient communication failures.
        _COMMS_RETRY_MAX: 3,
        _COMMS_RETRY_BACKOFF_MS: 1300,

        // Idempotent methods that are safe to retry silently. Writes
        // (processPluginData) and auth calls (login/logout) are excluded.
        _retrySafe: {
            ping: true, getBaseConfig: true, getUserConfig: true,
            getSessionCookie: true, getPluginConfig: true,
            getPluginData: true, validatePluginData: true
        },

        /**
         * Lazily create the JSON-RPC client and wire the session-cookie header.
         * @return {qx.io.jsonrpc.Client}
         */
        _getClient: function() {
            if (!this.__client) {
                var self = this;
                var transport = new qx.io.transport.Xhr(this.getUrl());
                var client = new qx.io.jsonrpc.Client(transport);
                client.addListener('outgoingRequest', function() {
                    // getTransportImpl() creates a fresh impl that the
                    // immediately-following Xhr.send() will pick up and reuse.
                    var impl = transport.getTransportImpl();
                    impl.setTimeout(self.getTimeout());
                    var cookie = self.getSessionCookie();
                    if (cookie) {
                        impl.setRequestHeader('X-Session-Cookie', cookie);
                    }
                });
                this.__client = client;
            }
            return this.__client;
        },

        /**
         * Recursively replace non-finite numbers (NaN, Infinity) with null in
         * plain data so the outgoing JSON is valid. qx.io.jsonrpc serialises
         * via qx.util.Serializer.toJson, which emits a literal "NaN"/"Infinity"
         * (invalid JSON the server rejects), whereas the legacy transport used
         * JSON.stringify, which already mapped these to null. An empty numeric
         * form field is the common source of NaN. Dates and qooxdoo objects are
         * passed through untouched so the serialiser can handle them.
         *
         * @param v {var} value to sanitise
         * @return {var} json-safe value
         */
        _jsonSafe: function(v) {
            if (typeof v === 'number') {
                return isFinite(v) ? v : null;
            }
            if (v === null || typeof v !== 'object' || v instanceof Date) {
                return v;
            }
            if (qx.lang.Type.isArray(v)) {
                var arr = [];
                for (var i = 0; i < v.length; i++) {
                    arr[i] = this._jsonSafe(v[i]);
                }
                return arr;
            }
            // only descend into plain data objects; leave qooxdoo objects intact
            if (v.constructor === Object) {
                var out = {};
                for (var k in v) {
                    if (Object.prototype.hasOwnProperty.call(v, k)) {
                        out[k] = this._jsonSafe(v[k]);
                    }
                }
                return out;
            }
            return v;
        },

        /**
         * Perform the actual JSON-RPC call and adapt the promise to the
         * historic (ret, exc, id) callback contract.
         *
         * @param handler {Function} callback(ret, exc, id)
         * @param methodName {String} remote method
         * @param params {Array} positional parameters
         */
        _send: function(handler, methodName, params) {
            var self = this;
            params = this._jsonSafe(params);
            var invoke = function(ret, exc, id) {
                try {
                    handler(ret, exc, id);
                }
                catch (e) {
                    if (window.console) {
                        window.console.error("Error while running CallAsync Handler", "ret:", ret, "exc", exc, "id", id, "e", e);
                    }
                }
            };
            this._getClient().sendRequest(methodName, params).then(
                function(result) {
                    // connectivity is healthy again
                    self.__commsErrorHandled = false;
                    invoke(result, null, null);
                },
                function(ex) {
                    // Only qx.io.exception.Protocol carries a server-supplied
                    // application code (e.g. 6 = login required, 7 = session
                    // expired). qx.io.exception.Transport/Cancel use their OWN
                    // small-integer code namespace (TIMEOUT=1, CANCELLED=5,
                    // FAILED=7) which must NOT be mistaken for an application
                    // code - otherwise a network/HTTP error (Transport FAILED=7)
                    // would trigger the session-expired page reload below.
                    var exc = {
                        code: ex && ex.code,
                        message: (ex && ex.message) || String(ex),
                        application: ex instanceof qx.io.exception.Protocol
                    };
                    invoke(null, exc, null);
                }
            );
        },

        /**
         * Handle a communication failure (non-application exception): bounded
         * silent retry for idempotent methods, otherwise one deduped dialog.
         *
         * @param resend {Function} resend(attempt) re-issues the original _send with that attempt number
         * @param methodName {String} the RPC method (for the retry-safe check)
         * @param attempt {Integer} 1-based attempt number that just failed
         */
        _handleCommsFailure: function(resend, methodName, attempt) {
            var self = this;
            if (this._retrySafe[methodName] && attempt < this._COMMS_RETRY_MAX) {
                qx.event.Timer.once(function() {
                    resend(attempt + 1);
                }, this, this._COMMS_RETRY_BACKOFF_MS);
                return;
            }
            // exhausted, or a non-retry-safe (write) call: one dialog owns the UX
            if (this.__commsErrorHandled) { return; }
            this.__commsErrorHandled = true;
            callbackery.ui.Busy.getInstance().vanish();
            var mb = callbackery.ui.MsgBox.getInstance();
            mb.addListenerOnce('choice', function(e) {
                if (e.getData() === 'reload') {
                    window.location.reload(true);
                }
                else { // retry
                    self.__commsErrorHandled = false;
                    resend(1);
                }
            });
            mb.commError(
                mb.tr('Connection problem'),
                mb.tr('The server is not responding or returned an unexpected answer.')
            );
        },

        /**
         * A callAsync handler which tries to login in the case of a permission
         * exception (code 6) and reloads on session expiry (code 7).
         *
         * @param handler {Function} the callback function.
         * @param methodName {String} the name of the method to call.
         */
        callAsync: function(handler, methodName) {
            var args = Array.prototype.slice.call(arguments, 2);
            if (methodName == 'login') {
                // login is special: no locale, no exception interception
                this._send(handler, methodName, args);
                return;
            }
            var origThis = this;
            var origArgs = args;
            var origMethod = methodName;
            var origHandler = handler;
            var localeMgr = qx.locale.Manager.getInstance();
            var wrapped = function(ret, exc, id) {
                // A reload is already committed for this expired session; keep
                // quiet so late-arriving failures don't pop error boxes.
                if (origThis.__sessionExpiredHandled) { return; }
                // only application (JSON-RPC protocol) errors carry the 6/7
                // codes the login/session logic reacts to; transport errors
                // fall through to the normal handler.
                if (exc && exc.application) {
                    switch (exc.code) {
                        case 6: {
                            // permission denied: prompt for login, then retry once
                            let login = callbackery.ui.Login.getInstance();
                            login.addListenerOnce('login', (e) => {
                                let r = e.getData();
                                origThis.setSessionCookie(r.sessionCookie);
                                // retry the original call (without re-wrapping)
                                origThis._send(origHandler, origMethod, origArgs);
                            });
                            login.open();
                            return;
                        }
                        case 7: {
                            // Session expired: exactly one reload prompt owns the
                            // UX; every other concurrent expired call is swallowed.
                            if (origThis.__sessionExpiredHandled) { return; }
                            origThis.__sessionExpiredHandled = true;
                            if (window.console) {
                                window.console.log("Session Expired. Prompting for reload.");
                            }
                            callbackery.ui.Busy.getInstance().vanish();
                            let mb = callbackery.ui.MsgBox.getInstance();
                            mb.addListenerOnce('choice', () => {
                                window.location.reload(true);
                            });
                            mb.sessionExpired(mb.tr('Session Expired'), mb.xtr(exc.message));
                            return;
                        }
                    }
                }
                if (exc && !exc.application) {
                    // communication failure -> retry (idempotent) or dialog
                    origThis._handleCommsFailure(
                        function(nextAttempt) { doSend(nextAttempt); },
                        origMethod,
                        currentAttempt
                    );
                    return;
                }
                origHandler(ret, exc, id);
            };
            var params = args.concat([{ qxLocale: localeMgr.getLocale() }]);
            // Per-call attempt counter (closure-local, so concurrent callAsync
            // invocations never clobber each other's retry state).
            var currentAttempt = 1;
            var doSend = function(attempt) {
                currentAttempt = attempt;
                origThis._send(wrapped, methodName, params);
            };
            doSend(1);
        },

        /**
         * A variant of callAsync which pops up server-generated error messages
         * automatically. The handler only ever receives a return value.
         *
         * @param handler {Function} the callback function.
         * @param methodName {String} the name of the method to call.
         */
        callAsyncSmart: function(handler, methodName) {
            var origHandler = handler;
            var superHandler = function(ret, exc, id) {
                if (exc) {
                    callbackery.ui.MsgBox.getInstance().exc(exc);
                } else {
                    origHandler(ret);
                }
            };
            var newArgs = Array.prototype.slice.call(arguments);
            newArgs[0] = superHandler;
            this.callAsync.apply(this, newArgs);
        },

        callAsyncSmartBusy: function(handler, methodName) {
            var origHandler = handler;
            var busy = callbackery.ui.Busy.getInstance();
            var superHandler = function(ret, exc, id) {
                busy.vanish();
                if (exc) {
                    callbackery.ui.MsgBox.getInstance().exc(exc);
                } else {
                    origHandler(ret);
                }
            };
            var newArgs = Array.prototype.slice.call(arguments);
            newArgs[0] = superHandler;
            busy.manifest('Running ' + methodName);
            this.callAsync.apply(this, newArgs);
        }
    }
});
