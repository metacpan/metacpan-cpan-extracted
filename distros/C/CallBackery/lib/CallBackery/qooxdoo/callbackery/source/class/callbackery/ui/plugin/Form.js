/* ************************************************************************
   Copyright: 2013 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Abstract Visualization widget.
 */
qx.Class.define("callbackery.ui.plugin.Form", {
    extend : qx.ui.container.Composite,
    /**
     * create a page for the View Tab with the given title
     *
     * @param vizWidget {Widget} visualization widget to embedd
     */
    construct : function(cfg,getParentFormData) {
        this.base(arguments);
        var that = this;
        cfg.form.forEach(function(s){
            if (s.triggerFormReset) {
                that._hasTrigger = true;
            }
        });
        this._cfg = cfg;
        this._loading = 0;
        this._getParentFormData = getParentFormData;
        this._populate();
        this._addValidation();
        this.addListener('appear',function () {
            this._loadData();
        }, this);
        this._actionResponseHandler = this._action.addListener('actionResponse',function(e){
            var data = e.getData();
            switch(data.action){
                case 'reload':
                    this._loadData();
                    this._reconfForm();
                    break;
                case 'dataSaved':
                    this._loadData();
                    this._reconfForm();
                    break;
                case 'reloadStatus':
                    this._loadDataReadOnly();
                    break;
                case 'uriData':
                    var el = qx.dom.Element.create('a', {
                        href: 'data:'+data.type+';base64,'
                            + qx.util.Base64.encode(data.data,true),
                        download: data.name
                    });
                    this.fireDataEvent('actionResponse',{action: 'dataSaved'});
                    // make sure we only run this once events have run
                    // their course
                    //window.setTimeout(function(){
                    qx.bom.Event.fire(el,'tap');
                    qx.dom.Element.remove(el);
                    //},0);
                    break;
            }
            this.fireDataEvent('actionResponse',e.getData());
        },this);
    },
    events: {
        actionResponse: 'qx.event.type.Data'
    },
    members: {
        _form: null,
        _action: null,
        _cfg: null,
        _loading: null,
        _actionResponseHandler : null,
        _getParentFormData: null,
        _hasTrigger: null,
        _reConfFormInProgress: null,

        _populate: function(){
            var cfg = this._cfg;
            this.setLayout(new qx.ui.layout.VBox(30));
            var form = this._form = new callbackery.ui.form.Auto(
                cfg.form,null,callbackery.ui.form.renderer.NoteForm);
            if (cfg['options'] && cfg.options['warnAboutUnsavedData']){
                form.addListener('changeData',function(){
                    if (this._loading == 0){ // only notify when update comes from human interaction
                        this.fireDataEvent('actionResponse',{action: 'dataModified'});
                    }
                },this);
            }
            this.add(new qx.ui.container.Scroll(form),{flex: 1});
            var that = this;
            var action = this._action = new callbackery.ui.plugin.Action(
                cfg,qx.ui.form.Button,
                new qx.ui.layout.Flow(5,5,'right'),
                function (){
                    if (that._form.validate()){
                        return that._form.getData();
                    }
                    else {
                        return false;
                    }
                }
            );
            this.add(action);
        },

        _addValidation: function(){
            var rpc = callbackery.data.Server.getInstance();
            var cfg = this._cfg;
            var form = this._form;
            var that = this;
            var buttonMap = this._action.getButtonMap();
            cfg.form.forEach(function(s){
                if (s.actionSet) {
                    for (var key in s.actionSet) {
                        buttonMap[key].set(s.actionSet[key]);
                    }
                }

                if (!s.key){
                    return;
                }                var control = form.getControl(s.key);
                var callback = function(e){
                    var data = e.getData();
                    // handle events from selectboxes
                    if (control.getSelection && qx.lang.Type.isArray(data)){
                        if (data.length > 0 && data[0]['getModel']){
                            data = data[0].getModel();
                        }
                        else {
                            data = null;
                        }
                    }
                    var required = control.getRequired();
                    if (required){
                        if (data == null || data == '' ){
                            control.setValid(false);
                            return;
                        }
                        else {
                            control.setValid(true);
                        }
                    }
                    if (s.validator){
                        rpc.callAsyncSmart(function(message) {
                            if (message){
                                control.set({
                                    valid: false,
                                    invalidMessage: that.xtr(message)
                                });
                            }
                            else {
                                control.setValid(true);
                            }
                        }, 'validatePluginData',cfg.name,s.key,form.getData());
                    }
                    if (s.triggerFormReset && ! this._loading){
                        this._reconfForm(s.key);
                    }
                };
                if (control.getSelection){
                    control.addListener('changeSelection',callback,this);
                }
                else {
                    control.addListener('changeValue',callback,this);
                }
            },this);
        },
        _reconfForm: function(triggerField){
            if (this._reConfFormInProgress) return;
            if (!this._form) return;

            var that = this;
            var rpc = callbackery.data.Server.getInstance();
            that._reConfFormInProgress=true;
            rpc.callAsyncSmart(function(pluginConfig) {
                if (pluginConfig){
                    that._reConfFormHandler(pluginConfig.form);
                }
                that._reConfFormInProgress = false;
            }, 'getPluginConfig', that._cfg.name,{
                triggerField: triggerField,
                currentFormData: that._form.getData()
            });
        },
        _reConfFormHandler: function(formCfg){
            if (! this._form) return;
            var buttonMap = this._action.getButtonMap();
            formCfg.forEach(function(s){
                if (s.actionSet) {
                    for (var key in s.actionSet) {
                        buttonMap[key].set(s.actionSet[key]);
                    }
                }
                if (!s.key){
                    return;
                }
                if (s.widget == 'selectBox' || s.widget == 'comboBox'){
                    this._form.setSelectBoxData(s.key,s.cfg.structure);
                }
                if (s.set) {
                    if ('value' in s.set){
                        delete s.set.value; // do NOT change the value of anything.
                    }
                    var ctrl = this._form.getControl(s.key);
                    ctrl.set(s.set);
                }
            },this);
            this._loadDataReadOnly();
        },
        _loadDataReadOnly: function(){
            // this.setEnabled(false);
            if (!this._form) return;

            var that = this;
            var rpc = callbackery.data.Server.getInstance();
            if (this._loading > 0){
                return;
            }
            this._loading++;
            var parentFormData = {};
            if (this._getParentFormData){
                parentFormData = this._getParentFormData();
            }
            rpc.callAsync(function(data,exc){
                if (!exc){
                    if (that._form) {
                        var statusData = {};
                        that._cfg.form.forEach(function(item){
                            if (data[item.key]) {
                                if (item.reloadOnFormReset === true) {
                                    statusData[item.key] = data[item.key];
                                }
                                else if (item.reloadOnFormReset !== false){
                                    if (item.set && item.set.readOnly){
                                        statusData[item.key] = data[item.key];
                                    }
                                }
                            }
                        });
                        that._form.setData(statusData,true);
                    }
                }
                that._loading--;
            },'getPluginData',this._cfg.name,'allFields',parentFormData,{ currentFormData: this._form.getData()});
        },
        _loadData: function(){
            if (!this._form) return;

            var that = this;
            var rpc = callbackery.data.Server.getInstance();
            this._loading++;
            var parentFormData = {};
            if (this._getParentFormData){
                parentFormData = this._getParentFormData();
            }
            var busy = callbackery.ui.Busy.getInstance();
            busy.show(this.tr('Loading Form Data'));
            rpc.callAsync(function(data,exc){
                if (!exc){
                    if (that._form) {
                        that._form.setData(data,true);
                        if (that._hasTrigger) {
                            that._reconfForm();
                        }
                    }
                }
                else {
                    if (exc.code != 2){ /* 2 is for aborted calls, this happens when the popup is closed */
                        callbackery.ui.MsgBox.getInstance().exc(exc);
                    }
                }
                busy.hide();
                that._loading--;
            },'getPluginData',this._cfg.name,'allFields',parentFormData,{ currentFormData: this._form.getData()});
        }
    },
    destruct : function() {
        // cleanup; setting _form=null will abort _reconfFormHandler()
        this._form.destroy();
        this._form = null;
        if (this._actionResponseHandler) {
            this.removeListenerById(this._actionResponseHandler);
        }
    }
});
