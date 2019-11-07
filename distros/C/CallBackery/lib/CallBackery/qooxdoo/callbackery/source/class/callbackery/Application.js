/* *ütf8 *****************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL V3 or later
   Authors:    Fritz Zaucker

************************************************************************ */

/**
 * This is the main application class of your custom application "afb"
 *
 * @asset(callbackery/*)
 */

qx.Class.define("callbackery.Application", {
    extend : qx.application.Standalone,

    /*
    *****************************************************************************
    MEMBERS
    *****************************************************************************
    */

    members : {

        main : function() {
            // Call super class
            this.base(arguments);

            // Enable logging in debug variant
            if (qx.core.Environment.get("qx.debug")) {
                // support native logging capabilities, e.g. Firebug for Firefox
                qx.log.appender.Native;
                // support additional cross-browser console. Press F7 to toggle visibility
                qx.log.appender.Console;
            }
            var rpc = callbackery.data.Server.getInstance();
            var root = this.getRoot();
            root.set({
                blockerColor   : '#fff',
                blockerOpacity : 0.7
            });
            var desktopContainer = new qx.ui.container.Composite(new qx.ui.layout.VBox(0));
            root.add(desktopContainer,{top: 0, left: 0, right: 0, bottom: 0});

            /* give the History object a more relaxed attitude towards encoding stuff */
            qx.Class.patch(qx.bom.History,callbackery.data.MHistoryRelaxedEncoding);
            qx.bom.History.getInstance().addListener('changeState', this.__changeLanguage, this);
            this.__changeLanguage();

            rpc.callAsyncSmart(function(baseCfg){
                callbackery.data.Config.getInstance().setBaseConfig(baseCfg);
                if (baseCfg.TRANSLATIONS){
                    var t = baseCfg.TRANSLATIONS;
                    var lm = qx.locale.Manager.getInstance();
                    for (var lang in t) {
                        lm.addTranslation(lang, t[lang]);
                    }
                }
                if (baseCfg.COLORS){
                    qx.Theme.define('callbackery.theme.CustomColor',{
                        colors: baseCfg.COLORS
                    });
                    var colorTheme = qx.theme.manager.Color.getInstance().getTheme();
                    qx.Theme.patch(colorTheme,callbackery.theme.CustomColor);
                    // reset/set theme to get the changes visible in to ui
                    qx.theme.manager.Color.getInstance().resetTheme();
                    qx.theme.manager.Color.getInstance().setTheme(colorTheme);
                }
                rpc.callAsyncSmart(function(userCfg){
                    callbackery.data.Config.getInstance().setUserConfig(userCfg);

                    desktopContainer.add(callbackery.ui.Desktop.getInstance(),{flex: 1});
                }, 'getUserConfig');
            }, 'getBaseConfig');

        },

        registerPlugin: function(type, func) {
            return callbackery.ui.Plugins.getInstance().register(type, func);
        },

        __changeLanguage: function() {
            var h = qx.bom.History.getInstance();
            var state = h.getState();
            var items = state.split(';');
            var lang;
            for (var i=0; i<items.length; i++) {
                var item = items[i].split('=');
                if (item[0] == 'lang') {
                    lang = decodeURIComponent(item[1]);
                    break;
                }
            }
            if (lang) {
                qx.locale.Manager.getInstance().setLocale(lang);
            }
        },

        getFooterWidget : function() {
            return callbackery.ui.Footer.getInstance();
        },

        getHeaderWidget : function() {
            return callbackery.ui.Header.getInstance();
        }

    }
});
