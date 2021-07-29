
function Chat () { return {

    bkpr: null,

    connect: function() {

        const This = this;

        this.bkpr = new BeekeeperClient;

        this.bkpr.connect({
            url:        CONFIG.url,       // "ws://localhost:18080/mqtt"
            username:   CONFIG.username,  // "frontend"
            password:   CONFIG.password,  // "abc123"
            debug:      CONFIG.debug,
            on_connect: function() { This.init() }
        });
    },

    init: function() {

        this.display_info(`Connected to ${this.bkpr.host}<br/>
                           JSON-RPC traffic is being dumped to console`);

        const names = ['Bob','Dave','Paul','Tom','Alice','Lisa','Lucy','Zoe'];
        document.getElementById('username').value = names[Math.floor(Math.random()*8)];
        document.getElementById('password').value = '12345';
        this.login_user();

        const This = this;

        this.bkpr.accept_notifications({
            method: "myapp.chat.message",
            on_receive: function(params) {
                const msg = params.message;
                const from = params.from;
                This.display_message(msg, from);
            }
        });

        this.bkpr.accept_notifications({
            method: "myapp.chat.pmessage",
            on_receive: function(params) {
                const msg = params.message;
                const from = params.from;
                This.display_private_message(msg, from);
            }
        });

        this.bkpr.on_error = function(error) {
            const msg = error.constructor === Object ? error.message : error;
            This.display_error(msg);
        }

        const cmdInput = document.getElementById('cmd');
        cmdInput.onkeypress = function(e) {
            const event = e || window.event;
            const charCode = event.which || event.keyCode;
            if (charCode == '13') { // Enter
                This.exec_command();
                return false;
            }
        }
    },

    display_bubble: function(msg, from, style) {
        const div = document.getElementById('chat');
        div.innerHTML = div.innerHTML + `<div class="bubble ${style}"><div class="sender">${from}</div>${msg}</div>`;
        div.scrollTop = div.scrollHeight;
    },

    display_info: function(msg) {
        this.display_bubble(msg, '', 'incoming info no_sender');
    },

    display_error: function(msg) {
        this.display_bubble(msg, '', 'incoming error no_sender');
    },

    display_message: function(msg, from) {
        const style = (from == this.username) ? 'outgoing no_sender' : 'incoming public';
        this.display_bubble(msg, from, style);
    },

    display_private_message: function(msg, from) {
        const style = (from == null) ? 'incoming private no_sender' : 'incoming private';
        this.display_bubble(msg, from, style);
    },

    login_user: function() {
        const This = this;
        const user = document.getElementById('username').value;
        const pass = document.getElementById('password').value;
        this.bkpr.call_remote_method({
            method: 'myapp.auth.login', 
            params: {
                "username": user,
                "password": pass
            },
            on_success: function(params) {
                This.username = user;
            }
        })
    },

    exec_command: function() {

        const cmdInput = document.getElementById('cmd');
        const cmd = cmdInput.value;
        if (!cmd.length) return;
        cmdInput.value = "";
        const This = this;
        let params;

        if (params = cmd.match(/^\/logout\b/i)) {
            this.bkpr.call_remote_method({
                method: 'myapp.auth.logout', 
                params: { }
            });
        }
        else if (params = cmd.match(/^\/kick\s+(.*)/i)) {
            this.bkpr.call_remote_method({
                method: 'myapp.auth.kick', 
                params: { "username": params[1] }
            });
        }
        else if (params =  cmd.match(/^\/pm\s+(\w+)\s+(.*)/i)) {
            const to_user = params[1];
            const msg = params[2];
            this.display_bubble(msg, `To ${to_user}`, 'outgoing');
            this.bkpr.call_remote_method({
                method: 'myapp.chat.pmessage', 
                params: { "to_user": to_user, "message": msg }
            });
        }
        else if (params = cmd.match(/^\/ping\b/i)) {
            const t0 = performance.now();
            this.bkpr.call_remote_method({
                method: 'myapp.chat.ping', 
                params: { },
                on_success: function(result) {
                    const took = Math.round(performance.now() - t0);
                    This.display_info( `Ping: ${took} ms` );
                }
            });
        }
        else {
            this.bkpr.call_remote_method({
                method: 'myapp.chat.message', 
                params: { "message": cmd }
            });
        }
    }
}};

const chat = new Chat;
chat.connect();
