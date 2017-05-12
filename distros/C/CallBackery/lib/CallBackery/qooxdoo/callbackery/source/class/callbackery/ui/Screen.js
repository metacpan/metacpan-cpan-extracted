/* ************************************************************************
   Copyright: 2013 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>, Fritz Zaucker <fritz.zaucker@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Abstract visualization widget.
 */
qx.Class.define("callbackery.ui.Screen", {
    extend : qx.ui.container.Composite,
    /**
     * Create a page for the View Tab with the given title
     *
     * @param vizWidget {Widget} visualization widget to embed
     */
    construct : function(cfg,getParentFormData,extraAction) {
        /* using syntax trick to not get a warning for translating
           a variable */
        this.base(arguments,new qx.ui.layout.Grow());
        var that = this;
        var rpc = callbackery.data.Server.getInstance();
        var pluginMap = callbackery.ui.Plugins.getInstance().getPlugins();
        this.addListenerOnce('appear',function(){
            rpc.callAsyncSmart(function(pluginConfig){
                if (extraAction && pluginConfig.action){
                    pluginConfig.action.push(extraAction);
                }
                pluginConfig['name'] = cfg.name;
                var type = pluginConfig.type;
                if (type in pluginMap) {
                    var content = pluginMap[type](pluginConfig,getParentFormData);
                    content.addListener('actionResponse',function(e){
                        that.fireDataEvent('actionResponse',e.getData());
                    });
                    that.add(content);
                }
                else {
                    that.debug('Invalid plugin type:"' + type + '"');
                }
            },'getPluginConfig',cfg.name,getParentFormData ? getParentFormData() : null);
        });
    },

    events: {
        actionResponse: 'qx.event.type.Data'
    }

});
