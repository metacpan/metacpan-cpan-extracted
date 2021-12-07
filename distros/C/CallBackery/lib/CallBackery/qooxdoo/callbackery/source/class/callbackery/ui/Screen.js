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
     * @param cfg {Object} plugin configuration map
     * @param getParentFormDataCallBack {Function} method to get data of parent form
     * @param extraAction {Option} additional action to be added to plugin actions
    */
    construct : function(cfg,getParentFormDataCallBack,extraAction) {
        this.base(arguments);
        // just a reference to the Dock layout to make sure
        // it gets included
        qx.ui.layout.Dock;
        qx.ui.layout.Canvas;
        // end
        this.__cfg = cfg;
        this.__getParentFormDataCallBack =  getParentFormDataCallBack;
        this.__extraAction = extraAction;
        switch (cfg.instantiationMode) {
            case 'onStartup':
                this.instantiatePlugin();
                break;
            case 'onTabSelection':
                this.addListenerOnce('appear',this.instantiatePlugin,this);
                break;
            default:
                console.warn('ERROR unknown instantiationMode '+cfg.instantiationMode);
        };
    },

    events: {
        actionResponse: 'qx.event.type.Data'
    },
    members: {
        __extraAction: null,
        __getParentFormDataCallBack: null,
        __cfg: null,
        __reconfiguring: null,
        instantiatePlugin: function(){
            var rpc = callbackery.data.Server.getInstance();
            var pluginMap = callbackery.ui.Plugins.getInstance().getPlugins();
            var that = this;
            var cfg = this.__cfg;
            var getParentFormDataCallBack = this.__getParentFormDataCallBack;
            var extraAction = this.__extraAction;

            var formData = this.__getParentFormDataCallBack ? this.__getParentFormDataCallBack() : {};
            formData.userData = cfg.userData;

            rpc.callAsyncSmart(function(pluginConfig){
                if (extraAction && pluginConfig.action){
                    pluginConfig.action.push(extraAction);
                }
                pluginConfig['name'] = cfg.name;
                var type = pluginConfig.type;
                if (type in pluginMap) {
                    var content = pluginMap[type](pluginConfig,getParentFormDataCallBack);
                    content.addListener('actionResponse',function(e){
                        that.fireDataEvent('actionResponse',e.getData());
                    });
                    // track visibility changes in the screen widget
                    content.addListener('changeVisibility',function(){
                        this.setVisibility(content.getVisibility());
                    },that);
                    var options = pluginConfig.options;
                    var layoutClass = qx.ui.layout.Grow;
                    var layoutClassSet = {};
                    var containerSet = {};
                    var containerAddProps = {};
                    if (options) {
                        var layout = options.layout;
                        if (layout) {
                            if (layout.class) {
                                layoutClass = qx.Bootstrap.getByName(layout.class);
                            }
                            if (layout.set) {
                                layoutClassSet = layout.set;
                            }
                        }
                        var container = options.container;
                        if (container) {
                            if (container.set) {
                                containerSet = container.set;
                            }
                            if (container.addProps) {
                                containerAddProps = container.addProps;
                            }
                        }
                    }
                    var lc = new layoutClass;
                    lc.set(layoutClassSet);
                    that.setLayout(lc);
                    content.set(containerSet);
                    that.add(content,containerAddProps);

                    // Show (legal) disclaimer and hide screen content until
                    // checkbox is set and btn is executed.
                    var disclaimerCfg;
                    if (options) {
                        disclaimerCfg = options.disclaimer;
                    }
                    if (disclaimerCfg && !that.__reconfiguring) {
                        content.hide();
                        // force widget visibility because it is tied to
                        // content visibility above
                        that.setVisibility('visible');

                        var disclaimerContainer = new qx.ui.container.Composite(new qx.ui.layout.VBox(10));
                        var disclaimer = new qx.ui.basic.Label(that.xtr(disclaimerCfg.note)).set({
                            rich: true
                        });

                        var okBtnLabel = disclaimerCfg.okButtonLabel ? that.xtr(disclaimerCfg.okButtonLabel)
                                                                     : that.xtr('OK');
                        var okBtn = new qx.ui.form.Button(okBtnLabel).set({
                            enabled: false
                        });
                        okBtn.addListener('execute', function() {
                            content.show();
                            disclaimerContainer.hide();
                        }, that);

                        var check = new qx.ui.form.CheckBox(that.xtr(disclaimerCfg.label)).set({
                            rich: true, value: false
                        });
                        check.bind('value', okBtn, 'enabled');

                        var btnRow     = new qx.ui.container.Composite(new qx.ui.layout.HBox(10, 'right'));
                        btnRow.add(okBtn);

                        disclaimerContainer.add(disclaimer);
                        disclaimerContainer.add(check);
                        disclaimerContainer.add(btnRow);
                        that.add(disclaimerContainer);
                    }
                    // install re-configure handler
                    if (pluginConfig.reconfigurePluginOnAppear && !that.__reconfiguring) {
                        that.addListener('appear', function() {
                            this.__reconfiguring = true;
                            this.removeAll();
                            this.instantiatePlugin();
                        }, that);
                    }
                }
                else {
                    that.debug('Invalid plugin type:"' + type + '"');
                }
            },'getPluginConfig', cfg.name, formData
            );
        }
    }

});
