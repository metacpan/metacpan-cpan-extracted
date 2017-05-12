/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL V3 or later
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */

/**
@asset(callbackery/spinner.gif);
 */

/**
 * singleton with two methods for blocking and unblocking the screen. while the screen
 * is blocked, a busy icon is shown.
 *
 * <pre code='javascript'>
 * var busy = callbackery.ui.Busy.getInstance();
 * busy.show();busy.hide();
 * </pre>
 */

qx.Class.define("callbackery.ui.Busy", {
    extend : qx.ui.basic.Atom,
    type : "singleton",

    construct : function() {
        var img = 'callbackery/spinner.gif';
        var cfg = callbackery.data.Config.getInstance().getBaseConfig();
        if (cfg.spinner){
            img = cfg.spinner;
        }
        this.base(arguments,null,img);
        this.set({
            center : true,
            show: 'both',
            iconPosition: 'top',
            visibility: 'excluded',
            zIndex: 10000
        });
        this.getApplicationRoot().add(this,{top:0,bottom:0,left:0,right:0});
        this.__blocker = new qx.ui.core.Blocker(callbackery.ui.Desktop.getInstance()).set({
            opacity: 0.7,
            color   : '#fff',
            keepBlockerActive: true
        });
    },
    members : {
        __blocker : null,
        show: function(label){
            this.setVisibility('visible');
            this.fadeIn(500);
            this.setLabel(label);
            this.__blocker.block();
        },
        hide: function(){
            this.setVisibility('excluded');
            this.fadeOut(10);
            this.__blocker.unblock();
        }
    }
});
