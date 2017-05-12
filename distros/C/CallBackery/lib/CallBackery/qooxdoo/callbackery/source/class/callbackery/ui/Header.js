/* ************************************************************************
   Copyright: 2011 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */
/**
 * Build the desktop. This is a singleton. So that the desktop
 * object and with it the treeView and the searchView are universaly accessible
 */
qx.Class.define("callbackery.ui.Header", {
    extend : qx.ui.container.Composite,
    type : 'singleton',

    construct : function() {
        this.base(arguments, new qx.ui.layout.HBox());
        var cfg = callbackery.data.Config.getInstance().getBaseConfig();
        if (cfg.title){
            this.add(new qx.ui.basic.Label(cfg.title).set({
                font: 'title',
                rich: true,
                allowGrowX: true,
                alignY: 'middle',
                 padding: [ 5,0,5,0]
            }),{ flex: 1});
        }
        if (cfg.logo_small){
            this.getApplicationRoot().add(
                new qx.ui.basic.Image(cfg.logo_small),
                { top: 10, right: 10 }
            );
        }
    }
});
