/* ************************************************************************
   Copyright: 2013 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Abstract Visualization widget.
 */
qx.Class.define("callbackery.ui.plugin.Action", {
    extend : qx.ui.container.Composite,
    /**
     * create a page for the View Tab with the given title
     *
     * @param vizWidget {Widget} visualization widget to embedd
     */
    construct : function(cfg,buttonClass,layout,getFormData) {
        this.base(arguments, layout);
        this._buttonMap = {};
        this._buttonSetMap = {};
        this._populate(cfg,buttonClass,getFormData);
        this.addListener('actionResponse',function(e){
            var data = e.getData();
            // ignore empty actions responses
            if (!data){
                return;
            }
            switch (data.action){
                case 'logout':
                    callbackery.data.Server.getInstance().callAsyncSmartBusy(function(ret) {
                        if (window.console){
                            window.console.log('last words from the server "'+ret+'"');
                        }
                        document.location.reload(true);
                    }, 'logout');
                    break;
                case 'dataSaved':
                case 'showMessage':
                    if (data.title && data.message){
                        callbackery.ui.MsgBox.getInstance().info(this.xtr(data.title),this.xtr(data.message));
                    }
                    break;
            }
        },this);
    },
    events: {
        actionResponse: 'qx.event.type.Data',
        popupClosed: 'qx.event.type.Event'
    },
    properties: {
        selection: {}
    },
    members: {
        _cfg: null,
        _tableMenu: null,
        _defaultAction: null,
        _buttonMap: null,
        _populate: function(cfg,buttonClass,getFormData){
            var tm = this._tableMenu =  new qx.ui.menu.Menu;
            cfg.action.forEach(function(btCfg){
                var button;
                var menuButton;
                switch (btCfg.action) {
                    case 'submitVerify':
                    case 'submit':
                    case 'popup':
                    case 'logout':
                    case 'cancel':
                    case 'download':
                        button = new buttonClass(this.xtr(btCfg.label));
                        if (btCfg.key){
                            this._buttonMap[btCfg.key]=button;
                        }
                        if (btCfg.buttonSet) {
                            var bs = btCfg.buttonSet;
                            if (bs.label) {
                                bs.label = this.xtr(bs.label);
                            }
                            button.set(bs);
                            if (btCfg.key){
                                this._buttonSetMap[btCfg.key]=bs;
                            }
                        }
                        
                        if ( btCfg.addToContextMenu ){
                            menuButton = new qx.ui.menu.Button(this.xtr(btCfg.label));
                            [
                                'Enabled',
                                'Visibility',
                                'Icon',
                                'Label'
                            ].forEach(function(Prop){
                                var prop = Prop.toLowerCase();
                                button.addListener('change'+Prop,function(e){
                                    menuButton['set'+Prop](e.getData());
                                },this);
                                if (btCfg.buttonSet && prop in btCfg.buttonSet){
                                    menuButton['set'+Prop](
                                            btCfg.buttonSet[prop]);
                                }
                            },this);
                        }
                        break;
                    case 'refresh':
                        var timer = qx.util.TimerManager.getInstance();
                        var timerId;
                        this.addListener('appear',function(){
                            timerId = timer.start(function(){
                                this.fireDataEvent('actionResponse',{action: 'reloadStatus'});
                            }, btCfg.interval * 1000, this);
                        }, this);
                        this.addListener('disappear',function(){
                            timer.stop(timerId);
                        }, this);
                        break;
                    case 'upload':
                        button = this._makeUploadButton(cfg,btCfg,getFormData);
                        break;
                    case 'separator':
                        this.add(new qx.ui.core.Spacer(10,10));
                        break;
                    default:
                        this.debug('Invalid execute action:' + btCfg.action);
                }
                var action = function(){
                    var that = this;
                    if (! button.isEnabled()) {
                        return;
                    }
                    switch (btCfg.action) {
                        case 'submitVerify':
                        case 'submit':
                            var formData = getFormData();
                            if (formData === false){
                                callbackery.ui.MsgBox.getInstance().error(
                                    this.tr("Validation Error"),
                                    this.tr("The form can only be submitted when all data fields have valid content.")
                                );
                                return;
                            }
                            var key = btCfg.key;
                            var asyncCall = function(){
                                callbackery.data.Server.getInstance().callAsyncSmartBusy(function(ret){
                                    that.fireDataEvent('actionResponse',ret || {});
                                },'processPluginData',cfg.name,{ "key": key, "formData": formData });
                            };

                            if (btCfg.action == 'submitVerify'){
                                callbackery.ui.MsgBox.getInstance().yesno(
                                    this.xtr(btCfg.label),
                                    this.xtr(btCfg.question)
                                )
                                .addListenerOnce('choice',function(e){
                                    if (e.getData() == 'yes'){
                                        asyncCall();
                                    }
                                },this);
                            }
                            else {
                                asyncCall();
                            }
                            break;
                        case 'download':
                            var formData = getFormData();
                            if (formData === false){
                                callbackery.ui.MsgBox.getInstance().error(
                                    this.tr("Validation Error"),
                                    this.tr("The form can only be submitted when all data fields have valid content.")
                                );
                                return;
                            }
                            var key = btCfg.key;
                            var that = this;
                            callbackery.data.Server.getInstance().callAsyncSmart(function(cookie){
                                var iframe = new qx.ui.embed.Iframe().set({
                                    width: 100,
                                    height: 100
                                });
                                iframe.addListener('load',function(e){
                                    var response = {
                                        exception: {
                                            message: that.tr("No Data"),
                                            code: 9999
                                        }
                                    };
                                    try {
                                        response = qx.lang.Json.parse(iframe.getBody().innerHTML);
                                    } catch (e){};
                                    if (response.exception){
                                        callbackery.ui.MsgBox.getInstance().error(
                                            that.tr("Download Exception"),
                                            that.xtr(response.exception.message) + " ("+ response.exception.code +")"
                                        );
                                    }
                                    that.getApplicationRoot().remove(iframe);
                                });
                                iframe.setSource(
                                    'download'
                                    +'?key='+key
                                    +'&xsc='+encodeURIComponent(cookie)
                                    +'&name='+cfg.name
                                    +'&formData='+encodeURIComponent(qx.lang.Json.stringify(formData))
                                );
                                that.getApplicationRoot().add(iframe,{top: -1000,left: -1000});
                            },'getSessionCookie');
                            break;
                        case 'cancel':
                            this.fireDataEvent('actionResponse',{action: 'cancel'});
                            break;
                        case 'popup':
                            var popup = new callbackery.ui.Popup(btCfg,getFormData);

                            let appRoot = this.getApplicationRoot();
                            let bounds = appRoot.getBounds();
                            // make sure the window does not get larger than the screen
                            if (bounds) {
                                if (!popup.getMaxWidth()) {
                                    popup.setMaxWidth(bounds.width-20);
                                }
                                if (!popup.getMaxHeight()) {
                                    popup.setMaxHeight(bounds.height-20);
                                }
                            }
                    
                            popup.addListenerOnce('close',function(){
                                // wait for stuff to happen before we rush into
                                // disposing the popup
                                qx.event.Timer.once(function(){
                                    appRoot.remove(popup);
                                    popup.dispose();
                                    this.fireEvent('popupClosed');
                                },this,100);
                                if (!(btCfg.options && btCfg.options.noReload)){
                                    this.fireDataEvent('actionResponse',{action: ( btCfg.options && btCfg.options.reloadStatusOnClose ) ? 'reloadStatus' : 'reload'});
                                }
                            },this);
                            popup.open();
                            break;
                        case 'logout':
                            this.fireDataEvent('actionResponse',{action: 'logout'});
                            break;

                        default:
                            this.debug('Invalid execute action:' + btCfg.action);
                    }
                };

                if (btCfg.defaultAction){
                    this._defaultAction = action;
                }
                if (button){
                    button.addListener('execute',action,this);
                    this.add(button);
                }
                if (menuButton){
                    menuButton.addListener('execute',action,this);
                    this._tableMenu.add(menuButton);
                }
            },this);
        },
        _makeUploadButton: function(cfg,btCfg,getFormData){
            var button;
            if (btCfg.btnClass == 'toolbar') {
                button = new callbackery.ui.form.UploadToolbarButton(
                    this.xtr(btCfg.label));
            }
            else {
                button = new callbackery.ui.form.UploadButton(
                    this.xtr(btCfg.label));
            }
            if (btCfg.key){
                this._buttonMap[btCfg.key]=button;
            }
            if (btCfg.buttonSet) {
                var bs = btCfg.buttonSet;
                if (bs.label) {
                    bs.label = this.xtr(bs.label);
                }
                button.set(bs);
                if (btCfg.key){
                    this._buttonSetMap[btCfg.key]=bs;
                }
            }
            var serverCall = callbackery.data.Server.getInstance();
            var key = btCfg.key;
            var name = cfg.name;
            button.addListener('changeFileSelection',function(e){
                var fileList = e.getData();
                var formData = getFormData();
                if(formData && fileList) {
                    var form = new FormData();
                    form.append('name',name);
                    form.append('key',key);
                    form.append('file',fileList[0]);
                    form.append('formData',qx.lang.Json.stringify(formData));
                    var that = this;
                    serverCall.callAsyncSmart(function(cookie){
                        form.append('xsc',cookie);
                        that._uploadForm(form);
                    },'getSessionCookie');
                } else {
                    callbackery.ui.MsgBox.getInstance().error(
                        this.tr("Upload Exception"),
                        this.tr("Make sure to select a file and properly fill the form")
                    );
                }
            },this);

            
            return button;
        },

        _uploadForm: function(form){
            var req = new qx.io.request.Xhr("upload",'POST').set({
                requestData: form
            });
            req.addListener('success',function(e) {
                var response = req.getResponse();
                if (response.exception){
                    callbackery.ui.MsgBox.getInstance().error(
                        this.tr("Upload Exception"),
                        this.xtr(response.exception.message) 
                            + " ("+ response.exception.code +")"
                    );
                } else {
                    this.fireDataEvent('actionResponse',response);
                }
                req.dispose();
            },this);
            req.addListener('fail',function(e){
                var response = {};
                try {
                    response = req.getResponse();
                }
                catch(e){
                    response = {
                        exception: {
                            message: e.message,
                            code: 99999
                        }
                    };
                }
                callbackery.ui.MsgBox.getInstance().error(
                    this.tr("Upload Exception"),
                    this.xtr(response.exception.message) 
                        + " ("+ response.exception.code +")"
                );
                req.dispose();
            });
            req.send();
        },

        getTableContextMenu: function(){
            return this._tableMenu;
        },

        getDefaultAction: function(){
            return this._defaultAction;
        },
        getButtonMap: function(){
            return this._buttonMap;
        },
        getButtonSetMap: function(){
            return this._buttonSetMap;
        }
    }
});
