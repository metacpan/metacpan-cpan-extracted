/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL V3 or later
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */

/**
@asset(qx/icon/${qx.icontheme}/32/status/dialog-error.png)
@asset(qx/icon/${qx.icontheme}/16/status/dialog-error.png)
@asset(qx/icon/${qx.icontheme}/32/status/dialog-information.png)
@asset(qx/icon/${qx.icontheme}/16/status/dialog-information.png)
@asset(qx/icon/${qx.icontheme}/32/status/dialog-warning.png)
@asset(qx/icon/${qx.icontheme}/16/status/dialog-warning.png)
@asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
@asset(qx/icon/${qx.icontheme}/16/actions/dialog-apply.png)
@asset(qx/icon/${qx.icontheme}/16/actions/dialog-cancel.png)
 */
 
/**
 * A status window singelton. There is only one instance, several calls to
 * open will just change the windows content on the fly.
 *
 * <pre code='javascript'>
 * var msg = callbackery.ui.MsgBox.getInstance();
 * msg.error('Title','Message');
 * </pre>
 */
qx.Class.define("callbackery.ui.MsgBox", {
    extend : qx.ui.window.Window,
    type : "singleton",

    construct : function() {
        this.base(arguments);

        this.set({
            modal          : true,
            showMinimize   : false,
            showMaximize   : false,
            contentPadding : 15
        });

        this.setLayout(new qx.ui.layout.VBox(20));

        // setting the lable to an empty string, so that the lable widget gets
        // created in the first place and hence the selectable attribute
        // can be set on it
        var body = this.__body = new qx.ui.basic.Atom('').set({
            rich       : true,
            gap        : 10,
            allowGrowY : true,
            allowGrowX : false,
            selectable : true
        });

        this.add(body);
        
        var box = this.__btnBox = new qx.ui.container.Composite;
        box.setLayout(new qx.ui.layout.HBox(5, "right"));
        this.add(box);

        this.__btn = {};

        this.__mk_btn('cancel',this.tr("Cancel"), "actions/dialog-cancel.png");
        this.__mk_btn('apply',this.tr("Apply"), "actions/dialog-apply.png");
        this.__mk_btn('ok',this.tr("OK"), "actions/dialog-ok.png");
        this.__mk_btn('yes',this.tr("Yes"), "actions/dialog-ok.png");
        this.__mk_btn('no',this.tr("No"), "actions/dialog-cancel.png");

        ['ok','cancel','no'].forEach(function(x){
            this.__btn[x].addListener('appear', function(e) {
                this.__btn[x].focus();
            },this);
        }, this);

        this.addListener('appear',function(e){
            this.center();
        },this);
    },
    events: {
        choice: 'qx.event.type.Data'
    },
    members : {
        __body   : null,
        __btn    : null,
        __btnBox : null,


        /**
         * Open the message box
         *
         * @param titel {String} window title
         * @param text {String} contents
         * @return {void} 
         */
        __open : function(titel, text) {
            this.setCaption(String(titel));

            this.set({
                width  : 400,
                height : 100
            });
            /* we are rich to get line breaking and stuff, but we do NOT
               allow any HTML tags to execute */
            var map = {
                '>': '&gt;',
                '<': '&lt;',
                '&': '&amp;'
            };
            var label = String(text).replace(/[<>&]/g,function(m){return map[m]});
            this.__body.setLabel(label);
            this.open();
        },


        /**
         * Create a button which is at least 40 pixel wide
         *
         * @param lab {String} label
         * @param ico {Icon} icon
         * @return {Button} button widget
         */
        __mk_btn : function(key,lab,ico) {
            var b = this.__btn[key] = new qx.ui.form.Button(lab, 'icon/16/'+ico).set({ minWidth : 60 });
            this.__btnBox.add(b);
            b.addListener('execute',function(){
                this.fireDataEvent('choice',key);
                this.close();
            },this);
        },

        __show_btn: function(btns){
            for (var key in this.__btn){
                this.__btn[key].setVisibility('excluded');
            }
            btns.forEach(function(key){
                this.__btn[key].setVisibility('visible');
            },this);
        },


        /**
         * Open the Error popup
         *
         * @param titel {String} title
         * @param text {String} body
         * @return {void} 
         */
        error : function(titel, text) {
            this.__body.setIcon("icon/32/status/dialog-error.png");
            this.setIcon("icon/16/status/dialog-error.png");
            this.__show_btn(['ok']);
            this.__open(titel, text);
            return this;
        },


        /**
         * Show server error message
         *
         * @param exc {Map} callAsync exception
         * @return {void} 
         */
        exc : function(exc) {
            this.__body.setIcon("icon/32/status/dialog-error.png");
            this.setIcon("icon/16/status/dialog-error.png");
            this.__show_btn(['ok']);
            //var trace = '';
            //if (exc.code == 2 && console.log){
            //    qx.dev.StackTrace.getStackTrace().forEach(function(row){
            //        console.log('stack trace:' + row);
            //    },this);
            // }
            
            this.__open(this.tr('RPC Error %1', exc.code), this['tr'](exc.message));
            return this;
        },


        /**
         * Open the Info popup
         *
         * @param titel {String} title
         * @param text {String} body
         * @return {void} 
         */
        info : function(titel, text) {
            this.__body.setIcon("icon/32/status/dialog-information.png");
            this.setIcon("icon/16/status/dialog-information.png");
            this.__show_btn(['ok']);
            this.__open(titel, text);
            return this;
        },


        /**
         * Open the Warning popup with optional callback
         *
         * @param titel {String} window title
         * @param text {String} content
         * @return {void} 
         */
        warn : function(titel, text) {
            this.__body.setIcon("icon/32/status/dialog-warning.png");
            this.setIcon("icon/16/status/dialog-warning.png");
            this.__show_btn(['cancel','apply']);
            this.__open(titel, text);
            return this;
        },
        /**
         * Open the Warning popup with optional callback
         *
         * @param titel {String} window title
         * @param text {String} content
         * @return {void} 
         */
        yesno : function(titel, text) {
            this.__body.setIcon("icon/32/status/dialog-warning.png");
            this.setIcon("icon/16/status/dialog-warning.png");
            this.__show_btn(['yes','no']);
            this.__open(titel, text);
            return this;
        }
    }
});
