/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPLv3 or Later
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */

/**
 * @asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
 * @asset(qx/icon/${qx.icontheme}/64/status/dialog-password.png)
 */

/**
 * Login Popup that performs authentication.
 */
qx.Class.define("callbackery.ui.Login", {
    extend : qx.ui.window.Window,
    type : 'singleton',

    construct : function() {
        this.base(arguments, this.tr("Login"));
        this.__iframe = this.__ensureIframe();
        // some browsers will be so nice to save the
        // content of the form elements if they appear inside a form AND
        // the form has a name (firefox comes to mind).
        var el = this.getContentElement();
        var form = new qx.html.Element('form',null,{name: 'cbLoginform', autocomplete: 'on'});
        form.insertBefore(el);
        el.insertInto(form);

        this.set({
            modal                   : true,
            showMinimize            : false,
            showMaximize            : false,
            showClose               : false,
            resizable               : false,
            allowGrowX              : true,
            allowShrinkX            : true,
            allowGrowY              : true,
            allowShrinkY            : true,
            contentPaddingLeft      : 30,
            contentPaddingRight     : 30,
            contentPaddingTop       : 20,
            contentPaddingBottom    : 20,
            centerOnContainerResize : true,
            centerOnAppear          : true
        });
        this.getApplicationRoot().addListener('resize',this.__setMaxWidth,this);
        this.__setMaxWidth();
        this.getChildControl('captionbar').exclude();
        this.getChildControl('pane').set({
            decorator : new qx.ui.decoration.Decorator().set({
                style: 'solid',
                width: 1
            }),
            backgroundColor: '#fff'
        });
        var cfg = callbackery.data.Config.getInstance().getBaseConfig();
        var grid = new qx.ui.layout.Grid(10, 10);
        this.setLayout(grid);
        grid.setColumnAlign(1, 'right', 'middle');
        let logoScale = ! cfg.logo_noscale;
        let logoSpan  = logoScale ? 3 : 1; 
        if (cfg.logo){
            this.add(new qx.ui.basic.Image(cfg.logo).set({
                alignX : 'left',
                allowGrowX: true,
                allowShrinkX: true,
                allowGrowY: true,
                allowShrinkY: true,
                scale: logoScale
            }), {
                row     : 0,
                column  : 0,
                colSpan : logoSpan
            });
        }

        if (! cfg.hide_password && ! cfg.hide_password_icon) {
            this.add(new qx.ui.basic.Image("icon/64/status/dialog-password.png").set({
                alignY : 'top',
                alignX : 'right',
                allowShrinkX: true,
                allowShrinkY: true,
                scale: true
            }),
            {
                row     : 2,
                column  : 0,
                rowSpan : 2
            });
        }

        this.add(new qx.ui.basic.Label(this.tr("User")), {
            row    : 2,
            column : 1
        });

        var username = new qx.ui.form.TextField().set({
            minWidth: 160
        });
        username.getContentElement().setAttribute("name", "cbUsername");
        username.getContentElement().setAttribute("autocomplete", "on");

        this.add(username, {
            row    : 2,
            column : 2
        });

        var login;
        if (! cfg.hide_password) {
            this.add(new qx.ui.basic.Label(this.tr("Password")), {
                row    : 3,
                column : 1
            });

            var password = new qx.ui.form.PasswordField().set({
                minWidth: 160
            });;
            password.getContentElement().setAttribute("name", "cbPassword");
            password.getContentElement().setAttribute("autocomplete", "on");

            this.add(password, {
                row    : 3,
                column : 2
            });
            login = new qx.ui.form.Button(this.tr("Login"), "icon/16/actions/dialog-ok.png");
        }
        else {
            login = new qx.ui.form.Button(this.tr("OK"), "icon/16/actions/dialog-ok.png");
        }

        login.set({
            marginTop  : 6,
            allowGrowX : false,
            alignX     : 'right'
        });

        this.add(login, {
            row     : 4,
            column  : 0,
            colSpan : 3
        });
        var extraActions = new qx.ui.container.Composite(
            new qx.ui.layout.VBox(0).set({
                alignX: 'right'
            })
        ).set({
            paddingTop: 10
        });
        this.add(extraActions, {
            row: 5,
            column: 0,
            colSpan: 3
        });
        if (cfg.passwordreset_popup) {
            let btn = this.__passwordresetBtn = this.__makeExtraButton(
                cfg.passwordreset_popup,this.tr("Reset Password")
            );
            extraActions.add(btn);
            

        }
        if (cfg.registration_popup) {
            let btn = this.__registrationBtn = this.__makeExtraButton(
                cfg.registration_popup,this.tr("Register New Account")
            );
            extraActions.add(btn);
        }
        
        if ( cfg.company_name && !cfg.hide_company){
            var who = '';
            if (cfg.company_url){
                who += '<a href="' + cfg.company_url + '" style="color: #444;" target="_blank">' + cfg.company_name + '</a>';
            }
            else {
                who += cfg.company_name;
            }
        }
        if (! cfg.hide_release) {
            this.add(new qx.ui.basic.Label(this.tr('release %1, %2 by %3','#VERSION#','#DATE#',who)).set({
                textColor : '#444',
                rich : true
            }), {
                row    : 6,
                column : 0,
                colSpan: 3
            });
        }

        this.addListener('keyup', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                login.press();
                login.execute();
                login.release();
            }
        });
        var rpc = callbackery.data.Server.getInstance();

        login.addListener("execute", function(e) {
            this.setEnabled(false);
            var passwordValue;
            if (! cfg.hide_password) {
                passwordValue = password.getValue();
            }
            // The credentials are handed to the hidden iframe form in the
            // handler, once the login actually succeeded. Nothing about the
            // iframe happens before this call: it is a convenience for the
            // browser's password manager and must never be able to stop a
            // login. It used to run here, and whenever the iframe had not
            // finished loading /login the null it returned threw before this
            // line ever ran -- leaving the form disabled forever with no
            // request sent and nothing on screen to say why.
            rpc.callAsync(qx.lang.Function.bind(
                    this.__loginHandler, this, username.getValue(), passwordValue),
                'login',
                username.getValue(),
                passwordValue
            );
        },
        this);

        let urlCfg = callbackery.data.Config.getInstance().getUrlConfig();
        this.addListener('appear', function() {
            if (! cfg.hide_password) {
                password.setValue('');
            }
            this.setEnabled(true);
            if (username.getValue()){
                username.set({
                    enabled: false,
                    readOnly: true,
                    focusable: false
                });
                if (! cfg.hide_password) {
                    password.focus();
                    password.activate();
                }
            }
            else {
                username.focus();
                username.activate();
            }
            this.__ensureIframe();
            if (urlCfg.app === 'registration' && this.__registrationBtn){
                this.__registrationBtn.fireEvent('tap');
            }
            else if (urlCfg.app === 'passwordreset' && this.__passwordresetBtn){
                this.__passwordresetBtn.fireEvent('tap');
            }
        },this);
    },

    events : { 'login' : 'qx.event.type.Event' },

    members : {
        /**
         * Hand the credentials to the browser's password manager by filling
         * the hidden iframe form and submitting it.
         *
         * Best effort by design. The iframe reloads /login on every appear,
         * so its document can still be blank when this runs and
         * getElementById then returns null. That is a missed save prompt and
         * nothing more, so every step is guarded and the caller ignores the
         * outcome -- this must never come between the user and their session.
         *
         * @param username {String} the user name to offer for saving
         * @param password {String} the password to offer, may be undefined
         * @return {void}
         */
        __rememberCredentials: function(username, password) {
            try {
                var doc = this.__getIframeDocument();
                var form = doc && doc.getElementById('cbLoginForm');
                var userField = doc && doc.getElementById('cbUsername');
                var passField = doc && doc.getElementById('cbPassword');
                if (!form || !userField) {
                    this.debug('login iframe not ready, skipping the password save prompt');
                    return;
                }
                userField.value = username;
                if (password !== undefined && passField) {
                    passField.value = password;
                }
                form.submit();
            }
            catch (e) {
                this.debug('could not offer the credentials for saving: ' + e);
            }
        },

        /**
         * Handler for the login events
         *
         * @param username {String} the user name that was submitted.
         * @param password {String} the password that was submitted, may be undefined.
         * @param ret {Boolean} true if the login is ok and false if it is not ok.
         * @param exc {Exception} any error found during the login process.
         * @return {void}
         */
        __iframe: null,
        __passwdBtn: null,
        __registrationBtn: null,
        __ensureIframe: function(){
            var iframe = document.getElementById("cbLoginIframe");
            if (!iframe) {
                iframe = qx.dom.Element.create('iframe',{
                    id: "cbLoginIframe",
                    style: "width:0px;height:0px;border:0px;"
                });
                document.body.appendChild(iframe);
            }
            iframe.setAttribute('src',
                'login?nocache='+Math.round(1000000*Math.random()).toString(16));
            return iframe;
        },
        __getIframeDocument: function(){
            var iframe = this.__iframe;
            return iframe.contentWindow ? iframe.contentWindow.document : iframe.contentDocument;
        },
        __loginHandler : function(username, password, ret, exc) {
            if (exc == null) {
                if (qx.lang.Type.isObject(ret) && ret.sessionCookie) {
                    this.__rememberCredentials(username, password);
                    this.fireDataEvent('login', ret);
                    this.close();
                }
                else {
                    var element = this.getContentElement().getDomElement();
                    var tada = {duration: 1000, keyFrames : {
                        0 :  {scale: 1, rotate: "0deg"},
                        10 : {scale: 0.9, rotate: "-3deg"},
                        20 : {scale: 0.9, rotate: "-3deg"},
                        30 : {scale: 1.1, rotate: "3deg"},
                        40 : {scale: 1.1, rotate: "-3deg"},
                        50 : {scale: 1.1, rotate: "3deg"},
                        60 : {scale: 1.1, rotate: "-3deg"},
                        70 : {scale: 1.1, rotate: "3deg"},
                        80 : {scale: 1.1, rotate: "-3deg"},
                        90 : {scale: 1.1, rotate: "3deg"},
                        100 : {scale: 1, rotate: "0deg"}
                    }};
                    qx.bom.element.Animation.animate(element,tada);
                    this.setEnabled(true);
                }
            }
            else {
                callbackery.ui.MsgBox.getInstance().exc(exc);
                this.setEnabled(true);
            }
        },
        __makeExtraButton: function(cfg,label) {
            var ul = this.tr('<span style="text-decoration: underline;">%1</span>',label);
            var button = new qx.ui.basic.Label(ul).set({
                cursor: 'pointer',
                rich: true
            });
            button.addListener('tap',function(e) {
                var popup = new callbackery.ui.Popup(cfg);
                popup.addListenerOnce('close', function(e) {
                    this.getApplicationRoot().remove(popup);
                    popup.dispose();
                    this.setModal(true);
                },this);
                this.setModal(false);
                popup.open();
            },this);
            return button;
        },
        __setMaxWidth: function() {
            let bounds = this.getApplicationRoot().getBounds();
            // make sure the window does not get larger than the screen by default ... 
            if (bounds) {
                this.setMaxWidth(bounds.width-20);
            }
        }
    }
});
