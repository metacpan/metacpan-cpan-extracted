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
qx.Class.define("callbackery.ui.TabView", {
    extend : qx.ui.tabview.TabView,
    type : 'singleton',

    construct : function() {
        this.base(arguments);
        var cfg = callbackery.data.Config.getInstance();
        var baseCfg = cfg.getBaseConfig();
        var userCfg = cfg.getUserConfig();
        var urlCfg = cfg.getUrlConfig();
        var tabMap = this.__tabMap = {};
        userCfg.plugins.map(function(cfg){
            var page = tabMap[cfg.name]
                = new callbackery.ui.Page(cfg);
            this.add(page);
            qx.core.Id.getInstance().register(page, cfg.name);
            page.setQxObjectId(cfg.name);
            page.addOwnedQxObject(page.getButton(), 'TabButton');
        },this);
        var initialPlugin = tabMap[baseCfg.initial_plugin];
        // #app=pluginKey
        if (urlCfg.app){
            initialPlugin = tabMap[urlCfg.app];
        }
        if (initialPlugin){
            initialPlugin.getChildControl('button').execute();
        }
        var selectionChangeInProgress = false;
        this.addListener('changeSelection',function(e){
            if (selectionChangeInProgress){
                return;
            }
            var oldSelection = e.getOldData();
            var newSelection = e.getData();
            if (oldSelection[0].getUnsavedData()){
                selectionChangeInProgress = true;
                this.setSelection(oldSelection);
                callbackery.ui.MsgBox.getInstance().yesno(
                    this.tr("Unsaved Data"),
                    this.tr("This form contains unsaved data. Do you still want to switch?")
                )
                .addListenerOnce('choice',function(e){
                    if (e.getData() == 'yes'){
                        this.setSelection(newSelection);
                        oldSelection[0].setUnsavedData(false);
                    }
                    selectionChangeInProgress = false;
                },this);
            }
        });
    },
    members : {
        __tabMap: null
    }
});
