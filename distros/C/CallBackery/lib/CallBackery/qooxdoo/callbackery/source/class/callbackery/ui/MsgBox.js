/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL V3 or later
   Authors:    Tobias Oetiker, Fritz Zaucker
   Utf8Check:  äöü

************************************************************************ */

/**
 * A status window singleton. There is only one instance, several calls to
 * open will just change the windows content on the fly.
 *
 * <pre code='javascript'>
 * var msg = callbackery.ui.MsgBox.getInstance();
 * msg.error('Title','Message'); // htmlEncode tags
 * msg.error('Title','Message', true); // active HTML content
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

        this.__mk_btn('cancel',this.tr("Cancel"));
        this.__mk_btn('apply',this.tr("Apply"));
        this.__mk_btn('ok',this.tr("OK"));
        this.__mk_btn('yes',this.tr("Yes"));
        this.__mk_btn('no',this.tr("No"));

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
         * @param title {String} window title
         * @param text {String} contents
         * @param html {Boolean} allow HTML if true
         * @param size {Map} of width and height
         * @return {void} 
         */
        __open : function(title, text, html, size) {
            this.setCaption(String(title));

            let width  = 400;
            let height = 100;
            if (size) {
                if (size.height) {
                    height = size.height;
                }
                if (size.width) {
                    width = size.width;
                }
            }
            this.set({
                width  : width,
                height : height
            });
            let label = text.toString();

            if (!html) {
                /* we are always rich to get line breaking, but we do NOT
                   allow any HTML tags to execute unless requested */
                var map = {
                    '>': '&gt;',
                    '<': '&lt;',
                    '&': '&amp;'
                };
                label = label.replace(/[<>&]/g,function(m){return map[m]});
            }
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
        __mk_btn : function(key, label) {
            var b = this.__btn[key] = new qx.ui.form.Button(label).set({ minWidth : 60 });
            this.__btnBox.add(b);
            b.addListener('execute',function(){
                this.fireDataEvent('choice',key);
                this.close();
            },this);
        },

        __show_btn: function(btns, icons){
            for (var key in this.__btn){
                this.__btn[key].setVisibility('excluded');
            }
            btns.forEach(function(key){
                this.__btn[key].setVisibility('visible');
                if (icons && icons.button && icons.button[key]) {
                    this.__btn[key].setIcon(icons[key]);
                }
                else {
                    this.__btn[key].setIcon(null);
                }
            },this);
        },

        __setIcons: function(icons) {
            if (icons && icons.caption) {
                this.setIcon(icons.caption);
            }
            if (icons && icons.body) {
                this.__body.setIcon(icons);
            }
        },

        /**
         * Open the Error popup
         *
         * @param title {String} title
         * @param text {String} body
         * @param html {Boolean} allow HTML if true
         * @param icons {Map} of body, button, and title icon strings
         * @param size {Map} of width and height
         * @return {void} 
         */
        error : function(title, text, html, icons, size) {
            this.__setIcons(icons);
            this.__show_btn(['ok'], icons);
            this.__open(title, text, html, size);
            return this;
        },


        /**
         * Show server error message
         *
         * @param exc {Map} callAsync exception
         * @param icons {Map} of title and body icon strings
         * @param icons {Map} of body, button, and title icon strings
         * @param size {Map} of width and height
         * @return {void} 
         */
        exc : function(exc, icons, size) {
            this.__setIcons(icons);
            this.__show_btn(['ok'], icons);
            //var trace = '';
            //if (exc.code == 2 && console.log){
            //    qx.dev.StackTrace.getStackTrace().forEach(function(row){
            //        console.log('stack trace:' + row);
            //    },this);
            // }

            // no HTML
            this.__open(this.tr('RPC Error %1', exc.code), this.xtr(exc.message), false);
            return this;
        },


        /**
         * Open the Info popup
         *
         * @param title {String} title
         * @param text {String} body
         * @param html {Boolean} allow HTML if true
         * @param icons {Map} of body, button, and title icon strings
         * @return {void} 
         */
        info : function(title, text, html, icons, size) {
            this.__setIcons(icons);
            this.__show_btn(['ok'], icons);
            this.__open(title, text, html, size);
            return this;
        },


        /**
         * Open the Warning popup with optional callback
         *
         * @param title {String} window title
         * @param text {String} content
         * @param html {Boolean} allow HTML if true
         * @param icons {Map} of body, button, and title icon strings
         * @param size {Map} of width and height
         * @return {void} 
         */
        warn : function(title, text, html, icons, size) {
            this.__setIcons(icons);
            this.__show_btn(['cancel','apply'], icons);
            this.__open(title, text, html, size);
            return this;
        },
        /**
         * Open the Warning popup with optional callback
         *
         * @param title {String} window title
         * @param text {String} content
         * @param html {Boolean} allow HTML if true
         * @param icons {Map} of body, button, and title icon strings
         * @param size {Map} of width and height
         * @return {void} 
         */
        yesno : function(title, text, html, icons, size) {
            this.__setIcons(icons);
            this.__show_btn(['yes','no'], icons);
            this.__open(title, text, html, size);
            return this;
        }
    }
});
