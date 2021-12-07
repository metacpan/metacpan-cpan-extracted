/* ************************************************************************
   Copyright: 2015 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Fritz Zaucker <fritz.zaucker@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Abstract Visualization widget.
 */
qx.Class.define("callbackery.ui.Plugins", {
    extend : qx.core.Object,
    type   : "singleton",

    properties : {

        plugins : {
            init: {
                action: function(pluginConfig,getParentFormData) {
                    return new callbackery.ui.plugin.ActionForm(pluginConfig,getParentFormData);
                },
                form: function(pluginConfig,getParentFormData) {
                    return new callbackery.ui.plugin.Form(pluginConfig,getParentFormData);
                },
                cardlist: function(pluginConfig,getParentFormData) {
                    return new callbackery.ui.plugin.CardList(pluginConfig,getParentFormData);
                },
                table: function(pluginConfig,getParentFormData) {
                    return new callbackery.ui.plugin.Table(pluginConfig,getParentFormData);
                },
                html: function(pluginConfig,getParentFormData) {
                    return new callbackery.ui.plugin.Html(pluginConfig,getParentFormData);
                }
            }
        }

    },

    members: {

        register : function(type, func) {
            var plugins = this.getPlugins();
            plugins[type] = func;
            this.setPlugins(plugins);
            return plugins;
        }

    }

});
