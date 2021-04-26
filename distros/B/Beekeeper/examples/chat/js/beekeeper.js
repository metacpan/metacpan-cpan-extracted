/*

    Beekeeper client (JSON-RPC over STOMP)

    Copyright 2015 José Micó

    For protocol references see: 
    - http://www.jsonrpc.org/specification
    - http://stomp.github.com/stomp-specification-1.2.html

    This uses the STOMP.js library originally written by Jeff Mesnil
    - http://www.jmesnil.net/stomp-websocket/doc/
    - https://github.com/stomp-js/stomp-websocket

    var rpc = new JSON_RPC;

    rpc.connect({
        login:    "test",
        password: "abc123",
        url:      "ws://localhost:15674/ws",
        on_ready: function() {
            console.log('Connected');
        }
    });

    rpc.debug();

    rpc.notify({
        method: "test.foo",
        params: { foo: "bar" }
    });

    rpc.call({
        method: "test.bar",
        params: { foo: "baz" },
        on_success: function(result) {
            console.log(result);
        }
    });

    rpc.accept_notifications({
        method: "test.foo",
        on_receive: function(params) {
            console.log(params);
        }
    });

    rpc.accept_calls({
        method: "test.bar",
        on_receive: function(params) {
            return params;
        }
    });
*/

function JSON_RPC () { return {

    stomp: null,
    server: null,
    reply_queue: null,
    request_seq: 1,
    pending_req: {},
    callbacks: {},
    connected: false,

    connect: function(args) {

        var This = this;

        // Connect to STOMP broker using websockets
        this.stomp = Stomp.client(args.url);

        if (args.debug) {
            this.stomp.debug = function(str) { console.log(str) }
        }

        this.stomp.heartbeat.outgoing = 10000;
        this.stomp.heartbeat.incoming = 0;

        this.stomp.connect(
            {
                "login":    args.login    || 'guest', 
                "passcode": args.password || 'guest',
                "host":     args.vhost    || '/'
            },
            function(frame) {
                // Connect success
                clearTimeout(This.reconnTout);
                This.connected = true;
                This.server = frame.headers.server;
                This._create_reply_queue();
                if (args.on_ready) args.on_ready();
            },
            function(error) {
                // Connect error or error frame
                if (This.connected) console.log(error);
                This.connected = false;
                This.stomp.disconnect();
                This.reconnTout = setTimeout( function() {
                    This.connect(args);
                }, 1000);
            }
        );

        window.addEventListener("unload", function(evt) {
            This.stomp.disconnect();
        });
    },

    debug: function(enabled) {
        if (enabled == null || enabled) {
            this.stomp.debug = function(str) { console.log(str) }
            console.log("JSON-RPC debug enabled, all traffic is dumped to console");
        }
        else {
            this.stomp.debug = null;
            console.log("JSON-RPC debug disabled");
        }
    },

    notify: function(args) {

        if (!this.connected) {
            console.log("Not connected to STOMP broker");
            return;
        }

        var msg = {
            jsonrpc: "2.0",
            method: args.method,
            params: args.params
        };

        this.stomp.send(
            "/topic/msg." + args.method,
            {},
            JSON.stringify(msg)
        );
    },

    accept_notifications: function(args) {

        if (!this.connected) {
            console.log("Not connected to STOMP broker");
            return;
        }

        this.callbacks[args.method] = args.on_receive;

        this.stomp.subscribe(
            "/topic/msg.frontend." + args.method,
            function(message) {
                var msg = JSON.parse(message.body);  //TODO: catch parse exceptions
                try { args.on_receive(msg.params) }
                catch(e) { console.log("RPC: Exception into on_receive callback of '" + args.method + "': " + e) }
            }
        );
    },

    call: function(args) {

        if (!this.connected) {
            var err = { code: -32603, message: "Not connected to STOMP broker" };
            (args.on_error) ? args.on_error(err) : console.log(err.message);
            return;
        }

        var req = {
            jsonrpc: "2.0",
            method: args.method,
            params: args.params,
            id: this.request_seq++
        };

        var QUEUE_LANES = 2;

        this.stomp.send(
            "/queue/req.backend-" + Math.floor(Math.random()*QUEUE_LANES+1),
            {
                "reply-to": this.reply_queue,
                "x-forward-to": "/queue/req.backend." + args.method.replace(/\.[\w-]+$/,''),
             // "content-type": "application/json;charset=utf-8",
            },
            JSON.stringify(req)
        );

        this.pending_req[req.id] = {
            on_success: args.on_success,
            on_error: args.on_error,
            method: args.method,
            timeout: null
        };

        var This = this;

        this.pending_req[req.id].timeout = setTimeout( function() {
            delete This.pending_req[req.id];
            if (args.on_error) {
                try { args.on_error({ code: -32603, message: "RPC call timeout" }) }
                catch(e) { console.log("RPC: Exception into on_error callback of '" + args.method + "': " + e) }
            }
            else {
                console.log("RPC: Call to '" + args.method + "' timed out");
            }
        }, (args.timeout || 30) * 1000);
    },

    _create_reply_queue: function() {

        var This = this;
        var on_receive_reply = function(message) {
            var resp = JSON.parse(message.body);  //TODO: catch parse exceptions
            if (!resp.id) {
                // Unicasted notification
                var cb = This.callbacks[resp.method];
                if (cb) {
                    try { cb(resp.params) }
                    catch(e) { console.log("RPC: Exception into callback of '" + resp.method + "': " + e) }
                }
                else {
                    console.log("RPC: Received unhandled notification '" + args.method + "'");
                }
                return;
            }
            var req = This.pending_req[resp.id];
            delete This.pending_req[resp.id];
            if (!req) return;
            clearTimeout(req.timeout);
            if ("result" in resp) {
                if (req.on_success) {
                    try { req.on_success(resp.result) }
                    catch(e) { console.log("RPC: Exception into on_success callback of '" + req.method + "': " + e) }
                }
            }
            else {
                if (req.on_error) {
                    try { req.on_error(resp.error) }
                    catch(e) { console.log("RPC: Exception into on_error callback of '" + req.method + "': " + e) }
                }
                else {
                    console.log("RPC: Got error from '" + req.method + "' call: " + resp.error.message);
                }
            }
        };

        var sid = ''; for(;sid.length < 16;) sid += (Math.random() * 36 | 0).toString(36);

        this.reply_queue = "/temp-queue/tmp." + sid;

        if (this.server.match(/^RabbitMQ/)) {
            // HACK: Inject callback without actually subscribing, as RabbitMQ
            // automagically create temp-queues when used in reply-to headers
            // and subscribe to it with a subscription id equal to destination
            this.stomp.subscriptions[this.reply_queue] = on_receive_reply;
        }
        else {
            this.stomp.subscribe( this.reply_queue, on_receive_reply );
        }
    },

    accept_calls: function(args) {

        if (!this.connected) {
            console.log("Not connected to STOMP broker");
            return;
        }

        var This = this;

        this.stomp.subscribe(
            "/queue/req." + args.method, 
            function(message) {
                var req = JSON.parse(message.body);  //TODO: catch parse exceptions
                var resp;
                try {
                    var result = args.on_receive(req.params);
                    resp = {
                        jsonrpc: "2.0",
                        result: result,
                        id: req.id
                    };
                }
                catch (e) {
                    resp = {
                        jsonrpc: "2.0",
                        error: { code: -32603, message: e.message },
                        id: req.id
                    };
                }
                This.stomp.send(
                    message.headers['reply-to'],
                    {},
                    JSON.stringify(resp)
                );
            }
        );
    },
}};
