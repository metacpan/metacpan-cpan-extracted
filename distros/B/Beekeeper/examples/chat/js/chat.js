
function Chat () { return {

    rpc: null,

    connect: function() {

        var This = this;

        this.rpc = new JSON_RPC;
        this.rpc.connect({

            url:      CONFIG.url,       // "ws://localhost:15674/ws"
            login:    CONFIG.login,     // "frontend"
            password: CONFIG.password,  // "abc123"
            vhost:    CONFIG.vhost,     // "/frontend"
            debug:    CONFIG.debug,

            on_ready: function() {
                This.echo_info( 'Connected to ' + This.rpc.server + ' at ' + This.rpc.stomp.ws.url );
                This.echo_info( 'Debug enabled, STOMP traffic is being dumped to console' );
                This.init();

                This.login_user();
            }
        });
    },

    init: function() {

        var This = this;

        this.rpc.accept_notifications({
            method: "myapp.chat.message",
            on_receive: function(params) {
                var msg = params.message;
                var from = params.from;
                This.echo_mcast( from ? from + ": " + msg : msg );
            }
        });

        this.rpc.accept_notifications({
            method: "myapp.chat.pmessage",
            on_receive: function(params) {
                var msg = params.message;
                var from = params.from;
                This.echo_ucast( from ? from + ": " + msg : msg );
            }
        });

        var cmdInput = document.getElementById('cmd');
        cmdInput.onkeypress = function(e) {
            var event = e || window.event;
            var charCode = event.which || event.keyCode;
            if (charCode == '13') { // Enter
                This.exec_command();
                return false;
            }
        }
    },

    echo: function(msg,style) {
        var div = document.getElementById('chat');
        div.innerHTML = div.innerHTML + '<div class="'+style+'">' + msg + '</div>';
        div.scrollTop = div.scrollHeight;
    },

    echo_info: function(msg) {
        this.echo(msg,'info');
    },

    echo_error: function(msg) {
        this.echo(msg,'error');
    },

    echo_mcast: function(msg) {
        this.echo(msg,'mcast');
    },

    echo_ucast: function(msg) {
        this.echo(msg,'ucast');
    },

    login_user: function() {
        this.rpc.call({
            method: 'myapp.auth.login', 
            params: {
                "username": document.getElementById('username').value,
                "password": document.getElementById('password').value
            },
            on_error: function(error) {
                This.echo_error( "Error : " + error.data );
            }
        });
    },

    exec_command: function() {

        var cmdInput = document.getElementById('cmd');
        var cmd = cmdInput.value;
        if (!cmd.length) return;
        cmdInput.value = "";
        var This = this;

        if (params = cmd.match(/^\/logout\b/i)) {
            this.rpc.call({
                method: 'myapp.auth.logout', 
                params: { },
                on_error: function(error) {
                    This.echo_error( "Error : " + error.data );
                }
            });
        }
        else if (params = cmd.match(/^\/kick\s+(.*)/i)) {
            this.rpc.call({
                method: 'myapp.auth.kick', 
                params: { "username": params[1] },
                on_error: function(error) {
                    This.echo_error( "Error : " + error.data );
                }
            });
        }
        else if (params =  cmd.match(/^\/pm\s+(\w+)\s+(.*)/i)) {
            this.rpc.call({
                method: 'myapp.chat.pmessage', 
                params: { "to_user": params[1], "message": params[2] },
                on_error: function(error) {
                    This.echo_error( "Error : " + error.data );
                }
            });
        }
        else if (params = cmd.match(/^\/ping\b/i)) {
            var t0 = performance.now();
            this.rpc.call({
                method: 'myapp.chat.ping', 
                params: { },
                on_success: function(result) {
                    var took = Math.round(performance.now() - t0);
                    This.echo_info( 'Ping: ' + took + " ms" );
                },
                on_error: function(error) {
                    This.echo_error( "Error : " + error.data );
                }
            });
        }
        else {
            this.rpc.call({
                method: 'myapp.chat.message', 
                params: { "message": cmd },
                on_error: function(error) {
                    This.echo_error( "Error : " + error.data );
                }
            });
        }
    }
}};
