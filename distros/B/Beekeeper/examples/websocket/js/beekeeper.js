/*

    Beekeeper client (JSON-RPC over MQTT)

    Copyright 2015-2023 José Micó

    For protocol references see: 
    - https://mqtt.org/mqtt-specification
    - https://www.jsonrpc.org/specification

    This requires the MQTT.js library:
    - https://github.com/mqttjs/MQTT.js

    let bkpr = new BeekeeperClient;

    bkpr.connect({
        url:       "ws://localhost:18080/mqtt",
        username:  "guest",
        password:  "guest",
        on_connect: function() {...}
    });

    bkpr.send_notification({
        method: "test.foo",
        params: { foo: "bar" }
    });

    bkpr.call_remote_method({
        method:    "test.bar",
        params:     { foo: "baz" },
        on_success: function(result) {...},
        on_error:   function(error) {...}
    });

    bkpr.accept_notifications({
        method:    "test.foo.*",
        on_receive: function(params) {...}
    });

    bkpr.accept_remote_calls({
        method:    "test.bar",
        on_receive: function(params) {...}
    });
*/

function BeekeeperClient () { return {

    mqtt: null,
    host: null,
    client_id: null,
    response_topic: null,
    request_seq: 1,
    subscr_seq: 1,
    pending_req: {},
    subscr_cb: {},
    subscr_re: {},

    connect: function(args) {

        const This = this;

        if (!this.client_id) this._generate_client_id();

        if ('debug' in args) this.debug(args.debug);

        this._debug(`Connecting to MQTT broker at ${args.url}`);

        // It is possible to iterate over a list of servers specifying:
        // url: [{ host: 'localhost', port: 1883 }, ... ]

        // Connect to MQTT broker using websockets
        this.mqtt = mqtt.connect( args.url, {
            username: args.username || 'guest',
            password: args.password || 'guest',
            clientId: this.client_id,
            protocolVersion: 5,
            clean: true,
            keepalive: 60,
            reconnectPeriod: 1000,
            connectTimeout: 30 * 1000
        });

        this.mqtt.on('connect', function (connack) {
            This.host = This.mqtt.options.host;
            This._debug("Connected to MQTT broker at " + This.host);
            This._create_response_topic();
            if (args.on_connect) args.on_connect(connack.properties);
        });

        this.mqtt.on('reconnect', function () {
            // Emitted when a reconnect starts
            This._debug("Reconnecting...");
        });

        this.mqtt.on('close', function () {
            // Emitted after a disconnection
            This._debug("Disconnected");
        });

        this.mqtt.on('disconnect', function (packet) {
            // Emitted after receiving disconnect packet from broker
            This._debug("Disconnected by broker");
        });

        this.mqtt.on('offline', function () {
            // Emitted when the client goes offline
            This._debug("Client offline");
        });

        this.mqtt.on('error', function (error) {
            // Emitted when the client cannot connect
            This._debug(error);
        });

        this.mqtt.on('message', function (topic, message, packet) {

            let jsonrpc;
            try {
                if (message[0] == 0x78) {
                    // Deflated JSON
                    let json = pako.inflate(message, {to:'string'});
                    jsonrpc = JSON.parse(json);
                }
                else {
                    jsonrpc = JSON.parse(message.toString());
                }
            } catch (e) { throw `Received invalid JSON: ${e}` }
            This._debug(`Got  << ${message}`);

            const subscr_id = packet.properties.subscriptionIdentifier;
            const subscr_cb = This.subscr_cb[subscr_id];

            subscr_cb(jsonrpc, packet.properties);
        });
    },

    _generate_client_id: function() {
        // Generate a random client id (128+ bits)
        this.client_id = '';
        const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        const random = new Uint32Array(22);
        window.crypto.getRandomValues(random);
        for (let i = 0; i < random.length; i++) {
            this.client_id += chars.charAt(random[i] % 62);
        }
    },

   _debug: function () {},
    debug: function(enabled) {
        if (enabled) {
            this._debug = function (msg) { console.log(`Beekeeper: ${msg}`) };
        }
        else {
            this._debug = function () {};
        }
    },

    on_error: null,
   _on_error: function (error) {
        if (!this.on_error) return;
        try { this.on_error(error) }
        catch(e) { this._debug(`Uncaught exception into on_error handler: ${e}`) }
    },

    send_notification: function(args) {

        // This is included for reference, but please note that frontend clients
        // should *not* be allowed to publish to msg/frontend/*, as that would 
        // allow a malicious actor to inject messages to other users

        if (!this.mqtt.connected) throw "Not connected to MQTT broker";

        const json = JSON.stringify({
            jsonrpc: "2.0",
            method: args.method,
            params: args.params
        });

        this._debug(`Sent >> ${json}`);

        this.mqtt.publish(
            'msg/frontend/' + args.method.replace(/\./g,'/'),
            json,
            {}
        );
    },

    accept_notifications: function (args) {

        if (!this.mqtt.connected) throw "Not connected to MQTT broker";

        const subscr_id = this.subscr_seq++;
        const on_receive = args.on_receive;
        const This = this;

        this.subscr_cb[subscr_id] = function(jsonrpc, packet_prop) {

            // Incoming notification

            try { on_receive( jsonrpc.params, packet_prop ) }
            catch(e) { This._debug(`Uncaught exception into on_receive callback of ${jsonrpc.method}: ${e}`) }
        };

        this.subscr_re[subscr_id] = new RegExp('^' + args.method.replace(/\./g,'\\.').replace(/\*/g,'.+') + '$');

        // Private notifications are received on response_topic subscription
        if (args.private) return;

        const topic = 'msg/frontend/' + args.method.replace(/\./g,'/').replace(/\*/g,'#');

        this.mqtt.subscribe(
            topic,
            { properties: { subscriptionIdentifier: subscr_id }},
            function (err, granted) {
                if (err) throw `Failed to subscribe to ${topic}: ${err}`;
            }
        );
    },

    call_remote_method: function(args) {

        if (!this.mqtt.connected) throw "Not connected to MQTT broker";

        const req_id = this.request_seq++;

        const json = JSON.stringify({
            jsonrpc: "2.0",
            method: args.method,
            params: args.params,
            id:     req_id
        });

        const QUEUE_LANES = 2;
        const topic  = 'req/backend-' + Math.floor( Math.random() * QUEUE_LANES + 1 );
        const fwd_to = 'req/backend/' + args.method.replace(/\.[\w-]+$/,'').replace(/\./g,'/');

        this.mqtt.publish(
            topic,
            json,
            { properties: {
                responseTopic: this.response_topic,
                userProperties: { fwd_to: fwd_to }
            }}
        );

        this._debug("Sent >> " + json);

        this.pending_req[req_id] = {
            method:     args.method,
            on_success: args.on_success,
            on_error:   args.on_error,
            timeout:    null
        };

        const This = this;

        this.pending_req[req_id].timeout = setTimeout( function() {
            delete This.pending_req[req_id];
            This._debug(`Call to ${args.method} timed out`);
            const err_resp = { code: -32603, message: "Request timeout" };
            if (args.on_error) {
                try { args.on_error(err_resp) }
                catch(e) { This._debug(`Uncaught exception into on_error callback of ${args.method}: ${e}`) }
            }
            else {
                This._on_error(err_resp);
            }
        }, (args.timeout || 30) * 1000);
    },

    _create_response_topic: function() {

        const response_topic = 'priv/' + this.client_id;
        this.response_topic = response_topic;

        const subscr_id = this.subscr_seq++;
        const This = this;

        this.subscr_cb[subscr_id] = function(jsonrpc, packet_prop) {

            if (!jsonrpc.id) {

                // Incoming private notification

                let on_receive;
                for (let subscr_id in This.subscr_re) {
                    if (jsonrpc.method.match( This.subscr_re[subscr_id] )) {
                        on_receive = This.subscr_cb[subscr_id];
                        break;
                    }
                }

                if (on_receive) {
                    try { on_receive( jsonrpc, packet_prop ) }
                    catch(e) { This._debug(`Uncaught exception into on_receive callback of ${jsonrpc.method}: ${e}`) }
                }
                else {
                    This._debug(`Received unhandled private notification ${jsonrpc.method}`);
                }

                return;
            }

            // Incoming remote call response

            const resp = jsonrpc;
            const req = This.pending_req[resp.id];
            delete This.pending_req[resp.id];
            if (!req) return;

            clearTimeout(req.timeout);

            if ('result' in resp) {
                if (req.on_success) {
                    try { req.on_success( resp.result, packet_prop ) }
                    catch(e) { This._debug(`Uncaught exception into on_success callback of ${req.method}: ${e}`) }
                }
            }
            else {
                This._debug(`Error response from ${req.method} call: ${resp.error.message}`);
                if (req.on_error) {
                    try { req.on_error( resp.error, packet_prop ) }
                    catch(e) { This._debug(`Uncaught exception into on_error callback of ${req.method}: ${e}`) }
                }
                else {
                    This._on_error(resp.error);
                }
            }
        };

        this.mqtt.subscribe(
            response_topic,
            { properties: { subscriptionIdentifier: subscr_id }},
            function (err, granted) {
                if (err) throw `Failed to subscribe to ${response_topic}: ${err}`;
            }
        );
    },

    accept_remote_calls: function(args) {

        // This is included for reference, but please note that frontend clients
        // should *not* be allowed to even connect to the backend broker, let alone
        // consume from req/backend/*, as that would allow a malicious actor to 
        // disrupt services or steal other users credentials

        if (!this.mqtt.connected) throw "Not connected to MQTT broker";

        const subscr_id = this.subscr_seq++;
        const on_receive = args.on_receive;
        const This = this;

        this.subscr_cb[subscr_id] = function(jsonrpc, packet_prop) {

            // Incoming remote request

            let json;

            try {
                let result = on_receive( jsonrpc.params, packet_prop );
                json = JSON.stringify({
                    jsonrpc: "2.0",
                    result: result,
                    id: req.id
                });
            }
            catch (e) {
                json = JSON.stringify({
                    jsonrpc: "2.0",
                    error: { code: -32603, message: e.message },
                    id: req.id
                });
            }

            This.mqtt.publish(
                packet_prop.responseTopic,
                json,
                {}
            );

            This._debug(`Sent >> ${json}`);
        };

        const topic = '$share/BKPR/req/backend/' + args.method.replace(/\./g,'/');

        this.mqtt.subscribe(
            topic,
            { properties: { subscriptionIdentifier: subscr_id }},
            function (err, granted) {
                if (err) throw `Failed to subscribe to ${topic}: ${err}`;
            }
        );
    },
}};
