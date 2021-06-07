
function Calculator () { return {

    bkpr: null,

    connect: function() {

        const This = this;

        this.bkpr = new BeekeeperClient;

        this.bkpr.connect({

            url:        CONFIG.url,       // "ws://localhost:8000/mqtt"
            username:   CONFIG.username,  // "frontend"
            password:   CONFIG.password,  // "abc123"
            debug:      CONFIG.debug,

            on_connect: function() {
                This.init();
            }
        });
    },

    init: function() {

        const This = this;

        const cmdInput = document.getElementById('expr');
        cmdInput.addEventListener('input', function(e) {
            This.eval_expr();
        });

        This.eval_expr();
    },

    _display: function(msg,style) {
        const div = document.getElementById('result');
        div.innerHTML = msg;
        div.className = style;
    },

    display_success: function(msg) {
        this._display(msg,'result success');
    },

    display_error: function(msg) {
        this._display(msg,'result error');
    },

    eval_expr: function() {

        const cmdInput = document.getElementById('expr');
        const expr = cmdInput.value;

        if (!expr.length) {
            this.display_success('');
            return;
        }

        const This = this;

        this.bkpr.call_remote_method({
            method: 'myapp.calculator.eval_expr', 
            params: { "expr": expr },
            on_success: function(result) {
                This.display_success(`${expr} = ${result}`);
            },
            on_error: function(error) {
                This.display_error(`${expr} : ${error.message}`);
            }
        });
    }
}};

const calc = new Calculator;
calc.connect();
